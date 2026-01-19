####
################################################################################
# FILE 1: cts_vars.tcl
# Clock Tree Synthesis Variables and Configuration
################################################################################

################################################################################
# DESIGN INFORMATION
################################################################################
set CTS_CONFIG(design_name)         "my_design"
set CTS_CONFIG(top_module)          "top"

################################################################################
# CTS TARGET SPECIFICATIONS
################################################################################
set CTS_CONFIG(target_skew)         0.100      ;# Target skew (ns)
set CTS_CONFIG(max_trans)           0.200      ;# Max transition (ns)
set CTS_CONFIG(max_cap)             0.300      ;# Max capacitance (pF)
set CTS_CONFIG(target_latency)      0.500      ;# Target insertion delay (ns)
set CTS_CONFIG(max_fanout)          32         ;# Max fanout

################################################################################
# CLOCK BUFFER AND INVERTER CELLS
################################################################################
set CTS_CONFIG(buffer_cells)        {CLKBUF_X1 CLKBUF_X2 CLKBUF_X4 CLKBUF_X8 CLKBUF_X16}
set CTS_CONFIG(inverter_cells)      {CLKINV_X1 CLKINV_X2 CLKINV_X4 CLKINV_X8}
set CTS_CONFIG(excluded_buffers)    {CLKBUF_X32}
set CTS_CONFIG(root_buffer)         "CLKBUF_X8"
set CTS_CONFIG(leaf_buffer)         "CLKBUF_X2"

################################################################################
# CLOCK TREE ARCHITECTURE
################################################################################
set CTS_CONFIG(tree_structure)      "hTree"              ;# hTree, spine, multiLevel
set CTS_CONFIG(use_useful_skew)     true                 ;# Enable useful skew
set CTS_CONFIG(balance_mode)        "equal_path_length"  ;# or equal_delay
set CTS_CONFIG(cts_mode)            "full"               ;# full, incremental

################################################################################
# CLOCK GATING
################################################################################
set CTS_CONFIG(integrate_icg)       true
set CTS_CONFIG(use_clock_gating)    true
set CTS_CONFIG(clock_gate_cells)    {CLKGATE_X1 CLKGATE_X2 CLKGATE_X4}

################################################################################
# ROUTING CONFIGURATION
################################################################################
set CTS_CONFIG(shield_clocks)       true
set CTS_CONFIG(ndr_name)            "clk_2W2S"
set CTS_CONFIG(ndr_spacing)         "2W2S"               ;# NDR spacing rule
set CTS_CONFIG(route_top_layer)     "M6"
set CTS_CONFIG(route_bot_layer)     "M3"
set CTS_CONFIG(preferred_layers)    {M4 M5}
set CTS_CONFIG(route_with_tieoff)   true

################################################################################
# OPTIMIZATION OPTIONS
################################################################################
set CTS_CONFIG(opt_hold)            true
set CTS_CONFIG(opt_setup)           true
set CTS_CONFIG(buffer_relocation)   true
set CTS_CONFIG(delay_insertion)     true
set CTS_CONFIG(power_priority)      "medium"   ;# low, medium, high
set CTS_CONFIG(power_opt)           true
set CTS_CONFIG(fix_drc)             true

################################################################################
# MCMM CONFIGURATION
################################################################################
set CTS_CONFIG(setup_views)         {view_wc_setup view_bc_setup}
set CTS_CONFIG(hold_views)          {view_wc_hold view_bc_hold}
set CTS_CONFIG(active_corners)      {corner_ss corner_ff corner_tt}
set CTS_CONFIG(update_mcmm)         true

################################################################################
# POST-CTS OPTIMIZATION
################################################################################
set CTS_CONFIG(postcts_effort)      "high"     ;# low, medium, high
set CTS_CONFIG(postcts_iterations)  3
set CTS_CONFIG(incremental_opt)     true
set CTS_CONFIG(slack_threshold)     -0.050     ;# ns - threshold for violations

