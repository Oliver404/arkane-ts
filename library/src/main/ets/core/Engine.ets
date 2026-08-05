// core/Engine.ts
import { InputManager } from '../input/InputManager'
import { Camera2D } from '../render/Camera2D'
import { RenderContext } from '../render/RenderContext'
import { Renderer2D } from '../render/Renderer2D'
import { Scene2D } from '../scene/Scene2D'
import { SceneContext } from '../scene/SceneContext'
import { EventBus } from '../events/EventBus'
import { AssetManager } from '../assets/AssetManager'
import { GameLoop } from './GameLoop'
import { SceneManager } from './SceneManager'

export interface EngineConfig {
  targetFPS?: number // Reserved for v2
}

export class Engine {
  private loop: GameLoop
  private renderer?: Renderer2D
  private renderContext?: RenderContext
  private camera?: Camera2D
  private sceneContext?: SceneContext
  private eventBus?: EventBus
  private assetManager: AssetManager = new AssetManager()
  private sceneManager: SceneManager
  private input: InputManager = new InputManager()
  private systems: GameSystem[] = []

  constructor(config?: EngineConfig) {
    this.sceneManager = new SceneManager()

    this.loop = new GameLoop(
      () => {
        this.update()
      },
      () => {
        this.render()
      }
    )
  }

  getInput(): InputManager {
    return this.input
  }

  /** Inject an asset manager (e.g. one with `resourceManager` and a
   *  `decoder` configured). Call before `start()`. */
  setAssetManager(manager: AssetManager): void {
    this.assetManager = manager
  }

  /** Read-only handle for advanced cases. Consumers should prefer
   *  `setAssetManager` to construct their own. */
  getAssetManager(): AssetManager {
    return this.assetManager
  }

  start(initialScene: Scene2D) {
    const eventBus = new EventBus()
    this.eventBus = eventBus
    const context = this.createSceneContext(eventBus)
    this.sceneContext = context
    initialScene.setContext(context)
    this.sceneManager.setScene(initialScene)

    if (this.camera) {
      initialScene.setCamera(this.camera)
    }

    this.loop.start()
  }

  /**
   * Switch the active scene at runtime. Calls `onExit` on the previous
   * scene (if any) and `onEnter` on the new one. Injects the current
   * `SceneContext` and `Camera2D` into the new scene so consumers don't
   * need to re-wire them manually.
   */
  setScene(scene: Scene2D): void {
    if (this.sceneContext) {
      scene.setContext(this.sceneContext)
    }
    if (this.camera) {
      scene.setCamera(this.camera)
    }
    this.sceneManager.setScene(scene)
  }

  stop() {
    this.loop.stop()
  }

  private createSceneContext(eventBus: EventBus): SceneContext {
    if (!this.camera) {
      throw new Error('Camera not initialized')
    }

    return new SceneContext(this.input, this.camera, eventBus, this.assetManager)
  }

  setRenderer(renderer: Renderer2D, context: RenderContext) {
    this.renderer = renderer
    this.renderContext = context
    this.camera = new Camera2D(context.width, context.height)
    const scene = this.sceneManager.getCurrentScene()
    this.input.setCamera(this.camera)

    if (scene) {
      scene.setCamera(this.camera)
    }
  }

  /** Register a custom system. Hooks run in registration order around
   *  scene.update: beforeUpdate of every system, then scene.update,
   *  then afterUpdate of every system. If the system exposes `attach`,
   *  the engine calls it with itself so the system can query the active
   *  scene inside `beforeUpdate`. */
  registerSystem(system: GameSystem): void {
    this.systems.push(system)
    if (system.attach) {
      system.attach(this)
    }
  }

  /** Read-only handle to the active scene (managed by `SceneManager`).
   *  Available so registered systems can pull the scene from inside
   *  their `beforeUpdate` hook without holding a direct back-reference
   *  to the engine. */
  getScene(): Scene2D | undefined {
    return this.sceneManager.getCurrentScene()
  }

  /** Test-only helper: inject a scene without going through `setRenderer`
   *  or `start`. Pairs with `updateForTest`. */
  setTestScene(scene: Scene2D): void {
    this.sceneManager.setScene(scene)
  }

  /** Test-only helper: run a single update tick synchronously against
   *  the scene previously injected via `setTestScene`. */
  updateForTest(): void {
    this.update()
  }

  private update() {
    for (let i = 0; i < this.systems.length; i++) {
      const system = this.systems[i]
      if (system.beforeUpdate) {
        system.beforeUpdate()
      }
    }

    this.sceneManager.update()

    for (let i = 0; i < this.systems.length; i++) {
      const system = this.systems[i]
      if (system.afterUpdate) {
        system.afterUpdate()
      }
    }

    this.input.clearFrameFlags()
  }

  private render() {
    if (!this.renderer || !this.renderContext) {
      return
    }

    const scene = this.sceneManager.getCurrentScene()
    if (!scene) {
      return
    }

    this.renderer.begin(this.renderContext)
    scene.render(this.renderContext, this.renderer)
    this.renderer.end()
  }
}

/** Optional hook contract for systems registered with the engine.
 *  Implementations may provide either, both, or neither; the engine
 *  invokes whatever is present in registration order. */
export interface GameSystem {
  beforeUpdate?(): void
  afterUpdate?(): void
  /** Called once when the engine registers the system. Lets the system
   *  reach back into the engine (e.g. to query the current scene from
   *  inside `beforeUpdate`). Optional — non-attaching systems keep the
   *  original contract. */
  attach?(engine: Engine): void
}
