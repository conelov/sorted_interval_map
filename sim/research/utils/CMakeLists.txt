chc_target_auto_name()

add_library(${name}
  IterativeAverage.hpp
  IterationRate.hpp
  Singleton.hpp
  random.hpp
)

target_link_libraries(${name} PUBLIC
  ${PROJECT_NAME_SHORT}-utils
)

chc_target_common(${name})
