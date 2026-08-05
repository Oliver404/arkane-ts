// Index.ets — entry point of the "2-player Pong" example.
//
//   • Detects the physical screen size with
//     `display.getDefaultDisplaySync()` and uses it as the viewport
//     (world and render). Works on wearable 466x466, phones, tablets, etc.
//   • Creates the Engine, the CanvasRenderer2D, the RenderContext and
//     registers PhysicsSystem so the simulation runs every frame.
//   • Starts with `MenuScene` and delegates the navigation callbacks
//     to each scene. To change scenes it uses `engine.setScene`, which
//     invokes `onExit` on the previous one and `onEnter` on the new one.
//   • Converts ArkUI touches into TouchInput for the InputManager.
//     CRITICAL: it detects the lift via `event.type === TouchType.Up`
//     (not `event.touches.length === 0`, because in some ArkUI
//     versions the released finger is still in `touches`). Without the
//     explicit lift, `touching` stays `true` forever and nothing
//     re-fires `justStarted` after the first gesture.
import { display } from '@kit.ArkUI';
import {
  CanvasRenderer2D,
  Engine,
  EventBus,
  PhysicsSystem,
  RenderContext,
  TouchInput
} from '@oliver404/arkane-ts';
import { ExampleScene } from './ExampleScene';
import { MenuScene } from './MenuScene';
import { DifficultyScene } from './DifficultyScene';
import { OptionsScene } from './OptionsScene';
import { GameOverScene } from './GameOverScene';
import { Difficulty, GameMode, GameOverInfo } from './PongTypes';

@Entry
@Component
struct Index {
  @State message: string = 'Pong';
  private engine: Engine = new Engine();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private renderer: CanvasRenderer2D = new CanvasRenderer2D('#0e0e1a');
  private physics: PhysicsSystem = new PhysicsSystem();
  private started: boolean = false;
  // The renderContext is created in startScene() once we know the
  // viewport. We keep it as a field so it is not lost.
  private renderContext: RenderContext | null = null;
  // Difficulty carried between matches: the "vs Player" menu uses it
  // as the default, and `Rematch` falls back here when the mode was
  // not CPU.
  private currentDifficulty: Difficulty = 'medium';

  private startScene(): void {
    if (this.started) {
      return;
    }
    this.started = true;

    // Physical screen size. If the API fails or returns something
    // unexpectedly small (e.g. during preview), we fall back to 200x200.
    let viewportW: number = 236;
    let viewportH: number = 236;
    try {
      const info = display.getDefaultDisplaySync();
      if (info.width > 0) {
        viewportW = info.width;
      }
      if (info.height > 0) {
        viewportH = info.height;
      }
    } catch (e) {
      console.warn(`[index] display.getDefaultDisplaySync failed: ${e}`);
    }
    console.info(`[index] viewport=${viewportW}x${viewportH}`);

    this.renderContext = new RenderContext(this.context, viewportW, viewportH);
    this.engine.setRenderer(this.renderer, this.renderContext);
    this.engine.registerSystem(this.physics);
    this.wireEngineEvents();
    // Start with the main menu.
    this.showMenu(viewportW, viewportH);
  }

  private wireEngineEvents(): void {
    // The real EventBus is created inside engine.start(); we retrieve
    // it via the current scene's context. The `goal.scored` listener is
    // registered lazily in `attachGoalLogger()` the first time we have
    // a scene with a valid context.
  }

  private attachGoalLogger(): void {
    const scene = this.engine.getScene();
    if (scene === undefined) {
      return;
    }
    const ctx = scene.getContext();
    if (ctx === undefined) {
      return;
    }
    const events: EventBus = ctx.events;
    events.on('goal.scored', (payload: Object) => {
      const p = payload as Record<string, Object>;
      const scorer = p['scorer'] as string;
      const p1Score = p['p1Score'] as number;
      const p2Score = p['p2Score'] as number;
      console.info(`[goal.scored] scorer=${scorer} p1=${p1Score} p2=${p2Score}`);
    });
  }

