chc_target_auto_name()

add_executable(${name}
  smoke.cpp
)

target_link_libraries(${name} PRIVATE
  ${PROJECT_NAME_SHORT}
)

chc_target_common(${name})
chc_target_gtest(${name} MAIN)
