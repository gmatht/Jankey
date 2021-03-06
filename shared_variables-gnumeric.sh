get_tmp_dir () {
	#tmpfs/tmp-$USER/$OUT_NAME
	echo tmpfs/$1/$2
}
if [ -z "$KT" ]
then
  DIRNAME0=`dirname "$0"`
else
  DIRNAME0="$KT"
fi
#OUT_NAME=out/branch_16_a/
. $DIRNAME0/local_keytest.rc
OUT_NAME=out/gnumeric_$OUT_COUNT/
#TMP_DIR=tmpfs/tmp-$USER/$OUT_NAME
TMP_DIR=`get_tmp_dir $USER $OUT_NAME`
LOG_FILE=$TMP_DIR/log
ROOT_OUTDIR="$DIRNAME0/$OUT_NAME"
WINDOWS_MANAGER="metacity"
#export LD_LIBRARY_PATH=abiword/src/.libs
export LD_LIBRARY_DIR=/usr/local/lib/

REPRODUCE_ANY=y 
EXE_NAME=gnumeric
LYX_WINDOW_NAME="Book1.gnumeric"
#GET_VERSION_COMMAND=$EXE_TO_TEST -version
GET_VERSION_COMMAND="echo unknown"
export LYX_WINDOW_NAME=K
export LYX_WINDOW_NAME=gnumeric
export RAISE_WINDOW_CMD="./focus -R '$LYX_WINDOW_NAME'"
export RAISE_WINDOW_CMD="wmctrl -R $LYX_WINDOW_NAME"
#export RAISE_WINDOW_CMD="true"
if [ -z $SRC_DIR ]
then 
        SRC_ROOT=gnumeric
	SRC_DIR=$SRC_ROOT/src
	#SRC_DIR=/mnt/sdb7/xp/src/svn2/lyx-1.6.x/src
fi
EXE_TO_TEST=/usr/local/bin/$EXE_NAME

if [ -e $EXE_TO_TEST ]
then
	EXE_TO_TEST=`readlink -f "$EXE_TO_TEST"` # softlinks can confuse "ps"
	echo EXE_TO_TEST $EXE_TO_TEST
else
	pwd
	echo EXE_TO_TEST $EXE_TO_TEST does not exist D
	#exit 1
fi

export BISECT_IN_PLACE="y"

SRC_ROOT=`pwd`/$SRC_ROOT
export SRC_ROOT
export EXE_NAME
#### fix below!!!
export MAKE_CMD='(export PATH=/mnt/big/keytest/path/bin:$PATH; pwd; sed -i.bak "s/fgets.buf,10,stdin.;/buf[0]='\'y\'';/" src/af/util/unix/ut_unixAssert.cpp || true ; ./autogen.sh && ./configure --enable-debug --prefix=`pwd`_bin && nice -19 make -j2 && nice -19 make install) | tee MAKE.LOG'
BUG_SEARCH_ENGINE="https://bugzilla.gnome.org/buglist.cgi?quicksearch="
BUG_REPORT_ENGINE="https://bugzilla.gnome.org/enter_bug.cgi?product=Gnumeric&version=GIT&short_desc=%s&commment=%s&JUNK=%s"

## Stuff to install: libgtk2.0-0-dbg libglib2.0-dbg
