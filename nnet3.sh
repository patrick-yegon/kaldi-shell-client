#!/bin/bash

#split all files into portions of 3 minutes, create a unique folder in kaldi-related and put all the split files in there

for i in *.mp3; \
  do file_split=`echo "${i%.*}"`; \
  echo $file_split; \
  ffmpeg -i "${i}" -f segment -segment_time 180 -c copy $file_split%03d.mp3; \
mkdir $HOME/kaldi-related/$file_split
rm "$file_split".mp3
mv "$file_split"*.mp3 $HOME/kaldi-related/$file_split
cd $HOME/kaldi-related/$file_split
mkdir audio/
mkdir text/

#convert all audio files to wav, mono, pcm, little endian, 8000

for i in *.mp3;
  do file_name=`echo "${i%.*}"`;{
  echo $file_name;
  ffmpeg -i "${i}" -acodec pcm_s16le -ac 1 -ar 8000 "${file_name}".wav;
rm "${file_name}".mp3

kaldi_main=$HOME/kaldi-master/src
kaldi_dir=$HOME/kaldi-master/egs/aspire/s5/exp/tdnn_7b_chain_online

$kaldi_main/online2bin/online2-wav-nnet3-latgen-faster \
--online=true \
--do-endpointing=false \
--frame-subsampling-factor=3 \
--config=$kaldi_dir/conf/online.conf \
--max-active=7000 \
--beam=15.0 \
--lattice-beam=6.0 \
--acoustic-scale=1.0 \
--word-symbol-table=$kaldi_dir/graph_pp/words.txt \
$kaldi_dir/final.mdl \
$kaldi_dir/graph_pp/HCLG.fst \
"ark:echo utterance-id1 utterance-id1|" \
"scp:echo utterance-id1 '$file_name'.wav|" \
"ark:|$kaldi_main/latbin/lattice-best-path \
--acoustic-scale=10.0 ark:- ark,t:- | \
$HOME/kaldi-master/egs/aspire/s5/utils/int2sym.pl -f 2- \
$kaldi_dir/graph_pp/words.txt \
>text/$file_name.txt"
mv "$file_name".wav audio/
}&
done
done
