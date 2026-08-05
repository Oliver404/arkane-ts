---
title: Texture
version: 0.0.1
section: assets
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Texture

Wraps a native ArkUI image (`@ohos.multimedia.image.PixelMap` or an `ImageBitmap`) together with its dimensions and a discriminator (`'pixelmap' | 'bitmap'`). Stored on `Sprite.image` to make a sprite image-backed instead of solid-colored.

## Basic usage

You typically construct a `Texture` via `AssetManager.load(name)` or `AssetManager.loadFromBuffer(...)`. Direct construction is rare:

```typescript
import { Texture } from '@oliver404/arkane-ts';

const tex = new Texture(pixelMap, 64, 64, 'pixelmap');
```

Then assign it to a sprite:

```typescript
sprite.image = tex;
```

## Configuration

### Constructor

```typescript
new Texture(source: Object, width: number, height: number, kind?: TextureKind)
```

| Parameter | Default | Description |
|---|---|---|
| `source` | (required) | The underlying ArkUI image object. The library treats this as opaque. |
| `width` | (required) | Width in pixels. |
| `height` | (required) | Height in pixels. |
| `kind` | `'pixelmap'` | `'pixelmap'` or `'bitmap'`. Used for future fast-paths that branch on the underlying type. |

### Properties (all readonly)

| Name | Type | Description |
|---|---|---|
| `source` | `Object` | The wrapped native image. Consumers should not mutate. |
| `width` | `number` | Width in pixels. |
| `height` | `number` | Height in pixels. |
| `kind` | `TextureKind` | `'pixelmap'` or `'bitmap'`. |

### `TextureKind`

```typescript
type TextureKind = 'pixelmap' | 'bitmap'
```

The Canvas renderer casts `source as ImageBitmap` when calling `ctx.drawImage`. ArkUI accepts both `PixelMap` and `ImageBitmap` in its drawImage overloads, so either kind works at draw time. Use `'pixelmap'` for `PixelMap` and `'bitmap'` for `ImageBitmap`.

## Advanced usage

### Custom renderers and `source`

If you write a custom `Renderer2D`, you can branch on `texture.kind` to call native APIs that are type-specific:

```typescript
drawSprite(sprite: Sprite, transform: Transform, camera?: Camera2D): void {
  const tex = sprite.image;
  if (tex === undefined) { /* fillRect */ return; }

  if (tex.kind === 'pixelmap') {
    // call pixelmap-specific paths
  } else {
    // bitmap-specific paths
  }
}
```

## Pitfalls & FAQ

- **`source` is opaque.** Do not mutate it after constructing the `Texture`.
- **No sub-rect / sprite sheet support.** A `Texture` represents one image. Use multiple `Texture` instances or a custom `Entity` subclass for atlas rendering.
- **Dimensions are not derived from `source`.** You supply them. This avoids an async call but means you must keep them in sync with the underlying image.
- **`source` is typed `Object` for portability.** Casting in your own code is necessary to call native APIs.

## See also

- [AssetManager](assetmanager.md) — the loader and cache.
- [Sprite](../render/sprite.md) — the consumer of `Texture` via `sprite.image`.
- [CanvasRenderer2D](../render/canvasrenderer2d.md) — the default renderer that draws textures.
