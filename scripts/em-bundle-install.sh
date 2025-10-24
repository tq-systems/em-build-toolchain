#!/bin/bash
# Copyright (c) 2025 TQ-Systems GmbH <license@tq-group.com>, D-82229 Seefeld, Germany. All rights reserved.
# License: TQSSLA-1.0.4 (TQ-Systems Software License Agreement Version 1.0.4)

set -e

SCRIPT_NAME="$(basename "$0")"
usage() {
	echo "$SCRIPT_NAME

NAME
       $SCRIPT_NAME - install a bundle via SSH

SYNOPSIS
       $SCRIPT_NAME IP_ADDRESS BUNDLE [OPTIONS]

OPTIONS
       -f, --factory-reset
              run a factory reset during the update process,
              this option is highly recommended for downgrades
       -p, --password PASSWORD
              provide the root password for non-interactive execution

DESCRIPTION
       The script installs an Energy Manager bundle over an SSH connection.
       This requires the device's root password and an enabled SSH server on
       the device. The script respects the machine type, all other
       incompatibilities are ignored. To use the password argument, the sshpass
       program is required on the host system."
}

fatal() {
	echo >&2 "$1"
	exit 1
}

if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
	usage; exit 0
fi

if [ $# -lt 2 ] || [ $# -gt 5 ]; then
	fatal "Number of arguments is not supported: $#"
fi

TARGET_IP="$1"
BUNDLE="$2"

FACTORY_RESET=""
SSHPASS=""
if [ $# -ge 2 ]; then
	shift;shift
	# shellcheck disable=SC3057
	while [ "${1:0:1}" = '-' ]; do
		arg="$1"; shift
		case "$arg" in
		-f|--factory-reset)
			FACTORY_RESET="--factory-reset"
			;;
		-p|--password)
			[ -z "$1" ] && fatal "The value for the password argument is missing"
			SSHPASS='sshpass -p '${1}' '
			shift
			;;
		*)
			fatal "unknown option: $arg"
			;;
		esac
	done
fi

# Pipe bundle through stdin instead of using scp to avoid duplicate password check
# shellcheck disable=SC2016
dd if="$BUNDLE" status=progress | $SSHPASS ssh \
	-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa -o LogLevel=ERROR \
	root@"$TARGET_IP" '
	set -e
	PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

	touch /run/ignore-compatible

	cd /update
	cat > upgrade-bundle.raucb
	emos-upgrade install '"$FACTORY_RESET"' upgrade-bundle.raucb
'
