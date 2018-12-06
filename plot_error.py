import numpy as np
import matplotlib.pyplot as plt
plt.style.use('seaborn-darkgrid')
import matplotlib.cm as cm

cmap = cm.get_cmap('bone_r') #'Greys_r'

file_name = "error_results.csv"

results = []

lambdas = []

try:
    with open(file_name) as file:
        lambdas = list(map(float, file.readline().strip().split(',')))
        for line in file:
            results.append(list(map(float, line.strip().split(','))))
except IOError:
    print('Noise results file not found.')

x_values = np.array([x/(len(results[0]) - 1) for x in range(len(results[0]))])
print(x_values)

y_values = np.array(results)
print(y_values)

c = [cmap(x/len(lambdas)) for x in range(len(lambdas))]

for l, value in enumerate(lambdas):
    plt.plot(x_values, y_values[l], color=c[l])

plt.legend(lambdas)

plt.savefig("../results/graphs/dempshaf/error_functions.pdf")

plt.clf()