#!/usr/bin/tclsh
#==============================================================================
# Standard Cell Placement Script for Cadence Innovus
# Prerequisites: Floorplan, Pin Placement, and Power Grid completed
#==============================================================================

puts "=========================================="
puts "Starting Standard Cell Placement - Innovus"
puts "=========================================="

#------------------------------------------------------------------------------
# Configuration Parameters
#------------------------------------------------------------------------------
set DESIGN_NAME "your_design"

# Basic Placement Control
set PLACEMENT_EFFORT "high"              ;# low, medium, high
set CORE_UTILIZATION 0.70                ;# Target utilization (0.70 = 70%)
set MAX_DENSITY 0.75                     ;# Max density per region (0.75 = 75%)

# Optimization Modes
set TIMING_DRIVEN "true"                 ;# Enable timing-driven placement
set CONGESTION_DRIVEN "true"             ;# Enable congestion-driven placement
set POWER_DRIVEN "false"                 ;# Enable power-driven placement
set AREA_RECOVERY "true"                 ;# Enable area recovery

# Timing Parameters
set SETUP_PRIORITY "true"                ;# Prioritize setup timing
set HOLD_PRIORITY "false"                ;# Prioritize hold timing (usually post-CTS)
set CRITICAL_RANGE 0.5                   ;# Critical path range in ns
set SLACK_MARGIN 0.05                    ;# Target slack margin (ns)

# Congestion Control
set CONGESTION_EFFORT "medium"           ;# low, medium, high, ultra
set HORIZONTAL_CONG_WEIGHT 1.0           ;# Horizontal congestion weight
set VERTICAL_CONG_WEIGHT 1.0             ;# Vertical congestion weight
set MAX_ROUTING_OVERFLOW 5               ;# Max overflow percentage

# Density Control
set UNIFORM_DENSITY "true"               ;# Enable uniform density spreading
set DENSITY_PENALTY_WEIGHT 1.0           ;# Weight for density penalty
set TARGET_DENSITY_PER_BIN 0.75          ;# Target density per placement bin

# Macro Related
set MACRO_PLACE_FIRST "true"             ;# Place macros before standard cells
set MACRO_CHANNEL_WIDTH 10.0             ;# Channel width around macros (um)
set MACRO_HALO_TOP 2.0                   ;# Macro halo top (um)
set MACRO_HALO_BOTTOM 2.0                ;# Macro halo bottom (um)
set MACRO_HALO_LEFT 2.0                  ;# Macro halo left (um)
set MACRO_HALO_RIGHT 2.0                 ;# Macro halo right (um)

# Row and Site Configuration
set CELL_TO_CELL_GAP 1                   ;# Minimum gap between cells (sites)
set INST_GAP_FOR_SPACING 0               ;# Extra gap for DRC spacing
set RESPECT_SYMMETRY "true"              ;# Respect cell symmetry constraints

# Multi-Voltage Domain (if applicable)
set HONOR_VOLTAGE_DOMAIN "false"         ;# Honor voltage domain boundaries
set POWER_DOMAIN_AWARE "false"           ;# Enable power domain aware placement

# Buffer/Inverter Control
set MAX_BUFFER_COUNT 0                   ;# Max buffers to add (0=unlimited)
set BUFFER_CELL_LIST ""                  ;# List of buffer cells to use
set MAX_FANOUT 16                        ;# Max fanout for buffering
set MAX_TRANSITION 0.5                   ;# Max transition time (ns)
set MAX_CAPACITANCE 0.5                  ;# Max net capacitance (pF)

# Clock-Aware Placement
set CLOCK_GATE_AWARE "true"              ;# Clock gate aware placement
set REGISTER_CLUSTERING "true"           ;# Enable register clustering
set CLOCK_NET_WEIGHT 2.0                 ;# Weight for clock nets

# Special Cell Handling
set ICG_CELLS_LIST ""                    ;# List of ICG cells
set WELL_TAP_SPACING 30.0                ;# Well tap spacing (um)
set END_CAP_CELLS "true"                 ;# Add end cap cells
set TIE_CELL_HANDLING "true"             ;# Handle tie cells (tie-high/low)

# Placement Stages Control
set RUN_COARSE_PLACEMENT "true"          ;# Run coarse (global) placement
set RUN_DETAILED_PLACEMENT "true"        ;# Run detailed (legalization)
set RUN_INCREMENTAL_PLACEMENT "false"    ;# Run incremental placement
set RUN_IN_PLACE_OPT "true"              ;# Run in-place optimization

