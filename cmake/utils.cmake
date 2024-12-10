include_guard(GLOBAL)


macro(chc_assert_not_str_empty var)
  if("${${var}}" STREQUAL "")
    message(FATAL_ERROR "Assert variable '${var}' is empty string.")
  endif()
endmacro()


macro(chc_assert_not_variable var)
  if(NOT ${var})
    message(FATAL_ERROR "Assert variable '${var}' is false.")
  endif()
endmacro()


macro(chc_assert_defined_target target_var)
  if(NOT TARGET ${target_var})
    message(FATAL_ERROR "Assert target '${var}' is not defined.")
  endif()
endmacro()


macro(chc_set_if_undefined variable value #[[<cache command sequence>]])
  if(NOT DEFINED ${variable})
    cmake_language(EVAL CODE "set(${variable} \"${value}\" ${ARGN})")
  endif()
endmacro()


macro(chc_assert_incomparable_arguments arg #[[args]])
  set(if_condition_cmd "${ARGN}")
  list(TRANSFORM if_condition_cmd PREPEND "AND ")
  list(PREPEND if_condition_cmd "${arg}")
  chc_list_unpack(if_condition_cmd)
  cmake_language(EVAL CODE "
    if(${if_condition_cmd})
      message(FATAL_ERROR \"Incomparable or all false arguments: ${if_condition_cmd}\")
    endif()
  ")
endmacro()


macro(chc_set_if var)
  set(options_keywords NOT EMPTY "PARENT_SCOPE" HEAD)
  set(one_value_keywords SET THEN)
  set(multi_value_keywords)
  cmake_parse_arguments(arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}" ${ARGN})
  chc_assert_incomparable_arguments(arg_SET arg_THEN)
  chc_assert_incomparable_arguments(arg_SET arg_HEAD)

  set(if_condition_cmd "${var}")
  if(arg_EMPTY)
    set(if_condition_cmd "\"${${var}}\" STREQUAL \"\"")
  endif()
  if(arg_NOT)
    set(if_condition_cmd "NOT ${if_condition_cmd}")
  endif()

  if(arg_HEAD)
    chcaux_head_check()
    chc_head_variable(${arg_THEN} head_value)
    set(set_cmd "set(${var} \"${head_value}\")")
  else()
    set(set_cmd "set(${var} \"${arg_THEN}\")")
  endif()

  if(NOT "${arg_SET}" STREQUAL "")
    set(set_cmd "${arg_SET} \"${${var}}\"")
  endif()
  if(arg_PARENT_SCOPE)
    set(set_cmd "${set_cmd} PARENT_SCOPE")
  endif()

  cmake_language(EVAL CODE "
  if(${if_condition_cmd})
    cmake_language(EVAL CODE \"${set_cmd}\")
  endif()
  ")
endmacro()


macro(chc_list_unpack list_var #[[delim]] #[[result_var]])
  set(delim " ")
  if(${ARGC} GREATER 1)
    set(delim "${ARGV1}")
  endif()

  set(result_var ${list_var})
  if(${ARGC} GREATER 2)
    set(result_var ${ARGV2})
  endif()

  string(REPLACE ";" "${delim}" ${result_var} "${${list_var}}")
endmacro()


function(chc_list_split delim result_list_prefix #[[list_var]])
  set(current_list "")
  set(index 0)

  foreach(element IN LISTS ARGN)
    if(element STREQUAL delim)
      set(result_list_name "${result_list_prefix}_${index}")
      set(${result_list_name} "${current_list}" PARENT_SCOPE)
      set(current_list "")
      math(EXPR index "${index} + 1")
    else()
      list(APPEND current_list "${element}")
    endif()
  endforeach()

  if(current_list)
    set(result_list_name "${result_list_prefix}_${index}")
    set(${result_list_name} "${current_list}" PARENT_SCOPE)
  endif()

  set(${result_list_prefix}_count ${index} PARENT_SCOPE)
endfunction()


# https://github.com/nocnokneo/cmake-git-versioning-example/blob/master/GenerateVersionHeader.cmake
function(chc_get_git_tag result_var)
  unset(${result_var} PARENT_SCOPE)
  find_package(Git)
  if(NOT "${GIT_EXECUTABLE}" STREQUAL "")
    macro(git_exec command variable)
      cmake_language(EVAL CODE "
          execute_process(
          COMMAND \"${GIT_EXECUTABLE}\" ${command}
          WORKING_DIRECTORY \"${PROJECT_SOURCE_DIR}\"
          OUTPUT_VARIABLE ${variable}
          OUTPUT_STRIP_TRAILING_WHITESPACE
          COMMAND_ERROR_IS_FATAL ANY
        )"
      )
    endmacro()

    git_exec("show -s --date=format:%Y%m%d-%H%M --format=%cd" time)
    git_exec("rev-parse --short HEAD" hash)
    set(${result_var} "${time};${hash}" PARENT_SCOPE)
  endif()
endfunction()


function(chc_download_file url to)
  set(options_keywords OVERWRITE SHOW_PROGRESS)
  set(one_value_keywords)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 2 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  cmake_path(SET to NORMALIZE "${to}")
  if(EXISTS "${to}" AND NOT arg_OVERWRITE)
    return()
  endif()

  if(arg_SHOW_PROGRESS)
    set(show_progress_cmd SHOW_PROGRESS)
  endif()

  get_filename_component(file "${to}" NAME)
  message(STATUS "Try download ${file} from ${url}")
  cmake_language(EVAL CODE "file(DOWNLOAD \"${url}\" \"${to}\" STATUS check ${show_progress_cmd})")
  list(GET check 0 check)
  if(NOT ${check} EQUAL 0)
    message(FATAL_ERROR "Failed to download ${file}")
  endif()
endfunction()


function(chc_cpm #[[CPMAddPackage ...]])
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
  chc_download_file(https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.2/CPM.cmake "${cpm_file}")

  option(CPM_USE_NAMED_CACHE_DIRECTORIES "" ON)
  option(CPM_USE_LOCAL_PACKAGES "" ON)
  include("${cpm_file}")
  CPMAddPackage(${ARGN}) # https://github.com/cpm-cmake/CPM.cmake
endfunction()


function(chc_resolve_instrument_per_library instrument #[[result_path_var = ${instrument}_path]] #[[result_dir_var = ${instrument}_dir]])
  set(result_path_var ${instrument}_path)
  if(${ARGC} GREATER 1)
    set(${result_path_var} ${ARGV1})
  endif()

  set(result_dir_var ${instrument}_dir)
  if(${ARGC} GREATER 2)
    set(${result_dir_var} ${ARGV2})
  endif()

  macro(per_qt_lib name)
    chc_assert_not_str_empty(Qt_VERSION)
    get_target_property(${result_path_var} Qt${Qt_VERSION}::${name} LOCATION)
    chc_assert_not_variable(${result_path_var})
    cmake_path(NORMAL_PATH ${result_path_var})
    get_filename_component(${result_dir_var} "${${result_path_var}}" DIRECTORY CACHE)
  endmacro()

  if("${instrument}" STREQUAL "uic" OR "${instrument}" STREQUAL "moc")
    per_qt_lib(${instrument})
  endif()

  if(NOT DEFINED ${result_path_var})
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} unknown instrument '${instrument}'.")
  else()
    set(${result_path_var} "${${result_path_var}}" PARENT_SCOPE)
    set(${result_dir_var} "${${result_dir_var}}" PARENT_SCOPE)
  endif()
endfunction()


function(chc_switch_case cond_var result_var #[[<CASE key v1 v2 ...> ...]])
  set(options_keywords QUIT)
  set(one_value_keywords)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 2 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  chc_list_split(CASE cases ${arg_UNPARSED_ARGUMENTS})
  if(NOT cases_0 STREQUAL "")
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}. Not founded CASE keyword.")
  endif()

  foreach(i RANGE 1 ${cases_count})
    list(POP_FRONT cases_${i} key)
    if(key STREQUAL ${cond_var})
      set(${result_var} "${cases_${i}}" PARENT_SCOPE)
      return()
    endif()
  endforeach()

  if(arg_QUIT)
    unset(${result_var} PARENT_SCOPE)
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}. No match key ${cond_var}.")
  endif()
endfunction()


function(chc_switch_case_fn cond_var #[[<CASE key call fn> ...]])
  chc_switch_case(${cond_var} math_fn "${ARGN}")
  cmake_language(CALL ${math_fn})
endfunction()


function(chc_defer_fn_bind callback_fn_var)
  set(options_keywords NO_DIRECTORY)
  set(one_value_keywords DIRECTORY ID_VAR)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  chc_assert_incomparable_arguments(arg_NO_DIRECTORY arg_DIRECTORY)

  set(defer_cmd CALL ${callback_fn_var})
  if(NOT "${arg_UNPARSED_ARGUMENTS}" STREQUAL "")
    list(APPEND defer_cmd "${arg_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT arg_NO_DIRECTORY)
    if(arg_DIRECTORY STREQUAL "")
      set(dir "${CMAKE_CURRENT_SOURCE_DIR}")
    else()
      set(dir "${arg_DIRECTORY}")
    endif()
    list(PREPEND defer_cmd DIRECTORY "\"${dir}\"")
  endif()

  if(NOT arg_ID_VAR STREQUAL "")
    list(PREPEND defer_cmd ID_VAR ${arg_ID_VAR})
  endif()

  chc_list_unpack(defer_cmd)
  cmake_language(EVAL CODE "cmake_language(DEFER ${defer_cmd})")

  if(NOT arg_ID_VAR STREQUAL "")
    set(${arg_ID_VAR} "${${arg_ID_VAR}}" PARENT_SCOPE)
  endif()
endfunction()
