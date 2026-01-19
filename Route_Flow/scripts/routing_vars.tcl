################################################################################
# routing_vars.tcl
# Variable definitions for routing stage (16nm/7nm/5nm compatible)
################################################################################

# Design Variables
set DESIGN_NAME "your_design"
set RUN_DIR "./run"
set RESULTS_DIR "${RUN_DIR}/results"
set REPORTS_DIR "${RUN_DIR}/reports"
set LOGS_DIR "${RUN_DIR}/logs"

# Database paths
set CTS_DB "${RESULTS_DIR}/cts/${DESIGN_NAME}_cts.enc"
set ROUTE_DB "${RESULTS_DIR}/route/${DESIGN_NAME}_route.enc"

# Technology node selection (16nm, 7nm, or 5nm)
set TECH_NODE "7nm"  ;# Options: 16nm, 7nm, 5nm

# Technology-dependent corner configurations
if {$TECH_NODE == "16nm"} {
    set CORNER_LIST "ss_125c_0p70v tt_25c_0p80v ff_m40c_0p88v"
    set WC_CORNER "ss_125c_0p70v"
    set BC_CORNER "ff_m40c_0p88v"
    set NOMINAL_VOLTAGE 0.80
} elseif {$TECH_NODE == "7nm"} {
    set CORNER_LIST "ss_125c_0p72v tt_25c_0p80v ff_m40c_0p88v"
    set WC_CORNER "ss_125c_0p72v"
    set BC_CORNER "ff_m40c_0p88v"
    set NOMINAL_VOLTAGE 0.80
} elseif {$TECH_NODE == "5nm"} {
    set CORNER_LIST "ss_125c_0p68v tt_25c_0p75v ff_m40c_0p82v"
    set WC_CORNER "ss_125c_0p68v"
    set BC_CORNER "ff_m40c_0p82v"
    set NOMINAL_VOLTAGE 0.75
} else {
    puts "ERROR: Unsupported technology node: $TECH_NODE"
    exit 1
}

# Routing configuration
set ROUTE_EFFORT "high"
set ROUTE_DETAIL_EFFORT "high"
set ROUTE_NANO_ITERATIONS 3
set ROUTE_ECO_ITERATIONS 2

# Technology-dependent track assignment
# Metal stack configuration per technology node
if {$TECH_NODE == "16nm"} {
    # 16nm typical: 10-12 metal layers
    set ROUTING_LAYER_MIN 2
    set ROUTING_LAYER_MAX 10
    set SIGNAL_LAYER_MIN 2
    set SIGNAL_LAYER_MAX 8
    set CLOCK_LAYER_MIN 6
    set CLOCK_LAYER_MAX 8
    set POWER_LAYER_MIN 9
    set POWER_LAYER_MAX 10
    set MIN_ROUTING_PITCH 0.064  ;# 64nm
    
} elseif {$TECH_NODE == "7nm"} {
    # 7nm typical: 12-15 metal layers
    set ROUTING_LAYER_MIN 2
    set ROUTING_LAYER_MAX 13
    set SIGNAL_LAYER_MIN 2
    set SIGNAL_LAYER_MAX 10
    set CLOCK_LAYER_MIN 8
    set CLOCK_LAYER_MAX 10
    set POWER_LAYER_MIN 11
    set POWER_LAYER_MAX 13
    set MIN_ROUTING_PITCH 0.040  ;# 40nm
    
} elseif {$TECH_NODE == "5nm"} {
    # 5nm typical: 14-16 metal layers
    set ROUTING_LAYER_MIN 2
    set ROUTING_LAYER_MAX 15
    set SIGNAL_LAYER_MIN 2
    set SIGNAL_LAYER_MAX 12
    set CLOCK_LAYER_MIN 10
    set CLOCK_LAYER_MAX 12
    set POWER_LAYER_MIN 13
    set POWER_LAYER_MAX 15
    set MIN_ROUTING_PITCH 0.028  ;# 28nm
}

