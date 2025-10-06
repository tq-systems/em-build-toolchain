#!/bin/sh

usage() {
	echo >&2 'Usage: em-app-install <ip> <empkg> <opt:root password>'
	echo >&2
	echo >&2 'Install any valid Energy Manager app package (*.empkg) into app file system.'
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
APP_FILE="$2"
SSHPASS=""

if [ ! -e "$APP_FILE" ]; then
	"File does not exist: $APP_FILE"
	exit 1
fi

# has at least 3 input args and length of third is non-zero (ROOT_PW)
if [ $# -gt 2 ] && [ -n "$3" ]; then
	SSHPASS='sshpass -p '${3}' '
fi

# Pipe bundle through stdin instead of using scp to avoid duplicate password check
# shellcheck disable=SC2016
dd if="$APP_FILE" status=progress | $SSHPASS ssh \
	-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa -o LogLevel=ERROR \
	root@"$TARGET_IP" '
	set -e
	PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

	DIR="$(mktemp -d)"
	cd "$DIR"

	cat > app.empkg
	empkg install "$DIR"/app.empkg
	rm -rf "$DIR"
'
