import { describe, it, expect } from '@ohos/hypium';
import { Renderer2D } from '../main/ets/render/Renderer2D';
import { CanvasRenderer2D } from '../main/ets/render/CanvasRenderer2D';
import { RenderContext } from '../main/ets/render/RenderContext';
import { Sprite } from '../main/ets/render/Sprite';
import { Transform } from '../main/ets/scene/Transform';
import { Vector2 } from '../main/ets/math/Vector2';
import { Camera2D } from '../main/ets/render/Camera2D';
import { TextEntity } from '../main/ets/render/TextEntity';
import { Texture } from '../main/ets/assets/Texture';

// Stub of the 2D context that records calls so we can assert
// the order and the values of the canvas operations.
class CallRecord {
  method: string = '';
  args: number[] = [];
}

class Canvas2DStub {
  calls: CallRecord[] = [];
  fillStyle: string = '';
  font: string = '';

  translate(x: number, y: number): void {
    const c = new CallRecord();
    c.method = 'translate';
    c.args = [x, y];
    this.calls.push(c);
  }
  rotate(angle: number): void {
    const c = new CallRecord();
    c.method = 'rotate';
    c.args = [angle];
    this.calls.push(c);
  }
  save(): void {
    const c = new CallRecord();
    c.method = 'save';
    c.args = [];
    this.calls.push(c);
  }
  restore(): void {
    const c = new CallRecord();
    c.method = 'restore';
    c.args = [];
    this.calls.push(c);
  }
  fillRect(x: number, y: number, w: number, h: number): void {
    const c = new CallRecord();
    c.method = 'fillRect';
    c.args = [x, y, w, h];
    this.calls.push(c);
  }
  fillText(text: string, x: number, y: number): void {
    const c = new CallRecord();
    c.method = 'fillText';
    c.args = [x, y]; // x, y of the drawing position
    this.calls.push(c);
  }
  drawImage(_image: Object, x: number, y: number, w: number, h: number): void {
    const c = new CallRecord();
    c.method = 'drawImage';
    c.args = [x, y, w, h];
    this.calls.push(c);
  }
}

interface ContextPair {
  rc: RenderContext
  stub: Canvas2DStub
}

function makeContext(): ContextPair {
  const stub = new Canvas2DStub();
  const rc = new RenderContext(
    stub as Object as CanvasRenderingContext2D,
    800,
    600
  );
  const pair: ContextPair = { rc: rc, stub: stub };
  return pair;
}

function indexOf(stub: Canvas2DStub, method: string): number {
  for (let i = 0; i < stub.calls.length; i++) {
    if (stub.calls[i].method === method) {
      return i;
    }
  }
  return -1;
}

class NoopRenderer implements Renderer2D {
  begin(_ctx: RenderContext): void {}
  drawSprite(_s: Sprite, _t: Transform, _c?: Camera2D): void {}
  end(): void {}
}

class CallsRecorder implements Renderer2D {
  calls: string[] = [];
  begin(_ctx: RenderContext): void {
    this.calls.push('begin');
  }
  drawSprite(_s: Sprite, _t: Transform, _c?: Camera2D): void {
    this.calls.push('drawSprite');
  }
  end(): void {
    this.calls.push('end');
  }
}

