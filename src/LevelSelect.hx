
import haxegon.*;

import Game;

using haxegon.MathExtensions;
using Lambda;

@:publicFields
class LevelSelect {
// force unindent

static inline var THUMB_SCALE = 0.15;
static inline var THUMB_WIDTH = Game.WORLD_WIDTH * Game.RENDER_SCALE * Game.TILESIZE * THUMB_SCALE;
static inline var THUMB_HEIGHT = Game.WORLD_HEIGHT * Game.RENDER_SCALE * Game.TILESIZE * THUMB_SCALE;
static inline var X_OFFSET = 50;

static function update() {
    var x = X_OFFSET;
    var y = 50;

    var hovering_level = 'none';

    for (name in Main.level_list) {
        if (Math.point_box_intersect(Mouse.x, Mouse.y, x, y, THUMB_WIDTH, THUMB_HEIGHT + Text.height(name))) {
            hovering_level = name;
        }

        Gfx.scale(THUMB_SCALE);
        Gfx.drawimage(x, y + Text.height(name), name);

        Gfx.scale(1);
        Text.display(x, y, name);

        x += Math.round(Math.max(THUMB_WIDTH, Text.width(name)));

        if (x + THUMB_WIDTH > Main.SCREEN_WIDTH) {
            x = X_OFFSET;
            y += Math.round(THUMB_HEIGHT + Text.height());
        }
    }

    if (Text.input(x, y, 'New level: ')) {
        Main.load_level(Text.get_input());
        Main.state = State_Game;
    }

    if (hovering_level != 'none' && Mouse.leftclick()) {
        Main.level_name = hovering_level;
        Main.load_level(Main.level_name);
        Main.state = State_Game;
    }
}

}
