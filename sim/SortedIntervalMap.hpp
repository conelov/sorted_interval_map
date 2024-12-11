#pragma once

#include <unordered_map>

#include <sim/SortedInterval.hpp>


namespace sim {


template<
  typename K_,
  typename V_,
  template<typename> class VPred_                                             = std::less,
  template<typename> class KHash_                                             = std::hash,
  template<typename> class KPred_                                             = std::equal_to,
  template<typename, typename, typename, typename, typename> class Container_ = std::unordered_map,
  template<typename, typename, typename> class SortedIntervalContainer_       = std::set,
  template<typename> class Allocator_                                         = std::allocator,
  template<typename, typename> class VAggregator_                             = std::pair>
class SortedIntervalMap final {
public:
  using sorted_interval_type = SortedInterval<V_, VPred_, SortedIntervalContainer_, Allocator_, VAggregator_>;
  using interval_type        = typename sorted_interval_type::interval_type;
  using key_type             = K_;
  using hasher               = KHash_<key_type>;
  using key_equal            = KPred_<key_type>;
  using allocator_type       = Allocator_<std::pair<key_type const, sorted_interval_type>>;
  using container_type       = Container_<key_type, sorted_interval_type, hasher, key_equal, allocator_type>;

public:
  explicit SortedIntervalMap(auto&&... args)
      : map_{std::forward<decltype(args)>(args)...} {
  }


  /// @complexity log n
  constexpr typename sorted_interval_type::container_type::const_iterator emplace(auto&& key, auto&& interval) {
    return map_[std::forward<decltype(key)>(key)].emplace(std::forward<decltype(interval)>(interval));
  }


  /// @complexity 1
  [[nodiscard]] sorted_interval_type const* get(auto&& key) const {
    if (auto const it = map_.find(std::forward<decltype(key)>(key)); it != map_.end()) {
      return &it->second;
    }
    return nullptr;
  }


  constexpr void clear() {
    map_.clear();
  }


  /// @complexity 1
  [[nodiscard]] constexpr bool contains(auto&& interval) const {
    return map_.contains(std::forward<decltype(interval)>(interval));
  }


  [[nodiscard]] constexpr std::size_t size() const {
    return map_.size();
  }


  [[nodiscard]] constexpr bool empty() const {
    return map_.empty();
  }


  /// @complexity n
  [[nodiscard]] constexpr bool operator==(const SortedIntervalMap& other) const {
    return std::ranges::equal(map_, other.map_);
  }


  auto begin() const {
    return map_.cbegin();
  }


  auto end() const {
    return map_.cend();
  }


private:
  container_type map_;
};


}// namespace sim
