#!/usr/bin/env bash
# rv_display CLion init.
#
# Project-specific bit: pin per-workspace west defaults (board, dir-fmt,
# runner) so plain `west build` / `west flash` work after bootstrap.
# Then delegate to zephyr-bootstrap's bundled default clion-init for
# the standard onboarding output (Attach-Directory hints from `west list`,
# debug setup guidance, etc.).
set -euo pipefail

WORKSPACE_DIR="$1"
APP_DIR="$2"

# 1. Pin west config for this workspace.
( cd "$WORKSPACE_DIR" \
	&& west config build.board nucleo_h753zi \
	&& west config build.dir-fmt 'build/{app_src}' \
	&& west config build.cmake-args -- '-DBOARD_FLASH_RUNNER=openocd -DBOARD_DEBUG_RUNNER=openocd' )
echo "  west config: board=nucleo_h753zi, dir-fmt=build/{app_src}, runner=openocd"

# 2. Delegate. ZEPHYR_BOOTSTRAP_DIR is exported by the bootstrap; fall
# back to the default install location if invoked manually.
DEFAULTS="${ZEPHYR_BOOTSTRAP_DIR:-$HOME/projects/zephyr-bootstrap}/ide-defaults"
DEFAULT_INIT="$DEFAULTS/clion-init.sh"
if [ -f "$DEFAULT_INIT" ]; then
	exec bash "$DEFAULT_INIT" "$WORKSPACE_DIR" "$APP_DIR"
else
	echo "Warning: bundled CLion default not found at $DEFAULT_INIT" >&2
fi
