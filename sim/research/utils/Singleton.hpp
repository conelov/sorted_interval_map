//
// Created by dym on 01.10.22.
//

#pragma once

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <memory>

#include <sim/utils/functional.hpp>


namespace sim::rer {


enum class SingletonLivetimeMode : std::uint8_t {
  Global,
  ThreadLocal
};


namespace aux {


template<typename Singleton_, typename Derived_, SingletonLivetimeMode>
struct SingletonMem;


template<typename Singleton_, typename Derived_>
struct SingletonMem<Singleton_, Derived_, SingletonLivetimeMode::Global> {
  static inline Derived_* p_;

  // https://en.cppreference.com/w/cpp/memory/destroy_at
  // https://habr.com/ru/post/540954/
  static std::byte* memory() {
    alignas(Derived_) static std::byte mem_[sizeof(Derived_)];
    static auto                        destroy_sentry = finally(SIM_WRAP_IN_LAMBDA(Singleton_::destroy()));
    return mem_;
  }
};


template<typename Singleton_, typename Derived_>
struct SingletonMem<Singleton_, Derived_, SingletonLivetimeMode::ThreadLocal> {
  static thread_local inline Derived_* p_;

  static std::byte* memory() {
    alignas(Derived_) static thread_local std::byte mem_[sizeof(Derived_)];
    static thread_local auto                        destroy_sentry = finally(SIM_WRAP_IN_LAMBDA(Singleton_::destroy()));
    return mem_;
  }
};


}// namespace aux


template<typename Derived_, SingletonLivetimeMode LMode_ = SingletonLivetimeMode::ThreadLocal, bool auto_init_ = true>
class Singleton : private aux::SingletonMem<Singleton<Derived_, LMode_, auto_init_>, Derived_, LMode_> {
private:
  using Derived = Derived_;
  using Mem     = aux::SingletonMem<Singleton, Derived_, LMode_>;

public:
  static Derived* init(auto&&... args) {
    assert(!Mem::p_ && "Singleton has been initialized");
    Mem::p_ = new (Mem::memory()) Derived{std::forward<decltype(args)>(args)...};
    return instance();
  }


  [[nodiscard]] static Derived* instance() {
    if constexpr (auto_init_) {
      if (!Mem::p_) {
        init();
      }
    } else {
      assert(Mem::p_ && "Singleton not initialized");
    }
    return Mem::p_;
  }


  static void destroy() {
    if (Mem::p_) {
      Mem::p_->~Derived();
      Mem::p_ = nullptr;
    }
  }

protected:
  Singleton() noexcept = default;
};


}// namespace sim::rer