// scene/SceneContext.ts
import { InputManager } from '../input/InputManager'
import { Camera2D } from '../render/Camera2D'
import { EventBus } from '../events/EventBus'
import { AssetManager } from '../assets/AssetManager'

export class SceneContext {
  readonly input: InputManager
  readonly camera: Camera2D
  readonly events: EventBus
  readonly assets: AssetManager

  constructor(
    input: InputManager,
    camera: Camera2D,
    events: EventBus,
    assets?: AssetManager
  ) {
    this.input = input
    this.camera = camera
    this.events = events
    this.assets = assets ?? new AssetManager()
  }
}
