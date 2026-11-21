# ChipScope setup

The debug wrapper uses the 50 MHz board clock to sample the same video signals sent to the monitor.

## Core configuration

The `icon.xco` and `ila.xco` files in `ipcore_dir` preserve the working Core Generator settings. The lab used ISE 13.4, ICON 1.05.a, and ILA 1.04.a. Generate the cores using a matching installation and add their generated implementation files to the ISE project.

| Core | Required interface |
| --- | --- |
| `icon` | One `CONTROL0` port, 36 bits, connected to the ILA control bus |
| `ila` | `CONTROL[35:0]`, `CLK`, `DATA[31:0]`, `TRIG0[7:0]` |

The ILA has an 8192-sample buffer, separate data and trigger ports, and samples on rising clock edges. Its data width is 32 bits and trigger width is 8 bits.

## Probe mapping

| DATA bits | Signal |
| --- | --- |
| 7:0 | Red |
| 15:8 | Green |
| 23:16 | Blue |
| 24 | Horizontal sync |
| 25 | Vertical sync |
| 26 | DAC clock |
| 31:27 | Zero |

TRIG0 bit 0 is horizontal sync, bit 1 is vertical sync, and bit 2 is the DAC clock. Bits 7:3 are zero.

## Capture procedure

1. Set `game_debug_top` as the top module, build it, and program its bitstream.
2. Open ChipScope Pro Analyzer and identify the JTAG chain and ILA.
3. Group DATA into three 8-bit RGB buses and individual H, V, and DAC signals.
4. Use an all-don't-care trigger for an immediate horizontal or DAC view. To capture vertical sync, trigger on a falling edge of TRIG0 bit 1, with all other trigger bits set to don't-care.
5. Multiply cursor differences by 20 ns to obtain time intervals.

The vertical capture used trigger position 0. The signal started low at the trigger and rose at sample 3200, giving a 64 us low interval. A pre-trigger offset can show the preceding high level more clearly. The buffer is too short to contain consecutive vertical sync pulses at the full 50 MHz sample rate.

The source repository contains core configuration files, not the generated Xilinx IP netlists. Follow the Core Generator prompts for the matching installed IP versions. The course tutorial's legacy workflow disabled XST's Read Cores option before implementing the generated ChipScope cores.
