// #include <boost/container/flat_set.hpp>

#include <gmock/gmock-matchers.h>
#include <gtest/gtest.h>

#include <sim/SortedInterval.hpp>


using namespace ::testing;
using namespace sim;


TEST(SortedInterval, smoke) {
  SortedInterval<int /*, boost::container::flat_set*/> sorted_interval;
  ASSERT_TRUE(sorted_interval.emplace(std::pair{1, 1}).second);
  ASSERT_EQ(sorted_interval.size(), 1);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 1}));

  ASSERT_TRUE(sorted_interval.emplace(std::pair{2, 2}).second);
  ASSERT_EQ(sorted_interval.size(), 2);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(sorted_interval.contains(std::pair{2, 2}));

  ASSERT_TRUE(sorted_interval.emplace(std::pair{2, 3}).second);
  ASSERT_EQ(sorted_interval.size(), 2);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(sorted_interval.contains(std::pair{2, 3}));

  ASSERT_TRUE(sorted_interval.emplace(std::pair{1, 3}).second);
  ASSERT_EQ(sorted_interval.size(), 1);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 3}));

  ASSERT_TRUE(sorted_interval.emplace(std::pair{1, 10}).second);
  ASSERT_EQ(sorted_interval.size(), 1);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 10}));

  ASSERT_TRUE(sorted_interval.emplace(std::pair{-10, 10}).second);
  ASSERT_EQ(sorted_interval.size(), 1);
  ASSERT_TRUE(sorted_interval.contains(std::pair{-10, 10}));

  sorted_interval.clear();
  ASSERT_EQ(sorted_interval.size(), 0);
}
