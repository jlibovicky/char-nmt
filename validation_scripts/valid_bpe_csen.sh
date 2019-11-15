#!/bin/bash

OUTPUT=$1

sed 's/@@ //g' $1 | sacremoses detokenize -l en -x 2> /dev/null | sacrebleu data/encs/val/en --score-only --width 2
