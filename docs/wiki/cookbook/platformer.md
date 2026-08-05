---
title: Recipe — Platformer
version: 0.0.1
section: cookbook
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Recipe — Platformer

A small side-scrolling platformer: gravity pulls the player down, the player jumps on tap, and static platforms catch them. Demonstrates the standard "vertical gravity + jump impulse + grounded check" pattern.

## What you build

- A floor and a couple of floating platforms.
- A player that falls under gravity and can jump on tap.
- A `isGrounded` check using `Manifold.compute` (or a simple downward raycast alternative).

## Scene

```typescript
import {
  BoxCollider,
  Entity,
  Manifold,
  MathUtils,
  Rigidbody,
  Scene2D,
  Sprite,
  Vector2,
} from '@oliver404/arkane-ts';

class PlatformerScene extends Scene2D {
  private player!: Entity;
  private platforms: Entity[] = [];
  private isGrounded: boolean = false;

  override onEnter(): void {
    // Gravity points DOWN (negative Y is down in world space).
    this.gravity = new Vector2(0, -20);

    // Ground
    this.addPlatform(new Vector2(0, -100), 400, 16, '#555');

    // Floating platforms
    this.addPlatform(new Vector2(-60, -40), 80, 12, '#888');
    this.addPlatform(new Vector2(60, 10), 80, 12, '#888');
    this.addPlatform(new Vector2(0, 50), 80, 12, '#888');

    // Player
    this.player = new Entity();
    this.player.transform.position = new Vector2(0, 80);
    this.player.sprite = new Sprite(16, 24, '#00ff00');
    const c = new BoxCollider(this.player.transform, 16, 24);
    c.restitution = 0;
    this.player.setCollider(c);
    const rb = new Rigidbody(this.player.transform);
    rb.gravityScale = 1;
    rb.drag = 0;
    this.player.setRigidbody(rb);
    this.addEntity(this.player);
  }

  override update(): void {
    super.update();

    // Ground check: ask Manifold if the player is touching anything below.
    this.isGrounded = false;
    const pc = this.player.collider!;
    for (const p of this.platforms) {
      const m = Manifold.compute(pc, p.collider!);
      if (m && m.normal.y > 0.5) {
        this.isGrounded = true;
        break;
      }
    }

    // Jump on tap.
    const input = this.context?.input;
    if (input?.isTouchStarted() && this.isGrounded) {
      this.player.rigidbody!.velocity.y = 8;   // initial jump velocity
    }

    // Sideways motion: not touch-driven in this snippet; add swipe or
    // virtual buttons as needed.
  }

  private addPlatform(pos: Vector2, w: number, h: number, color: string): void {
    const e = new Entity();
    e.transform.position = pos;
    e.sprite = new Sprite(w, h, color);
    e.setCollider(new BoxCollider(e.transform, w, h));
    this.platforms.push(e);
    this.addEntity(e);
  }
}
```

## Tuning jump height

With `gravity = (0, -20)` and an initial jump velocity `v = 8`:

- Time to apex: `v / |g| = 8 / 20 = 0.4 s`.
- Apex height: `0.5 * v² / |g| = 0.5 * 64 / 20 = 1.6` world units.

For a jump of 5 world units (matching a typical wearable screen), use `v = sqrt(2 * 20 * 5) ≈ 14.1`.

## Pitfalls

- **No continuous collision detection.** A jump velocity high enough to skip the platform's thickness in one frame will tunnel through. Tune gravity / jump speed to keep dt × velocity smaller than the platform's smallest dimension.
- **`isGrounded` is approximate.** It only fires if `Manifold.compute` finds the player overlapping a platform with the contact normal pointing up (`normal.y > 0.5`). Sliding down a wall gives `normal.y ≈ 0`, so the player is not "grounded" — which is correct.
- **No double-jump protection other than `isGrounded`.** If you want mid-air jumps, gate them on a separate counter (`jumpsRemaining`).
- **Y axis convention.** World Y points UP, so `gravity.y = -20` is downward. `velocity.y = 8` is upward. Don't confuse with screen Y.

## Variations

- **Double jump**: keep a `jumpsRemaining` counter, decrement on each `isTouchStarted` while airborne, reset when `isGrounded` becomes true.
- **Coyote time**: store the last time `isGrounded` was true; allow a small grace window (e.g. 100 ms) after leaving a ledge.
- **Wall jump**: detect a wall contact (normal pointing sideways) and launch sideways on tap.

## See also

- [PhysicsSystem](../physics/physicssystem.md) — what integrates gravity each tick.
- [Manifold](../physics/manifold.md) — what `Manifold.compute` returns.
- [Example 03 — Physics system](../examples/03-physics-system.md) — base physics patterns.
