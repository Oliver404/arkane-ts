---
title: CollisionSystem
version: 0.0.1
section: physics
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# CollisionSystem

A static utility that detects which colliders overlap right now. Returns a flat list of `Collision` pairs. **It does not resolve anything** — no impulse, no positional correction, no integration. It is the V1.0 boundary detection primitive, superseded for any non-trivial game by [PhysicsSystem](physicssystem.md).

## Basic usage

```typescript
import { CollisionSystem } from '@oliver404/arkane-ts';

const colliders = scene.getEntities()
  .map(e => e.collider)
  .filter((c): c is Collider => c !== undefined);

const collisions = CollisionSystem.checkCollisions(colliders);
for (const c of collisions) {
  // c.a and c.b are the overlapping colliders
  if (c.involves(player.collider!)) {
    // handle player hit
  }
}
```

## Methods

### Static `checkCollisions`

```typescript
static checkCollisions(colliders: Collider[]): Collision[]
```

Walks all unique `(i, j)` pairs in O(n²), tests each with `a.isColliding(b)`, and returns the pairs that overlap. Order of the returned array follows insertion order.

## Why you usually do not need this

`PhysicsSystem` does overlap detection **and** resolution in one step. If you only need "did these two touch this frame?" you can:

- Subscribe to a custom resolver that wraps `Manifold.compute`.
- Read `entity.rigidbody.velocity` after the system ticks and react when it flips sign at a wall (lossy).
- Build your own minimal contact event by re-running `Manifold.compute` between two specific colliders of interest.

`CollisionSystem` exists for:

- Edge cases where you want a static, no-side-effects detector (e.g. a "no two enemies overlap" spawn check).
- Backwards compatibility with V1.0 code that predates `PhysicsSystem`.
- Tests that want to verify broadphase behavior without integration.

## Pitfalls & FAQ

- **O(n²).** Every collider is tested against every other collider. For more than a few dozen colliders, write a spatial hash or quadtree first.
- **No resolution.** You are responsible for pushing bodies apart, applying impulses, etc. If you want that, use [PhysicsSystem](physicssystem.md).
- **`Collision` is not the same as `Manifold`.** `Collision` carries only `(a, b)` and a couple of helper methods (`involves`, `getOther`). For penetration, normal, and restitution, call `Manifold.compute(a, b)` on the returned pair.
- **Empty array on no overlap.** A non-empty result means at least one pair overlaps.

## See also

- `Collision` (same module — exported from `@oliver404/arkane-ts`) — the value type returned. It carries `a`, `b`, and the helpers `involves(collider)` and `getOther(collider)`.
- [PhysicsSystem](physicssystem.md) — full overlap + resolve + integrate.
- [Manifold](manifold.md) — rich contact data for a single pair.
