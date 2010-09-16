set -e

pylint -e ./cache-bisect.py

# This script does a binary bisection on a KEYCODEpure file

D=3
BISECT_AS_USER=keytest2

#Uncomment the following if you want to bisect to run as you with the primary X-server.
#D=0
#BISECT_AS_USER=$USER

absname () {
        #Absolute name of path
        echo "$1" | grep ^/ || ( echo `pwd`/"$1" )
}

TEST_FILE=`echo "$1" | sed s,^file://,,`
TEST_FILE=`echo "$1" | sed s,^http://.*/keytest/,,`
TEST_FILE=`absname "$TEST_FILE"`


KT=`dirname $0`
echo KT $KT 
cd $KT || exit
KT=`pwd`
echo PWD $PWD

BISECT_TMP_DIR="$KT/tmpfs/cache-bisect.$USER"
mkdir -p $BISECT_TMP_DIR
chgrp keytest $BISECT_TMP_DIR
chmod g+rwx $BISECT_TMP_DIR

if echo "$TEST_FILE" | grep '.KEYCODEpure$'
then
	KEYCODEpure=$TEST_FILE
	echo KEYCODEpure $KEYCODEpure 
	DIR=`dirname $KEYCODEpure`

	#sudo -H -u $BISECT_AS_USER touch $DIR/.test_can_write || exit
	#rm -f $DIR/.test_can_write

	GDB_FILE=`echo $KEYCODEpure | sed s/KEYCODEpure/GDB/`
	echo GDB_FILE $GDB_FILE

	CRASH=`grep -o lyx::[:[:alnum:]]* < $GDB_FILE| grep -v -i "assert" | grep -v "lyx::lyx" | head -n1`

	KEYCODEpure_cp="$BISECT_TMP_DIR"/`basename $KEYCODEpure`
	cp $KEYCODEpure $KEYCODEpure_cp

	TEST_COMMAND="$KT/reproduce.sh $KEYCODEpure_cp $CRASH"
	echo CRASH $CRASH
elif echo "$TEST_FILE" | grep '.sh$'
then
	echo TEST_FILE "$TEST_FILE"
	echo "$TEST_FILE"* "$KT/tmpfs/cache-bisect/"
	cp "$TEST_FILE"* "$KT/tmpfs/cache-bisect/"
	chgrp keytest $KT/tmpfs/cache-bisect/*sh.lyx
	chmod g+w $KT/tmpfs/cache-bisect/*sh.lyx
	
	TEST_COMMAND="$KT/tmpfs/cache-bisect/`basename $TEST_FILE`"
else
	echo Type of "$TEST_COMMAND'" not recognized.
	echo Can only handle KEYCODEpure files and sh files.
	exit 1
fi

set | egrep  '^(CRASH|KEYCODEpure|GDB|TEST_COMMAND)='

test_run () {
	A=/tmp/.out.$USER.1
	B=/tmp/.out.$USER.2
	if ! ("$@" > $A 2> $B)
	then
		echo FAILED: "$*"
		echo --- stdout ---
		cat $A
		echo --- stderr ---
		cat $B
		exit 1
	fi
}

DISPLAY=:$D xhost +localhost || true
#( sudo -H -u $BISECT_AS_USER ./kt > /dev/null 2> /dev/null || true ; DISPLAY=:$D xwininfo -root > /dev/null 2> /dev/null || sudo -H -u $BISECT_AS_USER ./initXvfb $D > /dev/null 2>/dev/null ; DISPLAY=:$D LYX_NO_BACKTRACE_HELPER="y" ./cache-bisect.py sudo -H -u $BISECT_AS_USER $KT/doNtimes.sh 0013 $KT/set_LYX_DIR_16x $TEST_COMMAND ) 2>&1 | tee $KEYCODEpure.full_bisect_log

(
sudo -H -u "$BISECT_AS_USER" ./kt > /dev/null 2> /dev/null || true
DISPLAY=:$D xwininfo -root > /dev/null 2> /dev/null ||
	test_run sudo -H -u "$BISECT_AS_USER" ./initXvfb $D
DISPLAY=:$D LYX_NO_BACKTRACE_HELPER="y" ./cache-bisect.py sudo -H -u "$BISECT_AS_USER" "$KT/doNtimes.sh" 0032 "$KT/set_LYX_DIR_16x" $TEST_COMMAND	
) #2>&1 | tee $KEYCODEpure.full_bisect_log

mkdir -p out/cache-bisect/store
cp /tmp/cache-bisect.xp.log  out/cache-bisect/store/`basename "$1"`