# Wire Length Optimization
set WIRE_LENGTH_OPT "true"               ;# Enable wire length optimization
set NET_WEIGHT_PRIORITY "timing"         ;# timing, congestion, power, balanced
set CRITICAL_NET_PERCENTAGE 10           ;# Top % of critical nets

# Advanced Controls
set PRESERVE_USER_INST "true"            ;# Preserve user-placed instances
set HONOR_DONT_TOUCH "true"              ;# Honor dont_touch attributes
set HONOR_DONT_USE "true"                ;# Honor dont_use attributes
set PLACE_IO_PINS "false"                ;# Place I/O pins (usually done already)
set COLOR_AWARE_PLACEMENT "true"         ;# Multi-patterning aware placement

# Concurrent Optimization
set CONCURRENT_MACROS "true"             ;# Concurrent macro placement
set CONCURRENT_REFINE "true"             ;# Concurrent refinement

# Scan Chain (if applicable)
set REORDER_SCAN_CHAIN "false"           ;# Reorder scan chain for placement
set SCAN_MAX_LENGTH 0                    ;# Max scan chain length (0=auto)

# Spare Cell Insertion
set ADD_SPARE_CELLS "false"              ;# Add spare cells
set SPARE_CELL_PREFIX "SPARE_"           ;# Prefix for spare cells
set SPARE_CELL_PERCENTAGE 5              ;# Percentage of spare cells

# Runtime vs Quality Trade-off
set ENABLE_MULTI_THREADING "true"        ;# Use multiple CPU cores
set NUM_THREADS 8                        ;# Number of threads to use
set RUNTIME_LIMIT 0                      ;# Max runtime in minutes (0=unlimited)

#------------------------------------------------------------------------------
# Check Prerequisites
#------------------------------------------------------------------------------
proc check_prerequisites {} {
    puts "\n--- Checking Prerequisites ---"
    
    # Check if floorplan exists
    set core_area [dbGet top.fPlan.coreBox]
    if {$core_area == ""} {
        puts "ERROR: No floorplan found. Please run floorplan first."
        return 0
    } else {
        puts "PASS: Floorplan exists - Core area: $core_area"
    }
    
    # Check if power grid exists
    set pg_nets [dbGet top.nets.isPwrOrGnd 1 -p]
    if {[llength $pg_nets] == 0} {
        puts "WARNING: No power grid found. Consider building power grid first."
    } else {
        puts "PASS: Power grid found - [llength $pg_nets] power/ground nets"
    }
    
    # Check if pins are placed
    set total_pins [dbGet top.terms.name -e]
    set placed_pins [dbGet top.terms.pt.x -e]
    if {[llength $total_pins] > 0} {
        set unplaced [expr [llength $total_pins] - [llength $placed_pins]]
        if {$unplaced > 0} {
            puts "WARNING: $unplaced pins are not placed yet."
        } else {
            puts "PASS: All pins are placed."
        }
    }
    
    puts "Prerequisites check completed."
    return 1
}

#------------------------------------------------------------------------------
# Pre-Placement Setup
#------------------------------------------------------------------------------
proc pre_placement_setup {} {
    puts "\n--- Pre-Placement Setup ---"
    
    # Delete any existing placement
    deleteAllPlaceBlockage
    
    # Set placement blockages around macros with halos
    set macros [dbGet top.insts.cell.subClass block -p2]
    if {[llength $macros] > 0} {
        foreach macro $macros {
            set inst_name [dbGet [dbGet $macro.name] -e]
            set bbox [dbGet $macro.box]
            
            # Create hard blockage around macro
            createPlaceBlockage -type hard -box $bbox -inst $inst_name
            
            # Add halo with configurable spacing
            set halo_box [list \
                [expr [lindex $bbox 0] - $MACRO_HALO_LEFT] \
                [expr [lindex $bbox 1] - $MACRO_HALO_BOTTOM] \
                [expr [lindex $bbox 2] + $MACRO_HALO_RIGHT] \
                [expr [lindex $bbox 3] + $MACRO_HALO_TOP]]
            
            createPlaceBlockage -type soft -box $halo_box
        }
        puts "Added placement blockages and halos around [llength $macros] macros."
        puts "  Halo: T=$MACRO_HALO_TOP B=$MACRO_HALO_BOTTOM L=$MACRO_HALO_LEFT R=$MACRO_HALO_RIGHT um"
    }
    
    # Set keepout margins for power rails
    setPlaceMode -placeKeepOutMarginTop 0.5
    setPlaceMode -placeKeepOutMarginBottom 0.5
    
    # Prevent placement under power stripes
    set power_nets [dbGet top.nets.isPwrOrGnd 1 -p]
    foreach net $power_nets {
        set net_name [dbGet $net.name -e]
        createRouteBlk -layer {METAL3 METAL4 METAL5} -pgnetonly -box [dbGet top.fPlan.box]
    }
    
    puts "Pre-placement setup completed."
}

