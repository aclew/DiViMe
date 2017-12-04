#!/usr/bin/env python
#
# author = julien karadayi
#
# Use this script to merge all the wavs in a subfolder
# and have 1 big wav. This script also keeps the timestamps
# corresponding to each of the initial wavs, in the big wavs.
# This script is particularly useful when you need to use the
# OpenSAT system and have a lot a wav file (big or small).
# Indeed, OpenSAT seems to take a lot of time accessing/writing
# for each file, so it takes a lot more time to use it on
# 1000 1s files, than on 1 1000s file.
#
# Input
#   1 folder containing multiple wav files.
#
# Output
#   1 wav file which is the concatenation of all the wav files
#   1 text file that contains the timestamps of all the wav files
#       in the newly created wav file.

import os
import argparse
import wave
import ipdb

def merge_all_wavs(folder, outfile):
    """ read all the wavs in a folder, merge them into
    1 big wav, and create a text file to keep track of
    where they are
    """
    assert os.path.isdir(folder), "ERROR: input folder is not a directory"

    # Loop over all the files in the folder,
    # open them with wave, store the signal in data
    # and merge them.
    data = []
    
    # keep timestamps for each wav files
    timestamps = []
    pos = 0
    for wav_name in os.listdir(folder):
        wav = os.path.join(folder, wav_name)
        if not wav.endswith('.wav'):
            # skip files that are not wav (obviously)
            continue
        w = wave.open(wav, 'rb')
        data.append([w.getparams(), w.readframes(w.getnframes())])
        
        # keep track of position of each wav in big final wav
        dur = w.getnframes() # number of frames
        frate = w.getframerate() # framerate
        timestamps.append((wav_name, pos, dur, frate ))

        pos += dur # position of first frame of next wav file
        w.close()

    # open output wave, write header (setparams, which writes
    # framerate, number of channels etc...), and write frames
    output_wave = wave.open(outfile, 'wb')
    output_wave.setparams(data[0][0])
    for k in range(len(data)):
        output_wave.writeframes(data[k][1])
    output_wave.close()

    # write timestamps of original wav files in new wav
    write_timestamps(timestamps, outfile)
    
    return

def write_timestamps(times, wav_name):
    """ write text file containing the name of the 
    small files, their position (in frame), their 
    duration (in number of frames) and their framerate 
    (to be sure that all wav have same framerate)
    """
    text_name = wav_name[:-4]+".txt"
    with open(text_name, 'w') as fout:
        for wav, pos, dur, frate in times:
            fout.write(u'{} {} {} {}\n'.format(wav, pos, dur, frate))
    return

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('input_folder', metavar='INPUT_FOLDER',
            help='''Folder containing all the wav files you want to merge''')
    parser.add_argument('output_wav', metavar='OUTPUT_WAV',
            help='''Name of the output folder containing the wav''')
    args = parser.parse_args()

    """
    # use this loop if you have 
    #   folder/
    #       subfolder1/*.wav
    #       subfolder2/*.wav
    #       etc...
    #
    # , and you want to create 1 wav per subfolder.
    """

    #if not os.path.isdir(args.output_wav):
    #    os.makedirs(args.output_wav)
    #for subf in os.listdir(args.input_folder):
    #    outfile = os.path.join(args.output_wav, subf + ".wav")
    #    merge_all_wavs(os.path.join(args.input_folder, subf), outfile)

    merge_all_wavs(args.input_folder, args.output_wav)
