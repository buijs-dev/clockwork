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

bool isLeapYear(int year) => _isLeapYear(year);

bool _isLeapYear(int year) =>
    (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);

extension DateTimeExtension on DateTime {
  int get secondsSinceEpoch => (millisecondsSinceEpoch / 1000).round();

  bool isBeforeOrSame(DateTime other) => !isAfter(other);

  bool isAfterOrSame(DateTime other) => !isBefore(other);

  DateTime roundToMinute({bool? utc}) => (utc ?? isUtc)
      ? DateTime.utc(year, month, day, hour, minute)
      : DateTime(year, month, day, hour, minute);

  DateTime startOfDay({bool? utc}) => (utc ?? isUtc)
      ? DateTime.utc(year, month, day)
      : DateTime(year, month, day);

  bool get isLeapYear => _isLeapYear(year);
}
