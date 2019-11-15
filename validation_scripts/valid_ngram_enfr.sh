#!/bin/bash

OUTPUT=$1

./ngram_decode.py $OUTPUT | sacrebleu data/enfr/val/fr --score-only --width 2
