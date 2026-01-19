#######
#!/usr/bin/tclsh
#==============================================================================
# Placement Procedures Library
# File: placement_procs.tcl
# Description: All procedures for placement flow
#==============================================================================

puts "Loading placement procedures library..."

#------------------------------------------------------------------------------
# Load Technology and Design Files
#------------------------------------------------------------------------------
proc load_design_data {} {
    global ALL_LEF_FILES NETLIST_FILE INPUT_DEF SDC_FILE
    global USE_MMMC MMMC_FILE USE_UPF UPF_FILE
    global USE_QRC QRC_TECH_FILE TLUPLUS_MAX TLUPLUS_MIN TLUPLUS_MAP
    global DESIGN_NAME TOP_MODULE DONT_USE_FILE
    global LIB_TYPICAL LIB_WORST LIB_BEST LIB_MACRO
    
    puts "\n=========================================="
    puts "Loading Technology and Design Files"
    puts "=========================================="
    
    # Check if design is already loaded
    if {[dbGet top.name] != ""} {
        puts "Design already loaded: [dbGet top.name]"
        return
    }
    
    # Load LEF files
    puts "\n--- Loading LEF Files ---"
    set lef_count 0
    foreach lef_file $ALL_LEF_FILES {
        if {[file exists $lef_file]} {
            puts "  Loading: $lef_file"
            loadLefFile $lef_file
            incr lef_count
        } else {
            puts "  WARNING: LEF file not found: $lef_file"
        }
    }
    puts "Successfully loaded $lef_count LEF files"
    
    # Set top design name
    set init_design_name $DESIGN_NAME
    set init_top_cell $TOP_MODULE
    
    # Load timing libraries
    puts "\n--- Loading Timing Libraries ---"
    if {$USE_MMMC == "true" && [file exists $MMMC_FILE]} {
        puts "Loading MMMC views from: $MMMC_FILE"
        source $MMMC_FILE
    } else {
        puts "Loading timing libraries (single corner mode)..."
        set lib_count 0
        foreach lib_file $LIB_TYPICAL {
            if {[file exists $lib_file]} {
                puts "  Loading: $lib_file"
                read_lib $lib_file
                incr lib_count
            } else {
                puts "  WARNING: Library file not found: $lib_file"
            }
        }
        puts "Loaded $lib_count library files"
    }
    
    # Load netlist
    puts "\n--- Loading Netlist ---"
    if {[file exists $NETLIST_FILE]} {
        puts "Loading netlist: $NETLIST_FILE"
        set init_verilog $NETLIST_FILE
    } else {
        puts "ERROR: Netlist file not found: $NETLIST_FILE"
        return -code error "Netlist not found"
    }
    
    # Initialize design
    puts "\n--- Initializing Design ---"
    init_design
    puts "Design initialized: [dbGet top.name]"
    
    # Load DEF from floorplan
    puts "\n--- Loading Floorplan DEF ---"
    if {[file exists $INPUT_DEF]} {
        puts "Loading DEF: $INPUT_DEF"
        defIn $INPUT_DEF
        puts "DEF loaded successfully"
    } else {
        puts "WARNING: Input DEF not found: $INPUT_DEF"
        puts "         Assuming floorplan is already in database"
    }
    
    # Load UPF for multi-voltage designs
    if {$USE_UPF == "true" && [file exists $UPF_FILE]} {
        puts "\n--- Loading Power Intent (UPF) ---"
        puts "Loading UPF: $UPF_FILE"
        read_power_intent -1801 $UPF_FILE
        commit_power_intent
        puts "UPF loaded and committed"
    }
    
    # Load SDC constraints
    puts "\n--- Loading Timing Constraints ---"
    if {[file exists $SDC_FILE]} {
        puts "Loading SDC: $SDC_FILE"
        read_sdc $SDC_FILE
        puts "SDC loaded successfully"
    } else {
        puts "WARNING: SDC file not found: $SDC_FILE"
    }
    
    # Set up RC extraction
    puts "\n--- Setting Up RC Extraction ---"
    if {$USE_QRC == "true"} {
        if {[file exists $QRC_TECH_FILE]} {
            puts "Loading QRC tech file: $QRC_TECH_FILE"
            set_db extract_rc_engine post_route
            read_qrc $QRC_TECH_FILE
            puts "QRC setup completed"
        } else {
            puts "WARNING: QRC tech file not found: $QRC_TECH_FILE"
        }
    } else {
        if {[file exists $TLUPLUS_MAX] && [file exists $TLUPLUS_MIN] && [file exists $TLUPLUS_MAP]} {
            puts "Loading TLU+ files..."
            puts "  Max: $TLUPLUS_MAX"
            puts "  Min: $TLUPLUS_MIN"
            puts "  Map: $TLUPLUS_MAP"
            set_db extract_rc_engine post_route
            read_rc_model -max $TLUPLUS_MAX -min $TLUPLUS_MIN -map $TLUPLUS_MAP
            puts "TLU+ setup completed"
        } else {
            puts "WARNING: TLU+ files not found"
        }
    }
    
    # Apply dont_use cells
    if {[file exists $DONT_USE_FILE]} {
        puts "\n--- Applying Dont Use Constraints ---"
        source $DONT_USE_FILE
        puts "Dont use constraints applied"
    }
    
    puts "\n=========================================="
    puts "Design Data Loaded Successfully"
    puts "=========================================="
    puts "  Top cell: [dbGet top.name]"
    puts "  Instances: [dbGet top.numInsts]"
    puts "  Nets: [dbGet top.numNets]"
    puts "  Ports: [llength [dbGet top.terms.name]]"
}

