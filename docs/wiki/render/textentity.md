---
title: TextEntity
version: 0.0.1
section: render
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# TextEntity

An `Entity` subclass that renders a string of text using the canvas's `fillText`. Use it for HUDs, scores, titles, labels — anything where you need readable text on the canvas without building native ArkUI.

## Basic usage

```typescript
import { TextEntity, Vector2 } from '@oliver404/arkane-ts';

const label = new TextEntity('Score: 0');
label.setColor('#ffffff');
label.setFontSize(16);
label.setFontFamily('sans-serif');
label.transform.position = new Vector2(0, 50);
scene.addEntity(label);
```

Update the text at runtime:

```typescript
label.setText(`Score: ${score}`);
```

## Configuration

### Constructor

```typescript
new TextEntity(text: string)
```

### Properties (private — set via methods)

| Name | Type | Default | Description |
|---|---|---|---|
| `text` | `string` | (constructor) | The string drawn each frame. |
| `fontFamily` | `string` | `'Arial'` | CSS-style font family. |
| `fontSize` | `number` | `24` | In pixels. |
| `color` | `string` | `'#ffffff'` | CSS color. |
| `textAlign` | `'start' \| 'end' \| 'left' \| 'right' \| 'center'` | `'start'` | Maps directly to `CanvasRenderingContext2D.textAlign`. |
| `textBaseline` | `'top' \| 'hanging' \| 'middle' \| 'alphabetic' \| 'ideographic' \| 'bottom'` | `'alphabetic'` | Maps directly to `CanvasRenderingContext2D.textBaseline`. |

### Methods

| Method | Description |
|---|---|
| `setText(text)` | Update the string. |
| `setFontFamily(family)` | Update the font. |
| `setFontSize(size)` | Update the size. |
| `setColor(color)` | Update the color. |
| `setTextAlign(align)` | Update the alignment. |
| `setTextBaseline(baseline)` | Update the baseline. |

### Inherited from Entity

- `transform` (position, scale, rotation)
- `id`
- All other `Entity` machinery (collider, rigidbody, etc. — usually you do not use them on a `TextEntity`).

## Advanced usage

### Centered title

A common pattern: a `CenteredTextEntity` subclass that pre-sets `textAlign` and `textBaseline`:

```typescript
class CenteredTextEntity extends TextEntity {
  constructor(text: string) {
    super(text);
    this.setTextAlign('center');
    this.setTextBaseline('middle');
  }
}
```

Then position the text by its center:

```typescript
const title = new CenteredTextEntity('ARKANE TS');
title.transform.position = new Vector2(0, 80);
scene.addEntity(title);
```

### Score with live update

```typescript
class GameScene extends Scene2D {
  private scoreLabel!: TextEntity;
  private score: number = 0;

  override onEnter(): void {
    this.scoreLabel = new TextEntity('Score: 0');
    this.scoreLabel.setFontSize(20);
    this.scoreLabel.setColor('#ffffff');
    this.scoreLabel.transform.position = new Vector2(-100, 100);
    this.addEntity(this.scoreLabel);
  }

  addPoints(n: number): void {
    this.score += n;
    this.scoreLabel.setText(`Score: ${this.score}`);
  }
}
```

## Pitfalls & FAQ

- **`TextEntity` bypasses the renderer abstraction.** Its `render(ctx, _renderer, camera)` writes directly to `context.ctx`. A custom `Renderer2D` cannot intercept text rendering. If you need that, override `Entity.render` in your own subclass.
- **Position is camera-aware.** `transform.position` is converted to screen coordinates via `camera.worldToScreen` if a camera is provided, otherwise used as-is. This means TextEntity participates in camera zoom and follow.
- **No text measurement.** `TextEntity` does not cache its rendered width. If you need to center text manually or detect text-vs-text overlap, measure it yourself (`context.ctx.measureText(...)` is available before you draw).
- **Default font is `'Arial'`.** Wearable devices may not have Arial installed; the engine falls back to the system default, which may differ in size. Test on a real device or set `fontFamily` to something you know is present.
- **No wrapping or multi-line.** Long strings are drawn on a single line and may overflow the viewport. If you need wrapping, split into multiple `TextEntity` instances.
- **`fontSize` is in pixels, not world units.** It is not affected by `transform.scale` or `camera.zoom`. The text stays the same screen size regardless of camera zoom.

## See also

- [Entity](../scene/entity.md) — base class.
- [Camera2D](camera2d.md) — used inside `TextEntity.render`.
- [Sprite](sprite.md) — for solid or textured shapes; `TextEntity` is the text-only sibling.
