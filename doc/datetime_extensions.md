### DateTime Extensions

Clockwork adds extension methods to `DateTime` for calendar‑aware manipulation, rounding/truncation, comparisons, and ISO week helpers. These work with both UTC and local `DateTime` instances and preserve the timezone of the receiver.

#### Core utilities

- `copyWith({year, month, day, hour, minute, second, millisecond, microsecond})`
- `atTime(h, m, [s, ms, us])`
- `roundToMinute()`
- `toMidday()`
- `secondsSinceEpoch`
- `isBeforeOrSame(other)`, `isAfterOrSame(other)`

#### Day/Month/Year helpers

- `startOfDay()`, `endOfDay()`
- `startOfMonth()`, `endOfMonth()`
- `startOfYear()`, `endOfYear()`
- `addMonths(count)` — clamps the day (Jan 31 + 1 → Feb 28/29)
- `addYears(count)` — adjusts Feb 29 → Feb 28 if necessary
- `isSameDay(other)`, `isSameMonth(other)`, `isSameYear(other)`
- `isLeapYear`, `isLeapMonth`, `isLeapDay`

#### Week and quarter

- `startOfWeek()`, `endOfWeek()` — Monday as first day
- `isoWeekDay` — 1..7 (Mon..Sun)
- `startOfISOWeek()`, `endOfISOWeek()`
- `isoWeek`, `isoWeekYear` — ISO‑8601 week numbering
- `quarter` (1..4), `startOfQuarter()`, `endOfQuarter()`
- `nextQuarter()`, `previousQuarter()`

#### Ranges and navigation

- `clamp(min, max)` — bounds this instance to a range
- `between(start, end)` — inclusive range check
- `nextWeekday(weekday)` / `previousWeekday(weekday)` — 1=Mon … 7=Sun

#### Differences

Use `differenceIn(other, unit: TimeUnit.*)` to calculate absolute distance in the chosen unit. Convenience wrappers exist:

- `differenceInYears`, `differenceInMonths`, `differenceInWeeks`, `differenceInDays`, `differenceInHours`, `differenceInMinutes`, `differenceInSeconds`, `differenceInMilliseconds`, `differenceInMicroseconds`

Notes:

- `months` and `years` differences use calendar math based on year/month components, not `Duration`.
- `weeks` uses `days ~/ 7`.

#### Examples

```dart
import 'package:clockwork/clockwork.dart';

final d = DateTime.utc(2025, 1, 31, 23, 40, 45);
print(d.roundToMinute());          // 2025-01-31 23:41:00.000Z
print(d.startOfMonth());           // 2025-01-01 00:00:00.000Z
print(d.endOfMonth());             // 2025-01-31 23:59:59.999999Z
print(d.addMonths(1));             // 2025-02-28 23:40:45.000Z

final other = DateTime.utc(2024, 12, 31);
print(d.differenceInDays(other));  // absolute days between d and other

final mon = d.startOfISOWeek();
final sun = d.endOfISOWeek();
```