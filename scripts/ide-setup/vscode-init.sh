#!/usr/bin/env bash
# rv_display VSCode init.
#
# Project-specific bit: pin per-workspace west defaults (board, dir-fmt,
# runner) so plain `west build` / `west flash` work after bootstrap.
# Then delegate the .code-workspace + .vscode/tasks.json generation to
# zephyr-bootstrap's bundled default vscode-init -- no point duplicating
# the JSON here.
set -euo pipefail

WORKSPACE_DIR="$1"
APP_DIR="$2"

# 1. Pin west config for this workspace.
( cd "$WORKSPACE_DIR" \
	&& west config build.board nucleo_h753zi \
	&& west config build.dir-fmt 'build/{app_src}' \
	&& west config build.cmake-args -- '-DBOARD_FLASH_RUNNER=openocd -DBOARD_DEBUG_RUNNER=openocd' )
echo "  west config: board=nucleo_h753zi, dir-fmt=build/{app_src}, runner=openocd"

# 2. Delegate the rest. ZEPHYR_BOOTSTRAP_DIR is exported by the bootstrap
# before invoking project init scripts; fall back to the default install
# location if invoked manually.
DEFAULTS="${ZEPHYR_BOOTSTRAP_DIR:-$HOME/projects/zephyr-bootstrap}/ide-defaults"
DEFAULT_INIT="$DEFAULTS/vscode-init.sh"
if [ -f "$DEFAULT_INIT" ]; then
	exec bash "$DEFAULT_INIT" "$WORKSPACE_DIR" "$APP_DIR"
else
	echo "Warning: bundled VSCode default not found at $DEFAULT_INIT" >&2
	echo "Project's west config defaults are set, but no .code-workspace was generated." >&2
fi
