#!/bin/bash

OUTPUT=$1

./ngram_decode.py $OUTPUT | sacrebleu data/ende/val/en --score-only --width 2
