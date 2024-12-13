chc_target_auto_name()

chc_head_variable(SANITIZERS)
add_library(${name}
  IterativeAverage.hpp
  IterationRate.hpp
  Singleton.hpp
  random.hpp
  MxGuarded.hpp
  $<$<BOOL:"${SANITIZERS}">:src/san_report_breakpoints.cpp>
)

target_link_libraries(${name} PUBLIC
  ${PROJECT_NAME_SHORT}-utils
)

chc_target_common(${name})
