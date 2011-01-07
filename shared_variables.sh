get_tmp_dir () {
	#tmpfs/tmp-$USER/$OUT_NAME
	echo tmpfs/$1/$2
}

DIRNAME0=`dirname "$0"`
#OUT_NAME=out/branch_16_a/
OUT_NAME=out/t11/
#TMP_DIR=tmpfs/tmp-$USER/$OUT_NAME
TMP_DIR=`get_tmp_dir $USER $OUT_NAME`
LOG_FILE=$TMP_DIR/log
ROOT_OUTDIR="$DIRNAME0/$OUT_NAME"
WINDOWS_MANAGER="metacity"
export LD_LIBRARY_PATH=abiword/src/.libs

EXE_NAME=abiword
LYX_WINDOW_NAME=lyx
#GET_VERSION_COMMAND=$EXE_TO_TEST -version
GET_VERSION_COMMAND="echo unknown"
export LYX_WINDOW_NAME=K
export LYX_WINDOW_NAME=abiword
export RAISE_WINDOW_CMD="./focus -R $LYX_WINDOW_NAME"
#export RAISE_WINDOW_CMD="true"
if [ -z $SRC_DIR ]
then 
	SRC_DIR=lyx/src
	SRC_DIR=.
        SRC_ROOT=abiword
	SRC_DIR=$SRC_ROOT/src
	#SRC_DIR=/mnt/sdb7/xp/src/svn2/lyx-1.6.x/src
fi
if [ -z $EXE_TO_TEST ]
then
	#EXE_TO_TEST=$SRC_DIR/lyx
	#EXE_TO_TEST=`which ksirk`
	#EXE_TO_TEST=/usr/games/ksirk
	#EXE_TO_TEST=$SRC_DIR/abiword 
	EXE_TO_TEST=$SRC_DIR/.libs/$EXE_NAME
fi

if [ -e $EXE_TO_TEST ]
then
	EXE_TO_TEST=`readlink -f "$EXE_TO_TEST"` # softlinks can confuse "ps"
	echo EXE_TO_TEST $EXE_TO_TEST
else
	echo EXE_TO_TEST $EXE_TO_TEST does not exist D
	exit 1
fi

SRC_ROOT=`pwd`/$SRC_ROOT
export SRC_ROOT
export EXE_NAME
export MAKE_CMD='(export PATH=/mnt/big/keytest/path/bin:$PATH; pwd; sed -i.bak "s/fgets.buf,10,stdin.;/buf[0]='\'y\'';/" src/af/util/unix/ut_unixAssert.cpp || true ; ./autogen.sh && ./configure --enable-debug --prefix=`pwd`_bin && nice -19 make -j2 && nice -19 make install) | tee MAKE.LOG'

