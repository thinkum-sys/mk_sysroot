## pkg_shell.sh - shell script utility functions for pkgsrc systems

MAKE=${MAKE:-bmake}

PKGSRCDIR=${PKGSRCDIR:-/usr/pkgsrc}

ERR_USAGE=64 ## NB: EX_USAGE in BSD sysexits(3)

## --

## NB: Seting THIS here may be ineffective if this script is sourced

THIS_P=$(readlink "$0")
HERE=$(dirname "${THIS_P}")
THIS=$(basename "${THIS_P}")

msg() {
  echo "#-- ${THIS} : $@"
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

_ppkgpath() {
  local WHENCE="${1}"; shift
  _pmk_var "${WHENCE}" PKGPATH || exit ${ERR_USAGE}
}

