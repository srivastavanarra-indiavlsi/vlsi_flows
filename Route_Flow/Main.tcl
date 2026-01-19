################################################################################
# route_main.tcl
# Main script for routing stage
# Supports: 16nm, 7nm, 5nm technologies
################################################################################

puts "=========================================================================="
puts "                    ROUTING STAGE - START"
puts "=========================================================================="
set script_start_time [clock seconds]

################################################################################
# Technology Selection
################################################################################
# Set your technology node here: 16nm, 7nm, or 5nm
if {![info exists TECH_NODE]} {
    set TECH_NODE "7nm"  ;# Default to 7nm if not set
}

puts "INFO: Selected Technology Node: ${TECH_NODE}"

################################################################################
# Source configuration files
################################################################################
puts "\n>>> Sourcing configuration files..."

# Source technology-specific variables
if {$TECH_NODE == "16nm"} {
    if {[file exists ./scripts/routing_vars_16nm.tcl]} {
        source ./scripts/routing_vars_16nm.tcl
        puts "INFO: Loaded 16nm routing variables"
    } else {
        puts "ERROR: routing_vars_16nm.tcl not found!"
        exit 1
    }
} elseif {$TECH_NODE == "7nm"} {
    if {[file exists ./scripts/routing_vars_7nm.tcl]} {
        source ./scripts/routing_vars_7nm.tcl
        puts "INFO: Loaded 7nm routing variables"
    } else {
        puts "ERROR: routing_vars_7nm.tcl not found!"
        exit 1
    }
} elseif {$TECH_NODE == "5nm"} {
    if {[file exists ./scripts/routing_vars_5nm.tcl]} {
        source ./scripts/routing_vars_5nm.tcl
        puts "INFO: Loaded 5nm routing variables"
    } else {
        puts "ERROR: routing_vars_5nm.tcl not found!"
        exit 1
    }
} else {
    puts "ERROR: Unsupported technology node: ${TECH_NODE}"
    puts "       Supported nodes: 16nm, 7nm, 5nm"
    exit 1
}

# Source procedures
if {[file exists ./scripts/routing_procs.tcl]} {
    source ./scripts/routing_procs.tcl
    puts "INFO: Loaded routing_procs.tcl"
} else {
    puts "ERROR: routing_procs.tcl not found!"
    exit 1
}

################################################################################
# Create directories
################################################################################
puts "\n>>> Creating directory structure..."
file mkdir ${RESULTS_DIR}/route
file mkdir ${REPORTS_DIR}/route
file mkdir ${LOGS_DIR}/route

################################################################################
# Restore CTS database
################################################################################
puts "\n>>> Restoring CTS database..."
if {[file exists $CTS_DB]} {
    restoreDesign $CTS_DB ${DESIGN_NAME}
    puts "INFO: CTS database restored successfully."
} else {
    puts "ERROR: CTS database not found at: $CTS_DB"
    exit 1
}

# Set multi-corner multi-mode if required
if {[info exists MCMM_CONFIG]} {
    set_multi_cpu_usage -localCpu $NUM_CORES
}

################################################################################
# Pre-route Setup
################################################################################
puts "\n>>> Setting up routing environment..."

# Initialize timing
timeDesign -preCTS -prefix preroute_initial

# Run pre-route checks
if {[catch {pre_route_checks} result]} {
    puts "ERROR: Pre-route checks failed: $result"
    exit 1
}

# Setup routing options
setup_routing_options

# Set routing constraints
puts "INFO: Setting routing constraints..."

# Set routing blockages if needed
# createRouteBlk -layer {M1 M2} -box {100 100 200 200} -name blk1

# Set shielding for critical nets if required
if {$SR_ENABLE_SHIELDING} {
    # Example: setAttribute -net clk_net -shield_net VSS
}

# Set non-default rules for critical nets
# createRouteNDR -name 2x2x -spacing {M1:M9 2} -width {M1:M9 2}
# setAttribute -net critical_net -non_default_rule 2x2x

################################################################################
# STEP 1: Global Routing
################################################################################
puts "\n=========================================================================="
puts "STEP 1: Global Routing"
puts "=========================================================================="

set step_start [clock seconds]
run_global_route
set step_end [clock seconds]
puts "INFO: Global routing completed in [expr $step_end - $step_start] seconds."

# Save checkpoint
saveDesign ${RESULTS_DIR}/route/${DESIGN_NAME}_groute.enc

################################################################################
# STEP 2: Track Assignment
################################################################################
puts "\n=========================================================================="
puts "STEP 2: Track Assignment"
puts "=========================================================================="

