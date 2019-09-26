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

PKG_CC='clang-7'
PKG_CXX='clang++-7'
PKG_CPP='clang-cpp-7'
PKG_LD='ld.lld-7'


HOST_TOOLCHAIN=clang

FINISH_BOOTSTRAP_PKGS="pkgtools/libnbcompat
 pkgtools/cwrappers
 pkgtools/shlock
 pkgtools/digest
 sysutils/checkperms
 devel/nbpatch"


THIS=$(readlink -f "$0")
HERE=$(dirname "${THIS}")
THIS=$(basenam "${THIS}")

BOOTSTRAP_VARS="USE_CWRAPPERS=no \
 WRKDIR_LOCKTYPE=none \
 LOCALBASE_LOCKTYPE=none"


msg(){
  echo "#-- ${THIS} : $@"
}

set -e

bmake_var() {
 local PKGPATH="$1"; shift
 bmake -C /usr/pkgsrc/${PKGPATH} -D.MAKE.EXPAND_VARIABLES -V $@
}

msg "Build ${FINISH_BOOTSTRAP_PKGS} - no cwrappers, host toolchain ${HOST_TOOLCHAIN}"

for P in ${FINISH_BOOTSTRAP_PKGS}; do
  msg "Build and in-place update ${P}"

  ## FIXME - make sure to configure for no locking, below

  env CC="${PKG_CC}" CXX="${PKG_CXX}" CPP="${PKG_CPP}" LD="${PKG_LD}" \
    HOST_TOOLCHAIN=${HOST_TOOLCHAIN} \
    bmake -C /usr/pkgsrc/${P} \
    	clean build package ${BOOTSTRAP_VARS} || break

  PKG_BASE=$(bmake_var "${P}" PKGBASE)
  PKG_F=$(bmake_var "${P}" PKGFILE) && {
      pkg_delete -f "${PKG_BASE}"
      pkg_add "${PKG_F}"
  }

done
