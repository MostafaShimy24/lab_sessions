# ============================================================
# constraints.sdc — SDC Timing Constraints
# ------------------------------------------------------------
# Project : ELCT1005 PROJ02
# Phase   : Phase 3 — Pre-Layout STA
# Target  : 100000 ns clock period (10 kHz)
# Corner  : TT / 1.8V / 25C
# Tool    : OpenSTA
# ============================================================

# ============================================================
# CLOCK
# ============================================================

create_clock -name clk \
             -period 60 \
             -waveform {0 30} \
             [get_ports clk]

# ============================================================
# CLOCK UNCERTAINTY
# ============================================================

set_clock_uncertainty -setup 0.10 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]

# ============================================================
# INPUT DELAYS
# ============================================================

set_input_delay -clock clk -max 1.0 [get_ports rst_n]

set_input_delay -clock clk -max 1.0 \
    [get_ports imem_rdata]

# ============================================================
# OUTPUT DELAYS
# ============================================================

set_output_delay -clock clk -max 1.0 \
    [get_ports imem_addr]

# ============================================================
# DRIVING CELL
# ============================================================

set_driving_cell \
    -lib_cell sky130_fd_sc_hd__buf_2 \
    [all_inputs]

# ============================================================
# OUTPUT LOAD
# ============================================================

set_load 0.1 [all_outputs]