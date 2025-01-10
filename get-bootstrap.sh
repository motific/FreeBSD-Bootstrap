#!/bin/sh

# preloader for bootstrap script

mkdir -p /usr/local/sbin/motific
fetch https://raw.githubusercontent.com/motific/FreeBSD-Bootstrap/refs/heads/main/bootstrap.sh -o /usr/local/sbin/motific/bootstrap.sh
chmod +x /usr/local/sbin/motific/bootstrap.sh
/usr/local/sbin/motific/bootstrap.sh
