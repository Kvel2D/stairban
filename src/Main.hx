
import haxegon.*;
import openfl.net.SharedObject;

import Tile;

using haxegon.MathExtensions;
using Lambda;

enum GameState {
    GameState_Normal;
}

enum Tool {
    Tool_None;
    Tool_Legs;
    Tool_Hand;
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
    dx: Int,
    dy: Int,
    z: Int,
    name: String,
    controllable: Bool,
    controlled: Bool,
    colliding: Bool,

    tool: Tool,
    attached: Map<Direction, Array<Tool>>,
};

@:publicFields
class Main {
// force unindent

static inline var SCREEN_WIDTH = 1600;
static inline var SCREEN_HEIGHT = 960;
static inline var TILESIZE = 64;
static inline var WORLD_WIDTH = 6;
static inline var WORLD_HEIGHT = 6;
static inline var WORLD_SCALE = 2;
static inline var MESSAGES_Y = 580;
static inline var TEXT_SIZE = 10;
static inline var Z_MIN = -1;
static inline var Z_MAX = 1;

var game_state = GameState_Normal;

var tiles = Data.create2darray(WORLD_WIDTH, WORLD_HEIGHT, Tile.Floor);
var entities = new Array<Entity>();

var cardinals: Array<Vec2i> = [{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

var obj: SharedObject;

function make_entity(x, y, name): Entity {
    var e = {
        x: x,
        y: y,
        dx: 0,
        dy: 0,
        z: 0,
        name: name,
        controllable: true,
        controlled: false,
        colliding: true,

        tool: Tool_None,
        attached: new Map<Direction, Array<Tool>>(),
    };
    for (d in Type.allEnums(Direction)) {
        e.attached[d] = new Array<Tool>();
    }
    entities.push(e);

    return e;
}

function new() {
    obj = SharedObject.getLocal("options");

    Gfx.resizescreen(SCREEN_WIDTH, SCREEN_HEIGHT);
    Text.setfont('pixelfj8');
    Gfx.loadtiles('tiles', TILESIZE, TILESIZE);

    var kenic = make_entity(2, 3, 'Kenic');
    kenic.controlled = true;
    kenic.attached[Direction_Down].push(Tool_Legs);
    kenic.attached[Direction_Left].push(Tool_Hand);
    kenic.attached[Direction_Right].push(Tool_Hand);
    kenic.attached[Direction_Up].push(Tool_Hand);
    make_entity(4, 3, 'Ahmp');
    make_entity(5, 1, 'Jipple');

    var legs = make_entity(3, 4, 'Legs');
    legs.tool = Tool_Legs;

    var hands = make_entity(3, 2, 'Hands');
    hands.tool = Tool_Hand;
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

function tool_string(tool: Tool): String {
    return switch (tool) {
        case Tool_Legs: 'L';
        case Tool_Hand: 'H';
        case Tool_None: 'H';
    }
}

function draw_entity(e: Entity) {
    var radius = TILESIZE * WORLD_SCALE / 2;
    var circle_color = if (e.controlled) Col.BLUE else Col.NIGHTBLUE;
    Gfx.drawcircle(screen_x(e.x) + radius, screen_y(e.y) + radius, radius, circle_color);
    Text.display(screen_x(e.x) + radius - Text.width(e.name), screen_y(e.y) + radius, e.name, Col.PINK);

    var down = '';
    for (t in e.attached[Direction_Down]) {
        down += tool_string(t) + ',';
    }
    Text.display(screen_x(e.x), screen_y(e.y) + radius * 1.5, down, Col.PINK);

    var up = '';
    for (t in e.attached[Direction_Up]) {
        up += tool_string(t);
    }
    Text.display(screen_x(e.x), screen_y(e.y), up, Col.PINK);

    var left = '';
    for (t in e.attached[Direction_Left]) {
        left += tool_string(t);
    }
    Text.display(screen_x(e.x), screen_y(e.y) + radius, left, Col.PINK);

    var right = '';
    for (t in e.attached[Direction_Right]) {
        right += tool_string(t);
    }
    Text.display(screen_x(e.x) + radius * 2, screen_y(e.y) + radius, right, Col.PINK);
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

    for (e in entities) {
        if (e.z < Z_MIN || e.z > Z_MAX) {
            trace('entity has incorrect z = ${e.z}, entity = ${e}');
        }
    }

    Gfx.scale(1);
    Text.change_size(TEXT_SIZE);
    for (z in Z_MIN...(Z_MAX + 1)) {
        for (e in entities) {
            if (e.z == z) {
                draw_entity(e);
            }
        }
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

function push_onto(subject: Entity, pushed: Entity, dx: Int, dy: Int): Bool {
    // Invert because the direction of pushing is inverse the direction of attachment
    var direction = get_direction(-dx, -dy);

    var success = false;

    if (dy == -1 && pushed.tool == Tool_Legs && !contains(subject.attached[Direction_Down], Tool_Legs)) {
        subject.attached[Direction_Down].push(Tool_Legs);
        success = true;
    } else if (pushed.tool == Tool_Hand && !contains(subject.attached[direction], pushed.tool)) {
        subject.attached[direction].push(Tool_Hand);
        success = true;
    }

    if (success) {
        entities.remove(pushed);
        return true;
    } else {
        return false;
    }
}

function contains(array: Array<Dynamic>, thing: Dynamic): Bool {
    return array.indexOf(thing) != -1;
}

function update_normal() {
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
            var new_x2 = player.x + player_dx * 2;
            var new_y2 = player.y + player_dy * 2;

            var free_map = get_free_map();

            if (player != null && contains(player.attached[Direction_Down], Tool_Legs) && !out_of_bounds(new_x, new_y)) {

                if (free_map[new_x][new_y]) {
                    // Free tile
                    player.x = new_x;
                    player.y = new_y;
                } else if (!out_of_bounds(new_x2, new_y2)) {
                    var direction = get_direction(player_dx, player_dy);

                    if (contains(player.attached[direction], Tool_Hand)) {
                        if (free_map[new_x2][new_y2]) {
                            // Pushing onto free space
                            var pushed_entity = entity_at(new_x, new_y);
                            pushed_entity.x = new_x2;
                            pushed_entity.y = new_y2;
                            player.x = new_x;
                            player.y = new_y;
                        } else {
                            var subject = entity_at(new_x2, new_y2);
                            var pushed = entity_at(new_x, new_y);

                            // Try to push onto
                            if (push_onto(subject, pushed, player_dx, player_dy)) {
                                player.x = new_x;
                                player.y = new_y;
                            }
                        }
                    }
                }
            }


            for (e in entities) {
                if (e.controlled) {
                    continue;
                }

                for (d in Type.allEnums(Direction)) {
                    if (contains(e.attached[d], Tool_Hand)) {
                        var dxdy = get_dxdy(d);

                        var new_x = e.x + dxdy.x;
                        var new_y = e.y + dxdy.y;

                        if (!out_of_bounds(new_x, new_y)) {
                            var pushed = entity_at(new_x, new_y);


                            if (pushed != null) {
                                pushed.dx += dxdy.x;
                                pushed.dy += dxdy.y;
                            }
                        }
                    }
                }
            }

            for (e in entities) {
                if (e.controlled) {
                    continue;
                }

                // NOTE: doesn't take into account conflicts
                while (e.dx != 0 || e.dy != 0) {
                    e.x += Math.sign(e.dx);
                    e.y += Math.sign(e.dy);
                    e.dx -= Math.sign(e.dx);
                    e.dy -= Math.sign(e.dy);
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
