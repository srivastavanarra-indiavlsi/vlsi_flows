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








