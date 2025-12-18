##Tcl --- NMDRC SCRIPT
#!/usr/bin/tclsh
# -------------------------------------------------------------
# Script to run Calibre Metal Fill (MFill) in Batch Mode
# -------------------------------------------------------------

# --- 1. Define Design and File Paths ---
set DESIGN_TOP_CELL "my_chip_final"
set INPUT_LAYOUT_FILE "./tapeout/${DESIGN_TOP_CELL}.gds"
set RUN_DIR         "./results/mfill_run"
set LAYOUT_FORMAT   "GDSII"

# --- 2. Define Output Files ---
# The primary output is a new GDS file that contains all original data + new fill shapes
set MFILL_OUTPUT_GDS "${RUN_DIR}/${DESIGN_TOP_CELL}_with_fill.gds"
set MFILL_REPORT     "${RUN_DIR}/mfill_report.txt"

# --- 3. Specify the Foundry Metal Fill Rule Deck ---
# NOTE: This file is proprietary to the foundry and defines density/spacing rules
set MFILL_RULES_FILE "/path/to/foundry_pdk/Calibre_N5_MFILL.svrf"

# Ensure the run directory exists before running the tool
exec mkdir -p $RUN_DIR

puts "--- Launching Calibre Metal Fill (SmartFill) Run ---"

# --- 4. Execute the Calibre Command ---

# This command runs the DRC process using the MFILL rules, which inherently
# include the commands to generate fill shapes as part of the check
exec calibre -hier -batch -drc \
    -design $INPUT_LAYOUT_FILE $DESIGN_TOP_CELL \
    -ruledir $MFILL_RULES_FILE \
    -format $LAYOUT_FORMAT \
    -drc_results_database $MFILL_OUTPUT_GDS \
    -report $MFILL_REPORT \
    -append ; # Append additional options/flags if needed

puts "--- Calibre Metal Fill command executed. ---"
puts "New GDS file generated with fill shapes: $MFILL_OUTPUT_GDS"
puts "Check $MFILL_REPORT for any DRC violations caused by fill."
