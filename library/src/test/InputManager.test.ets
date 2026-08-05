// Source feature: .infO404/docs/features/gestures/gestures.feature (HU-05)
// Feature: Recognize swipe and long-press gestures
// Scenarios covered by the "gestures" block below:
//   1. Swipe detected on quick directional movement
//   2. Swipe not detected on slow movement
//   3. Swipe not detected on small movement
//   4. Long press detected on stationary hold
//   5. Long press not detected if movement exceeds tolerance
//   6. Gestures coexist with multitouch and frame-bounded touch state
// The gesture tests use an identity camera (viewport 200x200 at (100,100))
// so that screen == world and the assertions do not depend on the camera.
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { InputManager } from '../main/ets/input/InputManager';
import { TouchInput } from '../main/ets/input/TouchInput';
import { Camera2D } from '../main/ets/render/Camera2D';
import { Vector2 } from '../main/ets/math/Vector2';

export default function inputManagerTest() {
  describe('InputManager', () => {
    let input: InputManager;

    beforeEach(() => {
      input = new InputManager();
    });

    // Camara identidad: screenToWorld(p) = (p - 200/2) / 1 + 100 = p
    const identityCamera = (): Camera2D => {
      const camera = new Camera2D(200, 200);
      camera.position = new Vector2(100, 100);
      return camera;
    };

    it('initial state: not touching, no started/ended flags', 0, () => {
      expect(input.isTouching()).assertFalse();
      expect(input.isTouchStarted()).assertFalse();
      expect(input.isTouchEnded()).assertFalse();
    });

    it('simple touch: updateTouches([t]) -> isTouching true, isTouchStarted true (Scenario 1)', 0, () => {
      const t = new TouchInput(100, 100);
      input.updateTouches([t]);

      expect(input.isTouching()).assertTrue();
      expect(input.isTouchStarted()).assertTrue();
    });

    it('release: updateTouches([]) -> isTouchEnded true, isTouching false (Scenario 2)', 0, () => {
      input.updateTouches([new TouchInput(100, 100)]);
      input.updateTouches([]);

      expect(input.isTouchEnded()).assertTrue();
      expect(input.isTouching()).assertFalse();
    });

    it('clearFrameFlags resets justStarted/justEnded on next read (Scenario 3)', 0, () => {
      const t = new TouchInput(100, 100);
      input.updateTouches([t]);
      expect(input.isTouchStarted()).assertTrue();

      input.clearFrameFlags();
      expect(input.isTouchStarted()).assertFalse();
    });

    it('clearFrameFlags also clears isTouchEnded', 0, () => {
      input.updateTouches([new TouchInput(100, 100)]);
      input.updateTouches([]);
      expect(input.isTouchEnded()).assertTrue();

      input.clearFrameFlags();
      expect(input.isTouchEnded()).assertFalse();
    });

    it('getTouchesWorld without camera returns an empty array', 0, () => {
      input.updateTouches([new TouchInput(100, 100)]);
      expect(input.getTouchesWorld().length).assertEqual(0);
    });

    it('getTouchesWorld with camera: screen (200,200) + camera (50,50) in viewport 466x466 -> world (17,17) (Scenario 4)', 0, () => {
      const camera = new Camera2D(466, 466);
      camera.position = new Vector2(50, 50);
      input.setCamera(camera);

      input.updateTouches([new TouchInput(200, 200)]);

      const world = input.getTouchesWorld();
      expect(world.length).assertEqual(1);
      // screenToWorld formula:
      //   x = (200 - 466/2) / 1 + 50 = -33 + 50 = 17
      //   y = (200 - 466/2) / 1 + 50 = 17
      expect(world[0].x).assertClose(17, 1e-9);
      expect(world[0].y).assertClose(17, 1e-9);
    });

    it('getTouchesWorld with camera: no zoom adjustment when zoom=1 (round-trip check)', 0, () => {
      const camera = new Camera2D(800, 600);
      camera.position = new Vector2(0, 0);
      input.setCamera(camera);

      // screen (400, 300) is the viewport center -> world (0, 0)
      input.updateTouches([new TouchInput(400, 300)]);
      const world = input.getTouchesWorld();
      expect(world[0].x).assertClose(0, 1e-9);
      expect(world[0].y).assertClose(0, 1e-9);
    });

    it('multitouch: updateTouches([t1, t2]) -> getTouchesWorld() returns 2 points (Scenario 5)', 0, () => {
      const camera = new Camera2D(800, 600);
      camera.position = new Vector2(0, 0);
      input.setCamera(camera);

      const t1 = new TouchInput(100, 100);
      const t2 = new TouchInput(300, 250);
      input.updateTouches([t1, t2]);

      const world = input.getTouchesWorld();
      expect(world.length).assertEqual(2);
    });

    it('multitouch: world points map to the correct screen positions', 0, () => {
      const camera = new Camera2D(800, 600);
      camera.position = new Vector2(0, 0);
      input.setCamera(camera);

      input.updateTouches([new TouchInput(100, 100), new TouchInput(500, 400)]);

      const world = input.getTouchesWorld();
      // t1: (100 - 400, 100 - 300) = (-300, -200)
      // t2: (500 - 400, 400 - 300) = (100, 100)
      expect(world[0].x).assertClose(-300, 1e-9);
      expect(world[0].y).assertClose(-200, 1e-9);
      expect(world[1].x).assertClose(100, 1e-9);
      expect(world[1].y).assertClose(100, 1e-9);
    });

    it('isTouchStarted only fires on the transition frame (not latched)', 0, () => {
      const t = new TouchInput(100, 100);
      input.updateTouches([t]);
      expect(input.isTouchStarted()).assertTrue();

      // Same touch still active next frame
      input.updateTouches([t]);
      expect(input.isTouchStarted()).assertFalse();
      expect(input.isTouching()).assertTrue();
    });

    it('isTouchEnded only fires on the transition frame (not latched)', 0, () => {
      const t = new TouchInput(100, 100);
      input.updateTouches([t]);
      input.updateTouches([]);
      expect(input.isTouchEnded()).assertTrue();

      // Still empty next frame
      input.updateTouches([]);
      expect(input.isTouchEnded()).assertFalse();
      expect(input.isTouching()).assertFalse();
    });

    // ===== HU-05: gestures (swipe / long press) =====
    // API under test (frame-bounded flags, same pattern as isTouchStarted):
    //   updateTouches(rawTouches, currentTime?)  -> currentTime in ms, injectable for tests
    //   isSwipeTriggered() / getSwipeDirection()      -> Vector2 normalized | null
    //   isLongPressTriggered() / getLongPressPosition() -> Vector2 origin | null
    //   setSwipeThresholds(minDistance, maxDurationMs)
    //   setLongPressThresholds(minDurationMs, maxMovement)
    // Defaults: swipe >= 30 units in <= 300 ms; long press >= 500 ms with <= 10 units.

    it('initial gesture state: no swipe or long press reported (HU-05)', 0, () => {
      expect(input.isSwipeTriggered()).assertFalse();
      expect(input.isLongPressTriggered()).assertFalse();
      expect(input.getSwipeDirection()).assertNull();
      expect(input.getLongPressPosition()).assertNull();
    });

    it('touch that travels 60 units in 200 ms reports a swipe with east direction (HU-05 Scenario 1)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(0, 0)], 1000);
      input.updateTouches([new TouchInput(60, 0)], 1200);

      expect(input.isSwipeTriggered()).assertTrue();
      const dir = input.getSwipeDirection();
      expect(dir).not().assertNull();
      // direction must be normalized: (1, 0)
      expect(dir!.x).assertEqual(1);
      expect(dir!.y).assertEqual(0);
    });

    it('swipe is reported only once per gesture and does not repeat on later frames (HU-05 Scenario 1)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(0, 0)], 1000);
      input.updateTouches([new TouchInput(60, 0)], 1200);
      expect(input.isSwipeTriggered()).assertTrue();

      // the same gesture is still active: it does not fire again
      input.updateTouches([new TouchInput(90, 0)], 1250);
      expect(input.isSwipeTriggered()).assertFalse();
    });

    it('touch that travels 60 units in 1000 ms does not report swipe (too slow) (HU-05 Scenario 2)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(0, 0)], 1000);
      input.updateTouches([new TouchInput(60, 0)], 2000);

      expect(input.isSwipeTriggered()).assertFalse();
      expect(input.getSwipeDirection()).assertNull();
    });

    it('touch that travels 10 units in 100 ms does not report swipe (below distance threshold) (HU-05 Scenario 3)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(0, 0)], 1000);
      input.updateTouches([new TouchInput(10, 0)], 1100);

      expect(input.isSwipeTriggered()).assertFalse();
      expect(input.getSwipeDirection()).assertNull();
    });

    it('touch held 600 ms within 10 units reports long press at the origin position (HU-05 Scenario 4)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(100, 100)], 1000);
      // at 200 ms it still does not meet the duration threshold
      input.updateTouches([new TouchInput(100, 100)], 1200);
      expect(input.isLongPressTriggered()).assertFalse();

      // at 600 ms, with 5 units of movement (within tolerance)
      input.updateTouches([new TouchInput(105, 100)], 1600);

      expect(input.isLongPressTriggered()).assertTrue();
      const pos = input.getLongPressPosition();
      expect(pos).not().assertNull();
      expect(pos!.x).assertEqual(100);
      expect(pos!.y).assertEqual(100);
      // a long press must not be mistaken for a swipe
      expect(input.isSwipeTriggered()).assertFalse();
    });

    it('long press is reported only once while the finger is still down (HU-05 Scenario 4)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(100, 100)], 1000);
      input.updateTouches([new TouchInput(100, 100)], 1600);
      expect(input.isLongPressTriggered()).assertTrue();

      input.updateTouches([new TouchInput(100, 100)], 1800);
      expect(input.isLongPressTriggered()).assertFalse();
    });

    it('touch that moves 50 units away from the origin does not report long press even while held (HU-05 Scenario 5)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(100, 100)], 1000);
      // at 100 ms it moves 50 units away: exceeds the tolerance of 10
      input.updateTouches([new TouchInput(150, 100)], 1100);
      expect(input.isLongPressTriggered()).assertFalse();

      // still held past 500 ms, but the candidate was already invalidated
      input.updateTouches([new TouchInput(150, 100)], 1700);
      expect(input.isLongPressTriggered()).assertFalse();
      expect(input.getLongPressPosition()).assertNull();
    });

    it('with multitouch, detecting a swipe does not alter isTouchStarted/isTouchEnded nor getTouchesWorld (HU-05 Scenario 6)', 0, () => {
      input.setCamera(identityCamera());

      // frame 1: two fingers land -> raw lifecycle reports the start
      input.updateTouches([new TouchInput(0, 0), new TouchInput(150, 150)], 1000);
      expect(input.isTouchStarted()).assertTrue();
      expect(input.isTouching()).assertTrue();
      expect(input.isSwipeTriggered()).assertFalse();

      // frame 2: the primary finger swipes, both are still held
      input.updateTouches([new TouchInput(60, 0), new TouchInput(150, 150)], 1200);
      expect(input.isSwipeTriggered()).assertTrue();
      expect(input.isTouchStarted()).assertFalse();
      expect(input.isTouchEnded()).assertFalse();
      expect(input.isTouching()).assertTrue();
      expect(input.getTouchesWorld().length).assertEqual(2);

      // frame 3: the fingers are released -> raw lifecycle reports the end
      input.updateTouches([], 1250);
      expect(input.isTouchEnded()).assertTrue();
      expect(input.isTouching()).assertFalse();
    });

    it('clearFrameFlags also clears the gesture flags of the frame (HU-05 Scenario 6)', 0, () => {
      input.setCamera(identityCamera());

      input.updateTouches([new TouchInput(0, 0)], 1000);
      input.updateTouches([new TouchInput(60, 0)], 1200);
      expect(input.isSwipeTriggered()).assertTrue();

      input.clearFrameFlags();
      expect(input.isSwipeTriggered()).assertFalse();
      expect(input.getSwipeDirection()).assertNull();
    });

    it('swipe thresholds are configurable by the consumer (HU-05 public thresholds)', 0, () => {
      input.setCamera(identityCamera());
      // requires 100 units instead of 30
      input.setSwipeThresholds(100, 300);

      input.updateTouches([new TouchInput(0, 0)], 1000);
      input.updateTouches([new TouchInput(60, 0)], 1100);

      expect(input.isSwipeTriggered()).assertFalse();
    });

    it('long press thresholds are configurable by the consumer (HU-05 public thresholds)', 0, () => {
      input.setCamera(identityCamera());
      // 200 ms of pressure is enough instead of 500
      input.setLongPressThresholds(200, 10);

      input.updateTouches([new TouchInput(100, 100)], 1000);
      input.updateTouches([new TouchInput(100, 100)], 1300);

      expect(input.isLongPressTriggered()).assertTrue();
    });
  });
}
