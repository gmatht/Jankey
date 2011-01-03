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
if [ -z $SRC_DIR ]
then 
	SRC_DIR=lyx/src
	#SRC_DIR=/mnt/sdb7/xp/src/svn2/lyx-1.6.x/src
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