# DRC and timing - Technology scaled
if {$TECH_NODE == "16nm"} {
    set TARGET_SETUP_SLACK 0.100
    set TARGET_HOLD_SLACK 0.050
    set MAX_TRANSITION_16nm 0.200
    set MAX_CAPACITANCE_16nm 0.150
    set CROSSTALK_NET_THRESHOLD 0.10
    set DELTA_DELAY_THRESHOLD 0.050
    
} elseif {$TECH_NODE == "7nm"} {
    set TARGET_SETUP_SLACK 0.080
    set TARGET_HOLD_SLACK 0.040
    set MAX_TRANSITION_7nm 0.150
    set MAX_CAPACITANCE_7nm 0.100
    set CROSSTALK_NET_THRESHOLD 0.15
    set DELTA_DELAY_THRESHOLD 0.040
    
} elseif {$TECH_NODE == "5nm"} {
    set TARGET_SETUP_SLACK 0.060
    set TARGET_HOLD_SLACK 0.030
    set MAX_TRANSITION_5nm 0.120
    set MAX_CAPACITANCE_5nm 0.080
    set CROSSTALK_NET_THRESHOLD 0.20
    set DELTA_DELAY_THRESHOLD 0.030
}

set ROUTE_DRC_EFFORT "high"
set MAX_ROUTE_VIOLATIONS 0
set MAX_TRANSITION_VIOLATION 0
set MAX_CAPACITANCE_VIOLATION 0

# Search and repair options
set SR_ENABLE_DETOUR true
set SR_ENABLE_SHIELDING false
set SR_WIRE_SPREAD_EFFORT "medium"
set SR_HONOR_USER_ROUTE true

# Post-route optimization
set POSTROUTE_OPT_ITERATIONS 3
set POSTROUTE_BUFFER_AREA_MAX_PERCENT 10
set POSTROUTE_AREA_RECLAIM true
set POSTROUTE_TNS_EFFORT "high"
set POSTROUTE_DRIV_EFFORT "high"

# Via optimization - Technology dependent
if {$TECH_NODE == "16nm"} {
    set VIA_OPT_EFFORT "medium"
    set VIA_LADDER_CHECK true
    set REDUNDANT_VIA_INSERTION true
    set DOUBLE_VIA_THRESHOLD 0.5
    set VIA_ENCLOSURE_CHECK true
    
} elseif {$TECH_NODE == "7nm"} {
    set VIA_OPT_EFFORT "high"
    set VIA_LADDER_CHECK true
    set REDUNDANT_VIA_INSERTION true
    set DOUBLE_VIA_THRESHOLD 0.6
    set VIA_ENCLOSURE_CHECK true
    set MULTI_CUT_VIA_EFFORT "high"
    
} elseif {$TECH_NODE == "5nm"} {
    set VIA_OPT_EFFORT "high"
    set VIA_LADDER_CHECK true
    set REDUNDANT_VIA_INSERTION true
    set DOUBLE_VIA_THRESHOLD 0.7
    set VIA_ENCLOSURE_CHECK true
    set MULTI_CUT_VIA_EFFORT "high"
    set VIA_STACK_OPTIMIZATION true  ;# Critical for 5nm
}

# SI and crosstalk - Technology dependent
if {$TECH_NODE == "16nm"} {
    set SI_AWARE_ROUTING true
    set CROSSTALK_ANALYSIS true
    set SI_ANALYSIS_EFFORT "medium"
    
} elseif {$TECH_NODE == "7nm"} {
    set SI_AWARE_ROUTING true
    set CROSSTALK_ANALYSIS true
    set SI_ANALYSIS_EFFORT "high"
    
} elseif {$TECH_NODE == "5nm"} {
    set SI_AWARE_ROUTING true
    set CROSSTALK_ANALYSIS true
    set SI_ANALYSIS_EFFORT "high"
    set ENABLE_ADVANCED_SI true  ;# Advanced SI for 5nm
}

# Antenna fixing - Technology specific
set ANTENNA_CHECK true
set ANTENNA_FIX_DIODE true
set ANTENNA_FIX_JUMPER true

if {$TECH_NODE == "16nm"} {
    set ANTENNA_DIODE_CELL "ANTENNA_DRC"
    set ANTENNA_RATIO_THRESHOLD 400
    
} elseif {$TECH_NODE == "7nm"} {
    set ANTENNA_DIODE_CELL "ANTENNABHD1"
    set ANTENNA_RATIO_THRESHOLD 300
    
} elseif {$TECH_NODE == "5nm"} {
    set ANTENNA_DIODE_CELL "ANTENNABHD1"
    set ANTENNA_RATIO_THRESHOLD 200
    set ANTENNA_FIX_AGGRESSIVE true  ;# More aggressive for 5nm
}

