# ------------------------------------------------------------
# 1. Technology and library files
# ------------------------------------------------------------

set TECH_LEF "sky130_fd_sc_hd__nom.tlef"
set STD_CELL_LEF "sky130_fd_sc_hd.lef"
set LIB_FILE "sky130_fd_sc_hd__tt_025C_1v80.lib"

# ------------------------------------------------------------
# 2. Design files
# ------------------------------------------------------------

set DESIGN_NAME "LUT"
set NETLIST_FILE "LUT_synth.v"
set SDC_FILE "sta.sdc"

# ------------------------------------------------------------
# 3. Read technology, standard-cell LEF, and Liberty file
# ------------------------------------------------------------

read_lef $TECH_LEF
read_lef $STD_CELL_LEF
read_liberty $LIB_FILE

# ------------------------------------------------------------
# 4. Read synthesized netlist and link design
# ------------------------------------------------------------

read_verilog $NETLIST_FILE
link_design $DESIGN_NAME

# ------------------------------------------------------------
# 5. Read timing constraints
# ------------------------------------------------------------

read_sdc $SDC_FILE

# ------------------------------------------------------------
# 6. Initial design report
# ------------------------------------------------------------

puts "============================================================"
puts "Initial design information"
puts "============================================================"

report_design_area

# ------------------------------------------------------------
# 7. Initialize floorplan
# ------------------------------------------------------------

initialize_floorplan \
    -utilization 30 \
    -aspect_ratio 1.0 \
    -core_space 20.0 \
    -site unithd

make_tracks

# ------------------------------------------------------------
# 8. Place IO pins
# ------------------------------------------------------------

place_pins \
    -hor_layer met3 \
    -ver_layer met2

# ------------------------------------------------------------
# 9. Insert tapcells and endcaps
# ------------------------------------------------------------

tapcell \
    -distance 14 \
    -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 \
    -endcap_master sky130_fd_sc_hd__decap_3

# ------------------------------------------------------------
# 10. Power Distribution Network
# ------------------------------------------------------------

add_global_connection \
    -net VPWR \
    -inst_pattern {.*} \
    -pin_pattern {^VPWR$} \
    -power

add_global_connection \
    -net VGND \
    -inst_pattern {.*} \
    -pin_pattern {^VGND$} \
    -ground

add_global_connection \
    -net VPWR \
    -inst_pattern {.*} \
    -pin_pattern {^VPB$}

add_global_connection \
    -net VGND \
    -inst_pattern {.*} \
    -pin_pattern {^VNB$}

global_connect

set_voltage_domain \
    -name CORE \
    -power VPWR \
    -ground VGND

define_pdn_grid \
    -name core_grid \
    -voltage_domains {CORE}

add_pdn_stripe \
    -grid core_grid \
    -layer met1 \
    -width 0.48 \
    -followpins

pdngen

# ------------------------------------------------------------
# 11. Save Task 3 floorplan checkpoint
# ------------------------------------------------------------

write_def results/task3_floorplan.def
write_db  results/task3_floorplan.odb

puts "============================================================"
puts "Task 3 floorplan checkpoint saved."
puts "============================================================"

# ------------------------------------------------------------
# 12. Global placement
# ------------------------------------------------------------

global_placement -density 0.50

write_def results/task3_global_placed.def
write_db  results/task3_global_placed.odb

# ------------------------------------------------------------
# 13. Detailed placement
# ------------------------------------------------------------

detailed_placement \
    -max_displacement {500 500} \
    -report_file_name reports/task3_dpl_before_cts.rpt

check_placement

# ------------------------------------------------------------
# 14. Save placed design before CTS
# ------------------------------------------------------------

write_def     results/task3_placed_before_cts.def
write_db      results/task3_placed_before_cts.odb
write_verilog results/task3_placed_before_cts.v

report_design_area > reports/task3_area_before_cts.rpt
report_checks -path_delay max > reports/task3_setup_before_cts.rpt
report_checks -path_delay min > reports/task3_hold_before_cts.rpt

# ------------------------------------------------------------
# 15. Clock Tree Synthesis
# ------------------------------------------------------------

puts "============================================================"
puts "Running CTS before routing"
puts "============================================================"

report_clock_skew > reports/task3_clock_skew_before_cts.rpt
report_clock_latency > reports/task3_clock_latency_before_cts.rpt

set_wire_rc -clock -layer met3

clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_1} \
    -root_buf sky130_fd_sc_hd__clkbuf_1

# Legalize CTS-inserted buffers
detailed_placement \
    -max_displacement {500 500} \
    -report_file_name reports/task3_dpl_after_cts.rpt

check_placement

report_clock_skew > reports/task3_clock_skew_after_cts.rpt
report_clock_latency > reports/task3_clock_latency_after_cts.rpt

write_def     results/task3_after_cts.def
write_db      results/task3_after_cts.odb
write_verilog results/task3_after_cts.v

