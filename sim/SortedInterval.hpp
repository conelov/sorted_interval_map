#pragma once

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
  using value_type     = V_;
  using Aggregator     = Aggregator_<value_type, value_type>;
  using compare_type   = Pred_<value_type>;
  using allocator_type = Allocator_<Aggregator>;

private:
  struct IntervalComparator final {
    using is_transparent = void;

    constexpr bool operator()(Aggregator const& lhs, Aggregator const& rhs) const {
      return compare_type{}(lhs.first, rhs.first);
    }

    constexpr bool operator()(Aggregator const& lhs, auto&& rhs) const {
      return compare_type{}(lhs.first, rhs);
    }
  };

public:
  using Container = Container_<Aggregator, IntervalComparator, allocator_type>;

public:
  constexpr explicit SortedInterval(auto&&... args)
      : set_{std::forward<decltype(args)>(args)...} {
  }


  constexpr std::pair<typename Container::iterator, bool> emplace(auto&& interval) {
    auto [start, end] = std::as_const(interval);

    auto it = set_.lower_bound(start);
    if (it != set_.begin()) {
      --it;
    }

    while (it != set_.cend() && it->first <= end) {
      if (it->second < start) {
        ++it;
        continue;
      }

      start = std::min(start, it->first);
      end   = std::max(end, it->second);
      it    = set_.erase(it);
    }

    return set_.emplace(std::forward<decltype(interval)>(interval));
  }


  constexpr void clear() {
    set_.clear();
  }


  [[nodiscard]] constexpr bool contains(Aggregator&& interval) const {
    return set_.contains(std::forward<decltype(interval)>(interval));
  }


  [[nodiscard]] constexpr std::size_t size() const {
    return set_.size();
  }


  [[nodiscard]] constexpr bool empty() const {
    return set_.empty();
  }

private:
  Container set_;
};


}// namespace sim
