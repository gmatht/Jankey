#!/bin/sh
. ./shared_variables.sh
if [ ! -z "$1" ]
then
  OUT_NAME=out/$1
fi

TMP_DIR=`get_tmp_dir keytest $OUT_NAME`

echo TMP_DIR $TMP_DIR

OUT="$TMP_DIR"
LOG_FILE=tmpfs/nohup.log
NOW_SEC=`date +%s`
echo NOW_SEC $NOW_SEC 
echo recently modified files:
echo LATEST_FILE="ls $OUT/* $ROOT_OUTDIR/toreproduce/* $ROOT_OUTDIR/toreplay/* $ROOT_OUTDIR/toreproduce/replayed/* $ROOT_OUTDIR/toreplay/* -td -1 | grep -v log  | head -n1"
LATEST_FILE=`ls $OUT/* $ROOT_OUTDIR/toreproduce/* $ROOT_OUTDIR/toreplay/* $ROOT_OUTDIR/toreproduce/replayed/* $ROOT_OUTDIR/toreplay/* -td -1 | egrep -v '(log|list_of_sizes.txt|kt.dir)'  | head -n1 `
echo $LATEST_FILE | (
 grep replay > /dev/null || (
	ls $OUT/* -hlotd | head -n6
 )
)
ls $OUT/* -htdo -1 | grep rep |head -n4

#LATEST_FILE=`ls $OUT/* $ROOT_OUTDIR/toreproduce/*  -td -1 | grep rep  | grep -v list_of_sizes.txt | head -n1`

#for D in "$OUT/torep"{lay,roduce}{,/replayed}
for D in /toreplay /toreplay/replayed /toreproduce /toreproduce/replayed
do
  if  [ "$LATEST_FILE" = "$ROOT_OUTDIR/$D" ]
  then
	#echo foo
	LATEST_FILE=`ls $ROOT_OUTDIR/$D/* -td -1 | grep replay | grep -v list_of_sizes.txt  | head -n1`	
  fi
done

#if  [ $LATEST_FILE = "$OUT/toreplay/replayed" ]
#then
#	echo foo
#	LATEST_FILE=`ls $OUT/toreplay/replayed/* -td -1 | grep replay  | head -n1`	
#else
#	echo oof
#fi

echo  LATEST_FILE $LATEST_FILE 
echo $LATEST_FILE | (
 grep replay > /dev/null && (
  if [ -e $LATEST_FILE/last_crash_sec ]
  then
	ls $LATEST_FILE/*re -lotd | head
	SEC=`cat $LATEST_FILE/last_crash_sec`
	echo $SEC $(($NOW_SEC-$SEC))
	ls -l $LATEST_FILE/$SEC.KEYCODEpure | head -n4
	if [ `wc -l < $LATEST_FILE/$SEC.KEYCODEpure` -lt 180 ]
	then
		sed 's/KK: //g' < $LATEST_FILE/$SEC.KEYCODEpure | awk '{printf("%s ",$0) }'
	fi
	echo
	grep "VIOLATED" $LATEST_FILE/$SEC.GDB
	grep "signal SIG" $LATEST_FILE/$SEC.GDB
	grep "lyx::" $LATEST_FILE/$SEC.GDB
  else
	ls $LATEST_FILE -lot | head
	grep -A 19 "signal SIG" `echo $LATEST_FILE | sed s/KEYCODEpure.replay/GDB/`
  fi
 ) || (
	ls $OUT/* -lotd | head
 )
)


false && tail -n 10000 $LOG_FILE | grep -F "autolyx:
Trace
reproduced
X_PID
x-session" | grep -v kill | grep -v Terminated | tail -n 9
#exit
echo autolyx crashes ---------
tail -n 10000 $LOG_FILE | grep autolyx: | grep -v kill | grep -v Terminated | grep -v grep #-A 5
echo python crashes ---------
tail -n 10000 $LOG_FILE | grep -i -a Trace -A 7 | tail -n8
#echo misc ----
