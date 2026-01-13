################################################################################
# Synthesis Setup Variables
# File: scripts/synth_setup.tcl
################################################################################

################################################################################
# DESIGN CONFIGURATION
################################################################################
set DESIGN_NAME "top_module"       ;# Top-level module name
set RTL_FORMAT "verilog"           ;# RTL language: verilog, sverilog, or vhdl
set DESIGN_PARAMETERS ""           ;# Parameters for elaboration (e.g., "WIDTH=32,DEPTH=1024")

################################################################################
# PATH CONFIGURATION
################################################################################
set RTL_PATH "./rtl"               ;# Directory containing RTL source files
set REPORTS_DIR "./reports"        ;# Directory for output reports
set RESULTS_DIR "./results"        ;# Directory for synthesis results (netlist, constraints)
set SCRIPT_DIR "./scripts"         ;# Directory for TCL scripts

file mkdir $REPORTS_DIR            ;# Create reports directory if it doesn't exist
file mkdir $RESULTS_DIR            ;# Create results directory if it doesn't exist
file mkdir $SCRIPT_DIR             ;# Create scripts directory if it doesn't exist

################################################################################
# LIBRARY PATHS
################################################################################
set STD_CELL_LIB_PATH "/path/to/std_cell_lib"  ;# Path to standard cell library
set MEMORY_LIB_PATH "/path/to/memory_lib"      ;# Path to memory compiler libraries
set IO_LIB_PATH "/path/to/io_lib"              ;# Path to I/O pad libraries

################################################################################
# LIBRARY FILES
################################################################################
set TARGET_LIBS [list \
    "typical.db" \                 ;# Typical corner standard cell library
    "memory_typical.db" \          ;# Typical corner memory library
]

set SYMBOL_LIBS [list "generic.sdb"]  ;# Symbol library for schematic viewing

# Multi-corner library sets (optional for advanced timing analysis)
# set LINK_LIBS_TYPICAL "typical.db memory_typical.db"    ;# Typical PVT corner
# set LINK_LIBS_FAST "fast.db memory_fast.db"             ;# Fast corner (best case)
# set LINK_LIBS_SLOW "slow.db memory_slow.db"             ;# Slow corner (worst case)

################################################################################
# RTL FILE LIST
################################################################################
set RTL_FILES [list \
    $RTL_PATH/top_module.v \       ;# Top-level module
    $RTL_PATH/sub_module1.v \      ;# Sub-module 1
    $RTL_PATH/sub_module2.v \      ;# Sub-module 2
    $RTL_PATH/sub_module3.v \      ;# Sub-module 3
]

# Alternative: Automatically include all files from directory
# set RTL_FILES [glob $RTL_PATH/*.v]   ;# All Verilog files
# set RTL_FILES [glob $RTL_PATH/*.sv]  ;# All SystemVerilog files

################################################################################
# SYNTHESIS CONTROL VARIABLES
################################################################################
set GENERIC_MAP_EFFORT "medium"    ;# Mapping effort for generic synthesis: low, medium, high
set GENERIC_AREA_EFFORT "medium"   ;# Area optimization effort: low, medium, high

set ENABLE_DESIGN_RULE_OPT 1       ;# Enable design rule violation fixing (1=yes, 0=no)
set ENABLE_AREA_RECOVERY 1         ;# Enable area recovery after timing closure (1=yes, 0=no)
set ENABLE_HOLD_FIX 1              ;# Enable hold time violation fixing (1=yes, 0=no)
set ENABLE_POWER_OPT 0             ;# Enable power optimization (1=yes, 0=no)

set CRITICAL_RANGE 0.5             ;# Critical path range in ns for focused optimization

