module dempshaf.generateNoiseProfile;

import dempshaf.misc.normalDistribution;

import std.math, std.stdio, std.string, std.random;

void main(string[] args)
{
    immutable auto iterations = 1000;

    immutable auto seed = unpredictableSeed;
    auto rand = Random(seed);

    immutable auto noiseSigma = sqrt(0.025);

    immutable auto choices = 3;
    immutable auto qualities = [0.8, 0.9, 1.0];

    auto values = new double[][](choices, iterations);

    auto getNoise = true;
    real[2] noisePair;

    foreach (iteration; 0 .. iterations)
    {
        foreach (choice; 0 .. choices)
        {
            double noise;
            double quality = qualities[choice];
            do
            {
                if (getNoise)
                {
                    noisePair = normalDistribution(rand);
                    noise = noisePair[0];
                    getNoise = false;
                }
                else
                {
                    noise = noisePair[1];
                    getNoise = true;
                }

                noise *= noiseSigma;

                if (quality + noise > 1.0 || quality + noise < 0.0)
                    noise = -noise;

            } while (quality + noise < 0 || quality + noise > 1);
            quality += noise;

            if (quality > 1)      values[choice][iteration] = 1.0;
            else if (quality < 0) values[choice][iteration] = 0.0;
            else                  values[choice][iteration] = quality;
        }
    }

    // Write the results

    string directory = "../results/test_results/dempshaf/";

    auto file = File("noise_results.csv", "w");
    foreach (choice; 0 .. choices)
    {
        foreach (iteration; 0 .. iterations)
        {
            file.write(values[choice][iteration]);
            file.write((iteration == cast(ulong) values[choice].length - 1) ? "\n" : ",");
        }
    }
    file.close();
}