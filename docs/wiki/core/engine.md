---
title: Engine
version: 0.0.1
section: core
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Engine

The orchestrator. Owns the `GameLoop`, `SceneManager`, `InputManager`, `AssetManager`, `EventBus`, `Camera2D`, and a list of registered `GameSystem`s. You create one per app, wire its renderer, register optional systems, then call `start` with your first scene.

## Basic usage

```typescript
import { Engine, CanvasRenderer2D, RenderContext, PhysicsSystem, Scene2D } from '@oliver404/arkane-ts';

const engine = new Engine();

const ctx = new RenderContext(canvasCtx, width, height);
engine.setRenderer(new CanvasRenderer2D('#0e0e1a'), ctx);
engine.registerSystem(new PhysicsSystem());

engine.start(new GameScene());
```

## Configuration

### Constructor

```typescript
new Engine(config?: EngineConfig)
```

`EngineConfig` currently exposes only `targetFPS` (reserved for v2; ignored).

### Lifecycle methods

| Method | Description |
|---|---|
| `start(initialScene)` | First-time setup. Creates a fresh `EventBus`, builds the `SceneContext`, calls `onEnter` on the initial scene, starts the `GameLoop`. **Throws** if no renderer was set. |
| `stop()` | Stops the `GameLoop`. Use when the ArkUI component unmounts. |
| `setScene(scene)` | Switches the active scene. Re-injects the existing `SceneContext` and `Camera2D`. Calls `onExit` on the previous scene, `onEnter` on the new one. |

### Wiring methods

| Method | Description |
|---|---|
| `setRenderer(renderer, context)` | Registers the renderer, creates a `Camera2D` at the context's viewport, wires it into the input manager and current scene (if any). **Call before `start`**. |
| `registerSystem(system)` | Appends a `GameSystem`. If it implements `attach`, the engine calls it with itself. |
| `setAssetManager(manager)` | Replaces the default no-op `AssetManager`. **Call before `start`** (or before any scene calls `assets.load`). |

### Accessors

| Method | Description |
|---|---|
| `getInput(): InputManager` | The engine's `InputManager` instance. |
| `getAssetManager(): AssetManager` | The active asset manager. |
| `getScene(): Scene2D \| undefined` | The currently active scene. Useful inside `GameSystem.beforeUpdate`. |

### Test helpers

| Method | Description |
|---|---|
| `setTestScene(scene)` | Inject a scene without going through `setRenderer` / `start`. |
| `updateForTest()` | Run a single `update` tick synchronously against the injected scene. |

### `EngineConfig`

```typescript
interface EngineConfig {
  targetFPS?: number   // reserved for v2 — currently ignored
}
```

## Tick order

Every frame, the engine runs:

```
for system in systems: system.beforeUpdate?.()
scene.update()              // via SceneManager
for system in systems: system.afterUpdate?.()
input.clearFrameFlags()

renderer.begin(ctx)
scene.render(ctx, renderer)   // via SceneManager
renderer.end()
```

Systems are called in registration order. `PhysicsSystem` registers itself and runs in `beforeUpdate`.

## Advanced usage

### Replace the scene mid-game

```typescript
engine.setScene(new PauseScene());   // -> onExit on GameScene, onEnter on PauseScene
```

The new scene gets the existing `SceneContext` and `Camera2D` automatically. If you mutate `camera.position` in the game scene, the pause scene sees the same camera.

### Custom system

```typescript
class AudioSystem implements GameSystem {
  private engine!: Engine;

  attach(engine: Engine): void { this.engine = engine; }

  beforeUpdate(): void {
    const scene = this.engine.getScene();
    if (!scene) return;
    // poll audio sources based on scene state
  }
}

engine.registerSystem(new AudioSystem());
```

### Multiple systems, ordered

Register them in the order you want them called:

```typescript
engine.registerSystem(new PhysicsSystem());   // runs first in beforeUpdate
engine.registerSystem(new AiSystem());        // runs after physics
engine.registerSystem(new HudSystem());       // runs after AI, can read physics state
```

## Pitfalls & FAQ

- **Call `setRenderer` before `start`.** `start` throws `'Camera not initialized'` if the camera was never created (which requires the renderer's `RenderContext`).
- **One engine per canvas.** Two engines in the same process would clobber `Time` global state. In practice you only run one engine per canvas.
- **Events reset on `start`.** The `EventBus` is recreated on every `start`; subscribers from a previous run are gone. Use `setScene` to keep the same bus across scene changes.
- **Empty placeholder files exist.** `events/GameEvent.ets` and `input/GestureInput.ets` are zero-byte stubs reserved for future use. They are not exported.
- **`getScene()` returns `undefined` before `start` and after `stop`.** Guard with `if (!scene) return;`.

## See also

- [GameLoop](gameloop.md) — the per-frame loop the engine drives.
- [SceneManager](scenemanager.md) — the single-scene holder.
- [Time](time.md) — global timing state.
- [Architecture](../architecture.md) — module map and tick flow.
