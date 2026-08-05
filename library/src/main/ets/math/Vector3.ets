// math/Vector3.ts
export class Vector3 {
  x: number
  y: number
  z: number

  constructor(x: number = 0, y: number = 0, z: number = 0) {
    this.x = x
    this.y = y
    this.z = z
  }

  clone(): Vector3 {
    return new Vector3(this.x, this.y, this.z)
  }

  set(x: number, y: number, z: number): Vector3 {
    this.x = x
    this.y = y
    this.z = z
    return this
  }

  add(v: Vector3): Vector3 {
    this.x += v.x
    this.y += v.y
    this.z += v.z
    return this
  }

  subtract(v: Vector3): Vector3 {
    this.x -= v.x
    this.y -= v.y
    this.z -= v.z
    return this
  }

  multiply(scalar: number): Vector3 {
    this.x *= scalar
    this.y *= scalar
    this.z *= scalar
    return this
  }

  length(): number {
    return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z)
  }

  normalize(): Vector3 {
    const len = this.length()
    if (len > 0) {
      this.x /= len
      this.y /= len
      this.z /= len
    }
    return this
  }

  static zero(): Vector3 {
    return new Vector3(0, 0, 0)
  }
}
