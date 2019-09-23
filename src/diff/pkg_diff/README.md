Patches for pkgsrc, pkgsrc-wip
==============================

## Patches With Descriptions

### Towards the origin of the mk_sysroot project

**pkgsrc-wip:** patch_wip-musl_update-1.1.23.diff

### Patches onto pkgsrc, pkgsrc-wip Emacs support

The second patch, in the following, requries the first patch of the set
in order to function normally

* **pkgsrc main:** patch_emacs27-support.diff
* **pkgsrc-wip:**  patch_wip-emacs-support.diff

### Patches onto pkgsrc bootstrap/bootstrap

**pkgsrc main:** patch_bootstrap-bootstrap_toolchain-passthru.diff

## Patches Without Descriptions

* thinkum-sys:thinkum:56fe37945f2 - "devel/boost-libs: Initial update
  (Annotated) for boost stacktrace libs" - concerning addr2line
  hard-coded path and libbacktrace support for boost stacktrace; TBD
  options.mk for boost-libs; TBD build boost-libs with GCC on Debian 10
  (The jam build fails w/ GCC - OK when building with LLVM on Debian 10)
  (PROV: devel/boost-libs may be a build-dep of
  textproc/source-highlight, thus a build-dep of textproc/gtk-doc)

* ......

* NB: libtool hacks

