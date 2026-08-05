// 2-player Pong — demo minigame for the arkane-ts library.
//
//   Controls:
//     • Touch the left half of the screen  → moves the left paddle
//     • Touch the right half               → moves the right paddle
//       (in CPU mode this paddle is driven by the AI)
//     • Tap during SERVE                   → serves the ball
//     • Release                            → the paddle stays at the
//                                              last Y (there is no
//                                              auto-return)
//
//   Rules:
//     • Simplified tennis: first player to reach 4 points with a gap
//       of 2 wins. The UI shows consecutive numbers, not the 15/30/40
//       notation.
//     • Each player defends a goal (gap) behind their paddle.
//     • The ball bounces off every wall and paddle (no drain).
//
//   Library features exercised:
//     • Engine + GameLoop + PhysicsSystem as a registered system
//     • BoxCollider (walls, paddles), CircleCollider (ball)
//     • Rigidbody with mass / gravityScale (0 → top-down) / drag
//     • Manifold + restitution (perfect bounces)
//     • InputManager.isTouching + getTouchesWorld (1:1 drag per half)
//     • CenteredTextEntity for the P1/P2 scoreboards and the hint
//     • EventBus to signal each goal
//     • Camera2D.worldToScreen via CanvasRenderer2D
//
// The viewport is passed to the constructor. World centered on (0, 0).
// Convention: +Y = down (Camera2D does not flip Y). Gravity is 0 — the
// game is top-down, air-hockey style.
import {
  BoxCollider,
  CircleCollider,
  Entity,
  EventBus,
  MathUtils,
  RenderContext,
  Renderer2D,
  Rigidbody,
  Scene2D,
  Sprite,
  TextEntity,
  Time,
  Vector2
} from '@oliver404/arkane-ts';
import { Camera2D } from '@oliver404/arkane-ts';
import { AiController } from '../AiController';
import { CenteredTextEntity } from './CenteredTextEntity';
import { Difficulty, GameMode, GameOverInfo } from './PongTypes';
import { TennisScore } from '../TennisScore';

// ── EventBus payloads ──────────────────────────────────────────────────
interface GoalScoredPayload {
  scorer: 'p1' | 'p2';
  p1Score: number;
  p2Score: number;
}

// ── Circular entity ───────────────────────────────────────────────────
// Sprite + CanvasRenderer2D draws rectangles with fillRect, so we
// override `render` to paint the ball with `ctx.arc(...)`.
// The physics (CircleCollider) already respects the circular shape.
class BallEntity extends Entity {
  radius: number;
  color: string;

  constructor(radius: number, color: string) {
    super();
    this.radius = radius;
    this.color = color;
  }

  render(
    context: RenderContext,
    _renderer: Renderer2D,
    camera?: Camera2D
  ): void {
    if (camera === undefined) {
      return;
    }
    const screenPos: Vector2 = camera.worldToScreen(this.transform.position);
    const radiusScreen: number = this.radius * camera.zoom;
    const ctx = context.ctx;
    ctx.save();
    ctx.fillStyle = this.color;
    ctx.beginPath();
    ctx.arc(screenPos.x, screenPos.y, radiusScreen, 0, 2 * Math.PI);
    ctx.fill();
    ctx.restore();
  }
}

// ── Per-paddle state ───────────────────────────────────────────────────
class PaddleState {
  entity: Entity;
  sideSign: number; // -1 = left, +1 = right
  constructor(entity: Entity, sideSign: number) {
    this.entity = entity;
    this.sideSign = sideSign;
  }
}

type GameState = 'serve' | 'play' | 'finished';

export interface ExampleSceneConfig {
  mode: GameMode
  difficulty: Difficulty
  onGameOver: (info: GameOverInfo) => void
}

export class ExampleScene extends Scene2D {
  // ── World (configured in the constructor) ────────────────────────────
  private readonly viewportW: number;
  private readonly viewportH: number;
  private readonly halfW: number;
  private readonly halfH: number;
  /** Scale based on the smaller dimension: 1.0 when the viewport is
   *  200x200 (the design size). */
  private readonly s: number;

  // ── Scaled constants (computed from `s`) ────────────────────────────
  private readonly wallThickness: number;
  private readonly goalHalfHeight: number;
  private readonly paddleW: number;
  private readonly paddleH: number;
  private readonly paddleOffsetFromWall: number;
  private readonly paddleMinY: number;
  private readonly paddleMaxY: number;
  private readonly ballRadius: number;
  private readonly ballMass: number;
  private readonly ballRestitution: number;
  private readonly serveVx: number;
  private readonly serveVy: number;

  // ── Match configuration ─────────────────────────────────────────────
  private readonly mode: GameMode;
  private readonly difficulty: Difficulty;
  private readonly onGameOver: (info: GameOverInfo) => void;

