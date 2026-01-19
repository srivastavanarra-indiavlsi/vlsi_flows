################################################################################
# Main RTL Synthesis Script with DFT
# Tool: Design Compiler (Synopsys)
################################################################################

################################################################################
# 1. SOURCE SETUP FILES
################################################################################
source scripts/synth_setup.tcl      ;# Load synthesis variables and settings
source scripts/constraints.tcl      ;# Load timing constraints definitions
source scripts/dft_setup.tcl        ;# Load DFT configuration and scan setup

################################################################################
# 2. LIBRARY SETUP
################################################################################
set search_path [list . $STD_CELL_LIB_PATH $MEMORY_LIB_PATH $RTL_PATH]  ;# Define library search paths
set target_library $TARGET_LIBS                                          ;# Set target technology library
set link_library "* $TARGET_LIBS dw_foundation.sldb"                     ;# Set libraries for linking (includes DesignWare)
set symbol_library $SYMBOL_LIBS                                          ;# Set symbol library for schematic generation
set synthetic_library [list dw_foundation.sldb]                          ;# Set DesignWare synthetic library for operators

################################################################################
# 3. READ RTL FILES
################################################################################
echo "=========================================="
echo "Reading RTL files..."
echo "=========================================="

if {$RTL_FORMAT == "verilog"} {
    analyze -format verilog $RTL_FILES      ;# Parse Verilog files and check syntax
} elseif {$RTL_FORMAT == "sverilog"} {
    analyze -format sverilog $RTL_FILES     ;# Parse SystemVerilog files and check syntax
} elseif {$RTL_FORMAT == "vhdl"} {
    analyze -format vhdl $RTL_FILES         ;# Parse VHDL files and check syntax
}

if {[info exists DESIGN_PARAMETERS]} {
    elaborate $DESIGN_NAME -parameters $DESIGN_PARAMETERS  ;# Build design hierarchy with parameters
} else {
    elaborate $DESIGN_NAME                                 ;# Build design hierarchy without parameters
}

current_design $DESIGN_NAME             ;# Set the top-level design as current
link                                    ;# Resolve design references and link all modules
check_design > $REPORTS_DIR/check_design_pre.rpt  ;# Check for design issues (unmapped cells, multi-driven nets, etc.)

################################################################################
# 4. APPLY DESIGN CONSTRAINTS
################################################################################
echo "=========================================="
echo "Applying design constraints..."
echo "=========================================="

apply_constraints                       ;# Apply all timing constraints (clocks, I/O delays, false paths, etc.)
report_constraint -all_violators > $REPORTS_DIR/constraints_applied.rpt  ;# Report all constraint violations
report_clock > $REPORTS_DIR/clocks.rpt                                    ;# Report clock definitions and properties

################################################################################
# 5. PRE-DFT CHECKS
################################################################################
echo "=========================================="
echo "Running pre-DFT checks..."
echo "=========================================="

report_dft_signal -view existing_dft > $REPORTS_DIR/dft_signals_pre.rpt  ;# Report existing DFT signals before insertion
check_dft_rules > $REPORTS_DIR/dft_rules_check.rpt                       ;# Check if design meets DFT rules
dft_drc -verbose > $REPORTS_DIR/dft_drc_pre.rpt                          ;# Run DFT design rule check before scan insertion

################################################################################
# 6. GENERIC SYNTHESIS (Technology Independent)
################################################################################
echo "=========================================="
echo "Starting Generic Synthesis..."
echo "=========================================="

uniquify                                ;# Make all module instances unique (breaks hierarchy sharing)
check_timing > $REPORTS_DIR/check_timing_pre.rpt  ;# Check timing setup (clocks, I/O constraints, etc.)

compile -map_effort $GENERIC_MAP_EFFORT \         ;# Technology-independent Boolean optimization
        -area_effort $GENERIC_AREA_EFFORT \       ;# Control area optimization effort
        -no_design_rule                           ;# Skip design rule fixing (capacitance, transition, fanout)

report_area > $REPORTS_DIR/area_generic.rpt                  ;# Report area after generic synthesis
report_timing -max_paths 5 > $REPORTS_DIR/timing_generic.rpt ;# Report top 5 critical timing paths
report_qor > $REPORTS_DIR/qor_generic.rpt                    ;# Report Quality of Results (timing, area, DRVs)
report_resources > $REPORTS_DIR/resources_generic.rpt        ;# Report inferred resources (adders, muxes, registers)

################################################################################
# 7. TECHNOLOGY MAPPING
################################################################################
echo "=========================================="
echo "Starting Technology Mapping..."
echo "=========================================="

