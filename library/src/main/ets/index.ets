// Public surface of @oliver404/arkane-ts.
// V1.0 modules. V1.1 additions (Manifold, PhysicsSystem, registerSystem,
// Camera2D.follow/lookAt, gestures, Vector3) are exported alongside as
// they land.

// core
export { Engine } from './core/Engine'
export type { EngineConfig } from './core/Engine'
export type { GameSystem } from './core/Engine'
export { GameLoop } from './core/GameLoop'
export type { LoopCallback } from './core/GameLoop'
export { Time } from './core/Time'
export { SceneManager } from './core/SceneManager'

// scene
export { Scene2D } from './scene/Scene2D'
export { Entity } from './scene/Entity'
export { Transform } from './scene/Transform'
export { SceneContext } from './scene/SceneContext'

// render
export type { Renderer2D } from './render/Renderer2D'
export { CanvasRenderer2D } from './render/CanvasRenderer2D'
export { Camera2D } from './render/Camera2D'
export { Sprite } from './render/Sprite'
export { RenderContext } from './render/RenderContext'
export { TextEntity } from './render/TextEntity'

// math
export { Vector2 } from './math/Vector2'
export { Vector3 } from './math/Vector3'
export { Rect } from './math/Rect'
export { MathUtils } from './math/MathUtils'

// input
export { InputManager } from './input/InputManager'
export { TouchInput } from './input/TouchInput'

// events
export { EventBus } from './events/EventBus'

// assets
export { AssetManager } from './assets/AssetManager'
export type { ResourceManagerLike, TextureDecoder } from './assets/AssetManager'
export { Texture } from './assets/Texture'
export type { TextureKind } from './assets/Texture'

// physics
export { Collider } from './physics/Collider'
export { BoxCollider } from './physics/BoxCollider'
export { CircleCollider } from './physics/CircleCollider'
export { Rigidbody } from './physics/Rigidbody'
export { Collision } from './physics/Collision'
export { CollisionSystem } from './physics/CollisionSystem'
export { Manifold } from './physics/Manifold'
export { PhysicsSystem } from './physics/PhysicsSystem'

// perf
export { PerformanceBudget } from './perf/PerformanceBudget'
export { BudgetExceededError } from './perf/PerformanceBudget'
export type { BudgetConfig, BudgetResult } from './perf/PerformanceBudget'
