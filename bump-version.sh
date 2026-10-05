#!/bin/bash
# Copyright (c) 2026 TQ-Systems GmbH

set -e

VERSION="${1#v}"
IMAGES_FILE="ci/common/images.yml"
ENVIRONMENT_FILE="environment.mk"
SEMVER_REGEX='^v[0-9]+\.[0-9]+\.[0-9]+(-.+)?$'

check_em_build_ref() {
	local em_build_ref
	em_build_ref="$(awk '$1 == "EM_BUILD_REF" {print $3; exit}' "$ENVIRONMENT_FILE")"

	if [[ ! "$em_build_ref" =~ $SEMVER_REGEX ]]; then
		echo >&2 "Error: EM_BUILD_REF in $ENVIRONMENT_FILE needs a git tag with a semantic version."
		exit 1
	fi
}

set_toolchain_docker_tag() {
	local docker_tag="v${1}"
	sed -i "s/^\(  PUBLIC_TOOLCHAIN_DOCKER_TAG: '\)[^']*'/\1${docker_tag}'/" "$IMAGES_FILE"
}

check_em_build_ref
set_toolchain_docker_tag "$VERSION"
git add "$IMAGES_FILE"
