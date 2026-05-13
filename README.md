# rv_display

Zephyr application driving a Good Display **GDEM075F52** (7.5" 800×480
monochrome e-paper, UC8179 controller) from an **ST Nucleo-H753ZI**.
The current `src/main.c` cycles a white → split → black test pattern
to validate the panel.

## Hardware

- **Nucleo-H753ZI** dev board (Cortex-M7 @ 480 MHz, 1 MB SRAM, 2 MB flash).
- **GDEM075F52** e-paper panel + **DESPI-C02** adapter.
- Wiring on the Arduino R3 header (see `boards/nucleo_h753zi.overlay`):

| DESPI-C02 | Arduino pin | STM32 |
|-----------|-------------|-------|
| VCC       | 3V3         | —     |
| GND       | GND         | —     |
| DIN       | D11         | PB5  (SPI1 MOSI) |
| CLK       | D13         | PA5  (SPI1 SCK)  |
| /CS       | D10         | PD14 (SPI1 CS)   |
| D/C       | D9          | PD15 |
| /RST      | D8          | PF3  |
| BUSY      | D7          | PG12 |

DESPI-C02 BS jumper at **3.3 V**, current-sense switch at **0.47 Ω**
(typical for 7.5" panels — confirm against the Good Display datasheet
for your specific revision).

## Prerequisites

The bootstrap (zephyr-bootstrap) handles west, the Python venv, the
Zephyr SDK, and all the Zephyr Python deps. You bring:

### Linux / macOS

| Tool | Why | Install |
|------|-----|---------|
| `bash`, `curl`, `git` | invoking the bootstrap, cloning | preinstalled / `apt install git` / `brew install git` |
| `python3` + `venv` *(or `uv`)* | the workspace's Python env | `apt install python3-venv` |
| `openocd` | `west flash` runner (Nucleo ST-Link V3) | `apt install openocd` / `brew install openocd` |
| `tio` or `picocom` *(optional)* | nicer serial monitor than the `stty + cat` fallback | `apt install tio` / `brew install picocom` |

### Windows (PowerShell)

| Tool | Why | Install |
|------|-----|---------|
| PowerShell 5.1+ or 7+ | running the bootstrap | preinstalled / `winget install Microsoft.PowerShell` |
| `git` | cloning | `winget install Git.Git` |
| Python 3 *(or `uv`)* | the workspace's Python env | `winget install Python.Python.3` |
| `7z.exe` | extracting the SDK `.7z` archives during `-Toolchain` | `scoop install 7zip` |
| `openocd.exe` | `west flash` runner | `scoop install openocd` (or xPack openocd) |

### Hardware

Already covered above — Nucleo-H753ZI + GDEM075F52 + DESPI-C02
adapter, plus the USB-A → USB-Micro-B cable that came with the Nucleo.

