export class RenderContext {
  public ctx: CanvasRenderingContext2D;
  public width: number;
  public height: number;

  constructor(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number
  ) {
    this.ctx = ctx;
    this.width = width;
    this.height = height;
  }

  clear(color: string = '#000000') {
    this.ctx.fillStyle = color
    this.ctx.fillRect(0, 0, this.width, this.height)
  }
}
