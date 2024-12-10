include_guard(DIRECTORY)


macro(chcaux_no_except_rtti target)
  chcaux_head_check()
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")

  macro(gnu_fn)
    target_compile_options(${target} PRIVATE
      -fno-rtti
      -fno-exceptions
    )
  endmacro()

  #  macro(msvc_fn)
  #    target_compile_definitions(${target} PRIVATE
  #      ${prefix}_attribute=__declspec
  #    )
  #  endmacro()

  chc_switch_case_fn(CMAKE_CXX_COMPILER_FRONTEND_VARIANT
    CASE "GNU" gnu_fn
    #    CASE "MSVC" msvc_fn TODO msvc noexcept flags
  )

  target_compile_definitions(${target} PRIVATE
    ${PROJECT_NAME_UP}_NO_EXCEPT_AND_RTTI
    ${PROJECT_NAME_SHORT_UP}_NO_EXCEPT_AND_RTTI
  )
endmacro()


macro(chcaux_wall target)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")

  macro(gnu_fn)
    target_compile_options(${target} PRIVATE
      -Wall
      -fdiagnostics-all-candidates
    )
  endmacro()

  #  macro(msvc_fn)

  #  endmacro()

  chc_switch_case_fn(CMAKE_CXX_COMPILER_FRONTEND_VARIANT
    CASE "GNU" gnu_fn
    #    CASE "MSVC" msvc_fn TODO msvc wall flags
  )


  #  target_compile_options(${target} PRIVATE TODO is valid check
  #    $<$<OR:$<COMPILE_LANG_AND_ID:CXX,Clang>,$<COMPILE_LANG_AND_ID:CXX,GNU>>:-Wall>
  #    $<$<COMPILE_LANG_AND_ID:CXX,GNU>:-fdiagnostics-all-candidates>
  #  )
endmacro()


function(chcaux_uic_resolve target #[[ui_n ...]])
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")
  chc_resolve_instrument_per_library(uic)
  foreach(ui_file_relative_path IN LISTS ARGN)
    cmake_path(ABSOLUTE_PATH ui_file_relative_path BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" NORMALIZE OUTPUT_VARIABLE ui_file_absolute_path)
    get_filename_component(ui_header_file_name "${ui_file_absolute_path}" NAME_WE)
    set(ui_header_file_name "ui_${ui_header_file_name}.h")
    cmake_path(SET ui_header_dir NORMALIZE "${CMAKE_CURRENT_BINARY_DIR}/uic")
    cmake_path(SET ui_header_file_path NORMALIZE "${ui_header_dir}/${ui_header_file_name}")
    add_custom_command(
      COMMAND "${uic_path}"
      --output "${ui_header_file_path}"
      --generator cpp
      --connections pmf
      "${ui_file_absolute_path}"
      OUTPUT "${ui_header_file_path}"
      DEPENDS "${ui_file_absolute_path}"
      WORKING_DIRECTORY "${ui_header_dir}"
      COMMENT "Uic generate from \"${ui_file_absolute_path}\" to \"${ui_header_file_path}\""
      COMMAND_EXPAND_LISTS
      VERBATIM
      #        USES_TERMINAL
    )
    target_sources(${target} PRIVATE "${ui_header_file_path}" "${ui_file_absolute_path}")
    target_include_directories(${target} PRIVATE "${ui_header_dir}")
  endforeach()
endfunction()


function(chcaux_moc_cpp target #[[cpp ...]])
  chc_assert_not_str_empty(Qt_VERSION)

  string(TOUPPER "${CMAKE_BUILD_TYPE}" self_build_type)
  set(map_buidl_type_var CMAKE_MAP_IMPORTED_CONFIG_${self_build_type})
  if(NOT "${${map_buidl_type_var}}" STREQUAL "")
    string(TOUPPER "${${map_buidl_type_var}}" map_buidl_type)
    set(moc_target Qt${Qt_VERSION}::moc)
    get_target_property(moc_path ${moc_target} IMPORTED_LOCATION)
    set_target_properties(${moc_target} PROPERTIES IMPORTED_LOCATION_${map_buidl_type} "${moc_path}")
  endif()

  cmake_language(CALL qt${Qt_VERSION}_wrap_cpp moc_files "${ARGN}" TARGET ${target})
  target_sources(${target} PRIVATE "${moc_files}")
endfunction()
