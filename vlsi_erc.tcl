 ------- ERC SCRIPT ------
#!/usr/bin/tclsh
# -------------------------------------------------------------
# Script to run Calibre ERC in Batch Mode
# -------------------------------------------------------------

# --- 1. Define Design and File Paths ---
set DESIGN_TOP_CELL "top_level_soc"
set INPUT_LAYOUT_FILE "./layout/${DESIGN_TOP_CELL}.gds"
set LVS_RUN_DIR     "./results/erc_run"
set LAYOUT_FORMAT   "GDSII"

# --- 2. Define Output Files ---
set ERC_REPORT      "${LVS_RUN_DIR}/${DESIGN_TOP_CELL}.erc.report"
set ERC_SUMMARY     "${LVS_RUN_DIR}/${DESIGN_TOP_CELL}.erc.summary"
set ERC_DB          "${LVS_RUN_DIR}/${DESIGN_TOP_CELL}.erc.resultsdb"

# --- 3. Specify the Foundry ERC Rule Deck ---
# NOTE: This file is proprietary and contains all the specific ERC rules in SVRF/TVF format
set ERC_RULES_FILE "/path/to/foundry_pdk/Calibre_N5_ERC.svrf"

# Ensure the run directory exists
exec mkdir -p $LVS_RUN_DIR

puts "--- Launching Calibre PERC/ERC Run for $DESIGN_TOP_CELL ---"

# --- 4. Execute the Calibre Command ---

# The 'exec' command is used in Tcl to run an external program (the calibre executable)
exec calibre -perc -batch \
    -design $INPUT_LAYOUT_FILE $DESIGN_TOP_CELL \
    -ruledir $ERC_RULES_FILE \
    -format $LAYOUT_FORMAT \
    -report $ERC_REPORT \
    -summary $ERC_SUMMARY \
    -results_database $ERC_DB

# Note: Calibre typically runs as a heavy background process. A more robust script 
# would check the return status of the 'exec' com


