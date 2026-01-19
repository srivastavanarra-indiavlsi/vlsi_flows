################################################################################
# routing_procs.tcl
# Procedure definitions for routing stage
################################################################################

################################################################################
# Procedure: setup_routing_options
# Description: Configure routing options and settings (16nm/7nm/5nm compatible)
################################################################################
proc setup_routing_options {} {
    global ROUTE_EFFORT ROUTE_DETAIL_EFFORT TECH_NODE
    global ROUTING_LAYER_MIN ROUTING_LAYER_MAX
    global SIGNAL_LAYER_MIN SIGNAL_LAYER_MAX
    global SI_AWARE_ROUTING CROSSTALK_ANALYSIS
    global NUM_CORES MIN_ROUTING_PITCH
    global LITHO_DRIVEN_ROUTING ENABLE_COLORING_CHECK
    
    puts "INFO: Setting up routing options for ${TECH_NODE}..."
    
    # Set routing layers
    setDesignMode -process $TECH_NODE
    setNanoRouteMode -routeTopRoutingLayer $ROUTING_LAYER_MAX
    setNanoRouteMode -routeBottomRoutingLayer $ROUTING_LAYER_MIN
    setNanoRouteMode -routeWithSiDriven $SI_AWARE_ROUTING
    setNanoRouteMode -routeWithTimingDriven true
    
    # Technology-specific settings
    if {$TECH_NODE == "16nm"} {
        setNanoRouteMode -routeWithLithoDriven false
        setNanoRouteMode -drouteMinSlackForWireOptimization 0.1
        
    } elseif {$TECH_NODE == "7nm"} {
        setNanoRouteMode -routeWithLithoDriven $LITHO_DRIVEN_ROUTING
        setNanoRouteMode -drouteMinSlackForWireOptimization 0.08
        if {[info exists ENABLE_COLORING_CHECK] && $ENABLE_COLORING_CHECK} {
            setNanoRouteMode -routeWithViaInPinUseLef58 true
            setNanoRouteMode -routeWithViaOnlyForStandardCell false
        }
        
    } elseif {$TECH_NODE == "5nm"} {
        setNanoRouteMode -routeWithLithoDriven $LITHO_DRIVEN_ROUTING
        setNanoRouteMode -drouteMinSlackForWireOptimization 0.06
        if {[info exists ENABLE_COLORING_CHECK] && $ENABLE_COLORING_CHECK} {
            setNanoRouteMode -routeWithViaInPinUseLef58 true
            setNanoRouteMode -routeWithViaOnlyForStandardCell false
        }
        if {[info exists ENABLE_EUV_CHECKS] && $ENABLE_EUV_CHECKS} {
            setNanoRouteMode -drouteUseMultiCutViaEffort high
            setNanoRouteMode -drouteMinAreaViaEffort high
        }
    }
    
    # Detail route settings
    setNanoRouteMode -drouteAutoStop false
    setNanoRouteMode -drouteEndIteration $::ROUTE_NANO_ITERATIONS
    setNanoRouteMode -routeInsertAntennaDiode true
    
    # SI settings
    if {$SI_AWARE_ROUTING} {
        setNanoRouteMode -drouteUseCrosstalkInfo true
        setNanoRouteMode -siDriveThreshold $::CROSSTALK_NET_THRESHOLD
        
        if {$TECH_NODE == "7nm" || $TECH_NODE == "5nm"} {
            setNanoRouteMode -siEffort $::SI_ANALYSIS_EFFORT
        }
    }
    
    # Multi-threading
    setMultiCpuUsage -localCpu $NUM_CORES
    setDistributeHost -local
    
    if {$::DISTRIBUTED_ROUTING && [info exists ::DISTRIBUTED_HOSTS] && $::DISTRIBUTED_HOSTS != ""} {
        setDistributeHost -host $::DISTRIBUTED_HOSTS
    }
    
    # Via settings - technology dependent
    setNanoRouteMode -drouteFixAntenna true
    setNanoRouteMode -drouteUseMultiCutViaEffort $::VIA_OPT_EFFORT
    
    if {[info exists ::MULTI_CUT_VIA_EFFORT]} {
        setNanoRouteMode -drouteUseMultiCutViaEffort $::MULTI_CUT_VIA_EFFORT
    }
    
    # Timing settings
    setNanoRouteMode -routeStrictlyHonorNonDefaultRule true
    setNanoRouteMode -routeWithEco true
    
    # Advanced settings for 7nm/5nm
    if {$TECH_NODE == "7nm" || $TECH_NODE == "5nm"} {
        if {[info exists ::ENABLE_AOCV] && $::ENABLE_AOCV} {
            setAnalysisMode -cppr both
            setAnalysisMode -onChipVariation true
        }
    }
    
    # 5nm specific
    if {$TECH_NODE == "5nm"} {
        if {[info exists ::ENABLE_POCV] && $::ENABLE_POCV} {
            setAnalysisMode -checkType setup -analysisType ocv
        }
        if {[info exists ::VIA_STACK_OPTIMIZATION] && $::VIA_STACK_OPTIMIZATION} {
            setNanoRouteMode -drouteViaStackOpt true
        }
    }
    
    puts "INFO: Routing options configured successfully for ${TECH_NODE}."
}

