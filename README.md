#A "toolbox" library used by other polygonal libraries (core)

The library includes the following packages:
	
### `event`
- A library for handling events, with focus on boilerplate reduction and performance.
- See [A fast notification system for event-driven design](http://lab.polygonal.de/?p=2548).
- See [The Observer pattern](http://en.wikipedia.org/wiki/Observer_pattern)

### `fmt`
- Varios helper functions for formatting numbers and objects.
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
- Fast 2D/3D vector and matrix mathematics.
- Pseudorandom number generators (Park-Miller-Carta, MT19937)
- [Trigonometric approximations](http://lab.polygonal.de/?p=205).

### `sys`
- Entity framework for component based architectures.

### `time`
- Everything related to time-based updates, timed execution.

### `tween`
- A tweening framework.

### `util`
- Misc utility functions.

## Changelog

### 1.00 (released 2012-12-XX)

* initial version