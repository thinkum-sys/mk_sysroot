## pkg_shell.sh - shell script utility functions for pkgsrc systems

MAKE=${MAKE:-bmake}

PKGSRCDIR=${PKGSRCDIR:-/usr/pkgsrc}

ERR_USAGE=64 ## NB: EX_USAGE in BSD sysexits(3)

## --

## NB: Seting THIS here may be ineffective if this script is sourced

#_THIS_P=${_THIS_P:-$(readlink -f "$0")}
#_HERE=${_HERE:-$(dirname "${_THIS_P}")}
#_THIS=${_THIS:-$(basename "${_THIS_P}")}

msg() {
  echo "#-- ${_THIS}${_THIS:+ : }$@"
}

warn() {
  msg "$@" 1>&2
}

cerr() {
  local CODE="$1"; shift
  warn "$@"
  exit "${CODE}"
}

err() {
## FIXME - this is not exiting the top-level shell script
## when called in _ppkg_path via _pmk_var
  cerr 1 "$@"
}

## --

_mk_var() {
  local WHENCE="${1}"; shift
  local NAME="${1}"; shift
  ${MAKE} -C "${WHENCE}" -D.MAKE.EXPAND_VARIABLES -V "${NAME}"
}


_emk_var() {
  local WHENCE="${1}"; shift
  local NAME="${1}"; shift
  local OUT=$(_mk_var "${WHENCE}" "${NAME}")
  if [ "x${OUT}" = "x" ]; then
    cerr ${ERR_USAGE} "Invalid call: _emk_var ${WHENCE} ${NAME}"
  else
    echo "${OUT}"
  fi
}

_ppkg_path() {
## compute PKGPATH for an installed pkg
  local NAME="${1}"; shift
  local OUT=$(pkg_info -B "${NAME}" | grep '^PKGPATH=' | cut -d= -f2)
  if [ "x${OUT}" = "x" ]; then
    cerr ${ERR_USAGE} "Unable to compute PKGPATH for \"${NAME}\""
  else
    echo "${OUT}"
  fi
}

_pmk_var(){
  local NAME="${1}"; shift
  local VAR="${1}"; shift

  if [ "${NAME#*/*/}" != "${NAME}" ]; then
  ## Assumption: NAME denotes a pathname
    _emk_var "${NAME}" "${VAR}" || exit ${ERR_USAGE}
  elif [ "${NAME#*/*}" != "${NAME}" ]; then
  ## Assumption: NAME denotes a PKGPATH
  ## NB: This does not trim any trailing "/" from any provided PKGPATH
   _emk_var "${PKGSRCDIR}/${NAME}" "${VAR}" || exit ${ERR_USAGE}
  else
  ## Assumption: NAME denotes a PKGNAME
  ##
  ## Compute a PKGPATH given a PKGNAME for an installed pkg
    local PKGPATH=$(_ppkg_path "${NAME}")
    if [ "x${PKGPATH}" = "x" ]; then
    ## Assumption: NAME does not denote an installed pkg
      exit ${ERR_USAGE}
    else
      _emk_var "${PKGSRCDIR}/${PKGPATH}" "${VAR}"
    fi
  ## TBD: Compute a PKGPATH given a PKGNAME for an uninstalled pkg
  fi
}

_pdistname() {
  local WHENCE="${1}"; shift
  _pmk_var "${WHENCE}" DISTNAME || exit ${ERR_USAGE}
}

## test forms
#_pdistname bmake
#_pdistname devel/bmake
#_pdistname /usr/pkgsrc/devel/bmake

_ppkgname() {
  local WHENCE="${1}"; shift
  _pmk_var "${WHENCE}" PKGNAME || exit ${ERR_USAGE}
}

_ppkgname_nover() {
 ## package name with no version suffix
 local WHENCE="${1}"; shift
 local PKGFULL=$(_pmk_var "${WHENCE}" PKGNAME || exit ${ERR_USAGE})
 local PKGVER=$(_pmk_var "${WHENCE}" PKGVERSION || exit ${ERR_USAGE})
 echo "${PKGFULL%-${PKGVER}}"
}

_ppkgpath() {
  local WHENCE="${1}"; shift
  _pmk_var "${WHENCE}" PKGPATH || exit ${ERR_USAGE}
}

