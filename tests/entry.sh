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

if test -z "$PYBUILDDEP_DISTROTAG"; then
    echo "PYBUILDDEP_DISTROTAG not set" >&2
    exit 2
fi

case "$PYBUILDDEP_DISTROTAG" in
    centos-7|rhel-7)
        # no strict build, OpenSSL 1.1.1 missing
        ;;
    *)
        # fail on missing stdlib extension module
        export PYTHONSTRICTEXTENSIONBUILD=1
        ;;
esac

# use out-of-tree builds
BUILDDIR="${PYBUILDDEP_SRCDIR}/builddep/${PYBUILDDEP_DISTROTAG}-$(uname -m)"

mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

"${PYBUILDDEP_SRCDIR}/configure" -C
make
