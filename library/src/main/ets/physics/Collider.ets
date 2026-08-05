// physics/Collider.ts
import { Transform } from '../scene/Transform'

export abstract class Collider {
  transform: Transform
  /**
   * Tangential damping coefficient applied during a collision response.
   * Stored here; the actual tangential impulse resolution ships in V1.1
   * (along with `Manifold` and the impulsive `PhysicsSystem`).
   */
  friction: number = 0
  /**
   * Bounce factor in the [0, 1] range applied during a collision response.
   * Stored here; the actual normal-impulse resolution ships in V1.1.
   */
  restitution: number = 0

  constructor(transform: Transform) {
    this.transform = transform
  }

  abstract isColliding(other: Collider): boolean
}
