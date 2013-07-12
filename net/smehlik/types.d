
module net.smehlik.types;

struct Vec2 {
    double x, y;

    Vec2 opBinary(string op)(Vec2 other) {
        Vec2 res;

        res.x = mixin("x" ~ op ~ "other.x");
        res.y = mixin("y" ~ op ~ "other.y");

        return res;
    }
}

