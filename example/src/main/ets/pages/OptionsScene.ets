// OptionsScene — placeholder. Shows a title and a Back button.
// Kept as an extension point for future settings (sound, etc.).

import { Scene2D, TextEntity, Vector2 } from '@oliver404/arkane-ts';
import { CenteredTextEntity } from './CenteredTextEntity';
import { UiButton } from './UiButton';

export class OptionsScene extends Scene2D {
  private readonly viewportW: number
  private readonly viewportH: number
  private readonly s: number

  private title: TextEntity | null = null
  private note: TextEntity | null = null
  private backButton: UiButton | null = null
  private allButtons: UiButton[] = []
  private frame: number = 0
  private readonly onBack: () => void;

  constructor(
    viewportW: number,
    viewportH: number,
  onBack: () => void
  ) {
    super();
  this.onBack = onBack;
  this.viewportW = viewportW;
  this.viewportH = viewportH;
  const ref = Math.min(viewportW, viewportH);
  this.s = ref > 0 ? ref / 200 : 1;
}

  onEnter(): void {
    this.title = new CenteredTextEntity('Options');
    this.title.setColor('#ffffff');
    this.title.setFontSize(22 * this.s);
    this.title.setFontFamily('sans-serif');
    this.title.transform.position = new Vector2(0, -40 * this.s);
    this.addEntity(this.title);

    this.note = new CenteredTextEntity('No settings yet');
    this.note.setColor('#888888');
    this.note.setFontSize(12 * this.s);
    this.note.setFontFamily('sans-serif');
    this.note.transform.position = new Vector2(0, -5 * this.s);
    this.addEntity(this.note);

    const btnW: number = 90 * this.s;
    const btnH: number = 26 * this.s;
    this.backButton = new UiButton(
      new Vector2(0, 40 * this.s),
      new Vector2(btnW, btnH),
      'Back',
      '#9e9e9e',
      () => this.onBack(),
      14 * this.s
    );
    this.addEntity(this.backButton);
    this.addEntity(this.backButton.getLabel());
    this.allButtons = [this.backButton];
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