if {$ENABLE_SCAN == 1} {
    compile_ultra -scan \               ;# Map to technology cells with scan insertion capability
                  -gate_clock \         ;# Insert clock gating cells for power saving
                  -no_autoungroup \     ;# Preserve hierarchy (don't flatten automatically)
                  -no_seq_output_inversion \  ;# Don't invert sequential outputs
                  -retime               ;# Enable register retiming for better timing
} else {
    compile_ultra -gate_clock \         ;# Map to technology cells without scan
                  -no_autoungroup \     ;# Preserve hierarchy
                  -retime               ;# Enable register retiming
}
### We can write reports proc and call it when ever needed ##### Reports proc - synth/place/route/timing
report_area > $REPORTS_DIR/area_mapped.rpt                           ;# Report area after technology mapping
report_timing -max_paths 10 > $REPORTS_DIR/timing_mapped.rpt         ;# Report top 10 timing paths
report_timing -delay min -max_paths 5 > $REPORTS_DIR/timing_mapped_min.rpt  ;# Report hold time paths
report_qor > $REPORTS_DIR/qor_mapped.rpt                             ;# Report QoR after mapping
report_resources > $REPORTS_DIR/resources_mapped.rpt                 ;# Report mapped resources
report_power > $REPORTS_DIR/power_mapped.rpt                         ;# Report power consumption

################################################################################
# 8. DFT INSERTION
################################################################################
if {$ENABLE_SCAN == 1} {
    echo "=========================================="
    echo "Inserting DFT structures..."
    echo "=========================================="
    
    preview_dft -show all > $REPORTS_DIR/dft_preview.rpt            ;# Preview what will be inserted (scan chains, test points)
    insert_dft                                                       ;# Insert scan chains (convert FFs to scan FFs)
    dft_drc -verbose -coverage_estimate > $REPORTS_DIR/dft_drc_post.rpt  ;# Check DFT rules and estimate fault coverage
    report_scan_path -view existing_dft -chain all > $REPORTS_DIR/scan_chains_inserted.rpt  ;# Report all scan chains
    report_dft_signal -view existing_dft > $REPORTS_DIR/dft_signals_post.rpt  ;# Report DFT signals after insertion
}

################################################################################
# 9. INCREMENTAL OPTIMIZATION
################################################################################
echo "=========================================="
echo "Starting Incremental Optimization..."
echo "=========================================="

# PASS 1: General timing and area optimization
if {$ENABLE_SCAN == 1} {
    compile_ultra -scan -incremental -no_autoungroup  ;# Incremental compile to fix timing/area (preserves existing netlist)
} else {
    compile_ultra -incremental -no_autoungroup        ;# Incremental compile without scan
}

report_qor > $REPORTS_DIR/qor_incr1.rpt                          ;# Report QoR after first incremental pass
report_timing -max_paths 10 > $REPORTS_DIR/timing_incr1.rpt      ;# Report timing after first pass
report_area > $REPORTS_DIR/area_incr1.rpt                        ;# Report area after first pass

# PASS 2: Design rule violation fixing
if {$ENABLE_DESIGN_RULE_OPT == 1} {
    echo "Running design rule optimization..."
    if {$ENABLE_SCAN == 1} {
        compile_ultra -scan -incremental -only_design_rule  ;# Fix max_transition, max_capacitance, max_fanout violations
    } else {
        compile_ultra -incremental -only_design_rule        ;# Fix design rule violations only
    }
    report_qor > $REPORTS_DIR/qor_incr2.rpt                 ;# Report QoR after DRV fixing
}

# PASS 3: Area recovery optimization
if {$ENABLE_AREA_RECOVERY == 1} {
    echo "Running area recovery optimization..."
    if {$ENABLE_SCAN == 1} {
        compile_ultra -scan -incremental -area_high_effort_script  ;# Aggressive area optimization (downsizing cells)
    } else {
        compile_ultra -incremental -area_high_effort_script        ;# Aggressive area recovery
    }
    report_qor > $REPORTS_DIR/qor_incr3.rpt                        ;# Report QoR after area recovery
    report_area > $REPORTS_DIR/area_incr3.rpt                      ;# Report final area
}

################################################################################
# 10. OPTIMIZATION WITH SPECIFIC FOCUS
################################################################################
echo "=========================================="
echo "Running focused optimizations..."
echo "=========================================="

group_path -name CRITICAL -critical_range $CRITICAL_RANGE  ;# Create path group for critical paths (WNS to WNS+range)

# Hold time fixing
if {$ENABLE_HOLD_FIX == 1} {
    echo "Fixing hold time violations..."
    if {$ENABLE_SCAN == 1} {
        compile_ultra -scan -incremental -only_hold_time  ;# Insert buffers/delay cells to fix hold violations
    } else {
        compile_ultra -incremental -only_hold_time        ;# Fix hold time only
    }
    report_timing -delay min > $REPORTS_DIR/timing_hold_fixed.rpt  ;# Report hold timing after fixing
}

# High effort timing optimization if violations remain
set timing_viol [sizeof_collection [get_timing_paths -slack_lesser_than 0 -max_paths 1]]  ;# Count setup violations
if {$timing_viol > 0} {
    echo "Timing violations detected: $timing_viol paths"
    echo "Running high-effort optimization..."
    if {$ENABLE_SCAN == 1} {
        compile_ultra -scan -incremental -timing_high_effort_script  ;# Aggressive timing optimization (restructuring, upsizing)
    } else {
        compile_ultra -incremental -timing_high_effort_script        ;# High-effort timing fix
    }
    report_timing -max_paths 20 > $REPORTS_DIR/timing_high_effort.rpt  ;# Report timing after aggressive optimization
}

