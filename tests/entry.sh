#!/bin/sh
set -ex

cd /cpython
./configure -C
make -j4
