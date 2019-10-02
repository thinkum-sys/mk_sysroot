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
##
## - Error messages may not be perfectly informative

set -e

MAKE=${MAKE:-bmake}

PKGSRCDIR=${PKGSRCDIR:-/usr/pkgsrc}
PREFIX=${PREFIX:-${PKGSRC_PREFIX:/usr/pkg}}
##^ FIXME - Set a default PREFIX as an effective constant, before install

ERR_USAGE=64 ## NB: EX_USAGE in BSD sysexits(3)

## --

PKG_INFO=${PKG_INFO:-${PREFIX}/sbin/pkg_info}
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

_exit() {
  exit $?
}

## --


if [ -z "${BASH_SOURCE}" ]; then
  ## NB This serves to indicate the actual SHELL, which may
  ## not have been set, e.g when running under dash(1)
  ## i.e running directly under a typical Debian /bin/sh
  _uerr "Not supported for this shell: $(ps -p $$ c -o comm=)"
fi

## debug
# _warn Using prefix ${PREFIX}

## --

_qstr() {
  ## Output the set of arguments as a shell-quoted string
  ##
  ## NB: requires a BASH built-in printf extension
  ##
  ## FIXME why is this resulting in an error under any BASH?
  printf "%q" "$@" ## FIXME - this should work
}

_mk_var() {
  ## Output an expanded mk-file variable for a given port location
  local WHENCE="${1}"; shift
  local NAME="${1}"; shift
  local MULTI_VARS="$@"
  ${MAKE} -C "${WHENCE}" -D.MAKE.EXPAND_VARIABLES -V "${NAME}" \
          $(_qstr "${MULTI_VARS}")
}


