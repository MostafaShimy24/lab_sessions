#!/bin/bash

# ============================================================
# run_klayout_drc.sh
# Run KLayout DRC on LUT.gds
# Assumes all required files are in the current directory
# Includes DRC marker count
# ============================================================

set -e

DESIGN_NAME="LUT"
GDS_FILE="LUT.gds"
DRC_DECK="sky130A.lydrc"
REPORT_FILE="klayout_drc_report.lyrdb"
LOG_FILE="klayout_drc.log"

echo "============================================================"
echo "KLayout DRC Run"
echo "============================================================"

# ------------------------------------------------------------
# Check required files
# ------------------------------------------------------------

if ! command -v klayout >/dev/null 2>&1; then
    echo "ERROR: klayout command not found."
    exit 1
fi

if [ ! -f "$GDS_FILE" ]; then
    echo "ERROR: Cannot find GDS file: $GDS_FILE"
    exit 1
fi

if [ ! -f "$DRC_DECK" ]; then
    echo "ERROR: Cannot find DRC deck: $DRC_DECK"
    echo "Expected it in the same directory as this script."
    exit 1
fi

# ------------------------------------------------------------
# Clean old outputs
# ------------------------------------------------------------

rm -f "$REPORT_FILE" "$LOG_FILE"

# ------------------------------------------------------------
# Run DRC
# ------------------------------------------------------------

echo "Design: $DESIGN_NAME"
echo "GDS:    $GDS_FILE"
echo "Deck:   $DRC_DECK"
echo "Report: $REPORT_FILE"
echo ""

klayout -b -r "$DRC_DECK" \
    -rd input="$GDS_FILE" \
    -rd topcell="$DESIGN_NAME" \
    -rd report="$REPORT_FILE" \
    2>&1 | tee "$LOG_FILE"

# ------------------------------------------------------------
# Count DRC markers
# ------------------------------------------------------------

DRC_COUNT="UNKNOWN"

if [ -f "$REPORT_FILE" ]; then
    # KLayout marker DB is XML-like. Most marker entries are stored as <item>.
    DRC_COUNT=$(grep -c "<item>" "$REPORT_FILE" || true)

    # Fallback for other marker DB formats
    if [ "$DRC_COUNT" -eq 0 ]; then
        DRC_COUNT=$(grep -c "<marker>" "$REPORT_FILE" || true)
    fi
fi

# ------------------------------------------------------------
# Check result
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "KLayout DRC completed"
echo "============================================================"

if [ -f "$REPORT_FILE" ]; then
    echo "Generated marker report:"
    echo "  $REPORT_FILE"
    echo ""
    echo "Number of DRC errors / markers: $DRC_COUNT"
    echo ""
    echo "Open with:"
    echo "  klayout $GDS_FILE -m $REPORT_FILE"
else
    echo "WARNING: KLayout finished, but no marker report was generated."
    echo "Check:"
    echo "  $LOG_FILE"
fi

echo "Log file:"
echo "  $LOG_FILE"
echo "============================================================"