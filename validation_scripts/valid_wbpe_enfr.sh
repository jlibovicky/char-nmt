#!/bin/bash

OUTPUT=$1

sed -e 's/ //g;s/▁/ /g;s/^ //' $1 | sacrebleu data/enfr/val/fr --score-only --width 2
