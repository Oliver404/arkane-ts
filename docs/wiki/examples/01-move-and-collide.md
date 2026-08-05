---
title: Example 01 — Move and collide
version: 0.0.1
section: examples
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Example 01 — Move and collide

The minimum viable Arkane TS game: one touch-controlled square that bounces off a wall. No assets, no UI, no event bus. Once you have this running, every other example in the Wiki builds on it.

## What you will build

- A full-screen ArkUI canvas.
- An `Engine` with a `CanvasRenderer2D` and a `PhysicsSystem`.
- A `Scene2D` with:
  - one static wall (`BoxCollider`, no rigidbody)
  - one dynamic player (`BoxCollider` + `Rigidbody`, gravity disabled)
- A touch handler that drags the player to the finger position.

The player follows your finger. If you throw it at the wall, `PhysicsSystem` bounces it back.

## Files

You will create two files:

- `entry/src/main/ets/pages/Index.ets` — the ArkUI `@Entry` component that owns the canvas.
- `entry/src/main/ets/scenes/MoveAndCollideScene.ets` — the `Scene2D` subclass.

## `MoveAndCollideScene.ets`

```typescript
import {
  BoxCollider,
  Entity,
  MathUtils,
  Rigidbody,
  Scene2D,
  Sprite,
  Vector2,
} from '@oliver404/arkane-ts';

export class MoveAndCollideScene extends Scene2D {
  // The player is spawned in onEnter and dragged each frame in update.
  private player!: Entity;

  // Tunables — kept inline for clarity. In a real game, hoist them to a
  // config object passed into the constructor.
  private readonly playerSize: number = 24;
  private readonly wallSize = { w: 200, h: 12 };
  private readonly worldHalf: number = 100;   // clamp range for the player

  override onEnter(): void {
    // Top-down: zero gravity. Without this the player would fall forever.
    this.gravity = new Vector2(0, 0);

    this.spawnWall();
    this.spawnPlayer();
  }

  override update(): void {
    super.update();

    const input = this.context?.input;
    if (!input || !input.isTouching()) return;

    const touches = input.getTouchesWorld();
    if (touches.length === 0) return;

    // Drag the player 1:1 to the touch position, clamped to the play area.
    this.player.transform.position.x = MathUtils.clamp(
      touches[0].x,
      -this.worldHalf,
      this.worldHalf
    );
    this.player.transform.position.y = MathUtils.clamp(
      touches[0].y,
      -this.worldHalf,
      this.worldHalf
    );
  }

  private spawnWall(): void {
    const wall = new Entity();
    wall.transform.position = new Vector2(0, 60);
    wall.sprite = new Sprite(this.wallSize.w, this.wallSize.h, '#888888');
    const collider = new BoxCollider(wall.transform, this.wallSize.w, this.wallSize.h);
    collider.restitution = 1.0;          // perfect bounce
    wall.setCollider(collider);
    // No rigidbody — static.
    this.addEntity(wall);
  }

  private spawnPlayer(): void {
    this.player = new Entity();
    this.player.transform.position = new Vector2(0, 0);
    this.player.sprite = new Sprite(this.playerSize, this.playerSize, '#00ff00');

    const collider = new BoxCollider(this.player.transform, this.playerSize, this.playerSize);
    collider.restitution = 1.0;
    this.player.setCollider(collider);

    const rb = new Rigidbody(this.player.transform);
    rb.gravityScale = 0;                  // top-down — no fall
    this.player.setRigidbody(rb);

    this.addEntity(this.player);
  }
}
```

## `Index.ets`

```typescript
import { CanvasRenderer2D, Engine, PhysicsSystem, RenderContext } from '@oliver404/arkane-ts';
import { MoveAndCollideScene } from '../scenes/MoveAndCollideScene';

@Entry
@Component
struct Index {
  private engine: Engine = new Engine();
  private settings = new RenderingContextSettings(true);
  private ctx = new CanvasRenderingContext2D(this.settings);
  private renderer = new CanvasRenderer2D('#0e0e1a');
  private physics = new PhysicsSystem();
  private renderContext: RenderContext | null = null;
  private started: boolean = false;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.ctx)
        .width('100%')
        .height('100%')
        .onReady(() => this.startScene())
        .onTouch((event: TouchEvent) => this.feedTouch(event));
    }
    .width('100%')
    .height('100%');
  }

  private startScene(): void {
    if (this.started) return;
    this.started = true;

    // Detect viewport size from the device display.
    let w = 400, h = 400;
    try {
      const info = display.getDefaultDisplaySync();
      if (info.width > 0) w = info.width;
      if (info.height > 0) h = info.height;
    } catch (e) {
      console.warn(`[index] display.getDefaultDisplaySync failed: ${e}`);
    }

    this.renderContext = new RenderContext(this.ctx, w, h);
    this.engine.setRenderer(this.renderer, this.renderContext);
    this.engine.registerSystem(this.physics);
    this.engine.start(new MoveAndCollideScene());
  }

  private feedTouch(event: TouchEvent): void {
    const input = this.engine.getInput();

    // CRITICAL: explicit lift on UP / CANCEL. Without this, isTouching()
    // stays true forever because some ArkUI versions retain the released
    // finger in event.touches.
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      input.updateTouches([]);
      return;
    }

    if (event.type === TouchType.Down || event.type === TouchType.Move) {
      const t = event.touches[0];
      if (t !== undefined) {
        input.updateTouches([{ position: new Vector2(t.x, t.y) } as any]);
      }
    }
  }
}
```

> Note: `updateTouches` accepts `TouchInput[]`. In production code import `TouchInput` from the library and construct `new TouchInput(t.x, t.y)`. The `as any` shorthand above is only for keeping the snippet short.

## Try it

1. Open the project in DevEco Studio.
2. Build and run on a wearable emulator or device.
3. Touch the screen — the green square follows your finger.
4. Drag the square into the gray wall and let go — `PhysicsSystem` bounces it back with restitution = 1.0 (perfect bounce).
5. Reduce `wall.collider.restitution` to `0.4` and feel the difference.

## What this exercises

| Feature | Where |
|---|---|
| `Engine` setup | `startScene()` in `Index.ets`. |
| `CanvasRenderer2D` + `RenderContext` | `setRenderer(...)`. |
| `PhysicsSystem` registration | `registerSystem(this.physics)`. |
| `Scene2D` with `gravity = 0` | `MoveAndCollideScene.onEnter`. |
| `Entity` + `Sprite` | `spawnPlayer`, `spawnWall`. |
| `BoxCollider` with `restitution` | both spawn methods. |
| `Rigidbody` with `gravityScale = 0` | `spawnPlayer`. |
| `InputManager` with `getTouchesWorld()` | `MoveAndCollideScene.update`. |
| ArkUI `onTouch` wiring | `feedTouch` in `Index.ets`. |

## Next

- [02 — Text and sprites](02-text-and-sprites.md) — adds `TextEntity` for a score HUD.
- [04 — Camera and input](04-camera-and-input.md) — adds swipe gestures and a follow camera.
- [Cookbook: top-down game](../cookbook/top-down-game.md) — extends this into a full top-down game with walls and goal detection.
