// Copyright (c) 2021 - 2025 Buijs Software
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

class ClockProvider {
  const ClockProvider._();

  static Clock current = Clock.system();

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

abstract class Clock {
  static Clock system() => SystemClock();

  static Clock fixed(DateTime fixedTime) => FixedClock(fixedTime);

  static Clock offset(Duration offset) => OffsetClock(offset);

  const Clock();

  /// Onderliggende interne tijd → ALTIJD UTC
  DateTime _nowUtc();

  /// Publieke API: keuze tussen UTC of locale view
  DateTime now({bool? asUtc}) {
    final utc = _nowUtc();
    return (asUtc == null || asUtc == true) ? utc : utc.toLocal();
  }

  /// Utc-variant altijd direct beschikbaar
  DateTime nowUtc() => _nowUtc();

  /// Vandaag om middernacht — intern UTC, maar om te zetten afhankelijk van param
  DateTime today({bool? asUtc}) {
    final utc = _nowUtc();
    final t = DateTime.utc(utc.year, utc.month, utc.day);
    return (asUtc == null || asUtc == true) ? t : t.toLocal();
  }

  int secondsSinceEpoch({bool? asUtc}) =>
      millisecondsSinceEpoch(asUtc: asUtc) ~/ 1000;

  int millisecondsSinceEpoch({bool? asUtc}) =>
      now(asUtc: true).millisecondsSinceEpoch;

  int microsecondsSinceEpoch({bool? asUtc}) =>
      now(asUtc: true).microsecondsSinceEpoch;

  /// Timezone offset — dus locale-based
  Duration timeZoneOffset({bool? asUtc}) => now(asUtc: false).timeZoneOffset;
}

class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime _nowUtc() => DateTime.now().toUtc();
}

class FixedClock extends Clock {
  final DateTime _fixedUtc;

  FixedClock(DateTime fixed) : _fixedUtc = fixed.toUtc();

  @override
  DateTime _nowUtc() => _fixedUtc;
}

class OffsetClock extends Clock {
  final Clock base;
  final Duration offset;

  OffsetClock(this.offset, {Clock? base}) : base = base ?? const SystemClock();

  @override
  DateTime _nowUtc() => base.nowUtc().add(offset);
}

class AdjustableClock extends Clock {
  DateTime _currentUtc;

  AdjustableClock(DateTime initial) : _currentUtc = initial.toUtc();

  void set(DateTime newValue) => _currentUtc = newValue.toUtc();

  void advance(Duration d) => _currentUtc = _currentUtc.add(d);

  @override
  DateTime _nowUtc() => _currentUtc;
}

class TickingClock extends Clock {
  final Duration tick;
  DateTime _currentUtc;

  TickingClock(DateTime start, this.tick) : _currentUtc = start.toUtc();

  @override
  DateTime _nowUtc() {
    final c = _currentUtc;
    _currentUtc = _currentUtc.add(tick);
    return c;
  }
}

class StopwatchClock extends Clock {
  final Stopwatch _sw;
  final DateTime _originUtc;

  StopwatchClock({Stopwatch? sw, DateTime? origin})
    : _sw = sw ?? (Stopwatch()..start()),
      _originUtc = (origin ?? DateTime.now()).toUtc();

  @override
  DateTime _nowUtc() => _originUtc.add(_sw.elapsed);
}
