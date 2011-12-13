. ./shared_variables.sh
OUT=$ROOT_OUTDIR
set -x
if [ "$1" = "-f" ]
then
  FORCE=yes
  shift
fi

for g in "$@"
do
if echo "$g" | grep -s '^file://'
then
	f=`echo "$g" | sed s,^file://,,`
else
	f="$g"
fi
f=`echo "$f" | sed s,^file://,, |  sed s/html$/KEYCODEpure/g | sed s,^http://.*/keytest/,,`
echo file_ $f
if [ "$FORCE" = yes ]
then 
	rm -f $f.replay.bak
	mv $f.replay $f.replay.bak
fi
if [ ! -e $f.replay ]
then
	echo replaying $f for screenshot
	#(SCREENSHOT_OUT="auto" ./doNtimes.sh 3 ./reproduce.sh $f ; echo $f ; ./list_all_children.sh kill $$ ) 2>&1 | tee $f.screenshot-log
	(SCREENSHOT_OUT="auto" ./doNtimes.sh 9 ./reproduce.sh $f ; echo $f ; killall sleep ) 2>&1 | tee $f.screenshot-log
	echo replayed $f for screenshot
else
	echo  $f.replay already exists
fi
done
