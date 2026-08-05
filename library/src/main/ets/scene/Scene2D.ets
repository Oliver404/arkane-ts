// scene/Scene2D.ts
import { Camera2D } from '../render/Camera2D'
import { RenderContext } from '../render/RenderContext'
import { Renderer2D } from '../render/Renderer2D'
import { Vector2 } from '../math/Vector2'
import { SceneContext } from './SceneContext'
import { Entity } from './Entity'

export abstract class Scene2D {
  protected entities: Entity[] = []
  protected camera?: Camera2D
  protected context?: SceneContext
  gravity: Vector2 = new Vector2(0, -9.8)

  setCamera(camera: Camera2D): void {
    this.camera = camera
  }

  setContext(context: SceneContext): void {
    this.context = context
  }

  getContext(): SceneContext | undefined {
    return this.context
  }

  getEntities(): readonly Entity[] {
    return this.entities
  }

  entityCount(): number {
    return this.entities.length
  }

  abstract onEnter(): void

  onExit(): void {}

  update(): void {
    for (const entity of this.entities) {
      entity.update()
    }
  }

  render(context: RenderContext, renderer: Renderer2D): void {
    for (const entity of this.entities) {
      entity.render(context, renderer, this.camera)
    }
  }

  addEntity(entity: Entity): void {
    this.entities.push(entity)
  }

  removeEntity(entity: Entity): void {
    const index = this.entities.indexOf(entity)
    if (index !== -1) {
      this.entities.splice(index, 1)
    }
  }
}
