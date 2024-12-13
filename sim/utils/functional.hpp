//
// Created by dym on 12.01.23.
//

#pragma once

#include <functional>
#include <utility>


// https://stackoverflow.com/a/66642898
/// warn: valid for clans only
#define DO_PRAGMA(x) _Pragma(#x)
#define NOWARN(warnoption, ...)                   \
  DO_PRAGMA(clang diagnostic push)                \
  DO_PRAGMA(clang diagnostic ignored #warnoption) \
  __VA_ARGS__                                     \
  DO_PRAGMA(clang diagnostic pop)


#define SIM_MEM_FN_LAMBDA(mem, ...) [__VA_ARGS__](auto&& arg) noexcept(noexcept(std::declval<std::remove_cvref_t<std::remove_pointer_t<decltype(arg)>>>().mem)) -> decltype(auto) { \
  if constexpr (std::is_pointer_v<decltype(arg)>) {                                                                                                                                 \
    return std::forward<decltype(arg)>(arg)->mem;                                                                                                                                   \
  } else {                                                                                                                                                                          \
    return std::forward<decltype(arg)>(arg).mem;                                                                                                                                    \
  }                                                                                                                                                                                 \
}


#define SIM_WRAP_IN_LAMBDA(expr, ...) [__VA_ARGS__](auto&&...) constexpr noexcept(noexcept(expr)) -> void { \
  do {                                                                                                      \
    expr;                                                                                                   \
  } while (false);                                                                                          \
}


#define SIM_WRAP_IN_LAMBDA_R(expr, ...) [__VA_ARGS__](auto&&...) constexpr noexcept(noexcept(expr)) -> decltype(auto) { \
  do {                                                                                                                  \
    return expr;                                                                                                        \
  } while (false);                                                                                                      \
}


namespace sim {


template<typename F>
[[nodiscard]] constexpr auto finally(F&& f) noexcept {
  class Sentry final {
  public:
    constexpr ~Sentry() noexcept {
      if (!spent_) {
        std::move(f_)();
      }
    }

    constexpr explicit Sentry(F&& in) noexcept
        : f_{std::move(in)} {
    }

    constexpr Sentry(Sentry&& in) noexcept
        : f_{std::move(in.f_)} {
      in.spent_ = true;
    }

    constexpr Sentry(Sentry const&) noexcept = delete;

  private:
    F    f_;
    bool spent_ = false;
  };

  return Sentry{std::forward<F>(f)};
}


}// namespace sim