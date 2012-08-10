#A "toolbox" library used by other polygonal libraries (core)

## Documentation
-    API [http://polygonal.github.com/doc/core/](http://polygonal.github.com/doc/core/)

## Packages
The library includes the following packages:

### `event`
- A library for handling events, with focus on boilerplate reduction and performance.
- See [A fast notification system for event-driven design](http://lab.polygonal.de/?p=2548).
- See [The Observer pattern](http://en.wikipedia.org/wiki/Observer_pattern)

### `fmt`
- Various helper functions for formatting numbers and objects.
- Supports [sprintf](http://www.cplusplus.com/reference/clibrary/cstdio/sprintf/) syntax. See [Using sprintf with Haxe](http://lab.polygonal.de/?p=1939).

### `io`
- A fast [Base64](http://en.wikipedia.org/wiki/Base64) encoder.
- Resource loading / mass loader (_flash only_)

### `log`
- A simple logging framework.

### `macro`
- A bunch of basic macros for generating classes at compile-time.

### `math`
- Math helper functions.
- Fast 2D/3D vector and matrix math.
- Pseudorandom number generators ([Park-Miller-Carta](http://lab.polygonal.de/?p=162), MT19937)
- [Trigonometric approximations](http://lab.polygonal.de/?p=205).

### `sys`
- Entity framework for component based architectures.

### `time`
- Time-based updates, timeline, timed execution.

### `tween`
- A tweening framework.

### `util`
- Misc utility functions.

## Installation
Install [Haxe](http://haxe.org/download) and run `$ haxelib install polygonal-core` from the console.
This installs the polygonal-core library hosted on [lib.haxe.org](http://lib.haxe.org/p/polygonal-core), which always mirrors the git master branch. From now on just compile with `$ haxe ... -lib polygonal-core`.
If you want to test the latest beta build, you should pull the dev branch and add the src folder to the classpath via `$ haxe ... -cp src`.

## Changelog

### 1.01 (dev)

* fixed: Mathematics.floor(), ceil(), fwrap() for neko, don't use Std.int() for cpp
* modified: Entity.findXXXById => Entity.findXXXByName
* modified: optional subclass check in Entity.findXXXByClass
* modified: keep dispatching Timebase updates when calling MainLoop.pause()
* modified: make de.polygonal.core.time.Delay cancelable
* added: math.RootSolver class
* modified: pass message sender to Entity.onMessage()
* fixed: keep existing fields in macro.Version
* added: Entity.is() and Entity.isAny()
* fixed: minor tweening fixes, added tweening examples
* modified: Observable: consider group id in event filtering, use 30 bits for neko
* added: TimelineListener as an alternative to TimelineEvent
* modified: optimized tweening performance
* added: Entity.iterator() to iterate over all children (non-recursive)

### 1.00

* Initial version.