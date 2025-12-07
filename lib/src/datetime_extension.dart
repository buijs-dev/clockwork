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

bool _isLeapYear(int year) =>
    (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);

/// Supported time units for distance/difference calculations.
///
/// This enum allows callers to express which granularity of
/// temporal distance they want, mapping cleanly onto common
/// calendar and duration interpretations.
enum TimeUnit {
  years,
  months,
  weeks,
  days,
  hours,
  minutes,
  seconds,
  milliseconds,
  microseconds,
}

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

  /// Returns a timestamp truncated to the nearest minute.
  ///
  /// By default, the returned DateTime uses the same UTC/local
  /// behavior as the source object unless explicitly overridden.
  DateTime roundToMinute({bool? utc}) =>
      utc ?? isUtc
          ? DateTime.utc(year, month, day, hour, minute)
          : DateTime(year, month, day, hour, minute);

  /// Alias for [roundToMinute] provided for semantic clarity.
  DateTime floorToMinute({bool? utc}) =>
      utc ?? isUtc
          ? DateTime.utc(year, month, day, hour, minute)
          : DateTime(year, month, day, hour, minute);

  /// Midnight (00:00:00.000000) of the same calendar day.
  DateTime startOfDay({bool? utc}) =>
      utc ?? isUtc ? DateTime.utc(year, month, day) : DateTime(year, month, day);

  /// 23:59:59.999999 of the same calendar day.
  DateTime endOfDay({bool? utc}) =>
      utc ?? isUtc
          ? DateTime.utc(year, month, day, 23, 59, 59, 999, 999)
          : DateTime(year, month, day, 23, 59, 59, 999, 999);

  /// First day of the month at midnight.
  DateTime startOfMonth({bool? utc}) =>
      utc ?? isUtc ? DateTime.utc(year, month) : DateTime(year, month);

  /// Last microsecond of the month.
  DateTime endOfMonth({bool? utc}) {
    final useUtc = utc ?? isUtc;
    final nextMonth = useUtc
        ? (month == 12 ? DateTime.utc(year + 1, 1, 1) : DateTime.utc(year, month + 1, 1))
        : (month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1));
    return nextMonth.subtract(const Duration(microseconds: 1));
  }

  /// January 1st of the same year, at midnight.
  DateTime startOfYear({bool? utc}) =>
      utc ?? isUtc ? DateTime.utc(year, 1, 1) : DateTime(year, 1, 1);

  /// Last second of the year (microseconds always zeroed).
  DateTime endOfYear({bool? utc}) =>
      utc ?? isUtc
          ? DateTime.utc(year, 12, 31, 23, 59, 59, 999, 999)
          : DateTime(year, 12, 31, 23, 59, 59, 999, 999);

  /// True when this date falls in a leap year.
  bool get isLeapYear => _isLeapYear(year);

  /// Saturday or Sunday.
  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Monday through Friday.
  bool get isWeekday => !isWeekend;

  /// True when this month is February in a leap year.
  bool isLeapMonth() => month == 2 && isLeapYear;

  /// True when this instance represents February 29th.
  bool get isLeapDay => month == 2 && day == 29;

  /// Calendar match for year, month, and day components.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Calendar match for year and month.
  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  /// Calendar match for year.
  bool isSameYear(DateTime other) => year == other.year;

  int differenceInYears(DateTime other) => differenceIn(other, unit: TimeUnit.years);

  int differenceInMonths(DateTime other) => differenceIn(other, unit: TimeUnit.months);

  int differenceInWeeks(DateTime other) => differenceIn(other, unit: TimeUnit.weeks);

  /// Difference (absolute) expressed in whole days using
  /// standard Duration computation.
  int differenceInDays(DateTime other) => differenceIn(other, unit: TimeUnit.days);

  int differenceInHours(DateTime other) => differenceIn(other, unit: TimeUnit.hours);

  int differenceInMinutes(DateTime other) => differenceIn(other, unit: TimeUnit.minutes);

  int differenceInSeconds(DateTime other) => differenceIn(other, unit: TimeUnit.seconds);

  int differenceInMilliseconds(DateTime other) => differenceIn(other, unit: TimeUnit.milliseconds);

  int differenceInMicroseconds(DateTime other) => differenceIn(other, unit: TimeUnit.microseconds);

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
    final dur = difference(other);
    final absDur = dur.isNegative ? dur * -1 : dur;

    switch (unit) {
      case TimeUnit.microseconds:
        return absDur.inMicroseconds;

      case TimeUnit.milliseconds:
        return absDur.inMilliseconds;

      case TimeUnit.seconds:
        return absDur.inSeconds;

      case TimeUnit.minutes:
        return absDur.inMinutes;

      case TimeUnit.hours:
        return absDur.inHours;

      case TimeUnit.days:
        return absDur.inDays;

      case TimeUnit.weeks:
        return absDur.inDays ~/ 7;

      case TimeUnit.months:
        final y1 = year, y2 = other.year;
        final m1 = month, m2 = other.month;
        final total1 = y1 * 12 + m1;
        final total2 = y2 * 12 + m2;
        return (total1 - total2).abs();

      case TimeUnit.years:
        final yDiff = (year - other.year).abs();
        return yDiff;
    }
  }
}
