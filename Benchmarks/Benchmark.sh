#!/bin/bash
#
# Run as: 
# KT=/mnt/big/xp/images/share/Ubuntu904/keytest
# ( sudo -H -u keytest2 ./kt; DISPLAY=:3 xwininfo -root || nice -19 ./initXvfb 3; DISPLAY=:3 nice -19 ./cache-bisect.py sudo -H -u keytest2 $KT/doNtimes.sh 3 $KT/WrongLine.sh )  2>&1 | tee tmpfs/bisect4.log

TMPFILE=/tmp/lyx-$USER.txt
mkdir -p /tmp/bak-$USER
mv $TMPFILE*  /tmp/bak-$USER
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
pwd
echo "time -o $TMPFILE.time $EXE 2> $TMPFILE.err  &" #./WrongLine.sh.t2.lyx ./WrongLine.sh.t0.lyx &
rm $TMPFILE.lyx
rm $TMPFILE.lyx.emergency

/usr/bin/time -o $TMPFILE.time  $EXE $TMPFILE.lyx 2> $TMPFILE.err  &#./WrongLine.sh.t2.lyx ./WrongLine.sh.t0.lyx &
#valgrind --tool=massif $EXE $TMPFILE.lyx 2> $TMPFILE.err  &#./WrongLine.sh.t2.lyx ./WrongLine.sh.t0.lyx &
ps  -o pid,ppid
echo LYX_PID="ps  -o pid,ppid | grep \ $!\$  | sed s/\ .*//" # Get child of time process
LYX_PID=`ps  -o pid,ppid | grep \ $!  | sed s/\ .*//` # Get child of time process
echo .LYX_PID=$LYX_PID.
echo NO_CLIP | xclip 
i=0
while ! (wmctrl -R "LyX")
do
	i=$(($i+1))
	sleep 0.1
	echo -n w$i
	if [ "$i" -gt 1000 ]
	then
		kill $LYX_PID
		sleep 1
		kill -9 $LYX_PID
		exit
	fi
done
sleep 0.1
#for K in `echo '\Af n \Cs . . } \As RR \Ao RR \CD \[Escape] \Cq'`
#for K in `echo '\Cn \D9 \Ai \D9  n \D9  n \D9 nnn \D9 \[Right] asdf \D9 \r \r iadsf \Ca \Cc \Cv \Cv  \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc MEMINFO \Cq \Cs \Ad \Ad'`
#for K in `echo '\Ac \D1 \Ac \D9 \D9 \Ao \D1\Av\D10 \Ai n n nnn \[Right] asdf \r \r iadsf \Ao \Ca \D9 \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Ca \Ca \Cc \Cv \Cv \Ca \Cc \Cv \Cv \Cc MEMINFO \Cq \Cs \Ad \Ad'`
#for K in `echo '\Ac \D1 \Ac \D9 \D9 \Ao  \D1\Av\D101 \b \b \e \D1 a \D1 \Cm \D1  b \D9  \[Right] \[Right] c' ; for i in $(seq 1 8) ; do echo ' \Ca \Cc \Cv  \Cv ' ; done ; for i in $(seq 1 80) ; do echo -n ' \[Left] ' ; done ;  echo 'MEMINFO \S\C\[End] \Cc \Cq \Cs \Ad \Ad'`
for K in `echo '\Ac \D1 \Ac \D9 \D9 \Ao  \D1\Av\D101 \b \b \e \D1 a \D1 \Cm \D1  b \D9  \[Right] \[Right] ccc' ; for i in $(seq 1 8) ; do echo ' \Ca \Cc \Cv  \Cv ' ; done ; for i in $(seq 1 200) ; do echo -n ' \[Left] \[\Right] \[Left] \[Right] \[Right] ' ; done ;  echo 'MEMINFO \S\C\[End] \Cc \Cq \Cs \Ad \Ad'`
do
	if [ "$K" = RR ]
	then
		#wmctrl -R xp@xp
		wmctrl -R desktop

		wmctrl -R "LyX: "
	elif [ "$K" = MEMINFO ]
	then
		ps gaux | grep _bin/bin/lyx | grep -v grep
		echo CLIP_CONT `xclip -o -selection CLIPBOARD` | tee > $TMPFILE.xclipc
		echo CLIP_LEN `xclip -o -selection CLIPBOARD | wc` | tee > $TMPFILE.xclip
	else
		i=0
		while test -e "/proc/$LYX_PID/status" && ! grep 'S .sleeping.' "/proc/$LYX_PID/status"
		do
			echo -n s
			sleep 0.05

			i=$(($i+1))
			if [ "$i" -gt 1000 ]
			then
				kill $LYX_PID
				sleep 1
				kill -9 $LYX_PID
				exit
			fi

		done
		sleep 0.05

			

		if [ "$K" = END -a  ! -e "/proc/$LYX_PID/status" ]
		then
			cat "/proc/$LYX_PID/status"
			#exit 125 # Not good or bad, just ugly.
		fi

		if wmctrl -R "Document class not available"
		then
			xvkbd -xsendevent -text "\Ao"
		fi

		#xvkbd -xsendevent -text "$K"
		if echo "$K" | grep C
		then 
			echo -- xvkbd -xsendevent -text "$K"
			xvkbd -text "$K"
		else
			xvkbd -xsendevent -text "$K"
		fi
	fi
	sleep 0.1
done
wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
wmctrl -R desktop; sleep 0.3
wmctrl -R "LyX: Save" ;sleep 0.3; xvkbd -xsendevent -text '\Ad'; sleep 0.3
#xvkbd -xsendevent -text '\Cs\D9\D9.\D9\D9c\D9\D9\Ad\D9\D9\D9s\D9\D9\Ac\D9\D9\AD\D9\D9\D9\D9\D9\[Escape]\D9\D9\[Escape]'
#sleep 2
sleep 0.3
kill $LYX_PID
sleep 0.3
kill -9 $LYX_PID
sleep 0.3 ; kill $! ; sleep 0.3 ; kill -9 $!  &
cat $TMPFILE.err
#exit 125 # Not good or bad, just ugly.
