
import haxegon.*;
import flash.net.SharedObject;
import haxe.Serializer;
import haxe.Unserializer;

import Game;

using haxegon.MathExtensions;
using Lambda;

enum State {
    State_Game;
    State_Edit;
    State_LevelSelect;
}

@:publicFields
class Main {
// force unindent

static inline var SCREEN_WIDTH = 1800;
static inline var SCREEN_HEIGHT = 1000;
static inline var OVERWRITE_LEVEL = 'none';
static inline var OVERWRITE_ALL_LEVELS = false;

static var state = State_Game;

static var level_list: Array<String>;
static var level_name = 'default';

static function save_level_list() {
    var level_list_file = SharedObject.getLocal('level-list');
    level_list_file.data.level_list = level_list;
    level_list_file.flush();
}

static function load_level(name: String) {
    var level_file = SharedObject.getLocal(name);

    var overwrite_level = name == OVERWRITE_LEVEL || OVERWRITE_ALL_LEVELS;

    if (level_file.data.walls == null || overwrite_level) {
        level_file.data.walls = [for (x in 0...Game.WORLD_WIDTH) [for (y in 0...Game.WORLD_HEIGHT) [for (z in 0...Game.WORLD_ELEVATION) false]]];
    }
    Game.walls = level_file.data.walls;

    if (level_file.data.entities == null || overwrite_level) {
        level_file.data.entities = Serializer.run(new Array<Entity>());
    }
    Game.entities = Unserializer.run(level_file.data.entities);

    if (level_file.data.player_pos == null || overwrite_level) {
        level_file.data.player_pos = Serializer.run({x: 5, y: 5, z: 0});
    }
    Game.player_pos = Unserializer.run(level_file.data.player_pos);
    Game.player_history = new Array<Vec3i>();

    level_file.flush();

    level_name = name;

    if (level_list.indexOf(name) == -1) {
        level_list.push(name);
    }
    save_level_list();

    // TODO: think about if there's anything weird going on with entity prev_pos being saved, maybe just reset everything before saving into file for cleanliness
    for (e in Game.entities) {
        e.history = new Array<Vec3i>();
        e.prev_pos = {x: e.pos.x, y: e.pos.y, z: e.pos.z};
    }
}

function new() {
    Gfx.resizescreen(SCREEN_WIDTH, SCREEN_HEIGHT);
    Gfx.loadtiles('isometric_tiles', 27, 30);
    Gfx.loadtiles('tiles', 8, 8);
    Gfx.createimage('tiles_canvas', Game.TILESIZE * Game.WORLD_WIDTH, Game.TILESIZE * Game.WORLD_HEIGHT);

    var level_list_file = SharedObject.getLocal('level-list');
    if (level_list_file.data.level_list == null) {
        level_list_file.data.level_list = ['default'];
        level_list_file.flush();
    }
    level_list = level_list_file.data.level_list;

    for (name in level_list) {
        load_level(name);
    }

    load_level('default');
}

function update() {
    switch (state) {
        case State_Game: Game.update();
        case State_Edit: Edit.update();
        case State_LevelSelect: LevelSelect.update();
    }

    if (Input.justpressed(Key.I)) {
        Game.DRAW_ISO = !Game.DRAW_ISO;
    }

    if (Input.justpressed(Key.E)) {
        if (state == State_Game) {
            state = State_Edit;
            Main.load_level(Main.level_name);
        } else if (state == State_Edit) {
            state = State_Game;
            Edit.save_changes();
            Main.load_level(Main.level_name);
        }
    }

    if (Input.justpressed(Key.L)) {
        if (state == State_Game) {
            Main.load_level(Main.level_name);
        }

        Edit.save_changes();

        if (state == State_LevelSelect) {
            state = State_Game;
        } else {
            state = State_LevelSelect;
            // Clear text input
            Text.get_input();
        }

        // Render thumbnails
        for (name in level_list) {
            if (!Gfx.imageexists(name)) {
                Gfx.createimage(name, SCREEN_WIDTH, SCREEN_HEIGHT);
            }
            Main.load_level(name);
            Gfx.drawtoimage(name);
            Game.render(name);
            Gfx.drawtoscreen();
        }

        load_level(level_name);
    }
}

}
