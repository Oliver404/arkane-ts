---
title: Wiki
version: 0.0.1
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# Arkane TS Wiki

This is the developer-facing documentation for `@oliver404/arkane-ts` v0.0.1, a 2D game engine library for HarmonyOS NEXT (ArkTS).

**New here?** Start with [getting-started.md](getting-started.md) — it walks you through install, bootstrap, and the basic touch-and-collide pattern.

**Looking for code?** See [examples/](examples/) — five progressive examples from a single moving element to assets and events.

**Need a recipe?** See [cookbook/](cookbook/) — concrete patterns for top-down, platformer, endless runner, and menu systems.

**Want to understand the internals?** Read [architecture.md](architecture.md).

---

## Table of contents

### Top level
- [Getting started](getting-started.md)
- [Architecture overview](architecture.md)

### Core
- [Engine](core/engine.md) — orchestrator that wires everything together
- [GameLoop](core/gameloop.md) — fixed-timestep loop
- [Time](core/time.md) — frame timing state
- [SceneManager](core/scenemanager.md) — single-scene holder

### Scene
- [Scene2D](scene/scene2d.md) — abstract scene with lifecycle
- [Entity](scene/entity.md) — base node with Transform and optional components
- [Transform](scene/transform.md) — position, scale, rotation
- [SceneContext](scene/scenecontext.md) — injected input, camera, events, assets

### Render
- [Renderer2D](render/renderer2d.md) — pluggable interface
- [CanvasRenderer2D](render/canvasrenderer2d.md) — default ArkUI implementation
- [Camera2D](render/camera2d.md) — world↔screen, follow, lookAt, world bounds
- [Sprite](render/sprite.md) — solid color or texture-backed rectangle
- [TextEntity](render/textentity.md) — text with font and alignment

### Math
- [Vector2](math/vector2.md)
- [Vector3](math/vector3.md)
- [Rect](math/rect.md)
- [MathUtils](math/mathutils.md)

### Input
- [InputManager](input/inputmanager.md) — touch + gestures
- [TouchInput](input/touchinput.md) — touch point DTO

### Events
- [EventBus](events/eventbus.md) — per-scene pub/sub

### Assets
- [AssetManager](assets/assetmanager.md) — texture cache + pluggable decoder
- [Texture](assets/texture.md) — image wrapper

### Physics
- [Collider](physics/collider.md) — abstract base
- [BoxCollider](physics/boxcollider.md) — AABB
- [CircleCollider](physics/circlecollider.md) — circle
- [Rigidbody](physics/rigidbody.md) — mass, velocity, gravity, drag
- [Manifold](physics/manifold.md) — contact data
- [PhysicsSystem](physics/physicssystem.md) — auto-driven physics tick
- [CollisionSystem](physics/collisionsystem.md) — V1.0 overlap detector

### Performance
- [PerformanceBudget](perf/performancebudget.md) — CI benchmark harness

### Examples
- [01 — Move and collide](examples/01-move-and-collide.md) — minimal: one moving element, one obstacle
- [02 — Text and sprites](examples/02-text-and-sprites.md)
- [03 — Physics system](examples/03-physics-system.md)
- [04 — Camera and input](examples/04-camera-and-input.md)
- [05 — Assets and events](examples/05-assets-and-events.md)

### Cookbook
- [Top-down game](cookbook/top-down-game.md)
- [Platformer](cookbook/platformer.md)
- [Endless runner](cookbook/endless-runner.md)
- [Menu system](cookbook/menu-system.md)

---

## Conventions used in this Wiki

- **Code snippets** assume imports come from `@oliver404/arkane-ts`. TypeScript-style type annotations are used for clarity even though ArkTS is a typed subset.
- **Y axis**: world Y points **UP**. Default gravity is `(0, -9.8)`. See [architecture.md](architecture.md#y-axis-convention).
- **Frame-bounded flags**: `isTouchStarted`, `isTouchEnded`, `isSwipeTriggered`, `isLongPressTriggered` are reset at the end of every engine tick. Always read them inside `Scene2D.update()` or `GameSystem.beforeUpdate()`.
- **Per-module pages** follow a standard template: basic usage → configuration → advanced usage → pitfalls & FAQ → see also.

## Public API at a glance

All symbols are exported from `@oliver404/arkane-ts`.

| Section | Classes / types |
|---|---|
| Core | `Engine`, `EngineConfig`, `GameSystem`, `GameLoop`, `LoopCallback`, `Time`, `SceneManager` |
| Scene | `Scene2D`, `Entity`, `Transform`, `SceneContext` |
| Render | `Renderer2D`, `CanvasRenderer2D`, `Camera2D`, `Sprite`, `RenderContext`, `TextEntity` |
| Math | `Vector2`, `Vector3`, `Rect`, `MathUtils` |
| Input | `InputManager`, `TouchInput` |
| Events | `EventBus` |
| Assets | `AssetManager`, `ResourceManagerLike`, `TextureDecoder`, `Texture`, `TextureKind` |
| Physics | `Collider`, `BoxCollider`, `CircleCollider`, `Rigidbody`, `Collision`, `CollisionSystem`, `Manifold`, `PhysicsSystem` |
| Performance | `PerformanceBudget`, `BudgetExceededError`, `BudgetConfig`, `BudgetResult` |