################################################################################
# CLOCK-SPECIFIC SETTINGS
################################################################################
# Format: clock_name {skew max_trans tree_type}
array set CTS_CONFIG(clock_specs) {
    clk_main    {0.080 0.150 hTree}
    clk_fast    {0.050 0.100 hTree}
    clk_slow    {0.150 0.250 spine}
}

################################################################################
# REPORTING OPTIONS
################################################################################
set CTS_CONFIG(report_dir)          "reports/cts"
set CTS_CONFIG(max_paths)           10
set CTS_CONFIG(verbose_reports)     true
set CTS_CONFIG(generate_qor)        true

################################################################################
# DATABASE SAVE OPTIONS
################################################################################
set CTS_CONFIG(checkpoint_dir)      "checkpoints"
set CTS_CONFIG(save_preCTS)         "preCTS.enc"
set CTS_CONFIG(save_postCTS)        "postCTS.enc"
set CTS_CONFIG(save_def)            "postCTS.def"
set CTS_CONFIG(save_netlist)        "postCTS.v"
set CTS_CONFIG(save_sdc)            "postCTS.sdc"

################################################################################
# DEBUG AND LOG OPTIONS
################################################################################
set CTS_CONFIG(debug_mode)          false
set CTS_CONFIG(enable_gui)          false
set CTS_CONFIG(log_file)            "logs/cts_flow.log"
set CTS_CONFIG(enable_logging)      true

puts "INFO: CTS variables loaded successfully!"

################################################################################
# END OF cts_vars.tcl
################################################################################


################################################################################
# FILE 2: cts_procs.tcl
# Clock Tree Synthesis Procedures/Functions
################################################################################

################################################################################
# UTILITY PROCEDURES
################################################################################

proc print_banner {msg} {
    set len [string length $msg]
    set bar [string repeat "=" [expr {$len + 4}]]
    puts "\n$bar"
    puts "  $msg"
    puts "$bar"
}

proc print_section {msg} {
    puts "\n>>> $msg"
}

proc log_message {msg} {
    global CTS_CONFIG
    puts $msg
    if {$CTS_CONFIG(enable_logging)} {
        set log_fh [open $CTS_CONFIG(log_file) a]
        puts $log_fh "[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}] $msg"
        close $log_fh
    }
}

################################################################################
# SETUP PROCEDURES
################################################################################

proc setup_directories {} {
    global CTS_CONFIG
    
    # Create report directory
    if {![file exists $CTS_CONFIG(report_dir)]} {
        file mkdir $CTS_CONFIG(report_dir)
        log_message "INFO: Created report directory: $CTS_CONFIG(report_dir)"
    }
    
    # Create checkpoint directory
    if {![file exists $CTS_CONFIG(checkpoint_dir)]} {
        file mkdir $CTS_CONFIG(checkpoint_dir)
        log_message "INFO: Created checkpoint directory: $CTS_CONFIG(checkpoint_dir)"
    }
    
    # Create log directory
    set log_dir [file dirname $CTS_CONFIG(log_file)]
    if {![file exists $log_dir]} {
        file mkdir $log_dir
    }
}

proc validate_config {} {
    global CTS_CONFIG
    
    log_message "INFO: Validating configuration..."
    
    # Check critical parameters
    if {$CTS_CONFIG(target_skew) <= 0} {
        log_message "ERROR: Invalid target_skew value"
        return 0
    }
    
    if {[llength $CTS_CONFIG(buffer_cells)] == 0} {
        log_message "ERROR: No buffer cells specified"
        return 0
    }
    
    log_message "INFO: Configuration validation passed"
    return 1
}

################################################################################
# PRE-CTS PROCEDURES
################################################################################

