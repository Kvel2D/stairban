
import haxegon.*;

using haxegon.MathExtensions;
using Lambda;

enum Direction {
    Direction_Left;
    Direction_Right;
    Direction_Up;
    Direction_Down;
    Direction_None;
}

typedef Entity = {
    pos: Vec3i,
    prev_pos: Vec3i,
    history: Array<Vec3i>,
    stair_direction: Direction, 
};

@:publicFields
class Game {
// force unindent

static inline var RENDER_SCALE = 8;
static inline var TILESIZE = 8;
static inline var WORLD_WIDTH = Math.ceil(1000 / TILESIZE / RENDER_SCALE);
static inline var WORLD_HEIGHT = Math.ceil(Main.SCREEN_HEIGHT / TILESIZE / RENDER_SCALE);
static inline var WORLD_ELEVATION = 2;

static var DRAW_ISO = false;

static var walls: Array<Array<Array<Bool>>>;
static var entities: Array<Entity>;
static var player_pos: Vec3i;
static var player_history: Array<Vec3i>;

static function stairs(x, y, z, direction) {
    entities.push({
        pos: {x: x, y: y, z: z},
        prev_pos: {x: x, y: y, z: z},
        history: new Array<Vec3i>(),
        stair_direction: direction,
    });
}

static function box(x, y, z) {
    stairs(x, y, z, Direction_None);
}

static function walls_rect(x, y, z, width, height) {
    for (dx in 0...width) {
        for (dy in 0...height) {
            walls[x + dx][y + dy][z] = true;
        }
    }
}

static inline function screenx(x) {
    return x * TILESIZE * RENDER_SCALE;
}
static inline function screeny(y) {
    return y * TILESIZE * RENDER_SCALE;
}

static inline function out_of_bounds(x, y) {
    return x < 0 || y < 0 || x >= WORLD_WIDTH || y >= WORLD_HEIGHT;
}

static function entity_at(x: Int, y: Int, z: Int): Entity {
    for (e in entities) {
        if (e.pos.x == x && e.pos.y == y && e.pos.z == z) {
            return e;
        }
    }
    return null;
}

static function draw_tile(x, y, z, tile) {
    if (z == 1) {
        Gfx.scale(RENDER_SCALE / 2);
        var size = TILESIZE * RENDER_SCALE;
        Gfx.drawtile(screenx(x) + size / 4, screeny(y) + size / 4, tile);
        Gfx.scale(RENDER_SCALE);
    } else {
        Gfx.drawtile(screenx(x), screeny(y), tile);
    }
}

static var ISO_OFFSET_X = 14;
static var ISO_OFFSET_Y = 7;
static var ISO_OFFSET_Z = 15;
static var ISO_ORIGIN_X = 1400;
static var ISO_ORIGIN_Y = 100;

static var tiles_cache = [for (x in 0...WORLD_WIDTH) [for (y in 0...WORLD_HEIGHT) Tile.None]];

static function render(drawing_to_image: String = null) {
    Gfx.clearscreen(Col.LIGHTBLUE);

    Gfx.drawtoimage('tiles_canvas');
    Gfx.scale(1);
    for (x in 0...WORLD_WIDTH) {
        for (y in 0...WORLD_HEIGHT) {
            var tile = if (!walls[x][y][0] && !walls[x][y][1]) {
                Tile.Floor;
            } else if (walls[x][y][0] && !walls[x][y][1]) {
                Tile.Elevated;
            } else if (walls[x][y][0] && walls[x][y][1]) {
                Tile.Wall;
            } else if (!walls[x][y][0] && walls[x][y][1]) {
                Tile.Bridge;
            } else {
                Tile.None;
            }

            if (tile != tiles_cache[x][y]) {
                Gfx.drawtile(x * TILESIZE, y * TILESIZE, tile);
                tiles_cache[x][y] = tile;
            }
        }
    }

    if (drawing_to_image == null) {
        Gfx.drawtoscreen();
    } else {
        Gfx.drawtoimage(drawing_to_image);
    }

    Gfx.scale(RENDER_SCALE);
    Gfx.drawimage(0, 0, 'tiles_canvas');

    for (e in entities) {
        // TODO: select stair tile
        var tile = switch (e.stair_direction) {
            case Direction_None: Tile.Box;
            case Direction_Up: Tile.StairsUp;
            case Direction_Down: Tile.StairsDown;
            case Direction_Right: Tile.StairsRight;
            case Direction_Left: Tile.StairsLeft;
        }
        draw_tile(e.pos.x, e.pos.y, e.pos.z, tile);
    }

    draw_tile(player_pos.x, player_pos.y, player_pos.z, Tile.Player);

    if (Main.state == State_Game) {
        Text.display(0, 0, '${Main.level_name}', Col.YELLOW);
    }

    if (DRAW_ISO) {
        Gfx.changetileset('isometric_tiles');
        var ISOSCALE = 2;
        Gfx.scale(ISOSCALE);
        var k = 0;
        var x = 0;
        var y = 0;

        var ISOTILEWIDTH = 26;

        // GUI.x = 400;
        // GUI.y = 0;
        // GUI.auto_slider('x offset', function(x) { ISO_OFFSET_X = Math.round(x); }, ISO_OFFSET_X, 5, 30, 10, 400);
        // GUI.auto_slider('y offset', function(x) { ISO_OFFSET_Y = Math.round(x); }, ISO_OFFSET_Y, 5, 30, 10, 400);
        // GUI.auto_slider('z offset', function(x) { ISO_OFFSET_Z = Math.round(x); }, ISO_OFFSET_Z, 5, 30, 10, 400);

        function draw_stuff(x, y, z, draw_x, draw_y) {
            if (walls[x][y][z]) {
                Gfx.drawtile(draw_x, draw_y, Tile.IsoGround);
            }

            if (player_pos.x == x && player_pos.y == y && player_pos.z == z) {  
                Gfx.drawtile(draw_x, draw_y, Tile.IsoPlayer);
            }

            var e = entity_at(x, y, z);
            if (e != null) {  
                switch (e.stair_direction) {
                    case Direction_None: Gfx.drawtile(draw_x, draw_y, Tile.IsoBox);
                    case Direction_Left: Gfx.drawtile(draw_x, draw_y, Tile.IsoStairsLeft);
                    case Direction_Up: Gfx.drawtile(draw_x, draw_y, Tile.IsoStairsUp);
                    case Direction_Down: Gfx.drawtile(draw_x, draw_y, Tile.IsoStairsDown);
                    case Direction_Right: Gfx.drawtile(draw_x, draw_y, Tile.IsoStairsRight);
                    default:
                }
            }
        }

        var draw_x_start = ISO_ORIGIN_X;
        var draw_x = draw_x_start;
        var draw_y = ISO_ORIGIN_Y + ISO_OFFSET_Z * ISOSCALE;
        while (k < WORLD_HEIGHT) {
            x = 0;
            y = k;

            draw_x = draw_x_start;

            while (y > 0) {
                x++;
                y--;

                draw_x += ISOTILEWIDTH * ISOSCALE;

                Gfx.drawtile(draw_x, draw_y, Tile.IsoGround);
            }

            draw_x_start -= ISO_OFFSET_X * ISOSCALE;
            draw_y += ISO_OFFSET_Y * ISOSCALE;

            k++;
        }

        x = 0;
        k = 0;
        y = 0;
        draw_x_start = ISO_ORIGIN_X;
        draw_x = draw_x_start;
        draw_y = ISO_ORIGIN_Y;
        while (k < WORLD_HEIGHT) {
            x = 0;
            y = k;

            draw_x = draw_x_start;

            while (y > 0) {
                x++;
                y--;

                draw_x += ISOTILEWIDTH * ISOSCALE;

                draw_stuff(x, y, 0, draw_x, draw_y);
            }

            draw_x_start -= ISO_OFFSET_X * ISOSCALE;
            draw_y += ISO_OFFSET_Y * ISOSCALE;

            k++;
        }

        x = 0;
        k = 0;
        y = 0;
        draw_x_start = ISO_ORIGIN_X;
        draw_x = draw_x_start;
        draw_y = ISO_ORIGIN_Y - ISO_OFFSET_Z * ISOSCALE;
        while (k < WORLD_HEIGHT) {
            x = 0;
            y = k;

            draw_x = draw_x_start;

            while (y > 0) {
                x++;
                y--;

                draw_x += ISOTILEWIDTH * ISOSCALE;

                draw_stuff(x, y, 1, draw_x, draw_y);
            }

            draw_x_start -= ISO_OFFSET_X * ISOSCALE;
            draw_y += ISO_OFFSET_Y * ISOSCALE;

            k++;
        }

        Gfx.changetileset('tiles');

    }
}

static function direction_aligns(direction: Direction, dx, dy): Bool {
    return switch (direction) {
        case Direction_None: false;
        case Direction_Up: dx == 0 && dy == -1;
        case Direction_Down: dx == 0 && dy == 1;
        case Direction_Right: dx == 1 && dy == 0;
        case Direction_Left: dx == -1 && dy == 0;
    };
}

static function occupied(x, y, z): Bool {
    return out_of_bounds(x, y) || walls[x][y][z] || entity_at(x, y, z) != null;
}

static function drop_pos(pos: Vec3i): Int {
    var z = pos.z;
    while (z > 0 && !occupied(pos.x, pos.y, z - 1)) {
        z--;
    }
    return z;
}

static function move(pos: Vec3i, dx: Int, dy: Int, is_player: Bool): Bool {
    var moved = false;
    var used_stairs = false;
    var move_x = pos.x + dx;
    var move_y = pos.y + dy;
    var stairs_x = pos.x + 2 * dx;
    var stairs_y = pos.y + 2 * dy;

    var below_e = entity_at(move_x, move_y, pos.z - 1);
    var below_occupied = occupied(move_x, move_y, pos.z - 1);
    var above_e = entity_at(move_x, move_y, pos.z + 1);
    var move_e = entity_at(move_x, move_y, pos.z);
    var move_occupied = occupied(move_x, move_y, pos.z);
    var stairs_e = entity_at(stairs_x, stairs_y, 0);
    var stairs_occupied = occupied(stairs_x, stairs_y, 0);

    if (pos.z == 0) {
        // On the ground
        if (is_player) {
            if (!move_occupied) {
                // Move into empty space
                moved = true;
            } else if (move_e != null) {
                if (above_e == null && (move_e.stair_direction == Direction_None || !direction_aligns(move_e.stair_direction, dx, dy))) {
                    // Push box or stairs from side
                    if (move(move_e.pos, dx, dy, false)) {
                        moved = true;
                    }
                } else if (direction_aligns(move_e.stair_direction, dx, dy) && !occupied(stairs_x, stairs_y, 1)) {
                    if (stairs_occupied && (stairs_e == null || stairs_e.stair_direction == Direction_None)) {
                        // Use stairs
                        pos.z = 1;
                        used_stairs = true;
                    } else {
                        // Push stairs from front
                        if (move(move_e.pos, dx, dy, false)) {
                            moved = true;
                        }
                    }
                }
            }
        } else {
            if (!move_occupied) {
                // Move into empty space
                moved = true;
            }                
        }
    } else if (pos.z == 1) {
        // Elevated
        if (is_player) {
            if (!move_occupied) {
                if (below_occupied && (below_e == null || below_e.stair_direction == Direction_None)) {
                    // Move on top of wall or box
                    moved = true;
                } else if (below_e != null && direction_aligns(below_e.stair_direction, -dx, -dy) && !occupied(stairs_x, stairs_y, 0)) {
                    // Use stairs
                    used_stairs = true;
                }
            } else if (move_e != null) {
                var pushed = move(move_e.pos, dx, dy, false);
                moved = pushed;
            }
        } else {
            if (!move_occupied && (below_e == null || below_e.stair_direction == Direction_None)) {
                // Move into empty space, on top of wall or box or drop down to ground
                moved = true;
            }
        }
    }

    if (used_stairs) {
        pos.x = stairs_x;
        pos.y = stairs_y;
    } else if (moved) {
        pos.x = move_x;
        pos.y = move_y;
    }

    // Apply gravity
    pos.z = drop_pos(pos);

    return moved || used_stairs;
}

static function update() {
    if (Input.delaypressed(Key.Z, 10) && player_history.length > 0) {
        var prev_pos = player_history.pop();
        player_pos.x = prev_pos.x;
        player_pos.y = prev_pos.y;
        player_pos.z = prev_pos.z;

        for (e in entities) {
            var prev_pos = e.history.pop();
            e.pos.x = prev_pos.x;
            e.pos.y = prev_pos.y;
            e.pos.z = prev_pos.z;
            e.prev_pos.x = e.pos.x;
            e.prev_pos.y = e.pos.y;
            e.prev_pos.z = e.pos.z;
        }
    }

    if (Input.justpressed(Key.R)) {
        Main.load_level(Main.level_name);
    }

    var player_dx = 0;
    var player_dy = 0;
    var up = Input.delaypressed(Key.W, 5);
    var down = Input.delaypressed(Key.S, 5);
    var left = Input.delaypressed(Key.A, 5);
    var right = Input.delaypressed(Key.D, 5);

    if (up && !down) {
        player_dy = -1;
    }
    if (down && !up) {
        player_dy = 1;
    }
    if (left && !right) {
        player_dx = -1;
    }
    if (right && !left) {
        player_dx = 1;
    }            

    if (player_dx != 0|| player_dy != 0) {
        var prev_pos = {x: player_pos.x, y: player_pos.y, z: player_pos.z};
        move(player_pos, player_dx, player_dy, true);

        if (player_pos.x != prev_pos.x || player_pos.y != prev_pos.y || player_pos.z != prev_pos.z) {
            player_history.push(prev_pos);
            
            for (e in entities) {
                e.history.push({x: e.prev_pos.x, y: e.prev_pos.y, z: e.prev_pos.z});
                e.prev_pos.x = e.pos.x;
                e.prev_pos.y = e.pos.y;
                e.prev_pos.z = e.pos.z;
            }
        }
    }

    render();
}

}
