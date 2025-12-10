// Copyright (c) 2021 - 2026 Buijs Software
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// Clockwork — A high‑performance time toolkit for Dart.
///
/// This package provides:
///
/// - A flexible `Clock` abstraction with multiple implementations
///   (`SystemClock`, `FixedClock`, `OffsetClock`, `TickingClock`, `AdjustableClock`) and
///   a simple override mechanism via `ClockProvider.withClock`.
/// - Rich `DateTime` extensions for calendar‑safe manipulation,
///   truncation/rounding, comparisons, ISO week helpers, and distance utilities.
/// - A calendar‑aware `Timespan` type plus robust parsers that support both
///   ISO‑8601 (e.g. `P3Y6M4DT12H30M5S`) and simple unit formats (e.g. `1h30m`, `250ms`).
///
/// See the docs/ folder for categorized guides:
/// - docs/clock.md — Clocks API and best practices
/// - docs/datetime_extensions.md — DateTime helpers overview
/// - docs/timespan.md — Timespan modeling and conversion
/// - docs/parsing.md — Duration parsing formats and details
export 'src/clock.dart';
export 'src/datetime_extension.dart';
export 'src/timespan.dart';
export 'src/timespan_parser.dart';
