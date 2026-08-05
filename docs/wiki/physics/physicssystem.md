---
title: PhysicsSystem
version: 0.0.1
section: physics
created: 2026-08-04
last_modified: 2026-08-04
status: stable
---

# PhysicsSystem

The auto-driven physics tick. Implements `GameSystem` so it can be registered against an `Engine` and run on every frame. Per tick, it integrates gravity + drag + position for every dynamic rigidbody, then resolves collisions for every pair of colliders using [Manifold](manifold.md).

## Basic usage

```typescript
import { Engine, PhysicsSystem } from '@oliver404/arkane-ts';

const engine = new Engine();
engine.registerSystem(new PhysicsSystem());

// Entities with colliders + rigidbodies will now be simulated.
engine.start(scene);
```

Without registering `PhysicsSystem`, no integration runs — your bodies will sit motionless even with `Rigidbody.update(dt)` declared. Conversely, with the system registered, you should **not** also call `Rigidbody.update(dt)` from your scene; doing so will double-integrate.

## Configuration

### Properties

| Name | Type | Default | Description |
|---|---|---|---|
| `slop` | `number` | `0.05` | Penetration tolerance. Pairs whose overlap is below `slop` skip positional correction entirely. |
| `baumgarte` | `number` | `0.4` | Positional correction factor (0..1). Higher = snappier resolution, lower = softer. |
| `dt` | `number` | `1 / 60` | Fallback dt used when `Time.deltaTime` is 0 (rare; happens in some test paths). |

### Methods

| Method | Description |
|---|---|
| `attach(engine)` | Called once by `Engine.registerSystem`. Stores the engine reference for `beforeUpdate`. |
| `beforeUpdate()` | The auto-driven entry point. Reads the active scene, runs `step(scene, Time.deltaTime)`. |
| `step(scene, dt)` | Manual one-shot. Used by tests and by consumers that want full control over the tick. |

## Tick sequence

```
for each entity with rigidbody (mass > 0):
    velocity += gravity * gravityScale * dt
    if drag > 0: velocity *= max(0, 1 - drag*dt)
    position  += velocity * dt

for each (i, j) pair with colliders:
    m = Manifold.compute(ca, cb)
    if m is null: continue
    applyImpulse(a, b, m)              // normal-direction impulse with restitution
    applyPositionalCorrection(a, b, m) // Baumgarte split by inverse mass
```

Separating contacts (relative velocity along the normal > 0) are skipped — they are moving apart, no impulse needed.

### Impulse formula

```
vRel = v_b - v_a
vAlongNormal = vRel · m.normal
if vAlongNormal > 0: return       // separating

e = m.restitution
j = -(1 + e) * vAlongNormal / (invMassA + invMassB)

v_a -= j * m.normal * invMassA
v_b += j * m.normal * invMassB
```

Infinite-mass bodies (`mass ≤ 0`) have `invMass = 0` and do not receive impulse.

### Positional correction formula

```
correctionMag = max(m.penetration - slop, 0) / (invMassA + invMassB) * baumgarte

position_a -= correctionMag * m.normal * invMassA
position_b += correctionMag * m.normal * invMassB
```

This prevents the bodies from sinking into each other over many frames of imperfect resolution.

## Advanced usage

### Step manually (e.g. in tests)

```typescript
const physics = new PhysicsSystem();
physics.step(scene, 1 / 60);
```

In tests, do not register the system against an engine — call `step` directly so the test controls time.

### Soft physics

For a more forgiving feel, lower `baumgarte` to `0.1` and raise `slop` to `0.2`. Bodies will overlap more visibly before being pushed apart.

```typescript
const physics = new PhysicsSystem();
physics.baumgarte = 0.1;
physics.slop = 0.2;
engine.registerSystem(physics);
```

### Custom gravity

Per-scene gravity is read directly:

```typescript
scene.gravity = new Vector2(0, -20);   // heavier gravity
```

Per-body tuning via `rigidbody.gravityScale` (set on the entity before adding to the scene).

## Pitfalls & FAQ

- **Register at most once.** Two `PhysicsSystem` instances would integrate each pair of bodies twice per tick.
- **Order of `registerSystem` matters.** `PhysicsSystem.beforeUpdate` runs **before** `Scene2D.update` (the scene's own update). If your scene reads `entity.transform.position` after physics, the values are current.
- **Tangential friction is not applied.** `Manifold.friction` is computed but the impulse formula only handles the normal component. Tangential resolution is V1.2.
- **No collision callbacks.** The system applies impulses silently. If you need a "hit" event, read entity state in `Scene2D.update` (e.g. compare distances or use `EventBus.emit` from a custom collision-detection pass).
- **Mass = 0 is treated as infinite.** The body is not integrated and not impulsed. It still participates in contact detection and positional correction is skipped for it.
- **No continuous collision detection (CCD).** Fast-moving bodies can tunnel through thin walls. If this matters, do your own swept tests before applying velocity.

## See also

- [Rigidbody](rigidbody.md) — what `PhysicsSystem` integrates.
- [Collider](collider.md), [Manifold](manifold.md) — what `PhysicsSystem` resolves.
- [Engine](../core/engine.md) — `registerSystem` hook.
- [GameSystem](../core/engine.md#custom-system) — the interface `PhysicsSystem` implements.
