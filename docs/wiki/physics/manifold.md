---
title: Manifold
version: 0.0.1
section: physics
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Manifold

Contact data between two colliders. Produced by `Manifold.compute(a, b)` (returns `null` if they do not overlap). Consumed by `PhysicsSystem` to apply the collision impulse and the positional correction.

## Basic usage

```typescript
import { Manifold } from '@oliver404/arkane-ts';

const m: Manifold | null = Manifold.compute(boxA, boxB);
if (m !== null) {
  // m.normal points from a → b
  // m.penetration is how deep they overlap
  // m.restitution is the bounciness to use
  // m.friction is informational only (V0.0.1)
}
```

You do not usually call `Manifold.compute` directly — `PhysicsSystem` does it for you. Call it yourself when you want to:

- Build a custom resolver.
- Inspect a contact for visualization (e.g. draw the contact normal as a debug line).
- Write unit tests for collision behavior.

## Configuration

### Constructor

```typescript
new Manifold(a?, b?, normal?, penetration?, restitution?, friction?)
```

All parameters are optional. With no arguments the manifold has zero-valued fields and `a` / `b` are placeholder objects — useful as a stub in tests.

### Properties

| Name | Type | Description |
|---|---|---|
| `a` | `Collider` | First collider in the contact. |
| `b` | `Collider` | Second collider. |
| `normal` | `Vector2` | **Points from `a` toward `b`.** The direction an impulse on `b` follows to push it away from `a`. |
| `penetration` | `number` | How far the two colliders overlap along the normal. Always ≥ 0. |
| `restitution` | `number` | The effective bounciness: `Math.max(a.restitution, b.restitution)`. |
| `friction` | `number` | `sqrt(max(a.friction, 0) * max(b.friction, 0))`. **Informational only** — the system does not yet apply tangential friction. |

### Static method

| Method | Description |
|---|---|
| `Manifold.compute(a, b)` | Returns `Manifold | null`. Dispatches by shape pair: Box↔Box uses SAT (smallest-overlap axis), Box↔Circle uses closest-point on the AABB, Circle↔Circle uses the center-to-center direction. |

## Sign convention

`normal` always points from `a` to `b`. This is consistent across all three shape-pair branches:

- Box↔Box: along the smallest-overlap axis, sign chosen by the relative position of `b` with respect to `a`.
- Box↔Circle: the box is always the receiver (`a`). The normal is the unit vector from the closest point on the AABB to the circle center. If `Manifold.compute` is called with the circle as `a`, it internally swaps so the box becomes `a` and negates the normal to preserve the convention.
- Circle↔Circle: from `a`'s center to `b`'s center. For concentric circles, picks `(1, 0)` arbitrarily.

If you write your own impulse resolver, remember to apply `+impulse` to `b` and `-impulse` to `a`.

## Edge cases

| Scenario | Behavior |
|---|---|
| Box↔Box with equal overlap on both axes | Resolves along Y (the tiebreak). |
| Box↔Circle with circle center inside the box | Picks the shortest exit axis. Normal points outward from the box face the circle is closest to. |
| Circle↔Circle concentric | Normal = `(1, 0)`, penetration = sum of radii. Arbitrary but stable. |
| Mixed shape (e.g. circle-vs-circle after a deletion) | `Manifold.compute` returns `null`. No collision. |

## Pitfalls & FAQ

- **Normal is unit-length, but only approximately.** Compute branches may produce a normal with magnitude < 1 if the geometry degenerates (e.g. concentric circles, or a circle center exactly on a box edge). The system does not renormalize; impulse magnitudes scale by `normal.x` / `normal.y` directly.
- **`restitution` is the max, not the average.** A heavy bouncy box and a light non-bouncy box yield a bouncy collision.
- **`friction` is informational.** The current physics tick does not read it for tangential resolution. Treat it as a forward-compatibility field.
- **`null` means "no contact", not "error".** Always null-check the return value.

## See also

- [Collider](collider.md), [BoxCollider](boxcollider.md), [CircleCollider](circlecollider.md) — the input shapes.
- [PhysicsSystem](physicssystem.md) — the consumer of `Manifold.compute`.
