#!/bin/bash

OUTPUT=$1

./ngram_decode.py $OUTPUT | sacrebleu data/ende/val/de --score-only --width 2
