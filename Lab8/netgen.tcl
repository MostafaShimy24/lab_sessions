# ============================================================
# run_lvs.tcl
# Netgen LVS for LUT
# ============================================================

set DESIGN_NAME LUT

set LAYOUT_NETLIST LUT_layout_lvs.spice
set SOURCE_NETLIST finalll.v
set SETUP_FILE sky130A_setup.tcl


# Ignore physical-only cells
# ------------------------------------------------------------
set ignore_cells {
    sky130_fd_sc_hd__fill_1
    sky130_fd_sc_hd__fill_2
    sky130_fd_sc_hd__fill_4
    sky130_fd_sc_hd__fill_8
    sky130_fd_sc_hd__decap_3
}


# ------------------------------------------------------------
# Run LVS
# ------------------------------------------------------------
lvs "$LAYOUT_NETLIST $DESIGN_NAME" \
    "$SOURCE_NETLIST $DESIGN_NAME" \
    $SETUP_FILE \
    lvs_report.out \
    -ignore $ignore_cells \
    -json

quit


