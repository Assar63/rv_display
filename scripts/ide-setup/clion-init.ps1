# CLion init for Windows / PowerShell users.
# Invoked by zephyr-bootstrap's new-workspace.ps1 when called with
# -Ide clion. Receives the workspace dir as the first positional arg.
#
# .idea/runConfigurations/ is committed in this project, so this script
# mostly verifies the clone made it through and prints onboarding guidance.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$WorkspaceDir
)

$ErrorActionPreference = 'Stop'

$AppDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$AppName = Split-Path -Leaf $AppDir

# Pin per-workspace west defaults so `west build`/`west flash` Just Work.
Push-Location $WorkspaceDir
try {
    & west config build.board nucleo_h753zi
    & west config build.dir-fmt 'build/{app_src}'
    & west config build.cmake-args -- '-DBOARD_FLASH_RUNNER=openocd -DBOARD_DEBUG_RUNNER=openocd'
} finally { Pop-Location }
Write-Host "  west config: board=nucleo_h753zi, dir-fmt=build/{app_src}, runner=openocd"

if (-not (Test-Path (Join-Path $AppDir '.idea\runConfigurations'))) {
    Write-Warning "$AppDir\.idea\runConfigurations\ missing -- did the run configs get committed?"
}

@"
CLion setup ready.

  1. Open this folder as the CLion project (NOT the workspace root):
       $AppDir
  2. CMakePresets.json is autodetected -- pick the configure preset
     matching the board you're building for.
  3. Run configurations (Flash, OpenOCD GDB Server, Serial Monitor)
     load from .idea\runConfigurations\.

  Debug (one-time machine-local setup, not committed):
    - Settings -> Build, Execution, Deployment -> Toolchains -> + System.
      Set C/C++ compiler and Debugger to the matching toolchain binaries
      under `$env:ZEPHYR_SDK_INSTALL_DIR\<arch>-zephyr-*\bin\ (e.g.
      arm-zephyr-eabi for Cortex-M, riscv64-zephyr-elf for RISC-V).
    - Run -> Edit Configurations -> + GDB Remote Debug.
      'target remote' args: tcp:localhost:3333
      Symbol file: $WorkspaceDir\build\$AppName\zephyr\zephyr.elf

  To debug: start the "OpenOCD GDB Server" run config first (foreground),
  then start the GDB Remote Debug config.
"@ | Write-Host
