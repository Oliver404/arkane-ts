// ExampleScene tests: configuration, mode, initial state and the
// win flow. The `onGameOver` callback is validated by forcing 5
// goals for P2 with the ball repositioned by hand. Since
// `ExampleScene` does not expose the `BallEntity` publicly, this
// test reaches the entities through the public `getEntities()` API.
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import {
  Camera2D,
  Engine,
  Entity,
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
import { ExampleScene, ExampleSceneConfig } from '../main/ets/pages/ExampleScene';
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

function makeEngine(): Engine {
  const e: Engine = new Engine();
  const rc: RenderContext = new RenderContext(new StubCtx() as Object as CanvasRenderingContext2D, 200, 200);
  e.setRenderer(new StubRenderer(), rc);
  return e;
}

function makeCamera(): Camera2D {
  const c: Camera2D = new Camera2D(200, 200);
  c.position = new Vector2(100, 100);
  return c;
}

function attachContext(engine: Engine, scene: ExampleScene): InputManager {
  const cam = makeCamera();
  const input = new InputManager();
  input.setCamera(cam);
  const ctx = new SceneContext(input, cam, new EventBus());
  scene.setContext(ctx);
  scene.setCamera(cam);
  return input;
}

function findBall(scene: ExampleScene): Entity | null {
  // The ball is the only entity with a CircleCollider (checked via
  // collider) and with a rigidbody. Build order: walls, paddles,
  // ball. We filter by the presence of a rigidbody + transform with
  // a collider carrying a `radius` property. Since the wall and
  // paddle entities have no rigidbody, looking for one with a
  // rigidbody is enough.
  for (const e of scene.getEntities()) {
    if (e.rigidbody !== undefined) {
      return e;
    }
  }
  return null;
}

export default function exampleSceneTest() {
  describe('ExampleScene - game mode', () => {
    let engine: Engine;

    beforeEach(() => {
      engine = makeEngine();
    });

    it('starts in pvp mode by default when no config is passed', 0, () => {
      let received: GameOverInfo | null = null;
      const cfg: ExampleSceneConfig = {
        mode: 'pvp',
        difficulty: 'medium',
        onGameOver: (i) => { received = i; }
      };
      const pong: ExampleScene = new ExampleScene(200, 200, cfg);
      engine.start(pong);
      attachContext(engine, pong);
      expect(pong.getMode()).assertEqual('pvp');
      expect(received).assertNull();
    });

    it('accepts mode=cpu and difficulty=hard without throwing', 0, () => {
      const cfg: ExampleSceneConfig = {
        mode: 'cpu',
        difficulty: 'hard',
        onGameOver: () => {}
      };
      const pong: ExampleScene = new ExampleScene(200, 200, cfg);
      engine.start(pong);
      attachContext(engine, pong);
      expect(pong.getMode()).assertEqual('cpu');
    });

    it('initial state: serve', 0, () => {
      const pong: ExampleScene = new ExampleScene(200, 200, {
        mode: 'pvp',
        difficulty: 'medium',
        onGameOver: () => {}
      });
      engine.start(pong);
      attachContext(engine, pong);
      expect(pong.getGameState()).assertEqual('serve');
    });
  });

  describe('ExampleScene - victory', () => {
    it('onGameOver fires once when P2 wins by 5-0', 0, () => {
      const engine2: Engine = makeEngine();
      let calls = 0;
      let last: GameOverInfo | null = null;
      const pong: ExampleScene = new ExampleScene(200, 200, {
        mode: 'pvp',
        difficulty: 'medium',
        onGameOver: (i) => {
          calls++;
          last = i;
        }
      });
      engine2.start(pong);
      const input: InputManager = attachContext(engine2, pong);
      const ball: Entity | null = findBall(pong);
      expect(ball !== null).assertTrue();

      // Serve: tap anywhere while in the serve state.
      input.updateTouches([new TouchInput(0, 0)]);
      engine2.updateForTest();
      // The ball is now in play.

      // Force 5 goals for P2: the ball enters through the left
      // goal (x < -halfW).
      for (let i = 0; i < 5; i++) {
        if (ball !== null) {
          ball.transform.position.x = -150;
          ball.transform.position.y = 0;
        }
        // The ball needs to "leave" the field: detectGoal's logic
        // does that on update. For the next goal to be counted, the
        // state goes back to 'serve' except on the last one.
        engine2.updateForTest();
        // After the goal we must serve again (except on the last one).
        if (i < 4) {
          input.updateTouches([new TouchInput(0, 0)]);
          engine2.updateForTest();
        }
      }

      expect(calls).assertEqual(1);
      expect(last).not().assertNull();
      expect(last!.winner).assertEqual('p2');
      expect(last!.p2Score).assertGreater(3);
      expect(last!.p1Score).assertEqual(0);
    });

    it('the state transitions to finished after the victory', 0, () => {
      const engine2: Engine = makeEngine();
      const pong: ExampleScene = new ExampleScene(200, 200, {
        mode: 'pvp',
        difficulty: 'medium',
        onGameOver: () => {}
      });
      engine2.start(pong);
      const input: InputManager = attachContext(engine2, pong);
      const ball: Entity | null = findBall(pong);
      // Serve
      input.updateTouches([new TouchInput(0, 0)]);
      engine2.updateForTest();
      // Force 4 goals in a row
      for (let i = 0; i < 4; i++) {
        if (ball !== null) {
          ball.transform.position.x = 150;
        }
        engine2.updateForTest();
        if (i < 3) {
          input.updateTouches([new TouchInput(0, 0)]);
          engine2.updateForTest();
        }
      }
      expect(pong.getGameState()).assertEqual('finished');
    });
  });
}
