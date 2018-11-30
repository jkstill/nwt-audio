#!/bin/bash

function usage {
cat <<-EOF

usage: $0

-o overwrite - default is to not overwrite
-b bible book list - default is bb-list.txt
-l list available files only and exit

EOF
}

OVERWRITE=1
LISTONLY=0
bookList='bb-list.txt'
AUDIO_DIR='nwt-audio'

while getopts b:olh arg
do
	case $arg in
		o) OVERWRITE=0;;
		l) LISTONLY=1;;
		b) bookList=$OPTARG;;
		h) usage;exit 0;;
		*) usage;exit 5;;
	esac
done

: <<'JKS-DOC'
cat <<EOF
OVERWRITE: $OVERWRITE
LISTONLY: $LISTONLY
bookList: $bookList
EOF

exit
JKS-DOC


# run from the current directory
BASEDIR=$(pwd)

mainURL='https://apps.jw.org/GETPUBMEDIALINKS?booknum=0&output=html&pub=nwt&fileformat=MP3%2CAAC&alllangs=0&langwritten=E&txtCMSLang=E'

listURL=$(lynx -dump -listonly $mainURL | grep http | awk '{ print $2 }')


[ -f "$bookList" -a -r "$bookList" ] || {
	echo
	echo $bookList is missing or unreadable
	exit 4
}


mkdir -p zips || {
	echo Cannot create zips dir
	exit 1
}

cd zips

#: <<'JKS-DOC'

lynx -dump -listonly $listURL | grep mp3 | while read enumerator mp3url
do
	echo getting $mp3url
	filename=$(basename $mp3url)
	if [[ $LISTONLY -lt 1 ]]; then
		if [[ $OVERWRITE -lt 1 ]]; then
	 		wget --no-check-certificate -O $filename $mp3url
		else # do not overwrite existing file
			echo filename: $filename
			if [[ -f $filename ]]; then
				echo skipping $filename - already stored
			else
				wget --no-check-certificate $mp3url
			fi
		fi
	fi
done

[[ $LISTONLY -gt 0 ]] && exit

#JKS-DOC

cd $BASEDIR

## bb: bible books
# the format of the file names allows parsing by the ordinal position of
# the book in the 66 books.
# it is unknown if the first 9 books will be '_N_' or '_NN_' so both are allowed for
# ie. '_1_' or '_01_'

declare -A bb
declare -a bookArray

while read -a bookArray
do
	bbNum=${bookArray[0]}
	book=$(echo ${bookArray[@]} | sed -re 's/\s+/-/g')
	bb[$bbNum]=$book
	echo book: "$bbNum: $book"
done < $bookList

mkdir -p $AUDIO_DIR
RC=$?

if [[ $RC -gt 0 ]]; then
	echo Something is wrong
	exit 2
fi

cd $AUDIO_DIR

for zipfile in $BASEDIR/zips/*.zip
do
	# get the numeric position of the book in the list
	bookPos=$(echo $zipfile | cut -f2 -d_)
	#echo bookPos-1: $bookPos

	# should the number of the book not include a leading zero for 1-9 then add it
	# this will cause the books to appear sorted in the same order as in the Bible
	echo $bookPos | grep -E '^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$' > /dev/null
	RC=$?
	#echo RC: $RC
	[[ $RC -eq 0 ]] && bookPos="0${bookPos}"

	book=${bb[$bookPos]}
	#echo bookPos-2: $bookPos
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



