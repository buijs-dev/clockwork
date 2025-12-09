import 'package:clockwork/clockwork.dart';

void main() {
  SimpleUnitTimespanParserBenchmark()
    ..preRun()
    ..run();

  ISO8601TimespanParserBenchmark()
    ..preRun()
    ..run();
}

abstract class _AbstractBenchMark {
  final TimespanParser subject;
  final List<String> testcases;
  final int iterations;
  const _AbstractBenchMark(this.subject, this.iterations, this.testcases);

  void preRun() {
    for (final testcase in testcases) {
      subject.parse(testcase);
    }
  }

  void run() {
    Stopwatch stopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      subject.parse(testcases[i % testcases.length]);
    }
    stopwatch.stop();
    print('Elapsed (${subject.runtimeType} direct call): ${stopwatch.elapsed.inMilliseconds}ms');

    stopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      Timespan.parse(testcases[i % testcases.length]);
    }
    stopwatch.stop();
    print('Elapsed (static indirect call): ${stopwatch.elapsed.inMilliseconds}ms');
  }
}

class SimpleUnitTimespanParserBenchmark extends _AbstractBenchMark {
  SimpleUnitTimespanParserBenchmark()
    : super(SimpleUnitTimespanParser(), 2000000, [
        "10s",
        "5m",
        "1h30m",
        "2h15m10s",
        "1.234s",
        "123ms",
        "999.999ms",
        "5m10.5s",
        "10s5ms250us",
        "3d12h15m10.250s",
      ]);
}

class ISO8601TimespanParserBenchmark extends _AbstractBenchMark {
  ISO8601TimespanParserBenchmark()
    : super(ISO8601TimespanParser(), 2000000, [
        "P3Y",
        "P3Y6M",
        "P3Y6M4D",
        "P3Y6M4DT12H",
        "P3Y6M4DT12H30M",
        "P3Y6M4DT12H30M5S",
        "P1M",
        "P1D",
        "PT12H30M1S",
      ]);
}
