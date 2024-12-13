include_guard(GLOBAL)

function(chc_cpm #[[CPMAddPackage ...]])
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")
  set(cpm_folder_var ${CMAKE_CURRENT_FUNCTION}_cpm_folder)
  if(NOT DEFINED CACHE{${cpm_folder_var}})
    set(dest "${CPM_SOURCE_CACHE}")
    if("${dest}" STREQUAL "")
      set(dest "$ENV{CPM_SOURCE_CACHE}")
    endif()
    if("${dest}" STREQUAL "")
      set(dest "${CMAKE_BINARY_DIR}/cpm_repo")
      set(CPM_SOURCE_CACHE "${dest}" CACHE STRING "")
    endif()
    set(${cpm_folder_var} "${dest}" CACHE INTERNAL "")
  endif()

  set(file CPM.cmake)
  cmake_path(SET cpm_file NORMALIZE "${${cpm_folder_var}}/${file}")

  set(cpm_version 0.40.2)
  if(DEFINED PROJECT_NAME)
    chc_head_variable(CPM_VERSION QUIT)
    if(DEFINED CPM_VERSION)
      set(cpm_version ${CPM_VERSION})
    endif()
  endif()
  chc_download_file(https://github.com/cpm-cmake/CPM.cmake/releases/download/v${cpm_version}/CPM.cmake "${cpm_file}")

  option(CPM_USE_NAMED_CACHE_DIRECTORIES "" ON)
  option(CPM_USE_LOCAL_PACKAGES "" ON)
  include("${cpm_file}")
  CPMFindPackage(${ARGN}) # https://github.com/cpm-cmake/CPM.cmake
endfunction()


function(chc_cpm_gtest)
  chc_head_variable(GTEST_VERSION)
  # https://github.com/cpm-cmake/CPM.cmake/tree/master/examples/gtest
  chc_cpm(
    NAME googletest
    GITHUB_REPOSITORY google/googletest
    VERSION ${GTEST_VERSION}
    OPTIONS "INSTALL_GTEST OFF" "gtest_force_shared_crt" # https://stackoverflow.com/q/12540970
  )
endfunction()


function(chc_cpm_gbench)
  chc_head_variable(GBENCH_VERSION)
  # https://github.com/cpm-cmake/CPM.cmake/blob/master/examples/benchmark
  chc_cpm(
    NAME benchmark
    GITHUB_REPOSITORY google/benchmark
    VERSION ${GBENCH_VERSION}
    OPTIONS "BENCHMARK_ENABLE_TESTING OFF"
  )
endfunction()


function(chc_cpm_itlib)
  chc_head_variable(ITLIB_VERSION)
  chc_cpm(
    NAME itlib
    GITHUB_REPOSITORY iboB/itlib
    VERSION ${ITLIB_VERSION}
  )
endfunction()


function(chc_cpm_range_v3)
  chc_head_variable(RANGE-V3_COMMIT_HASH)
  chc_cpm(
    NAME range-v3
    URL https://github.com/ericniebler/range-v3/archive/${RANGE-V3_COMMIT_HASH}.tar.gz
  )
endfunction()


function(chc_cpm_boost BOOST_INCLUDE_LIBRARIES)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")
  chc_assert_not_str_empty(BOOST_INCLUDE_LIBRARIES)
  chc_head_variable(BOOST_VERSION)
  chc_cpm(
    NAME Boost
    VERSION ${BOOST_VERSION}
    URL https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/boost-${BOOST_VERSION}-cmake.tar.gz
    OPTIONS "BOOST_ENABLE_CMAKE ON"
  )
endfunction()
