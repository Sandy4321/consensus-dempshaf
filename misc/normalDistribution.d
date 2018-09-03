module dempshaf.misc.normalDistribution;

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
    import std.random : uniform01;

    auto u1 = uniform01(rand);
    auto u2 = uniform01(rand);

    auto r = sqrt(-2.0 * log(u1));
    auto theta = 2.0 * pi * u2;

    auto z1 = r * cos(theta);
    auto z2 = r * sin(theta);

    return [z1, z2]
}
