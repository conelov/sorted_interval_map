chc_target_auto_name()

add_executable(${name}
  SortedInterval.cpp
  SortedIntervalMap.cpp
)

chc_head_variable(RESEARCH)
target_link_libraries(${name} PRIVATE
  ${PROJECT_NAME_SHORT}
  ${PROJECT_NAME_SHORT}-fixture
  $<$<BOOL:${RESEARCH}>:${PROJECT_NAME_SHORT}-research>
)

chc_target_common(${name})
chc_target_gtest(${name} GMOCK_MAIN)
