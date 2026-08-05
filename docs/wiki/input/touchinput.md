---
title: TouchInput
version: 0.0.1
section: input
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# TouchInput

A minimal data transfer object for a single touch point. Created by the consumer from ArkUI's `TouchEvent.touches` array and passed to `InputManager.updateTouches(...)`.

## Basic usage

```typescript
import { TouchInput } from '@oliver404/arkane-ts';

new TouchInput(120, 80);   // screen-space (x, y)
```

## Configuration

### Constructor

```typescript
new TouchInput(x: number, y: number)
```

### Properties

| Name | Type | Description |
|---|---|---|
| `position` | `Vector2` | The screen-space position. `x` is the horizontal pixel offset from the canvas left edge; `y` is the vertical offset from the top. |

Note that screen coordinates here are **Y-down** (ArkUI's native convention). Conversion to world Y-up happens inside `InputManager` via the camera.

## Pitfalls & FAQ

- **Y-down screen space.** The `position` field uses ArkUI's native canvas convention. If you read it directly (without going through `InputManager.getTouchesWorld()`), remember that `y` increases downward.
- **Only `position` is exposed.** There are no fields for `id`, `force`, or `phase`. If you need them, subclass `TouchInput` and pass the subclass instance to `updateTouches`.

## See also

- [InputManager](inputmanager.md) — the consumer of `TouchInput`.
- [Vector2](../math/vector2.md) — the underlying `position` type.
