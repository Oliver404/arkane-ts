/**
 * Source feature: .infO404/docs/features/utilities/utilities.feature (HU-06)
 * Feature: Provide Vector3, Rect, and MathUtils APIs
 * Scenarios covered:
 *   - Scenario 6: MathUtils.clamp(value, min, max)
 *   - Scenario 7: MathUtils.lerp(a, b, t)
 *
 * Background: the math utilities are pure static methods with no global
 * state; that is why there is no setup hook nor test doubles.
 */
import { describe, it, expect } from '@ohos/hypium';
import { MathUtils } from '../main/ets/math/MathUtils';

export default function mathUtilsTest() {
  describe('MathUtils', () => {
    // ===== Scenario 6: clamp =====

    it('clamp returns the value itself when within the range (Scenario 6)', 0, () => {
      expect(MathUtils.clamp(5, 0, 10)).assertEqual(5);
    });

    it('clamp returns min when the value is less than min (Scenario 6)', 0, () => {
      expect(MathUtils.clamp(-5, 0, 10)).assertEqual(0);
    });

    it('clamp returns max when the value is greater than max (Scenario 6)', 0, () => {
      expect(MathUtils.clamp(15, 0, 10)).assertEqual(10);
    });

    it('clamp returns the limit when the value matches min or max (Scenario 6)', 0, () => {
      expect(MathUtils.clamp(0, 0, 10)).assertEqual(0);
      expect(MathUtils.clamp(10, 0, 10)).assertEqual(10);
    });

    it('clamp works with negative ranges (Scenario 6)', 0, () => {
      expect(MathUtils.clamp(-50, -10, -1)).assertEqual(-10);
      expect(MathUtils.clamp(0, -10, -1)).assertEqual(-1);
      expect(MathUtils.clamp(-5, -10, -1)).assertEqual(-5);
    });

    it('clamp works with decimal values (Scenario 6)', 0, () => {
      expect(MathUtils.clamp(0.75, 0, 1)).assertClose(0.75, 1e-9);
      expect(MathUtils.clamp(1.25, 0, 1)).assertClose(1, 1e-9);
      expect(MathUtils.clamp(-0.25, 0, 1)).assertEqual(0);
    });

    it('clamp with min equal to max collapses any value to that limit (Scenario 6)', 0, () => {
      expect(MathUtils.clamp(100, 7, 7)).assertEqual(7);
      expect(MathUtils.clamp(-100, 7, 7)).assertEqual(7);
    });

    it('clamp is pure: repeating the call yields the same result (Scenario 6)', 0, () => {
      const first = MathUtils.clamp(42, 0, 10);
      const second = MathUtils.clamp(42, 0, 10);
      expect(first).assertEqual(second);
      expect(first).assertEqual(10);
    });

    it('clamp is idempotent when applied to its own result (Scenario 6)', 0, () => {
      const once = MathUtils.clamp(99, 0, 10);
      expect(MathUtils.clamp(once, 0, 10)).assertEqual(once);
    });

    // ===== Scenario 7: lerp =====

    it('lerp with t=0 returns a (Scenario 7)', 0, () => {
      expect(MathUtils.lerp(0, 10, 0)).assertEqual(0);
      expect(MathUtils.lerp(3, 9, 0)).assertEqual(3);
    });

    it('lerp with t=1 returns b (Scenario 7)', 0, () => {
      expect(MathUtils.lerp(0, 10, 1)).assertEqual(10);
      expect(MathUtils.lerp(3, 9, 1)).assertEqual(9);
    });

    it('lerp with t=0.5 returns the midpoint (Scenario 7)', 0, () => {
      expect(MathUtils.lerp(0, 10, 0.5)).assertClose(5, 1e-9);
      expect(MathUtils.lerp(-10, 10, 0.5)).assertEqual(0);
    });

    it('lerp applies the formula a + (b - a) * t (Scenario 7)', 0, () => {
      expect(MathUtils.lerp(2, 8, 0.25)).assertClose(3.5, 1e-9);
      expect(MathUtils.lerp(2, 8, 0.75)).assertClose(6.5, 1e-9);
    });

    it('lerp interpolates in descending order when a is greater than b (Scenario 7)', 0, () => {
      expect(MathUtils.lerp(10, 0, 0.25)).assertClose(7.5, 1e-9);
      expect(MathUtils.lerp(10, 0, 1)).assertEqual(0);
    });

    it('lerp works with negative values for a and b (Scenario 7)', 0, () => {
      expect(MathUtils.lerp(-4, -1, 0.5)).assertClose(-2.5, 1e-9);
    });

    it('lerp with a equal to b returns that same value for any t (Scenario 7)', 0, () => {
      expect(MathUtils.lerp(5, 5, 0)).assertEqual(5);
      expect(MathUtils.lerp(5, 5, 0.5)).assertEqual(5);
      expect(MathUtils.lerp(5, 5, 1)).assertEqual(5);
    });

    it('lerp is monotonic as t advances within [0, 1] (Scenario 7)', 0, () => {
      const t25 = MathUtils.lerp(0, 100, 0.25);
      const t50 = MathUtils.lerp(0, 100, 0.5);
      const t75 = MathUtils.lerp(0, 100, 0.75);
      expect(t25).assertLess(t50);
      expect(t50).assertLess(t75);
    });

    it('lerp is pure: repeating the call yields the same result (Scenario 7)', 0, () => {
      const first = MathUtils.lerp(1, 2, 0.3);
      const second = MathUtils.lerp(1, 2, 0.3);
      expect(first).assertEqual(second);
    });
  });
}
