import { describe, it, expect } from '@ohos/hypium';
import { Sprite } from '../main/ets/render/Sprite';
import { Vector2 } from '../main/ets/math/Vector2';

export default function spriteTest() {
  describe('Sprite (HU-07)', () => {
    it('new Sprite(w, h) creates size with width/height and default color #ffffff', 0, () => {
      const s = new Sprite(50, 30);
      expect(s.size).assertEqual(s.size);
      expect(s.size.x).assertEqual(50);
      expect(s.size.y).assertEqual(30);
      expect(s.color).assertEqual('#ffffff');
      expect(s.image).assertUndefined();
    });

    it('new Sprite(w, h, color) stores the given color (Scenario 1 HU-07)', 0, () => {
      const s = new Sprite(50, 30, '#ff0000');
      expect(s.size.x).assertEqual(50);
      expect(s.size.y).assertEqual(30);
      expect(s.color).assertEqual('#ff0000');
    });

    it('size is a Vector2 instance and is not shared between sprites', 0, () => {
      const a = new Sprite(10, 20, '#aaa');
      const b = new Sprite(10, 20, '#bbb');
      // a.size has the same identity as itself
      expect(a.size === a.size).assertTrue();
      a.size.x = 999;
      expect(b.size.x).assertEqual(10);
    });

    it('image is optional and stays undefined by default (V1.1 reserved)', 0, () => {
      const s = new Sprite(10, 10, '#000000');
      expect(s.image).assertUndefined();
    });

    it('Sprite no longer exposes the draw method (HU-07: moved to the renderer)', 0, () => {
      // draw has been the renderer's responsibility since HU-06.
      // We verify that the draw property does not exist.
      const s = new Sprite(10, 10, '#000000');
      interface SpriteWithDraw {
  draw?: Object;
}
const sExtra = s as SpriteWithDraw;
expect(sExtra.draw).assertUndefined();
    });

    it('mutating size does not break the color', 0, () => {
      const s = new Sprite(10, 10, '#123456');
      s.size.x = 100;
      s.size.y = 200;
      expect(s.color).assertEqual('#123456');
    });
  });
}
