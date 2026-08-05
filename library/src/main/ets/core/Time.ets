// core/Time.ts
export class Time {
  static deltaTime: number = 0
  static time: number = 0

  private static lastTime: number = 0
  private static isFirstFrame: boolean = true

  static update(currentTime: number) {
    if (Time.isFirstFrame) {
      Time.isFirstFrame = false
      Time.lastTime = currentTime
      return
    }

    Time.deltaTime = (currentTime - Time.lastTime) / 1000
    Time.time += Time.deltaTime
    Time.lastTime = currentTime
  }

  static reset() {
    Time.deltaTime = 0
    Time.time = 0
    Time.lastTime = 0
    Time.isFirstFrame = true
  }
}
