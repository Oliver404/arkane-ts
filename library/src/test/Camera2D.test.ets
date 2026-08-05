/**
 * Source feature: .infO404/docs/features/cameraFollow/cameraFollow.feature
 * Feature: Follow targets and look at points with Camera2D (HU-04, V1.1)
 *
 * Scenarios covered (HU-04):
 *   1. Follow a target entity
 *   2. Follow respects zoom
 *   3. Follow clamps to world bounds
 *   4. Look at a world point
 *   5. Follow / lookAt coexist with worldToScreen / screenToWorld
 *   6. Test coverage (implicitly covered by 1-5)
 *
 * Assumed contract (not implemented yet - TDD red phase):
 *   Camera2D.follow(target: Entity): void
 *   Camera2D.lookAt(point: Vector2): void
 *   Camera2D.update(): void
 *   Camera2D.setWorldBounds(minX: number, maxX: number, minY: number, maxY: number): void
 *
 * The asserts rely only on observable behaviour: the camera position and
 * the result of worldToScreen / screenToWorld. They are not coupled to the
 * internal mechanism that applies the follow.
 */
import { describe, it, expect } from '@ohos/hypium';
import { Camera2D } from '../main/ets/render/Camera2D';
import { Entity } from '../main/ets/scene/Entity';
import { Vector2 } from '../main/ets/math/Vector2';

const EPS = 1e-9;

function makeTarget(x: number, y: number): Entity {
  const e = new Entity();
  e.transform.position = new Vector2(x, y);
  return e;
}

function assertClose(actual: number, expected: number): void {
  expect(Math.abs(actual - expected) < EPS).assertTrue();
}

function assertCenteredOnScreen(cam: Camera2D, worldPos: Vector2): void {
  const screen = cam.worldToScreen(worldPos);
  assertClose(screen.x, cam.viewportWidth / 2);
  assertClose(screen.y, cam.viewportHeight / 2);
}

