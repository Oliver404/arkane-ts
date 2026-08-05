// render/Camera2D.ts
import { Vector2 } from '../math/Vector2'
import { Entity } from '../scene/Entity'

interface WorldBounds {
  minX: number
  maxX: number
  minY: number
  maxY: number
}

export class Camera2D {
  position: Vector2 = new Vector2(0, 0)
  zoom: number = 1
  public viewportWidth: number;
  public viewportHeight: number;

  private followTarget: Entity | null = null
  private worldBounds: WorldBounds | null = null

  constructor(
  viewportWidth: number,
  viewportHeight: number
  ) {
  this.viewportWidth = viewportWidth;
  this.viewportHeight = viewportHeight;
}

  worldToScreen(worldPos: Vector2): Vector2 {
    return new Vector2(
      (worldPos.x - this.position.x) * this.zoom + this.viewportWidth / 2,
      (worldPos.y - this.position.y) * this.zoom + this.viewportHeight / 2
    )
  }

  screenToWorld(screenPos: Vector2): Vector2 {
    return new Vector2(
      (screenPos.x - this.viewportWidth / 2) / this.zoom + this.position.x,
      (screenPos.y - this.viewportHeight / 2) / this.zoom + this.position.y
    )
  }

  follow(target: Entity): void {
    this.followTarget = target
  }

  lookAt(point: Vector2): void {
    this.position = new Vector2(point.x, point.y)
  }

  update(): void {
    if (!this.followTarget) {
      return
    }

    const target = this.followTarget.transform.position
    let x = target.x
    let y = target.y

    if (this.worldBounds) {
      const halfW = this.viewportWidth / (2 * this.zoom)
      const halfH = this.viewportHeight / (2 * this.zoom)
      x = Math.max(this.worldBounds.minX + halfW, Math.min(x, this.worldBounds.maxX - halfW))
      y = Math.max(this.worldBounds.minY + halfH, Math.min(y, this.worldBounds.maxY - halfH))
    }

    this.position = new Vector2(x, y)
  }

  setWorldBounds(minX: number, maxX: number, minY: number, maxY: number): void {
    this.worldBounds = { minX: minX, maxX: maxX, minY: minY, maxY: maxY }
  }
}

