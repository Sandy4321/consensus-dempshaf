import numpy as np
import matplotlib.pyplot as plt

file_name = "noise_results.csv"

results = []

variance = 0.0
qualities = []

try:
    with open(file_name) as file:
        variance = float(file.readline().strip())
        qualities = list(map(float, file.readline().strip().split(',')))
        for line in file:
            results.append(list(map(float, line.strip().split(','))))
except IOError:
    print('Noise results file not found.')

choices = len(results)

x_values = np.array([x/100 for x in range(101)])
print(x_values)
results = np.sort(np.array(results))
print(results)

bin_values = []

for values in results:
    bin_values.append(list(np.digitize(values, x_values)))

bin_values = bin_values
print(np.array(bin_values))

y_values = [[0 for x in range(len(x_values))] for y in range(choices)]

for i in range(0, choices):
    for j, value in enumerate(x_values):
        y_values[i][j] = bin_values[i].count(j)

print(y_values)

for choice in range(choices):
    plt.plot(x_values, y_values[choice])

plt.legend(qualities)

plt.savefig("../results/graphs/dempshaf/{0}_{1:.4f}.pdf".format('_'.join(map(str, qualities)), variance))

plt.clf()