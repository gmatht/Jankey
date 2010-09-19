#!/bin/bash

BISECT_DIR=cache-bisect.dir
vers_fname="default_vers.txt"

PWD_=`pwd`
#BISECT_DIR=/var/cache/keytest/lyx-devel.cache

set -e

VER=`cd lyx && svn info | grep Revision: | sed s/Revision:.//`

echo .$VER.

if grep "^$VER$" $vers_fname
then
	echo $VER already in $vers_fname
	exit 0
fi

mkdir -p $BISECT_DIR/$VER/
echo RSYNCING 
echo rsync -a --progress --exclude '*.o' --exclude '*.lo' --exclude '*.emergency'  --exclude '#*#'  --exclude '~' --exclude 'Makefile' --exclude 'moc_*' --exclude '*.pyc' --exclude '*.gmo' --exclude '*.Po' --exclude 'ui_*.h' --exclude '*.a' --exclude '*.1' --exclude 'autom4te*' --exclude 'aclocal.m4' lyx/* lyx/.svn $BISECT_DIR/$VER/
rsync -a --progress --exclude '*.o' --exclude '*.lo' --exclude '*.emergency'  --exclude '#*#'  --exclude '~' --exclude 'Makefile' --exclude 'moc_*' --exclude '*.pyc' --exclude '*.gmo' --exclude '*.Po' --exclude 'ui_*.h' --exclude '*.a' --exclude '*.1' --exclude 'autom4te*' --exclude 'aclocal.m4' lyx/* lyx/.svn $BISECT_DIR/$VER/ || true
echo RSYNC DONE
echo cd  $BISECT_DIR/$VER/
(cd  $BISECT_DIR/$VER/ && echo cd success && echo test "$PWD_" != `pwd` && [ "$PWD_" != "`pwd`" ] && echo dir is new && (svn diff . > autopatch.patch || echo made patch) && svn revert -R . echo reverted) && echo $VER >> $vers_fname
echo REVERT DONE
exit 0