  // ── UI ───────────────────────────────────────────────────────────────
  private p1ScoreText: TextEntity | null = null;
  private p2ScoreText: TextEntity | null = null;
  private serveHint: CenteredTextEntity | null = null;
  private gameOverText: CenteredTextEntity | null = null;

  // ── Physical world ───────────────────────────────────────────────────
  private ball: Entity | null = null;
  private ballRb: Rigidbody | null = null;
  private paddles: PaddleState[] = [];

  // ── Match state ──────────────────────────────────────────────────────
  private score: TennisScore = new TennisScore();
  private state: GameState = 'serve';
  /** -1 = serves toward the left (P1), +1 = serves toward the right (P2). */
  private nextServeSign: number = +1;
  private ai: AiController | null = null;
  private frame: number = 0;
  /** Blocks repeated onGameOver firing after a final goal. */
  private gameOverFired: boolean = false;

  constructor(
    viewportW: number = 200,
    viewportH: number = 200,
    config?: ExampleSceneConfig
  ) {
    super();
    this.viewportW = viewportW;
    this.viewportH = viewportH;
    this.halfW = viewportW / 2;
    this.halfH = viewportH / 2;
    const ref = Math.min(viewportW, viewportH);
    this.s = ref > 0 ? ref / 200 : 1;

    this.wallThickness = 12 * this.s;
    this.goalHalfHeight = 30 * this.s;
    this.paddleW = 8 * this.s;
    this.paddleH = 50 * this.s;
    this.paddleOffsetFromWall = 35 * this.s;
    this.paddleMinY = -(this.halfH - this.wallThickness - this.paddleH / 2);
    this.paddleMaxY = +(this.halfH - this.wallThickness - this.paddleH / 2);
    this.ballRadius = 8 * this.s;
    this.ballMass = 0.3;
    this.ballRestitution = 1.0;
    this.serveVx = 260 * this.s;
    this.serveVy = 60 * this.s;

    this.mode = config?.mode ?? 'pvp';
    this.difficulty = config?.difficulty ?? 'medium';
    this.onGameOver =
      config?.onGameOver ??
      (() => {
        // No-op: the callback is not interesting in tests.
      });
    if (this.mode === 'cpu') {
      this.ai = new AiController(this.difficulty);
    }
  }

  /** For tests: match mode. */
  getMode(): GameMode {
    return this.mode
  }

  /** For tests: current internal state. */
  getGameState(): GameState {
    return this.state
  }

  // ── World construction ───────────────────────────────────────────────
  onEnter(): void {
    // Top-down: zero gravity, no drain.
    this.gravity = new Vector2(0, 0);

    this.buildTopBottomWalls();
    this.buildSideWallsWithGoalGap();
    this.buildPaddles();
    this.buildBall();
    this.buildUI();
  }

  /** Creates a static entity with a BoxCollider (no rigidbody). */
  private makeStaticBox(
    pos: Vector2,
    width: number,
    height: number,
    color: string,
    restitution: number
  ): Entity {
    const e: Entity = new Entity();
    e.transform.position = pos;
    e.sprite = new Sprite(width, height, color);
    const collider: BoxCollider = new BoxCollider(e.transform, width, height);
    collider.restitution = restitution;
    e.setCollider(collider);
    this.addEntity(e);
    return e;
  }

  private buildTopBottomWalls(): void {
    // Top wall: full width, solid.
    this.makeStaticBox(
      new Vector2(0, -this.halfH + this.wallThickness / 2),
      this.viewportW, this.wallThickness, '#3a3a55', 1.0
    );
    // Bottom wall: full width, solid. There is no drain.
    this.makeStaticBox(
      new Vector2(0, this.halfH - this.wallThickness / 2),
      this.viewportW, this.wallThickness, '#3a3a55', 1.0
    );
  }

  /** Each side wall is split into 2 segments separated by the goal
   *  (gap centered on y=0 with height 2*goalHalfHeight). */
  private buildSideWallsWithGoalGap(): void {
    // Height of each segment = halfH - wallThickness - goalHalfHeight
    // (top/bottom walls + gap = what the segment covers).
    const segHeight: number =
      this.halfH - this.wallThickness - this.goalHalfHeight;
    // Y position of each segment's center:
    //   Top: covers from -halfH + wallThickness to -goalHalfHeight.
    //   Center = (-halfH + wallThickness + (-goalHalfHeight)) / 2.
    const segYTop: number =
      (-this.halfH + this.wallThickness + (-this.goalHalfHeight)) / 2;
    const segYBot: number = -segYTop; // symmetric.

    // Left side: P1's goal, gap between the 2 segments.
    this.makeStaticBox(
      new Vector2(-this.halfW + this.wallThickness / 2, segYTop),
      this.wallThickness, segHeight, '#3a3a55', 1.0
    );
    this.makeStaticBox(
      new Vector2(-this.halfW + this.wallThickness / 2, segYBot),
      this.wallThickness, segHeight, '#3a3a55', 1.0
    );
    // Right side: P2's goal.
    this.makeStaticBox(
      new Vector2(this.halfW - this.wallThickness / 2, segYTop),
      this.wallThickness, segHeight, '#3a3a55', 1.0
    );
    this.makeStaticBox(
      new Vector2(this.halfW - this.wallThickness / 2, segYBot),
      this.wallThickness, segHeight, '#3a3a55', 1.0
    );
  }

