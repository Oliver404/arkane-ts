import { describe, it, expect } from '@ohos/hypium';
import { Rigidbody } from '../main/ets/physics/Rigidbody';
import { Transform } from '../main/ets/scene/Transform';
import { Vector2 } from '../main/ets/math/Vector2';
import { Entity } from '../main/ets/scene/Entity';

export default function rigidbodyTest() {
  describe('Rigidbody (HU-12)', () => {
    it('defaults: mass=1, gravityScale=1, drag=0, velocity=(0,0)', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const rb = new Rigidbody(t);
      expect(rb.mass).assertEqual(1);
      expect(rb.gravityScale).assertEqual(1);
      expect(rb.drag).assertEqual(0);
      expect(rb.velocity.x).assertEqual(0);
      expect(rb.velocity.y).assertEqual(0);
    });

    it('update(dt) integrates velocity into position (Euler)', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const rb = new Rigidbody(t);
      rb.velocity = new Vector2(10, 0);
      rb.update(0.5);
      // x = 0 + 10 * 0.5 = 5
      expect(t.position.x).assertEqual(5);
      expect(t.position.y).assertEqual(0);
    });

    it('applyImpulse divides by mass: v += impulse/mass', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const rb = new Rigidbody(t);
      rb.mass = 2;
      rb.applyImpulse(new Vector2(10, 0));
      expect(rb.velocity.x).assertEqual(5);
      expect(rb.velocity.y).assertEqual(0);
    });

    it('applyImpulse on a static body (mass<=0) is a no-op', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const rb = new Rigidbody(t);
      rb.mass = 0; // static / infinite mass
      rb.applyImpulse(new Vector2(100, 100));
      expect(rb.velocity.x).assertEqual(0);
      expect(rb.velocity.y).assertEqual(0);
    });

    it('applyImpulse with negative mass is a no-op', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const rb = new Rigidbody(t);
      rb.mass = -1;
      rb.applyImpulse(new Vector2(50, 50));
      expect(rb.velocity.x).assertEqual(0);
      expect(rb.velocity.y).assertEqual(0);
    });

    it('drag reduces velocity in update (formula 1 - drag*dt)', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const rb = new Rigidbody(t);
      rb.velocity = new Vector2(10, 0);
      rb.drag = 1;
      rb.update(0.1);
      // velocity x = 10 * (1 - 1*0.1) = 10 * 0.9 = 9
      expect(Math.abs(rb.velocity.x - 9) < 1e-9).assertTrue();
      // position x = 0 + 9 * 0.1 = 0.9
      expect(Math.abs(t.position.x - 0.9) < 1e-9).assertTrue();
    });

    it('saturated drag (k<=0) drives velocity to 0', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const rb = new Rigidbody(t);
      rb.velocity = new Vector2(10, 0);
      rb.drag = 100;
      rb.update(0.1); // k = 1 - 100*0.1 = -9
      expect(rb.velocity.x).assertEqual(0);
      expect(rb.velocity.y).assertEqual(0);
    });

    it('Entity can assign a Rigidbody via setRigidbody (HU-12)', 0, () => {
      const e: Entity = new Entity();
      const rb: Rigidbody = new Rigidbody(e.transform);
      e.setRigidbody(rb);
      expect(e.rigidbody).not().assertNull();
      expect(e.rigidbody === rb).assertTrue();
    });
  });
}
