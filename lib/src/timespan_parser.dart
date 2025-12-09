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

const int _whitespace = 32; // ' '
const int _zero = 48; // 0
const int _nine = 57; // 9
const int _dot = 46; // .
const int _dUppercase = 68; // D
const int _hUppercase = 72; // H
const int _mUppercase = 77; // M
const int _nUppercase = 78; // N
const int _pUppercase = 80; // P
const int _sUppercase = 83; // S
const int _tUppercase = 84; // T
const int _uUppercase = 85; // U
const int _wUppercase = 87; // W
const int _yUppercase = 89; // Y
const int _dLowercase = 100; // d
const int _hLowercase = 104; // h
const int _mLowercase = 109; // m
const int _pLowercase = 112; // p
const int _sLowercase = 115; // s
const int _tLowercase = 116; // t
const int _nLowercase = 110; // n
const int _uLowercase = 117; // u
const int _wLowercase = 119; // w
const int _yLowercase = 121; // y
const int _nsMultiplier = 1;
const int _usMultiplier = 1000 * _nsMultiplier;
const int _msMultiplier = 1000 * _usMultiplier;
const int _sMultiplier = 1000 * _msMultiplier;
const int _mMultiplier = 60 * _sMultiplier;
const int _hMultiplier = 60 * _mMultiplier;
const int _dMultiplier = 24 * _hMultiplier;

// pow10 lookup for fractional parsing
const List<int> _pow10 = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000];

sealed class TimespanParser {
  const TimespanParser();

  Timespan? parse(String value);

  Timespan parseOrThrow(String value) {
    final parsed = parse(value);
    if (parsed != null) {
      return parsed;
    } else {
      throw TimespanParseException("Invalid value for parser $runtimeType", value);
    }
  }
}

/// Exception thrown when a duration cannot be parsed.
class TimespanParseException implements FormatException {
  @override
  final String message;

  @override
  final String? source;

  @override
  final int? offset;

  TimespanParseException(this.message, [this.source, this.offset]);

  @override
  String toString() => '$runtimeType: $message';
}