# ------------------------------------------------------------
# 16. Optional tie-cell fanout repair
# ------------------------------------------------------------

repair_tie_fanout sky130_fd_sc_hd__conb_1/HI
repair_tie_fanout sky130_fd_sc_hd__conb_1/LO

check_placement

write_def results/task3_after_tie_repair.def
write_db  results/task3_after_tie_repair.odb

# ------------------------------------------------------------
# 17. Insert filler cells
# ------------------------------------------------------------
filler_placement {
    sky130_fd_sc_hd__fill_1
    sky130_fd_sc_hd__fill_2
    sky130_fd_sc_hd__fill_4
    sky130_fd_sc_hd__fill_8
}

check_placement

write_def results/task3_after_filler.def
write_db  results/task3_after_filler.odb

# ------------------------------------------------------------
# 18. Set routing layers
# ------------------------------------------------------------
# Required by Task 3.

set_routing_layers \
    -signal met1-met5

# Estimate parasitics before routing
estimate_parasitics -placement

# ------------------------------------------------------------
# 19. Global routing
# ------------------------------------------------------------

puts "============================================================"
puts "Running global routing"
puts "============================================================"

global_route

write_def results/task3_global_routed.def
write_db  results/task3_global_routed.odb

# Timing estimate after global routing
estimate_parasitics -global_routing

report_checks -path_delay max > reports/task3_setup_after_global_route.rpt
report_checks -path_delay min > reports/task3_hold_after_global_route.rpt

# ------------------------------------------------------------
# 20. Detailed routing
# ------------------------------------------------------------

puts "============================================================"
puts "Running detailed routing"
puts "============================================================"

detailed_route \
    -output_drc reports/task3_drc.rpt

write_def results/task3_detailed_routed.def
write_db  results/task3_detailed_routed.odb

# ------------------------------------------------------------
# 21. DRC report
# ------------------------------------------------------------

puts "============================================================"
puts "Detailed routing DRC report written to:"
puts "  reports/task3_drc.rpt"
puts "============================================================"

# ------------------------------------------------------------
# 22. Final post-route reports
# ------------------------------------------------------------

report_design_area > reports/task3_area_after_route.rpt
report_checks -path_delay max > reports/task3_setup_after_route.rpt
report_checks -path_delay min > reports/task3_hold_after_route.rpt
report_clock_skew > reports/task3_clock_skew_after_route.rpt
report_clock_latency > reports/task3_clock_latency_after_route.rpt

# ------------------------------------------------------------
# 23. Save final routed design
# ------------------------------------------------------------

write_def     results/task3_final_routed.def
write_db      results/task3_final_routed.odb
write_verilog results/task3_final_routed.v

# ------------------------------------------------------------
# 24. Done
# ------------------------------------------------------------

puts "============================================================"
puts "Task 3 completed: Global routing + detailed routing."
puts ""
puts "Generated layout files:"
puts "  results/task3_floorplan.def"
puts "  results/task3_floorplan.odb"
puts "  results/task3_global_placed.def"
puts "  results/task3_global_placed.odb"
puts "  results/task3_placed_before_cts.def"
puts "  results/task3_placed_before_cts.odb"
puts "  results/task3_after_cts.def"
puts "  results/task3_after_cts.odb"
puts "  results/task3_after_tie_repair.def"
puts "  results/task3_after_tie_repair.odb"
puts "  results/task3_after_filler.def"
puts "  results/task3_after_filler.odb"
puts "  results/task3_global_routed.def"
puts "  results/task3_global_routed.odb"
puts "  results/task3_detailed_routed.def"
puts "  results/task3_detailed_routed.odb"
puts "  results/task3_final_routed.def"
puts "  results/task3_final_routed.odb"
puts "  results/task3_final_routed.v"
puts ""
puts "Generated reports:"
puts "  reports/task3_area_before_cts.rpt"
puts "  reports/task3_setup_before_cts.rpt"
puts "  reports/task3_hold_before_cts.rpt"
puts "  reports/task3_clock_skew_before_cts.rpt"
puts "  reports/task3_clock_latency_before_cts.rpt"
puts "  reports/task3_clock_skew_after_cts.rpt"
puts "  reports/task3_clock_latency_after_cts.rpt"
puts "  reports/task3_dpl_before_cts.rpt"
puts "  reports/task3_dpl_after_cts.rpt"
puts "  reports/task3_setup_after_global_route.rpt"
puts "  reports/task3_hold_after_global_route.rpt"
puts "  reports/task3_drc.rpt"
puts "  reports/task3_area_after_route.rpt"
puts "  reports/task3_setup_after_route.rpt"
puts "  reports/task3_hold_after_route.rpt"
puts "  reports/task3_clock_skew_after_route.rpt"
puts "  reports/task3_clock_latency_after_route.rpt"
puts "============================================================"