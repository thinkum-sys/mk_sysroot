# portable bashrc_pkg.sh [mk_sysroot]
#
# Usage: This shell script may be sourced from the interactive shell
#        environment (when BASH), or sourced from arbitrary shells
#        scripts (typically BASH) such as to configure the shell
#        process environment in a manner that may be assumed suitable
#        for shell processes (non-chroot) under pkgsrc.
#
# Remarks
# - This shell script may not depend expressly on BASH. It's believed
#   that the BASH built-in 'test' cmd may behave differently than some
#   BSD 'test' cmd under '-z' and/or '-n' tests. As such, it may be
#   advisable to use this shell script with BASH environments only.
#   (not tested under any other SH)
#


_path_add() {
 local NEWP="$1"; shift
 if [ "${#}" -ge 1  ] ; then
    if [ -n "${@}" ]; then
      PATH="${NEWP}:${@}"
    else
      PATH="${NEWP}"
    fi
 else
   PATH="${NEWP}:${PATH}"
 fi
}

## Local prefix variables - may be exported in the calling environment
MACH_PREFIX=${MACH_PREFIX:-}
SYS_PREFIX=${SYS_PREFIX:-/usr}
HOST_PREFIX=${HOST_PREFIX:-/usr/local}
if [ -z "${PKGSRC_PREFIX}" ]; then
  ## assumption: This file is installed in ${LOCALBASE}/etc/
  if [ -n "${BASH_SOURCE}" ]; then
    PKGSRC_PREFIX=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
  else
    PKGSRC_PREFIX=$(dirname $(dirname $(readlink -f "${0}")))
  fi
fi


## PATH - Configure path for MACH_PREFIX, SYS_PREFIX, HOST_PREFIX
_path_add /sbin:${SYS_PREFIX}/sbin:${SYS_PREFIX}/bin:${MACH_PREFIX}/bin ""
_path_add ${HOST_PREFIX}/sbin:${HOST_PREFIX}/bin

## PATH - Configure for GCC, GNU binutils, GNU coreutils in pkgsrc
[ -e ${PKGSRC_PREFIX}/gcc8/bin ] &&
    _path_add ${PKGSRC_PREFIX}/gcc8/bin

[ -e ${PKGSRC_PREFIX}/gnu/bin ] &&
    _path_add ${PKGSRC_PREFIX}/gnu/bin

## PATH - Configure for PKGSRC_PREFIX
_path_add ${PKGSRC_PREFIX}/sbin:${PKGSRC_PREFIX}/bin

## PATH - Add a generic ccache libexec under PKGSRC_PREFIX, if exists
##
## NB: This would be searched before gcc8/bin, gnu/bin, and pkgsrc prefix
[ -e ${PKGSRC_PREFIX}/libexec/ccache ] &&
    _path_add ${PKGSRC_PREFIX}/libexec/ccache

## PATH - Configure for user ~/bin if exists at this time
[ -e ${HOME}/bin ] &&
    _path_add ${HOME}/bin

## - TBD: gtk-doc paths; ScrollKeeper/Rarian paths; ...

MANPATH=${PKGSRC_PREFIX}/man:${PKGSRC_PREFIX}/share/man:${HOST_PREFIX}/man:${HOST_PREFIX}/share/man:${SYS_PREFIX}/share/man

for OPT in guile/2.2/man gnu/man; do
## MANPATH - configure for GNU coreutils, GNU binutils, Guile 2.2
[ -e ${PKGSRC_PREFIX}/${OPT}/ ] && MANPATH=${PKGSRC_PREFIX}/${OPT}:${MANPATH}
done

## NB GNU coreutils, GNU binutils, GCC info, and Guile info documentation
## should be (??) installed under the conventional PKGSRC infodir

INFOPATH=${PKGSRC_PREFIX}/info:${PKGSRC_PREFIX}/share/info:${HOST_PREFIX}/info:${HOST_PREFIX}/share/info:${SYS_PREFIX}/share/info
## NB Editor/IDE suport - Emacs `Info-directory-list`
##
## NB lang/guile20 and lang/guile22 would conficlit in the Guile info docs

## TBD: set MAKESYSPATH (pkgsrc bootstrap-mk-files or sys mk-files @ host)
## sys mk-files as sys mk-files [BSD] ::
# MAKESYSPATH=/usr/share/mk
## bootstrap-mk-files as sys mk-files [Other] ::
# MAKESYSPATH=${PKGSRC_PREFIX}/share/mk


PKG_CONFIG_LIBDIR=${PKGSRC_PREFIX}/lib/pkgconfig:${HOST_PREFIX}/lib/pkgconfig:${SYS_PREFIX}/lib/pkgconfig
## ^ NB PKG_CONFIG_LIBDIR will be set, during builds, in mk/tools/pkg-config.mk
##      PKG_CONFIG_PATH may be defined as extensional to that value,
##      but would not per se result in "Clean builds" for pkgsrc
##
## note also PKGPATH:pkgtools/verifypc

export PATH MANPATH INFOPATH PKG_CONFIG_LIBDIR  # MAKESYSPATH

## CCACHE config-in-process-environment


## NB: Leaving CCACHE_PATH to a careful $PATH config
##     such that can be modified in the build eviroment
##     to add any arbitray libexec/<NAME> symlinks dir @ host
##     during the build
CCACHE_MAXSIZE=4G
CCACHE_DIR=/usr/pkg/var/tmp/ccache

export CCACHE_MAXSIZE CCACHE_DIR # CCACHE_PATH
