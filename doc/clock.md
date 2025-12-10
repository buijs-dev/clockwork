### Clocks API

The `Clock` abstraction decouples code from `DateTime.now()`. 
You can swap the global clock for tests and simulations using `ClockProvider.withClock`.

#### Available clocks
- [SystemClock](#systemclock)
- [FixedClock](#fixedclock)
- [OffsetClock](#offsetclock)
- [AdjustableClock](#adjustableclock)
- [TickingClock](#tickingclock)

##### SystemClock
Clock which returns the system wall‑clock time as UTC.

```dart
    final systemClock = Clock.system();

    // alternatively use primary constructor, 
    // useful for default constructor parameters
    const systemClock = SystemClock();
    
    // current DateTime in UTC
    systemClock.now();
    
    // redundant because default is true
    systemClock.now(asUtc: true);
    
    // local DateTime instead of UTC
    systemClock.now(asUtc: false);
    
    // current day
    systemClock.today();
    
    // redundant because default is true
    systemClock.today(asUtc: true);
    
    // current local DateTime instead of UTC
    systemClock.today(asUtc: false);
    
    // current system timezone offset
    systemClock.timeZoneOffset;
```

##### FixedClock
Clock which always returns the same instant (great for deterministic tests).

```dart
    // fixed DateTime
    Clock.fixed(2025, 12, 1).now();
```

##### OffsetClock
Clock which adds a fixed Duration to a base clock (time‑travel/virtual time zone).

```dart
    // Create a clock with a positive offset
    final clock = Clock.offset(hours: 2);
    
    // Create a clock with a negative offset
    final clock = Clock.offset(hours: -2);
    
    // Offset by minutes
    final clock = Clock.offset(hours: 0, minutes: 15);
    
    // Use primary constructor for more fine-grained control
    final clock = OffsetClock(Duration(seconds: 15));
    
    // Offset can also be based off a different clock
    final clock = Clock.offset(hours: 1, base: Clock.fixed(2024, 12, 31, 12));
```

##### AdjustableClock
AdjustableClock which manually sets `set(...)` or advances `advance(...)` time for scenarios.

```dart
    // Create a clock with fixed date and time 2025 January 1st at 00:00:00
    final clock = AdjustableClock(DateTime.utc(2025, 1, 1));
    
    // Returns the fixed time, e.g. 2025 January 1st at 00:00:00
    clock.now();
    
    // Returns the fixed time, e.g. 2025 January 1st at 00:00:00 again
    clock.now();
    
    // Add 1 second to fixed date and time
    clock.advance(Duration(seconds: 1));
    
    // Returns 2025 January 1st at 00:00:01
    clock.now(); 
    
    // Set the clock date and time to 2024 February 1st at 12:00:00
    clock.set(DateTime.utc(2024, 2, 1, 12));
    
    // Returns 2024 February 1st at 12:00:00
    clock.now();
```

##### TickingClock
TickingClock which returns a value that advances by a fixed `tick` with each call.

```dart
    // Create a TickingClock with current DateTime as base (default) 
    // which advances time by 1 minute every tick
    final clock = Clock.ticking(tick: Duration(minutes: 1));
    
    // Equivalent to above but by using constructor
    final clock = TickingClock(DateTime.now(), Duration(minutes: 1));
    
    // Create a TickingClock which starts at 2025 January 1st at 00:00:00
    final clock = Clock.ticking(tick: Duration(minutes: 1), start: DateTime.utc(2025, 1,1));
    
    // Returns fixed DateTime, e.g. 2025 January 1st at 00:00:00
    // and then adds 1 minute
    clock.now();
    
    // Returns fixed DateTime, e.g. 2025 January 1st at 00:01:00
    // and then adds another 1 minute
    clock.now();
```

#### Global override

```dart
import 'package:clockwork/clockwork.dart';

void main() {
  final fixed = FixedClock(DateTime.utc(2025, 1, 1));
  ClockProvider.withClock(fixed, () {
    // Inside this scope, all calls use the fixed instant.
    print(ClockProvider.current.now());
  });
}
```

#### Best practices

- Prefer `ClockProvider.current` instead of `DateTime.now()` in app code.
- Use `FixedClock` or `AdjustableClock` in tests to remove flakiness.
- Keep authoritative time in UTC; convert to local only for presentation.