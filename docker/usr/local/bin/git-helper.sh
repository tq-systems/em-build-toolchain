#!/bin/bash

set -e

SCRIPT_NAME="$(basename "$0")"

# shellcheck source=/dev/null
. /usr/local/lib/tqem/shell/log.sh

usage() {
	echo "NAME
       $SCRIPT_NAME - helper script for git functions

SYNOPSIS
       $SCRIPT_NAME [MODE] [ARGS...]

MODES
       check-clean [DIRECTORY] - Check if the given directory is clean in git. The directory
                                 should be given relative to the repository root.
       check-tag   [VERSION]   - Check if the current commit is tagged with the given version.

DESCRIPTION
       This script provides commonly used Git functions.
"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
	usage; exit 0
fi

if [ $# -ne 2 ]; then
	tqem_log_error_and_exit "Unsupported number of arguments: $#"
fi


MODE="$1"
# Enable to pass a variable number of arguments after the mode
shift

# Check if a given directory is clean in git
check_clean() {
	local dir_rel="$1"
	if ! test -z "$(git status --porcelain "./${dir_rel}")"; then
		echo "Validation failed: Workspace is inconsistent in directory: ${dir_rel}."
		git status "./${dir_rel}"
		exit 1
	fi
}

# Check if the current commit is tagged with the given version
check_tag() {
	local version="$1"

	local tag
	tag="$(git describe --exact-match --tags HEAD 2>/dev/null || true)"

	# Tags have a leading 'v', versions do not
	if [ "$tag" != "v$version" ]; then
		tqem_log_error_and_exit "Version check failed: tag=${tag}, version=${version}"
	fi
}

case "$MODE" in
check-clean)
	check_clean "$@"
	;;
check-tag)
	check_tag "$@"
	;;
*)
	tqem_log_error_and_exit "Unknown mode: $MODE"
	;;
esac
