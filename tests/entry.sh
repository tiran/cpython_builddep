#!/bin/sh
set -ex

SENTINEL=${SRC}/pyconfig.h.in

if ! test -e /cpython/pyconfig.h.in; then
    echo "/cpython/pyconfig.h.in missing" >&2
    exit 1
fi

cd /cpython
./configure -C
make -j4
