/**
 * Source feature: .infO404/docs/features/apiCompatibility/apiCompatibility.feature (HU-09)
 * Scenarios covered: each public module has at least one unit test (Scenario 4)
 * Target symbol: TextEntity
 */
import { describe, it, expect } from '@ohos/hypium';
import { TextEntity } from '../main/ets/render/TextEntity';
import { Camera2D } from '../main/ets/render/Camera2D';
import { RenderContext } from '../main/ets/render/RenderContext';
import { Renderer2D } from '../main/ets/render/Renderer2D';
import { Sprite } from '../main/ets/render/Sprite';
import { Transform } from '../main/ets/scene/Transform';

class StubCtx {
  savedCount: number = 0;
  restoredCount: number = 0;
  font: string = '';
  fillStyle: string = '';
  textAlign: string = '';
  textBaseline: string = '';
  text: string = '';
  textX: number = -1;
  textY: number = -1;
  save(): void { this.savedCount++; }
  restore(): void { this.restoredCount++; }
  fillText(text: string, x: number, y: number): void {
    this.text = text;
    this.textX = x;
    this.textY = y;
  }
}

class StubRenderer implements Renderer2D {
  begin(_context: RenderContext): void {}
  drawSprite(_sprite: Sprite, _transform: Transform, _camera?: Camera2D): void {}
  end(): void {}
}

function makeCtx(): Object {
  return new StubCtx();
}

function makeRenderContext(): RenderContext {
  return new RenderContext(makeCtx() as Object as CanvasRenderingContext2D, 466, 466);
}

export default function textEntityTest() {
  describe('TextEntity', () => {
    it('setText updates the rendered text', 0, () => {
      const e: TextEntity = new TextEntity('hola');
      e.setText('adios');
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.text).assertEqual('adios');
    });

    it('wraps the operation with save/restore', 0, () => {
      const e: TextEntity = new TextEntity('x');
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.savedCount).assertEqual(1);
      expect(ctx.restoredCount).assertEqual(1);
    });

    it('sets font with the configured size and family', 0, () => {
      const e: TextEntity = new TextEntity('x');
      e.setFontFamily('Helvetica');
      e.setFontSize(32);
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.font.indexOf('32') >= 0).assertEqual(true);
      expect(ctx.font.indexOf('Helvetica') >= 0).assertEqual(true);
    });

    it('sets fillStyle with the configured color', 0, () => {
      const e: TextEntity = new TextEntity('x');
      e.setColor('#ff00ff');
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.fillStyle).assertEqual('#ff00ff');
    });

    it('applies camera.worldToScreen to the position when a camera is present', 0, () => {
      const cam: Camera2D = new Camera2D(466, 466);
      cam.position.x = 10;
      cam.position.y = -5;
      const e: TextEntity = new TextEntity('x');
      e.transform.position.x = 25;
      e.transform.position.y = 12;
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer(), cam);
      const screen = cam.worldToScreen(e.transform.position);
      expect(ctx.textX).assertClose(screen.x, 1e-9);
      expect(ctx.textY).assertClose(screen.y, 1e-9);
    });

    it('uses the direct position when there is NO camera', 0, () => {
      const e: TextEntity = new TextEntity('x');
      e.transform.position.x = 17;
      e.transform.position.y = -23;
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.textX).assertEqual(17);
      expect(ctx.textY).assertEqual(-23);
    });

    it('setTextAlign propagates the value to context.textAlign', 0, () => {
      const e: TextEntity = new TextEntity('x');
      e.setTextAlign('center');
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.textAlign).assertEqual('center');
    });

    it('setTextBaseline propagates the value to context.textBaseline', 0, () => {
      const e: TextEntity = new TextEntity('x');
      e.setTextBaseline('middle');
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.textBaseline).assertEqual('middle');
    });

    it('defaults: textAlign=start and textBaseline=alphabetic', 0, () => {
      const e: TextEntity = new TextEntity('x');
      const rc: RenderContext = makeRenderContext();
      const ctx = rc.ctx as Object as StubCtx;
      e.render(rc, new StubRenderer());
      expect(ctx.textAlign).assertEqual('start');
      expect(ctx.textBaseline).assertEqual('alphabetic');
    });
  });
}