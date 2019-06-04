
@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0); // for bugged/invisible things
    static inline var Floor = at(1, 0);
    static inline var Sword = at(2, 0);
    static inline var Shield = at(3, 0);
    static inline var Player = at(4, 0);
    static inline var Enemy = at(5, 0);
    static inline var SwordFree = at(6, 0);
    static inline var ShieldFree = at(7, 0);
}