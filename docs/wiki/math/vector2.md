---
title: Vector2
version: 0.0.1
section: math
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Vector2

A mutable 2D vector with chained arithmetic operations. Used everywhere — `Transform.position`, `Rigidbody.velocity`, `Camera2D.position`, `TouchInput.position`, and any world coordinate you need to manipulate.

## Basic usage

```typescript
import { Vector2 } from '@oliver404/arkane-ts';

const v = new Vector2(3, 4);
v.length();                 // 5
v.normalize();              // v is now (0.6, 0.8)
v.add(new Vector2(1, 1));  // v is now (1.6, 1.8)
```

All instance methods return `this`, so you can chain:

```typescript
const direction = new Vector2(target.x - origin.x, target.y - origin.y)
  .normalize()
  .multiply(speed);
```

## Configuration

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `x` | `number` | `0` | Horizontal component. |
| `y` | `number` | `0` | Vertical component. World Y points **UP**. |

### Instance methods (return `this`)

| Method | Description |
|---|---|
| `clone()` | Returns a new `Vector2` with the same values. |
| `set(x, y)` | Replaces both components. |
| `add(v)` | Adds `v` component-wise. |
| `subtract(v)` | Subtracts `v` component-wise. |
| `multiply(scalar)` | Multiplies both components. |
| `divide(scalar)` | Divides both components. **No-op when `scalar === 0`**. |
| `length()` | Euclidean magnitude. |
| `normalize()` | Scales the vector to unit length. **No-op when length is 0**. |
| `distance(v)` | Euclidean distance to `v`. |

### Static methods (return a new `Vector2`)

| Method | Description |
|---|---|
| `Vector2.add(a, b)` | Returns `a + b`. |
| `Vector2.subtract(a, b)` | Returns `a - b`. |
| `Vector2.zero()` | Returns `Vector2(0, 0)`. |

## Pitfalls & FAQ

- **Mutable by default.** Every instance method mutates `this`. If you need an unchanged copy, call `clone()` first.
- **`divide(0)` is a silent no-op.** This avoids `Infinity` / `NaN` propagating into physics calculations, but it also means a typo in your code will not throw.
- **`normalize()` on a zero vector is a silent no-op.** Same rationale.
- **No static `Vector2.distance`.** If you need a static distance, compute `a.subtract(b).length()` or use `a.distance(b)` after constructing one of them.

## See also

- [Vector3](vector3.md) — same pattern with `z` added.
- [MathUtils](mathutils.md) — `clamp`, `lerp` for scalar math.
- [Rect](rect.md) — AABB which uses Vector2 for point tests.
