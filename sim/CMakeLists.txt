include("${PROJECT_SOURCE_DIR}/cmake/target.cmake")


add_subdirectory(utils)


chc_target_auto_name()

add_library(${name}
  SortedInterval.hpp aux/SortedIntervalImpl.hpp
  SortedIntervalMap.hpp
)

target_link_libraries(${name} PUBLIC
  ${PROJECT_NAME_SHORT}-utils
)


add_subdirectory(fixture)

chc_head_variable(RESEARCH)
if(RESEARCH)
  add_subdirectory(research)
endif()


chc_target_common(${name} UT)
