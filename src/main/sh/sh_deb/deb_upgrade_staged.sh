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

set -e

PKG_REQUIRED=$(grep-status -n -sPackage \
               -FStatus "install ok installed" \
               -a -FPriority required)

PKG_LIBSIGCXX=$(grep-status -n -sPackage \
                 -FPackage "libsigc++" \
                 -a -FStatus "install ok installed")

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

#if [ "x${PKG_LIBSIGCXX}" != "x" ]; then
#msg "Full Install-Based Upgrade for GNU libsigc++ ${PKG_LIBSIGCXX}"
## NB: safe-ugrade does nothing here. dist-upgrade similarly,
##     ... and even this is useless:
# ${APT_GET} --safe-resolver --allow-new-upgrades --allow-new-installs \
#    install "${PKG_LIBSIGCXX}"
## ... also useless:
# ${APT_GET} --full-resolver --allow-new-upgrades --allow-new-installs \
#    install "${PKG_LIBSIGCXX}"
## So, this ....
#fi

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

msg "Safe Upgrade for Host  - Select Upgrades (No Fetch, No Install)"

${APT_GET} --schedule-only --allow-new-upgrades --allow-new-installs safe-upgrade
