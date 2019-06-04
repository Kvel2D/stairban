
import haxegon.*;
import openfl.net.SharedObject;

import Tile;

using haxegon.MathExtensions;
using Lambda;

enum GameState {
    GameState_Normal;
}

enum ToolType {
    ToolType_None;
    ToolType_Sword;
    ToolType_Shield;
}

enum Direction {
    Direction_None;
    Direction_Left;
    Direction_Right;
    Direction_Up;
    Direction_Down;
}

typedef Entity = {
    x: Int,
    y: Int,
    controllable: Bool,
    controlled: Bool,
    colliding: Bool,

    tool: ToolType,
    attached: Map<Direction, Array<ToolType>>,

    hp: Int,
};

typedef Tool = {
    x: Int,
    y: Int,
    type: ToolType,
};

@:publicFields
class Main {
// force unindent

static inline var SCREEN_WIDTH = 1600;
static inline var SCREEN_HEIGHT = 960;
static inline var TILESIZE = 32;
static inline var WORLD_WIDTH = 6;
static inline var WORLD_HEIGHT = 6;
static inline var WORLD_SCALE = 4;
static inline var TEXT_SIZE = 30;

var game_state = GameState_Normal;

var tiles = Data.create2darray(WORLD_WIDTH, WORLD_HEIGHT, Tile.Floor);
var entities = new Array<Entity>();
var tools = new Array<Tool>();

var cardinals: Array<Vec2i> = [{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

var obj: SharedObject;

function make_entity(x, y): Entity {
    var e = {
        x: x,
        y: y,
        controllable: true,
        controlled: false,
        colliding: true,

        tool: ToolType_None,
        attached: new Map<Direction, Array<ToolType>>(),

        hp: 6,
    };
    for (d in Type.allEnums(Direction)) {
        e.attached[d] = new Array<ToolType>();
    }
    entities.push(e);

    return e;
}

function new() {
    obj = SharedObject.getLocal("options");

    Gfx.resizescreen(SCREEN_WIDTH, SCREEN_HEIGHT);
    Text.setfont('pixelfj8');
    Gfx.loadtiles('tiles', TILESIZE, TILESIZE);

    var kenic = make_entity(2, 3);
    kenic.controlled = true;
    var enemy = make_entity(4, 3);
    enemy.hp = 2;

    tools.push({
        x: 3,
        y: 4,
        type: ToolType_Shield,
    });
    tools.push({
        x: 4,
        y: 4,
        type: ToolType_Sword,
    });
}

inline function screen_x(x) {
    return unscaled_screen_x(x) * WORLD_SCALE;
}
inline function screen_y(y) {
    return unscaled_screen_y(y) * WORLD_SCALE;
}
inline function unscaled_screen_x(x) {
    return x * TILESIZE;
}
inline function unscaled_screen_y(y) {
    return y * TILESIZE;
}
static inline function out_of_bounds(x, y) {
    return x < 0 || y < 0 || x >= WORLD_WIDTH || y >= WORLD_HEIGHT;
}

function get_free_map(): Array<Array<Bool>> {
    var free_map = Data.create2darray(WORLD_WIDTH, WORLD_HEIGHT, true);

    for (e in entities) {
        if (e.colliding) {
            free_map[e.x][e.y] = false;
        }
    }

    return free_map;
}

function tool_string(tool: ToolType): String {
    return switch (tool) {
        case ToolType_Shield: 'Sh';
        case ToolType_Sword: 'Sw';
        case ToolType_None: 'N';
    }
}

function tool_tile(tool: ToolType): Int {
    return switch (tool) {
        case ToolType_Shield: Tile.Shield;
        case ToolType_Sword: Tile.Sword;
        case ToolType_None: Tile.None;
    }
}

function tool_free_tile(tool: ToolType): Int {
    return switch (tool) {
        case ToolType_Shield: Tile.ShieldFree;
        case ToolType_Sword: Tile.SwordFree;
        case ToolType_None: Tile.None;
    }
}

function draw_entity(e: Entity) {
    var radius = TILESIZE * WORLD_SCALE / 2;

    var circle_color = if (e.controlled) Col.BLUE else Col.NIGHTBLUE;

    Gfx.scale(WORLD_SCALE);

    var tool_x = 0;
    var tool_y = 0;

    tool_y = screen_y(e.y);
    for (t in e.attached[Direction_Left]) {
        Gfx.drawtile(screen_x(e.x), tool_y, tool_tile(t));
        tool_y += 4 * WORLD_SCALE;
    }

    Gfx.rotation(180);
    tool_y = screen_y(e.y);
    for (t in e.attached[Direction_Right]) {
        Gfx.drawtile(screen_x(e.x) + radius * 2, tool_y + radius * 2, tool_tile(t));
        tool_y -= 4 * WORLD_SCALE;
    }

    Gfx.rotation(90);
    tool_x = screen_x(e.x);
    for (t in e.attached[Direction_Up]) {
        Gfx.drawtile(tool_x + radius * 2, screen_y(e.y), tool_tile(t));
        tool_x += 4 * WORLD_SCALE;
    }

    Gfx.rotation(-90);
    tool_x = screen_x(e.x);
    for (t in e.attached[Direction_Down]) {
        Gfx.drawtile(tool_x, screen_y(e.y) + radius * 2, tool_tile(t));
        tool_x += 4 * WORLD_SCALE;
    }

    Gfx.rotation(0);
    
    if (e.controlled) {
        Gfx.drawtile(screen_x(e.x), screen_y(e.y), Tile.Player);
    } else {
        Gfx.drawtile(screen_x(e.x), screen_y(e.y), Tile.Enemy);
    }

    Text.display(screen_x(e.x) + radius - Text.width('${e.hp}') / 2, screen_y(e.y) + radius - Text.height('${e.hp}') / 2, '${e.hp}', Col.YELLOW);
}

function draw_tool(t: Tool) {
    var radius = TILESIZE * WORLD_SCALE / 2;
    var circle_color = Col.ORANGE;

    Gfx.drawtile(screen_x(t.x), screen_y(t.y), tool_free_tile(t.type));
}

function print_entity(e: Entity) {
    trace(e);
    for (d in Type.allEnums(Direction)) {
        trace('$d = ${e.attached[d]}');
    }
}

function render() {
    Gfx.clearscreen(Col.BLACK);
    Gfx.scale(WORLD_SCALE);

    for (x in 0...WORLD_WIDTH) {
        for (y in 0...WORLD_HEIGHT) {
            Gfx.drawtile(screen_x(x), screen_y(y), tiles[x][y]);
        }
    }


    Gfx.scale(1);
    Text.change_size(TEXT_SIZE);
    for (e in entities) {
        draw_entity(e);
    }

    for (t in tools) {
        draw_tool(t);
    }
}

function entity_at(x: Int, y: Int): Entity {
    for (e in entities) {
        if (e.x == x && e.y == y) {
            return e;
        }
    }
    return null;
}

function tool_at(x: Int, y: Int): Tool {
    for (t in tools) {
        if (t.x == x && t.y == y) {
            return t;
        }
    }
    return null;
}

function get_direction(dx: Int, dy: Int): Direction {
    if (dx == 1 && dy == 0) {
        return Direction_Right;
    } else if (dx == -1 && dy == 0) {
        return Direction_Left;
    } else if (dx == 0 && dy == 1) {
        return Direction_Down;
    } else if (dx == 0 && dy == -1) {
        return Direction_Up;
    } else {
        return Direction_None;
    }
}

function get_dxdy(d: Direction): Vec2i {
    return switch (d) {
        case Direction_Right: {x: 1, y: 0};
        case Direction_Left: {x: -1, y: 0};
        case Direction_Up: {x: 0, y: -1};
        case Direction_Down: {x: 0, y: 1};
        case Direction_None: {x: 0, y: 0};
    }
}

function opposite_direction(d: Direction): Direction {
    return switch (d) {
        case Direction_Right: Direction_Left;
        case Direction_Left: Direction_Right;
        case Direction_Up: Direction_Down;
        case Direction_Down: Direction_Up;
        case Direction_None: Direction_None;
    }
}

function contains(array: Array<Dynamic>, thing: Dynamic): Bool {
    return array.indexOf(thing) != -1;
}

function combat(e1: Entity, e2: Entity, direction1: Direction) {
    var direction2 = opposite_direction(direction1);

    var attached1 = e1.attached[direction1];
    var attached2 = e2.attached[direction2];

    var e1_shields = 0;
    var e1_swords = 0;
    for (t in attached1) {
        switch (t) {
            case ToolType_Shield: e1_shields++;
            case ToolType_Sword: e1_swords++;
            case ToolType_None:
        } 
    }

    var e2_shields = 0;
    var e2_swords = 0;
    for (t in attached2) {
        switch (t) {
            case ToolType_Shield: e2_shields++;
            case ToolType_Sword: e2_swords++;
            case ToolType_None:
        } 
    }

    // e2 swords vs e1 shields
    if (e1_shields >= e2_swords) {
        for (i in 0...e2_swords) {
            attached1.remove(ToolType_Shield);
            attached2.remove(ToolType_Sword);
        }
    } else {
        for (i in 0...e1_shields) {
            attached1.remove(ToolType_Shield);
            attached2.remove(ToolType_Sword);
        }
    }

    // e1 swords attack e2 shields
    if (e2_shields >= e1_swords) {
        for (i in 0...e1_swords) {
            attached2.remove(ToolType_Shield);
            attached1.remove(ToolType_Sword);
        }
    } else {
        for (i in 0...e2_shields) {
            attached2.remove(ToolType_Shield);
            attached1.remove(ToolType_Sword);
        }
    }

    // Recount tools
    e1_shields = 0;
    e1_swords = 0;
    for (t in attached1) {
        switch (t) {
            case ToolType_Shield: e1_shields++;
            case ToolType_Sword: e1_swords++;
            case ToolType_None:
        } 
    }

    var e2_shields = 0;
    var e2_swords = 0;
    for (t in attached2) {
        switch (t) {
            case ToolType_Shield: e2_shields++;
            case ToolType_Sword: e2_swords++;
            case ToolType_None:
        } 
    }

    // Actual hurting time
    if (e1_swords > 0) {
        e2.hp -= e1_swords;

        for (i in 0...e1_swords) {
            attached1.remove(ToolType_Sword);
        }
    }

    if (e2_swords > 0) {
        e1.hp -= e2_swords;

        for (i in 0...e1_swords) {
            attached2.remove(ToolType_Sword);
        }
    }

    if (e2.hp <= 0) {
        tools.push({
            x: e2.x,
            y: e2.y,
            type: Random.pick([ToolType_Sword, ToolType_Shield]),
        });

        entities.remove(e2);
    }
}

function update_normal() {
    if (Input.justpressed(Key.SPACE)) {
        var player: Entity = null;
        for (e in entities) {
            if (e.controlled) {
                player = e;
                break;
            }
        }

        var ahmp: Entity = null;
        for (e in entities) {
            if (!e.controlled) {
                ahmp = e;
                break;
            }
        }

        function attach_random_tools(attached: Array<ToolType>) {
            attached.splice(0, attached.length);
            var k = Random.int(1, 4);
            for (i in 0...k) {
                attached.push(Random.pick([ToolType_Sword, ToolType_Shield]));
            }
        }

        attach_random_tools(player.attached[Direction_Right]);

        attach_random_tools(ahmp.attached[Direction_Left]);
    }

    var turn_ended = false;

    render();

    // Tab through controllables
    if (Input.justpressed(Key.TAB)) {
        var select_next = false;
        var selected_someone = false;

        for (e in entities) {
            if (select_next && e.controllable) {
                e.controlled = true;
                selected_someone = true;
                break;
            }

            if (e.controlled) {
                e.controlled = false;
                select_next = true;
            }
        }

        if (!selected_someone) {
            for (e in entities) {
                if (e.controllable) {
                    e.controlled = true;
                    break;
                }
            }
        }
    }

    var player_dx = 0;
    var player_dy = 0;
    var up = Input.delaypressed(Key.W, 4);
    var down = Input.delaypressed(Key.S, 4);
    var left = Input.delaypressed(Key.A, 4);
    var right = Input.delaypressed(Key.D, 4);

    var count = 0;
    if (up) {
        count++;
    }
    if (down) {
        count++;
    }
    if (left) {
        count++;
    }
    if (right) {
        count++;
    }

    if (count == 1) {
        if (up) {
            player_dy = -1;
        } else if (down) {
            player_dy = 1;
        } else if (left) {
            player_dx = -1;
        } else if (right) {
            player_dx = 1;
        }

        turn_ended = true;
    }


    //
    // End of turn
    //
    if (turn_ended) {
        if (player_dx != 0 || player_dy != 0) {
            var player: Entity = null;
            for (e in entities) {
                if (e.controlled) {
                    player = e;
                    break;
                }
            }

            var new_x = player.x + player_dx;
            var new_y = player.y + player_dy;

            var free_map = get_free_map();
            var free = free_map[new_x][new_y];
            var tool = tool_at(new_x, new_y);
            var entity = entity_at(new_x, new_y);
            var direction = get_direction(player_dx, player_dy);

            if (player != null && !out_of_bounds(new_x, new_y)) {
                if (entity != null) {
                    combat(player, entity, direction);
                } else {
                    if (tool != null) {
                        // Attach tool
                        player.attached[direction].push(tool.type);
                        tools.remove(tool);
                    }

                    player.x = new_x;
                    player.y = new_y;
                }
            }
        }
    }
}

function update() {
    switch (game_state) {
        case GameState_Normal: update_normal();
    }
}

}
