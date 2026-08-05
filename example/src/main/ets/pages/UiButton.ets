// UiButton — rectangular entity with an AABB hit-test and a callback.
//
//   • Built from a `Rect` in world coordinates (center + size).
//   • The label is rendered centered using `CenteredTextEntity`.
//   • `hitTest(worldPos)` returns true if the point is inside.
//   • The consumer reads `isTouchStarted()` and, if the touch is
//     inside, calls `dispatch()` to run the callback.
//
// Keeping it as an `Entity` lets it live in the scene's entity list
// and be rendered with no extra code.

import { CenteredTextEntity } from './CenteredTextEntity';
import { Rect } from '@oliver404/arkane-ts';
import { Entity } from '@oliver404/arkane-ts';
import { Sprite } from '@oliver404/arkane-ts';
import { Vector2 } from '@oliver404/arkane-ts';

export class UiButton extends Entity {
  readonly rect: Rect;
  private label: CenteredTextEntity;
  private onTap: () => void;
  private lastTappedFrame: number = -1;
  private currentFrame: number = 0;

  constructor(
    center: Vector2,
    size: Vector2,
    label: string,
    color: string,
    onTap: () => void,
    fontSize: number = 14
  ) {
    super();
    this.rect = new Rect(
      center.x - size.x / 2,
      center.y - size.y / 2,
      size.x,
      size.y
    );
    this.onTap = onTap;
    this.sprite = new Sprite(size.x, size.y, color);
    this.transform.position = new Vector2(center.x, center.y);

    this.label = new CenteredTextEntity(label);
    this.label.setFontSize(fontSize);
    this.label.setColor('#0e0e1a');
    this.label.setFontFamily('sans-serif');
    this.label.transform.position = new Vector2(center.x, center.y);
  }

  /** Centers the label over the button position. */
  getLabel(): CenteredTextEntity {
    return this.label
  }

  /**
   * Call every frame with the scene's frame counter. If the previous
   * frame was "tap started" and this one is not, it does not fire
   * again (prevents re-firing while the finger stays down).
   */
  updateFrame(frame: number): void {
    this.currentFrame = frame
  }

  /** The consumer must call this during the scene's `serve` frame.
   *  Returns `true` if the tap fired. */
  consumeTapIfHit(worldPos: Vector2, touchStarted: boolean): boolean {
    if (!touchStarted) {
      this.lastTappedFrame = -1
      return false
    }
    if (this.lastTappedFrame === this.currentFrame) {
      return false
    }
    if (!this.rect.contains(worldPos)) {
      return false
    }
    this.lastTappedFrame = this.currentFrame
    this.onTap()
    return true
  }
}
