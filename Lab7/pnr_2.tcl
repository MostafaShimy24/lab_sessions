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
# 3. Read technology, cell LEF, and Liberty timing file
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
# 6. Report initial design information
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
    -core_space 10.0 \
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
# 11. Save Task 2 floorplan checkpoint before placement
# ------------------------------------------------------------

write_def results/task2_floorplan.def
write_db  results/task2_floorplan.odb

puts "============================================================"
puts "Task 2 floorplan checkpoint saved."
puts "This is still BEFORE placement."
puts "============================================================"

# ------------------------------------------------------------
# 12. Global placement
# ------------------------------------------------------------

global_placement -density 0.50

write_def results/task2_global_placed.def
write_db  results/task2_global_placed.odb

# ------------------------------------------------------------
# 13. Detailed placement
# ------------------------------------------------------------

detailed_placement \
    -max_displacement {500 500} \
    -report_file_name reports/task2_dpl_before_cts.rpt

# ------------------------------------------------------------
# 14. Check placement legality before CTS
# ------------------------------------------------------------

check_placement

# ------------------------------------------------------------
# 15. Save placed design before CTS
# ------------------------------------------------------------

write_def     results/task2_before_cts.def
write_db      results/task2_before_cts.odb
write_verilog results/task2_before_cts.v

# ------------------------------------------------------------
# 16. Reports before CTS
# ------------------------------------------------------------

report_design_area > reports/task2_area_before_cts.rpt
report_checks -path_delay max > reports/task2_setup_before_cts.rpt
report_checks -path_delay min > reports/task2_hold_before_cts.rpt

puts "============================================================"
puts "Clock reports BEFORE CTS"
puts "============================================================"

report_clock_skew > reports/task2_clock_skew_before_cts.rpt
report_clock_latency > reports/task2_clock_latency_before_cts.rpt

# ------------------------------------------------------------
# 17. Clock Tree Synthesis
# ------------------------------------------------------------
# Required by Task 2:
# Set clock routing layer using met3.

set_wire_rc -clock -layer met3

# Run CTS using SKY130 clock buffers.
# Start simple with clkbuf_1. If your version/library supports larger
# buffers, you can expand the buffer list later.

clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_1} \
    -root_buf sky130_fd_sc_hd__clkbuf_1

# ------------------------------------------------------------
# 18. Legalize CTS-inserted buffers
# ------------------------------------------------------------

detailed_placement \
    -max_displacement {500 500} \
    -report_file_name reports/task2_dpl_after_cts.rpt

check_placement

# ------------------------------------------------------------
# 19. Reports after CTS
# ------------------------------------------------------------

puts "============================================================"
puts "Clock reports AFTER CTS"
puts "============================================================"

report_clock_skew > reports/task2_clock_skew_after_cts.rpt
report_clock_latency > reports/task2_clock_latency_after_cts.rpt

report_design_area > reports/task2_area_after_cts.rpt
report_checks -path_delay max > reports/task2_setup_after_cts.rpt
report_checks -path_delay min > reports/task2_hold_after_cts.rpt

# ------------------------------------------------------------
# 20. Save final Task 2 CTS design
# ------------------------------------------------------------

write_def     results/task2_cts.def
write_db      results/task2_cts.odb
write_verilog results/task2_cts.v

# ------------------------------------------------------------
# 21. Done
# ------------------------------------------------------------

puts "============================================================"
puts "Task 2 completed: Placement + Clock Tree Synthesis."
puts ""
puts "Generated layout files:"
puts "  results/task2_floorplan.def"
puts "  results/task2_floorplan.odb"
puts "  results/task2_global_placed.def"
puts "  results/task2_global_placed.odb"
puts "  results/task2_before_cts.def"
puts "  results/task2_before_cts.odb"
puts "  results/task2_before_cts.v"
puts "  results/task2_cts.def"
puts "  results/task2_cts.odb"
puts "  results/task2_cts.v"
puts ""
puts "Generated reports:"
puts "  reports/task2_area_before_cts.rpt"
puts "  reports/task2_setup_before_cts.rpt"
puts "  reports/task2_hold_before_cts.rpt"
puts "  reports/task2_clock_skew_before_cts.rpt"
puts "  reports/task2_clock_latency_before_cts.rpt"
puts "  reports/task2_dpl_before_cts.rpt"
puts "  reports/task2_dpl_after_cts.rpt"
puts "  reports/task2_clock_skew_after_cts.rpt"
puts "  reports/task2_clock_latency_after_cts.rpt"
puts "  reports/task2_area_after_cts.rpt"
puts "  reports/task2_setup_after_cts.rpt"
puts "  reports/task2_hold_after_cts.rpt"
puts "============================================================"