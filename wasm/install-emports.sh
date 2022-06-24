#!/bin/sh
set -e

# install extra emscripten ports
embuilder build MINIMAL_PIC
embuilder build zlib bzip2

# rebuild for shared extensions
embuilder build --pic MINIMAL_PIC
embuilder build --pic zlib bzip2

# ws / websocket is required for socket support
npm install --prefix /root ws websocket
ln -rs /root/node_modules /root/.node_modules