proc generate_prects_reports {} {
    global CTS_CONFIG
    
    print_section "Generating Pre-CTS Reports"
    
    report_timing -max_paths $CTS_CONFIG(max_paths) \
        > $CTS_CONFIG(report_dir)/timing_preCTS.rpt
    log_message "INFO: Pre-CTS timing report generated"
    
    report_clock_tree -summary \
        > $CTS_CONFIG(report_dir)/clock_tree_preCTS.rpt
    log_message "INFO: Pre-CTS clock tree report generated"
    
    report_constraint -all_violators \
        > $CTS_CONFIG(report_dir)/constraints_preCTS.rpt
    log_message "INFO: Pre-CTS constraint report generated"
    
    if {$CTS_CONFIG(generate_qor)} {
        report_qor > $CTS_CONFIG(report_dir)/qor_preCTS.rpt
        log_message "INFO: Pre-CTS QoR report generated"
    }
}

proc save_prects_checkpoint {} {
    global CTS_CONFIG
    
    set checkpoint_path "$CTS_CONFIG(checkpoint_dir)/$CTS_CONFIG(save_preCTS)"
    saveDesign $checkpoint_path
    log_message "INFO: Pre-CTS checkpoint saved: $checkpoint_path"
}

################################################################################
# CTS CONFIGURATION PROCEDURES
################################################################################

proc apply_cts_specifications {} {
    global CTS_CONFIG
    
    print_section "Applying CTS Specifications"
    
    # Basic properties
    set_ccopt_property target_skew $CTS_CONFIG(target_skew)
    set_ccopt_property target_max_trans $CTS_CONFIG(max_trans)
    set_ccopt_property target_max_cap $CTS_CONFIG(max_cap)
    set_ccopt_property max_fanout $CTS_CONFIG(max_fanout)
    
    log_message "INFO: Target skew: $CTS_CONFIG(target_skew) ns"
    log_message "INFO: Max transition: $CTS_CONFIG(max_trans) ns"
    log_message "INFO: Max capacitance: $CTS_CONFIG(max_cap) pF"
    
    # Buffer and inverter cells
    set_ccopt_property buffer_cells $CTS_CONFIG(buffer_cells)
    set_ccopt_property inverter_cells $CTS_CONFIG(inverter_cells)
    
    if {[llength $CTS_CONFIG(excluded_buffers)] > 0} {
        set_ccopt_property excluded_buffer_cells $CTS_CONFIG(excluded_buffers)
    }
    
    set_ccopt_property clock_tree_root_buffer $CTS_CONFIG(root_buffer)
    log_message "INFO: Buffer cells configured"
}

proc configure_tree_architecture {} {
    global CTS_CONFIG
    
    print_section "Configuring Clock Tree Architecture"
    
    set_ccopt_property clock_tree_structure $CTS_CONFIG(tree_structure)
    set_ccopt_property use_useful_skew $CTS_CONFIG(use_useful_skew)
    set_ccopt_property integrate_clock_gates $CTS_CONFIG(integrate_icg)
    set_ccopt_property use_clock_gating $CTS_CONFIG(use_clock_gating)
    set_ccopt_property optimize_for_hold $CTS_CONFIG(opt_hold)
    
    log_message "INFO: Tree structure: $CTS_CONFIG(tree_structure)"
    log_message "INFO: Useful skew: $CTS_CONFIG(use_useful_skew)"
    log_message "INFO: Clock gating integration: $CTS_CONFIG(integrate_icg)"
}

proc configure_routing {} {
    global CTS_CONFIG
    
    print_section "Configuring Clock Routing"
    
    set_ccopt_property shield_clock_nets $CTS_CONFIG(shield_clocks)
    set_ccopt_property route_top_layer $CTS_CONFIG(route_top_layer)
    set_ccopt_property route_bottom_layer $CTS_CONFIG(route_bot_layer)
    set_ccopt_property route_clk_net_with_tie_off_cell $CTS_CONFIG(route_with_tieoff)
    
    log_message "INFO: Clock shielding: $CTS_CONFIG(shield_clocks)"
    log_message "INFO: Routing layers: $CTS_CONFIG(route_bot_layer) to $CTS_CONFIG(route_top_layer)"
    
    # NDR configuration
    if {$CTS_CONFIG(ndr_name) ne ""} {
        if {[catch {
            create_route_type -name $CTS_CONFIG(ndr_name) \
                -non_default_rule $CTS_CONFIG(ndr_spacing)
            set_ccopt_property route_type $CTS_CONFIG(ndr_name)
            log_message "INFO: NDR '$CTS_CONFIG(ndr_name)' applied"
        } err]} {
            log_message "WARNING: Could not create/apply NDR: $err"
        }
    }
}

