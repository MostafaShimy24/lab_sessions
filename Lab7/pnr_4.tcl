# # ============================================================
# # pnr_4_pre.tcl
# # Task 4 - Pre-Layout Analysis
# # ============================================================

# file mkdir reports

# # ------------------------------------------------------------
# # 1. Files
# # ------------------------------------------------------------

# set TECH_LEF "sky130_fd_sc_hd__nom.tlef"
# set STD_CELL_LEF "sky130_fd_sc_hd.lef"
# set LIB_FILE "sky130_fd_sc_hd__tt_025C_1v80.lib"

# set DESIGN_NAME "LUT"
# set NETLIST_FILE "LUT_synth.v"
# set SDC_FILE "sta.sdc"

# # ------------------------------------------------------------
# # 2. Read libraries and synthesized netlist
# # ------------------------------------------------------------

# read_lef $TECH_LEF
# read_lef $STD_CELL_LEF
# read_liberty $LIB_FILE

# read_verilog $NETLIST_FILE
# link_design $DESIGN_NAME

# read_sdc $SDC_FILE

# puts "============================================================"
# puts "Running PRE-layout analysis"
# puts "============================================================"

# # ------------------------------------------------------------
# # 3. Pre-layout timing
# # ------------------------------------------------------------

# report_checks \
#     -path_delay max \
#     -fields {slew cap input_pin net} \
#     -digits 4 \
#     > reports/pre_setup.rpt

# report_checks \
#     -path_delay min \
#     -fields {slew cap input_pin net} \
#     -digits 4 \
#     > reports/pre_hold.rpt

# report_checks \
#     -path_delay max \
#     -sort_by_slack \
#     -fields {slew cap input_pin net} \
#     -digits 4 \
#     -group_count 1 \
#     > reports/pre_critical_path.rpt

# # ------------------------------------------------------------
# # 4. Pre-layout WNS / TNS
# # ------------------------------------------------------------

# set fh [open "reports/pre_slack_summary.rpt" "w"]

# puts $fh "Pre-Layout Slack Summary"
# puts $fh "========================"
# puts $fh ""

# if {[catch {report_worst_slack} result]} {
#     puts $fh "WNS: report_worst_slack not supported in this OpenROAD build."
# } else {
#     puts $fh "WNS / Worst Slack:"
#     puts $fh $result
# }

# puts $fh ""

# if {[catch {report_tns} result]} {
#     puts $fh "TNS: report_tns not supported in this OpenROAD build."
# } else {
#     puts $fh "TNS / Total Negative Slack:"
#     puts $fh $result
# }

# puts $fh ""
# puts $fh "Detailed setup report: reports/pre_setup.rpt"
# puts $fh "Detailed hold report:  reports/pre_hold.rpt"

# close $fh

# # ------------------------------------------------------------
# # 5. Pre-layout area
# # ------------------------------------------------------------
# # report_design_area can be weak/empty before floorplanning in some builds.
# # So generate both design-area and cell-usage reports.

# set af [open "reports/pre_area.rpt" "w"]

# puts $af "Pre-Layout Area Report"
# puts $af "======================"
# puts $af ""

# puts $af "Design area report:"
# puts $af "-------------------"

# if {[catch {report_design_area} area_result]} {
#     puts $af "report_design_area failed or is unsupported:"
#     puts $af $area_result
# } else {
#     puts $af $area_result
# }

# puts $af ""
# puts $af "Cell usage / standard-cell area report:"
# puts $af "---------------------------------------"

# if {[catch {report_cell_usage} cell_result]} {
#     puts $af "report_cell_usage failed or is unsupported:"
#     puts $af $cell_result
# } else {
#     puts $af $cell_result
# }

# close $af

# # ------------------------------------------------------------
# # 6. Pre-layout power with default activity
# # ------------------------------------------------------------

# puts "============================================================"
# puts "Running PRE-layout power analysis"
# puts "Using default switching activity = 0.10"
# puts "============================================================"

# if {[catch {
#     set_power_activity \
#         -input \
#         -activity 0.10
# } err]} {
#     puts "WARNING: set_power_activity -input failed:"
#     puts $err
# }

# if {[catch {
#     set_power_activity \
#         -global \
#         -activity 0.10
# } err]} {
#     puts "WARNING: set_power_activity -global failed:"
#     puts $err
# }

# report_power > reports/pre_power.rpt

