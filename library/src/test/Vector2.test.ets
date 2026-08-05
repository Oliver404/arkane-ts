import { describe, it, expect } from '@ohos/hypium';
import { Vector2 } from '../main/ets/math/Vector2';

export default function vector2Test() {
  describe('Vector2', () => {
    it('default constructor: x=0, y=0', 0, () => {
      const v = new Vector2();
      expect(v.x).assertEqual(0);
      expect(v.y).assertEqual(0);
    });

    it('constructor with x, y', 0, () => {
      const v = new Vector2(3, 4);
      expect(v.x).assertEqual(3);
      expect(v.y).assertEqual(4);
    });

    it('clone returns a new instance with the same values', 0, () => {
      const a = new Vector2(3, 4);
      const b = a.clone();
      expect(b.x).assertEqual(3);
      expect(b.y).assertEqual(4);
      expect(b === a).assertFalse();
    });

    it('set mutates and returns this', 0, () => {
      const v = new Vector2();
      const ret = v.set(5, 6);
      expect(v.x).assertEqual(5);
      expect(v.y).assertEqual(6);
      expect(ret === v).assertTrue();
    });

    it('add mutates', 0, () => {
      const a = new Vector2(1, 2);
      a.add(new Vector2(3, 4));
      expect(a.x).assertEqual(4);
      expect(a.y).assertEqual(6);
    });

    it('subtract mutates', 0, () => {
      const a = new Vector2(5, 5);
      a.subtract(new Vector2(2, 1));
      expect(a.x).assertEqual(3);
      expect(a.y).assertEqual(4);
    });

    it('multiply by scalar mutates', 0, () => {
      const v = new Vector2(2, 3);
      v.multiply(4);
      expect(v.x).assertEqual(8);
      expect(v.y).assertEqual(12);
    });

    it('divide by scalar mutates (no zero-divide)', 0, () => {
      const v = new Vector2(8, 12);
      v.divide(4);
      expect(v.x).assertEqual(2);
      expect(v.y).assertEqual(3);
    });

    it('divide by zero is a no-op (does not throw)', 0, () => {
      const v = new Vector2(8, 12);
      v.divide(0);
      expect(v.x).assertEqual(8);
      expect(v.y).assertEqual(12);
    });

    it('length: (3, 4) -> 5', 0, () => {
      expect(new Vector2(3, 4).length()).assertEqual(5);
    });

    it('normalize produces unit vector when length > 0', 0, () => {
      const v = new Vector2(3, 4).normalize();
      expect(Math.abs(v.length() - 1)).assertLess(1e-9);
    });

    it('normalize is no-op when length is 0 (does not throw)', 0, () => {
      const v = new Vector2(0, 0).normalize();
      expect(v.x).assertEqual(0);
      expect(v.y).assertEqual(0);
    });

    it('distance between (0,0) and (3,4) is 5', 0, () => {
      expect(new Vector2(0, 0).distance(new Vector2(3, 4))).assertEqual(5);
    });

    it('static add returns a new vector', 0, () => {
      const r = Vector2.add(new Vector2(1, 2), new Vector2(3, 4));
      expect(r.x).assertEqual(4);
      expect(r.y).assertEqual(6);
    });

    it('static subtract returns a new vector', 0, () => {
      const r = Vector2.subtract(new Vector2(5, 5), new Vector2(2, 1));
      expect(r.x).assertEqual(3);
      expect(r.y).assertEqual(4);
    });

    it('static zero returns (0, 0)', 0, () => {
      const v = Vector2.zero();
      expect(v.x).assertEqual(0);
      expect(v.y).assertEqual(0);
    });
  });
}
