#ifdef SIM_RESEARCH
  #include <itlib/flat_set.hpp>
#endif

#include <gmock/gmock-matchers.h>
#include <gtest/gtest.h>

#include <sim/SortedInterval.hpp>

#include <sim/fixture/SortedInterval.hpp>


template<typename SortedInterval_>
class SortedIntervalTest
    : public ::testing::Test
    , public sim::fix::SortedInterval<SortedInterval_> {
protected:
  void SetUp() override {
    this->pre_iteration();
  }
};


// clang-format off
using Types = ::testing::Types<
  sim::SortedInterval<int>
#ifdef SIM_RESEARCH
  , sim::SortedInterval<int, std::less, itlib::flat_set, std::vector>
#endif
>;
// clang-format on

TYPED_TEST_SUITE(SortedIntervalTest, Types);


TYPED_TEST(SortedIntervalTest, smoke) {
  {
    typename decltype(this->sorted_interval)::container_type::const_iterator it;
    ASSERT_NO_THROW(it = this->sorted_interval.emplace(std::pair{1, 1}));
    ASSERT_EQ(*it, (std::pair{1, 1}));
  }
  ASSERT_EQ(this->sorted_interval.size(), 1);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));

  ASSERT_NO_THROW(this->sorted_interval.emplace(std::pair{1, 1}));
  ASSERT_EQ(this->sorted_interval.size(), 1);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));

  ASSERT_NO_THROW(this->sorted_interval.emplace(std::pair{2, 2}));
  ASSERT_EQ(this->sorted_interval.size(), 2);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{2, 2}));

  ASSERT_NO_THROW(this->sorted_interval.emplace(std::pair{2, 3}));
  ASSERT_EQ(this->sorted_interval.size(), 2);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{2, 3}));

  ASSERT_NO_THROW(this->sorted_interval.emplace(std::pair{1, 2}));
  ASSERT_EQ(this->sorted_interval.size(), 1);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 3}));

  this->sorted_interval.clear();
  ASSERT_EQ(this->sorted_interval.size(), 0);
}
