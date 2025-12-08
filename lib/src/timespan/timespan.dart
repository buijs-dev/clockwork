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

import '../datetime_extension.dart';
import 'timespan_parser.dart';
export 'timespan_exception.dart';

/// Represents a calendar-aware, multi-unit span of time.
///
/// Unlike [Duration], which is strictly a count of microseconds, a [Timespan]
/// can express years, months, weeks, days, hours, minutes, seconds,
/// milliseconds, microseconds, and even nanoseconds.
///
/// This makes it useful for:
/// - Representing ISO-8601 durations (`P3Y6M4DT12H30M5S`)
/// - Parsing human-friendly durations (`"1h30m"`, `"2d"`, `"250ms"`)
/// - Calendar-based arithmetic (years/months with variable lengths)
///
/// A [Timespan] is *not* tied to an absolute instant until it is converted to a
/// concrete [Duration] via [toDuration], which requires a reference date
/// because months and years vary in length.
///
/// ## Examples:
///
/// ```dart
/// final span = Timespan(years: 1, months: 2, days: 3);
/// final duration = span.toDuration(start: DateTime.utc(2025, 1, 31));
/// // Duration accounts for month-length rules, leap years, etc.
/// ```
class Timespan {
  /// Number of full calendar years in the span.
  final int years;

  /// Number of full calendar months in the span.
  final int months;

  /// Number of full calendar weeks (7 days each).
  final int weeks;

  /// Number of full days.
  final int days;

  /// Number of hours.
  final int hours;

  /// Number of minutes.
  final int minutes;

  /// Number of seconds.
  final int seconds;

  /// Number of milliseconds.
  final int milliseconds;

  /// Number of microseconds.
  final int microseconds;

  /// Number of nanoseconds.
  /// These are internally converted to microseconds where possible.
  final int nanoseconds;

  /// Creates a calendar-aware timespan.
  ///
  /// All fields default to zero, allowing very flexible construction.
  const Timespan({
    this.years = 0,
    this.months = 0,
    this.weeks = 0,
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
    this.milliseconds = 0,
    this.microseconds = 0,
    this.nanoseconds = 0,
  });

  /// Parses a textual duration representation into a [Timespan].
  ///
  /// Supported formats:
  /// - **ISO-8601** duration format (e.g., `"P3Y6M4DT12H30M5S"`)
  /// - **Simple / Go-style** formats (e.g. `"1h30m"`, `"250ms"`, `"2d"`)
  ///
  /// The parser automatically detects the format:
  /// - Strings starting with `'P'` are treated as ISO-8601.
  /// - Everything else uses the simple parser.
  ///
  /// Throws:
  /// - `TimespanFormatException` for invalid formats.
  factory Timespan.parse(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('P')) {
      return const ISO8601TimespanParser().parse(trimmed);
    } else {
      return const SimpleUnitTimespanParser().parse(trimmed)!;
    }
  }

  /// Converts this [Timespan] into a concrete [Duration], using the given
  /// reference start date.
  ///
  /// Calendar-based components (years, months, weeks, days) require a
  /// reference instant because the actual number of seconds depends on:
  ///
  /// - leap years
  /// - month lengths
  /// - day clamping (e.g., adding 1 month to January 31 ⇒ February 28/29)
  ///
  /// If [start] is omitted, the current UTC time is used.
  ///
  /// Time units finer than days (hours - nanoseconds) are converted directly
  /// and added to the calendar-difference result.
  ///
  /// Example:
  /// ```dart
  /// final span = Timespan(months: 1);
  /// span.toDuration(start: DateTime.utc(2025, 1, 31));
  /// // Duration corresponds to Jan 31 - Feb 28/29
  /// ```
  Duration toDuration({DateTime? start}) {
    final reference = start?.toUtc() ?? DateTime.now().toUtc();
    final cursor = _Cursor(reference)
      ..addYears(years)
      ..addMonths(months)
      ..addWeeks(weeks)
      ..addDays(days);

    return cursor.utc.difference(reference) +
        Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
          microseconds: microseconds + (nanoseconds ~/ 1000),
        );
  }
}

/// Internal helper used to incrementally apply calendar arithmetic
/// to a UTC timestamp.
///
/// `_Cursor` ensures operations are applied in sequence and correctly handle
/// leap years, month overflow, and clamping.
class _Cursor {
  DateTime _current;
  _Cursor(this._current);

  /// Returns the current UTC timestamp.
  DateTime get utc => _current;

  /// Adds full calendar years, including leap-year-aware clamping.
  void addYears(int years) {
    if (years != 0) {
      _current = _current.addYears(years);
    }
  }

  /// Adds full calendar months, applying clamping for shorter months.
  void addMonths(int months) {
    if (months != 0) {
      _current = _current.addMonths(months);
    }
  }

  /// Adds full weeks (7 days each).
  void addWeeks(int weeks) {
    if (weeks != 0) {
      _current = _current.add(Duration(days: weeks * 7));
    }
  }

  /// Adds full days.
  void addDays(int days) {
    if (days != 0) {
      _current = _current.add(Duration(days: days));
    }
  }
}
