add_subdirectory(utils)


chc_target_auto_name()

add_executable(${name}
  SortedIntervalBench.cpp
)

chc_target_common(${name})
chc_target_gbench(${name} MAIN)

target_link_libraries(${name} PUBLIC
  ${PROJECT_NAME_SHORT}-research-utils
)

chc_cpu_count(ncpu)
target_compile_definitions(${name} PUBLIC
  ${PROJECT_NAME_SHORT_UP}_RESEARCH
  ${PROJECT_NAME_SHORT_UP}_NCPU=${ncpu}
)
