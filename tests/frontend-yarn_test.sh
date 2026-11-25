#!/bin/bash
#
# Copyright (c) 2026 TQ-Systems GmbH <license@tq-group.com>, D-82229 Seefeld, Germany. All rights reserved.
# Author: Hans-Christian Melzer and the Energy Manager development team
#
# This software is licensed under the TQ-Systems Product Software License Agreement Version 1.0.3 or any later version.
# You can obtain a copy of the License Agreement in the TQS (TQ-Systems Software Licenses) folder on the following website:
# https://www.tq-group.com/en/support/downloads/tq-software-license-conditions/
# In case of any license issues please contact license@tq-group.com.
#

# Tests for the SBOM handling in yarn-push: a frontend built with the SBOM plugin ships its
# bill of materials, a frontend built without the plugin warns instead of failing.

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
MAKEFILE="${SCRIPT_DIR}/../docker/opt/energy-manager/apps/public/frontend-yarn.mk"

APP_ID='demo-app'
BUILD_VARIANT='tq'
DIR_APP_ROOT='/apps/installed/demo-app'

RETURN_CODE=0

pass() { echo "PASS: $*"; }
fail() { echo >&2 "FAIL: $*"; RETURN_CODE=1; }

# Builds a frontend build directory and runs yarn-push against it. With 'with-sbom' the
# directory also holds the file the SBOM plugin writes by default.
run_yarn_push() {
	local mode="$1" tmpdir="$2" dist
	dist="${tmpdir}/frontend/dist/${BUILD_VARIANT}"

	mkdir -p "${dist}/static"
	echo 'console.log(1)' > "${dist}/static/index.js"
	echo 'third party notices' > "${dist}/ThirdPartyNotice.txt"

	if [[ "$mode" == 'with-sbom' ]]; then
		mkdir -p "${dist}/cyclonedx"
		echo '{"bomFormat":"CycloneDX"}' > "${dist}/cyclonedx/bom.json"
	fi

	make --no-print-directory -f "$MAKEFILE" yarn-push \
		DIR_FRONTEND="${tmpdir}/frontend" \
		DIR_PACKAGE="${tmpdir}/package" \
		DIR_APP_ROOT="$DIR_APP_ROOT" \
		BUILD_VARIANT="$BUILD_VARIANT" \
		APP_ID="$APP_ID" 2>&1
}

# --- A frontend built with the plugin ships its SBOM ---
TMPDIR_WITH="$(mktemp -d)"
TMPDIR_WITHOUT="$(mktemp -d)"
# Empty paths would make the cleanup delete from the root directory
: "${TMPDIR_WITH:?mktemp failed}" "${TMPDIR_WITHOUT:?mktemp failed}"
trap 'rm -rf "${TMPDIR_WITH:?}" "${TMPDIR_WITHOUT:?}"' EXIT

if run_yarn_push 'with-sbom' "$TMPDIR_WITH" > "${TMPDIR_WITH}/log"; then
	pass 'yarn-push succeeds for a frontend with SBOM'
else
	fail 'yarn-push succeeds for a frontend with SBOM'
	cat "${TMPDIR_WITH}/log"
fi

SBOM_IN_PACKAGE="${TMPDIR_WITH}/package/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/sbom/${APP_ID}.frontend-sbom.json"
if [[ -f "$SBOM_IN_PACKAGE" ]]; then
	pass 'SBOM is shipped from the default path cyclonedx/bom.json'
else
	fail 'SBOM is shipped from the default path cyclonedx/bom.json'
fi

# --- A frontend built without the plugin warns and keeps building ---
if run_yarn_push 'without-sbom' "$TMPDIR_WITHOUT" > "${TMPDIR_WITHOUT}/log"; then
	pass 'yarn-push succeeds for a frontend without SBOM'
else
	fail 'yarn-push succeeds for a frontend without SBOM'
	cat "${TMPDIR_WITHOUT}/log"
fi

if grep -q "Warning: Cannot find SBOM for ${APP_ID}" "${TMPDIR_WITHOUT}/log"; then
	pass 'missing SBOM is reported'
else
	fail 'missing SBOM is reported'
	cat "${TMPDIR_WITHOUT}/log"
fi

if [[ ! -e "${TMPDIR_WITHOUT}/package/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/sbom/${APP_ID}.frontend-sbom.json" ]]; then
	pass 'no SBOM is shipped when the frontend has none'
else
	fail 'no SBOM is shipped when the frontend has none'
fi

exit "$RETURN_CODE"
