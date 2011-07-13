for v in `cd lyx.cache ; echo 2???? 3????`
do
	examples/Benchmark.sh lyx.cache/$v_bin/bin/lyx
	echo $v `head -n1 /tmp/lyx-code.txt.err` 8192=`grep asdf /tmp/lyx-code.txt.lyx | wc -l`
done | tee Benchmarks.out
	
