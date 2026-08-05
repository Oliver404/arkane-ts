// Types shared by the example scenes.

export type GameMode = 'pvp' | 'cpu'
export type Difficulty = 'easy' | 'medium' | 'hard'
export type GameSide = 'p1' | 'p2'

export interface GameOverInfo {
  winner: GameSide
  p1Score: number
  p2Score: number
  mode: GameMode
  difficulty: Difficulty | null
}
