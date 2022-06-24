#!/bin/sh
set -e

BUILDDIR=/tmp/libffi-emscripten
DESTDIR="${DEST:-/opt/libffi-emscripten}"

git clone --depth=1 -b 2022-06-23 https://github.com/hoodmane/libffi-emscripten.git ${BUILDDIR}

cd ${BUILDDIR}
./build.sh

if [ -d ${DESTDIR} ]; then
  rm -rf ${DESTDIR}
fi

mkdir ${DESTDIR}
cp -r ${BUILDDIR}/target/include ${DESTDIR}
cp -r ${BUILDDIR}/target/lib ${DESTDIR}
sed -i "s,^prefix=.*,prefix=${DESTDIR},g" ${DESTDIR}/lib/pkgconfig/libffi.pc

rm -rf ${BUILDDIR}
