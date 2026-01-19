######
#!/usr/bin/tclsh
#==============================================================================
# Placement Configuration File
# File: placement_config.tcl
# Description: Central configuration file for all placement parameters
#==============================================================================

puts "Loading placement configuration..."

#------------------------------------------------------------------------------
# DESIGN INFORMATION
#------------------------------------------------------------------------------
set DESIGN_NAME "your_design"
set TOP_MODULE "top"
set TECH_NODE "7nm"  ;# Technology node

#------------------------------------------------------------------------------
# BASIC PLACEMENT CONTROL
#------------------------------------------------------------------------------
set PLACEMENT_EFFORT "high"              ;# low, medium, high
set CORE_UTILIZATION 0.70                ;# Target utilization (0.70 = 70%)
set MAX_DENSITY 0.75                     ;# Max density per region (0.75 = 75%)
set PLACEMENT_STYLE "timing_driven"      ;# timing_driven, congestion_driven, balanced

#------------------------------------------------------------------------------
# OPTIMIZATION MODES
#------------------------------------------------------------------------------
set TIMING_DRIVEN "true"                 ;# Enable timing-driven placement
set CONGESTION_DRIVEN "true"             ;# Enable congestion-driven placement
set POWER_DRIVEN "false"                 ;# Enable power-driven placement
set AREA_RECOVERY "true"                 ;# Enable area recovery
set INCREMENTAL_PLACEMENT "false"        ;# Enable incremental placement

#------------------------------------------------------------------------------
# TIMING PARAMETERS
#------------------------------------------------------------------------------
set SETUP_PRIORITY "true"                ;# Prioritize setup timing
set HOLD_PRIORITY "false"                ;# Prioritize hold timing (usually post-CTS)
set CRITICAL_RANGE 0.5                   ;# Critical path range in ns
set SLACK_MARGIN 0.05                    ;# Target slack margin (ns)
set WNS_TARGET -0.1                      ;# Worst Negative Slack target (ns)
set TNS_TARGET -1.0                      ;# Total Negative Slack target (ns)

# Electrical constraints
set MAX_FANOUT 16                        ;# Max fanout for buffering
set MAX_TRANSITION 0.5                   ;# Max transition time (ns)
set MAX_CAPACITANCE 0.5                  ;# Max net capacitance (pF)
set MIN_BUFFER_DISTANCE 5.0              ;# Min distance between buffers (um)

#------------------------------------------------------------------------------
# CONGESTION CONTROL
#------------------------------------------------------------------------------
set CONGESTION_EFFORT "medium"           ;# low, medium, high, ultra
set HORIZONTAL_CONG_WEIGHT 1.0           ;# Horizontal congestion weight
set VERTICAL_CONG_WEIGHT 1.0             ;# Vertical congestion weight
set MAX_ROUTING_OVERFLOW 5               ;# Max overflow percentage
set GLOBAL_ROUTE_OVERFLOW_ITERATIONS 100 ;# Max iterations for overflow fix
set LAYER_AWARE_CONGESTION "true"        ;# Layer-aware congestion analysis

#------------------------------------------------------------------------------
# DENSITY CONTROL
#------------------------------------------------------------------------------
set UNIFORM_DENSITY "true"               ;# Enable uniform density spreading
set DENSITY_PENALTY_WEIGHT 1.0           ;# Weight for density penalty
set TARGET_DENSITY_PER_BIN 0.75          ;# Target density per placement bin
set DENSITY_BIN_SIZE 10.0                ;# Density bin size (um x um)
set WHITESPACE_MARGIN 0.05               ;# Whitespace margin for routing

#------------------------------------------------------------------------------
# MACRO RELATED PARAMETERS
#------------------------------------------------------------------------------
set MACRO_PLACE_FIRST "true"             ;# Place macros before standard cells
set MACRO_PLACEMENT_STYLE "auto"         ;# auto, corner, center, user
set MACRO_CHANNEL_WIDTH 10.0             ;# Channel width around macros (um)

# Macro halos (keepout margins)
set MACRO_HALO_TOP 2.0                   ;# Macro halo top (um)
set MACRO_HALO_BOTTOM 2.0                ;# Macro halo bottom (um)
set MACRO_HALO_LEFT 2.0                  ;# Macro halo left (um)
set MACRO_HALO_RIGHT 2.0                 ;# Macro halo right (um)

# Macro-to-macro spacing
set MACRO_TO_MACRO_SPACING 5.0           ;# Minimum spacing between macros (um)

