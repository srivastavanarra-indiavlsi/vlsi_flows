################################################################################
# routing_vars_5nm.tcl
# Variable definitions for 5nm routing stage
################################################################################

puts "INFO: Loading 5nm technology variables..."

################################################################################
# Technology Configuration
################################################################################
set TECH_NODE "5nm"
set TECH_LIBRARY "tcbn05ffcllbwp5t30p140"
set TECH_LEF_FILES {
    "tcbn05ffcllbwp5t30p140_15lm.tlef"
    "tcbn05ffcllbwp5t30p140.lef"
}

################################################################################
# Design Paths
################################################################################
set DESIGN_NAME "your_design"
set RUN_DIR "./run"
set RESULTS_DIR "${RUN_DIR}/results"
set REPORTS_DIR "${RUN_DIR}/reports"
set LOGS_DIR "${RUN_DIR}/logs"

# Database paths
set CTS_DB "${RESULTS_DIR}/cts/${DESIGN_NAME}_cts.enc"
set ROUTE_DB "${RESULTS_DIR}/route/${DESIGN_NAME}_route.enc"

################################################################################
# Process Corners (5nm)
################################################################################
set CORNER_LIST "ss_125c_0p68v tt_25c_0p75v ff_m40c_0p82v"
set WC_CORNER "ss_125c_0p68v"
set BC_CORNER "ff_m40c_0p82v"
set NOMINAL_VOLTAGE 0.75
set NOMINAL_TEMP 25

# Corner definitions (5nm has tighter voltage range)
set CORNER_SETUP {
    {ss_125c_0p68v 125 0.68 slow slow}
    {tt_25c_0p75v  25  0.75 typical typical}
    {ff_m40c_0p82v -40 0.82 fast fast}
}

################################################################################
# Metal Stack Configuration (5nm: 15 layers typical)
################################################################################
set ROUTING_LAYER_MIN 2
set ROUTING_LAYER_MAX 15
set SIGNAL_LAYER_MIN 2
set SIGNAL_LAYER_MAX 12
set CLOCK_LAYER_MIN 10
set CLOCK_LAYER_MAX 12
set POWER_LAYER_MIN 13
set POWER_LAYER_MAX 15

# Layer properties (very fine pitch)
set MIN_ROUTING_PITCH 0.028  ;# 28nm
set MIN_METAL_WIDTH_M1 0.014
set MIN_METAL_WIDTH_M2 0.020
set MIN_METAL_SPACING_M1 0.014
set MIN_METAL_SPACING_M2 0.020

# Metal layer directions (5nm EUV-based)
set METAL_DIRECTIONS {
    M1 vertical
    M2 horizontal
    M3 vertical
    M4 horizontal
    M5 vertical
    M6 horizontal
    M7 vertical
    M8 horizontal
    M9 vertical
    M10 horizontal
    M11 vertical
    M12 horizontal
    M13 vertical
    M14 horizontal
    M15 horizontal
}

################################################################################
# Routing Configuration
################################################################################
set ROUTE_EFFORT "high"
set ROUTE_DETAIL_EFFORT "high"
set ROUTE_NANO_ITERATIONS 5
set ROUTE_ECO_ITERATIONS 4
set ROUTE_GUIDE_EFFORT "high"

################################################################################
# Timing Constraints (5nm - very tight)
################################################################################
set TARGET_SETUP_SLACK 0.060     ;# 60ps
set TARGET_HOLD_SLACK 0.030      ;# 30ps
set SETUP_SLACK_MARGIN 0.030
set HOLD_SLACK_MARGIN 0.010

# Transition and capacitance limits
set MAX_TRANSITION 0.120         ;# 120ps
set MAX_CAPACITANCE 0.080        ;# 80fF
set MAX_FANOUT 10

# Derating factors (very tight for 5nm)
set TIMING_DERATE_EARLY 0.93
set TIMING_DERATE_LATE 1.07

################################################################################
# DRC Settings
################################################################################
set ROUTE_DRC_EFFORT "high"
set MAX_ROUTE_VIOLATIONS 0
set MAX_TRANSITION_VIOLATION 0
set MAX_CAPACITANCE_VIOLATION 0
set MAX_FANOUT_VIOLATION 0
set ENABLE_ADVANCED_DRC_CHECK true

