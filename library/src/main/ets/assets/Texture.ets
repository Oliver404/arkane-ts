// assets/Texture.ts

/**
 * Discriminator for the underlying image object. ArkUI's
 * `CanvasRenderingContext2D.drawImage` accepts both, but renderer
 * fast-paths (or future code paths that need to call APIs specific to one
 * type) may branch on this field.
 */
export type TextureKind = 'pixelmap' | 'bitmap'

/**
 * A texture wraps the underlying ArkUI image (`@ohos.multimedia.image.PixelMap`
 * or `.ImageBitmap`) together with its dimensions. Stored on `Sprite.image`.
 */
export class Texture {
  /** Underlying image object. Consumers should not mutate. */
  readonly source: Object
  readonly width: number
  readonly height: number
  readonly kind: TextureKind

  constructor(
    source: Object,
    width: number,
    height: number,
    kind: TextureKind = 'pixelmap'
  ) {
    this.source = source
    this.width = width
    this.height = height
    this.kind = kind
  }
}
