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

## Bootstrap

Set up a fresh workspace from scratch with
[zephyr-bootstrap](https://github.com/Assar63/zephyr-bootstrap):

```sh
curl -sL https://raw.githubusercontent.com/Assar63/zephyr-bootstrap/main/new-workspace.sh \
    | bash -s -- --ide clion --toolchain arm \
        ~/projects/rv_display-workspace \
        https://github.com/Assar63/rv_display.git
```

That one command:

1. Creates `~/projects/rv_display-workspace/` and clones this repo into it.
2. Sets up an in-tree Python venv (uv if installed, else pip).
3. Runs `west init -l rv_display` + `west update` (Zephyr `main` plus the
   modules listed in `west.yml`: `cmsis`, `cmsis_6`, `hal_stm32`, `segger`,
   `tinycrypt`, `mbedtls`, `hal_common`, `lvgl`).
4. Installs the Zephyr SDK (arm-zephyr-eabi only) into `~/zephyr-sdk-<version>/`.
5. Runs the project's CLion init (drops in run configs).
6. Symlinks `activate.sh` + `tools/` from the bootstrap repo.

For VSCode: replace `--ide clion` with `--ide vscode`. For Windows
PowerShell: use `new-workspace.ps1` (see the
[zephyr-bootstrap README](https://github.com/Assar63/zephyr-bootstrap)
for syntax).

You also need **openocd** on `PATH` for flashing — `sudo apt install openocd`
on Debian/Ubuntu, or `brew install openocd` on macOS.

## Build, flash, monitor

After bootstrap:

```sh
cd ~/projects/rv_display-workspace
source activate.sh
west build rv_display          # uses west config defaults below
west flash                     # via openocd
tools/serial-monitor.sh        # ST-Link VCP, /dev/ttyACM1 @ 115200
```

The bootstrap presets these `west config` values for the workspace:

- `build.board=nucleo_h753zi`
- `build.dir-fmt=build/{app_src}`
- `build.cmake-args=-DBOARD_FLASH_RUNNER=openocd -DBOARD_DEBUG_RUNNER=openocd`

Build artifacts land at `build/rv_display/`.

## Project layout

```
rv_display/
├── west.yml                       manifest (Zephyr main + allowlisted modules)
├── CMakeLists.txt
├── CMakePresets.json              nucleo_h753zi (default), nucleo_h753zi-debug
├── prj.conf                       CONFIG_DISPLAY / MIPI_DBI / SPI / LOG
├── src/main.c                     white / split / black test pattern
├── boards/nucleo_h753zi.overlay   SPI1 + e-paper pin mapping
├── scripts/ide-setup/             project's CLion init (VSCode falls back to bootstrap defaults)
└── .idea/runConfigurations/       Flash, OpenOCD GDB Server, Serial Monitor
```
