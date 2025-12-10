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

/// Provides a globally available [Clock] instance that can be temporarily
/// overridden for a specific synchronous execution scope.
///
/// This allows application code to depend on abstracted time sources rather
/// than calling `DateTime.now()` directly.
/// Useful for:
/// - deterministic tests,
/// - time-shifted simulations,
/// - reproducible integration testing,
/// - dependency injection without frameworks.
///
/// The active clock is stored in static mutable state, but changes are
/// always restored after `withClock` completes.
/// {@category clock}
class ClockProvider {
  const ClockProvider._();

  /// The currently active clock instance.
  ///
  /// Defaults to a [SystemClock], but can be replaced using [withClock].
  static Clock current = Clock.system();

  /// Temporarily replaces the globally active [Clock] for the duration of
  /// the provided synchronous callback [fn].
  ///
  /// After the function completes—whether normally or through an exception—
  /// the previous clock will be restored.
  ///
  /// Example:
  /// ```dart
  /// ClockProvider.withClock(FixedClock(DateTime.utc(2025)),
  ///   () {
  ///     print(ClockProvider.current.now()); // Always the fixed time
  ///   },
  /// );
  /// ```
  static T withClock<T>(Clock clock, T Function() fn) {
    final old = current;
    current = clock;
    try {
      return fn();
    } finally {
      current = old;
    }
  }
}

/// Base class for all clock implementations.
///
/// A [Clock] always measures and stores time internally in **UTC**.
/// The user-facing API (`now`, `today`, etc.) can return either:
///
/// - UTC values (`asUtc: true`, the default), or
/// - Local timezone values (`asUtc: false`) derived from the internal UTC time.
///
/// Subclasses implement the core method [_nowUtc], which must return the
/// authoritative UTC timestamp for the specific clock behavior.
abstract class Clock {
  /// Creates a [SystemClock] that uses the system's wall clock time.
  static SystemClock system() => SystemClock();

  /// Creates a [FixedClock] that always returns the same fixed instant.
  static FixedClock fixed(int year, [
    int month = 1,
  int day = 1,
  int hour = 0,
  int minute = 0,
  int second = 0,
  int millisecond = 0,
  int microsecond = 0]) => FixedClock(DateTime.utc(year, month, day, hour, minute, second, millisecond, microsecond));

  /// Creates a [OffsetClock] from system time.
  static OffsetClock offset({
    required int hours,
    int minutes = 0,
    Clock? base,
  }) => OffsetClock(Duration(hours: hours, minutes: minutes), base: base);

  /// Creates a [TickingClock].
  static TickingClock ticking({
    required Duration tick,
    DateTime? start,
  }) => TickingClock(start ?? system().now(asUtc: true), tick);

  /// Creates an [AdjustableClock].
  static AdjustableClock adjustable({DateTime? initial}) => AdjustableClock(initial ?? system().now());

  const Clock();

  /// Returns the current timestamp strictly in **UTC**, representing the
  /// internal authoritative time source.
  ///
  /// Subclasses must implement this method. Implementations should not apply
  /// any local timezone conversions.
  DateTime _nowUtc();

  /// Returns the current time using either UTC or local timezone semantics.
  ///
  /// If [asUtc] is `true` (or omitted), the raw UTC time is returned.
  /// If `false`, the time is converted to the local timezone using `toLocal()`.
  DateTime now({bool? asUtc}) {
    final utc = _nowUtc();
    return (asUtc == null || asUtc == true) ? utc : utc.toLocal();
  }

  /// Returns the current date at midnight based on the internal UTC clock.
  ///
  /// If [asUtc] is `true` (default), the returned value is midnight UTC.
  /// If `false`, the UTC midnight is converted to local time.
  DateTime today({bool? asUtc}) {
    final utc = _nowUtc();
    final t = DateTime.utc(utc.year, utc.month, utc.day);
    return (asUtc == null || asUtc == true) ? t : t.toLocal();
  }

  /// Returns the Unix timestamp in whole seconds.
  ///
  /// This value is always derived from the internal UTC value.
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;

  /// Returns the Unix timestamp in milliseconds.
  ///
  /// The returned value always represents UTC milliseconds.
  int get millisecondsSinceEpoch => now().millisecondsSinceEpoch;

  /// Returns the Unix timestamp in microseconds.
  ///
  /// The returned value always represents UTC microseconds.
  int get microsecondsSinceEpoch => now().microsecondsSinceEpoch;

  /// Returns the timezone offset of the current instant.
  ///
  /// This always reflects the local timezone offset and therefore depends on
  /// converting the internally stored UTC instant to local time.
  Duration get timeZoneOffset => now(asUtc: false).timeZoneOffset;
}

/// A [Clock] that forwards to the system wall-clock time (`DateTime.now()`
/// converted to UTC).
///
/// This clock reflects actual elapsed real world time and cannot be controlled.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime _nowUtc() => DateTime.now().toUtc();
}

/// A [Clock] that always returns the same fixed moment in time.
///
/// Useful for deterministic testing and reproducible snapshots.
class FixedClock extends Clock {
  /// The fixed instant stored in UTC.
  final DateTime _fixedUtc;

  FixedClock(DateTime fixed) : _fixedUtc = fixed.toUtc();

  @override
  DateTime _nowUtc() => _fixedUtc;
}

/// A [Clock] that applies a fixed [offset] to a base clock.
///
/// By default the base clock is a [SystemClock], but any other custom [Clock]
/// implementation may be provided.
/// Useful for time travel simulation or creating clocks in different
/// "virtual time zones."
class OffsetClock extends Clock {
  /// The base clock providing the underlying source time.
  final Clock base;

  /// The amount of time added to the base clock's UTC instant.
  final Duration offset;

  OffsetClock(this.offset, {Clock? base}) : base = base ?? const SystemClock();

  @override
  DateTime _nowUtc() => base.now().add(offset);
}

/// A manually adjustable clock whose time can be explicitly set or advanced.
///
/// This is ideal for:
/// - Testing complex temporal logic,
/// - Advancing time deterministically without delays,
/// - Simulating long-running processes.
class AdjustableClock extends Clock {
  /// The current UTC instant maintained by the clock.
  DateTime _currentUtc;

  AdjustableClock(DateTime initial) : _currentUtc = initial.toUtc();

  /// Sets the current time to the provided [newValue] (converted to UTC).
  void set(DateTime newValue) => _currentUtc = newValue.toUtc();

  /// Advances the clock by the given duration.
  void advance(Duration d) => _currentUtc = _currentUtc.add(d);

  @override
  DateTime _nowUtc() => _currentUtc;
}

/// A [Clock] that increments its time by a fixed [tick] duration with every
/// call to [now] or [nowUtc].
///
/// The first call returns the initial value; each subsequent call returns
/// the next ticked value.
/// This is especially useful for testing logic that expects time to move
/// predictably without using artificial delays.
class TickingClock extends Clock {
  /// Amount of time added per call.
  final Duration tick;

  /// Internal UTC time that will be returned on the next call.
  DateTime _currentUtc;

  TickingClock(DateTime start, this.tick) : _currentUtc = start.toUtc();

  @override
  DateTime _nowUtc() {
    final c = _currentUtc;
    _currentUtc = _currentUtc.add(tick);
    return c;
  }
}
