//
// Created by dym on 05.11.24.
//

#pragma once

#include <algorithm>
#include <functional>
#include <limits>
#include <optional>
#include <ranges>
#include <type_traits>


namespace sim {


/// https://en.cppreference.com/w/cpp/utility/intcmp
template<class T, class U>
constexpr bool cmp_equal(T t, U u) noexcept {
  using UT = std::make_unsigned_t<T>;
  using UU = std::make_unsigned_t<U>;
  if constexpr (std::is_signed_v<T> == std::is_signed_v<U>)
    return t == u;
  else if constexpr (std::is_signed_v<T>)
    return t < 0 ? false : UT(t) == u;
  else
    return u < 0 ? false : t == UU(u);
}

template<class T, class U>
constexpr bool cmp_not_equal(T t, U u) noexcept {
  return !cmp_equal(t, u);
}

template<class T, class U>
constexpr bool cmp_less(T t, U u) noexcept {
  using UT = std::make_unsigned_t<T>;
  using UU = std::make_unsigned_t<U>;
  if constexpr (std::is_signed_v<T> == std::is_signed_v<U>)
    return t < u;
  else if constexpr (std::is_signed_v<T>)
    return t < 0 ? true : UT(t) < u;
  else
    return u < 0 ? false : t < UU(u);
}

template<class T, class U>
constexpr bool cmp_greater(T t, U u) noexcept {
  return cmp_less(u, t);
}

template<class T, class U>
constexpr bool cmp_less_equal(T t, U u) noexcept {
  return !cmp_greater(t, u);
}

template<class T, class U>
constexpr bool cmp_greater_equal(T t, U u) noexcept {
  return !cmp_less(t, u);
}

/// https://en.cppreference.com/w/cpp/utility/in_range
template<class Min, class Max, class T>
constexpr bool in_range(T t, Min min, Max max) noexcept {
  return cmp_greater_equal(t, min) && cmp_less_equal(t, max);
}

template<class R, class T>
constexpr bool in_range(T t) noexcept {
  return in_range(t, std::numeric_limits<R>::min(), std::numeric_limits<R>::max());
}


template<typename U, typename T>
requires std::is_integral_v<T> && std::is_integral_v<U>
[[nodiscard]] [[deprecated("unsafe")]] auto val_map(T x, U out_min = std::numeric_limits<U>::min(), U out_max = std::numeric_limits<U>::max(), T in_min = std::numeric_limits<T>::min(), T in_max = std::numeric_limits<T>::max()) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


// https://chatgpt.com/share/672a5fb0-46cc-8009-a872-da963d440f88
template<typename T, typename Operation>
requires std::is_integral_v<T>
[[nodiscard]] std::optional<T> safe_arithmetic(T a, T b, Operation op) noexcept {
  if constexpr (std::is_same_v<Operation, std::plus<>>) {
    if ((b > 0 && a > std::numeric_limits<T>::max() - b)
      || (b < 0 && a < std::numeric_limits<T>::min() - b)) {
      return std::nullopt;
    }
  } else if constexpr (std::is_same_v<Operation, std::minus<>>) {
    if ((b < 0 && a > std::numeric_limits<T>::max() + b) || (b > 0 && a < std::numeric_limits<T>::min() + b)) {
      return std::nullopt;
    }
  } else if constexpr (std::is_same_v<Operation, std::multiplies<>>) {
    if (a != 0 && b != 0) {
      if ((a > 0 && b > 0 && a > std::numeric_limits<T>::max() / b)
        || (a < 0 && b < 0 && a < std::numeric_limits<T>::max() / b)
        || (a > 0 && b < 0 && b < std::numeric_limits<T>::min() / a)
        || (a < 0 && b > 0 && a < std::numeric_limits<T>::min() / b)) {
        return std::nullopt;
      }
    }
  } else if constexpr (std::is_same_v<Operation, std::divides<>>) {
    if (b == 0 || (a == std::numeric_limits<T>::min() && b == -1)) {
      return std::nullopt;
    }
  } else {
    static_assert(std::is_void_v<Operation>);
  }

  return op(a, b);
}


// https://chatgpt.com/share/672a8927-8a18-8009-a1fa-8c61dbddc4c3
auto merge_intervals(auto& a, auto comparator, auto first, auto second) {
  if (a.empty()) {
    return a.end();
  }

  // Сортируем интервалы по началу, а если начала совпадают — по концу
  std::ranges::sort(a, comparator);

  std::size_t index = 0;// индекс для записи объединённых интервалов
  for (std::size_t i = 1; i < a.size(); ++i) {
    // Если текущий интервал пересекается с последним записанным интервалом
    if (second(a[index]) >= first(a[i])) {
      // Объединяем интервалы
      second(a[index]) = std::max(second(a[index]), second(a[i]));
    } else {
      // Переходим к следующему интервалу и записываем его на позицию index + 1
      ++index;
      a[index] = a[i];
    }
  }

  // Возвращаем итератор на позицию сразу после последнего объединённого интервала
  return std::next(a.begin(), index + 1);
}

auto merge_intervals(auto& a, auto comparator) {
  return merge_intervals(a, comparator, std::mem_fn(&std::remove_cvref_t<decltype(a[0])>::first), std::mem_fn(&std::remove_cvref_t<decltype(a[0])>::second));
}

auto merge_intervals(auto& a) {
  return merge_intervals(a, std::less{});
}


}