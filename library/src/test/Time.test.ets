import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { Time } from '../main/ets/core/Time';

export default function timeTest() {
  describe('Time', () => {
    beforeEach(() => {
      Time.reset();
    });

    it('initial state: deltaTime=0 and time=0', 0, () => {
      expect(Time.deltaTime).assertEqual(0);
      expect(Time.time).assertEqual(0);
    });

    it('first update does not produce deltaTime (Scenario 4)', 0, () => {
      Time.update(1000);
      expect(Time.deltaTime).assertEqual(0);
      expect(Time.time).assertEqual(0);
    });

    it('first update accepts currentTime=0 without magic-number bug (Scenario 4)', 0, () => {
      Time.update(0);
      expect(Time.deltaTime).assertEqual(0);
      Time.update(0);
      expect(Time.deltaTime).assertEqual(0);
      Time.update(50);
      expect(Time.deltaTime).assertEqual(0.05);
    });

    it('second update computes deltaTime in seconds (Scenario 1)', 0, () => {
      Time.update(1000);
      Time.update(1016.67);
      expect(Time.deltaTime).assertClose(0.01667, 1e-6);
      expect(Time.time).assertClose(0.01667, 1e-6);
    });

    it('deltaTime accumulates into time across updates', 0, () => {
      Time.update(0);
      Time.update(1000);
      Time.update(2000);
      expect(Time.deltaTime).assertEqual(1);
      expect(Time.time).assertEqual(2);
    });

    it('long elapsed time produces matching deltaTime (Scenario 2)', 0, () => {
      Time.update(0);
      Time.update(50);
      expect(Time.deltaTime).assertEqual(0.05);
    });

    it('reset() returns to initial state and re-arms first frame (Scenario 3)', 0, () => {
      Time.update(0);
      Time.update(1000);
      Time.update(2000);
      expect(Time.time).assertEqual(2);

      Time.reset();
      expect(Time.deltaTime).assertEqual(0);
      expect(Time.time).assertEqual(0);

      Time.update(5000);
      expect(Time.deltaTime).assertEqual(0);
    });
  });
}
