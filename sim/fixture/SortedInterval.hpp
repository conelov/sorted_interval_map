#pragma once


namespace sim::fix {


template<typename SortedInterval_>
class SortedInterval {
public:
  virtual ~SortedInterval() = default;

protected:
  virtual void pre_iteration() {
    sorted_interval.clear();
  }

protected:
  SortedInterval_ sorted_interval;
};


}// namespace sim::rer