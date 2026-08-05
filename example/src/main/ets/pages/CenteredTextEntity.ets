// CenteredTextEntity — shortcut for a TextEntity with textAlign='center'
// and textBaseline='middle'. Handy for titles and button labels where
// we do not want to measure the text width by hand.
//
// It is a wrapper that delegates `render` to the inner `TextEntity` so
// the font/color logic is not duplicated.

import { TextEntity } from '@oliver404/arkane-ts';

export class CenteredTextEntity extends TextEntity {
  constructor(text: string) {
    super(text);
    this.setTextAlign('center');
    this.setTextBaseline('middle');
  }
}