# # ------------------------------------------------------------
# # 7. Done
# # ------------------------------------------------------------

# puts "============================================================"
# puts "PRE-layout analysis completed."
# puts ""
# puts "Generated:"
# puts "  reports/pre_setup.rpt"
# puts "  reports/pre_hold.rpt"
# puts "  reports/pre_critical_path.rpt"
# puts "  reports/pre_slack_summary.rpt"
# puts "  reports/pre_area.rpt"
# puts "  reports/pre_power.rpt"
# puts "============================================================"


# ============================================================
# pnr_4_post.tcl
# Task 4 - Post-Layout Analysis
# ============================================================

file mkdir results
file mkdir reports

# ------------------------------------------------------------
# 1. Files
# ------------------------------------------------------------

set LIB_FILE "sky130_fd_sc_hd__tt_025C_1v80.lib"
set SDC_FILE "sta.sdc"

set ROUTED_DB_FILE "results/task3_final_routed.odb"

# ------------------------------------------------------------
# 2. Check files
# ------------------------------------------------------------

if {![file exists $ROUTED_DB_FILE]} {
    puts "ERROR: Cannot find routed database:"
    puts "  $ROUTED_DB_FILE"
    puts "Make sure Task 3 generated results/task3_final_routed.odb"
    exit 1
}

if {![file exists $LIB_FILE]} {
    puts "ERROR: Cannot find Liberty file:"
    puts "  $LIB_FILE"
    exit 1
}

if {![file exists $SDC_FILE]} {
    puts "ERROR: Cannot find SDC file:"
    puts "  $SDC_FILE"
    exit 1
}

# ------------------------------------------------------------
# 3. Load routed design
# ------------------------------------------------------------

read_db $ROUTED_DB_FILE
read_liberty $LIB_FILE
read_sdc $SDC_FILE

puts "============================================================"
puts "Running POST-layout analysis"
puts "============================================================"

# # ------------------------------------------------------------
# # 4. Extract / estimate post-layout parasitics
# # ------------------------------------------------------------

# # ------------------------------------------------------------
# # Write estimated parasitics reports
# # ------------------------------------------------------------
# # estimate_parasitics -global_routing does not create real SPEF
# # extraction data in this OpenROAD build.
# # Therefore, save timing reports that include estimated RC effects.

# puts "============================================================"
# puts "Writing estimated-parasitics reports"
# puts "============================================================"

# report_checks \
#     -path_delay max \
#     -fields {slew cap input_pin net} \
#     -digits 4 \
#     > reports/post_setup_estimated_parasitics.rpt

# report_checks \
#     -path_delay min \
#     -fields {slew cap input_pin net} \
#     -digits 4 \
#     > reports/post_hold_estimated_parasitics.rpt

# report_checks \
#     -path_delay max \
#     -sort_by_slack \
#     -fields {slew cap input_pin net} \
#     -digits 4 \
#     -group_count 5 \
#     > reports/post_critical_paths_estimated_parasitics.rpt

# # Write a clear note explaining why SPEF is not generated.
# set spef_note [open "reports/final_estimated_parasitics_note.rpt" "w"]

# puts $spef_note "Estimated Parasitics Report"
# puts $spef_note "==========================="
# puts $spef_note ""
# puts $spef_note "Command executed:"
# puts $spef_note "  estimate_parasitics -global_routing"
# puts $spef_note ""
# puts $spef_note "The design was analyzed using global-routing estimated parasitics."
# puts $spef_note ""
# puts $spef_note "SPEF generation was attempted using write_spef, but this OpenROAD build reported:"
# puts $spef_note "  [INFO RCX-0134] Can't execute write_spef command. There's no extraction data."
# puts $spef_note ""
# puts $spef_note "Reason:"
# puts $spef_note "  estimate_parasitics -global_routing provides internal estimated RC values for STA,"
# puts $spef_note "  but it does not create OpenRCX extraction data that can be written as SPEF."
# puts $spef_note ""
# puts $spef_note "Evidence files:"
# puts $spef_note "  reports/post_setup_estimated_parasitics.rpt"
# puts $spef_note "  reports/post_hold_estimated_parasitics.rpt"
# puts $spef_note "  reports/post_critical_paths_estimated_parasitics.rpt"

# close $spef_note

# ------------------------------------------------------------
# 5. Write required post-layout files
# ------------------------------------------------------------