#------------------------------------------------------------------------------
# ROW AND SITE CONFIGURATION
#------------------------------------------------------------------------------
set CELL_TO_CELL_GAP 1                   ;# Minimum gap between cells (sites)
set INST_GAP_FOR_SPACING 0               ;# Extra gap for DRC spacing
set RESPECT_SYMMETRY "true"              ;# Respect cell symmetry constraints
set RESPECT_SITE_SYMMETRY "true"         ;# Respect site symmetry
set ALIGN_TO_POWER_RAIL "true"           ;# Align cells to power rails

#------------------------------------------------------------------------------
# MULTI-VOLTAGE DOMAIN (if applicable)
#------------------------------------------------------------------------------
set HONOR_VOLTAGE_DOMAIN "false"         ;# Honor voltage domain boundaries
set POWER_DOMAIN_AWARE "false"           ;# Enable power domain aware placement
set LEVEL_SHIFTER_PLACEMENT "auto"       ;# auto, manual
set ISOLATION_CELL_PLACEMENT "auto"      ;# auto, manual
set RETENTION_CELL_PLACEMENT "auto"      ;# auto, manual

#------------------------------------------------------------------------------
# BUFFER/INVERTER CONTROL
#------------------------------------------------------------------------------
set MAX_BUFFER_COUNT 0                   ;# Max buffers to add (0=unlimited)
set BUFFER_CELL_LIST "BUF_X1 BUF_X2 BUF_X4 BUF_X8"  ;# List of buffer cells
set INVERTER_CELL_LIST "INV_X1 INV_X2 INV_X4"       ;# List of inverter cells
set ENABLE_BUFFER_INSERTION "true"       ;# Enable buffer insertion during placement
set ENABLE_INVERTER_INSERTION "true"     ;# Enable inverter insertion

#------------------------------------------------------------------------------
# CLOCK-AWARE PLACEMENT
#------------------------------------------------------------------------------
set CLOCK_GATE_AWARE "true"              ;# Clock gate aware placement
set REGISTER_CLUSTERING "true"           ;# Enable register clustering
set CLOCK_NET_WEIGHT 2.0                 ;# Weight for clock nets
set ICG_PLACEMENT_STYLE "balanced"       ;# balanced, timing, power
set CLOCK_TREE_AWARE "true"              ;# Consider future clock tree structure

# Clock gate cells
set ICG_CELLS_LIST "CLKGATE_X1 CLKGATE_X2 CLKGATE_X4"

#------------------------------------------------------------------------------
# SPECIAL CELL HANDLING
#------------------------------------------------------------------------------
# Well tap cells
set ADD_WELL_TAP "true"                  ;# Add well tap cells
set WELL_TAP_SPACING 30.0                ;# Well tap spacing (um)
set WELL_TAP_CELL "WELLTAP"              ;# Well tap cell name

# End cap cells
set ADD_END_CAP "true"                   ;# Add end cap cells
set END_CAP_PRE "ENDCAP_PRE"             ;# Pre end cap cell
set END_CAP_POST "ENDCAP_POST"           ;# Post end cap cell

# Tie cells (tie-high/low)
set TIE_CELL_HANDLING "true"             ;# Handle tie cells
set TIE_HIGH_CELL "TIEHI"                ;# Tie-high cell name
set TIE_LOW_CELL "TIELO"                 ;# Tie-low cell name
set MAX_TIE_FANOUT 8                     ;# Max fanout for tie cells

# Filler cells
set ADD_FILLER "false"                   ;# Add filler cells (usually done later)
set FILLER_CELL_LIST "FILL1 FILL2 FILL4 FILL8 FILL16"

# Decap cells
set ADD_DECAP "false"                    ;# Add decap cells
set DECAP_CELL_LIST "DECAP_X1 DECAP_X2 DECAP_X4"
set DECAP_DENSITY 0.05                   ;# Decap density (5%)

#------------------------------------------------------------------------------
# PLACEMENT STAGES CONTROL
#------------------------------------------------------------------------------
set RUN_COARSE_PLACEMENT "true"          ;# Run coarse (global) placement
set RUN_DETAILED_PLACEMENT "true"        ;# Run detailed (legalization)
set RUN_INCREMENTAL_PLACEMENT "false"    ;# Run incremental placement
set RUN_IN_PLACE_OPT "true"              ;# Run in-place optimization
set RUN_REFINE_PLACEMENT "true"          ;# Run placement refinement

#------------------------------------------------------------------------------
# WIRE LENGTH OPTIMIZATION
#------------------------------------------------------------------------------
set WIRE_LENGTH_OPT "true"               ;# Enable wire length optimization
set NET_WEIGHT_PRIORITY "timing"         ;# timing, congestion, power, balanced
set CRITICAL_NET_PERCENTAGE 10           ;# Top % of critical nets
set OPTIMIZE_WIRE_VIA_DENSITY "true"     ;# Optimize wire and via density
set NET_LENGTH_THRESHOLD 100.0           ;# Threshold for long nets (um)

