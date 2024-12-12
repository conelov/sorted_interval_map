chc_target_auto_name()


add_library(${name}
  SortedInterval.hpp
)

chc_target_common(${name})

target_link_libraries(${name} PUBLIC
  ${PROJECT_NAME_SHORT}
)
