#!/bin/sh
set -e

BUILDDIR=/tmp/libffi-emscripten
DEST="${DEST:-/opt/libffi-emscripten}"

git clone --depth=1 https://github.com/hoodmane/libffi-emscripten.git ${BUILDDIR}

cd ${BUILDDIR}
./build.sh

mkdir ${DEST}
cp -r ${BUILDDIR}/target/include ${DEST}
cp -r ${BUILDDIR}/target/lib ${DEST}
sed -i "s,^prefix=.*,prefix=${DEST},g" ${DEST}/lib/pkgconfig/libffi.pc

rm -rf ${BUILDDIR}
