#pragma once

#include <functional>
#include <mutex>
#include <shared_mutex>


namespace sim::rer {


template<typename Mutex>
concept IsHaveLockShared = requires(Mutex m) {
  { m.lock_shared() };
};


template<typename T_, typename Mx_ = std::shared_mutex>
class MxGuarded {
public:
  using value_type = T_;
  using mutex_type = Mx_;

public:
  explicit MxGuarded(auto&&... args)
      : value_{
          std::forward<decltype(args)>(args)...} {
  }


  decltype(auto) modify(auto&& fn) & {
    {
      std::lock_guard const _{mx_};
      return std::invoke(std::forward<decltype(fn)>(fn), value_);
    }
  }


  decltype(auto) modify(auto&& fn) && {
    {
      std::lock_guard const _{mx_};
      return std::invoke(std::forward<decltype(fn)>(fn), std::move(value_));
    }
  }


  decltype(auto) read(auto&& fn) const {
    {
      auto const _ = [this] {
        if constexpr (IsHaveLockShared<mutex_type>) {
          return std::shared_lock{mx_};
        } else {
          return std::lock_guard{mx_};
        }
      }();
      return std::invoke(std::forward<decltype(fn)>(fn), value_);
    }
  }


  [[nodiscard]] value_type& raw() noexcept {
    return value_;
  }

private:
  value_type value_;
  mutex_type mutable mx_;
};


}// namespace sim::rer