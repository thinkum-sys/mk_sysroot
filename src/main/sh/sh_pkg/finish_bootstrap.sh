#!/bin/sh

## Trival post-bootstrap script for a pkg filesystem w/ pkgsrc
##
## NB - Usage
##
## - To be run within an environment configured for a bootstrapped
##   pkg filesystem
##
## - Reentrant with regards to existing bootstrap
##
## - Will overwrite all FINISH_BOOTSTRAP_PKGS with newly built bootstrap
##   pkgs
##
## - Do not add bmake to FINISH_BOOTSTRAP_PKGS
##

PKG_CC='clang-7'
PKG_CXX='clang++-7'
PKG_CPP='clang-cpp-7'
PKG_LD='ld.lld-7'
HOST_TOOLCHAIN=clang

LOCALBASE=${PKGSRC_PREFIX:-/usr/pkg}
BMAKE=${BMAKE:-${LOCALBASE}/bin/bmake}

FINISH_BOOTSTRAP_PKGS="pkgtools/libnbcompat \
 pkgtools/cwrappers \
 pkgtools/shlock \
 pkgtools/digest \
 sysutils/checkperms \
 devel/nbpatch"

## NB: This uses two builds of devel/git and -- indirectly -- two builds
## of www/nghttp2 and www/curl, in something of a work-around a certain
## dependency loop. The dependency loop may be encountered with curl,
## nghttp2, and libcares under some config. The second build of each
## should include the full dependency graph, under local config.

POST_BOOTSTRAP_PKGS="net/wget \
 devel/ccache \
 devel/git
 www/nghttp2
 www/curl
 devel/git"

## NB: devel/git is a meta-port, such that includes a substantial docs
## tree in tool deps -- when built with the asciidoc pdf option.
##
## When built with the asciidoc pdf option, the build may fail due
## something about buildlink and libwebp - at least, during an
## initial build
##
## e.g in
## [lcms2-2.9 openjpeg-2.3.1 ImageMagick-7.0.8.61 dblatex-0.3.10nb2 asciidoc-8.6.10nb1 git-docs-2.23.0]
##
## Local configuration has been updated for this.

THIS=$(readlink -f "$0")
HERE=$(dirname "${THIS}")
THIS=$(basename "${THIS}")

BOOTSTRAP_VARS="USE_CWRAPPERS=no \
 WRKDIR_LOCKTYPE=none \
 LOCALBASE_LOCKTYPE=none"

POST_BOOTSTRAP_VARS=""

msg(){
  echo "#-- ${THIS} : $@"
}

set -e

msg "Using LOCALBASE ${LOCALBASE}"

bmake_var() {
 local PKGPATH="$1"; shift
 ${BMAKE} -C /usr/pkgsrc/${PKGPATH} -D.MAKE.EXPAND_VARIABLES -V $@
}

if [ -z "${NO_FINISH_BOOTSTRAP}" ]; then

msg "Build ${FINISH_BOOTSTRAP_PKGS} - no cwrappers, host toolchain ${HOST_TOOLCHAIN}"

for P in ${FINISH_BOOTSTRAP_PKGS}; do
  msg "Build and in-place update ${P}"

  ## FIXME - make sure to configure for no locking, below

  env CC="${PKG_CC}" CXX="${PKG_CXX}" CPP="${PKG_CPP}" LD="${PKG_LD}" \
    HOST_TOOLCHAIN=${HOST_TOOLCHAIN} \
    ${BMAKE} -C /usr/pkgsrc/${P} \
    	clean build package ${BOOTSTRAP_VARS} || exit $?

  PKG_BASE=$(bmake_var "${P}" PKGBASE)
  PKG_F=$(bmake_var "${P}" PKGFILE)

  if pkg_info -e "${PKG_BASE}" > /dev/null; then
      msg "Deinstall ${PKG_BASE}"
      pkg_delete -f "${PKG_BASE}"
  fi
  msg "Install ${PKG_F}"
  pkg_add "${PKG_F}" || exit $?

  ${BMAKE} -C /usr/pkgsrc/${P} clean ${BOOTSTRAP_VARS}

done

fi


msg "Build post-bootstrap tools"


## - allow crwappers, locking here
##
## - assumption: the distfiles for each of POST_BOOTSTRAP_PKGS are
##   already available locally


for P in ${POST_BOOTSTRAP_PKGS}; do
  msg "Build and in-place update ${P}"

  ## FIXME - make sure to configure for no locking, below

  env CC="${PKG_CC}" CXX="${PKG_CXX}" CPP="${PKG_CPP}" LD="${PKG_LD}" \
    HOST_TOOLCHAIN=${HOST_TOOLCHAIN} \
    ${BMAKE} -C /usr/pkgsrc/${P} \
    	clean build package ${POST_BOOTSTRAP_VARS} || exit $?

  PKG_BASE=$(bmake_var "${P}" PKGBASE)
  PKG_F=$(bmake_var "${P}" PKGFILE)

  if pkg_info -e "${PKG_BASE}" > /dev/null; then
      msg "Deinstall ${PKG_BASE}"
      pkg_delete -f "${PKG_BASE}"
  fi
  msg "Install ${PKG_F}"
  pkg_add "${PKG_F}" || exit $?

  ${BMAKE} -C /usr/pkgsrc/${P} clean ${BOOTSTRAP_VARS}

done


## Assumption: mozilla-rootcerts was installed consequent of the wget build
${LOCALBASE}/sbin/mozilla-rootcerts install
