### Parsing Durations

Clockwork parses two syntax families into `Timespan`:

1) ISO‑8601 duration strings (e.g., `P3Y6M4DT12H30M5S`, `PT15M`, `P2W`)
2) Simple/Go‑style unit strings (e.g., `1h30m`, `250ms`, `2d`, `1.5s`)

Both parsers are case‑insensitive for unit letters.

#### Quick start

```dart
import 'package:clockwork/clockwork.dart';

final iso = Timespan.parse('P2DT3H4M');    // 2 days, 3 hours, 4 minutes
final simple = Timespan.parse('1h30m');    // 1 hour, 30 minutes
```

#### ISO‑8601

Pattern: `P(n)Y (n)M (n)W (n)D T(n)H (n)M (n)S`

- `P` starts the period
- Date part: `Y` years, `M` months, `W` weeks, `D` days
- `T` starts the time part
- Time part: `H` hours, `M` minutes, `S` seconds

Examples:

- `PT15M` → 15 minutes
- `PT1H30M` → 1 hour, 30 minutes
- `P2DT3H4M` → 2 days, 3 hours, 4 minutes

#### Simple unit format

- Units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`
- Segments may be combined: `1h30m10s`
- Fractions supported on seconds: `1.5s` (1 s + 500 ms)

Examples:

- `1ns`, `250ms`, `10s`, `5m`, `2h`, `1d`
- `2h15m10.5s`

#### Errors

If parsing fails, a `TimespanParseException` is thrown by `parseOrThrow` or returned as `null` by the parser’s `parse` method.

```dart
final parser = ISO8601TimespanParser();
final span = parser.parse('PX');        // returns null
// parser.parseOrThrow('PX');           // throws TimespanParseException
```

#### Converting to Duration

Parsed `Timespan` values preserve calendar units. Convert to a concrete `Duration` using `toDuration(start: ...)` when you need elapsed time accounting for month lengths and leap years.