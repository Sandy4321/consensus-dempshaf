module dempshaf.generateNoiseProfile;

import dempshaf.misc.normalDistribution;

import std.math, std.stdio, std.string, std.random;

void main(string[] args)
{
    immutable auto iterations = 500_000;

    auto rand = Random(unpredictableSeed);

    immutable auto variance = 0.1; // Sigma^2, StdDev = Sigma, sqrt(Sigma^2)

    immutable auto qualitySet = [
        [0.3, 0.9],
        [0.5, 1.0],
        [0.9, 1.0],

        [0.2, 0.4, 1.0],
        [0.3, 0.5, 0.7],
        [0.8, 0.9, 1.0]
    ];

    immutable auto qualities = qualitySet[5];
    immutable auto choices = qualities.length;

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

                noise *= variance;

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

    file.write(format("%.3f\n", variance));
    foreach (choice; 0 .. choices)
    {
        file.write(format("%.2f", qualities[choice]));
        file.write((choice == choices - 1) ? "\n" : ",");
    }
    foreach (choice; 0 .. choices)
    {
        foreach (iteration; 0 .. iterations)
        {
            file.write(format("%.4f", values[choice][iteration]));
            file.write((iteration == cast(ulong) values[choice].length - 1) ? "\n" : ",");
        }
    }
    file.close();
}