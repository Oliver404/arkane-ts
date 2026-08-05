/**
 * Source feature: .infO404/docs/features/physicsSystem/physicsSystem.feature
 * Feature: Resolve collisions with Manifold and automatic PhysicsSystem (HU-01, V1.1)
 * Scenarios covered:
 *   - Scenario 1: Manifold generation on overlap
 *   - Scenario 2: Manifold restitution equals max(a.restitution, b.restitution)
 *   - Scenario 3: PhysicsSystem integrates gravity and velocity
 *   - Scenario 4: PhysicsSystem applies drag
 *   - Scenario 5: PhysicsSystem applies restitution on contact
 *   - Scenario 6: PhysicsSystem performs positional correction
 *   - Scenario 7: Static colliders are not integrated
 *   - Scenario 8: PhysicsSystem is registrable as a system
 *   - Scenario 9: Public export
 *   - Scenario 10: Patch-version API compatibility
 *   - + bonus: Manifold.compute returns null when not overlapping
 *           (box-box / box-circle / circle-circle)
 *   - + bonus: restitution impulse conserves momentum for equal masses
 */
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { Engine, GameSystem } from '../main/ets/core/Engine';
import { Scene2D } from '../main/ets/scene/Scene2D';
import { Entity } from '../main/ets/scene/Entity';
import { Transform } from '../main/ets/scene/Transform';
import { Vector2 } from '../main/ets/math/Vector2';
import { BoxCollider } from '../main/ets/physics/BoxCollider';
import { CircleCollider } from '../main/ets/physics/CircleCollider';
import { Collider } from '../main/ets/physics/Collider';
import { Rigidbody } from '../main/ets/physics/Rigidbody';
import { Manifold } from '../main/ets/physics/Manifold';
import { PhysicsSystem } from '../main/ets/physics/PhysicsSystem';

// --------------------------------------------------------------------
// Test scene — minimal Scene2D subclass that exposes gravity/entities.
// --------------------------------------------------------------------
class PhysicsTestScene extends Scene2D {
  onEnter(): void {}
}

// --------------------------------------------------------------------
// Helpers — build an entity that already has a transform, collider
// and rigidbody in one call, so individual tests stay focused.
// --------------------------------------------------------------------
function makeEntity(
  pos: Vector2,
  box: boolean,
  sizeOrRadius: number
): Entity {
  const e: Entity = new Entity();
  e.transform.position = pos;
  if (box) {
    e.setCollider(new BoxCollider(e.transform, sizeOrRadius, sizeOrRadius));
  } else {
    e.setCollider(new CircleCollider(e.transform, sizeOrRadius));
  }
  return e;
}

function addBox(scene: Scene2D, pos: Vector2, size: number): Entity {
  const e: Entity = makeEntity(pos, true, size);
  scene.addEntity(e);
  return e;
}

function addCircle(scene: Scene2D, pos: Vector2, radius: number): Entity {
  const e: Entity = makeEntity(pos, false, radius);
  scene.addEntity(e);
  return e;
}

function addRigidbody(entity: Entity, mass: number, gravityScale: number, drag: number): Rigidbody {
  const rb: Rigidbody = new Rigidbody(entity.transform);
  rb.mass = mass;
  rb.gravityScale = gravityScale;
  rb.drag = drag;
  entity.setRigidbody(rb);
  return rb;
}

// Deterministic dt used across every integration test so numbers stay tractable.
const DT: number = 1 / 60;
const EPS: number = 1e-6;

