include("${PROJECT_SOURCE_DIR}/cmake/target.cmake")

chc_target_auto_name()

add_library(${name}
  SortedInterval.hpp
  SortedIntervalMap.hpp
)

chc_target_common(${name} UT)
#chc_target_boost(${name} LINK PUBLIC container)
