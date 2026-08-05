// Hit-test and callback tests for MenuScene, DifficultyScene,
// OptionsScene and GameOverScene. Pattern: identity camera, real
// InputManager, manual TouchInput, Engine's updateForTest.
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import {
  Camera2D,
  Engine,
  EventBus,
  InputManager,
  RenderContext,
  Renderer2D,
  SceneContext,
  Sprite,
  TouchInput,
  Transform,
  Vector2
} from '@oliver404/arkane-ts';
import { MenuScene } from '../main/ets/pages/MenuScene';
import { DifficultyScene } from '../main/ets/pages/DifficultyScene';
import { OptionsScene } from '../main/ets/pages/OptionsScene';
import { GameOverScene } from '../main/ets/pages/GameOverScene';
import { GameOverInfo } from '../main/ets/pages/PongTypes';

class StubRenderer implements Renderer2D {
  begin(_context: RenderContext): void {}
  drawSprite(_sprite: Sprite, _transform: Transform, _camera?: Camera2D): void {}
  end(): void {}
}

class StubCtx {
  save(): void {}
  restore(): void {}
  fillText(_t: string, _x: number, _y: number): void {}
  fillRect(_x: number, _y: number, _w: number, _h: number): void {}
  beginPath(): void {}
  arc(_x: number, _y: number, _r: number, _a: number, _b: number): void {}
  fill(): void {}
  translate(_x: number, _y: number): void {}
  rotate(_a: number): void {}
  drawImage(_i: Object, _x: number, _y: number, _w: number, _h: number): void {}
}

function makeEngine(viewportW: number, viewportH: number): Engine {
  const e: Engine = new Engine();
  const rc: RenderContext = new RenderContext(new StubCtx() as Object as CanvasRenderingContext2D, viewportW, viewportH);
  e.setRenderer(new StubRenderer(), rc);
  return e;
}

function makeCamera(viewportW: number, viewportH: number): Camera2D {
  // Identity camera: world == screen.
  const c: Camera2D = new Camera2D(viewportW, viewportH);
  c.position = new Vector2(viewportW / 2, viewportH / 2);
  return c;
}

function attachContext(engine: Engine): InputManager {
  const scene = engine.getScene();
  if (scene === undefined) {
    throw new Error('no scene');
  }
  const cam = makeCamera(200, 200);
  const input = new InputManager();
  input.setCamera(cam);
  const ctx = new SceneContext(input, cam, new EventBus());
  scene.setContext(ctx);
  scene.setCamera(cam);
  return input;
}

