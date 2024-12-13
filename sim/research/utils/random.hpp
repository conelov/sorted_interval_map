//
// Created by dym on 29.12.22.
//

#pragma once

#include <limits>
#include <random>
#include <ranges>
#include <type_traits>
#include <vector>

#include <sim/utils/numeric.hpp>

#include <sim/research/utils/Singleton.hpp>


namespace sim::rer {


template<typename RG_ = std::minstd_rand, SingletonLivetimeMode LMode_ = SingletonLivetimeMode::ThreadLocal>
class RandomEngine final : public Singleton<RandomEngine<RG_, LMode_>, LMode_> {
public:
  using RandomDevice = RG_;

public:
  RandomEngine(RandomEngine const&) = delete;
  RandomEngine(RandomEngine&&)      = delete;

  static RandomDevice& re() {
    return RandomEngine::instance()->re_;
  }


  template<typename T = int>
  requires std::numeric_limits<T>::is_specialized
  static T number(T min = std::numeric_limits<T>::min(), T max = std::numeric_limits<T>::max()) {
    return std::conditional_t<std::is_floating_point_v<T>, std::uniform_real_distribution<T>, std::uniform_int_distribution<T>>{min, max}(re());
  }

private:
  RandomEngine() = default;

private:
  RandomDevice re_{[]() -> std::uint64_t {
    if (std::random_device rd; rd.entropy() > 0) {
      return std::move(rd)();
    } else {
      return std::chrono::high_resolution_clock::now().time_since_epoch().count();
    }
  }()};

  friend Singleton<RandomEngine, LMode_>;
};


template<typename T_, typename Re_ = RandomEngine<>>
requires std::is_integral_v<T_> || std::is_floating_point_v<T_>
class Random final {
public:
  using value_type   = T_;
  using RandomEngine = Re_;
  using Range        = std::vector<std::pair<value_type, value_type>>;

public:
  Random()
      : Random(Range{{std::numeric_limits<value_type>::min(), std::numeric_limits<value_type>::max()}}) {
  }


  Random(Range a)
      : map_{merge_interval_(std::move(a))}
      , di_{calc_discrete_distribution(map_)} {
  }


  Random(auto... pairs)
  requires((std::is_same_v<typename decltype(pairs)::first_type, typename decltype(pairs)::second_type>) && ...)
      : Random{Range{pairs...}} {
  }


  template<typename T>
  requires std::is_integral_v<T> || std::is_floating_point_v<T>
  Random(T floor, T ceiling)
      : Random{std::pair{floor, ceiling}} {
  }


  [[nodiscard]] value_type get() {
    auto const [floor, ceil] = map_[di_(RandomEngine::re())];
    return RandomEngine::number(floor, ceil);
  }


  [[nodiscard]] operator value_type() {
    return get();
  }

private:
  using Distribution = std::discrete_distribution<>;

private:
  static Distribution calc_discrete_distribution(Range const& a) noexcept {
    auto rng = std::views::all(a | std::views::transform([count = std::accumulate(a.cbegin(), a.cend(), 0, [](auto accum, auto pair) {
      return accum + pair.second - pair.first;
    })](auto pair) {
      return (pair.second - pair.first) / static_cast<double>(count);
    }));
    return {rng.begin(), rng.end()};
  }


  static Range merge_interval_(Range a) {
    assert(std::all_of(a.cbegin(), a.cend(), [](auto const pair) {
      return pair.first <= pair.second;
    }) && "In one of the ranges floor > ceil.");
    a.erase(merge_intervals(a), a.cend());
    return std::move(a);
  }

private:
  Range const  map_;
  Distribution di_;
};

template<typename T>
Random(T, T) -> Random<T>;


template<typename T_, typename Re_ = RandomEngine<>>
class RandomPreviously final {
public:
  using RandomSource = Random<T_, Re_>;
  using value_type   = typename RandomSource::value_type;
  using RandomEngine = typename RandomSource::RandomEngine;
  using Ranges       = typename RandomSource::Range;

private:
  using Values = std::vector<value_type>;

public:
  RandomPreviously(std::size_t count, auto&&... args)
      : values_{[count, ... args = std::forward<decltype(args)>(args)] mutable -> Values {
        Values out;
        out.reserve(count);
        std::ranges::generate_n(std::back_inserter(out), count, [rd = RandomSource{std::move(args)...}] mutable {
          return rd.get();
        });
        return out;
      }()} {
  }


  [[nodiscard]] value_type get() noexcept {
    assert(!values_.empty());
    auto const out = values_.back();
    values_.pop_back();
    return out;
  }


  [[nodiscard]] operator value_type() noexcept {
    return get();
  }

private:
  Values values_;
};


}// namespace sim::rer