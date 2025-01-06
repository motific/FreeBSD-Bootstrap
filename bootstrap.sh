#!/bin/sh

# BSD 3-Clause License
# Copyright (c) 2025, James Snell <james.snell@motific.com>
# All rights reserved
# 
# https://github.com/motific/FreeBSD-Bootstrap
# 
# Script to move to pkgbase, add a user, and default packages
# 

USER_NAME='james'
## todo: bsddialog option for user name

sysrc powerd_enable="YES"
sysrc powerd_flags="-a hiadaptive -b adaptive"
service powerd start

## set up pkg repos for latest packages and pkgbase
## info: pkgbase installation [https://wiki.freebsd.org/PkgBase]
## info: reddit [https://www.reddit.com/r/freebsd/comments/1d08a6c/preparing_for_greater_support_of_pkgbase_for/]
mkdir -p /usr/local/etc/pkg/repos/
echo -e 'FreeBSD: {\n  enabled: no\n}' > /usr/local/etc/pkg/repos/FreeBSD.conf
echo -e 'FreeBSD-base: {\n  url: "https://pkg.freebsd.org/${ABI}/base_weekly",\n  mirror_type: "srv",\n  signature_type: "fingerprints",\n  fingerprints: "/usr/share/keys/pkg",\n  enabled: yes\n}' > /usr/local/etc/pkg/repos/FreeBSD-base.conf
echo -e 'FreeBSD-kmods-latest: {\n  url: "https://pkg.freebsd.org/${ABI}/kmods_latest_${VERSION_MINOR}",\n  mirror_type: "srv",\n  signature_type: "fingerprints",\n  fingerprints: "/usr/share/keys/pkg",\n  enabled: yes\n}' > /usr/local/etc/pkg/repos/FreeBSD-kmods.conf
echo -e 'FreeBSD-pkg-latest: {\n  url: "https://pkg.freebsd.org/${ABI}/latest",\n  enabled: yes\n}' > /usr/local/etc/pkg/repos/FreeBSD-pkg-latest.conf
pkg bootstrap --yes
echo -e '\nBACKUP_LIBRARIES=true\nBACKUP_LIBRARY_PATH=/usr/local/lib/compat/pkg\n' >> /usr/local/etc/pkg.conf
pkg install --yes -r FreeBSD-base -g 'FreeBSD-*'
pkg update --force --quiet
pkg upgrade --yes

## todo: do these need saving?
cp /etc/master.passwd.pkgsave /etc/master.passwd
cp /etc/group.pkgsave /etc/group
cp /etc/sysctl.conf.pkgsave /etc/sysctl.conf

## after installing pkgbase you need to remake the password database
pwd_mkdb -p /etc/master.passwd

## clean up pkgbase installation
find / -name \*.pkgsave -delete
rm /boot/kernel/linker.hints
cp /tmp/up/boot/loader.efi /boot/efi/efi/freebsd/loader.efi
cp /tmp/up/boot/loader.efi /boot/efi/efi/boot/bootx64.efi

## create user
pw useradd -m -s /bin/sh -n $USER_NAME
pw usermod -n $USER_NAME -h 0
pw groupmod -n wheel -m $USER_NAME

## default packages
pkg install --yes doas sshd tmux

## package: doas
echo -e 'permit :wheel\npermit nopass :wheel cmd shutdown\npermit nopass :wheel cmd pkg\n' > /usr/local/etc/doas.conf
sysrc doas_enable=YES

## package: sshd
cp -a /etc/ssh /etc/ssh.bak
## disable insecure algorithms
sysrc sshd_dsa_enable="no"
sysrc sshd_ecdsa_enable="no"
sysrc sshd_ed25519_enable="yes"
sysrc sshd_rsa_enable="yes"
## remove weak keys
mv /etc/ssh/moduli /etc/ssh/moduli.bak
awk '$5 >= 3071' /etc/ssh/moduli.bak > /etc/ssh/moduli
## restrict weak algorithms [https://sshaudit.com]
echo -e "\n# Restrict insecure key exchange, cipher, and MAC algorithms\nKexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com\n" >> /etc/ssh/sshd_config
## todo: create/import ssh public key [https://www.cyberciti.biz/faq/freebsd-setting-up-public-key-password-less-ssh-login/]
## todo: disable password access
sysrc sshd_enable=YES

## todo: download system update scripts
## todo: trigger post-reboot cron jobs

shutdown -r now
