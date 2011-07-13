#!/bin/bash
#rm Benchmarks.out
for v in `cd lyx.cache ; echo 2???? 3????`
#for v in `cd lyx.cache ; echo 30120 3{4,5,6,7,8,9}???`
do
	rm /tmp/lyx-code.txt.*
	examples/Benchmark.sh lyx.cache/${v}_bin/bin/lyx
	echo $v `tr '\n' ' ' < /tmp/lyx-code.txt.time` 8192=`grep asdf /tmp/lyx-code.txt.lyx | wc -l` >> Benchmarks.out
done #| tee Benchmarks.out
	
