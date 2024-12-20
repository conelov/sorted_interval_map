#ifdef SIM_RESEARCH
  #include <deque>
  #include <vector>

  #include <itlib/flat_set.hpp>
#endif

#include <gtest/gtest.h>

#include <sim/SortedInterval.hpp>

#include <sim/fixture/SortedInterval.hpp>


template<typename SortedInterval_>
class SortedInterval
    : public ::testing::Test
    , public sim::fix::SortedInterval<SortedInterval_> {
protected:
  void SetUp() override {
    this->pre_iterations();
  }
};


// clang-format off
using Types = ::testing::Types<
  sim::SortedInterval<int, std::less, std::set, std::allocator, std::pair, sim::SortedIntervalImplType::trivial>,
  sim::SortedInterval<int, std::less, std::set, std::allocator, std::pair, sim::SortedIntervalImplType::optimized_erase>
#ifdef SIM_RESEARCH
  , sim::SortedInterval<int, std::less, itlib::flat_set, std::vector, std::pair, sim::SortedIntervalImplType::trivial>
  , sim::SortedInterval<int, std::less, itlib::flat_set, std::deque, std::pair, sim::SortedIntervalImplType::trivial>
#endif
>;
// clang-format on

TYPED_TEST_SUITE(SortedInterval, Types);


TYPED_TEST(SortedInterval, smoke) {
  {
    typename decltype(this->sorted_interval)::container_type::const_iterator it;
    it = this->sorted_interval.emplace(std::pair{1, 1});
    ASSERT_EQ(*it, (std::pair{1, 1}));
  }
  ASSERT_EQ(this->sorted_interval.size(), 1);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));

  this->sorted_interval.emplace(std::pair{1, 1});
  ASSERT_EQ(this->sorted_interval.size(), 1);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));

  this->sorted_interval.emplace(std::pair{2, 2});
  ASSERT_EQ(this->sorted_interval.size(), 2);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{2, 2}));

  this->sorted_interval.emplace(std::pair{2, 3});
  ASSERT_EQ(this->sorted_interval.size(), 2);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 1}));
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{2, 3}));

  this->sorted_interval.emplace(std::pair{1, 2});
  ASSERT_EQ(this->sorted_interval.size(), 1);
  ASSERT_TRUE(this->sorted_interval.contains(std::pair{1, 3}));

  this->sorted_interval.clear();
  ASSERT_EQ(this->sorted_interval.size(), 0);
}
