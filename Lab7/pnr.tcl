# ------------------------------------------------------------
# 0. Create output directories
# ------------------------------------------------------------

file mkdir results
file mkdir reports

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
#report_cells

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
# 11. Save floorplan checkpoint before placement
# ------------------------------------------------------------

write_def results/task1_floorplan.def
write_db  results/task1_floorplan.odb

puts "============================================================"
puts "Take BEFORE SS"
puts "============================================================"

# ------------------------------------------------------------
# 12. Global placement
# ------------------------------------------------------------

global_placement -density 0.50

write_def results/task1_global_placed.def
write_db  results/task1_global_placed.odb

# ------------------------------------------------------------
# 13. Detailed placement
# ------------------------------------------------------------
# Large displacement gives the legalizer freedom to fix cell locations.

detailed_placement \
    -max_displacement {500 500} \
    -report_file_name reports/dpl_debug.rpt

# ------------------------------------------------------------
# 14. Check placement legality
# ------------------------------------------------------------

check_placement

# ------------------------------------------------------------
# 15. Save final placed design
# ------------------------------------------------------------

write_def     results/task1_placed.def
write_db      results/task1_placed.odb
write_verilog results/task1_placed.v

# ------------------------------------------------------------
# 16. Reports
# ------------------------------------------------------------

report_design_area > reports/task1_area.rpt
report_checks -path_delay max > reports/task1_setup.rpt
report_checks -path_delay min > reports/task1_hold.rpt

# ------------------------------------------------------------
# 17. Done
# ------------------------------------------------------------

puts "============================================================"
puts "Task 1 completed."
puts ""
puts "Generated layout files:"
puts "  results/task1_floorplan.def"
puts "  results/task1_floorplan.odb"
puts "  results/task1_global_placed.def"
puts "  results/task1_global_placed.odb"
puts "  results/task1_placed.def"
puts "  results/task1_placed.odb"
puts "  results/task1_placed.v"
puts ""
puts "Generated reports:"
puts "  reports/task1_area.rpt"
puts "  reports/task1_setup.rpt"
puts "  reports/task1_hold.rpt"
puts "  reports/dpl_debug.rpt"
puts "============================================================"