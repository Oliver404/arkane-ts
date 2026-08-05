import { Vector2 } from '../math/Vector2'
import { Texture } from '../assets/Texture'

export class Sprite {
  size: Vector2
  color: string
  // V1.1: image support — once Texture is implemented, the renderer
  // will draw sprite.image scaled to sprite.size instead of the solid color.
  image?: Texture

  constructor(
    width: number,
    height: number,
    color: string = '#ffffff'
  ) {
    this.size = new Vector2(width, height)
    this.color = color
  }
}
