################################################################################
# Complete RTL Synthesis Script with DFT
# Tool: Design Compiler (Synopsys)
################################################################################

# Set design name
set DESIGN_NAME "top_module"
set RTL_PATH "./rtl"
set REPORTS_DIR "./reports"
set RESULTS_DIR "./results"

# Create directories
file mkdir $REPORTS_DIR
file mkdir $RESULTS_DIR

################################################################################
# 1. LIBRARY SETUP
################################################################################
set search_path [list . \
                      /path/to/std_cell_lib \
                      /path/to/memory_lib \
                      $RTL_PATH]

set target_library "typical.db"
set link_library "* $target_library dw_foundation.sldb"
set symbol_library "generic.sdb"

# Set synthetic library for DesignWare
set synthetic_library [list dw_foundation.sldb]

################################################################################
# 2. READ RTL FILES
################################################################################
# Analyze RTL files
analyze -format verilog [list \
    $RTL_PATH/top_module.v \
    $RTL_PATH/sub_module1.v \
    $RTL_PATH/sub_module2.v \
]

# Or analyze SystemVerilog
# analyze -format sverilog [glob $RTL_PATH/*.sv]

# Elaborate the design
elaborate $DESIGN_NAME -parameters "WIDTH=32,DEPTH=1024"

# Set current design
current_design $DESIGN_NAME

# Link the design
link

################################################################################
# 3. DESIGN CONSTRAINTS
################################################################################
# Clock definition
set CLK_PERIOD 10.0
set CLK_PORT "clk"
set RST_PORT "rst_n"

create_clock -name CLK -period $CLK_PERIOD [get_ports $CLK_PORT]
set_clock_uncertainty 0.2 [get_clocks CLK]
set_clock_transition 0.1 [get_clocks CLK]
set_clock_latency -source 0.5 [get_clocks CLK]
set_clock_latency 0.3 [get_clocks CLK]

