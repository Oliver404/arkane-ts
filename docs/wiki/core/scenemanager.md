---
title: SceneManager
version: 0.0.1
section: core
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# SceneManager

Holds at most one active `Scene2D`. The engine constructs one internally and uses it to manage transitions. Consumers normally do not interact with it directly — call `engine.setScene(...)` instead.

## Basic usage

You typically do not construct or call methods on `SceneManager`. The engine does:

```typescript
// Engine.start(scene):
sceneManager.setScene(scene);     // calls scene.onEnter()

// Engine.setScene(newScene):
sceneManager.setScene(newScene);  // calls oldScene.onExit(), newScene.onEnter()

// Each tick:
sceneManager.update();             // calls currentScene.update()
```

## Methods

| Method | Description |
|---|---|
| `setScene(scene \| null)` | Replaces the active scene. Calls `onExit` on the previous (if any), then `onEnter` on the new one. Passing `null` is equivalent to clearing. |
| `clear()` | Convenience for `setScene(null)`. |
| `getCurrentScene(): Scene2D \| undefined` | The currently active scene, or `undefined` after `clear` or before any `setScene`. |
| `update()` | Calls `currentScene.update()` if a scene is present; otherwise no-op. |

## Pitfalls & FAQ

- **No scene stack.** Only one scene is active. If you need "pause overlay on top of gameplay," either pause the gameplay scene manually (`scene.gravity = Vector2(0,0); scene.paused = true;`) and have the pause scene handle its own logic, or build your own stack outside the library.
- **`getCurrentScene()` returns `undefined` initially.** The engine injects the initial scene in `start()`. Inside the constructor of a custom `GameSystem`, the scene is not yet present.
- **Lifecycle order matters.** `setScene` calls `onExit` on the previous scene **before** `onEnter` on the new one. If you transfer resources (event listeners, asset preloads), the previous scene's `onExit` is the place to do it.

## See also

- [Scene2D](../scene/scene2d.md) — the scenes it manages.
- [Engine](engine.md) — the owner and primary caller.