################################################################################
# Signal Integrity (5nm - most critical)
################################################################################
set SI_AWARE_ROUTING true
set CROSSTALK_ANALYSIS true
set SI_ANALYSIS_EFFORT "high"
set CROSSTALK_NET_THRESHOLD 0.20
set DELTA_DELAY_THRESHOLD 0.030  ;# 30ps
set GLITCH_THRESHOLD 0.20        ;# 20% of VDD
set ENABLE_ADVANCED_SI true

# Shielding options (critical for 5nm)
set ENABLE_CLOCK_SHIELDING true
set ENABLE_SIGNAL_SHIELDING true
set CLOCK_SHIELD_NET "VSS"
set CRITICAL_NET_SHIELDING true

################################################################################
# Via Configuration (critical for 5nm)
################################################################################
set VIA_OPT_EFFORT "high"
set VIA_LADDER_CHECK true
set REDUNDANT_VIA_INSERTION true
set DOUBLE_VIA_THRESHOLD 0.7
set VIA_ENCLOSURE_CHECK true
set MULTI_CUT_VIA_EFFORT "high"
set VIA_STACK_OPTIMIZATION true
set MIN_CUT_VIA_SIZE "VIA1"
set ENABLE_VIA_PILLAR true

################################################################################
# Antenna Rules (5nm - very strict)
################################################################################
set ANTENNA_CHECK true
set ANTENNA_FIX_DIODE true
set ANTENNA_FIX_JUMPER true
set ANTENNA_DIODE_CELL "ANTENNABHD1"
set ANTENNA_RATIO_THRESHOLD 200
set ANTENNA_DIFF_RATIO 100
set ANTENNA_GATE_RATIO 200
set ANTENNA_FIX_AGGRESSIVE true
set ANTENNA_LAYER_CHECK "M1:M12"

################################################################################
# Search and Repair
################################################################################
set SR_ENABLE_DETOUR true
set SR_ENABLE_SHIELDING true
set SR_WIRE_SPREAD_EFFORT "high"
set SR_HONOR_USER_ROUTE true
set SR_MAX_ITERATIONS 5

################################################################################
# Post-Route Optimization
################################################################################
set POSTROUTE_OPT_ITERATIONS 5
set POSTROUTE_BUFFER_AREA_MAX_PERCENT 15
set POSTROUTE_AREA_RECLAIM true
set POSTROUTE_TNS_EFFORT "high"
set POSTROUTE_DRIV_EFFORT "high"
set POSTROUTE_RESIZE_CELLS true
set POSTROUTE_CLONE_GATES true
set POSTROUTE_VT_SWAP true
set POSTROUTE_LAYER_OPT true

################################################################################
# Filler Cells (5nm)
################################################################################
set FILLER_CELLS "FILLHD128 FILLHD64 FILLHD32 FILLHD16 FILLHD8 FILLHD4 FILLHD2 FILLHD1"
set DECAP_CELLS "DCAPHD128 DCAPHD64 DCAPHD32 DCAPHD16 DCAPHD8 DCAPHD4"
set USE_DECAP true
set USE_WELLTIES true
set DECAP_PERCENTAGE 8.0
set WELLTIE_CELL "WELLTIE"
set WELLTIE_INTERVAL 30.0

################################################################################
# Metal Fill
################################################################################
set METAL_FILL_ENABLE true
set METAL_FILL_TIMING_AWARE true
set METAL_FILL_LAYERS "M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12"
set METAL_FILL_WINDOW_SIZE 30.0
set METAL_FILL_SPACING 1.0
set METAL_FILL_BLOCKAGE_SPACING 2.0
set METAL_FILL_SI_AWARE true

################################################################################
# CMP (Chemical Mechanical Polishing)
################################################################################
set CMP_AWARE_FILL true
set CMP_TARGET_DENSITY 0.75
set CMP_WINDOW_SIZE 40.0
set CMP_ANALYSIS_LAYERS "M1:M12"