#------------------------------------------------------------------------------
# ADVANCED CONTROLS
#------------------------------------------------------------------------------
set PRESERVE_USER_INST "true"            ;# Preserve user-placed instances
set HONOR_DONT_TOUCH "true"              ;# Honor dont_touch attributes
set HONOR_DONT_USE "true"                ;# Honor dont_use attributes
set PLACE_IO_PINS "false"                ;# Place I/O pins (usually done already)
set COLOR_AWARE_PLACEMENT "true"         ;# Multi-patterning aware placement
set ECO_MODE "false"                     ;# ECO mode (preserve existing placement)

#------------------------------------------------------------------------------
# CONCURRENT OPTIMIZATION
#------------------------------------------------------------------------------
set CONCURRENT_MACROS "true"             ;# Concurrent macro placement
set CONCURRENT_REFINE "true"             ;# Concurrent refinement
set ENABLE_PARALLEL_OPTIMIZATION "true"  ;# Enable parallel optimization

#------------------------------------------------------------------------------
# SCAN CHAIN (if applicable)
#------------------------------------------------------------------------------
set REORDER_SCAN_CHAIN "false"           ;# Reorder scan chain for placement
set SCAN_MAX_LENGTH 0                    ;# Max scan chain length (0=auto)
set SCAN_COMPRESSION_MODE "false"        ;# Scan compression mode
set PRESERVE_SCAN_ORDER "true"           ;# Preserve scan chain ordering

#------------------------------------------------------------------------------
# SPARE CELL INSERTION
#------------------------------------------------------------------------------
set ADD_SPARE_CELLS "false"              ;# Add spare cells
set SPARE_CELL_PREFIX "SPARE_"           ;# Prefix for spare cells
set SPARE_CELL_PERCENTAGE 5              ;# Percentage of spare cells
set SPARE_CELL_TYPES "AND2 OR2 NAND2 NOR2 INV BUF FLOP"  ;# Types of spare cells

#------------------------------------------------------------------------------
# RUNTIME VS QUALITY TRADE-OFF
#------------------------------------------------------------------------------
set ENABLE_MULTI_THREADING "true"        ;# Use multiple CPU cores
set NUM_THREADS 8                        ;# Number of threads to use
set RUNTIME_LIMIT 0                      ;# Max runtime in minutes (0=unlimited)
set MEMORY_LIMIT 0                       ;# Max memory in GB (0=unlimited)
set INCREMENTAL_MODE "false"             ;# Incremental mode for faster iterations

#------------------------------------------------------------------------------
# REPORTING AND DEBUG
#------------------------------------------------------------------------------
set ENABLE_VERBOSE_MODE "false"          ;# Enable verbose reporting
set GENERATE_PLACEMENT_IMAGES "true"     ;# Generate placement images
set REPORT_FREQUENCY "stage"             ;# never, stage, iteration, always
set DEBUG_LEVEL 1                        ;# Debug level (0-3)
set LOG_FILE "placement_run.log"         ;# Log file name

#------------------------------------------------------------------------------
# OUTPUT DIRECTORIES
#------------------------------------------------------------------------------
set REPORT_DIR "reports/placement"       ;# Report directory
set RESULT_DIR "results/placement"       ;# Result directory
set LOG_DIR "logs"                       ;# Log directory

#------------------------------------------------------------------------------
# DESIGN-SPECIFIC OVERRIDES
#------------------------------------------------------------------------------
# Add design-specific parameters here
# Example:
# if {$DESIGN_NAME == "cpu_core"} {
#     set PLACEMENT_EFFORT "ultra"
#     set NUM_THREADS 16
# }

#------------------------------------------------------------------------------
# VALIDATION
#------------------------------------------------------------------------------
proc validate_config {} {
    global CORE_UTILIZATION MAX_DENSITY
    
    if {$CORE_UTILIZATION > $MAX_DENSITY} {
        puts "WARNING: CORE_UTILIZATION ($CORE_UTILIZATION) > MAX_DENSITY ($MAX_DENSITY)"
        puts "         Adjusting MAX_DENSITY to match CORE_UTILIZATION"
        set MAX_DENSITY [expr $CORE_UTILIZATION + 0.05]
    }
    
    if {$CORE_UTILIZATION > 0.9} {
        puts "WARNING: Very high utilization ($CORE_UTILIZATION) may cause routing issues"
    }
}

# Run validation
validate_config

puts "Placement configuration loaded successfully."
puts "Design: $DESIGN_NAME"
puts "Effort: $PLACEMENT_EFFORT"
puts "Utilization: $CORE_UTILIZATION"
puts "Style: $PLACEMENT_STYLE"
