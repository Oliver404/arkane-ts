// AiController — right paddle controller in CPU mode.
//
//   • Three profiles: `easy`, `medium`, `hard`. Harder = faster,
//     less lag, less error.
//   • Moves toward the ball's Y with a configurable lag in frames
//     (the AI "sees" the ball position N frames behind) plus uniform
//     noise on Y so it is not perfect.
//   • The RNG is injected so tests can be deterministic.
//   • `step(paddle, ballY, dt, frame)` returns the target Y the
//     paddle should move to this frame. Integration with the
//     Rigidbody/Transform is up to the consumer (clamp + assignment).

export type Difficulty = 'easy' | 'medium' | 'hard'

export interface AiConfig {
  maxSpeed: number        // units per second
  reactionLagFrames: number // frames of lag before reacting
  noiseY: number          // noise amplitude on Y (units)
  targetBias: number      // bias toward the center (0 = pure ball, 1 = pure center)
}

export interface AiConfigByDifficulty {
  easy: AiConfig
  medium: AiConfig
  hard: AiConfig
}

export const AI_PROFILES: AiConfigByDifficulty = {
  easy: {
    maxSpeed: 220,
    reactionLagFrames: 12,
    noiseY: 18,
    targetBias: 0.35
  },
  medium: {
    maxSpeed: 360,
    reactionLagFrames: 6,
    noiseY: 9,
    targetBias: 0.15
  },
  hard: {
    maxSpeed: 520,
    reactionLagFrames: 2,
    noiseY: 3,
    targetBias: 0.05
  }
}

function aiConfigFor(d: Difficulty): AiConfig {
  if (d === 'easy') {
    return AI_PROFILES.easy;
  }
  if (d === 'medium') {
    return AI_PROFILES.medium;
  }
  return AI_PROFILES.hard;
}

export type Rng = () => number

export class AiController {
  private cfg: AiConfig
  private rng: Rng
  private seenY: number = 0
  private lastSeenFrame: number = -1
  private noisyTarget: number = 0

  constructor(difficulty: Difficulty, rng: Rng = Math.random) {
    this.cfg = aiConfigFor(difficulty)
    this.rng = rng
  }

  /**
   * Updates the internal state. `paddleY` is the paddle's current Y,
   * `ballY` the ball's current Y, `frame` the frame counter
   * (integer, monotonically increasing), `dt` the delta in seconds.
   * Returns the target Y the paddle should move to.
   */
  step(paddleY: number, ballY: number, frame: number, dt: number): number {
    // Sample the ball position every `reactionLagFrames` frames.
    if (frame - this.lastSeenFrame >= this.cfg.reactionLagFrames) {
      this.lastSeenFrame = frame
      // Blend the ball's Y with a bias toward the center (this keeps
      // the AI from running fully to one edge and getting stuck there
      // if the ball always goes to the same place).
      const biasedBall: number = ballY * (1 - this.cfg.targetBias)
      const noise: number = (this.rng() * 2 - 1) * this.cfg.noiseY
      this.seenY = biasedBall + noise
      this.noisyTarget = this.seenY
    }

    // Move toward `noisyTarget` with a capped speed.
    const delta: number = this.noisyTarget - paddleY
    const maxStep: number = this.cfg.maxSpeed * dt
    if (Math.abs(delta) <= maxStep) {
      return this.noisyTarget
    }
    return paddleY + Math.sign(delta) * maxStep
  }
}
