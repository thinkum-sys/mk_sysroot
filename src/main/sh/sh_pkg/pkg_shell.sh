## pkg_shell.sh - shell script utility functions for pkgsrc systems
##
## Version: 0.2
##
## Notes
##
## - If the variable THIS is set when the functions _msg, _warn, or any
##   of the _cerr variants are applied, the value of THIS will be
##   printed as a prefix value in the message text.
##
## Known Issues
##
## - May not fail gracefully in some call forms.
##
## - The SH 'shift' command is  used, here, without checking whether
##   it's to operate on an empty set of argv[1+] -- Should not fail,
##   if the calling SH routine is using a supported syntax.
##

MAKE=${MAKE:-bmake}

PKGSRCDIR=${PKGSRCDIR:-/usr/pkgsrc}

ERR_USAGE=64 ## NB: EX_USAGE in BSD sysexits(3)

## --

PKG_INFO=${PKG_INFO:-pkg_info}
AWK=${AWK:-awk}

## --

## NB: Seting THIS here may be ineffective if this script is sourced

#_THIS_P=${_THIS_P:-$(readlink -f "$0")}
#_HERE=${_HERE:-$(dirname "${_THIS_P}")}
#_THIS=${_THIS:-$(basename "${_THIS_P}")}

_msg() {
  echo "#-- ${_THIS}${_THIS:+ : }$@"
}

_warn() {
  _msg "$@" 1>&2
}

_cerr() {
  local CODE="$1"; shift
  _warn "$@"
  exit "${CODE}"
}

_uerr() {
  _cerr ${ERR_USAGE} "$@"
}

_err() {
## FIXME - this is not exiting the top-level shell script
## when called in _ppkg_path via _pmk_var (??)
  _cerr 1 "$@"
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
    _cerr ${ERR_USAGE} "Invalid call: _emk_var ${WHENCE} ${NAME}"
  else
    echo "${OUT}"
  fi
}

_ppkg_path_i() {
## compute PKGPATH for an installed pkg
  local NAME="${1}"; shift
  local OUT=$(${PKG_INFO} -B "${NAME}" | grep '^PKGPATH=' | cut -d= -f2)
  if [ "x${OUT}" = "x" ]; then
    _uerr "Unable to compute PKGPATH for \"${NAME}\""
  else
    echo "${OUT}"
  fi
}

_pmk_var(){
  local NAME="${1}"; shift
  local VAR="${1}"; shift

  if [ "${NAME#*/*/}" != "${NAME}" ]; then
  ## Assumption: NAME denotes a pathname
    _emk_var "${NAME}" "${VAR}" || _uerr
  elif [ "${NAME#*/*}" != "${NAME}" ]; then
  ## Assumption: NAME denotes a PKGPATH
  ## NB: This does not trim any trailing "/" from any provided PKGPATH
   _emk_var "${PKGSRCDIR}/${NAME}" "${VAR}" || _uerr
  else
  ## Assumption: NAME denotes a PKGNAME
  ##
  ## Compute a PKGPATH given a PKGNAME for an installed pkg
    local PKGPATH=$(_ppkg_path_i "${NAME}")
    if [ "x${PKGPATH}" = "x" ]; then
    ## Assumption: NAME does not denote an installed pkg
      _uerr
    else
      _emk_var "${PKGSRCDIR}/${PKGPATH}" "${VAR}"
    fi
  ## TBD: Compute a PKGPATH given a PKGNAME for an uninstalled pkg
  fi
}

_pdistname() {
  local WHENCE="${1}"; shift
  _pmk_var "${WHENCE}" DISTNAME || _uerr
}

## test forms
#_pdistname bmake
#_pdistname devel/bmake
#_pdistname /usr/pkgsrc/devel/bmake

_ppkgname() {
  local WHENCE="${1}"; shift
  _pmk_var "${WHENCE}" PKGNAME || _uerr
}

_ppkgname_nover() {
 ## package name with no version suffix
 local WHENCE="${1}"; shift
 local PKGFULL=$(_ppkgname "${WHENCE}" || _uerr)
 local PKGVER=$(_pmk_var "${WHENCE}" PKGVERSION || _uerr)
 echo "${PKGFULL%-${PKGVER}}"
}

_ppkgpath() {
  local WHENCE="${1}"; shift
  _pmk_var "${WHENCE}" PKGPATH || _uerr
}

_pkg_pkgver_p() {
 ## package version as under PKGSRCDIR
 local WHENCE="${1}"; shift
 _pmk_var "${WHENCE}" PKGVERSION || _uerr
}

_pkg_pkgver_i() {
 ## package version as installed (if installed)
 local WHENCE="${1}"; shift
 local PKGNAME=$(_ppkgname_nover "${WHENCE}")
 local PKG_INAME=$(${PKG_INFO} -E "${PKGNAME}" ||
                       _uerr "Not installed? ${WHENCE}")
 echo "${PKG_INAME#${PKGNAME}-}"
}

## NB:
## if [ $(_pkg_pkgver_i ${WHENCE}) < $(_pkg_pkgver_p ${WHENCE}) ] ...
