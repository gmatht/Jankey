#!/bin/bash
#
# This command makes all files in "$ROOT_OUTDIR" writable by keytest.
#
# This command is useful if you run keytest under a seperate user "keytest" of group "keytest" 
. ./shared_variables.sh
mkdir -p $ROOT_OUTDIR
find  $ROOT_OUTDIR tmpfs | egrep -v  '(pure|GDB|gz)$' | while read f ; do chmod g+rw $f ; chgrp keytest $f ;done
find  $ROOT_OUTDIR | egrep '(pure|GDB|gz)$' | while read f ; do chmod 644 $f ; chgrp keytest $f ;done
