# ============================================================
# run_sta.tcl — Phase 3 STA + Power
# ELCT1005 PROJ02
# ============================================================

# ============================================================
# WORK DIRECTORY
# ============================================================

set WORK_DIR /home/asiclab/Desktop/lab_sessions/Project/STA_TASK3

# ============================================================
# READ LIBERTY
# ============================================================

read_liberty $WORK_DIR/sky130_fd_sc_hd__tt_025C_1v80.lib

# ============================================================
# READ GATE-LEVEL NETLIST
# ============================================================

read_verilog $WORK_DIR/riscv_top_netlist.v

# ============================================================
# LINK DESIGN
# ============================================================

link_design riscv_top_synth

# ============================================================
# READ SDC CONSTRAINTS
# ============================================================

read_sdc $WORK_DIR/constraints.sdc

# ============================================================
# SWITCHING ACTIVITY
# ============================================================

set_power_activity -input -activity 0.1 -duty 0.5

set_power_activity \
    -input_port clk \
    -activity 1.0 \
    -duty 0.5

# ============================================================
# SETUP TIMING REPORT
# ============================================================

report_checks \
    -path_delay max \
    -format full_clock_expanded \
    -fields {slew cap input nets fanout} \
    -digits 4 \
    > $WORK_DIR/setup_timing.rpt

# ============================================================
# HOLD TIMING REPORT
# ============================================================

report_checks \
    -path_delay min \
    -format full_clock_expanded \
    -digits 4 \
    > $WORK_DIR/hold_timing.rpt

# ============================================================
# WNS / TNS REPORT
# ============================================================

set wns_file [open "$WORK_DIR/wns_tns.rpt" w]

puts $wns_file "=================================================="
puts $wns_file "WNS / TNS REPORT"
puts $wns_file "=================================================="

puts $wns_file "\nWNS:"
puts $wns_file [report_wns]

puts $wns_file "\nTNS:"
puts $wns_file [report_tns]

close $wns_file

# ============================================================
# VIOLATION REPORT
# ============================================================

report_check_types \
    -max_slew \
    -max_cap \
    -max_fanout \
    -violators \
    > $WORK_DIR/violations.rpt

# ============================================================
# MAXIMUM FREQUENCY SUMMARY
# ============================================================

set summary_file [open "$WORK_DIR/summary.rpt" w]

set wns [sta::worst_slack -max]

set target_period 30.0

set critical_period [expr {$target_period - $wns}]

set max_frequency [expr {1000.0 / $critical_period}]

puts $summary_file "=================================================="
puts $summary_file "PHASE 3 SUMMARY"
puts $summary_file "=================================================="

puts $summary_file [format "Target Period     : %.4f ns" $target_period]
puts $summary_file [format "WNS               : %.4f ns" $wns]
puts $summary_file [format "Critical Period   : %.4f ns" $critical_period]
puts $summary_file [format "Maximum Frequency : %.4f MHz" $max_frequency]

close $summary_file

# ============================================================
# POWER REPORT
# ============================================================

report_power > $WORK_DIR/power_report.rpt

puts ""
puts "=================================================="
puts "STA COMPLETE"
puts "=================================================="

puts "Generated reports:"
puts "  setup_timing.rpt"
puts "  hold_timing.rpt"
puts "  wns_tns.rpt"
puts "  violations.rpt"
puts "  summary.rpt"
puts "  power_report.rpt"