# Filler and finishing - Technology specific
if {$TECH_NODE == "16nm"} {
    set FILLER_CELLS "FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1"
    set DECAP_CELLS "DCAP64 DCAP32 DCAP16 DCAP8 DCAP4"
    
} elseif {$TECH_NODE == "7nm"} {
    set FILLER_CELLS "FILLHD64 FILLHD32 FILLHD16 FILLHD8 FILLHD4 FILLHD2 FILLHD1"
    set DECAP_CELLS "DCAPHD64 DCAPHD32 DCAPHD16 DCAPHD8 DCAPHD4"
    set USE_DECAP true
    
} elseif {$TECH_NODE == "5nm"} {
    set FILLER_CELLS "FILLHD64 FILLHD32 FILLHD16 FILLHD8 FILLHD4 FILLHD2 FILLHD1"
    set DECAP_CELLS "DCAPHD64 DCAPHD32 DCAPHD16 DCAPHD8 DCAPHD4"
    set USE_DECAP true
    set USE_WELLTIES true  ;# Well tie requirements stricter in 5nm
}

set METAL_FILL_ENABLE true
set METAL_FILL_TIMING_AWARE true

# Report settings
set REPORT_PREFIX "${DESIGN_NAME}_route"
set GENERATE_QOR_REPORT true
set GENERATE_AREA_REPORT true
set GENERATE_POWER_REPORT true

# Multi-threading - Adjusted for modern designs
if {$TECH_NODE == "16nm"} {
    set NUM_CORES 16
    set DISTRIBUTED_ROUTING false
    
} elseif {$TECH_NODE == "7nm"} {
    set NUM_CORES 32
    set DISTRIBUTED_ROUTING true
    set DISTRIBUTED_HOSTS ""  ;# Add hosts if available
    
} elseif {$TECH_NODE == "5nm"} {
    set NUM_CORES 64
    set DISTRIBUTED_ROUTING true
    set DISTRIBUTED_HOSTS ""  ;# Add hosts if available
    set USE_MULTI_SCENARIO_OPT true  ;# Important for 5nm
}

# Debug and verification
set ROUTE_DEBUG_LEVEL 0
set VERIFY_GEOMETRY true
set VERIFY_CONNECTIVITY true
set VERIFY_PROCESS_ANTENNA true

# Technology-specific verification
if {$TECH_NODE == "16nm"} {
    set LITHO_DRIVEN_ROUTING false
    set CMP_AWARE_FILL false
    
} elseif {$TECH_NODE == "7nm"} {
    set LITHO_DRIVEN_ROUTING true
    set CMP_AWARE_FILL true
    set ENABLE_COLORING_CHECK true  ;# Multi-patterning
    
} elseif {$TECH_NODE == "5nm"} {
    set LITHO_DRIVEN_ROUTING true
    set CMP_AWARE_FILL true
    set ENABLE_COLORING_CHECK true
    set ENABLE_EUV_CHECKS true  ;# EUV-specific checks
    set VERIFY_MINAREA true
}

# Timing windows - Technology scaled
if {$TECH_NODE == "16nm"} {
    set TIMING_WINDOW_SETUP "0:1.0"
    set TIMING_WINDOW_HOLD "0:1.0"
    set ENABLE_CPPR true
    
} elseif {$TECH_NODE == "7nm"} {
    set TIMING_WINDOW_SETUP "0:0.8"
    set TIMING_WINDOW_HOLD "0:0.8"
    set ENABLE_CPPR true
    set ENABLE_AOCV true  ;# AOCV for 7nm
    
} elseif {$TECH_NODE == "5nm"} {
    set TIMING_WINDOW_SETUP "0:0.6"
    set TIMING_WINDOW_HOLD "0:0.6"
    set ENABLE_CPPR true
    set ENABLE_AOCV true
    set ENABLE_POCV true  ;# POCV for 5nm
}

# ECO routing
set ECO_ROUTE_ENABLE true
set ECO_ROUTE_MAX_ITERATIONS 5

# Exports
set EXPORT_GDS true
set EXPORT_DEF true
set EXPORT_NETLIST true
set EXPORT_SDF true
set EXPORT_SPEF true

################################################################################
# End of routing_vars.tcl
################################################################################

# Print technology configuration summary
puts "=========================================================================="
puts "Technology Configuration: $TECH_NODE"
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
if {$TECH_NODE == "5nm"} {
    puts "EUV Checks:        ${ENABLE_EUV_CHECKS}"
}
puts "=========================================================================="
