#!/bin/sh
set -e

BUILDDIR=/tmp/wasix
DESTDIR="${DEST:-/opt/wasix}"

git clone -b main --depth=1 https://github.com/singlestore-labs/wasix.git ${BUILDDIR}

make -C ${BUILDDIR}
make -C ${BUILDDIR} install DESTDIR=${DESTDIR}

rm -rf ${BUILDDIR}
