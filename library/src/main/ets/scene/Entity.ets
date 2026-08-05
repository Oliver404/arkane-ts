// scene/Entity.ts
import { Transform } from './Transform'
import { Sprite } from '../render/Sprite'
import { RenderContext } from '../render/RenderContext'
import { Renderer2D } from '../render/Renderer2D'
import { Camera2D } from '../render/Camera2D'
import { Collider } from '../physics/Collider'
import { Rigidbody } from '../physics/Rigidbody'

let ENTITY_ID = 0

export class Entity {
  readonly id: number
  readonly transform: Transform
  sprite?: Sprite
  collider?: Collider
  rigidbody?: Rigidbody

  constructor() {
    this.id = ENTITY_ID++
    this.transform = new Transform()
  }

  setCollider(collider: Collider) {
    this.collider = collider
  }

  setRigidbody(rigidbody: Rigidbody) {
    this.rigidbody = rigidbody
  }

  update(): void {
    // Hook: integration is manual for V1.0. Consumers may drive
    // `entity.rigidbody?.update(dt)` from their Scene2D.update().
    // The auto-driven loop ships with `PhysicsSystem` in V1.1.
  }

  render(
    context: RenderContext,
    renderer: Renderer2D,
    camera?: Camera2D
  ): void {
    if (!this.sprite) {
      return
    }

    renderer.drawSprite(this.sprite, this.transform, camera)
  }
}
