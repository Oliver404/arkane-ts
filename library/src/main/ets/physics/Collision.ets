import { Collider } from './Collider'

export class Collision {
  a: Collider
  b: Collider

  constructor(a: Collider, b: Collider) {
    this.a = a
    this.b = b
  }

  involves(collider: Collider): boolean {
    return this.a === collider || this.b === collider
  }

  getOther(collider: Collider): Collider | null {
    if (this.a === collider) return this.b
    if (this.b === collider) return this.a
    return null
  }
}
