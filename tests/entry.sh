#!/bin/sh

# entrypoint
# - add compiler cache to PATH
# - set compiler cache directory
# - set make flags to run parallel jobs

# Include ccache
for ccache_dir in /usr/lib/ccache/bin /usr/lib/ccache /usr/lib64/ccache; do
    if test -e ${ccache_dir}/gcc; then
        PATH="${ccache_dir}:${PATH}"
        break
    fi
done
export PATH

# export ccache dir
if test -z "$CCACHE_DIR"; then
    CCACHE_DIR="${PYBUILDDEP_SRCDIR}/builddir/.ccache"
fi
mkdir -p "${CCACHE_DIR}"
export CCACHE_DIR

# use all CPU cores
MAKEFLAGS="-j$(nproc)"
export MAKEFLAGS

exec "$@"
