// physics/Manifold.ts
import { Collider } from './Collider'
import { BoxCollider } from './BoxCollider'
import { CircleCollider } from './CircleCollider'
import { Vector2 } from '../math/Vector2'

/**
 * Contact data between two colliders produced by `Manifold.compute`.
 *
 * Sign convention: `normal` points from `a` toward `b` (i.e. the direction
 * an impulse on `b` follows to push it away from `a`).
 *
 * `restitution` = max(a.restitution, b.restitution).
 * `friction` = sqrt(a.friction * b.friction) — informational in V1.1
 * (tangential friction impulse is NOT applied yet).
 */
export class Manifold {
  readonly a: Collider
  readonly b: Collider
  normal: Vector2
  penetration: number
  restitution: number
  friction: number

  // Overload form 1: no-arg stub (Scenario 9 — public export).
  // Overload form 2: full contact data.
  constructor(a?: Collider, b?: Collider, normal?: Vector2, penetration?: number, restitution?: number, friction?: number) {
    const aVal: Collider | undefined = a
    const bVal: Collider | undefined = b
    const nVal: Vector2 | undefined = normal
    const pVal: number | undefined = penetration
    const rVal: number | undefined = restitution
    const fVal: number | undefined = friction

    if (aVal === undefined) {
      // No-arg form: leave fields uninitialised. ArkTS strict requires an
      // explicit value for non-nullable fields, so use Object-as-Type.
      const dummy: Object = new Object()
      this.a = dummy as Object as Collider
      this.b = dummy as Object as Collider
      this.normal = new Vector2()
      this.penetration = 0
      this.restitution = 0
      this.friction = 0
      return
    }
    this.a = aVal
    this.b = bVal as Collider
    if (nVal === undefined) {
      this.normal = new Vector2()
    } else {
      this.normal = nVal
    }
    this.penetration = pVal as number
    this.restitution = rVal as number
    this.friction = fVal as number
  }

  /**
   * Compute the contact manifold for an `a ↔ b` pair. Returns `null` when
   * the colliders do not overlap.
   *
   *   Box-Box:       smallest-overlap axis (SAT). Normal from a → b.
   *   Box-Circle:    box is the receiver (a). Closest point on the AABB
   *                  to the circle center; edge or corner case selected
   *                  by which side the circle sits on.
   *   Circle-Circle: along the line from a.center to b.center.
   */
  static compute(a: Collider, b: Collider): Manifold | null {
    const restitution: number = Math.max(a.restitution, b.restitution)
    const friction: number = Math.sqrt(Math.max(a.friction, 0) * Math.max(b.friction, 0))

    if (a instanceof BoxCollider && b instanceof BoxCollider) {
      return Manifold.computeBoxBox(a, b, restitution, friction)
    }
    if (a instanceof BoxCollider && b instanceof CircleCollider) {
      return Manifold.computeBoxCircle(a, b, restitution, friction)
    }
    if (a instanceof CircleCollider && b instanceof BoxCollider) {
      // Swap roles so the box is always the receiver (a). Negate normal so
      // the convention "normal from a → b" still holds.
      const m: Manifold | null = Manifold.computeBoxCircle(b, a, restitution, friction)
      if (m === null) {
        return null
      }
      m.normal.x = -m.normal.x
      m.normal.y = -m.normal.y
      return m
    }
    if (a instanceof CircleCollider && b instanceof CircleCollider) {
      return Manifold.computeCircleCircle(a, b, restitution, friction)
    }
    return null
  }

  private static computeBoxBox(a: BoxCollider, b: BoxCollider, restitution: number, friction: number): Manifold | null {
    // Axis-aligned. Overlap on each axis:
    const overlapX: number = Math.min(a.right, b.right) - Math.max(a.left, b.left)
    const overlapY: number = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top)
    if (overlapX <= 0 || overlapY <= 0) {
      return null
    }
    const normal: Vector2 = new Vector2()
    let penetration: number = 0
    if (overlapX < overlapY) {
      // Resolve along X. Direction from a toward b.
      penetration = overlapX
      if (b.transform.position.x < a.transform.position.x) {
        normal.x = -1
      } else {
        normal.x = 1
      }
      normal.y = 0
    } else {
      // Resolve along Y. Direction from a toward b.
      penetration = overlapY
      if (b.transform.position.y < a.transform.position.y) {
        normal.y = -1
      } else {
        normal.y = 1
      }
      normal.x = 0
    }
    return new Manifold(a, b, normal, penetration, restitution, friction)
  }

  private static computeBoxCircle(box: BoxCollider, circle: CircleCollider, restitution: number, friction: number): Manifold | null {
    // Same closest-point logic as `BoxCollider.isColliding` for the
    // circle case: clamp circle center to the AABB.
    const halfW: number = box.size.x / 2
    const halfH: number = box.size.y / 2
    const cx: number = circle.transform.position.x
    const cy: number = circle.transform.position.y
    const closestX: number = Math.max(box.transform.position.x - halfW,
      Math.min(cx, box.transform.position.x + halfW))
    const closestY: number = Math.max(box.transform.position.y - halfH,
      Math.min(cy, box.transform.position.y + halfH))
    const dx: number = cx - closestX
    const dy: number = cy - closestY
    const distSq: number = dx * dx + dy * dy
    const r: number = circle.radius
    if (distSq > r * r) {
      return null
    }

    const normal: Vector2 = new Vector2()
    let penetration: number = 0

    if (distSq > 0) {
      // Circle center is outside the box: push along (dx, dy) toward the
      // closest point. Normal must point from box (a) toward circle (b),
      // i.e. the same direction as the offset from closest-point to
      // circle center.
      const dist: number = Math.sqrt(distSq)
      normal.x = dx / dist
      normal.y = dy / dist
      penetration = r - dist
    } else {
      // Circle center is inside the box: pick the shortest exit axis.
      const leftPen: number = cx - (box.transform.position.x - halfW)
      const rightPen: number = (box.transform.position.x + halfW) - cx
      const topPen: number = cy - (box.transform.position.y - halfH)
      const bottomPen: number = (box.transform.position.y + halfH) - cy
      const minPen: number = Math.min(Math.min(leftPen, rightPen), Math.min(topPen, bottomPen))
      if (minPen === leftPen) {
        normal.x = -1
        normal.y = 0
        penetration = leftPen + r
      } else if (minPen === rightPen) {
        normal.x = 1
        normal.y = 0
        penetration = rightPen + r
      } else if (minPen === topPen) {
        normal.x = 0
        normal.y = -1
        penetration = topPen + r
      } else {
        normal.x = 0
        normal.y = 1
        penetration = bottomPen + r
      }
    }

    return new Manifold(box, circle, normal, penetration, restitution, friction)
  }

  private static computeCircleCircle(a: CircleCollider, b: CircleCollider, restitution: number, friction: number): Manifold | null {
    const dx: number = b.transform.position.x - a.transform.position.x
    const dy: number = b.transform.position.y - a.transform.position.y
    const distSq: number = dx * dx + dy * dy
    const r: number = a.radius + b.radius
    if (distSq > r * r) {
      return null
    }

    const normal: Vector2 = new Vector2()
    let penetration: number = 0

    if (distSq > 0) {
      const dist: number = Math.sqrt(distSq)
      normal.x = dx / dist
      normal.y = dy / dist
      penetration = r - dist
    } else {
      // Concentric: pick +x arbitrarily.
      normal.x = 1
      normal.y = 0
      penetration = r
    }

    return new Manifold(a, b, normal, penetration, restitution, friction)
  }
}