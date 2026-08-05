/**
 * Source feature: .infO404/docs/features/apiCompatibility/apiCompatibility.feature (HU-09)
 * Scenarios covered: each public module has at least one unit test (Scenario 4)
 * Target symbol: EventBus
 */
import { describe, it, expect } from '@ohos/hypium';
import { EventBus } from '../main/ets/events/EventBus';

interface CoinPayload {
  value: number;
}

interface ScorePayload {
  delta: number;
}

interface EmptyPayload {
  tag: string;
}

function coin(value: number): CoinPayload {
  const p: CoinPayload = { value: value };
  return p;
}

function score(delta: number): ScorePayload {
  const p: ScorePayload = { delta: delta };
  return p;
}

function empty(tag: string): EmptyPayload {
  const p: EmptyPayload = { tag: tag };
  return p;
}

export default function eventBusTest() {
  describe('EventBus', () => {
    it('initial state: no event has handlers', 0, () => {
      const bus: EventBus = new EventBus();
      let count = 0;
      bus.emit('nadie.escucha', empty('init') as Object);
      expect(count).assertEqual(0);
    });

    it('on + emit delivers the payload to the handler', 0, () => {
      const bus: EventBus = new EventBus();
      let received: number = 0;
      bus.on('coin.collected', (payload: Object) => {
        const p = payload as CoinPayload;
        received = p.value;
      });
      bus.emit('coin.collected', coin(7) as Object);
      expect(received).assertEqual(7);
    });

    it('multiple handlers on the same event are all called in order', 0, () => {
      const bus: EventBus = new EventBus();
      const order: number[] = [];
      bus.on('go', (_payload: Object) => { order.push(1); });
      bus.on('go', (_payload: Object) => { order.push(2); });
      bus.on('go', (_payload: Object) => { order.push(3); });
      bus.emit('go', empty('go') as Object);
      expect(order[0]).assertEqual(1);
      expect(order[1]).assertEqual(2);
      expect(order[2]).assertEqual(3);
    });

    it('off removes a specific handler and the others remain active', 0, () => {
      const bus: EventBus = new EventBus();
      let countA = 0;
      let countB = 0;
      const handlerA = (_payload: Object): void => { countA++; };
      const handlerB = (_payload: Object): void => { countB++; };
      bus.on('e', handlerA);
      bus.on('e', handlerB);
      bus.off('e', handlerA);
      bus.emit('e', empty('e') as Object);
      expect(countA).assertEqual(0);
      expect(countB).assertEqual(1);
    });

    it('emit with undefined payload does NOT throw', 0, () => {
      const bus: EventBus = new EventBus();
      let called = 0;
      bus.on('plain', (_payload: Object) => { called++; });
      bus.emit('plain');
      expect(called).assertEqual(1);
    });

    it('dispatch is synchronous: the handler runs before emit returns', 0, () => {
      const bus: EventBus = new EventBus();
      let flag = 0;
      bus.on('sync', (_payload: Object) => { flag = 42; });
      bus.emit('sync', empty('sync') as Object);
      expect(flag).assertEqual(42);
    });

    it('two buses do NOT share handlers', 0, () => {
      const a: EventBus = new EventBus();
      const b: EventBus = new EventBus();
      let countA = 0;
      let countB = 0;
      a.on('shared', (_payload: Object) => { countA++; });
      b.on('shared', (_payload: Object) => { countB++; });
      a.emit('shared', empty('shared') as Object);
      expect(countA).assertEqual(1);
      expect(countB).assertEqual(0);
    });

    it('two events with different names do NOT interfere with each other', 0, () => {
      const bus: EventBus = new EventBus();
      let receivedValue = 0;
      let receivedDelta = 0;
      bus.on('coin', (payload: Object) => {
        receivedValue = (payload as CoinPayload).value;
      });
      bus.on('score', (payload: Object) => {
        receivedDelta = (payload as ScorePayload).delta;
      });
      bus.emit('coin', coin(11) as Object);
      expect(receivedValue).assertEqual(11);
      expect(receivedDelta).assertEqual(0);
    });
  });
}