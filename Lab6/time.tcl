# ------------------------------------------------------------
# READ DESIGN
# ------------------------------------------------------------
read_liberty /home/asiclab/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog LUT_synth.v
link_design LUT
read_sdc sta.sdc
set_propagated_clock [all_clocks]

# Clock period 
set clk_period 6.0

proc run_sta {mode_name mode_value clk_period} {

    # ----------------------------------------
    # Set mode (0 = comb, 1 = registered)
    # ----------------------------------------
    set_case_analysis $mode_value [get_ports is_sync]

    puts "=================================="
    puts "Running STA for mode: $mode_name"
    puts "=================================="

    # ----------------------------------------
    # REPORTS
    # ----------------------------------------
    report_checks -path_delay max > ${mode_name}_timing.rpt
    report_checks -path_delay min > ${mode_name}_hold.rpt
    report_wns > ${mode_name}_wns.rpt
    report_tns > ${mode_name}_tns.rpt

    # ----------------------------------------
    # EXTRACT WNS
    # ----------------------------------------
    set fp [open "${mode_name}_wns.rpt" r]
    set data [read $fp]
    close $fp

    # Extract WNS value
    regexp {(-?[0-9.]+)} $data -> wns

    # ----------------------------------------
    # FMAX CALCULATION
    # ----------------------------------------
    set critical_path [expr $clk_period - $wns]
    set fmax [expr 1000.0 / $critical_path]

    puts "WNS: $wns ns"
    puts "Critical Path Delay: $critical_path ns"
    puts "Fmax: $fmax MHz"
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