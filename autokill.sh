!/bin/sh
KT=`dirname $0`
. $KT/shared_variables.sh
if [ ! -z "$1" ]
then
  OUT_NAME=out/$1
fi

OUT="$TMP_DIR"
LOG_FILE=tmpfs/nohup.log
NOW_SEC=`date +%s`
LATEST_FILE=`ls $OUT/* $ROOT_OUTDIR/toreproduce/* $ROOT_OUTDIR/toreplay/* $ROOT_OUTDIR/toreproduce/replayed/* $ROOT_OUTDIR/toreplay/* -td -1 2> /dev/null | egrep -v '(log|list_of_sizes.txt|kt.dir)'  | head -n1 `
#LATEST_SEC=`basename $LATEST_FILE | sed s/[.].*//`
LATEST_SEC=`date +%s -r $LATEST_FILE`
AGE=$(($NOW_SEC-$LATEST_SEC))

if [ "$AGE" -gt 1800 ] #running more than 1/5 and hour
then
	echo AGE too old!!!
	. $KT/shared_functions.sh
	#maybe the next four lines should be made a function?
	kill_exe
	killall gdb
	sleep 0.2
	killall -9 gdb 
fi