################################################################################
# Procedure: pre_route_checks
# Description: Perform pre-route sanity checks
################################################################################
proc pre_route_checks {} {
    puts "INFO: Running pre-route checks..."
    
    # Check design status
    if {[dbGet top.numInsts] == 0} {
        puts "ERROR: No instances found in design!"
        return -code error
    }
    
    # Check clock tree
    set cts_buffers [dbGet [dbGet top.insts.cell.baseClass block -p2].name]
    if {[llength $cts_buffers] == 0} {
        puts "WARNING: No CTS buffers found. Is CTS completed?"
    } else {
        puts "INFO: Found [llength $cts_buffers] CTS buffers."
    }
    
    # Verify special routes
    set pg_nets [get_db nets -if {.is_power||.is_ground}]
    puts "INFO: Found [llength $pg_nets] power/ground nets."
    
    # Check unplaced cells
    set unplaced [get_db insts -if {.location_x==0&&.location_y==0}]
    if {[llength $unplaced] > 0} {
        puts "WARNING: Found [llength $unplaced] unplaced instances!"
    }
    
    # Check timing
    set wns [get_db timing_analysis_type:late timing_library_set:* slack -max]
    set tns [get_db timing_analysis_type:late timing_library_set:* slack -sum]
    puts "INFO: Pre-route timing - WNS: $wns, TNS: $tns"
    
    puts "INFO: Pre-route checks completed."
    return 0
}

################################################################################
# Procedure: run_global_route
# Description: Execute global routing
################################################################################
proc run_global_route {} {
    global DESIGN_NAME REPORTS_DIR
    
    puts "INFO: Starting global route..."
    
    # Set global route options
    setNanoRouteMode -quiet -routeWithSiPostRouteFix false
    setNanoRouteMode -quiet -droutePostRouteSwapVia false
    
    # Run global routing
    globalDetailRoute
    
    # Check results
    set total_overflows [dbGet top.fPlan.overflows]
    puts "INFO: Total overflows after global route: $total_overflows"
    
    if {$total_overflows > 1000} {
        puts "WARNING: High overflow count detected!"
    }
    
    # Generate report
    summaryReport -noHtml -outfile ${REPORTS_DIR}/${DESIGN_NAME}_groute.rpt
    
    puts "INFO: Global route completed."
}

################################################################################
# Procedure: run_track_assignment
# Description: Execute track assignment
################################################################################
proc run_track_assignment {} {
    puts "INFO: Running track assignment..."
    
    # Configure track assignment
    setNanoRouteMode -drouteUseMinSpacingForBlockage true
    setNanoRouteMode -drouteOnGridOnly none
    
    # Run track assignment
    routeDesign -globalDetail
    
    puts "INFO: Track assignment completed."
}

