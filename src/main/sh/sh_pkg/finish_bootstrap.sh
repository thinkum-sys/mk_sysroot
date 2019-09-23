#!/bin/sh

HOST_TOOLCHAIN=${HOST_TOOLCHAIN:-clang}

## FIXME: set LOCALBASE local to this shell script
## - needed for mozilla-rootcerts install [NB: wget]
## - needed for local trust registry
##   for GPG after mozilla-rootcerts install (TBD)
## - see also: pkgsrc security/mozilla-rootcerts/MESSAGE
## - NB security/mozilla-rootcerts-openssl
##   is not normally installed under an unpriv. pkgsrc installation

PKG_CC=${PKG_CC:-${CC:-'clang-7'}}
PKG_CXX=${PKG_CXX:-${CXX:-'clang++-7'}}
PKG_CPP=${PKG_CPP:-${CPP:-'clang-cpp-7'}}
PKG_LD=${PKG_LD:-${LD:-'ld.lld-7'}}

FINISH_BOOTSTRAP_PKGS="pkgtools/libnbcompat
 pkgtools/cwrappers
 pkgtools/shlock
 pkgtools/digest
 sysutils/checkperms
 devel/nbpatch"

LLVM_STAGE1_PKGS="lang/llvm
 lang/clang
 devel/lld"

## must specify each manually, to build the stage-2 pkg
## using the stage-1 install - pursuant to installing the
## entire set of stage-2 built pkgs, after stage-2 build
## (thus, in effect, a reinstall)
LLVM_STAGE2_PKGS="lang/llvm
  lang/libcxxabi
  lang/libcxx
  lang/libunwind
  lang/compiler-rt
  lang/clang
  devel/lld"

THIS=$(readlink -f "$0")
HERE=$(dirname "${THIS}")
THIS=$(basename "${THIS}")

msg(){
  echo "#-- ${THIS:-$0} : $@"
}

set -e

msg "Finish bootstrap with host toolchain ${HOST_TOOLCHAIN} \
- ${FINISH_BOOTSTRAP_PKGS}"

for P in ${FINISH_BOOTSTRAP_PKGS}; do
  msg "Build for in-place update: ${P}"

  bmake -C /usr/pkgsrc/${P} build package \
   CC="${PKG_CC}" CXX="${PKG_CXX}" CPP="${PKG_CPP}" LD="${PKG_LD}" \
   USE_CWRAPPERS=no HOST_TOOLCHAIN=${HOST_TOOLCHAIN} || exit $?

  BUILT_PKG=$(bmake -C /usr/pkgsrc/${P} -D.MAKE.EXPAND_VARIABLES -V PKGFILE)
  WHICH=$(bmake -C /usr/pkgsrc/${P} -D.MAKE.EXPAND_VARIABLES -V PKGNAME)
  pkg_delete -f ${WHICH}
#  bmake -C /usr/pkgsrc/${P} install
  pkg_add ${BUILT_PKG}
done

## ----------

## NB: net/wget - substantial deps graph when building w/ openssl support
## - needs fetch-script prelim, using host wget
## - and subsq. host certs integration
##
## it's not all as simple as the shell cmd under a config:
msg "Build net/wget"
make -C /usr/pkgsrc/net/wget clean build package install \
  HOST_TOOLCHAIN=${HOST_TOOLCHAIN} HOST_WGET=$(which wget)

${LOCALBASE}/sbin/mozilla-rootcerts install

## FIXME:
## - Build ccache
## - Create ccache storage dir
## - Add stub ccache.conf under LOCALBASE

## ----------

## FIXME: Configure a libexec path for CCACHE and the host LLVM installation


msg "Build LLVM stage-1, host toolchain - ${LLVM_STAGE1_PKGS}"

