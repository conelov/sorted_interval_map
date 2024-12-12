chc_target_auto_name()


add_library(${name}
  SortedInterval.hpp
)

chc_target_common(${name})
chc_target_itlib(${name})

target_link_libraries(${name} PUBLIC
  itlib::itlib
#  ${PROJECT_NAME_SHORT}
)

target_compile_definitions(${name} PUBLIC
  ${PROJECT_NAME_SHORT_UP}_RESEARCH
)
