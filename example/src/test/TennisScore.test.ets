// Deterministic tests for TennisScore.
// They validate the rule of 4 with a gap of 2, deuce/advantage and reset.
import { describe, it, expect } from '@ohos/hypium';
import { TennisScore } from '../main/ets/TennisScore';

export default function tennisScoreTest() {
  describe('TennisScore', () => {
    it('starts at 0-0 and not finished', 0, () => {
      const s: TennisScore = new TennisScore();
      expect(s.getPoints('p1')).assertEqual(0);
      expect(s.getPoints('p2')).assertEqual(0);
      expect(s.isFinished()).assertFalse();
      expect(s.getWinner()).assertNull();
    });

    it('increments points per player', 0, () => {
      const s: TennisScore = new TennisScore();
      s.addPoint('p1');
      s.addPoint('p1');
      s.addPoint('p2');
      expect(s.getPoints('p1')).assertEqual(2);
      expect(s.getPoints('p2')).assertEqual(1);
      expect(s.isFinished()).assertFalse();
    });

    it('whoever reaches 4 with a gap of 2 wins (4-2)', 0, () => {
      const s: TennisScore = new TennisScore();
      for (let i = 0; i < 4; i++) s.addPoint('p1');
      s.addPoint('p2');
      s.addPoint('p2');
      // 4-2: does NOT end (gap < 2)
      expect(s.isFinished()).assertFalse();
      s.addPoint('p1');
      // 5-2: ends
      expect(s.isFinished()).assertTrue();
      expect(s.getWinner()).assertEqual('p1');
    });

    it('deuce: at 4-4 nobody wins and play continues', 0, () => {
      const s: TennisScore = new TennisScore();
      for (let i = 0; i < 4; i++) s.addPoint('p1');
      for (let i = 0; i < 4; i++) s.addPoint('p2');
      expect(s.getPoints('p1')).assertEqual(4);
      expect(s.getPoints('p2')).assertEqual(4);
      expect(s.isFinished()).assertFalse();
      expect(s.getWinner()).assertNull();
    });

    it('advantage: at 5-4 it does not finish, at 6-4 it does', 0, () => {
      const s: TennisScore = new TennisScore();
      for (let i = 0; i < 4; i++) s.addPoint('p1');
      for (let i = 0; i < 4; i++) s.addPoint('p2');
      s.addPoint('p1'); // 5-4
      expect(s.isFinished()).assertFalse();
      s.addPoint('p1'); // 6-4
      expect(s.isFinished()).assertTrue();
      expect(s.getWinner()).assertEqual('p1');
    });

    it('p2 can also win by a gap of 2 after deuce', 0, () => {
      const s: TennisScore = new TennisScore();
      for (let i = 0; i < 4; i++) s.addPoint('p1');
      for (let i = 0; i < 4; i++) s.addPoint('p2');
      s.addPoint('p2'); // 4-5
      s.addPoint('p2'); // 4-6
      expect(s.isFinished()).assertTrue();
      expect(s.getWinner()).assertEqual('p2');
    });

    it('once finished, it does not accept more points', 0, () => {
      const s: TennisScore = new TennisScore();
      for (let i = 0; i < 4; i++) s.addPoint('p1');
      s.addPoint('p1'); // 5-0, already finished
      expect(s.isFinished()).assertTrue();
      s.addPoint('p2'); // 5-1 (should not apply)
      expect(s.getPoints('p2')).assertEqual(0);
    });

    it('reset() returns to 0-0 with no winner', 0, () => {
      const s: TennisScore = new TennisScore();
      for (let i = 0; i < 4; i++) s.addPoint('p1');
      s.addPoint('p1');
      s.reset();
      expect(s.getPoints('p1')).assertEqual(0);
      expect(s.getPoints('p2')).assertEqual(0);
      expect(s.isFinished()).assertFalse();
      expect(s.getWinner()).assertNull();
    });
  });
}
