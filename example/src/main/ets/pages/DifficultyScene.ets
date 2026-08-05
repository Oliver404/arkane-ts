// DifficultyScene — difficulty selection with touch arrows.
//
//   • ◀ arrow on the left and ▶ on the right, both with a hit-test.
//   • The current level (`easy`/`medium`/`hard`) is shown large in
//     the center and cycles round-robin on each tap.
//   • `Play` button (uses the selected difficulty) and `Back`.

import {
  Scene2D,
  TextEntity,
  Vector2
} from '@oliver404/arkane-ts';
import { CenteredTextEntity } from './CenteredTextEntity';
import { Difficulty } from './PongTypes';
import { UiButton } from './UiButton';

export interface DifficultyCallbacks {
  onPlay: (difficulty: Difficulty) => void
  onBack: () => void
}

const ORDER: Difficulty[] = ['easy', 'medium', 'hard']
interface DifficultyLabel {
  easy: string
  medium: string
  hard: string
}
const LABEL: DifficultyLabel = {
  easy: 'EASY',
  medium: 'MEDIUM',
  hard: 'HARD'
}

function labelFor(d: Difficulty): string {
  if (d === 'easy') {
    return LABEL.easy;
  }
  if (d === 'medium') {
    return LABEL.medium;
  }
  return LABEL.hard;
}

export class DifficultyScene extends Scene2D {
  private readonly viewportW: number
  private readonly viewportH: number
  private readonly s: number

  private level: Difficulty = 'easy'
  private levelText: TextEntity | null = null
  private title: TextEntity | null = null
  private leftArrow: UiButton | null = null
  private rightArrow: UiButton | null = null
  private playButton: UiButton | null = null
  private backButton: UiButton | null = null
  private allButtons: UiButton[] = []
  private frame: number = 0
  private readonly callbacks: DifficultyCallbacks;

  constructor(
    viewportW: number,
    viewportH: number,
    initial: Difficulty,
  callbacks: DifficultyCallbacks
  ) {
    super();
  this.callbacks = callbacks;
  this.viewportW = viewportW;
  this.viewportH = viewportH;
  const ref = Math.min(viewportW, viewportH);
  this.s = ref > 0 ? ref / 200 : 1;
  this.level = initial;
}

  /** For tests: currently selected level. */
  getLevel(): Difficulty {
    return this.level
  }

  private setLevel(next: Difficulty): void {
    this.level = next;
    if (this.levelText !== null) {
      this.levelText.setText(labelFor(this.level));
    }
  }

  onEnter(): void {
    this.title = new CenteredTextEntity('Difficulty');
    this.title.setColor('#ffffff');
    this.title.setFontSize(18 * this.s);
    this.title.setFontFamily('sans-serif');
    this.title.transform.position = new Vector2(0, -65 * this.s);
    this.addEntity(this.title);

    this.levelText = new CenteredTextEntity(labelFor(this.level));
    this.levelText.setColor('#ffffff');
    this.levelText.setFontSize(26 * this.s);
    this.levelText.setFontFamily('sans-serif');
    this.levelText.transform.position = new Vector2(0, -15 * this.s);
    this.addEntity(this.levelText);

    // Large arrows to the left and right of the level.
    const arrowSize: number = 26 * this.s;
    const arrowOffset: number = 55 * this.s;
    this.leftArrow = new UiButton(
      new Vector2(-arrowOffset, -15 * this.s),
      new Vector2(arrowSize, arrowSize),
      '◀',
      '#e8e8e8',
      () => this.shiftLevel(-1),
      18 * this.s
    );
    this.rightArrow = new UiButton(
      new Vector2(arrowOffset, -15 * this.s),
      new Vector2(arrowSize, arrowSize),
      '▶',
      '#e8e8e8',
      () => this.shiftLevel(+1),
      18 * this.s
    );
    this.addEntity(this.leftArrow);
    this.addEntity(this.leftArrow.getLabel());
    this.addEntity(this.rightArrow);
    this.addEntity(this.rightArrow.getLabel());

    // Play and Back, below.
    const btnW: number = 90 * this.s;
    const btnH: number = 26 * this.s;
    this.playButton = new UiButton(
      new Vector2(0, 45 * this.s),
      new Vector2(btnW, btnH),
      'Play',
      '#b8e8b8',
      () => this.callbacks.onPlay(this.level),
      14 * this.s
    );
    this.backButton = new UiButton(
      new Vector2(0, 45 * this.s + btnH + 10 * this.s),
      new Vector2(btnW, btnH),
      'Back',
      '#9e9e9e',
      () => this.callbacks.onBack(),
      14 * this.s
    );
    this.addEntity(this.playButton);
    this.addEntity(this.playButton.getLabel());
    this.addEntity(this.backButton);
    this.addEntity(this.backButton.getLabel());

    this.allButtons = [
      this.leftArrow,
      this.rightArrow,
      this.playButton,
      this.backButton
    ];
  }

  private shiftLevel(delta: number): void {
    const idx: number = ORDER.indexOf(this.level);
    const nextIdx: number = (idx + delta + ORDER.length) % ORDER.length;
    this.setLevel(ORDER[nextIdx]);
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
