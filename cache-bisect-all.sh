export ANY_CRASH="y"
rm cache-bisect-all.log
for f in "$@" 
do
	echo S "$f" > cache-bisect-all.log
	./timeout3.sh -t 36000 -i 5 -d 20 ./cache-bisect.sh "$f"
	echo E "$f" > cache-bisect-all.log
done