proc configure_power_optimization {} {
    global CTS_CONFIG
    
    set_ccopt_property power_priority $CTS_CONFIG(power_priority)
    log_message "INFO: Power priority: $CTS_CONFIG(power_priority)"
}

proc apply_clock_specific_settings {} {
    global CTS_CONFIG
    
    if {[info exists CTS_CONFIG(clock_specs)] && [array size CTS_CONFIG] > 0} {
        print_section "Applying Clock-Specific Settings"
        foreach {clk_name specs} [array get CTS_CONFIG clock_specs] {
            set skew [lindex $specs 0]
            set trans [lindex $specs 1]
            set tree [lindex $specs 2]
            log_message "INFO: Clock $clk_name - Skew:${skew}ns, Trans:${trans}ns, Tree:$tree"
            
            # Apply per-clock settings
            # set_ccopt_property -clock $clk_name target_skew $skew
            # set_ccopt_property -clock $clk_name target_max_trans $trans
        }
    }
}

################################################################################
# CTS EXECUTION PROCEDURES
################################################################################

proc run_cts {} {
    global CTS_CONFIG
    
    print_banner "Running Clock Tree Synthesis"
    
    set start_time [clock seconds]
    
    if {$CTS_CONFIG(buffer_relocation)} {
        ccopt_design -cts -buffer_relocation
    } else {
        ccopt_design -cts
    }
    
    set end_time [clock seconds]
    set runtime [expr {$end_time - $start_time}]
    
    log_message "INFO: CTS completed in $runtime seconds"
    return $runtime
}

################################################################################
# POST-CTS OPTIMIZATION PROCEDURES
################################################################################

proc get_violation_count {} {
    set setup_viol [llength [get_db timing_setup_violators -if {.slack < 0}]]
    set hold_viol [llength [get_db timing_hold_violators -if {.slack < 0}]]
    return [list $setup_viol $hold_viol]
}

proc run_postcts_optimization {} {
    global CTS_CONFIG
    
    print_banner "Post-CTS Optimization"
    
    set start_time [clock seconds]
    
    for {set i 1} {$i <= $CTS_CONFIG(postcts_iterations)} {incr i} {
        log_message "\nINFO: Post-CTS optimization iteration $i/$CTS_CONFIG(postcts_iterations)"
        
        if {$CTS_CONFIG(opt_setup)} {
            log_message "  - Running setup optimization..."
            optDesign -postCTS -setup -effort $CTS_CONFIG(postcts_effort)
        }
        
        if {$CTS_CONFIG(opt_hold)} {
            log_message "  - Running hold optimization..."
            optDesign -postCTS -hold -effort $CTS_CONFIG(postcts_effort)
        }
        
        # Check violations
        set viol_counts [get_violation_count]
        set setup_viol [lindex $viol_counts 0]
        set hold_viol [lindex $viol_counts 1]
        
        log_message "  - Setup violations: $setup_viol"
        log_message "  - Hold violations: $hold_viol"
        
        if {$setup_viol == 0 && $hold_viol == 0} {
            log_message "INFO: No timing violations. Optimization complete."
            break
        }
    }
    
    # Fix DRC
    if {$CTS_CONFIG(fix_drc)} {
        log_message "\nINFO: Fixing design rule violations..."
        optDesign -postCTS -fix_drc
    }
    
    set end_time [clock seconds]
    set runtime [expr {$end_time - $start_time}]
    
    log_message "INFO: Post-CTS optimization completed in $runtime seconds"
    return $runtime
}

################################################################################
# REPORTING PROCEDURES
################################################################################

