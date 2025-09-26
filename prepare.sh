#!/bin/bash
# Copyright (c) 2024 TQ-Systems GmbH

set -e

COMMAND="$1"
EM_BUILD_REF="$2"

# These variables will later be adjusted for release builds
VERSION=""
ROOTFS_VERSION=""
SUBDIR="snapshots"

# Filenames with or without version
FILE_AARCH64_TOOLCHAIN="emos-x86_64-aarch64-toolchain$VERSION.sh"
FILE_EM_AARCH64_BOOTLOADER="em-image-core-em-aarch64$VERSION.bootloader.tar"
FILE_EM_AARCH64_CORE_IMAGE="em-image-core-em-aarch64$ROOTFS_VERSION.tar"

log_error_and_exit() {
	echo >&2 "$1"; exit 1
}

set_base_env() {
	if [ -e "$DOCKER_COMPOSE_ENV" ]; then
		echo "Using existing $DOCKER_COMPOSE_ENV file"
		exit 0
	fi

	echo "$DOCKER_COMPOSE_ENV_CONTENT" > "$DOCKER_COMPOSE_ENV"

	if [ -n "$GOPRIVATE" ]; then
		echo "GOPRIVATE=$GOPRIVATE" >> "$DOCKER_COMPOSE_ENV"
	fi

	# Improve overview by adding a newline
	echo "" >> "$DOCKER_COMPOSE_ENV"
}

provide_file() {
	local variable="$1"
	local file="$2"
	local subdirs="$3"

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

		# Add variable to the Docker Compose environment file
		echo "$variable=./$TQEM_TMP_PATH/$file" >> "$DOCKER_COMPOSE_ENV"
	fi
}

provide_all_files() {
	[ -e "$DOCKER_COMPOSE_ENV" ] || log_error_and_exit "Missing $DOCKER_COMPOSE_ENV."


	provide_file PATH_AARCH64_TOOLCHAIN     "$FILE_AARCH64_TOOLCHAIN"     toolchain/aarch64
	provide_file PATH_EM_AARCH64_BOOTLOADER "$FILE_EM_AARCH64_BOOTLOADER" core-image/em-aarch64
	provide_file PATH_EM_AARCH64_CORE_IMAGE "$FILE_EM_AARCH64_CORE_IMAGE" core-image/em-aarch64
}

case "$COMMAND" in
	env)
		set_base_env
		;;
	files)
		# The files are needed for the builds - not for the pulls
		provide_all_files
		;;
	*)
		log_error_and_exit "Unknown command: $COMMAND"
		;;
esac
