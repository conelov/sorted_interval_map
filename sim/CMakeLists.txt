include("${PROJECT_SOURCE_DIR}/cmake/target.cmake")

chc_target_auto_name()

add_library(${name}
  sorted_interval_map.hpp
)

chc_target_common(${name} UT)
