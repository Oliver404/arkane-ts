---
title: Getting started
version: 0.0.1
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Getting started

This page walks through a complete first-time setup of Arkane TS: prerequisites, install, bootstrap, and the basic touch-and-collide pattern.

## Prerequisites

- **HarmonyOS NEXT** with the Stage development model.
- **ArkTS** (the typed subset of TypeScript that compiles to ArkUI).
- **Hvigor** as the build system.
- **DevEco Studio** for IDE, signing, and deployment to a device or emulator.
- The library targets the **wearable** device type by default; the engine itself has no UI assumptions.

## Install

In your app's `oh-package.json5`, add:

```json5
{
  "dependencies": {
    "@oliver404/arkane-ts": "file:../library"
  }
}
```

The `file:` form is used while the library is being developed locally. Once a release is published to OHPM, you can replace it with a version range:

```json5
{
  "dependencies": {
    "@oliver404/arkane-ts": "^0.1.0"
  }
}
```

Then run `ohpm install` (or let DevEco Studio sync). The library is a HAR, so its symbols are available at the package root.

## The five-step bootstrap

Every Arkane TS app follows the same wiring sequence:

```typescript
// 1) Create the engine.
const engine = new Engine();

// 2) Wrap your canvas context. Width/height must match the canvas.
const renderContext = new RenderContext(canvasCtx, width, height);

// 3) Pick a renderer. CanvasRenderer2D works with ArkUI's
//    CanvasRenderingContext2D out of the box.
const renderer = new CanvasRenderer2D('#0e0e1a'); // background color

// 4) Wire the renderer. Engine creates the Camera2D for you.
engine.setRenderer(renderer, renderContext);

// 5) Register optional systems (PhysicsSystem is the most common one).
engine.registerSystem(new PhysicsSystem());

// 6) Start the loop with your first scene.
engine.start(new MyScene());
```

`setRenderer` **must** be called before `start`. Calling `start` without a renderer throws because the engine needs the camera for scene context.

## ArkUI entry point

The library has no UI opinions — you bring your own ArkUI component. The most common pattern is a full-screen `Canvas`:

```typescript
import { Engine, RenderContext, CanvasRenderer2D, PhysicsSystem } from '@oliver404/arkane-ts';

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
        .onTouch((e: TouchEvent) => this.feedTouch(e));
    }
    .width('100%').height('100%');
  }

  private startScene(): void {
    if (this.started) return;
    this.started = true;

    const info = display.getDefaultDisplaySync();
    const w = info.width, h = info.height;

    this.renderContext = new RenderContext(this.ctx, w, h);
    this.engine.setRenderer(this.renderer, this.renderContext);
    this.engine.registerSystem(this.physics);
    this.engine.start(new MyScene());
  }

  private feedTouch(event: TouchEvent): void {
    const input = this.engine.getInput();
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      // Must explicitly clear touches on lift — see "Pitfalls" below.
      input.updateTouches([]);
      return;
    }
    if (event.type === TouchType.Down || event.type === TouchType.Move) {
      const t = event.touches[0];
      if (t !== undefined) {
        input.updateTouches([new TouchInput(t.x, t.y)]);
      }
    }
  }
}
```

## First scene

Scenes extend `Scene2D` and live their own lifecycle:

```typescript
import {
  Scene2D, Entity, Sprite, BoxCollider, Rigidbody, Vector2, MathUtils
} from '@oliver404/arkane-ts';

export class MyScene extends Scene2D {
  private player!: Entity;

  override onEnter(): void {
    // Top-down: zero gravity.
    this.gravity = new Vector2(0, 0);

    // A static obstacle.
    const wall = new Entity();
    wall.transform.position = new Vector2(0, 60);
    wall.sprite = new Sprite(200, 10, '#888888');
    wall.setCollider(new BoxCollider(wall.transform, 200, 10));
    this.addEntity(wall);

    // A dynamic player.
    this.player = new Entity();
    this.player.transform.position = new Vector2(0, 0);
    this.player.sprite = new Sprite(20, 20, '#00ff00');
    const collider = new BoxCollider(this.player.transform, 20, 20);
    collider.restitution = 1.0;          // bounces off the wall
    this.player.setCollider(collider);
    const rb = new Rigidbody(this.player.transform);
    rb.gravityScale = 0;                 // top-down, no fall
    this.player.setRigidbody(rb);
    this.addEntity(this.player);
  }

  override update(): void {
    super.update();
    const input = this.context!.input;
    const touches = input.getTouchesWorld();
    if (input.isTouching() && touches.length > 0) {
      this.player.transform.position.x = MathUtils.clamp(touches[0].x, -90, 90);
      this.player.transform.position.y = MathUtils.clamp(touches[0].y, -90, 90);
    }
  }
}
```

## Next steps

- The complete annotated version of this example lives in [examples/01-move-and-collide.md](examples/01-move-and-collide.md).
- For how the engine ticks per frame and how modules interact, read [architecture.md](architecture.md).
- For genre recipes (platformer, top-down, endless runner, menus), browse [cookbook/](cookbook/).
- For the full API surface per class, browse the section index in [README.md](README.md#table-of-contents).

## Pitfalls & FAQ

- **Bootstrap inside `Canvas.onReady`, never `aboutToAppear`.** The canvas dimensions are only known once the canvas is laid out; bootstrapping too early produces a blank screen.
- **Always call `input.updateTouches([])` on `TouchType.Up` and `TouchType.Cancel`.** Some ArkUI versions keep the released finger in `event.touches`; without the explicit lift, `isTouching()` stays true forever and your game logic breaks on the second tap.
- **Call `engine.setRenderer(...)` before `engine.start(...)`.** `start` needs the camera to build the `SceneContext`.
- **The first `deltaTime` is non-zero.** The engine tracks `Time` from the first frame, so even `Scene2D.update` on tick 0 sees a sensible value (no magic constants in your own code).
- **Y axis points UP.** World coordinates use the classical physics convention: gravity is `(0, -9.8)`. See [architecture.md#y-axis-convention](architecture.md#y-axis-convention).
