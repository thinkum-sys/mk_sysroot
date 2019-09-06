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
##   pkg_x_install_fonts.sh NO_CHECKSUM=yes HOST_TOOLCHAIN=clang
##
##
## TBD/FIXME
## - Font pkg linting
## - Font path integration for pkg/host window system - x.org, mingw,
##   android apk, ...

set -e

## NB:: fonts/noto-hinted-ttf => distfile file is 477M+ ?

CATEG=fonts

LOCALBASE=${LOCALBASE:-/usr/pkgsrc}

MK_TGTS=${MK_TGTS:-checksum package install}

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

    PORT_PATH=${LOCALBASE}/${CATEG}/${NAME}

    DISTNAME=$(bmake \
                   -C ${PORT_PATH} -D.MAKE.EXPAND_VARIABLES -V DISTNAME ||
                   exit)

    if pkg_info -c ${DISTNAME}; then
        echo "#-- ... already installed"
    else
      ${MAKE:-bmake} -C ${PORT_PATH} \
                     ${MK_TGTS} "$@" || break
    fi

done
