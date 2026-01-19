Main CTS Execution Script
################################################################################
print_banner "CCOpt CTS Flow - Post-Placement"
################################################################################
STEP 1: SOURCE FILES
################################################################################
puts "\n>>> Loading configuration and procedures..."
set script_dir [file dirname [info script]]
if {[file exists $script_dir/cts_vars.tcl]} {
source $script_dir/cts_vars.tcl
puts "✓ Variables loaded"
} else {
puts "✗ ERROR: cts_vars.tcl not found"
exit 1
}
if {[file exists $script_dir/cts_procs.tcl]} {
source $script_dir/cts_procs.tcl
puts "✓ Procedures loaded"
} else {
puts "✗ ERROR: cts_procs.tcl not found"
exit 1
}
################################################################################
STEP 2: SETUP
################################################################################
print_banner "Setup"
setup_directories
if {![validate_config]} {
log_message "ERROR: Configuration validation failed!"
exit 1
}
################################################################################
STEP 3: LOAD POST-PLACEMENT DATABASE
################################################################################
if {$CTS_CONFIG(load_db)} {
if {![load_placement_database]} {
exit 1
}
}
################################################################################
STEP 4: LOAD SDC CONSTRAINTS
################################################################################
if {![load_sdc_constraints]} {
exit 1
}
################################################################################
STEP 5: VERIFY PLACEMENT
################################################################################
if {![verify_placement_status]} {
log_message "ERROR: Placement verification failed!"
exit 1
}
################################################################################
STEP 6: ANALYZE CLOCK STRUCTURE
################################################################################
if {![analyze_clock_structure]} {
log_message "WARNING: No clocks found, but continuing..."
}
################################################################################
STEP 7: GENERATE AND DUMP CTS SPEC
################################################################################
if {$CTS_CONFIG(dump_cts_spec)} {
set spec_file [generate_cts_spec]
log_message "INFO: CTS specification generated: $spec_file"
}
################################################################################
STEP 8: PRE-CTS REPORTS AND CHECKPOINT
################################################################################
print_banner "Pre-CTS Phase"
save_prects_checkpoint
generate_prects_reports
################################################################################
STEP 9: APPLY CCOPT CONFIGURATION
################################################################################
print_banner "CCOpt Configuration"
apply_ccopt_specifications
configure_advanced_ccopt
configure_routing
configure_power_optimization
################################################################################
STEP 10: MCMM SETUP
################################################################################
if {$CTS_CONFIG(update_mcmm) && [llength $CTS_CONFIG(setup_views)] > 0} {
print_section "MCMM Setup"
update_timing
if {$CTS_CONFIG(concurrent_mcmm)} {
    set_analysis_mode -analysisType onChipVariation
}

log_message "INFO: MCMM configured"

################################################################################
STEP 11: CLOCK-SPECIFIC SETTINGS
################################################################################
apply_clock_specific_settings
################################################################################
STEP 12: CREATE CLOCK TREE SPEC
################################################################################
print_section "Creating Clock Tree Specification"
if {![info exists CTS_CONFIG(clock_specs)] || [array size CTS_CONFIG] == 0} {
create_ccopt_clock_tree_spec
}
log_message "INFO: Clock tree spec created"
################################################################################
STEP 13: DUMP CURRENT CTS SPEC
################################################################################
if {$CTS_CONFIG(dump_cts_spec)} {
dump_current_cts_spec
}
################################################################################
STEP 14: RUN CTS
################################################################################
set cts_runtime [run_ccopt_cts]
################################################################################
STEP 15: POST-CTS OPTIMIZATION
################################################################################
set opt_runtime [run_postcts_optimization]
################################################################################
STEP 16: GENERATE REPORTS
################################################################################
generate_postcts_reports
################################################################################
STEP 17: SAVE DESIGN
################################################################################
save_postcts_design
################################################################################
STEP 18: SUMMARY
################################################################################
print_cts_summary $cts_runtime $opt_runtime
print_banner "CTS Flow Completed"
################################################################################
END OF run_cts_main.tcl
################################################################################
