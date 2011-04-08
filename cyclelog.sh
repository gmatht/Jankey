#!/bin/sh
while true; do dd bs=1 count=1024000 > "$1"; mv -f "$1" "$1".bak ; done
