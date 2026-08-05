import { Time } from '../core/Time'

export type SpawnCallback<T> = () => T

export class SpawnerSystem<T> {
  private interval: number
  private timer: number = 0
  private spawnFn: SpawnCallback<T>

  constructor(interval: number, spawnFn: SpawnCallback<T>) {
    this.interval = interval
    this.spawnFn = spawnFn
  }

  update(): T | null {
    this.timer += Time.deltaTime
    if (this.timer >= this.interval) {
      this.timer = 0
      return this.spawnFn()
    }
    return null
  }

  setInterval(interval: number): void {
    this.interval = interval
  }
}
