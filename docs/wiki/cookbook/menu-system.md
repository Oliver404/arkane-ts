---
title: Recipe — Menu system
version: 0.0.1
section: cookbook
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Recipe — Menu system

A complete menu → gameplay → game-over navigation pattern using `engine.setScene(...)` and `EventBus`. Demonstrates how to split a game across multiple `Scene2D` subclasses without leaking state between them.

## What you build

- `MenuScene` — a title and a "Play" button.
- `GameScene` — minimal gameplay (use the [move-and-collide](../examples/01-move-and-collide.md) example).
- `GameOverScene` — "Game Over" + "Restart" button.
- `engine.setScene(...)` to navigate.
- A shared `EventBus` event (`'game.start'`, `'game.over'`, `'game.restart'`) to coordinate.

## Pattern

The engine has a single `EventBus` per `start()` call, but the bus persists across `setScene` calls (because the engine re-injects the same `SceneContext` into the new scene). This is what lets scenes talk to each other.

```typescript
// In the entry component, after engine.start(menuScene):
private showGameOver(): void {
  this.engine.setScene(new GameOverScene(() => this.restart()));
}
private restart(): void {
  this.engine.setScene(new GameScene(() => this.showGameOver()));
}
```

The lambdas (`() => this.showGameOver()`) wire up "what happens when the user picks this option" without coupling scenes directly.

## `MenuScene`

```typescript
import { Scene2D, Sprite, TextEntity, Vector2 } from '@oliver404/arkane-ts';

export class MenuScene extends Scene2D {
  constructor(private onPlay: () => void) { super(); }

  override onEnter(): void {
    // Title
    const title = new TextEntity('ARKANE TS');
    title.setFontSize(28);
    title.setColor('#ffffff');
    title.setTextAlign('center');
    title.setTextBaseline('middle');
    title.transform.position = new Vector2(0, 60);
    this.addEntity(title);

    // Play button background
    const btn = new Entity();
    btn.transform.position = new Vector2(0, -20);
    btn.sprite = new Sprite(120, 36, '#00aa55');
    this.addEntity(btn);

    // Play button label
    const lbl = new TextEntity('PLAY');
    lbl.setFontSize(18);
    lbl.setColor('#ffffff');
    lbl.setTextAlign('center');
    lbl.setTextBaseline('middle');
    lbl.transform.position = btn.transform.position.clone();
    this.addEntity(lbl);

    // Listen for taps.
    this.context!.events.on('menu.tap', (payload) => {
      const p = payload as { x: number; y: number };
      if (p.y < 0 && p.y > -40 && Math.abs(p.x) < 60) {
        this.context!.events.off('menu.tap', this.tapHandler); // prevent double-fire
        this.onPlay();
      }
    });
  }

  override update(): void {
    super.update();
    const input = this.context?.input;
    if (input?.isTouchStarted()) {
      const t = input.getTouchesWorld();
      if (t.length > 0) this.context!.events.emit('menu.tap', { x: t[0].x, y: t[0].y });
    }
  }

  // Keep a field reference for off().
  private tapHandler = (payload: Object): void => {
    this.context!.events.emit('menu.tap', payload);
  };

  override onExit(): void {
    this.context!.events.off('menu.tap', this.tapHandler);
  }
}
```

## `GameOverScene`

```typescript
import { Scene2D, TextEntity, Vector2 } from '@oliver404/arkane-ts';

export class GameOverScene extends Scene2D {
  constructor(private onRestart: () => void) { super(); }

  override onEnter(): void {
    const t = new TextEntity('GAME OVER');
    t.setFontSize(24);
    t.setColor('#ff3030');
    t.setTextAlign('center');
    t.setTextBaseline('middle');
    t.transform.position = new Vector2(0, 30);
    this.addEntity(t);

    const btn = new TextEntity('Tap to restart');
    btn.setFontSize(16);
    btn.setColor('#ffffff');
    btn.setTextAlign('center');
    btn.setTextBaseline('middle');
    btn.transform.position = new Vector2(0, -30);
    this.addEntity(btn);

    this.tapHandler = (): void => this.onRestart();
    this.context!.events.on('menu.tap', this.tapHandler);
  }

  override update(): void {
    super.update();
    if (this.context?.input.isTouchStarted()) {
      this.context!.events.emit('menu.tap', { x: 0, y: 0 });
    }
  }

  private tapHandler!: () => void;

  override onExit(): void {
    this.context!.events.off('menu.tap', this.tapHandler);
  }
}
```

## Wiring in `Index.ets`

```typescript
private showMenu(): void {
  if (this.engine.getScene() === undefined) {
    this.engine.start(new MenuScene(() => this.startGame()));
  } else {
    this.engine.setScene(new MenuScene(() => this.startGame()));
  }
}

private startGame(): void {
  this.engine.setScene(new GameScene(() => this.endGame()));
}

private endGame(): void {
  this.engine.setScene(new GameOverScene(() => this.startGame()));
}
```

## Why this pattern works

- **Scenes are stateless.** They do not hold cross-scene references. The wiring lives in the entry component.
- **Events survive scene transitions.** Because the bus is per-`start()` call, scenes can subscribe once and stay subscribed as long as they want (until they `off` themselves).
- **No coupling between scenes.** `MenuScene` does not know `GameScene` exists — it just calls the constructor lambda.

## Pitfalls

- **Do not re-subscribe on every `onEnter` without `off`-ing in `onExit`.** Otherwise the same handler accumulates across scene transitions.
- **Use `engine.start` once.** The first scene transition must be `engine.setScene(...)`, not `engine.start(...)` — `start` creates a fresh `EventBus` and resets the loop.
- **Constructors should be cheap.** If your scene needs heavy setup (loading assets), do it in `onEnter` (or an async `onEnter`), not in the constructor — otherwise menu → game → menu will re-decode assets every navigation.

## See also

- [Engine](../core/engine.md) — `start` vs `setScene`.
- [EventBus](../events/eventbus.md) — listener cleanup pattern.
- [Scene2D](../scene/scene2d.md) — lifecycle hooks.
