import { describe, it, expect } from '@ohos/hypium';
import { CircleCollider } from '../main/ets/physics/CircleCollider';
import { BoxCollider } from '../main/ets/physics/BoxCollider';
import { Transform } from '../main/ets/scene/Transform';
import { Vector2 } from '../main/ets/math/Vector2';

export default function circleColliderTest() {
  describe('CircleCollider (HU-10)', () => {
    it('Circle↔Circle: two overlapping circles collide (Scenario 3)', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(3, 0));
      const a = new CircleCollider(ta, 5);
      const b = new CircleCollider(tb, 5);
      expect(a.isColliding(b)).assertTrue();
      expect(b.isColliding(a)).assertTrue();
    });

    it('Circle↔Circle: two separated circles do not collide', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(50, 0));
      const a = new CircleCollider(ta, 5);
      const b = new CircleCollider(tb, 5);
      expect(a.isColliding(b)).assertFalse();
    });

    it('Circle↔Circle: tangent circles count as colliding', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(10, 0)); // r1+r2 = 10
      const a = new CircleCollider(ta, 5);
      const b = new CircleCollider(tb, 5);
      expect(a.isColliding(b)).assertTrue();
    });

    it('Circle↔Box: a circle near the box edge delegates correctly (Scenario 4)', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(11, 0));
      const box = new BoxCollider(ta, 10, 10);   // right edge = 5
      const circ = new CircleCollider(tb, 5);    // distance to center = 11, radius 5 -> gap 6 > 5, no overlap
      expect(circ.isColliding(box)).assertFalse();
      expect(box.isColliding(circ)).assertFalse();
    });

    it('default friction and restitution are 0 (HU-10)', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const c = new CircleCollider(t, 5);
      expect(c.friction).assertEqual(0);
      expect(c.restitution).assertEqual(0);
    });

    it('friction and restitution are assignable (HU-10)', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const c = new CircleCollider(t, 5);
      c.friction = 0.3;
      c.restitution = 0.95;
      expect(c.friction).assertEqual(0.3);
      expect(c.restitution).assertEqual(0.95);
    });
  });
}
