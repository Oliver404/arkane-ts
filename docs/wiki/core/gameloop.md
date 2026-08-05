---
title: GameLoop
version: 0.0.1
section: core
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# GameLoop

The per-frame loop. Calls an update callback (advances physics, scenes, systems) and a render callback (draws the scene) at a target FPS using `setTimeout`. Owned by the `Engine`; you typically never construct one directly.

## Basic usage

You normally do not interact with `GameLoop` directly. The engine wires it inside its constructor. If you are writing a custom engine wrapper:

```typescript
import { GameLoop, Time } from '@oliver404/arkane-ts';

const loop = new GameLoop(
  () => { /* update */ },
  () => { /* render */ },
  60  // target FPS
);

loop.start();
```

## Configuration

### Constructor

```typescript
new GameLoop(update: LoopCallback, render: LoopCallback, targetFPS?: number)
```

| Parameter | Default | Description |
|---|---|---|
| `update` | (required) | Called first each frame. Typically the engine's per-tick logic. |
| `render` | (required) | Called second each frame. |
| `targetFPS` | `60` | Target frames per second. Becomes `frameDuration = 1000 / targetFPS` ms. |

### Methods

| Method | Description |
|---|---|
| `start()` | Resets `Time`, schedules the first frame, and starts the loop. No-op if already running. |
| `stop()` | Cancels the next scheduled tick and marks the loop as stopped. |
| `isRunning(): boolean` | `true` between `start` and `stop`. |

### `LoopCallback`

```typescript
type LoopCallback = () => void
```

A zero-arg function. The loop does not pass `dt` — read it from `Time.deltaTime` inside the callback.

## How the loop ticks

```
loop():
  now = Date.now()
  Time.update(now)            // advance Time.deltaTime and Time.time
  update()                    // scene + systems
  render()                    // scene + renderer
  nextFrameTime += frameDuration
  wait = max(0, nextFrameTime - Date.now())
  setTimeout(loop, wait)
```

`Time.update(now)` is what guarantees `Time.deltaTime` is non-zero even on the first measured frame. The `setTimeout` is unconditional — if the previous frame ran late, the next one starts immediately.

## Pitfalls & FAQ

- **`setTimeout`-based, not vsync.** The loop does not synchronize to the display refresh. On slow frames the next tick starts as soon as the previous one finishes, then waits if it ran too fast. Frame pacing is best-effort.
- **No frame skip cap.** If many frames run late in a row, `nextFrameTime` accumulates and the loop catches up without dropping frames. A long stall (e.g. backgrounded app) does not skip — it just resumes when the OS yields back.
- **Drift-free.** `Time.update` always uses `Date.now()`, not an accumulating counter. No drift between wall clock and engine time.
- **`stop` cancels the next tick, not the current one.** If you call `stop` inside a callback, the current callback finishes normally; the next one is not scheduled.

## See also

- [Time](time.md) — what the loop advances.
- [Engine](engine.md) — the consumer of `GameLoop`.
- [Architecture](../architecture.md#tick-order) — full tick sequence including systems and renderer.
