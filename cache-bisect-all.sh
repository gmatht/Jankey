export ANY_CRASH="y"
for f in "$@" 
do
	./timeout3.sh -t 36000 -i 5 -d 20 ./cache-bisect.sh "$f"
done
