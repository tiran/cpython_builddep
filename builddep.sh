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
    echo ""
    echo "    -h --help     display this help and exit"
    echo "    --update      update all packages"
    echo "    --extras      install extra development packages (gdb, ccache...)"
    echo "    --cleanup     cleanup package cache"
    echo ""
}

OPT_DEBUG=no
OPT_UPDATE=no
OPT_EXTRAS=no
OPT_CLEANUP=no

while test -n "$1"; do
    case $1 in
        -h|--help)
            usage
            exit
            ;;
        -d|--debug)
            OPT_DEBUG=yes
            ;;
        --update)
            OPT_UPDATE=yes
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

if test "$OPT_DEBUG" = yes; then
    echo "sysname: ${SYSNAME}"
    if test -f /etc/os-release; then
        echo "os-release: ID=${ID}, ID_LIKE=${ID_LIKE}, VERSION_ID=${VERSION_ID}"
    fi
    echo ""
fi

# function
check_command() {
    command -v "$1" >/dev/null 2>&1
    return
}

# prepare environment, e.g. update package cache
PREPARE_CMD=
# update distro packages
UPDATE_CMD=
# install development packages
INSTALL_CMD=
# install additional development packages, used by CI
INSTALL_EXTRAS_CMD=
# cleanup, e.g. clear package cache
CLEANUP_CMD=

case "${SYSNAME}" in
  Darwin)
    # macOS platform
    if check_command brew; then
        # Homebrew
        INSTALL_CMD="brew install pkgconfig openssl@1.1 xz gdbm"
    elif check_command port; then
        INSTALL_CMD="port install pkgconfig openssl xz gdbm"
    else
        echo "Unsupported macOS installation, brew or port not detected." >&2
        exit 2
    fi
    ;;
  FreeBSD)
    INSTALL_CMD="pkg install -y \
        editline libffi lzma bzip2 gdbm openssl pkgconf sqlite3 tcl86 tk86"
    ;;
  Linux)
    if check_command apk; then
        # Alpine
        PREPARE_CMD="apk update"
        UPDATE_CMD="apk upgrade"
        INSTALL_CMD="apk add \
            build-base git \
            bzip2-dev gdbm-dev expat-dev libffi-dev libnsl-dev libtirpc-dev \
            ncurses-dev openssl-dev readline-dev sqlite-dev tcl-dev tk-dev \
            xz-dev zlib-dev"
    elif check_command pacman; then
        # Arch Linux
        PREPARE_CMD="pacman -Sy"
        UPDATE_CMD="pacman --noconfirm -Su"
        INSTALL_CMD="pacman --noconfirm -S \
            gcc make pkg-config bzip2 gdbm expat libffi ncurses openssl readline sqlite3 tk"
        CLEANUP_CMD="pacman -Scc --noconfirm"
    elif check_command apt; then
        # Debian, Ubuntu, and similar
        # apt build-deb requires deb-src entries in sources.list. They are not
        # present on user systems and there seems to be no apt command to enable
        # them.
        apt="env DEBIAN_FRONTEND=noninteractive apt --no-install-recommends -qy"
        PREPARE_CMD="${apt} update"
        UPDATE_CMD="${apt} upgrade"
        INSTALL_CMD="${apt} install \
            build-essential git pkg-config \
            libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
            libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
            lzma lzma-dev tk-dev uuid-dev zlib1g-dev"
        INSTALL_EXTRAS_CMD="${apt} install gdb lcov ccache"
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
        UPDATE_CMD="dnf update -y ${dnf_args}"
        INSTALL_CMD="dnf build-dep -y ${dnf_args} python3"
        INSTALL_EXTRAS_CMD="dnf install -y ${dnf_args} ${dnf_extras}"
        CLEANUP_CMD="dnf clean all"
    elif check_command yum; then
        # RHEL 7 and CentOS 7
        # to use openssl11 from EPEL:
        # yum install -y epel && yum install -y openssl11-devel
        # sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
        PREPARE_CMD="yum install -y yum-utils make"
        UPDATE_CMD="yum update -y"
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
        echo "Unsupported Linux platform ($PRETTY_NAME)" >&2
        exit 2
    fi
    # end of Linux block
    ;;
  *)
    echo "Unsupported system ${SYSNAME}" >&2
    exit 2
    ;;
esac

if test -n "$PREPARE_CMD"; then
    $PREPARE_CMD
fi

if test "$OPT_UPDATE" = "yes" -a -n "$UPDATE_CMD"; then
    $UPDATE_CMD
fi

$INSTALL_CMD

if test "$OPT_EXTRAS" = "yes" -a -n "$INSTALL_EXTRAS_CMD"; then
    $INSTALL_EXTRAS_CMD
fi

if test "$OPT_CLEANUP" = "yes" -a -n "$CLEANUP_CMD"; then
    $CLEANUP_CMD
fi
