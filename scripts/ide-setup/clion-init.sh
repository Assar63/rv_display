#!/usr/bin/env bash
# rv_display CLion init -- verify the committed .idea/runConfigurations/
# files made it through the clone and print onboarding guidance.
#
# Invoked by zephyr-bootstrap's new-workspace.sh when called with
# --ide=clion. Receives the workspace dir as $1.
set -euo pipefail

WORKSPACE_DIR="$1"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="$(basename "$APP_DIR")"

# Pin per-workspace west defaults so `west build`/`west flash` Just Work.
( cd "$WORKSPACE_DIR" \
	&& west config build.board nucleo_h753zi \
	&& west config build.dir-fmt 'build/{app_src}' \
	&& west config build.cmake-args -- '-DBOARD_FLASH_RUNNER=openocd -DBOARD_DEBUG_RUNNER=openocd' )
echo "  west config: board=nucleo_h753zi, dir-fmt=build/{app_src}, runner=openocd"

if [ ! -d "$APP_DIR/.idea/runConfigurations" ]; then
	echo "Warning: $APP_DIR/.idea/runConfigurations/ missing -- did the run configs get committed?" >&2
fi

cat <<EOF
CLion setup ready.

  1. Open this folder as the CLion project (NOT the workspace root):
       $APP_DIR
  2. CMakePresets.json is autodetected -- pick the configure preset
     matching the board you're building for.
  3. Run configurations (Flash, OpenOCD GDB Server, Serial Monitor)
     load from .idea/runConfigurations/.

  Debug (one-time machine-local setup, not committed):
    - Settings -> Build, Execution, Deployment -> Toolchains -> + System.
      Set C/C++ compiler and Debugger to the matching toolchain binaries
      under \$ZEPHYR_SDK_INSTALL_DIR/<arch>-zephyr-*/bin/ (e.g.
      arm-zephyr-eabi for Cortex-M, riscv64-zephyr-elf for RISC-V).
    - Run -> Edit Configurations -> + GDB Remote Debug.
      'target remote' args: tcp:localhost:3333
      Symbol file: $WORKSPACE_DIR/build/$APP_NAME/zephyr/zephyr.elf

  To debug: start the "OpenOCD GDB Server" run config first (foreground),
  then start the GDB Remote Debug config.
EOF
