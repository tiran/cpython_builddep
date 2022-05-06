#!/bin/sh
set -e

BUILDDIR=/tmp/wasix
DEST="${DEST:-/opt/wasix}"

git clone --depth=1 https://github.com/singlestore-labs/wasix.git ${BUILDDIR}

make -C ${BUILDDIR}

mkdir -p ${DEST}/include ${DEST}/lib
cp -R ${BUILDDIR}/include/* ${DEST}/include/
cp ${BUILDDIR}/libwasix.a ${DEST}/lib/

rm -rf ${BUILDDIR}