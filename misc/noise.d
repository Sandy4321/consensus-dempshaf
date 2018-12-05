module dempshaf.misc.noise;

import dempshaf.misc.importidiom;

/**
 * normalDistribution implements the Box-Muller transform for generating
 * normal distributions from a pair of uniformly generated random numbers.
 *
 * D's mathspecial.normalDistribution function offers no parameters, nor even
 * the ability to seed the RNG.
 */
auto normalDistribution(ref from!"std.random".Random rand)
{
    import std.math : cos, log, pow, PI, sin, sqrt;
    import std.random : uniform;

    immutable auto u1 = uniform(0.0, 1.0, rand);
    immutable auto u2 = uniform(0.0, 1.0, rand);

    immutable auto r = sqrt(-2.0 * log(u1));
    immutable auto theta = 2.0 * PI * u2;

    auto z1 = r * cos(theta);
    auto z2 = r * sin(theta);

    return [z1, z2];
}

/**
 *
 */
auto negComparisonError(
    const double x,
    const double lambda,
    ref from!"std.random".Random rand)
{
    import std.math : E;
    import std.math : pow;

    // Bound the error function in [0, bound]
    immutable auto bound = 0.5;
    auto errorValue = pow(E, -lambda * x) - pow(E, -lambda);
         errorValue = errorValue / 1 - pow(E, -lambda);

    return bound * errorValue;
}