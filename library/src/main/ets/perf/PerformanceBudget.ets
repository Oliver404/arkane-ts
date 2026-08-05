// perf/PerformanceBudget.ts
//
// Repeatable performance test with an explicit budget. Wraps a workload in a
// warm-up phase plus a sampling phase, then enforces an average frame budget
// and a worst-case per-frame budget against the supplied `BudgetConfig`.

export interface BudgetConfig {
  warmup: number
  samples: number
  avgLimitMs: number
  sampleLimitMs: number
  now?: () => number
}

export interface BudgetResult {
  averageMs: number
  worstMs: number
  samples: number
  passed: boolean
}

export class BudgetExceededError extends Error {
  readonly averageMs: number
  readonly limitMs: number
  readonly worstMs: number
  readonly worstLimitMs: number

  constructor(
    message: string,
    averageMs: number,
    limitMs: number,
    worstMs: number,
    worstLimitMs: number
  ) {
    super(message + ' averageMs=' + averageMs + ' limitMs=' + limitMs +
      ' worstMs=' + worstMs + ' worstLimitMs=' + worstLimitMs)
    this.name = 'BudgetExceededError'
    this.averageMs = averageMs
    this.limitMs = limitMs
    this.worstMs = worstMs
    this.worstLimitMs = worstLimitMs
  }
}

export class PerformanceBudget {
  readonly config: BudgetConfig

  constructor(config?: BudgetConfig) {
    const provided: BudgetConfig = (config !== undefined) ? config : {
      warmup: 5,
      samples: 30,
      avgLimitMs: 16.6,
      sampleLimitMs: 33.3,
    }
    const nowFn: () => number = provided.now ? provided.now : Date.now
    this.config = {
      warmup: provided.warmup,
      samples: provided.samples,
      avgLimitMs: provided.avgLimitMs,
      sampleLimitMs: provided.sampleLimitMs,
      now: nowFn,
    }
  }

  run(workload: () => void): BudgetResult {
    const cfg: BudgetConfig = this.config
    const now: () => number = cfg.now ? cfg.now : Date.now

    // Warm-up phase: invoke the workload and tick the clock once per warm-up
    // run. Warm-up durations are not recorded, but the clock advances so the
    // first sample measures the gap between the last warm-up tick and itself.
    let lastTime: number = 0
    for (let i: number = 0; i < cfg.warmup; i++) {
      workload()
      lastTime = now()
    }

    // Edge case: zero samples short-circuits to passed=true without enforcing.
    if (cfg.samples === 0) {
      const empty: BudgetResult = {
        averageMs: 0,
        worstMs: 0,
        samples: 0,
        passed: true,
      }
      return empty
    }

    // Initial tick: establishes the baseline before the first sample. Without
    // it the first sample's duration would be measured against the warm-up
    // baseline only when warm-up > 0, leaving warm-up=0 runs mis-aligned.
    lastTime = now()

    // Sampling phase: tick the clock before each sample to capture the
    // elapsed time since the previous tick (initial or previous sample).
    let total: number = 0
    let worstMs: number = 0
    for (let i: number = 0; i < cfg.samples; i++) {
      const current: number = now()
      workload()
      const delta: number = current - lastTime
      total += delta
      if (delta > worstMs) {
        worstMs = delta
      }
      lastTime = current
    }

    const averageMs: number = total / cfg.samples

    if (averageMs > cfg.avgLimitMs || worstMs > cfg.sampleLimitMs) {
      throw new BudgetExceededError(
        'BudgetExceededError: averageMs=' + averageMs + ' limitMs=' + cfg.avgLimitMs +
        ' worstMs=' + worstMs + ' worstLimitMs=' + cfg.sampleLimitMs,
        averageMs,
        cfg.avgLimitMs,
        worstMs,
        cfg.sampleLimitMs
      )
    }

    const result: BudgetResult = {
      averageMs: averageMs,
      worstMs: worstMs,
      samples: cfg.samples,
      passed: true,
    }
    return result
  }
}
