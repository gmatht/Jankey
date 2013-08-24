#!/bin/bash
#This file is a wrapper round reproduce such that we 
export PATH=/usr/lib/ccache/:$PATH
export KT=$(readlink -f `dirname $0`)
export SRC_DIR=$KT/lyx.gitbisect
cd $SRC_DIR && git checkout po/
(./autogen.sh && ./configure && nice make -j3) || exit 125
#(test -e src/lyx || nice make -j3) || exit 125
#sudo -H -u "$BISECT_AS_USER" "$KT/doNtimes.sh" $count $KT/reproduce.sh "$@"
sudo -H -u "$BISECT_AS_USER" "$KT/doNtimes.sh" $count "$@"
