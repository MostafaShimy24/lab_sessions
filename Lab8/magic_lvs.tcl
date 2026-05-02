# # ============================================================
# # run_magic_extract_lvs.tcl
# # Extract LVS-clean SPICE from LUT.gds
# # ============================================================

# set DESIGN_NAME "LUT"
# set GDS_FILE "LUT.gds"

# drc off

# gds read $GDS_FILE

# load $DESIGN_NAME
# select top cell
# expand

# extract all

# # LVS mode
# ext2spice lvs

# # Do NOT include tiny parasitic caps/resistors in LVS
# ext2spice cthresh 999
# ext2spice rthresh 999

# # Write top as subcircuit
# ext2spice subcircuit top on

# # Write extracted SPICE
# ext2spice -o ${DESIGN_NAME}_layout_lvs.spice

# puts "Generated: ${DESIGN_NAME}_layout_lvs.spice"

# quit -noprompt





# ============================================================
# run_magic_extract_lvs.tcl (CLEAN VERSION)
# ============================================================

set DESIGN_NAME "LUT"
set GDS_FILE "LUT.gds"

drc off

gds read $GDS_FILE

load $DESIGN_NAME
select top cell
expand

# ------------------------------------------------------------
# Extraction
# ------------------------------------------------------------
extract do local       ;# avoid global net pollution
extract no all         ;# reset extraction options
extract all

# ------------------------------------------------------------
# LVS mode (important)
# ------------------------------------------------------------
ext2spice lvs

# Remove parasitics completely
ext2spice cthresh infinite
ext2spice rthresh infinite

# Reduce unwanted nodes
ext2spice short resistor
ext2spice merge conservative

# Ignore floating parasitic nodes
ext2spice ignore floating

# Write as subckt
ext2spice subcircuit top on

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------
ext2spice -o ${DESIGN_NAME}_layout_lvs.spice

puts "Generated CLEAN LVS netlist: ${DESIGN_NAME}_layout_lvs.spice"

quit -noprompt





