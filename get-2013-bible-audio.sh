#!/bin/bash


# run from the current directory
BASEDIR=$(pwd)

mainURL='https://www.jw.org/download/?booknum=0&output=html&pub=nwt&fileformat=MP3%2CAAC&alllangs=0&langwritten=E&txtCMSLang=E&isBible=1'

listURL=$(lynx -dump -listonly $mainURL | grep http | awk '{ print $2 }')


mkdir -p zips || {
	echo Cannot create zips dir
	exit 1
}

cd zips

#: <<'JKS-DOC'

lynx -dump -listonly $listURL | grep mp3 | while read enumerator mp3url
do
	echo getting $mp3url
	wget --no-check-certificate $mp3url
done

#JKS-DOC

cd $BASEDIR

## bb: bible books
declare -A bb
bb=( [Ezr]='15-Ezra' \
	[Ne]='16-Nehemiah' \
	[Es]='17-Esther' \
	[Job]='18-Job' \
	[Mt]='40-Matthew' \
	[Mr]='41-Mark' \
	[Lu]='42-Luke' \
	[Ga]='48-Galatians' \
	[Php]='50-Philippians' \
	[1Th]='52-1-Thessalonians' \
	[2Th]='53-2-Thessalonians' \
	[Phm]='57-Philemon' \
) 

mkdir -p bb-audio
RC=$?

if [[ $RC -gt 0 ]]; then
	echo Something is wrong
	exit 2
fi

cd nwt-audio

for zipfile in $BASEDIR/zips/*.zip
do
	abbrev=$(echo $zipfile | cut -f3 -d_)
	book=${bb[$abbrev]}
	echo working on $book
	mkdir -p $book
	RC=$?

	if [[ $RC -gt 0 ]]; then
		echo Error creating dir for $book
		exit 3
	fi
	cd $book
	unzip -o $zipfile
	cd ..
done

zip -r ../nwt-mp3-audio.zip *

cd $BASEDIR



