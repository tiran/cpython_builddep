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
    echo "    --extras      install extra development packages"
    echo "                  (ccache, lcov, Python for bootstrapping, ...)"
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

PKG_MGR=

case "${SYSNAME}" in
    Darwin)
        # macOS platform
        if check_command brew; then
            # Homebrew
            PKG_MGR="${SYSNAME}-brew"
        elif check_command port; then
            # port
            PKG_MGR="${SYSNAME}-port"
        fi
        ;;
    FreeBSD)
        PKG_MGR="${SYSNAME}-pkg"
        ;;
    Linux)
        case "$ID $ID_LIKE" in
            alpine*)
                if check_command apk; then
                    PKG_MGR="${SYSNAME}-apk"
                fi
                ;;
            arch*)
                if check_command pacman; then
                    PKG_MGR="${SYSNAME}-pacman"
                fi
                ;;
            *debian* | *ubuntu*)
                if check_command apt; then
                    # Debian, Ubuntu, Mint, Raspbian
                    PKG_MGR="${SYSNAME}-apt"
                fi
                ;;
            *fedora*)
                if check_command dnf; then
                    # Fedora, CentOS 8+, RHEL 8+
                    PKG_MGR="${SYSNAME}-dnf"
                elif check_command yum; then
                    # RHEL 7 and CentOS 7
                    PKG_MGR="${SYSNAME}-yum"
                fi
                ;;
            *suse*)
                if check_command zypper; then
                    PKG_MGR="${SYSNAME}-zypper"
                fi
                ;;
        esac
        ;;
    *)
        ;;
esac

if test "$OPT_DEBUG" = yes; then
    echo "package manager: ${PKG_MGR}"
    echo ""
fi

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

case "$PKG_MGR" in
    Darwin-brew)
        # macOS Homebrew
        INSTALL_CMD="brew install pkgconfig openssl@1.1 xz gdbm"
        ;;
    Darwin-port)
        INSTALL_CMD="port install pkgconfig openssl xz gdbm"
        ;;
    FreeBSD-pkg)
        INSTALL_CMD="pkg install -y \
            editline libffi lzma bzip2 gdbm openssl pkgconf sqlite3 tcl86 tk86"
        INSTALL_EXTRAS_CMD="pkg install -y python3"
        ;;
    Linux-apk)
        # Alpine
        PREPARE_CMD="apk update"
        UPDATE_CMD="apk upgrade"
        INSTALL_CMD="apk add \
            build-base git \
            bzip2-dev gdbm-dev expat-dev libffi-dev libnsl-dev libtirpc-dev \
            ncurses-dev openssl-dev readline-dev sqlite-dev tcl-dev tk-dev \
            xz-dev zlib-dev"
        INSTALL_EXTRAS_CMD="apk add ccache gdb python3"
        ;;
    Linux-pacman)
        # Arch Linux
        PREPARE_CMD="pacman -Sy"
        UPDATE_CMD="pacman --noconfirm -Su"
        INSTALL_CMD="pacman --noconfirm -S \
            gcc make pkg-config bzip2 gdbm expat libffi ncurses openssl \
            readline sqlite3 tk"
        INSTALL_EXTRAS_CMD="pacman --noconfirm -S python"
        CLEANUP_CMD="pacman -Scc --noconfirm"
        ;;
    Linux-apt)
        # Debian, Ubuntu, and similar
        # apt build-deb requires deb-src entries in sources.list. They are not
        # present on user systems and there seems to be no apt command to enable
        # them.
        apt="env DEBIAN_FRONTEND=noninteractive apt --no-install-recommends -qy"
        PREPARE_CMD="${apt} update"
        UPDATE_CMD="${apt} upgrade"
        INSTALL_CMD="${apt} install \
            build-essential git pkg-config procps \
            libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
            libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
            lzma lzma-dev tk-dev uuid-dev zlib1g-dev"
        INSTALL_EXTRAS_CMD="${apt} install gdb lcov ccache python3"
        CLEANUP_CMD="apt clean"
        ;;
    Linux-dnf)
        # CentOS and RHEL need extra development packages from powertools
        # or Code Ready Builder repos.
        case "$ID" in
            centos)
                dnf_args="--enablerepo=powertools"
                INSTALL_EXTRAS_CMD="dnf install -y epel-release && \
                    dnf install -y ccache gdb python3"
                ;;
            rhel)
                dnf_args="--enablerepo=rhel-CRB"
                INSTALL_EXTRAS_CMD="dnf install -y gdb python3"
                ;;
            *)
                dnf_args=""
                INSTALL_EXTRAS_CMD="dnf install -y gdb ccache lcov python3"
                ;;
        esac
        # PREPARE_CMD="dnf install -y dnf-plugins-core"
        UPDATE_CMD="dnf update -y ${dnf_args}"
        # "dnf build-dep python3" installs large deps like valgrind and systemd
        INSTALL_CMD="dnf install -y ${dnf_args} \
            gcc make pkgconfig git-core tzdata procps-ng \
            bluez-libs-devel bzip2-devel expat-devel gdbm-devel libffi-devel \
            libnsl2-devel libuuid-devel ncurses-devel openssl-devel \
            readline-devel sqlite-devel tcl-devel tk-devel xz-devel \
            zlib-devel"
        CLEANUP_CMD="dnf clean all"
        ;;
    Linux-yum)
        # RHEL 7 and CentOS 7
        # to use openssl11 from EPEL:
        # yum install -y epel && yum install -y openssl11-devel
        # sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
        yum="yum --setopt=skip_missing_names_on_install=False"
        PREPARE_CMD="${yum} install -y yum-utils make procps-ng"
        UPDATE_CMD="${yum} update -y"
        INSTALL_CMD="yum-builddep -y python3"
        INSTALL_EXTRAS_CMD="${yum} install -y epel-release && \
            ${yum} install -y lcov gdb ccache python3"
        CLEANUP_CMD="yum clean all"
        ;;
    Linux-zypper)
        INSTALL_CMD="zypper install -y \
            gcc make git pkg-config \
            libbz2-devel libffi-devel libnsl-devel libuuid-devel sqlite3-devel \
            gdbm-devel openssl-devel ncurses-devel readline-devel tk-devel \
            xz-devel zlib-devel"
        INSTALL_EXTRAS_CMD="zypper install -y python3"
        CLEANUP_CMD="zypper clean --all"
        ;;
    *)
        echo "ERROR: unsupported platform ${SYSNAME} ${PRETTY_NAME}" >&2
        exit 2
        ;;
esac

#function
eval_cmd() {
    if test "$OPT_DEBUG" = yes; then
        echo "$@"
        echo ""
    fi
    eval "$@"
}

if test -n "$PREPARE_CMD"; then
    eval_cmd "$PREPARE_CMD"
fi

# exit

if test "$OPT_UPDATE" = "yes" -a -n "$UPDATE_CMD"; then
    eval_cmd "$UPDATE_CMD"
fi

eval_cmd "$INSTALL_CMD"

if test "$OPT_EXTRAS" = "yes" -a -n "$INSTALL_EXTRAS_CMD"; then
    eval_cmd "$INSTALL_EXTRAS_CMD"
fi

if test "$OPT_CLEANUP" = "yes" -a -n "$CLEANUP_CMD"; then
    eval_cmd "$CLEANUP_CMD"
fi
