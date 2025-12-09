import 'package:clockwork/clockwork.dart';
import 'package:test/test.dart';

void main() {
  group('ISO8601TimespanParser successfully parses', () {
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

    test('parses weeks only p2w', () {
      final t = Timespan.parse('p2w');
      expect(t.weeks, 2);
      expect(t.days, 0);
    });

    test('parses time only PT10S', () {
      final t = Timespan.parse('PT10S');
      expect(t.seconds, 10);
    });

    test('parses time only pt10s', () {
      final t = Timespan.parse('pt10s');
      expect(t.seconds, 10);
    });

    test('parses months only P1M (date part M)', () {
      final t = Timespan.parse('P1M');
      expect(t.months, 1);
      expect(t.minutes, 0);
    });

    test('parses months only p1m (date part m', () {
      final t = Timespan.parse('p1m');
      expect(t.months, 1);
      expect(t.minutes, 0);
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

    test('composite units across all supported case-insensitive', () {
      final t = Timespan.parse('1D2H3M4S5MS6US7NS');
      expect(t.days, 1);
      expect(t.hours, 2);
      expect(t.minutes, 3);
      expect(t.seconds, 4);
      expect(t.milliseconds, 5);
      expect(t.microseconds, 6);
      expect(t.nanoseconds, 7);
    });
  });
}