################################################################################
# COMPILE OPTIONS AND APP VARS
################################################################################
# General compile application variables
set_app_var compile_ultra_ungroup_dw false                         ;# Don't ungroup DesignWare components
set_app_var hdlin_check_no_latch true                              ;# Report warning if latches are inferred
set_app_var compile_seqmap_propagate_constants false               ;# Don't propagate constants through sequential logic
set_app_var compile_delete_unloaded_sequential_cells false         ;# Keep unloaded registers (may be for observability)
set_app_var hdlin_enable_presto_for_vhdl true                      ;# Enable PRESTO VHDL for better QoR
set_app_var compile_timing_high_effort true                        ;# Enable high-effort timing optimization
set_app_var compile_area_high_effort true                          ;# Enable high-effort area optimization

# Hierarchy and ungrouping
set_app_var compile_ultra_ungroup_small_hierarchies true           ;# Auto-ungroup small hierarchies for better optimization
set_app_var hdlin_infer_complex_set_reset true                     ;# Infer complex set/reset logic
set_app_var hdlin_auto_ungroup_area_limit 10000                    ;# Ungroup hierarchies smaller than 10K gates

# Boundary optimization
set_app_var compile_enable_constant_propagation_with_no_boundary_opt false  ;# Prevent constant propagation across boundaries

# Timing optimization
set_app_var timing_enable_multiple_clocks_per_reg true             ;# Allow multiple clocks per register (multi-mode)
set_app_var timing_all_clocks_propagated true                      ;# Propagate all clocks through design

# Wire load modeling
set_app_var auto_wire_load_selection true                          ;# Automatically select wire load model based on area

# Resource limits
set_app_var compile_cpu_limit 7200                                 ;# Maximum CPU time in seconds (2 hours)
set_host_options -max_cores 4                                      ;# Number of CPU cores for parallel processing

################################################################################
# COMPILE DIRECTIVES
################################################################################
set_compile_directives -gate_clock false   ;# Don't gate clocks during generic synthesis
set_compile_directives -retime false       ;# Don't retime during generic synthesis

################################################################################
# MULTI-VT OPTIMIZATION (Optional)
################################################################################
# Multi-threshold voltage optimization for power/performance tradeoff
# set_app_var compile_enable_multiple_vt_optimization true  ;# Enable multi-Vt cell usage
# set_multi_vt_constraint -type soft -threshold_percentage 20  ;# Use HVT cells for 20% of design

################################################################################
# OPERATING CONDITIONS
################################################################################
set OPERATING_CONDITION "typical"                          ;# Operating condition name from library
set_operating_conditions -max $OPERATING_CONDITION -max_library typical  ;# Set worst-case operating condition

################################################################################
# WIRE LOAD MODEL
################################################################################
set WIRE_LOAD_MODEL "suggested"                            ;# Wire load model name from library
set_wire_load_model -name $WIRE_LOAD_MODEL -library typical  ;# Apply wire load model for interconnect estimation

################################################################################
# VERIFICATION SETTINGS
################################################################################
set_app_var verification_verify_directly_unresolved_references false  ;# Don't verify unresolved references
set_app_var hdlin_hide_resource_line_numbers false                    ;# Show line numbers in resource sharing messages

################################################################################
# OPTIMIZATION PREFERENCES
################################################################################
# Structure and resource sharing preferences
# set_app_var compile_prefer_mux false                      ;# Don't prefer mux structures
# set_app_var hlo_share_common_subexpressions true          ;# Share common sub-expressions
# set_app_var compile_seqmap_identify_shift_registers true  ;# Identify and optimize shift registers

################################################################################
# INCREMENTAL COMPILE SETTINGS
################################################################################
set_app_var compile_timing_high_effort_tns true            ;# Focus on total negative slack in incremental
set_app_var compile_effort_limit normal                    ;# Compile effort limit: low, normal, high

################################################################################
# MESSAGE SUPPRESSION (Optional)
################################################################################
# Suppress specific warning or informational messages
# suppress_message LINT-1   ;# Suppress linting message
# suppress_message LINT-2   ;# Suppress linting message
# suppress_message OPT-1    ;# Suppress optimization message

puts "Synthesis setup variables loaded successfully"
puts "Design: $DESIGN_NAME"
puts "RTL Format: $RTL_FORMAT"
