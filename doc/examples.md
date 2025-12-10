### Examples and Recipes

This page shows small, focused examples combining Clockwork features.

#### Override time globally in a scope

```dart
import 'package:clockwork/clockwork.dart';

void main() {
  final fixed = FixedClock(DateTime.utc(2025, 1, 1));
  ClockProvider.withClock(fixed, () {
    print(ClockProvider.current.now());  // 2025-01-01 00:00:00.000Z
  });
}
```

#### Add one calendar month with clamping

```dart
import 'package:clockwork/clockwork.dart';

final d = DateTime.utc(2025, 1, 31, 12);
print(d.addMonths(1));                  // 2025-02-28 12:00:00.000Z
```

#### ISO week helpers

```dart
import 'package:clockwork/clockwork.dart';

final d = DateTime.utc(2025, 1, 1);
print(d.isoWeekYear);                   // e.g., 2025 or 2024 depending on ISO rules
print(d.isoWeek);                       // ISO week number
print(d.startOfISOWeek());              // Monday 00:00:00.000000
print(d.endOfISOWeek());                // Sunday 23:59:59.999999
```

#### Parse duration strings

```dart
import 'package:clockwork/clockwork.dart';

final a = Timespan.parse('PT45M');      // ISO‑8601
final b = Timespan.parse('1h30m');      // simple units

final start = DateTime.utc(2025, 1, 31);
final oneMonth = Timespan.parse('P1M');
final elapsed = oneMonth.toDuration(start: start);
```

#### Ticking clock for deterministic progression

```dart
import 'package:clockwork/clockwork.dart';

final ticking = Clock.ticking(DateTime.utc(2025, 1, 1), const Duration(seconds: 1));
print(ticking.nowUtc());                // 00:00:00
print(ticking.nowUtc());                // 00:00:01
print(ticking.nowUtc());                // 00:00:02
```