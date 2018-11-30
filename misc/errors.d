module dempshaf.misc.errors;

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

    auto u1 = uniform(0.0, 1.0, rand);
    auto u2 = uniform(0.0, 1.0, rand);

    auto r = sqrt(-2.0 * log(u1));
    auto theta = 2.0 * PI * u2;

    auto z1 = r * cos(theta);
    auto z2 = r * sin(theta);

    return [z1, z2];
}
