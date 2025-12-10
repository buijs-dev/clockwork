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
/// always possible by converting the DateTime itself.
extension DateTimeTimeHelpers on DateTime {
  /// Returns a new DateTime based on this one, overriding only
  /// the fields that are explicitly provided.
  ///
  /// The resulting instance preserves this.isUtc.
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    if (isUtc) {
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

  /// Replace time portion.
  DateTime atTime(int h, int m, [int s = 0, int ms = 0, int us = 0]) =>
      copyWith(hour: h, minute: m, second: s, millisecond: ms, microsecond: us);

  /// Returns a timestamp rounded to the nearest minute.
  ///
  /// Rounds up when seconds >= 30, otherwise rounds down (truncates seconds).
  DateTime roundToMinute() =>
      copyWith(minute: minute + (second >= 30 ? 1 : 0), second: 0, millisecond: 0, microsecond: 0);

  /// Noon helper.
  DateTime toMidday() => atTime(12, 0);
}

extension DateTimeDateHelpers on DateTime {
  /// Start of day at 00:00:00.000000 for this DateTime (preserves UTC/local).
  DateTime startOfDay() => copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  /// End of day at 23:59:59.999999 for this DateTime (preserves UTC/local).
  DateTime endOfDay() => copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);

  /// True if this date is February 29th.
  bool get isLeapDay => month == 2 && day == 29;

  /// True if this month is February of a leap year.
  bool get isLeapMonth => month == 2 && isLeapYear;

  /// True if the year component is a Gregorian leap year.
  bool get isLeapYear => _isLeapYear(year);

  /// True if this date falls on Saturday or Sunday.
  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// True if this date falls on Monday–Friday.
  bool get isWeekday => !isWeekend;

  /// True if [other] has the same year, month and day as this instance.
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// True if [other] has the same year and month as this instance.
  bool isSameMonth(DateTime other) => year == other.year && month == other.month;

  /// True if [other] has the same year as this instance.
  bool isSameYear(DateTime other) => year == other.year;

