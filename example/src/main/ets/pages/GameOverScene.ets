// GameOverScene — screen shown after the match ends.
//
//   • "P1 wins" / "P2 wins" title.
//   • Final result "P1: N - P2: M".
//   • `Rematch` button (replays the same match: mode and difficulty
//     preserved) and `Menu` button (back to the main menu).
//
// It shows no difficulty controls: the user has to go through the
// main menu to pick a different difficulty.

import { Scene2D, TextEntity, Vector2 } from '@oliver404/arkane-ts';
import { CenteredTextEntity } from './CenteredTextEntity';
import { GameOverInfo } from './PongTypes';
import { UiButton } from './UiButton';

export interface GameOverCallbacks {
  onRematch: () => void
  onMenu: () => void
}

export class GameOverScene extends Scene2D {
  private readonly viewportW: number
  private readonly viewportH: number
  private readonly s: number
  private readonly info: GameOverInfo
  private readonly callbacks: GameOverCallbacks

  private title: TextEntity | null = null
  private scoreText: TextEntity | null = null
  private rematchButton: UiButton | null = null
  private menuButton: UiButton | null = null
  private allButtons: UiButton[] = []
  private frame: number = 0

  constructor(
    viewportW: number,
    viewportH: number,
    info: GameOverInfo,
    callbacks: GameOverCallbacks
  ) {
    super();
    this.viewportW = viewportW;
    this.viewportH = viewportH;
    const ref = Math.min(viewportW, viewportH);
    this.s = ref > 0 ? ref / 200 : 1;
    this.info = info;
    this.callbacks = callbacks;
  }

  /** For tests: info used to build the screen. */
  getInfo(): GameOverInfo {
    return this.info
  }

  onEnter(): void {
    const winnerLabel: string = this.info.winner === 'p1' ? 'P1 wins' : 'P2 wins';
    this.title = new CenteredTextEntity(winnerLabel);
    this.title.setColor('#ffffff');
    this.title.setFontSize(22 * this.s);
    this.title.setFontFamily('sans-serif');
    this.title.transform.position = new Vector2(0, -45 * this.s);
    this.addEntity(this.title);

    this.scoreText = new CenteredTextEntity(
      `${this.info.p1Score} - ${this.info.p2Score}`
    );
    this.scoreText.setColor('#bdbdbd');
    this.scoreText.setFontSize(18 * this.s);
    this.scoreText.setFontFamily('sans-serif');
    this.scoreText.transform.position = new Vector2(0, -10 * this.s);
    this.addEntity(this.scoreText);

    const btnW: number = 90 * this.s;
    const btnH: number = 26 * this.s;
    const gap: number = 10 * this.s;
    this.rematchButton = new UiButton(
      new Vector2(0, 35 * this.s),
      new Vector2(btnW, btnH),
      'Rematch',
      '#b8e8b8',
      () => this.callbacks.onRematch(),
      14 * this.s
    );
    this.menuButton = new UiButton(
      new Vector2(0, 35 * this.s + btnH + gap),
      new Vector2(btnW, btnH),
      'Menu',
      '#9e9e9e',
      () => this.callbacks.onMenu(),
      14 * this.s
    );
    this.addEntity(this.rematchButton);
    this.addEntity(this.rematchButton.getLabel());
    this.addEntity(this.menuButton);
    this.addEntity(this.menuButton.getLabel());
    this.allButtons = [this.rematchButton, this.menuButton];
  }

  update(): void {
    super.update();
    this.frame++;
    if (this.context === undefined) {
      return;
    }
    const input = this.context.input;
    if (!input.isTouchStarted()) {
      for (const b of this.allButtons) {
        b.updateFrame(this.frame);
      }
      return;
    }
    const touches = input.getTouchesWorld();
    if (touches.length === 0) {
      return;
    }
    const t = touches[0];
    for (const b of this.allButtons) {
      b.consumeTapIfHit(t, true);
    }
  }
}
