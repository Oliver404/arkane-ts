---
title: Rect
version: 0.0.1
section: math
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Rect

An axis-aligned bounding box (AABB) with point-containment and AABB-intersection tests. Useful for UI hit-testing (e.g. tap targets) and spatial queries that do not need circle logic.

## Basic usage

```typescript
import { Rect, Vector2 } from '@oliver404/arkane-ts';

const button = new Rect(10, 10, 100, 30);   // x, y, width, height
button.contains(new Vector2(50, 25));      // true
button.contains(new Vector2(200, 25));     // false (out of range)
button.intersects(new Rect(80, 20, 50, 50)); // true (overlap)
```

## Configuration

### Properties

| Name | Type | Description |
|---|---|---|
| `x` | `number` | Left edge in world coordinates. |
| `y` | `number` | Top edge in world coordinates. |
| `width` | `number` | Width. |
| `height` | `number` | Height. |

### Read-only accessors

| Getter | Returns | Notes |
|---|---|---|
| `left` | `x` | |
| `right` | `x + width` | Exclusive. |
| `top` | `y` | World Y points UP — top has the smaller Y. |
| `bottom` | `y + height` | Exclusive. |

### Methods

| Method | Description |
|---|---|
| `contains(point: Vector2)` | Returns `true` if `point.x ∈ [left, right)` **and** `point.y ∈ [top, bottom)`. Half-open interval — the right and bottom edges are excluded. |
| `intersects(other: Rect)` | Standard AABB overlap test. Touching edges (without overlap) returns `false`. |

## Advanced usage

UI button hit-testing in world coordinates:

```typescript
const playButton = new Rect(-40, 20, 80, 24);

update(): void {
  super.update();
  const input = this.context!.input;
  const touches = input.getTouchesWorld();
  if (input.isTouchStarted() && touches.length > 0) {
    if (playButton.contains(touches[0])) {
      this.onPlayPressed();
    }
  }
}
```

## Pitfalls & FAQ

- **Half-open intervals.** `contains` excludes the right and bottom edges. A point exactly at `(x + width, y + height)` is not inside. This matches the convention most layout systems use, but it surprises people expecting inclusive bounds.
- **`top` / `bottom` follow world Y-up.** `top` is the smaller Y value; `bottom` is the larger. This is opposite to ArkUI's screen-space convention. If you are doing screen-space hit-tests (without a camera), remember that `y + height` is downward.
- **`intersects` requires strict overlap.** Touching edges return `false`. If you need inclusive intersection, expand one rect by epsilon before testing.

## See also

- [Vector2](vector2.md) — used for the point argument in `contains`.
- [BoxCollider](../physics/boxcollider.md) — uses the same AABB semantics for collision detection.
