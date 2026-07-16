# SPDX-FileCopyrightText: © 2026 Paritala Venkata Sai Harshith
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting VGA Hardware Engine Verification")

    # Set the clock period to match standard 25.175 MHz VGA timing (approx 39.722 ns)
    clock = Clock(dut.clk, 39722, unit="ps")
    cocotb.start_soon(clock.start())

    # Initialize and Apply Reset
    dut._log.info("Applying Hardware Reset...")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    
    # Hold reset active for 10 clock cycles
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Reset Released successfully.")

    dut._log.info("Testing VGA synchronization behavior...")

    # Let's run the simulation for 200 clock cycles to watch the initial pixels sweep
    # We will verify that HSYNC and VSYNC start in their correct default active-high states (since sync is active-low)
    for i in range(200):
        await RisingEdge(dut.clk)
        
        # uo_out pinouts from info.yaml: 
        # [7]=hsync, [3]=vsync
        current_out = dut.uo_out.value.integer
        hsync_bit = (current_out >> 7) & 1
        vsync_bit = (current_out >> 3) & 1
        
        # Periodically log the outputs to clear the verification pipeline step
        if i % 40 == 0:
            dut._log.info(f"Pixel Clock {i:03d} -> HSYNC: {hsync_bit}, VSYNC: {vsync_bit}, Raw Out (Bin): {bin(current_out)}")

        # Basic functional check: Sync pulses should be high (inactive) during the active visible region
        assert hsync_bit == 1, f"Assertion failed: HSYNC dropped unexpectedly at cycle {i}"
        assert vsync_bit == 1, f"Assertion failed: VSYNC dropped unexpectedly at cycle {i}"

    dut._log.info("Success! VGA Sync Pulses are stable and logic is working.")
