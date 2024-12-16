cmake_minimum_required(VERSION 3.30)

include(cmake/head.cmake)
include(cmake/utils.cmake)
chc_project(sorted_interval_map
  SHORT_NAME sim
  LANGUAGES CXX
  VERSION 0.1
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
option(BUILD_TESTING "Enable testing" ${PROJECT_IS_TOP_LEVEL})

chc_head_define_variable(STRING GTEST_VERSION 1.15.2)
chc_head_define_variable(STRING GBENCH_VERSION 1.9.0)
chc_head_define_variable(STRING BOOST_VERSION 1.87.0)
chc_head_define_variable(STRING ITLIB_VERSION 1.11.4)
chc_head_define_variable(STRING RANGE-V3_COMMIT_HASH 7e6f34b1e820fb8321346888ef0558a0ec842b8e)
chc_head_define_variable(BOOL RESEARCH ${PROJECT_IS_TOP_LEVEL})
chc_head_define_variable(BOOL RESEARCH_GBENCH_SAN OFF "Use sanitizers for benchmarking")

chc_host_memory_physical_size(mem_size)
chc_head_define_variable(BOOL RESEARCH_SORTED_INTERVAL_INT32 $<VERSION_GREATER_EQUAL:${mem_size},32768>)

if(PROJECT_IS_TOP_LEVEL)
  chc_head_define_variable(STRING SANITIZERS "address;thread;ub;leak;mem" "Add this sanitizers per targets. [address;thread;ub;leak;mem]")
endif()

if(BUILD_TESTING)
  chc_head_variable(SANITIZERS)
  if(NOT "${SANITIZERS}" STREQUAL "" AND NOT BUILD_SHARED_LIBS)
    message(STATUS "BUILD_SHARED_LIBS needed for sanitize. Forced enabled.")
    set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
  endif()
  enable_testing()
endif()


add_subdirectory(sim)