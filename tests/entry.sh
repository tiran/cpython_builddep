#!/bin/sh

# entrypoint
# - add compiler cache to PATH
# - set compiler cache directory
# - set make flags to run parallel jobs

PYBUILDDEP_SRCDIR=/cpython

# Include ccache
for ccache_dir in /usr/lib/ccache/bin /usr/lib/ccache /usr/lib64/ccache; do
    if test -e ${ccache_dir}/gcc; then
        PATH="${ccache_dir}:${PATH}"
        break
    fi
done
export PATH

# export ccache dir
CCACHE_DIR="${PYBUILDDEP_SRCDIR}/builddep/.ccache"
mkdir -p "${CCACHE_DIR}"
export CCACHE_DIR

# use all CPU cores
MAKEFLAGS="-j$(nproc)"
export MAKEFLAGS

exec "$@"
