set PDK_ROOT "../pdk"

puts "--- 1. Reading Tech LEF and Standard Cell LEF ---"
# Magic MUST read the tech LEF first to understand vias!
lef read $PDK_ROOT/sky130_fd_sc_hd__nom.tlef
lef read $PDK_ROOT/sky130_fd_sc_hd.lef

puts "--- 2. Reading Routed DEF ---"
def read results/final.def
load riscv_top_synth

puts "--- 3. Extracting Layout ---"
extract do local
extract no all
extract unique
extract

puts "--- 4. Writing SPICE Netlist ---"
ext2spice lvs
ext2spice -o results/layout.spice

puts "\n=== Extraction Complete! Saved to results/layout.spice ==="
quit -noprompt
