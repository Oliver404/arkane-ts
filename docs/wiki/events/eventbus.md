---
title: EventBus
version: 0.0.1
section: events
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# EventBus

A minimal synchronous pub/sub bus. The engine creates one per scene on every `start()`; access it via `scene.context.events`. Use it for system-to-system messaging (e.g. "enemy spawned", "goal scored", "level cleared") without coupling the producer and consumer directly.

## Basic usage

Producer (a scene):

```typescript
override onEnter(): void {
  this.context!.events.on('enemy.spawned', (payload) => {
    const p = payload as { x: number; y: number };
    this.spawnEnemyAt(p.x, p.y);
  });
}

private onEnemyDefeated(score: number): void {
  this.context!.events.emit('score.added', { value: score });
}
```

Consumer (anywhere with access to the same `SceneContext.events`):

```typescript
this.context!.events.on('score.added', (payload) => {
  const p = payload as { value: number };
  this.totalScore += p.value;
  this.scoreLabel.setText(`Score: ${this.totalScore}`);
});
```

## Configuration

### Methods

| Method | Description |
|---|---|
| `on(event, handler)` | Subscribe. `handler` receives the payload emitted with this event name. |
| `off(event, handler)` | Unsubscribe. Safe to call even if the handler was never registered. |
| `emit(event, payload?)` | Synchronously invoke every handler for `event`. Safe to call `off` during dispatch — handlers iterate a snapshot. |

### Handler signature

```typescript
type Handler = (payload: Object) => void
```

Payloads are typed as `Object`. The producer and consumer agree on the shape via convention (no runtime type check). Cast in the handler:

```typescript
events.on('player.hit', (payload) => {
  const { damage } = payload as { damage: number };
});
```

## Advanced usage

### Unsubscribe on scene exit

Override `onExit` to clean up listeners — though the per-scene bus is recreated on every `engine.start()` anyway, so the bus itself is throwaway:

```typescript
override onExit(): void {
  this.context!.events.off('enemy.spawned', this.handleEnemySpawned);
  this.handleEnemySpawned = (): void => {};   // no-op fallback
}
```

### Multiple handlers per event

```typescript
events.on('game.over', showGameOverScreen);
events.on('game.over', saveHighScore);
events.on('game.over', stopBackgroundMusic);
events.emit('game.over');
```

All three fire in registration order, on the same call stack.

## Pitfalls & FAQ

- **Synchronous.** `emit` runs handlers inline. Do not emit from a tight loop expecting async fan-out.
- **Per-scene instance.** `engine.start(scene)` allocates a fresh `EventBus`. Listeners from the previous run are gone.
- **No namespacing.** Two systems using `'score.added'` for different purposes will conflict. Prefix your events (e.g. `'game.score.added'`, `'ui.score.added'`).
- **No priority, no wildcard.** First-registered, first-fired. Use multiple `on` calls if you need ordering control.
- **`off` during emit is safe.** The bus iterates a snapshot of handlers, so unsubscribing inside a callback does not skip subsequent handlers.
- **Payload type is `Object`.** You own the contract. A typo on either side is a silent runtime crash. Consider adding a small assertion in development builds.

## See also

- [SceneContext](../scene/scenecontext.md) — exposes the bus.
- [Engine](../core/engine.md) — creates the bus on `start()`.
