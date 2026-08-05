import { RenderContext } from './RenderContext'
import { Sprite } from './Sprite'
import { Transform } from '../scene/Transform'
import { Camera2D } from './Camera2D'

export interface Renderer2D {
  begin(context: RenderContext): void
  drawSprite(sprite: Sprite, transform: Transform, camera?: Camera2D): void
  end(): void
}
