# Version history

This file tracks the public release history of `@oliver404/arkane-ts`. The version declared in `library/oh-package.json5` is the source of truth at any given moment.

---

## 0.0.1 — 2026-08-04

Initial documented release. Baseline for the public API. Every symbol listed in this section is stable and will not break in patch releases (`0.0.x`).

### Core
- `Engine` — orchestrator that owns the GameLoop, SceneManager, Input, AssetManager, EventBus, and Camera2D.
- `GameLoop` — fixed-timestep loop at 60 FPS using `setTimeout`. `start` / `stop` / `isRunning`.
- `Time` — static tick state: `deltaTime` (seconds), `time` (seconds since start).
- `SceneManager` — holds at most one `Scene2D`; calls `onExit` / `onEnter` on transitions.

### Scene
- `Scene2D` — abstract scene with `gravity`, entity list, optional camera and context.
- `Entity` — base node with `Transform`, optional `Sprite`, `Collider`, `Rigidbody`.
- `Transform` — `position`, `scale` (Vector2), `rotation` (radians).
- `SceneContext` — injected by Engine: `input`, `camera`, `events`, `assets`.

### Render
- `Renderer2D` — pluggable interface (`begin` / `drawSprite` / `end`).
- `CanvasRenderer2D` — default renderer for `CanvasRenderingContext2D` (ArkUI).
- `Camera2D` — world↔screen conversion, `zoom`, `follow`, `lookAt`, `setWorldBounds`.
- `Sprite` — `size`, `color`, optional `image: Texture`.
- `TextEntity` — text rendering with font, size, color, alignment. Extends `Entity`.
- `RenderContext` — wraps `CanvasRenderingContext2D` plus viewport `width` and `height`.

### Math
- `Vector2`, `Vector3` — mutable structs with chained operations (`add`, `subtract`, `multiply`, `divide`, `length`, `normalize`, `distance`).
- `Rect` — AABB with `contains` and `intersects`.
- `MathUtils` — `clamp`, `lerp`.

### Input
- `InputManager` — multitouch with frame-bounded `isTouchStarted` / `isTouchEnded`; swipe and long-press gestures with configurable thresholds; camera-aware `getTouchesWorld()`.
- `TouchInput` — minimal DTO with `position: Vector2`.

### Events
- `EventBus` — synchronous per-scene pub/sub (`on` / `off` / `emit`). Engine creates a fresh instance on every `start`.

### Assets
- `AssetManager` — pluggable: accepts a `ResourceManagerLike` (host's resource manager) and a `TextureDecoder` (consumer-supplied async decode function). Caches `Texture`s by name.
- `Texture` — wraps a native `PixelMap` or `ImageBitmap` plus `width`, `height`, and `kind`.

### Physics
- `Collider` — abstract base with `friction` and `restitution`.
- `BoxCollider` — axis-aligned rectangle (rotation is intentionally ignored; OBB is V1.2+).
- `CircleCollider` — circle with `radius`.
- `Rigidbody` — `velocity`, `mass`, `gravityScale`, `drag`, `applyImpulse`. Manual `update(dt)` for V1.0; `PhysicsSystem` integrates automatically.
- `Collision` — overlap pair DTO (V1.0 boundary).
- `CollisionSystem` — static all-pairs overlap detector (V1.0). Superseded by `PhysicsSystem` for any non-trivial game.
- `Manifold` — contact data: `normal`, `penetration`, `restitution`, `friction`. Static `compute(a, b)` for Box↔Box, Box↔Circle, Circle↔Circle.
- `PhysicsSystem` — auto-driven GameSystem that integrates gravity + drag, then resolves every collider pair via `Manifold.compute` with impulsive restitution and Baumgarte positional correction. Tangential friction is informational only (not yet applied).

### Performance
- `PerformanceBudget` — repeatable benchmark harness (`warmup`, `samples`, `avgLimitMs`, `sampleLimitMs`) for CI / test-time perf assertions.
- `BudgetExceededError` — thrown when a budget run fails.

### Deferred to next versions
- OBB / rotated box colliders (V1.2).
- Tangential friction application in `PhysicsSystem` (V1.2).
- Native ArkUI HUD widgets — for now, use `TextEntity`.
- OHPM publish of `0.1.0` (manual step).
