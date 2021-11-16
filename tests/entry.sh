#!/bin/sh
set -ex

SENTINEL=${SRC}/pyconfig.h.in

if ! test -e /cpython/pyconfig.h.in; then
    echo "/cpython/pyconfig.h.in missing" >&2
    exit 1
fi

case "$PYBUILDDEP_DISTRO" in
    centos:7|rhel:7)
        # OpenSSL 1.1.1 missing
        ;;
    *)
        # fail on missing stdlib extension module
        export PYTHONSTRICTEXTENSIONBUILD=1
        ;;
esac

cd /cpython
./configure -C
make -j4