write_def     results/final.def
write_verilog results/final.v
write_spef    results/final.spef

write_def     results/task4_final.def
write_verilog results/task4_final.v
write_spef    results/task4_final.spef
write_db      results/task4_post_layout.odb

# ------------------------------------------------------------
# 6. Post-layout timing
# ------------------------------------------------------------

report_checks \
    -path_delay max \
    -fields {slew cap input_pin net} \
    -digits 4 \
    > reports/post_setup.rpt

report_checks \
    -path_delay min \
    -fields {slew cap input_pin net} \
    -digits 4 \
    > reports/post_hold.rpt

report_checks \
    -path_delay max \
    -sort_by_slack \
    -fields {slew cap input_pin net} \
    -digits 4 \
    -group_count 1 \
    > reports/post_critical_path.rpt

report_checks \
    -unconstrained \
    > reports/post_unconstrained_paths.rpt

# ------------------------------------------------------------
# 7. Post-layout WNS / TNS
# ------------------------------------------------------------

set fh [open "reports/post_slack_summary.rpt" "w"]

puts $fh "Post-Layout Slack Summary"
puts $fh "========================="
puts $fh ""

if {[catch {report_worst_slack} result]} {
    puts $fh "WNS: report_worst_slack not supported in this OpenROAD build."
} else {
    puts $fh "WNS / Worst Slack:"
    puts $fh $result
}

puts $fh ""

if {[catch {report_tns} result]} {
    puts $fh "TNS: report_tns not supported in this OpenROAD build."
} else {
    puts $fh "TNS / Total Negative Slack:"
    puts $fh $result
}

puts $fh ""
puts $fh "Detailed setup report: reports/post_setup.rpt"
puts $fh "Detailed hold report:  reports/post_hold.rpt"

close $fh

# ------------------------------------------------------------
# 8. Post-layout area
# ------------------------------------------------------------
# Generate both design-area and cell-usage reports.
# This avoids empty reports on OpenROAD builds where redirection
# does not capture report_design_area cleanly.

set paf [open "reports/post_area.rpt" "w"]

puts $paf "Post-Layout Area Report"
puts $paf "======================="
puts $paf ""

puts $paf "Design area report:"
puts $paf "-------------------"

if {[catch {report_design_area} area_result]} {
    puts $paf "report_design_area failed or is unsupported:"
    puts $paf $area_result
} else {
    puts $paf $area_result
}

puts $paf ""
puts $paf "Cell usage / standard-cell area report:"
puts $paf "---------------------------------------"

if {[catch {report_cell_usage} cell_result]} {
    puts $paf "report_cell_usage failed or is unsupported:"
    puts $paf $cell_result
} else {
    puts $paf $cell_result
}

close $paf

# ------------------------------------------------------------
# 9. Post-layout power with default activity
# ------------------------------------------------------------

puts "============================================================"
puts "Running POST-layout power analysis"
puts "Using default switching activity = 0.10"
puts "============================================================"

if {[catch {
    set_power_activity \
        -input \
        -activity 0.10
} err]} {
    puts "WARNING: set_power_activity -input failed:"
    puts $err
}

if {[catch {
    set_power_activity \
        -global \
        -activity 0.10
} err]} {
    puts "WARNING: set_power_activity -global failed:"
    puts $err
}

report_power > reports/post_power.rpt

set pfh [open "reports/post_power_activity_note.rpt" "w"]
puts $pfh "Post-Layout Power Activity Note"
puts $pfh "==============================="
puts $pfh ""
puts $pfh "No SAIF/VCD switching activity file was used."
puts $pfh "Post-layout power was estimated using default switching activity = 0.10."
puts $pfh "This is an estimated/default-activity power report."
close $pfh

# ------------------------------------------------------------
# 10. Done
# ------------------------------------------------------------

puts "============================================================"
puts "POST-layout analysis completed."
puts ""
puts "Required post-layout files:"
puts "  results/final.def"
puts "  results/final.spef"
puts "  results/final.v"
puts ""
puts "Generated reports:"
puts "  reports/post_setup.rpt"
puts "  reports/post_hold.rpt"
puts "  reports/post_critical_path.rpt"
puts "  reports/post_unconstrained_paths.rpt"
puts "  reports/post_slack_summary.rpt"
puts "  reports/post_area.rpt"
puts "  reports/post_power.rpt"
puts "============================================================"