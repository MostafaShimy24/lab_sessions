import re

infile = "final.v"
outfile = "final_lvs_clean.v"

# Physical-only cells to ignore in LVS
ignore_prefixes = [
    "sky130_fd_sc_hd__fill_",
    "sky130_fd_sc_hd__decap_",
    "sky130_fd_sc_hd__tapvpwrvgnd_",
]

with open(infile, "r") as f:
    text = f.read()

for prefix in ignore_prefixes:
    # Remove multiline Verilog instances:
    # sky130_fd_sc_hd__fill_1 FILLER_0_0 (...);
    pattern = rf"\s*{re.escape(prefix)}\S*\s+\S+\s*\(.*?\);\s*"
    text = re.sub(pattern, "\n", text, flags=re.DOTALL)

with open(outfile, "w") as f:
    f.write(text)

print(f"Wrote: {outfile}")