/**
 * Source feature: .infO404/docs/features/apiCompatibility/apiCompatibility.feature (HU-09)
 * Scenarios covered: each public module has at least one unit test (Scenario 4)
 * Target symbol: RenderContext
 */
import { describe, it, expect } from '@ohos/hypium';
import { RenderContext } from '../main/ets/render/RenderContext';

class StubCtx {
  fillStyle: string = '';
  fillRectCalls: number = 0;
  lastX: number = -1;
  lastY: number = -1;
  lastW: number = -1;
  lastH: number = -1;
  fillRect(x: number, y: number, w: number, h: number): void {
    this.fillRectCalls++;
    this.lastX = x;
    this.lastY = y;
    this.lastW = w;
    this.lastH = h;
  }
}

function makeStubCtx(): Object {
  return new StubCtx();
}

function makeRenderContext(width: number, height: number): RenderContext {
  return new RenderContext(makeStubCtx() as Object as CanvasRenderingContext2D, width, height);
}

export default function renderContextTest() {
  describe('RenderContext', () => {
    it('constructor stores width, height and ctx in public fields', 0, () => {
      const rc: RenderContext = makeRenderContext(466, 466);
      expect(rc.width).assertEqual(466);
      expect(rc.height).assertEqual(466);
      expect(rc.ctx !== null).assertEqual(true);
    });

    it('clear() paints a fillRect covering the whole viewport with the given color', 0, () => {
      const rc: RenderContext = makeRenderContext(800, 600);
      rc.clear('#1e1e1e');
      const ctx = rc.ctx as Object as StubCtx;
      expect(ctx.fillStyle).assertEqual('#1e1e1e');
      expect(ctx.fillRectCalls).assertEqual(1);
      expect(ctx.lastX).assertEqual(0);
      expect(ctx.lastY).assertEqual(0);
      expect(ctx.lastW).assertEqual(800);
      expect(ctx.lastH).assertEqual(600);
    });

    it('clear() defaults to "#000000"', 0, () => {
      const rc: RenderContext = makeRenderContext(100, 100);
      rc.clear();
      const ctx = rc.ctx as Object as StubCtx;
      expect(ctx.fillStyle).assertEqual('#000000');
    });

    it('clear() honors the color passed on each call (no persistence)', 0, () => {
      const rc: RenderContext = makeRenderContext(64, 64);
      rc.clear('#ff0000');
      rc.clear('#00ff00');
      const ctx = rc.ctx as Object as StubCtx;
      expect(ctx.fillStyle).assertEqual('#00ff00');
      expect(ctx.fillRectCalls).assertEqual(2);
    });

    it('two distinct RenderContext instances keep their ctx isolated', 0, () => {
      const a: RenderContext = makeRenderContext(10, 10);
      const b: RenderContext = makeRenderContext(20, 20);
      expect(a.ctx === b.ctx).assertEqual(false);
      a.clear('#aaa');
      const ctxB = b.ctx as Object as StubCtx;
      expect(ctxB.fillStyle).assertEqual('');
      expect(ctxB.fillRectCalls).assertEqual(0);
    });
  });
}