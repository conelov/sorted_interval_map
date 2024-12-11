#pragma once

#include <unordered_map>

#include <sim/SortedInterval.hpp>


namespace sim {


template<
  typename K_,
  typename V_,
  typename Comparator_,
  template<typename, typename> class VAggregator_ = std::pair>
class SortedIntervalMap {
public:
  using K           = K_;
  using V           = V_;
  using Comparator  = Comparator_;
  using VAggregator = VAggregator_;
};


}// namespace sim
