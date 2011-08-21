#!/bin/bash
# This is meant to be a collection of useful short commands, so that I
# Can stop adding hundreds of random shell scripts into this directory

if [ -z "$KT" ]
then
	KT=`dirname $0`
fi

export KT



case "$1" in 
testA)
	echo test_A
;;
testB)
	echo test B
;;
#add_autokill_crontab_to1)
	#set -x
	#KT=`cat ~keytest/KT.dir.tmp`
	#echo .. $@
	#grep autokill.sh "$2" || echo '35 * * * * '$KT/autokill.sh  >> "$2"
	#cat "$2"
	#touch "$2"
	#echo END
#;;
add_autokill_crontab)
	. $KT/shared_functions.sh
	#absname "$KT" > ~keytest/KT.dir.tmp
	#THIS_COMMAND=`absname $0`
	
	#(VISUAL="$THIS_COMMAND add_autokill_crontab_to1" crontab -e -u keytest)
	crontab -l | grep autokill ||
		(
			#Crontab -e is really buggy, so instead use 
			#   crontab -l | crontab -
			# Note crontab -l is rather nasty without debian specific fixes, as it will repeat the header
			# but I guess it will work ...
			( ( crontab -l ; echo  '35 * * * * '`absname $KT`/autokill.sh ) | crontab - )
		)
;;
*)
	echo Unknown Command "$1"
esac

