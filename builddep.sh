#!/bin/sh
#
# Install CPython build and development dependencies
#
# Christian Heimes <christian@python.org>
#
set -e

# for ID, ID_LIKE, VERSION_ID, PRETTY_NAME
if test -f /etc/os-release; then
    . /etc/os-release
fi

# system name: Linux, FreeBSD, ...
SYSNAME=$(uname -s)

# function
usage() {
    echo "builddeps.sh - Install CPython build dependencies"
    echo "    -h --help     display this help and exit"
    echo "    --extras      install extra development packages"
    echo "    --cleanup     cleanup package cache"
    echo ""
}

OPT_EXTRAS=no
OPT_CLEANUP=no

while test -n "$1"; do
    case $1 in
        -h|--help)
            usage
            exit
            ;;
        --extras)
            OPT_EXTRAS=yes
            ;;
        --cleanup)
            OPT_CLEANUP=yes
            ;;
        *)
            echo "ERROR: unknown option \"$1\"" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

# function
check_command() {
    command -v "$1" >/dev/null 2>&1
    return
}

# prepare environment, e.g. update package cache
PREPARE_CMD=
# install development packages
INSTALL_CMD=
# install additional development packages, used by CI
INSTALL_EXTRAS_CMD=
# cleanup, e.g. clear package cache
CLEANUP_CMD=

if check_command apk; then
    # Alpine
    INSTALL_CMD="apk add \
        build-base git \
        bzip2-dev gdbm-dev expat-dev libffi-dev libnsl-dev libtirpc-dev \
        ncurses-dev openssl-dev readline-dev sqlite-dev tcl-dev tk-dev \
        xz-dev zlib-dev"
elif check_command pacman; then
    # Arch Linux
    PREPARE_CMD="pacman -Sy"
    INSTALL_CMD="pacman --noconfirm -S \
        gcc make pkg-config bzip2 gdbm expat libffi ncurses openssl readline sqlite3 tk"
    CLEANUP_CMD="pacman -Scc --noconfirm"
elif check_command apt; then
    # Debian, Ubuntu, and similar
    # apt build-deb requires deb-src entries in sources.list. They are not
    # present on user systems and there seems to be no apt command to enable
    # them.
    apt_install="env DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -qy"
    PREPARE_CMD="apt update"
    INSTALL_CMD="${apt_install} \
        build-essential git pkg-config \
        libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
        libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
        lzma lzma-dev tk-dev uuid-dev zlib1g-dev"
    INSTALL_EXTRAS_CMD="${apt_install} gdb lcov ccache"
    CLEANUP_CMD="apt clean"
elif check_command dnf; then
    # CentOS and RHEL need extra development packages from powertools
    # or Code Ready Builder repos.
    case "$ID" in
        centos)
            dnf_args="--enablerepo=powertools"
            dnf_extras="gdb"
            ;;
        rhel)
            dnf_args="--enablerepo=rhel-CRB"
            dnf_extras="gdb"
            ;;
        *)
            dnf_args=""
            dnf_extras="gdb ccache lcov"
            ;;
    esac
    # build-dep is provided by core plugins
    PREPARE_CMD="dnf install -y dnf-plugins-core"
    INSTALL_CMD="dnf build-dep -y ${dnf_args} python3"
    INSTALL_EXTRAS_CMD="dnf install -y ${dnf_args} ${dnf_extras}"
    CLEANUP_CMD="dnf clean all"
elif check_command yum; then
    # RHEL 7 and CentOS 7
    # to use openssl11 from EPEL:
    # yum install -y epel && yum install -e openssl11-devel
    # sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
    PREPARE_CMD="yum install -y yum-utils make"
    INSTALL_CMD="yum-builddep -y python3"
    INSTALL_EXTRAS_CMD="yum install -y lcov gdb ccache"
    CLEANUP_CMD="yum clean all"
elif check_command zypper; then
    INSTALL_CMD="zypper install -y \
        gcc make git pkg-config \
        libbz2-devel libffi-devel libnsl-devel libuuid-devel sqlite3-devel \
        gdbm-devel openssl-devel ncurses-devel readline-devel tk-devel \
        xz-devel zlib-devel"
    CLEANUP_CMD="zypper clean --all"
else
    echo "Unsupported or unknown platform ($SYSNAME, $PRETTY_NAME)" >&2
    exit 2
fi

$PREPARE_CMD

$INSTALL_CMD

if test "$OPT_EXTRAS" = "yes" -a -n "$INSTALL_EXTRAS_CMD"; then
    $INSTALL_EXTRAS_CMD
fi

if test "$OPT_CLEANUP" = "yes" -a -n "$CLEANUP_CMD"; then
    $CLEANUP_CMD
fi
