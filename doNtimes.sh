#!/bin/bash
#Attempts to reproduce a failure N times.
#It quits with the error code if a failure occurs
#If all N times succeed, it outputs 0 (success)

KT=`dirname "$0"`

. "$KT/shared_functions.sh"

N=$1
shift

echo doNtimes .$N. "$@"

MAX_UGLY=4

i=0
j=0
#for intr in `yes | head -n$N`
while [ "$i" -lt "$N" -a "$j" -lt "$MAX_UGLY" ] 
do
	#i=$(($i+1))
	echo 'TRY#' $i/$j '(Good/Ugly)'
	"$@"
	result=$?
	if [ "$result" -gt 0  ]
	then
		if [ "$result" -eq 125  ]
		then
			UGLY=True
			j=$(($j+1))
		else
			echo RESULT3: $result
			echo TRIES_REQUIRED: $i
			kill_all_children $$
			exit 1
		fi
	else
		SUCCESS=True
		i=$(($i+1))
		echo RESULT2: $result
	fi
done

kill_all_children $$
echo DONE $N TIMES
if [ -z "$SUCCESS" ] 
then
	exit 125
fi
exit 0 
