#!/bin/sh

## NB: Host toolchain configuation - LLVM on Debian 8

## NB: This script represents a general procedure,
##     and has not been singularly tested, in itself

## NB: This assumes that a bare minimum LOCALBASE is installed --
## principally, a bare pkgsrc bootstrap filesystem -- and an appropriate
## configuraton under the pkg 'etc' dir.

## FIXME: QA needed for stage-2 build failures with stage-1 built w/ GCC
##
## - Note that compiler-rt is being built under local config, in
##   the stage-1 build. Use its rtlib in the stage 2 build? and subsq.
##
##   - works OK in local testing - libunwind stage-2 build, at least
##
##   - somehow fails in the llvm stage-2 buld
##     > ld.lld: error: undefined symbol: vtable for __cxxabiv1::__si_class_type_info
##
##   - stage-2 build was not successful, even for libunwind, without the
##     configuration resulting from -DWITH_COMPILER_RT as below

## NB: This script, in iteslf, does not provide support for build-
##     logging or storage of other site maintenance data -- e.g storing
##     the CMakeCache.txt for each LLVM component build, for later
##     review, QA. Insofar as for build logging, there is the BSD script
##     command and its approximate analogue in GNU tools

## NB: This script does not provide any support for logging or analysis
##     of build failures, during initial post-bootstrap, stage-1
##     stage-2, or later "Host" builds.
##
## QA methodologies may vary, by site.

set -e

## NB: This default host CC configuration is for Debian 8

HOST_CC_LLVM=${HOST_CC_LLVM:-clang-4.0}
HOST_CXX_LLVM=${HOST_CXX_LLVM:-clang++-4.0}
HOST_CPP_LLVM=${HOST_CPP_LLVM:-clang-cpp-4.0}
HOST_LD_LLVM=${HOST_LD_LLVM:-ld.lld-4.0}

HOST_CC_GCC=${HOST_CC_GCC:-clang-4.0}
HOST_CXX_GCC=${HOST_CXX_GCC:-clang++-4.0}
HOST_CPP_GCC=${HOST_CPP_GCC:-clang-cpp-4.0}
HOST_LD_GCC=${HOST_LD_GCC:-ld.lld-4.0}

LOCALBASE="${LOCALBASE:-/usr/pkg}"
PKGSRCDIR="${PKGSRCDIR:-/usr/pkgsrc}"

LLVM_CCACHE_LINKDIR=${LOCALBASE}/libexec/llvm
## NB: Cheap hack - hard-coding the relative path here
CCACHE_RELPATH="../../ccache"
LLD_RELPATH="../../lld"

PKG_TGT=${PKG_TGT:-clean build package}
INSTALL_TGT=${INSTALL_TGT:-install}
CLEAN_TGT=${CLEAN_TGT:-clean}


## Assumption: Site mk.conf provides mk-conf specifications dispatching
## on HOST_TOOLCHAIN and/or PKGSRC_COMPILER to select an appropiate set
## of specification for CC, CXX, CPP, LLD


clean_after_build() {
  local PORT=$1; shift
  if [ "x${CLEAN_TGT}" != "x" ]; then
     bmake -C ${PKGSRCDIR}/${PORT} ${CLEAN_TGT}
  fi
}

build_llvm_1() {
  local PORT=$1; shift
  env CC="${HOST_CC_LLVM}" CXX="${HOST_CXX_LLVM}" CPP="${HOST_CPP_LLVM}" \
    LD="${HOST_LD_LLVM}" bmake -C ${PKGSRCDIR}/${PORT} \
    	${PKG_TGT} ${INSTALL_TGT} USE_CWRAPPERS=no HOST_TOOLCHAIN=clang &&
    clean_after_build
}

build_llvm_2() {
  local PORT=$1; shift
  env CC="${HOST_CC_LLVM}" CXX="${HOST_CXX_LLVM}" CPP="${HOST_CPP_LLVM}" \
    LD="${HOST_LD_LLVM}" bmake -C ${PKGSRCDIR}/${PORT} \
    	${PKG_TGT} ${INSTALL_TGT} HOST_TOOLCHAIN=gcc HOST_TOOLCHAIN=clang &&
    clean_after_build
}


build_s1() {
  local PORT=$1; shift
  env CC="${HOST_CC_GCC}" CXX="${HOST_CXX_GCC}" CPP="${HOST_CPP_GCC}" \
    LD="${HOST_LD_GCC}" bmake -C ${PKGSRCDIR}/${PORT} \
    	build package install clean USE_CWRAPPERS=no HOST_TOOLCHAIN=gcc &&
    clean_after_build
  ## NB: This configuration has been tested, though not via this script,
  ## per se

  ## FIXME: Copy each build/CMakeCache.txt to maint. storage before clean_after_build
}


