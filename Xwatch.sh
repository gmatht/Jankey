#!/bin/sh
# This script is used to watch the contents of an alternate X window session 
# to watch :1 do use the following line.
#     Xwatch.sh 1
#
# Warnings:
#   - This may well cause the screen to flash. May not be appropriate for those with epilepsy.
#   - If you do not close the :1.png window it will spam [F5] to whatever window has focus.
#
# Notes:
#   - A pure white screen probably means that LyX isn't running.


#This only works with browsers that put the :$D.png in their title, e.g. not Konqueror
BROWSER="$(which google-chrome epiphany firefox | head -n1)"
D=$1
if [ -z "$D" ]
then
	D=1
fi

# Hack to get epiphany to work, epiphany won't display the :1.png unless the file exists
DISPLAY=:$D import -window root /tmp/:$D.png 

echo $BROWSER "file:///tmp/:$D.png"
$BROWSER "file:///tmp/:$D.png" &

while ! wmctrl -R :$D.png
do
	sleep 1
done

while wmctrl -l | grep :$D.png 
do
	DISPLAY=:$D import -window root /tmp/:$D.png 
	(wmctrl -l | grep :$D.png) && xvkbd -text '\[F5]'
	sleep 0.15
	echo -n .
done

exit

#The following might be useful in later version:
#<META HTTP-EQUIV=REFRESH CONTENT=5>

----------
<html>
<head>
<title>Auto Reload</title>
<script language="JavaScript">
<!--
var time = null
function move() {
window.location = 'http://yoursite.com'
}
//-->
</script>
</head>
<body onload="timer=setTimeout('move()',3000)">
<p>see this page refresh itself in 3 secs.<p>
</body>
