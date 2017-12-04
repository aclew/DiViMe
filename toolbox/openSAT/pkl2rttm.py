"""
script designed to convert pkl output from OpenSAT
into rttm format

inputs:

path to .pkl
path to directory where to save .rttm
OpenSAT labels to be accounted for speech for SAD (18 classes)

returns:

saves .rttm file

"""

import numpy as np
import argparse
import pickle
import gzip
import os


def convert(path_to_pkl, speech_labels, path_to_write):
	"""
	operates on a single pkl output file
	saves result in rttm format 

	"""

	with open(path_to_pkl, 'rb') as f:
		data = pickle.load(f)

	result = data.values()[0]
	most_likely = result.argmax(axis=1)

	length_sample = len(most_likely)
	time_frame = np.arange(0, length_sample) * 0.1

	directory = os.path.dirname(path_to_pkl)
	name = os.path.split(directory)[1]

	with open(os.path.join(path_to_write, name + ".rttm"), "w") as rttm:

		t_start = time_frame[0]

		for t in range(length_sample):

			if most_likely[t] != most_likely[t-1]:

				if most_likely[t-1] in speech_labels:

					time_elapse = time_frame[t] - t_start

					rttm.write(u"SPEAKER\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format
						(name, 1, t_start, time_elapse, "<NA>", "<NA>", "<NA>", "<NA>" ))

					t_start = time_frame[t]


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description="convert a pkl into rttm")
	parser.add_argument('-i', '--input', type=str, required=True)
	parser.add_argument('-o', '--output', type=str, required=True)
	parser.add_argument('-l', '--labels', nargs='+', required=True)
	args = parser.parse_args()

	speech_labels = [int(x) for x in args.labels]

	convert(args.input, speech_labels, args.output)