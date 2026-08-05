import { describe, it, expect } from '@ohos/hypium';
import { BoxCollider } from '../main/ets/physics/BoxCollider';
import { CircleCollider } from '../main/ets/physics/CircleCollider';
import { Transform } from '../main/ets/scene/Transform';
import { Vector2 } from '../main/ets/math/Vector2';

export default function boxColliderTest() {
  describe('BoxCollider (HU-10)', () => {
    it('Box↔Box: two overlapping boxes collide (Scenario 1)', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(5, 0));
      const a = new BoxCollider(ta, 10, 10);
      const b = new BoxCollider(tb, 10, 10);
      expect(a.isColliding(b)).assertTrue();
      expect(b.isColliding(a)).assertTrue();
    });

    it('Box↔Box: two separated boxes do not collide (Scenario 1)', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(100, 100));
      const a = new BoxCollider(ta, 10, 10);
      const b = new BoxCollider(tb, 10, 10);
      expect(a.isColliding(b)).assertFalse();
    });

    it('Box↔Box: tangent boxes (edge to edge) count as collision', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(10, 0));
      const a = new BoxCollider(ta, 10, 10); // right edge at x=5
      const b = new BoxCollider(tb, 10, 10); // left edge at x=5
      expect(a.isColliding(b)).assertTrue();
    });

    it('Box↔Circle: circle inside the box collides (Scenario 2)', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(2, 0));
      const box = new BoxCollider(ta, 10, 10);
      const circ = new CircleCollider(tb, 5);
      expect(box.isColliding(circ)).assertTrue();
      // Symmetry via BoxCollider↔CircleCollider dispatch (direction-independent).
      expect(circ.isColliding(box)).assertTrue();
    });

    it('Box↔Circle: circle outside the box by distance > radius does not collide', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(100, 0));
      const box = new BoxCollider(ta, 10, 10);
      const circ = new CircleCollider(tb, 5);
      expect(box.isColliding(circ)).assertFalse();
      expect(circ.isColliding(box)).assertFalse();
    });

    it('Box↔Circle: circle tangent to the box edge counts as collision', 0, () => {
      const ta = new Transform(new Vector2(0, 0));
      const tb = new Transform(new Vector2(10, 0)); // center exactly on the box's right edge (x=5)
      const box = new BoxCollider(ta, 10, 10);     // halfW = 5, right=5
      const circ = new CircleCollider(tb, 5);      // radius = 5, distance = 5
      expect(box.isColliding(circ)).assertTrue();
    });

    it('friction and restitution default to 0 (HU-10)', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const c = new BoxCollider(t, 10, 10);
      expect(c.friction).assertEqual(0);
      expect(c.restitution).assertEqual(0);
    });

    it('friction and restitution are assignable (HU-10)', 0, () => {
      const t = new Transform(new Vector2(0, 0));
      const c = new BoxCollider(t, 10, 10);
      c.friction = 0.5;
      c.restitution = 0.8;
      expect(c.friction).assertEqual(0.5);
      expect(c.restitution).assertEqual(0.8);
    });
  });
}
