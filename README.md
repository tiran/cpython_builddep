# CPython build dependencies

Install CPython build and development dependencies on various distributions.

## Usage

```
$ ./builddep.sh --help
builddeps.sh - Install CPython build dependencies

    -h --help     display this help and exit
    --extras      install extra development packages (gdb, ccache...)
    --update      update all packages
    --cleanup     cleanup package cache

```

Install build dependencies:
```
sudo ./builddep.sh
```

Also install extra dependencies and purge the package cache afterwards
```
sudo ./builddep.sh --extras --cleanup
```

## Supported distros

* Alpine
* ArchLinux
* CentOS
* Debian
* Fedora
* RHEL
* Ubuntu

### Note

CentOS 7 and RHEL 7 ship an unsupported OpenSSL version. CentOS 7's EPEL
repository comes with ``openssl11`` package. The package install files in
non-standard locations and uses a custom pkgconf module name ``openssl11``.
You can patch Python's ``configure`` script to use the custom build:

```
sudo yum install -y epel
sudo yum install -y openssl11-devel
```

```
cd /path/to/cpython-sources
sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
```

## Unsupported or untested distributions

* FreeBSD
* Gentoo
* macOS brew
* SUSE

## Build containers

Containers are hosted at https://quay.io/repository/tiran/cpythonbuild

* quay.io/tiran/cpythonbuild:alpine-3.13 (linux/amd64, linux/arm64, linux/s390x)
* quay.io/tiran/cpythonbuild:alpine-3.16 (linux/amd64, linux/arm/v7, linux/arm64/v8, linux/s390x, linux/ppc64le)
* quay.io/tiran/cpythonbuild:archlinux (linux/amd64)
* quay.io/tiran/cpythonbuild:centos-7 (linux/amd64, linux/arm64)
* quay.io/tiran/cpythonbuild:centos-stream8 (linux/amd64, linux/arm64, linux/ppc64le)
* quay.io/tiran/cpythonbuild:centos-stream9 (linux/amd64)
* quay.io/tiran/cpythonbuild:debian-bullseye (linux/amd64, linux/arm/v7, linux/arm64/v8, linux/s390x, linux/ppc64le, linux/mips64le)
* quay.io/tiran/cpythonbuild:debian-testing (linux/amd64, linux/arm64, linux/s390x)
* quay.io/tiran/cpythonbuild:fedora-35 (linux/amd64, linux/s390x)
* quay.io/tiran/cpythonbuild:fedora-36 (linux/amd64, linux/ppc64le, linux/arm64)
* quay.io/tiran/cpythonbuild:ubuntu-focal (linux/amd64, linux/arm64, linux/s390x)
* quay.io/tiran/cpythonbuild:ubuntu-jammy (linux/amd64, linux/arm64, linux/s390x)
* quay.io/tiran/cpythonbuild:emsdk3 (linux/amd64)

### Usage

The default entry point of a build container runs ``configure -C``,
``make clean``, and parallel out-of-tree ``make`` in ``builddep/$tag``. The
default entry script also sets up ``CCACHE_DIR=/cpython/builddir/.ccache``.

```
cd cpython
```

```
podman run -ti --rm -v $(pwd):/cpython:Z quay.io/tiran/cpythonbuild:fedora-35
```

```
docker run -ti --rm -v $(pwd):/cpython quay.io/tiran/cpythonbuild:fedora-35
```

### Emulated archs

Needs ``qemu-user-static`` package and ``binfmt`` support. Emulation is rather slow.

```
podman run --platform linux/s390x -ti --rm -v .:/cpython:Z quay.io/tiran/cpythonbuild:fedora-35
```

## WebAssembly build

The WebAssembly container image is based on latest Emscripten SDK 3 (emsdk),
which is based on Ubuntu 20.04 LTS. It comes with all CPython build
dependencies, [Emscripten](https://emscripten.org/) SDK,
[WASI SDK](https://github.com/WebAssembly/wasi-sdk),
[wasmtime](https://wasmtime.dev/) runtime, and
[python-wasm](https://github.com/ethanhs/python-wasm) build scripts. `zlib`
and `bzip2` emports are pre-built.

```
podman run -ti --rm -v $(pwd):/python-wasm/cpython:Z quay.io/tiran/cpythonbuild:emsdk3
```

The ``emsdk3-mini`` is smaller and comes without WASI and additional build dependencies.

```
./build-python-build.sh
./build-python-emscripten-node.sh
./build-python-emscripten-browser.sh
./build-python-wasi.sh
```