build_s2() {
  local PORT=$1; shift
  env PATH="${LLVM_CCACHE_LINKDIR}:${PATH}" \
    CC="clang" CXX="clang++" CPP="clang-cpp" LD="ld.lld" \
    bmake -C ${PKGSRCDIR}/${PORT} -DWITH_COMPILER_RT \
    	build package clean USE_CWRAPPERS=no PKGSRC_COMPILER=clang &&
    clean_after_build
}

## ---

## Assumption: site mk.conf already updated

## rebootstrap without cwrappers (or locking)
##
## NB mk.conf configured to prevent locking in these port builds
##
## Assumtion: mk.conf already configured for non-locking on these ports
for P in  pkgtools/cwrappers pkgtools/shlock pkgtools/digest \
                             sysutils/checkperms devel/nbpatch; do
  build_llvm_1 $P || break
done

## additional tools, previous to the stage 1 build
for P in  net/wget; do
  build_llvm_2 $P || break
done

## build stage-1 LLVM with host GCC, on Debian 8
for P in lang/llvm lang/clang devel/lld; do
  build_s1 $P || break
done

## additional tools, previous to the stage 2 build
##
## FIXME: Hard-coding the relative path for the symlinks, here
## as a matter of simplicity, though it's not portable
##
## ASSUMPTION: Site has installed a ccache configuration at e.g the
## pathname ${LOCALBASE}/etc/ccache.conf
##
## NB: Assuming it's a new ccache installation, it may not serve to
## speed up the initial stage-2 build but should serve to speed up any
## LLVM build subsequent of the stage-2 build.
build_s1 devel/ccache &&
  mkdir -p "${LLVM_CCACHE_LINKDIR}" &&
  { ln -s ${CCACHE_RELPATH} clang;
    ln -s ${CCACHE_RELPATH} clang++;
    ln -s ${LLD_RELPATH} ld;
  }



for P in lang/libunwind lang/llvm lang/clang \
   lang/libcxxabi lang/libcxx lang/compiler-rt devel/lld; do
  build_s2 $P || break
done

## NB: Manually installing rebuilt pkgs built within build_s2

## -- QA/Remarks

## FIXME/TBD: pkg zlib for all builds - compatibility with host bytecode

## NB: Configure LD libexec/PATH hacks for host lld e.g ld.lld-4.0 in the next
##
## ... SECONDLY, build
## lang/llvm lang/clang devel/lld
## using host CC
##
## NB: Configure LD libexec/PATH HACKS for devel/lld in the following
##
## .. THIRDLY, build
## lang/llvm lang/libunwind lang/libcxxabi lang/libcxx lang/compiler-rt devel/lld lang/clang
## ... using pkg llvm, clang, lld
##
## NB: also openmp ...


## NB: libtool breakage in the db4 build (in deps build for python 3.7) when configured for 'this'
##
## FIXME: libtool in the db4 build is using /usr/bin/ld even when nothing is configured for that
##
## ... and it cannot use ld.lld-4.0 from Debian 8 on Debian 8 ??
## ... even when the compiler is clang-4.0
##
## FIXME: db4 build needs host GCC - for no too obvious reasoning
##
## ... and something needs to replace db4
##
## db6 any less broken? compiled with host CC and the lld-as-ld libexec/PATH hack
##
## .. it's not any less broken:
# /usr/bin/ld: cannot find -lc++
##
## so, try ... re-building pkg libtool-base ? & then try to build db4 ?
## (NO - trivial shell scripts)
##
## or try building db4 with host CC (LLVM, clang 4.0) and USE_CWRAPPERS=no ?
## and no libtool '--tag' hack ...
##
## or try building it with explicit GNU libstdc++ usage? (still fails)
##
## NB: db4..db6 is not itself coded in c++ ?? it uses CC for build, but CXX
## via libtool, for some linking @ e.g libdb6_cxx-6.2.la
##
## so, try building db6 w/ CC=clang++-4.0 (and no cwrappers) [nope]
##
## no cwrappers, no local libtool fix, and deb. lld as /usr/bin/ld ?
## [still nope - broken tools infrast]
##
## ... OR: Just disable the bdb buildink3 deb in the python37 makefile
## (broad but effective)


