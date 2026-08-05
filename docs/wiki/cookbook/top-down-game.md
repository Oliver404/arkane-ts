---
title: Recipe — Top-down game
version: 0.0.1
section: cookbook
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Recipe — Top-down game

A complete top-down game skeleton: the player drags to move, walls block movement, enemies spawn and patrol, and the player loses when an enemy touches them. Demonstrates the standard pattern of `gravity = 0`, drag-controlled player, AI patrol, and `EventBus`-driven game state.

## What you build

- A 200×200 play area bounded by walls.
- A drag-controlled player (BoxCollider + Rigidbody, gravity disabled).
- 3 patrolling enemies (sin-wave AI).
- Walls as static colliders.
- A "you died" event on contact.

## Scene

```typescript
import {
  BoxCollider,
  Entity,
  EventBus,
  MathUtils,
  Rigidbody,
  Scene2D,
  Sprite,
  TextEntity,
  Vector2,
} from '@oliver404/arkane-ts';

const HALF = 100;

class TopDownGameScene extends Scene2D {
  private player!: Entity;
  private enemies: Entity[] = [];

  override onEnter(): void {
    this.gravity = new Vector2(0, 0);
    this.buildWalls();
    this.buildPlayer();
    this.buildEnemies(3);

    // Game-over event listener.
    this.context!.events.on('player.died', () => {
      this.context!.events.emit('game.over');
    });
  }

  override update(): void {
    super.update();

    // Player drag.
    const input = this.context?.input;
    if (input?.isTouching()) {
      const t = input.getTouchesWorld();
      if (t.length > 0) {
        const target = new Vector2(
          MathUtils.clamp(t[0].x, -HALF + 8, HALF - 8),
          MathUtils.clamp(t[0].y, -HALF + 8, HALF - 8)
        );
        // Direct position assignment — feels 1:1 on a wearable screen.
        this.player.transform.position.set(target.x, target.y);
      }
    }

    // Enemy patrol — simple sin wave around the center.
    for (let i = 0; i < this.enemies.length; i++) {
      const e = this.enemies[i];
      const phase = i * (Math.PI * 2 / this.enemies.length);
      e.transform.position.x = Math.cos(Time.time + phase) * (HALF - 30);
      e.transform.position.y = Math.sin(Time.time + phase) * (HALF - 30);
    }

    // Enemy-player collision.
    for (const e of this.enemies) {
      const dx = e.transform.position.x - this.player.transform.position.x;
      const dy = e.transform.position.y - this.player.transform.position.y;
      if (Math.hypot(dx, dy) < 20) {
        this.context!.events.emit('player.died');
        return;
      }
    }
  }

  // ===== helpers =====

  private buildWalls(): void {
    const w = HALF * 2;
    const t = 6; // thickness
    const sides = [
      { pos: new Vector2(0,  HALF), size: [w, t] },
      { pos: new Vector2(0, -HALF), size: [w, t] },
      { pos: new Vector2( HALF, 0), size: [t, w] },
      { pos: new Vector2(-HALF, 0), size: [t, w] },
    ];
    for (const s of sides) {
      const e = new Entity();
      e.transform.position = s.pos;
      e.sprite = new Sprite(s.size[0], s.size[1], '#888');
      e.setCollider(new BoxCollider(e.transform, s.size[0], s.size[1]));
      this.addEntity(e);
    }
  }

  private buildPlayer(): void {
    this.player = new Entity();
    this.player.transform.position = new Vector2(0, 0);
    this.player.sprite = new Sprite(16, 16, '#00ff00');
    const c = new BoxCollider(this.player.transform, 16, 16);
    c.restitution = 0.4;
    this.player.setCollider(c);
    this.player.setRigidbody(new Rigidbody(this.player.transform));
    this.addEntity(this.player);
  }

  private buildEnemies(n: number): void {
    for (let i = 0; i < n; i++) {
      const e = new Entity();
      e.sprite = new Sprite(12, 12, '#ff3030');
      e.setCollider(new BoxCollider(e.transform, 12, 12));
      this.addEntity(e);
      this.enemies.push(e);
    }
  }
}
```

The bootstrap is the standard one (see [Example 01](../examples/01-move-and-collide.md)).

## Variations

- **Make enemies bounce off walls**: assign a `Rigidbody` with `gravityScale = 0` and a velocity, plus static wall colliders. `PhysicsSystem` will handle the bouncing for you.
- **Add a score**: emit `'score.changed'` from a tap-detection pass; subscribe in a HUD `TextEntity`'s owning scene.
- **Replace sin-wave with an `AiController`**: see `example/src/main/ets/AiController.ets` in the example app for a difficulty-tuned chase AI.

## See also

- [Example 01 — Move and collide](../examples/01-move-and-collide.md) — base bootstrap and patterns.
- [Scene2D](../scene/scene2d.md) — the lifecycle hooks.
- [EventBus](../events/eventbus.md) — for game-over events.
