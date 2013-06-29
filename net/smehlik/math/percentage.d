
module net.smehlik.math.percentage;

/**
 * Calculates the given number of percent from whole.
 * Params:
 *     percent = amount of percent to take from whole
 *     whole = size of whole
 * Returns:
 *     size of part
 */
pure T getPart(T = double)(T percent, T whole) nothrow
{
    return whole * 0.01 * percent;
}

unittest
{
   assert(getPart(30.0, 10.0) == 3.0);
   assert(getPart(0.0, 10.0) == 0.0);
   assert(getPart(100.0, 10.0) == 10.0);
   assert(getPart(200.0, 10.0) == 20.0);
}

/**
 * Calculates how much percent is a part from a whole.
 * Params:
 *     part = size of part
 *     whole = size of whole
 * Returns:
 *     number of percent
 */
pure T getPercent(T = double)(T part, T whole)
{
    return part / (whole * 0.01);
}

unittest
{
    assert(getPercent(0.0, 10.0) == 0.0);
    assert(getPercent(5.0, 10.0) == 50.0);
    assert(getPercent(20.0, 10.0) == 200.0);
}

/**
 * Maps value in one range to another range.
 * Params:
 *     inMin = minimal value in input range
 *     inCur = current value in input range, should be inMin <= inCur <= inMax
 *     inMax = maximal value in input range
 *     outMin = minimal value in output range
 *     outMax = maximal value in output range
 * Returns:
 *     percentually equivalent value in output range
 */
pure T mapRange(T = double)(T inMin, T inCur, T inMax, T outMin, T outMax)
{
    T inPartDist = inCur - inMin;
    T inWholeDist = inMax - inMin;
    T outDist = outMax - outMin;

    T inPercent = getPercent(inPartDist, inWholeDist);
    T outPart = getPart(inPercent, outDist);
    
    return outMin + outPart;
}

unittest
{
    assert(mapRange(2.0, 3.0, 6.0, 10.0, 14.0) == 11.0);
    assert(mapRange(2.0, 3.0, 6.0, 14.0, 10.0) == 13.0);
}
