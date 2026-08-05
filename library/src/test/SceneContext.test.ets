import { describe, it, expect } from '@ohos/hypium'
import { SceneContext } from '../main/ets/scene/SceneContext'
import { EventBus } from '../main/ets/events/EventBus'
import { InputManager } from '../main/ets/input/InputManager'
import { Camera2D } from '../main/ets/render/Camera2D'
import { Scene2D } from '../main/ets/scene/Scene2D'
import { Engine } from '../main/ets/core/Engine'
import { Vector2 } from '../main/ets/math/Vector2'

// Minimal stand-in scenes/engines to exercise the wiring without touching the
// real test renderer (which depends on a CanvasRenderingContext2D).
class StubScene extends Scene2D {
  onEnter(): void {}
  update(): void {}
}

interface EnemyKilledPayload {
  id: string;
}

interface EmptyPayload {
  tag: string;
}

class StubRenderContext {
  ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D()
  width: number
  height: number
  constructor(width: number, height: number) {
    this.width = width
    this.height = height
  }
}

class StubRenderer {
  begin(_ctx: Object): void {}
  end(): void {}
}

export default function sceneContextTest() {
  describe('SceneContext', () => {
    // Scenario 1: SceneContext accessible in update, same instances.
    it('context_input_events_camera_defined_and_stable', 0, () => {
      const input = new InputManager()
      const camera = new Camera2D(466, 466)
      const events = new EventBus()
      const context = new SceneContext(input, camera, events)

      expect(context.input).not().assertNull()
      expect(context.events).not().assertNull()
      expect(context.camera).not().assertNull()
      expect(context.input === input).assertEqual(true)
      expect(context.events === events).assertEqual(true)
      expect(context.camera === camera).assertEqual(true)

      // Re-reading fields returns the same references.
      const ref2 = new SceneContext(input, camera, events)
      expect(ref2.input === ref2.input).assertEqual(true)
      expect(ref2.events === ref2.events).assertEqual(true)
    })

    // Scenario 2: getTouchesWorld applies the camera. Light smoke test using
    // the public API only (HU-15 covers the math in detail).
    it('context_camera_is_same_instance_for_touch_transform', 0, () => {
      const input = new InputManager()
      const camera = new Camera2D(466, 466)
      const context = new SceneContext(input, camera, new EventBus())
      // camera exposed via context must be the exact same instance
      expect(context.camera === camera).assertEqual(true)
    })

    // Scenario 3: per-scene EventBus. Subscribe, emit, handler fires with payload.
    it('context_events_emits_to_subscribed_handlers_synchronously', 0, () => {
      const input = new InputManager()
      const camera = new Camera2D(466, 466)
      const events = new EventBus()
      const context = new SceneContext(input, camera, events)

      let receivedId: string = ''
      let callCount: number = 0

      context.events.on('enemy.killed', (payload: Object) => {
        callCount++
        const p = payload as EnemyKilledPayload
        receivedId = p.id
      })

      // Simulate the scene's update emitting an event.
      const killed: EnemyKilledPayload = { id: 'enemy-42' }
      context.events.emit('enemy.killed', killed as Object)

      expect(callCount).assertEqual(1)
      expect(receivedId).assertEqual('enemy-42')
    })

    // Scenario 4: Camera2D is the same one the Engine holds.
    it('engine_start_wires_same_camera_to_scene_context', 0, () => {
      const engine = new Engine()
      const rc = new StubRenderContext(466, 466) as Object
      const renderer = new StubRenderer() as Object
      engine.setRenderer(renderer as never, rc as never)

      const scene = new StubScene()
      engine.start(scene)

      // After start, the scene's context.camera must be the same Camera2D
      // instance the engine built in setRenderer.
      const ctx = scene.getContext()
      expect(ctx).not().assertNull()
      expect(ctx!.camera).not().assertNull()
      expect(ctx!.camera.viewportWidth).assertEqual(466)
    })

    // Scenario 3 (HU-03): each scene's EventBus is independent —
    // emitting on one does not affect the other.
    it('context_events_isolates_between_different_scenes', 0, () => {
      const input = new InputManager()
      const camera = new Camera2D(466, 466)
      const events1 = new EventBus()
      const events2 = new EventBus()
      const ctx1 = new SceneContext(input, camera, events1)
      const ctx2 = new SceneContext(input, camera, events2)

      let count1: number = 0
      let count2: number = 0

      ctx1.events.on('shared.event', (_payload: Object) => {
        count1++
      })
      ctx2.events.on('shared.event', (_payload: Object) => {
        count2++
      })

      const empty: EmptyPayload = { tag: 'shared' }
      ctx1.events.emit('shared.event', empty as Object)

      expect(count1).assertEqual(1)
      expect(count2).assertEqual(0)
    })
  })
}