################################################################################
# Procedure: run_detail_route
# Description: Execute detailed routing
################################################################################
proc run_detail_route {} {
    global DESIGN_NAME REPORTS_DIR ROUTE_DETAIL_EFFORT
    
    puts "INFO: Starting detail route..."
    
    # Detail route with timing
    routeDesign -wireOpt
    
    # Check DRC violations
    verify_drc -limit 1000000
    set drc_viols [dbGet top.markers.numMarkers]
    puts "INFO: DRC violations after detail route: $drc_viols"
    
    # Generate route report
    report_route -outfile ${REPORTS_DIR}/${DESIGN_NAME}_route.rpt
    
    puts "INFO: Detail route completed."
}

################################################################################
# Procedure: fix_routing_drc
# Description: Fix routing DRC violations
################################################################################
proc fix_routing_drc {} {
    global MAX_ROUTE_VIOLATIONS ROUTE_ECO_ITERATIONS
    
    puts "INFO: Fixing routing DRC violations..."
    
    set iter 0
    set prev_viols 999999
    
    while {$iter < $ROUTE_ECO_ITERATIONS} {
        incr iter
        puts "INFO: DRC fix iteration $iter..."
        
        # Run ECO route
        ecoRoute -fix_drc
        
        # Check violations
        verify_drc
        set curr_viols [dbGet top.markers.numMarkers]
        
        puts "INFO: DRC violations: $curr_viols"
        
        if {$curr_viols <= $MAX_ROUTE_VIOLATIONS} {
            puts "INFO: DRC target achieved."
            break
        }
        
        if {$curr_viols >= $prev_viols} {
            puts "WARNING: DRC violations not improving."
            break
        }
        
        set prev_viols $curr_viols
    }
}

################################################################################
# Procedure: optimize_post_route
# Description: Post-route optimization for timing and power
################################################################################
proc optimize_post_route {} {
    global POSTROUTE_OPT_ITERATIONS TARGET_SETUP_SLACK TARGET_HOLD_SLACK
    global DESIGN_NAME REPORTS_DIR
    
    puts "INFO: Starting post-route optimization..."
    
    # Set optimization options
    setOptMode -fixDrc true
    setOptMode -fixFanoutLoad true
    setOptMode -holdTargetSlack $TARGET_HOLD_SLACK
    setOptMode -setupTargetSlack $TARGET_SETUP_SLACK
    setOptMode -reclaimArea $::POSTROUTE_AREA_RECLAIM
    
    # Multiple optimization iterations
    for {set i 1} {$i <= $POSTROUTE_OPT_ITERATIONS} {incr i} {
        puts "INFO: Post-route optimization iteration $i..."
        
        # Optimize for setup
        optDesign -postRoute -setup -outDir ${REPORTS_DIR}/opt_postroute_setup_${i}
        
        # Optimize for hold
        optDesign -postRoute -hold -outDir ${REPORTS_DIR}/opt_postroute_hold_${i}
        
        # Check timing
        timeDesign -postRoute -outDir ${REPORTS_DIR}/time_postroute_${i}
        
        set wns [get_db timing_analysis_type:late slack -max]
        set tns [get_db timing_analysis_type:late slack -sum]
        set whs [get_db timing_analysis_type:early slack -max]
        set ths [get_db timing_analysis_type:early slack -sum]
        
        puts "INFO: Iteration $i - Setup WNS: $wns, TNS: $tns"
        puts "INFO: Iteration $i - Hold WHS: $whs, THS: $ths"
        
        if {$wns > -0.001 && $whs > -0.001} {
            puts "INFO: Timing closure achieved."
            break
        }
    }
    
    puts "INFO: Post-route optimization completed."
}

