// assets/AssetManager.ts
import { Texture } from './Texture'

/**
 * Minimal interface for the host environment's `ResourceManager`. Consumers
 * inject a concrete instance (typically `getContext().resourceManager`) so
 * the library stays decoupled from `@ohos.app.ability`.
 */
export interface ResourceManagerLike {
  getRawFileContent(name: string): Promise<Uint8Array>
}

/**
 * Pluggable decoder that turns a rawfile buffer into a `Texture`. The
 * library ships no default — the consumer must supply a function that
 * uses their preferred runtime APIs (e.g. `@ohos.multimedia.image`).
 *
 * Example consumer-side decoder:
 *   const decoder: TextureDecoder = async (_name, buf) => {
 *     const image = await import('@ohos.multimedia.image');
 *     const src = image.createImageSource(buf.buffer as ArrayBuffer);
 *     const pm = await src.createPixelMap();
 *     const info = await pm.getImageInfo();
 *     return new Texture(pm, info.size.width, info.size.height, 'pixelmap');
 *   };
 */
export type TextureDecoder = (
  name: string,
  buffer: Uint8Array
) => Promise<Texture>

/**
 * Loads and caches `Texture` instances from `rawfile` (or any in-memory
 * buffer). Cache is per-instance: one `AssetManager` per app.
 */
export class AssetManager {
  private cache: Map<string, Texture> = new Map()
  private resourceManager: ResourceManagerLike | null
  private decoder: TextureDecoder | null

  constructor(
    resourceManager?: ResourceManagerLike | null,
    decoder?: TextureDecoder | null
  ) {
    this.resourceManager = resourceManager ?? null
    this.decoder = decoder ?? null
  }

  /**
   * Async: loads a rawfile by `name` and caches it. Cache hit on repeated
   * calls. Throws when `resourceManager` or `decoder` were not provided
   * to the constructor — use `loadFromBuffer()` for tests / in-memory data.
   */
  async load(name: string): Promise<Texture> {
    const cached = this.cache.get(name)
    if (cached) {
      return cached
    }
    if (!this.resourceManager) {
      throw new Error(
        'AssetManager.load(): no resourceManager provided. '
        + 'Pass one to the constructor or use loadFromBuffer().'
      )
    }
    if (!this.decoder) {
      throw new Error(
        'AssetManager.load(): no decoder provided. '
        + 'Pass a TextureDecoder to the constructor (e.g. one wrapping '
        + '@ohos.multimedia.image) or use loadFromBuffer().'
      )
    }
    const buffer = await this.resourceManager.getRawFileContent(name)
    const texture = await this.decoder(name, buffer)
    this.cache.set(name, texture)
    return texture
  }

  /**
   * Synchronous: wraps an already-decoded image in a `Texture` and caches
   * it under `name`. Use this when loading via network, file picker, or
   * any side channel other than rawfile. Useful for tests, too.
   */
  loadFromBuffer(
    name: string,
    source: Object,
    width: number,
    height: number,
    kind: 'pixelmap' | 'bitmap' = 'pixelmap'
  ): Texture {
    const tex = new Texture(source, width, height, kind)
    this.cache.set(name, tex)
    return tex
  }

  has(name: string): boolean {
    return this.cache.has(name)
  }

  clear(): void {
    this.cache.clear()
  }
}
