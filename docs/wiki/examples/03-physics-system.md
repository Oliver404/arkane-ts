---
title: Example 03 — Physics system
version: 0.0.1
section: examples
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Example 03 — Physics system

Shows `PhysicsSystem` in action: gravity, drag, restitution, multiple bodies, and the difference between static (`mass = 0`) and dynamic (`mass > 0`) rigidbodies.

## What you will build

- A floor that catches falling boxes.
- Several boxes that fall under gravity.
- One bouncy ball that ricochets off everything.
- A drag-controlled player that nudges the boxes on contact.

## Scene

```typescript
import {
  BoxCollider,
  CircleCollider,
  Entity,
  PhysicsSystem,
  Rigidbody,
  Scene2D,
  Sprite,
  Vector2,
} from '@oliver404/arkane-ts';

// BoxCollider + Rigidbody + Sprite — a dynamic falling box.
class FallingBox extends Entity {
  constructor(x: number, size: number, color: string) {
    super();
    this.transform.position = new Vector2(x, 80);
    this.sprite = new Sprite(size, size, color);
    this.setCollider(new BoxCollider(this.transform, size, size));
    const rb = new Rigidbody(this.transform);
    rb.gravityScale = 1;
    rb.drag = 0.1;       // light damping
    this.setRigidbody(rb);
  }
}

// CircleCollider + Rigidbody + custom render — a bouncy ball.
class BouncyBall extends Entity {
  radius: number = 10;

  constructor(x: number, y: number) {
    super();
    this.transform.position = new Vector2(x, y);
    this.setCollider(new CircleCollider(this.transform, this.radius));
    const rb = new Rigidbody(this.transform);
    rb.gravityScale = 1;
    rb.restitution = 0.95;
    rb.mass = 0.5;
    this.setRigidbody(rb);
  }

  override render(context: RenderContext, _renderer: Renderer2D, camera?: Camera2D): void {
    if (!camera) return;
    const p = camera.worldToScreen(this.transform.position);
    const r = this.radius * camera.zoom;
    context.ctx.save();
    context.ctx.fillStyle = '#ffaa00';
    context.ctx.beginPath();
    context.ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
    context.ctx.fill();
    context.ctx.restore();
  }
}

export class PhysicsScene extends Scene2D {
  override onEnter(): void {
    // Standard downward gravity (world Y points UP).
    this.gravity = new Vector2(0, -9.8);

    // Floor — wide static collider at the bottom.
    const floor = new Entity();
    floor.transform.position = new Vector2(0, -100);
    floor.sprite = new Sprite(300, 20, '#444');
    const fc = new BoxCollider(floor.transform, 300, 20);
    fc.restitution = 0.6;
    floor.setCollider(fc);
    this.addEntity(floor);

    // Stack of falling boxes.
    for (let i = 0; i < 5; i++) {
      this.addEntity(new FallingBox(-40 + i * 20, 16, '#8888ff'));
    }

    // A bouncy ball.
    this.addEntity(new BouncyBall(50, 50));
  }
}
```

The bootstrap is identical to [01 — Move and collide](01-move-and-collide.md) — just instantiate `PhysicsScene` instead.

## Try it

1. Run the scene. Boxes fall, hit the floor, and stack.
2. Watch the ball bounce off the floor and boxes with restitution = 0.95 (almost no energy loss).
3. Set `rb.drag = 2.0` on a box and notice how it now slows down quickly.
4. Add `rb.mass = 0` to a box — it becomes static and unaffected by gravity.

## Tuning reference

| Effect | What to change |
|---|---|
| Bouncier collisions | Increase `collider.restitution` on both bodies. |
| Heavier boxes fall faster | Increase `mass`. Note: gravity is independent of mass in this engine (no `g = Gm1m2/r²` simulation — just acceleration). |
| Sticky collisions | Set `restitution = 0`. |
| Slow a body over time | Increase `rigidbody.drag`. |
| Disable gravity on a body | `rigidbody.gravityScale = 0`. |
| Reverse gravity on a body | `rigidbody.gravityScale = -1`. |
| Inverted world gravity | `scene.gravity = new Vector2(0, +9.8)`. |

## Pitfalls

- **Mass does not affect gravity.** With `gravityScale = 1`, every dynamic body gains `gravity * dt` of velocity per tick regardless of mass. To simulate heavy vs light, apply impulses manually or override `PhysicsSystem.step`.
- **Tangential friction is not yet applied.** Bodies slide along each other without losing energy to friction, even when `friction` is non-zero.
- **Stacking bodies sink into each other slightly.** The Baumgarte correction fixes most overlap, but a tall stack may still drift over time. Tune `PhysicsSystem.baumgarte` to taste.
- **No CCD.** A fast-moving ball can tunnel through a thin floor in a single tick.

## Next

- [04 — Camera and input](04-camera-and-input.md) — adds `Camera2D.follow` and gesture recognition.
- [Cookbook: platformer](../cookbook/platformer.md) — uses gravity and collision for jump physics.
