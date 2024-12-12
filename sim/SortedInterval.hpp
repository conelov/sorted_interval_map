#pragma once

#include <algorithm>
#include <cassert>
#include <functional>
#include <set>
#include <utility>


namespace sim {


template<
  typename V_,
  template<typename> class Pred_                          = std::less,
  template<typename, typename, typename> class Container_ = std::set,
  template<typename> class Allocator_                     = std::allocator,
  template<typename, typename> class Aggregator_          = std::pair>
class SortedInterval final {
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
  };

public:
  using container_type = Container_<interval_type, IntervalComparator, allocator_type>;

public:
  constexpr explicit SortedInterval(auto&&... args)
      : ranges_{std::forward<decltype(args)>(args)...} {
  }


  /// @complexity n
  constexpr typename container_type::const_iterator emplace(auto&& interval) {
    auto& [start, end] = interval;
    auto it            = ranges_.lower_bound(start);
    if (it != ranges_.begin() && std::prev(it)->second >= start) {
      --it;
    }

    while (it != ranges_.end() && it->first <= end) {
      start = std::min(start, it->first);
      end   = std::max(end, it->second);
      it    = ranges_.erase(it);
    }

    auto const [out, f] = ranges_.emplace(std::forward<decltype(interval)>(interval));
    assert(f);
    return out;
  }


  constexpr void clear() {
    ranges_.clear();
  }


  /// @complexity log n
  [[nodiscard]] constexpr typename container_type::const_iterator find(auto&& key) const {
    static_assert(std::is_same_v<std::remove_cvref_t<decltype(key)>, interval_type>);
    if (auto const it = ranges_.find(std::forward<decltype(key)>(key)); it != ranges_.cend()) {
      return it;
    }
    return ranges_.cend();
  }

  /// @complexity log n
  [[nodiscard]] constexpr bool contains(auto&& interval) const {
    return find(std::forward<decltype(interval)>(interval)) != ranges_.cend();
  }


  [[nodiscard]] constexpr std::size_t size() const {
    return ranges_.size();
  }


  [[nodiscard]] constexpr bool empty() const {
    return ranges_.empty();
  }


  /// @complexity n
  [[nodiscard]] constexpr bool operator==(const SortedInterval& other) const {
    return std::ranges::equal(ranges_, other.ranges_);
  }


  auto begin() const {
    return ranges_.cbegin();
  }


  auto end() const {
    return ranges_.cend();
  }

private:
  container_type ranges_;
};


}// namespace sim
