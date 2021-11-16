#!/bin/sh -l
# use login shell to load profiles and have ccache in PATH

# fail on error, show comands
set -ex

# trap and kill on CTRL+C
trap 'pkill -P $$; exit 255;' TERM INT

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

# export ccache dir
CCACHE_DIR="${SRCDIR}/builddep/.ccache"
mkdir -p "${CCACHE_DIR}"
export CCACHE_DIR

# use out-of-tree builds
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"
"${SRCDIR}/configure" -C
make
