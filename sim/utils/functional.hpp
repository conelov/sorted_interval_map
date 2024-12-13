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


#define SIM_INVOKER_AS_LAMBDA(fn, ...) [__VA_ARGS__](auto&&... args) noexcept(noexcept(fn(std::forward<decltype(args)>(args)...))) -> decltype(auto) { \
  return fn(std::forward<decltype(args)>(args)...);                                                                                                   \
}


#define SIM_MEM_FN_LAMBDA(mem, ...) [__VA_ARGS__](auto&& arg) noexcept(noexcept(std::forward<decltype(arg)>(arg) mem)) -> decltype(auto) { \
  return std::forward<decltype(arg)>(arg) mem;                                                                                            \
}


#define SIM_WRAP_IN_LAMBDA(expr, ...) [__VA_ARGS__](auto&&...) noexcept(noexcept(expr)) -> decltype(auto) { \
  do {                                                                                                     \
    expr;                                                                                                  \
  } while (false);                                                                                         \
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


}