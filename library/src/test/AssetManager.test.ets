import { describe, it, expect } from '@ohos/hypium';
import {
  AssetManager,
  ResourceManagerLike,
  TextureDecoder
} from '../main/ets/assets/AssetManager';
import { Texture } from '../main/ets/assets/Texture';

// Named interfaces so ArkTS strict accepts the literal initializers.
interface StubMarker {
  mark: string;
  stub?: number | boolean;
  from?: string;
}

class FakeResourceManager implements ResourceManagerLike {
  calls: number = 0
  lastName: string = ''
  payload: Uint8Array

  constructor(payload: Uint8Array = new Uint8Array([1, 2, 3, 4])) {
    this.payload = payload
  }

  async getRawFileContent(name: string): Promise<Uint8Array> {
    this.calls++
    this.lastName = name
    return this.payload
  }
}

const noopDecoder: TextureDecoder = async (_name: string, _buf: Uint8Array) => {
  const m: StubMarker = { mark: 'noop' }
  return new Texture(m as Object, 1, 1, 'pixelmap')
}

async function expectReject(p: Promise<Object>, needle: string): Promise<boolean> {
  try {
    await p
  } catch (err) {
    const msg = (err as Record<string, Object>)['message'] as string
    return msg.indexOf(needle) >= 0
  }
  return false
}

export default function assetManagerTest() {
  describe('Texture (HU-18)', () => {
    it('constructor stores source/width/height/kind', 0, () => {
      const m: StubMarker = { stub: 1, mark: 't1' }
      const t = new Texture(m as Object, 64, 48, 'bitmap')
      expect(t.source).not().assertNull()
      expect(t.width).assertEqual(64)
      expect(t.height).assertEqual(48)
      expect(t.kind).assertEqual('bitmap')
    });

    it('default kind is pixelmap (HU-18)', 0, () => {
      const m: StubMarker = { mark: 'default' }
      const t = new Texture(m as Object, 32, 32)
      expect(t.kind).assertEqual('pixelmap')
    });
  });

  describe('AssetManager (HU-18)', () => {
    it('load() without a resourceManager rejects with a message about resourceManager (HU-18)', 0, async () => {
      const am = new AssetManager()
      const matched = await expectReject(am.load('foo.png'), 'resourceManager')
      expect(matched).assertTrue();
    });

    it('load() without a decoder rejects with a message about decoder (HU-18)', 0, async () => {
      const rm = new FakeResourceManager()
      const am = new AssetManager(rm)
      const matched = await expectReject(am.load('foo.png'), 'decoder')
      expect(matched).assertTrue();
    });

    it('loadFromBuffer wraps source and caches by name (HU-18)', 0, () => {
      const am = new AssetManager()
      const m1: StubMarker = { stub: 1, mark: 'enemy1' }
      const tex = am.loadFromBuffer('enemy', m1 as Object, 32, 32, 'bitmap')
      expect(tex).not().assertNull()
      expect(tex.width).assertEqual(32)
      expect(tex.kind).assertEqual('bitmap')
      expect(am.has('enemy')).assertTrue()
      const m2: StubMarker = { stub: 2, mark: 'enemy2' }
      const tex2 = am.loadFromBuffer('enemy', m2 as Object, 16, 16)
      expect(tex2 === tex).assertFalse()
      expect(am.has('enemy')).assertTrue()
    });

    it('load() async: calls resourceManager and decoder once (HU-18)', 0, async () => {
      const rm = new FakeResourceManager()
      let decoderCalls = 0
      const decoder: TextureDecoder = async (_name, _buf) => {
        decoderCalls++
        const m: StubMarker = { from: 'decoder', mark: 'd1' }
        return new Texture(m as Object, 8, 8, 'pixelmap')
      }
      const am = new AssetManager(rm, decoder)
      const tex = await am.load('sprite.png')
      expect(rm.calls).assertEqual(1)
      expect(rm.lastName).assertEqual('sprite.png')
      expect(decoderCalls).assertEqual(1)
      expect(tex.width).assertEqual(8)
    });

    it('load() cache hit does NOT re-call resourceManager (HU-18)', 0, async () => {
      const rm = new FakeResourceManager()
      const am = new AssetManager(rm, noopDecoder)
      const t1 = await am.load('hero.png')
      const t2 = await am.load('hero.png')
      expect(rm.calls).assertEqual(1)
      expect(t1 === t2).assertTrue()
    });

    it('has() reflects the cache state; clear() empties it (HU-18)', 0, () => {
      const am = new AssetManager()
      expect(am.has('foo')).assertFalse()
      const m: StubMarker = { stub: 1, mark: 'foo' }
      am.loadFromBuffer('foo', m as Object, 1, 1)
      expect(am.has('foo')).assertTrue()
      am.clear()
      expect(am.has('foo')).assertFalse()
    });
  });
}