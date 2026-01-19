################################################################################
# routing_vars_16nm.tcl
# Variable definitions for 16nm routing stage
################################################################################

puts "INFO: Loading 16nm technology variables..."

################################################################################
# Technology Configuration
################################################################################
set TECH_NODE "16nm"
set TECH_LIBRARY "tcbn16ffcllbwp16tc"
set TECH_LEF_FILES {
    "tcbn16ffcllbwp16tc_9lm.tlef"
    "tcbn16ffcllbwp16tc.lef"
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
# Process Corners (16nm)
################################################################################
set CORNER_LIST "ss_125c_0p70v tt_25c_0p80v ff_m40c_0p88v"
set WC_CORNER "ss_125c_0p70v"
set BC_CORNER "ff_m40c_0p88v"
set NOMINAL_VOLTAGE 0.80
set NOMINAL_TEMP 25

# Corner definitions
set CORNER_SETUP {
    {ss_125c_0p70v 125 0.70 slow slow}
    {tt_25c_0p80v  25  0.80 typical typical}
    {ff_m40c_0p88v -40 0.88 fast fast}
}

################################################################################
# Metal Stack Configuration (16nm: 10 layers typical)
################################################################################
set ROUTING_LAYER_MIN 2
set ROUTING_LAYER_MAX 10
set SIGNAL_LAYER_MIN 2
set SIGNAL_LAYER_MAX 8
set CLOCK_LAYER_MIN 6
set CLOCK_LAYER_MAX 8
set POWER_LAYER_MIN 9
set POWER_LAYER_MAX 10

# Layer properties
set MIN_ROUTING_PITCH 0.064  ;# 64nm
set MIN_METAL_WIDTH_M1 0.032
set MIN_METAL_WIDTH_M2 0.040
set MIN_METAL_SPACING_M1 0.032
set MIN_METAL_SPACING_M2 0.040

# Metal layer directions
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
}

################################################################################
# Routing Configuration
################################################################################
set ROUTE_EFFORT "high"
set ROUTE_DETAIL_EFFORT "high"
set ROUTE_NANO_ITERATIONS 3
set ROUTE_ECO_ITERATIONS 2
set ROUTE_GUIDE_EFFORT "medium"

################################################################################
# Timing Constraints (16nm)
################################################################################
set TARGET_SETUP_SLACK 0.100     ;# 100ps
set TARGET_HOLD_SLACK 0.050      ;# 50ps
set SETUP_SLACK_MARGIN 0.050     ;# Additional margin
set HOLD_SLACK_MARGIN 0.020

# Transition and capacitance limits
set MAX_TRANSITION 0.200         ;# 200ps
set MAX_CAPACITANCE 0.150        ;# 150fF
set MAX_FANOUT 16

# Derating factors
set TIMING_DERATE_EARLY 0.97
set TIMING_DERATE_LATE 1.03

################################################################################
# DRC Settings
################################################################################
set ROUTE_DRC_EFFORT "high"
set MAX_ROUTE_VIOLATIONS 0
set MAX_TRANSITION_VIOLATION 0
set MAX_CAPACITANCE_VIOLATION 0
set MAX_FANOUT_VIOLATION 0

################################################################################
# Signal Integrity (16nm)
################################################################################
set SI_AWARE_ROUTING true
set CROSSTALK_ANALYSIS true
set SI_ANALYSIS_EFFORT "medium"
set CROSSTALK_NET_THRESHOLD 0.10
set DELTA_DELAY_THRESHOLD 0.050  ;# 50ps
set GLITCH_THRESHOLD 0.30        ;# 30% of VDD

# Shielding options
set ENABLE_CLOCK_SHIELDING false
set ENABLE_SIGNAL_SHIELDING false

################################################################################
# Via Configuration
################################################################################
set VIA_OPT_EFFORT "medium"
set VIA_LADDER_CHECK true
set REDUNDANT_VIA_INSERTION true
set DOUBLE_VIA_THRESHOLD 0.5
set VIA_ENCLOSURE_CHECK true
set MIN_CUT_VIA_SIZE "VIA1"

################################################################################
# Antenna Rules (16nm)
################################################################################
set ANTENNA_CHECK true
set ANTENNA_FIX_DIODE true
set ANTENNA_FIX_JUMPER true
set ANTENNA_DIODE_CELL "ANTENNA"
set ANTENNA_RATIO_THRESHOLD 400
set ANTENNA_DIFF_RATIO 200
set ANTENNA_GATE_RATIO 400

################################################################################
# Search and Repair
################################################################################
set SR_ENABLE_DETOUR true
set SR_ENABLE_SHIELDING false
set SR_WIRE_SPREAD_EFFORT "medium"
set SR_HONOR_USER_ROUTE true
set SR_MAX_ITERATIONS 3

