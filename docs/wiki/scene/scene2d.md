---
title: Scene2D
version: 0.0.1
section: scene
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Scene2D

The abstract base class for every game screen (menu, gameplay, pause, game-over). A scene owns a list of entities, an optional camera, and an optional `SceneContext`. The engine calls `onEnter` once when the scene becomes active, `update` every frame, and `onExit` once before transitioning away.

## Basic usage

```typescript
import { Scene2D, Entity, Sprite, Vector2 } from '@oliver404/arkane-ts';

class TitleScene extends Scene2D {
  override onEnter(): void {
    const logo = new Entity();
    logo.transform.position = new Vector2(0, 40);
    logo.sprite = new Sprite(80, 40, '#ffffff');
    this.addEntity(logo);
  }
}

engine.start(new TitleScene());
```

## Configuration

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `gravity` | `Vector2` | `(0, -9.8)` | World-space gravity vector. Y points **UP**, so positive Y is upward. Set to `Vector2(0, 0)` for top-down games. |

### Abstract method

| Method | Description |
|---|---|
| `onEnter(): void` | **Must override.** Called once when the scene becomes active. Spawn your entities here. |

### Optional overrides

| Method | Default | Description |
|---|---|---|
| `onExit(): void` | empty | Cleanup timers, unsubscribed events. Called before transitioning away. |
| `update(): void` | iterates `entity.update()` for every entity | Read input, advance game state. Call `super.update()` to also iterate entities. |
| `render(context, renderer): void` | iterates `entity.render(ctx, renderer, camera)` | Custom draw pass — usually you leave this alone and let entities draw themselves. |

### Built-in API

| Method | Description |
|---|---|
| `addEntity(entity)` | Appends an entity to the scene. |
| `removeEntity(entity)` | Removes the entity if present (silently does nothing otherwise). |
| `getEntities(): readonly Entity[]` | The current entity list. Read-only view. |
| `entityCount(): number` | Number of entities. |
| `setCamera(camera)` | Inject a `Camera2D`. Normally the engine does this for you via `engine.setRenderer(...)`. |
| `setContext(context)` | Inject a `SceneContext`. Normally the engine does this. |
| `getContext(): SceneContext \| undefined` | Access `input`, `camera`, `events`, `assets`. |

## Advanced usage

Top-down game with custom gravity:

```typescript
class TopDownScene extends Scene2D {
  override onEnter(): void {
    this.gravity = new Vector2(0, 0);  // no fall
    // ...
  }
}
```

Per-frame input dispatch:

```typescript
override update(): void {
  super.update();              // update entities first
  const input = this.context?.input;
  if (input?.isTouchStarted()) {
    // handle tap
  }
}
```

Dynamic entity cleanup (e.g. expired particles):

```typescript
override update(): void {
  super.update();
  for (const e of this.getEntities()) {
    if (e.rigidbody && e.transform.position.y < -1000) {
      this.removeEntity(e);
    }
  }
}
```

## Pitfalls & FAQ

- **`onEnter` is mandatory.** The class is abstract; TypeScript will complain if you do not override it.
- **`context` may be `undefined` outside of `update`/`render`.** The engine injects the context right before the first tick, but it is typed `optional` for safety. Use `this.context?.input` or guard with `if (!this.context) return;`.
- **Entities are not auto-cleaned.** Removing an entity from the scene does not detach its collider or rigidbody. If you switch scenes, the previous scene's entities are simply discarded — but any timers or external references you held remain your responsibility.
- **Iteration order is insertion order.** `update` and `render` walk `entities[]` in the order entities were added. Use this if you need z-ordering or deterministic updates.
- **`gravity` is per-scene.** It is applied by `PhysicsSystem` to entities with `Rigidbody.gravityScale !== 0`. Manually-integrated rigidbodies are unaffected.

## See also

- [Entity](entity.md) — the things a scene contains.
- [SceneContext](scenecontext.md) — the global services exposed to the scene.
- [Engine](../core/engine.md) — drives the lifecycle and owns the active scene.
- [Architecture](../architecture.md#lifecycle-hooks) — full lifecycle hook map.
