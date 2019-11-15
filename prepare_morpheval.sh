#!/bin/bash

mkdir morpheval
cd morpheval

wget https://morpheval.limsi.fr/morpheval.limsi.v2.en.info
wget https://morpheval.limsi.fr/morpheval.limsi.v2.en.sents
wget https://github.com/ufal/morphodita/releases/download/v1.3.0/morphodita-1.3.0-bin.zip
unzip morphodita-1.3.0-bin.zip

wget https://www.cis.uni-muenchen.de/~schmid/tools/SMOR/data/SMOR-linux.tar.gz
tar zxvf SMOR-linux.tar.gz

wget https://morpheval.limsi.fr/lefff.pkl

../wordpiece_tokenize.py morpheval.limsi.v2.en.sents > morpheval.limsi.v2.en.sents.wtok

for PAIR in ende encs enfr; do
    for BPE in ../data/$PAIR/wbpe*; do
        echo $BPE
        ~/local/fastBPE/bin/fast applybpe_stream $BPE < morpheval.limsi.v2.en.sents.wtok | sed -e 's/@@ / /g' > segmented/$PAIR/sents.$PAIR.${BPE:13:1000}
    done
done

git clone https://github.com/franckbrl/morpheval_v2

curl --remote-name-all https://lindat.mff.cuni.cz/repository/xmlui/bitstream/handle/11234/1-1836{/czech-morfflex-pdt-161115.zip}
unzip czech-morfflex-pdt-161115.zip
