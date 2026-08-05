/**
 * Source feature: .infO404/docs/features/performance/performance.feature (HU-07)
 * Feature: Repeatable performance test with explicit budget
 * Scenarios covered:
 *   - Scenario 1: Defined workload and protocol (default BudgetConfig values)
 *   - Scenario 2: Repeatable measurement (two consecutive runs share sample count and report average)
 *   - Scenario 3: Budget enforcement: pass case (result.passed === true, average reported)
 *   - Scenario 4: Budget enforcement: average exceeds budget (BudgetExceededError on average)
 *   - Scenario 5: Budget enforcement: any sample exceeds per-frame limit (BudgetExceededError on worst)
 *   - Scenario 6: Warm-up phase is performed before sampling (warm-up runs are excluded from samples)
 *   - Scenario 7: Public export (PerformanceBudget + BudgetExceededError importable)
 *   - Scenario 8: Patch-version API compatibility (public symbols + fields remain stable)
 *   - Edge cases: zero warm-up allowed; zero samples returns passed:true without enforcing budget
 */
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { PerformanceBudget, BudgetExceededError } from '../main/ets/perf/PerformanceBudget';
import type { BudgetConfig, BudgetResult } from '../main/ets/perf/PerformanceBudget';

interface CountingWorkload {
  callCount: number;
  workload: () => void;
}

/**
 * A deterministic clock factory. Each call to the returned `now()` returns the
 * next entry of the supplied sequence. The sequence models the wall-clock
 * duration of every run (warm-up or sample) as a fixed value in milliseconds,
 * so the measured per-run duration = (now()_after - now()_before) = sequence[i+1] - sequence[i].
 *
 * Example: buildClock([10, 11, 12, 13, 14]) means every run takes exactly 1 ms.
 */
function buildClock(sequence: number[]): () => number {
  let index: number = 0;
  return (): number => {
    const value: number = sequence[index];
    index++;
    return value;
  };
}

/**
 * Constant-time workload: increments a counter so the test can verify that
 * exactly N calls were made during warm-up + sampling.
 */
function makeCountingWorkload(): CountingWorkload {
  const state: CountingWorkload = {
    callCount: 0,
    workload: (): void => {
      state.callCount = state.callCount + 1;
    },
  };
  return state;
}

