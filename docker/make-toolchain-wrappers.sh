#!/bin/bash

set -e

declare -A TOOLS=(
	[CC]=gcc
	[CXX]=g++
	[CPP]=cpp
	[AS]=as
	[LD]=ld
	[GDB]=gdb
	[STRIP]=strip
	[RANLIB]=ranlib
	[OBJCOPY]=objcopy
	[OBJDUMP]=objdump
	[AR]=ar
	[NM]=nm
)

WRAPPERDIR=/opt/energy-manager/bin
ENVSCRIPT=$OECORE_TARGET_SYSROOT/environment-setup.d/toolchain-wrappers.sh

mkdir -p "$WRAPPERDIR" "$(dirname "$ENVSCRIPT")"
echo "PATH=$WRAPPERDIR:\$PATH" > "$ENVSCRIPT"

for tool in "${!TOOLS[@]}"; do
	eval "cmd=\"\$$tool\""
	# shellcheck disable=SC2154,SC2086
	set -- $cmd
	name="$1"; shift
	exe="$(command -v "$name")"
	wrapper="$CROSS_COMPILE${TOOLS[$tool]}"

	(
		echo '#!/bin/sh'
		echo 'exec' "$exe" "$@" '"$@"'
	) > "$WRAPPERDIR/$wrapper"
	chmod +x "$WRAPPERDIR/$wrapper"

	echo "export $tool=$wrapper" >> "$ENVSCRIPT"
done
