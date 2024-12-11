chc_target_auto_name()

add_executable(${name}
  SortedInterval.cpp
)

target_link_libraries(${name} PRIVATE
  ${PROJECT_NAME_SHORT}
)

chc_target_common(${name})
chc_target_gtest(${name} GMOCK_MAIN)
