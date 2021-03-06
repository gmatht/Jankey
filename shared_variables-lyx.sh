get_tmp_dir () {
	#tmpfs/tmp-$USER/$OUT_NAME
	echo tmpfs/$1/$2
}

DIRNAME0=`dirname "$0"`
#OUT_NAME=out/branch_16_a/
. $DIRNAME0/local_keytest.rc
OUT_NAME=out/t$OUT_COUNT/
TMP_DIR=`get_tmp_dir $USER $OUT_NAME`
LOG_FILE=$TMP_DIR/log
ROOT_OUTDIR="$DIRNAME0/$OUT_NAME"
WINDOWS_MANAGER="metacity"
#export LD_LIBRARY_PATH=abiword/src/.libs

#EXE_TO_TEST_ARGS="-dbg any"

EXE_NAME=lyx
LYX_WINDOW_NAME=lyx
#export RAISE_WINDOW_CMD="./focus -R $LYX_WINDOW_NAME"
export RAISE_WINDOW_CMD="wmctrl -R $LYX_WINDOW_NAME"
echo SRC $SRC_DIR
if [ -z "$SRC_ROOT" ] 
then
	SRC_ROOT=/mnt/big/keytest/lyx
fi

if [ -z "$SRC_DIR" ]
then
	#SRC_DIR=lyx/src
	SRC_DIR=$SRC_ROOT/src
fi
if [ -z $EXE_TO_TEST ]
then
	EXE_TO_TEST=$SRC_DIR/lyx
fi

#if [ -e $EXE_TO_TEST ]
#then
#	EXE_TO_TEST=`readlink -f "$EXE_TO_TEST"` # softlinks can confuse "ps"
#	echo EXE_TO_TEST $EXE_TO_TEST
#else
#	echo EXE_TO_TEST $EXE_TO_TEST does not exist D
#	exit 1
#fi

GET_VERSION_COMMAND="$EXE_TO_TEST -version"
#SRC_ROOT=`pwd`/$SRC_ROOT
#SRC_ROOT=/var/cache/keytest/lyx-devel
#SRC_ROOT=/mnt/big/keytest/lyx.gitbisect
export SRC_ROOT
export EXE_NAME
export KEYTEST_HARDCODE=LYX
export IS_BUILT_SUFFIX="_bin/share/lyx/chkconfig.ltx" 

export MAKE_CMD='(make distclean ; make clean ; rm -r autom4te.cache ; rm aclocal.m4 ;  export PATH=/usr/lib/ccache/:/mnt/big/keytest/path/bin:$PATH && sed -i.bak s/0-[34]/0-5/ ./autogen.sh && ./autogen.sh && CXX=g++-4.2 CC=gcc-4.2 CXXFLAGS=-Os CFLAGS=-Os ./configure --enable-debug --prefix=`pwd`_bin && nice -19 make -j2 && nice -19 make install) | tee MAKE.LOG'

##Used only by report_html
BUG_SEARCH_ENGINE='http://www.lyx.org/trac/search?q='
BUG_REPORT_ENGINE="http://www.lyx.org/trac/newticket?summary=%s&description=%s&version=%s"
