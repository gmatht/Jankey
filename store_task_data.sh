#!/bin/bash
KT=`dirname "$0"`

task_tar_data () {
	(cd $KT
        tar -c $2 | gzip -9
	)
}

$KT ./shared_variables.sh
for F in $ROOT_OUTDIR/tasks/*.task
do
        task_tar_data `cat $F` > $F.data.tar.gz || true
done
