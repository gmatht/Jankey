#!/bin/bash
#rm Benchmarks.out
#for v in `cd lyx.cache ; echo 2???? 3????`
for v in `cd lyx.cache ; echo 3816?`
do
	rm /tmp/lyx-$USER.txt.*
	examples/Benchmark.sh lyx.cache/${v}_bin/bin/lyx
	echo $v `tr '\n' ' ' < /tmp/lyx-$USER.txt.time` 8192=`grep asdf /tmp/lyx-$USER.txt.lyx | wc -l` >> Benchmarks.out
done #| tee Benchmarks.out
	
