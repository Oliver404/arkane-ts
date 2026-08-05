// input/InputManager.ts
import { TouchInput } from './TouchInput'
import { Camera2D } from '../render/Camera2D'
import { Vector2 } from '../math/Vector2'

export class InputManager {
  private touches: TouchInput[] = []
  private camera?: Camera2D

  // Touch lifecycle (continuo + eventos discretos)
  private touching: boolean = false
  private justStarted: boolean = false
  private justEnded: boolean = false

  // Gestures (HU-05): frame-bounded flags visible to the consumer
  private swipeTriggered: boolean = false
  private swipeDirection: Vector2 | null = null
  private longPressTriggered: boolean = false
  private longPressPosition: Vector2 | null = null

  // Internal state of the gesture in progress; reset on touch start/release
  private touchOrigin: Vector2 | null = null
  private touchStartTime: number = 0
  private swipeFired: boolean = false
  private longPressFired: boolean = false
  private longPressCandidateAlive: boolean = false

  // Configurable thresholds (sensible defaults for mobile UI)
  private swipeMinDistance: number = 30
  private swipeMaxDurationMs: number = 300
  private longPressMinDurationMs: number = 500
  private longPressMaxMovement: number = 10

  setCamera(camera: Camera2D) {
    this.camera = camera
  }

  setSwipeThresholds(minDistance: number, maxDurationMs: number): void {
    this.swipeMinDistance = minDistance
    this.swipeMaxDurationMs = maxDurationMs
  }

  setLongPressThresholds(minDurationMs: number, maxMovement: number): void {
    this.longPressMinDurationMs = minDurationMs
    this.longPressMaxMovement = maxMovement
  }

  updateTouches(rawTouches: TouchInput[], currentTime?: number) {
    const isTouching = rawTouches.length > 0
    const now = currentTime !== undefined ? currentTime : Date.now()

    this.resetFrameFlags()

    const wasTouching = this.touching
    this.justStarted = isTouching && !wasTouching
    this.justEnded = !isTouching && wasTouching

    if (this.justStarted && rawTouches.length > 0) {
      this.touchOrigin = this.toWorld(rawTouches[0].position)
      this.touchStartTime = now
      this.swipeFired = false
      this.longPressFired = false
      this.longPressCandidateAlive = true
    }

    if (isTouching && this.touchOrigin !== null) {
      this.evaluateGestures(rawTouches[0], now)
    }

    if (this.justEnded) {
      this.touchOrigin = null
      this.swipeFired = false
      this.longPressFired = false
      this.longPressCandidateAlive = false
    }

    this.touching = isTouching
    this.touches = rawTouches
  }

  isTouching(): boolean {
    return this.touching
  }

  getTouchesWorld(): Vector2[] {
    if (!this.camera) return []
    return this.touches.map((t) => { return this.camera!.screenToWorld(t.position) })
  }

  isTouchStarted(): boolean {
    return this.justStarted
  }

  isTouchEnded(): boolean {
    return this.justEnded
  }

  isSwipeTriggered(): boolean {
    return this.swipeTriggered
  }

  getSwipeDirection(): Vector2 | null {
    return this.swipeDirection
  }

  isLongPressTriggered(): boolean {
    return this.longPressTriggered
  }

  getLongPressPosition(): Vector2 | null {
    return this.longPressPosition
  }

  clearFrameFlags() {
    this.resetFrameFlags()
  }

  // ===== Internals =====

  private resetFrameFlags(): void {
    this.justStarted = false
    this.justEnded = false
    this.swipeTriggered = false
    this.swipeDirection = null
    this.longPressTriggered = false
    this.longPressPosition = null
  }

  // screenToWorld when a camera is present; identity when there is none.
  private toWorld(p: Vector2): Vector2 {
    if (this.camera) {
      return this.camera.screenToWorld(p)
    }
    return new Vector2(p.x, p.y)
  }

  private evaluateGestures(primary: TouchInput, now: number): void {
    if (this.touchOrigin === null) return
    // If both gestures have already fired, there is nothing to evaluate until the next touch.
    if (this.swipeFired && (this.longPressFired || !this.longPressCandidateAlive)) return

    const current = this.toWorld(primary.position)
    const distance = current.distance(this.touchOrigin)
    const elapsed = now - this.touchStartTime

    if (!this.swipeFired && distance >= this.swipeMinDistance && elapsed <= this.swipeMaxDurationMs) {
      this.swipeFired = true
      this.swipeTriggered = true
      this.swipeDirection = new Vector2(
        (current.x - this.touchOrigin.x) / distance,
        (current.y - this.touchOrigin.y) / distance,
      )
    }

    if (this.longPressCandidateAlive && !this.longPressFired) {
      if (distance > this.longPressMaxMovement) {
        this.longPressCandidateAlive = false
      } else if (elapsed >= this.longPressMinDurationMs) {
        this.longPressFired = true
        this.longPressCandidateAlive = false
        this.longPressTriggered = true
        this.longPressPosition = new Vector2(this.touchOrigin.x, this.touchOrigin.y)
      }
    }
  }
}