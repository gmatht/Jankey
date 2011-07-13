maxver=$1

export VERS=`echo -n "$maxver "
cat  default_vers.txt | sort -r | while read l
do
	if [ $l -lt $maxver ]
	then
		echo -n "$l "
	fi
done`

echo $VERS
shift
./cache-bisect.sh "$@"
