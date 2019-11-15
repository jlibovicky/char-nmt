#!/bin/bash

OUTPUT=$1

sed -e 's/ //g;s/▁/ /g;s/^ //' $1 | sacrebleu data/encs/val/en --score-only --width 2
