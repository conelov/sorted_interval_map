#include <chrono>
#include <ranges>
#include <thread>
#include <vector>

#include <benchmark/benchmark.h>

#include <sim/SortedInterval.hpp>

#include <sim/utils/functional.hpp>

#include <sim/fixture/SortedInterval.hpp>

#include <sim/research/utils/IterationRate.hpp>
#include <sim/research/utils/IterativeAverage.hpp>
#include <sim/research/utils/MxGuarded.hpp>
#include <sim/research/utils/random.hpp>


namespace {


auto constexpr min_iterations = 1000uz;
std::size_t constexpr n_cpu   = SIM_NCPU;


using namespace sim;


template<typename Interval_>
class SortedIntervalBench : public benchmark::Fixture {
public:
  void SetUp(benchmark::State& state) override {
    state.counters["ist"] = counts_ = state.range(0);
  }


  void entered() {
    ctxs_.modify(SIM_MEM_FN_LAMBDA(operator[](std::this_thread::get_id())));
  }


  void pre_iteration() {
  }


  void iteration() {
    auto& [sorted_interval, rate, rate_total] = ctxs_.raw().at(std::this_thread::get_id());
    using RandomSource                        = rer::RandomPreviously<typename Interval_::interval_value_type>;
    RandomSource rg{counts_ * 2};
    rate.reset(min_iterations);

    for (auto i = 0uz; i < counts_; ++i) {
      auto interval = std::pair{rg.get(), rg.get()};
      if (interval.first > interval.second) {
        std::swap(interval.first, interval.second);
      }
      sorted_interval.emplace(std::move(interval));
      ++rate;
    }

    rate.cut();
    rate_total += rate.average();
  }


  void post_iteration() {
  }


  void exited() {
  }


  void TearDown(benchmark::State& st) override {
    namespace rv                   = std::views;
    auto       aves                = ctxs_.raw() | rv::transform(SIM_MEM_FN_LAMBDA(second.rate_total));
    auto const rate                = std::ranges::fold_left(aves | std::views::drop(1), *aves.begin(), [](auto&& acc, auto&& v) {
      return acc += v.average();
    });
    st.counters["rate_per_µs"]     = rate.average().count();
    st.counters["rate_max_per_µs"] = rate.min_max().max.count();
  }

private:
  struct ThreadContext final {
    Interval_                                       sorted_interval;
    rer::IterationRate<std::micro>                  rate;
    rer::IterativeAverage<decltype(rate)::Duration> rate_total;
  };

private:
  std::size_t                                                        counts_;
  rer::MxGuarded<std::unordered_map<std::thread::id, ThreadContext>> ctxs_;
};


void generate_dependent_args(benchmark::internal::Benchmark* b) {
  for (auto const its : {1'000, 10'000, 100'000}) {
    b->Args({its});
  }
}


using StdTrivial = SortedInterval<int, std::less, std::set, std::allocator, std::pair, SortedIntervalImplType::trivial>;


}// namespace


#define SIM_BENCH(name_type)                                                                         \
  BENCHMARK_TEMPLATE_DEFINE_F(SortedIntervalBench, name_type, name_type)(benchmark::State & state) { \
    entered();                                                                                       \
    for (auto _ : state) {                                                                           \
      pre_iteration();                                                                               \
      iteration();                                                                                   \
      post_iteration();                                                                              \
    }                                                                                                \
    exited();                                                                                        \
  }                                                                                                  \
  BENCHMARK_REGISTER_F(SortedIntervalBench, name_type)                                               \
    ->Apply(generate_dependent_args)                                                                 \
    ->Unit(benchmark::kMillisecond)                                                                  \
    ->Threads(n_cpu)


SIM_BENCH(StdTrivial);