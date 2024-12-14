add_subdirectory(utils)


chc_target_auto_name()

function(sim_target_bench_gen name)
  add_executable(${name}
    SortedIntervalBench.cpp
  )

  chc_target_common(${name})
  chc_target_gbench(${name} MAIN RUN LOG_DIR "${PROJECT_SOURCE_DIR}/bench_logs")
  chc_target_itlib(${name})

  target_link_libraries(${name} PUBLIC
    ${PROJECT_NAME_SHORT}-research-utils
  )

  chc_cpu_count(ncpu)
  target_compile_definitions(${name} PUBLIC
    ${PROJECT_NAME_SHORT_UP}_RESEARCH
    ${PROJECT_NAME_SHORT_UP}_NCPU=${ncpu}
  )
endfunction()

sim_target_bench_gen(${name})

chc_head_variable(RESEARCH_GBENCH_SAN)
if(RESEARCH_GBENCH_SAN)
  chc_san_common(dummy ${name} sim_target_bench_gen)
endif()
