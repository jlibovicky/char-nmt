#!/bin/bash

set -ex

MARIAN_HOME=$HOME/marian

SRC=en
TGT=de
BATCH=9500
VALID_BATCH=64
SUFFIX=
SEED=1111
DEPTH=6
LEARNING_RATE=0.0003
DROP=

function usage {
    echo "Train MT system using Marian."
    echo "usage: ./train_baseline_marian.sh -s <lng1> -t <lng2> --bpe <bpe> ..."
    echo "   --depth        Number of the model layers, defalt: $DEPTH"
    echo "   --bpe          Size of BPE vocabulary: 32k|16k|8k|4k|2k|1k|950..0..50"
    echo "                  Prefix 'w' means word-piece-like tokeniation."
    echo "   --batch        Training batch size in number of words, default: $BATCH"
    echo "   --val-batch    Validation batch size in number of sentences, deafult: $VALID_BATCH"
    echo "   --seed         Random seed."
    echo "   --lr           Initial learning rate, default $LEARNING_RATE"
    echo "   --gpus         Comma-separated IDs of GPUs that will be used."
    echo "   --dropout      Turns on BPE-dropout on training data."
}


while [ "$1" != "" ]; do
    case $1 in
        -s | --src )   shift
                       SRC=$1
                       ;;
        -t | --tgt )   shift
					   TGT=$1
                       ;;
        -b | --bpe )   shift
					   BPE=$1
                       ;;
        -c | --char )  shift
					   CHARNGRAM=$1
                       ;;
        --words )      shift
					   WORDS=$1
                       ;;
        --batch ) shift
					   BATCH=$1
                       ;;
        --val-batch )  shift
					   VALID_BATCH=$1
                       ;;
        --suffix )     shift
					   SUFFIX=$1
                       ;;
        --seed )       shift
					   SEED=$1
                       ;;
        --depth )      shift
					   DEPTH=$1
                       ;;
        --lr )         shift
					   LEARNING_RATE=$1
                       ;;
        --gpus )       shift
					   GPUS=$1
                       ;;
        --dropout )    DROP=drop
                       ;;
        -h | --help )  usage
                       exit
                       ;;
        * )            usage
                       exit 1
    esac
    shift
done

if [ ! -v GPUS ]; then
    echo No GPUs were set. > /dev/stderr
    exit 1
fi
GPUS=$(echo $GPUS | sed -e 's/,/ /g')
GPU_COUNT=$(echo $GPUS | wc -w)
if [ $GPU_COUNT -gt 1 ]; then
    SUFFIX="${SUFFIX}_gpu$(echo $GPUS | wc -w)"
fi


if [[ ! $SRC =~ ^(en|cs|fr|de)$ ]]; then
    echo Unknown source language $SRC 2> /dev/stderr
    exit 1
fi
if [[ ! $TGT =~ ^(en|cs|fr|de)$ ]]; then
    echo Unknown target language $TGT 2> /dev/stderr
    exit 1
fi

if [[ $SRC != en && $TGT != en ]]; then
    echo One of the languages must be English. 2> /dev/stderr
    exit 1
fi

if [[ $SRC == $TGT ]]; then
    echo One of the languages must be English.
    exit 1
fi


if [[ $SRC == en ]]; then
    PAIR=en${TGT}
else
    PAIR=en${SRC}
fi

if [[ -v BPE && -v CHARNGRAM || -v BPE && -v WORDS || -v CHARNGRAM && -v WORDS ]]; then
    echo You cannot use BPE and character n-grams at the same time. 2> /dev/stderr
fi

if [[ -v BPE && ! $BPE =~ ^w{0,1}(32k|16k|8k|4k|2k|1k|900|800|700|600|500|250|125|63|0)$ ]]; then
    echo Available BPE sizes are 32/16/8/4/2/1k/900/800/700/600/500/250/125/63/0, was ${BPE} 2> /dev/stderr
    exit 1
fi

DATA_SUFFIX=
if [[ -v BPE ]]; then
    DATA_SUFFIX=bpe${BPE}
    PREFIX=valid_bpe
    if [[ $BPE =~ ^w.*$ ]]; then
        PREFIX=valid_wbpe
    fi
    VALID_SCRIPT=${PREFIX}_${SRC}${TGT}.sh
fi
if [[ -v WORDS ]]; then
    DATA_SUFFIX=words${WORDS}
    VALID_SCRIPT=valid_bpe_${SRC}${TGT}.sh
fi
if [[ -v CHARNGRAM ]]; then
    DATA_SUFFIX=char$CHARNGRAM
    VALID_SCRIPT=valid_ngram_${SRC}${TGT}.sh
fi


MODEL_DIR=models/${SRC}${TGT}_${DATA_SUFFIX}${DROP}${SUFFIX}
mkdir -p $MODEL_DIR
if [ -e $MODEL_DIR/model.npz.yml ]; then
    rm $MODEL_DIR/model.npz.yml
fi

VOCAB_FILE=$MODEL_DIR/vocab.$PAIR.yml
if [[ ! -e $VOCAB_FILE ]]; then
    python3 ./get_vocabulary.py data/${PAIR}/train/{$SRC,$TGT}.$DATA_SUFFIX --marian-yaml | sort -nk2 > $VOCAB_FILE
fi


$MARIAN_HOME/build/marian \
    --model $MODEL_DIR/model.npz --type transformer \
    --train-sets data/$PAIR/train/{$SRC,$TGT}.$DATA_SUFFIX$DROP \
    --max-length 400 \
    --vocabs $VOCAB_FILE $VOCAB_FILE \
    --mini-batch-fit -w $(($BATCH * 1)) --maxi-batch $((1000 * $GPU_COUNT)) \
    --early-stopping 5 \
    --valid-freq 5000 --save-freq 5000 --disp-freq 500 \
    --valid-metrics cross-entropy perplexity translation \
    --valid-sets data/$PAIR/val/{$SRC,$TGT}.$DATA_SUFFIX \
    --valid-script-path validation_scripts/$VALID_SCRIPT \
    --valid-translation-output $MODEL_DIR/valid.output --quiet-translation \
    --valid-mini-batch $VALID_BATCH \
    --beam-size 6 --normalize 0.6 \
    --log $MODEL_DIR/train.log --valid-log $MODEL_DIR/valid.log \
    --enc-depth $DEPTH --dec-depth $DEPTH \
    --transformer-heads 8 \
    --transformer-postprocess-emb d \
    --transformer-postprocess dan \
    --transformer-dropout 0.1 --label-smoothing 0.1 \
    --learn-rate $LEARNING_RATE --lr-warmup 16000 --lr-decay-inv-sqrt 16000 --lr-report \
    --optimizer-params 0.9 0.98 1e-09 --clip-norm 5 \
    --tied-embeddings-all \
    --devices $GPUS --sync-sgd --seed $SEED \
    --exponential-smoothing
