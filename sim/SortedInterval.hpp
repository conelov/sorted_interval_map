#pragma once

#include <algorithm>
#include <set>

#include <sim/aux/SortedIntervalImpl.hpp>


namespace sim {


template<
  typename V_,
  template<typename> class Pred_                          = std::less,
  template<typename, typename, typename> class Container_ = std::set,
  template<typename> class Allocator_                     = std::allocator,
  template<typename, typename> class Aggregator_          = std::pair,
  SortedIntervalImplType impl_type_                       = SortedIntervalImplType::optimized_erase>
class SortedInterval final : private sorted_interval_impl::SortedIntervalSetBased<impl_type_> {
public:
  using interval_value_type = V_;
  using interval_type       = Aggregator_<interval_value_type, interval_value_type>;
  using compare_type        = Pred_<interval_value_type>;
  using allocator_type      = Allocator_<interval_type>;

private:
  struct IntervalComparator {
    using is_transparent = void;

    constexpr bool operator()(interval_type const& lhs, interval_type const& rhs) const {
      return compare_type{}(lhs.first, rhs.first);
    }

    constexpr bool operator()(interval_type const& lhs, auto const& rhs) const {
      return compare_type{}(lhs.first, rhs);
    }


    constexpr bool operator()(auto const& lhs, interval_type const& rhs) const {
      return compare_type{}(lhs, rhs.first);
    }
  };

public:
  using container_type = Container_<interval_type, IntervalComparator, allocator_type>;

public:
  constexpr explicit SortedInterval(auto&&... args)
      : intervals_{std::forward<decltype(args)>(args)...} {
  }


  /// @complexity log n
  constexpr typename container_type::const_iterator emplace(auto&& in) {
    return static_cast<typename SortedInterval::ImplSame*>(this)->emplace_impl(intervals_, std::forward<decltype(in)>(in));
  }


  constexpr void clear() {
    intervals_.clear();
  }


  /// @complexity log n
  [[nodiscard]] constexpr typename container_type::const_iterator find(auto&& key) const {
    static_assert(std::is_same_v<std::remove_cvref_t<decltype(key)>, interval_type>);
    if (auto const it = intervals_.find(std::forward<decltype(key)>(key)); it != intervals_.cend()) {
      return it;
    }
    return intervals_.cend();
  }

  /// @complexity log n
  [[nodiscard]] constexpr bool contains(auto&& interval) const {
    return find(std::forward<decltype(interval)>(interval)) != intervals_.cend();
  }


  [[nodiscard]] constexpr std::size_t size() const {
    return intervals_.size();
  }


  [[nodiscard]] constexpr bool empty() const {
    return intervals_.empty();
  }


  /// @complexity n
  [[nodiscard]] constexpr bool operator==(const SortedInterval& other) const {
    return std::ranges::equal(intervals_, other.intervals_);
  }


  auto begin() const {
    return intervals_.cbegin();
  }


  auto end() const {
    return intervals_.cend();
  }

private:
  container_type intervals_;
};


}// namespace sim
