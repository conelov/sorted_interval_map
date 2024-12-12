include("${PROJECT_SOURCE_DIR}/cmake/target.cmake")

chc_target_auto_name()

add_library(${name}
  SortedInterval.hpp
  SortedIntervalMap.hpp
)

chc_target_common(${name})


chc_head_variable(RESEARCH)
if(RESEARCH)
  add_subdirectory(research)
endif()

if(BUILD_TESTING)
  add_subdirectory(ut)
endif()
