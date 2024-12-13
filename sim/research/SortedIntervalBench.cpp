#include <chrono>
#include <mutex>
#include <thread>
#include <vector>

#include <benchmark/benchmark.h>

#include <sim/SortedInterval.hpp>

#include <sim/fixture/SortedInterval.hpp>

#include <sim/research/utils/IterationRate.hpp>
#include <sim/research/utils/IterativeAverage.hpp>
#include <sim/research/utils/random.hpp>


namespace {


auto constexpr min_iterations = 1000uz;


using namespace sim;


template<typename Interval_>
class SortedIntervalBench
    : public benchmark::Fixture
    , fix::SortedInterval<Interval_> {
public:
  void SetUp(benchmark::State& state) override {
    state.counters["ist"] = counts_ = state.range(0);
  }


  void TearDown(benchmark::State& st) override {
    // if (this->payloads().empty()) {
    //   return;
    // }
    // rer::IterativeAverage<std::chrono::duration<double, std::micro>> read_rate;
    // rer::IterativeAverage<std::chrono::duration<double, std::micro>> write_rate;
    // // for (auto const& p : this->payloads()) {
    // //   assert(p->type == aux::MultiThreadedRWFixturePayloadMixin::reader
    // //     || p->type == aux::MultiThreadedRWFixturePayloadMixin::writer);
    // //   (p->type == aux::MultiThreadedRWFixturePayloadMixin::reader ? read_rate : write_rate) += p->rate->average();
    // // }
    // st.counters["r_rate_per_µs"]     = read_rate.average().count();
    // st.counters["r_rate_max_per_µs"] = read_rate.min_max().max.count();
    // st.counters["w_rate_per_µs"]     = write_rate.average().count();
    // st.counters["w_rate_max_per_µs"] = write_rate.min_max().max.count();
  }


  void pre_iterations() override {
    {
      std::lock_guard const _{ctxs_mx_};
      ctxs_.emplace(std::this_thread::get_id(), counts_ / min_iterations);
    }
  }


  void iteration() {
    auto& [rate]       = ctxs_.at(std::this_thread::get_id());
    using RandomSource = rer::RandomPreviously<typename Interval_::interval_value_type>;
    RandomSource rg{counts_, typename RandomSource::Ranges{{0, (counts_ - 1) * 2}}};
    rate.reset();
    for (auto i = 0uz; i < counts_; ++i) {
      auto interval = std::pair{rg.get(), rg.get()};
      if (interval.first > interval.second) {
        std::swap(interval.first, interval.second);
      }
      this->sorted_interval.emplace(std::move(interval));
      ++rate;
    }
    rate.cut();
  }

private:
  struct ThreadContext final {
    rer::IterationRate<> rate;
  };

private:
  // ReSharper disable once CppUninitializedNonStaticDataMember
  std::size_t                                        counts_;
  std::unordered_map<std::thread::id, ThreadContext> ctxs_;
  std::mutex                                         ctxs_mx_;
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
    for (auto _ : state) {                                                                           \
      pre_iterations();                                                                              \
      iteration();                                                                                   \
    }                                                                                                \
  }                                                                                                  \
  BENCHMARK_REGISTER_F(SortedIntervalBench, name_type)                                               \
    ->Apply(generate_dependent_args)                                                                 \
    ->Unit(benchmark::kMillisecond)                                                                  \
    ->Threads(SIM_NCPU)


SIM_BENCH(StdTrivial);