# Arkane TS

A lightweight **2D game engine library** for [HarmonyOS NEXT](https://developer.huawei.com/consumer/en/harmonyos) written in ArkTS. Ship a sprite-on-canvas game in under ten lines of code.

`@oliver404/arkane-ts` is distributed as a [HAR](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/har-package) (HarmonyOS Archive) and consumed via [OHPM](https://developer.huawei.com/consumer/en/ohpm/).

> **Current version: 0.0.1** — see [docs/VERSIONS.md](docs/VERSIONS.md) for the changelog.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Features

- **Game loop** with stable timing (no drift, no magic numbers on first frame)
- **Scene lifecycle** (`onEnter` / `update` / `render` / `onExit`)
- **Entity** with optional `Sprite`, `Collider`, `Rigidbody`
- **Renderer2D** abstraction — `CanvasRenderer2D` ships by default, swap in your own implementation
- **Camera2D** with world↔screen transforms, zoom, `follow`, and `lookAt`
- **Multitouch InputManager** with frame-bounded events (`isTouchStarted` / `isTouchEnded`) and swipe / long-press gestures
- **EventBus** per-scene for system-to-system messaging
- **PhysicsSystem** with `Manifold` contact data, restitution, and Baumgarte positional correction
- **AssetManager** that caches loaded `Texture`s by name (from `rawfile` or arbitrary buffers); consumers plug in their own `TextureDecoder`
- **Sprite** can be either a solid color or an image-backed `Texture`
- **TextEntity** for HUD/score text, with camera-aware positioning
- **Zero magic**: every public class is a plain ArkTS class you can read, extend, or replace

---

## Installation

```bash
ohpm install @oliver404/arkane-ts
```

Add the dependency to your `oh-package.json5`:

```json5
{
  "dependencies": {
    "@oliver404/arkane-ts": "^0.1.0"
  }
}
```

> **Note:** `0.0.1` is the current baseline (see [VERSIONS.md](docs/VERSIONS.md)). For local development before the OHPM publish, clone the repo and add `"@oliver404/arkane-ts": "file:../library"` to your `oh-package.json5` — see `example/`.

---

## Quickstart

```typescript
import { Engine, RenderContext, CanvasRenderer2D, Scene2D, Entity, Sprite, Vector2 } from '@oliver404/arkane-ts';

class HelloScene extends Scene2D {
  onEnter(): void {
    const s = new Entity();
    s.transform.position = new Vector2(0, 0);
    s.sprite = new Sprite(80, 80, '#ff3030');
    this.addEntity(s);
  }
}

@Entry @Component struct Index {
  private engine: Engine = new Engine();
  private settings = new RenderingContextSettings(true);
  private ctx = new CanvasRenderingContext2D(this.settings);
  private renderer = new CanvasRenderer2D();

  build() {
    Canvas(this.ctx).onReady(() => {
      this.engine.setRenderer(this.renderer, new RenderContext(this.ctx, 466, 466));
      this.engine.start(new HelloScene());
    });
  }
}
```

That's the whole game loop. The engine handles frame timing, scene lifecycle, and rendering — you only write the gameplay.

For a **complete moving-and-colliding example** (touch input + `Rigidbody` + `BoxCollider` + `PhysicsSystem`), jump to [docs/wiki/examples/01-move-and-collide.md](docs/wiki/examples/01-move-and-collide.md).

A richer Pong-style demo lives in [`example/src/main/ets/pages/`](example/src/main/ets/pages/) — clone the repo and open `example/` in DevEco Studio to run it.

---

## Documentation

Full developer documentation lives in [`docs/wiki/`](docs/wiki/).

- **[Wiki landing page](docs/wiki/README.md)** — table of contents
- **[Getting started](docs/wiki/getting-started.md)** — install + bootstrap
- **[Architecture overview](docs/wiki/architecture.md)** — module map and tick order
- **[Examples](docs/wiki/examples/)** — progressive examples from "move and collide" to assets and events
- **[Cookbook](docs/wiki/cookbook/)** — recipes for common game genres
- **[Version history](docs/VERSIONS.md)** — per-version changelog

---

## Running tests

```bash
hvigor test
```

Tests use [Hypium](https://developer.huawei.com/consumer/en/hypium/) and Hamock. The library test suite pins the public API surface (see `library/src/test/ApiSurface.test.ets`) so the Wiki never drifts from what is actually exported.

---

## License

MIT. See [LICENSE](LICENSE).
