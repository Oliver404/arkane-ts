// events/EventBus.ts
// Minimal V1.0 typed pub/sub. Per-scene instance, created fresh by Engine.start().
// No async, no namespacing. Synchronous emit.

type Handler = (payload: Object) => void

export class EventBus {
  private handlers: Map<string, Handler[]> = new Map<string, Handler[]>()

  on(event: string, handler: (payload: Object) => void): void {
    const list = this.handlers.get(event)
    if (list) {
      list.push(handler)
    } else {
      this.handlers.set(event, [handler])
    }
  }

  off(event: string, handler: Function): void {
    const list = this.handlers.get(event)
    if (!list) {
      return
    }
    const idx = list.indexOf(handler as Handler)
    if (idx >= 0) {
      list.splice(idx, 1)
    }
    if (list.length === 0) {
      this.handlers.delete(event)
    }
  }

  emit(event: string, payload?: Object): void {
    const list = this.handlers.get(event)
    if (!list) {
      return
    }
    // Iterate over a snapshot so off() during dispatch is safe.
    const snapshot = list.slice()
    for (let i = 0; i < snapshot.length; i++) {
      snapshot[i](payload as Object)
    }
  }
}
