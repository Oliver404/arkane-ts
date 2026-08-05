---
title: Example 02 — Text and sprites
version: 0.0.1
section: examples
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Example 02 — Text and sprites

Extends the move-and-collide example with a HUD score label and a few differently-styled sprites. Demonstrates `TextEntity`, color updates on hit, and centered text.

## What you will build

- A static score label in the top-left.
- A counter that increments every frame.
- A small "enemy" sprite that resets color to red on every tap.

## Scene

```typescript
import {
  BoxCollider,
  Entity,
  Scene2D,
  Sprite,
  TextEntity,
  Vector2,
} from '@oliver404/arkane-ts';

class CenteredTextEntity extends TextEntity {
  constructor(text: string) {
    super(text);
    this.setTextAlign('center');
    this.setTextBaseline('middle');
  }
}

export class TextAndSpritesScene extends Scene2D {
  private scoreLabel!: TextEntity;
  private score: number = 0;
  private enemy!: Entity;

  override onEnter(): void {
    this.gravity = new Vector2(0, 0);

    // HUD score label (top-left, in world coordinates).
    this.scoreLabel = new TextEntity('Score: 0');
    this.scoreLabel.setFontSize(18);
    this.scoreLabel.setColor('#ffffff');
    this.scoreLabel.transform.position = new Vector2(-90, 90);
    this.addEntity(this.scoreLabel);

    // Centered title at the top.
    const title = new CenteredTextEntity('ARKANE TS');
    title.setFontSize(24);
    title.setColor('#ffffff');
    title.transform.position = new Vector2(0, 70);
    this.addEntity(title);

    // A "background" rectangle.
    const bg = new Entity();
    bg.transform.position = new Vector2(0, 0);
    bg.sprite = new Sprite(180, 80, '#222233');
    this.addEntity(bg);

    // An enemy sprite that flashes white on every tap.
    this.enemy = new Entity();
    this.enemy.transform.position = new Vector2(0, -40);
    this.enemy.sprite = new Sprite(40, 40, '#ff3030');
    this.enemy.setCollider(new BoxCollider(this.enemy.transform, 40, 40));
    this.addEntity(this.enemy);
  }

  override update(): void {
    super.update();

    // Bump the score every second.
    this.score += 1;                  // 1 point per frame at 60 FPS = ~60 / sec; tune as desired
    this.scoreLabel.setText(`Score: ${Math.floor(this.score / 60)}`);

    // Flash the enemy on tap.
    const input = this.context?.input;
    if (input?.isTouchStarted()) {
      this.enemy.sprite!.color = '#ffffff';
      setTimeout(() => {
        if (this.enemy.sprite) this.enemy.sprite.color = '#ff3030';
      }, 100);
    }
  }
}
```

## Try it

1. Tap the screen — the enemy flashes white for 100 ms.
2. The score counter ticks up every frame; divide by 60 to make it count seconds.

## What this exercises

| Feature | Where |
|---|---|
| `TextEntity` with `setFontSize`, `setColor` | `scoreLabel`. |
| `TextEntity` subclass with `setTextAlign` / `setTextBaseline` | `CenteredTextEntity`. |
| Live text updates with `setText` | `this.scoreLabel.setText(...)`. |
| Color updates on `Sprite` | enemy flash. |
| Multiple entity types in one scene | HUD + background + enemy. |

## Pitfalls

- **`TextEntity` bypasses the renderer abstraction.** If you plug in a custom `Renderer2D`, text will still be drawn directly to the canvas. Plan for that if you want a unified draw pipeline.
- **Score is per-frame, not per-second.** Divide by your target FPS (`60`) or by `Time.time` to convert.
- **Flash via `setTimeout` does not pause with the scene.** If the scene swaps mid-flash, the timer fires after the scene is gone. For most cases this is harmless; for stateful flashes use scene-tracked timers.

## Next

- [03 — Physics system](03-physics-system.md) — adds gravity, restitution, and multiple bodies.
- [Cookbook: menu system](../cookbook/menu-system.md) — uses `TextEntity` for menu titles.
