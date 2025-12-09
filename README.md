# Clockwork — Summary of lib/src

[![](https://img.shields.io/badge/Buijs-Software-blue)](https://pub.dev/publishers/buijs.dev/packages)
[![GitHub license](https://img.shields.io/github/license/buijs-dev/klutter-dart?color=black&logoColor=black)](https://github.com/buijs-dev/clockwork/blob/main/LICENSE)
[![pub](https://img.shields.io/pub/v/clockwork)](https://pub.dev/packages/clockwork)
[![codecov](https://codecov.io/gh/buijs-dev/clockwork/branch/main/graph/badge.svg?token=rF9oTajbaK)](https://codecov.io/gh/buijs-dev/clockwork)
[![CodeScene Code Health](https://codescene.io/projects/27237/status-badges/code-health)](https://codescene.io/projects/27237)

A high-performance time toolkit for Dart, offering fast mockable clocks, elegant DateTime extensions, and rock-solid duration parsing with full ISO-8601 and Go-style syntax support.







This library provides three core building blocks:

1) Clock abstraction (`clock.dart`)
- Swap the global time source for deterministic tests and simulations.
- All clock implementations keep authoritative time in UTC, with opt‑in local conversions.
- Use `ClockProvider.withClock` to temporarily override the active clock in a synchronous scope.

Available clocks
- `SystemClock` — returns the system wall clock time.
- `FixedClock` — always returns a fixed instant (useful for tests).
- `OffsetClock` — shifts a base clock by a fixed `Duration` (e.g., time travel +2h).
- `StopwatchClock` — measures time relative to a start point using a `Stopwatch`.
- `TickingClock` — advances in fixed ticks from a start instant (discrete steps).
- `AdjustableClock` — mutable clock you can move forward/backward programmatically.

Quick example (conceptual)
- Create a fixed clock at `2025‑01‑01T00:00:00Z` and run code within `ClockProvider.withClock(...)`.
- Inside the scope, calls like `ClockProvider.current.now()` return the fixed instant.

2) DateTime extensions (`datetime_extension.dart`)
- Convenience API for calendar‑safe manipulation, truncation/rounding, and comparisons.
- Includes `copyWith`, `startOf…`/`endOf…` helpers (minute, hour, day, week, month, year).
- Checks like `isLeapYear`, `isWeekend`, `isSameDay/Month/Year`.
- Distance helpers: `differenceInYears/Months/Weeks/Days/.../Microseconds` and general `differenceIn(unit: TimeUnit.*)`.
- Epoch helpers like `secondsSinceEpoch`.

Quick example (conceptual)
- From a given UTC timestamp, get `startOfMonth()` / `endOfMonth()`.
- Compute distances, e.g., `differenceInDays(other)`.

3) Calendar‑aware timespans and parsing (`timespan/`)
- `Timespan` represents a multi‑unit span (years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds).
- Unlike `Duration` (microseconds only), `Timespan` preserves calendar units and can be converted to a `Duration` via `toDuration(start: DateTime)` to respect month lengths, leap years, etc.
- Parsing support via `TimespanParser` implementations:
  - `ISO8601TimespanParser` — parses ISO‑8601 durations like `P3Y6M4DT12H30M5S`, `P2W`, `PT10S`.
  - `SimpleUnitsTimespanParser` — parses Go/Spring‑style simple units like `1h30m`, `250ms`, `2d`.

Quick example (conceptual)
- Parse `P1M` as a timespan of one calendar month.
- Convert to a concrete `Duration` with `toDuration(start: <reference date>)` to account for month length.

Duration parsing support — examples

ISO‑8601
case insensitive by default
- `PT15M`   → 15 minutes
- `PT1H30M` → 1 hour 30 minutes
- `P2DT3H4M`→ 2 days, 3 hours, 4 minutes

Simple Units
case insensitive by default
- `1ns` → nanoseconds
- `1us` → microseconds
- `1ms` → milliseconds
- `1s`  → seconds
- `1m`  → minutes
- `1h`  → hours
- `1d`  → days
