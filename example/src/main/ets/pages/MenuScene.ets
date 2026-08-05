// MenuScene — the example's initial menu.
//
//   • "Pong" title centered in the upper third.
//   • Three buttons stacked vertically: `vs Computer`, `vs Player`
//     and `Options`.
//   • Each button is a `UiButton` (sprite + centered label) with its
//     callback injected by `Index`.

import {
  BoxCollider,
  Entity,
  Scene2D,
  Sprite,
  TextEntity,
  Vector2
} from '@oliver404/arkane-ts';
import { CenteredTextEntity } from './CenteredTextEntity';
import { UiButton } from './UiButton';

export interface MenuCallbacks {
  onVsComputer: () => void
  onVsPlayer: () => void
  onOptions: () => void
}

export class MenuScene extends Scene2D {
  private readonly viewportW: number
  private readonly viewportH: number
  private readonly halfH: number
  private readonly halfW: number
  private readonly s: number

  private title: TextEntity | null = null
  private subtitle: TextEntity | null = null
  private buttons: UiButton[] = []
  private frame: number = 0
  private readonly callbacks: MenuCallbacks;

  constructor(
    viewportW: number,
    viewportH: number,
  callbacks: MenuCallbacks
  ) {
    super();
  this.callbacks = callbacks;
  this.viewportW = viewportW;
  this.viewportH = viewportH;
  this.halfW = viewportW / 2;
  this.halfH = viewportH / 2;
  const ref = Math.min(viewportW, viewportH);
  this.s = ref > 0 ? ref / 200 : 1;
}

  onEnter(): void {
    // Title
    this.title = new CenteredTextEntity('PONG');
    this.title.setColor('#ffffff');
    this.title.setFontSize(28 * this.s);
    this.title.setFontFamily('sans-serif');
    this.title.transform.position = new Vector2(0, -70 * this.s);
    this.addEntity(this.title);

    // Subtitle / help
    this.subtitle = new CenteredTextEntity('Tennis rules');
    this.subtitle.setColor('#888888');
    this.subtitle.setFontSize(11 * this.s);
    this.subtitle.setFontFamily('sans-serif');
    this.subtitle.transform.position = new Vector2(0, -45 * this.s);
    this.addEntity(this.subtitle);

    // Buttons: width = 110*s, height = 28*s, 12*s vertical gap.
    const btnW: number = 110 * this.s;
    const btnH: number = 28 * this.s;
    const gap: number = 12 * this.s;
    const startY: number = 0;

    const vsCpu = new UiButton(
      new Vector2(0, startY),
      new Vector2(btnW, btnH),
      'vs Computer',
      '#e8e8e8',
      () => this.callbacks.onVsComputer(),
      13 * this.s
    );
    const vsP = new UiButton(
      new Vector2(0, startY + btnH + gap),
      new Vector2(btnW, btnH),
      'vs Player',
      '#e8e8e8',
      () => this.callbacks.onVsPlayer(),
      13 * this.s
    );
    const opts = new UiButton(
      new Vector2(0, startY + 2 * (btnH + gap)),
      new Vector2(btnW, btnH),
      'Options',
      '#9e9e9e',
      () => this.callbacks.onOptions(),
      13 * this.s
    );
    for (const b of [vsCpu, vsP, opts]) {
      this.addEntity(b);
      this.addEntity(b.getLabel());
      this.buttons.push(b);
    }
  }

  update(): void {
    super.update();
    this.frame++;
    if (this.context === undefined) {
      return;
    }
    const input = this.context.input;
    if (!input.isTouchStarted()) {
      for (const b of this.buttons) {
        b.updateFrame(this.frame);
      }
      return;
    }
    const touches = input.getTouchesWorld();
    if (touches.length === 0) {
      return;
    }
    const t = touches[0];
    for (const b of this.buttons) {
      b.consumeTapIfHit(t, true);
    }
  }
}
