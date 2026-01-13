 --------- LVS SCRIPT ------------------------------------------------------------------
#!/usr/bin/tclsh
# lvs_run.tcl : Script to run a physical verification LVS check

# --- 1. Configuration Variables ---
set DESIGN_TOP_CELL "Design_name"
set LVS_RUN_DIR     "./lvs_results"

# Input Files
set INPUT_LAYOUT_GDS "./${DESIGN_TOP_CELL}.gds"
set INPUT_SCHEMATIC_NETLIST "./${DESIGN_TOP_CELL}.spi" ; # SPICE netlist extracted from schematic/cdl files (Circuit Description language)

# Foundry-provided LVS Rule Deck (Proprietary file)
set LVS_RULE_DECK   "/path/to/foundry_pdk/foundry_lvs_rules.ruledeck"

# Output Files
set LVS_REPORT_FILE "${LVS_RUN_DIR}/lvs_final_report.txt"
set LVS_RESULTS_DB  "${LVS_RUN_DIR}/lvs_database.results"

# Ensure the results directory exists
exec mkdir -p $LVS_RUN_DIR

puts "--- Starting LVS Verification Run ---"

# --- 2. Main Execution Command (Tool-Specific) ---

# This command is a placeholder for the actual command used by a specific EDA vendor.
# Example command using generic syntax:

run_lvs_verification \
    -layout_file $INPUT_LAYOUT_GDS \
    -layout_top_cell $DESIGN_TOP_CELL \
    -schematic_netlist_file $INPUT_SCHEMATIC_NETLIST \
    -rule_deck_file $LVS_RULE_DECK \
    -report_file $LVS_REPORT_FILE \
    -results_database $LVS_RESULTS_DB \
    -connect_by_net_name_only false ; # Must match by physical connectivity, not just name

# --- 3. Post-Run Analysis ---

puts "--- LVS execution complete. Checking status. ---"

# In a real script, you would check the exit status of the run_lvs_verification command
# and parse the report file to see if the status is "MATCHED" or "SUCCESS".

# Check the report file for match status (conceptual check)
if {[file exists $LVS_REPORT_FILE]} {
    if {[exec grep -i "MATCHED" $LVS_REPORT_FILE] != ""} {
        puts "SUCCESS: LVS Matched! Layout is electrically correct."
    } else {
        puts "WARNING: LVS did not match. See $LVS_REPORT_FILE for errors."
    }
} else {
    puts "Error: LVS report file was not generated."
}

puts "--- LVS Script Finished ---"
tcl ------- ERC SCRIPT ------
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
















Tcl ----- MFILL SCRIPT ------
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















Tcl. --- NMDRC SCRIPT
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






