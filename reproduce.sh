#!/bin/bash
# attempt to reproduce an error from a KEYCODEpure file
# NOTE: does not kill its children, may lead to hangs.
KT=`dirname $0`
(cd $KT
if [ ! -z "$2" ]
then
	MUST_MATCH="$2"
fi

KEYCODEpure_FILE=`echo "$1" | sed s,^file:///,/,g`

set | grep ^KEYCODEpure_FILE=

echo AND_THEN_QUIT="y" time ./autolyx $KEYCODEpure_FILE 
AND_THEN_QUIT="y" time ./autolyx $KEYCODEpure_FILE 
#AND_THEN_QUIT="y" time $KT/autolyx $KEYCODEpure_FILE 
RESULT=$?
echo RESULT_REPRODUCE $RESULT
echo MUST_MATCH="$MUST_MATCH"
if [ $RESULT -gt 0 -a ! -z "$MUST_MATCH" ] 
then
	SEC=`cat $KEYCODEpure_FILE.replay/last_crash_sec`
	GDB_FILE=$KEYCODEpure_FILE.replay/$SEC.GDB
	echo GDB_FILE=$GDB_FILE
	ls $GDB_FILE 
	echo egrep "$MUST_MATCH" "$GDB_FILE"
	if egrep "$MUST_MATCH" "$GDB_FILE"
	then
		echo matches: egrep "$MUST_MATCH" "$GDB_FILE"
	else
		echo DOES NOT MATCH CRASH
		exit 125 
	fi
fi

exit $RESULT
)