#------------------------------------------------------------------------------
# Placement Configuration
#------------------------------------------------------------------------------
proc configure_placement {effort timing_driven congestion_driven} {
    global CONGESTION_EFFORT HORIZONTAL_CONG_WEIGHT VERTICAL_CONG_WEIGHT
    global MAX_ROUTING_OVERFLOW UNIFORM_DENSITY DENSITY_PENALTY_WEIGHT
    global TARGET_DENSITY_PER_BIN CELL_TO_CELL_GAP INST_GAP_FOR_SPACING
    global MAX_BUFFER_COUNT MAX_FANOUT MAX_TRANSITION MAX_CAPACITANCE
    global CLOCK_GATE_AWARE REGISTER_CLUSTERING CLOCK_NET_WEIGHT
    global PRESERVE_USER_INST HONOR_DONT_TOUCH HONOR_DONT_USE
    global COLOR_AWARE_PLACEMENT CONCURRENT_MACROS CONCURRENT_REFINE
    global ENABLE_MULTI_THREADING NUM_THREADS WIRE_LENGTH_OPT
    global CRITICAL_RANGE SLACK_MARGIN POWER_DRIVEN NET_WEIGHT_PRIORITY
    global AREA_RECOVERY RUNTIME_LIMIT RESPECT_SYMMETRY
    
    puts "\n--- Configuring Placement Parameters ---"
    
    # Reset to default
    setPlaceMode -reset
    
    # Basic placement effort
    setPlaceMode -effort $effort
    setPlaceMode -place_global_solver_effort $effort
    
    if {$effort == "high"} {
        setPlaceMode -place_global_max_density 0.95
    } elseif {$effort == "medium"} {
        setPlaceMode -place_global_max_density 0.90
    } else {
        setPlaceMode -place_global_max_density 0.85
    }
    
    # Timing-driven parameters
    if {$timing_driven == "true"} {
        setPlaceMode -timingDriven true
        setPlaceMode -place_global_timing_effort high
        setOptMode -setupTargetSlack $SLACK_MARGIN
        setOptMode -criticalPathOpt true
        
        # Wire length optimization
        if {$WIRE_LENGTH_OPT == "true"} {
            setPlaceMode -place_global_optimize_wire_via_density true
        }
        
        # Max transition and capacitance
        setDesignMode -process $MAX_TRANSITION
        
        puts "  Timing-driven placement: ENABLED"
        puts "    - Target slack margin: $SLACK_MARGIN ns"
        puts "    - Critical range: $CRITICAL_RANGE ns"
    } else {
        setPlaceMode -timingDriven false
    }
    
    # Congestion-driven parameters
    if {$congestion_driven == "true"} {
        setPlaceMode -congEffort $CONGESTION_EFFORT
        setPlaceMode -place_global_cong_effort $CONGESTION_EFFORT
        
        # Congestion weights
        setCongestionEffort -hCongWeight $HORIZONTAL_CONG_WEIGHT
        setCongestionEffort -vCongWeight $VERTICAL_CONG_WEIGHT
        
        # Overflow control
        setNanoRouteMode -droutePostRouteSpreadWire true
        setNanoRouteMode -routeWithTimingDriven true
        
        puts "  Congestion-driven placement: ENABLED"
        puts "    - Congestion effort: $CONGESTION_EFFORT"
        puts "    - Max overflow: $MAX_ROUTING_OVERFLOW%"
    }
    
    # Power-driven parameters
    if {$POWER_DRIVEN == "true"} {
        setPlaceMode -powerDriven true
        setOptMode -optimizePowerForSetup true
        puts "  Power-driven placement: ENABLED"
    }
    
    # Density control
    if {$UNIFORM_DENSITY == "true"} {
        setPlaceMode -place_global_uniform_density true
        setPlaceMode -place_detail_density_target $TARGET_DENSITY_PER_BIN
        puts "  Uniform density: ENABLED (target: $TARGET_DENSITY_PER_BIN)"
    }
    
    # Cell spacing
    setPlaceMode -place_detail_legalization_inst_gap $CELL_TO_CELL_GAP
    if {$INST_GAP_FOR_SPACING > 0} {
        setPlaceMode -place_detail_check_cut_spacing true
    }
    puts "  Cell-to-cell gap: $CELL_TO_CELL_GAP sites"
    
    # Multi-patterning aware
    if {$COLOR_AWARE_PLACEMENT == "true"} {
        setPlaceMode -place_detail_color_aware_legal true
        puts "  Color-aware placement: ENABLED"
    }
    
    # Clock-related
    if {$CLOCK_GATE_AWARE == "true"} {
        setOptMode -clockGateAware true
        puts "  Clock gate aware: ENABLED"
    }
    
    if {$REGISTER_CLUSTERING == "true"} {
        setPlaceMode -place_global_clock_gate_aware true
    }
    
    # Preserve user constraints
    if {$PRESERVE_USER_INST == "true"} {
        setPlaceMode -place_global_ignore_fixed_cells false
    }
    
    if {$HONOR_DONT_TOUCH == "true"} {
        setDontTouch [get_cells -hier *] false
        setOptMode -honorDontTouch true
    }
    
    if {$HONOR_DONT_USE == "true"} {
        setOptMode -honorDontUse true
    }
    
    # Concurrent optimization
    if {$CONCURRENT_MACROS == "true"} {
        setPlaceMode -concurrent_macros true
    }
    
    # Multi-threading
    if {$ENABLE_MULTI_THREADING == "true"} {
        setMultiCpuUsage -localCpu $NUM_THREADS
        setDistributeHost -local
        puts "  Multi-threading: ENABLED ($NUM_THREADS threads)"
    }
    
    # Area recovery
    if {$AREA_RECOVERY == "true"} {
        setOptMode -areaReclaim true
    }
    
    # Cell symmetry
    if {$RESPECT_SYMMETRY == "true"} {
        setPlaceMode -place_detail_respect_symmetry true
    }
    
    # Runtime limit
    if {$RUNTIME_LIMIT > 0} {
        setPlaceMode -place_global_max_time [expr $RUNTIME_LIMIT * 60]
    }
    
    # Net weight priority
    switch $NET_WEIGHT_PRIORITY {
        "timing" {
            setPathGroupWeight -group default -weight 10.0
            puts "  Net weight priority: TIMING"
        }
        "congestion" {
            setPlaceMode -place_global_cong_effort high
            puts "  Net weight priority: CONGESTION"
        }
        "power" {
            setOptMode -optimizePowerForSetup true
            puts "  Net weight priority: POWER"
        }
        "balanced" {
            puts "  Net weight priority: BALANCED"
        }
    }
    
    # Additional detail placement settings
    setPlaceMode -place_detail_legalization_inst_gap 1
    setPlaceMode -place_detail_check_cut_spacing true
    setPlaceMode -place_detail_prealigned_inst_boxed_out true
    
    # IO pin placement (usually already done)
    setPlaceMode -place_global_place_io_pins false
    
    puts "Placement configuration completed.\n"
}