proc generate_postcts_reports {} {
    global CTS_CONFIG
    
    print_banner "Generating Post-CTS Reports"
    
    # Timing reports
    log_message "INFO: Generating timing reports..."
    report_timing -max_paths $CTS_CONFIG(max_paths) \
        > $CTS_CONFIG(report_dir)/timing_postCTS.rpt
    report_timing -late -max_paths $CTS_CONFIG(max_paths) \
        > $CTS_CONFIG(report_dir)/timing_postCTS_setup.rpt
    report_timing -early -max_paths $CTS_CONFIG(max_paths) \
        > $CTS_CONFIG(report_dir)/timing_postCTS_hold.rpt
    
    # Clock tree reports
    log_message "INFO: Generating clock tree reports..."
    report_ccopt_clock_trees \
        -file $CTS_CONFIG(report_dir)/clock_trees.rpt
    report_ccopt_skew_groups \
        -file $CTS_CONFIG(report_dir)/clock_skew_groups.rpt
    report_clock_tree -summary \
        > $CTS_CONFIG(report_dir)/clock_tree_summary.rpt
    report_clock_tree -report_cells \
        > $CTS_CONFIG(report_dir)/clock_tree_cells.rpt
    report_skew \
        > $CTS_CONFIG(report_dir)/clock_skew.rpt
    
    # Power reports
    log_message "INFO: Generating power reports..."
    report_power -hierarchy \
        > $CTS_CONFIG(report_dir)/power_postCTS.rpt
    
    # Constraint reports
    log_message "INFO: Generating constraint reports..."
    check_timing -verbose \
        > $CTS_CONFIG(report_dir)/check_timing_postCTS.rpt
    report_constraint -all_violators \
        > $CTS_CONFIG(report_dir)/constraints_postCTS.rpt
    
    # Clock gating report
    if {$CTS_CONFIG(use_clock_gating)} {
        log_message "INFO: Generating clock gating report..."
        report_clock_gating -gating_elements \
            > $CTS_CONFIG(report_dir)/clock_gating.rpt
    }
    
    # QoR report
    if {$CTS_CONFIG(generate_qor)} {
        report_qor > $CTS_CONFIG(report_dir)/qor_postCTS.rpt
        log_message "INFO: Post-CTS QoR report generated"
    }
}

################################################################################
# SAVE PROCEDURES
################################################################################

proc save_postcts_design {} {
    global CTS_CONFIG
    
    print_section "Saving Post-CTS Design"
    
    set checkpoint_path "$CTS_CONFIG(checkpoint_dir)/$CTS_CONFIG(save_postCTS)"
    saveDesign $checkpoint_path
    log_message "INFO: Database saved: $checkpoint_path"
    
    defOut -routing $CTS_CONFIG(save_def)
    log_message "INFO: DEF saved: $CTS_CONFIG(save_def)"
    
    saveNetlist $CTS_CONFIG(save_netlist)
    log_message "INFO: Netlist saved: $CTS_CONFIG(save_netlist)"
    
    write_sdc $CTS_CONFIG(save_sdc)
    log_message "INFO: SDC saved: $CTS_CONFIG(save_sdc)"
}

################################################################################
# SUMMARY PROCEDURES
################################################################################