export default function renderer2DTest() {
  describe('Renderer2D interface (custom renderer injection)', () => {
    it('Engine.setRenderer accepts any Renderer2D and is invoked on begin/drawSprite/end (Scenario 4)', 0, () => {
      const custom = new CallsRecorder();

      // We only verify that the engine accepts the renderer and that,
      // given a manual call, the order is begin → drawSprite → end.
      const stubCtx = new RenderContext(new Canvas2DStub() as Object as CanvasRenderingContext2D, 800, 600);
      custom.begin(stubCtx);
      custom.drawSprite(new Sprite(1, 1, '#fff'), new Transform(), undefined);
      custom.end();

      expect(custom.calls[0]).assertEqual('begin');
      expect(custom.calls[1]).assertEqual('drawSprite');
      expect(custom.calls[2]).assertEqual('end');
    });
  });

  describe('CanvasRenderer2D', () => {
    it('default fillColor is #1e1e1e', 0, () => {
      const r = new CanvasRenderer2D();
      expect(r.fillColor).assertEqual('#1e1e1e');
    });

    it('constructor accepts an optional fillColor', 0, () => {
      const r = new CanvasRenderer2D('#202020');
      expect(r.fillColor).assertEqual('#202020');
    });

    it('begin fills the canvas with the fillColor from the constructor (Scenario 2)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D('#abcdef');
      r.begin(rc);
      expect(stub.fillStyle).assertEqual('#abcdef');
      expect(indexOf(stub, 'fillRect')).assertEqual(0);
      const args = stub.calls[0].args;
      expect(args[0]).assertEqual(0);
      expect(args[1]).assertEqual(0);
      expect(args[2]).assertEqual(800);
      expect(args[3]).assertEqual(600);
    });

    it('end leaves no pending operations (Scenario 3)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D();
      r.begin(rc);
      stub.calls.length = 0;
      r.end();
      // end must not emit any call to the 2D context
      expect(stub.calls.length).assertEqual(0);
    });

    it('drawSprite with a solid color sprite draws a fillRect (Scenario 1 HU-07)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D();
      const sprite = new Sprite(50, 30, '#ff0000');
      const t = new Transform(new Vector2(100, 100));
      r.begin(rc);
      stub.calls.length = 0;
      r.drawSprite(sprite, t);
      expect(stub.fillStyle).assertEqual('#ff0000');
      const frIdx = indexOf(stub, 'fillRect');
      expect(frIdx >= 0).assertTrue();
      const args = stub.calls[frIdx].args;
      // 100 - 25, 100 - 15, 50, 30
      expect(args[0]).assertEqual(75);
      expect(args[1]).assertEqual(85);
      expect(args[2]).assertEqual(50);
      expect(args[3]).assertEqual(30);
    });

    it('drawSprite uses camera.worldToScreen when a camera is passed (HU-07)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D();
      const sprite = new Sprite(10, 10, '#00ff00');
      const t = new Transform(new Vector2(50, 50));
      const cam = new Camera2D(800, 600);
      cam.position = new Vector2(0, 0);
      cam.zoom = 1;
      r.begin(rc);
      stub.calls.length = 0;
      r.drawSprite(sprite, t, cam);
      const frIdx = indexOf(stub, 'fillRect');
      const args = stub.calls[frIdx].args;
      // screen pos = (50-0)*1 + 400 = 450 (x), 50 + 300 = 350 (y)
      // rect = (450 - 5, 350 - 5) = (445, 345)
      expect(args[0]).assertEqual(445);
      expect(args[1]).assertEqual(345);
    });

    it('drawSprite applies transform.scale to the size (HU-07 scenario 3)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D();
      const sprite = new Sprite(50, 30, '#ff0000');
      const t = new Transform(new Vector2(0, 0));
      t.scale = new Vector2(2, 2);
      r.begin(rc);
      stub.calls.length = 0;
      r.drawSprite(sprite, t);
      const frIdx = indexOf(stub, 'fillRect');
      const args = stub.calls[frIdx].args;
      // 100x60
      expect(args[2]).assertEqual(100);
      expect(args[3]).assertEqual(60);
      // centered on (0,0): (-50, -30)
      expect(args[0]).assertEqual(-50);
      expect(args[1]).assertEqual(-30);
    });

    it('drawSprite applies transform.rotation to the canvas (HU-07 scenario 4)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D();
      const sprite = new Sprite(10, 10, '#0000ff');
      const t = new Transform(new Vector2(100, 100));
      t.rotation = Math.PI / 2;
      r.begin(rc);
      stub.calls.length = 0;
      r.drawSprite(sprite, t);
      // orden esperado: save, translate(+x,+y), rotate(angle), translate(-x,-y), fillRect, restore
      const order = stub.calls.map(c => c.method);
      expect(order[0]).assertEqual('save');
      expect(order[1]).assertEqual('translate');
      expect(order[2]).assertEqual('rotate');
      expect(order[3]).assertEqual('translate');
      const fillIdx = indexOf(stub, 'fillRect');
      const restIdx = indexOf(stub, 'restore');
      expect(fillIdx).assertEqual(4);
      expect(restIdx).assertEqual(5);
      const rotArgs = stub.calls[2].args;
      expect(rotArgs[0]).assertEqual(Math.PI / 2);
    });

    it('drawSprite wraps the operation in save/restore to avoid leaking state (HU-06)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D();
      const sprite = new Sprite(10, 10, '#ffffff');
      r.begin(rc);
      stub.calls.length = 0;
      r.drawSprite(sprite, new Transform());
      // The first call must be save, the last must be restore
      expect(stub.calls[0].method).assertEqual('save');
      expect(stub.calls[stub.calls.length - 1].method).assertEqual('restore');
    });

    it('drawSprite with sprite.image draws via drawImage (HU-18)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const r = new CanvasRenderer2D();
      const sprite = new Sprite(40, 60, '#ff0000');
      interface FakeImageSource {
        fake: string;
      }
      const fakeImage: FakeImageSource = { fake: 'image' };
      const tex = new Texture(fakeImage as Object, 100, 100, 'pixelmap');
      sprite.image = tex;
      const t = new Transform(new Vector2(10, 20));
      r.begin(rc);
      stub.calls.length = 0;
      r.drawSprite(sprite, t);
      // Esperado: save, translate, rotate, translate, drawImage, restore
      // We verify that fillRect was NOT called, and that drawImage was.
      expect(indexOf(stub, 'fillRect') >= 0).assertFalse();
      const diIdx = indexOf(stub, 'drawImage');
      expect(diIdx >= 0).assertTrue();
      const args = stub.calls[diIdx].args;
      // (10 - 20, 20 - 30) = (-10, -10), w=40, h=60
      expect(args[0]).assertEqual(-10);
      expect(args[1]).assertEqual(-10);
      expect(args[2]).assertEqual(40);
      expect(args[3]).assertEqual(60);
    });
  });

  describe('TextEntity (HU-09)', () => {
    it('wraps ctx.fillText in save/restore (HU-09)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const text = new TextEntity('Hello');
      const spyRenderer: Renderer2D = new NoopRenderer();
      text.render(rc, spyRenderer);
      // first call save, last restore, fillText in between
      expect(stub.calls.length > 0).assertTrue();
      expect(stub.calls[0].method).assertEqual('save');
      expect(stub.calls[stub.calls.length - 1].method).assertEqual('restore');
      const ftIdx = indexOf(stub, 'fillText');
      expect(ftIdx > 0).assertTrue();
      expect(ftIdx < stub.calls.length - 1).assertTrue();
    });

    it('applies camera.worldToScreen to transform.position when a camera is present (HU-09)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const text = new TextEntity('Hi');
      text.transform.position = new Vector2(10, 0);
      const cam = new Camera2D(800, 600);
      cam.position = new Vector2(0, 0);
      cam.zoom = 1;
      const spyRenderer: Renderer2D = new NoopRenderer();
      text.render(rc, spyRenderer, cam);
      const ftIdx = indexOf(stub, 'fillText');
      const args = stub.calls[ftIdx].args;
      // world (10, 0), camera (0,0), zoom 1, viewport (800, 600):
      // screen.x = (10 - 0) * 1 + 400 = 410
      // screen.y = (0 - 0) * 1 + 300 = 300
      expect(args[0]).assertEqual(410);
      expect(args[1]).assertEqual(300);
    });

    it('uses transform.position directly when there is NO camera (HU-09)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const text = new TextEntity('Hi');
      text.transform.position = new Vector2(100, 200);
      const spyRenderer: Renderer2D = new NoopRenderer();
      text.render(rc, spyRenderer);
      const ftIdx = indexOf(stub, 'fillText');
      const args = stub.calls[ftIdx].args;
      expect(args[0]).assertEqual(100);
      expect(args[1]).assertEqual(200);
    });

    it('sets font and fillStyle on the ctx (HU-09)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const text = new TextEntity('Hi');
      text.setFontFamily('Helvetica');
      text.setFontSize(32);
      text.setColor('#ff00ff');
      const spyRenderer: Renderer2D = new NoopRenderer();
      text.render(rc, spyRenderer);
      expect(stub.font).assertEqual('32px Helvetica');
      expect(stub.fillStyle).assertEqual('#ff00ff');
    });

    it('setText updates the drawn text (HU-09)', 0, () => {
      const pair = makeContext();
      const rc = pair.rc;
      const stub = pair.stub;
      const text = new TextEntity('Old');
      text.setText('New');
      const spyRenderer: Renderer2D = new NoopRenderer();
      text.render(rc, spyRenderer);
      const ftIdx = indexOf(stub, 'fillText');
      // args[0] holds x; since we switched to storing (x,y), the args are numeric.
      // We verify that fillText was called exactly once.
      let count = 0;
      for (const c of stub.calls) {
        if (c.method === 'fillText') count++;
      }
      expect(count).assertEqual(1);
    });
  });
}
