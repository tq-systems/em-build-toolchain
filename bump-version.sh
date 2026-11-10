#!/bin/bash
#
# Copyright (c) 2026 TQ-Systems GmbH <license@tq-group.com>, D-82229 Seefeld, Germany. All rights reserved.
# Author: Christoph Krutz and the Energy Manager development team
#
# This software is licensed under the TQ-Systems Product Software License Agreement Version 1.0.3 or any later version.
# You can obtain a copy of the License Agreement in the TQS (TQ-Systems Software Licenses) folder on the following website:
# https://www.tq-group.com/en/support/downloads/tq-software-license-conditions/
# In case of any license issues please contact license@tq-group.com.
#

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