set step_start [clock seconds]
run_track_assignment
set step_end [clock seconds]
puts "INFO: Track assignment completed in [expr $step_end - $step_start] seconds."

################################################################################
# STEP 3: Detail Routing
################################################################################
puts "\n=========================================================================="
puts "STEP 3: Detail Routing"
puts "=========================================================================="

set step_start [clock seconds]
run_detail_route
set step_end [clock seconds]
puts "INFO: Detail routing completed in [expr $step_end - $step_start] seconds."

# Save checkpoint
saveDesign ${RESULTS_DIR}/route/${DESIGN_NAME}_droute.enc

################################################################################
# STEP 4: Search and Repair
################################################################################
puts "\n=========================================================================="
puts "STEP 4: Search and Repair Routing"
################################################################################

if {$SR_ENABLE_DETOUR} {
    puts "INFO: Running search and repair..."
    set step_start [clock seconds]
    
    # Set S&R options
    setNanoRouteMode -drouteSearchAndRepair true
    setNanoRouteMode -drouteAutoStop false
    
    # Run search and repair
    searchRepair -noOpt
    
    set step_end [clock seconds]
    puts "INFO: Search and repair completed in [expr $step_end - $step_start] seconds."
}

################################################################################
# STEP 5: Fix DRC Violations
################################################################################
puts "\n=========================================================================="
puts "STEP 5: DRC Violation Fixing"
puts "=========================================================================="

set step_start [clock seconds]
fix_routing_drc
set step_end [clock seconds]
puts "INFO: DRC fixing completed in [expr $step_end - $step_start] seconds."

################################################################################
# STEP 6: Antenna Fix
################################################################################
puts "\n=========================================================================="
puts "STEP 6: Antenna Fixing"
puts "=========================================================================="

if {$ANTENNA_CHECK} {
    puts "INFO: Checking and fixing antenna violations..."
    
    # Check antenna
    verifyProcessAntenna -reportfile ${REPORTS_DIR}/route/${DESIGN_NAME}_antenna.rpt
    
    # Fix antenna
    if {$ANTENNA_FIX_DIODE} {
        setNanoRouteMode -drouteFixAntenna true
        addDiodeCell -cell $ANTENNA_DIODE_CELL
    }
    
    if {$ANTENNA_FIX_JUMPER} {
        ecoRoute -fix_antenna
    }
    
    # Re-verify
    verifyProcessAntenna -reportfile ${REPORTS_DIR}/route/${DESIGN_NAME}_antenna_final.rpt
}

################################################################################
# STEP 7: Post-Route Optimization
################################################################################
puts "\n=========================================================================="
puts "STEP 7: Post-Route Optimization"
puts "=========================================================================="

set step_start [clock seconds]
optimize_post_route
set step_end [clock seconds]
puts "INFO: Post-route optimization completed in [expr $step_end - $step_start] seconds."

# Save checkpoint after optimization
saveDesign ${RESULTS_DIR}/route/${DESIGN_NAME}_postroute_opt.enc

################################################################################
# STEP 8: Via Optimization
################################################################################
puts "\n=========================================================================="
puts "STEP 8: Via Optimization"
puts "=========================================================================="

if {$REDUNDANT_VIA_INSERTION} {
    puts "INFO: Inserting redundant vias..."
    
    # Add redundant vias
    addRedundantVia
    
    # Verify
    verify_drc
}

################################################################################
# STEP 9: Add Filler Cells
################################################################################
puts "\n=========================================================================="
puts "STEP 9: Adding Filler Cells"
puts "=========================================================================="

add_filler_cells

################################################################################
# STEP 10: Metal Fill
################################################################################
puts "\n=========================================================================="
puts "STEP 10: Metal Fill"
puts "=========================================================================="

if {$METAL_FILL_ENABLE} {
    puts "INFO: Adding metal fill..."
    
    # Set metal fill options
    setMetalFill -layer {M1 M2 M3 M4 M5 M6 M7 M8 M9}
    
    if {$METAL_FILL_TIMING_AWARE} {
        addMetalFill -timingAware true
    } else {
        addMetalFill
    }
}

################################################################################
# STEP 11: Final Verification
################################################################################
puts "\n=========================================================================="
puts "STEP 11: Final Verification"
puts "=========================================================================="

puts "INFO: Running final verifications..."

# Verify geometry
if {$VERIFY_GEOMETRY} {
    verifyGeometry -report ${REPORTS_DIR}/route/${DESIGN_NAME}_geometry.rpt
}

