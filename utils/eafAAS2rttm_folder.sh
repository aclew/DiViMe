#!/bin/bash
#
# Shell script to convert all .eaf files following the ACLEW Annotation Scheme inside a folder to .rttm format
# 
for j in ${1}/*.eaf
    do elan2rttm.py $j #generate the basic rttms
done