  /// First instant of the current month (at 00:00:00.000000).
  DateTime startOfMonth() => copyWith(day: 1, hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  /// Last instant of the current month (at 23:59:59.999999).
  DateTime endOfMonth() {
    // compute first moment of next month then subtract 1 microsecond
    final nextMonthYear = month == 12 ? year + 1 : year;
    final nextMonthMonth = month == 12 ? 1 : month + 1;
    final nextMonthFirst = copyWith(
      year: nextMonthYear,
      month: nextMonthMonth,
      day: 1,
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    return nextMonthFirst.subtract(const Duration(microseconds: 1));
  }

  /// Adds [count] calendar months, clamping the day when needed
  /// (e.g. Jan 31 + 1 month → Feb 28/29).
  DateTime addMonths(int count) {
    final total = (year * 12 + month - 1) + count;
    final y = total ~/ 12;
    final m = (total % 12) + 1;
    final lastDay = _daysInMonth(y, m);
    final d = day.clamp(1, lastDay);
    return copyWith(year: y, month: m, day: d);
  }

  int _daysInMonth(int y, int m) {
    if (m == 2) return _isLeapYear(y) ? 29 : 28;
    if (m == 4 || m == 6 || m == 9 || m == 11) return 30;
    return 31;
  }

  /// First instant of the current year (at 00:00:00.000000 on Jan 1).
  DateTime startOfYear() => copyWith(month: 1, day: 1, hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  /// Last instant of the current year (at 23:59:59.999999 on Dec 31).
  DateTime endOfYear() =>
      copyWith(month: 12, day: 31, hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);

  /// Adds [count] calendar years, adjusting Feb 29 to Feb 28 when the
  /// resulting year is not a leap year.
  DateTime addYears(int count) {
    final newYear = year + count;
    if (month == 2 && day == 29 && !_isLeapYear(newYear)) {
      // Move to Feb 28 in non-leap year
      return copyWith(year: newYear, month: 2, day: 28);
    } else {
      return copyWith(year: newYear);
    }
  }

  /// Start of week assuming Monday is the first day.
  DateTime startOfWeek() {
    final offset = weekday - DateTime.monday;
    return startOfDay().subtract(Duration(days: offset));
  }

  /// End of week (Sunday 23:59:59.999999) assuming Monday is the first day.
  DateTime endOfWeek() => startOfWeek().add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));

  /// Quarter number for this date (1..4).
  int get quarter => ((month - 1) ~/ 3) + 1;

  /// First instant of the current quarter.
  DateTime startOfQuarter() {
    final m = ((quarter - 1) * 3) + 1;
    return copyWith(month: m, day: 1, hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  }

  /// Last instant of the current quarter.
  DateTime endOfQuarter() {
    final endM = quarter * 3;
    final nextYear = endM == 12 ? year + 1 : year;
    final nextMonth = endM == 12 ? 1 : endM + 1;
    final next = copyWith(
      year: nextYear,
      month: nextMonth,
      day: 1,
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    return next.subtract(const Duration(microseconds: 1));
  }

  /// Same date/time in the next quarter.
  DateTime nextQuarter() => addMonths(3);

  /// Same date/time in the previous quarter.
  DateTime previousQuarter() => addMonths(-3);

  /// Clamp between [min] and [max].
  DateTime clamp(DateTime min, DateTime max) => isBefore(min) ? min : (isAfter(max) ? max : this);

  /// Next occurrence of a weekday (1=Mon … 7=Sun)
  DateTime nextWeekday(int weekday) {
    final delta = (weekday - this.weekday + 7) % 7;
    return add(Duration(days: delta == 0 ? 7 : delta));
  }

  /// Previous occurrence of a weekday
  DateTime previousWeekday(int weekday) {
    final delta = (this.weekday - weekday + 7) % 7;
    return subtract(Duration(days: delta == 0 ? 7 : delta));
  }

  /// True if in range (start, end) inclusive.
  bool between(DateTime start, DateTime end) => (isAfterOrSame(start) && isBeforeOrSame(end));
}

extension DateTimeDurationHelpers on DateTime {
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

extension DateTimeIso8601Helpers on DateTime {
  /// ISO weekday number (1=Monday … 7=Sunday).
  int get isoWeekDay => weekday == DateTime.sunday ? 7 : weekday;

  DateTime _isoWeekStart() {
    // base is the midnight of this date (preserves UTC/local)
    final base = startOfDay();
    final w = base.weekday == DateTime.sunday ? 7 : base.weekday;
    return base.subtract(Duration(days: w - 1));
  }

  /// Start of ISO week (Monday 00:00:00.000000).
  DateTime startOfISOWeek() => _isoWeekStart();

  /// End of ISO week (Sunday 23:59:59.999999).
  DateTime endOfISOWeek() => startOfISOWeek().add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));

  /// ISO week-year for this date.
  int get isoWeekYear {
    // Thursday of this week determines the ISO week-year.
    final thursday = add(Duration(days: 4 - isoWeekDay));
    return thursday.year;
  }

  /// ISO week number within the ISO week-year (1..52/53).
  int get isoWeekNumber {
    final y = isoWeekYear;
    final jan4Start = copyWith(
      year: y,
      month: 1,
      day: 4,
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    )._isoWeekStart();
    final thisStart = startOfISOWeek();
    return thisStart.difference(jan4Start).inDays ~/ 7 + 1;
  }

  /// Start of ISO week-year (Monday of the week that contains Jan 4).
  DateTime startOfISOYear() {
    final y = isoWeekYear;
    final jan4 = copyWith(year: y, month: 1, day: 4, hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    return jan4._isoWeekStart();
  }

  /// End of ISO week-year (last microsecond before next ISO year starts).
  DateTime endOfISOYear() {
    final y = isoWeekYear;
    final nextJan4 = copyWith(
      year: y + 1,
      month: 1,
      day: 4,
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final nextStart = nextJan4._isoWeekStart();
    return nextStart.subtract(const Duration(microseconds: 1));
  }

  /// Number of ISO weeks in this ISO week-year (52 or 53).
  int get isoWeeksInYear {
    final start = startOfISOYear();
    final endNext = startOfISOYear().copyWith(year: isoWeekYear + 1)._isoWeekStart();
    return endNext.difference(start).inDays ~/ 7;
  }
}
