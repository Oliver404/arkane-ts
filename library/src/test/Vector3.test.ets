/**
 * Source feature: .infO404/docs/features/utilities/utilities.feature (HU-06)
 * Feature: Provide Vector3, Rect, and MathUtils APIs
 * Scenarios covered:
 *   - Scenario 1: Vector3 basic operations
 *   - Scenario 2: Vector3 static factory zero()
 */
import { describe, it, expect } from '@ohos/hypium';
import { Vector3 } from '../main/ets/math/Vector3';

export default function vector3Test() {
  describe('Vector3', () => {
    it('the default constructor leaves the vector at (0, 0, 0) (Scenario 1)', 0, () => {
      const v = new Vector3();
      expect(v.x).assertEqual(0);
      expect(v.y).assertEqual(0);
      expect(v.z).assertEqual(0);
    });

    it('the constructor with x, y, z stores the three components (Scenario 1)', 0, () => {
      const v = new Vector3(1, 2, 3);
      expect(v.x).assertEqual(1);
      expect(v.y).assertEqual(2);
      expect(v.z).assertEqual(3);
    });

    it('clone returns a new instance with the same values (Scenario 1)', 0, () => {
      const a = new Vector3(1, 2, 3);
      const b = a.clone();
      expect(b.x).assertEqual(1);
      expect(b.y).assertEqual(2);
      expect(b.z).assertEqual(3);
      expect(b === a).assertFalse();
    });

    it('mutating the clone does not affect the original vector (Scenario 1)', 0, () => {
      const a = new Vector3(1, 2, 3);
      const b = a.clone();
      b.set(9, 9, 9);
      expect(a.x).assertEqual(1);
      expect(a.y).assertEqual(2);
      expect(a.z).assertEqual(3);
    });

    it('set mutates the components and returns this (Scenario 1)', 0, () => {
      const v = new Vector3();
      const ret = v.set(5, 6, 7);
      expect(v.x).assertEqual(5);
      expect(v.y).assertEqual(6);
      expect(v.z).assertEqual(7);
      expect(ret === v).assertTrue();
    });

    it('add sums component by component mutating this (Scenario 1)', 0, () => {
      const a = new Vector3(1, 2, 3);
      a.add(new Vector3(3, 4, 5));
      expect(a.x).assertEqual(4);
      expect(a.y).assertEqual(6);
      expect(a.z).assertEqual(8);
    });

    it('add returns this to allow chaining (Scenario 1)', 0, () => {
      const a = new Vector3(1, 2, 3);
      const ret = a.add(new Vector3(1, 1, 1));
      expect(ret === a).assertTrue();
    });

    it('add does not modify the vector passed as argument (Scenario 1)', 0, () => {
      const a = new Vector3(1, 2, 3);
      const b = new Vector3(3, 4, 5);
      a.add(b);
      expect(b.x).assertEqual(3);
      expect(b.y).assertEqual(4);
      expect(b.z).assertEqual(5);
    });

    it('subtract subtracts component by component mutating this (Scenario 1)', 0, () => {
      const a = new Vector3(5, 5, 5);
      a.subtract(new Vector3(2, 1, 4));
      expect(a.x).assertEqual(3);
      expect(a.y).assertEqual(4);
      expect(a.z).assertEqual(1);
    });

    it('subtract returns this to allow chaining (Scenario 1)', 0, () => {
      const a = new Vector3(5, 5, 5);
      const ret = a.subtract(new Vector3(1, 1, 1));
      expect(ret === a).assertTrue();
    });

    it('multiply scales the three components mutating this (Scenario 1)', 0, () => {
      const v = new Vector3(2, 3, 4);
      v.multiply(4);
      expect(v.x).assertEqual(8);
      expect(v.y).assertEqual(12);
      expect(v.z).assertEqual(16);
    });

    it('multiply by a negative scalar reverses the direction of the vector (Scenario 1)', 0, () => {
      const v = new Vector3(1, -2, 3);
      const ret = v.multiply(-2);
      expect(v.x).assertEqual(-2);
      expect(v.y).assertEqual(4);
      expect(v.z).assertEqual(-6);
      expect(ret === v).assertTrue();
    });

    it('multiply by zero leaves the vector at the origin (Scenario 1)', 0, () => {
      const v = new Vector3(1, 2, 3);
      v.multiply(0);
      expect(v.x).assertEqual(0);
      expect(v.y).assertEqual(0);
      expect(v.z).assertEqual(0);
    });

    it('length of (1, 2, 2) is 3 (Scenario 1)', 0, () => {
      expect(new Vector3(1, 2, 2).length()).assertEqual(3);
    });

    it('length of (1, 2, 3) is the square root of 14 (Scenario 1)', 0, () => {
      expect(new Vector3(1, 2, 3).length()).assertClose(Math.sqrt(14), 1e-9);
    });

    it('length of the zero vector is 0 (Scenario 1)', 0, () => {
      expect(new Vector3(0, 0, 0).length()).assertEqual(0);
    });

    it('length ignores the sign of the components (Scenario 1)', 0, () => {
      expect(new Vector3(-1, -2, -2).length()).assertEqual(3);
    });

    it('length does not mutate the vector (Scenario 1)', 0, () => {
      const v = new Vector3(1, 2, 2);
      v.length();
      expect(v.x).assertEqual(1);
      expect(v.y).assertEqual(2);
      expect(v.z).assertEqual(2);
    });

    it('normalize produces a unit vector when the length is greater than 0 (Scenario 1)', 0, () => {
      const v = new Vector3(1, 2, 3).normalize();
      expect(Math.abs(v.length() - 1)).assertLess(1e-9);
    });

    it('normalize preserves the direction of the vector (Scenario 1)', 0, () => {
      const v = new Vector3(0, 0, 5).normalize();
      expect(Math.abs(v.x)).assertLess(1e-9);
      expect(Math.abs(v.y)).assertLess(1e-9);
      expect(v.z).assertClose(1, 1e-9);
    });

    it('normalize mutates this and returns this (Scenario 1)', 0, () => {
      const v = new Vector3(3, 0, 4);
      const ret = v.normalize();
      expect(ret === v).assertTrue();
      expect(v.x).assertClose(0.6, 1e-9);
      expect(v.z).assertClose(0.8, 1e-9);
    });

    it('normalize on the zero vector is a no-op and does not throw (Scenario 1)', 0, () => {
      const v = new Vector3(0, 0, 0).normalize();
      expect(v.x).assertEqual(0);
      expect(v.y).assertEqual(0);
      expect(v.z).assertEqual(0);
    });

    it('Vector3.zero() returns a vector with all three components set to 0 (Scenario 2)', 0, () => {
      const v = Vector3.zero();
      expect(v.x).assertEqual(0);
      expect(v.y).assertEqual(0);
      expect(v.z).assertEqual(0);
    });

    it('Vector3.zero() returns a new instance on each call (Scenario 2)', 0, () => {
      const a = Vector3.zero();
      const b = Vector3.zero();
      expect(a === b).assertFalse();
      a.set(1, 1, 1);
      expect(b.x).assertEqual(0);
      expect(b.y).assertEqual(0);
      expect(b.z).assertEqual(0);
    });
  });
}
