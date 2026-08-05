---
title: Transform
version: 0.0.1
section: scene
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Transform

Position, scale, and rotation for an `Entity`. Plain data class — the engine does no math on it directly; it is consumed by the renderer (for screen position and rotation) and by the physics layer (for position and velocity coupling).

## Basic usage

```typescript
import { Entity, Vector2 } from '@oliver404/arkane-ts';

const e = new Entity();
e.transform.position = new Vector2(100, 200);
e.transform.scale = new Vector2(2, 2);    // 2× larger
e.transform.rotation = Math.PI / 4;      // 45 degrees, in radians
```

Or pass `position` at construction time:

```typescript
import { Transform, Vector2 } from '@oliver404/arkane-ts';

const t = new Transform(new Vector2(50, 50));
```

## Configuration

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `position` | `Vector2` | `(0, 0)` | World position. World Y points **UP**. |
| `scale` | `Vector2` | `(1, 1)` | Per-axis scale multiplier. Applied to sprite size at render time. |
| `rotation` | `number` | `0` | Rotation in **radians** around the sprite center (positive Y is up, so positive rotation is counter-clockwise from above). |

## Advanced usage

Move an entity along an arbitrary axis each frame:

```typescript
const speed = 60; // pixels per second
const direction = new Vector2(1, 0).normalize();
e.transform.position.add(
  direction.multiply(speed * Time.deltaTime)
);
```

Constant rotation:

```typescript
e.transform.rotation += Math.PI * Time.deltaTime; // half a turn per second
```

The `Transform` is shared between the entity, its `Collider`, and its `Rigidbody`. Mutating `position` from anywhere is visible to all three.

## Pitfalls & FAQ

- **Rotation is in radians, not degrees.** `Math.PI` is 180°. There is no built-in degree converter — multiply by `Math.PI / 180` if you store degrees elsewhere.
- **Rotation is around the sprite center.** The renderer translates, rotates, then draws centered on the rotated origin. For `BoxCollider`, rotation is **ignored** (AABB); only `position` and `size` matter for collision.
- **`scale` is a multiplier, not an absolute size.** `scale = (2, 2)` makes a 32×32 sprite render as 64×64. The collider is unaffected — collisions use the collider's own `size`.
- **No parent/child hierarchy.** Transforms are flat. If you need hierarchy, build it yourself by composing matrices.

## See also

- [Entity](entity.md) — owns the transform.
- [Vector2](../math/vector2.md) — what `position` and `scale` are.
- [Sprite](../render/sprite.md) — uses `position`, `scale`, and `rotation` at draw time.
