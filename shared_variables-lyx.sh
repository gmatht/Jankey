get_tmp_dir () {
	#tmpfs/tmp-$USER/$OUT_NAME
	echo tmpfs/$1/$2
}

DIRNAME0=`dirname "$0"`
#OUT_NAME=out/branch_16_a/
OUT_NAME=out/t12/
TMP_DIR=`get_tmp_dir $USER $OUT_NAME`
LOG_FILE=$TMP_DIR/log
ROOT_OUTDIR="$DIRNAME0/$OUT_NAME"
WINDOWS_MANAGER="metacity"
export LD_LIBRARY_PATH=abiword/src/.libs

EXE_NAME=lyx
LYX_WINDOW_NAME=lyx
GET_VERSION_COMMAND=$EXE_TO_TEST -version
export RAISE_WINDOW_CMD="./focus -R $LYX_WINDOW_NAME"
if [ -z $SRC_DIR ]
then 
	SRC_DIR=lyx/src
fi
if [ -z $EXE_TO_TEST ]
then
	EXE_TO_TEST=$SRC_DIR/lyx
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
export KEYTEST_HARDCODE=LYX
export IS_BUILT_SUFFIX="_bin/share/lyx/chkconfig.ltx" 

MAKE_CMD=FIXEME