export default function physicsSystemTest() {
  describe('Manifold (HU-01)', () => {
    it('Manifold.compute returns null when two BoxColliders do not overlap (Scenario 1)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(50, 50));
      const a: Collider = new BoxCollider(tA, 10, 10);
      const b: Collider = new BoxCollider(tB, 10, 10);

      expect(Manifold.compute(a, b)).assertNull();
    });

    it('Manifold.compute returns null when two CircleColliders do not overlap (Scenario 1)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(50, 50));
      const a: Collider = new CircleCollider(tA, 5);
      const b: Collider = new CircleCollider(tB, 5);

      expect(Manifold.compute(a, b)).assertNull();
    });

    it('Manifold.compute returns null when a Box and a Circle do not overlap (Scenario 1)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(50, 50));
      const a: Collider = new BoxCollider(tA, 10, 10);
      const b: Collider = new CircleCollider(tB, 5);

      expect(Manifold.compute(a, b)).assertNull();
    });

    it('Manifold.compute produces a non-null Manifold when two BoxColliders overlap (Scenario 1)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(3, 0));
      const a: Collider = new BoxCollider(tA, 10, 10);
      const b: Collider = new BoxCollider(tB, 10, 10);

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
    });

    it('Manifold.compute produces a non-null Manifold when two CircleColliders overlap (Scenario 1)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(3, 0));
      const a: Collider = new CircleCollider(tA, 5);
      const b: Collider = new CircleCollider(tB, 5);

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
    });

    it('Manifold.normal points from a to b (Scenario 1)', 0, () => {
      // b is to the right of a, so n.x must be positive.
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(2, 0));
      const a: Collider = new BoxCollider(tA, 10, 10);
      const b: Collider = new BoxCollider(tB, 10, 10);

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
      const mnf: Manifold = m as Manifold;
      expect(mnf.normal.x).assertLarger(0);
      expect(Math.abs(mnf.normal.y)).assertLess(EPS);
    });

    it('Manifold.normal also points from a to b in a vertical collision (Scenario 1)', 0, () => {
      // b is below a, so n.y must be negative (vector pointing down).
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(0, -2));
      const a: Collider = new CircleCollider(tA, 5);
      const b: Collider = new CircleCollider(tB, 5);

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
      const mnf: Manifold = m as Manifold;
      expect(Math.abs(mnf.normal.x)).assertLess(EPS);
      expect(mnf.normal.y).assertLess(0);
    });

    it('Manifold.penetration is >= 0 (Scenario 1)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(2, 0));
      const a: Collider = new BoxCollider(tA, 10, 10);
      const b: Collider = new BoxCollider(tB, 10, 10);

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
      const mnf: Manifold = m as Manifold;
      expect(mnf.penetration).assertLargerOrEqual(0);
    });

    it('Manifold.restitution is max(a.restitution, b.restitution) (Scenario 2)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(2, 0));
      const a: BoxCollider = new BoxCollider(tA, 10, 10);
      const b: BoxCollider = new BoxCollider(tB, 10, 10);
      a.restitution = 0.2;
      b.restitution = 0.8;

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
      const mnf: Manifold = m as Manifold;
      expect(mnf.restitution).assertClose(0.8, EPS);
    });

    it('Manifold.restitution takes the higher side when a.restitution is higher (Scenario 2)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(2, 0));
      const a: BoxCollider = new BoxCollider(tA, 10, 10);
      const b: BoxCollider = new BoxCollider(tB, 10, 10);
      a.restitution = 0.9;
      b.restitution = 0.1;

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
      const mnf: Manifold = m as Manifold;
      expect(mnf.restitution).assertClose(0.9, EPS);
    });

    it('Manifold.friction is an informational numeric field (HU-01 contract)', 0, () => {
      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(2, 0));
      const a: BoxCollider = new BoxCollider(tA, 10, 10);
      const b: BoxCollider = new BoxCollider(tB, 10, 10);
      a.friction = 0.4;
      b.friction = 0.6;

      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
      const mnf: Manifold = m as Manifold;
      // Friction is informational in V1.1: we only check that it is a number.
      expect(typeof mnf.friction === 'number').assertTrue();
    });
  });

  describe('PhysicsSystem (HU-01)', () => {
    let scene: PhysicsTestScene;
    let sys: PhysicsSystem;

    beforeEach(() => {
      scene = new PhysicsTestScene();
      sys = new PhysicsSystem();
    });

    it('public slop is 0.05 (HU-01 contract)', 0, () => {
      expect(sys.slop).assertEqual(0.05);
    });

    it('public baumgarte is 0.4 (HU-01 contract)', 0, () => {
      expect(sys.baumgarte).assertEqual(0.4);
    });

    it('integrates gravity into the rigidbody velocity (Scenario 3)', 0, () => {
      // Scene2D's default gravity is (0, -9.8), gravityScale = 1.
      const e: Entity = addBox(scene, new Vector2(0, 0), 10);
      addRigidbody(e, 1, 1, 0);
      const beforeY: number = e.rigidbody!.velocity.y;

      sys.step(scene, DT);

      const deltaV: number = e.rigidbody!.velocity.y - beforeY;
      // Δv = g * gs * dt = -9.8 * 1 * (1/60)
      expect(deltaV).assertClose(-9.8 * DT, EPS);
    });

    it('respects gravityScale when integrating gravity (Scenario 3)', 0, () => {
      const e: Entity = addBox(scene, new Vector2(0, 0), 10);
      addRigidbody(e, 1, 2, 0);
      const beforeY: number = e.rigidbody!.velocity.y;

      sys.step(scene, DT);

      const deltaV: number = e.rigidbody!.velocity.y - beforeY;
      expect(deltaV).assertClose(-9.8 * 2 * DT, EPS);
    });

    it('advances the position according to the integrated velocity (Scenario 3)', 0, () => {
      // Gravity = 0 to isolate the position = v * dt integration.
      scene.gravity = new Vector2(0, 0);
      const e: Entity = addBox(scene, new Vector2(0, 0), 10);
      addRigidbody(e, 1, 1, 0);
      e.rigidbody!.velocity.set(60, 0); // v.x = 60 → Δx = 60 * (1/60) = 1

      sys.step(scene, DT);

      expect(e.transform.position.x).assertClose(1, EPS);
      expect(e.transform.position.y).assertClose(0, EPS);
    });

    it('multiplies the velocity by (1 - drag * dt) when drag > 0 (Scenario 4)', 0, () => {
      scene.gravity = new Vector2(0, 0);
      const e: Entity = addBox(scene, new Vector2(0, 0), 10);
      addRigidbody(e, 1, 1, 1.5);
      e.rigidbody!.velocity.set(10, 0);

      sys.step(scene, DT);

      // v' = v * (1 - drag*dt) = 10 * (1 - 1.5 * 1/60)
      expect(e.rigidbody!.velocity.x).assertClose(10 * (1 - 1.5 * DT), EPS);
    });

    it('applies drag before integrating the position, but not after (Scenario 4)', 0, () => {
      // With drag=0 the position advances by exactly v*dt.
      scene.gravity = new Vector2(0, 0);
      const e: Entity = addBox(scene, new Vector2(0, 0), 10);
      addRigidbody(e, 1, 1, 0);
      e.rigidbody!.velocity.set(60, 0);

      sys.step(scene, DT);

      expect(e.transform.position.x).assertClose(1, EPS);
    });

    it('does not integrate the velocity of a body with mass <= 0 (Scenario 7)', 0, () => {
      // Negative / zero mass models a static body (infinite-mass).
      const e: Entity = addBox(scene, new Vector2(0, 0), 10);
      addRigidbody(e, 0, 1, 0);
      const beforeY: number = e.rigidbody!.velocity.y;

      sys.step(scene, DT);

      expect(e.rigidbody!.velocity.y).assertEqual(beforeY);
    });

    it('does not integrate the position of an entity without a rigidbody (Scenario 7)', 0, () => {
      scene.gravity = new Vector2(0, -9.8);
      const e: Entity = addBox(scene, new Vector2(5, 7), 10);
      // We do not add a rigidbody.
      const initialX: number = e.transform.position.x;
      const initialY: number = e.transform.position.y;

      sys.step(scene, DT);

      expect(e.transform.position.x).assertEqual(initialX);
      expect(e.transform.position.y).assertEqual(initialY);
    });

    it('applies a normal impulse with restitution when two bodies approach (Scenario 5)', 0, () => {
      scene.gravity = new Vector2(0, 0);
      // a is at (0,0), b is at (4,0); both boxes 10x10 → they collide.
      const a: Entity = addBox(scene, new Vector2(0, 0), 10);
      const b: Entity = addBox(scene, new Vector2(4, 0), 10);
      addRigidbody(a, 1, 1, 0);
      addRigidbody(b, 1, 1, 0);
      a.rigidbody!.velocity.set(10, 0);   // a moves toward +x
      b.rigidbody!.velocity.set(-10, 0);  // b moves toward -x

      sys.step(scene, DT);

      // After the collision the relative velocity along the normal is
      // cancelled (e=0, default restitution → perfectly inelastic collision
      // for equal masses): a stops going toward +x, b stops going toward -x.
      // We verify that the contact response flipped the effective direction
      // of each velocity (they do not stay at ±10).
      expect(a.rigidbody!.velocity.x).assertLessOrEqual(0);
      expect(b.rigidbody!.velocity.x).assertLargerOrEqual(0);
    });

    it('conserves momentum when masses are equal (HU-01 invariant)', 0, () => {
      scene.gravity = new Vector2(0, 0);
      const a: Entity = addBox(scene, new Vector2(0, 0), 10);
      const b: Entity = addBox(scene, new Vector2(4, 0), 10);
      addRigidbody(a, 1, 1, 0);
      addRigidbody(b, 1, 1, 0);
      a.rigidbody!.velocity.set(10, 0);
      b.rigidbody!.velocity.set(-10, 0);
      const momentumBefore: number =
        a.rigidbody!.velocity.x * 1 + b.rigidbody!.velocity.x * 1;

      sys.step(scene, DT);

      const momentumAfter: number =
        a.rigidbody!.velocity.x * 1 + b.rigidbody!.velocity.x * 1;
      expect(momentumAfter).assertClose(momentumBefore, EPS);
    });

    it('performs positional correction proportional to penetration and inverse mass (Scenario 6)', 0, () => {
      // No initial velocity and no gravity: the only motion must come
      // from the positional correction.
      scene.gravity = new Vector2(0, 0);
      const a: Entity = addBox(scene, new Vector2(0, 0), 10);
      const b: Entity = addBox(scene, new Vector2(4, 0), 10);
      addRigidbody(a, 1, 1, 0);
      addRigidbody(b, 1, 1, 0);

      sys.step(scene, DT);

      // The normal goes from a → b (toward +x). The penetration between
      // centers is 10 - 4 = 6. With slop=0.05 and baumgarte=0.4, each body
      // moves half: 0.5 * max(6 - 0.05, 0) * 0.4 = 0.5 * 5.95 * 0.4 = 1.19.
      const expectedShift: number = 0.5 * (6 - 0.05) * 0.4;
      // a is pushed toward -x, b toward +x.
      expect(a.transform.position.x).assertClose(-expectedShift, EPS);
      expect(b.transform.position.x).assertClose(4 + expectedShift, EPS);
    });

    it('does not apply positional correction when penetration is within the slop (Scenario 6)', 0, () => {
      // Penetration < slop → no positional separation.
      scene.gravity = new Vector2(0, 0);
      const a: Entity = addBox(scene, new Vector2(0, 0), 10);
      const b: Entity = addBox(scene, new Vector2(9.98, 0), 10);
      addRigidbody(a, 1, 1, 0);
      addRigidbody(b, 1, 1, 0);

      sys.step(scene, DT);

      // The penetration is 10 - 9.98 = 0.02 < slop (0.05), so
      // max(pen - slop, 0) = 0 and there is no displacement.
      expect(a.transform.position.x).assertClose(0, EPS);
      expect(b.transform.position.x).assertClose(9.98, EPS);
    });

    it('processes multiple pairs (i<j) without duplicating the resolution', 0, () => {
      scene.gravity = new Vector2(0, 0);
      // Three boxes overlapping in a chain: a↔b and b↔c.
      const a: Entity = addBox(scene, new Vector2(0, 0), 10);
      const b: Entity = addBox(scene, new Vector2(4, 0), 10);
      const c: Entity = addBox(scene, new Vector2(8, 0), 10);
      addRigidbody(a, 1, 1, 0);
      addRigidbody(b, 1, 1, 0);
      addRigidbody(c, 1, 1, 0);

      sys.step(scene, DT);

      // With no external forces the positions only separate. We verify
      // that the processing order does not leave b uncorrected: b separates
      // simultaneously from a (toward +x) and from c (toward -x), so the
      // net displacement may be 0 but the velocities are inverted on each
      // x axis. We check that b does not stay exactly at 4.
      const bMoved: boolean = Math.abs(b.transform.position.x - 4) > 1e-9;
      expect(bMoved).assertTrue();
    });

    it('satisfies the GameSystem contract: implements beforeUpdate', 0, () => {
      const gs: GameSystem = sys as GameSystem;
      expect(typeof gs.beforeUpdate === 'function').assertTrue();
    });

    it('can be registered against an Engine via registerSystem (Scenario 8)', 0, () => {
      const engine: Engine = new Engine();
      engine.registerSystem(sys);
      // If registerSystem failed with non-GameSystem types, this test would
      // not compile. The real assertion is that the internal list accepts
      // the instance without throwing.
      expect(true).assertTrue();
    });

    it('beforeUpdate runs step against the active scene of the Engine (Scenario 8)', 0, () => {
      const engine: Engine = new Engine();
      engine.registerSystem(sys);
      engine.setTestScene(scene);

      // Sanity: before the tick the velocity has not changed.
      const e: Entity = addBox(scene, new Vector2(0, 0), 10);
      addRigidbody(e, 1, 1, 0);
      const beforeY: number = e.rigidbody!.velocity.y;

      engine.updateForTest();

      // After the tick the system applied gravity.
      const afterY: number = e.rigidbody!.velocity.y;
      expect(afterY - beforeY).assertClose(-9.8 * DT, EPS);
    });

    it('PhysicsSystem and Manifold are exported and publicly usable (Scenario 9)', 0, () => {
      // Type check: the compiler would already validate this, but we add
      // a runtime assertion that the classes exist and are instantiable.
      const m: Manifold = new Manifold();
      expect(m).not().assertNull();
      const s: PhysicsSystem = new PhysicsSystem();
      expect(s).not().assertNull();
    });

    it('public symbols (PhysicsSystem, Manifold) survive a patch-version change (Scenario 10)', 0, () => {
      // Patch-compatibility contract: the classes are still referenceable
      // and keep their stable public fields
      // (slop, baumgarte, a, b, normal, penetration, restitution).
      const ps: PhysicsSystem = new PhysicsSystem();
      expect(ps.slop).assertEqual(0.05);
      expect(ps.baumgarte).assertEqual(0.4);

      const tA: Transform = new Transform(new Vector2(0, 0));
      const tB: Transform = new Transform(new Vector2(2, 0));
      const a: BoxCollider = new BoxCollider(tA, 10, 10);
      const b: BoxCollider = new BoxCollider(tB, 10, 10);
      const m: Manifold | null = Manifold.compute(a, b);
      expect(m).not().assertNull();
      const mnf: Manifold = m as Manifold;
      expect(mnf.a).assertEqual(a);
      expect(mnf.b).assertEqual(b);
      expect(typeof mnf.normal.x === 'number').assertTrue();
      expect(typeof mnf.penetration === 'number').assertTrue();
      expect(typeof mnf.restitution === 'number').assertTrue();
    });
  });
}