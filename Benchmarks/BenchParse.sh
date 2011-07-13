grep < Benchmarks.out '8192=8192' | grep user | sed 's/8192=8192//g' | sed s/0avgtext+0avgdata\ // | sort -n | sed s/^/r/ | sed s/k.*//g
