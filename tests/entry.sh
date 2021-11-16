#!/bin/sh
set -ex

SRCDIR=/cpython
SENTINEL="${SRCDIR}/pyconfig.h.in"

if ! test -e "${SENTINEL}"; then
    echo "${SENTINEL} missing" >&2
    exit 1
fi

if test -z "$PYBUILDDEP_DISTROTAG"; then
    echo "PYBUILDDEP_DISTROTAG not set" >&2
    exit 2
fi

BUILDDIR="${SRCDIR}/builddep/${PYBUILDDEP_DISTROTAG}"

case "$PYBUILDDEP_DISTROTAG" in
    centos-7|rhel-7)
        # no strict build, OpenSSL 1.1.1 missing
        ;;
    *)
        # fail on missing stdlib extension module
        export PYTHONSTRICTEXTENSIONBUILD=1
        ;;
esac

# use all CPU cores
MAKEFLAGS="-j$(nproc)"
export MAKEFLAGS

# use out-of-tree builds
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"
"${SRCDIR}/configure" -C
make clean
make
