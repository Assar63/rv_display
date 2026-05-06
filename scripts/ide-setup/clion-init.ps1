# rv_display CLion init for Windows / PowerShell users.
#
# Project-specific bit: pin per-workspace west defaults (board, dir-fmt,
# runner) so plain `west build` / `west flash` work after bootstrap.
# Then delegate to zephyr-bootstrap's bundled default clion-init for
# the standard onboarding output (Attach-Directory hints from `west list`,
# debug setup guidance, etc.).

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$WorkspaceDir,
    [Parameter(Mandatory = $true, Position = 1)][string]$AppDir
)

$ErrorActionPreference = 'Stop'

# 1. Pin west config for this workspace.
Push-Location $WorkspaceDir
try {
    & west config build.board nucleo_h753zi
    & west config build.dir-fmt 'build/{app_src}'
    & west config build.cmake-args -- '-DBOARD_FLASH_RUNNER=openocd -DBOARD_DEBUG_RUNNER=openocd'
} finally { Pop-Location }
Write-Host "  west config: board=nucleo_h753zi, dir-fmt=build/{app_src}, runner=openocd"

# 2. Delegate.
$BootstrapDir = if ($env:ZEPHYR_BOOTSTRAP_DIR) {
    $env:ZEPHYR_BOOTSTRAP_DIR
} else {
    Join-Path $env:USERPROFILE 'projects\zephyr-bootstrap'
}
$DefaultInit = Join-Path $BootstrapDir 'ide-defaults\clion-init.ps1'
if (Test-Path $DefaultInit) {
    & $DefaultInit $WorkspaceDir $AppDir
} else {
    Write-Warning "Bundled CLion default not found at $DefaultInit"
}
