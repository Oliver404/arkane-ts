// physics/PhysicsSystem.ts
//
// Auto-driven physics tick for V1.1. Integrates rigidbodies (gravity,
// drag, position), then resolves collider pairs via `Manifold.compute`
// using the impulsive restitution formula.
//
// Implements `GameSystem` so consumers can register it via
// `engine.registerSystem(physics)`. The engine calls `attach(this)`
// at registration time; the system uses that back-reference to read
// the active scene in `beforeUpdate`.
//
// Two ways to drive the system:
//   1. Explicit: `physics.step(scene, dt)` — used by tests and by
//      consumers that want full control over the tick.
//   2. Auto: register against an `Engine`; `beforeUpdate` calls
//      `step(engine.getScene(), Time.deltaTime)`.

import { Engine, GameSystem } from '../core/Engine'
import { Time } from '../core/Time'
import { Scene2D } from '../scene/Scene2D'
import { Entity } from '../scene/Entity'
import { Manifold } from './Manifold'
import { Vector2 } from '../math/Vector2'

export class PhysicsSystem implements GameSystem {
  /** Penetration tolerance. Pairs whose overlap is below `slop` skip
   *  positional correction entirely. */
  readonly slop: number = 0.05
  /** Baumgarte factor applied to positional correction (0..1). */
  readonly baumgarte: number = 0.4
  /** Fallback dt used when `beforeUpdate` runs but `Time.deltaTime` is
   *  0 (e.g. engine.updateForTest path). 1/60 matches the default
   *  GameLoop targetFPS. */
  dt: number = 1 / 60
  /** Back-reference set by `Engine.registerSystem` via `attach`. */
  private engine?: Engine

  attach(engine: Engine): void {
    this.engine = engine
  }

  beforeUpdate(): void {
    if (this.engine === undefined) {
      return
    }
    const scene: Scene2D | undefined = this.engine.getScene()
    if (scene === undefined) {
      return
    }
    let dt: number = Time.deltaTime
    if (dt <= 0) {
      dt = this.dt
    }
    this.step(scene, dt)
  }

  /**
   * One physics tick against the given scene.
   *
   *   1. Integration pass: every entity with a rigidbody of mass > 0
   *      accumulates gravity (scaled by `gravityScale`), has drag
   *      applied to velocity, then advances its transform position.
   *   2. Resolution pass: every i<j pair of entities with colliders is
   *      tested via `Manifold.compute`. Approaching contacts receive
   *      a normal impulse (with restitution) and a positional Baumgarte
   *      correction proportional to the inverse masses.
   */
  step(scene: Scene2D, dt: number): void {
    this.integrate(scene, dt)
    this.resolve(scene)
  }

  private integrate(scene: Scene2D, dt: number): void {
    const entities: readonly Entity[] = scene.getEntities()
    const gravity: Vector2 = scene.gravity
    const gx: number = gravity.x
    const gy: number = gravity.y
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i]
      const rb = e.rigidbody
      if (rb === undefined) {
        continue
      }
      if (rb.mass <= 0) {
        continue
      }
      // Apply gravity scaled by gravityScale.
      rb.velocity.x += gx * rb.gravityScale * dt
      rb.velocity.y += gy * rb.gravityScale * dt
      // Apply drag BEFORE integrating position (Scenario 4).
      if (rb.drag > 0) {
        const k: number = 1 - rb.drag * dt
        if (k <= 0) {
          rb.velocity.x = 0
          rb.velocity.y = 0
        } else {
          rb.velocity.x *= k
          rb.velocity.y *= k
        }
      }
      // Integrate position.
      e.transform.position.x += rb.velocity.x * dt
      e.transform.position.y += rb.velocity.y * dt
    }
  }

  private resolve(scene: Scene2D): void {
    const entities: readonly Entity[] = scene.getEntities()
    const n: number = entities.length
    for (let i: number = 0; i < n; i++) {
      const a: Entity = entities[i]
      const ca = a.collider
      if (ca === undefined) {
        continue
      }
      for (let j: number = i + 1; j < n; j++) {
        const b: Entity = entities[j]
        const cb = b.collider
        if (cb === undefined) {
          continue
        }
        const m: Manifold | null = Manifold.compute(ca, cb)
        if (m === null) {
          continue
        }
        this.applyImpulse(a, b, m)
        this.applyPositionalCorrection(a, b, m)
      }
    }
  }

  private applyImpulse(a: Entity, b: Entity, m: Manifold): void {
    const rbA = a.rigidbody
    const rbB = b.rigidbody
    const invMassA: number = (rbA !== undefined && rbA.mass > 0) ? 1 / rbA.mass : 0
    const invMassB: number = (rbB !== undefined && rbB.mass > 0) ? 1 / rbB.mass : 0
    // No dynamic side → nothing to impulse.
    if (invMassA === 0 && invMassB === 0) {
      return
    }
    // Use any available velocity (zero when rigidbody absent).
    const vAx: number = rbA !== undefined ? rbA.velocity.x : 0
    const vAy: number = rbA !== undefined ? rbA.velocity.y : 0
    const vBx: number = rbB !== undefined ? rbB.velocity.x : 0
    const vBy: number = rbB !== undefined ? rbB.velocity.y : 0
    const rvx: number = vBx - vAx
    const rvy: number = vBy - vAy
    const velAlongNormal: number = rvx * m.normal.x + rvy * m.normal.y
    // Skip separating contacts.
    if (velAlongNormal > 0) {
      return
    }
    const e: number = m.restitution
    const j: number = -(1 + e) * velAlongNormal / (invMassA + invMassB)
    const impulseX: number = j * m.normal.x
    const impulseY: number = j * m.normal.y
    if (rbA !== undefined && invMassA > 0) {
      rbA.velocity.x -= impulseX * invMassA
      rbA.velocity.y -= impulseY * invMassA
    }
    if (rbB !== undefined && invMassB > 0) {
      rbB.velocity.x += impulseX * invMassB
      rbB.velocity.y += impulseY * invMassB
    }
  }

  private applyPositionalCorrection(a: Entity, b: Entity, m: Manifold): void {
    const rbA = a.rigidbody
    const rbB = b.rigidbody
    const invMassA: number = (rbA !== undefined && rbA.mass > 0) ? 1 / rbA.mass : 0
    const invMassB: number = (rbB !== undefined && rbB.mass > 0) ? 1 / rbB.mass : 0
    const invMassSum: number = invMassA + invMassB
    if (invMassSum === 0) {
      return
    }
    const correctionMag: number = Math.max(m.penetration - this.slop, 0) / invMassSum * this.baumgarte
    const cx: number = m.normal.x * correctionMag
    const cy: number = m.normal.y * correctionMag
    a.transform.position.x -= cx * invMassA
    a.transform.position.y -= cy * invMassA
    b.transform.position.x += cx * invMassB
    b.transform.position.y += cy * invMassB
  }
}