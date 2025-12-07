import 'package:clockwork/clockwork.dart';
import 'package:test/test.dart';

void main() {
  group('ISO8601TimespanParser.parse', () {
    test('parses full date+time example P3Y6M4DT12H30M5S', () {
      final t = Timespan.parse('P3Y6M4DT12H30M5S');
      expect(t.years, 3);
      expect(t.months, 6);
      expect(t.weeks, 0);
      expect(t.days, 4);
      expect(t.hours, 12);
      expect(t.minutes, 30);
      expect(t.seconds, 5);
      expect(t.milliseconds, 0);
      expect(t.microseconds, 0);
      expect(t.nanoseconds, 0);
    });

    test('parses weeks only P2W', () {
      final t = Timespan.parse('P2W');
      expect(t.weeks, 2);
      expect(t.days, 0);
    });

    test('parses time only PT10S', () {
      final t = Timespan.parse('PT10S');
      expect(t.seconds, 10);
    });

    test('parses months only P1M (date part M)', () {
      final t = Timespan.parse('P1M');
      expect(t.months, 1);
      expect(t.minutes, 0);
    });

    test('throws on invalid ISO8601 string', () {
      expect(
        () => Timespan.parse('PX'),
        throwsA(isA<TimespanParseException>()),
      );
    });
  });

  group('SimpleUnitTimespanParser.parse (Go-style/simple units)', () {
    test('single unit seconds', () {
      final t = Timespan.parse('10s');
      expect(t.seconds, 10);
    });

    test('milliseconds', () {
      final t = Timespan.parse('250ms');
      expect(t.milliseconds, 250);
    });

    test('hours and minutes combined', () {
      final t = Timespan.parse('1h30m');
      expect(t.hours, 1);
      expect(t.minutes, 30);
    });

    test('fractional seconds (10.5s)', () {
      final t = Timespan.parse('10.5s');
      expect(t.seconds, 10);
      expect(t.milliseconds, 500);
      expect(t.microseconds, 0);
      expect(t.nanoseconds, 0);
    });

    test('fractional milliseconds (1.5ms)', () {
      final t = Timespan.parse('1.5ms');
      expect(t.milliseconds, 1);
      expect(t.microseconds, 500);
      expect(t.nanoseconds, 0);
    });

    test('fractional microseconds (1.5us)', () {
      final t = Timespan.parse('1.5us');
      expect(t.microseconds, 1);
      expect(t.nanoseconds, 500);
    });

    test('nanoseconds (500ns)', () {
      final t = Timespan.parse('500ns');
      expect(t.nanoseconds, 500);
    });

    test('days supported (2d)', () {
      final t = Timespan.parse('2d');
      expect(t.days, 2);
    });

    test('composite units across all supported (1d2h3m4s5ms6us7ns)', () {
      final t = Timespan.parse('1d2h3m4s5ms6us7ns');
      expect(t.days, 1);
      expect(t.hours, 2);
      expect(t.minutes, 3);
      expect(t.seconds, 4);
      expect(t.milliseconds, 5);
      expect(t.microseconds, 6);
      expect(t.nanoseconds, 7);
    });

    test('throws on completely invalid simple-unit input', () {
      // No number + unit pair present at all
      expect(
        () => Timespan.parse('abc'),
        throwsA(isA<TimespanParseException>()),
      );
    });
  });

  group('Timespan.toDuration', () {
    test(
      'computes calendar-aware years/months and exact time with reference',
      () {
        final start = DateTime.utc(2023, 1, 15, 12, 0, 0, 0, 0);
        final t = Timespan(
          years: 1,
          months: 2,
          weeks: 1,
          days: 3,
          hours: 4,
          minutes: 5,
          seconds: 6,
          milliseconds: 7,
          microseconds: 8,
          nanoseconds: 900, // contributes 0 microseconds (integer division)
        );

        final actual = t.toDuration(start: start);
        expect(actual.inDays, 435);
        expect(actual.inHours, 10444);
        expect(actual.inMinutes, 626645);
        expect(actual.inSeconds, 37598706);
        expect(actual.inMilliseconds, 37598706007);
        expect(actual.inMicroseconds, 37598706007008);
      },
    );

    test('leap year: 1 year starting before Feb 29 (2024-01-01)', () {
      // 2024 is a leap year.
      final start = DateTime.utc(2024, 1, 1);
      final t = Timespan(years: 1);
      // From Jan 1 2024 to Jan 1 2025 includes Feb 29, 2024.
      // Should be 366 days.
      expect(t.toDuration(start: start).inDays, 366);
    });

    test('leap year: 1 year starting after Feb 29 (2024-03-01)', () {
      // 2024 is a leap year, but we start after the leap day.
      final start = DateTime.utc(2024, 3, 1);
      final t = Timespan(years: 1);
      // From Mar 1 2024 to Mar 1 2025 (2025 is common).
      // Does not include a Feb 29. Should be 365 days.
      expect(t.toDuration(start: start).inDays, 365);
    });

    test('leap year: 1 month starting Feb 1 (2024-02-01)', () {
      final start = DateTime.utc(2024, 2, 1);
      final t = Timespan(months: 1);
      // Feb 2024 has 29 days.
      expect(t.toDuration(start: start), Duration(days: 29));
    });

    test('common year: 1 month starting Feb 1 (2023-02-01)', () {
      final start = DateTime.utc(2023, 2, 1);
      final t = Timespan(months: 1);
      // Feb 2023 has 28 days.
      expect(t.toDuration(start: start).inDays, 28);
    });

    test('multiple leap years passed: 3 years spanning 2023→2026', () {
      // 2024 is a leapyear, 2025 is not.
      // Period: 2023-01-01 to 2026-01-01
      // Including leapdays 2024-02-29 totals 365 + 366 + 365 = 1096 dagen
      final start = DateTime.utc(2023, 1, 1);
      final t = Timespan(years: 3);

      expect(t.toDuration(start: start).inDays, 1096);
    });

    test('multiple leap years passed but start after leap day so skip one', () {
      // 2024 is a leapday but the start is after 29th
      // Period: 2024-03-01 to 2027-03-01
      // 2024: rest of year without leapday
      // 2025: 365
      // 2026: 365
      // 2027: until 03-01 (no extra day)
      //
      // Total: 365 + 365 + 365 = 1095 dagen.
      final start = DateTime.utc(2024, 3, 1);
      final t = Timespan(years: 3);

      expect(t.toDuration(start: start).inDays, 1095);
    });

    test(
      'leap day only counted when crossed: spanning Feb 28→Mar 1 in leap year',
      () {
        // 2024 is a leapyear.
        // Feb 28 12:00 to Mar 1 12:00 includes 1 extra (leap)day (29 feb).
        final start = DateTime.utc(2024, 2, 28, 12);
        final t = Timespan(days: 2); // 28→29, 29→1

        expect(t.toDuration(start: start).inDays, 2);
      },
    );

    test('leap day NOT counted if Timespan ends before it', () {
      // 2024-02-27 +1 day = 2024-02-28
      // Leap day 29 feb is not reached
      final start = DateTime.utc(2024, 2, 27);
      final t = Timespan(days: 1);

      expect(t.toDuration(start: start).inDays, 1);
    });

    test(
      'adding 1 month across Feb 29: Jan 29 2024 + 1M = Feb 29 (leap day)',
      () {
        final start = DateTime.utc(2024, 1, 29);

        // Adding a month in leap year:
        // Jan 29 + 1M = Feb 29 (best effort date clamping)
        final t = Timespan(months: 1);

        final actual = t.toDuration(start: start);
        // Jan 29 to Feb 29 = 31 dagen
        expect(actual.inDays, 31);
      },
    );

    test(
      'adding 1 month across Feb in common year: Jan 29 2023 + 1M → Feb 28',
      () {
        final start = DateTime.utc(2023, 1, 29);
        final t = Timespan(months: 1);

        final actual = t.toDuration(start: start);
        // Jan 29 to Feb 28 = 30 dagen
        expect(actual.inDays, 30);
      },
    );

    test('adding 10 years crossing exactly two leap years (2016 and 2020)', () {
      // Start after 29 feb to include leapdays
      final start = DateTime.utc(2015, 3, 1);
      final t = Timespan(years: 10);

      // 10 years: 3650 days + 3 leapdays (2016, 2020, 2024)
      expect(t.toDuration(start: start).inDays, 3653);
    });
  });
}