# Input/Output delays
set_input_delay -clock CLK -max 2.0 [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set_input_delay -clock CLK -min 0.5 [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
set_output_delay -clock CLK -max 2.0 [all_outputs]
set_output_delay -clock CLK -min 0.5 [all_outputs]

# Drive strength
set_driving_cell -lib_cell BUFX4 -library typical [all_inputs]
set_drive 0 [get_ports $CLK_PORT]

# Load
set_load 0.05 [all_outputs]

# Operating conditions
set_operating_conditions -max typical -max_library typical

# Wire load model
set_wire_load_model -name "suggested" -library typical

# Reset constraints
set_ideal_network [get_ports $RST_PORT]
set_dont_touch_network [get_ports $RST_PORT]

# False paths and multicycle paths
set_false_path -from [get_ports $RST_PORT]
# set_multicycle_path -setup 2 -from [get_pins reg1/Q] -to [get_pins reg2/D]

################################################################################
# 4. DFT SETUP AND CONFIGURATION
################################################################################
# Set DFT signal names
set_dft_signal -view existing_dft -type ScanClock -port $CLK_PORT -timing {45 55}
set_dft_signal -view existing_dft -type Reset -port $RST_PORT -active_state 0

# Define scan ports
set_dft_signal -view spec -type ScanDataIn -port scan_in
set_dft_signal -view spec -type ScanDataOut -port scan_out
set_dft_signal -view spec -type ScanEnable -port scan_en -active_state 1

# DFT configuration
set_scan_configuration -chain_count 4
set_scan_configuration -clock_mixing mix_clocks
set_scan_configuration -style multiplexed_flip_flop
set_scan_configuration -max_length 500

# Set scan path
set_dft_insertion_configuration -synthesis_optimization full
set_dft_insertion_configuration -preserve_design_name true

# Specify non-scan cells (if any)
# set_dont_touch [get_cells async_reg*]

# Create test protocol
create_test_protocol -infer_clock -infer_asynch

################################################################################
# 5. PRE-DFT CHECKS
################################################################################
# Check design for DFT readiness
report_dft_signal -view existing_dft > $REPORTS_DIR/dft_signals_pre.rpt
check_dft_rules > $REPORTS_DIR/dft_rules_check.rpt
dft_drc -verbose > $REPORTS_DIR/dft_drc_pre.rpt

################################################################################
# 6. GENERIC SYNTHESIS (Technology Independent)
################################################################################
echo "Starting Generic Synthesis..."

# Set compile options
set_app_var compile_ultra_ungroup_dw false
set_app_var hdlin_check_no_latch true
set_app_var compile_seqmap_propagate_constants false
set_app_var compile_delete_unloaded_sequential_cells false
set_app_var hdlin_enable_presto_for_vhdl true

# Compile strategy
set_compile_directives -gate_clock false
set_compile_directives -retime false

# Uniquify design
uniquify

# Generic synthesis - Boolean optimization, structuring, flattening
compile -map_effort medium -area_effort medium -no_design_rule

# Report after generic synthesis
report_area > $REPORTS_DIR/area_generic.rpt
report_timing -max_paths 5 > $REPORTS_DIR/timing_generic.rpt
report_qor > $REPORTS_DIR/qor_generic.rpt

################################################################################
# 7. TECHNOLOGY MAPPING
################################################################################
echo "Starting Technology Mapping..."

# Enable DFT during mapping
set_scan_configuration -add_lockup true

# Technology mapping with scan
# Map generic gates to technology library cells
compile_ultra -scan -gate_clock -no_autoungroup

# Report after mapping
report_area > $REPORTS_DIR/area_mapped.rpt
report_timing -max_paths 10 > $REPORTS_DIR/timing_mapped.rpt
report_qor > $REPORTS_DIR/qor_mapped.rpt
report_resources > $REPORTS_DIR/resources_mapped.rpt

################################################################################
# 8. DFT INSERTION
################################################################################
echo "Inserting DFT structures..."

# Preview DFT insertion
preview_dft -show all > $REPORTS_DIR/dft_preview.rpt

# Insert scan chains
insert_dft

# Post-DFT DRC
dft_drc -verbose -coverage_estimate > $REPORTS_DIR/dft_drc_post.rpt

# Report scan chains
report_scan_path -view existing_dft -chain all > $REPORTS_DIR/scan_chains_inserted.rpt

################################################################################
# 9. INCREMENTAL OPTIMIZATION
################################################################################
echo "Starting Incremental Optimization..."

# First incremental pass - optimize timing and area
compile_ultra -scan -incremental -no_autoungroup

report_qor > $REPORTS_DIR/qor_incr1.rpt
report_timing > $REPORTS_DIR/timing_incr1.rpt

# Second incremental pass - focus on design rules
compile_ultra -scan -incremental -only_design_rule

report_qor > $REPORTS_DIR/qor_incr2.rpt

# Third incremental pass - fine-tune area
compile_ultra -scan -incremental -area_high_effort_script

report_qor > $REPORTS_DIR/qor_incr3.rpt
report_area > $REPORTS_DIR/area_final.rpt

# Optional: Fourth pass for power optimization
# compile_ultra -scan -incremental -gate_clock -self_gating

################################################################################
# 10. OPTIMIZATION WITH SPECIFIC FOCUS
################################################################################
echo "Running focused optimizations..."

# Optimize critical paths
group_path -name CRITICAL -critical_range 0.5
compile_ultra -scan -incremental -only_hold_time

# Optimize for congestion (if needed)
# set_app_var compile_prefer_mux true
# compile_ultra -scan -incremental -congestion

# High effort compile for remaining violations
if {[sizeof_collection [get_timing_paths -slack_lesser_than 0 -max_paths 1]] > 0} {
    echo "Timing violations detected, running high-effort optimization..."
    compile_ultra -scan -incremental -timing_high_effort_script
}

################################################################################
# 11. FINAL REPORTS - Area, Timing, Power, DFT
################################################################################
echo "Generating final reports..."
# Timing reports
report_timing -transition_time -nets -attributes -nosplit > $REPORTS_DIR/timing.rpt
report_timing -delay min -max_paths 10 > $REPORTS_DIR/timing_min.rpt
report_constraint -all_violators > $REPORTS_DIR/constraints.rpt
report_clock -skew -attributes > $REPORTS_DIR/clock.rpt

# Area reports
report_area -hierarchy > $REPORTS_DIR/area.rpt
report_resources -hierarchy > $REPORTS_DIR/resources.rpt
report_cell [get_cells -hierarchical *] > $REPORTS_DIR/cells.rpt

# Power reports
report_power -analysis_effort high > $REPORTS_DIR/power.rpt
report_power -hierarchy > $REPORTS_DIR/power_hierarchy.rpt

# DFT reports
report_dft_signal -view existing_dft > $REPORTS_DIR/dft_signals.rpt
report_scan_path -view existing_dft -chain all > $REPORTS_DIR/scan_paths.rpt
report_scan_path -view existing_dft -cell all > $REPORTS_DIR/scan_cells.rpt
dft_drc -verbose -coverage_estimate > $REPORTS_DIR/dft_coverage.rpt

# QoR summary
report_qor > $REPORTS_DIR/qor.rpt
report_qor -summary > $REPORTS_DIR/qor_summary.rpt

################################################################################
# 12. WRITE OUT RESULTS
################################################################################
echo "Writing output files..."
# Write netlist
write -format verilog -hierarchy -output $RESULTS_DIR/${DESIGN_NAME}_netlist.v
write -format ddc -hierarchy -output $RESULTS_DIR/${DESIGN_NAME}.ddc

# Write SDC constraints
write_sdc -nosplit $RESULTS_DIR/${DESIGN_NAME}.sdc

# Write scan DEF
write_scan_def -output $RESULTS_DIR/${DESIGN_NAME}_scan.def

# Write test protocol
write_test_protocol -output $RESULTS_DIR/${DESIGN_NAME}.spf

# Write STIL patterns (optional)
# write_test -format stil -output $RESULTS_DIR/${DESIGN_NAME}.stil

################################################################################
# 13. FINAL CHECKS
################################################################################
echo "Running final verification checks..."
check_design > $REPORTS_DIR/check_design.rpt
check_timing > $REPORTS_DIR/check_timing.rpt

# Verify scan chains
dft_drc -verbose -coverage_estimate > $REPORTS_DIR/dft_final_check.rpt

################################################################################
# COMPLETION MESSAGE
################################################################################
echo "=========================================="
echo "Synthesis completed successfully!"
echo "Reports directory: $REPORTS_DIR"
echo "Results directory: $RESULTS_DIR"
echo "=========================================="

# Exit
# quit
