
import Main;

@:publicFields
class Tile {
    static inline var tileset_width = 8;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0);
    static inline var Floor = at(1, 0);
    static inline var Elevated = at(2, 0);
    static inline var Wall = at(3, 0);
    static inline var Bridge = at(4, 0);

    static inline var Player = at(0, 1);
    static inline var Box = at(1, 1);
    static inline var StairsUp = at(2, 1);
    static inline var StairsLeft = at(3, 1);
    static inline var StairsDown = at(4, 1);
    static inline var StairsRight = at(5, 1);
    
    static inline var IsoGround = 0;
    static inline var IsoBox = 1;
    static inline var IsoPlayer = 2;
    static inline var IsoStairsLeft = 3;
    static inline var IsoStairsUp = 4;
    static inline var IsoStairsRight = 5;
    static inline var IsoStairsDown = 6;
}