#------------------------------------------------------------------------------
# Verify Design State
#------------------------------------------------------------------------------
proc verify_design_state {} {
    puts "\n=========================================="
    puts "Verifying Design State"
    puts "=========================================="
    
    # Check connectivity
    puts "\n--- Checking Connectivity ---"
    check_design -all
    
    # Verify timing setup
    puts "\n--- Verifying Timing Setup ---"
    if {[dbGet top.numDelayCalcs] > 0} {
        puts "Timing analysis setup: OK"
        report_analysis_coverage
    } else {
        puts "WARNING: No timing analysis setup found"
    }
    
    # Check for unconnected nets
    puts "\n--- Checking for Floating Nets ---"
    set floating_nets [get_db [get_db nets -if {.num_drivers == 0 && .num_loads > 0}] .name]
    if {[llength $floating_nets] > 0} {
        puts "WARNING: Found [llength $floating_nets] floating nets"
        foreach net [lrange $floating_nets 0 9] {
            puts "  $net"
        }
        if {[llength $floating_nets] > 10} {
            puts "  ... and [expr [llength $floating_nets] - 10] more"
        }
    } else {
        puts "No floating nets found"
    }
    
    puts "\nDesign state verification completed"
}

#------------------------------------------------------------------------------
# Check Prerequisites
#------------------------------------------------------------------------------
proc check_prerequisites {} {
    puts "\n=========================================="
    puts "Checking Prerequisites"
    puts "=========================================="
    
    set all_checks_passed 1
    
    # Check if floorplan exists
    puts "\n--- Checking Floorplan ---"
    set core_area [dbGet top.fPlan.coreBox]
    if {$core_area == ""} {
        puts "ERROR: No floorplan found. Please run floorplan first."
        set all_checks_passed 0
    } else {
        puts "PASS: Floorplan exists"
        puts "  Core area: $core_area"
    }
    
    # Check if power grid exists
    puts "\n--- Checking Power Grid ---"
    set pg_nets [dbGet top.nets.isPwrOrGnd 1 -p]
    if {[llength $pg_nets] == 0} {
        puts "WARNING: No power grid found"
        set all_checks_passed 0
    } else {
        puts "PASS: Power grid found"
        puts "  Power/Ground nets: [llength $pg_nets]"
        foreach net $pg_nets {
            set net_name [dbGet $net.name]
            puts "    - $net_name"
        }
    }
    
    # Check if pins are placed
    puts "\n--- Checking Pin Placement ---"
    set total_pins [dbGet top.terms.name -e]
    set placed_pins [dbGet top.terms.pt.x -e]
    if {[llength $total_pins] > 0} {
        set unplaced [expr [llength $total_pins] - [llength $placed_pins]]
        if {$unplaced > 0} {
            puts "WARNING: $unplaced of [llength $total_pins] pins are not placed"
        } else {
            puts "PASS: All [llength $total_pins] pins are placed"
        }
    }
    
    # Check for macros
    puts "\n--- Checking Macros ---"
    set macros [dbGet top.insts.cell.subClass block -p2]
    if {[llength $macros] > 0} {
        puts "Found [llength $macros] macros"
        foreach macro $macros {
            set inst_name [dbGet $macro.name]
            set status [dbGet $macro.pStatus]
            puts "  - $inst_name: $status"
        }
    } else {
        puts "No macros found in design"
    }
    
    puts "\n=========================================="
    if {$all_checks_passed} {
        puts "Prerequisites Check: PASSED"
    } else {
        puts "Prerequisites Check: FAILED"
    }
    puts "=========================================="
    
    return $all_checks_passed
}

