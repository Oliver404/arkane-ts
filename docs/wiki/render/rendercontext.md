---
title: RenderContext
version: 0.0.1
section: render
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# RenderContext

A small wrapper around `CanvasRenderingContext2D` plus the framebuffer dimensions. Constructed by the consumer and passed to `engine.setRenderer(...)`. The engine does not own the context — your ArkUI component does.

## Basic usage

```typescript
import { CanvasRenderingContext2D, RenderingContextSettings } from '@kit.ArkUI';
import { Engine, CanvasRenderer2D, RenderContext } from '@oliver404/arkane-ts';

const settings = new RenderingContextSettings(true);
const ctx = new CanvasRenderingContext2D(settings);
const renderContext = new RenderContext(ctx, 466, 466);

const engine = new Engine();
engine.setRenderer(new CanvasRenderer2D(), renderContext);
engine.start(scene);
```

The `width` and `height` you pass should match the actual canvas size. Mismatches produce off-center or stretched output.

## Configuration

### Constructor

```typescript
new RenderContext(ctx: CanvasRenderingContext2D, width: number, height: number)
```

| Parameter | Description |
|---|---|
| `ctx` | The ArkUI canvas rendering context (from `Canvas.getContext()` or constructed manually). |
| `width` | Framebuffer width in pixels. |
| `height` | Framebuffer height in pixels. |

### Properties

| Name | Type | Description |
|---|---|---|
| `ctx` | `CanvasRenderingContext2D` | The wrapped context. |
| `width` | `number` | Framebuffer width. |
| `height` | `number` | Framebuffer height. |

### Methods

| Method | Description |
|---|---|
| `clear(color = '#000000')` | Fills the entire framebuffer with `color` by issuing a `fillRect(0, 0, width, height)`. Used by `CanvasRenderer2D.begin()` each frame. |

## Advanced usage

### Detecting the viewport size

If you want the context to match the actual canvas, query the display:

```typescript
const info = display.getDefaultDisplaySync();
const renderContext = new RenderContext(ctx, info.width, info.height);
```

Wrap this in a `try / catch` — `display.getDefaultDisplaySync()` may throw in some test or preview environments.

### Reading pixel data

The wrapped `ctx` is publicly accessible, so anything you can do with `CanvasRenderingContext2D` is reachable:

```typescript
const imageData = renderContext.ctx.getImageData(0, 0, renderContext.width, renderContext.height);
```

Be aware this is a synchronous call that allocates. Read once, save the result.

## Pitfalls & FAQ

- **You own the canvas.** When the ArkUI component unmounts, the context becomes invalid. Call `engine.stop()` to halt the `GameLoop`'s `setTimeout` chain.
- **`width` and `height` are not auto-updated.** If the canvas resizes (rotation, foldable hinge), rebuild the `RenderContext` and call `engine.setRenderer(...)` again with the new dimensions — that recreates the camera at the new viewport.
- **`clear` is the only helper.** There is no `present`, no `flush` — ArkUI presents the canvas automatically each frame after `onReady`'s render callback completes.

## See also

- [Renderer2D](renderer2d.md) — receives the `RenderContext` in `begin()`.
- [CanvasRenderer2D](canvasrenderer2d.md) — default backend that uses `clear()` each frame.
- [Getting started](../getting-started.md) — full bootstrap pattern.