  private buildPaddles(): void {
    // Left paddle: vertically centered at the start.
    const leftEntity: Entity = this.makeStaticBox(
      new Vector2(-this.halfW + this.paddleOffsetFromWall, 0),
      this.paddleW, this.paddleH, '#ffffff', 1.0
    );
    this.paddles.push(new PaddleState(leftEntity, -1));

    // Right paddle: symmetric.
    const rightEntity: Entity = this.makeStaticBox(
      new Vector2(this.halfW - this.paddleOffsetFromWall, 0),
      this.paddleW, this.paddleH, '#ffffff', 1.0
    );
    this.paddles.push(new PaddleState(rightEntity, +1));
  }

  private buildBall(): void {
    const ball: BallEntity = new BallEntity(this.ballRadius, '#ff3b3b');
    ball.transform.position = new Vector2(0, 0);
    const collider: CircleCollider = new CircleCollider(
      ball.transform, this.ballRadius
    );
    collider.restitution = this.ballRestitution;
    ball.setCollider(collider);

    const rb: Rigidbody = new Rigidbody(ball.transform);
    rb.mass = this.ballMass;
    rb.gravityScale = 0;
    rb.drag = 0;
    ball.setRigidbody(rb);

    this.addEntity(ball);
    this.ball = ball;
    this.ballRb = rb;
  }

  private buildUI(): void {
    const fontSize: number = 14 * this.s;

    // P1 and P2 scoreboards near the horizontal center, in the upper
    // third. On circular screens the corners (-halfW, -halfH) fall
    // outside the visible circle, so the scoreboards are repositioned
    // to x ≈ ±30s, y ≈ -80s (distance to the center ≈ 85, well within
    // the halfW radius).
    const scoreY: number = -80 * this.s;

    const p1Text: TextEntity = new TextEntity('P1: 0');
    p1Text.setColor('#ffffff');
    p1Text.setFontSize(fontSize);
    p1Text.setFontFamily('sans-serif');
    p1Text.transform.position = new Vector2(-30 * this.s, scoreY);
    this.addEntity(p1Text);
    this.p1ScoreText = p1Text;

    const p2Text: TextEntity = new TextEntity('P2: 0');
    p2Text.setColor('#ffffff');
    p2Text.setFontSize(fontSize);
    p2Text.setFontFamily('sans-serif');
    p2Text.transform.position = new Vector2(+30 * this.s, scoreY);
    this.addEntity(p2Text);
    this.p2ScoreText = p2Text;

    // SERVE hint: centered on (0, 30*s) with textAlign='center' and
    // textBaseline='middle' so there is no need to measure the width.
    const hint: CenteredTextEntity = new CenteredTextEntity('Tap to serve');
    hint.setColor('#888888');
    hint.setFontSize(12 * this.s);
    hint.setFontFamily('sans-serif');
    hint.transform.position = new Vector2(0, 30 * this.s);
    this.addEntity(hint);
    this.serveHint = hint;
  }

  // ── Loop ─────────────────────────────────────────────────────────────
  update(): void {
    super.update();
    this.frame++;

    if (this.state === 'finished') {
      // The match is over: accept no more input or goals.
      return;
    }

    if (this.state === 'serve') {
      this.handleServeInput();
      return;
    }
    // PLAY
    this.updatePaddles();
    this.updateAi();
    this.detectGoal();
  }

  private handleServeInput(): void {
    const input = this.context!.input;
    if (!input.isTouchStarted()) {
      return;
    }
    if (this.ballRb !== null) {
      // Random diagonal (±serveVy) to vary the serve.
      const vySign: number = Math.random() < 0.5 ? -1 : +1;
      this.ballRb.velocity.x = this.nextServeSign * this.serveVx;
      this.ballRb.velocity.y = vySign * this.serveVy;
    }
    if (this.serveHint !== null) {
      this.removeEntity(this.serveHint);
      this.serveHint = null;
    }
    this.state = 'play';
  }

