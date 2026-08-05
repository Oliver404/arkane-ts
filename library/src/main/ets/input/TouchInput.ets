import { Vector2 } from '../math/Vector2'

export class TouchInput {
  position: Vector2

  constructor(x: number, y: number) {
    this.position = new Vector2(x, y)
  }
}