proc print_cts_summary {cts_runtime opt_runtime} {
    global CTS_CONFIG
    
    print_banner "CTS Flow Summary"
    
    set total_runtime [expr {$cts_runtime + $opt_runtime}]
    
    puts "\nRUNTIME SUMMARY:"
    puts "  - CTS Runtime         : $cts_runtime seconds"
    puts "  - Optimization Runtime: $opt_runtime seconds"
    puts "  - Total Runtime       : $total_runtime seconds"
    
    puts "\nKEY METRICS:"
    puts "  - Target Skew         : $CTS_CONFIG(target_skew) ns"
    puts "  - Max Transition      : $CTS_CONFIG(max_trans) ns"
    puts "  - Tree Structure      : $CTS_CONFIG(tree_structure)"
    puts "  - Useful Skew         : $CTS_CONFIG(use_useful_skew)"
    puts "  - Clock Shielding     : $CTS_CONFIG(shield_clocks)"
    puts "  - Power Priority      : $CTS_CONFIG(power_priority)"
    
    puts "\nREPORTS LOCATION:"
    puts "  $CTS_CONFIG(report_dir)/"
    
    # Final violation check
    set viol_counts [get_violation_count]
    set final_setup_viol [lindex $viol_counts 0]
    set final_hold_viol [lindex $viol_counts 1]
    
    puts "\nFINAL TIMING STATUS:"
    puts "  - Setup Violations    : $final_setup_viol"
    puts "  - Hold Violations     : $final_hold_viol"
    
    if {$final_setup_viol == 0 && $final_hold_viol == 0} {
        puts "\n✓ STATUS: CTS completed with CLEAN timing!"
    } else {
        puts "\n⚠ WARNING: Timing violations present. Review reports for details."
    }
}

puts "INFO: CTS procedures loaded successfully!"

################################################################################
# END OF cts_procs.tcl
################################################################################


################################################################################
# FILE 3: run_cts_main.tcl
# Main CTS Execution Script
################################################################################

################################################################################
# MAIN CTS FLOW EXECUTION
################################################################################

# Print start banner
puts "\n========================================"
puts "  Clock Tree Synthesis Flow"
puts "========================================"

################################################################################
# STEP 1: SOURCE REQUIRED FILES
################################################################################
puts "\n>>> Loading required files..."

# Get script directory
set script_dir [file dirname [info script]]

# Source variables file
if {[file exists $script_dir/cts_vars.tcl]} {
    source $script_dir/cts_vars.tcl
    puts "✓ Variables loaded: cts_vars.tcl"
} else {
    puts "✗ ERROR: cts_vars.tcl not found in $script_dir"
    exit 1
}

# Source procedures file
if {[file exists $script_dir/cts_procs.tcl]} {
    source $script_dir/cts_procs.tcl
    puts "✓ Procedures loaded: cts_procs.tcl"
} else {
    puts "✗ ERROR: cts_procs.tcl not found in $script_dir"
    exit 1
}

################################################################################
# STEP 2: SETUP
################################################################################
print_banner "Setup and Validation"

setup_directories

if {![validate_config]} {
    log_message "ERROR: Configuration validation failed!"
    exit 1
}

################################################################################
# STEP 3: PRE-CTS PHASE
################################################################################
print_banner "Pre-CTS Phase"

save_prects_checkpoint
generate_prects_reports

################################################################################
# STEP 4: CTS CONFIGURATION
################################################################################
print_banner "CTS Configuration"

apply_cts_specifications
configure_tree_architecture
configure_routing
configure_power_optimization

# MCMM setup
if {$CTS_CONFIG(update_mcmm) && [llength $CTS_CONFIG(setup_views)] > 0} {
    print_section "Updating MCMM"
    update_timing
    log_message "INFO: MCMM views updated"
}

# Clock-specific settings
apply_clock_specific_settings

################################################################################
# STEP 5: CREATE CLOCK TREE SPECIFICATION
################################################################################
print_section "Creating Clock Tree Specification"
create_ccopt_clock_tree_spec
log_message "INFO: Clock tree specification created"

################################################################################
# STEP 6: RUN CTS
################################################################################
set cts_runtime [run_cts]

################################################################################
# STEP 7: POST-CTS OPTIMIZATION
################################################################################
set opt_runtime [run_postcts_optimization]

################################################################################
# STEP 8: GENERATE REPORTS
################################################################################
generate_postcts_reports

################################################################################
# STEP 9: SAVE DESIGN
################################################################################
save_postcts_design

################################################################################
# STEP 10: PRINT SUMMARY
################################################################################
print_cts_summary $cts_runtime $opt_runtime

print_banner "CTS Flow Completed Successfully"

################################################################################
# END OF run_cts_main.tcl
################################################################################
