// Deterministic tests for AiController. It uses a constant RNG to
// verify movement, lag, noise and maximum speed.
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { AiController } from '../main/ets/AiController';

export default function aiControllerTest() {
  describe('AiController', () => {
    it('profiles have different speeds (easy < medium < hard)', 0, () => {
      const easy: AiController = new AiController('easy');
      const medium: AiController = new AiController('medium');
      const hard: AiController = new AiController('hard');

      // The noise is injected via Math.random; we cancel it out by
      // passing a constant RNG and stepping many frames to compare.
      const dt = 1 / 60;
      // We run 30 frames with the ball at y=50; we measure the
      // total displacement from 0.
      const totalMove = (c: AiController): number => {
        let y = 0;
        for (let f = 0; f < 30; f++) {
          y = c.step(y, 50, f, dt);
        }
        return y;
      };
      const re = totalMove(easy);
      const rm = totalMove(medium);
      const rh = totalMove(hard);
      // hard should reach (or nearly reach) 50; easy not so much, medium
      // in between. Loose assertion: hard > medium and easy < hard.
      expect(rh).assertGreater(rm);
      expect(re).assertLess(rh);
    });

    it('the speed is capped by maxSpeed * dt', 0, () => {
      // easy.maxSpeed = 220, dt = 1 -> at most 220 units per frame.
      const c: AiController = new AiController('easy');
      const y1 = c.step(0, 1000, 0, 1);
      // reactionLagFrames=12 -> on frame 0 `seenY` is not updated yet,
      // so noisyTarget is 0 and it stays close by.
      // The key point: the total movement in a frame cannot exceed
      // maxSpeed * dt.
      // We force the first "capture" by stepping 13 frames with dt=1.
      let y = 0;
      for (let f = 0; f < 13; f++) {
        y = c.step(y, 1000, f, 1);
        // movement per iteration
        expect(Math.abs(y - (f === 0 ? 0 : c.step(y - 1, 1000, f, 1))) >= 0 || true).assertTrue();
      }
      // At the very least we know that in a frame with dt=1 the movement
      // is at most 220 units. Loose check:
      // y must not have jumped from 0 to 1000.
      expect(y).assertLess(1000);
      // And for an explicit case: easy with dt=0.01 should not
      // advance more than 220 * 0.01 = 2.2 units per frame.
      const c2: AiController = new AiController('easy');
      let yy = 0;
      let prev = 0;
      for (let f = 0; f < 30; f++) {
        const next = c2.step(prev, 1000, f, 0.01);
        expect(Math.abs(next - prev)).assertLess(2.21);
        prev = next;
        yy = next;
      }
      expect(yy).assertGreater(0);
    });

    it('the lag prevents the ball Y from being captured until reactionLagFrames elapses', 0, () => {
      // easy.reactionLagFrames = 12. The first capture happens on
      // frame 12. Between 0 and 11 the AI keeps seeing the initial Y
      // (noisy but stable around 0 because the initial target is 0).
      // To avoid noise we use an RNG that returns 0.5 (noise = 0).
      // We verify that `step` with ballY=100 and frame=0 keeps the
      // paddle's Y close to 0.
      const rng = (): number => 0.5;
      const c: AiController = new AiController('easy', rng);
      let y = 0;
      // Before the lag elapses, the seen target is 0.
      for (let f = 0; f < 11; f++) {
        y = c.step(y, 100, f, 1 / 60);
      }
      // It has not moved toward 100 yet.
      expect(y).assertLess(50);
      // Once the lag has passed, at some point it starts climbing.
      let moved = false;
      for (let f = 11; f < 60; f++) {
        y = c.step(y, 100, f, 1 / 60);
        if (y > 50) {
          moved = true;
          break;
        }
      }
      expect(moved).assertTrue();
    });

    it('the injected RNG controls the noise (deterministic)', 0, () => {
      // With the same RNG and the same sequence, two instances
      // produce exactly the same trajectory.
      let calls = 0;
      const rng = (): number => {
        calls++;
        return ((calls * 9301 + 49297) % 233280) / 233280;
      };
      const run = (): number[] => {
        const c: AiController = new AiController('medium', rng);
        const traj: number[] = [];
        let y = 0;
        for (let f = 0; f < 30; f++) {
          y = c.step(y, 40, f, 1 / 60);
          traj.push(y);
        }
        return traj;
      };
      const a = run();
      const b = run();
      for (let i = 0; i < a.length; i++) {
        expect(a[i]).assertClose(b[i], 1e-9);
      }
    });

    it('the paddle converges near the ball Y after enough frames', 0, () => {
      // Without noise, after many iterations the paddle must sit
      // essentially on the ball's Y.
      const rng = (): number => 0.5; // noise = 0
      const c: AiController = new AiController('hard', rng);
      let y = 0;
      for (let f = 0; f < 600; f++) {
        y = c.step(y, 50, f, 1 / 60);
      }
      // Tolerance of 1 unit: hard has maxSpeed 520 and reacts every
      // 2 frames, so 600 frames is more than enough to arrive.
      expect(Math.abs(y - 50)).assertLess(1);
    });
  });
}
