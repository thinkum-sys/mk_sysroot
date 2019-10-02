#!/bin/sh

## print a list of all dynamic shared objects (DSOs) needed
## for an EXE or dynamic library
##
## uses eu-readelf
##
## for each DSO not found under LIBPATH, print a message
## indicating the depending DSO and that "Not found" DSO
## (printed on STDERR)
##
## print a list of all found (stdout) and not-found (stderr)
## at the end of the shell script
##
## Known Issues:
##
## - Does not provide much of a command line syntax
##
## - Does not gracefully handle some errors
##   - e.g when find, awk, or eu-readelf is not available
##
## - Does not recognize the host linker
##   - e.g libuuid.so.1 => ld-linux-x86-64.so.2
##
## - May not recognize every "Missing link"
##   - This is partly a side effect of the crude algorithm for list
##     element deduplication, developed in this shell script
##
## - Does not produce a very clear output, at end of script
##
## - Is not integrated with pkgsrc. As such, this shell script may not
##   in itself be useful, except in some usage cases of interactive
##   review -- if not as an example towards linting pkg dependencies,
##   for each *.so.* or bytecode executable installed by a pkg
##
## - Not well documented
##
## Other remarks:
##
## - It may be, in some ways, non-trivial to diagonose the exact cause
##   of some situations of a pkg being built with a dependency on a host
##   library, rather than a similar library installed and available
##   under pkg LOCALBASE. As a simple example, there may be some of a
##   system configuration in which libtiff is built to use the host's
##   libwebp, instead of the libwep under pkg LOCALBASE - such that may
##   not be recognizable as a concern, per se, until some build-time
##   linking for a bytecode object trying to use libtiff itself, e.g
##   temacs, during an Emacs build, subsequent of a dist-upgrade after
##   the initial libtiff build.


THIS_P=$(readlink -f "$0")
HERE=$(dirname "${THIS_P}")
THIS=$(basename "${THIS_P}")

_DSO_NEEDED=""

_DSO_FOUND=""

_DSO_NF=""

#export _DSO_NEEDED _DSO_FOUND _DSO_NF

LIBPATH="${LIBPATH:-/usr/pkg/lib}"

filter_needed() {
  awk --posix '/NEEDED/ {print substr($4,2,(length($4) - 2)); }'
}

print_needed() {
  local WHENCE="${1:-/dev/stdin}"; shift
  if [ -e "${WHENCE}" ]; then
    eu-readelf -d ${WHENCE} | filter_needed
  else
    echo "File not found: ${WHENCE}" 1>&2
    exit 4
  fi
}

find_dso() {
  local WHICH="$1"; shift
  find ${LIBPATH} -name "${WHICH}" \( -type f -o -type l \)
}

new_dso_found() {
  local DWHICH="$1"; shift
  [ "${_DSO_FOUND#*${DWHICH}}" = "${_DSO_FOUND}" ]
}

add_dso_found() {
  local DWHICH="$1"; shift
  _DSO_FOUND="${_DSO_FOUND}${_DSO_FOUND:+ }${DWHICH}"
}

new_dso_nf() {
  local DWHICH="$1"; shift
  [ "${_DSO_NF#*${DWHICH}}" = "${_DSO_NF}" ]
}

add_dso_nf() {
  local DWHICH="$1"; shift
  _DSO_NF="${_DSO_NF}${_DSO_NF:+ }${DWHICH}"
}

add_dso() {
 local DWHICH="$1"; shift
 local DSO_P
 if  [ "${_DSO_NEEDED#*${DWHICH}}" = "${_DSO_NEEDED}" ]; then
   _DSO_NEEDED="${_DSO_NEEDED}${_DSO_NEEDED:+ }${DWHICH}"

   DSO_P=$(find_dso "${DWHICH}")

   if [ -n "${DSO_P}" ]; then
     if new_dso_found "${DWHICH}"; then
       add_dso_found "${DWHICH}"
     fi

#     echo "#-- parse ${DSO_P}" 1>&2
#     echo "#-- Needed: ${_DSO_NEEDED}" 1>&2
#     echo "#-- Found: ${_DSO_FOUND}" 1>&2
#     echo "#-- NotFound: ${_DSO_NF}" 1>&2
     for DNEXT in $(print_needed "${DSO_P}"); do

       add_dso "${DNEXT}" || echo "#-- ${DWHICH} => ${DNEXT} ??" 1>&2
     done
   else
     if new_dso_nf "${DWHICH}"; then
       add_dso_nf "${DWHICH}"
     fi
     return 1
  fi
 fi
}

_INIT_NEEDED=$(print_needed "$@")

#echo "#-- ${_INIT_NEEDED}"

for DSO in ${_INIT_NEEDED}; do
 add_dso ${DSO}
done


echo "${_DSO_FOUND}"

if [ "x${_DSO_NF}" != "x" ]; then
  echo "#-- ?? ${_DSO_NF}" 1>&2
  exit 1
fi
