---
title: CircleCollider
version: 0.0.1
section: physics
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# CircleCollider

A circular collider centered on the entity's transform. Supports Circle↔Circle overlap directly, and delegates Box↔Circle to the `BoxCollider` branch.

## Basic usage

```typescript
import { Entity, CircleCollider, Vector2 } from '@oliver404/arkane-ts';

const ball = new Entity();
ball.transform.position = new Vector2(0, 0);
ball.setCollider(new CircleCollider(ball.transform, 8));   // radius 8
```

## Configuration

### Constructor

```typescript
new CircleCollider(transform: Transform, radius: number)
```

| Parameter | Description |
|---|---|
| `transform` | The transform the collider follows. |
| `radius` | Circle radius in world units. |

### Properties

| Name | Type | Description |
|---|---|---|
| `radius` | `number` | Circle radius. |
| `transform` | `Transform` | Inherited from `Collider`. |
| `friction`, `restitution` | `number` | Inherited from `Collider`. |

### Methods

| Method | Description |
|---|---|
| `isColliding(other)` | Circle↔Circle uses squared distance ≤ squared (sum of radii). Circle↔Box delegates to `BoxCollider.isColliding` for the closest-point-on-AABB check. |

## Advanced usage

### Bouncy ball

```typescript
const c = new CircleCollider(ball.transform, 8);
c.restitution = 0.95;
ball.setCollider(c);
```

### Pair with a custom `Entity` subclass

`CanvasRenderer2D.drawSprite` draws rectangles, so to render a ball you typically subclass `Entity` to override `render` and draw a circle. The collider stays a `CircleCollider`. See [Entity](../scene/entity.md#subclassing-for-custom-render) for the render pattern.

## Pitfalls & FAQ

- **No `size` field.** `CircleCollider` uses `radius`, not `size`. Do not access `.size`.
- **Concentric circles.** When two circle colliders share a position, `Manifold.compute` picks an arbitrary normal `(1, 0)` and `penetration = sum of radii`. This avoids a divide-by-zero but means the contact direction is undefined for stacked circles.
- **Box↔Circle always treats the box as the receiver.** When `Manifold.compute(a=circle, b=box)` runs, it internally swaps so the box is `a`. The normal is then negated so it always points from box to circle. Consumers do not need to worry about this — `applyImpulse` handles the contact regardless of order.
- **Circle↔Box overlap does not mean the circle center is inside the box.** A circle whose center is outside the box but whose radius reaches the edge still overlaps, and `Manifold.compute` pushes it out along the closest-point direction.

## See also

- [Collider](collider.md) — base class.
- [BoxCollider](boxcollider.md) — the other concrete shape.
- [Manifold](manifold.md) — contact data for the closest-point case.
- [Entity](../scene/entity.md#subclassing-for-custom-render) — render override pattern for circles.
