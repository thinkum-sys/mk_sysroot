#!/bin/sh

## deb_upgrade_staged.sh - Staged dist-upgrade scripting for Debian hosts

## Recommendation: New user logins should be disabled, on the host,
## before this script it initialized.

## Note: If running this script during an X Window System session, it
## may be run via such as tmux or GNU screen, thus allowing for a
## continuation even if the X Window System session is interrupted
## during upgrade.

## Recommendation: Run this under script - using GNU script if no
## portable BSD script command is available on the host - as in order to
## log the output for later review, on event of "Q/A Issues"

## Recommendation: Consider editing /etc/apt/apt.conf.d/70debconf
## before completing the full upgrade

## NB: GNU libstdc++ may be much of a source of conflicts during dist-upgrade

## FIXME: Things like this would break the upgrade process, on all hosts
##
# libc6-dev:amd64 (2.24-11+deb9u4) breaks binutils (<< 2.26) and is unpacked but not configured
##
## ... thus the 'apt-get -f install' at the start

## NB: temporarily
#    update-alternatives --remove-all ld
## while upgrading binutils

## --

PKG_EARLY=

## --

APT_GET=$(which aptitude || which apt-get)

## --

THIS=$(readlink -f "$0")
HERE=$(dirname "${THIS}")
THIS=$(basename "${THIS}")

msg() {
  echo "#-- $@"
}
warn () {
  msg "$@" 1>&2
}
err () {
 warn "$@"
 exit ${_ECODE:-1}
}

dgrep_for() {
for P in $@; do
  grep-status -n -sPackage \
    -FPackage "${P}" -a \
    -FStatus "install ok installed"
done
}

set -e

PKG_REQUIRED=$(grep-status -n -sPackage \
               -FStatus "install ok installed" \
               -a -FPriority required)

## ??
# P_UP=$(grep-status -n -sPackage \
#                 -FStatus "install ok installed" |
#            grep-available -n -SVersion ...

#PKG_LIBSIGCXX=$(dgrep_for "libsigc++")

msg "Kernel: $(uname -a)"
msg "Release:"
lsb_release -a

msg "Fix any earlier installation failures"
apt-get -f install

msg "Clear Package Selections"
## NB: The following does more than unmarking packages, after an install failure
##
## FIXME: This may be specific to aptitude & not apt-get
${APT_GET} keep-all


msg "Safe Upgrade for Required Packages"
## NB: If this stage fails initially, it will now be restarted
## gracefully with this scripting
${APT_GET} safe-upgrade -y ${PKG_REQUIRED}

## FIXME : If rebooting after the previous - this may require a certain
## degree of systems management infrastructure, to restart/continue the
## upgrade script after reboot.

#msg "Second Safe Upgrade for Required Packages (Allow New)"
## NB: Try to address a situation of the required-packages upgrade,
## i.e "The following packages have been kept back," with a
## second upgrade for required packages (probably useless)
#${APT_GET} safe-upgrade  --allow-new-upgrades --allow-new-installs \
#   -y ${PKG_REQUIRED} || ${APT_GET} -f install


# msg "Safe Upgrade for Aptitude (Allow New)"
# ## NB: Try to address a situation of the required-packages upgrade,
# ## i.e "The following packages have been kept back," via a
# ## second upgrade for required packages
# ${APT_GET} safe-upgrade  --allow-new-upgrades --allow-new-installs \
#   -y aptitude || ${APT_GET} -f install
##
## ^ NB: aptitude was showing as "kept back" when upgrading from
# Debian 8 to Debian 9 (amd64) thus rendering the previous shell call
# superfluous.
##
## This requries Q/A:
# ${APT_GET} dist-upgrade  --allow-new-upgrades --allow-new-installs aptitude
## ... to an extent that it is, in effect, unusable

## NB: Subsequently, it should be safe to interrupt the safe-upgrade process
##
##     ... which is probably good, considering that it can take as long
##     as to compile the kernel itself -- or longer -- for the installer
##     to traverse its depdendencies graph to a point of a locally usable
##     "Upgrade Solution"

## TBD: Select for install on tags (needs filtering for "Manually Installed")
##
## e.g
## grep-debtags -n -sPackage -FTag "devel::compiler" | xargs -n1 grep-status -n -sPackage -FStatus "install ok installed" -a -FPackage
## ... slow but effectual, pursuant to the "Manually Installed" filter && ${APT_GET} install

## TBD: Iterating per dpkg-architecture(1) ...


# msg "Safe Upgrade for Host  - Reinstall perl-base"
# ## NB: This would be useless at the cmdline.
# ## Can it not resolve the dependencies withtout deb removals en masse?
# ${APT_GET} --safe-resolver --allow-new-upgrades --allow-new-installs install \
#   perl-base

#msg "Safe Upgrade for Host  - Reinstall PERL"
## NB: This would be useless at the cmdline.
## Can it not resolve the dependencies withtout deb removals en masse?
#${APT_GET} --safe-resolver --allow-new-upgrades --allow-new-installs install \
#  perl-base perl-modules
## ^ the "safe resolver" does nothing for those upgrades.
## ^ the "full resolver" is by no means a solution

## NB: libstd++6, libstdc++6:i386

## Let it run, and see what non-solution it produces (??) is not a solution

msg "Safe Upgrade for Host  - Reinstall Manually Installed Packages"
apt-mark showmanual | xargs ${APT_GET} \
 --safe-resolver --allow-new-upgrades --allow-new-installs install \


msg "Safe Upgrade for Host  - Upgrades (No Fetch, No Install)"
${APT_GET} --schedule-only --allow-new-upgrades --allow-new-installs safe-upgrade
