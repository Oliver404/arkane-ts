import { describe, it, expect } from '@ohos/hypium';
import { Entity } from '../main/ets/scene/Entity';
import { Sprite } from '../main/ets/render/Sprite';
import { Renderer2D } from '../main/ets/render/Renderer2D';
import { BoxCollider } from '../main/ets/physics/BoxCollider';
import { Transform } from '../main/ets/scene/Transform';
import { Vector2 } from '../main/ets/math/Vector2';
import { RenderContext } from '../main/ets/render/RenderContext';
import { Camera2D } from '../main/ets/render/Camera2D';

class CtxStub {
  fillStyle: string = '';
  fillRect(_x: number, _y: number, _w: number, _h: number): void {}
  save(): void {}
  restore(): void {}
  translate(_x: number, _y: number): void {}
  rotate(_a: number): void {}
  drawImage(_i: Object, _x: number, _y: number, _w: number, _h: number): void {}
  font: string = '';
  fillText(_t: string, _x: number, _y: number): void {}
}

function makeStubContext(): RenderContext {
  return new RenderContext(new CtxStub() as Object as CanvasRenderingContext2D, 800, 600);
}

class CameraStub extends Camera2D {
  constructor() {
    super(800, 600);
  }
}

function makeStubCamera(): Camera2D {
  return new CameraStub();
}

class RendererSpy implements Renderer2D {
  beginCalls: number = 0;
  drawCalls: number = 0;
  endCalls: number = 0;
  lastSprite?: Sprite;
  lastTransform?: Transform;
  lastCamera?: Camera2D;

  begin(context: RenderContext): void {
    this.beginCalls++;
  }

  drawSprite(
    sprite: Sprite,
    transform: Transform,
    camera?: Camera2D
  ): void {
    this.drawCalls++;
    this.lastSprite = sprite;
    this.lastTransform = transform;
    this.lastCamera = camera;
  }

  end(): void {
    this.endCalls++;
  }
}

export default function entityTest() {
  describe('Entity', () => {
    it('creates entity with no components: only transform is present (Scenario 1)', 0, () => {
      const e = new Entity();
      expect(e.transform).assertEqual(e.transform); // exists
      expect(e.transform).not().assertNull();
      expect(e.sprite).assertUndefined();
      expect(e.collider).assertUndefined();
    });

    it('assigns unique, monotonic IDs (Scenario 2)', 0, () => {
      const a = new Entity();
      const b = new Entity();
      const c = new Entity();
      expect(a.id).assertLess(b.id);
      expect(b.id).assertLess(c.id);
    });

    it('initial transform: position (0,0), scale (1,1), rotation 0 (Scenario 3)', 0, () => {
      const e = new Entity();
      expect(e.transform.position.x).assertEqual(0);
      expect(e.transform.position.y).assertEqual(0);
      expect(e.transform.scale.x).assertEqual(1);
      expect(e.transform.scale.y).assertEqual(1);
      expect(e.transform.rotation).assertEqual(0);
    });

    it('transform is independent between entities (Scenario 3)', 0, () => {
      const a = new Entity();
      const b = new Entity();
      a.transform.position.x = 42;
      expect(b.transform.position.x).assertEqual(0);
    });

    it('sprite and collider are assignable (Scenario 1)', 0, () => {
      const e = new Entity();
      e.sprite = new Sprite(10, 10, '#ff0000');
      e.setCollider(new BoxCollider(e.transform, 10, 10));
      expect(e.sprite).not().assertNull();
      expect(e.collider).not().assertNull();
    });

    it('update() is an empty hook: it does not mutate transform (HU-03)', 0, () => {
      const e = new Entity();
      e.transform.position = new Vector2(10, 20);
      e.update();
      expect(e.transform.position.x).assertEqual(10);
      expect(e.transform.position.y).assertEqual(20);
    });

    it('render() with sprite calls renderer.drawSprite(sprite, transform, camera)', 0, () => {
      const e = new Entity();
      const sprite = new Sprite(10, 20, '#ff0000');
      e.sprite = sprite;
      const ctx: RenderContext = makeStubContext();
      const cam: Camera2D = makeStubCamera();
      const renderer = new RendererSpy();
      e.render(ctx, renderer, cam);
      expect(renderer.drawCalls).assertEqual(1);
      expect(renderer.lastSprite).assertEqual(sprite);
      expect(renderer.lastTransform).assertEqual(e.transform);
      expect(renderer.lastCamera).assertEqual(cam);
    });

    it('render() without sprite is a no-op', 0, () => {
      const e = new Entity();
      const ctx: RenderContext = makeStubContext();
      const renderer = new RendererSpy();
      e.render(ctx, renderer);
      expect(renderer.drawCalls).assertEqual(0);
    });

    it('transform can receive an initial position via constructor', 0, () => {
      const t = new Transform(new Vector2(5, 5));
      expect(t.position.x).assertEqual(5);
      expect(t.position.y).assertEqual(5);
    });
  });
}
