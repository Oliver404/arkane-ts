---
title: Entity
version: 0.0.1
section: scene
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Entity

The base node added to a `Scene2D`. Holds a `Transform` and optional `Sprite`, `Collider`, and `Rigidbody`. Subclass it freely — the engine treats any subclass as a first-class scene entity.

## Basic usage

```typescript
import { Entity, Sprite, BoxCollider, Rigidbody, Vector2 } from '@oliver404/arkane-ts';

const e = new Entity();
e.transform.position = new Vector2(100, 50);
e.sprite = new Sprite(32, 32, '#ff0000');
e.setCollider(new BoxCollider(e.transform, 32, 32));
e.setRigidbody(new Rigidbody(e.transform));

scene.addEntity(e);
```

## Configuration

### Properties

| Name | Type | Description |
|---|---|---|
| `id` | `number` (readonly) | Auto-incrementing, unique per process. Useful for debugging. |
| `transform` | `Transform` (readonly) | Owned by the entity; never reassigned. Mutate its fields. |
| `sprite` | `Sprite?` | If set, `Entity.render` delegates to `renderer.drawSprite`. |
| `collider` | `Collider?` | Set via `setCollider`. Read by `PhysicsSystem` and `CollisionSystem`. |
| `rigidbody` | `Rigidbody?` | Set via `setRigidbody`. Integrated by `PhysicsSystem` when present. |

### Methods

| Method | Description |
|---|---|
| `setCollider(collider)` | Assigns the collider. The collider references the same `transform` you pass — they are intentionally coupled. |
| `setRigidbody(rigidbody)` | Assigns the rigidbody. Same coupling: rigidbody reads from and writes to the entity's transform. |
| `update()` | Default is empty. Override to add per-entity per-frame logic. |
| `render(context, renderer, camera?)` | Default delegates to `renderer.drawSprite(sprite, transform, camera)` if `sprite` is set. Otherwise no-op. Override for custom rendering. |

## Advanced usage

### Subclassing for custom render

`CanvasRenderer2D.drawSprite` only fills rectangles. To draw a circle (a ball), override `render`:

```typescript
class BallEntity extends Entity {
  radius: number = 8;
  color: string = '#ff0000';

  override render(
    context: RenderContext,
    _renderer: Renderer2D,
    camera?: Camera2D
  ): void {
    if (camera === undefined) return;
    const screen = camera.worldToScreen(this.transform.position);
    const r = this.radius * camera.zoom;
    context.ctx.save();
    context.ctx.fillStyle = this.color;
    context.ctx.beginPath();
    context.ctx.arc(screen.x, screen.y, r, 0, Math.PI * 2);
    context.ctx.fill();
    context.ctx.restore();
  }
}
```

### Custom update logic

```typescript
class AutoSpinEntity extends Entity {
  speed: number = 1.5;          // radians per second

  override update(): void {
    this.transform.rotation += this.speed * Time.deltaTime;
  }
}
```

### Tagging and grouping

There is no built-in tag system. If you need to find entities by category, give your subclass a property:

```typescript
class Enemy extends Entity {
  hp: number = 3;
}
const enemies = scene.getEntities().filter((e): e is Enemy => e instanceof Enemy);
```

## Pitfalls & FAQ

- **`transform` is created in the constructor.** You cannot reassign it (`readonly`), but you can replace its fields freely.
- **Collider and rigidbody share the entity's transform.** Both `BoxCollider(transform, w, h)` and `Rigidbody(transform)` take a reference. Mutating `entity.transform.position` is visible to both — that is the whole point.
- **Auto-incrementing `id` is process-global.** Two engines in the same process share the counter. In practice you only run one engine per canvas.
- **`update` is a no-op by default.** With `PhysicsSystem` registered, you do not need to call `rigidbody.update(dt)` yourself — the system handles it. Without it, you must integrate manually.
- **Default `render` is no-op if no sprite.** If you forget to set `sprite`, your entity draws nothing but still participates in collision if a collider is attached.

## See also

- [Transform](transform.md) — the entity's position, scale, and rotation.
- [Sprite](../render/sprite.md) — what `Entity.render` uses by default.
- [BoxCollider](../physics/boxcollider.md), [CircleCollider](../physics/circlecollider.md) — collision shapes.
- [Rigidbody](../physics/rigidbody.md) — mass, velocity, gravity.
