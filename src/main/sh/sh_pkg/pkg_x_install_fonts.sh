#!/bin/sh

## pkg_x_install_fonts.sh - Install a small number of fonts
##
##
## usage e.g
##
##   pkg_x_install_fonts.sh
##
## alternately [Indemnification Clause Here]
##
##   pkg_x_install_fonts.sh NO_CHECKSUM=yes
##
##
## TBD/FIXME
## - Font pkg linting
## - Font path integration for pkg/host window system - x.org, mingw,
##   android apk, ...

set -e

## TBD/Linting - fonts/noto-hinted-ttf => distfile size is 477M+ (??)

CATEG=fonts

## configure the shell script environment for local pkgsrc builds
PREFIX=${LOCALBASE:-${PREFIX:-${PKGSRC_PREFIX:-/usr/pkg}}}
[ -e "${PREFIX}/etc/bashrc_pkg.sh" ] && . "${PREFIX}/etc/bashrc_pkg.sh"

PKGSRCDIR=${PKGSRCDIR:-/usr/pkgsrc}

## ...


MK_TGTS=${MK_TGTS:-checksum package install clean}

for F in ms \
		liberation \
		inconsolata \
		go \
		geoslab703 \
		gentium \
		freefont \
		font-bh \
		dejavu \
		consolamono \
		TextFonts; do

    NAME=${F}-ttf

    echo "#-- ${NAME}"

    PORT_PATH=${PKGSRCDIR}/${CATEG}/${NAME}

    PKGNAME=$(bmake \
                   -C ${PORT_PATH} -D.MAKE.EXPAND_VARIABLES -V PKGNAME ||
                   exit)

    if pkg_info -e ${PKGNAME} > /dev/null; then
        echo "#-- ... already installed"
    else
      ${MAKE:-bmake} -C ${PORT_PATH} \
                     ${MK_TGTS} "$@" || break
    fi

done
