---
title: Camera2D
version: 0.0.1
section: render
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Camera2D

Converts between world coordinates and screen coordinates, optionally follows an entity, and supports zoom and world bounds. The engine creates a `Camera2D` for you when you call `engine.setRenderer(...)`.

## Basic usage

```typescript
import { Camera2D, Vector2 } from '@oliver404/arkane-ts';

// (Normally you do not construct one — engine.setRenderer() does.)
const cam = new Camera2D(400, 400);

cam.zoom = 2;
cam.lookAt(new Vector2(100, 50));
cam.setWorldBounds(-500, 500, -500, 500);

cam.follow(playerEntity);   // tracks the player's position each tick
```

You typically never construct a camera yourself. Access the active one via `scene.context.camera`.

## Configuration

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `position` | `Vector2` | `(0, 0)` | World-space position of the camera center. World Y points **UP**. |
| `zoom` | `number` | `1` | Uniform scale factor. `2` means 2× magnification. |
| `viewportWidth` | `number` | (constructor) | Framebuffer width, in pixels. Set at construction. |
| `viewportHeight` | `number` | (constructor) | Framebuffer height, in pixels. |

### Methods

| Method | Description |
|---|---|
| `worldToScreen(worldPos)` | Returns a new `Vector2` in screen space. Pure function of `worldPos`, `camera.position`, `zoom`, and `viewport`. |
| `screenToWorld(screenPos)` | Inverse of `worldToScreen`. Used by `InputManager.getTouchesWorld()`. |
| `follow(target)` | Tells the camera to track `target.transform.position` on each `update()`. Pass `null` to stop following. |
| `lookAt(point)` | One-shot repositioning. Snaps the camera center to the world point. |
| `update()` | Steps the follow logic. **You must call this yourself** — the engine does not drive it. |
| `setWorldBounds(minX, maxX, minY, maxY)` | Clamps `follow` to the rectangle. Outside the bounds the camera stops at the edge. |

## Advanced usage

### Follow a player with smooth bounds

```typescript
class FollowCameraSystem implements GameSystem {
  beforeUpdate(): void {
    const camera = engine.getScene()?.context?.camera;
    if (camera) {
      camera.update();   // <-- this is your responsibility
    }
  }
}

engine.registerSystem(new FollowCameraSystem());
```

Combine `follow` + `setWorldBounds` for a side-scroller that does not show the level edges:

```typescript
camera.follow(player);
camera.setWorldBounds(-levelWidth/2, levelWidth/2, -Infinity, Infinity);
```

### Zoom in and out

```typescript
const targetZoom = 1.5;
camera.zoom = MathUtils.lerp(camera.zoom, targetZoom, 1 - Math.pow(0.001, Time.deltaTime));
```

### Manual conversion in custom renderers

If you override `Entity.render` to draw a shape the renderer does not natively support (e.g. a circle), do the world→screen conversion yourself:

```typescript
override render(context, renderer, camera): void {
  if (!camera) return;
  const screen = camera.worldToScreen(this.transform.position);
  const r = this.radius * camera.zoom;
  // ... draw at screen, with radius r
}
```

## Pitfalls & FAQ

- **`camera.update()` is not auto-driven.** Unlike `PhysicsSystem`, the engine does not call `camera.update()` for you. If you want `follow` to actually work, register a system that calls `update()` once per tick.
- **Y axis is not flipped.** `worldToScreen` keeps Y up. World objects at higher Y appear higher on the canvas. If your game logic assumes Y-down (like ArkUI's native layout), be explicit about it.
- **`lookAt` reassigns `position`.** Calling `lookAt` while `follow` is active is overridden on the next `update()`. To "look at and stop", call `lookAt` then set `followTarget` to null.
- **Bounds clamp the camera center, not the viewport edge.** When `setWorldBounds` is set, `update()` clamps `position.x` to `[minX + halfW, maxX - halfW]` so the viewport stays inside the world. If `maxX - minX < viewportWidth`, the clamp becomes a no-op (you cannot zoom out past the world size).
- **No rotation.** The camera has no `rotation` field — it always points up. If you need rotated viewports, fork the class.

## See also

- [InputManager](../input/inputmanager.md) — uses `screenToWorld` to translate touches.
- [SceneContext](../scene/scenecontext.md) — `context.camera` is the live instance.
- [Transform](../scene/transform.md) — the `Vector2` semantics used for `position`.
