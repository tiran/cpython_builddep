#!/bin/sh
set -ex

cd /cpython
ls
./configure -C
make -j4
