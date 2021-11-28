#!/bin/sh

# fail on error
set -e

# trap and kill on CTRL+C
trap 'pkill -P $$; exit 255;' TERM INT

# for PYBUILDDEP_SRCDIR, PATH, CCACHE_DIR, MAKEFLAGS
# shellcheck source=./tests/activate
. ./activate

SENTINEL="${PYBUILDDEP_SRCDIR}/pyconfig.h.in"
if ! test -e "${SENTINEL}"; then
    echo "${SENTINEL} missing" >&2
    exit 1
fi

# use out-of-tree builds
BUILDDIR="${PYBUILDDEP_SRCDIR}/builddep/${PYBUILDDEP_DISTROTAG}-$(uname -m)"

mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"
"${PYBUILDDEP_SRCDIR}/configure" -C
make

BUILDHOST=$(${PYBUILDDEP_SRCDIR}/config.guess)
CROSSTARGET="aarch64-linux-gnu"
CROSSDIR="${PYBUILDDEP_SRCDIR}/builddep/${PYBUILDDEP_DISTROTAG}-${CROSSTARGET}"
CC=aarch64-linux-gnu-gcc

mkdir -p "${CROSSDIR}"
cd "${CROSSDIR}"
"${PYBUILDDEP_SRCDIR}/configure" -C \
    --host="${CROSSTARGET}" \
    --build="${BUILDHOST}" \
    PYTHON_FOR_BUILD="${BUILDDIR}/python" \
    CC="${CC}"

# XXX the env var should not be necessary
make \
    _PYTHON_HOST_PLATFORM="${CROSSTARGET}" \
    FREEZE_MODULE=${BUILDDIR}/Programs/_freeze_module

