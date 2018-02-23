module dempshaf.consensus.operators;

import std.math;

public final class Operators
{
	public
	{
		static double entropy(
			in double[2][] beliefs,
			in int l)
		{
			double entropy = 0.0;
			double one, two, logOne, logTwo, logThree = 0.0;

			foreach (belief; beliefs)
			{
				one = (belief[1] - belief[0]) < 0 ? 0 : (belief[1] - belief[0]);
				two = (1.0 - belief[1]) < 0 ? 0 : 1.0 - belief[1];

				logOne = (belief[0] == 0 ? 0 : log2(belief[0]));
				logTwo = (one == 0 ? 0 : log2(one));
				logThree = (two == 0 ? 0 : log2(two));

				entropy -= (belief[0] * logOne)
						+ (one * logTwo)
						+ (two * logThree);
			}

			return entropy / l;
		}

		static double inconsistency(
			in double[2][] beliefs1,
			in double[2][] beliefs2,
			in int l)
		{
			double inconsistency = 0.0;
			foreach (prop; 0 .. l)
			{
				inconsistency += (beliefs1[prop][0] * (1.0 - beliefs2[prop][1])) +
					((1.0 - beliefs1[prop][1]) * beliefs2[prop][0]);
			}

			return (inconsistency / l);
		}

		static double frankTNorm(T, L)(T belief1, T belief2, L p)
		{
			T function(T value1, T value2, L p) func;

			if (p == 0) func = (x, y, p) => (x <= y) ? x : y;
			else if (p == 1) func = (x, y, p) => x * y;
			else
			{
				func = (x, y, p)
				{
					return log(1 + ( ((pow(exp(p), x) - 1) * (pow(exp(p), y) - 1) ) / (exp(p) - 1)) ) / p;
				};
			}

			return func(belief1, belief2, p);
		}

		static int[][][] conservative(
			in int[][][] opinions1, in double[] probability1,
			in int[][][] opinions2, in double[] probability2,
			out double[] probability)
		{
			int[][][] opinions;

			foreach (int i, ref v1; opinions1)
			{
				foreach (int j, ref v2; opinions2)
				{
					auto opinion = new int[][2];

					auto p1 = v1[0];
					auto n1 = v1[1];
					auto p2 = v2[0];
					auto n2 = v2[1];

					// P1 INTERSECTION P2
					foreach (ref prop1; p1)
					{
						foreach (ref prop2; p2)
						{
							if (prop1 == prop2)
							{
								opinion[0] ~= prop1;
								break;
							}
						}
					}

					// N1 INTERSECTION N2
					foreach (ref prop1; n1)
					{
						foreach (ref prop2; n2)
						{
							if (prop1 == prop2)
							{
								opinion[1] ~= prop1;
								break;
							}
						}
					}

					opinions ~= opinion;
					probability ~= probability1[i] * probability2[j];

				}
			}

			return opinions;
		}

		static int[][][] positive(
			in int[][][] opinions1, in double[] probability1,
			in int[][][] opinions2, in double[] probability2,
			out double[] probability)
		{
			int[][][] opinions;

			foreach (int i, ref v1; opinions1)
			{
				foreach (int j, ref v2; opinions2)
				{
					auto opinion = new int[][2];

					auto p1 = v1[0];
					auto n1 = v1[1];
					auto p2 = v2[0];
					auto n2 = v2[1];

					// P1 UNION P2
					opinion[0] ~= p1;
					foreach (ref prop2; p2)
					{
						bool append = false;

						foreach (ref prop1; p1)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion[0] ~= prop2;
					}

					// N1 INTERSECTION N2
					foreach (ref prop1; n1)
					{
						foreach (ref prop2; n2)
						{
							if (prop1 == prop2)
							{
								opinion[1] ~= prop1;
								break;
							}
						}
					}

					opinions ~= opinion;
					probability ~= probability1[i] * probability2[j];
				}
			}

			return opinions;
		}

		static int[][][] negative(
			in int[][][] opinions1, in double[] probability1,
			in int[][][] opinions2, in double[] probability2,
			out double[] probability)
		{
			int[][][] opinions;

			foreach (int i, ref v1; opinions1)
			{
				foreach (int j, ref v2; opinions2)
				{
					auto opinion = new int[][2];

					auto p1 = v1[0];
					auto n1 = v1[1];
					auto p2 = v2[0];
					auto n2 = v2[1];

					// P1 INTERSECTION P2
					foreach (ref prop1; p1)
					{
						foreach (ref prop2; p2)
						{
							if (prop1 == prop2)
							{
								opinion[0] ~= prop1;
								break;
							}
						}
					}

					// N1 UNION N2
					opinion[1] ~= n1;
					foreach (ref prop2; n2)
					{
						bool append = true;

						foreach (ref prop1; n1)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion[1] ~= prop2;
					}

					opinions ~= opinion;
					probability ~= probability1[i] * probability2[j];
				}
			}

			return opinions;
		}

		static int[][][] difference(
			in int[][][] opinions1, in double[] probability1,
			in int[][][] opinions2, in double[] probability2,
			out double[] probability)
		{
			int[][][] opinions;

			foreach (int i, ref v1; opinions1)
			{
				foreach (int j, ref v2; opinions2)
				{
					auto opinion = new int[][2];

					auto p1 = v1[0];
					auto n1 = v1[1];
					auto p2 = v2[0];
					auto n2 = v2[1];

					// P1 DIFFERENCE N2
					foreach (ref prop1; p1)
					{
						bool append = true;
						foreach (ref prop2; n2)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion[0] ~= prop1;
					}

					// N1 DIFFERENCE P2
					foreach (ref prop1; n1)
					{
						bool append = true;
						foreach (ref prop2; p2)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion[1] ~= prop1;
					}

					opinions ~= opinion;

					probability ~= probability1[i] * probability2[j];
				}
			}

			return opinions;
		}

		static int[][][] optimistic(
			in int[][][] opinions1, in double[] probability1,
			in int[][][] opinions2, in double[] probability2,
			out double[] probability)
		{
			int[][][] opinions;

			foreach (int i, ref v1; opinions1)
			{
				foreach (int j, ref v2; opinions2)
				{
					auto opinion = new int[][2];

					auto p1 = v1[0];
					auto n1 = v1[1];
					auto p2 = v2[0];
					auto n2 = v2[1];

					// P1 UNION P2
					opinion[0] ~= p1;
					foreach (ref prop2; p2)
					{
						bool append = true;

						foreach (ref prop1; p1)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion[0] ~= prop2;
					}

					// N1 UNION N2
					opinion[1] ~= n1;
					foreach (ref prop2; n2)
					{
						bool append = true;

						foreach (ref prop1; n1)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion[1] ~= prop2;
					}

					opinions ~= opinion;
					probability ~= probability1[i] * probability2[j];
				}
			}

			return opinions;
		}

		static int[][][] consensus(
			in int[][][] opinions1, in double[] probability1,
			in int[][][] opinions2, in double[] probability2,
			out double[] probabilities)
		{
			int[][][] opinions;

			foreach (i, ref v1; opinions1)
			{
				foreach (j, ref v2; opinions2)
				{
					auto opinion1 = new int[][2];

					// DIFFERENCE OPERATOR FOR EACH OPINION PAIR

					// P1 DIFFERENCE N2
					foreach (ref prop1; v1[0])
					{
						bool append = true;
						foreach (ref prop2; v2[1])
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion1[0] ~= prop1;
					}

					// N1 DIFFERENCE P2
					foreach (ref prop1; v1[1])
					{
						bool append = true;
						foreach (ref prop2; v2[0])
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion1[1] ~= prop1;
					}

					auto opinion2 = new int[][2];

					// P2 DIFFERENCE N1
					foreach (ref prop1; v2[0])
					{
						bool append = true;
						foreach (ref prop2; v1[1])
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion2[0] ~= prop1;
					}

					// N2 DIFFERENCE P1
					foreach (ref prop1; v2[1])
					{
						bool append = true;
						foreach (ref prop2; v1[0])
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion2[1] ~= prop1;
					}


					// CONSENSUS OPERATOR FOR EACH OPINION PAIR

					auto opinion3 = new int[][2];

					auto p1 = opinion1[0];
					auto n1 = opinion1[1];
					auto p2 = opinion2[0];
					auto n2 = opinion2[1];

					// P1 UNION P2
					opinion3[0] ~= p1;
					foreach (ref prop2; p2)
					{
						bool append = true;

						foreach (ref prop1; p1)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion3[0] ~= prop2;
					}

					// N1 UNION N2
					opinion3[1] ~= n1;
					foreach (ref prop2; n2)
					{
						bool append = true;

						foreach (ref prop1; n1)
						{
							if (prop1 == prop2)
							{
								append = false;
								break;
							}
						}

						if (append)
							opinion3[1] ~= prop2;
					}

					opinions ~= opinion3;
					probabilities ~= probability1[i] * probability2[j];
				}
			}

			return opinions;
		}

		static double[2][] beliefConsensus(
			double[2][] beliefs1,
			double[2][] beliefs2)
		{
			auto beliefs = new double[2][beliefs1.length];
			auto w1 = beliefs1;
			auto w2 = beliefs2;

			foreach (i, ref belief; beliefs)
			{
				belief = [
					(w1[i][0] * w2[i][1]) +
					(w1[i][1] * w2[i][0]) -
					(w1[i][0] * w2[i][0]),
					(w1[i][0] + w2[i][0]) +
					(w1[i][1] * w2[i][1]) -
					(w1[i][1] * w2[i][0]) -
					(w1[i][0] * w2[i][1])
				];
			}

			return beliefs;
		}
	}
}
