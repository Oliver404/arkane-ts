---
title: Architecture
version: 0.0.1
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Architecture

This page describes how the engine is wired internally: who owns what, the per-frame tick order, and the conventions you need to internalize before building non-trivial games.

## Module map

The `Engine` class is a thin orchestrator. It owns (or holds a reference to) every other top-level piece:

```
Engine
 ├── GameLoop          (drives the per-frame tick)
 ├── SceneManager      (holds the active Scene2D)
 ├── InputManager      (touch state + gestures)
 ├── AssetManager      (texture cache, pluggable decoder)
 ├── EventBus          (per-scene pub/sub — created in start())
 ├── Renderer2D        (swap-in render backends)
 ├── Camera2D          (world↔screen conversion)
 └── registered        GameSystem[] (e.g. PhysicsSystem)

Each Scene2D owns:
 ├── gravity: Vector2
 ├── entities: Entity[]
 ├── optional Camera2D
 └── optional SceneContext (input, camera, events, assets)

Each Entity owns:
 ├── Transform         (position, scale, rotation)
 ├── optional Sprite   (size + color + optional Texture)
 ├── optional Collider (Box or Circle)
 └── optional Rigidbody
```

## Tick order

Each frame, the engine runs this sequence:

1. **Time tick** — `GameLoop` advances `Time.deltaTime` and `Time.time`.
2. **`beforeUpdate` of every registered `GameSystem`** (in registration order). `PhysicsSystem` runs here.
3. **`SceneManager.update()`** — calls `currentScene.update()`, which iterates every entity's `update()`.
4. **`afterUpdate` of every registered `GameSystem`** (in registration order).
5. **`InputManager.clearFrameFlags()`** — frame-bounded flags (`isTouchStarted`, `isTouchEnded`, `isSwipeTriggered`, `isLongPressTriggered`) become false for the next frame.
6. **Render** — `renderer.begin(ctx)` → `scene.render(ctx, renderer)` → `renderer.end()`. `scene.render` iterates every entity's `render(ctx, renderer, camera)`.

If a system needs `afterUpdate` (e.g. cleanup after physics), implement the optional `afterUpdate()` hook on your `GameSystem`. Both hooks are called in registration order — register dependent systems later.

## Render flow

```
Scene2D.render(ctx, renderer)
  └─ for each entity:
       entity.render(ctx, renderer, camera)
         ├─ if entity is a TextEntity → ctx.fillText(...) [bypasses renderer]
         └─ otherwise → renderer.drawSprite(sprite, transform, camera)
              ├─ camera.worldToScreen(transform.position)
              ├─ ctx.save(); ctx.translate(...); ctx.rotate(radians); ctx.restore();
              └─ if sprite.image → ctx.drawImage(...); else → ctx.fillRect(...)
```

`TextEntity` deliberately ignores the `Renderer2D` abstraction — it draws directly to `context.ctx`. Custom renderers therefore cannot intercept text rendering. If you need a custom text pipeline, fork the class or render via your own `Entity` subclass.

## Scene transitions

There are two ways to change the active scene:

- **`engine.start(scene)`** — first call only. Creates a fresh `EventBus`, builds the `SceneContext`, sets the scene, starts the `GameLoop`.
- **`engine.setScene(scene)`** — subsequent calls. Calls `onExit()` on the previous scene, then `onEnter()` on the new one. Re-injects the existing `SceneContext` and `Camera2D` so you do not need to re-wire anything.

Use `setScene` for menu → game → game-over navigation. Use `start` only once.

## GameSystem lifecycle

```typescript
interface GameSystem {
  attach?(engine: Engine): void   // called once at registration
  beforeUpdate?(): void            // called before scene update each tick
  afterUpdate?(): void             // called after scene update each tick
}
```

All hooks are optional. Use `attach(engine)` if your system needs to look up the current scene (`engine.getScene()`) inside `beforeUpdate` — that is the pattern `PhysicsSystem` follows. See [physics/physicssystem.md](physics/physicssystem.md).

## Y-axis convention

**World Y points UP.** This is the classical physics convention. The default `Scene2D.gravity` is `Vector2(0, -9.8)`, meaning objects fall in the `-Y` direction.

`Camera2D.worldToScreen()` does **not** flip Y. The conversion is purely:

```
screen = (world - camera.position) * zoom + viewport / 2
```

The library never implicitly flips the Y axis. If you want a top-down layout (positive Y goes down on screen, like ArkUI's native canvas), either:

- Put your world objects at negative Y (e.g. the player at `(0, 0)`, ground at `(0, -100)`).
- Or flip the camera's viewport mapping yourself in a custom renderer.

The Pong example in this repo places paddles at `+Y` and uses `(0, 0)` for the ball, treating the canvas as a Y-up world — players start at the top and bottom of the screen and the ball stays in the middle.

## Lifecycle hooks

| Hook | When | Used for |
|---|---|---|
| `Scene2D.onEnter()` | Once, when the scene becomes active | Spawn initial entities, configure gravity, register listeners. |
| `Scene2D.update()` | Every frame, after `beforeUpdate` and before `afterUpdate` | Read input, advance game state. Call `super.update()` to iterate entities. |
| `Scene2D.render(ctx, renderer)` | Every frame, after the engine render frame | Override only if you need a custom draw pass; the default iterates entities. |
| `Scene2D.onExit()` | Once, before transitioning away | Default is empty. Override to remove timers, unsubscribe events. |
| `Entity.update()` | Every frame, after `beforeUpdate` | Default is empty. Override for per-entity logic. |
| `Entity.render(ctx, renderer, camera?)` | Every frame, during the render pass | Default delegates to `renderer.drawSprite(sprite, transform, camera)`. Override for custom shapes. |

## Where things are pinned

The public API surface (the 41 symbols exported from `@oliver404/arkane-ts`) is enforced by `library/src/test/ApiSurface.test.ets`. Adding a new class means writing a test that lists it; removing or renaming a public class breaks the test. This is what keeps the Wiki honest — the API cannot drift silently.

## Pitfalls & FAQ

- **`PhysicsSystem` is optional.** Without it, no integration runs — `Rigidbody.update(dt)` must be called manually from your own system or scene. See [physics/physicssystem.md](physics/physicssystem.md).
- **`Camera2D.update()` is not auto-driven.** If you call `camera.follow(entity)`, you must also invoke `camera.update()` once per frame (typically from a `GameSystem.beforeUpdate`). The engine does not call it for you.
- **`Time` is global state.** Two engines in the same process would clobber each other's `Time`. In practice you only ever run one engine per canvas.
- **The `Engine` does not own the canvas.** It only borrows the `CanvasRenderingContext2D`. If the canvas is destroyed (page navigation, component unmount), call `engine.stop()` to clear the `setTimeout` chain in `GameLoop`.
- **`EventBus` is recreated on every `start()`.** Subscribers from the previous run are gone. Use `setScene` for navigation if you want to keep listeners alive.
- **Empty placeholder files exist.** `events/GameEvent.ets` and `input/GestureInput.ets` are zero-byte stubs reserved for future use. They are not exported.
