---
title: AssetManager
version: 0.0.1
section: assets
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# AssetManager

Loads and caches `Texture` instances by name. Pluggable: the consumer supplies a `ResourceManagerLike` (typically `getContext().resourceManager`) and a `TextureDecoder` (typically a thin wrapper around `@ohos.multimedia.image`). The library itself stays decoupled from `@ohos.app.ability` and `@ohos.multimedia.image`.

## Basic usage

Wire at engine bootstrap:

```typescript
import { AssetManager, Texture } from '@oliver404/arkane-ts';
import image from '@ohos.multimedia.image';

const decoder = async (_name: string, buf: Uint8Array): Promise<Texture> => {
  const src = image.createImageSource(buf.buffer as ArrayBuffer);
  const pm = await src.createPixelMap();
  const info = await pm.getImageInfo();
  return new Texture(pm, info.size.width, info.size.height, 'pixelmap');
};

const assetManager = new AssetManager(
  getContext().resourceManager,
  decoder
);
engine.setAssetManager(assetManager);
```

Load a texture from inside a scene:

```typescript
override async onEnter(): Promise<void> {
  super.onEnter();
  const tex = await this.context!.assets.load('sprites/hero.png');

  const e = new Entity();
  e.sprite = new Sprite(tex.width, tex.height, '#ffffff');
  e.sprite.image = tex;
  e.transform.position = new Vector2(0, 0);
  this.addEntity(e);
}
```

## Configuration

### Constructor

```typescript
new AssetManager(resourceManager?: ResourceManagerLike | null, decoder?: TextureDecoder | null)
```

| Parameter | Description |
|---|---|
| `resourceManager` | The host environment's `ResourceManager`. Provide `null` if you only need `loadFromBuffer`. |
| `decoder` | Async function `(name, buffer) => Promise<Texture>`. Provide `null` if you only need `loadFromBuffer`. |

### `ResourceManagerLike`

```typescript
interface ResourceManagerLike {
  getRawFileContent(name: string): Promise<Uint8Array>
}
```

Only one method is needed. If your host's `ResourceManager` exposes more, you can write a one-liner adapter.

### `TextureDecoder`

```typescript
type TextureDecoder = (name: string, buffer: Uint8Array) => Promise<Texture>
```

The library ships **no default decoder** — consumers must supply one. This keeps the library portable across ArkUI versions and lets advanced users pre-process textures (mipmaps, atlas packing).

### Methods

| Method | Description |
|---|---|
| `load(name)` | Async. Cache-aware. Returns the cached `Texture` if present; otherwise loads via the resource manager + decoder and caches. **Throws** if either `resourceManager` or `decoder` is `null` at construction time. |
| `loadFromBuffer(name, source, width, height, kind?)` | Sync. Wraps an already-decoded image into a `Texture` and caches under `name`. Use for tests, network loads, file picker results. |
| `has(name)` | `true` if `name` is in the cache. |
| `clear()` | Empties the cache. |

## Advanced usage

### Network-loaded textures

```typescript
const res = await fetch('https://example.com/hero.png');
const buf = new Uint8Array(await res.arrayBuffer());
const decoder = await assets['loadFromBuffer'].bind(assets);
const tex = assets.loadFromBuffer('hero.png', /* decoded image */ decodedImage, w, h, 'pixelmap');
```

`loadFromBuffer` is synchronous because the image is already decoded.

### Pre-warm the cache

Load a list of textures during a loading screen, then `setScene` to the gameplay scene:

```typescript
const texNames = ['hero.png', 'enemy.png', 'bullet.png'];
await Promise.all(texNames.map(n => assets.load(n)));
engine.setScene(new GameScene());
```

### Atlas / sprite sheet

The library has no sprite sheet primitive — store each sub-image as its own texture and write a custom `Entity` subclass that draws the right sub-rect.

## Pitfalls & FAQ

- **`load` throws without a resource manager and decoder.** If you only need `loadFromBuffer`, construct `new AssetManager(null, null)`.
- **Cache is per-instance.** Two engines need two `AssetManager` instances (or share one via `engine.setAssetManager` on both — they will share the cache).
- **`Texture.source` is typed as `Object`.** The renderer casts it to `ImageBitmap` for `drawImage`. If you use a custom image format, ensure ArkUI's `drawImage` accepts it.
- **No eviction.** `clear()` is manual. For a long-running app, you may need an LRU policy.
- **No async batching.** Each `load` call awaits its own resource + decode. Use `Promise.all` for parallelism.

## See also

- [Texture](texture.md) — the loaded value type.
- [Engine](../core/engine.md) — `setAssetManager`.
- [Sprite](../render/sprite.md) — `sprite.image` is a `Texture`.