#------------------------------------------------------------------------------
# Main Placement Flow
#------------------------------------------------------------------------------
proc run_placement {max_density} {
    puts "\n--- Running Placement ---"
    
    # Set target density
    setDesignMode -targetDensity [expr 1.0 - $max_density]
    
    # Initial in-place optimization (optional, if timing exists)
    if {[dbGet top.numDelayCalcs] > 0} {
        puts "Running pre-placement optimization..."
        setOptMode -addInst true -addInstancePrefix PREPLACE_
        optDesign -preCTS
    }
    
    # Run standard cell placement
    puts "Running place_design..."
    place_design -concurrent_macros
    
    # Check placement status
    checkPlace [dbGet top.name].checkPlace
    
    puts "Placement completed."
}

#------------------------------------------------------------------------------
# Post-Placement Optimization
#------------------------------------------------------------------------------
proc post_placement_optimization {} {
    puts "\n--- Post-Placement Optimization ---"
    
    # Refine placement
    puts "Refining placement..."
    refinePlace -preserveRouting false
    
    # Add filler cells will be done later, but can add end caps now
    # addEndCap -preCap ENDCAP -postCap ENDCAP -prefix ENDCAP
    
    # Optimize placement for better timing if timing exists
    if {[dbGet top.numDelayCalcs] > 0} {
        puts "Running post-placement timing optimization..."
        setOptMode -addInst true -addInstancePrefix POSTPLACE_
        setOptMode -fixDrc true -fixFanoutLoad true
        optDesign -postCTS -setup -hold
    }
    
    # Final legalization check
    puts "Checking placement legality..."
    checkPlace [dbGet top.name].checkPlace.final
    
    puts "Post-placement optimization completed."
}