for P in ${LLVM_STAGE1_PKGS}; do
## FIXME: Use a PATH for CCACHE and the host LLVM installation
  msg "Build LLVM stage-1 : $P"
    env CCACHE_RECACHE=defined  bmake -C /usr/pkgsrc/${P} \
    clean build package install \
      USE_CWRAPPERS=no HOST_TOOLCHAIN=${HOST_TOOLCHAIN} || exit $?
done

## FIXME: Now store the stage-1 file - each PKGFILE - under a prefix
## directory, along with the CMakeCache.txt for eaach. The set of
## stage-1 PKGFILE would then be available for reverting the tolchain
## to stage-2 on event of failure in or subsequent to the stage-2 build.
## Furthermore, each CMakeCache.txt would then be available for review
## as to the build configuration for the stage-1 build.

## FIXME: stage-2 LLVM builds failing w/ local config on Debian 10,
## some not until linking @ late in the build

## NB: very long "Link time" for libclang.so in stage-1 build
##     ... even when using LLD (Debian 8 LLVM 7 dist)
##     ... with LLD runing on four CPUs
##
## Could this be in any ways improved with an appropriate configuration
## for LLVM LTO?
##
## NB: Update config to use -nostdlib -- Linux Host, should not be
## problematic elsewhere -- as something in the lld call for stage-1
## is accessing /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25
## as well as [FIXME]
## /lib/x86_64-linux-gnu/libz.so.1.2.11
## /usr/lib/x86_64-linux-gnu/libffi.so.6.0.4
## /usr/lib/x86_64-linux-gnu/libedit.so.2.0.59
## ...
## ... and somehow ...
## /usr/lib/x86_64-linux-gnu/libbsd.so.0.9.1
##
## TBD: in the lang/lvm build
##  - non user-settable (??) HAVE_LIBZ_Z:INTERNAL
##  - user-settable FFI_LIBRARY_DIR & pkgsrc libffi + port needs build-dep update
##  - user-settable ICONV_LIBRARY_PATH && pkgsrc converters/libiconv + port needs build-dep update
##  ?? user-settable .. using GNU ld.gold (??) GOLD_EXECUTABLE (


## FIXME: Configure a libexec path for CCACHE and the pkgsrc LLVM installation

## then try building LLVM stage-2, using the resulting LLVM stage-1
##
## NB: mk-files config defaulting to using pkg LLVM (stage-1 at this time)

msg "Build LLVM stage-2, LLVM toolchain in pkgsrc - ${LLVM_STAGE2_PKGS}"

## NB: The stage-2 build should be linked onto pkgsrc libc++, libc++abi
##     rather than host libc++, libc++abi

for P in ${LLVM_STAGE2_PKGS}; do
## FIXME: Use a PATH for CCACHE and the pkgsrc LLVM installation
  msg "Build LLVM stage-2 : $P"

  env CCACHE_RECACHE=defined bmake -C /usr/pkgsrc/${P} \
    clean build package USE_CWRAPPERS=no || exit $?

  BUILT_PKG=$(bmake -C /usr/pkgsrc/${P} -D.MAKE.EXPAND_VARIABLES -V PKGFILE)
  WHICH=$(bmake -C /usr/pkgsrc/${P} -D.MAKE.EXPAND_VARIABLES -V PKGNAME)
  pkg_delete -f ${WHICH}
#  bmake -C /usr/pkgsrc/${P} install
  pkg_add ${BUILT_PKG}
done

## FIXME: For each LLVM_STAGE2_PKGS
## also store the BUILDDIR/CMakeCache.txt

## FIXME: if configured to, also run 'bmake clean' for each

## FIXME: re-install the LLVM toolchain, from the stage-2 built pkgs


##
## subsq:
## - ccache && add local libexec hack to filesystem and PATH
## - tmux
## - ...

## subsq: ... userspace builds w/ LLVM stage-2
##
## - sysutils/nbase
## - ...
## - tmux
## - ...
## - tig
## - git...
## - "Preferred editor"
## - .... GNOME ....
