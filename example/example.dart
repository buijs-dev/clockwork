// ignore_for_file: avoid_print

import 'package:clockwork/clockwork.dart';

/// This example demonstrates the full public API available in `lib/src`:
/// - Clock and ClockProvider utilities
/// - DateTime extension helpers
/// - Timespan, parsing (ISO-8601 and simple/go-style), and exceptions
///
/// Run with: `dart run example/example.dart`
void main() {
  print('--- ClockProvider & Clocks ---');
  _clockExamples();

  print('\n--- DateTime extensions ---');
  _dateTimeExtensionExamples();

  print('\n--- Timespan & Parsers ---');
  _timespanExamples();
}

void _clockExamples() {
  // System clock (default)
  final sys = Clock.system();
  print('System now UTC:   \'${sys.nowUtc()}\'');
  print('System today UTC: \'${sys.today()}\'');
  print('Seconds since epoch: ${sys.secondsSinceEpoch()}');
  print('Millis since epoch:  ${sys.millisecondsSinceEpoch()}');
  print('Micros since epoch:  ${sys.microsecondsSinceEpoch()}');
  print('Local timezone offset (Duration): ${sys.timeZoneOffset()}');

  // Fixed clock
  final fixedInstant = DateTime.utc(2025, 12, 31, 23, 59, 59);
  final fixed = Clock.fixed(fixedInstant);
  print('Fixed now UTC:    \'${fixed.nowUtc()}\'');
  print('Fixed today UTC:  \'${fixed.today()}\'');

  // Offset clock (+2h from system)
  final offset = Clock.offset(const Duration(hours: 2));
  print('Offset(+2h) now UTC: \'${offset.nowUtc()}\' (base: system+2h)');

  // Adjustable clock
  final adjustable = Clock.adjustable(initial: DateTime.utc(2000, 1, 1));
  print('Adjustable start: \'${adjustable.nowUtc()}\'');
  adjustable.advance(const Duration(days: 10));
  print('Adjustable +10d:  \'${adjustable.nowUtc()}\'');
  adjustable.set(DateTime.utc(1999, 12, 31, 12));
  print('Adjustable set:   \'${adjustable.nowUtc()}\'');

  // Ticking clock (ticks +500ms every call)
  final ticking = Clock.ticking(DateTime.utc(2025, 1, 1), const Duration(milliseconds: 500));
  print('Tick 1: ${ticking.nowUtc()}');
  print('Tick 2: ${ticking.nowUtc()}');
  print('Tick 3: ${ticking.nowUtc()}');

  // Stopwatch clock
  final sw = Stopwatch()..start();
  final swClock = Clock.stopwatch(sw: sw, origin: DateTime.utc(2025, 1, 1));
  // Wait a tiny moment without async: do a small busy loop to elapse some time
  for (var i = 0; i < 100000; i++) {
    // noop to spend some CPU cycles
  }
  print('Stopwatch origin+elapsed: ${swClock.nowUtc()}');

  // ClockProvider.withClock for a temporary global override
  final before = ClockProvider.current;
  final result = ClockProvider.withClock(fixed, () {
    // Within this callback, ClockProvider.current points to our fixed clock
    final insideNow = ClockProvider.current.nowUtc();
    print('Inside withClock: $insideNow (should equal fixed)');
    return 'done';
  });
  print('withClock result: $result');
  print('Restored provider equals before: ${identical(ClockProvider.current, before)}');
}

