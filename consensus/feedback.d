module dempshaf.consensus.feedback;

public import std.random;

interface Feedback
{
	public static double maximalPayoff = 0;
	public static double[][] generatePayoff(Random, int);
	public static double calculatePayoff(double[][], int[][]);
	public static double minPayoff(double[]);
	public static double maxPayoff(double[]);
	public static double totalPayoff(double[], double);
	public static int[] rouletteSelection(Random, double[], double, double, int);
	public static double distance(double[2][] worldBeliefs1, double[2][] worldBeliefs2, int l);
	public static double valuationDistance(int[][][], double[], int[][][], double[]);
}

