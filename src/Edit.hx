
import haxegon.*;
import flash.net.SharedObject;
import haxe.Serializer;

import Game;

using haxegon.MathExtensions;
using Lambda;

enum PlaceType {
    PlaceType_Floor;
    PlaceType_Elevated;
    PlaceType_Wall;
    PlaceType_Box;
    PlaceType_StairsL;
    PlaceType_StairsR;
    PlaceType_StairsU;
    PlaceType_StairsD;
    PlaceType_Player;
    PlaceType_Delete;
}

@:publicFields
class Edit {
// force unindent

static var place = PlaceType_Floor;

static var ERROR_TIMER_MAX = 120;
static var error_timer = 0;
static var error_message = '';

static function error(message: String) {
    error_timer = ERROR_TIMER_MAX;
    error_message = message;
}

static inline function mouse_x(): Int {
    return Math.floor(Mouse.x / Game.TILESIZE / Game.RENDER_SCALE);
}
static inline function mouse_y(): Int {
    return Math.floor(Mouse.y / Game.TILESIZE / Game.RENDER_SCALE);
}

static function do_place() {
    var x = mouse_x();
    var y = mouse_y();

    function stairs(direction) {
        var below_e = Game.entity_at(x, y, 0);
        if (!Game.occupied(x, y, 1) && (below_e == null || below_e.stair_direction == Direction_None)) {
            Game.stairs(x, y, 1, direction);
        } else {
            error('Invalid location');
        }
    }

    switch (place) {
        case PlaceType_Floor: {
            for (z in 0...2) {
                Game.walls[x][y][z] = false;
            }
        }
        case PlaceType_Wall: {
            for (z in 0...2) {
                Game.walls[x][y][z] = true;
                Game.entities.remove(Game.entity_at(x, y, z));
            }
        }
        case PlaceType_Elevated: {
            Game.walls[x][y][0] = true;
            Game.walls[x][y][1] = false;

            var entity_0 = Game.entity_at(x, y, 0);
            var entity_1 = Game.entity_at(x, y, 1);

            // Elevate entity
            if (entity_0 != null) {
                entity_0.pos.z = 1;
            }
            // Delete squished entity
            Game.entities.remove(entity_1);

            // Elevate player
            if (Game.player_pos.x == x && Game.player_pos.y == y) {
                Game.player_pos.z = 1;
            }
        }
        case PlaceType_Box: {
            var below_e = Game.entity_at(x, y, 0);
            if (!Game.occupied(x, y, 1) && (below_e == null || below_e.stair_direction == Direction_None)) {
                Game.box(x, y, 1);
            } else {
                error('Invalid location');
            }
        }
        case PlaceType_Player: {
            var below_e = Game.entity_at(x, y, 0);
            if (!Game.occupied(x, y, 1) && (below_e == null || below_e.stair_direction == Direction_None)) {
                Game.player_pos.x = x;
                Game.player_pos.y = y;
                Game.player_pos.z = 1;
            } else {
                error('Invalid location');
            }
        }
        case PlaceType_Delete: {
            var entity_0 = Game.entity_at(x, y, 0);
            var entity_1 = Game.entity_at(x, y, 1);

            Game.entities.remove(entity_0);
            Game.entities.remove(entity_1);
        }
        case PlaceType_StairsL: {
            stairs(Direction_Left);
        }
        case PlaceType_StairsR: {
            stairs(Direction_Right);
        }
        case PlaceType_StairsU: {
            stairs(Direction_Up);
        }
        case PlaceType_StairsD: {
            stairs(Direction_Down);
        }
    }

    // Drop all entities
    for (e in Game.entities) {
        e.pos.z = Game.drop_pos(e.pos);
    }
    Game.player_pos.z = Game.drop_pos(Game.player_pos);
}

static function save_changes() {
    var s = new Serializer();

    var level_file = SharedObject.getLocal(Main.level_name);
    level_file.data.walls = Game.walls;
    
    level_file.data.entities = Serializer.run(Game.entities);

    level_file.data.player_pos = Serializer.run(Game.player_pos);
    level_file.flush();
}

static function update() {
    Game.render();

    Text.display(0, 0, 'Editing ${Main.level_name}', Col.YELLOW);

    // Mouse coordinates
    Text.display(0, 30, '${mouse_x()} ${mouse_y()}');

    // Cursor
    Gfx.drawbox(Game.screenx(mouse_x()), Game.screeny(mouse_y()), Game.TILESIZE * Game.RENDER_SCALE, Game.TILESIZE * Game.RENDER_SCALE, Col.LIGHTBLUE);

    // Errro message
    if (error_timer > 0) {
        error_timer--;
        Text.display(Mouse.x, Mouse.y, error_message);
    }

    var pressed_button = false;
    GUI.x = 0;
    GUI.y = 100;
    GUI.hovering_button = false;
    if (GUI.auto_text_button("Floor")) {
        place = PlaceType_Floor;
    }
    if (GUI.auto_text_button("Wall")) {
        place = PlaceType_Wall;
    }
    if (GUI.auto_text_button("Elevated floor")) {
        place = PlaceType_Elevated;
    }
    if (GUI.auto_text_button("Box")) {
        place = PlaceType_Box;
    }
    if (GUI.auto_text_button("Stairs left")) {
        place = PlaceType_StairsL;
    }
    if (GUI.auto_text_button("Stairs right")) {
        place = PlaceType_StairsR;
    }
    if (GUI.auto_text_button("Stairs up")) {
        place = PlaceType_StairsU;
    }
    if (GUI.auto_text_button("Stairs down")) {
        place = PlaceType_StairsD;
    }
    if (GUI.auto_text_button("Player")) {
        place = PlaceType_Player;
    }
    if (GUI.auto_text_button("Delete")) {
        place = PlaceType_Delete;
    }
    if (GUI.auto_text_button("Delete level", 1) && Main.level_name != 'default') {
        Main.level_list.remove(Main.level_name);
        Main.save_level_list();

        Main.level_name = 'default';
        Main.load_level('default');
    }

    if (!GUI.hovering_button) {
        var placing_terrain = place == PlaceType_Floor || place == PlaceType_Wall || place == PlaceType_Elevated;

        if (Mouse.leftclick() || (placing_terrain && Mouse.leftheld())) {
            do_place();
        }
    }

}

}
