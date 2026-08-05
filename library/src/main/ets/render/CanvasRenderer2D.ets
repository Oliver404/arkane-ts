// render/CanvasRenderer2D.ts
import { Renderer2D } from './Renderer2D'
import { RenderContext } from './RenderContext'
import { Sprite } from './Sprite'
import { Transform } from '../scene/Transform'
import { Camera2D } from './Camera2D'
import { Vector2 } from '../math/Vector2'

export class CanvasRenderer2D implements Renderer2D {
  fillColor: string = '#1e1e1e'
  private context?: RenderContext

  constructor(color?: string) {
    this.fillColor = color ?? '#1e1e1e'
  }

  begin(context: RenderContext): void {
    this.context = context
    context.clear(this.fillColor)
  }

  drawSprite(
    sprite: Sprite,
    transform: Transform,
    camera?: Camera2D
  ): void {
    const ctx = this.context!.ctx

    const screenPos: Vector2 = camera
      ? camera.worldToScreen(transform.position)
      : transform.position

    // V1.0 simplification: we apply transform.scale to sprite.size.
    const scaledSize: Vector2 = new Vector2(
      sprite.size.x * transform.scale.x,
      sprite.size.y * transform.scale.y
    )

    const halfW = scaledSize.x / 2
    const halfH = scaledSize.y / 2

    // save/restore so that rotation/scale does not leak
    // into the next drawSprite.
    ctx.save()
    ctx.translate(screenPos.x, screenPos.y)
    ctx.rotate(transform.rotation)
    ctx.translate(-screenPos.x, -screenPos.y)

    if (sprite.image) {
      // Texture image is drawn stretched to (scaledSize.x, scaledSize.y).
      // The cast to `Object` matches the ArkUI `drawImage` overload that
      // accepts both PixelMap and ImageBitmap.
      ctx.drawImage(
        sprite.image.source as ImageBitmap,
        screenPos.x - halfW,
        screenPos.y - halfH,
        scaledSize.x,
        scaledSize.y
      )
    } else {
      ctx.fillStyle = sprite.color
      ctx.fillRect(
        screenPos.x - halfW,
        screenPos.y - halfH,
        scaledSize.x,
        scaledSize.y
      )
    }
    ctx.restore()
  }

  end(): void {
    // V1.0: no quedan operaciones pendientes.
  }
}
