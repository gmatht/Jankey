#!/bin/sh
#LT=development/keystest

set -e
set -x

LT=`dirname $0`
. $LT/shared_variables.sh
. ./$0.format


if [ -z "$KEYCODE_DIR" ]
then
	KEYCODE_DIR=$ROOT_OUTDIR
fi
#convert -normalize -scale $GEOM -quality $QUALITY $f $GEOM/$f

UNIQUE_LINE=1

mkdir -p $OUT
rm $OUT/index*.html || true

list_keycode_files () {
#echo for f in  $OUT_NAME/*y/last_crash_sec $OUT_NAME/toreplay/replayed/*y/last_crash_sec
for f in  $OUT_NAME/*y/last_crash_sec $OUT_NAME/toreplay/replayed/*y/last_crash_sec $OUT_NAME/toreproduce/replayed/*y/last_crash_sec  $OUT_NAME/toreplay/*y/last_crash_sec $OUT_NAME/toreplay/final/*y/last_crash_sec
#for f in  $OUT_NAME/*y/*y/last_crash_sec $OUT_NAME/toreplay/replayed/*y/*y/last_crash_sec  $OUT_NAME/toreplay/*y/*y/last_crash_sec $OUT_NAME/toreplay/final/*y/last_crash_sec
do
        keycode_file=$(echo $f | sed s/last_crash_sec/$(cat $f).KEYCODEpure/)
	if test -e $keycode_file.replay/last_crash_sec
	then
		f=$keycode_file.replay/last_crash_sec
        	keycode_file=$(echo $f | sed s/last_crash_sec/$(cat $f).KEYCODEpure/)
	fi
        if [ -e `echo $keycode_file | sed s/KEYCODEpure/GDB/` ] # hack to stop other bug causing crash
	then
	true #        echo $keycode_file
	fi
done
}

list_keycode_files () {
for f in  $OUT_NAME/final/*.KEYCODEpure
do
	#echo $f
        if [ -e `echo $f | sed s/KEYCODEpure/GDB/` ] # hack to stop other bug causing crash
	then
	        echo $f
	fi
done
}

make_cpp_html() {
#This is ugly. At the moment all bug reports in the same set reference the same files, which could lead to confusion if they are from differnt versions of LyX. Do not mix different versions until this is fixed. However we may not want to "fix" this when it may be better to always use a new outdir for each version and just reproduce the old bugs so they don't get lost.
if ! test -e $ROOT_OUTDIR/html/cpp_html
then 
	(mkdir -p $ROOT_OUTDIR/html/cpp_html/ &&
	cd $ROOT_OUTDIR/html/cpp_html/ &&
	for f in `find ../../../src/ -iname '*.cpp' ; find ../../../src/ -iname '*.h'` ; do  g=`basename $f`; c2html -n < $f > $g.html ; echo $f  ; done)
fi
}




echo beginning
make_cpp_html
#for file in `find $LT/$OUT_NAME/ -anewer $LT/$OUT_NAME/html | grep replay/last_crash_sec`
#for file in `find $KEYCODE_DIR | grep save/.*KEYCODEpure`
#for file in `find $KEYCODE_DIR -anewer oldfile | grep save/.*KEYCODEpure$ | head -n4`
#for file in `ls $KEYCODE_DIR/*/final/*KEYCODEpure`
#for file in `ls $KEYCODE_DIR/*/final/*/*KEYCODEpure`
list_keycode_files
echo END OF KEYCODE FILES
mkdir -p $OUT/indexreport.d
for file in `list_keycode_files`
do
 echo FILE $file
 SEC=`basename $file | sed s/[.].*$//g`
 echo SEC .$SEC. .$SEC2.
 #if [ ! $SEC -eq $SEC2 ]
 #then
	#break
 #fi
 echo SEC $SEC
 #f_base=`echo $file | sed s/last_crash_sec/$SEC/g`
 f_base=`dirname $file`'/'$SEC
 echo f_base $f_base
 NUM_KEYCODES=`wc -l < "$f_base.KEYCODEpure"`
 echo NUM_KEYCODES=$NUM_KEYCODES...
 if [ "$NUM_KEYCODES" -lt 50 ]  
 then
  INDEX_FILE=$OUT/indexreport.d/$SEC.html
  if [ \( ! -e $OUT/$SEC.html \) -o \( "$0".format -nt $OUT/$SEC.html \) -o \( out/cache-bisect/store/$SEC.KEYCODEpure -nt $OUT/$SEC.html \) ]
  then
	make_one_bug
  fi
  cat $INDEX_FILE >> $OUT/indexreport.html
 fi
done
echo will build index.html
(echo "<html>" 
echo "<title>Keytest_Report</title>"
echo "<a href=\"$URL_OF_OUT\"><h1>List of bugs found</h1></a>"
echo '<p>Please, do not "report" bugs without searching for them first. Also make sure to fill out the "To reproduce" section before pressing the "Create ticket" button</p>' 
#FIXME: Sort messes up multiline entries.
#sort -k 2 -t '>' < $OUT/indexreport.html 
cat < $OUT/indexreport.html ) >> $OUT/index.html
#sort -k 2 -t '>' < $OUT/indexreport.html ) >> $OUT/index.html
echo built index.html

#firefox $OUT/indexreport.html

if [ -z $BROWSER ]
then
	BROWSER=`which firefox google-chrome opera epiphany xdg-open | head -n1` #Could perhaps adjust order
fi

echo $URL_OF_OUT/indexreport.html
if [ ! -z "$DISPLAY" ]
then
	#google-chrome $OUT/index.html && wmctrl -R '- Google Chrome'
	$BROWSER file://`pwd`/$OUT/index.html && wmctrl -R 'Keytest_Report'
fi

if [ -e "keytest_upload.rc" ]
then
	#This is not a webserver, so we'll have to upload the HTML files to our host
	. ./keytest_upload.rc
	rsync -ra --progress html_out/$OUT_NAME $KEYTEST_UPLOAD_AS_USER@$KEYTEST_HTML_HOST:/var/www/$KEYTEST_HTML_DIR/html_out/$OUT_NAME/
fi