################################################################################
# Procedure: add_filler_cells
# Description: Add filler cells to complete placement (16nm/7nm/5nm compatible)
################################################################################
proc add_filler_cells {} {
    global FILLER_CELLS DESIGN_NAME TECH_NODE
    global USE_DECAP DECAP_CELLS USE_WELLTIES
    
    puts "INFO: Adding filler cells for ${TECH_NODE}..."
    
    # Delete existing fillers
    deleteFiller -prefix FILLER
    
    # Add standard fillers
    addFiller -cell $FILLER_CELLS -prefix FILLER
    
    set num_fillers [llength [dbGet top.insts.cell.name FILLER* -p]]
    puts "INFO: Added $num_fillers filler cells."
    
    # Add decap cells for 7nm/5nm
    if {[info exists USE_DECAP] && $USE_DECAP} {
        if {[info exists DECAP_CELLS]} {
            puts "INFO: Adding decap cells for ${TECH_NODE}..."
            addFiller -cell $DECAP_CELLS -prefix DECAP
            set num_decaps [llength [dbGet top.insts.cell.name DECAP* -p]]
            puts "INFO: Added $num_decaps decap cells."
        }
    }
    
    # Add well ties for 5nm if needed
    if {[info exists USE_WELLTIES] && $USE_WELLTIES && $TECH_NODE == "5nm"} {
        puts "INFO: Checking well tie requirements for 5nm..."
        # Well tie insertion would be technology library specific
        # addWellTap -cell WELLTIE -cellInterval <distance>
    }
}

################################################################################
# Procedure: verify_connectivity
# Description: Verify design connectivity
################################################################################
proc verify_connectivity {} {
    global DESIGN_NAME REPORTS_DIR
    
    puts "INFO: Verifying connectivity..."
    
    verifyConnectivity -type all -report ${REPORTS_DIR}/${DESIGN_NAME}_connectivity.rpt
    
    set opens [dbGet top.numOpens]
    set shorts [dbGet top.numShorts]
    
    puts "INFO: Opens: $opens, Shorts: $shorts"
    
    if {$opens > 0 || $shorts > 0} {
        puts "ERROR: Connectivity issues detected!"
        return -code error
    }
    
    puts "INFO: Connectivity verification passed."
}

################################################################################
# Procedure: extract_rc
# Description: Extract RC parasitics
################################################################################
proc extract_rc {} {
    global DESIGN_NAME RESULTS_DIR
    
    puts "INFO: Extracting RC parasitics..."
    
    # Set extraction options
    setExtractRCMode -engine postRoute
    setExtractRCMode -effortLevel high
    
    # Extract
    extractRC
    
    # Generate SPEF
    rcOut -spef ${RESULTS_DIR}/${DESIGN_NAME}.spef
    
    puts "INFO: RC extraction completed."
}

