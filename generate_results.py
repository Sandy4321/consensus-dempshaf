import os
import sys

population = [
	#100,
	1000,
]

languages = [
	#1,
	#3,
	5,
	# 10,
	# 50,
	# 100,
]

evidence_rates = [
	#5,
	#15,
	30,
]

results_dir = 'test_results'

logic_type = sys.argv[1]
selection_type = sys.argv[2]
evidence_model = sys.argv[3]

random_selection = "false"
boolean = ""

if selection_type == "normal":
	random_selection = "false"
elif selection_type == "random":
	random_selection = "true"

if logic_type == "three-valued":
	boolean = ""
elif logic_type == "boolean":
	boolean = "-version=boolean "

evidence = ""

if "evidence-only" in evidence_model:
	evidence = "-version=evidence_only "
elif "evidence" in evidence_model:
	evidence = "-version=evidence "

set_seed = "true"
p_value = 0.66
thresh_start = 0.0
thresh_end = 1.0

# Plot the normal graphs for all of the above parameters

# Move to directory above

for agents in population:
	for lang in languages:
		for evidence_rate in evidence_rates:
			if evidence == "":
				evidence_rate = ""
			if evidence_rate != "" and lang != 5:
				continue;

			print('rdmd --compiler=ldmd2 -I../ {0}{9}world {1} {2} {3:.2f} {4:.2f} {5:.2f} {6} {7} {8}'.format(
				boolean,
				lang,
				agents,
				p_value,
				thresh_start,
				thresh_end,
				set_seed,
				random_selection,
				evidence_rate,
				evidence
			))

			os.system('rdmd --compiler=ldmd2 -I../ {0}{9}world {1} {2} {3:.2f} {4:.2f} {5:.2f} {6} {7} {8}'.format(
				boolean,
				lang,
				agents,
				p_value,
				thresh_start,
				thresh_end,
				set_seed,
				random_selection,
				evidence_rate,
				evidence
			))

			# If evidence_model is false, skip the innermost loop
			if evidence == "":
				break
