#!/bin/bash

set -ex

MARIAN_HOME=$HOME/marian

while [ "$1" != "" ]; do
    case $1 in
        -m | --model )   shift
                       MODEL=$1
                       ;;
        -h | --help )  usage
                       exit
                       ;;
        * )            usage
                       exit 1
    esac
    shift
done

SRC=${MODEL:7:2}
TGT=${MODEL:9:2}

if [[ $SRC == en ]]; then
    DATA_DIR=en${TGT}
else
    DATA_DIR=en${SRC}
fi

if [[ ! $MODEL =~ 'bpew' ]]; then
    echo "This script only with wordpiece-like BPE model." > /dev/stderr
    exit 1
fi

if [[ ! -d $MODEL ]]; then
    echo "Model directory \"$MODEL\" does not exist." > /dev/stderr
    exit 1
fi

python3 average.py -m $(ls -t $MODEL/model.iter*.npz | head -n 5) -o $MODEL/model.avg.npz

for TOK in $(echo ${MODEL:12:1000} | sed -e 's/_/ /g'); do
    if [[ $TOK =~ ^bpew.*$ ]]; then
        INPUT_TYPE=$TOK
    fi
done
echo $INPUT_TYPE

TEST_FILE=data/${DATA_DIR}/test/${SRC}.${INPUT_TYPE}
$MARIAN_HOME/build/marian-decoder -c $MODEL/model.npz.decoder.yml -m $MODEL/model.avg.npz --beam-size 12 --normalize 0.4 < $TEST_FILE > $MODEL/test.output
sed -e 's/ //g;s/▁/ /g;s/^ //' $MODEL/test.output > $MODEL/test.txt
sacrebleu data/$DATA_DIR/test/$TGT --score-only --width 2 < $MODEL/test.txt > $MODEL/test_bleu

echo -n 'Test BLEU score: '
cat $MODEL/test_bleu

if [[ $SRC$TGT =~ en(de|cs|fr) ]]; then
    INPUT_TYPE=${INPUT_TYPE/bpew/wbpe}
    TEST_FILE=morpheval/segmented/${SRC}${TGT}/sents.${SRC}${TGT}.${INPUT_TYPE}
    $MARIAN_HOME/build/marian-decoder -c $MODEL/model.npz.decoder.yml -m $MODEL/model.avg.npz  --beam-size 12 --normalize 1.0 < $TEST_FILE > $MODEL/morpheval.output
    sed -e 's/ //g;s/▁/ /g;s/^ //' $MODEL/morpheval.output | sacremoses tokenize -l $TGT -x > $MODEL/morpheval.tok

    if [[ $TGT == "de" ]]; then
        cd morpheval/SMOR
        tr ' ' '\n' < ../../$MODEL/morpheval.tok | sort | uniq | ./smor > ../../$MODEL/morpheval.smored
        cd ../..
        python3 morpheval/morpheval_v2/evaluate_de.py -i $MODEL/morpheval.tok -n morpheval/morpheval.limsi.v2.en.info -d $MODEL/morpheval.smored | tee $MODEL/morpheval.analysis
    fi

    if [[ $TGT == "cs" ]]; then
        sed 's/$/\n/' $MODEL/morpheval.tok | tr ' ' '\n' | morpheval/morphodita-1.3.0-bin/bin-linux64/run_morpho_analyze --input=vertical --output=vertical  morpheval/czech-morfflex-pdt-131112/czech-morfflex-131112.dict 1  > $MODEL/morpheval.morphodita
        python3 morpheval/morpheval_v2/evaluate_cs.py -i $MODEL/morpheval.morphodita -n morpheval/morpheval.limsi.v2.en.info | tee $MODEL/morpheval.analysis
    fi

    if [[ $TGT == "fr" ]]; then
        python3 morpheval/morpheval_v2/evaluate_fr.py -i output.tokenized -n morpheval.limsi.v2.en.info -d morpheval/lefff.pkl
    fi

fi

echo -n 'Test BLEU score: '
cat $MODEL/test_bleu
