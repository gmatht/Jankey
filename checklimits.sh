#!/bin/bash

#This script watchs for keytest processes that are using too much memory.
#ulimit is not very useful, because processes can use huge amounts of virtual allocated but untouched memor without trouble.

MAX_RSS=512000 # Resource limit in KB.

checklimit () {
	_PID=$2
	_RSS=$6
	if [ "$_RSS" -gt "$MAX_RSS" ]
	then
		echo $_RSS gt $MAX_RSS KILLING:
		echo $@
		kill -SIGXCPU $_PID
		sleep 1
		kill -9 $_PID
	fi
}

while true
do
	ps ux | grep -v RSS |  while read f
	do
		checklimit $f
		killall firefox-bin
	done
	sleep 8
done
