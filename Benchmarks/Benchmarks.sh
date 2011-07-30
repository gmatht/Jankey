#!/bin/bash
#rm Benchmarks.out

if [ -z "VERS" ]
then
	VERS="`cd lyx.cache ; echo 2???? 3????`"
fi

for v in $VERS
#for v in `cd lyx.cache ; echo 20010`
do
	#rm -rf Benchmark_copy_dir
	mkdir -p Benchmarks_copy_dir
	mv /tmp/lyx-$USER.txt.* Benchmarks_copy_dir/
	Benchmarks/Benchmark.sh lyx.cache/${v}_bin/bin/lyx
	#echo $v `tr '\n' ' ' < /tmp/lyx-$USER.txt.time` 8192=`grep asdf /tmp/lyx-$USER.txt.lyx | wc -l` >> Benchmarks.out
	echo $v `tr '\n' ' ' < /tmp/lyx-$USER.txt.time` 8192=`cat /tmp/lyx-$USER.txt.xclip | tr -d '\n'` >> Benchmarks.out
done #| tee Benchmarks.out
	
