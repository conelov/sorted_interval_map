#pragma once


namespace sim {


template<typename K_, typename V_, template<typename, typename> class VAggregator_ = std::pair>
class SortedIntervalMap {
public:
  using K = K_;
  using V = V_;
  using VPair = VAggregator_<V, V>;

public:

};


}// namespace sim
