// TennisScore — simplified scoring rules for the Pong-tennis game.
//
//   • First player to reach 4 points wins, as long as the gap is at
//     least 2 (the "win by two" rule).
//   • Past 3-3 the match continues until someone reaches that gap
//     (deuce + advantage).
//   • `addPoint` adds to the player and returns the winner when the
//     match ends; once the match is over it adds no more points.

export type Side = 'p1' | 'p2'

export class TennisScore {
  private p1: number = 0
  private p2: number = 0
  private finished: boolean = false
  private matchWinner: Side | null = null

  /** Point count for player `side`. */
  getPoints(side: Side): number {
    return side === 'p1' ? this.p1 : this.p2
  }

  /** The match is already over (someone won). */
  isFinished(): boolean {
    return this.finished
  }

  /** Match winner, or `null` if it is not over yet. */
  getWinner(): Side | null {
    return this.matchWinner
  }

  /**
   * Adds a point to player `side`. Returns the winner if the
   * resulting score closes the match, or `null` if the game goes on.
   * If the match is already over, the score is left untouched.
   */
  addPoint(side: Side): Side | null {
    if (this.finished) {
      return this.matchWinner
    }
    if (side === 'p1') {
      this.p1++
    } else {
      this.p2++
    }
    if (this.p1 >= 4 && this.p1 - this.p2 >= 2) {
      this.finished = true
      this.matchWinner = 'p1'
    } else if (this.p2 >= 4 && this.p2 - this.p1 >= 2) {
      this.finished = true
      this.matchWinner = 'p2'
    }
    return this.matchWinner
  }

  /** Resets the score (not used inside a match; only between
   *  matches so the same object can be reused). */
  reset(): void {
    this.p1 = 0
    this.p2 = 0
    this.finished = false
    this.matchWinner = null
  }
}
