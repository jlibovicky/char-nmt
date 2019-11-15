#!/bin/bash

# #############################################################################
# This script downloads and prepares training data for
# English-{Czech,French,German} translation. It uses wmt14 data for German and
# French, so the results can be compared with Vaswani et al. (2017) and wmt18
# for Czech, so for comparison with Popel et al. (2018).
#
# Requirements:
#  * sacremoses
#  * fastBPE
# #############################################################################

# =============================================================================
# Training Data
# - en-de, en-fr WMT14 data
# - en-cs WMT17 data
# =============================================================================
#mkdir tmp_data
#cd tmp_data
#
#mkdir ende enfr encs

# wget http://data.statmt.org/wmt18/translation-task/training-parallel-nc-v13.tgz
# 
# tar -zxvf training-parallel-nc-v13.tgz training-parallel-nc-v13/news-commentary-v13.de-en.en
# tar -zxvf training-parallel-nc-v13.tgz training-parallel-nc-v13/news-commentary-v13.de-en.de
# tar -zxvf training-parallel-nc-v13.tgz training-parallel-nc-v13/news-commentary-v13.cs-en.en
# tar -zxvf training-parallel-nc-v13.tgz training-parallel-nc-v13/news-commentary-v13.cs-en.cs
# rm training-parallel-nc-v13.tgz
# 
# mv training-parallel-nc-v13/news-commentary-v13.de-en.{en,de} ende/
# mv training-parallel-nc-v13/news-commentary-v13.cs-en.{en,cs} encs/
# 
# rmdir training-parallel-nc-v13
# 
# # -----------------------------------------------------------------------------
# 
# wget http://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz
# 
# tar -zxvf training-parallel-commoncrawl.tgz commoncrawl.de-en.en
# tar -zxvf training-parallel-commoncrawl.tgz commoncrawl.de-en.de
# tar -zxvf training-parallel-commoncrawl.tgz commoncrawl.fr-en.en
# tar -zxvf training-parallel-commoncrawl.tgz commoncrawl.fr-en.fr
# tar -zxvf training-parallel-commoncrawl.tgz commoncrawl.cs-en.en
# tar -zxvf training-parallel-commoncrawl.tgz commoncrawl.cs-en.cs
# rm training-parallel-commoncrawl.tgz
# 
# mv commoncrawl.de-en.{en,de} ende/
# mv commoncrawl.fr-en.{en,fr} enfr/
# mv commoncrawl.cs-en.{en,cs} encs/

# -----------------------------------------------------------------------------

# wget http://www.statmt.org/wmt13/training-parallel-europarl-v7.tgz
# 
# tar -zxvf training-parallel-europarl-v7.tgz training/europarl-v7.de-en.en
# tar -zxvf training-parallel-europarl-v7.tgz training/europarl-v7.de-en.de
# tar -zxvf training-parallel-europarl-v7.tgz training/europarl-v7.cs-en.en
# tar -zxvf training-parallel-europarl-v7.tgz training/europarl-v7.cs-en.cs
# tar -zxvf training-parallel-europarl-v7.tgz training/europarl-v7.fr-en.en
# tar -zxvf training-parallel-europarl-v7.tgz training/europarl-v7.fr-en.fr
# rm training-parallel-europarl-v7.tgz
# 
# mv training/europarl-v7.de-en.{en,de} ende/
# mv training/europarl-v7.cs-en.{en,cs} encs/
# mv training/europarl-v7.fr-en.{en,fr} enfr/
# rmdir training

# -----------------------------------------------------------------------------

#wget http://www.statmt.org/wmt14/training-parallel-nc-v9.tgz
#tar -zxvf training-parallel-nc-v9.tgz training/news-commentary-v9.fr-en.en
#tar -zxvf training-parallel-nc-v9.tgz training/news-commentary-v9.fr-en.fr
#rm training-parallel-nc-v9.tgz

#sed -i 's/\r//g' training/*
#mv training/news-commentary-v9.fr-en.{en,fr} enfr/
#rmdir training

# -----------------------------------------------------------------------------

#wget http://www.statmt.org/wmt10/training-giga-fren.tar
#tar -xvf training-giga-fren.tar giga-fren.release2.fixed.en.gz
#tar -xvf training-giga-fren.tar giga-fren.release2.fixed.fr.gz
#rm training-giga-fren.tar
#gunzip giga-fren.release2.fixed.en.gz
#gunzip giga-fren.release2.fixed.fr.gz

#mv giga-fren.release2.fixed.{en,fr} enfr/

# -----------------------------------------------------------------------------

#wget http://www.statmt.org/wmt13/training-parallel-un.tgz
#tar -zxvf training-parallel-un.tgz un/undoc.2000.fr-en.en
#tar -zxvf training-parallel-un.tgz un/undoc.2000.fr-en.fr
#rm training-parallel-un.tgz

#mv un/endoc.2000.fr-en.{en,fr} enfr/
#rmdir un

# -----------------------------------------------------------------------------

#wget https://lindat.mff.cuni.cz/repository/xmlui/bitstream/handle/11234/1-1458/data-plaintext-format.tar
#tar xvf data-plaintext-format.tar
#zcat data.plaintext-format/*train.gz > czeng.tsv
#cut -f 3 czeng.tsv > encs/czeng.cs
#cut -f 4 czeng.tsv > encs/czeng.en
#chmod -R +w data.plaintext-format
#rm -rf data.plaintext-format

# -----------------------------------------------------------------------------

# COLLECT AND TOKENIZE EVERYTHING

