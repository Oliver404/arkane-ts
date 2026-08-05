// math/Rect.ts
import { Vector2 } from './Vector2'

export class Rect {
  x: number
  y: number
  width: number
  height: number

  constructor(x: number, y: number, width: number, height: number) {
    this.x = x
    this.y = y
    this.width = width
    this.height = height
  }

  get left(): number {
    return this.x
  }

  get right(): number {
    return this.x + this.width
  }

  get top(): number {
    return this.y
  }

  get bottom(): number {
    return this.y + this.height
  }

  contains(point: Vector2): boolean {
    return point.x >= this.left && point.x < this.right &&
      point.y >= this.top && point.y < this.bottom
  }

  intersects(other: Rect): boolean {
    return this.left < other.right && this.right > other.left &&
      this.top < other.bottom && this.bottom > other.top
  }
}
