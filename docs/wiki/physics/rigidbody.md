---
title: Rigidbody
version: 0.0.1
section: physics
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Rigidbody

The dynamic-side counterpart to a `Collider`. Holds mass, velocity, gravity scale, and drag. `PhysicsSystem` integrates gravity + drag + position and resolves collisions against colliders every tick.

## Basic usage

```typescript
import { Entity, Rigidbody } from '@oliver404/arkane-ts';

const e = new Entity();
e.setRigidbody(new Rigidbody(e.transform));

// Give the body an initial velocity (units per second).
e.rigidbody!.velocity.set(60, 0);
```

Register `PhysicsSystem` once at bootstrap so the engine ticks physics for you:

```typescript
engine.registerSystem(new PhysicsSystem());
```

Without `PhysicsSystem`, you must call `rigidbody.update(dt)` manually from a scene or system.

## Configuration

### Constructor

```typescript
new Rigidbody(transform: Transform)
```

The transform is shared with the entity — mutating the body's velocity moves the entity's position.

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `transform` | `Transform` | (constructor) | The body's position is read/written here. |
| `velocity` | `Vector2` | `(0, 0)` | Linear velocity in world units per second. |
| `mass` | `number` | `1` | Positive = dynamic. `0` or negative = infinite-mass / static — `PhysicsSystem` skips it during integration. |
| `gravityScale` | `number` | `1` | Multiplier on `scene.gravity`. `0` = unaffected. Negative = flips direction. |
| `drag` | `number` | `0` | Linear damping. Each `update(dt)` multiplies velocity by `max(0, 1 - drag*dt)`. `0` = no damping. |

### Methods

| Method | Description |
|---|---|
| `update(deltaTime)` | Apply drag and integrate position. **Manual use only** when `PhysicsSystem` is not registered. |
| `applyImpulse(impulse)` | Add to velocity: `v += impulse / mass`. **No-op when `mass <= 0`**. |

## Advanced usage

### Static body (mass = 0)

```typescript
const wall = new Entity();
const rb = new Rigidbody(wall.transform);
rb.mass = 0;          // infinite mass — physics skips it
wall.setRigidbody(rb);
```

In `PhysicsSystem`, mass-zero bodies are not integrated and do not receive collision impulses, but they still participate in contact detection. They behave like static walls.

### Jumping (instant velocity change)

```typescript
player.rigidbody!.velocity.y = 0;            // cancel downward velocity first
player.rigidbody!.applyImpulse(new Vector2(0, 300));
```

`applyImpulse` divides by mass, so a body with `mass = 2` receiving `impulse = (0, 300)` gets `velocity.y += 150`.

### One-way platforms

Set `gravityScale = 0` on platform entities to make them ignore gravity while still participating in collision. Combine with a custom solver if you need actual one-way logic (e.g. only collide from above) — that ships in V1.2.

## Pitfalls & FAQ

- **Sharing `transform` with the entity is the whole point.** Do not pass a fresh `Transform` to `new Rigidbody(...)`; the body will move independently of the entity.
- **`mass = 0` is special.** The body is treated as static — neither integrated nor impulsed. `applyImpulse` is a no-op. To push a static body, change its `velocity` and call `update(dt)` yourself (rare).
- **Drag is per-second, not per-frame.** `drag = 1` does **not** mean "velocity halves each frame." It means the velocity decays so that after one second roughly 1/e of it remains. Use the formula `velocity *= max(0, 1 - drag*dt)` to reason about it.
- **Gravity direction follows scene Y-up.** With `Scene2D.gravity = (0, -9.8)` and `gravityScale = 1`, the body accelerates in `-Y` (downward on screen).
- **Negative gravityScale flips direction.** Useful for a jet-pack / underwater effect without redefining `scene.gravity`.
- **No angular velocity.** The body does not track rotation. Spinning entities must update `transform.rotation` manually.

## See also

- [Collider](collider.md) — the shape side; works with this rigidbody.
- [PhysicsSystem](physicssystem.md) — the auto-driven tick.
- [Vector2](../math/vector2.md) — `velocity` is a mutable `Vector2`.
