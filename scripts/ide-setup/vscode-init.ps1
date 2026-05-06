# rv_display VSCode init for Windows / PowerShell users.
#
# Project-specific bit: pin per-workspace west defaults (board, dir-fmt,
# runner) so plain `west build` / `west flash` work after bootstrap.
# Then delegate the .code-workspace + .vscode\tasks.json generation to
# zephyr-bootstrap's bundled default vscode-init -- no point duplicating
# the JSON here.

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

# 2. Delegate the rest.
$BootstrapDir = if ($env:ZEPHYR_BOOTSTRAP_DIR) {
    $env:ZEPHYR_BOOTSTRAP_DIR
} else {
    Join-Path $env:USERPROFILE 'projects\zephyr-bootstrap'
}
$DefaultInit = Join-Path $BootstrapDir 'ide-defaults\vscode-init.ps1'
if (Test-Path $DefaultInit) {
    & $DefaultInit $WorkspaceDir $AppDir
} else {
    Write-Warning "Bundled VSCode default not found at $DefaultInit"
    Write-Warning "Project's west config defaults are set, but no .code-workspace was generated."
}
