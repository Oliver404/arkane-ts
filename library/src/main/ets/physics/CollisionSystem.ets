import { Collider } from './Collider'
import { Collision } from './Collision'

export class CollisionSystem {
  static checkCollisions(colliders: Collider[]): Collision[] {
    const collisions: Collision[] = []

    for (let i = 0; i < colliders.length; i++) {
      const a = colliders[i]
      for (let j = i + 1; j < colliders.length; j++) {
        const b = colliders[j]
        if (a.isColliding(b)) {
          collisions.push(new Collision(a, b))
        }
      }
    }

    return collisions
  }
}
