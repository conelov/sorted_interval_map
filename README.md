### Тестовое по вакансии на должность c++ developer.

* Синопсис [Задание_тест.pdf](%D0%97%D0%B0%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5_%D1%82%D0%B5%D1%81%D1%82.pdf). <br/>
* Реализация [SortedIntervalMap.hpp](sim/SortedIntervalMap.hpp). <br/>
* Тесты требуемого класса [SortedIntervalMap.cpp](sim/ut/SortedIntervalMap.cpp). <br/>
* Автоматическое разрешение остутсвующих зависимостей с помощью [cmake-CPM](https://github.com/cpm-cmake/CPM.cmake). <br/>
* Таргет `*-doxygen_generate` | `*-doxygen_show`: автогенерация документации с помощью [doxygen](https://www.doxygen.nl/) при наличии [Doxyfile](Doxyfile.in). `Doxyfile` может быть конфигурируемым синтаксисом [configure_file](https://cmake.org/cmake/help/latest/command/configure_file.html). Определяется автоматически по `.in` расширению. Цели конфигурируются наличии в системе `doxygen`.
* [User defined](Doxyfile.in#L273) теги doxygen. Например: Worst case complexity (O), Best case complexity (Ω), Average case complexity (Θ).

<details> <summary>Исследование по поиску оптимального решения.</summary>
   
  * Четыре реализации [SortedInterval.hpp](sim/SortedInterval.hpp) путём комбинации использованного нижележащего контейнера и параметризации метода [emplace](sim/aux/SortedIntervalImpl.hpp). [Пример параметризации](sim/ut/SortedInterval.cpp#L28-L33). <br/>
    * `std::set` с поэлементным удалением пересекающихся диапазонов ([trivial](sim/aux/SortedIntervalImpl.hpp#L12)).
    * `std::set` удалением пересекающихся диапазонов одним куском с переиспользованием одного из удаляемых диапазонов ([optimized_erase](sim/aux/SortedIntervalImpl.hpp#L13)).
    * В режиме RESEARCH используется `itlib::flat_set` как нижележащий контейнер ([SortedInterval.cpp](sim/ut/SortedInterval.cpp#L31)).
    * В режиме RESEARCH используется `itlib::flat_set` как нижележащий контейнер с базовым контейнером `std::deque` ([SortedInterval.cpp](sim/ut/SortedInterval.cpp#L32)).
  * [Бенчмарк](sim/research/SortedIntervalBench.cpp) для них.
</details> 

<details> <summary>Сборка и запуск</summary>

Здесь и далее выполнять из папки проекта. <br/> 
Используется переменная `CPM_SOURCE_CACHE` для ускорения последующих конфигураций. <br/>
Целевой тест собирается и запускается командой: <br/>
```
SRC="$(pwd)"; BUILD_ROOT=/tmp; BUILD="$BUILD_ROOT/sim_build"; CPM_CACHE="$BUILD_ROOT/sim_cpm_cache"; cmake "$SRC" -B "$BUILD" -DSIM_RESEARCH=OFF -DCMAKE_BUILD_TYPE=Release -DCPM_SOURCE_CACHE="$CPM_CACHE" && cmake --build "$BUILD" --target sim-ut --parallel $(nproc) && "$BUILD/sim/ut/sim-ut"
```
Сборка и запуск бенчмарков всех имплементаций:

```
SRC="$(pwd)"; BUILD_ROOT=/tmp; BUILD="$BUILD_ROOT/sim_build"; CPM_CACHE="$BUILD_ROOT/sim_cpm_cache"; rm "$BUILD/CMakeCache.txt" 2> /dev/null; cmake "$SRC" -B "$BUILD" -DSIM_RESEARCH=ON -DCMAKE_BUILD_TYPE=Release -DCPM_SOURCE_CACHE="$CPM_CACHE" && cmake --build "$BUILD" --target sim-research-bench --parallel $(nproc)
```
</details>

<details> <summary>Параметризация сборки</summary>

`-DBUILD_TESTING=<ON|OFF>`: Сборка тестов. Стандартная переменная cmake. <br/>
`-DSIM_RESEARCH=<ON|OFF>`: Сборка бенчмарков. <br/>
`-DSIM_RESEARCH_GBENCH_SAN=<ON|OFF>`^ Санитайзеры для бенчмарка. <br/>
`-DSIM_SANITIZERS="[[address];[thread];[ub];[leak];[mem]]"`: Для всех тестов и бенчмарка в создаются `<target>-<san type>` с санитайзерами из списка. <br/>
Полный список параметров в [CMakeLists.txt](CMakeLists.txt#L13-L25).
</details>

<details> <summary>Список целей</summary>

<img alt="targets.svg" src="gifs/targets.svg"/>
</details>

Проект собирался и тестировался:
* GNU C++17 (Ubuntu 10.5.0-1ubuntu1~22.04) version 10.5.0 (x86_64-linux-gnu)
* clang -cc1 version 19.1.1 based upon LLVM 19.1.1 default target x86_64-unknown-linux-gnu
* GNU C++17 (GCC) версия 14.2.0 (x86_64-pc-linux-gnu)

Проект зависит только от `libc++` | `libstdc++` и сопутствующих им библиотек. <br/>
Разрешение других зависимостей происходит автоматически с помощью `cmake-CPM`.

© Весь код (c++/cmake), представленный в репозитории, так или иначе, написан [мной](https://github.com/conelov).
Некоторый код мог быть взят из [CustomHelper](https://github.com/conelov/CustomHelper). <br/>
В ином случае имеется аннотация на источник.