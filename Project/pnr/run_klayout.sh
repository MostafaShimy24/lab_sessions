#!/bin/bash

# ==============================================================================
# run_klayout.sh - KLayout DRC Batch Script & Report Generator
# ==============================================================================

# Define paths
export PDK_ROOT="/mnt/FA685EF1685EAC5F/University/Advanced-Microelectronics-Lab/pdk/sky130A"

# The Sky130 Manufacturing Rule (MR) DRC deck for KLayout
export DRC_DECK="$PDK_ROOT/libs.tech/klayout/drc/sky130A_mr.drc"

cd results

echo "--- 1. Running KLayout DRC ---"
echo "Using GDS: final.gds"
echo "Using Deck: $DRC_DECK"

# Run KLayout in batch mode (-b), execute the DRC script (-r), and pass input/output parameters
klayout -b -r "$DRC_DECK" -rd input=final.gds -rd report=klayout_drc.lyrdb

echo "--- 2. Parsing DRC Results ---"
# KLayout outputs a heavy XML marker database (.lyrdb). 
# We use a quick inline python script to parse it into a clean text report.
python3 -c "
import xml.etree.ElementTree as ET
import os

if not os.path.exists('klayout_drc.lyrdb'):
    print('Error: klayout_drc.lyrdb was not generated.')
    exit()

tree = ET.parse('klayout_drc.lyrdb')
root = tree.getroot()

total_errors = 0
error_counts = {}

# Locate the violations ('items' node in the XML)
items = root.find('items')
if items is not None:
    for item in items.findall('item'):
        cat_node = item.find('category')
        if cat_node is not None:
            # Clean up the category name string
            cat = cat_node.text.strip('\'')
            error_counts[cat] = error_counts.get(cat, 0) + 1
            total_errors += 1

print('\n========================================')
print('        KLAYOUT DRC ANALYSIS REPORT     ')
print('========================================')
print(f'Total DRC Errors: {total_errors}\n')

if total_errors > 0:
    print('Error Types and Details:')
    print('------------------------')
    for cat, count in error_counts.items():
        print(f'- {cat}: {count} violations')
else:
    print('Congratulations! The design is DRC clean in KLayout.')
" > klayout_drc_report.txt

# Print the report to the terminal
cat klayout_drc_report.txt
echo -e "\n=== KLayout DRC Complete! Saved to results/klayout_drc_report.txt ==="