################################################################################
# Lithography (5nm EUV + multi-patterning)
################################################################################
set LITHO_DRIVEN_ROUTING true
set ENABLE_COLORING_CHECK true
set OPC_AWARE_ROUTING true
set ENABLE_DOUBLE_PATTERNING true
set ENABLE_TRIPLE_PATTERNING false
set ENABLE_EUV_CHECKS true
set EUV_LAYERS "M1 M2 M3 M4 M5"

# Multi-patterning layers (lower metals)
set MULTI_PATTERN_LAYERS "M2 M3 M4 M5"

################################################################################
# Multi-threading (maximum for 5nm)
################################################################################
set NUM_CORES 64
set DISTRIBUTED_ROUTING true
set DISTRIBUTED_HOSTS ""
set PARALLEL_ROUTE_PARTITIONS 8
set USE_MULTI_SCENARIO_OPT true

################################################################################
# Timing Analysis Options (POCV for 5nm)
################################################################################
set TIMING_WINDOW_SETUP "0:0.6"
set TIMING_WINDOW_HOLD "0:0.6"
set ENABLE_CPPR true
set ENABLE_AOCV true
set ENABLE_POCV true
set TIMING_ANALYSIS_TYPE "bcwc_pocv"

# AOCV/POCV settings
set AOCV_ENABLE_DISTANCE true
set AOCV_ENABLE_DEPTH true
set POCV_COEFFICIENT_FILE "pocv.coeff"

################################################################################
# Power Settings (critical for 5nm)
################################################################################
set POWER_ANALYSIS_MODE "time_based"
set POWER_ACTIVITY_FILE ""
set LEAKAGE_POWER_EFFORT "high"
set DYNAMIC_POWER_OPTIMIZATION true
set LOW_POWER_PLACEMENT true
set MULTI_VT_OPTIMIZATION true

# Power gating (common in 5nm)
set ENABLE_POWER_GATING false
set RETENTION_CELLS ""
set ISOLATION_CELLS ""

################################################################################
# Clock Tree Settings
################################################################################
set CTS_BUFFER_CELLS "CKBUFHD2 CKBUFHD4 CKBUFHD8 CKBUFHD12 CKBUFHD16 CKBUFHD20"
set CTS_INVERTER_CELLS "CKINVHD2 CKINVHD4 CKINVHD8 CKINVHD12 CKINVHD16 CKINVHD20"
set CTS_CLOCK_NETS "clk"
set CTS_NDR "3W3S"

################################################################################
# ECO Routing
################################################################################
set ECO_ROUTE_ENABLE true
set ECO_ROUTE_MAX_ITERATIONS 8
set ECO_REFINE_ROUTING true
set ECO_FIX_ANTENNA true
set ECO_FIX_SI true

################################################################################
# Verification Options (comprehensive for 5nm)
################################################################################
set ROUTE_DEBUG_LEVEL 0
set VERIFY_GEOMETRY true
set VERIFY_CONNECTIVITY true
set VERIFY_PROCESS_ANTENNA true
set VERIFY_METAL_DENSITY true
set VERIFY_MINAREA true
set VERIFY_CUT_SPACING true
set VERIFY_EOL_SPACING true
set VERIFY_WIRE_EXTENSION true

################################################################################
# Export Options
################################################################################
set EXPORT_GDS true
set EXPORT_DEF true
set EXPORT_NETLIST true
set EXPORT_SDF true
set EXPORT_SPEF true
set EXPORT_LEF false
set EXPORT_TIMING_CONSTRAINTS true
set EXPORT_PARASITICS_DETAILED true

# GDS options
set GDS_LAYER_MAP "gds.map"
set GDS_MERGE_FILES ""
set GDS_HIERARCHY_DEPTH 64
set GDS_TEXT_LAYER 63

################################################################################
# Report Settings
################################################################################
set REPORT_PREFIX "${DESIGN_NAME}_route"
set GENERATE_QOR_REPORT true
set GENERATE_AREA_REPORT true
set GENERATE_POWER_REPORT true
set GENERATE_TIMING_REPORT true
set GENERATE_DRC_REPORT true
set GENERATE_SI_REPORT true
set GENERATE_IR_DROP_REPORT true

