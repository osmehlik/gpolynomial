
module net.smehlik.math.geometry;

import std.math;
import net.smehlik.types;

/**
 * Calculates distance between two points.
 * Params:
 *     p1 = the first point
 *     p2 = the second point
 * Returns:
 *     the distance between p1 and p2
 */
pure T dist(T = double)(ref Vec2 p1, ref Vec2 p2)
{
    T a = abs(p2.x - p1.x);
    T b = abs(p2.y - p1.y);

    return sqrt(a*a + b*b);
}
