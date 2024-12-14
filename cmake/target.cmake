include_guard(GLOBAL)


function(chc_target_auto_name #[[result_var = name]])
  chcaux_head_check()

  set(result_var name)
  if(${ARGC} GREATER 1)
    set(result_var ${ARGV1})
  endif()

  cmake_path(SET ${result_var} NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}")
  cmake_path(RELATIVE_PATH ${result_var} BASE_DIRECTORY "${PROJECT_SOURCE_DIR}")
  string(REPLACE "${PROJECT_NAME}" "${PROJECT_NAME_SHORT}" ${result_var} "${${result_var}}")
  string(REPLACE "/" "-" ${result_var} "${${result_var}}")
  set(${result_var} "${${result_var}}" PARENT_SCOPE)
endfunction()


function(chc_target_common target)
  chcaux_head_check()

  set(options_keywords UT DEMO)
  set(one_value_keywords)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  target_include_directories(${target} PRIVATE
    "${PROJECT_SOURCE_DIR}"
  )

  set_target_properties(${target} PROPERTIES
    LINKER_LANGUAGE CXX
  )

  target_compile_definitions(${target}
    PRIVATE
    PROJECT_NAME="${PROJECT_NAME}"
    PROJECT_VERSION=${PROJECT_VERSION}
    PUBLIC
    ${PROJECT_NAME_SHORT_UP}_CXX_COMPILER_FRONTEND_${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}
  )

  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/private.cmake")
  if(${PROJECT_NAME}_EXTRA_DIAG)
    chcaux_wall(${target})
  endif()

  if(${PROJECT_NAME}_NO_EXCEPT_AND_RTTI)
    chcaux_no_except_rtti(${target})
  endif()

  if(BUILD_TESTING AND arg_UT)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/ut")
  endif()

  if(${PROJECT_NAME}_DEMO AND arg_DEMO)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/demo")
  endif()
endfunction()


function(chc_target_gtest target)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")
  chc_assert_not_variable(BUILD_TESTING)

  set(options_keywords MAIN MOCK MOCK_MAIN)
  set(one_value_keywords)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/cpm.cmake")
  chc_cpm_gtest()
  target_link_libraries(${name} PRIVATE
    GTest::gtest
    $<$<BOOL:${arg_MAIN}>:GTest::gtest_main>
    $<$<BOOL:${arg_MOCK}>:GTest::gmock>
    $<$<BOOL:${arg_MOCK_MAIN}>:GTest::gmock_main>
  )
  add_test(NAME ${name} COMMAND "$<TARGET_FILE:${name}>")
endfunction()


function(chc_target_gbench target)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")

  set(options_keywords MAIN LOG)
  set(one_value_keywords RUN LOG_PATH LOG_DIR)
  set(multi_value_keywords)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/cpm.cmake")
  chc_cpm_gbench()
  target_link_libraries(${name} PRIVATE
    benchmark::benchmark
    $<$<BOOL:${arg_MAIN}>:benchmark::benchmark_main>
  )

  if(NOT "${arg_RUN}" STREQUAL "" OR "${arg_KEYWORDS_MISSING_VALUES}" MATCHES "RUN")
    chc_set_if(arg_RUN EMPTY THEN "${target}-bench")

    set(benchmark_out_cmd "")
    if(arg_LOG OR NOT "${arg_LOG_PATH}" STREQUAL "")
      chc_set_if(arg_LOG_PATH EMPTY THEN "${CMAKE_CURRENT_BINARY_DIR}")
      string(TIMESTAMP timestamp)
      set(log_file_name "${arg_RUN}_log_${timestamp}.txt")
      set(benchmark_out_cmd "${arg_LOG_PATH}/${log_file_name}")
    endif()
    chc_set_if(arg_LOG_PATH NOT EMPTY SET benchmark_out_cmd)
    if(NOT "${benchmark_out_cmd}" STREQUAL "")
      set(benchmark_out_cmd "--benchmark_out=${benchmark_out_cmd}")
    endif()

    add_custom_target(${arg_RUN}
      "$<TARGET_FILE:${target}>" --benchmark_out_format=console --benchmark_counters_tabular=true ${benchmark_out_cmd}
      WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
      COMMAND_EXPAND_LISTS
      VERBATIM
      USES_TERMINAL
    )
    add_dependencies(${arg_RUN} ${target})
  endif()
endfunction()


function(chc_target_itlib target)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/cpm.cmake")
  chc_cpm_itlib()
  target_link_libraries(${name} PRIVATE
    itlib::itlib
  )
endfunction()


function(chc_target_range_v3 target)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/cpm.cmake")
  chc_cpm_range_v3()
  target_link_libraries(${name} PRIVATE
    range-v3::range-v3
  )
endfunction()


function(chc_target_boost target)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")

  set(options_keywords)
  set(one_value_keywords VERSION)
  set(multi_value_keywords LINK PUBLIC)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  chc_set_if(arg_VERSION EMPTY THEN BOOST_VERSION HEAD)

  set(BOOST_INCLUDE_LIBRARIES ${arg_LINK} ${arg_PUBLIC})
  chc_assert_not_str_empty(BOOST_INCLUDE_LIBRARIES)
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/cpm.cmake")
  chc_cpm_boost(${BOOST_INCLUDE_LIBRARIES})

  foreach(i IN LISTS arg_LINK)
    target_link_libraries(${target} PRIVATE Boost::${i})
  endforeach()

  foreach(i IN LISTS arg_PUBLIC)
    target_link_libraries(${target} PUBLIC Boost::${i})
  endforeach()
endfunction()


function(chc_target_qt target #[[source ...]])
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/utils.cmake")
  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/private.cmake")

  set(options_keywords)
  set(one_value_keywords TYPE)
  set(multi_value_keywords LIBS UIC MOC)
  cmake_parse_arguments(PARSE_ARGV 1 arg "${options_keywords}" "${one_value_keywords}" "${multi_value_keywords}")

  chc_assert_not_str_empty(arg_TYPE)

  set(sources "${arg_UNPARSED_ARGUMENTS}")
  chc_assert_not_str_empty(sources)

  if("${arg_TYPE}" STREQUAL "EXECUTABLE")
    cmake_language(CALL qt${Qt_VERSION}_add_executable ${target} "${sources}")

  elseif("${arg_TYPE}" STREQUAL "LIBRARY")
    set(type STATIC)
    if(BUILD_SHARED_LIBS)
      set(type SHARED)
    endif()
    cmake_language(CALL qt${Qt_VERSION}_add_library ${target} ${type} "${sources}")

  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}. Unspecified type target. Type: ${arg_TYPE}")
  endif()

  chc_target_common(${target} "${ARGN}")

  target_compile_definitions(${target} PRIVATE
    QT_USE_QSTRINGBUILDER
  )

  chc_assert_not_str_empty(arg_LIBS)
  find_package(Qt${Qt_VERSION} COMPONENTS ${arg_LIBS} REQUIRED)
  list(TRANSFORM arg_LIBS PREPEND Qt${Qt_VERSION}::)
  target_link_libraries(${target} PRIVATE ${arg_LIBS})

  chcaux_uic_resolve(${target} "${arg_UIC}")
  chcaux_moc_cpp(${target} "${arg_MOC}")
endfunction()


function(chc_san_common out_var suffix fn_gen #[[sanitizers = ${PROJECT_NAME}_SANITIZERS]])
  unset(${out_var})
  macro(asan)
    target_compile_options(${name} PRIVATE
      -fsanitize=address
      -fno-common
      -fno-omit-frame-pointer
      -fsanitize-address-use-after-scope
    )
    target_link_options(${name} PRIVATE
      -fsanitize=address
    )
  endmacro()

  macro(tsan)
    target_compile_options(${name} PUBLIC
      -fsanitize=thread
    )
    target_link_options(${name} PUBLIC
      -fsanitize=thread
    )
  endmacro()

  macro(msan)
    target_compile_options(${name} PRIVATE
      -fsanitize=memory
      -fsanitize-memory-track-origins
      -fno-omit-frame-pointer
      -fno-optimize-sibling-calls
    )
    target_link_options(${name} PRIVATE
      -fsanitize=memory
    )
  endmacro()

  macro(usan)
    target_compile_options(${name} PRIVATE
      -fsanitize=undefined
      $<$<COMPILE_LANG_AND_ID:CXX,Clang>:
      -fsanitize=integer
      -fsanitize=nullability
      >
    )
    target_link_options(${name} PRIVATE
      -fsanitize=undefined
      -lubsan
      $<$<COMPILE_LANG_AND_ID:CXX,Clang>:
      -fsanitize=integer
      -fsanitize=nullability
      >
    )
  endmacro()

  macro(lsan)
    target_compile_options(${name} PUBLIC
      -fsanitize=leak
    )
    target_link_options(${name} PUBLIC
      -fsanitize=leak
    )
  endmacro()

  if(${ARGC} GREATER 3)
    set(SANITIZERS ${ARGV3})
  else()
    chc_head_variable(SANITIZERS)
  endif()

  foreach(i IN LISTS SANITIZERS)
    if("${i}" STREQUAL "address")
      set(name ${suffix}-asan)
      cmake_language(CALL ${fn_gen} ${name})
      asan()
      list(APPEND ${out_var} ${name})
    endif()

    if("${i}" STREQUAL "mem")
      if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
        message(STATUS "Memory sanitizer disabled.")
      else()
        set(name ${suffix}-msan)
        cmake_language(CALL ${fn_gen} ${name})
        msan()
        list(APPEND ${out_var} ${name})
      endif()
    endif()

    if("${i}" STREQUAL "thread")
      set(name ${suffix}-tsan)
      cmake_language(CALL ${fn_gen} ${name})
      tsan()
      list(APPEND ${out_var} ${name})
    endif()

    if("${i}" STREQUAL "leak")
      set(name ${suffix}-lsan)
      cmake_language(CALL ${fn_gen} ${name})
      lsan()
      list(APPEND ${out_var} ${name})
    endif()

    if("${i}" STREQUAL "ub")
      set(name ${suffix}-ubsan)
      cmake_language(CALL ${fn_gen} ${name})
      usan()
      list(APPEND ${out_var} ${name})
    endif()
  endforeach()

  set(${out_var} ${${out_var}} PARENT_SCOPE)
endfunction()


function(collect_targets target scope) # TODO use chc_defer
  chcaux_head_check()
  set(scope_var ${PROJECT_NAME}_${CMAKE_CURRENT_FUNCTION}_${scope})

  set(callback_fn_var ${PROJECT_NAME}_${CMAKE_CURRENT_FUNCTION}_${scope}_callback)
  set(build_all_var ${PROJECT_NAME_SHORT}-build_all_${scope})
  if(NOT TARGET ${build_all_var})
    add_custom_target(${build_all_var})

    function(${callback_fn_var} scope scope_var build_all_var)
      unset(args)
      foreach(i IN LISTS ${scope_var})
        set(args "${args} COMMAND \"$<TARGET_FILE:${i}>\"")
      endforeach()
      set(run_all_var ${PROJECT_NAME}_run_all_${scope})
      cmake_language(EVAL CODE "add_custom_target(${run_all_var} USES_TERMINAL ${args})")
      add_dependencies(${run_all_var} ${build_all_var})
    endfunction()
    cmake_language(EVAL CODE "cmake_language(DEFER DIRECTORY \"${PROJECT_SOURCE_DIR}\" CALL ${callback_fn_var} ${scope} ${scope_var} ${build_all_var})")
  endif()

  add_dependencies(${build_all_var} ${target})
  list(APPEND ${scope_var} ${target})
  set(${scope_var} "${${scope_var}}" CACHE INTERNAL "")
endfunction()