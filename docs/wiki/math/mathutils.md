---
title: MathUtils
version: 0.0.1
section: math
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# MathUtils

A tiny namespace for scalar math helpers used throughout the engine.

## Basic usage

```typescript
import { MathUtils } from '@oliver404/arkane-ts';

MathUtils.clamp(playerY, minY, maxY);     // clamp a coordinate to a range
MathUtils.lerp(0, 100, 0.25);             // 25 — 25% of the way from 0 to 100
MathUtils.lerp(0, 100, 1.5);              // 150 — does NOT clamp t
```

## Configuration

All methods are static.

| Method | Signature | Description |
|---|---|---|
| `clamp` | `(value, min, max) → number` | Returns `min` if `value < min`, `max` if `value > max`, otherwise `value`. Assumes `min ≤ max` — does not validate. |
| `lerp` | `(a, b, t) → number` | Returns `a + (b - a) * t`. Linear interpolation. `t` is **not** clamped; values outside `[0, 1]` extrapolate. |

## Advanced usage

Framerate-independent damping (with manual exponential smoothing):

```typescript
const smoothing = 1 - Math.pow(0.001, Time.deltaTime); // ~critical damping
this.cameraX = MathUtils.lerp(this.cameraX, targetX, smoothing);
```

Snapping a position into the viewport:

```typescript
e.transform.position.x = MathUtils.clamp(
  e.transform.position.x,
  -viewportWidth / 2,
  viewportWidth / 2
);
```

## Pitfalls & FAQ

- **`lerp` does not clamp `t`.** `lerp(0, 100, 1.5)` returns 150, not 100. Use `MathUtils.clamp(t, 0, 1)` first if you need a saturated interpolation.
- **`clamp` does not validate `min ≤ max`.** If you pass `min > max`, the function returns `max` (because the `value > max` branch fires before the `value < min` branch).
- **No trigonometric helpers.** `sin` / `cos` / `atan2` are not wrapped. Use the JavaScript `Math` global directly.

## See also

- [Vector2](vector2.md) — vector arithmetic; pair `MathUtils.lerp` with `Vector2` for vector interpolation:

  ```typescript
  Vector2.add(a, Vector2.subtract(b, a).multiply(t)); // = lerp(a, b, t) on vectors
  ```