export default function camera2DTest() {
  describe('Camera2D', () => {
    it('worldToScreen with zoom=1: camera (0,0), viewport 466x466, world (0,0) -> screen (233, 233) (Scenario 1)', 0, () => {
      const cam = new Camera2D(466, 466);
      const screen = cam.worldToScreen(new Vector2(0, 0));
      expect(screen.x).assertEqual(233);
      expect(screen.y).assertEqual(233);
    });

    it('worldToScreen with zoom=2: camera (0,0), world (10, 0) -> screen (253, 233) (Scenario 2)', 0, () => {
      const cam = new Camera2D(466, 466);
      cam.zoom = 2;
      const screen = cam.worldToScreen(new Vector2(10, 0));
      expect(screen.x).assertEqual(253);
      expect(screen.y).assertEqual(233);
    });

    it('screenToWorld is the inverse of worldToScreen: round-trip within epsilon (Scenario 4)', 0, () => {
      const cam = new Camera2D(466, 466);
      cam.position = new Vector2(15, -7);
      cam.zoom = 2;

      const samples: Vector2[] = [
        new Vector2(0, 0),
        new Vector2(10, 20),
        new Vector2(-50, 50),
        new Vector2(100, -100)
      ];
      const eps = 1e-9;

      for (const p of samples) {
        const screen = cam.worldToScreen(p);
        const back = cam.screenToWorld(screen);
        expect(Math.abs(back.x - p.x) < eps).assertTrue();
        expect(Math.abs(back.y - p.y) < eps).assertTrue();
      }
    });

    it('follow(target) + update(): the camera centers on the target after moving its position (HU-04 Scenario 1)', 0, () => {
      const cam = new Camera2D(400, 300);
      const target = makeTarget(0, 0);

      cam.follow(target);
      target.transform.position = new Vector2(120, -45);
      cam.update();

      assertClose(cam.position.x, 120);
      assertClose(cam.position.y, -45);
      assertCenteredOnScreen(cam, target.transform.position);
    });

    it('follow(target) + update(): the camera follows the target across successive frames (HU-04 Scenario 1)', 0, () => {
      const cam = new Camera2D(400, 300);
      const target = makeTarget(0, 0);
      cam.follow(target);

      target.transform.position = new Vector2(10, 10);
      cam.update();
      assertClose(cam.position.x, 10);
      assertClose(cam.position.y, 10);

      target.transform.position = new Vector2(-250, 80);
      cam.update();
      assertClose(cam.position.x, -250);
      assertClose(cam.position.y, 80);
      assertCenteredOnScreen(cam, target.transform.position);
    });

    it('follow(target) with zoom=2: the target still stays at the center of the viewport (HU-04 Scenario 2)', 0, () => {
      const cam = new Camera2D(400, 300);
      cam.zoom = 2;
      const target = makeTarget(75, -30);

      cam.follow(target);
      cam.update();

      assertCenteredOnScreen(cam, target.transform.position);
      assertClose(cam.position.x, 75);
      assertClose(cam.position.y, -30);
    });

    it('follow(target) with zoom=0.5: centering is independent of the zoom factor (HU-04 Scenario 2)', 0, () => {
      const cam = new Camera2D(400, 300);
      cam.zoom = 0.5;
      const target = makeTarget(75, -30);

      cam.follow(target);
      cam.update();

      assertCenteredOnScreen(cam, target.transform.position);
    });

    it('follow with worldBounds: a target next to the min edge does not push the camera out of the world (HU-04 Scenario 3)', 0, () => {
      const cam = new Camera2D(400, 300);
      cam.setWorldBounds(0, 1000, 0, 800);
      const target = makeTarget(10, 20);

      cam.follow(target);
      cam.update();

      // half-extents with zoom=1: 400/2 = 200 on X, 300/2 = 150 on Y
      assertClose(cam.position.x, 200);
      assertClose(cam.position.y, 150);
      expect(cam.position.x - cam.viewportWidth / (2 * cam.zoom) >= 0).assertTrue();
      expect(cam.position.y - cam.viewportHeight / (2 * cam.zoom) >= 0).assertTrue();
    });

    it('follow with worldBounds: a target next to the max edge does not push the camera out of the world (HU-04 Scenario 3)', 0, () => {
      const cam = new Camera2D(400, 300);
      cam.setWorldBounds(0, 1000, 0, 800);
      const target = makeTarget(990, 790);

      cam.follow(target);
      cam.update();

      assertClose(cam.position.x, 800);
      assertClose(cam.position.y, 650);
      expect(cam.position.x + cam.viewportWidth / (2 * cam.zoom) <= 1000).assertTrue();
      expect(cam.position.y + cam.viewportHeight / (2 * cam.zoom) <= 800).assertTrue();
    });

    it('follow with worldBounds: a target far from the edges is centered without clamping (HU-04 Scenario 3)', 0, () => {
      const cam = new Camera2D(400, 300);
      cam.setWorldBounds(0, 1000, 0, 800);
      const target = makeTarget(500, 400);

      cam.follow(target);
      cam.update();

      assertClose(cam.position.x, 500);
      assertClose(cam.position.y, 400);
      assertCenteredOnScreen(cam, target.transform.position);
    });

    it('follow with worldBounds and zoom=2: the clamp uses the half-extents scaled by zoom (HU-04 Scenario 3)', 0, () => {
      const cam = new Camera2D(400, 300);
      cam.zoom = 2;
      cam.setWorldBounds(0, 1000, 0, 800);
      const target = makeTarget(10, 20);

      cam.follow(target);
      cam.update();

      // half-extents with zoom=2: 400/(2*2) = 100 on X, 300/(2*2) = 75 on Y
      assertClose(cam.position.x, 100);
      assertClose(cam.position.y, 75);
    });

    it('lookAt(point): the point ends up at the center of the screen (HU-04 Scenario 4)', 0, () => {
      const cam = new Camera2D(400, 300);
      const point = new Vector2(-60, 210);

      cam.lookAt(point);

      assertCenteredOnScreen(cam, point);
      assertClose(cam.position.x, -60);
      assertClose(cam.position.y, 210);
    });

    it('lookAt(point) with zoom != 1: the point still ends up at the center of the screen (HU-04 Scenario 4)', 0, () => {
      const cam = new Camera2D(466, 466);
      cam.zoom = 3;
      const point = new Vector2(12.5, -7.25);

      cam.lookAt(point);

      assertCenteredOnScreen(cam, point);
    });

    it('follow + worldToScreen: the target position maps to the center of the viewport (HU-04 Scenario 5)', 0, () => {
      const cam = new Camera2D(466, 466);
      cam.zoom = 2;
      const target = makeTarget(33, 44);

      cam.follow(target);
      cam.update();

      const screen = cam.worldToScreen(target.transform.position);
      assertClose(screen.x, 233);
      assertClose(screen.y, 233);
    });

    it('follow + screenToWorld: the round-trip stays exact after following the target (HU-04 Scenario 5)', 0, () => {
      const cam = new Camera2D(466, 466);
      cam.zoom = 2;
      const target = makeTarget(33, 44);

      cam.follow(target);
      cam.update();

      const samples: Vector2[] = [
        new Vector2(0, 0),
        new Vector2(33, 44),
        new Vector2(-120, 90),
        new Vector2(400, -400)
      ];

      for (const p of samples) {
        const back = cam.screenToWorld(cam.worldToScreen(p));
        assertClose(back.x, p.x);
        assertClose(back.y, p.y);
      }
    });

    it('lookAt + screenToWorld: the center of the screen returns the observed point (HU-04 Scenario 5)', 0, () => {
      const cam = new Camera2D(400, 300);
      cam.zoom = 1.5;
      const point = new Vector2(80, -20);

      cam.lookAt(point);
      const world = cam.screenToWorld(new Vector2(200, 150));

      assertClose(world.x, 80);
      assertClose(world.y, -20);
    });
  });
}