export default function menuSceneTest() {
  describe('MenuScene', () => {
    let engine: Engine;
    let input: InputManager;

    beforeEach(() => {
      engine = makeEngine(200, 200);
    });

    it('vs Computer fires the matching callback', 0, () => {
      let called = '';
      const menu: MenuScene = new MenuScene(200, 200, {
        onVsComputer: () => { called = 'cpu'; },
        onVsPlayer: () => { called = 'pvp'; },
        onOptions: () => { called = 'opts'; }
      });
      engine.start(menu);
      input = attachContext(engine);
      // The "vs Computer" button is at (0, 0), size 110x28 (scale=1).
      // A tap at (0, 0) falls inside.
      input.updateTouches([new TouchInput(0, 0)]);
      engine.updateForTest();
      // Second frame with empty touches: it must not re-fire.
      input.updateTouches([]);
      engine.updateForTest();
      expect(called).assertEqual('cpu');
    });

    it('vs Player fires its callback', 0, () => {
      let called = '';
      const menu: MenuScene = new MenuScene(200, 200, {
        onVsComputer: () => { called = 'cpu'; },
        onVsPlayer: () => { called = 'pvp'; },
        onOptions: () => { called = 'opts'; }
      });
      engine.start(menu);
      input = attachContext(engine);
      // vs Player is at y = 0 + 28 + 12 = 40.
      input.updateTouches([new TouchInput(0, 40)]);
      engine.updateForTest();
      expect(called).assertEqual('pvp');
    });

    it('tap outside the buttons fires nothing', 0, () => {
      let called = '';
      const menu: MenuScene = new MenuScene(200, 200, {
        onVsComputer: () => { called = 'cpu'; },
        onVsPlayer: () => { called = 'pvp'; },
        onOptions: () => { called = 'opts'; }
      });
      engine.start(menu);
      input = attachContext(engine);
      input.updateTouches([new TouchInput(150, 150)]);
      engine.updateForTest();
      expect(called).assertEqual('');
    });
  });

  describe('DifficultyScene', () => {
    let engine: Engine;
    let input: InputManager;

    beforeEach(() => {
      engine = makeEngine(200, 200);
    });

    it('starts with the provided level', 0, () => {
      const diff: DifficultyScene = new DifficultyScene(200, 200, 'hard', {
        onPlay: () => {},
        onBack: () => {}
      });
      expect(diff.getLevel()).assertEqual('hard');
    });

    it('the right arrow cycles easy -> medium -> hard -> easy', 0, () => {
      const diff: DifficultyScene = new DifficultyScene(200, 200, 'easy', {
        onPlay: () => {},
        onBack: () => {}
      });
      engine.start(diff);
      input = attachContext(engine);
      // ▶ is at (55, -15) (in world, viewport 200x200 center=100,100)
      // x = 100 + 55 = 155 on screen. Tap there.
      input.updateTouches([new TouchInput(155, 85)]);
      engine.updateForTest();
      expect(diff.getLevel()).assertEqual('medium');
      input.updateTouches([new TouchInput(155, 85)]);
      engine.updateForTest();
      expect(diff.getLevel()).assertEqual('hard');
      input.updateTouches([new TouchInput(155, 85)]);
      engine.updateForTest();
      expect(diff.getLevel()).assertEqual('easy');
    });

    it('the left arrow cycles backwards with wrap-around', 0, () => {
      const diff: DifficultyScene = new DifficultyScene(200, 200, 'easy', {
        onPlay: () => {},
        onBack: () => {}
      });
      engine.start(diff);
      input = attachContext(engine);
      // ◀ at (-55, -15) in world -> screen (45, 85).
      input.updateTouches([new TouchInput(45, 85)]);
      engine.updateForTest();
      expect(diff.getLevel()).assertEqual('hard');
    });

    it('Play invokes onPlay with the current level', 0, () => {
      let received = '';
      const diff: DifficultyScene = new DifficultyScene(200, 200, 'medium', {
        onPlay: (d) => { received = d; },
        onBack: () => {}
      });
      engine.start(diff);
      input = attachContext(engine);
      // Play is at (0, 45) in world -> screen (100, 145).
      input.updateTouches([new TouchInput(100, 145)]);
      engine.updateForTest();
      expect(received).assertEqual('medium');
    });

    it('Back invokes onBack', 0, () => {
      let back = false;
      const diff: DifficultyScene = new DifficultyScene(200, 200, 'medium', {
        onPlay: () => {},
        onBack: () => { back = true; }
      });
      engine.start(diff);
      input = attachContext(engine);
      // Back is at (0, 45+26+10) in world = (0, 81) -> screen (100, 181).
      input.updateTouches([new TouchInput(100, 181)]);
      engine.updateForTest();
      expect(back).assertTrue();
    });
  });

  describe('OptionsScene', () => {
    it('Back invokes the callback', 0, () => {
      const engine2: Engine = makeEngine(200, 200);
      let back = false;
      const opts: OptionsScene = new OptionsScene(200, 200, () => {
        back = true;
      });
      engine2.start(opts);
      const input: InputManager = attachContext(engine2);
      // Back at (0, 40) in world -> screen (100, 140).
      input.updateTouches([new TouchInput(100, 140)]);
      engine2.updateForTest();
      expect(back).assertTrue();
    });
  });

  describe('GameOverScene', () => {
    it('Rematch invokes onRematch with the match info', 0, () => {
      const engine2: Engine = makeEngine(200, 200);
      let rematch = false;
      const info: GameOverInfo = {
        winner: 'p1',
        p1Score: 4,
        p2Score: 2,
        mode: 'pvp',
        difficulty: null
      };
      const over: GameOverScene = new GameOverScene(200, 200, info, {
        onRematch: () => { rematch = true; },
        onMenu: () => {}
      });
      engine2.start(over);
      const input: InputManager = attachContext(engine2);
      // Rematch at (0, 35) -> screen (100, 135).
      input.updateTouches([new TouchInput(100, 135)]);
      engine2.updateForTest();
      expect(rematch).assertTrue();
    });

    it('Menu invokes onMenu', 0, () => {
      const engine2: Engine = makeEngine(200, 200);
      let menuCalled = false;
      const info: GameOverInfo = {
        winner: 'p2',
        p1Score: 2,
        p2Score: 4,
        mode: 'cpu',
        difficulty: 'hard'
      };
      const over: GameOverScene = new GameOverScene(200, 200, info, {
        onRematch: () => {},
        onMenu: () => { menuCalled = true; }
      });
      engine2.start(over);
      const input: InputManager = attachContext(engine2);
      // Menu at (0, 35+26+10) = (0, 71) -> screen (100, 171).
      input.updateTouches([new TouchInput(100, 171)]);
      engine2.updateForTest();
      expect(menuCalled).assertTrue();
    });

    it('getInfo returns the GameOverInfo used to construct', 0, () => {
      const info: GameOverInfo = {
        winner: 'p1',
        p1Score: 4,
        p2Score: 1,
        mode: 'cpu',
        difficulty: 'easy'
      };
      const over: GameOverScene = new GameOverScene(200, 200, info, {
        onRematch: () => {},
        onMenu: () => {}
      });
      expect(over.getInfo().winner).assertEqual('p1');
      expect(over.getInfo().difficulty).assertEqual('easy');
    });
  });
}
