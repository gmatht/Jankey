DIRNAME0=`dirname "$0"`
#ROOT_OUTDIR="$DIRNAME0/out"
#OUTDIR="$ROOT_OUTDIR"

OUTDIR="$TMP_DIR"
STATUS_FILE="$TMP_DIR"/log.status
#OUTDIR="$DIRNAME0/out"
DEBUG_FILE="$TMP_DIR"/debug
if [ -z "$dotLYX" ]
then
	dotLYX=.lyx # The lyx setting directory is ~/$dotLYX
fi

THIS_PID=$$

WINDOW_MANAGER=icewm

mkdirp () {
	mkdir -p "$1"
	chmod g+w "$1"
} 

kill_exe() {
	killall evince-previewer latex pdflatex
	killall_children $EXE_NAME
	killall -9 evince-previewer latex pdflatex
}

killall_children() {
	for pid in `ps ux | grep :..\ "$1" | grep -v grep | awk '{print $2}'`
	do
		kill $pid
		kill `$DIRNAME0/list_all_children.sh $pid`
	done
	sleep 0.2
	for pid in `ps ux | grep :..\ "$1" | grep -v grep | awk '{print $2}'`
	do
		kill -9 $pid
		kill -9 `$DIRNAME0/list_all_children.sh $pid`
	done
}

kill_all_childrenx() {
	echo killing $1 all children of PID $1 by $$
        #echo kill $1 `$DIRNAME0/list_all_children.sh $1` 
        kill $1 `$DIRNAME0/list_all_children.sh $1`
}
	
kill_all_children() {
	kill_all_childrenx '' $1
        sleep 0.1
	kill_all_childrenx '-9' $1
}

