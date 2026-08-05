import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import { GameLoop } from '../main/ets/core/GameLoop';
import { Time } from '../main/ets/core/Time';

export default function gameLoopTest() {
  describe('GameLoop', () => {
    let loop: GameLoop;
    let updateCount: number;
    let renderCount: number;

    beforeEach(() => {
      updateCount = 0;
      renderCount = 0;
      Time.reset();
      loop = new GameLoop(
        () => { updateCount++; },
        () => { renderCount++; }
      );
    });

    afterEach(() => {
      if (loop.isRunning()) {
        loop.stop();
      }
    });

    it('initial state: not running', 0, () => {
      expect(loop.isRunning()).assertEqual(false);
    });

    it('start() sets running = true', 0, () => {
      loop.start();
      expect(loop.isRunning()).assertEqual(true);
    });

    it('stop() sets running = false (Scenario 3)', 0, () => {
      loop.start();
      loop.stop();
      expect(loop.isRunning()).assertEqual(false);
    });

    it('start() is idempotent', 0, () => {
      loop.start();
      loop.start();
      expect(loop.isRunning()).assertEqual(true);
    });

    it('stop() when not running is a no-op', 0, () => {
      loop.stop();
      expect(loop.isRunning()).assertEqual(false);
    });

    it('start() resets Time state (Scenario 3)', 0, () => {
      Time.update(0);
      Time.update(5000);
      expect(Time.time).assertEqual(5);

      loop.start();
      expect(Time.deltaTime).assertEqual(0);
      expect(Time.time).assertEqual(0);

      loop.stop();
    });

    it('update and render run after start() with timing', 0, async () => {
      loop.start();
      await new Promise<void>(resolve => setTimeout(resolve, 80));
      loop.stop();

      expect(updateCount).assertLarger(1);
      expect(renderCount).assertEqual(updateCount);
    });
  });
}
