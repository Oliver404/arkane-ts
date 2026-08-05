---
title: Collider
version: 0.0.1
section: physics
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Collider

Abstract base class for collision shapes. Two concrete implementations ship: [BoxCollider](boxcollider.md) and [CircleCollider](circlecollider.md). You typically attach a collider to an `Entity` and let `PhysicsSystem` handle pair resolution.

## Configuration

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `transform` | `Transform` | (constructor) | The transform the collider follows. Mutating `transform.position` is immediately visible to the collider. |
| `friction` | `number` | `0` | Tangential damping coefficient. Stored; the tangential impulse is **not yet applied** in V0.0.1 — see the V1.2 roadmap. |
| `restitution` | `number` | `0` | Bounciness in `[0, 1]`. `0` = inelastic (objects stick). `1` = perfect bounce. Used by `Manifold.compute` and `PhysicsSystem`. |

### Abstract method

| Method | Description |
|---|---|
| `isColliding(other)` | Subclass-implemented broadphase check. Box↔Box, Box↔Circle, Circle↔Circle are all supported. |

### Attach to an entity

```typescript
import { Entity, BoxCollider, Rigidbody } from '@oliver404/arkane-ts';

const e = new Entity();
e.setCollider(new BoxCollider(e.transform, 32, 32));
e.setRigidbody(new Rigidbody(e.transform));
```

`PhysicsSystem` finds these on every tick via `entity.collider` and `entity.rigidbody`.

## Advanced usage

### Restitution tuning

For a Pong-like game where the ball must bounce forever off walls:

```typescript
wall.setCollider(new BoxCollider(wall.transform, 200, 10));
wall.collider!.restitution = 1.0;
ball.setCollider(new CircleCollider(ball.transform, 8));
ball.collider!.restitution = 1.0;
```

For a slow, damped ball:

```typescript
ball.collider!.restitution = 0.4;
ball.rigidbody!.drag = 0.5;
```

### Friction (informational)

`Manifold.friction` is filled with `sqrt(a.friction * b.friction)`. The physics system does not currently apply this — collisions are perfectly smooth along the tangent. Tangential friction resolution ships in V1.2.

## Pitfalls & FAQ

- **Pass the entity's transform, not a copy.** Both `BoxCollider` and `CircleCollider` take a reference to the transform they are coupled with. If you pass a fresh `Transform`, the collider will never move with the entity.
- **`friction` is not applied yet.** Setting it does nothing observable in V0.0.1. Use it as a placeholder / future-proofing field.
- **Restitution is per-collider.** The effective restitution used by `Manifold.compute` is `Math.max(a.restitution, b.restitution)`. Setting restitution on the lighter body has no effect if the heavier body is at `0`.

## See also

- [BoxCollider](boxcollider.md), [CircleCollider](circlecollider.md) — concrete shapes.
- [Rigidbody](rigidbody.md) — the dynamic-side counterpart to a collider.
- [Manifold](manifold.md) — contact data produced from two colliders.
- [PhysicsSystem](physicssystem.md) — the auto-driven tick.
