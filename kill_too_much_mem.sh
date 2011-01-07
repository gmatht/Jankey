MAX_RSS=64000

handle_ps_line () {
	RSS="$6"
	pyPID="$2"
	if [ $RSS -gt $MAX_RSS ] 
	then 
		echo KILLING "$2" .. "$6"
		kill -sSIGXCPU "$2"
		sleep 1
		kill -9 "$2"
	fi
	
}
while true
do

ps u -u keytest  | grep python | while read l
do
	handle_ps_line $l
done

sleep 6
done
