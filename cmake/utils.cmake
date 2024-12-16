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
    chc_head_variable(${arg_THEN} RESULT_VAR head_value)
    set(set_cmd "${var} \"${head_value}\"")
  else()
    set(set_cmd "${var} \"${arg_THEN}\"")
  endif()

  if(NOT "${arg_SET}" STREQUAL "")
    set(set_cmd "${arg_SET} \"${${var}}\"")
  endif()
  if(arg_PARENT_SCOPE)
    set(set_cmd "${set_cmd} PARENT_SCOPE")
  endif()

  cmake_language(EVAL CODE "
  if(${if_condition_cmd})
    cmake_language(EVAL CODE \"set(${set_cmd})\")
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


function(chc_defer_fn callback_fn_var)
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
    chc_set_if(arg_DIRECTORY EMPTY THEN "${CMAKE_CURRENT_SOURCE_DIR}")
    list(PREPEND defer_cmd DIRECTORY "\"${arg_DIRECTORY}\"")
  endif()

  if(NOT "${arg_ID_VAR}" STREQUAL "")
    list(PREPEND defer_cmd ID_VAR ${arg_ID_VAR})
  endif()

  chc_list_unpack(defer_cmd)
  cmake_language(EVAL CODE "cmake_language(DEFER ${defer_cmd})")

  if(NOT arg_ID_VAR STREQUAL "")
    set(${arg_ID_VAR} "${${arg_ID_VAR}}" PARENT_SCOPE)
  endif()
endfunction()


function(chc_defer_code code #[[chc_defer_fn args ...]])
  string(MD5 defer_fn "${code}")
  set(defer_fn ${CMAKE_CURRENT_FUNCTION}_${defer_fn})
  function(${defer_fn})
    set(code "${ARGN}")
    chc_list_unpack(code "")
    cmake_language(EVAL CODE "${code}")
  endfunction()
  chc_defer_fn(${defer_fn} \""${code}\"" ${ARGN})
endfunction()


function(chc_doxygen)
  chcaux_head_check()

  set(options_keywords NO_CONFIGURED_DOXYFILE REQUIRED)
  set(one_value_keywords SCAN_DIRECTORY DOXYFILE OUTPUT)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 0 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  chc_set_if(arg_OUTPUT EMPTY THEN "${PROJECT_BINARY_DIR}/docs")

  chc_set_if(arg_DOXYFILE EMPTY THEN "${PROJECT_SOURCE_DIR}/Doxyfile.in")
  if(NOT EXISTS "${arg_DOXYFILE}")
    message(FATAL_ERROR "Doxyfile not exist.")
  endif()

  if(NOT arg_NO_CONFIGURED_DOXYFILE)
    cmake_path(SET doxy_file NORMALIZE "${arg_OUTPUT}/Doxyfile")
    configure_file("${arg_DOXYFILE}" "${doxy_file}" @ONLY)
    cmake_path(SET arg_DOXYFILE NORMALIZE "${doxy_file}")
  endif()

  chc_set_if(arg_SCAN_DIRECTORY EMPTY THEN "${PROJECT_SOURCE_DIR}/${PROJECT_NAME_SHORT}")

  if(arg_REQUIRED)
    find_package(Doxygen REQUIRED)
  else()
    find_package(Doxygen)
    if(NOT Doxygen_FOUND)
      return()
    endif()
  endif()

  cmake_path(SET html_index_path NORMALIZE "${arg_OUTPUT}/html/index.html")
  add_custom_target(${PROJECT_NAME_SHORT}-doxygen_generate
    COMMAND "${DOXYGEN_EXECUTABLE}" "${arg_DOXYFILE}"
    DEPENDS "${arg_DOXYFILE}"
    BYPRODUCTS "${html_index_path}"
    WORKING_DIRECTORY "${arg_SCAN_DIRECTORY}"
    COMMENT "Generating documentation with doxygen."
    COMMAND_EXPAND_LISTS
    VERBATIM
  )

  foreach(i chromium firefox)
    find_program(browser_exe ${i})
    if(browser_exe-NOTFOUND)
      continue()
    endif()

    add_custom_target(${PROJECT_NAME_SHORT}-doxygen_show
      COMMAND "${browser_exe}" "${html_index_path}"
      DEPENDS "${html_index_path}"
    )
    break()
  endforeach()
endfunction()


function(chc_doxygen_auto)
  cmake_path(SET doxy_path "${PROJECT_SOURCE_DIR}/Doxyfile")
  if(EXISTS "${doxy_path}")
    chc_doxygen(NO_CONFIGURED_DOXYFILE)
  else()
    cmake_path(SET doxy_path "${PROJECT_SOURCE_DIR}/Doxyfile.in")
    if(EXISTS "${doxy_path}")
      chc_doxygen()
    endif()
  endif()
endfunction()


function(chc_host_cpu_count out_var)
  cmake_host_system_information(RESULT ${out_var} QUERY NUMBER_OF_PHYSICAL_CORES)
  set(${out_var} ${${out_var}} PARENT_SCOPE)
endfunction()


function(chc_host_memory_physical_size out_var)
  cmake_host_system_information(RESULT ${out_var} QUERY TOTAL_PHYSICAL_MEMORY)
  set(${out_var} ${${out_var}} PARENT_SCOPE)
endfunction()


function(chc_get_libcxx_type result_var) # TODO not working
  set(options_keywords)
  set(one_value_keywords UNKNOWN LIBSTDCPP LIBCPP)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  chc_set_if(arg_UNKNOWN EMPTY THEN "unknown")
  set(unknown_return_code 1)

  chc_set_if(arg_LIBSTDCPP EMPTY THEN "libstdc++")
  set(libstdcpp_return_code 2)

  chc_set_if(arg_LIBCPP EMPTY THEN "libc++")
  set(libcpp_return_code 3)

  set(type_var "${CMAKE_CURRENT_FUNCTION}-type")
  if(NOT DEFINED CACHE{type_var})
    set(bindir "${PROJECT_BINARY_DIR}/chc")
    set(file_check_libcxx_source "${bindir}/check_libcxx.cpp")
    file(WRITE "${file_check_libcxx_source}" "
#ifdef __GLIBCXX__
  int main () { return ${libstdcpp_return_code}; }
#elif defined(_LIBCPP_VERSION)
  int main () { return ${libcpp_return_code}; }
#else
  int main () { return ${unknown_return_code}; }
#endif
      ")

    try_run(run_return_var compile_result_var ${bindir} "${file_check_libcxx_source}")
    if(NOT compile_result_var EQUAL 0)
      message(FATAL_ERROR " ${CMAKE_CURRENT_FUNCTION}. Failed to compile.")
    elseif("${run_return_var}" STREQUAL "FAILED_TO_RUN")
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}. Failed to run.")
    endif()
    set(${type_var} ${run_return_var} CACHE INTERNAL "")
  endif()

  if(${${type_var}} EQUAL ${unknown_return_code})
    set(${result_var} "${arg_UNKNOWN}" PARENT_SCOPE)
  elseif(${${type_var}} EQUAL ${libstdcpp_return_code})
    set(${result_var} "${arg_LIBSTDCPP}" PARENT_SCOPE)
  elseif(${${type_var}} EQUAL ${arg_LIBCPP})
    set(${result_var} "${arg_UNKNOWN}" PARENT_SCOPE)
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}. Logic error.")
  endif()
endfunction()