See the full
[zephyr-bootstrap prerequisites table](https://github.com/Assar63/zephyr-bootstrap#prerequisites)
for the host-tool details (uv as a faster alternative to pip, etc.).

## Bootstrap

Set up a fresh workspace from scratch with
[zephyr-bootstrap](https://github.com/Assar63/zephyr-bootstrap).

### Linux / macOS (bash)

```sh
curl -sL https://raw.githubusercontent.com/Assar63/zephyr-bootstrap/main/new-workspace.sh \
    | bash -s -- --ide clion --toolchain arm \
        ~/projects/rv_display-workspace \
        https://github.com/Assar63/rv_display.git
```

### Windows (PowerShell)

```powershell
iwr https://raw.githubusercontent.com/Assar63/zephyr-bootstrap/main/new-workspace.ps1 -OutFile new-workspace.ps1
.\new-workspace.ps1 -Ide clion -Toolchain arm `
    C:\dev\rv_display-workspace `
    https://github.com/Assar63/rv_display.git
```

The PowerShell variant copies `activate.ps1` + `tools\` into the
workspace rather than symlinking, so it works without Developer Mode.

### What the bootstrap does, either way

1. Creates the workspace dir and clones this repo into it.
2. Sets up an in-tree Python venv (uv if installed, else pip).
3. Runs `west init -l rv_display` + `west update` (Zephyr `main` plus the
   modules listed in `west.yml`: `cmsis`, `cmsis_6`, `hal_stm32`, `segger`,
   `tinycrypt`, `mbedtls`, `hal_common`, `lvgl`).
4. Installs the Zephyr SDK (arm-zephyr-eabi only) into `~/zephyr-sdk-<version>/`
   (or `%USERPROFILE%\zephyr-sdk-<version>\` on Windows).
5. Runs the project's CLion init — pins per-workspace `west config`,
   then prints attach-dir hints from `west list`.
6. Symlinks (or copies, on Windows) `activate.{sh,ps1}` + `tools/` from
   the bootstrap repo.

For VSCode instead of CLion: swap `clion` for `vscode` in the `--ide` /
`-Ide` argument.

## Build, flash, monitor

After bootstrap:

### Linux / macOS

```sh
cd ~/projects/rv_display-workspace
source activate.sh
west build rv_display          # uses west config defaults below
west flash                     # via openocd
tools/serial-monitor.sh        # ST-Link VCP, /dev/ttyACM1 @ 115200
```

### Windows (PowerShell)

```powershell
cd C:\dev\rv_display-workspace
. .\activate.ps1
west build rv_display          # uses west config defaults below
west flash                     # via openocd
.\tools\serial-monitor.ps1     # default COM3; override with $env:PORT='COM4'
```

The project's IDE init script (run by the bootstrap when `--ide` is passed)
pins these `west config` values for the workspace:

- `build.board=nucleo_h753zi`
- `build.dir-fmt=build/{app_src}`
- `build.cmake-args=-DBOARD_FLASH_RUNNER=openocd -DBOARD_DEBUG_RUNNER=openocd`

Build artifacts land at `build/rv_display/`. If you bootstrapped without
`--ide`, you'll need to set those `west config` values yourself (or pass
`-b nucleo_h753zi` on every `west build`).

> **Heads-up on `pip`:** if the bootstrap used `uv` (the default when
> `uv` is on `PATH`), the workspace's `.venv` doesn't include `pip` —
> use `uv pip install <pkg>` instead of `pip install <pkg>`. Nothing
> in west or Zephyr itself calls `pip` at runtime, so this only matters
> if a tutorial tells you to. See the
> [zephyr-bootstrap note on pip vs uv](https://github.com/Assar63/zephyr-bootstrap#heads-up-pip-vs-uv-pip-inside-the-workspace-venv)
> for details.

## Updating the workspace

Pull updates into an existing workspace via zephyr-bootstrap's
`update-workspace` script — `git pull` both this repo and the tools
repo, `west update` to refresh Zephyr + modules to current manifest
pins, refresh Python deps, and re-arm the pre-commit hook.

### Linux / macOS

```sh
~/projects/zephyr-bootstrap/update-workspace.sh ~/projects/rv_display-workspace
```

### Windows (PowerShell)

```powershell
~\projects\zephyr-bootstrap\update-workspace.ps1 C:\dev\rv_display-workspace
```

What it does **not** re-run: the project's IDE init script
(`scripts/ide-setup/<ide>-init.{sh,ps1}`). If this project bumps its
`west config` defaults or `.idea/runConfigurations/` contents,
re-run `new-workspace.{sh,ps1}` against the same workspace dir with
`--ide <name>` instead — every other step skips, only IDE init
re-runs. See the
[zephyr-bootstrap update section](https://github.com/Assar63/zephyr-bootstrap#updating-an-existing-workspace)
for details.

## Linting / pre-commit

`.pre-commit-config.yaml` runs **clang-format** (Zephyr style via the
in-tree `.clang-format`) on changed C/C++ files. The bootstrap installs
the `pre-commit` package and runs `pre-commit install` automatically,
so the hook is already armed after a fresh `new-workspace.{sh,ps1}` run
— no manual setup. Run the checks manually any time with:

```sh
pre-commit run --all-files
```

If you really must skip the hook on a single commit, `git commit
--no-verify` works — but **the `Lint` GitHub Actions workflow runs the
same hook on every push/PR**, so anything that slips through locally
will fail in CI.

Bumping the pinned `clang-format` version:

```sh
pre-commit autoupdate
```

## Opening in CLion

Open `<workspace>/rv_display/` as the CLion project (not the workspace
root) — that's where `CMakePresets.json` and `.idea/runConfigurations/`
live. CLion will detect the presets automatically; pick `nucleo_h753zi`.

The bootstrap's CLion init prints suggested **"Attach Directory to
Project"** targets at the end of its output — they're the dirs that
sit one level up from the project root and aren't auto-visible in
CLion's Project pane. For this project they are:

| Path                                        | Why                                  |
|---------------------------------------------|--------------------------------------|
| `<workspace>/zephyr`                        | Zephyr kernel, drivers, headers, samples |
| `<workspace>/modules/hal/stm32`             | STM32Cube HAL/LL — peripheral source |
| `<workspace>/modules/hal/cmsis`             | older Arm CMSIS (still referenced) |
| `<workspace>/modules/hal/cmsis_6`           | current Arm CMSIS Core/DSP |
| `<workspace>/modules/lib/gui/lvgl`          | LVGL widget library |
| `<workspace>/modules/crypto/mbedtls`        | mbedTLS (TLS, hashing, RNG) |
| `<workspace>/modules/debug/segger`          | SEGGER RTT/SystemView |

To attach: in the Project pane, right-click the project root → **Attach
Directory to Project** → pick the dir. Or use **File → Attach Directory
to Project**. CLion stores attached dirs in `.idea/workspace.xml`, which
is per-user and gitignored, so do this once per machine. `Zephyr` is the
most useful one to attach first — it puts the entire RTOS source one
ctrl-click away.

VSCode users get this for free: the bootstrap default vscode-init writes
a multi-root `.code-workspace` with each module as its own top-level
folder, so no manual attach step is needed.

## Project layout

```
rv_display/
├── west.yml                       manifest (Zephyr main + allowlisted modules)
├── CMakeLists.txt
├── CMakePresets.json              nucleo_h753zi (default), nucleo_h753zi-debug
├── prj.conf                       CONFIG_DISPLAY / MIPI_DBI / SPI / LOG
├── .clang-format                  snapshot of zephyr/.clang-format (Zephyr style)
├── .pre-commit-config.yaml        clang-format on changed C/C++ files
├── src/main.c                     white / split / black test pattern
├── boards/nucleo_h753zi.overlay   SPI1 + e-paper pin mapping
├── scripts/ide-setup/             project's CLion + VSCode init (sets west config, then delegates)
├── .idea/runConfigurations/       Flash, OpenOCD GDB Server, Serial Monitor
└── .github/workflows/lint.yml     CI mirror of the pre-commit hook
```
