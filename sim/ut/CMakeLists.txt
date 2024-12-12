chc_target_auto_name()

add_executable(${name}
  SortedInterval.cpp
  SortedIntervalMap.cpp
)

target_link_libraries(${name} PRIVATE
  ${PROJECT_NAME_SHORT}
  ${PROJECT_NAME_SHORT}-fixture
)

chc_target_common(${name})
chc_target_gtest(${name} GMOCK_MAIN)
