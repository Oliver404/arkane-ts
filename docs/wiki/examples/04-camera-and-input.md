---
title: Example 04 — Camera and input
version: 0.0.1
section: examples
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Example 04 — Camera and input

Combines `Camera2D.follow`, world bounds, and gesture detection (swipe, long-press) into a small top-down scene.

## What you will build

- A player in a wider world (300×300 world units).
- A camera that follows the player.
- World bounds that stop the camera at the edges.
- Swipe to "kick" the player in the swipe direction.
- Long-press to spawn a marker at the press location.

## Scene

```typescript
import {
  BoxCollider,
  Entity,
  GameSystem,
  InputManager,
  MathUtils,
  Rigidbody,
  Scene2D,
  Sprite,
  Vector2,
} from '@oliver404/arkane-ts';

// Required because Camera2D.update() is not auto-driven.
class CameraUpdateSystem implements GameSystem {
  beforeUpdate(): void {
    // The engine calls beforeUpdate on registered systems in registration order.
    // We do not have an engine back-reference here; in real code, capture
    // the engine in the system constructor and call `engine.getScene()?.context?.camera?.update()`.
  }
}

export class CameraScene extends Scene2D {
  private player!: Entity;
  private marker: Entity | null = null;

  override onEnter(): void {
    this.gravity = new Vector2(0, 0);

    // World bounds so the camera does not show empty space at the edges.
    const cam = this.context!.camera;
    cam.setWorldBounds(-150, 150, -150, 150);
    cam.zoom = 1.5;

    // Player
    this.player = new Entity();
    this.player.transform.position = new Vector2(0, 0);
    this.player.sprite = new Sprite(16, 16, '#00ff00');
    const c = new BoxCollider(this.player.transform, 16, 16);
    c.restitution = 0.6;
    this.player.setCollider(c);
    this.player.setRigidbody(new Rigidbody(this.player.transform));
    cam.follow(this.player);
  }

  override update(): void {
    super.update();
    const input = this.context?.input;
    if (!input) return;

    // Swipe → kick the player in the swipe direction.
    if (input.isSwipeTriggered()) {
      const dir = input.getSwipeDirection();
      if (dir) {
        const k = 250;
        this.player.rigidbody!.applyImpulse(new Vector2(dir.x * k, dir.y * k));
      }
    }

    // Long press → place a marker that decays.
    if (input.isLongPressTriggered()) {
      const p = input.getLongPressPosition();
      if (p) this.spawnMarker(p.x, p.y);
    }

    // Keep the player inside the world.
    const rb = this.player.rigidbody!;
    rb.velocity.x = MathUtils.clamp(rb.velocity.x, -150, 150);
    rb.velocity.y = MathUtils.clamp(rb.velocity.y, -150, 150);
  }

  private spawnMarker(x: number, y: number): void {
    if (this.marker) this.removeEntity(this.marker);
    const m = new Entity();
    m.transform.position = new Vector2(x, y);
    m.sprite = new Sprite(8, 8, '#ffff00');
    this.addEntity(m);
    this.marker = m;
  }
}
```

> **Important**: `Camera2D.update()` is not auto-driven. Register a small system that calls it once per tick:

```typescript
class CameraTickSystem implements GameSystem {
  beforeUpdate(): void {
    // Walk to find the active scene's camera.
    const engine = (this as any).engine as Engine | undefined;
    engine?.getScene()?.context?.camera?.update();
  }
  attach(engine: Engine): void {
    (this as any).engine = engine;
  }
}

engine.registerSystem(new CameraTickSystem());
```

## Try it

1. Swipe quickly in any direction — the player gets a kick in that direction.
2. Press and hold — a yellow marker appears at the press position.
3. Move the player to the world edge — the camera stops following once the viewport hits the bound.

## Tuning

| Effect | How |
|---|---|
| Wider zoom | `camera.zoom = 2.0` |
| Slower camera follow | Not built in — write a damping step yourself before calling `camera.update()`. |
| Different swipe sensitivity | `engine.getInput().setSwipeThresholds(50, 200)` — 50 units in ≤ 200 ms. |
| Different long-press threshold | `engine.getInput().setLongPressThresholds(750, 12)` — 750 ms, 12 units of slop. |

## Pitfalls

- **Camera `update()` must be called explicitly.** If you forget the `CameraTickSystem`, `follow` is a no-op and the camera stays at `(0, 0)`.
- **`setWorldBounds` clamps the camera center, not the player.** The player can still wander up to `±(halfViewport / zoom)` past the bounds visually before the camera stops moving.
- **Gestures do not stack.** A long press invalidates the swipe candidate and vice versa for the same gesture. If you want both, release the finger and start a new touch.
- **`setWorldBounds` and `setSwipeThresholds` are persistent.** Changing them in one scene affects subsequent scenes that share the same `Camera2D` and `InputManager`.

## Next

- [05 — Assets and events](05-assets-and-events.md) — image-backed sprites and scene-to-scene messaging.
- [Cookbook: endless runner](../cookbook/endless-runner.md) — uses `Camera2D.follow` plus world scrolling.
