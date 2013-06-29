/**
 * Methods for working with polynomials.
 * [3, 6, 8] = 8x^2 + 6x + 3
 * Authors: Oldrich Smehlik, oldrich@smehlik.net
 */

module net.smehlik.math.polynomial;

import std.conv;
import std.math;
import std.stdio;
import std.string;
import net.smehlik.types;


/**
 * Adds two polynomials
 * Params:
 *     p1 = the first polynomial to add
 *     p2 = the second polynomial to add
 * Returns:
 *     p1 + p2
 */
pure T[] polyAdd(T = double)(T[] p1, T[] p2)
{
    T[] pr;

    pr.length = p1.length > p2.length ? p1.length : p2.length;

    foreach (ref T p; pr) { p = 0; }

    for (uint i = 0; i < pr.length; ++i) {
        pr[i] = (i < p1.length ? p1[i] : 0) + (i < p2.length ? p2[i] : 0);
    }

    polyRemoveTrailingZeros(pr);

    return pr;
}

unittest
{
    assert(polyAdd!uint([],[]) == []);
    assert(polyAdd([1,2],[3]) == [4,2]);
    assert(polyAdd([1],[2,3]) == [3,3]);
    assert(polyAdd([1,2],[3,4]) == [4,6]);
}

/**
 * Inverts a polynomial
 * Params:
 *    p = a polynomial to invert
 * Returns:
 *    -p
 */
pure T[] polyInv(T = double)(T[] p)
{
    T[] pr;

    foreach (T item; p) {
        pr ~= -item;
    }

    return pr;
}

unittest
{
    assert(polyInv!uint([]) == []);
    assert(polyInv([-1,2]) == [1,-2]);
}

/**
 * Substracts one polynomial from the other polynomial.
 * Params:
 *     p1 = minuend
 *     p2 = subtrahend
 * Returns:
 *     p1 - p2
 */
pure T[] polySubstract(T = double)(T[] p1, T[] p2)
{
    T[] pr = polyAdd(p1, polyInv(p2));

    polyRemoveTrailingZeros(pr);

    return pr;
}

unittest
{
    assert(polySubstract([4,5,2], [1,0,8]) == [3,5,-6]);
}

/**
 * Multiplies two polynomials.
 * Params:
 *     p1 = factor
 *     p2 = factor
 * Returns:
 *     p1 * p2
 */
pure T[] polyMul(T = double)(T[] p1, T[] p2)
{
    T[] pr;

    pr.length = p1.length + p2.length - 1;

    foreach (ref T p; pr) { p = 0; }

    for (int i = 0; i < p1.length; ++i) {
        for (int j = 0; j < p2.length; ++j) {
            pr[i+j] += p1[i] * p2[j];
        }
    }

    polyRemoveTrailingZeros(pr);

    return pr;
}

unittest
{
    assert(polyMul([5,3],[-2,3]) == [-10,9,9]);
}

/**
 * Divides a polynomial by a number.
 * Params:
 *     p = polynom to divide
 *     divisor = number to divide polynom with
 * Returns:
 *     array of item/divisor for each item in p
 */
pure T[] polyDiv(T = double)(T[] p, T divisor)
{
    T[] pr;

    foreach (T item; p) {
        pr ~= (item / divisor);
    }

    polyRemoveTrailingZeros(pr);

    return pr;
}

unittest
{
    assert(polyDiv([24,16,40],4) == [6,4,10]);
}

/**
 * Removes trailing zeros from polynomial.
 */
void polyRemoveTrailingZeros(T = double)(ref T[] p)
{
    for (int i = cast(int)p.length - 1; i >= 0; --i) {
        if (p[i] == 0) {
            p.length = i + 1;
        }
        else {
            return;
        }
    }
}


/**
 * Params:
 *     points = a set of points
 * Returns:
 *     lagrange polynomial interpolating a set of points 
 */
pure T[] polyInterpolate(T=double)(Vec2D[] points)
{
    T[] result;


    T[] x = [0, 1];

    for (int i = 0; i < points.length; ++i) {

        T[] substract;
        T[] numerator = [1];
        T[] denominator = [1];

        T[] x_i = [points[i].x];
        T[] y_i = [points[i].y];

        for (int j = 0; j < points.length; ++j) {
            if (i == j) continue;

            T[] x_j = [points[j].x];

            substract = polySubstract(x, x_j);
            numerator = polyMul(numerator, substract);

            substract = polySubstract(x_i, x_j);
            denominator = polyMul(denominator, substract);

        }

        T[] fraction = polyDiv(numerator, denominator[0]);
        fraction = polyMul(fraction, y_i);
        result   = polyAdd(result, fraction);
    }

    return result;
}

/**
 * Evalutes polynomial at the given point.
 * Params:
 *     p = polynomial
 *     x = point to evaluate polynomial for
 * Returns:
 *     y = p(x)
 */
T polyEval(T=double)(T[] p, T x)
{
    T sum = 0;

    for (int i = 0; i < p.length; ++i) {
        sum += p[i] * pow(x,i);
    }

    return sum;
}

unittest
{
    assert(polyEval([0,0,1],4)==16);
}

string polyPrint(double[] poly)
{
    string s;

    for (int i = cast(int)poly.length - 1; i >= 0; --i) {

        if (s.length > 0) {
	    s ~= " ";
        }

	if (poly[i] >= 0) {
	    s ~= format(" + %.6f", poly[i]);
	}
	else {
	    s ~= format(" - %.6f", -poly[i]);
        }

        if (i > 0) s ~= " x";
	if (i > 1) s ~= "<sup>" ~ text(i) ~ "</sup>";
    }

    return s;
}