  // ── Navigation ───────────────────────────────────────────────────────
  private showMenu(viewportW: number, viewportH: number): void {
    const menu: MenuScene = new MenuScene(viewportW, viewportH, {
      onVsComputer: () => {
        this.showDifficulty('cpu', viewportW, viewportH);
      },
      onVsPlayer: () => {
        this.startMatch('pvp', this.currentDifficulty, viewportW, viewportH);
      },
      onOptions: () => {
        this.showOptions(viewportW, viewportH);
      }
    });
    // `engine.start()` initializes the SceneContext and starts the loop;
    // it is only called the first time. Later navigation uses
    // `setScene`, which only swaps the active scene.
    if (this.engine.getScene() === undefined) {
      this.engine.start(menu);
    } else {
      this.engine.setScene(menu);
    }
    this.attachGoalLogger();
  }

  private showOptions(viewportW: number, viewportH: number): void {
    const opts: OptionsScene = new OptionsScene(viewportW, viewportH, () => {
      this.showMenu(viewportW, viewportH);
    });
    this.engine.setScene(opts);
  }

  private showDifficulty(
    mode: GameMode,
    viewportW: number,
    viewportH: number
  ): void {
    const diff: DifficultyScene = new DifficultyScene(
      viewportW,
      viewportH,
      this.currentDifficulty,
      {
        onPlay: (d: Difficulty) => {
          this.currentDifficulty = d;
          this.startMatch(mode, d, viewportW, viewportH);
        },
        onBack: () => {
          this.showMenu(viewportW, viewportH);
        }
      }
    );
    this.engine.setScene(diff);
  }

  private startMatch(
    mode: GameMode,
    difficulty: Difficulty,
    viewportW: number,
    viewportH: number
  ): void {
    const pong: ExampleScene = new ExampleScene(viewportW, viewportH, {
      mode,
      difficulty,
      onGameOver: (info: GameOverInfo) => {
        this.showGameOver(info, viewportW, viewportH);
      }
    });
    this.engine.setScene(pong);
    this.attachGoalLogger();
  }

  private showGameOver(
    info: GameOverInfo,
    viewportW: number,
    viewportH: number
  ): void {
    const over: GameOverScene = new GameOverScene(
      viewportW,
      viewportH,
      info,
      {
        onRematch: () => {
          this.startMatch(
            info.mode,
            info.difficulty ?? this.currentDifficulty,
            viewportW,
            viewportH
          );
        },
        onMenu: () => {
          this.showMenu(viewportW, viewportH);
        }
      }
    );
    this.engine.setScene(over);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          if (!this.started) {
            this.startScene();
          }
        })
        .onTouch((event: TouchEvent) => {
          this.feedTouch(event);
        })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * Converts ArkUI's `TouchEvent` into a call to
   * `InputManager.updateTouches`. The library's rule is ONE call per
   * frame with the current state.
   *
   * CRITICAL RULE: the primary discriminator is `event.type`, NOT
   * `event.touches.length`. In some ArkUI versions `event.touches`
   * still contains the released finger during the UP (only
   * `event.changedTouches` carries it reliably). If we relied on
   * `touches.length === 0`, the lift signal would never arrive,
   * `touching` would stay `true` forever, and every later gesture
   * would be ignored — swipe would die after the first use and
   * tap-to-restart would never fire.
   *
   *   - Down / Move → feed `event.touches[0]` as TouchInput.
   *   - Up / Cancel → ALWAYS feed `[]` (explicit lift signal,
   *     independent of what `event.touches` contains).
   *
   * Losing a swipe that completes EXACTLY on the UP frame remains an
   * acceptable edge case: any real swipe has at least one intermediate
   * MOVE between DOWN and UP, and the detector runs on that MOVE.
   */
  private feedTouch(event: TouchEvent): void {
    const input = this.engine.getInput();
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      input.updateTouches([]);
      return;
    }
    if (event.type === TouchType.Down || event.type === TouchType.Move) {
      const t = event.touches[0];
      if (t !== undefined) {
        input.updateTouches([new TouchInput(t.x, t.y)]);
      }
    }
  }
}
