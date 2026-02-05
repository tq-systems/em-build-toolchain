#!/bin/bash
# Copyright (c) 2024 TQ-Systems GmbH

set -e

COMMAND="$1"
EM_BUILD_REF="$2"

# em-build releases have a semantic version tag (e.g. v1.2.3)
if [[ "$EM_BUILD_REF" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	VERSION="-${EM_BUILD_REF#v}"     # Add '-' and remove 'v' for version string
	ROOTFS_VERSION="$VERSION.rootfs" # Add suffix for core image releases only
	SUBDIR="releases"
else
	VERSION=""
	ROOTFS_VERSION=""
	SUBDIR="snapshots"
fi

# Filenames with or without version
FILE_AARCH64_TOOLCHAIN="emos-x86_64-aarch64-toolchain$VERSION.sh"
FILE_EM_AARCH64_BOOTLOADER="em-image-core-em-aarch64$VERSION.bootloader.tar"
FILE_EM_AARCH64_CORE_IMAGE="em-image-core-em-aarch64$ROOTFS_VERSION.tar"

log_error_and_exit() {
	echo >&2 "$1"; exit 1
}

set_env_file() {
	local variable="$1"
	local file="$2"

	echo "$variable=./$TQEM_TMP_PATH/$file" >> "$DOCKER_COMPOSE_ENV"
}

set_env() {
	if [ -e "$DOCKER_COMPOSE_ENV" ]; then
		echo "Using existing $DOCKER_COMPOSE_ENV file"
		exit 0
	fi

	echo "$DOCKER_COMPOSE_ENV_CONTENT" > "$DOCKER_COMPOSE_ENV"

	if [ -n "$GOPRIVATE" ]; then
		echo "GOPRIVATE=$GOPRIVATE" >> "$DOCKER_COMPOSE_ENV"
	fi

	set_env_file PATH_AARCH64_TOOLCHAIN     "$FILE_AARCH64_TOOLCHAIN"
	set_env_file PATH_EM_AARCH64_BOOTLOADER "$FILE_EM_AARCH64_BOOTLOADER"
	set_env_file PATH_EM_AARCH64_CORE_IMAGE "$FILE_EM_AARCH64_CORE_IMAGE"
}

copy_file() {
	local file="$1"
	local subdirs="$2"

	local tmp_path source_path
	tmp_path="$TQEM_TMP_PATH/$file"

	if [ -e "$tmp_path" ]; then
		# Images can easily switched during the development
		echo "Using existing file: $tmp_path"
	else
		# Check if the file can be copied from PATH_BASE_DEPLOY
		source_path="$TQEM_BASE_DEPLOY_PATH/$SUBDIR/emos/$EM_BUILD_REF/$subdirs/$file"
		if [ -e "$source_path" ]; then
			cp -v "$source_path" "$tmp_path"
		else
			log_error_and_exit "Missing file: $source_path"
		fi
	fi
}

copy_files() {
	copy_file "$FILE_AARCH64_TOOLCHAIN"     toolchain/aarch64
	copy_file "$FILE_EM_AARCH64_BOOTLOADER" core-image/em-aarch64
	copy_file "$FILE_EM_AARCH64_CORE_IMAGE" core-image/em-aarch64
}

case "$COMMAND" in
	env)
		set_env
		;;
	files)
		# The files are needed for the builds - not for the pulls
		copy_files
		;;
	*)
		log_error_and_exit "Unknown command: $COMMAND"
		;;
esac
