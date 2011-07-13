
#Usage: (VERS="38262 38150" ./cache-bisect.sh 1 `pwd`/examples/Bench_Bisect_Memory.sh)
rm /tmp/lyx-$USER.txt.* || true
/mnt/big/keytest/examples/Benchmark.sh
#$KT/examples/Benchmark.sh
MEM=`cat /tmp/lyx-$USER.txt.time | grep -o ' [0-9]*maxresident' | grep -o '[0-9]*'`

if [ $MEM -gt 600000 ]
then 
	echo MEM 1 $MEM !!!Q
	exit 1
fi

if [ $MEM -gt 300000 ]
then 
	echo MEM 0 $MEM  !!!!
	exit 0
fi

echo MEM x $MEM !!!
exit 125 




