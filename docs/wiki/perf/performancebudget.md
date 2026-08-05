---
title: PerformanceBudget
version: 0.0.1
section: perf
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# PerformanceBudget

A repeatable benchmark harness for asserting that a workload (typically a scene update + render) stays within a per-frame budget. Intended for **test-time and CI use** — there is no runtime instrumentation hook.

`BudgetExceededError` is thrown when a budget run fails.

## Basic usage

```typescript
import { PerformanceBudget, BudgetExceededError } from '@oliver404/arkane-ts';

const budget = new PerformanceBudget({
  warmup: 5,
  samples: 30,
  avgLimitMs: 16.6,    // 60 FPS budget
  sampleLimitMs: 33.3  // hard cap on a single slow frame
});

try {
  const result = budget.run(() => {
    scene.update();
    scene.render(ctx, renderer);
  });
  // result.passed === true
  console.log(`avg ${result.averageMs} ms, worst ${result.worstMs} ms`);
} catch (e) {
  if (e instanceof BudgetExceededError) {
    // CI gate failed
  }
}
```

## Configuration

### `BudgetConfig`

| Field | Type | Default | Description |
|---|---|---|---|
| `warmup` | `number` | `5` | Number of warm-up ticks run before measurement. Discarded from the average. |
| `samples` | `number` | `30` | Number of measured ticks. |
| `avgLimitMs` | `number` | `16.6` | Hard cap on the average per-sample time. |
| `sampleLimitMs` | `number` | `33.3` | Hard cap on the worst single sample. |
| `now` | `() => number` | `Date.now` | Injected clock. Use a deterministic source in tests. |

### `BudgetResult`

| Field | Type | Description |
|---|---|---|
| `averageMs` | `number` | Mean duration across the sampling phase. |
| `worstMs` | `number` | Slowest single sample. |
| `samples` | `number` | Number of samples (echoes config). |
| `passed` | `boolean` | `true` if both limits held. |

### `BudgetExceededError`

Thrown by `run` when either `avgLimitMs` or `sampleLimitMs` is violated. Carries the actual measurements plus the configured limits so CI logs are diagnostic.

```typescript
class BudgetExceededError extends Error {
  readonly averageMs: number
  readonly limitMs: number       // = avgLimitMs at the time of failure
  readonly worstMs: number
  readonly worstLimitMs: number  // = sampleLimitMs at the time of failure
}
```

## Advanced usage

### Deterministic timing in tests

```typescript
const budget = new PerformanceBudget({
  warmup: 0,
  samples: 10,
  avgLimitMs: 10,
  sampleLimitMs: 20,
  now: mockClock    // returns increasing numbers in test
});
```

Use a controllable clock to make test results reproducible across machines.

### Zero samples edge case

`budget.run(workload)` returns `{ passed: true, samples: 0, averageMs: 0, worstMs: 0 }` when `samples: 0`. The workload is not invoked, no error is thrown. Useful as a "compile only" smoke check.

### Pure-functional workloads

The workload is invoked synchronously each tick. Avoid awaiting async work inside it — `now()` will not advance during an await.

## Pitfalls & FAQ

- **Not a runtime profiling tool.** There is no per-frame hook into the engine; `run` is a one-shot harness.
- **Wall-clock timing.** `run` uses the supplied `now()` function. System noise, GC pauses, and scheduler jitter are all counted. Run enough samples for the average to stabilize.
- **`workload` is invoked `warmup + samples` times** (plus one extra tick to establish the baseline). For expensive workloads, keep `warmup + samples` small.
- **`BudgetExceededError` is the only way to detect failure.** `run` does not return a `BudgetResult` with `passed: false` — it throws.

## See also

- `BudgetConfig`, `BudgetResult`, `BudgetExceededError` — the types used by `PerformanceBudget`.
