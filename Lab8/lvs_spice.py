import re

infile = "LUT_layout_lvs.spice"
outfile = "LUT_layout_lvs_clean.spice"

ignore_prefixes = [
    "sky130_fd_sc_hd__fill_",
    "sky130_fd_sc_hd__decap_",
    "sky130_fd_sc_hd__tapvpwrvgnd_",
]

with open(infile, "r") as f:
    text = f.read()

# Remove SPICE instance lines/blocks.
# Standard-cell instances usually start with X and end with the cell name.
# This handles single-line and continuation-line instances.
for prefix in ignore_prefixes:
    pattern = rf"\nX\S+.*?{re.escape(prefix)}\S*(?=\nX|\n\.|\Z)"
    text = re.sub(pattern, "\n", text, flags=re.DOTALL | re.IGNORECASE)

with open(outfile, "w") as f:
    f.write(text)

print(f"Wrote: {outfile}")