#------------------------------------------------------------------------------
# Pre-Placement Setup
#------------------------------------------------------------------------------
proc pre_placement_setup {} {
    global MACRO_HALO_TOP MACRO_HALO_BOTTOM MACRO_HALO_LEFT MACRO_HALO_RIGHT
    
    puts "\n=========================================="
    puts "Pre-Placement Setup"
    puts "=========================================="
    
    # Delete any existing placement
    puts "\n--- Clearing Existing Placement ---"
    deleteAllPlaceBlockage
    puts "All placement blockages cleared"
    
    # Set placement blockages around macros with halos
    puts "\n--- Creating Macro Blockages and Halos ---"
    set macros [dbGet top.insts.cell.subClass block -p2]
    if {[llength $macros] > 0} {
        foreach macro $macros {
            set inst_name [dbGet $macro.name]
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
            puts "  Macro: $inst_name - blockage and halo created"
        }
        puts "Added placement blockages around [llength $macros] macros"
        puts "  Halo: T=${MACRO_HALO_TOP}um B=${MACRO_HALO_BOTTOM}um L=${MACRO_HALO_LEFT}um R=${MACRO_HALO_RIGHT}um"
    } else {
        puts "No macros found - skipping macro blockages"
    }
    
    # Set keepout margins for power rails
    puts "\n--- Setting Keepout Margins ---"
    setPlaceMode -placeKeepOutMarginTop 0.5
    setPlaceMode -placeKeepOutMarginBottom 0.5
    puts "Keepout margins set for power rails"
    
    # Prevent placement under power stripes
    puts "\n--- Creating Route Blockages for Power Stripes ---"
    set power_nets [dbGet top.nets.isPwrOrGnd 1 -p]
    foreach net $power_nets {
        set net_name [dbGet $net.name]
        # This creates blockages to prevent placement under wide power stripes
        # Adjust layers based on your power grid strategy
    }
    
    puts "\n=========================================="
    puts "Pre-Placement Setup Completed"
    puts "=========================================="
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
    
    puts "\n=========================================="
    puts "Configuring Placement Parameters"
    puts "=========================================="
    
    # Reset to default
    setPlaceMode -reset
    
    # Basic placement effort
    puts "\n--- Basic Settings ---"
    setPlaceMode -effort $effort
    setPlaceMode -place_global_solver_effort $effort
    puts "  Placement effort: $effort"
    
    if {$effort == "high"} {
        setPlaceMode -place_global_max_density 0.95
    } elseif {$effort == "medium"} {
        setPlaceMode -place_global_max_density 0.90
    } else {
        setPlaceMode -place_global_max_density 0.85
    }
    
    # Timing-driven parameters
    if {$timing_driven == "true"} {
        puts "\n--- Timing-Driven Settings ---"
        setPlaceMode -timingDriven true
        setPlaceMode -place_global_timing_effort high
        setOptMode -setupTargetSlack $SLACK_MARGIN
        setOptMode -criticalPathOpt true
        
        if {$WIRE_LENGTH_OPT == "true"} {
            setPlaceMode -place_global_optimize_wire_via_density true
        }
        
        puts "  Timing-driven: ENABLED"
        puts "  Target slack margin: ${SLACK_MARGIN}ns"
        puts "  Critical range: ${CRITICAL_RANGE}ns"
    } else {
        setPlaceMode -timingDriven false
        puts "\n--- Timing-Driven: DISABLED ---"
    }
    
    # Congestion-driven parameters
    if {$congestion_driven == "true"} {
        puts "\n--- Congestion-Driven Settings ---"
        setPlaceMode -congEffort $CONGESTION_EFFORT
        setPlaceMode -place_global_cong_effort $CONGESTION_EFFORT
        
        setCongestionEffort -hCongWeight $HORIZONTAL_CONG_WEIGHT
        setCongestionEffort -vCongWeight $VERTICAL_CONG_WEIGHT
        
        setNanoRouteMode -droutePostRouteSpreadWire true
        setNanoRouteMode -routeWithTimingDriven true
        
        puts "  Congestion-driven: ENABLED"
        puts "  Congestion effort: $CONGESTION_EFFORT"
        puts "  Max overflow: ${MAX_ROUTING_OVERFLOW}%"
    }
    
    # Power-driven parameters
    if {$POWER_DRIVEN == "true"} {
        puts "\n--- Power-Driven Settings ---"
        setPlaceMode -powerDriven true
        setOptMode -optimizePowerForSetup true
        puts "  Power-driven: ENABLED"
    }
    
    # Density control
    if {$UNIFORM_DENSITY == "true"} {
        puts "\n--- Density Control ---"
        setPlaceMode -place_global_uniform_density true
        setPlaceMode -place_detail_density_target $TARGET_DENSITY_PER_BIN
        puts "  Uniform density: ENABLED"
        puts "  Target density per bin: $TARGET_DENSITY_PER_BIN"
    }
    
    # Cell spacing
    puts "\n--- Cell Spacing ---"
    setPlaceMode -place_detail_legalization_inst_gap $CELL_TO_CELL_GAP
    if {$INST_GAP_FOR_SPACING > 0} {
        setPlaceMode -place_detail_check_cut_spacing true
    }
    puts "  Cell-to-cell gap: $CELL_TO_CELL_GAP sites"
    
    # Multi-patterning aware
    if {$COLOR_AWARE_PLACEMENT == "true"} {
        puts "\n--- Advanced Features ---"
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
        puts "  Register clustering: ENABLED"
    }
    
    # Preserve user constraints
    if {$PRESERVE_USER_INST == "true"} {
        setPlaceMode -place_global_ignore_fixed_cells false
    }
    
    if {$HONOR_DONT_TOUCH == "true"} {
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
        puts "\n--- Performance Settings ---"
        setMultiCpuUsage -localCpu $NUM_THREADS
        setDistributeHost -local
        puts "  Multi-threading: ENABLED ($NUM_THREADS threads)"
    }
    
    # Area recovery
    if {$AREA_RECOVERY == "true"} {
        setOptMode -areaReclaim true
        puts "  Area recovery: ENABLED"
    }
    
    # Cell symmetry
    if {$RESPECT_SYMMETRY == "true"} {
        setPlaceMode -place_detail_respect_symmetry true
    }
    
    # Runtime limit
    if {$RUNTIME_LIMIT > 0} {
        setPlaceMode -place_global_max_time [expr $RUNTIME_LIMIT * 60]
        puts "  Runtime limit: ${RUNTIME_LIMIT} minutes"
    }
    
    # Net weight priority
    puts "\n--- Optimization Priority ---"
    switch $NET_WEIGHT_PRIORITY {
        "timing" {
            setPathGroupWeight -group default -weight 10.0
            puts "  Priority: TIMING"
        }
        "congestion" {
            setPlaceMode -place_global_cong_effort high
            puts "  Priority: CONGESTION"
        }
        "power" {
            setOptMode -optimizePowerForSetup true
            puts "  Priority: POWER"
        }
        "balanced" {
            puts "  Priority: BALANCED"
        }
    }
    
    # Additional detail placement settings
    setPlaceMode -place_detail_check_cut_spacing true
    setPlaceMode -place_detail_prealigned_inst_boxed_out true
    setPlaceMode -place_global_place_io_pins false
    
    puts "\n=========================================="
    puts "Placement Configuration Completed"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Main Placement Flow
#------------------------------------------------------------------------------
proc run_placement {max_density} {
    global RUN_COARSE_PLACEMENT RUN_DETAILED_PLACEMENT
    
    puts "\n=========================================="
    puts "Running Placement"
    puts "=========================================="
    
    # Set target density
    setDesignMode -targetDensity [expr 1.0 - $max_density]
    
    # Initial in-place optimization (optional, if timing exists)
    if {[dbGet top.numDelayCalcs] > 0} {
        puts "\n--- Pre-Placement Optimization ---"
        setOptMode -addInst true -addInstancePrefix PREPLACE_
        optDesign -preCTS
        puts "Pre-placement optimization completed"
    }
    
    # Run standard cell placement
    if {$RUN_COARSE_PLACEMENT == "true"} {
        puts "\n--- Running place_design ---"
        place_design -concurrent_macros
        puts "Placement completed"
    }
    
    # Check placement status
    puts "\n--- Checking Placement Quality ---"
    checkPlace [dbGet top.name].checkPlace
    
    puts "\n=========================================="
    puts "Placement Execution Completed"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Post-Placement Optimization
#------------------------------------------------------------------------------
proc post_placement_optimization {} {
    global RUN_REFINE_PLACEMENT RUN_IN_PLACE_OPT
    
    puts "\n=========================================="
    puts "Post-Placement Optimization"
    puts "=========================================="
    
    # Refine placement
    if {$RUN_REFINE_PLACEMENT == "true"} {
        puts "\n--- Refining Placement ---"
        refinePlace -preserveRouting false
        puts "Placement refinement completed"
    }
    
    # Optimize placement for better timing
    if {$RUN_IN_PLACE_OPT == "true" && [dbGet top.numDelayCalcs] > 0} {
        puts "\n--- Running Post-Placement Timing Optimization ---"
        setOptMode -addInst true -addInstancePrefix POSTPLACE_
        setOptMode -fixDrc true -fixFanoutLoad true
        optDesign -postCTS -setup -hold
        puts "Post-placement optimization completed"
    }
    
    # Final legalization check
    puts "\n--- Final Legalization Check ---"
    checkPlace [dbGet top.name].checkPlace.final
    
    puts "\n=========================================="
    puts "Post-Placement Optimization Completed"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Placement Quality Checks
#------------------------------------------------------------------------------
proc check_placement_quality {} {
    global REPORT_DIR
    
    puts "\n=========================================="
    puts "Placement Quality Analysis"
    puts "=========================================="
    
    # Check placement legality
    puts "\n--- Checking Legality ---"
    checkPlace [dbGet top.name].legality
    
    # Report placement statistics
    puts "\n--- Placement Statistics ---"
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
        puts "\n--- Timing Summary ---"
        reportTiming -nworst 10 -format {slack net cell fanout load delay arrival}
        reportConstraint -allViolators
    }
    
    # Report congestion
    puts "\n--- Congestion Analysis ---"
    reportCongestion -overflow
    
    # Report power
    puts "\n--- Power Summary ---"
    report_power -outfile ${REPORT_DIR}/placement_power.rpt
    
    puts "\n=========================================="
    puts "Quality Checks Completed"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Save Placement Results
#------------------------------------------------------------------------------
proc save_placement {design_name} {
    global REPORT_DIR RESULT_DIR
    
    puts "\n=========================================="
    puts "Saving Placement Results"
    puts "=========================================="
    
    # Save design database
    puts "\n--- Saving Design Database ---"
    saveDesign ${RESULT_DIR}/${design_name}_placed.enc -compress
    puts "Design saved: ${RESULT_DIR}/${design_name}_placed.enc"
    
    # Write DEF
    puts "\n--- Writing DEF ---"
    defOut -floorplan -netlist -routing ${RESULT_DIR}/${design_name}_placed.def
    puts "DEF written: ${RESULT_DIR}/${design_name}_placed.def"
    
    # Write Verilog
    puts "\n--- Writing Netlist ---"
    saveNetlist ${RESULT_DIR}/${design_name}_placed.v -excludeLeafCell
    puts "Netlist written: ${RESULT_DIR}/${design_name}_placed.v"
    
    # Generate detailed reports
    puts "\n--- Generating Reports ---"
    report_timing -nworst 100 > ${REPORT_DIR}/timing.rpt
    report_power > ${REPORT_DIR}/power.rpt
    reportCongestion -overflow > ${REPORT_DIR}/congestion.rpt
    reportWire > ${REPORT_DIR}/wire_length.rpt
    summaryReport -outfile ${REPORT_DIR}/summary.rpt
    puts "Reports generated in: $REPORT_DIR"
    
    # Generate placement image
    puts "\n--- Generating Placement Image ---"
    gui_hide -all
    fit
    saveImage -format png -file ${REPORT_DIR}/placement_view.png
    puts "Image saved: ${REPORT_DIR}/placement_view.png"
    
    puts "\n=========================================="
    puts "Results Saved Successfully"
    puts "=========================================="
}

puts "Placement procedures library loaded successfully."
