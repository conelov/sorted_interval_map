#include <gmock/gmock-matchers.h>
#include <gtest/gtest.h>

#include <sim/SortedIntervalMap.hpp>


using namespace ::testing;
using namespace sim;


TEST(SortedIntervalMap, smoke) {
  SortedIntervalMap<std::size_t, int> map;
  using Pair = decltype(map)::sorted_interval_type::interval_type;
  {
    auto const sorted_interval_it = map.emplace(0, Pair{0, 0});
    ASSERT_EQ(map.size(), 1);
    ASSERT_EQ(*sorted_interval_it, (Pair{0, 0}));
  }
  {
    auto const sorted_interval_it = map.emplace(0, Pair{0, 1});
    ASSERT_EQ(map.size(), 1);
    ASSERT_EQ(*sorted_interval_it, (Pair{0, 1}));
  }
  {
    auto const sorted_interval_it = map.emplace(0, Pair{0, 1});
    ASSERT_EQ(map.size(), 1);
    ASSERT_EQ(*sorted_interval_it, (Pair{0, 1}));
  }
  {
    auto const sorted_interval_it = map.emplace(0, Pair{-1, 0});
    ASSERT_EQ(map.size(), 1);
    ASSERT_EQ(*sorted_interval_it, (Pair{-1, 1}));
  }
  {
    auto const sorted_interval_it = map.emplace(1, Pair{0, 0});
    ASSERT_EQ(map.size(), 2);
    ASSERT_EQ(*sorted_interval_it, (Pair{0, 0}));
  }
}
