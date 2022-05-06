#!/bin/sh
set -e

# install extra emscripten ports
embuilder build zlib bzip2

# rebuild for shared extensions
embuilder build --pic zlib bzip2 libc-mt libdlmalloc-mt libsockets-mt \
    libstubs libcompiler_rt libcompiler_rt-mt crtbegin libhtml5 \
    libc++-mt-noexcept libc++abi-mt-noexcept \
    libal libGL-mt libstubs-debug libc-mt-debug

# ws / websocket is required for socket support
npm install --prefix /root ws websocket
ln -rs /root/node_modules /root/.node_modules
