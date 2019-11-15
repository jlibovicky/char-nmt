#!/bin/bash

OUTPUT=$1

./ngram_decode.py $OUTPUT | sacrebleu data/encs/val/cs --score-only --width 2
