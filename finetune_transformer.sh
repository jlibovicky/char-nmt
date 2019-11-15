#!/bin/bash

set -ex

SRC=en
TGT=de
PAIR=$SRC$TGT
VALID_SCRIPT=valid_bpe_${SRC}${TGT}.sh
VALID_BATCH=24
BATCH_PER_STEP=20000
MARIAN_HOME=$HOME/marian
BATCH=9500
LEARNING_RATE=1e-5


while [ "$1" != "" ]; do
    case $1 in
        -s | --src )   shift
                       SRC=$1
                       ;;
        -t | --tgt )   shift
					   TGT=$1
                       ;;
        --orig-model ) shift
                       ORIG_MODEL=$1
                       ;;
        --batches-per-step )  shift
                       BATCH_PER_STEP=$1
                       ;;
        --learning-rate )  shift
                       LEARNING_RATE=$1
                       ;;
        -b | --bpe )   shift
					   BPE=$1
                       ;;
        --gpus )       shift
					   GPUS=$1
                       ;;
        * )            usage
                       exit 1
    esac
    shift
done

# CHECK IF GPUS ARE SET AND FORMAT GPUS
if [ ! -v GPUS ]; then
    echo No GPUs were set. > /dev/stderr
    exit 1
fi
GPUS=$(echo $GPUS | sed -e 's/,/ /g')
GPU_COUNT=$(echo $GPUS | wc -w)
if [ $GPU_COUNT -gt 1 ]; then
    SUFFIX="${SUFFIX}_gpu$(echo $GPUS | wc -w)"
fi

# CHECK IF ORIGINAL MODEL EXISTS
if [ ! -d $ORIG_MODEL ]; then
    echo Original model \"$ORIG_MODEL\" does not exist. > /dev/stderr
    exit 1
fi

if [[ $SRC == en ]]; then
    PAIR=en${TGT}
else
    PAIR=en${SRC}
fi


ORIG_VOCAB_FILE=$ORIG_MODEL/vocab.$PAIR.yml
if [ ! -e $VOCAB_FILE ]; then
    echo Vocabulary of original model \"$VOCAB_FILE\" was not found. > /dev/stderr
    exit 1
fi

DATA_SUFFIX=bpe${BPE}
VALID_PREFIX=valid_bpe

# WHEN USING WORD-PIECE LIKE TOKENIZATION, USE MATCHING VALIDATION SCRIPT
if [[ $BPE =~ ^w.*$ ]]; then
    VALID_PREFIX=valid_wbpe
fi
VALID_SCRIPT=${VALID_PREFIX}_${SRC}${TGT}.sh

# CREATE NEW MODEL DIRECTORY AND COPY THE INITIAL MODEL AND VOCABULARY
MODEL_DIR=${ORIG_MODEL}_${DATA_SUFFIX}
mkdir -p $MODEL_DIR
cp $ORIG_VOCAB_FILE $MODEL_DIR
VOCAB_FILE=$MODEL_DIR/vocab.$PAIR.yml

cp $ORIG_MODEL/model.npz $MODEL_DIR

# RE-TRAIN THE MODEL
$MARIAN_HOME/build/marian \
    --model $MODEL_DIR/model.npz \
    --train-sets data/$PAIR/train/{$SRC,$TGT}.$DATA_SUFFIX \
    --max-length 400 \
    --early-stopping 5 \
    --vocabs $VOCAB_FILE $VOCAB_FILE \
    --mini-batch-fit -w $BATCH --maxi-batch $((1000 * $GPU_COUNT)) \
    --after-batches $BATCH_PER_STEP \
    --valid-freq 5000 --save-freq 5000 --disp-freq 500 \
    --valid-metrics cross-entropy perplexity translation \
    --valid-sets data/$PAIR/val/{$SRC,$TGT}.$DATA_SUFFIX \
    --valid-script-path validation_scripts/$VALID_SCRIPT \
    --valid-translation-output $MODEL_DIR/valid.output --quiet-translation \
    --valid-mini-batch $VALID_BATCH \
    --beam-size 6 --normalize 0.6 \
    --log $MODEL_DIR/train.log --valid-log $MODEL_DIR/valid.log \
    --optimizer adam --learn-rate $LEARNING_RATE --clip-norm 5 \
    --devices $GPUS --sync-sgd --seed 12674 \
    --exponential-smoothing
