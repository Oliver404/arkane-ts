import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { SceneManager } from '../main/ets/core/SceneManager';
import { Scene2D } from '../main/ets/scene/Scene2D';

class TestScene extends Scene2D {
  onEnterCalls: number = 0;
  onExitCalls: number = 0;
  updateCalls: number = 0;

  onEnter(): void {
    this.onEnterCalls++;
  }

  onExit(): void {
    this.onExitCalls++;
  }

  update(): void {
    this.updateCalls++;
  }
}

export default function sceneManagerTest() {
  describe('SceneManager', () => {
    let manager: SceneManager;

    beforeEach(() => {
      manager = new SceneManager();
    });

    it('initial state: no active scene', 0, () => {
      expect(manager.getCurrentScene()).assertUndefined();
    });

    it('setScene activates the scene and invokes onEnter once (Scenario 1)', 0, () => {
      const s = new TestScene();
      manager.setScene(s);
      expect(manager.getCurrentScene()).assertEqual(s);
      expect(s.onEnterCalls).assertEqual(1);
    });

    it('setScene(null) clears the state (Scenario 3)', 0, () => {
      const s = new TestScene();
      manager.setScene(s);
      expect(manager.getCurrentScene()).not().assertUndefined();

      manager.setScene(null);
      expect(manager.getCurrentScene()).assertUndefined();
      expect(s.onEnterCalls).assertEqual(1);
    });

    it('clear() clears the state (Scenario 3)', 0, () => {
      const s = new TestScene();
      manager.setScene(s);
      manager.clear();
      expect(manager.getCurrentScene()).assertUndefined();
    });

    it('replacing a scene invokes onExit of the previous one before onEnter of the new one (Scenario 1)', 0, () => {
      const a = new TestScene();
      const b = new TestScene();
      manager.setScene(a);
      expect(a.onEnterCalls).assertEqual(1);
      expect(a.onExitCalls).assertEqual(0);

      manager.setScene(b);

      expect(a.onExitCalls).assertEqual(1);
      expect(b.onEnterCalls).assertEqual(1);
      expect(b.onExitCalls).assertEqual(0);
      expect(manager.getCurrentScene()).assertEqual(b);
    });

    it('setScene(null) without a prior scene does not invoke onExit (Scenario 3)', 0, () => {
      manager.setScene(null);
      expect(manager.getCurrentScene()).assertUndefined();
    });

    it('update propagates to the active scene (Scenario 2)', 0, () => {
      const s = new TestScene();
      manager.setScene(s);
      manager.update();
      expect(s.updateCalls).assertEqual(1);
    });

    it('update without an active scene is a no-op (Scenario 3)', 0, () => {
      manager.update();
      // No exception means success.
    });

    it('update does not invoke the previous scene after setScene(null)', 0, () => {
      const a = new TestScene();
      manager.setScene(a);
      manager.setScene(null);
      a.updateCalls = 0;
      manager.update();
      expect(a.updateCalls).assertEqual(0);
    });
  });
}