# for TGT in de cs fr; do
#     FINAL_DIR=en${TGT}_final
#     mkdir $FINAL_DIR
#     cd en$TGT
#     dos2unix *
#     paste <(cat *.en) <(cat *.$TGT) | shuf > all.en$TGT
#     cut -f1 all.en$TGT > ../$FINAL_DIR/en
#     cut -f2 all.en$TGT > ../$FINAL_DIR/$TGT
# 
#     cd ../$FINAL_DIR
#     sacremoses tokenize -l en < en > en.tok
#     sacremoses tokenize -l $TGT < $TGT > $TGT.tok
#     cd ..
# done
#
#cd ..
#mkdir -p data/en{de,cs,fr}/{train,val,test}
#
#
#for TGT in de cs fr; do
#    mv tmp_data/en${TGT}_final data/en${TGT}/train
#done
#
#rm -r tmp_data

# PREPARE BPE AND CHARACTER VOCABULARY
#for TGT in de cs fr; do
#    ~/local/fastBPE/bin/fast learnbpe 32000 data/en${TGT}/train/{en,$TGT}.tok > data/en${TGT}/bpe32k
#    ./character_vocabulary.py data/en${TGT}/train/{en,$TGT}.tok --min-count 5 > data/en${TGT}/characters
#done

#for COUNT in 16 8 4 2 1; do
#    for BPE_FILE in data/*/bpe32k; do
#        head -n ${COUNT}000 $BPE_FILE > ${BPE_FILE:0:-3}${COUNT}k
#    done
#done

# =============================================================================
# Validation and test data
# =============================================================================

#sacrebleu -t wmt13 -l en-fr --echo src > data/enfr/val/en
#sacrebleu -t wmt13 -l en-fr --echo ref > data/enfr/val/fr
#sacrebleu -t wmt14 -l en-fr --echo src > data/enfr/test/en
#sacrebleu -t wmt14 -l en-fr --echo ref > data/enfr/test/fr
#
#sacrebleu -t wmt13 -l en-de --echo src > data/ende/val/en
#sacrebleu -t wmt13 -l en-de --echo ref > data/ende/val/de
#sacrebleu -t wmt14 -l en-de --echo src > data/ende/test/en
#sacrebleu -t wmt14 -l en-de --echo ref > data/ende/test/de
#
#sacrebleu -t wmt17 -l en-cs --echo src > data/encs/val/en
#sacrebleu -t wmt17 -l en-cs --echo ref > data/encs/val/cs
#sacrebleu -t wmt18 -l en-cs --echo src > data/encs/test/en
#sacrebleu -t wmt18 -l en-cs --echo ref > data/encs/test/cs
#
## Tokenize validation and test data
#for TGT in cs de fr; do
#    for SET in val test; do
#        SET_DIR=data/en${TGT}/${SET}
#
#        sacremoses tokenize -j 16 -l $TGT < $SET_DIR/$TGT > $SET_DIR/$TGT.tok
#        sacremoses tokenize -j 16 -l en   < $SET_DIR/en   > $SET_DIR/en.tok
#    done
#done 
# =============================================================================
# Apply BPE on everything
# =============================================================================

#for TGT in cs de fr; do
#    for SET in train val test; do
#        SET_DIR=data/en${TGT}/${SET}
#
#        for BPE_SIZE in 32 16 8 4 2 1; do
#            ~/local/fastBPE/bin/fast applybpe $SET_DIR/en.bpe${BPE_SIZE}k     $SET_DIR/en.tok     data/en${TGT}/bpe${BPE_SIZE}k
#            ~/local/fastBPE/bin/fast applybpe $SET_DIR/${TGT}.bpe${BPE_SIZE}k $SET_DIR/${TGT}.tok data/en${TGT}/bpe${BPE_SIZE}k
#        done
#
#    done
#done


#for F in data/*/{train,test,val,val_full}/??; do
#    echo $F
#    ./wordpiece_tokenize.py $F > $F.wtok
#done
#
#for PAIR in ende enfr encs; do
#    ~/local/fastBPE/bin/fast learnbpe 32000 data/$PAIR/train/??.wtok > data/$PAIR/wbpe32k;
#done
#
#for PAIR in ende enfr encs; do
#    for KSIZE in 16 8 4 2 1; do
#        head -n ${KSIZE}000 data/$PAIR/wbpe32k > data/$PAIR/wbpe${KSIZE}k
#    done
#
#    for SIZE in {950..0..50}; do
#        head -n ${KSIZE} data/$PAIR/wbpe1k > data/$PAIR/wbpe${SIZE}
#    done
#done

#for PAIR in ende enfr encs; do
#    for SIZE in 32k 16k 8k 4k 2k 1k {950..0..50}; do
#        CODES=data/$PAIR/wbpe${SIZE}
#        for FILE in data/$PAIR/*/*.wtok; do
#            echo $FILE
#            OUTFILE=${FILE:0:-5}.bpew${SIZE}
#            ~/local/fastBPE/bin/fast applybpe $OUTFILE $FILE $CODES
#            sed -i 's/@@ / /g' $OUTFILE
#        done
#    done
#done

# Create merge files also for subword-nmt
#for F in data/en??/?bpe*; do echo $F; cut -d' ' -f1,2 $F > $F.nonu; don

# Do the training data also with BPE dropout
for PAIR in ende enfr encs; do
    for SIZE in 32k 16k 8k 4k 2k 1k {950..0..50}; do
        CODES=data/$PAIR/wbpe${SIZE}.nonu
        for FILE in data/$PAIR/train/*.wtok; do
            echo $FILE
            OUTFILE=${FILE:0:-5}.bpew${SIZE}drop
            subword-nmt/apply_bpe.py -c $CODES --dropout 0.1 -i $FILE | sed 's/@@ / /g' > $OUTFILE
        done
    done
done
