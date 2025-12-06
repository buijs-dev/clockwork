// Copyright...

import 'dart:math';

import '../extension.dart';
import 'timespan_parser.dart';
export 'timespan_exception.dart';

const _monthLengths = <int>[
  31, // Jan
  28, // Feb
  31, // Mar
  30, // Apr
  31, // May
  30, // Jun
  31, // Jul
  31, // Aug
  30, // Sep
  31, // Oct
  30, // Nov
  31, // Dec
];

class Timespan {
  final int years;
  final int months;
  final int weeks;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int milliseconds;
  final int microseconds;
  final int nanoseconds;

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

  /// Unified parser:
  /// - ISO-8601 ("P3Y6M4DT12H30M5S")
  /// - Simple / Go-style ("1h30m", "250ms", "2d")
  factory Timespan.parse(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('P')) {
      return const ISO8601TimespanParser().parse(trimmed)!;
    } else {
      return const SimpleUnitTimespanParser().parse(trimmed)!;
    }
  }

  /// Convert to a concrete Duration given a reference start date.
  ///
  /// Calendar-correct handling of years and months:
  /// - Leap years
  /// - Month lengths
  /// - Day clamping (e.g., adding 1 month to Jan 31 becomes Feb 28/29)
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

class _Cursor {
  DateTime _current;
  _Cursor(this._current);

  DateTime get utc => _current;

  void addYears(int years) {
    if (years != 0) {
      _current = _current.addYears(years);
    }
  }

  void addMonths(int months) {
    if (months != 0) {
      _current = _current.addMonths(months);
    }
  }

  void addWeeks(int weeks) {
    if (weeks != 0) {
      _current = _current.add(Duration(days: weeks * 7));
    }
  }

  void addDays(int days) {
    if (days != 0) {
      _current = _current.add(Duration(days: days));
    }
  }
}

extension _CalendarArithmetic on DateTime {
  DateTime addYears(int years) {
    final targetYear = year + years;
    final maxDay = _daysInMonth(targetYear, month);
    final newDay = min(day, maxDay);
    return DateTime.utc(
      targetYear,
      month,
      newDay,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  DateTime addMonths(int monthsToAdd) {
    final totalMonths = month + monthsToAdd;
    final newYear = year + ((totalMonths - 1) ~/ 12);
    final newMonth = ((totalMonths - 1) % 12) + 1;
    final maxDay = _daysInMonth(newYear, newMonth);
    final newDay = min(day, maxDay);
    return DateTime.utc(
      newYear,
      newMonth,
      newDay,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }
}

int _daysInMonth(int year, int month) {
  if (month == 2) {
    return isLeapYear(year) ? 29 : 28;
  } else {
    return _monthLengths[month - 1];
  }
}
