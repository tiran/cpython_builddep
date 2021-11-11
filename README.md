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

* Alpine (3.12, 3.13)
* ArchLinux
* CentOS (7, 8)
* Debian (10, 11, testing)
* Fedora (32+)
* RHEL (7, 8)
* SUSE (untested)
* Ubuntu (18.04, 20.4+)

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
