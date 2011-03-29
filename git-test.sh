#!/bin/sh
#ccmake || exit 125                     # this skips broken builds
PATH=/usr/lib/ccache/:$PATH ~/bin/myconfigure                     # this skips broken builds
PATH=/usr/lib/ccache/:$PATH nice -19 make -j2 || exit 125                     # this skips broken builds
# -19 make "$@" -j2 || exit 125                     # this skips broken builds
export KT=/home/john_large/src/keytest
$KT/reproduce.sh "$@"
