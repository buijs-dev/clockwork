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

/// Basic leap-year test for a given Gregorian year.
bool isLeapYear(int year) => _isLeapYear(year);

bool _isLeapYear(int year) => (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);

/// Supported time units for distance/difference calculations.
///
/// This enum allows callers to express which granularity of
/// temporal distance they want, mapping cleanly onto common
/// calendar and duration interpretations.
enum TimeUnit { years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds }

/// Extension with a set of convenience utilities providing
/// calendar-safe manipulation, truncation, comparison, and
/// difference calculations. Designed to work naturally with
/// a UTC-first workflow, but switching to local time is
/// always possible via named parameters.
extension DateTimeExtension on DateTime {
  /// Returns a new DateTime based on this one, overriding only
  /// the fields that are explicitly provided.
  ///
  /// The resulting instance is UTC when:
  /// - `utc == true`, or
  /// - `utc == null` and this object itself is UTC.
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
    bool? utc,
  }) {
    if (utc ?? isUtc) {
      return DateTime.utc(
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
        millisecond ?? this.millisecond,
        microsecond ?? this.microsecond,
      );
    } else {
      return DateTime(
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
        millisecond ?? this.millisecond,
        microsecond ?? this.microsecond,
      );
    }
  }

  /// Integer seconds since Unix epoch (UTC-based).
  ///
  /// This uses truncation rather than rounding, which matches
  /// the behavior of most epoch-based systems.
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;

  /// Returns `true` if this DateTime is strictly before [other],
  /// or equal to it.
  bool isBeforeOrSame(DateTime other) => !isAfter(other);

  /// Returns `true` if this DateTime is strictly after [other],
  /// or equal to it.
  bool isAfterOrSame(DateTime other) => !isBefore(other);

  // ---------------------------------------------------------------------------
  // DAY HELPERS
  // ---------------------------------------------------------------------------

  DateTime startOfDay({bool? utc}) => (utc ?? isUtc) ? DateTime.utc(year, month, day) : DateTime(year, month, day);

  DateTime endOfDay({bool? utc}) => (utc ?? isUtc)
      ? DateTime.utc(year, month, day, 23, 59, 59, 999, 999)
      : DateTime(year, month, day, 23, 59, 59, 999, 999);

  /// Returns a timestamp truncated to the nearest minute.
  ///
  /// By default, the returned DateTime uses the same UTC/local
  /// behavior as the source object unless explicitly overridden.
  DateTime roundToMinute({bool? utc}) =>
      (utc ?? isUtc) ? DateTime.utc(year, month, day, hour, minute) : DateTime(year, month, day, hour, minute);

  DateTime floorToMinute({bool? utc}) => roundToMinute(utc: utc);

  bool get isLeapDay => month == 2 && day == 29;

  bool get isLeapMonth => month == 2 && isLeapYear;

  bool get isLeapYear => _isLeapYear(year);

  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;

  bool get isWeekday => !isWeekend;

  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) => year == other.year && month == other.month;

  bool isSameYear(DateTime other) => year == other.year;

  // ---------------------------------------------------------------------------
  // MONTH HELPERS
  // ---------------------------------------------------------------------------

  DateTime startOfMonth({bool? utc}) => (utc ?? isUtc) ? DateTime.utc(year, month, 1) : DateTime(year, month, 1);

  DateTime endOfMonth({bool? utc}) {
    final useUtc = utc ?? isUtc;

    final nextMonth = month == 12
        ? (useUtc ? DateTime.utc(year + 1, 1) : DateTime(year + 1, 1))
        : (useUtc ? DateTime.utc(year, month + 1) : DateTime(year, month + 1));

    return nextMonth.subtract(const Duration(microseconds: 1));
  }

  DateTime addMonths(int count, {bool? utc}) {
    final useUtc = utc ?? isUtc;
    final total = (year * 12 + month - 1) + count;
    final y = total ~/ 12;
    final m = (total % 12) + 1;
    final lastDay = _daysInMonth(y, m);
    final d = day.clamp(1, lastDay);
    return useUtc
        ? DateTime.utc(y, m, d, hour, minute, second, millisecond, microsecond)
        : DateTime(y, m, d, hour, minute, second, millisecond, microsecond);
  }

  int _daysInMonth(int y, int m) {
    if (m == 2) return _isLeapYear(y) ? 29 : 28;
    if (m == 4 || m == 6 || m == 9 || m == 11) return 30;
    return 31;
  }

  // ---------------------------------------------------------------------------
  // YEAR HELPERS
  // ---------------------------------------------------------------------------

  DateTime startOfYear({bool? utc}) => (utc ?? isUtc) ? DateTime.utc(year, 1, 1) : DateTime(year, 1, 1);

  DateTime endOfYear({bool? utc}) =>
      (utc ?? isUtc) ? DateTime.utc(year, 12, 31, 23, 59, 59, 999, 999) : DateTime(year, 12, 31, 23, 59, 59, 999, 999);

  DateTime addYears(int count, {bool? utc}) {
    final newYear = year + count;

    if (month == 2 && day == 29 && !_isLeapYear(newYear)) {
      return copyWith(year: newYear, month: 2, day: 28, utc: utc ?? isUtc);
    }

    return copyWith(year: newYear, utc: utc ?? isUtc);
  }

  // ---------------------------------------------------------------------------
  // WEEK HELPERS
  // ---------------------------------------------------------------------------

  DateTime startOfWeek({bool? utc}) {
    final useUtc = utc ?? isUtc;
    final offset = weekday - DateTime.monday;

    final base = useUtc ? DateTime.utc(year, month, day) : DateTime(year, month, day);

    return base.subtract(Duration(days: offset));
  }

  DateTime endOfWeek({bool? utc}) =>
      startOfWeek(utc: utc).add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));

  // ---------------------------------------------------------------------------
  // ISO 8601 WEEK HELPERS
  // ---------------------------------------------------------------------------

  DateTime _isoWeekStart({bool? utc}) {
    final useUtc = utc ?? isUtc;
    final base = useUtc ? DateTime.utc(year, month, day) : DateTime(year, month, day);

    final w = base.weekday == 7 ? 7 : base.weekday;
    return base.subtract(Duration(days: w - 1));
  }

  DateTime startOfISOWeek({bool? utc}) => _isoWeekStart(utc: utc);

  DateTime endOfISOWeek({bool? utc}) =>
      startOfISOWeek(utc: utc).add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));

  int get isoWeekYear {
    final thursday = add(Duration(days: 4 - weekday));
    return thursday.year;
  }

  int get isoWeekNumber {
    final useUtc = isUtc;
    final isoYear = isoWeekYear;

    final jan4 = useUtc ? DateTime.utc(isoYear, 1, 4) : DateTime(isoYear, 1, 4);

    final jan4Start = jan4._isoWeekStart(utc: useUtc);
    final thisStart = startOfISOWeek(utc: useUtc);

    return thisStart.difference(jan4Start).inDays ~/ 7 + 1;
  }

  // ---------------------------------------------------------------------------
  // QUARTER HELPERS
  // ---------------------------------------------------------------------------

  int get quarter => ((month - 1) ~/ 3) + 1;

  DateTime startOfQuarter({bool? utc}) {
    final useUtc = utc ?? isUtc;
    final m = ((quarter - 1) * 3) + 1;

    return useUtc ? DateTime.utc(year, m, 1) : DateTime(year, m, 1);
  }

  DateTime endOfQuarter({bool? utc}) {
    final useUtc = utc ?? isUtc;
    final endM = quarter * 3;

    final next = endM == 12
        ? (useUtc ? DateTime.utc(year + 1, 1, 1) : DateTime(year + 1, 1, 1))
        : (useUtc ? DateTime.utc(year, endM + 1, 1) : DateTime(year, endM + 1, 1));

    return next.subtract(const Duration(microseconds: 1));
  }

  DateTime nextQuarter({bool? utc}) => addMonths(3, utc: utc);

  DateTime previousQuarter({bool? utc}) => addMonths(-3, utc: utc);

  // ---------------------------------------------------------------------------
  // EXTRA UTILITIES
  // ---------------------------------------------------------------------------

  /// Clamp between [min] and [max].
  DateTime clamp(DateTime min, DateTime max) => isBefore(min) ? min : (isAfter(max) ? max : this);

  /// Replace time portion.
  DateTime atTime(int h, int m, [int s = 0, int ms = 0, int us = 0]) =>
      copyWith(hour: h, minute: m, second: s, millisecond: ms, microsecond: us);

  /// Next occurrence of a weekday (1=Mon … 7=Sun)
  DateTime nextWeekday(int weekday, {bool? utc}) {
    final delta = (weekday - this.weekday + 7) % 7;
    return add(Duration(days: delta == 0 ? 7 : delta));
  }

  /// Previous occurrence of a weekday
  DateTime previousWeekday(int weekday, {bool? utc}) {
    final delta = (this.weekday - weekday + 7) % 7;
    return subtract(Duration(days: delta == 0 ? 7 : delta));
  }

  /// True if in range [start, end] inclusive.
  bool between(DateTime start, DateTime end) => (isAfterOrSame(start) && isBeforeOrSame(end));

  /// Noon helper.
  DateTime toMidday({bool? utc}) => atTime(12, 0);

  /// General-purpose temporal distance between this instant
  /// and [other], expressed in the given [unit].
  ///
  /// - Units `milliseconds`, `microseconds`, `seconds`,
  ///   `minutes`, `hours`, and `days` are derived directly
  ///   from `Duration`.
  /// - Units `weeks` derive from `days ~/ 7`.
  /// - Units `months` and `years` use a calendar calculation
  ///   based on year/month components, not Duration:
  ///   - `months = (yearDiff * 12) + monthDiff`
  ///   - `years = months ~/ 12`
  int differenceIn(DateTime other, {required TimeUnit unit}) {
    final d = difference(other);
    final abs = d.isNegative ? -d : d;
    switch (unit) {
      case TimeUnit.microseconds:
        return abs.inMicroseconds;
      case TimeUnit.milliseconds:
        return abs.inMilliseconds;
      case TimeUnit.seconds:
        return abs.inSeconds;
      case TimeUnit.minutes:
        return abs.inMinutes;
      case TimeUnit.hours:
        return abs.inHours;
      case TimeUnit.days:
        return abs.inDays;
      case TimeUnit.weeks:
        return abs.inDays ~/ 7;
      case TimeUnit.months:
        final total1 = year * 12 + month;
        final total2 = other.year * 12 + other.month;
        return (total1 - total2).abs();
      case TimeUnit.years:
        return (year - other.year).abs();
    }
  }

  int differenceInYears(DateTime other) => differenceIn(other, unit: TimeUnit.years);

  int differenceInMonths(DateTime other) => differenceIn(other, unit: TimeUnit.months);

  int differenceInWeeks(DateTime other) => differenceIn(other, unit: TimeUnit.weeks);

  int differenceInDays(DateTime other) => differenceIn(other, unit: TimeUnit.days);

  int differenceInHours(DateTime other) => differenceIn(other, unit: TimeUnit.hours);

  int differenceInMinutes(DateTime other) => differenceIn(other, unit: TimeUnit.minutes);

  int differenceInSeconds(DateTime other) => differenceIn(other, unit: TimeUnit.seconds);

  int differenceInMilliseconds(DateTime other) => differenceIn(other, unit: TimeUnit.milliseconds);

  int differenceInMicroseconds(DateTime other) => differenceIn(other, unit: TimeUnit.microseconds);
}
