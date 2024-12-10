chc_target_auto_name()

add_executable(${name}
  smoke.cpp
)

chc_target_common(${name})
chc_target_gtest(${name} MAIN)
