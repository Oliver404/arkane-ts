---
title: SceneContext
version: 0.0.1
section: scene
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# SceneContext

A bundle of global services injected into every `Scene2D` by the `Engine`. Holds references to the input manager, the camera, the event bus, and the asset manager. Read-only from a scene's perspective — you should not reassign these fields.

## Basic usage

```typescript
class GameScene extends Scene2D {
  override update(): void {
    super.update();
    const ctx = this.context;          // SceneContext | undefined
    if (!ctx) return;

    // Read input in world coordinates.
    const touches = ctx.input.getTouchesWorld();

    // Emit a game event.
    ctx.events.emit('enemy.spawned', { x: 100, y: 50 });

    // Load an asset (async; needs await).
    // const tex = await ctx.assets.load('sprites/hero.png');
  }
}
```

## Configuration

### Properties (all readonly)

| Name | Type | Description |
|---|---|---|
| `input` | `InputManager` | The engine's touch + gesture state. |
| `camera` | `Camera2D` | The scene's camera (created by `engine.setRenderer`). |
| `events` | `EventBus` | A fresh per-scene pub/sub bus. |
| `assets` | `AssetManager` | The texture cache. Default is a no-op manager if you did not call `engine.setAssetManager(...)`. |

### Constructor

```typescript
new SceneContext(input, camera, events, assets?)
```

If `assets` is omitted, a default `AssetManager` is constructed (no resource manager, no decoder — `load()` throws). Always provide one if you need async loading.

## Advanced usage

### Sharing assets across scenes

The `Engine` keeps a single `AssetManager` instance and re-injects it into every new `SceneContext`. Loaded textures are cached by name across scene transitions.

```typescript
// In a menu scene
const logo = await this.context.assets.load('logo.png');
this.logoEntity.sprite = new Sprite(logo.width, logo.height, '#ffffff');
this.logoEntity.sprite.image = logo;
```

When you navigate to a gameplay scene via `engine.setScene(...)`, `context.assets` is the same instance and the cache survives.

### Replacing the asset manager mid-run

```typescript
const newManager = new AssetManager(resourceManager, decoder);
engine.setAssetManager(newManager);
```

New scenes will see the new manager. Already-running scenes continue to use the one they were constructed with — only `setScene` (which calls `setContext` internally) refreshes the reference.

## Pitfalls & FAQ

- **`this.context` may be `undefined` outside of `update`/`render`.** The engine injects the context right before the first tick. Guard with `if (!this.context) return;` or use the optional-chaining `this.context?.input`.
- **`events` is per-scene.** Every `engine.start(scene)` call creates a fresh `EventBus`. Use `engine.setScene(scene)` for navigation if you want listeners to survive across scene transitions.
- **`camera` is shared across scenes** (the engine re-injects it). If you mutate `camera.position` in one scene, every other scene sees the change unless you reset it on enter.
- **`assets` is shared across scenes.** The cache survives. To force a clean slate, call `assets.clear()` once.

## See also

- [Scene2D](scene2d.md) — `setContext`, `getContext`.
- [Engine](../core/engine.md) — creates and injects the context.
- [InputManager](../input/inputmanager.md), [Camera2D](../render/camera2d.md), [EventBus](../events/eventbus.md), [AssetManager](../assets/assetmanager.md) — the four services the context exposes.
