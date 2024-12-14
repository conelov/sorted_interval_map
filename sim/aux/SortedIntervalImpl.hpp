#pragma once

#include <cassert>
#include <cstdint>
#include <utility>


namespace sim {


enum class SortedIntervalImplType : std::uint8_t {
  trivial,
  optimized_erase,
};


namespace sorted_interval_impl {


template<typename T>
concept HaveExtractMethod = requires(T t) {
  { t.extract() };
};


template<SortedIntervalImplType implType>
struct SortedIntervalSetBased;


template<>
struct SortedIntervalSetBased<SortedIntervalImplType::trivial> {
  using ImplSame = SortedIntervalSetBased;


  constexpr auto emplace_impl(auto& intervals, auto&& in) {
    auto& [start, end] = in;
    assert(start <= end);
    auto it = intervals.lower_bound(start);
    if (it != intervals.begin() && std::prev(it)->second >= start) {
      --it;
    }

    while (it != intervals.end() && it->first <= end) {
      start = std::min(start, it->first);
      end   = std::max(end, it->second);
      it    = intervals.erase(it);
    }

    auto const [out, f] = intervals.emplace(std::forward<decltype(in)>(in));
    assert(f);
    return out;
  }
};


template<>
struct SortedIntervalSetBased<SortedIntervalImplType::optimized_erase> {
  using ImplSame = SortedIntervalSetBased;


  constexpr auto emplace_impl(auto& intervals, auto&& in) {
    auto& [new_low, new_high] = in;

    // Найти пересекающиеся интервалы
    auto it_low  = intervals.lower_bound(new_low); // Первый пересекающийся или следующий
    auto it_high = intervals.upper_bound(new_high);// Первый, не пересекающийся после

    if (it_low != intervals.begin() && std::prev(it_low)->second >= new_low) {
      --it_low;// Расширяем диапазон, если предыдущий пересекается
    }

    if (it_low == it_high) {
      return intervals.emplace(std::forward<decltype(in)>(in)).first;
    }

    // Извлекаем первый пересекающийся
    auto node = intervals.extract(std::exchange(it_low, std::next(it_low)));
    {
      auto const& [node_low, node_high] = node.value();
      new_low                           = std::min(new_low, node_low);
      new_high                          = std::max(new_high, node_high);
    }

    // Сливаем с остальными интервалами в диапазоне
    for (auto it = it_low; it != it_high; ++it) {
      new_low  = std::min(new_low, it->first);
      new_high = std::max(new_high, it->second);
    }

    // Удаляем оставшиеся пересекающиеся интервалы
    intervals.erase(it_low, it_high);

    // Обновляем извлечённый узел и вставляем его обратно
    node.value() = std::forward<decltype(in)>(in);
    return intervals.insert(std::move(node)).position;
  }
};


}// namespace aux
}// namespace sim