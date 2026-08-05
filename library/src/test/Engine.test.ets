// Source: /Users/oliverbotello/development/Oliver404/arkane-ts/.infO404/docs/features/registerSystem/registerSystem.feature
// Feature: Register custom systems at GameLoop hooks
// Scenarios: Register a system via the public Engine API; beforeUpdate hook runs before the main update phase; afterUpdate hook runs after the main update phase; Hooks are optional; Hooks are optional (other direction); Multiple systems run in deterministic registration order
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { Engine, GameSystem } from '../main/ets/core/Engine';
import { Scene2D } from '../main/ets/scene/Scene2D';
import { RenderContext } from '../main/ets/render/RenderContext';
import { Renderer2D } from '../main/ets/render/Renderer2D';
import { Sprite } from '../main/ets/render/Sprite';
import { Transform } from '../main/ets/scene/Transform';
import { Camera2D } from '../main/ets/render/Camera2D';

class RecordingScene extends Scene2D {
  private order: string[];
  public exited: boolean = false;
  public entered: boolean = false;
  public contextInjected: boolean = false;

  constructor(order: string[]) {
    super();
    this.order = order;
  }

  onEnter(): void {
    this.entered = true;
    if (this.context !== undefined) {
      this.contextInjected = true;
    }
  }

  onExit(): void {
    this.exited = true;
  }

  update(): void {
    this.order.push('scene.update');
  }
}

class RecordingSystem implements GameSystem {
  private order: string[];
  private beforeName?: string;
  private afterName?: string;

  constructor(order: string[], beforeName?: string, afterName?: string) {
    this.order = order;
    this.beforeName = beforeName;
    this.afterName = afterName;
  }

  beforeUpdate(): void {
    if (this.beforeName !== undefined) {
      this.order.push(this.beforeName);
    }
  }

  afterUpdate(): void {
    if (this.afterName !== undefined) {
      this.order.push(this.afterName);
    }
  }
}

class BeforeOnlySystem implements GameSystem {
  called: boolean = false;

  beforeUpdate(): void {
    this.called = true;
  }
}

class AfterOnlySystem implements GameSystem {
  called: boolean = false;

  afterUpdate(): void {
    this.called = true;
  }
}

export default function engineTest() {
  describe('Engine registerSystem (HU-08)', () => {
    let engine: Engine;
    let order: string[];

    beforeEach(() => {
      engine = new Engine();
      order = [];
    });

    it('registers the system against the engine instance without throwing errors (Scenario 1)', 0, () => {
      const system = new RecordingSystem(order);
      engine.registerSystem(system);
      expect(true).assertTrue();
    });

    it('runs beforeUpdate before scene.update (Scenario 2)', 0, () => {
      const system = new RecordingSystem(order, 'system.beforeUpdate');
      const scene = new RecordingScene(order);
      engine.registerSystem(system);
      engine.setTestScene(scene);
      engine.updateForTest();

      expect(order[0]).assertEqual('system.beforeUpdate');
      expect(order[1]).assertEqual('scene.update');
    });

    it('runs afterUpdate after scene.update (Scenario 3)', 0, () => {
      const system = new RecordingSystem(order, undefined, 'system.afterUpdate');
      const scene = new RecordingScene(order);
      engine.registerSystem(system);
      engine.setTestScene(scene);
      engine.updateForTest();

      expect(order[0]).assertEqual('scene.update');
      expect(order[1]).assertEqual('system.afterUpdate');
    });

    it('registers and runs a system that only implements beforeUpdate without requiring afterUpdate (Scenario 4)', 0, () => {
      const system = new BeforeOnlySystem();
      engine.registerSystem(system);
      engine.setTestScene(new RecordingScene(order));
      engine.updateForTest();

      expect(system.called).assertTrue();
    });

    it('registers and runs a system that only implements afterUpdate without requiring beforeUpdate (Scenario 5)', 0, () => {
      const system = new AfterOnlySystem();
      engine.registerSystem(system);
      engine.setTestScene(new RecordingScene(order));
      engine.updateForTest();

      expect(system.called).assertTrue();
    });

    it('runs the hooks of multiple systems in registration order (Scenario 6)', 0, () => {
      const first = new RecordingSystem(order, 'first.beforeUpdate', 'first.afterUpdate');
      const second = new RecordingSystem(order, 'second.beforeUpdate', 'second.afterUpdate');
      engine.registerSystem(first);
      engine.registerSystem(second);
      engine.setTestScene(new RecordingScene(order));
      engine.updateForTest();

      expect(order[0]).assertEqual('first.beforeUpdate');
      expect(order[1]).assertEqual('second.beforeUpdate');
      expect(order[2]).assertEqual('scene.update');
      expect(order[3]).assertEqual('first.afterUpdate');
      expect(order[4]).assertEqual('second.afterUpdate');
    });

    it('setScene calls onExit on the previous scene and onEnter on the new one', 0, () => {
      const first = new RecordingScene(order);
      const second = new RecordingScene(order);
      engine.setTestScene(first);
      // first already got onEnter via setTestScene. setScene should
      // fire first.onExit and second.onEnter.
      engine.setScene(second);

      expect(first.exited).assertTrue();
      expect(second.entered).assertTrue();
    });

    it('setScene injects the existing SceneContext into the new scene', 0, () => {
      // We create a full engine with a renderer so that
      // sceneContext quede configurado.
      const e2 = new Engine();
      const fakeCtx: Object = new Object();
      const rc: RenderContext = new RenderContext(fakeCtx as Object as CanvasRenderingContext2D, 100, 100);
      e2.setRenderer(new StubRenderer(), rc);
      const initial: RecordingScene = new RecordingScene(order);
      e2.start(initial);

      const next: RecordingScene = new RecordingScene(order);
      e2.setScene(next);

      expect(next.contextInjected).assertTrue();
    });
  });
}

class StubRenderer implements Renderer2D {
  begin(_context: RenderContext): void {}
  drawSprite(_sprite: Sprite, _transform: Transform, _camera?: Camera2D): void {}
  end(): void {}
}
