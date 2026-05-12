#!/bin/bash

export PDK_ROOT="../pdk"

echo "========================================"
echo "      STEP 1: SPICE EXTRACTION          "
echo "========================================"
magic -dnull -noconsole -T $PDK_ROOT/sky130A.tech extract_layout.tcl

echo ""
echo "========================================"
echo "      STEP 2: PREPARING LVS SETUP       "
echo "========================================"
# Copy the default foundry setup script
cp $PDK_ROOT/sky130A_setup.tcl results/custom_setup.tcl

# Inject commands to make Netgen ignore the physical dummy cells
cat << 'EOF' >> results/custom_setup.tcl

# --- CUSTOM LAB ALIGNMENT ---
# Ignore physical-only filler and tap cells for Gate-Level LVS
ignore class sky130_fd_sc_hd__fill_1
ignore class sky130_fd_sc_hd__fill_2
ignore class sky130_fd_sc_hd__fill_4
ignore class sky130_fd_sc_hd__fill_8
ignore class sky130_fd_sc_hd__tapvpwrvgnd_1

# Force top-level net mapping
equate nodes riscv_top_synth VDD VDD
equate nodes riscv_top_synth VSS VSS
EOF

echo "Custom setup generated."

echo ""
echo "========================================"
echo "      STEP 3: NETGEN LVS COMPARISON     "
echo "========================================"
# Run Netgen using our new custom_setup.tcl
cd results
netgen -batch lvs "layout.spice riscv_top_synth" "final.v riscv_top_synth" custom_setup.tcl lvs_report.out

echo ""
echo "=== LVS Run Complete! ==="
echo "Check results/lvs_report.out for details."
