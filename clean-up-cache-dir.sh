
do_clean () {
	if [ $(($ver-$lastver)) -lt $TOO_CLOSE -a ! -e $ver.multisect ]
	then
		echo REMOVE: $ver
		ionice -c 3 nice -19 rm -rf $ver $ver'_bin'
		df  $CACHE_DIR
		df -h $CACHE_DIR
	else
		echo KEEP: $ver
		lastver=$ver
	fi
}


CACHE_DIR=/var/cache/keytest/lyx-devel.cache
cd $CACHE_DIR
lastver=0
df $CACHE_DIR
df -h $CACHE_DIR
TOO_CLOSE=199
for ver in 2????
do
	do_clean
done

TOO_CLOSE=59
for ver in 3????
do
	do_clean
done
#exit

df $CACHE_DIR
df -h $CACHE_DIR

for f in *_bin ; do if [ -d `echo "$f" | sed s/_.*//g` ] ; then echo keep "$f" ; else echo remove "$f" && rm -rf "$f" ; fi ; done

df  $CACHE_DIR
df -h $CACHE_DIR