# Power optimization
if {$ENABLE_POWER_OPT == 1} {
    echo "Running power optimization..."
    if {$ENABLE_SCAN == 1} {
        compile_ultra -scan -incremental -gate_clock  ;# Optimize clock gating for power reduction
    } else {
        compile_ultra -incremental -gate_clock        ;# Power optimization without scan
    }
    report_power -analysis_effort high > $REPORTS_DIR/power_optimized.rpt  ;# Report power after optimization
}

################################################################################
# 11. FINAL REPORTS
################################################################################
echo "=========================================="
echo "Generating final reports..."
echo "=========================================="

# Timing reports
report_timing -transition_time -nets -attributes -nosplit > $REPORTS_DIR/timing_final.rpt  ;# Detailed timing with transitions and net delays
report_timing -delay min -max_paths 10 > $REPORTS_DIR/timing_min_final.rpt                 ;# Hold time paths report
report_timing -max_paths 100 -slack_lesser_than 0 > $REPORTS_DIR/timing_violations.rpt     ;# All setup violations
report_constraint -all_violators -verbose > $REPORTS_DIR/constraints_final.rpt              ;# All constraint violations
report_clock -skew -attributes > $REPORTS_DIR/clock_final.rpt                               ;# Clock skew and attributes

# Area reports
report_area -hierarchy > $REPORTS_DIR/area_final.rpt                    ;# Hierarchical area breakdown
report_area -designware > $REPORTS_DIR/area_designware.rpt              ;# Area of DesignWare components
report_resources -hierarchy > $REPORTS_DIR/resources_final.rpt          ;# Resources by hierarchy
report_cell [get_cells -hierarchical *] > $REPORTS_DIR/cells_final.rpt  ;# All cell instances
report_reference -hierarchy > $REPORTS_DIR/reference.rpt                ;# Reference count of each cell type

# Power reports
report_power -analysis_effort high -verbose > $REPORTS_DIR/power_final.rpt  ;# Detailed power analysis (dynamic + leakage)
report_power -hierarchy > $REPORTS_DIR/power_hierarchy.rpt                  ;# Hierarchical power breakdown

# QoR reports
report_qor > $REPORTS_DIR/qor_final.rpt          ;# Final Quality of Results
report_qor -summary > $REPORTS_DIR/qor_summary.rpt  ;# QoR summary table

# DFT reports
if {$ENABLE_SCAN == 1} {
    report_dft_signal -view existing_dft > $REPORTS_DIR/dft_signals_final.rpt          ;# Final DFT signal definitions
    report_scan_path -view existing_dft -chain all > $REPORTS_DIR/scan_paths_final.rpt ;# Scan chain structure
    report_scan_path -view existing_dft -cell all > $REPORTS_DIR/scan_cells_final.rpt  ;# All scan cells
    dft_drc -verbose -coverage_estimate > $REPORTS_DIR/dft_coverage_final.rpt          ;# Fault coverage estimate
}

################################################################################
# 12. WRITE OUT RESULTS
################################################################################
echo "=========================================="
echo "Writing output files..."
echo "=========================================="

write -format verilog -hierarchy -output $RESULTS_DIR/${DESIGN_NAME}_netlist.v  ;# Write gate-level Verilog netlist
write -format ddc -hierarchy -output $RESULTS_DIR/${DESIGN_NAME}.ddc            ;# Write Design Compiler database
write_sdc -nosplit $RESULTS_DIR/${DESIGN_NAME}.sdc                              ;# Write timing constraints in SDC format
write_parasitics -output $RESULTS_DIR/${DESIGN_NAME}.spef                       ;# Write parasitics (for back-annotation)

if {$ENABLE_SCAN == 1} {
    write_scan_def -output $RESULTS_DIR/${DESIGN_NAME}_scan.def        ;# Write scan chain DEF for P&R
    write_test_protocol -output $RESULTS_DIR/${DESIGN_NAME}.spf        ;# Write test protocol (STIL Procedure File)
    # write_test -format stil -output $RESULTS_DIR/${DESIGN_NAME}.stil ;# Write ATPG patterns in STIL format
}

################################################################################
# 13. FINAL CHECKS
################################################################################
echo "=========================================="
echo "Running final verification checks..."
echo "=========================================="

check_design > $REPORTS_DIR/check_design_final.rpt  ;# Final design integrity check
check_timing > $REPORTS_DIR/check_timing_final.rpt  ;# Final timing setup verification

if {$ENABLE_SCAN == 1} {
    dft_drc -verbose -coverage_estimate > $REPORTS_DIR/dft_final_check.rpt  ;# Final DFT verification and coverage
}

################################################################################
# COMPLETION MESSAGE
################################################################################
echo "=========================================="
echo "Synthesis completed successfully!"
echo "Design: $DESIGN_NAME"
echo "Reports directory: $REPORTS_DIR"
echo "Results directory: $RESULTS_DIR"
echo "=========================================="

report_qor -summary  ;# Print final QoR summary to console

# Exit
# quit
