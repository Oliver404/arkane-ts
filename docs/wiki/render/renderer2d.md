---
title: Renderer2D
version: 0.0.1
section: render
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Renderer2D

The interface every render backend implements. The library ships `CanvasRenderer2D` as the default; you can plug in your own (e.g. WebGL, a custom 2D engine, or a debug renderer that draws colliders).

## Basic usage

```typescript
import { Renderer2D, RenderContext, Sprite, Transform, Camera2D } from '@oliver404/arkane-ts';

class OutlineRenderer implements Renderer2D {
  begin(context: RenderContext): void {
    context.clear('#101010');
  }

  drawSprite(sprite: Sprite, transform: Transform, camera?: Camera2D): void {
    // custom draw logic
  }

  end(): void {
    // flush, swap buffers, etc.
  }
}

const engine = new Engine();
engine.setRenderer(new OutlineRenderer(), renderContext);
engine.start(scene);
```

## Interface

```typescript
interface Renderer2D {
  begin(context: RenderContext): void
  drawSprite(sprite: Sprite, transform: Transform, camera?: Camera2D): void
  end(): void
}
```

### Methods

| Method | When the engine calls it | Responsibility |
|---|---|---|
| `begin(context)` | Once per render frame, before drawing. | Set up the framebuffer — clear, push state, bind targets. |
| `drawSprite(sprite, transform, camera?)` | Once per entity that has a `sprite`. | Draw one sprite. The engine does not call this for `TextEntity` (text bypasses the abstraction). |
| `end()` | Once per render frame, after drawing. | Tear down — flush, swap, pop state. |

## Advanced usage

### Custom renderers and TextEntity

`TextEntity.render` draws directly to `context.ctx` and ignores the `Renderer2D` argument. A custom renderer **cannot** intercept text rendering. If you need a custom text pipeline, fork the class or override `Entity.render` in a subclass.

### Debug renderer

A common pattern is a renderer that draws collision shapes on top of the regular renderer:

```typescript
class DebugRenderer implements Renderer2D {
  constructor(private inner: Renderer2D) {}

  begin(ctx: RenderContext): void {
    this.inner.begin(ctx);
  }

  drawSprite(sprite: Sprite, transform: Transform, camera?: Camera2D): void {
    this.inner.drawSprite(sprite, transform, camera);
    // optionally outline the sprite here using ctx
  }

  end(): void {
    this.inner.end();
  }
}
```

Wrap the default once you have a debug mode toggle.

## Pitfalls & FAQ

- **`drawSprite` is called for every entity with a sprite, every frame.** If your renderer is slow, you have no built-in batching — add it yourself.
- **`camera` may be undefined.** When no camera is wired (e.g. before `engine.setRenderer(...)` is called), `camera` is `undefined`. Default to using `transform.position` as the screen position when that happens.
- **Sprite rotation is applied by the renderer.** The transform's `rotation` is in radians, and the renderer is responsible for rotating the canvas around the sprite center. Your custom renderer must do the same `save / translate / rotate / translate / restore` dance if you want consistent rotation behavior.

## See also

- [CanvasRenderer2D](canvasrenderer2d.md) — the default ArkUI implementation.
- [Sprite](sprite.md) — what `drawSprite` receives.
- [Camera2D](camera2d.md) — what converts world coordinates to screen.
