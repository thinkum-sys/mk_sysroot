mk_sysroot
==========

## Generalized Goals

* Developing a sysroot in a manner similar to LFS, using an LLVM
  toolchain ad pkgsrc ports, independent of the OS on the build host
  
* Prototyping a cross-compile system for one or more build-host
  sysroot and one or more of an installation host sysroot with pkgsrc,
  LLVM, and -- insofar as may be required for any indiviual software
  component builds -- GCC


## Platforms Tested - sysroot with pkgsrc

* Debian 8 (Linux 4.9.0) (amd64)
    * Bootstrap toolchain: LLVM 4 (Debian 8)
    * Note: pkgsrc cwrappers disabled during bootstrap, built and
      enabled post-boostrap
    * Note: "Needs QA" primarily due to concerns pursuant of updating
      to newer distsrc in pkgsrc
    * Note: GCC 8 and LLVM 8 built post-build -- no sysroot bytecode
      isolation [FIXME]

* FreeBSD 11.2 (amd64)
    * Bootstrap toolchain: LLVM 8 (FreeBSD ports)
    * Note: pkgsrc cwrappers disabled during bootstrap and subsequently
    * Note: "Needs QA" primarily due to link-time errors, `-lgcc`, `-lgcc_s`
    * Note: GCC 8 and LLVM 8 built post-build -- see previous remarks

* Ubuntu 16.04 userspace chroot under Android 4 (Linux 3.4.39) (armv7l) [New]
    * Bootstrap toolchain: TBD
