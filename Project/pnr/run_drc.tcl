# ==============================================================================
# run_drc.tcl - Magic Script for GDS Generation and DRC Analysis
# ==============================================================================
# magic -dnull -noconsole -T /mnt/FA685EF1685EAC5F/University/Advanced-Microelectronics-Lab/pdk/sky130A/libs.tech/magic/sky130A.tech run_drc.tcl

set PDK_ROOT "/mnt/FA685EF1685EAC5F/University/Advanced-Microelectronics-Lab/pdk/sky130A"

puts "--- 1. Reading Standard Cell LEF ---"
# Magic needs the LEF first to understand the bounding boxes and pin locations
lef read $PDK_ROOT/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
lef read $PDK_ROOT/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef

puts "--- 2. Loading Standard Cell GDS ---"
# Replace the abstract LEF boxes with the actual physical transistor layouts
gds read $PDK_ROOT/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds

puts "--- 3. Reading Routed DEF ---"
# Load your routing from OpenROAD
def read results/final.def

puts "--- 4. Writing Final Merged GDS ---"
# Save the complete, flat layout for your deliverables
gds write results/final.gds

puts "--- 5. Running DRC Analysis ---"
# Select the entire design and expand subcells
select top cell
expand
drc catchup

puts "--- 6. Generating DRC Report ---"
# Safely grab ONLY the total integer count to avoid the list memory bug
set drc_count [drc list count total]

# Write out the clean report
set fout [open "results/drc_report.txt" w]
puts $fout "========================================"
puts $fout "         MAGIC DRC ANALYSIS REPORT      "
puts $fout "========================================\n"
puts $fout "Total DRC Errors: $drc_count\n"

if {$drc_count > 0} {
    puts $fout "Note: Magic encountered $drc_count errors."
    puts $fout "Please run the KLayout DRC script to see the specific violation types and locations."
} else {
    puts $fout "Congratulations! The design is DRC clean."
}
close $fout

puts "\n=== DRC Complete! ==="
puts "Total Errors: $drc_count"
puts "Details saved to: results/drc_report.txt"
puts "Final layout saved to: results/final.gds"

# Exit Magic cleanly
quit -noprompt
