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
import 'timespan.dart';

const _nanosecondsSuffix = "ns";
const _microsecondsSuffix = "us";
const _millisecondsSuffix = "ms";
const _secondsSuffix = "s";
const _minutesSuffix = "m";
const _hoursSuffix = "h";
const _daysSuffix = "d";

sealed class TimespanParser {
  const TimespanParser();

  Timespan? parse(String value);
}

/// ISO 8601 duration format parser.
///
/// ISO 8601 durations follow the pattern:
///
/// `P(n)Y (n)M (n)W (n)D T(n)H (n)M (n)S`
///
/// Meaning of each designator:
///
/// | Letter | Name        | Description |
/// |--------|-------------|-------------|
/// | **P**  | Period      | Indicates the start of the duration (always first). |
/// | **Y**  | Years       | Number of years. |
/// | **M**  | Months      | Number of months (in the date section). |
/// | **W**  | Weeks       | Number of weeks. |
/// | **D**  | Days        | Number of days. |
/// | **T**  | Time        | Indicates the beginning of the time component section. |
/// | **H**  | Hours       | Number of hours. |
/// | **M**  | Minutes     | Number of minutes (in the time section). |
/// | **S**  | Seconds     | Number of seconds. |
///
/// **Example**
///
/// `P3Y6M4DT12H30M5S`
/// Represents a duration of **3 years**, **6 months**, **4 days**,
/// **12 hours**, **30 minutes**, and **5 seconds**.
class ISO8601TimespanParser extends TimespanParser {
  static final _regex = RegExp(
    r'^P'
    r'(?:(\d+)Y)?' // 1: years
    r'(?:(\d+)M)?' // 2: months (date part)
    r'(?:(\d+)W)?' // 3: weeks
    r'(?:(\d+)D)?' // 4: days
    r'(?:T'
    r'(?:(\d+)H)?' // 5: hours
    r'(?:(\d+)M)?' // 6: minutes (time part)
    r'(?:(\d+(?:\.\d+)?)S)?' // 7: seconds
    r')?$',
  );

  const ISO8601TimespanParser();

  @override
  Timespan parse(String value) {
    final match = _regex.firstMatch(value);
    if (match == null) {
      throw TimespanParseException(
        "Invalid ISO-8601 duration '$value'. Expected formats like 'P3Y6M4DT12H30M5S', 'P2W', 'PT10S', 'P1M'.",
        value,
      );
    }

    return Timespan(
      years: int.tryParse(match.group(1) ?? '0') ?? 0,
      months: int.tryParse(match.group(2) ?? '0') ?? 0,
      weeks: int.tryParse(match.group(3) ?? '0') ?? 0,
      days: int.tryParse(match.group(4) ?? '0') ?? 0,
      hours: int.tryParse(match.group(5) ?? '0') ?? 0,
      minutes: int.tryParse(match.group(6) ?? '0') ?? 0,
      seconds: int.tryParse(match.group(7) ?? '0') ?? 0,
    );
  }
}

/// Parses *simple-unit* and *Go-style* duration strings into a [Timespan].
///
/// This parser supports the same duration syntax used by:
/// - **Go** (`time.ParseDuration`)
/// - **Spring Boot** simple-duration syntax
/// - Many common shorthand duration formats
///
/// The format consists of one or more `<number><unit>` segments, concatenated
/// together without separators.
///
/// ### Supported units
///
/// | Unit | Meaning               | Example |
/// |------|------------------------|---------|
/// | `ns` | nanoseconds           | `10ns`  |
/// | `us` | microseconds          | `5us`   |
/// | `ms` | milliseconds          | `250ms` |
/// | `s`  | seconds               | `30s`   |
/// | `m`  | minutes               | `5m`    |
/// | `h`  | hours                 | `1h`    |
/// | `d`  | days                  | `2d`    |
///
/// ### Examples
///
/// ```dart
/// SimpleUnitTimespanParser().parse("10s");          // 10 seconds
/// SimpleUnitTimespanParser().parse("250ms");        // 250 milliseconds
/// SimpleUnitTimespanParser().parse("1h30m");        // 1 hour, 30 minutes
/// SimpleUnitTimespanParser().parse("2h15m10.5s");   // fractional seconds supported
/// ```
///
/// ### Notes
///
/// - Multiple segments can be combined: `"1h30m10s"`.
/// - Fractions are supported (`"1.5s"` → 1 second + 500ms).
/// - The parser does **not** assume any calendar-based components (no months,
///   years, weeks); everything resolves to pure time.
/// - The result is returned as a [Timespan] rather than a [Duration], preserving
///   nanosecond-level precision.
///
/// Throws a [TimespanParseException] if the string does not match the expected
/// format.
class SimpleUnitTimespanParser extends TimespanParser {
  // Match a number followed by a unit (ns, us, ms, s, m, h, d)
  static final _regex = RegExp(r'(\d+(?:\.\d+)?)(ns|us|ms|s|m|h|d)');

  const SimpleUnitTimespanParser();

  @override
  Timespan? parse(String value) {
    final matches = _regex.allMatches(value).toList();

    if (matches.isEmpty) {
      throw TimespanParseException(
        "Invalid simple-unit duration: '$value'. Expected formats like '10s', '5m', '1h30m', '2h15m10s'.",
        value,
      );
    }

    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    int milliseconds = 0;
    int microseconds = 0;
    int nanoseconds = 0;

    for (final match in matches) {
      final number = double.parse(match.group(1)!);
      switch (match.group(2)!) {
        case _daysSuffix:
          days += number.toInt();
          break;
        case _hoursSuffix:
          hours += number.toInt();
          break;
        case _minutesSuffix:
          minutes += number.toInt();
          break;
        case _secondsSuffix:
          seconds += number.toInt();
          final fraction = number - number.floor();
          milliseconds += (fraction * 1000).floor();
          break;
        case _millisecondsSuffix:
          milliseconds += number.toInt();
          final fraction = number - number.floor();
          microseconds += (fraction * 1000).floor();
          break;
        case _microsecondsSuffix:
          microseconds += number.toInt();
          final fraction = number - number.floor();
          nanoseconds += (fraction * 1000).floor();
          break;
        case _nanosecondsSuffix:
          nanoseconds += number.toInt();
          break;
      }
    }

    return Timespan(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
      microseconds: microseconds,
      nanoseconds: nanoseconds,
    );
  }
}
