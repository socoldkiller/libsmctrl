cmake_minimum_required(VERSION 3.10)
project(libsmctrl LANGUAGES C CUDA)

# Set CUDA path if not set
if(NOT DEFINED ENV{CUDA_HOME})
    set(CUDA_HOME "/usr/local/cuda")
else()
    set(CUDA_HOME $ENV{CUDA_HOME})
endif()

# Set compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -O0")
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -g -O0")

# Include directories
include_directories(${CUDA_HOME}/include)
link_directories(${CUDA_HOME}/lib64)

# ----- Main Library -----
# Shared library
add_library(smctrl_shared SHARED libsmctrl.c libsmctrl.h)
target_link_libraries(smctrl_shared cuda)
set_target_properties(smctrl_shared PROPERTIES OUTPUT_NAME "smctrl")

# Static library
add_library(smctrl_static STATIC libsmctrl.c libsmctrl.h)
target_link_libraries(smctrl_static cuda)
set_target_properties(smctrl_static PROPERTIES OUTPUT_NAME "smctrl")

# Alias targets for convenience
add_library(smctrl::shared ALIAS smctrl_shared)
add_library(smctrl::static ALIAS smctrl_static)

# ----- Test Executables -----
# Non-CUDA test (uses C compiler)
add_executable(libsmctrl_test_gpc_info libsmctrl_test_gpc_info.c)
target_link_libraries(libsmctrl_test_gpc_info smctrl_static)

# CUDA tests (use nvcc compiler)
# First, compile the shared CUDA object
add_library(smctrl_test_mask_shared OBJECT libsmctrl_test_mask_shared.cu)
target_include_directories(smctrl_test_mask_shared PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# CUDA test executables
add_executable(libsmctrl_test_global_mask libsmctrl_test_global_mask.c)
target_link_libraries(libsmctrl_test_global_mask smctrl_static smctrl_test_mask_shared)

add_executable(libsmctrl_test_stream_mask libsmctrl_test_stream_mask.c)
target_link_libraries(libsmctrl_test_stream_mask smctrl_static smctrl_test_mask_shared)

add_executable(libsmctrl_test_stream_mask_override libsmctrl_test_stream_mask_override.c)
target_link_libraries(libsmctrl_test_stream_mask_override smctrl_static smctrl_test_mask_shared)

add_executable(libsmctrl_test_next_mask libsmctrl_test_next_mask.c)
target_link_libraries(libsmctrl_test_next_mask smctrl_static smctrl_test_mask_shared)

add_executable(libsmctrl_test_next_mask_override libsmctrl_test_next_mask_override.c)
target_link_libraries(libsmctrl_test_next_mask_override smctrl_static smctrl_test_mask_shared)

# Custom targets for convenience
add_custom_target(build_tests DEPENDS
    libsmctrl_test_gpc_info
    libsmctrl_test_global_mask
    libsmctrl_test_stream_mask
    libsmctrl_test_stream_mask_override
    libsmctrl_test_next_mask
    libsmctrl_test_next_mask_override
)

add_custom_target(build_all DEPENDS smctrl_shared build_tests)

# Install targets
install(TARGETS smctrl_shared smctrl_static
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(FILES libsmctrl.h DESTINATION include)

# ----- Debugging Configuration -----
# Enable debug symbols
set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build" FORCE)
set_property(GLOBAL PROPERTY DEBUG_CONFIGURATIONS Debug)

# Add compile definitions for debugging
target_compile_definitions(smctrl_shared PRIVATE DEBUG)
target_compile_definitions(smctrl_static PRIVATE DEBUG)

# Create a custom target for cleaning (similar to Makefile's clean)
add_custom_target(clean_build
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}
    COMMENT "Cleaning build directory"
)
