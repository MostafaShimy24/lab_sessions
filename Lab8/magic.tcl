# ============================================================
# run_magic_drc.tcl
# Simple Magic DRC run for LUT
# ============================================================

# ------------------------------------------------------------
# Input files
# ------------------------------------------------------------

set DESIGN_NAME "LUT"

set TECH_LEF "sky130_fd_sc_hd__nom.tlef"
set STD_CELL_LEF "sky130_fd_sc_hd.lef"
set DEF_FILE "final.def"
set STD_CELL_GDS "sky130_fd_sc_hd.gds"

set DRC_REPORT "magic_drc_report.txt"

# ------------------------------------------------------------
# Clean / prepare
# ------------------------------------------------------------

drc off

# ------------------------------------------------------------
# Read LEF, DEF, and standard-cell GDS
# ------------------------------------------------------------

lef read $TECH_LEF
lef read $STD_CELL_LEF

def read $DEF_FILE

gds read $STD_CELL_GDS

# ------------------------------------------------------------
# Load top cell
# ------------------------------------------------------------

load $DESIGN_NAME
select top cell
expand

# ------------------------------------------------------------
# Run DRC
# ------------------------------------------------------------

drc on
drc style drc(full)
drc check
drc count
# ------------------------------------------------------------
# Write DRC report
# ------------------------------------------------------------

set fp [open $DRC_REPORT w]

puts $fp "Magic DRC Report"
puts $fp "================"
puts $fp "Top cell: $DESIGN_NAME"
puts $fp ""

puts $fp [drc listall why]

close $fp

# ------------------------------------------------------------
# Optional: write GDS
# ------------------------------------------------------------

gds write ${DESIGN_NAME}.gds

puts "============================================================"
puts "Magic DRC completed."
puts "Report: $DRC_REPORT"
puts "GDS: ${DESIGN_NAME}.gds"
puts "============================================================"

quit -noprompt