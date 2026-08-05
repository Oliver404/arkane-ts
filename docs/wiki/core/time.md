---
title: Time
version: 0.0.1
section: core
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Time

Global per-frame timing state. Static class — read `Time.deltaTime` and `Time.time` from anywhere; the `GameLoop` updates them.

## Basic usage

```typescript
import { Time } from '@oliver404/arkane-ts';

override update(): void {
  super.update();
  e.transform.position.x += 60 * Time.deltaTime;   // 60 units per second
}
```

## Configuration

### Static properties

| Name | Type | Description |
|---|---|---|
| `deltaTime` | `number` | Seconds elapsed since the previous frame. Set by `Time.update(currentTime)` each tick. |
| `time` | `number` | Total seconds elapsed since the engine started. Monotonically increasing. |

### Static methods

| Method | Description |
|---|---|
| `update(currentTime)` | Called by `GameLoop` every frame. Updates `deltaTime` and `time`. The first call after a `reset` does not advance `deltaTime` (it only sets the baseline) — so the first *measured* frame has a real, non-zero `deltaTime` instead of a giant initial jump. |
| `reset()` | Resets `deltaTime`, `time`, and the first-frame flag. Called by `GameLoop.start()`. |

## Advanced usage

### Frame-rate-independent motion

```typescript
e.transform.position.add(direction.multiply(speed * Time.deltaTime));
```

### Cooldowns

```typescript
private cooldown: number = 0;

override update(): void {
  super.update();
  this.cooldown = Math.max(0, this.cooldown - Time.deltaTime);
  if (this.cooldown === 0 && this.context?.input.isTouchStarted()) {
    this.fire();
    this.cooldown = 0.5;   // half-second cooldown
  }
}
```

### Smooth interpolation (alpha)

`Time.deltaTime` plus the desired target frame time lets you compute a smoothing factor:

```typescript
const alpha = 1 - Math.pow(0.001, Time.deltaTime / (1 / 60));
this.displayedX = MathUtils.lerp(this.displayedX, this.targetX, alpha);
```

## Pitfalls & FAQ

- **`Time` is global state.** Two engines in the same process clobber each other. Use only one engine per canvas.
- **`deltaTime` is zero on the very first tick.** This is by design — the loop's first `update` call happens before any time has passed, so consumers see `deltaTime = 0`. Move first-frame setup into `onEnter`, not the first `update`.
- **Reset is automatic.** `GameLoop.start()` calls `Time.reset()` for you. If you start a second engine in the same process, its first measured `deltaTime` will be relative to the previous engine's start, which is rarely what you want.

## See also

- [GameLoop](gameloop.md) — the caller of `Time.update`.
- [Engine](engine.md) — owns the loop.