#------------------------------------------------------------------------------
# Placement Quality Checks
#------------------------------------------------------------------------------
proc check_placement_quality {} {
    puts "\n--- Placement Quality Analysis ---"
    
    # Check placement legality
    puts "\nChecking legality..."
    checkPlace [dbGet top.name].legality
    
    # Report placement statistics
    puts "\nPlacement Statistics:"
    puts "  Total Instances: [dbGet top.numInsts]"
    puts "  Placed Instances: [llength [dbGet top.insts.pStatus placed -p]]"
    puts "  Fixed Instances: [llength [dbGet top.insts.pStatus fixed -p]]"
    puts "  Unplaced Instances: [llength [dbGet top.insts.pStatus unplaced -p]]"
    
    set core_area [expr {[dbGet top.fPlan.coreBox_area] / 1000000.0}]
    set cell_area [expr {[dbGet top.stdCellArea] / 1000000.0}]
    set utilization [expr {($cell_area / $core_area) * 100.0}]
    puts "  Core Area: [format "%.2f" $core_area] um^2"
    puts "  Cell Area: [format "%.2f" $cell_area] um^2"
    puts "  Utilization: [format "%.2f" $utilization]%"
    
    # Report timing if available
    if {[dbGet top.numDelayCalcs] > 0} {
        puts "\nTiming Summary:"
        reportTiming -nworst 10 -format {slack net cell fanout load delay arrival}
        reportConstraint -allViolators
    }
    
    # Report congestion
    puts "\nCongestion Analysis:"
    reportCongestion -overflow
    
    # Report power
    puts "\nPower Summary:"
    report_power -outfile reports/placement_power.rpt
    
    puts "\nQuality checks completed."
}

#------------------------------------------------------------------------------
# Save Placement Results
#------------------------------------------------------------------------------
proc save_placement {design_name} {
    puts "\n--- Saving Placement Results ---"
    
    # Create reports directory
    set report_dir "reports/placement"
    file mkdir $report_dir
    
    # Save design database
    saveDesign ${design_name}_placed.enc -compress
    
    # Write DEF
    defOut -floorplan -netlist -routing ${design_name}_placed.def
    
    # Write Verilog
    saveNetlist ${design_name}_placed.v -excludeLeafCell
    
    # Generate detailed reports
    report_timing -nworst 100 > ${report_dir}/timing.rpt
    report_power > ${report_dir}/power.rpt
    reportCongestion -overflow > ${report_dir}/congestion.rpt
    reportWire > ${report_dir}/wire_length.rpt
    summaryReport -outfile ${report_dir}/summary.rpt
    
    # Generate placement image
    gui_hide -all
    fit
    saveImage -format png -file ${report_dir}/placement_view.png
    
    puts "Placement results saved to: ${design_name}_placed.enc"
    puts "Reports saved to: $report_dir"
}

#------------------------------------------------------------------------------
# Main Execution
#------------------------------------------------------------------------------
proc main {} {
    global DESIGN_NAME PLACEMENT_EFFORT TIMING_DRIVEN CONGESTION_DRIVEN
    global MAX_DENSITY CORE_UTILIZATION
    
    # Start timing
    set start_time [clock seconds]
    
    # Check prerequisites
    if {![check_prerequisites]} {
        puts "ERROR: Prerequisites not met. Exiting."
        return
    }
    
    # Pre-placement setup
    pre_placement_setup
    
    # Configure placement
    configure_placement $PLACEMENT_EFFORT $TIMING_DRIVEN $CONGESTION_DRIVEN
    
    # Run placement
    run_placement $MAX_DENSITY
    
    # Post-placement optimization
    post_placement_optimization
    
    # Quality checks
    check_placement_quality
    
    # Save results
    save_placement $DESIGN_NAME
    
    # Report runtime
    set end_time [clock seconds]
    set runtime [expr $end_time - $start_time]
    puts "\n=========================================="
    puts "Placement Flow Completed Successfully"
    puts "Runtime: [expr $runtime/60] minutes"
    puts "=========================================="
}

# Execute main flow
main
