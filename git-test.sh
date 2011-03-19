#!/bin/sh
ccmake || exit 125                     # this skips broken builds
$KT/reproduce.sh "$@"
