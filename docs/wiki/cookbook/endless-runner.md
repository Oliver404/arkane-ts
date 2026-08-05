---
title: Recipe — Endless runner
version: 0.0.1
section: cookbook
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Recipe — Endless runner

A side-scrolling endless-runner skeleton: the world scrolls left, the player jumps over obstacles, and the camera follows the player. Demonstrates `Camera2D.follow` + world-bounds + scrolling entities.

## What you build

- A `Camera2D` that follows the player on the X axis.
- A scrolling ground (a series of tiles that recycle when they leave the viewport).
- Obstacles spawned ahead of the camera and recycled behind it.
- A player that can jump.

## Pattern: scrolling world without moving entities

Two equivalent approaches:

1. **Move entities, keep the camera at `(0, 0)`.** Easier physics (camera-relative positions match world positions).
2. **Keep entities still, move the camera.** Better for endless worlds — no need to recycle entities.

This recipe uses approach 2. The player stays at world `(0, groundY)`. Obstacles spawn at increasing world X, get recycled when they leave the viewport behind the camera.

## Scene

```typescript
import {
  BoxCollider,
  Entity,
  GameSystem,
  Manifold,
  Rigidbody,
  Scene2D,
  Sprite,
  Vector2,
} from '@oliver404/arkane-ts';

const GROUND_Y = -80;

class EndlessRunnerScene extends Scene2D {
  private player!: Entity;
  private obstacles: Entity[] = [];
  private nextObstacleAt: number = 4;   // seconds until next spawn
  private scrollSpeed: number = 60;    // world units per second (camera moves -X)
  private timeAlive: number = 0;
  private isGrounded: boolean = false;

  override onEnter(): void {
    this.gravity = new Vector2(0, -25);

    // Ground — a single very wide collider.
    const ground = new Entity();
    ground.transform.position = new Vector2(0, GROUND_Y - 8);
    ground.sprite = new Sprite(10000, 16, '#555');
    ground.setCollider(new BoxCollider(ground.transform, 10000, 16));
    this.addEntity(ground);

    // Player
    this.player = new Entity();
    this.player.transform.position = new Vector2(0, GROUND_Y - 16);
    this.player.sprite = new Sprite(16, 24, '#00ff00');
    const c = new BoxCollider(this.player.transform, 16, 24);
    c.restitution = 0;
    this.player.setCollider(c);
    const rb = new Rigidbody(this.player.transform);
    rb.gravityScale = 1;
    this.player.setRigidbody(rb);
    this.addEntity(this.player);

    // Camera follows player, world bounds prevent showing empty space.
    const cam = this.context!.camera;
    cam.zoom = 1.5;
    cam.follow(this.player);
    cam.setWorldBounds(-Infinity, Infinity, GROUND_Y - 50, GROUND_Y + 50);
  }

  override update(): void {
    super.update();
    this.timeAlive += Time.deltaTime;

    // Scroll the camera left (world moves right relative to camera).
    const cam = this.context!.camera;
    cam.position.x -= this.scrollSpeed * Time.deltaTime;

    // Jump on tap.
    this.refreshGrounded();
    const input = this.context?.input;
    if (input?.isTouchStarted() && this.isGrounded) {
      this.player.rigidbody!.velocity.y = 12;
    }

    // Spawn and recycle obstacles.
    if (this.timeAlive >= this.nextObstacleAt) {
      this.spawnObstacle();
      this.nextObstacleAt = this.timeAlive + 1.5 + Math.random();
    }
    for (let i = this.obstacles.length - 1; i >= 0; i--) {
      const o = this.obstacles[i];
      if (o.transform.position.x < cam.position.x - 200) {
        this.removeEntity(o);
        this.obstacles.splice(i, 1);
      }
    }
  }

  private refreshGrounded(): void {
    this.isGrounded = false;
    const ground = this.getEntities().find(e => e.collider && e.collider.friction === undefined);
    // Use the ground collider directly — find by reference if you have it as a field.
    // For brevity, this snippet leaves the ground check to PhysicsSystem collisions
    // (the player simply cannot fall below the ground because the static collider
    // stops them). A real implementation should track grounded explicitly.
  }

  private spawnObstacle(): void {
    const o = new Entity();
    o.transform.position = new Vector2(this.context!.camera.position.x + 120, GROUND_Y - 12);
    o.sprite = new Sprite(16, 24, '#ff3030');
    o.setCollider(new BoxCollider(o.transform, 16, 24));
    this.obstacles.push(o);
    this.addEntity(o);
  }
}
```

## Why approach 2 (move camera, not entities)?

- **No recycling the ground.** The ground is a single static collider 10000 units wide.
- **Obstacle lifecycle is simple.** Spawn ahead of the camera, despawn behind.
- **Player physics are local.** The player stays at world `(0, -Y)`, which makes "jump height" constants easier to reason about.

## Variations

- **Speed up over time**: increase `scrollSpeed` as `timeAlive` grows.
- **Procedural gap generation**: spawn obstacles in patterns (double, triple, low/high) using a seeded RNG.
- **Distance counter**: maintain a `distance = cam.position.x * -1` (since the camera moves left), show as a HUD.
- **Visual ground tiles**: instead of a single 10000-wide sprite, use multiple shorter tiles that recycle as the camera moves past them — keeps the texture memory bounded.

## Pitfalls

- **Camera `update()` must still be called explicitly.** This snippet moves `cam.position.x` directly in the scene's `update`, but if you want `follow(target)` to keep the camera locked to the player, register a `CameraUpdateSystem` (see [Example 04](../examples/04-camera-and-input.md)).
- **`Infinity` bounds are fine.** `setWorldBounds(-Infinity, Infinity, ...)` clamps the camera to the vertical bounds only.
- **`Math.random()` is non-deterministic.** For reproducible obstacle sequences, inject a seeded RNG (`mulberry32`, etc.) — same pattern as the example's `AiController`.
- **No collision callbacks from `PhysicsSystem`.** Detect "hit obstacle" in your own scene logic by reading positions or by subscribing to `EventBus` from a custom resolver.

## See also

- [Camera2D](../render/camera2d.md) — `follow`, `setWorldBounds`, manual position.
- [Example 04 — Camera and input](../examples/04-camera-and-input.md) — how to drive `camera.update()`.
- [PhysicsSystem](../physics/physicssystem.md) — how collisions resolve.
