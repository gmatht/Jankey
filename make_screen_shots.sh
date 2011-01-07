. ./shared_variables.sh
OUT=$ROOT_OUTDIR
for g in "$@"
do
if echo "$g" | grep -s '^file://'
then
	f=`echo "$g" | sed s,^file://,,`
else
	f="$g"
fi
echo file_ $f
if [ ! -e $f.replay ]
then
	echo replaying $f for screenshot
	#(SCREENSHOT_OUT="auto" ./doNtimes.sh 3 ./reproduce.sh $f ; echo $f ; ./list_all_children.sh kill $$ ) 2>&1 | tee $f.screenshot-log
	(SCREENSHOT_OUT="auto" ./doNtimes.sh 9 ./reproduce.sh $f ; echo $f ) 2>&1 | tee $f.screenshot-log
	echo replayed $f for screenshot
else
	echo  $f.replay already exists
fi
done
