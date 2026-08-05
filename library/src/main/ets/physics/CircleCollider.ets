// physics/CircleCollider.ts
import { Transform } from '../scene/Transform'
import { Collider } from './Collider'

export class CircleCollider extends Collider {
  radius: number

  constructor(transform: Transform, radius: number) {
    super(transform)
    this.radius = radius
  }

  isColliding(other: Collider): boolean {
    if (other instanceof CircleCollider) {
      const dx = other.transform.position.x - this.transform.position.x
      const dy = other.transform.position.y - this.transform.position.y
      const r = this.radius + other.radius
      return (dx * dx + dy * dy) <= (r * r)
    }
    // Box↔Circle: delegate to the BoxCollider's handler, which
    // computes the closest point on the AABB.
    return other.isColliding(this)
  }
}