# Report detail levels
set TIMING_REPORT_PATHS 300
set DRC_REPORT_LIMIT 100000

################################################################################
# Special Routing
################################################################################
set SPECIAL_ROUTE_VIA_EFFORT "high"
set SPECIAL_ROUTE_WIRE_TYPE "STRIPE"
set SPECIAL_ROUTE_SHIELD true
set SPECIAL_ROUTE_DOUBLE_VIA true

################################################################################
# Non-Default Rules (NDR)
################################################################################
set NDR_DOUBLE_WIDTH "2W2S"
set NDR_TRIPLE_WIDTH "3W3S"
set NDR_QUAD_WIDTH "4W4S"
set NDR_CLOCK_NETS "3W3S"
set NDR_HIGH_SPEED_NETS "4W4S"

# NDR definitions
set NDR_RULES {
    {2W2S {M1:M12 2 2} {V1:V11 2}}
    {3W3S {M1:M12 3 3} {V1:V11 3}}
    {4W4S {M1:M12 4 4} {V1:V11 4}}
}

################################################################################
# Buffer and Sizing Limits
################################################################################
set MAX_BUFFER_COUNT 3000
set MIN_BUFFER_DISTANCE 2.0
set MAX_CELL_SIZE "X20"
set MIN_CELL_SIZE "X1"
set ENABLE_BUFFER_POLARITY_OPT true

################################################################################
# Useful Skew Optimization
################################################################################
set ENABLE_USEFUL_SKEW true
set USEFUL_SKEW_CCOPT true
set USEFUL_SKEW_SETUP_SLACK_THRESHOLD -0.030
set USEFUL_SKEW_HOLD_SLACK_THRESHOLD 0.010

################################################################################
# Advanced Options (5nm specific)
################################################################################
set ENABLE_TRACK_PATTERN_ROUTING true
set ENABLE_PIN_ACCESS_ANALYSIS true
set ENABLE_ROUTE_ECO_TIMING true
set ENABLE_ADVANCED_NODE_OPT true
set ENABLE_RESISTANCE_AWARE_OPT true

# FinFET specific
set FINFET_OPTIMIZATION true
set MULTI_HEIGHT_CELL_SUPPORT true

################################################################################
# IR Drop Analysis (important for 5nm)
################################################################################
set ENABLE_IR_DROP_ANALYSIS true
set IR_DROP_LIMIT 50  ;# mV
set ENABLE_EM_ANALYSIS true

################################################################################
# Technology Summary
################################################################################
puts "=========================================================================="
puts "5nm Technology Configuration Loaded"
puts "=========================================================================="
puts "Routing Layers:    M${ROUTING_LAYER_MIN} - M${ROUTING_LAYER_MAX}"
puts "Signal Layers:     M${SIGNAL_LAYER_MIN} - M${SIGNAL_LAYER_MAX}"
puts "Clock Layers:      M${CLOCK_LAYER_MIN} - M${CLOCK_LAYER_MAX}"
puts "Power Layers:      M${POWER_LAYER_MIN} - M${POWER_LAYER_MAX}"
puts "Min Routing Pitch: ${MIN_ROUTING_PITCH} um"
puts "Nominal Voltage:   ${NOMINAL_VOLTAGE} V"
puts "Setup Target:      ${TARGET_SETUP_SLACK} ns"
puts "Hold Target:       ${TARGET_HOLD_SLACK} ns"
puts "SI Aware:          ${SI_AWARE_ROUTING}"
puts "Litho Driven:      ${LITHO_DRIVEN_ROUTING}"
puts "Multi-Patterning:  ${ENABLE_COLORING_CHECK}"
puts "EUV Checks:        ${ENABLE_EUV_CHECKS}"
puts "POCV Enabled:      ${ENABLE_POCV}"
puts "Well Ties:         ${USE_WELLTIES}"
puts "CPU Cores:         ${NUM_CORES}"
puts "=========================================================================="

################################################################################
# End of routing_vars_5nm.tcl
################################################################################
