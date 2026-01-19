#!/usr/bin/tclsh
#==============================================================================
# Standard Cell Placement - Main Execution Script
# File: run_placement.tcl
# Description: Main driver script that calls procedures from library
#==============================================================================

puts "=========================================="
puts "Standard Cell Placement Flow"
puts "Cadence Innovus"
puts "=========================================="

#------------------------------------------------------------------------------
# Load Configuration File
#------------------------------------------------------------------------------
puts "\n--- Loading Configuration ---"
if {[info exists env(PLACEMENT_CONFIG)]} {
    set config_file $env(PLACEMENT_CONFIG)
} else {
    set config_file "placement_config.tcl"
}

if {[file exists $config_file]} {
    puts "Configuration file: $config_file"
    source $config_file
} else {
    puts "ERROR: Configuration file not found: $config_file"
    puts "Please provide placement_config.tcl"
    exit 1
}

#------------------------------------------------------------------------------
# Load Procedures Library
#------------------------------------------------------------------------------
puts "\n--- Loading Procedures Library ---"
set procs_file "placement_procs.tcl"

if {[file exists $procs_file]} {
    puts "Procedures file: $procs_file"
    source $procs_file
} else {
    puts "ERROR: Procedures file not found: $procs_file"
    puts "Please provide placement_procs.tcl"
    exit 1
}

#------------------------------------------------------------------------------
# Create Output Directories
#------------------------------------------------------------------------------
puts "\n--- Creating Output Directories ---"
file mkdir $REPORT_DIR
file mkdir $RESULT_DIR
file mkdir $LOG_DIR
puts "Output directories created"

#------------------------------------------------------------------------------
# Main Execution Flow
#------------------------------------------------------------------------------
proc main {} {
    global DESIGN_NAME PLACEMENT_EFFORT TIMING_DRIVEN CONGESTION_DRIVEN
    global MAX_DENSITY RESULT_DIR REPORT_DIR
    
    # Start timing
    set start_time [clock seconds]
    
    puts "\n=========================================="
    puts "Starting Placement Flow"
    puts "=========================================="
    puts "Design: $DESIGN_NAME"
    puts "Date: [clock format $start_time -format "%Y-%m-%d %H:%M:%S"]"
    
    # Step 1: Load design data (LEF, LIB, netlist, DEF, SDC)
    load_design_data
    
    # Step 2: Verify design state
    verify_design_state
    
    # Step 3: Check prerequisites
    if {![check_prerequisites]} {
        puts "\nERROR: Prerequisites not met. Exiting."
        exit 1
    }
    
    # Step 4: Pre-placement setup
    pre_placement_setup
    
    # Step 5: Configure placement
    configure_placement $PLACEMENT_EFFORT $TIMING_DRIVEN $CONGESTION_DRIVEN
    
    # Step 6: Run placement
    run_placement $MAX_DENSITY
    
    # Step 7: Post-placement optimization
    post_placement_optimization
    
    # Step 8: Quality checks
    check_placement_quality
    
    # Step 9: Save results
    save_placement $DESIGN_NAME
    
    # Calculate runtime
    set end_time [clock seconds]
    set runtime [expr $end_time - $start_time]
    set runtime_hr [expr $runtime / 3600]
    set runtime_min [expr ($runtime % 3600) / 60]
    set runtime_sec [expr $runtime % 60]
    
    puts "\n=========================================="
    puts "Placement Flow Completed Successfully"
    puts "=========================================="
    puts "Runtime: ${runtime_hr}h ${runtime_min}m ${runtime_sec}s"
    puts "\nOutput Files:"
    puts "  Design DB: ${RESULT_DIR}/${DESIGN_NAME}_placed.enc"
    puts "  DEF File:  ${RESULT_DIR}/${DESIGN_NAME}_placed.def"
    puts "  Netlist:   ${RESULT_DIR}/${DESIGN_NAME}_placed.v"
    puts "  Reports:   ${REPORT_DIR}/"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Execute Main Flow
#------------------------------------------------------------------------------
# Catch any errors and provide meaningful output
if {[catch {main} err]} {
    puts "\n=========================================="
    puts "ERROR: Placement flow failed"
    puts "=========================================="
    puts "Error message: $err"
    puts "Error info: $::errorInfo"
    exit 1
}

puts "\nPlacement flow completed without errors"
exit 0
