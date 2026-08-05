// physics/BoxCollider.ts
import { Collider } from './Collider'
import { Vector2 } from '../math/Vector2'
import { Transform } from '../scene/Transform'
import { CircleCollider } from './CircleCollider'

// Axis-aligned only: Transform.rotation is intentionally ignored.
// OBB / rotated collider support is a later story (V1.2+).
export class BoxCollider extends Collider {
  size: Vector2

  constructor(transform: Transform, width: number, height: number) {
    super(transform)
    this.size = new Vector2(width, height)
  }

  get left(): number { return this.transform.position.x - this.size.x / 2 }
  get right(): number { return this.transform.position.x + this.size.x / 2 }
  get top(): number { return this.transform.position.y - this.size.y / 2 }
  get bottom(): number { return this.transform.position.y + this.size.y / 2 }

  isColliding(other: Collider): boolean {
    if (other instanceof BoxCollider) {
      return !(
        this.right < other.left ||
          this.left > other.right ||
          this.bottom < other.top ||
          this.top > other.bottom
      )
    }

    if (other instanceof CircleCollider) {
      // Closest point on this AABB to the circle center.
      const halfW = this.size.x / 2
      const halfH = this.size.y / 2
      const cx = other.transform.position.x
      const cy = other.transform.position.y
      const closestX = Math.max(this.transform.position.x - halfW,
        Math.min(cx, this.transform.position.x + halfW))
      const closestY = Math.max(this.transform.position.y - halfH,
        Math.min(cy, this.transform.position.y + halfH))
      const dx = cx - closestX
      const dy = cy - closestY
      return (dx * dx + dy * dy) <= (other.radius * other.radius)
    }

    return false
  }
}
