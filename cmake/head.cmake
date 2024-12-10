include_guard(DIRECTORY)


macro(chc_head_initialize_variable project_name #[[project_name_short = project_name]])
  string(TOUPPER "${project_name}" PROJECT_NAME_UP)

  set(PROJECT_NAME_SHORT ${project_name_short})
  if(${ARGC} GREATER 1)
    set(PROJECT_NAME_SHORT ${ARGV1})
  endif()
  string(TOUPPER "${PROJECT_NAME_SHORT}" PROJECT_NAME_SHORT_UP)

  set(CHCAUX_HEAD_LOADED_FOR_${project_name} ON CACHE INTERNAL "")
endmacro()


function(chc_define_head_variable type name value #[[doc = ""]] #[[result_var = "last_head_var"]])
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


macro(chcaux_head_check)
  if(NOT CHCAUX_HEAD_LOADED_FOR_${PROJECT_NAME})
    message(FATAL_ERROR "Call chc_head_initialize_variable() from '${CMAKE_CURRENT_FUNCTION_LIST_FILE}' in project root.")
  endif()
endmacro()
