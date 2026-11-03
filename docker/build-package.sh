#!/usr/bin/env bash
# Build the jerryv2 libpqxx binary distribution in Docker and export it to
# ./dist/libpqxx-<VERSION>-Linux.tar.gz (VERSION comes from ./VERSION).
#
# Usage: docker/build-package.sh [extra docker build args...]
#   e.g. docker/build-package.sh --build-arg CXX_STANDARD=17
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(tr -d '[:space:]' < "${root}/VERSION")"
dist="${root}/dist"

mkdir -p "${dist}"
DOCKER_BUILDKIT=1 docker build \
    --platform linux/amd64 \
    --file "${root}/docker/package.Dockerfile" \
    --target artifact \
    --output "type=local,dest=${dist}" \
    "$@" \
    "${root}"

tarball="${dist}/libpqxx-${version}-Linux.tar.gz"
if [[ ! -f "${tarball}" ]]; then
    echo "error: expected ${tarball} was not produced" >&2
    exit 1
fi
echo "Built ${tarball}"
