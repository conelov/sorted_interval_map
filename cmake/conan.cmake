include_guard(GLOBAL)


set(CHC_CONAN_PROFILE "default" CACHE STRING "Use conan profile")
set(CHC_CONAN_BUILD_TYPE "Release" CACHE STRING "Conan generated packages build type")
set(CHC_CONAN_BUILD_DIR "${CMAKE_SOURCE_DIR}/cmake-chc_conan_generated/${CHC_CONAN_PROFILE}/${CHC_CONAN_BUILD_TYPE}" CACHE PATH "Conan generated packages directory")


unset(CHCAUX_CONAN_ACCUM_FIND_PKG_ARG)
unset(CHCAUX_CONAN_ACCUM_CONAN_PKG)
unset(CHCAUX_CONAN_ACCUM_CONAN_ARG)
unset(CHCAUX_CONAN_TOOLCHAIN_FILE)


macro(chcaux_conan_project_assert)
  if(NOT "${PROJECT_NAME}" STREQUAL "")
    message(FATAL_ERROR "Call ${CMAKE_CURRENT_FUNCTION} before 'project' command.")
  endif()
endmacro()


function(chcaux_conan_find_package package_list_var mode)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")
  chc_assert_not_str_empty(${package_list_var})
  chc_assert_not_str_empty(mode)

  if(DEFINED CACHE{CHCAUX_CONAN_TOOLCHAIN_FILE})
    # https://discourse.cmake.org/t/third-party-package-problem/8516
    if("${CMAKE_BUILD_TYPE}" STREQUAL "")
      message(FATAL_ERROR "Required explicit set 'CMAKE_BUILD_TYPE' for conan toolchain handler.")
    endif()
    string(TOUPPER "${CMAKE_BUILD_TYPE}" type)
    set(CMAKE_MAP_IMPORTED_CONFIG_${type} ${CHC_CONAN_BUILD_TYPE} CACHE INTERNAL "") # TODO possible problem in msvc ITERATOR_DEBUG_LEVEL
  endif()

  foreach(i IN LISTS ${package_list_var})
    cmake_language(EVAL CODE "find_package(${i} ${mode})")
  endforeach()
endfunction()


function(chc_conan_declare pkg pkg_conan_ver)
  chcaux_conan_project_assert()
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")

  set(options_keywords)
  set(one_value_keywords VERSION)
  set(multi_value_keywords COMPONENTS CONAN_ARGS)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  set(find_package_args ${pkg} ${arg_VERSION})

  if(arg_COMPONENTS)
    list(APPEND find_package_args COMPONENTS ${arg_COMPONENTS})
  endif()

  chcaux_conan_find_package(find_package_args QUIET)
  if(${pkg}_FOUND)
    return()
  endif()

  if("${pkg_conan_ver}" STREQUAL "")
    message(FATAL_ERROR "Cannot build package '${pkg}' because no arguments were supplied for conan.")
  endif()

  macro(push_accum accum_type value)
    set(var CHCAUX_CONAN_ACCUM_${accum_type})
    list(APPEND ${var} "${value}")
    set(${var} "${${var}}" PARENT_SCOPE)
  endmacro()
  push_accum(FIND_PKG_ARG ${find_package_args})
  push_accum(CONAN_PKG ${pkg_conan_ver})

  chc_list_unpack(arg_CONAN_ARGS)
  push_accum(CONAN_ARG "${arg_CONAN_ARGS}")
endfunction()


function(chc_conan_do)
  chcaux_conan_project_assert()
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")

  if(DEFINED CACHE{CHCAUX_CONAN_TOOLCHAIN_FILE})
    return()
  endif()

  cmake_path(SET output_folder NORMALIZE "${CHC_CONAN_BUILD_DIR}")
  cmake_path(RELATIVE_PATH output_folder BASE_DIRECTORY "${CMAKE_SOURCE_DIR}")

  set(pkgs "${CHCAUX_CONAN_ACCUM_CONAN_PKG}")
  list(TRANSFORM pkgs PREPEND "--requires=")
  chc_list_unpack(pkgs)

  chc_list_unpack(CHCAUX_CONAN_ACCUM_CONAN_ARG ";" conan_args_str)

  find_program(conan_exe conan REQUIRED)
  set(conan_command "
    \"${conan_exe}\" install
        ${pkgs}
        --build=missing
        --output-folder=${output_folder}
        --profile:all=${CHC_CONAN_PROFILE}
        -s build_type=${CHC_CONAN_BUILD_TYPE}
        -g CMakeDeps
        -g CMakeToolchain
        ${conan_args_str}
  ")

  message(STATUS "Start conan resolve.")
  message(VERBOSE "Execute command: ${conan_command}")
  cmake_language(EVAL CODE "
    execute_process(
      COMMAND ${conan_command}
      WORKING_DIRECTORY \"${CMAKE_CURRENT_LIST_DIR}\"
      COMMAND_ERROR_IS_FATAL ANY
    )
  ")
  # if required sudo privileges for access package manager
  # add 'tools.system.package_manager:sudo=True' to you conan profile file

  set(CHCAUX_CONAN_TOOLCHAIN_FILE "${CHC_CONAN_BUILD_DIR}/conan_toolchain.cmake" CACHE INTERNAL "")
endfunction()


macro(chc_conan_toolchain)
  chcaux_conan_project_assert()
  if(NOT DEFINED CACHE{CHCAUX_CONAN_TOOLCHAIN_FILE})
    return()
  endif()

  if("${CMAKE_TOOLCHAIN_FILE}" STREQUAL "")
    set(CMAKE_TOOLCHAIN_FILE "${CHCAUX_CONAN_TOOLCHAIN_FILE}")
  elseif(NOT "${CMAKE_TOOLCHAIN_FILE}" STREQUAL "${CHCAUX_CONAN_TOOLCHAIN_FILE}")
    message(SEND_ERROR "Custom toolchain file '${CMAKE_TOOLCHAIN_FILE}' is not valid when using conan.")
  endif()
endmacro()


function(chc_conan_resolve)
  if("${PROJECT_NAME}" STREQUAL "")
    message(FATAL_ERROR "Call ${CMAKE_CURRENT_FUNCTION} after 'project' command.")
  endif()
  chcaux_conan_find_package(CHCAUX_CONAN_ACCUM_FIND_PKG_ARG REQUIRED)
endfunction()
