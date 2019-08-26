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
  with pkgsrc and arbitrary upstream source code distributions
  [WorkInProgress]

## Platforms Tested - sysroot with pkgsrc

* Debian 8 (Linux 4.9.0) (amd64)
    * Bootstrap toolchain: LLVM 4 (Debian 8)
    * Note: pkgsrc cwrappers disabled during bootstrap, built and
      enabled post-bootstrap
    * Note: "Needs QA," primarily due to concerns pursuant of:
        * (A) updating to newer distsrc for some ports in pkgsrc,
          pursuant to active support in upstream development projects
          and site-local integration for built components
        * (B) addressing concerns that may be entailed of a lack of
          bytecode isolation in the initial usage case - in effect,
          pursuant to numerous link-time build failures
        * (C) addressing any particular characteristics of individual
          source systems -- common concerns, e.g providing a `--tag=cc`
          option for `libtool` in individual builds.
    * Note: **Toolchain bootstrap** -- with pkgsrc LLVM 8, GCC 8 builds
      --  configuration and testing for **sysroot bytecode isolation**
      [FIXME]
    * Note: Userspace bootstrap for the mk_sysroot project on Linux -
      primary initial usage case - Components (tmux, BASH, editor, git,
      ...)

* FreeBSD 11.2 (amd64)
    * Bootstrap toolchain: LLVM 8 (FreeBSD ports)
    * Note: pkgsrc cwrappers disabled during bootstrap and subsequently
    * Note: "Needs QA" primarily due to link-time errors, `-lgcc`, `-lgcc_s`
    * Note: GCC 8 and LLVM 8 built post-build -- see previous remarks
    * Note: QA/Testing for build configuration (mk_sysroot project on
      FreeBSD - primary initial usage case) (NB: "Control Group"
      metaphor for site-local QA/support with a site-local pkgsrc
      build configuration)

* Ubuntu 16.04 userspace chroot under Android 4 (Linux 3.4.39) (armv7l) [New]
    * Bootstrap toolchain: TBD (LLVM 6)

## Additional Remarks - Support Profiles

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
        * Note: Android chroot as a subset of container filesystems
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
                * Note that some hyperv support (e.g _vis a vis_ bhyve)
                  may preclude any simultaneous usage of other hyperv
                  support (e.g _vis a vis_ VirtualBox) on some hosts
                  operating system architectures (e.g FreeBSD)

* System Profile - Build and Install within **Android chroot Filesystem**

* System Profile - Build and Install within **Sysroot on Linux**

* System Profile - Build and Install within **Sysroot on FreeBSD**

* System Profile - Build with PC Linux/amd64 Sysroot, Install to
      **Mobile Linux/ARM Sysroot** e.g Android chroot or Termux Sysroot
    * NB - Existing Works: Termux Sysroot on Android
    * NB - Limited Support: Ubuntu chroot on Android [Indemnification
      Clause Here]
    * NB - Historic Works: Maemo on Nokia Platforms

* System Profile - Other: Support TBD

## Additional Remarks - Userspace Concerns

* Generalized Concept: Uniform userspace environment, for development
  and support -- Linux and FreeBSD hosts; specialized Android mobile
  environments

* Generalized Topic: Site Clouds and Host Systems - Generalized Concerns
    * Generalized Trust and User Identity
        * Note user identity methods on supported host platforms -  UNIX
          hosts
        * Note _trusted third party_ systems for user authentication in
          network infrastructure systems, such as with Kerberos 5
          and GSS-API; Vague analogy for web-based systems in OAUTH2
    * Network Architectures
        * IPv4 and IPv6 Adoption
        * Network Management
            * Host-specific system management methods for network
              interface configuration, network route configuration,
              nameservice configuration and name provisioning, and
              configuration and provisioning for network messaging
              services; note IPv4 and IPv6 management services as a
              subset of name provisioning services; note "Trust" layers
              for network routing, networking naming, and network
              messaging services
            * LDAP and the Open Systems Interconnect (OSI) Model
            * FreeRadius is not Active Directory
            * rsyslog(8)
    * Filesystems - Storage Devices, Filesystem Formats, Storage
      Provisioning, Filesystem Backup, and Data Recovery Services
        * See also: Generalized Trust and User Identity
    * Host-Based Service Frameworks
        * Note BSD RC
        * Note systemd on Linux
        * TBD: Integrating launchd (pkgsrc) within the host service
          framework, under one or more system profiles: Build-host
          sysroot runtime; Build-host container runtime; Cross-build and
          install for emulator/mobile runtime
        * Note daemontools supervise(8)

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
<!--  LocalWords:  Maemo filesystems Kerberos GSS OAUTH IPv nameservice
 -->
<!--  LocalWords:  LDAP OSI FreeRadius rsyslog systemd launchd runtime
 -->
<!--  LocalWords:  daemontools libtool tmux
 -->
