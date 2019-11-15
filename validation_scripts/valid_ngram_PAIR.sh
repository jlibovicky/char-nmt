#!/bin/bash

OUTPUT=$1

./ngram_decode.py $OUTPUT | sacrebleu -t wmt17 -l SRC-TGT --score-only --width 2
