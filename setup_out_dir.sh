#!/bin/bash
set -e

DIRNAME0=`dirname "$0"`
#OUT_NAME=out/branch_16_a/
. $DIRNAME0/shared_variables.sh

OUT_N=$(echo $OUT_NAME | sed s,/$,,)

mkshareddir() {
	for d in "$@"
	do
		mkdir "$d"
		chgrp keytest "$d"
		chmod 775 "$d"
	done
}



TT=$OUT_N.tmp

mkdir -p $TT
for r in final initial reproducible tasks tasks_done toreplay toreproduce
do
	mkshareddir $TT/$r
done

chgrp keytest "$TT"
chmod 775 "$TT"

mv $TT $OUT_N