  /** 1:1 drag: the paddle whose screen half contains the finger
   *  follows the finger's Y, clamped so it does not cross walls. The
   *  paddle stays at the last Y on release. In CPU mode the right
   *  paddle is ignored (the AI drives it). */
  private updatePaddles(): void {
    const input = this.context!.input;
    const touches: Vector2[] = input.getTouchesWorld();
    if (!input.isTouching() || touches.length === 0) {
      return;
    }
    const t: Vector2 = touches[0];
    for (const p of this.paddles) {
      if (this.mode === 'cpu' && p.sideSign === +1) {
        continue; // driven by the AI, ignore right-side input.
      }
      // sideSign -1 = left paddle (requires tx < 0).
      // sideSign +1 = right paddle (requires tx >= 0).
      const ownsTouch: boolean = p.sideSign < 0 ? t.x < 0 : (t.x >= 0);
      if (!ownsTouch) {
        continue;
      }
      const clampedY: number =
        MathUtils.clamp(t.y, this.paddleMinY, this.paddleMaxY);
      p.entity.transform.position.y = clampedY;
    }
  }

  /** AI: the right paddle chases the ball's Y while respecting the
   *  field limits. */
  private updateAi(): void {
    if (this.ai === null || this.ball === null) {
      return;
    }
    const right = this.paddles.find((p) => p.sideSign === +1);
    if (right === undefined) {
      return;
    }
    const dt = this.fixedDt();
    const targetY: number = this.ai.step(
      right.entity.transform.position.y,
      this.ball.transform.position.y,
      this.frame,
      dt
    );
    right.entity.transform.position.y = MathUtils.clamp(
      targetY,
      this.paddleMinY,
      this.paddleMaxY
    );
  }

  /** dt consistent with `PhysicsSystem`: uses `Time.deltaTime` when
   *  it is >0, otherwise falls back to 1/60 so tests using
   *  `updateForTest` are deterministic. */
  private fixedDt(): number {
    const dt: number = Time.deltaTime;
    return dt > 0 ? dt : 1 / 60;
  }

  /** Goal detection: the ball leaves the field through one of the
   *  side goals. We award the point to the player opposite to the one
   *  that goal "belongs" to. */
  private detectGoal(): void {
    if (this.ball === null) {
      return;
    }
    const bx: number = this.ball.transform.position.x;
    if (bx < -this.halfW) {
      // P1's goal → P2 scores.
      this.onGoalScored('p2');
    } else if (bx > this.halfW) {
      // P2's goal → P1 scores.
      this.onGoalScored('p1');
    }
  }

  // ── Match events ─────────────────────────────────────────────────────
  private onGoalScored(scorer: 'p1' | 'p2'): void {
    const winner = this.score.addPoint(scorer);
    if (this.p1ScoreText !== null) {
      this.p1ScoreText.setText(`P1: ${this.score.getPoints('p1')}`);
    }
    if (this.p2ScoreText !== null) {
      this.p2ScoreText.setText(`P2: ${this.score.getPoints('p2')}`);
    }
    const payload: GoalScoredPayload = {
      scorer,
      p1Score: this.score.getPoints('p1'),
      p2Score: this.score.getPoints('p2')
    };
    this.context!.events.emit('goal.scored', payload as Object);

    // Reposition and stop the ball.
    if (this.ballRb !== null) {
      this.ballRb.velocity.x = 0;
      this.ballRb.velocity.y = 0;
    }
    if (this.ball !== null) {
      this.ball.transform.position.x = 0;
      this.ball.transform.position.y = 0;
    }

    if (winner !== null) {
      // Match over: freeze and notify.
      this.state = 'finished';
      this.gameOverFired = true;
      // Remove the hint so "Tap to serve" is not drawn on top of the
      // end-of-match message.
      if (this.serveHint !== null) {
        this.removeEntity(this.serveHint);
        this.serveHint = null;
      }
      const info: GameOverInfo = {
        winner,
        p1Score: this.score.getPoints('p1'),
        p2Score: this.score.getPoints('p2'),
        mode: this.mode,
        difficulty: this.mode === 'cpu' ? this.difficulty : null
      };
      this.onGameOver(info);
      return;
    }

    // Serve toward the player who conceded the goal (standard rule).
    this.nextServeSign = scorer === 'p1' ? -1 : +1;
    this.state = 'serve';
    this.showServeHint();
  }

  private showServeHint(): void {
    if (this.serveHint !== null) {
      return;
    }
    const hint: CenteredTextEntity = new CenteredTextEntity('Tap to serve');
    hint.setColor('#888888');
    hint.setFontSize(12 * this.s);
    hint.setFontFamily('sans-serif');
    hint.transform.position = new Vector2(0, 30 * this.s);
    this.addEntity(hint);
    this.serveHint = hint;
  }
}
