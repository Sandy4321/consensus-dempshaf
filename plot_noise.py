import ggplot

file_name = "noise_results.csv"

results = []

try:
    with open(file_name) as file:
        for line in file:
            results.append(line.split(','))
except IOError:
    print('Noise results file not found.')