export default function performanceBudgetTest() {
  describe('PerformanceBudget', () => {
    let budget: PerformanceBudget;

    beforeEach(() => {
      budget = new PerformanceBudget();
    });

    it('the default values expose warmup=5, samples=30, avgLimitMs=16.6 and sampleLimitMs=33.3 (Scenario 1)', 0, () => {
      const cfg: BudgetConfig = budget.config;
      expect(cfg.warmup).assertEqual(5);
      expect(cfg.samples).assertEqual(30);
      expect(cfg.avgLimitMs).assertEqual(16.6);
      expect(cfg.sampleLimitMs).assertEqual(33.3);
    });

    it('a BudgetConfig passed to the constructor replaces the default values (Scenario 1)', 0, () => {
      const custom: BudgetConfig = {
        warmup: 2,
        samples: 10,
        avgLimitMs: 8,
        sampleLimitMs: 16,
      };
      const b: PerformanceBudget = new PerformanceBudget(custom);
      expect(b.config.warmup).assertEqual(2);
      expect(b.config.samples).assertEqual(10);
      expect(b.config.avgLimitMs).assertEqual(8);
      expect(b.config.sampleLimitMs).assertEqual(16);
    });

    it('two consecutive runs with the same configuration report the same sample count and average (Scenario 2)', 0, () => {
      // Each "run" takes 1 ms; 5 warm-up + 1 initial + 30 samples = 36 ticks per run,
      // so the second run needs 36 more ticks at the same cadence.
      const clock: () => number = buildClock([
        0, 1, 2, 3, 4, 5,
        6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
        50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
        61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
      ]);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 5,
        samples: 30,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const w1: CountingWorkload = makeCountingWorkload();
      const w2: CountingWorkload = makeCountingWorkload();
      const r1: BudgetResult = b.run(w1.workload);
      const r2: BudgetResult = b.run(w2.workload);

      expect(r1.samples).assertEqual(30);
      expect(r2.samples).assertEqual(30);
      expect(r1.averageMs).assertEqual(1);
      expect(r2.averageMs).assertEqual(1);
      expect(w1.callCount).assertEqual(35);
      expect(w2.callCount).assertEqual(35);
    });

    it('a workload with an average within the budget returns passed=true and exposes averageMs (Scenario 3)', 0, () => {
      // 1 ms per run; 5 warm-up + 30 samples = 35 ticks.
      const clock: () => number = buildClock([
        0, 1, 2, 3, 4, 5,
        6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        31, 32, 33, 34, 35,
      ]);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 5,
        samples: 30,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const w: CountingWorkload = makeCountingWorkload();
      const result: BudgetResult = b.run(w.workload);

      expect(result.passed).assertEqual(true);
      expect(result.averageMs).assertEqual(1);
      expect(result.samples).assertEqual(30);
      expect(result.worstMs).assertEqual(1);
    });

    it('a workload whose average exceeds 16.6 ms throws BudgetExceededError naming average and limit (Scenario 4)', 0, () => {
      // Each sample takes 20 ms; 5 warm-up + 30 samples.
      const ticks: number[] = [];
      for (let i: number = 0; i <= 35; i++) {
        ticks.push(i * 20);
      }
      const clock: () => number = buildClock(ticks);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 5,
        samples: 30,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const w: CountingWorkload = makeCountingWorkload();
      let thrown: Error | null = null;
      try {
        b.run(w.workload);
      } catch (e) {
        thrown = e as Error;
      }

      expect(thrown !== null).assertEqual(true);
      expect(thrown instanceof BudgetExceededError).assertEqual(true);
      const err: BudgetExceededError = thrown as BudgetExceededError;
      expect(err.averageMs > 16.6).assertEqual(true);
      expect(err.limitMs).assertEqual(16.6);
    });

    it('a workload with one sample over the per-frame limit throws BudgetExceededError naming the worst sample (Scenario 5)', 0, () => {
      // 29 samples take 1 ms each, then one sample takes 50 ms (> 33.3 limit).
      // Layout: 5 warm-up ticks (1ms each) + 1 initial tick + 30 sample ticks (29 at 1ms, 1 at 50ms) = 36 ticks.
      const ticks: number[] = [];
      let t: number = 0;
      // 5 warm-up runs of 1 ms.
      for (let i: number = 0; i < 5; i++) {
        ticks.push(t);
        t = t + 1;
      }
      // Initial tick before samples.
      ticks.push(t);
      t = t + 1;
      // 29 sample runs of 1 ms.
      for (let i: number = 0; i < 29; i++) {
        ticks.push(t);
        t = t + 1;
      }
      // Final sample runs of 50 ms (exceeds the 33.3 per-frame limit).
      t = t + 50;
      ticks.push(t);
      const clock: () => number = buildClock(ticks);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 5,
        samples: 30,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const w: CountingWorkload = makeCountingWorkload();
      let thrown: Error | null = null;
      try {
        b.run(w.workload);
      } catch (e) {
        thrown = e as Error;
      }

      expect(thrown !== null).assertEqual(true);
      expect(thrown instanceof BudgetExceededError).assertEqual(true);
      const err: BudgetExceededError = thrown as BudgetExceededError;
      expect(err.worstMs > 33.3).assertEqual(true);
      expect(err.worstLimitMs).assertEqual(33.3);
    });

    it('the warm-up runs execute before the samples and are excluded from the sample count (Scenario 6)', 0, () => {
      // 3 warm-up runs of 1 ms + 1 initial tick + 10 sample runs of 2 ms each => 14 ticks.
      const ticks: number[] = [0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24];
      const clock: () => number = buildClock(ticks);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 3,
        samples: 10,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const w: CountingWorkload = makeCountingWorkload();
      const result: BudgetResult = b.run(w.workload);

      // Warm-up (3) + samples (10) = 13 workload invocations.
      expect(w.callCount).assertEqual(13);
      // result.samples records only the 10 measured runs.
      expect(result.samples).assertEqual(10);
      expect(result.averageMs).assertEqual(2);
    });

    it('the first half of the work (the runs before the first sampling tick) happens before any sample is recorded (Scenario 6)', 0, () => {
      // Use a workload that records its index-of-execution. The first
      // cfg.warmup invocations should happen before any sample is recorded.
      const clock: () => number = buildClock([
        0, 1, 2, 3, 4, 5,
        6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        31, 32, 33, 34, 35,
      ]);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 5,
        samples: 30,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const executionLog: number[] = [];
      let n: number = 0;
      const workload: () => void = (): void => {
        executionLog.push(n);
        n = n + 1;
      };
      b.run(workload);

      // The first 5 executions are warm-up; the next 30 are samples.
      expect(executionLog.length).assertEqual(35);
      expect(executionLog[0]).assertEqual(0);
      expect(executionLog[4]).assertEqual(4);
      expect(executionLog[5]).assertEqual(5);
      expect(executionLog[34]).assertEqual(34);
    });

    it('PerformanceBudget and BudgetExceededError are importable as public symbols (Scenario 7)', 0, () => {
      // Constructor + error class exist and are usable from the public import path.
      const b: PerformanceBudget = new PerformanceBudget();
      expect(b instanceof PerformanceBudget).assertEqual(true);

      const err: BudgetExceededError = new BudgetExceededError(
        'sample exceeded budget',
        20.0,
        16.6,
        33.3,
        40.0,
      );
      expect(err instanceof BudgetExceededError).assertEqual(true);
      expect(err instanceof Error).assertEqual(true);
    });

    it('the public fields of BudgetExceededError and BudgetConfig stay stable across releases (Scenario 8)', 0, () => {
      const err: BudgetExceededError = new BudgetExceededError(
        'sample exceeded budget',
        20.0,
        16.6,
        40.0,
        33.3,
      );
      // Stable public fields.
      expect(err.averageMs).assertEqual(20.0);
      expect(err.limitMs).assertEqual(16.6);
      expect(err.worstMs).assertEqual(40.0);
      expect(err.worstLimitMs).assertEqual(33.3);

      // Stable public field on PerformanceBudget.
      const cfg: BudgetConfig = budget.config;
      expect(cfg.warmup).assertEqual(5);
      expect(cfg.samples).assertEqual(30);
      expect(cfg.avgLimitMs).assertEqual(16.6);
      expect(cfg.sampleLimitMs).assertEqual(33.3);

      // Stable method on PerformanceBudget.
      expect(typeof budget.run).assertEqual('function');
    });

    it('a warm-up of 0 runs is valid and the full set of samples is recorded (edge case)', 0, () => {
      // 0 warm-up + 4 sample runs of 5 ms each = 5 ticks.
      const ticks: number[] = [0, 5, 10, 15, 20];
      const clock: () => number = buildClock(ticks);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 0,
        samples: 4,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const w: CountingWorkload = makeCountingWorkload();
      const result: BudgetResult = b.run(w.workload);

      expect(w.callCount).assertEqual(4);
      expect(result.samples).assertEqual(4);
      expect(result.averageMs).assertEqual(5);
      expect(result.passed).assertEqual(true);
    });

    it('samples=0 returns passed=true without invoking the workload or enforcing the budget (edge case)', 0, () => {
      // 5 warm-up runs of 1 ms + 0 samples => 6 ticks total.
      const ticks: number[] = [0, 1, 2, 3, 4, 5];
      const clock: () => number = buildClock(ticks);
      const b: PerformanceBudget = new PerformanceBudget({
        warmup: 5,
        samples: 0,
        avgLimitMs: 16.6,
        sampleLimitMs: 33.3,
        now: clock,
      });

      const w: CountingWorkload = makeCountingWorkload();
      const result: BudgetResult = b.run(w.workload);

      // Only the warm-up runs were executed; no samples were recorded.
      expect(w.callCount).assertEqual(5);
      expect(result.samples).assertEqual(0);
      expect(result.passed).assertEqual(true);
    });

    it('the BudgetExceededError message contains the average, limit, worst and worstLimit numbers (edge case)', 0, () => {
      const err: BudgetExceededError = new BudgetExceededError(
        'budget exceeded',
        25.5,
        16.6,
        45.0,
        33.3,
      );
      const message: string = err.message;
      // Numbers must appear in the constructor message so Hypium logs are diagnostic.
      expect(message.indexOf('25.5') >= 0).assertEqual(true);
      expect(message.indexOf('16.6') >= 0).assertEqual(true);
      expect(message.indexOf('45') >= 0).assertEqual(true);
      expect(message.indexOf('33.3') >= 0).assertEqual(true);
    });
  });
}