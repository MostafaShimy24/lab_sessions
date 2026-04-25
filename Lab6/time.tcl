# ------------------------------------------------------------
# READ DESIGN
# ------------------------------------------------------------
read_liberty /home/asiclab/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog LUT_synth.v
link_design LUT

# Read constraints 
read_sdc sta.sdc

# Use propagated clocks
set_propagated_clock [all_clocks]

# ------------------------------------------------------------
# CLOCK PERIOD 
# ------------------------------------------------------------
set clk_period 10.0

# ------------------------------------------------------------
# STA PROCEDURE
# ------------------------------------------------------------
proc run_sta {mode_name mode_value clk_period} {

    # ----------------------------------------
    # Set mode (0 = comb, 1 = registered)
    # ----------------------------------------
    set_case_analysis $mode_value [get_ports is_sync]

    puts "=================================="
    puts "Running STA for mode: $mode_name"
    puts "=================================="

    # ----------------------------------------
    # SETUP ANALYSIS (MAX DELAY)
    # ----------------------------------------
    report_checks -path_delay max -fields {slew cap input_pins nets fanout} \
        > ${mode_name}_setup.rpt

    # ----------------------------------------
    # HOLD ANALYSIS (MIN DELAY)
    # ----------------------------------------
    report_checks -path_delay min \
        > ${mode_name}_hold.rpt

    # ----------------------------------------
    # WORST NEGATIVE SLACK (WNS)
    # ----------------------------------------
    report_wns > ${mode_name}_wns.rpt

    # ----------------------------------------
    # EXTRACT WNS
    # ----------------------------------------
    set fp [open "${mode_name}_wns.rpt" r]
    set data [read $fp]
    close $fp

    regexp {(-?[0-9.]+)} $data -> wns

    # ----------------------------------------
    # CRITICAL PATH DELAY
    # ----------------------------------------
    set critical_path [expr $clk_period - $wns]

    # ----------------------------------------
    # MAX FREQUENCY (Fmax)
    # ----------------------------------------
    # Fmax = 1 / critical_path
    set fmax [expr 1000.0 / $critical_path]

    puts "WNS: $wns ns"
    puts "Critical Path Delay: $critical_path ns"
    puts "Maximum Frequency (Fmax): $fmax MHz"
    puts "----------------------------------"
}

# ============================================================
# RUN BOTH MODES
# ============================================================

# Combinational mode
run_sta "comb" 0 $clk_period

# Registered mode
run_sta "sync" 1 $clk_period

# ============================================================
# END
# ============================================================