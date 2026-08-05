// scene/Transform.ts
import { Vector2 } from '../math/Vector2'

export class Transform {
  position: Vector2 = new Vector2()
  scale: Vector2 = new Vector2(1, 1)
  rotation: number = 0

  constructor(position?: Vector2) {
    if (position) {
      this.position = position
    }
  }
}
