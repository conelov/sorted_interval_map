#pragma once

#include <chrono>
#include <utility>

#include <sim/research/utils/IterativeAverage.hpp>


namespace sim::rer {


template<typename Ratio_ = std::nano>
class IterationRate final {
public:
  using Clock    = std::chrono::steady_clock;
  using Ratio    = Ratio_;
  using Rep      = double;
  using Duration = std::chrono::duration<Rep, Ratio>;
  using Average  = IterativeAverage<Duration>;

public:
  IterationRate() = default;


  IterationRate(std::size_t resolution) {// NOLINT(*-pro-type-member-init, *-explicit-constructor)
    reset(resolution);
  }


  [[nodiscard]] std::size_t resolution() const noexcept {
    return resolution_;
  }


  void set_resolution(std::size_t resolution) noexcept {
    assert(ir_.empty());
    resolution_ = resolution;
  }


  Average const& average() const noexcept {
    return ir_;
  }


  Average const* operator->() const noexcept {
    return &average();
  }


  void iteration() noexcept {
    if (++iteration_counter_ < resolution_) {
      return;
    }
    cut();
  }


  void cut() noexcept {
    auto const start = std::exchange(time_prev_, Clock::now());
    if (iteration_counter_ == 0) {
      return;
    }
    assert(resolution_ > 0 && "not initialized");
    ir_ += (time_prev_ - start) * iteration_counter_ / static_cast<Rep>(resolution_);
    iteration_counter_ = 0;
  }


  void operator++() noexcept {
    iteration();
  }


  void operator++(int) noexcept {
    iteration();
  }


  void reset(std::size_t resolution) noexcept {
    assert(resolution > 0);
    ir_.reset();
    time_prev_         = Clock::now();
    resolution_        = resolution;
    iteration_counter_ = 0;
  }


  void reset() noexcept {
    reset(resolution_);
  }

private:
  Average           ir_;
  Clock::time_point time_prev_;
  std::size_t       resolution_        = 0;
  std::size_t       iteration_counter_ = 0;
};


}// namespace nut::aux