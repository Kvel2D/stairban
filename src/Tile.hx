
@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0); // for bugged/invisible things
    static inline var Floor = at(1, 0);
}