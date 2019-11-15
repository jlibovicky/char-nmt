#!/bin/bash

OUTPUT=$1

sed 's/@@ //g' $1 | sacremoses detokenize -l de -x 2> /dev/null | sacrebleu data/ende/val/de --score-only --width 2
