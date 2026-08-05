// library/Index.ets — HAR public surface (must stay in sync with
// library/src/main/ets/index.ets).

// ===== Core =====
export { Engine } from './src/main/ets/core/Engine'
export type { EngineConfig } from './src/main/ets/core/Engine'
export type { GameSystem } from './src/main/ets/core/Engine'
export { GameLoop } from './src/main/ets/core/GameLoop'
export type { LoopCallback } from './src/main/ets/core/GameLoop'
export { Time } from './src/main/ets/core/Time'
export { SceneManager } from './src/main/ets/core/SceneManager'

// ===== Scene =====
export { Scene2D } from './src/main/ets/scene/Scene2D'
export { Entity } from './src/main/ets/scene/Entity'
export { Transform } from './src/main/ets/scene/Transform'
export { SceneContext } from './src/main/ets/scene/SceneContext'

// ===== Render =====
export type { Renderer2D } from './src/main/ets/render/Renderer2D'
export { CanvasRenderer2D } from './src/main/ets/render/CanvasRenderer2D'
export { Camera2D } from './src/main/ets/render/Camera2D'
export { Sprite } from './src/main/ets/render/Sprite'
export { RenderContext } from './src/main/ets/render/RenderContext'
export { TextEntity } from './src/main/ets/render/TextEntity'

// ===== Input =====
export { InputManager } from './src/main/ets/input/InputManager'
export { TouchInput } from './src/main/ets/input/TouchInput'

// ===== Events =====
export { EventBus } from './src/main/ets/events/EventBus'

// ===== Math =====
export { Vector2 } from './src/main/ets/math/Vector2'
export { Vector3 } from './src/main/ets/math/Vector3'
export { Rect } from './src/main/ets/math/Rect'
export { MathUtils } from './src/main/ets/math/MathUtils'

// ===== Physics =====
export { Rigidbody } from './src/main/ets/physics/Rigidbody'
export { BoxCollider } from './src/main/ets/physics/BoxCollider'
export { CircleCollider } from './src/main/ets/physics/CircleCollider'
export { Collider } from './src/main/ets/physics/Collider'
export { Collision } from './src/main/ets/physics/Collision'
export { CollisionSystem } from './src/main/ets/physics/CollisionSystem'
export { Manifold } from './src/main/ets/physics/Manifold'
export { PhysicsSystem } from './src/main/ets/physics/PhysicsSystem'

// ===== Assets =====
export { Texture } from './src/main/ets/assets/Texture'
export type { TextureKind } from './src/main/ets/assets/Texture'
export { AssetManager } from './src/main/ets/assets/AssetManager'
export type { ResourceManagerLike, TextureDecoder } from './src/main/ets/assets/AssetManager'

// ===== Perf =====
export { PerformanceBudget } from './src/main/ets/perf/PerformanceBudget'
export { BudgetExceededError } from './src/main/ets/perf/PerformanceBudget'
export type { BudgetConfig, BudgetResult } from './src/main/ets/perf/PerformanceBudget'
