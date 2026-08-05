---
title: CanvasRenderer2D
version: 0.0.1
section: render
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# CanvasRenderer2D

The default `Renderer2D` implementation. Wraps ArkUI's `CanvasRenderingContext2D` to clear the framebuffer each frame and draw each entity's sprite as a filled rectangle or stretched image.

## Basic usage

```typescript
import { Engine, CanvasRenderer2D, RenderContext } from '@oliver404/arkane-ts';

const engine = new Engine();
const renderer = new CanvasRenderer2D('#0e0e1a'); // background fill
const ctx = new RenderContext(canvasCtx, width, height);

engine.setRenderer(renderer, ctx);
engine.start(scene);
```

## Configuration

### Constructor

```typescript
new CanvasRenderer2D(fillColor?: string)
```

| Parameter | Default | Description |
|---|---|---|
| `fillColor` | `'#1e1e1e'` | Background color used by `begin()` to clear the framebuffer each frame. |

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `fillColor` | `string` | `'#1e1e1e'` | Background fill — read at every `begin()`. You can change it after construction. |

### Methods

| Method | Description |
|---|---|
| `begin(context)` | Sets the internal context and clears to `fillColor` via `context.clear(...)`. |
| `drawSprite(sprite, transform, camera?)` | Computes screen position via `camera.worldToScreen(transform.position)` (or uses `transform.position` directly if no camera). Applies scale, rotation, and `save`/`restore`. Draws the texture if `sprite.image` is set, otherwise fills with `sprite.color`. |
| `end()` | No-op in v0.0.1. Reserved for flush hooks. |

## How drawSprite works

```
1. screenPos = camera ? camera.worldToScreen(transform.position) : transform.position
2. scaledSize = sprite.size * transform.scale       (component-wise)
3. ctx.save()
4. ctx.translate(screenPos.x, screenPos.y)
5. ctx.rotate(transform.rotation)
6. ctx.translate(-screenPos.x, -screenPos.y)
7. if sprite.image: ctx.drawImage(sprite.image.source, ...)
   else:           ctx.fillStyle = sprite.color; ctx.fillRect(...)
8. ctx.restore()
```

Rotation is around the sprite center (`screenPos`). Each sprite's transform is fully isolated by the `save`/`restore` pair — there is no state leakage between entities.

## Advanced usage

### Dynamic background

Change `fillColor` between frames to flash the screen:

```typescript
this.renderer.fillColor = frame % 30 < 15 ? '#000000' : '#202020';
```

### Z-ordering

The engine iterates `Scene2D.getEntities()` in insertion order. Insertion order therefore defines draw order: later entities are drawn on top. There is no built-in z-index — manage it yourself by adding entities in the order you want them stacked.

## Pitfalls & FAQ

- **Rectangles only.** `drawSprite` only knows how to draw rectangles (color) or stretched images. To draw a circle, a polygon, or a sprite sheet (sub-image), override `Entity.render` in a subclass — see [Entity](../scene/entity.md#advanced-usage).
- **No batching.** Each sprite is its own `fillRect` / `drawImage` call. Fine for hundreds of sprites on wearable-class hardware; profile before optimizing.
- **`fillColor` change does not retroactively clear.** The new color takes effect on the next `begin()` call (the next frame). The current frame remains as-is.
- **Image source must be `ImageBitmap` or `PixelMap`.** The renderer casts `sprite.image.source as ImageBitmap`. If you construct a `Texture` with a custom object, ensure `drawImage` understands it.

## See also

- [Renderer2D](renderer2d.md) — the interface.
- [RenderContext](rendercontext.md) — what `begin()` receives.
- [Sprite](sprite.md), [Texture](../assets/texture.md) — what `drawSprite` consumes.
- [Camera2D](camera2d.md) — used inside `drawSprite` when present.
