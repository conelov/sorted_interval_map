include_guard(DIRECTORY)


macro(chc_project)
  set(options_keywords)
  set(one_value_keywords SHORT_NAME)
  set(multi_value_keywords)
  cmake_parse_arguments(arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}" ${ARGN})

  cmake_language(EVAL CODE "project(${arg_UNPARSED_ARGUMENTS})")

  string(TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UP)

  set(PROJECT_NAME_SHORT ${PROJECT_NAME})
  if(NOT "${arg_SHORT_NAME}" STREQUAL "")
    set(PROJECT_NAME_SHORT ${arg_SHORT_NAME})
  endif()
  string(TOUPPER "${PROJECT_NAME_SHORT}" PROJECT_NAME_SHORT_UP)

  set(CHCAUX_HEAD_LOADED_FOR_${PROJECT_NAME} ON)
endmacro()


function(chc_head_define_variable type name value #[[doc = ""]] #[[result_var = "last_head_var"]])
  chcaux_head_check()

  foreach(prefix PROJECT_NAME_UP PROJECT_NAME_SHORT_UP)
    set(var ${${prefix}}_${name})
    if(DEFINED ${var} OR DEFINED CACHE{${var}})
      set(value "${${var}}")
      break()
    endif()
  endforeach()

  foreach(prefix PROJECT_NAME PROJECT_NAME_UP PROJECT_NAME_SHORT_UP)
    set(${${prefix}}_${name} "${value}" CACHE ${type} "${ARGV3}")
  endforeach()

  set(result_var last_head_var)
  if(ARGC GREATER 4)
    set(result_var ${ARGV4})
  endif()
  set(${result_var} "${value}" PARENT_SCOPE)
endfunction()


function(chc_head_variable var result_var #[[project = ${PROJECT_NAME}]])
  if(${ARGC} GREATER 2)
    set(project ${ARGV2})
  else()
    chcaux_head_check()
    set(project ${PROJECT_NAME})
  endif()

  set(var_head ${project}_${var})
  if(NOT DEFINED CACHE{${var_head}})
    message(FATAL_ERROR "Undefined head variable: ${var_head}")
  endif()

  set(${result_var} "${${var_head}}" PARENT_SCOPE)
endfunction()


function(chcaux_head_check #[[result_var]])
  if(NOT DEFINED PROJECT_NAME OR NOT CHCAUX_HEAD_LOADED_FOR_${PROJECT_NAME})
    if(${ARGC} GREATER 0)
      set(${ARGV0} FALSE PARENT_SCOPE)
    else()
      message(FATAL_ERROR "Call chc_project() from '${CMAKE_CURRENT_FUNCTION_LIST_FILE}' in project root.")
    endif()
    return()
  endif()
  if(${ARGC} GREATER 0)
    set(${ARGV0} TRUE PARENT_SCOPE)
  endif()
endfunction()