store_result() {
if [ -z "$NO_STORE_RESULT" ]
then
	#move result to permanent storage
	PREFIX=$(echo $(echo $OUTDIR | egrep -o '/[[:alnum:]]+.KEYCODEpure.replay' | sed 's/^.//' | sed s/.KEYCODEpure.replay//g) | sed 's/[[:space:]]/_/g')

	echo store_result "$@"	
	STORE_DIR=$ROOT_OUTDIR/$1
	mkdirp $STORE_DIR
	for F in $OUTDIR/$SEC*
	do 
		NEW_NAME="$PREFIX_"$(basename $F)
		cp $F $STORE_DIR/$NEW_NAME
	done
	get_version_info "$STORE_DIR/$PREFIX_$SEC".info
	if [ "$1" = "final" ]
	then
		tar -c $OUTDIR | gzip -9 > $ROOT_OUTDIR/final/$PREFIX_$SEC.tar.gz && (
			GDB_BAK=$GDB
			GDB=$OUTDIR/$LAST_CRASH_SEC.GDB
			CONFIRM_FILE=`calc_confirm_file`
			echo Reproducible > "$CONFIRM_FILE"
			(echo ---- CONF BEGIN
			set | egrep '^(CONFIRM_FILE|GDB|WANT_CRASH_I)'
			echo ls "$GDB" ----
			ls "$GDB"
			echo ls $OUTDIR/$SEC* ---
			ls $OUTDIR/$SEC*
			echo ---- CONF END
			echo) >> $DEBUG_FILE
			GDB=$GDB_BAK
		)
	fi
fi
}	


#BORED_AFTER_SECS=7200 #If we have spent more than 3600 secs (an hour) replaying a file, without learning anything new, go and start looking for more bugs instead
if [ -z $BORED_AFTER_SECS ]
then
	BORED_AFTER_SECS=7200 #If we have spent more than 3600 secs (an hour) replaying a file, without learning anything new, go and start looking for more bugs instead
fi

LAST_CORE=""

#############################
# This section of code is LyX Specific
#############################

if [ ! -e $DIRNAME0/$dotLYX ]
then
	echo WARNING $DIRNAME0/$dotLYX does not exist A
	echo will need to regenerate .lyx every test
fi

#if [ ! -e lib/doc.orig ]
#then
#	mv lib/doc lib/doc.orig
#fi

#kill_all_children() {
#        kill `$DIRNAME0/list_all_children.sh $1`
#        sleep 0.1
#        kill -9 `$DIRNAME0/list_all_children.sh $1`
#}

#. $DIRNAME0/shared_functions.sh


ensure_cannot_print () {
if [ ! -z "$REPLAYFILE" ]
then
	return
fi
if lpq
then
 
	echo We can print, this is bad!
	echo use lpadmin to stop keytest from destroying a forest.
	full_exit
	sleep 999999 ; read
else
	echo "Phew, lpq reckons we aren't ready to print. This is a *good* thing!"
fi
}

extras_save () {
 return 
 for f in `ls lib/doc`
 do
	if [ lib/doc/$f -nt lib/doc.orig/$f -o ! -e lib/doc.orig/$f ]
	then 
		#echo making doc dir $OUTDIR/$SEC.doc
		mkdirp $OUTDIR/$SEC.doc
		cp -a lib/doc/$f $OUTDIR/$SEC.doc/
	fi
 done
}

extras_prepare () {
	return
	mkdirp lib/doc/
	rm lib/doc/*.lyx
	cp -p lib/doc.orig/*.lyx lib/doc/
}

get_crash_id () {
  name=`(grep -o ' in lyx::[[:alnum:]:]*' < $GDB ; grep -o ' [ai][nt] [[:alnum:]:]*' < $GDB) |  grep -v -i assert | head -n4 | sed s/in// | sed 's/ //g'`
  echo $name | sed 's/ /__/g'
}

calc_confirm_file() {
	id=`get_crash_id`
	echo "$ROOT_OUTDIR/$id.reproduced"
}

get_pid () {
	sleep 3
	echo getting pidof "$1" 1>&2
	#PID=`ps "-u$USER" "$2" | grep "$1" | grep -v grep | sed 's/^ *//g'|  sed 's/ .*$//'`
	PID=`ps x | grep "$1" | grep -v grep | grep -v "gdb " | sed 's/^ *//g'|  sed 's/ .*$//'`
	echo "$PID" | ( grep " " > /dev/null && ( echo ERROR too many PIDs 1>&2 ; ps x ; full_exit ) )
	nPIDs=`echo PID "$PID" | wc -l`
	echo nPIDs $nPIDs 1>&2
	sleep 1
	echo -- if [ "$nPIDs" != "1" ] 1>&2
	if test "$nPIDs" != "1" #2> /tmp/testerr
	then 
		echo autolyx: Wrong number of PIDs "$nPIDs" "($1)" "($2)" 1>&2
		echo autolyx: PIDs "$PID" 1>&2
		ps x 1>&2
		echo -----
	fi
	echo "$PID"
	echo got pidof "$1" 1>&2
}
clean_up () {
  	KT_PID=`get_pid keytest.py x`
  	kill $KT_PID
	sleep 0.1
  	kill -9 $KT_PID
}

full_exit() {
	clean_up

	echo attempting to exit this entire script... normal exit may just exit one function

	kill $THIS_PID
	sleep 1
	echo We should not get this far
	sleep 1
	kill -9 $THIS_PID
	echo We really should not get this far 
	exit
}

run_gdb () {
  #Spawn a process to kill lyx if it runs too long
  if ! touch $GDB
  then
	echo cannot touch $GDB
	full_exit
  fi
  echo DISPLAY $DISPLAY
  (sleep 300; echo KILLER ACTIVATIED ; kill_exe ; killall gdb ; sleep 0.1 ; killall -9 gdb || true)&
  KILLER_PID=$!
  echo KILLING LYX, before starting new lyx
  kill_exe
  mkdirp $NEWHOME/tmp
  echo Starting GDB
  #shell svn info $SRC_DIR/
  #shell kill $CHILD_PID
  #shell kill -9 $CHILD_PID
  (echo "
  run $EXE_TO_TEST_ARGS 
  bt
  shell wmctrl -l
  shell sleep 1
" ; yes q) | HOME="$NEWHOME" TMPDIR="$NEWHOME/tmp" LYX_NO_BACKTRACE_HELPER="y" gdb $EXE_TO_TEST 2>&1 | strings|  tee $GDB ####| head -n40
  echo "end run_gdb ($KILLER_PID)"
  kill $KILLER_PID
  sleep 0.1
  kill -9 $KILLER_PID

  #### gcore $GDB.core
  #shell wmctrl -r __renamed__ -b add,shaded
  #shell wmctrl -r term -b add,shaded
  #shell wmctrl -r term -b add,shaded
  #shell wmctrl -R lyx' 
  #
  #shell import -window root '$GDB.png'
  #shell import -window root '$GDB..png'
  #exit
}


###########################

check_can_write () {
 TEST_FILE="$1"/.test_can_write
 if ! touch "$TEST_FILE" 
 then
	echo cannot write to "$TEST_FILE", exiting 1>&2
	full_exit
 fi
 rm "$TEST_FILE"
}
	

check_relatime () {
 if ! mount | egrep ' / .*(rel|no)atime'
 then
	echo -----------------------------------------
 	echo - WARNING!!!!
	echo - It appears that relatime is not enabled on your root partition
	echo - This means that every time you access a file, metadata will be updated
	echo - Keytest reads a *lot* of files
	echo - Unless you enable relatime or noatime, running keytest will
	echo -   * Greatly slow down your forground tasks.
	echo -   * Increase the wear and tear on your harddisk
	echo -----------------------------------------
	logger WARNING setting relatime on '/' STRONGLY recommended when running keytest!
 fi 1>&2
}

make_status_file () {
	set | egrep '(BOREDOM|WANT_CRASH_ID)' > $STATUS_FILE
}

try_replay () {
	id=`get_crash_id`
	echo CRASH_ID 
	export CONFIRM_FILE=`calc_confirm_file`
	if [ ! -e "$CONFIRM_FILE" ]
	then
		echo $CONFIRM_FILE does not exist B
		echo This bug appears not to have been reproduced before
		echo Will try to reproduce now
		echo
	        #echo WANT_CRASH_ID=$WANT_CRASH_ID
		mkdir -p $ROOT_OUTDIR/tasks
		TASK_FILE_NAME=$ROOT_OUTDIR/tasks/$SEC.$id.replay.task
		echo "replay $KEYCODEpure $id" >> $TASK_FILE_NAME
		echo "replay $KEYCODEpure $id" >> $ROOT_OUTDIR/tasks.log
		WANT_CRASH_ID="$id" do_replay
	        #echo _WANT_CRASH_ID=$WANT_CRASH_ID
		echo 
		echo Finished attempt at replay
		rm $TASK_FILE_NAME
	else
		echo $CONFIRM_FILE exists
		echo This bugs has already been reproduced
		echo Will not attempt to reproduce again
	fi
}

do_replay() {
	echo WANT_CRASH_ID=$WANT_CRASH_ID
	(REPLAYFILE="$KEYCODEpure" TAIL_LINES=25 MAX_TAIL_LINES=5000 bash "$0")&
	TEST_PID="$!"
	echo Backgrounded $TEST_PID
	echo waiting for $TEST_PID to finish
	wait "$TEST_PID" 
}

test_replayed () {
	test -e "$f.replay/last_crash_sec" -o -e "$f.replay/Irreproducible" 
}

move_to_replayed () {
	mkdirp $REPLAY_DIR/replayed
	mv $f* $REPLAY_DIR/replayed
}

do_queued_replay() {
	if test_replayed
	then
		move_to_replayed
	else
		#./development/keytest/killtest
		kill_exe
		KEYCODEpure="$f" do_replay
		#if test_replayed 
		#then 
		move_to_replayed
		#fi
	fi
}

do_queued_replays() {
  echo doing queued_reproduce_
(
  REPLAY_DIR=$ROOT_OUTDIR/toreproduce
  export BORED_AFTER_SECS=0
  echo doing queued_reproduce
  echo reproduce`ls $REPLAY_DIR/*KEYCODEpure`
  for f in `ls $REPLAY_DIR/*KEYCODEpure`
  do
        do_queued_replay
  done
  echo done queued_reproduce
)
  echo done queued_reproduce_
REPLAY_DIR=$ROOT_OUTDIR/toreplay
echo doing queued_replays
echo replays `ls $REPLAY_DIR/*KEYCODEpure`
for f in `ls $REPLAY_DIR/*KEYCODEpure`
do
	do_queued_replay
done
echo done queued_replays
jobs

}

interesting_crash () {
echo interesting_crash $GDB , $KEYCODE , =  "$WANT_CRASH_ID" = `get_crash_id`
(grep " signal SIG[^TK]" $GDB || grep KILL_FREEZE $KEYCODE) &&
   ( test -z "$WANT_CRASH_ID" || test "$WANT_CRASH_ID" = `get_crash_id` )
}

#get_pid() {
#	     ps a | grep $1 | grep -v grep | sed 's/^ *//g'|  sed 's/ .*$//'
#}

get_version_info() {
	(cd $SRC_DIR ; svn info) 2>&1 |tee "$1".svn
	### [[Should reenable this for lyx, makes little sense for abiword.
	#echo GETTING VERSION
	#$EXE_TO_TEST -version 2>&1 "$1".version || true
	#echo GOT VERSION
}

absname () {
	#Absolute name of path
        echo "$1" | grep ^/ || ( echo `pwd`/"$1" )
}


do_one_test() {
  GDB=$OUTDIR/$SEC.GDB
  KEYCODE=$OUTDIR/$SEC.KEYCODE
  KEYCODEpure=$OUTDIR/$SEC.KEYCODEpure
  NEWHOME=`absname $TMP_DIR/kt.dir/$SEC.$USER.dir`
  mkdirp $NEWHOME
  chmod g+w $TMP_DIR/kt.dir
  mkdir $NEWHOME
  NEWHOME=`cd $NEWHOME || (echo CANNOT CD TO NEW HOME $NEWHOME 1>&2 ; sleep 9 ; full_exit) ; pwd`
  echo NEWHOME $NEWHOME
  mkdirp "$NEWHOME"
  test -z "$DONT_CP_dotLYX" && cp -rv $DIRNAME0/$dotLYX "$NEWHOME"/
  kill_exe
  echo killall -9 latex pdflatex
  killall -9 latex pdflatex || true
  #rm -rf "$NEWHOME"/.lyx-
  #cp -rv ~xp/.lyx- "$NEWHOME"/.lyx-
  #ls "$NEWHOME"/.lyx- > /tmp/ls_NEW.log
  ( sleep 9 &&
     ps a | grep $EXE_NAME 
	echo -- 1 || full_exit
     LYX_PID=""
     i=0
     echo -- while [ -z "$LYX_PID" -a 200 -gt $i ]
     while [ -z "$LYX_PID" -a 200 -gt $i ]
     do
	     #export LYX_PID=`ps a | grep /src/lyx | grep -v grep | sed 's/^ *//g'|  sed 's/ .*$//'`
	     export LYX_PID=`get_pid "$EXE_TO_TEST$" `
	     echo LYXPID "$LYX_PID" || full_exit
	     sleep 0.1
	     i=$(($i+1))
     done 
     echo `ps a | grep $EXE_TO_TEST`
	echo -- 2
     echo `ps a | grep $EXE_TO_TEST | grep -v grep`
	echo -- 3
     echo `ps a | grep $EXE_TO_TEST | grep -v grep | sed 's/ [a-z].*$//'`
	echo -- 4
     echo LYX_PID=$LYX_PID
     echo 15 > /proc/$LYX_PID/oom_adj
     echo XA_PRIMARY | xclip -selection XA_PRIMARY
     echo XA_SECONDARY | xclip -selection XA_SECONDARY
     echo XA_CLIPBOARD | xclip -selection XA_CLIPBOARD
     sleep 0.1
     killall xclip

     

     echo -- if [ ! -z "$LYX_PID" ]
     if [ ! -z "$LYX_PID" ]
     then
	 kill `ps a | grep keytest.py | grep -v grep | cut -c 1-5`
	 sleep 0.2
	 kill -9 `ps a | grep keytest.py | grep -v grep | cut -c 1-5`
	#while ! wmctrl -r $LYX_WINDOW_NAME -b add,maximized_vert,maximized_horz
	while ! $RAISE_WINDOW_CMD
	do
		echo trying to maximize lyx
		if ps -U $USER | grep $WINDOWS_MANAGER
		then
			echo at least the windows manager is running
		else
			echo restarting windows_manager
			$WINDOWS_MANAGER &
		fi
		sleep 1
	done
         echo MAX_DROP is $MAX_DROP
	 echo BEGIN KEYTEST KEYTEST_OUTFILE="$KEYCODEpure" nice -19 python $DIRNAME0/keytest.py
	 if [ -e $DIRNAME0/keytest.py ]
	 then
		echo $DIRNAME0/keytest.py Exists \(`pwd`\)
	 else
		echo $DIRNAME0/keytest.py DOES NOT EXIST!!! \(`pwd`\)
	 fi
         KEYTEST_OUTFILE="$KEYCODEpure" nice -19 python $DIRNAME0/keytest.py | tee $KEYCODE
	 #echo "$!" > $NEWHOME/keytest_py.pid
	 echo END_KEYTEST KEYTEST_OUTFILE="$KEYCODEpure" nice -19 python $DIRNAME0/keytest.py ..  tee $KEYCODE
     fi
     echo NO_KEYTEST
     echo killall lyx
     kill_all_children $LYX_PID
     kill_exe
     sleep 0.1
     kill -9 "$LYX_PID" || true
     #killall -9 $EXE_NAME #sometimes LyX really doesn't want to die causing the script to freeze
     #killall lyx #sometimes LyX really doesn't want to die causing the script to freeze
     sleep 1
     #kill -9 "$LYX_PID" #sometimes LyX really doesn't want to die causing the script to freeze

     #sleep 1 
     #killall -9 lyx
     ) &
  CHILD_PID="$!"
  ls $EXE_TO_TEST ; sleep 1
   pwd
  
  #You may want to use the following to simulate SIGFPE
  #(sleep 90 && killall -8 lyx) &
  echo TTL $TAIL_LINES
  #extras_prepare
  ensure_cannot_print
  run_gdb
#  (run_gdb) &
#  GDBTASK_PID="$!"
#  (sleep 600 ; kill "$!")	
#  echo WAITING FOR: wait $GDBTASK_PID
#  wait $GDBTASK_PID
#  echo NOLONGER waiting for: wait $GDBTASK_PID

  echo END gdb
  kill $CHILD_PID
  KT_PID=`get_pid keytest.py`
  echo KT_PID=$KT_PID
  kill $KT_PID
  sleep 0.3
  kill -9 $CHILD_PID
  kill -9 $KT_PID
  # Or use "exited normally":
  echo END gdb2
  # these tend to take up a huge amount of space:
  echo will erase "$NEWHOME"
  sleep 2
  rm -rf $NEWHOME
  #if (grep " signal SIG[^TK]" $GDB || grep KILL_FREEZE $KEYCODE)
  if interesting_crash
  then
    #extras_save
    #mkdirp $OUTDIR/save && (
	#    ln $OUTDIR/$SEC.* $OUTDIR/save ||
	#    cp $OUTDIR/$SEC.* $OUTDIR/save)
    rm $OUTDIR/$LAST_CRASH_SEC.GDB
    rm $OUTDIR/$LAST_CRASH_SEC.KEYCODE
    LAST_CRASH_SEC=$SEC
    echo $LAST_CRASH_SEC > $OUTDIR/last_crash_sec
    get_version_info $OUTDIR/last_crash_sec.info
    echo GOT VERSION delme
    if [ ! -z "$TAIL_LINES" ]
    then
    	LAST_EVENT="$SEC"
	echo Reproducible > $OUTDIR/Reproducible
	store_result reproducible
    fi
    TAIL_LINES="" 
    if [ -z "$REPLAYFILE" ]
    then
	store_result initial
        #The following errors just keep on popping up. No point reproducing them over and over
	#if egrep '(::Graph::|lyx::frontend::GuiErrorList)' $GDB
	if egrep '(lyx::frontend::GuiErrorList)' $GDB
	then
		echo NOT REPLAYING, as ERROR ALREADY VERY WELL KNOWN
	else
		echo ATTEMPTING TO REPLAY
		try_replay
	fi
    else
    	export KEYTEST_INFILE=$KEYCODEpure
	NUM_KEYCODES=`wc -l < $KEYCODEpure`
	echo NUM_KEYCODES $NUM_KEYCODES, was $LAST_NUM_KEYCODES
	if [ "$NUM_KEYCODES" != "$LAST_NUM_KEYCODES" ]
	then
		LAST_EVENT="$SEC"
		LAST_NUM_KEYCODES=$NUM_KEYCODES
		echo "Hooray! we have eleminated some keycodes"
	fi
    fi
    if [ ! -z "$AND_THEN_QUIT" ]
    then
		RESULT=1
		echo RR 1
		store_result final
		return 1
    fi
    if [ ! -z "$LAST_CORE" ]
    then
      rm "$LAST_CORE"
    fi
    LAST_CORE="$GDB.core"
  else
    if ! test -z "$BAK"
    then
	  echo will erase '$BAK/*'="'$BAK/*'"
	  sleep 2
          rm -rf $BAK/*
    	  mv $OUTDIR/$SEC.* $BAK/
    else
          echo "BAK is null"
    fi
    if [ ! -z "$TAIL_LINES" ]
     then
        echo TTL3 $TAIL_LINES
	echo MAX_TAIL_LINES "$MAX_TAIL_LINES"
	TAIL_LINES=$(($TAIL_LINES*2))
        echo TTL4 $TAIL_LINES
	if [ "$TAIL_LINES" -ge "0$MAX_TAIL_LINES" -a ! -z "$MAX_TAIL_LINES" ]
	then
		echo Giving up because $TAIL_LINES '>' $MAX_TAIL_LINES
		echo Irreproducible > $OUTDIR/Irreproducible
		full_exit
	fi
    fi
    if [ ! -z "$AND_THEN_QUIT" ]
    then
		RESULT=0
		echo RR 0
		return 0
    fi

    echo TTL2 $TAIL_LINES
    #kill_all_children $$
  fi
  #kill_all_children $$
}

test_exist () {
	if [ ! -e "$1" ]
	then    
	        echo "$1" does not exist! 1>&2
		full_exit 1
	fi
}

assert () {
	if ! "$@"
	then 
		echo "Assertion '$*' Failed!" 1>&2
		full_exit 1
	fi
}

do_task () {

if [ ! -e "$2" ]
then
	tar -zxf $TASK_FILE.data.tar.gz
fi

#assert test "$1" = replay
if test "$1" = replay
then
	KEYCODEpure="$2" WANT_CRASH_ID="$3" do_replay
else
	echo UNKNOWN TASK TYPE "$1"
fi

}

do_tasks () {
echo DOING TASKS
mkdirp $ROOT_OUTDIR/tasks_done
for f in $ROOT_OUTDIR/tasks/*.task
do
	echo DOING TASK $f
	TASK_FILE=$f do_task `cat $f` && mv $ROOT_OUTDIR/tasks/$f $ROOT_OUTDIR/tasks_done/$f
	echo DONE TASK $f
done
}

	


#####################################################
# MAIN
#####################################################

#Start basic sanity checks

sanity_checks () {

 mkdirp "$TMP_DIR" 

 if [ ! -e "$EXE_TO_TEST" ]
 then
	echo EXE_TO_TEST "$EXE_TO_TEST" does not exist C
	echo Cannot proceed
	exit 1
 fi

 TMPFS_USED=`df tmpfs/ | grep -o ...% | sed s/[^[:digit:]]//g`
 if [ "$TMPFS_USED" -gt 95 ]
 then
	echo "More than 95% ($TMPFS_USED%) of tmpfs/ is used"
	echo "Not much point starting... will abort"
	exit 1
 fi

 assert which xvkbd
 assert which wmctrl

 test_exist "$EXE_TO_TEST"
 test_exist "$DIRNAME0/keytest.py"

 ensure_cannot_print
 #Recent kernels default to relatime, so check_relatime not really needed.
 #check_relatime
 check_can_write "$ROOT_OUTDIR"
 mkdirp "$TMP_DIR"/kt_dir
 check_can_write "$TMP_DIR"
 check_can_write "$TMP_DIR"/kt_dir

 if ! test -z "`pylint -e $DIRNAME0/keytest.py`" 
 then
	echo  "$DIRNAME0/keytest.py" has python errors
	exit
 fi
}

autolyx_main () {
mkdirp "$TMP_DIR"
if ! wmctrl -l > /dev/null 
then
	echo DISPLAY!
	echo autolyx: cannot run wmctrl -l
	echo DISPLAY!
	echo DISPLAY=$DISPLAY
	exit
fi

if [ ! -z "$1" ]
then
	REPLAYFILE=$1
	echo REPLAYFILE=$1
fi

sanity_checks

if [ ! -z "$REPLAYFILE" ]
then
	echo REPLAYMODE
	OUTDIR="$REPLAYFILE.replay/"
	mkdirp $REPLAYFILE.replay/ #|| (echo Cannot make directory $REPLAYFILE.replay/ ; full_exit )
	if [ ! -d $REPLAYFILE.replay/ ]
	then
		echo Cannot make directory $REPLAYFILE.replay/
		full_exit
	fi
	export KEYTEST_INFILE=$REPLAYFILE
	if [ -e $REPLAYFILE.replay/last_crash_sec -a -z "$AND_THEN_QUIT" ]
	then
		KEYTEST_INFILE=$REPLAYFILE.replay/`cat $REPLAYFILE.replay/last_crash_sec`.KEYCODEpure
		if [ ! -e $KEYTEST_INFILE ]
		then
			#if the newer file does not exist, clearly we do not want to use it
			KEYTEST_INFILE=$REPLAYFILE
		fi
		TAIL_LINES=''
	fi
	if [ ! -e "$REPLAYFILE" ]
	then
		echo "$REPLAYFILE" does not exist
		echo exiting
		full_exit 1
	fi
else
	do_queued_replays
	echo RANDOM MODE
fi

get_pid [0-9].x-session-manager"$" x
export X_PID=`get_pid [0-9].x-session-manager x`
echo X_PID $X_PID

export TAIL_LINES=$TAIL_LINES
echo TL $TAIL_LINES


BAK="$OUTDIR/backup"
mkdirp $BAK

	


#rename other windows to avoid confusion.
wmctrl -N __renamed__ -r lyx
wmctrl -N __renamed__ -r lyx
wmctrl -N __renamed__ -r lyx
wmctrl -N __renamed__ -r lyx
export PATH=`cd $DIRNAME0; pwd`/path:$PATH

if [ ! -z "$1" ]
then
  SEC=`date +%s`
  export MAX_DROP=0
  if [ ".$SCREENSHOT_OUT." = ".auto." ]
  then
	echo SCREENSHOT_OUT was $SCREENSHOT_OUT.
	export SCREENSHOT_OUT="$OUTDIR/$SEC.s"
	echo SCREENSHOT_OUT is $SCREENSHOT_OUT.
	#exit
  fi
  export RESULT=179
  do_one_test #| tee do_one_test.log
  RESULT="$?"
  echo Ressult $RESULT

  kill `$DIRNAME0/list_all_children.sh $$`
  killall xclip
  sleep 0.1
  kill -9 `$DIRNAME0/list_all_children.sh $$`
  killall -9 xclip || true

  exit $RESULT
  
  #echo done ; sleep 1
  full_exit
fi



echo TTL $TAIL_LINES

LAST_EVENT=`date +%s` # Last time something interesting happened. If nothing interesting has happened for a while, we should quit.

rm $LOG_FILE

ensure_cannot_print
echo X_PID $X_PID
export X_PID=`get_pid [0-9].x-session-manager"$" x`
echo PATH $PATH

if [ -z "$REPLAYFILE" ]
then
	do_tasks
fi

while true
do
#(
 echo Currently running autolyx PID=$$
 if [ ! -z "$TAIL_LINES" ] 
 then
  echo TAIL_LINES: "$TAIL_LINES"
  TAIL_FILE=$OUTDIR/tail_"$TAIL_LINES"
  tail -n "$TAIL_LINES" "$REPLAYFILE" > $TAIL_FILE
  KEYTEST_INFILE=$TAIL_FILE
  MAX_DROP=0
 else
  MAX_DROP=0.05
 fi #| tee -a $LOG_FILE
 export MAX_DROP
  SEC=`date +%s`
 if [ -z "$TAIL_LINES" ]
 then
   if [ ! -z "$REPLAYFILE" ] # We are replaying a KEYCODEpure file
   then
	BOREDOM=$(($SEC-$LAST_EVENT))
	echo Boredom factor: $SEC-$LAST_EVENT'=' BOREDOM=$BOREDOM
	if [ $BOREDOM -gt $BORED_AFTER_SECS -o -e $OUTDIR/STOP ]
	then
		echo
		echo Is is now $SEC seconds
		echo The last time we managed to eliminate a keycode was at $LAST_EVENT
		echo We get bored after $BORED_AFTER_SECS seconds
		echo Giving up now.
		echo
		echo $LAST_CRASH_SEC > $OUTDIR/Finished
		SEC=$LAST_CRASH_SEC #I used SEC in place of LAST_CRASH_SEC. Here is a quick fix.
		#make screenshots
		if [ `wc -l < $OUTDIR/$SEC.KEYCODEpure/` -lt 40 ] # If many keycodes, dont bother trying to make screenshots
		then
			echo "Making screenschot of $OUTDIR/$SEC.KEYCODEpure"
			test -e $OUTDIR/$SEC.KEYCODEpure || echo "DOES NOT EXIST: $OUTDIR/$SEC.KEYCODEpure"
			(SCREENSHOT_OUT="auto" ./doNtimes.sh 19 ./reproduce.sh $OUTDIR/$SEC.KEYCODEpure ; echo $f )
		else
			echo "Too many keycodes, not making screenshots."
		fi
		store_result final
		full_exit
	fi
   else
	BOREDOM=NA
	do_queued_replays
   fi
 fi | tee -a $LOG_FILE
 do_one_test
if [ `stat -c %b $LOG_FILE` -gt 1000 ] # if logfile > 1000 blocks in size
then
	mv $LOG_FILE $LOG_FILE.old 
fi
done
kill_all_children $$
kill_all_children $$
}
