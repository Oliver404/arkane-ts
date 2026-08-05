// math/MathUtils.ts
export class MathUtils {
  static clamp(value: number, min: number, max: number): number {
    if (value < min) {
      return min
    }
    if (value > max) {
      return max
    }
    return value
  }

  static lerp(a: number, b: number, t: number): number {
    return a + (b - a) * t
  }
}