# Verify connectivity
if {$VERIFY_CONNECTIVITY} {
    verify_connectivity
}

# Verify process antenna
if {$VERIFY_PROCESS_ANTENNA} {
    verifyProcessAntenna -reportfile ${REPORTS_DIR}/route/${DESIGN_NAME}_antenna_final.rpt
}

# Final DRC check
verify_drc -limit 1000000 -report ${REPORTS_DIR}/route/${DESIGN_NAME}_drc_final.rpt

set final_drc [dbGet top.markers.numMarkers]
puts "INFO: Final DRC violations: $final_drc"

################################################################################
# STEP 12: RC Extraction
################################################################################
puts "\n=========================================================================="
puts "STEP 12: RC Extraction"
puts "=========================================================================="

extract_rc

################################################################################
# STEP 13: Final Timing Analysis
################################################################################
puts "\n=========================================================================="
puts "STEP 13: Final Timing Analysis"
puts "=========================================================================="

puts "INFO: Running final timing analysis..."

# Update timing
setAnalysisMode -analysisType onChipVariation
timeDesign -postRoute -pathReports -drvReports -slackReports \
    -numPaths 100 -prefix final_route -outDir ${REPORTS_DIR}/route

# Get timing metrics
set setup_wns [get_db timing_analysis_type:late slack -max]
set setup_tns [get_db timing_analysis_type:late slack -sum]
set hold_wns [get_db timing_analysis_type:early slack -max]
set hold_tns [get_db timing_analysis_type:early slack -sum]

puts "\n=========================================================================="
puts "                    FINAL TIMING RESULTS"
puts "=========================================================================="
puts "Setup WNS: $setup_wns"
puts "Setup TNS: $setup_tns"
puts "Hold WNS:  $hold_wns"
puts "Hold TNS:  $hold_tns"
puts "=========================================================================="

################################################################################
# STEP 14: Generate Reports
################################################################################
puts "\n=========================================================================="
puts "STEP 14: Generating Final Reports"
puts "=========================================================================="

generate_route_reports

# QoR report
if {$GENERATE_QOR_REPORT} {
    report_qor > ${REPORTS_DIR}/route/${DESIGN_NAME}_qor.rpt
}

################################################################################
# STEP 15: Save Final Database
################################################################################
puts "\n=========================================================================="
puts "STEP 15: Saving Final Database"
puts "=========================================================================="

saveDesign ${RESULTS_DIR}/route/${DESIGN_NAME}_route.enc
puts "INFO: Final database saved: ${RESULTS_DIR}/route/${DESIGN_NAME}_route.enc"

################################################################################
# STEP 16: Export Outputs
################################################################################
puts "\n=========================================================================="
puts "STEP 16: Exporting Outputs"
puts "=========================================================================="

if {$EXPORT_DEF} {
    defOut -floorplan -netlist -routing \
        ${RESULTS_DIR}/route/${DESIGN_NAME}_route.def
    puts "INFO: DEF exported."
}

if {$EXPORT_NETLIST} {
    saveNetlist ${RESULTS_DIR}/route/${DESIGN_NAME}_route.v
    puts "INFO: Verilog netlist exported."
}

if {$EXPORT_SDF} {
    write_sdf -version 3.0 ${RESULTS_DIR}/route/${DESIGN_NAME}_route.sdf
    puts "INFO: SDF exported."
}

if {$EXPORT_SPEF} {
    rcOut -spef ${RESULTS_DIR}/route/${DESIGN_NAME}_route.spef
    puts "INFO: SPEF exported."
}

if {$EXPORT_GDS} {
    # GDS export would require technology-specific stream out commands
    puts "INFO: GDS export requires technology-specific configuration."
}

################################################################################
# Completion Summary
################################################################################
set script_end_time [clock seconds]
set total_runtime [expr $script_end_time - $script_start_time]

# Collect all final metrics
set total_area [dbGet top.fPlan.area]
set core_area [dbGet top.fPlan.coreBox_area]
set std_cell_area [dbGet [dbGet top.insts.cell.baseClass core -p2].area -sum]
set utilization [expr ($std_cell_area / $core_area) * 100.0]

set internal_power [dbGet top.internalPower]
set switching_power [dbGet top.switchingPower]
set leakage_power [dbGet top.leakagePower]
set total_power [expr $internal_power + $switching_power + $leakage_power]

set total_wire_length [dbGet top.numWires]
set num_vias [dbGet top.numVias]
set total_overflow [dbGet top.fPlan.overflows]

