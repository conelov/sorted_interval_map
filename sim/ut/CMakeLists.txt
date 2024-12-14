chc_target_auto_name()

add_executable(${name}
  SortedInterval.cpp
  SortedIntervalMap.cpp
)

chc_head_variable(RESEARCH)
if(RESEARCH)
  chc_target_itlib(${name})
endif()

target_link_libraries(${name} PRIVATE
  ${PROJECT_NAME_SHORT}
  ${PROJECT_NAME_SHORT}-fixture
)

chc_head_variable(RESEARCH)
if(RESEARCH)
  target_compile_definitions(${name} PRIVATE
    ${PROJECT_NAME_SHORT_UP}_RESEARCH
  )
endif()

chc_target_common(${name})
chc_target_gtest(${name} MOCK_MAIN)
