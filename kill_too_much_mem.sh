MAX_RSS=164000

handle_ps_line () {
	RSS="$6"
	pyPID="$2"
	if [ $RSS -gt $MAX_RSS ] 
	then 
	#	echo KILLING "$2" .. "$6"
		#kill -s XCPU "$2"
		kill "$2"
		sleep 1
		kill -9 "$2"
	fi
	
}
while true
do

ps u -u keytest  | egrep '(python|firefox|gnome-help|yelp|evolution)' | while read l
do
	handle_ps_line $l
done
#echo don#e
sleep 6
done
