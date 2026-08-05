---
title: Sprite
version: 0.0.1
section: render
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Sprite

The visual representation of an `Entity`. Either a solid-colored rectangle, or a stretched texture. Held by reference on `entity.sprite`.

## Basic usage

Solid color rectangle:

```typescript
import { Entity, Sprite, Vector2 } from '@oliver404/arkane-ts';

const e = new Entity();
e.transform.position = new Vector2(0, 0);
e.sprite = new Sprite(64, 64, '#ff0000');   // 64×64 red square
```

Image-backed sprite:

```typescript
import { Texture } from '@oliver404/arkane-ts';

const tex = await context.assets.load('sprites/hero.png');
const e = new Entity();
e.sprite = new Sprite(tex.width, tex.height, '#ffffff'); // color is the fallback
e.sprite.image = tex;                                    // actually drawn texture
```

## Configuration

### Constructor

```typescript
new Sprite(width: number, height: number, color?: string)
```

| Parameter | Default | Description |
|---|---|---|
| `width` | (required) | Sprite width in world units. Multiplied by `transform.scale.x` at render time. |
| `height` | (required) | Sprite height in world units. |
| `color` | `'#ffffff'` | Fill color used when `image` is not set. Ignored when a texture is drawn. |

### Properties

| Name | Type | Description |
|---|---|---|
| `size` | `Vector2` | The (width, height) you passed in. Mutate to resize at any time. |
| `color` | `string` | Fill color. Mutate to recolor (e.g. flash white when hit). |
| `image` | `Texture?` | When set, the renderer draws the texture stretched to `size × transform.scale` instead of a colored rectangle. |

## Advanced usage

### Hit-flash (temporary color change)

```typescript
e.sprite.color = '#ffffff';   // white flash
setTimeout(() => { e.sprite.color = '#ff0000'; }, 100);
```

### Resize at runtime

```typescript
e.sprite.size.set(96, 96);
```

### Stretch a texture to a different aspect ratio

```typescript
const tex = await context.assets.load('hero.png'); // 64×64 source
e.sprite = new Sprite(128, 64, '#ffffff');          // render stretched to 2× width
e.sprite.image = tex;
```

## Pitfalls & FAQ

- **Texture wins over color.** When `sprite.image` is set, `sprite.color` is ignored. Mutating color does nothing in that case.
- **No sprite sheets.** A `Sprite` holds one texture. To animate, swap `entity.sprite` to a new `Sprite` (or to a different `image`), or build a custom `Entity` subclass that draws sub-rects.
- **No pivot offset.** The sprite rotates and scales around its center. There is no `pivot` field; the engine always uses the center.
- **Size is in world units, not pixels.** A `Sprite(64, 64)` is 64 world units wide. The renderer multiplies by `transform.scale` and by `camera.zoom` to get screen pixels.

## See also

- [Texture](../assets/texture.md) — what `sprite.image` wraps.
- [Transform](../scene/transform.md) — `scale` and `rotation` consumed at draw time.
- [Entity](../scene/entity.md) — `entity.sprite` is where the sprite lives.
- [CanvasRenderer2D](canvasrenderer2d.md) — how the sprite is drawn.
