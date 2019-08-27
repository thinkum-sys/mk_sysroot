#!/bin/sh

## NB: LLVM on Debian 8

PKG_CC='clang-4.0'
PKG_CXX='clang++-4.0'
PKG_CPP='clang-cpp-4.0'
PKG_LD='ld.lld-4.0'


for P in  pkgtools/cwrappers pkgtools/shlock pkgtools/digest \
                             sysutils/checkperms devel/nbpatch; do
  env CC="${PKG_CC}" CXX="${PKG_CXX}" CPP="${PKG_CPP}" LD="${PKG_LD}" \
    bmake -C /usr/pkgsrc/${P} \
    	build package install clean USE_CWRAPPERS=no || break
done