_emk_var() {
  ## call _mk_var with a constraint of "Non-Empty Result Required"
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


_pkg_path_p() {
  # output PKGPATH for an available port
  local WHENCE="${1}"; shift
  local MULTI_VARS="$@"
  _pmk_var "${WHENCE}" PKGPATH ${MULTI_VARS} || _err
}


_pkg_path_i() {
  ## output PKGPATH for an installed pkg
  ##
  ## does not call ${MAKE}
  ##
  ## NAME must denote a versioned or unversioned package name, for an
  ## installed package
  local NAME="${1}"; shift
  local OUT=$(${PKG_INFO} -Q PKGPATH "${NAME}") || _err
#  if [ "x${OUT}" = "x" ]; then
    ## FIXME
    ## - This is not resulting in exit, when evaluated
    ## - This should not need be an error, for any pkg with no MULTI defined
#    _uerr "Unable to compute PKGPATH for pkg \"${NAME}\""
#  else
    echo "${OUT}"
#  fi
}


_pkg_multi_p() {
  ## output MULTI variables for an avaialble port
  local WHENCE="${1}"; shift
  local MK_OPTS="$@"
  local PPATH=$(_pkg_path_p "${WHENCE}")
  local OUT=$(_pmk_var "${PPATH}" MULTI ${MK_OPTS})
#  if [ "x${OUT}" = "x" ]; then
## NB: Not an error - mostly of interest for debugging
#    _uerr "Unable to compute MULTI parameters for port \"${WHENCE}\""
#  else
    echo "${OUT}"
#  fi
}

_pkg_multi_i() {
  ## output all MULTI variables for an installed pkg
  ##
  ## does not call ${MAKE}
  ##
  ## NAME must denote a versioned or unversioned package name, for an
  ## installed package
  local NAME="${1}"; shift
  local OUT=$(${PKG_INFO} -Q MULTI "${NAME}") || _err
#  if [ "x${OUT}" = "x" ]; then
## See previous
#    _uerr "Unable to compute MULTI parameters for \"${NAME}\""
#  else
    echo "${OUT}"
#  fi
}



_pmk_var(){
  ## Output the expanded value of a mk-file varaible for an available port
  ##
  ## Syntax
  ## - WHENCE: Denotes a pathname, PKGPATH, or versioned or unversioned
  ##   package name.
  ## - VAR: Denotes the name of the mk-file variable to be output.
  ## - MULTI_VARS: Variables for mk, such that may be provided by the
  ##   calling function. These parameters should use a syntax such as
  ##   output by the shell command
  ##     pkg_info -Q MULTI <pkgname>
  ##   or similarly:
  ##     bmake -C <portdir> -D.MAKE.EXPAND_VARIABLES -V MULTI
  ##   These MULTI parameters may affect selection of variables for
  ##   ports with variants, such as the python ports.
  ##
  ## Environment
  ## - ${MAKE}
  ## - ${PKG_INFO}
  ##
  ## Exceptional Situations
  ## - Should fail with ERR_USAGE if provided with a WHENCE for which no
  ##   port system location can be determined
  ##
  ## Known Issues
  ## - If a relative pathname having only one "/" is provided as WHENCE,
  ##   that value of WHENCE may be misconstrued as a PKGPATH not a
  ##   pathanme. It may be recommended that any pathname that may be
  ##   provided to this function would be expanded such as with
  ##   `readlink -f` before being provided as the WHENCE parameter to
  ##   this function.
  ##
  ## - This function, when provided with the name of an installed
  ##   package, will automatically use the set of MULTI variables
  ##   provided for that package when it was built. It will not check
  ##   any provided MULTI_VARS for duplication in the package MULTI
  ##   variables. The behaviors of this function are unspecified. for
  ##   any event of being provided with any MULTI_VARS duplicating any
  ##   of the MULTI variables defined in the installed package.
  ##
  ## - If provided with a package name as WHENCE, for any package
  ##   that is not installed under the ${PREFIX} principally as being
  ##   accesseed by ${PKG_INFO}, this function will be unable to compute
  ##   a port location for that package name. This may be addressed with
  ##   another programming system and any manner of a mklib and database
  ##   API under that programming system - pursuant of developing a
  ##   logical database schema, pkgsrc port traversal methodology, and
  ##   port configuration management methodology within the same.
  ##
  ## - When provided with a package name as WHENCE, this function will
  ##   not access any build information for that package other than the
  ##   MULTI variables defined when that package was built. In effect,
  ##   this function uses a package name in WHENCE only as a symbolic
  ##   port system pathname locator.
  ##
  ## - Does not serve to provide information about package archive
  ##   files, directly
  ##
  local WHENCE="${1}"; shift
  local VAR="${1}"; shift
  local MULTI_VARS="$@" ## NB: Avoid nested quoting, if this is used

  if [ "${WHENCE#*/*/}" != "${WHENCE}" ]; then
  ## Assumption: WHENCE denotes a pathname
    _emk_var "${WHENCE}" "${VAR}" ${MULTI_VARS} || _uerr
  elif [ "${WHENCE#*/*}" != "${WHENCE}" ]; then
  ## Assumption: WHENCE denotes a PKGPATH
  ## NB: This does not trim any trailing "/" from any provided PKGPATH
   _emk_var "${PKGSRCDIR}/${WHENCE}" "${VAR}" ${MULTI_VARS} || _uerr
  else
  ## Assumption: WHENCE denotes an installed package
  ##
  ## Output the expanded value of the variable VAR for the active port
  ## system configuration, given a WHENCE denoting an installed pkg --
  ## furthermore, using the MULTI info defined in that installed pkg
  ##
  ## NB: This appends any provided MULTI_VARS with no check for any
  ## duplicate/conflicting MULTI variable names. "Caller beware"
  ##
    local PKGPATH=$(_pkg_path_i "${WHENCE}" ${MULTI_VARS})
    if [ -z "${PKGPATH}" ]; then
       ## Assumption: WHENCE *does not* denote an installed pkg
       ##
       ## NB: This does not actually exit w/ error,
       ## for any non-installed pkg name, as $?
       ## from the failed pkg_info call will be
       ## overwritten by the subsequent 'test'
      _exit
    else
      MULTI_VARS="$(_pkg_multi_i "${WHENCE}") ${MULTI_VARS}"
      _emk_var "${PKGSRCDIR}/${PKGPATH}" "${VAR}" ${MULTI_VARS}
    fi
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
  ## versioned package name for an available port
  local WHENCE="${1}"; shift
  local MULTI_VARS="$@"
  _pmk_var "${WHENCE}" PKGNAME ${MULTI_VARS} || _uerr
}

_pkg_name_nover_p() {
 ## package name (no version suffix) for an available port
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 local PKGFULL=$(_pkg_name_p "${WHENCE}" ${MULTI_VARS} || _uerr)
 local PKGVER=$(_pmk_var "${WHENCE}" PKGVERSION ${MULTI_VARS} || _uerr)
 echo "${PKGFULL%-${PKGVER}}"
}

_pkg_name_nover_i() {
 ## package name (no version suffix) for an installed package
 ##
 ## will call ${MAKE}
 ##
 ## Assumption: For any installed package denoted in WHENCE, MULTI
 ## variables will be handled automatically, specifically in _pmk_var
 ##
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 local PKGVER=$(_pmk_var "${WHENCE}" PKGVERSION ${MULTI_VARS} || _uerr)
 echo "${WHENCE%-${PKGVER}}"
}

_pkg_pkgver_p() {
 ## package version (no package name) for an available port
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 _pmk_var "${WHENCE}" PKGVERSION ${MULTI_VARS} || _uerr
}

_pkg_pkgver_i() {
 ## package version (no package name) for an installed pkg
 ##
 ## the WHENCE parameter must denote an installed pkg, in this function
 ##
 ## will call ${MAKE} in all situations, to determine the unversioned
 ## name of the available port corresponding to the installed package
 ## name denoted in WHENCE
 ##
 ## Assumption: For any installed package denoted in WHENCE, MULTI
 ## variables will be handled automatically, specifically in _pmk_var
 ##
 local WHENCE="${1}"; shift
 local MULTI_VARS="$@"
 local PKGNAME=$(_pkg_name_nover_p "${WHENCE}" ${MULTI_VARS})
 local PKG_INAME=$(${PKG_INFO} -e "${PKGNAME}" ||
                       _uerr "Not installed? ${WHENCE}")
 echo "${PKG_INAME#${PKGNAME}-}"
}