set num_std_cells [llength [dbGet top.insts.cell.baseClass core -p]]
set num_macros [llength [dbGet top.insts.cell.baseClass block -p]]

set setup_viol [llength [get_db timing_analysis_type:late paths -if {.slack<0}]]
set hold_viol [llength [get_db timing_analysis_type:early paths -if {.slack<0}]]

# Calculate metal utilization average
set total_util 0.0
set layer_count 0
for {set layer $ROUTING_LAYER_MIN} {$layer <= $ROUTING_LAYER_MAX} {incr layer} {
    set layer_name "M$layer"
    set total_tracks [dbGet [dbGet head.layers.name $layer_name -p].numTracks]
    set used_tracks [dbGet [dbGet head.layers.name $layer_name -p].numUsedTracks]
    if {$total_tracks > 0} {
        set total_util [expr $total_util + (($used_tracks * 100.0) / $total_tracks)]
        incr layer_count
    }
}
set avg_metal_util [expr $total_util / $layer_count]

puts "\n=========================================================================="
puts "                    ROUTING STAGE - COMPLETED"
puts "=========================================================================="
puts "Total Runtime: [expr $total_runtime / 60] minutes [expr $total_runtime % 60] seconds"
puts "=========================================================================="

puts "\n+----------------------------------------------------------------------+"
puts "|                        FINAL DESIGN METRICS                          |"
puts "+----------------------------------------------------------------------+"

puts "\n--- TIMING METRICS ---"
puts [format "  Setup WNS:              %10.3f ns    (%s)" $setup_wns [expr {$setup_wns >= 0 ? "PASS" : "FAIL"}]]
puts [format "  Setup TNS:              %10.3f ns" $setup_tns]
puts [format "  Setup Violations:       %10d paths" $setup_viol]
puts [format "  Hold WNS:               %10.3f ns    (%s)" $hold_wns [expr {$hold_wns >= 0 ? "PASS" : "FAIL"}]]
puts [format "  Hold TNS:               %10.3f ns" $hold_tns]
puts [format "  Hold Violations:        %10d paths" $hold_viol]

puts "\n--- DRC/PDV METRICS ---"
puts [format "  Total DRC Violations:   %10d         (%s)" $final_drc [expr {$final_drc == 0 ? "CLEAN" : "VIOLATIONS"}]]
puts [format "  Opens:                  %10d" $opens]
puts [format "  Shorts:                 %10d" $shorts]

puts "\n--- AREA METRICS ---"
puts [format "  Die Area:               %10.2f um^2" $total_area]
puts [format "  Core Area:              %10.2f um^2" $core_area]
puts [format "  Std Cell Area:          %10.2f um^2" $std_cell_area]
puts [format "  Core Utilization:       %10.2f %%" $utilization]
puts [format "  Instance Count:         %10d cells" $num_std_cells]
puts [format "  Macro Count:            %10d blocks" $num_macros]

puts "\n--- POWER METRICS ---"
puts [format "  Total Power:            %10.3f mW" [expr $total_power * 1000]]
puts [format "  Internal Power:         %10.3f mW    (%.1f%%)" [expr $internal_power * 1000] [expr ($internal_power/$total_power)*100]]
puts [format "  Switching Power:        %10.3f mW    (%.1f%%)" [expr $switching_power * 1000] [expr ($switching_power/$total_power)*100]]
puts [format "  Leakage Power:          %10.3f mW    (%.1f%%)" [expr $leakage_power * 1000] [expr ($leakage_power/$total_power)*100]]
puts [format "  Power Density:          %10.3f mW/mm^2" [expr ($total_power * 1000) / ($core_area / 1000000)]]

puts "\n--- ROUTING METRICS ---"
puts [format "  Total Wire Length:      %10d um" $total_wire_length]
puts [format "  Total Vias:             %10d" $num_vias]
puts [format "  Avg Vias/Cell:          %10.2f" [expr double($num_vias) / $num_std_cells]]
puts [format "  Wire Density:           %10.2f um/um^2" [expr double($total_wire_length) / $core_area]]

puts "\n--- METAL UTILIZATION (M${ROUTING_LAYER_MIN}-M${ROUTING_LAYER_MAX}) ---"
for {set layer $ROUTING_LAYER_MIN} {$layer <= $ROUTING_LAYER_MAX} {incr layer} {
    set layer_name "M$layer"
    set total_tracks [dbGet [dbGet head.layers.name $layer_name -p].numTracks]
    set used_tracks [dbGet [dbGet head.layers.name $layer_name -p].numUsedTracks]
    if {$total_tracks > 0} {
        set util [expr ($used_tracks * 100.0) / $total_tracks]
        set bar_len [expr int($util / 5)]
        set bar [string repeat "#" $bar_len][string repeat "." [expr 20 - $bar_len]]
        puts [format "  %-6s %6.2f%%  |%s|" $layer_name $util $bar]
    }
}
puts [format "  Average:                %10.2f %%" $avg_metal_util]

