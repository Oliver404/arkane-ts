import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { Scene2D } from '../main/ets/scene/Scene2D';
import { Entity } from '../main/ets/scene/Entity';
import { Renderer2D } from '../main/ets/render/Renderer2D';
import { Camera2D } from '../main/ets/render/Camera2D';
import { RenderContext } from '../main/ets/render/RenderContext';
import { Vector2 } from '../main/ets/math/Vector2';
import { Sprite } from '../main/ets/render/Sprite';
import { Transform } from '../main/ets/scene/Transform';

class TestEntity extends Entity {
  updateCalls: number = 0;
  renderCalls: number = 0;
  lastRenderContext?: RenderContext;
  lastRenderRenderer?: Renderer2D;
  lastRenderCamera?: Camera2D;

  update(): void {
    this.updateCalls++;
  }

  render(
    context: RenderContext,
    renderer: Renderer2D,
    camera?: Camera2D
  ): void {
    this.renderCalls++;
    this.lastRenderContext = context;
    this.lastRenderRenderer = renderer;
    this.lastRenderCamera = camera;
  }
}

class TestScene extends Scene2D {
  onEnterCalls: number = 0;
  onEnter(): void {
    this.onEnterCalls++;
  }
}

class GravityScene extends Scene2D {
  onEnter(): void {
    this.gravity = new Vector2(0, -9.8);
  }
}

class CustomGravityScene extends Scene2D {
  onEnter(): void {
    this.gravity = new Vector2(0, -3.7);
  }
}

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

class FakeRenderer implements Renderer2D {
  beginCalls: number = 0;
  drawCalls: number = 0;
  endCalls: number = 0;

  begin(_context: RenderContext): void {
    this.beginCalls++;
  }

  drawSprite(
    _sprite: Sprite,
    _transform: Transform,
    _camera?: Camera2D
  ): void {
    this.drawCalls++;
  }

  end(): void {
    this.endCalls++;
  }
}

export default function scene2DTest() {
  describe('Scene2D', () => {
    let scene: TestScene;

    beforeEach(() => {
      scene = new TestScene();
    });

    it('default gravity is Vector2(0, -9.8)', 0, () => {
      const s = new TestScene();
      expect(s.gravity.x).assertEqual(0);
      expect(s.gravity.y).assertEqual(-9.8);
    });

    it('onEnter is abstract and can be implemented (Scenario 1 contract)', 0, () => {
      scene.onEnter();
      expect(scene.onEnterCalls).assertEqual(1);
      scene.onEnter();
      expect(scene.onEnterCalls).assertEqual(2);
    });

    it('onEnter can assign custom gravity (Scenario 4)', 0, () => {
      const s = new GravityScene();
      // Default gravity is Vector2(0, -9.8); onEnter overrides it with the
      // same value, so the visible state before/after is identical.
      expect(s.gravity.y).assertEqual(-9.8);
      s.onEnter();
      expect(s.gravity.x).assertEqual(0);
      expect(s.gravity.y).assertEqual(-9.8);
    });

    it('onEnter can assign any custom gravity value (Scenario 4)', 0, () => {
      const s = new CustomGravityScene();
      s.onEnter();
      expect(s.gravity.y).assertEqual(-3.7);
    });

    it('update iterates entities in insertion order (Scenario 2)', 0, () => {
      const e1 = new TestEntity();
      const e2 = new TestEntity();
      const e3 = new TestEntity();
      scene.addEntity(e1);
      scene.addEntity(e2);
      scene.addEntity(e3);

      scene.update();

      expect(e1.updateCalls).assertEqual(1);
      expect(e2.updateCalls).assertEqual(1);
      expect(e3.updateCalls).assertEqual(1);
    });

    it('update on empty scene is a no-op', 0, () => {
      scene.update();
      // No exception means success.
    });

    it('render delegates to each entity (Scenario 3)', 0, () => {
      const e1 = new TestEntity();
      const e2 = new TestEntity();
      scene.addEntity(e1);
      scene.addEntity(e2);

      const ctx: RenderContext = makeStubContext();
      const cam: Camera2D = makeStubCamera();
      const renderer = new FakeRenderer();
      scene.setCamera(cam);

      scene.render(ctx, renderer);

      expect(e1.renderCalls).assertEqual(1);
      expect(e2.renderCalls).assertEqual(1);
      expect(e1.lastRenderRenderer).assertEqual(renderer);
      expect(e2.lastRenderRenderer).assertEqual(renderer);
      expect(e1.lastRenderCamera).assertEqual(cam);
      expect(e2.lastRenderCamera).assertEqual(cam);
    });

    it('render on empty scene is a no-op', 0, () => {
      const ctx: RenderContext = makeStubContext();
      const renderer = new FakeRenderer();
      scene.render(ctx, renderer);
      // No exception means success.
    });

    it('removeEntity drops the entity from the iteration', 0, () => {
      const e1 = new TestEntity();
      const e2 = new TestEntity();
      scene.addEntity(e1);
      scene.addEntity(e2);
      expect(scene.entityCount()).assertEqual(2);

      scene.removeEntity(e1);
      expect(scene.entityCount()).assertEqual(1);

      scene.update();
      expect(e1.updateCalls).assertEqual(0);
      expect(e2.updateCalls).assertEqual(1);
    });

    it('removeEntity on unknown entity is a no-op', 0, () => {
      const e1 = new TestEntity();
      const stranger = new TestEntity();
      scene.addEntity(e1);
      scene.removeEntity(stranger);
      expect(scene.entityCount()).assertEqual(1);
    });

    it('onExit default is no-op (HU-04 contract)', 0, () => {
      const s = new TestScene();
      s.onExit();
      // No exception means success.
    });
  });
}
