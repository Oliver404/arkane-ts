// core/GameLoop.ts
import { Time } from './Time'

export type LoopCallback = () => void

export class GameLoop {
  private running: boolean = false
  private timerId: number = -1
  private update: LoopCallback
  private render: LoopCallback
  private readonly targetFPS: number
  private readonly frameDuration: number
  private lastFrameTime: number = 0
  private nextFrameTime: number = 0

  constructor(
    update: LoopCallback,
    render: LoopCallback,
    targetFPS: number = 60
  ) {
    this.update = update
    this.render = render
    this.targetFPS = targetFPS
    this.frameDuration = 1000 / targetFPS
  }

  start() {
    if (this.running) {
      return
    }

    this.running = true
    Time.reset()
    this.lastFrameTime = Date.now()
    this.nextFrameTime = this.lastFrameTime + this.frameDuration
    this.loop()
  }

  stop() {
    this.running = false
    if (this.timerId !== -1) {
      clearTimeout(this.timerId)
      this.timerId = -1
    }
  }

  isRunning(): boolean {
    return this.running
  }

  private loop() {
    if (!this.running) {
      return
    }

    const now = Date.now()
    Time.update(now)
    this.lastFrameTime = now

    this.update()
    this.render()

    this.nextFrameTime += this.frameDuration
    const wait = Math.max(0, this.nextFrameTime - Date.now())
    this.timerId = setTimeout(() => {
      this.loop()
    }, wait)
  }
}