################################################################################
# Post-Route Optimization
################################################################################
set POSTROUTE_OPT_ITERATIONS 3
set POSTROUTE_BUFFER_AREA_MAX_PERCENT 10
set POSTROUTE_AREA_RECLAIM true
set POSTROUTE_TNS_EFFORT "high"
set POSTROUTE_DRIV_EFFORT "high"
set POSTROUTE_RESIZE_CELLS true
set POSTROUTE_CLONE_GATES false

################################################################################
# Filler Cells (16nm)
################################################################################
set FILLER_CELLS "FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1"
set DECAP_CELLS "DCAP64 DCAP32 DCAP16 DCAP8"
set USE_DECAP false
set USE_WELLTIES false

################################################################################
# Metal Fill
################################################################################
set METAL_FILL_ENABLE true
set METAL_FILL_TIMING_AWARE true
set METAL_FILL_LAYERS "M1 M2 M3 M4 M5 M6 M7 M8"
set METAL_FILL_WINDOW_SIZE 50.0
set METAL_FILL_SPACING 2.0

################################################################################
# CMP (Chemical Mechanical Polishing)
################################################################################
set CMP_AWARE_FILL false
set CMP_TARGET_DENSITY 0.65

################################################################################
# Lithography
################################################################################
set LITHO_DRIVEN_ROUTING false
set ENABLE_COLORING_CHECK false
set OPC_AWARE_ROUTING false

################################################################################
# Multi-threading
################################################################################
set NUM_CORES 16
set DISTRIBUTED_ROUTING false
set DISTRIBUTED_HOSTS ""

################################################################################
# Timing Analysis Options
################################################################################
set TIMING_WINDOW_SETUP "0:1.0"
set TIMING_WINDOW_HOLD "0:1.0"
set ENABLE_CPPR true
set ENABLE_AOCV false
set ENABLE_POCV false
set TIMING_ANALYSIS_TYPE "bcwc"  ;# Best-case/Worst-case

################################################################################
# Power Settings
################################################################################
set POWER_ANALYSIS_MODE "time_based"
set POWER_ACTIVITY_FILE ""
set LEAKAGE_POWER_EFFORT "medium"
set DYNAMIC_POWER_OPTIMIZATION false

################################################################################
# Clock Tree Settings
################################################################################
set CTS_BUFFER_CELLS "BUFX2 BUFX4 BUFX8 BUFX12 BUFX16"
set CTS_INVERTER_CELLS "INVX2 INVX4 INVX8 INVX12 INVX16"
set CTS_CLOCK_NETS "clk"

################################################################################
# ECO Routing
################################################################################
set ECO_ROUTE_ENABLE true
set ECO_ROUTE_MAX_ITERATIONS 5
set ECO_REFINE_ROUTING true

################################################################################
# Verification Options
################################################################################
set ROUTE_DEBUG_LEVEL 0
set VERIFY_GEOMETRY true
set VERIFY_CONNECTIVITY true
set VERIFY_PROCESS_ANTENNA true
set VERIFY_METAL_DENSITY true
set VERIFY_MINAREA false

################################################################################
# Export Options
################################################################################
set EXPORT_GDS true
set EXPORT_DEF true
set EXPORT_NETLIST true
set EXPORT_SDF true
set EXPORT_SPEF true
set EXPORT_LEF false

# GDS options
set GDS_LAYER_MAP "gds.map"
set GDS_MERGE_FILES ""

################################################################################
# Report Settings
################################################################################
set REPORT_PREFIX "${DESIGN_NAME}_route"
set GENERATE_QOR_REPORT true
set GENERATE_AREA_REPORT true
set GENERATE_POWER_REPORT true
set GENERATE_TIMING_REPORT true
set GENERATE_DRC_REPORT true

# Report detail levels
set TIMING_REPORT_PATHS 100
set DRC_REPORT_LIMIT 10000

################################################################################
# Special Routing
################################################################################
set SPECIAL_ROUTE_VIA_EFFORT "high"
set SPECIAL_ROUTE_WIRE_TYPE "STRIPE"

################################################################################
# Non-Default Rules (NDR)
################################################################################
set NDR_DOUBLE_WIDTH "2W2S"
set NDR_TRIPLE_WIDTH "3W3S"
set NDR_CLOCK_NETS "2W2S"

################################################################################
# Buffer and Sizing Limits
################################################################################
set MAX_BUFFER_COUNT 1000
set MIN_BUFFER_DISTANCE 5.0
set MAX_CELL_SIZE "X16"
set MIN_CELL_SIZE "X1"

################################################################################
# Useful Skew Optimization
################################################################################
set ENABLE_USEFUL_SKEW false
set USEFUL_SKEW_CCOPT false

################################################################################
# Technology Summary
################################################################################
puts "=========================================================================="
puts "16nm Technology Configuration Loaded"
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
puts "CPU Cores:         ${NUM_CORES}"
puts "=========================================================================="

################################################################################
# End of routing_vars_16nm.tcl
################################################################################
