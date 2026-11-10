#!/bin/sh
#
# Copyright (c) 2025-2026 TQ-Systems GmbH <license@tq-group.com>, D-82229 Seefeld, Germany. All rights reserved.
# Author: Christoph Krutz and the Energy Manager development team
#
# This software is licensed under the TQ-Systems Product Software License Agreement Version 1.0.3 or any later version.
# You can obtain a copy of the License Agreement in the TQS (TQ-Systems Software Licenses) folder on the following website:
# https://www.tq-group.com/en/support/downloads/tq-software-license-conditions/
# In case of any license issues please contact license@tq-group.com.
#

SCRIPT_NAME="$(basename "$0")"
usage() {
	echo "$SCRIPT_NAME

NAME
       $SCRIPT_NAME - uninstall an application via SSH

SYNOPSIS
       $SCRIPT_NAME IP_ADDRESS APP_ID [PASSWORD]

DESCRIPTION
       Uninstall Energy Manager app package from app file system."
}

if [ "$1" = '--help' ] || [ "$1" = '-h' ]; then
	usage
	exit 0
fi

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
	usage
	exit 1
fi

set -e

TARGET_IP="$1"
APP_ID="$2"
SSHPASS=""

# has at least 3 input args and length of third is non-zero (ROOT_PW)
if [ $# -gt 2 ] && [ -n "$3" ]; then
	SSHPASS='sshpass -p '${3}' '
fi

# Uninstall app and enable it again, if it is builtin
$SSHPASS ssh \
	-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa -o LogLevel=ERROR \
	root@"$TARGET_IP" "
	set -e
	PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

	empkg uninstall \"$APP_ID\"

	if [ -e \"/apps/installed/$APP_ID\" ]; then
		empkg enable \"$APP_ID\"
	fi
"