################################################################################
# Procedure: generate_route_reports
# Description: Generate comprehensive routing reports with detailed metrics
################################################################################
proc generate_route_reports {} {
    global DESIGN_NAME REPORTS_DIR TECH_NODE
    
    puts "INFO: Generating comprehensive routing reports..."
    
    set rpt_dir ${REPORTS_DIR}/route
    
    #---------------------------------------------------------------------------
    # Timing Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating timing reports..."
    
    # Setup timing
    report_timing -max_paths 100 -nworst 10 -path_type full_clock \
        > ${rpt_dir}/${DESIGN_NAME}_route_timing_setup.rpt
    
    # Hold timing
    report_timing -late -max_paths 100 -nworst 10 \
        > ${rpt_dir}/${DESIGN_NAME}_route_timing_hold.rpt
    
    # All constraints
    report_constraint -all_violators \
        > ${rpt_dir}/${DESIGN_NAME}_route_constraints.rpt
    
    # Path groups summary
    report_timing -path_group **all** -slack_lesser_than 0.0 \
        > ${rpt_dir}/${DESIGN_NAME}_route_timing_violations.rpt
    
    # Clock timing
    report_clock_timing -type skew \
        > ${rpt_dir}/${DESIGN_NAME}_route_clock_skew.rpt
    
    report_clock_timing -type latency \
        > ${rpt_dir}/${DESIGN_NAME}_route_clock_latency.rpt
    
    #---------------------------------------------------------------------------
    # DRC and Geometry Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating DRC and geometry reports..."
    
    # Detailed DRC report
    verify_drc -limit 1000000 -report ${rpt_dir}/${DESIGN_NAME}_route_drc_detailed.rpt
    
    # Geometry verification
    verifyGeometry -noOverlap -noMinArea -report ${rpt_dir}/${DESIGN_NAME}_route_geometry.rpt
    
    # Antenna violations
    verifyProcessAntenna -reportfile ${rpt_dir}/${DESIGN_NAME}_route_antenna.rpt
    
    # Metal density
    verifyMetalDensity -report ${rpt_dir}/${DESIGN_NAME}_route_metal_density.rpt
    
    #---------------------------------------------------------------------------
    # Connectivity Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating connectivity reports..."
    
    verifyConnectivity -type all -noAntenna -noWeakConnect \
        -report ${rpt_dir}/${DESIGN_NAME}_route_connectivity.rpt
    
    # Opens and shorts summary
    set opens [dbGet top.numOpens]
    set shorts [dbGet top.numShorts]
    
    set conn_file [open ${rpt_dir}/${DESIGN_NAME}_route_opens_shorts.rpt w]
    puts $conn_file "=========================================================================="
    puts $conn_file "              CONNECTIVITY SUMMARY"
    puts $conn_file "=========================================================================="
    puts $conn_file "Total Opens:  $opens"
    puts $conn_file "Total Shorts: $shorts"
    puts $conn_file "=========================================================================="
    close $conn_file
    
    #---------------------------------------------------------------------------
    # Physical Design Verification (PDV) Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating PDV reports..."
    
    # Metal fill verification
    verifyMetalFill -report ${rpt_dir}/${DESIGN_NAME}_route_metal_fill.rpt
    
    # Via verification
    verifyVia -report ${rpt_dir}/${DESIGN_NAME}_route_via_check.rpt
    
    # Minimum area violations
    if {$TECH_NODE == "5nm" || $TECH_NODE == "7nm"} {
        verifyGeometry -minArea -report ${rpt_dir}/${DESIGN_NAME}_route_minarea.rpt
    }
    
    #---------------------------------------------------------------------------
    # Area Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating area reports..."
    
    report_area -detail > ${rpt_dir}/${DESIGN_NAME}_route_area_detailed.rpt
    
    set area_file [open ${rpt_dir}/${DESIGN_NAME}_route_area_summary.rpt w]
    puts $area_file "=========================================================================="
    puts $area_file "              AREA SUMMARY"
    puts $area_file "=========================================================================="
    
    set total_area [dbGet top.fPlan.area]
    set core_area [dbGet top.fPlan.coreBox_area]
    set std_cell_area [dbGet [dbGet top.insts.cell.baseClass core -p2].area -sum]
    set macro_area [dbGet [dbGet top.insts.cell.baseClass block -p2].area -sum]
    set utilization [expr ($std_cell_area / $core_area) * 100.0]
    
    puts $area_file [format "Total Die Area:       %.2f um^2" $total_area]
    puts $area_file [format "Core Area:            %.2f um^2" $core_area]
    puts $area_file [format "Standard Cell Area:   %.2f um^2" $std_cell_area]
    puts $area_file [format "Macro Area:           %.2f um^2" $macro_area]
    puts $area_file [format "Core Utilization:     %.2f %%" $utilization]
    
    set num_std_cells [llength [dbGet top.insts.cell.baseClass core -p]]
    set num_macros [llength [dbGet top.insts.cell.baseClass block -p]]
    set num_fillers [llength [dbGet top.insts.cell.name FILLER* -p]]
    
    puts $area_file ""
    puts $area_file "Instance Counts:"
    puts $area_file "  Standard Cells:     $num_std_cells"
    puts $area_file "  Macros/Blocks:      $num_macros"
    puts $area_file "  Filler Cells:       $num_fillers"
    puts $area_file "=========================================================================="
    close $area_file
    
    #---------------------------------------------------------------------------
    # Power Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating power reports..."
    
    report_power -hierarchy all > ${rpt_dir}/${DESIGN_NAME}_route_power_hierarchy.rpt
    report_power -rail_analysis > ${rpt_dir}/${DESIGN_NAME}_route_power_rail.rpt
    
    set power_file [open ${rpt_dir}/${DESIGN_NAME}_route_power_summary.rpt w]
    puts $power_file "=========================================================================="
    puts $power_file "              POWER SUMMARY"
    puts $power_file "=========================================================================="
    
    # Get power analysis results
    set internal_power [dbGet top.internalPower]
    set switching_power [dbGet top.switchingPower]
    set leakage_power [dbGet top.leakagePower]
    set total_power [expr $internal_power + $switching_power + $leakage_power]
    
    puts $power_file [format "Internal Power:    %.6f mW" [expr $internal_power * 1000]]
    puts $power_file [format "Switching Power:   %.6f mW" [expr $switching_power * 1000]]
    puts $power_file [format "Leakage Power:     %.6f mW" [expr $leakage_power * 1000]]
    puts $power_file [format "Total Power:       %.6f mW" [expr $total_power * 1000]]
    puts $power_file ""
    
    # Power by voltage domain
    set vdd_nets [dbGet [dbGet top.nets.isPwrOrGnd 1 -p].name]
    puts $power_file "Power/Ground Nets: [llength $vdd_nets]"
    foreach net $vdd_nets {
        puts $power_file "  - $net"
    }
    puts $power_file "=========================================================================="
    close $power_file
    
    #---------------------------------------------------------------------------
    # Metal Utilization Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating metal utilization reports..."
    
    set metal_file [open ${rpt_dir}/${DESIGN_NAME}_route_metal_util.rpt w]
    puts $metal_file "=========================================================================="
    puts $metal_file "              METAL LAYER UTILIZATION"
    puts $metal_file "=========================================================================="
    puts $metal_file [format "%-10s %10s %10s %10s %10s" "Layer" "Total" "Used" "Util%" "Overflow"]
    puts $metal_file "--------------------------------------------------------------------------"
    
    for {set layer $::ROUTING_LAYER_MIN} {$layer <= $::ROUTING_LAYER_MAX} {incr layer} {
        set layer_name "M$layer"
        
        # Get utilization data
        set total_tracks [dbGet [dbGet head.layers.name $layer_name -p].numTracks]
        set used_tracks [dbGet [dbGet head.layers.name $layer_name -p].numUsedTracks]
        
        if {$total_tracks > 0} {
            set util [expr ($used_tracks * 100.0) / $total_tracks]
        } else {
            set util 0.0
        }
        
        set overflow [dbGet [dbGet head.layers.name $layer_name -p].overflow]
        
        puts $metal_file [format "%-10s %10d %10d %9.2f%% %10d" \
            $layer_name $total_tracks $used_tracks $util $overflow]
    }
    
    puts $metal_file "=========================================================================="
    close $metal_file
    
    #---------------------------------------------------------------------------
    # Track Utilization Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating track utilization reports..."
    
    set track_file [open ${rpt_dir}/${DESIGN_NAME}_route_track_util.rpt w]
    puts $track_file "=========================================================================="
    puts $track_file "              TRACK UTILIZATION SUMMARY"
    puts $track_file "=========================================================================="
    
    # Overall track usage
    summaryReport -noHtml -outfile ${rpt_dir}/${DESIGN_NAME}_route_summary_temp.rpt
    
    # Get routing statistics
    set total_wire_length [dbGet top.numWires]
    set num_vias [dbGet top.numVias]
    
    puts $track_file "Routing Statistics:"
    puts $track_file "  Total Wire Length:  $total_wire_length um"
    puts $track_file "  Total Vias:         $num_vias"
    puts $track_file ""
    
    # Per-layer track utilization
    puts $track_file [format "\n%-10s %15s %15s %10s" "Layer" "Horiz Tracks" "Vert Tracks" "Avg Util%"]
    puts $track_file "--------------------------------------------------------------------------"
    
    for {set layer $::ROUTING_LAYER_MIN} {$layer <= $::ROUTING_LAYER_MAX} {incr layer} {
        set layer_name "M$layer"
        set h_tracks [dbGet [dbGet head.layers.name $layer_name -p].numHorizontalTracks]
        set v_tracks [dbGet [dbGet head.layers.name $layer_name -p].numVerticalTracks]
        set avg_util [dbGet [dbGet head.layers.name $layer_name -p].avgUtilization]
        
        puts $track_file [format "%-10s %15d %15d %9.2f%%" \
            $layer_name $h_tracks $v_tracks $avg_util]
    }
    
    puts $track_file "=========================================================================="
    close $track_file
    
    #---------------------------------------------------------------------------
    # Congestion Reports
    #---------------------------------------------------------------------------
    puts "INFO: Generating congestion reports..."
    
    # Generate congestion map
    reportCongestion -overflow -format text \
        -outfile ${rpt_dir}/${DESIGN_NAME}_route_congestion_overflow.rpt
    
    reportCongestion -hotspot \
        -outfile ${rpt_dir}/${DESIGN_NAME}_route_congestion_hotspot.rpt
    
    set cong_file [open ${rpt_dir}/${DESIGN_NAME}_route_congestion_summary.rpt w]
    puts $cong_file "=========================================================================="
    puts $cong_file "              CONGESTION ANALYSIS"
    puts $cong_file "=========================================================================="
    
    # Global congestion metrics
    set total_overflow [dbGet top.fPlan.overflows]
    set max_h_overflow [dbGet top.fPlan.maxHorizontalOverflow]
    set max_v_overflow [dbGet top.fPlan.maxVerticalOverflow]
    
    puts $cong_file "Global Congestion Metrics:"
    puts $cong_file "  Total Overflow:           $total_overflow"
    puts $cong_file "  Max Horizontal Overflow:  $max_h_overflow"
    puts $cong_file "  Max Vertical Overflow:    $max_v_overflow"
    puts $cong_file ""
    
    # Congestion hotspots
    puts $cong_file "Congestion Status:"
    if {$total_overflow == 0} {
        puts $cong_file "  Status: NO CONGESTION - CLEAN"
    } elseif {$total_overflow < 100} {
        puts $cong_file "  Status: LOW CONGESTION - ACCEPTABLE"
    } elseif {$total_overflow < 1000} {
        puts $cong_file "  Status: MODERATE CONGESTION - REVIEW NEEDED"
    } else {
        puts $cong_file "  Status: HIGH CONGESTION - CRITICAL"
    }
    
    puts $cong_file ""
    puts $cong_file "Per-Layer Overflow:"
    puts $cong_file [format "%-10s %15s %15s" "Layer" "H-Overflow" "V-Overflow"]
    puts $cong_file "--------------------------------------------------------------------------"
    
    for {set layer $::ROUTING_LAYER_MIN} {$layer <= $::ROUTING_LAYER_MAX} {incr layer} {
        set layer_name "M$layer"
        set h_overflow [dbGet [dbGet head.layers.name $layer_name -p].horizontalOverflow]
        set v_overflow [dbGet [dbGet head.layers.name $layer_name -p].verticalOverflow]
        
        puts $cong_file [format "%-10s %15d %15d" $layer_name $h_overflow $v_overflow]
    }
    
    puts $cong_file "=========================================================================="
    close $cong_file
    
    #---------------------------------------------------------------------------
    # Via Statistics
    #---------------------------------------------------------------------------
    puts "INFO: Generating via statistics..."
    
    set via_file [open ${rpt_dir}/${DESIGN_NAME}_route_via_stats.rpt w]
    puts $via_file "=========================================================================="
    puts $via_file "              VIA STATISTICS"
    puts $via_file "=========================================================================="
    
    set total_vias [dbGet top.numVias]
    set std_vias [dbGet [dbGet top.vias.isDefault 1 -p].name -count]
    set custom_vias [expr $total_vias - $std_vias]
    
    puts $via_file "Via Summary:"
    puts $via_file "  Total Vias:     $total_vias"
    puts $via_file "  Standard Vias:  $std_vias"
    puts $via_file "  Custom Vias:    $custom_vias"
    puts $via_file ""
    
    puts $via_file "Via Stack Distribution:"
    for {set layer $::ROUTING_LAYER_MIN} {$layer < $::ROUTING_LAYER_MAX} {incr layer} {
        set via_name "VIA[expr $layer]_[expr $layer+1]"
        set via_count [dbGet [dbGet top.vias.name ${via_name}* -p].name -count]
        puts $via_file [format "  %-15s: %d" $via_name $via_count]
    }
    
    puts $via_file "=========================================================================="
    close $via_file
    
    #---------------------------------------------------------------------------
    # Master Summary Report
    #---------------------------------------------------------------------------
    puts "INFO: Generating master summary report..."
    
    summaryReport -noHtml -outfile ${rpt_dir}/${DESIGN_NAME}_route_master_summary.rpt
    
    # Create consolidated QoR report
    set qor_file [open ${rpt_dir}/${DESIGN_NAME}_route_QoR_summary.rpt w]
    puts $qor_file "=========================================================================="
    puts $qor_file "                    ROUTE QoR SUMMARY REPORT"
    puts $qor_file "=========================================================================="
    puts $qor_file "Design:      $DESIGN_NAME"
    puts $qor_file "Technology:  $TECH_NODE"
    puts $qor_file "Date:        [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $qor_file "=========================================================================="
    puts $qor_file ""
    
    # Timing Summary
    set setup_wns [get_db timing_analysis_type:late slack -max]
    set setup_tns [get_db timing_analysis_type:late slack -sum]
    set hold_wns [get_db timing_analysis_type:early slack -max]
    set hold_tns [get_db timing_analysis_type:early slack -sum]
    set setup_viol [llength [get_db timing_analysis_type:late paths -if {.slack<0}]]
    set hold_viol [llength [get_db timing_analysis_type:early paths -if {.slack<0}]]
    
    puts $qor_file "TIMING SUMMARY:"
    puts $qor_file [format "  Setup WNS:            %10.3f ns" $setup_wns]
    puts $qor_file [format "  Setup TNS:            %10.3f ns" $setup_tns]
    puts $qor_file [format "  Setup Violations:     %10d" $setup_viol]
    puts $qor_file [format "  Hold WNS:             %10.3f ns" $hold_wns]
    puts $qor_file [format "  Hold TNS:             %10.3f ns" $hold_tns]
    puts $qor_file [format "  Hold Violations:      %10d" $hold_viol]
    puts $qor_file ""
    
    # DRC Summary
    set drc_viols [dbGet top.markers.numMarkers]
    puts $qor_file "DRC SUMMARY:"
    puts $qor_file [format "  Total DRC Violations: %10d" $drc_viols]
    puts $qor_file [format "  Opens:                %10d" $opens]
    puts $qor_file [format "  Shorts:               %10d" $shorts]
    puts $qor_file ""
    
    # Area Summary
    puts $qor_file "AREA SUMMARY:"
    puts $qor_file [format "  Total Die Area:       %10.2f um^2" $total_area]
    puts $qor_file [format "  Core Area:            %10.2f um^2" $core_area]
    puts $qor_file [format "  Utilization:          %10.2f %%" $utilization]
    puts $qor_file ""
    
    # Power Summary
    puts $qor_file "POWER SUMMARY:"
    puts $qor_file [format "  Total Power:          %10.6f mW" [expr $total_power * 1000]]
    puts $qor_file [format "  Leakage Power:        %10.6f mW" [expr $leakage_power * 1000]]
    puts $qor_file ""
    
    # Routing Summary
    puts $qor_file "ROUTING SUMMARY:"
    puts $qor_file [format "  Total Wire Length:    %10d um" $total_wire_length]
    puts $qor_file [format "  Total Vias:           %10d" $total_vias]
    puts $qor_file [format "  Total Overflow:       %10d" $total_overflow]
    puts $qor_file ""
    
    puts $qor_file "=========================================================================="
    
    # Final status
    if {$setup_wns > -0.001 && $hold_wns > -0.001 && $drc_viols == 0 && $total_overflow == 0} {
        puts $qor_file "                    *** DESIGN STATUS: CLEAN ***"
    } elseif {$drc_viols > 0 || $opens > 0 || $shorts > 0} {
        puts $qor_file "                 *** DESIGN STATUS: DRC VIOLATIONS ***"
    } elseif {$setup_wns < 0 || $hold_wns < 0} {
        puts $qor_file "               *** DESIGN STATUS: TIMING VIOLATIONS ***"
    } else {
        puts $qor_file "                 *** DESIGN STATUS: NEEDS REVIEW ***"
    }
    
    puts $qor_file "=========================================================================="
    close $qor_file
    
    puts "INFO: All reports generated successfully in ${rpt_dir}/"
}

################################################################################
# End of routing_procs.tcl
################################################################################
