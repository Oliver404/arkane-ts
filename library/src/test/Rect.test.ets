/**
 * Source feature: .infO404/docs/features/utilities/utilities.feature (HU-06)
 * Feature: Provide Vector3, Rect, and MathUtils APIs
 * Scenarios covered:
 *   - Scenario 3: Rect construction and basic accessors
 *   - Scenario 4: Rect.contains(point) hit-test
 *   - Scenario 5: Rect.intersects(other) overlap test
 *
 * Note: the .feature does not define the behaviour on exact edges
 * (a point right on an edge, rects that only touch). Those cases are NOT
 * asserted here so we do not pin a contract the story does not declare.
 */
import { describe, it, expect } from '@ohos/hypium';
import { Rect } from '../main/ets/math/Rect';
import { Vector2 } from '../main/ets/math/Vector2';

export default function rectTest() {
  describe('Rect', () => {
    // ===== Scenario 3: construction and accessors =====

    it('constructor stores x, y, width, and height (Scenario 3)', 0, () => {
      const r = new Rect(10, 20, 100, 50);
      expect(r.x).assertEqual(10);
      expect(r.y).assertEqual(20);
      expect(r.width).assertEqual(100);
      expect(r.height).assertEqual(50);
    });

    it('left and top return the rect origin (Scenario 3)', 0, () => {
      const r = new Rect(10, 20, 100, 50);
      expect(r.left).assertEqual(10);
      expect(r.top).assertEqual(20);
    });

    it('right is x + width and bottom is y + height (Scenario 3)', 0, () => {
      const r = new Rect(10, 20, 100, 50);
      expect(r.right).assertEqual(110);
      expect(r.bottom).assertEqual(70);
    });

    it('accessors work with origin at (0, 0) (Scenario 3)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.left).assertEqual(0);
      expect(r.top).assertEqual(0);
      expect(r.right).assertEqual(100);
      expect(r.bottom).assertEqual(50);
    });

    it('accessors work with negative origin (Scenario 3)', 0, () => {
      const r = new Rect(-30, -15, 10, 5);
      expect(r.left).assertEqual(-30);
      expect(r.top).assertEqual(-15);
      expect(r.right).assertEqual(-20);
      expect(r.bottom).assertEqual(-10);
    });

    it('accessors support decimal coordinates and sizes (Scenario 3)', 0, () => {
      const r = new Rect(1.5, 2.25, 3.5, 4.75);
      expect(r.right).assertClose(5, 1e-9);
      expect(r.bottom).assertClose(7, 1e-9);
    });

    it('accessors are computed: moving x relocates left and right (Scenario 3)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      r.x = 25;
      expect(r.left).assertEqual(25);
      expect(r.right).assertEqual(125);
    });

    it('accessors are computed: changing height relocates bottom (Scenario 3)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      r.height = 80;
      expect(r.top).assertEqual(0);
      expect(r.bottom).assertEqual(80);
    });

    it('a zero-size rect collapses left with right and top with bottom (Scenario 3)', 0, () => {
      const r = new Rect(7, 9, 0, 0);
      expect(r.left).assertEqual(r.right);
      expect(r.top).assertEqual(r.bottom);
    });

    // ===== Scenario 4: contains(point) =====

    it('contains returns true for a point at the center of the rect (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.contains(new Vector2(50, 25))).assertTrue();
    });

    it('contains returns true for an interior point near a corner (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.contains(new Vector2(1, 1))).assertTrue();
      expect(r.contains(new Vector2(99, 49))).assertTrue();
    });

    it('contains returns false for a point to the left of the rect (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.contains(new Vector2(-1, 25))).assertFalse();
    });

    it('contains returns false for a point to the right of the rect (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.contains(new Vector2(101, 25))).assertFalse();
    });

    it('contains returns false for a point above the rect (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.contains(new Vector2(50, -1))).assertFalse();
    });

    it('contains returns false for a point below the rect (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.contains(new Vector2(50, 51))).assertFalse();
    });

    it('contains returns false for an off-diagonal point (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      expect(r.contains(new Vector2(200, 200))).assertFalse();
    });

    it('contains respects the rect offset (Scenario 4)', 0, () => {
      const r = new Rect(100, 100, 50, 50);
      expect(r.contains(new Vector2(125, 125))).assertTrue();
      expect(r.contains(new Vector2(25, 25))).assertFalse();
    });

    it('contains works with rects of negative coordinates (Scenario 4)', 0, () => {
      const r = new Rect(-50, -50, 100, 100);
      expect(r.contains(new Vector2(-25, -25))).assertTrue();
      expect(r.contains(new Vector2(-75, 0))).assertFalse();
    });

    it('contains does not mutate the rect or the evaluated point (Scenario 4)', 0, () => {
      const r = new Rect(0, 0, 100, 50);
      const p = new Vector2(50, 25);
      r.contains(p);
      expect(r.x).assertEqual(0);
      expect(r.y).assertEqual(0);
      expect(r.width).assertEqual(100);
      expect(r.height).assertEqual(50);
      expect(p.x).assertEqual(50);
      expect(p.y).assertEqual(25);
    });

    // ===== Scenario 5: intersects(other) =====

    it('intersects returns true when two rects partially overlap (Scenario 5)', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(50, 50, 100, 100);
      expect(a.intersects(b)).assertTrue();
    });

    it('intersects returns true when one rect fully contains the other (Scenario 5)', 0, () => {
      const outer = new Rect(0, 0, 200, 200);
      const inner = new Rect(50, 50, 20, 20);
      expect(outer.intersects(inner)).assertTrue();
      expect(inner.intersects(outer)).assertTrue();
    });

    it('intersects returns true for two identical rects (Scenario 5)', 0, () => {
      const a = new Rect(10, 10, 30, 30);
      const b = new Rect(10, 10, 30, 30);
      expect(a.intersects(b)).assertTrue();
    });

    it('intersects returns false when separated on the X axis (Scenario 5)', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(200, 0, 100, 100);
      expect(a.intersects(b)).assertFalse();
    });

    it('intersects returns false when separated on the Y axis (Scenario 5)', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(0, 200, 100, 100);
      expect(a.intersects(b)).assertFalse();
    });

    it('intersects returns false when they overlap on X but not on Y (Scenario 5)', 0, () => {
      const a = new Rect(0, 0, 100, 10);
      const b = new Rect(50, 500, 100, 10);
      expect(a.intersects(b)).assertFalse();
    });

    it('intersects is symmetric between the two rects (Scenario 5)', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(50, 50, 100, 100);
      const c = new Rect(500, 500, 10, 10);
      expect(a.intersects(b)).assertEqual(b.intersects(a));
      expect(a.intersects(c)).assertEqual(c.intersects(a));
    });

    it('intersects returns true when compared with itself (Scenario 5)', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      expect(a.intersects(a)).assertTrue();
    });

    it('intersects works with rects of negative coordinates (Scenario 5)', 0, () => {
      const a = new Rect(-100, -100, 100, 100);
      const b = new Rect(-50, -50, 200, 200);
      const c = new Rect(50, 50, 10, 10);
      expect(a.intersects(b)).assertTrue();
      expect(a.intersects(c)).assertFalse();
    });

    it('intersects does not mutate either of the two rects (Scenario 5)', 0, () => {
      const a = new Rect(0, 0, 100, 100);
      const b = new Rect(50, 50, 100, 100);
      a.intersects(b);
      expect(a.x).assertEqual(0);
      expect(a.width).assertEqual(100);
      expect(b.x).assertEqual(50);
      expect(b.height).assertEqual(100);
    });
  });
}
