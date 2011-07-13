#!/bin/bash
#
# Run as: 
# KT=/mnt/big/xp/images/share/Ubuntu904/keytest
# ( sudo -H -u keytest2 ./kt; DISPLAY=:3 xwininfo -root || nice -19 ./initXvfb 3; DISPLAY=:3 nice -19 ./cache-bisect.py sudo -H -u keytest2 $KT/doNtimes.sh 3 $KT/WrongLine.sh )  2>&1 | tee tmpfs/bisect4.log
#
#
#WL=/home/xp/svn/PhD/t2/WrongLine3
#src/lyx $WL/t2.lyx $WL/t0.lyx &
#WINDOW_NAME=WrongLine.sh.t2.lyx

set -x

TMPFILE=/tmp/lyx-code.txt
WINDOW_NAME="LyX: ..."
if [ -z "$1" ]
then
	EXE=`pwd`_bin/bin/lyx
else
	EXE=`pwd`/"$1"
fi

if [ ! -e $EXE ]
then
	echo Cannot file $EXE
	exit
fi

echo PWD `pwd`
cd `dirname $0`
echo NO_CLIP | xclip 
#NEW_HOME=`mktemp`
echo PWD `pwd`
#HOME=$NEW_HOME $EXE $0.t2.lyx $0.t0.lyx &
#`pwd`_bin/bin/lyx $0.t2.lyx $0.t0.lyx &
#$EXE 2> $TMPFILE.err > $TMPFILE & #./WrongLine.sh.t2.lyx ./WrongLine.sh.t0.lyx &
pwd
echo "time $EXE 2> $TMPFILE.err  &" #./WrongLine.sh.t2.lyx ./WrongLine.sh.t0.lyx &
rm $TMPFILE.lyx

/usr/bin/time $EXE $TMPFILE.lyx 2> $TMPFILE.err  &#./WrongLine.sh.t2.lyx ./WrongLine.sh.t0.lyx &
#(time $EXE 2> $TMPFILE.err)  & #./WrongLine.sh.t2.lyx ./WrongLine.sh.t0.lyx &
LYX_PID=`ps  -o pid,ppid | grep \ $! | sed s/\ .*//$!` # Get child of time process
echo LYX_PID=$LYX_PID
echo NO_CLIP | xclip 
#while ! (wmctrl -F -R LyX || wmctrl -F -R lyx)
while ! (wmctrl -R "LyX: $TMPFILE.lyx")
do
	sleep 0.1
done
sleep 0.1
#for K in `echo '\Af n \Cs . . } \As RR \Ao RR \CD \[Escape] \Cq'`
#for K in `echo '\Cn \D9 \Ai \D9  n \D9  n \D9 nnn \D9 \[Right] asdf \D9 \r \r iadsf \Ca \Cc \Cv \Cv  \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc MEMINFO \Cq \Cs \Ad \Ad'`
for K in `echo '\Ai n n nnn \[Right] asdf \r \r iadsf \Ca \Cc \Cv \Cv  \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Cc MEMINFO \Cq \Cs \Ad \Ad'`
do
	if [ "$K" = RR ]
	then
		#wmctrl -R xp@xp
		wmctrl -R desktop

		wmctrl -R "LyX: "
	elif [ "$K" = MEMINFO ]
	then
		ps gaux | grep _bin/bin/lyx | grep -v grep
		echo CLIP_LEN `xclip -o -selection CLIPBOARD | wc -l`
	else
		while test -e "/proc/$LYX_PID/status" && ! grep 'S .sleeping.' "/proc/$LYX_PID/status"
		do
			sleep 0.1
		done
		if [ "$K" = END -a  ! -e "/proc/$LYX_PID/status" ]
		then
			cat "/proc/$LYX_PID/status"
			#exit 125 # Not good or bad, just ugly.
		fi
		xvkbd -xsendevent -text "$K"
	fi
	sleep 0.1
done
wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
wmctrl -R desktop; sleep 0.3
wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
#wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
#wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
#wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
#wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
#xvkbd -xsendevent -text '\Cs\D9\D9.\D9\D9c\D9\D9\Ad\D9\D9\D9s\D9\D9\Ac\D9\D9\AD\D9\D9\D9\D9\D9\[Escape]\D9\D9\[Escape]'
#sleep 2
sleep 3 ; kill $! ; sleep 3 ; kill -9 $!  &
cat $TMPFILE.err
#if grep "terminate called without an active exception" < $TMPFILE.err 
#then
#	exit 1
#else
#	exit 0
#fi
#exit 125 # Not good or bad, just ugly.
