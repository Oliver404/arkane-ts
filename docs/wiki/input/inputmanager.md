---
title: InputManager
version: 0.0.1
section: input
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# InputManager

Aggregates raw touch points into multitouch state, frame-bounded tap events, and gesture recognition (swipe, long-press). Owned by the engine — access it via `engine.getInput()` or `scene.context.input`.

## Basic usage

Wire the manager from your ArkUI `Canvas.onTouch`:

```typescript
private feedTouch(event: TouchEvent): void {
  const input = this.engine.getInput();
  if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
    input.updateTouches([]);              // explicit lift
    return;
  }
  if (event.type === TouchType.Down || event.type === TouchType.Move) {
    const t = event.touches[0];
    if (t !== undefined) {
      input.updateTouches([new TouchInput(t.x, t.y)]);
    }
  }
}
```

Read touches in world coordinates from a scene:

```typescript
override update(): void {
  super.update();
  const input = this.context!.input;
  const touches = input.getTouchesWorld();
  if (input.isTouchStarted() && touches.length > 0) {
    // first frame of a tap at touches[0]
  }
}
```

## Configuration

### Methods

| Method | Description |
|---|---|
| `setCamera(camera)` | Inject the active camera. After this, `getTouchesWorld()` returns converted coordinates; until then it returns `[]`. |
| `setSwipeThresholds(minDistance, maxDurationMs)` | Override the default swipe thresholds (30 units, 300 ms). |
| `setLongPressThresholds(minDurationMs, maxMovement)` | Override the default long-press thresholds (500 ms, 10 units). |
| `updateTouches(rawTouches, currentTime?)` | Update the manager state. Pass the current touch list every frame. `currentTime` defaults to `Date.now()`; pass a deterministic value in tests. |

### Query methods

| Method | Returns |
|---|---|
| `isTouching()` | `true` every frame the finger is down. |
| `isTouchStarted()` | `true` on the single frame a touch begins (frame-bounded). |
| `isTouchEnded()` | `true` on the single frame a touch ends (frame-bounded). |
| `getTouchesWorld()` | `Vector2[]` of the current touches, converted via `camera.screenToWorld`. Empty when no camera is set. |
| `isSwipeTriggered()` | `true` on the frame the swipe criteria are first met (frame-bounded). |
| `getSwipeDirection()` | Unit `Vector2` from origin to release, or `null` if no swipe. |
| `isLongPressTriggered()` | `true` on the frame the long-press criteria are first met (frame-bounded). |
| `getLongPressPosition()` | World position of the long-press origin, or `null` if no long press. |
| `clearFrameFlags()` | Resets all frame-bounded flags. The engine calls this at the end of every tick. |

### Default thresholds

| Gesture | Distance / duration | Movement tolerance |
|---|---|---|
| Swipe | `≥ 30` units in `≤ 300` ms | — |
| Long press | `≥ 500` ms | `≤ 10` units |

Tune these via `setSwipeThresholds` / `setLongPressThresholds`.

## Advanced usage

### Read multitouch (up to N touches)

```typescript
const touches = input.getTouchesWorld();
for (let i = 0; i < touches.length; i++) {
  // touches[i] is the i-th finger, in world space
}
```

The manager passes through whatever the consumer sent via `updateTouches`. If you forward all event touches, multi-finger gestures just work.

### Swipe in any direction

```typescript
override update(): void {
  super.update();
  if (this.context?.input.isSwipeTriggered()) {
    const dir = this.context.input.getSwipeDirection();
    if (dir) {
      // dir.x, dir.y are unit-length in world space
      this.player.rigidbody!.velocity.set(dir.x * 200, dir.y * 200);
    }
  }
}
```

### Inject a clock for tests

```typescript
input.updateTouches([new TouchInput(0, 0)], /* currentTime */ 1000);
input.updateTouches([new TouchInput(60, 0)], /* currentTime */ 1200);
// 200ms later with 60 units traveled — swipe fires
```

## Pitfalls & FAQ

- **Always call `updateTouches([])` on UP / CANCEL.** Some ArkUI versions keep the released finger in `event.touches`. Without the explicit lift, `isTouching()` stays `true` forever and your swipe / long-press state machines get stuck.
- **Frame-bounded flags are cleared by the engine at the end of every tick.** Read them inside `Scene2D.update()` or `GameSystem.beforeUpdate()` — never from a delayed callback.
- **A swipe and a long-press are mutually exclusive.** Once a long press fires, the swipe candidate is invalidated for the same gesture. Once a swipe fires, the long-press candidate is invalidated.
- **Gestures fire only once per gesture.** After firing, they reset on the next `touchOrigin` (i.e. when the next touch begins).
- **`getTouchesWorld()` returns `[]` until a camera is set.** If your consumer code unconditionally reads it, you'll silently get no input.
- **Swipe duration is measured from `touchOrigin` time to the current frame.** A fast flick over a long distance is a swipe; a slow drag with a long hold is a long press; a slow drag over a short distance is neither.

## See also

- [TouchInput](touchinput.md) — the per-frame DTO.
- [Engine](../core/engine.md) — `getInput()` accessor.
- [Camera2D](../render/camera2d.md) — used to convert screen touches to world coordinates.