/// ISO 8601 duration format (case-insensitve) parser.
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
  const ISO8601TimespanParser();

  @override
  Timespan? parse(String input) {
    final len = input.length;
    if (len == 0 || (input.codeUnitAt(0) != _pUppercase && input.codeUnitAt(0) != _pLowercase)) {
      return null;
    }

    int years = 0;
    int months = 0;
    int weeks = 0;
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    int milliseconds = 0;
    int microseconds = 0;
    int nanoseconds = 0;

    int i = 1;
    bool inTime = false;

    while (i < len) {
      int ch = input.codeUnitAt(i);

      // check for T/t which indicates time components
      if (ch == _tUppercase || ch == _tLowercase) {
        inTime = true;
        i++;
        if (i == len) {
          return null;
        }
        ch = input.codeUnitAt(i);
        if (ch < _zero || ch > _nine) {
          return null;
        }
        continue;
      }

      // a number should be present after P or PT
      if (ch < _zero || ch > _nine) {
        return null;
      }

      int intPart = 0;
      while (i < len) {
        ch = input.codeUnitAt(i);
        if (ch >= _zero && ch <= _nine) {
          intPart = intPart * 10 + (ch - _zero);
          i++;
        } else {
          break;
        }
      }

      // fractional part only for seconds
      int frac = 0;
      int fracLen = 0;

      if (i < len && input.codeUnitAt(i) == _dot) {
        i++; // skip dot
        while (i < len) {
          ch = input.codeUnitAt(i);
          if (ch >= _zero && ch <= _nine) {
            if (fracLen < 9) {
              frac = frac * 10 + (ch - _zero);
              fracLen++;
            }
            i++;
          } else {
            break;
          }
        }
      }

      // yeah no can do
      if (i >= len) {
        return null;
      }

      final int unit = input.codeUnitAt(i);
      i++;

      if (!inTime) {
        // DATE COMPONENTS
        switch (unit) {
          // yY
          case _yUppercase:
          case _yLowercase:
            years = intPart;
            break;

          // mM
          case _mUppercase:
          case _mLowercase:
            months = intPart;
            break;

          // wW
          case _wUppercase:
          case _wLowercase:
            weeks = intPart;
            break;

          // dD
          case _dUppercase:
          case _dLowercase:
            days = intPart;
            break;
          default:
            return null;
        }
      } else {
        // TIME COMPONENTS
        switch (unit) {
          // hH
          case _hUppercase:
          case _hLowercase:
            hours = intPart;
            break;
          // mM
          case _mUppercase:
          case _mLowercase:
            minutes = intPart;
            break;

          // sS
          case _sUppercase:
          case _sLowercase:
            seconds = intPart;
            if (fracLen > 0) {
              final scale = _pow10[fracLen];
              var extraNs = (frac * 1000000000 ~/ scale);
              milliseconds = extraNs ~/ 1000000;
              extraNs %= 1000000;
              microseconds = extraNs ~/ 1000;
              nanoseconds = extraNs % 1000;
            }
            break;
          default:
            return null;
        }
      }
    }

    // means there is trailing garbage like PT10SBLA
    if (i != len) {
      return null;
    }

    return Timespan(
      years: years,
      months: months,
      weeks: weeks,
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
  const SimpleUnitTimespanParser();

  @override
  Timespan? parse(String input) {
    final len = input.length;
    if (len == 0) {
      return null;
    }

    var i = 0;
    var totalNs = 0;

    while (i < len) {
      var ch = input.codeUnitAt(i);
      if (ch <= _whitespace) {
        i++;
        continue;
      }

      if (!(ch >= _zero && ch <= _nine)) {
        return null;
      }

      var intPart = 0;
      while (i < len) {
        ch = input.codeUnitAt(i);
        if (ch >= _zero && ch <= _nine) {
          intPart = intPart * 10 + (ch - _zero);
          i++;
        } else {
          break;
        }
      }

      var frac = 0;
      var fracLen = 0;
      if (i < len && input.codeUnitAt(i) == _dot) {
        // skip dot
        i++;
        while (i < len) {
          ch = input.codeUnitAt(i);
          if (ch >= _zero && ch <= _nine) {
            // limit to 9 digits (ns precision)
            if (fracLen < 9) {
              frac = frac * 10 + (ch - _zero);
              fracLen++;
            }
            i++;
          } else {
            break;
          }
        }
      }

      // parse unit (1-2 letters), must exist
      if (i >= len) {
        return null;
      }

      final u1 = input.codeUnitAt(i);
      int unitNs;

      switch (u1) {
        // dD
        case _dLowercase:
        case _dUppercase:
          unitNs = _dMultiplier;
          i++;
          break;

        // hH
        case _hLowercase:
        case _hUppercase:
          unitNs = _hMultiplier;
          i++;
          break;

        // mM
        case _mUppercase:
        case _mLowercase:
          if (i + 1 < len) {
            final u2 = input.codeUnitAt(i + 1);
            if (u2 == _sLowercase || u2 == _sUppercase) {
              unitNs = _msMultiplier;
              i += 2;
              break;
            }
          }

          unitNs = _mMultiplier;
          i++;
          break;

        // sS
        case _sUppercase:
        case _sLowercase:
          unitNs = _sMultiplier;
          i++;
          break;

        // nN
        case _nUppercase:
        case _nLowercase:
          if (i + 1 < len) {
            final u2 = input.codeUnitAt(i + 1);
            if (u2 == _sLowercase || u2 == _sUppercase) {
              unitNs = _nsMultiplier;
              i += 2;
              break;
            }
          }
          // only ns (nanoseconds) is valid, and at this point we know there is no s
          return null;

        // uU
        case _uUppercase:
        case _uLowercase:
          if (i + 1 < len) {
            final u2 = input.codeUnitAt(i + 1);
            if (u2 == _sLowercase || u2 == _sUppercase) {
              unitNs = _usMultiplier;
              i += 2;
              break;
            }
          }
          // only us (microseconds) is valid, and at this point we know there is no s
          return null;

        default:
          return null;
      }

      // compute value in nanoseconds without using floating point
      var partNs = intPart * unitNs;
      if (fracLen > 0) {
        partNs += (frac * unitNs) ~/ _pow10[fracLen];
      }

      totalNs += partNs;
    }

    // Now split totalNs back to fields (days..nanoseconds)
    var rem = totalNs;
    final days = rem ~/ _dMultiplier;
    rem %= _dMultiplier;
    final hours = rem ~/ _hMultiplier;
    rem %= _hMultiplier;
    final minutes = rem ~/ _mMultiplier;
    rem %= _mMultiplier;
    final seconds = rem ~/ _sMultiplier;
    rem %= _sMultiplier;
    final milliseconds = rem ~/ _msMultiplier;
    rem %= _msMultiplier;
    final microseconds = rem ~/ _usMultiplier;
    rem %= _usMultiplier;
    final nanoseconds = rem; // remainder

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
