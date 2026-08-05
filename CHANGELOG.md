# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Deferred from `0.0.1` — see [`docs/VERSIONS.md`](docs/VERSIONS.md) for the per-version API backlog.

## [0.0.1] - 2026-08-04

Initial library release. Ships the 2D engine foundation.

### Added

- **Core**: `Engine` orchestrator, fixed-timestep `GameLoop` (60 FPS), `Scene2D` with `onEnter` / `update` / `render` / `onExit`, `Entity` with optional `Sprite` / `Collider` / `Rigidbody` slots, `SceneContext` for dependency injection.
- **Render**: `Renderer2D` abstraction with `CanvasRenderer2D` default for ArkUI, `Camera2D` (world↔screen, zoom, follow, lookAt), `Sprite` (solid or image-backed), `TextEntity` for HUD with camera-aware positioning.
- **Input**: Multitouch `InputManager` with frame-bounded events, swipe and long-press gestures.
- **Events**: Per-scene synchronous `EventBus`.
- **Physics**: `PhysicsSystem` with `Manifold` contact data, restitution, and Baumgarte positional correction; `BoxCollider`, `CircleCollider`, `Rigidbody` with `applyImpulse` and gravity/drag integration.
- **Assets**: `AssetManager` + `Texture` cache with pluggable `TextureDecoder` (the library carries no `@ohos.multimedia.image` dependency).
- **Math**: `Vector2` / `Vector3`, `Rect`, `MathUtils` (`clamp`, `lerp`).
- **Performance**: `PerformanceBudget` harness for CI / test-time perf assertions.
- **Example app**: Pong-style game under `example/` (menu, gameplay, AI, score, game-over, options, difficulty scenes).
- **Tests**: Hypium + Hamock suites (device + host) including API-surface pinning (`library/src/test/ApiSurface.test.ets`) so the wiki never drifts from actual exports.
- **Docs**: Wiki under `docs/wiki/` — architecture, getting started, 5 progressive examples, cookbook (top-down / platformer / endless-runner / menu), and per-module API reference. Published via GitHub Pages + MkDocs Material + mike.
- **License**: MIT.
- **CI**: Tag-driven release workflow (`.github/workflows/release.yml`) — pushing a `v*` tag validates the version, deploys docs, and creates a GitHub Release.

### Known limitations

- `BoxCollider` ignores rotation (OBB support deferred to V1.2).
- Tangential friction in `PhysicsSystem` is informational only.
- No native ArkUI HUD widgets — use `TextEntity`.
- `0.0.1` is not yet published to OHPM (manual step).

[Unreleased]: https://github.com/Oliver404/arkane-ts/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/Oliver404/arkane-ts/releases/tag/v0.0.1
