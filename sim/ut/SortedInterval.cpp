// #include <boost/container/flat_set.hpp>

#include <gmock/gmock-matchers.h>
#include <gtest/gtest.h>

#include <sim/SortedInterval.hpp>


using namespace ::testing;
using namespace sim;


TEST(SortedInterval, smoke) {
  SortedInterval<int /*, boost::container::flat_set*/> sorted_interval;
  {
    decltype(sorted_interval)::container_type::const_iterator it;
    ASSERT_NO_THROW(it = sorted_interval.emplace(std::pair{1, 1}));
    ASSERT_EQ(*it, (std::pair{1, 1}));
  }
  ASSERT_EQ(sorted_interval.size(), 1);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 1}));

  ASSERT_NO_THROW(sorted_interval.emplace(std::pair{1, 1}));
  ASSERT_EQ(sorted_interval.size(), 1);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 1}));

  ASSERT_NO_THROW(sorted_interval.emplace(std::pair{2, 2}));
  ASSERT_EQ(sorted_interval.size(), 2);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(sorted_interval.contains(std::pair{2, 2}));

  ASSERT_NO_THROW(sorted_interval.emplace(std::pair{2, 3}));
  ASSERT_EQ(sorted_interval.size(), 2);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(sorted_interval.contains(std::pair{2, 3}));

  ASSERT_NO_THROW(sorted_interval.emplace(std::pair{1, 2}));
  ASSERT_EQ(sorted_interval.size(), 1);
  ASSERT_TRUE(sorted_interval.contains(std::pair{1, 3}));

  sorted_interval.clear();
  ASSERT_EQ(sorted_interval.size(), 0);
}
