import 'package:test/test.dart';
import 'package:clockwork/clockwork.dart';

void main() {
  group('FixedClock', () {
    test('returns fixed UTC time regardless of calls', () {
      // Given
      final clock = FixedClock(DateTime.utc(2025, 1, 1, 12, 0, 0));

      // Expect
      expect(clock.now(asUtc: true), DateTime.utc(2025, 1, 1, 12));
      expect(clock.now(asUtc: true), DateTime.utc(2025, 1, 1, 12));

      // And - Local representation should match UTC but converted to local zone
      final local = clock.now(asUtc: false);
      expect(local.isUtc, false);
      expect(local.toUtc(), DateTime.utc(2025, 1, 1, 12));
    });
  });

  group('SystemClock', () {
    test('now() returns current UTC time', () {
      // Given
      final clock = SystemClock();

      // When
      final a = clock.now(asUtc: true);
      final b = DateTime.now().toUtc();

      // Then - Should be within a second
      expect((a.difference(b)).inSeconds.abs() <= 1, true);
    });
  });

  group('OffsetClock', () {
    test('applies offset on base clock', () {
      // Given
      final start = DateTime.utc(2025, 1, 1, 10);
      final base = FixedClock(start);
      final offset = Duration(hours: 2);
      final clock = OffsetClock(offset, base: base);

      // When
      final time = clock.now(asUtc: true);

      // Then
      final timeWithOffset = DateTime.utc(2025, 1, 1, 12);
      expect(time, timeWithOffset);
      expect(clock.now(asUtc: false).toUtc(), time);
      expect(timeWithOffset.difference(start).inHours, 2);
    });

    test('defaults to SystemClock when no base clock is provided', () {
      // Given
      final offset = Duration(hours: 1);
      final offsetClock = OffsetClock(offset);
      final systemClock = DateTime.now().toUtc().add(offset);

      // Expect - identical times
      expect(
        offsetClock.now(asUtc: true).difference(systemClock).inSeconds.abs() <=
            1,
        true,
      );
    });
  });

  group('AdjustableClock', () {
    test('set() replaces current time', () {
      // When
      final time = DateTime.utc(2025, 1, 1, 10);
      final clock = AdjustableClock(time);

      // Then
      expect(clock.now(asUtc: true), time);

      // When
      final adjusted = DateTime.utc(2030, 1, 1, 15);
      clock.set(adjusted);

      // Then
      expect(clock.now(asUtc: true), adjusted);
    });

    test('advance() moves time forward', () {
      // Given
      final time = DateTime.utc(2025, 1, 1, 10);
      final clock = AdjustableClock(time);

      // When
      clock.advance(Duration(hours: 3));

      // Then
      expect(clock.now(asUtc: true), DateTime.utc(2025, 1, 1, 13));
    });

    test('local view returns local conversion', () {
      // Given
      final clock = AdjustableClock(DateTime.utc(2025, 1, 1, 10));
      final local = clock.now(asUtc: false);

      // Expect
      expect(local.toUtc(), DateTime.utc(2025, 1, 1, 10));
      expect(local.isUtc, false);
    });
  });

  group('TickingClock', () {
    test('each call to now() advances by tick', () {
      // Given
      final time = DateTime.utc(2025, 1, 1, 0);
      final clock = TickingClock(time, Duration(minutes: 5));

      // Expect
      final t1 = clock.now(asUtc: true);
      expect(t1, DateTime.utc(2025, 1, 1, 0));

      // And - Add a tick 5 minutes
      final t2 = clock.now(asUtc: true);
      expect(t2, DateTime.utc(2025, 1, 1, 0, 5));

      // And - Add another tick 5 minutes
      final t3 = clock.now(asUtc: true);
      expect(t3, DateTime.utc(2025, 1, 1, 0, 10));
    });

    test('local view still maps to correct UTC value', () {
      // Given
      final time = DateTime.utc(2025, 1, 1, 0);
      final clock = TickingClock(time, Duration(hours: 1));

      // Then
      final local = clock.now(asUtc: false);
      expect(local.toUtc(), time);

      // And - Add a tick of 1 hour
      final local2 = clock.now(asUtc: false);
      expect(local2.toUtc(), DateTime.utc(2025, 1, 1, 1));
    });
  });

  group('StopwatchClock', () {
    test('advances based on elapsed stopwatch time', () async {
      // Given
      final stopwatch = Stopwatch()..start();
      final origin = DateTime.utc(2025, 1, 1, 0);
      final clock = StopwatchClock(sw: stopwatch, origin: origin);

      // When
      final t1 = clock.now(asUtc: true);

      // Then
      expect((t1.difference(origin).inMilliseconds).abs() < 50, true);

      // When
      await Future.delayed(Duration(milliseconds: 120));

      // Then
      final t2 = clock.now(asUtc: true);
      expect((t2.difference(origin).inMilliseconds) >= 100, true);
    });

    test('local representation is valid', () async {
      // Given
      final stopwatch = Stopwatch()..start();
      final origin = DateTime.utc(2025, 1, 1, 12, 0);
      final clock = StopwatchClock(sw: stopwatch, origin: origin);

      // When
      await Future.delayed(Duration(milliseconds: 10));
      final local = clock.now(asUtc: false);

      // Then
      expect(local.isUtc, false);
      expect(local.toUtc().isAfter(origin), true);
    });
  });
}
