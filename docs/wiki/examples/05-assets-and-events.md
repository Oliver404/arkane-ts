---
title: Example 05 — Assets and events
version: 0.0.1
section: examples
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Example 05 — Assets and events

Wires `AssetManager` with a real `TextureDecoder` (using `@ohos.multimedia.image`), then uses `EventBus` to send a "score.added" event from a gameplay scene to a HUD label.

## What you will build

- An `AssetManager` constructed with the host's `ResourceManager` and a `TextureDecoder`.
- Two scenes: a gameplay scene that emits events, and a HUD scene that listens to them. For brevity, this example puts both in the same scene.

## Wiring `AssetManager`

In your `Index.ets` (or any module-level code):

```typescript
import { AssetManager, Texture } from '@oliver404/arkane-ts';
import image from '@ohos.multimedia.image';

const textureDecoder = async (_name: string, buf: Uint8Array): Promise<Texture> => {
  const src = image.createImageSource(buf.buffer as ArrayBuffer);
  const pm = await src.createPixelMap();
  const info = await pm.getImageInfo();
  return new Texture(pm, info.size.width, info.size.height, 'pixelmap');
};

const assetManager = new AssetManager(
  getContext().resourceManager,
  textureDecoder
);

engine.setAssetManager(assetManager);
```

Place `hero.png`, `enemy.png`, etc. under `entry/src/main/resources/rawfile/`.

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

export class GameScene extends Scene2D {
  private scoreLabel!: TextEntity;
  private hero!: Entity;
  private score: number = 0;

  override async onEnter(): Promise<void> {
    this.gravity = new Vector2(0, 0);

    // HUD
    this.scoreLabel = new TextEntity('Score: 0');
    this.scoreLabel.setFontSize(18);
    this.scoreLabel.setColor('#ffffff');
    this.scoreLabel.transform.position = new Vector2(-90, 90);
    this.addEntity(this.scoreLabel);

    // Subscribe to 'enemy.killed'. The handler updates the score.
    this.context!.events.on('enemy.killed', (payload) => {
      const { value } = payload as { value: number };
      this.score += value;
      this.scoreLabel.setText(`Score: ${this.score}`);
      this.context!.events.emit('score.changed', { total: this.score });
    });

    // Hero sprite — loaded from rawfile.
    const heroTex = await this.context!.assets.load('hero.png');
    this.hero = new Entity();
    this.hero.transform.position = new Vector2(0, 0);
    this.hero.sprite = new Sprite(heroTex.width, heroTex.height, '#ffffff');
    this.hero.sprite.image = heroTex;
    this.addEntity(this.hero);
  }

  override update(): void {
    super.update();

    // Tap the hero to "kill" it.
    const input = this.context?.input;
    if (!input?.isTouchStarted()) return;

    const touches = input.getTouchesWorld();
    if (touches.length === 0) return;

    if (this.hero.collider) {
      const t = touches[0];
      const dx = t.x - this.hero.transform.position.x;
      const dy = t.y - this.hero.transform.position.y;
      const halfW = (this.hero.collider as BoxCollider).size.x / 2;
      const halfH = (this.hero.collider as BoxCollider).size.y / 2;
      if (Math.abs(dx) < halfW && Math.abs(dy) < halfH) {
        this.context!.events.emit('enemy.killed', { value: 10 });
      }
    }
  }
}
```

## Try it

1. Tap the hero sprite — the score label updates and `score.changed` is also emitted (you can subscribe to it elsewhere).
2. Replace `hero.png` with a larger or smaller image — the sprite auto-sizes to the texture's natural dimensions.
3. Add a second listener for `'score.changed'` from a different scene or system to see fan-out work.

## Patterns illustrated

| Pattern | Where |
|---|---|
| `TextureDecoder` wrapping `@ohos.multimedia.image` | Bootstrap. |
| `AssetManager.setAssetManager` before `start` | Bootstrap. |
| Async `assets.load(name)` inside `onEnter` | `onEnter`. |
| Decoupled producer / consumer via `EventBus` | `'enemy.killed'` from update, subscribed in `onEnter`. |
| `Sprite.image` makes the renderer draw the texture | `this.hero.sprite.image = heroTex`. |

## Pitfalls

- **`AssetManager.load` throws without a resource manager + decoder.** Construct one explicitly if you only want to use `loadFromBuffer`.
- **`onEnter` returning a Promise is allowed but requires the override to be `async`.** The engine does not await it; the scene is "active" before the await completes. Don't rely on `onEnter` finishing before the first `update` tick.
- **EventBus listeners persist until `off` is called.** If the same scene re-enters, you can double-register. Use a `private handler = (p) => { ... }` field and `off` in `onExit`.
- **`Texture.source` is `Object`.** The renderer casts to `ImageBitmap`. If you build a custom renderer, you may need to handle both `PixelMap` and `ImageBitmap` explicitly.

## Next

- [Cookbook: menu system](../cookbook/menu-system.md) — uses `EventBus` to navigate between menu, gameplay, and game-over scenes.
- [Cookbook: top-down game](../cookbook/top-down-game.md) — uses `AssetManager` to load enemy sprites.
