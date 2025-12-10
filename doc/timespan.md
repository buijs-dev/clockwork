### Timespan
`Timespan` represents a calendar‑aware, multi‑unit span of time. Unlike `Duration` (pure microseconds), `Timespan` preserves calendar components such as years and months and converts to a concrete `Duration` relative to a reference date.

#### Fields
- `years`, 
- `months`, 
- `weeks`, 
- `days`
- `hours`, 
- `minutes`, 
- `seconds`, 
- `milliseconds`, 
- `microseconds`, 
- `nanoseconds`

#### Construction

```dart
import 'package:clockwork/clockwork.dart';

const span = Timespan(years: 1, months: 2, days: 3);
final copy = span.copyWith(days: 10);
```

#### Parsing

See parsing.md for ISO‑8601 and simple unit formats. Quick examples:

```dart
final iso = Timespan.parse('P3Y6M4DT12H30M5S');
final simple = Timespan.parse('1h30m');
```

#### Converting to Duration

Because months and years vary in length, `toDuration` requires a `start` reference to compute a concrete `Duration`.

```dart
final start = DateTime.utc(2025, 1, 31);
final oneMonth = Timespan(months: 1);
final dur = oneMonth.toDuration(start: start); // accounts for Feb length
```

Notes:

- Calendar units (`years`, `months`, `weeks`, `days`) are applied first by date arithmetic, then sub‑day units are added as a `Duration`.
- Nanoseconds are accumulated into microseconds where possible.