puts "\n--- TRACK UTILIZATION ---"
set total_h_util 0.0
set total_v_util 0.0
set track_layers 0
for {set layer $ROUTING_LAYER_MIN} {$layer <= $ROUTING_LAYER_MAX} {incr layer} {
    set layer_name "M$layer"
    set h_used [dbGet [dbGet head.layers.name $layer_name -p].numUsedHorizontalTracks]
    set h_total [dbGet [dbGet head.layers.name $layer_name -p].numHorizontalTracks]
    set v_used [dbGet [dbGet head.layers.name $layer_name -p].numUsedVerticalTracks]
    set v_total [dbGet [dbGet head.layers.name $layer_name -p].numVerticalTracks]
    
    if {$h_total > 0} {
        set h_util [expr ($h_used * 100.0) / $h_total]
        set total_h_util [expr $total_h_util + $h_util]
    } else {
        set h_util 0.0
    }
    
    if {$v_total > 0} {
        set v_util [expr ($v_used * 100.0) / $v_total]
        set total_v_util [expr $total_v_util + $v_util]
    } else {
        set v_util 0.0
    }
    
    incr track_layers
    puts [format "  %-6s H:%6.2f%%  V:%6.2f%%" $layer_name $h_util $v_util]
}
puts [format "  Average:   H:%6.2f%%  V:%6.2f%%" [expr $total_h_util/$track_layers] [expr $total_v_util/$track_layers]]

puts "\n--- CONGESTION METRICS ---"
puts [format "  Total Overflow:         %10d         (%s)" $total_overflow [expr {$total_overflow == 0 ? "NONE" : $total_overflow < 100 ? "LOW" : $total_overflow < 1000 ? "MODERATE" : "HIGH"}]]
puts [format "  Max H Overflow:         %10d" [dbGet top.fPlan.maxHorizontalOverflow]]
puts [format "  Max V Overflow:         %10d" [dbGet top.fPlan.maxVerticalOverflow]]

puts "\n+----------------------------------------------------------------------+"
puts "|                         DESIGN STATUS                                |"
puts "+----------------------------------------------------------------------+"

set status_clean true
set status_msg ""

if {$setup_wns < 0 || $hold_wns < 0} {
    set status_clean false
    set status_msg "${status_msg}\n  [!] TIMING VIOLATIONS DETECTED"
}

if {$final_drc > 0} {
    set status_clean false
    set status_msg "${status_msg}\n  [!] DRC VIOLATIONS DETECTED"
}

if {$opens > 0 || $shorts > 0} {
    set status_clean false
    set status_msg "${status_msg}\n  [!] CONNECTIVITY ISSUES DETECTED"
}

if {$total_overflow > 1000} {
    set status_clean false
    set status_msg "${status_msg}\n  [!] HIGH CONGESTION DETECTED"
}

if {$status_clean} {
    puts "\n              *** SUCCESS: DESIGN IS CLEAN AND READY! ***"
    puts "  - All timing constraints met"
    puts "  - No DRC violations"
    puts "  - No connectivity issues"
    puts "  - Routing congestion acceptable"
} else {
    puts "\n              *** WARNING: DESIGN NEEDS ATTENTION! ***"
    puts $status_msg
}

puts "\n+----------------------------------------------------------------------+"
puts "Detailed reports available in: ${REPORTS_DIR}/route/"
puts "  - ${DESIGN_NAME}_route_QoR_summary.rpt     (Master Summary)"
puts "  - ${DESIGN_NAME}_route_timing_*.rpt        (Timing Analysis)"
puts "  - ${DESIGN_NAME}_route_drc_detailed.rpt    (DRC Details)"
puts "  - ${DESIGN_NAME}_route_power_summary.rpt   (Power Analysis)"
puts "  - ${DESIGN_NAME}_route_metal_util.rpt      (Metal Usage)"
puts "  - ${DESIGN_NAME}_route_congestion_*.rpt    (Congestion Analysis)"
puts "+----------------------------------------------------------------------+"
puts "=========================================================================="

if {$status_clean} {
    exit 0
} else {
    exit 1
}

################################################################################
# End of route_main.tcl
################################################################################
