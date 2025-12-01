#!/bin/bash
cd $(dirname $0)
export PREVENT_LONG_RUN=1
for d in day*
do
    echo + $d
    make -C $d
done
