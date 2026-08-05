import { Time } from '../core/Time'

export class ScoreSystem {
  private score: number = 0
  private rate: number // Points per second

  constructor(rate: number = 1) {
    this.rate = rate
  }

  update(): void {
    this.score += this.rate * Time.deltaTime
  }

  add(points: number): void {
    this.score += points
  }

  reset(): void {
    this.score = 0
  }

  getScore(): number {
    return Math.floor(this.score)
  }

  setRate(rate: number): void {
    this.rate = rate
  }
}
