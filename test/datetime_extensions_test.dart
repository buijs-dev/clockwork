import 'package:clockwork/clockwork.dart';
import 'package:test/test.dart';

void main() {
  group('Leap year utilities', () {
    test('isLeapYear top-level function', () {
      expect(isLeapYear(2000), true); // divisible by 400
      expect(isLeapYear(2024), true); // divisible by 4
      expect(isLeapYear(1900), false); // divisible by 100 but not 400
      expect(isLeapYear(2023), false);
    });

    test('DateTime.isLeapYear getter', () {
      expect(DateTime.utc(2024).isLeapYear, true);
      expect(DateTime.utc(2023).isLeapYear, false);
    });

    test('isLeapMonth and isLeapDay', () {
      expect(DateTime.utc(2024, 2).isLeapMonth, true);
      expect(DateTime.utc(2024, 2, 29).isLeapDay, true);
      expect(DateTime.utc(2023, 2).isLeapMonth, false);
    });
  });

  group('copyWith', () {
    test('keeps UTC when original is UTC', () {
      final t = DateTime.utc(2024, 1, 1, 10, 15);
      final r = t.copyWith(hour: 20);
      expect(r.isUtc, true);
      expect(r.hour, 20);
    });

    test('keeps local when original is local', () {
      final t = DateTime(2024, 1, 1, 10, 15);
      final r = t.copyWith(hour: 20);
      expect(r.isUtc, false);
      expect(r.hour, 20);
    });

    test('can force UTC on local value', () {
      final t = DateTime(2024, 1, 1, 10);
      final r = t.copyWith(utc: true);
      expect(r.isUtc, true);
    });
  });

  group('start/end truncation helpers', () {
    final dt = DateTime.utc(2024, 5, 10, 14, 33, 59, 123, 456);

    test('startOfDay produces midnight', () {
      final r = dt.startOfDay();
      expect(r, DateTime.utc(2024, 5, 10));
    });

    test('endOfDay produces last microsecond of day', () {
      final r = dt.endOfDay();
      expect(r, DateTime.utc(2024, 5, 10, 23, 59, 59, 999, 999));
    });

    test('startOfMonth', () {
      final r = dt.startOfMonth();
      expect(r, DateTime.utc(2024, 5, 1));
    });

    test('endOfMonth', () {
      final r = dt.endOfMonth();
      expect(r, DateTime.utc(2024, 5, 31, 23, 59, 59, 999, 999));
    });

    test('startOfYear', () {
      final r = dt.startOfYear();
      expect(r, DateTime.utc(2024, 1, 1));
    });

    test('endOfYear', () {
      final r = dt.endOfYear();
      expect(r, DateTime.utc(2024, 12, 31, 23, 59, 59, 999, 999));
    });
  });

  group('comparison helpers', () {
    final a = DateTime.utc(2024, 1, 1, 12);
    final b = DateTime.utc(2024, 1, 1, 12);

    test('isBeforeOrSame', () {
      expect(a.isBeforeOrSame(b), true);
      expect(a.isBeforeOrSame(b.add(const Duration(hours: 1))), true);
    });

    test('isAfterOrSame', () {
      expect(a.isAfterOrSame(b), true);
      expect(a.isAfterOrSame(b.subtract(const Duration(hours: 1))), true);
    });
  });

  group('same-day/month/year checks', () {
    test('isSameDay', () {
      expect(
        DateTime.utc(2024, 1, 1).isSameDay(DateTime.utc(2024, 1, 1, 23)),
        true,
      );
      expect(
        DateTime.utc(2024, 1, 1).isSameDay(DateTime.utc(2024, 1, 2)),
        false,
      );
    });

    test('isSameMonth', () {
      expect(
        DateTime.utc(2024, 2, 1).isSameMonth(DateTime.utc(2024, 2, 20)),
        true,
      );
      expect(
        DateTime.utc(2024, 2, 1).isSameMonth(DateTime.utc(2024, 3, 1)),
        false,
      );
    });

    test('isSameYear', () {
      expect(
        DateTime.utc(2024, 1, 1).isSameYear(DateTime.utc(2024, 12, 31)),
        true,
      );
      expect(
        DateTime.utc(2024, 1, 1).isSameYear(DateTime.utc(2025, 1, 1)),
        false,
      );
    });
  });

  group('differenceIn(...) — granular tests', () {
    final a = DateTime.utc(2024, 1, 1, 0, 0, 0);
    final b = DateTime.utc(2025, 4, 1, 12, 0, 0);

    test('years', () {
      expect(a.differenceIn(b, unit: TimeUnit.years), 1);
    });

    test('months', () {
      expect(a.differenceIn(b, unit: TimeUnit.months), 15);
    });

    test('weeks', () {
      final weeks = a.differenceIn(b, unit: TimeUnit.weeks);
      expect(weeks, (b.difference(a).inDays ~/ 7));
    });

    test('days', () {
      expect(a.differenceIn(b, unit: TimeUnit.days), b.difference(a).inDays);
    });

    test('hours', () {
      expect(a.differenceIn(b, unit: TimeUnit.hours), b.difference(a).inHours);
    });

    test('minutes', () {
      expect(
        a.differenceIn(b, unit: TimeUnit.minutes),
        b.difference(a).inMinutes,
      );
    });

    test('seconds', () {
      expect(
        a.differenceIn(b, unit: TimeUnit.seconds),
        b.difference(a).inSeconds,
      );
    });

    test('milliseconds', () {
      expect(
        a.differenceIn(b, unit: TimeUnit.milliseconds),
        b.difference(a).inMilliseconds,
      );
    });

    test('microseconds', () {
      expect(
        a.differenceIn(b, unit: TimeUnit.microseconds),
        b.difference(a).inMicroseconds,
      );
    });
  });

  group('differenceInX convenience methods', () {
    final a = DateTime.utc(2024, 1, 1);
    final b = DateTime.utc(2025, 4, 1);

    test('differenceInYears', () {
      expect(a.differenceInYears(b), 1);
    });

    test('differenceInMonths', () {
      expect(a.differenceInMonths(b), 15);
    });

    test('differenceInWeeks', () {
      final expected = b.difference(a).inDays ~/ 7;
      expect(a.differenceInWeeks(b), expected);
    });

    test('differenceInDays', () {
      expect(a.differenceInDays(b), b.difference(a).inDays);
    });

    test('differenceInHours', () {
      expect(a.differenceInHours(b), b.difference(a).inHours);
    });
  });

  group('UTC/local behavior in getters', () {
    test('startOfDay respects utc: false override', () {
      final t = DateTime.utc(2024, 6, 1, 12);
      final r = t.startOfDay(utc: false);
      expect(r.isUtc, false);
      expect(r.hour, 0);
    });

    test('endOfMonth respects utc: false override', () {
      final t = DateTime.utc(2024, 2, 10);
      final r = t.endOfMonth(utc: false);
      expect(r.isUtc, false);
      expect(r.day, 29);
    });
  });
}
