# syntax=docker/dockerfile:1
# ------------------------------------------------------------------
# Build the libpqxx binary distribution consumed by jerryv2
# (Sonic-Web-Dev/jerryv2 Dockerfile / Dockerfile.local):
#
#   ADD https://github.com/Sonic-Web-Dev/libpqxx/releases/download/<ver>/libpqxx-<ver>-Linux.tar.gz /tmp
#   RUN tar -C /usr/local --strip-components=1 -xzf /tmp/libpqxx-<ver>-Linux.tar.gz
#
# The base image, compiler, CMake and libpq match jerryv2's toolchain stage
# so the static archive is ABI-compatible with the code that links it.
#
# Use docker/build-package.sh rather than invoking this directly; it exports
# the tarball to ./dist on the host.
# ------------------------------------------------------------------
ARG UBUNTU_VERSION=24.04

# ------------------------------------------------------------------
# Stage 1: toolchain
# ------------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION} AS toolchain
ENV DEBIAN_FRONTEND=noninteractive
ARG CMAKE_VERSION=3.31.3
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates libpq-dev ninja-build wget && \
    rm -rf /var/lib/apt/lists/*
RUN wget -q -O /tmp/cmake.sh \
        https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
    sh /tmp/cmake.sh --skip-license --prefix=/usr/local && \
    rm /tmp/cmake.sh

# ------------------------------------------------------------------
# Stage 2: build + package (CPack TGZ -> libpqxx-<VERSION>-Linux.tar.gz)
# ------------------------------------------------------------------
FROM toolchain AS build
# jerryv2 compiles with C++20; build the library with the same standard so
# the generated feature-check config header matches what consumers see.
ARG CXX_STANDARD=20
COPY . /src
RUN cmake -G Ninja -S /src -B /build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=${CXX_STANDARD} \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_SHARED_LIBS=OFF \
        -DSKIP_BUILD_TEST=ON \
        -DBUILD_DOC=OFF && \
    cmake --build /build -j"$(nproc)" && \
    cd /build && cpack -G TGZ && \
    mkdir -p /out && cp /build/libpqxx-*-Linux.tar.gz /out/

# ------------------------------------------------------------------
# Stage 3: smoke test
# Install the tarball exactly the way jerryv2 does and build a consumer
# with find_package(libpqxx). The artifact stage copies the tarball from
# here, so a package that fails this test can never be exported.
# ------------------------------------------------------------------
FROM toolchain AS smoke
ARG CXX_STANDARD=20
COPY --from=build /out/ /out/
COPY docker/smoke-test/ /smoke/
RUN set -eux; \
    tarball="$(ls /out/libpqxx-*-Linux.tar.gz)"; \
    tar -C /usr/local --strip-components=1 -xzf "${tarball}"; \
    ldconfig; \
    cmake -G Ninja -S /smoke -B /smoke/build \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=${CXX_STANDARD}; \
    cmake --build /smoke/build; \
    /smoke/build/pqxx-smoke

# ------------------------------------------------------------------
# Stage 4: artifact (exported with `docker build --output`)
# ------------------------------------------------------------------
FROM scratch AS artifact
COPY --from=smoke /out/ /
