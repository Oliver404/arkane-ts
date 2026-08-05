// render/TextEntity.ts
import { Entity } from '../scene/Entity'
import { RenderContext } from './RenderContext'
import { Renderer2D } from './Renderer2D'
import { Camera2D } from './Camera2D'
import { Vector2 } from '../math/Vector2'

export class TextEntity extends Entity {
  private text: string
  private fontFamily: string = 'Arial'
  private fontSize: number = 24
  private color: string = '#ffffff'
  private textAlign: 'start' | 'end' | 'left' | 'right' | 'center' = 'start'
  private textBaseline: 'top' | 'hanging' | 'middle' | 'alphabetic' | 'ideographic' | 'bottom' = 'alphabetic'

  constructor(text: string) {
    super()
    this.text = text
  }

  setText(newText: string): void {
    this.text = newText
  }

  setFontFamily(fontFamily: string): void {
    this.fontFamily = fontFamily
  }

  setFontSize(size: number): void {
    this.fontSize = size
  }

  setColor(color: string): void {
    this.color = color
  }

  setTextAlign(align: 'start' | 'end' | 'left' | 'right' | 'center'): void {
    this.textAlign = align
  }

  setTextBaseline(
    baseline: 'top' | 'hanging' | 'middle' | 'alphabetic' | 'ideographic' | 'bottom'
  ): void {
    this.textBaseline = baseline
  }

  render(
    context: RenderContext,
    _renderer: Renderer2D,
    camera?: Camera2D
  ): void {
    const ctx = context.ctx
    const pos: Vector2 = camera
      ? camera.worldToScreen(this.transform.position)
      : this.transform.position

    ctx.save()
    ctx.font = `${this.fontSize}px ${this.fontFamily}`
    ctx.fillStyle = this.color
    ctx.textAlign = this.textAlign
    ctx.textBaseline = this.textBaseline
    ctx.fillText(this.text, pos.x, pos.y)
    ctx.restore()
  }
}
