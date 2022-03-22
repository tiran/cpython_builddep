#!/usr/bin/env bash
set -e

# https://github.com/WebAssembly/wasi-sdk
WASI_SDK=/opt/wasi-sdk
# https://github.com/singlestore-labs/wasix
WASIX_DIR=/opt/wasix

mkdir -p ${PYBUILDDEP_SRCDIR}/builddir/wasi
pushd ${PYBUILDDEP_SRCDIR}/builddir/wasi

PATH=${WASI_SDK}/bin:$PATH \
CC="${WASI_SDK}/bin/clang" \
LDSHARED="${WASI_SDK}/bin/wasm-ld" \
AR="${WASI_SDK}/bin/llvm-ar" \
CFLAGS="-isystem ${WASIX_DIR}/include" \
LDFLAGS="-L${WASIX_DIR}/lib -lwasix" \
CONFIG_SITE=../../Tools/wasm/config.site-wasm32-wasi \
  ../../configure -C \
    --host=wasm32-unknown-wasi \
    --build=$(../../config.guess) \
    --with-build-python=$(pwd)/../build/python \
    --disable-ipv6

make -j$(nproc)

popd
