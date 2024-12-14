#include <chrono>
#include <deque>
#include <ranges>
#include <thread>
#include <vector>

#include <benchmark/benchmark.h>

#include <itlib/flat_set.hpp>

#include <sim/SortedInterval.hpp>

#include <sim/utils/functional.hpp>
#include <sim/utils/numeric.hpp>

#include <sim/research/utils/IterationRate.hpp>
#include <sim/research/utils/IterativeAverage.hpp>
#include <sim/research/utils/MxGuarded.hpp>
#include <sim/research/utils/random.hpp>


namespace {


auto constexpr min_iterations = 1000u;
std::size_t constexpr n_cpu   = SIM_NCPU;


using namespace sim;


template<typename Interval_>
class SortedIntervalBench : public benchmark::Fixture {
public:
  void SetUp(benchmark::State& state) override {
    if (state.thread_index() != 0) {
      return;
    }
    state.counters["ist"] = counts_ = state.range(0);
  }


  void entered() {
    ctxs_.modify(SIM_MEM_FN_LAMBDA(operator[](std::this_thread::get_id())));
  }


  void pre_iteration() {
  }


  void iteration(benchmark::State& state) {
    auto& [sorted_interval, rate, metric] = ctxs_.raw().at(std::this_thread::get_id());
    using interval_type                   = typename Interval_::interval_type;
    using interval_value_type             = typename Interval_::interval_value_type;

    std::vector<interval_type> rand_intervals;
    rand_intervals.reserve(counts_);
    std::ranges::generate_n(std::back_inserter(rand_intervals), counts_, [] {
      auto constexpr max           = std::numeric_limits<interval_value_type>::max();
      auto constexpr min           = std::numeric_limits<interval_value_type>::min();
      constexpr auto interval_size = 10;
      auto const     rand_val      = rer::RandomEngine<>::number(min + interval_size, max - interval_size);
      return interval_type{rand_val + interval_size, rand_val - interval_size};
    });

    rate.reset(min_iterations);
    for (auto i = 0uz; i < counts_; ++i) {
      auto interval = rand_intervals.back();
      if (interval.first > interval.second) {
        std::swap(interval.first, interval.second);
      }
      sorted_interval.emplace(std::move(interval));
      ++rate;
      rand_intervals.pop_back();
      metric.elements_count += sorted_interval.size();
    }

    rate.cut();
    metric.rate += rate.average();
  }


  void post_iteration() {
  }


  void exited() {
  }


  void TearDown(benchmark::State& state) override {
    if (state.thread_index() != 0) {
      return;
    }

    namespace rv      = std::views;
    auto metrics_view = ctxs_.raw() | rv::transform([](auto&& ctx) {
      return &ctx.second.metric;
    });

    Metric const metric = std::ranges::fold_left(metrics_view | rv::drop(1), Metric{**metrics_view.begin()}, [](auto&& acc, auto&& v) {
      acc.rate += v->rate;
      acc.elements_count += v->elements_count;
      return acc;
    });

    state.counters["it_time_ns"]     = metric.rate.average().count();
    state.counters["it_time_max_ns"] = metric.rate.min_max().max.count();
    state.counters["elements_n"]     = metric.elements_count.average();
    state.counters["elements_n_max"] = metric.elements_count.min_max().max;
  }

private:
  using ItRate = rer::IterationRate<std::nano>;

  struct Metric final {
    rer::IterativeAverage<ItRate::Duration> rate;
    rer::IterativeAverage<>                 elements_count;
  };


  struct ThreadContext final {
    Interval_ sorted_interval;
    ItRate    rate;
    Metric    metric;
  };

private:
  std::size_t                                                        counts_;
  rer::MxGuarded<std::unordered_map<std::thread::id, ThreadContext>> ctxs_;
};


using StdTrivial        = SortedInterval<std::int16_t, std::less, std::set, std::allocator, std::pair, SortedIntervalImplType::trivial>;
using StdOptimizedErase = SortedInterval<std::int16_t, std::less, std::set, std::allocator, std::pair, SortedIntervalImplType::optimized_erase>;
using Flat              = SortedInterval<std::int16_t, std::less, itlib::flat_set, std::vector, std::pair, SortedIntervalImplType::trivial>;
using FlatDeque         = sim::SortedInterval<int, std::less, itlib::flat_set, std::deque, std::pair, sim::SortedIntervalImplType::trivial>;


using StdTrivialBig        = SortedInterval<std::int32_t, std::less, std::set, std::allocator, std::pair, SortedIntervalImplType::trivial>;
using StdOptimizedEraseBig = SortedInterval<std::int32_t, std::less, std::set, std::allocator, std::pair, SortedIntervalImplType::optimized_erase>;
using FlatBig              = SortedInterval<std::int32_t, std::less, itlib::flat_set, std::vector, std::pair, SortedIntervalImplType::trivial>;
using FlatDequeBig         = sim::SortedInterval<int, std::less, itlib::flat_set, std::deque, std::pair, sim::SortedIntervalImplType::trivial>;


}// namespace


#define SIM_BENCH(name_type, ...)                                                                    \
  BENCHMARK_TEMPLATE_DEFINE_F(SortedIntervalBench, name_type, name_type)(benchmark::State & state) { \
    entered();                                                                                       \
    for (auto _ : state) {                                                                           \
      pre_iteration();                                                                               \
      iteration(state);                                                                              \
      post_iteration();                                                                              \
    }                                                                                                \
    exited();                                                                                        \
  }                                                                                                  \
  void generate_dependent_args_##name_type(benchmark::internal::Benchmark* b) {                      \
    for (auto const multi : {__VA_ARGS__}) {                                                         \
      b->Args({min_iterations * multi});                                                             \
    }                                                                                                \
  }                                                                                                  \
  BENCHMARK_REGISTER_F(SortedIntervalBench, name_type)                                               \
    ->Apply(generate_dependent_args_##name_type)                                                     \
    ->Unit(benchmark::kMillisecond)                                                                  \
    ->Threads(n_cpu)


SIM_BENCH(StdTrivial, 1, 100, 10'000);
SIM_BENCH(StdOptimizedErase, 1, 100, 10'000);
SIM_BENCH(Flat, 1, 10, 100);
SIM_BENCH(FlatDeque, 1, 10, 100);

SIM_BENCH(StdTrivialBig, 1, 100, 10'000);
SIM_BENCH(StdOptimizedEraseBig, 1, 100, 10'000);
SIM_BENCH(FlatBig, 1, 10, 100);
SIM_BENCH(FlatDequeBig, 1, 10, 100);
