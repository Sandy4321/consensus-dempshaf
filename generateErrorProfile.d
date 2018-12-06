module dempshaf.generateErrorProfile;

import dempshaf.misc.noise;

import std.conv, std.stdio, std.string;

void main(string[] args)
{
    auto lambda = [-10.0, -5.0, -3.0, -1.0, -0.1, 0.0, 1.0, 3.0, 5.0, 10.0, 20.0, 100.0];
    immutable auto xSamples = 1000;

    auto results = new double[][](lambda.length, xSamples + 1);

    foreach (i, value; lambda)
    {
        foreach (x; 0 .. xSamples + 1)
        {
            results[i][x] = comparisonError(x/xSamples.to!double, value);
            // writeln(value);
            // writeln(x/xSamples.to!double);
        }
    }

    // Write the results

    string directory = "../results/test_results/dempshaf/";

    auto file = File("error_results.csv", "w");

    foreach (i, value; lambda)
    {
        file.write(format("%.2f", value));
        file.write((value == lambda[$-1]) ? "\n" : ",");
    }
    foreach (i, value; lambda)
    {
        foreach (x; 0 .. xSamples + 1)
        {
            file.write(format("%.4f", results[i][x]));
            file.write((x == cast(ulong) results[i].length - 1) ? "\n" : ",");
        }
    }
    file.close();
}