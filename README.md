mk_sysroot
==========

## Generalized Goals

* Developing a sysroot -- in a manner semantically similar to LFS --
  using an LLVM toolchain and pkgsrc ports, with tool support provided
  as principally independent of the host OS, host compiler toolchain,
  and hardware profile on the build host [WorkInProgress]

* Prototyping a cross-compile system for one or more build-host
  sysroot and one or more of an installation host sysroot with pkgsrc,
  using an LLVM toolchain and -- insofar as may be required for any
  individual software component builds -- GCC [NeedsWork]

* Prototyping a system for using pkgsrc to install a Linux from
  Scratch kernel build and BSD-like base system (including a bootloader,
  e.g Grub or U-Boot, and text editor for console-interactive builds)
  for new Linux installations (TBD: System HW Profiles, Image Formats
  and Imaging Methods, and Usage Case/Component Profiles to support)
  [NeedsWork]

* Developing a Portable Infrastructure for Component-Oriented QA/Support
  with pkgsrc and arbitrary distribution upstream source code providers
  [WorkInProgress]

## Platforms Tested - sysroot with pkgsrc

* Debian 8 (Linux 4.9.0) (amd64)
    * Bootstrap toolchain: LLVM 4 (Debian 8)
    * Note: pkgsrc cwrappers disabled during bootstrap, built and
      enabled post-bootstrap
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

## Additional Remarks

* QA/Support - Infrastructure
    * Note Debian Alioth (Web-Based Q/A Infrastructure)
    * Note Kanbord (Web-Based Agile Development Support Service)

* QA/Support - Tools: Note GNATS send-pr (Email-like/Forms-like UI;
  Database-like infrastructure system)

* QA/Support - Tools: DocBook XML toolchain (LFS book; pkgsrc guide)

* System Profile - Install to **Pre-Container Filesystem**
    * Generalization -> Implementation
        * FreeBSD Jail Containers
        * Linux LXC
            * Note libvirt support [[href](https://libvirt.org/drvlxc.html)]
        * Post-Open Solaris (??)
        * POSIX-Like Host Namespace APIs
    * Special Concerns
        * Host Security Models
            * BSD MAC
            * SE Linux
            * Post-Open Solaris (??)
            * POSIX 1003.1e - The International Standard that Wasn't (??)
        * libvirt
            * libvirt XML configuration for Container Systems

* System Profile - Install to **Hypervirtualized Guest Filesystem**
    * Generalization -> Implementation
        * Bhyve
        * Xen
        * Privatized Systems
        * Hypervirtualized Network Cloud Infrastructure Systems
            * OpenStack
            * Privatized Systems - AWS

* System Profile - Install to **Emulator Filesystem**
    * Generalization -> Implementation
        * QEMU
        * VirtualBox
        * Privatized Systems
    * Special Concerns
        * libvirt
            * libvirt XML configuration for Emulator Systems
            * libvirt with QEMU _system_ (hyperv??) and _user_
              (userspace??) **emulator drivers**
                * Note that Some hyperv support (e.g _vis a vis_ bhyve)
                  may preclude any simultaneous usage of other hyperv
                  support (e.g _vis a vis_ VirtualBox) on some hosts
                  operating system architectures (e.g FreeBSD)

* System Profile - Build and Install within **Android chroot Filesystem**

* System Profile - Build and Install within **Sysroot on Linux**

* System Profile - Build and Install within **Sysroot on FreeBSD**
    * NB/Generalized Topic: Q/A "Control Group" for site-local pkgsrc
      builds

* System Profile - Build with PC Linux/amd64 Sysroot, Install to
      **Mobile Linux/ARM Sysroot** e.g Android chroot or Termux Sysroot
    * NB - Existing Works: Termux Sysroot on Android
    * NB - Limited Support: Ubuntu chroot on Android [Indemnification
      Clause Here]
    * NB - Historic Works: Maemo on Nokia Platforms

* System Profile - Other: Support TBD

<!--  LocalWords:  mk sysroot LFS LLVM toolchain pkgsrc WorkInProgress
 -->
<!--  LocalWords:  NeedsWork amd cwrappers distsrc bytecode FIXME lgcc
 -->
<!--  LocalWords:  FreeBSD userspace chroot armv TBD bootloader HW UI
 -->
<!--  LocalWords:  Kanbord DocBook Pre Filesystem LXC libvirt href APIs
 -->
<!--  LocalWords:  Solaris POSIX Namespace Hypervirtualized Bhyve Xen
 -->
<!--  LocalWords:  OpenStack QEMU VirtualBox hyperv vis bhyve Termux
 -->
<!--  LocalWords:  Maemo
 -->