void _dateTimeExtensionExamples() {
  // Base timestamps
  final utc = DateTime.utc(2025, 2, 28, 23, 45, 30, 123, 456);
  final local = DateTime(2025, 12, 15, 8, 30);

  // Basic getters/utilities
  print('secondsSinceEpoch (utc): ${utc.secondsSinceEpoch}');
  print('isBeforeOrSame: ${utc.isBeforeOrSame(utc)}');
  print('isAfterOrSame:  ${utc.isAfterOrSame(utc)}');

  // Copy/override fields
  final copy = utc.copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0);
  print('copyWith rounded hour: $copy');

  // Day helpers
  print('startOfDay: ${utc.startOfDay()}');
  print('endOfDay:   ${utc.endOfDay()}');
  print('roundToMinute: ${utc.roundToMinute()}');
  print('floorToMinute: ${utc.floorToMinute()}');
  print('isLeapDay (Feb29?): ${DateTime.utc(2024, 2, 29).isLeapDay}');
  print('isLeapMonth (Feb?): ${utc.isLeapMonth}');
  print('isLeapYear: ${utc.isLeapYear}');
  print('isWeekend: ${utc.isWeekend}, isWeekday: ${utc.isWeekday}');
  print('isSameDay: ${utc.isSameDay(utc.copyWith(hour: 0))}');
  print('isSameMonth: ${utc.isSameMonth(utc.copyWith(day: 1))}');
  print('isSameYear: ${utc.isSameYear(utc.copyWith(month: 1, day: 1))}');

  // Month helpers
  print('startOfMonth: ${utc.startOfMonth()}');
  print('endOfMonth:   ${utc.endOfMonth()}');
  print('addMonths(+1): ${utc.addMonths(1)}');
  print('addMonths(-1): ${utc.addMonths(-1)}');

  // Year helpers
  print('startOfYear: ${utc.startOfYear()}');
  print('endOfYear:   ${utc.endOfYear()}');
  print('addYears(+1): ${utc.addYears(1)}');
  print('addYears(-1): ${utc.addYears(-1)}');

  // Week helpers
  print('startOfWeek: ${utc.startOfWeek()}');
  print('endOfWeek:   ${utc.endOfWeek()}');

  // ISO week helpers
  print('startOfISOWeek: ${utc.startOfISOWeek()}');
  print('endOfISOWeek:   ${utc.endOfISOWeek()}');
  print('isoWeekYear: ${utc.isoWeekYear}');
  print('isoWeekNumber: ${utc.isoWeekNumber}');

  // Quarter helpers
  print('quarter: ${utc.quarter}');
  print('startOfQuarter: ${utc.startOfQuarter()}');
  print('endOfQuarter:   ${utc.endOfQuarter()}');
  print('nextQuarter:    ${utc.nextQuarter()}');
  print('previousQuarter:${utc.previousQuarter()}');

  // Extra utilities
  final min = utc.copyWith(day: 1);
  final max = utc.copyWith(day: 30);
  final mid = utc.copyWith(day: 15);
  print('clamp(min,max) of mid-day: ${mid.clamp(min, max)}');
  print('atTime to 12:34: ${utc.atTime(12, 34)}');
  print('nextWeekday(Mon) from local: ${local.nextWeekday(DateTime.monday)}');
  print('previousWeekday(Mon) from local: ${local.previousWeekday(DateTime.monday)}');
  final rangeStart = utc.startOfMonth();
  final rangeEnd = utc.endOfMonth();
  print('between in month: ${utc.between(rangeStart, rangeEnd)}');
  print('toMidday: ${utc.toMidday()}');

  // Differences
  final other = utc.add(const Duration(days: 40, hours: 3, minutes: 10, seconds: 5));
  print('differenceIn years:  ${utc.differenceIn(other, unit: TimeUnit.years)}');
  print('differenceIn months: ${utc.differenceIn(other, unit: TimeUnit.months)}');
  print('differenceIn weeks:  ${utc.differenceIn(other, unit: TimeUnit.weeks)}');
  print('differenceIn days:   ${utc.differenceIn(other, unit: TimeUnit.days)}');
  print('differenceIn hours:  ${utc.differenceIn(other, unit: TimeUnit.hours)}');
  print('differenceIn minutes:${utc.differenceIn(other, unit: TimeUnit.minutes)}');
  print('differenceIn seconds:${utc.differenceIn(other, unit: TimeUnit.seconds)}');
  print('differenceIn millis: ${utc.differenceIn(other, unit: TimeUnit.milliseconds)}');
  print('differenceIn micros: ${utc.differenceIn(other, unit: TimeUnit.microseconds)}');

  // Difference shortcuts
  print('differenceInYears:        ${utc.differenceInYears(other)}');
  print('differenceInMonths:       ${utc.differenceInMonths(other)}');
  print('differenceInWeeks:        ${utc.differenceInWeeks(other)}');
  print('differenceInDays:         ${utc.differenceInDays(other)}');
  print('differenceInHours:        ${utc.differenceInHours(other)}');
  print('differenceInMinutes:      ${utc.differenceInMinutes(other)}');
  print('differenceInSeconds:      ${utc.differenceInSeconds(other)}');
  print('differenceInMilliseconds: ${utc.differenceInMilliseconds(other)}');
  print('differenceInMicroseconds: ${utc.differenceInMicroseconds(other)}');
}

void _timespanExamples() {
  // Constructing a Timespan directly
  const span = Timespan(years: 1, months: 2, days: 3, hours: 4, minutes: 5, seconds: 6);
  print('Timespan constructed: $span');

  // Convert to a concrete Duration using a reference date (UTC)
  final reference = DateTime.utc(2025, 1, 31, 10, 0, 0);
  final asDuration = span.toDuration(start: reference);
  print('Timespan.toDuration from 2025-01-31T10:00Z => $asDuration');

  // Parsing ISO-8601 durations
  final isoParser = const ISO8601TimespanParser();
  final iso = isoParser.parse('P3Y6M4DT12H30M5S');
  print('Parsed ISO-8601: $iso -> toDuration(ref Jan31) = ${iso.toDuration(start: reference)}');

  // Parsing simple/go-style durations
  final simpleParser = const SimpleUnitTimespanParser();
  final simple = simpleParser.parse('1h30m10.5s');
  print('Parsed simple: $simple -> toDuration = ${simple!.toDuration(start: reference)}');

  // Using Timespan.parse auto-detection
  final auto1 = Timespan.parse('PT45S');
  final auto2 = Timespan.parse('2h15m');
  print('Timespan.parse ISO: $auto1, simple: $auto2');

  // Handling parse errors
  try {
    Timespan.parse('not-a-duration');
  } on TimespanParseException catch (e) {
    print('Caught TimespanParseException: ${e.message}');
  }
}
