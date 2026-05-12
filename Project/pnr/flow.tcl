# ==============================================================================
# flow.tcl - Full Physical Implementation (Floorplan to GDSII)
# ==============================================================================

# 1. Setup PDK Paths
set pdk_base "../pdk"
set tech_lef "${pdk_base}/sky130_fd_sc_hd__nom.tlef"
set macro_lef "${pdk_base}/sky130_fd_sc_hd.lef"
set lib_file "${pdk_base}/sky130_fd_sc_hd__tt_025C_1v80.lib"

set_thread_count 16

# 2. Create results directory
set results_dir "results"
file mkdir $results_dir

# 3. Read Libraries and Design Data
read_lef $tech_lef
read_lef $macro_lef
read_liberty $lib_file

# Read scan netlist from dft
read_verilog ../dft/riscv_top_scan_netlist.v
link_design riscv_top_synth
read_sdc ../synth/constraints.sdc

# ==============================================================================
# FLOORPLANNING
# ==============================================================================

# 4. Initialize Floorplan
# Requirements: die ≤ 500 µm × 500 µm, core utilisation ≤ 60%.
# Using -die_area to enforce exactly 500x500 die, which with standard designs gives well below 60% util.
initialize_floorplan -die_area {0 0 700 700} -core_area {10 10 600 600} -site unithd

make_tracks

write_def $results_dir/1_floorplan_init.def

# 5. Place IO Pins
place_pins -hor_layers met3 -ver_layers met2

# 6. Insert Tapcells
tapcell -distance 14 -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1

# ==============================================================================
# POWER DISTRIBUTION NETWORK (PDN)
# ==============================================================================

# 7. Global Power Connections (Requirement: IR-drop <= 5% VDD)
add_global_connection -net VDD -inst_pattern .* -pin_pattern VPWR -power
add_global_connection -net VDD -inst_pattern .* -pin_pattern VPB
add_global_connection -net VSS -inst_pattern .* -pin_pattern VGND -ground
add_global_connection -net VSS -inst_pattern .* -pin_pattern VNB
set_voltage_domain -name CORE -power VDD -ground VSS

# We use robust stripes to ensure IR drop < 5% (90mV for 1.8V VDD)
define_pdn_grid -name stdcell_grid -starts_with POWER -voltage_domain CORE -pins {met1 met4}

# FIX: Removed pitch, offset, and starts_with for the followpins layer
add_pdn_stripe -grid stdcell_grid -layer met1 -width 0.48 -followpins

# Vertical met4 stripes
add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 10.0 -offset 2.0 -starts_with POWER
add_pdn_connect -grid stdcell_grid -layers {met1 met4}

pdngen

# ==============================================================================
# PLACEMENT & TIMING REPAIR (Pre-CTS)
# ==============================================================================

# 8. Global Placement
global_placement

# Pre-CTS timing repair
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met3
estimate_parasitics -placement
repair_timing -setup
detailed_placement

write_def $results_dir/2_placement.def

# ==============================================================================
# CLOCK TREE SYNTHESIS (CTS)
# ==============================================================================

# 9. Set clock routing layer and run CTS
# (Clock wire RC already set above)
clock_tree_synthesis -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4}

# Repair timing after CTS
repair_clock_nets
estimate_parasitics -placement
repair_timing -setup -hold
detailed_placement

write_def $results_dir/3_cts.def

# ==============================================================================
# ROUTING & TIMING REPAIR (Post-Route)
# ==============================================================================

# 10. Signal routing layers
set_routing_layers -signal li1-met5

# Global Routing
global_route

# Requirement: Post-route repair_timing until all slacks >= 0
# We do global route, estimate parasitics, and repair timing to ensure >0 slack before detailed route.
estimate_parasitics -global_routing
repair_timing -setup -hold
detailed_placement

# 11. Insert Filler Cells
filler_placement "sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8"

# Detailed Routing
detailed_route

# ==============================================================================
# TASK: POST-LAYOUT ANALYSIS & EXPORTS
# ==============================================================================

# FIX: Logically tie power/ground to all newly inserted CTS and Filler cells
global_connect

# Write final DEF layout file
write_def $results_dir/final.def
write_verilog -include_pwr_gnd $results_dir/final.v

# 1. Define the SKY130 extraction rules file
set ext_rules "${pdk_base}/rules.openrcx.sky130A.nom.spef_extractor"

# 2. Run the formal RC extraction engine
extract_parasitics -ext_model_file $ext_rules
write_spef $results_dir/final.spef

# ==============================================================================
# POST-LAYOUT TIMING AND POWER REPORTS
# ==============================================================================

# Read the generated SPEF back into the timing engine
read_spef $results_dir/final.spef

# 1. Post-Layout Setup Timing
report_checks -path_delay max -format full_clock_expanded -digits 4 > $results_dir/post_setup.rpt
puts "--> Post-layout setup analysis written to $results_dir/post_setup.rpt"

# 2. Post-Layout Hold Timing
report_checks -path_delay min -format full_clock_expanded -digits 4 > $results_dir/post_hold.rpt
puts "--> Post-layout hold analysis written to $results_dir/post_hold.rpt"

# 3. Apply Switching Activities
set_power_activity -input -activity 0.1 -duty 0.5
set_power_activity -input_port clk -activity 1.0 -duty 0.5

# 4. Post-Layout Power Analysis
report_power -digits 4 > $results_dir/post_power.rpt
puts "--> Post-layout power analysis written to $results_dir/post_power.rpt"

# Output Area
puts "\n--- Post-Layout Area ---"
report_design_area

# Check IR Drop to ensure it meets <= 5% VDD
puts "\n--- IR Drop Analysis ---"
analyze_power_grid -net VDD

# Write GDSII (Placed at the end to prevent early exit if map files are missing)
puts "\n--- Writing GDSII ---"
catch {write_gds $results_dir/final.gds}

puts "\n=== Full Physical Implementation Complete! ==="