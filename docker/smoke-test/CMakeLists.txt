cmake_minimum_required(VERSION 3.12)
project(pqxx-smoke LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Same lookup jerryv2 uses (src/settlement/CMakeLists.txt).
find_package(libpqxx REQUIRED)

add_executable(pqxx-smoke main.cpp)
target_link_libraries(pqxx-smoke PRIVATE libpqxx::pqxx)
