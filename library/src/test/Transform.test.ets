/**
 * Source feature: .infO404/docs/features/apiCompatibility/apiCompatibility.feature (HU-09)
 * Scenarios covered: each public module has at least one unit test (Scenario 4)
 * Target symbol: Transform
 */
import { describe, it, expect } from '@ohos/hypium';
import { Transform } from '../main/ets/scene/Transform';
import { Vector2 } from '../main/ets/math/Vector2';

export default function transformTest() {
  describe('Transform', () => {
    it('default position is (0, 0)', 0, () => {
      const t: Transform = new Transform();
      expect(t.position.x).assertEqual(0);
      expect(t.position.y).assertEqual(0);
    });

    it('default scale is (1, 1)', 0, () => {
      const t: Transform = new Transform();
      expect(t.scale.x).assertEqual(1);
      expect(t.scale.y).assertEqual(1);
    });

    it('default rotation is 0', 0, () => {
      const t: Transform = new Transform();
      expect(t.rotation).assertEqual(0);
    });

    it('constructor with Vector2 assigns the initial position', 0, () => {
      const t: Transform = new Transform(new Vector2(3, -7));
      expect(t.position.x).assertEqual(3);
      expect(t.position.y).assertEqual(-7);
    });

    it('mutating position does NOT mutate the Vector2 passed to the constructor', 0, () => {
      const original: Vector2 = new Vector2(1, 1);
      const t: Transform = new Transform(original);
      t.position = new Vector2(99, 99);
      expect(original.x).assertEqual(1);
      expect(original.y).assertEqual(1);
    });

    it('writing scale and rotation persists the values', 0, () => {
      const t: Transform = new Transform();
      t.scale = new Vector2(2.5, 0.5);
      t.rotation = 1.57;
      expect(t.scale.x).assertClose(2.5, 1e-9);
      expect(t.scale.y).assertClose(0.5, 1e-9);
      expect(t.rotation).assertClose(1.57, 1e-9);
    });
  });
}