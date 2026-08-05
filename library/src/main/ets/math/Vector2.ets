// math/Vector2.ts
export class Vector2 {
  x: number
  y: number

  constructor(x: number = 0, y: number = 0) {
    this.x = x
    this.y = y
  }

  clone(): Vector2 {
    return new Vector2(this.x, this.y)
  }

  set(x: number, y: number): Vector2 {
    this.x = x
    this.y = y
    return this
  }

  add(v: Vector2): Vector2 {
    this.x += v.x
    this.y += v.y
    return this
  }

  subtract(v: Vector2): Vector2 {
    this.x -= v.x
    this.y -= v.y
    return this
  }

  multiply(scalar: number): Vector2 {
    this.x *= scalar
    this.y *= scalar
    return this
  }

  divide(scalar: number): Vector2 {
    if (scalar !== 0) {
      this.x /= scalar
      this.y /= scalar
    }
    return this
  }

  length(): number {
    return Math.sqrt(this.x * this.x + this.y * this.y)
  }

  normalize(): Vector2 {
    const len = this.length()
    if (len > 0) {
      this.x /= len
      this.y /= len
    }
    return this
  }

  distance(v: Vector2): number {
    const dx = this.x - v.x
    const dy = this.y - v.y
    return Math.sqrt(dx * dx + dy * dy)
  }

  static add(a: Vector2, b: Vector2): Vector2 {
    return new Vector2(a.x + b.x, a.y + b.y)
  }

  static subtract(a: Vector2, b: Vector2): Vector2 {
    return new Vector2(a.x - b.x, a.y - b.y)
  }

  static zero(): Vector2 {
    return new Vector2(0, 0)
  }
}
