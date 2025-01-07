#!/bin/sh

## todo: get the release build from uname -r
## todo: BastilleBSD doesn't mention stable, we need to rewrite it
OS_VERSION=14.2-RELEASE

## install bastille
pkg install --yes bastille git-lite ca_root_nss
sysrc bastille_enable=YES
sysrc bastille_rcorder=YES

## update doas
echo -e 'permit nopass :wheel cmd bastille' >> /usr/local/etc/doas.conf

## configure Bastille for ZFS
## todo: test for ZFS and skip
sysrc -f /usr/local/etc/bastille/bastille.conf bastille_zfs_enable=YES
sysrc -f /usr/local/etc/bastille/bastille.conf bastille_zfs_zpool=zroot

bastille setup vnet

## pull the os-version
bastille bootstrap ${OS_VERSION}
bastille bootstrap https://github.com/shadow53-bastille/pkg-latest
