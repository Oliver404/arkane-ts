---
title: Vector3
version: 0.0.1
section: math
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Vector3

A mutable 3D vector with chained arithmetic. The engine is 2D-only at render time, but `Vector3` exists for game logic that wants to keep a Z component (parallax layers, depth sorting, future 3D extensions).

## Basic usage

```typescript
import { Vector3 } from '@oliver404/arkane-ts';

const v = new Vector3(1, 2, 3);
v.length();                 // ~3.74
v.normalize();              // unit vector
v.multiply(2);              // v is now (2/√14, 4/√14, 6/√14)
```

## Configuration

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `x` | `number` | `0` | Horizontal component. |
| `y` | `number` | `0` | Vertical component. World Y points **UP**. |
| `z` | `number` | `0` | Depth / layer index. Not consumed by the 2D renderer. |

### Instance methods (return `this`)

| Method | Description |
|---|---|
| `clone()` | Returns a new `Vector3` with the same values. |
| `set(x, y, z)` | Replaces all three components. |
| `add(v)` | Adds `v` component-wise. |
| `subtract(v)` | Subtracts `v` component-wise. |
| `multiply(scalar)` | Multiplies all three components. |
| `length()` | Euclidean magnitude. |
| `normalize()` | Scales the vector to unit length. **No-op when length is 0**. |

### Static methods

| Method | Description |
|---|---|
| `Vector3.zero()` | Returns `Vector3(0, 0, 0)`. |

## Differences from Vector2

`Vector3` is a strict subset of `Vector2`'s API:

- No `divide()`.
- No `distance()`.
- No `static add()` or `static subtract()`.

If you need any of those, either downcast to a 2D problem (use `Vector2`) or compute them inline.

## Pitfalls & FAQ

- **Mutable by default.** Every instance method mutates `this`.
- **`z` is ignored by the 2D renderer.** The sprite draw path does not look at it. Use `z` only for your own game logic (e.g. parallax sorting, layering, or future 3D work).

## See also

- [Vector2](vector2.md) — primary 2D vector.
- [MathUtils](mathutils.md) — `clamp`, `lerp` for scalar math.
