// physics/Rigidbody.ts
import { Vector2 } from '../math/Vector2'
import { Transform } from '../scene/Transform'

export class Rigidbody {
  transform: Transform
  velocity: Vector2 = new Vector2()
  mass: number = 1
  /**
   * Multiplier applied to scene.gravity each step.
   * 1 (default) = full gravity. 0 = no gravity. Negative flips it.
   */
  gravityScale: number = 1
  /**
   * Linear damping factor. Each `update(dt)` call multiplies velocity by
   * `max(0, 1 - drag*dt)`. 0 (default) = no damping.
   */
  drag: number = 0

  constructor(transform: Transform) {
    this.transform = transform
  }

  /**
   * Euler integration step. Consumes `drag` and integrates `velocity` into `transform.position`.
   * The auto-driven loop (PhysicsSystem) is V1.1; until then, consumers call this
   * manually from `Scene2D.update()` if they want integration.
   */
  update(deltaTime: number): void {
    if (this.drag > 0) {
      const k = 1 - this.drag * deltaTime
      if (k <= 0) {
        this.velocity.x = 0
        this.velocity.y = 0
      } else {
        this.velocity.multiply(k)
      }
    }
    this.transform.position.add(
      this.velocity.clone().multiply(deltaTime)
    )
  }

  /**
   * Adds the given world impulse (units/sec) to this body's velocity,
   * scaled by inverse mass: `v += impulse / mass`.
   * No-op when `mass <= 0` (static / infinite-mass body).
   */
  applyImpulse(impulse: Vector2): void {
    if (this.mass <= 0) {
      return
    }
    this.velocity.x += impulse.x / this.mass
    this.velocity.y += impulse.y / this.mass
  }
}
