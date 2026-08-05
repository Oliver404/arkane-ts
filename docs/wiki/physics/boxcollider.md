---
title: BoxCollider
version: 0.0.1
section: physics
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# BoxCollider

An axis-aligned bounding box (AABB) collider centered on the entity's transform. Rotation is **intentionally ignored** — for rotated boxes you need an OBB collider (V1.2+).

## Basic usage

```typescript
import { Entity, BoxCollider, Vector2 } from '@oliver404/arkane-ts';

const e = new Entity();
e.transform.position = new Vector2(0, 0);
e.setCollider(new BoxCollider(e.transform, 32, 48));   // 32 wide, 48 tall
```

## Configuration

### Constructor

```typescript
new BoxCollider(transform: Transform, width: number, height: number)
```

| Parameter | Description |
|---|---|
| `transform` | The transform the collider follows. Usually `entity.transform`. |
| `width` | Box width in world units. |
| `height` | Box height in world units. |

### Properties

| Name | Type | Description |
|---|---|---|
| `size` | `Vector2` | The (width, height) you passed in. Mutate to resize. |
| `transform` | `Transform` | Inherited from `Collider`. |
| `friction`, `restitution` | `number` | Inherited from `Collider`. |

### Read-only accessors

| Getter | Returns | Notes |
|---|---|---|
| `left` | `position.x - size.x / 2` | |
| `right` | `position.x + size.x / 2` | |
| `top` | `position.y - size.y / 2` | Smaller Y (Y points UP). |
| `bottom` | `position.y + size.y / 2` | Larger Y. |

### Methods

| Method | Description |
|---|---|
| `isColliding(other)` | Returns `true` if this AABB overlaps `other`. Box↔Box uses AABB overlap. Box↔Circle uses closest-point on the AABB to the circle center. |

## Advanced usage

### Static wall

A static wall is a `BoxCollider` on an entity with **no rigidbody**, or a rigidbody with `mass = 0` (interpreted as infinite mass by `PhysicsSystem`).

```typescript
const wall = new Entity();
wall.transform.position = new Vector2(0, -100);
wall.sprite = new Sprite(400, 20, '#888');
const c = new BoxCollider(wall.transform, 400, 20);
c.restitution = 1.0;
wall.setCollider(c);
// no setRigidbody — purely static
scene.addEntity(wall);
```

### Half-overlap debugging

If two boxes only overlap on one axis (a corner touch), `Manifold.compute` resolves along the **smaller-overlap axis**. This is the standard SAT choice and is what `PhysicsSystem` uses to push bodies apart.

## Pitfalls & FAQ

- **Rotation is ignored.** A 45°-rotated entity still uses its unrotated AABB for collision. If you need rotated colliders, wait for V1.2 OBB support.
- **Centers on the entity position.** The box extends `width/2` to either side of `transform.position.x`. If you want the corner to anchor at the position, offset by `(width/2, height/2)` in your setup.
- **`top` / `bottom` follow world Y-up.** `top` is the smaller Y (further from gravity), `bottom` is larger.
- **Pure AABB test** — for any two `BoxCollider`s, `isColliding` returns false if they share only an edge (no overlap on at least one axis).

## See also

- [Collider](collider.md) — base class with `friction` / `restitution`.
- [CircleCollider](circlecollider.md) — the other concrete shape.
- [Rigidbody](rigidbody.md) — needed for dynamic bodies.
- [PhysicsSystem](physicssystem.md) — runs collision resolution.
