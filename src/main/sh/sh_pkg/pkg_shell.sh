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
## - In most cases, should gracefully handle output for any MULTI
##   package - see also, the definition and usage of _pkg_multi_i()
##   below
##
## Known Issues
##
## - May not fail gracefully in some call forms.
##
## - The SH 'shift' command is  used, here, without checking whether
##   it's to operate on an empty set of argv[1+] -- Should not fail,
##   if the calling SH routine is using a supported syntax.
##
## - Didactic source style (??)

MAKE=${MAKE:-bmake}

PKGSRCDIR=${PKGSRCDIR:-/usr/pkgsrc}
LOCALBASE=${LOCALBASE:-/usr/pkg}


ERR_USAGE=64 ## NB: EX_USAGE in BSD sysexits(3)

## --

PKG_INFO=${PKG_INFO:-${LOCALBASE}/sbin/pkg_info}
AWK=${AWK:-awk}

## --

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
## when called in _pkg_path_p via _pmk_var (??)
  _cerr 1 "$@"
}

## --

_qstr() {
## NB: requires a BASH built-in printf extension
  printf "%q" "$@"
}

_mk_var() {
  local WHENCE="${1}"; shift
  local NAME="${1}"; shift
  local MULTI_VARS="$@"
  ${MAKE} -C "${WHENCE}" -D.MAKE.EXPAND_VARIABLES -V "${NAME}" \
          $(_qstr "${MULTI_VARS}")
}


_emk_var() {
  local WHENCE="${1}"; shift
  local NAME="${1}"; shift
  local MULTI_VARS="$@"
  local OUT=$(_mk_var "${WHENCE}" "${NAME}" ${MULTI_VARS})
  if [ "x${OUT}" = "x" ]; then
    _cerr ${ERR_USAGE} "Invalid call: _emk_var ${WHENCE} ${NAME}"
  else
    echo "${OUT}"
  fi
}

_pkg_path_i() {
## compute PKGPATH for an installed pkg - does not call ${MAKE)
  local NAME="${1}"; shift
  local OUT=$(${PKG_INFO} -Q PKGPATH "${NAME}")
  if [ "x${OUT}" = "x" ]; then
    _uerr "Unable to compute PKGPATH for \"${NAME}\""
  else
    echo "${OUT}"
  fi
}

_pkg_multi_i() {
## compute MUTI variables for an installed pkg - does not call ${MAKE)
  local NAME="${1}"; shift
  local OUT=$(${PKG_INFO} -Q MULTI "${NAME}")
  if [ "x${OUT}" = "x" ]; then
    _uerr "Unable to compute MULTI parameters for \"${NAME}\""
  else
    echo "${OUT}"
  fi
}



_pmk_var(){
  local NAME="${1}"; shift
  local VAR="${1}"; shift
  local MULTI_VARS="$@" ## NB: Avoid nested quoting, if this is used

  if [ "${NAME#*/*/}" != "${NAME}" ]; then
  ## Assumption: NAME denotes a pathname
    _emk_var "${NAME}" "${VAR}" ${MULTI_VARS} || _uerr
  elif [ "${NAME#*/*}" != "${NAME}" ]; then
  ## Assumption: NAME denotes a PKGPATH
  ## NB: This does not trim any trailing "/" from any provided PKGPATH
   _emk_var "${PKGSRCDIR}/${NAME}" "${VAR}" ${MULTI_VARS} || _uerr
  else
  ## Assumption: NAME denotes a PKGNAME
  ##
  ## Compute a PKGPATH given a PKGNAME for an installed pkg + MULTI info
  ##
  ## NB: This appends any provided MULTI_VARS with no check for any
  ## duplicate/conflicting MULTI variable names. "Caller beware"
  ##
    local PKGPATH=$(_pkg_path_i "${NAME}" ${MULTI_VARS})
    if [ "x${PKGPATH}" = "x" ]; then
       ## Assumption: NAME *does not* denote an installed pkg
      _uerr
    else
      MULTI_VARS="$(_pkg_multi_i "${NAME}") ${MULTI_VARS}"
      _emk_var "${PKGSRCDIR}/${PKGPATH}" "${VAR}" ${MULTI_VARS}
    fi
  ## TBD: Compute a PKGPATH given a PKGNAME for an uninstalled pkg
  ## FIXME TEST -
  ## bash -c 'source ./pkg_shell.sh && _pmk_var py27-setuptools PKGNAME' &
  fi
}

_pdistname() {
  local WHENCE="${1}"; shift
  local MULTI_VARS="$@"
  _pmk_var "${WHENCE}" DISTNAME ${MULTI_VARS} || _uerr
}

## test forms
#_pdistname bmake
#_pdistname devel/bmake
#_pdistname /usr/pkgsrc/devel/bmake

_pkg_name_p() {
  local WHENCE="${1}"; shift
  local MULTI_VARS="$@"
  _pmk_var "${WHENCE}" PKGNAME ${MULTI_VARS} || _uerr
}

_pkg_name_nover_p() {
 ## package name for an available port, with no version suffix
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 local PKGFULL=$(_pkg_name_p "${WHENCE}" ${MULTI_VARS} || _uerr)
 local PKGVER=$(_pmk_var "${WHENCE}" PKGVERSION ${MULTI_VARS} || _uerr)
 echo "${PKGFULL%-${PKGVER}}"
}

_pkg_name_nover_i() {
 ## package name for an installed package, with no version suffix
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 local PKGVER=$(_pmk_var "${WHENCE}" PKGVERSION ${MULTI_VARS} || _uerr)
 echo "${WHENCE%-${PKGVER}}"
}


_pkg_path_p() {
## FIXME - needs test for installed pkg
  local WHENCE="${1}"; shift
  local MULTI_VARS="$@"
  _pmk_var "${WHENCE}" PKGPATH ${MULTI_VARS} || _uerr
}

_pkg_pkgver_p() {
 ## package version as under PKGSRCDIR
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 _pmk_var "${WHENCE}" PKGVERSION ${MULTI_VARS} || _uerr
}

_pkg_pkgver_i() {
 ## package version as installed (if installed) (calls bmake initially)
 ##
 ## NB - see remarks in _pkg_name_nover_i() ##
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 local PKGNAME=$(_pkg_name_nover_p "${WHENCE}" ${MULTI_VARS})
 local PKG_INAME=$(${PKG_INFO} -e "${PKGNAME}" ||
                       _uerr "Not installed? ${WHENCE}")
 echo "${PKG_INAME#${PKGNAME}-}"
}
