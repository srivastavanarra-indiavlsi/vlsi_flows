################################################################################
# FILE 2: cts_procs.tcl
# Clock Tree Synthesis Procedures
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
# DATABASE LOADING PROCEDURES
################################################################################

proc load_placement_database {} {
    global CTS_CONFIG
    
    print_banner "Loading Post-Placement Database"
    
    if {![file exists $CTS_CONFIG(input_db)]} {
        log_message "ERROR: Database file not found: $CTS_CONFIG(input_db)"
        return 0
    }
    
    log_message "INFO: Loading database: $CTS_CONFIG(input_db)"
    restoreDesign $CTS_CONFIG(input_db)
    
    log_message "INFO: Database loaded successfully"
    return 1
}

proc load_sdc_constraints {} {
    global CTS_CONFIG
    
    print_section "Loading SDC Constraints"
    
    if {![file exists $CTS_CONFIG(input_sdc)]} {
        log_message "ERROR: SDC file not found: $CTS_CONFIG(input_sdc)"
        return 0
    }
    
    log_message "INFO: Loading SDC: $CTS_CONFIG(input_sdc)"
    read_sdc $CTS_CONFIG(input_sdc)
    
    log_message "INFO: SDC constraints loaded successfully"
    return 1
}

proc verify_placement_status {} {
    global CTS_CONFIG
    
    print_section "Verifying Placement Status"
    
    # Check if design has cells placed
    set placed_cells [get_db insts -if {.place_status == placed}]
    set total_cells [get_db insts]
    
    if {[llength $placed_cells] == 0} {
        log_message "ERROR: No cells are placed!"
        return 0
    }
    
    set placement_ratio [expr {double([llength $placed_cells]) / [llength $total_cells] * 100}]
    log_message "INFO: Placement status: [llength $placed_cells] / [llength $total_cells] cells placed ([format %.2f $placement_ratio]%)"
    
    # Check if macros are placed
    set macros [get_db insts -if {.is_macro == true}]
    set placed_macros [get_db insts -if {.is_macro == true && .place_status == placed}]
    
    if {[llength $macros] > 0} {
        log_message "INFO: Macros: [llength $placed_macros] / [llength $macros] placed"
    }
    
    return 1
}

proc analyze_clock_structure {} {
    global CTS_CONFIG
    
    print_section "Analyzing Clock Structure"
    
    # Get all clocks
    set all_clocks [get_db clocks]
    
    if {[llength $all_clocks] == 0} {
        log_message "WARNING: No clocks found in design!"
        return 0
    }
    
    log_message "INFO: Found [llength $all_clocks] clock(s) in design:"
    
    foreach clk $all_clocks {
        set clk_name [get_db $clk .name]
        set clk_period [get_db $clk .period]
        set clk_sources [get_db $clk .sources]
        
        log_message "  - Clock: $clk_name, Period: $clk_period ns"
        
        # Count clock sinks
        set sinks [get_db [get_db $clk .sinks] .name]
        log_message "    Sinks: [llength $sinks]"
    }
    
    return 1
}

################################################################################
# SETUP PROCEDURES
################################################################################

proc setup_directories {} {
    global CTS_CONFIG
    
    foreach dir [list $CTS_CONFIG(report_dir) $CTS_CONFIG(checkpoint_dir) $CTS_CONFIG(cts_spec_dir)] {
        if {![file exists $dir]} {
            file mkdir $dir
            log_message "INFO: Created directory: $dir"
        }
    }
    
    set log_dir [file dirname $CTS_CONFIG(log_file)]
    if {![file exists $log_dir]} {
        file mkdir $log_dir
    }
}

proc validate_config {} {
    global CTS_CONFIG
    
    log_message "INFO: Validating configuration..."
    
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
# CTS SPECIFICATION GENERATION PROCEDURES
################################################################################

proc generate_cts_spec {} {
    global CTS_CONFIG
    
    print_banner "Generating CTS Specification"
    
    set spec_file "$CTS_CONFIG(cts_spec_dir)/$CTS_CONFIG(cts_spec_file)"
    
    log_message "INFO: Creating CTS specification file: $spec_file"
    
    set fh [open $spec_file w]
    
    # Header
    puts $fh "################################################################################"
    puts $fh "# Clock Tree Synthesis Specification"
    puts $fh "# Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $fh "# Design: $CTS_CONFIG(design_name)"
    puts $fh "################################################################################"
    puts $fh ""
    
    # Global CTS properties
    puts $fh "# Global CTS Properties"
    puts $fh "set_ccopt_property target_skew $CTS_CONFIG(target_skew)"
    puts $fh "set_ccopt_property target_max_trans $CTS_CONFIG(max_trans)"
    puts $fh "set_ccopt_property target_max_cap $CTS_CONFIG(max_cap)"
    puts $fh "set_ccopt_property max_fanout $CTS_CONFIG(max_fanout)"
    puts $fh ""
    
    # Buffer cells
    puts $fh "# Buffer and Inverter Cells"
    puts $fh "set_ccopt_property buffer_cells \{$CTS_CONFIG(buffer_cells)\}"
    puts $fh "set_ccopt_property inverter_cells \{$CTS_CONFIG(inverter_cells)\}"
    
    if {[llength $CTS_CONFIG(excluded_buffers)] > 0} {
        puts $fh "set_ccopt_property excluded_buffer_cells \{$CTS_CONFIG(excluded_buffers)\}"
    }
    
    puts $fh "set_ccopt_property clock_tree_root_buffer $CTS_CONFIG(root_buffer)"
    puts $fh ""
    
    # Tree architecture
    puts $fh "# Clock Tree Architecture"
    puts $fh "set_ccopt_property clock_tree_structure $CTS_CONFIG(tree_structure)"
    puts $fh "set_ccopt_property use_useful_skew $CTS_CONFIG(use_useful_skew)"
    
    if {$CTS_CONFIG(use_useful_skew)} {
        puts $fh "set_ccopt_property useful_skew_mode $CTS_CONFIG(useful_skew_mode)"
        puts $fh "set_ccopt_property useful_skew_ccopt $CTS_CONFIG(useful_skew_ccopt)"
        puts $fh "set_ccopt_property max_useful_skew $CTS_CONFIG(max_useful_skew)"
    }
    puts $fh ""
    
    # Clock gating
    puts $fh "# Clock Gating"
    puts $fh "set_ccopt_property integrate_clock_gates $CTS_CONFIG(integrate_icg)"
    puts $fh "set_ccopt_property use_clock_gating $CTS_CONFIG(use_clock_gating)"
    puts $fh ""
    
    # Routing
    puts $fh "# Routing Configuration"
    puts $fh "set_ccopt_property shield_clock_nets $CTS_CONFIG(shield_clocks)"
    puts $fh "set_ccopt_property route_top_layer $CTS_CONFIG(route_top_layer)"
    puts $fh "set_ccopt_property route_bottom_layer $CTS_CONFIG(route_bot_layer)"
    puts $fh ""
    
    # Power optimization
    puts $fh "# Power Optimization"
    puts $fh "set_ccopt_property power_priority $CTS_CONFIG(power_priority)"
    puts $fh ""
    
    # Per-clock specifications
    if {[info exists CTS_CONFIG(clock_specs)] && [array size CTS_CONFIG] > 0} {
        puts $fh "# Per-Clock Specifications"
        foreach {clk_name specs} [array get CTS_CONFIG clock_specs] {
            set skew [lindex $specs 0]
            set trans [lindex $specs 1]
            set tree [lindex $specs 2]
            
            puts $fh "# Clock: $clk_name"
            puts $fh "set_ccopt_property -clock_name $clk_name target_skew $skew"
            puts $fh "set_ccopt_property -clock_name $clk_name target_max_trans $trans"
            
            if {$tree ne "auto"} {
                puts $fh "set_ccopt_property -clock_name $clk_name clock_tree_structure $tree"
            }
            puts $fh ""
        }
    }
    
    close $fh
    
    log_message "INFO: CTS specification written to: $spec_file"
    return $spec_file
}

proc dump_current_cts_spec {} {
    global CTS_CONFIG
    
    print_section "Dumping Current CTS Specification"
    
    set dump_file "$CTS_CONFIG(cts_spec_dir)/cts_spec_current.rpt"
    
    # Report current CCOpt properties
    report_ccopt_property > $dump_file
    
    log_message "INFO: Current CTS spec dumped to: $dump_file"
}

################################################################################
# PRE-CTS PROCEDURES
################################################################################

proc generate_prects_reports {} {
    global CTS_CONFIG
    
    print_section "Generating Pre-CTS Reports"
    
    report_timing -max_paths $CTS_CONFIG(max_paths) \
        > $CTS_CONFIG(report_dir)/timing_preCTS.rpt
    
    report_clock_tree -summary \
        > $CTS_CONFIG(report_dir)/clock_tree_preCTS.rpt
    
    report_constraint -all_violators \
        > $CTS_CONFIG(report_dir)/constraints_preCTS.rpt
    
    if {$CTS_CONFIG(generate_qor)} {
        report_qor > $CTS_CONFIG(report_dir)/qor_preCTS.rpt
    }
    
    if {$CTS_CONFIG(generate_power_rpt)} {
        report_power > $CTS_CONFIG(report_dir)/power_preCTS.rpt
    }
    
    # Report placement status
    report_place > $CTS_CONFIG(report_dir)/placement_status.rpt
    
    log_message "INFO: Pre-CTS reports generated"
}

proc save_prects_checkpoint {} {
    global CTS_CONFIG
    
    set checkpoint_path "$CTS_CONFIG(checkpoint_dir)/$CTS_CONFIG(save_preCTS)"
    saveDesign $checkpoint_path
    log_message "INFO: Pre-CTS checkpoint saved: $checkpoint_path"
}

################################################################################
# CCOPT CONFIGURATION PROCEDURES
################################################################################

proc apply_ccopt_specifications {} {
    global CTS_CONFIG
    
    print_section "Applying CCOpt Specifications"
    
    set_ccopt_property target_skew $CTS_CONFIG(target_skew)
    set_ccopt_property target_max_trans $CTS_CONFIG(max_trans)
    set_ccopt_property target_max_cap $CTS_CONFIG(max_cap)
    set_ccopt_property max_fanout $CTS_CONFIG(max_fanout)
    
    if {$CTS_CONFIG(local_skew) < $CTS_CONFIG(global_skew)} {
        set_ccopt_property target_local_skew $CTS_CONFIG(local_skew)
    }
    
    log_message "INFO: Target global skew: $CTS_CONFIG(global_skew) ns"
    log_message "INFO: Target local skew: $CTS_CONFIG(local_skew) ns"
    
    set_ccopt_property buffer_cells $CTS_CONFIG(buffer_cells)
    set_ccopt_property inverter_cells $CTS_CONFIG(inverter_cells)
    
    if {[llength $CTS_CONFIG(excluded_buffers)] > 0} {
        set_ccopt_property excluded_buffer_cells $CTS_CONFIG(excluded_buffers)
    }
    
    set_ccopt_property clock_tree_root_buffer $CTS_CONFIG(root_buffer)
    
    if {$CTS_CONFIG(auto_buffer_sizing)} {
        set_ccopt_property auto_buffer_sizing true
    }
    
    log_message "INFO: CCOpt specifications applied"
}

proc configure_advanced_ccopt {} {
    global CTS_CONFIG
    
    print_section "Configuring Advanced CCOpt"
    
    set_ccopt_property clock_tree_structure $CTS_CONFIG(tree_structure)
    
    if {$CTS_CONFIG(use_useful_skew)} {
        set_ccopt_property use_useful_skew true
        set_ccopt_property useful_skew_mode $CTS_CONFIG(useful_skew_mode)
        set_ccopt_property useful_skew_ccopt $CTS_CONFIG(useful_skew_ccopt)
        set_ccopt_property max_useful_skew $CTS_CONFIG(max_useful_skew)
        log_message "INFO: Useful skew enabled - mode: $CTS_CONFIG(useful_skew_mode)"
    }
    
    if {$CTS_CONFIG(use_data_driven)} {
        set_ccopt_property data_driven_optimization true
        log_message "INFO: Data-driven optimization enabled"
    }
    
    if {$CTS_CONFIG(enable_si_aware)} {
        set_ccopt_property si_aware_cto true
        log_message "INFO: SI-aware CTS enabled"
    }
    
    if {$CTS_CONFIG(enable_ocv)} {
        set_analysis_mode -cppr $CTS_CONFIG(enable_cppr)
        set_analysis_mode -onChipVariation $CTS_CONFIG(enable_ocv)
        log_message "INFO: OCV enabled, CPPR: $CTS_CONFIG(enable_cppr)"
    }
    
    if {$CTS_CONFIG(enable_aocv)} {
        set_analysis_mode -aocv true
        log_message "INFO: Advanced OCV enabled"
    }
    
    set_ccopt_property integrate_clock_gates $CTS_CONFIG(integrate_icg)
    set_ccopt_property use_clock_gating $CTS_CONFIG(use_clock_gating)
    
    if {$CTS_CONFIG(icg_flow) eq "concurrent"} {
        set_ccopt_property concurrent_icg_flow true
    }
    
    set_ccopt_property optimize_for_hold $CTS_CONFIG(opt_hold)
    
    log_message "INFO: Advanced CCOpt features configured"
}

proc configure_routing {} {
    global CTS_CONFIG
    
    print_section "Configuring Routing"
    
    set_ccopt_property shield_clock_nets $CTS_CONFIG(shield_clocks)
    
    if {$CTS_CONFIG(shield_nets) eq "critical"} {
        set_ccopt_property shield_critical_nets true
    }
    
    set_ccopt_property route_top_layer $CTS_CONFIG(route_top_layer)
    set_ccopt_property route_bottom_layer $CTS_CONFIG(route_bot_layer)
    
    if {[llength $CTS_CONFIG(preferred_layers)] > 0} {
        set_ccopt_property preferred_routing_layers $CTS_CONFIG(preferred_layers)
    }
    
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
    
    if {$CTS_CONFIG(detailed_route_cts)} {
        set_ccopt_property route_clock_nets true
    }
    
    log_message "INFO: Routing configured"
}

proc configure_power_optimization {} {
    global CTS_CONFIG
    
    print_section "Configuring Power Optimization"
    
    set_ccopt_property power_priority $CTS_CONFIG(power_priority)
    
    if {$CTS_CONFIG(dynamic_power_opt)} {
        set_ccopt_property optimize_dynamic_power true
    }
    
    if {$CTS_CONFIG(leakage_power_opt)} {
        set_ccopt_property optimize_leakage_power true
    }
    
    if {$CTS_CONFIG(multi_vt_opt)} {
        set_ccopt_property multi_vt_optimization true
    }
    
    if {$CTS_CONFIG(clock_gate_aware)} {
        set_ccopt_property clock_gating_aware true
    }
    
    log_message "INFO: Power optimization configured"
}

proc apply_clock_specific_settings {} {
    global CTS_CONFIG
    
    if {[info exists CTS_CONFIG(clock_specs)] && [array size CTS_CONFIG] > 0} {
        print_section "Applying Per-Clock Settings"
        foreach {clk_name specs} [array get CTS_CONFIG clock_specs] {
            set skew [lindex $specs 0]
            set trans [lindex $specs 1]
            set tree [lindex $specs 2]
            
            log_message "INFO: Clock $clk_name - Skew:${skew}ns, Trans:${trans}ns, Tree:$tree"
            
            create_ccopt_clock_tree_spec -clock_name $clk_name
            set_ccopt_property -clock_name $clk_name target_skew $skew
            set_ccopt_property -clock_name $clk_name target_max_trans $trans
            
            if {$tree ne "auto"} {
                set_ccopt_property -clock_name $clk_name clock_tree_structure $tree
            }
        }
    }
}

################################################################################
# CTS EXECUTION
################################################################################

proc run_ccopt_cts {} {
    global CTS_CONFIG
    
    print_banner "Running CCOpt CTS"
    
    set start_time [clock seconds]
    
    if {$CTS_CONFIG(buffer_relocation)} {
        ccopt_design -cts -buffer_relocation
    } else {
        ccopt_design -cts
    }
    
    set end_time [clock seconds]
    set runtime [expr {$end_time - $start_time}]
    
    log_message "INFO: CCOpt CTS completed in $runtime seconds"
    return $runtime
}

################################################################################
# POST-CTS OPTIMIZATION
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
        log_message "\nINFO: Iteration $i/$CTS_CONFIG(postcts_iterations)"
        
        if {$CTS_CONFIG(opt_setup)} {
            optDesign -postCTS -setup -effort $CTS_CONFIG(postcts_effort)
        }
        
        if {$CTS_CONFIG(opt_hold)} {
            optDesign -postCTS -hold -effort $CTS_CONFIG(postcts_effort)
        }
        
        if {$CTS_CONFIG(opt_area)} {
            optDesign -postCTS -area
        }
        
        set viol_counts [get_violation_count]
        set setup_viol [lindex $viol_counts 0]
        set hold_viol [lindex $viol_counts 1]
        
        log_message "  - Setup violations: $setup_viol"
        log_message "  - Hold violations: $hold_viol"
        
        if {$setup_viol == 0 && $hold_viol == 0} {
            log_message "INFO: No violations. Optimization complete."
            break
        }
    }
    
    if {$CTS_CONFIG(fix_drc)} {
        optDesign -postCTS -fix_drc
    }
    
    if {$CTS_CONFIG(fix_fanout_load)} {
        optDesign -postCTS -fix_fanout_load
    }
    
    if {$CTS_CONFIG(postcts_detail_place)} {
        refinePlace -checkPlace
    }
    
    if {$CTS_CONFIG(postcts_route_opt)} {
        optDesign -postRoute
    }
    
    set end_time [clock seconds]
    set runtime [expr {$end_time - $start_time}]
    
    log_message "INFO: Post-CTS optimization completed in $runtime seconds"
    return $runtime
}

################################################################################
# REPORTING
################################################################################

proc generate_postcts_reports {} {
    global CTS_CONFIG
    
    print_banner "Generating Post-CTS Reports"
    
    report_ccopt_clock_trees -file $CTS_CONFIG(report_dir)/ccopt_clock_trees.rpt
report_ccopt_skew_groups -file $CTS_CONFIG(report_dir)/ccopt_skew_groups.rpt
report_clock_tree -summary > $CTS_CONFIG(report_dir)/clock_tree_summary.rpt
report_clock_tree -report_cells > $CTS_CONFIG(report_dir)/clock_tree_cells.rpt
report_skew > $CTS_CONFIG(report_dir)/clock_skew.rpt

if {$CTS_CONFIG(use_useful_skew)} {
    report_ccopt_clock_trees -useful_skew \
        > $CTS_CONFIG(report_dir)/useful_skew_report.rpt
}

report_power -hierarchy > $CTS_CONFIG(report_dir)/power_postCTS.rpt

if {$CTS_CONFIG(generate_power_rpt)} {
    report_power -clock_tree > $CTS_CONFIG(report_dir)/clock_power.rpt
}

check_timing -verbose > $CTS_CONFIG(report_dir)/check_timing_postCTS.rpt
report_constraint -all_violators > $CTS_CONFIG(report_dir)/constraints_postCTS.rpt

if {$CTS_CONFIG(use_clock_gating)} {
    report_clock_gating -gating_elements \
        > $CTS_CONFIG(report_dir)/clock_gating.rpt
}

if {$CTS_CONFIG(generate_qor)} {
    report_qor > $CTS_CONFIG(report_dir)/qor_postCTS.rpt
}

log_message "INFO: Post-CTS reports generated"
}


proc save_postcts_design {} {
global CTS_CONFIG
print_section "Saving Post-CTS Design"

set checkpoint_path "$CTS_CONFIG(checkpoint_dir)/$CTS_CONFIG(save_postCTS)"
saveDesign $checkpoint_path
log_message "INFO: Database: $checkpoint_path"

defOut -routing $CTS_CONFIG(save_def)
log_message "INFO: DEF: $CTS_CONFIG(save_def)"

saveNetlist $CTS_CONFIG(save_netlist)
log_message "INFO: Netlist: $CTS_CONFIG(save_netlist)"

write_sdc $CTS_CONFIG(save_sdc)
log_message "INFO: SDC: $CTS_CONFIG(save_sdc)"
}

### CTS SUMM - Can add max_cap, max_tran, drc and other violations####
#### CTS SUMM - Can we check which nets are shielded and How much percentage? NDR applied or not
proc print_cts_summary {cts_runtime opt_runtime} {
global CTS_CONFIG
print_banner "CTS Flow Summary"

set total_runtime [expr {$cts_runtime + $opt_runtime}]

puts "\nRUNTIME:"
puts "  - CTS         : $cts_runtime seconds"
puts "  - Optimization: $opt_runtime seconds"
puts "  - Total       : $total_runtime seconds"

puts "\nCONFIGURATION:"
puts "  - Method          : CCOpt"
puts "  - Global Skew     : $CTS_CONFIG(global_skew) ns"
puts "  - Local Skew      : $CTS_CONFIG(local_skew) ns"
puts "  - Tree Structure  : $CTS_CONFIG(tree_structure)"
puts "  - Useful Skew     : $CTS_CONFIG(use_useful_skew)"
puts "  - SI-Aware        : $CTS_CONFIG(enable_si_aware)"
puts "  - OCV/CPPR        : $CTS_CONFIG(enable_ocv)/$CTS_CONFIG(enable_cppr)"

puts "\nOUTPUTS:"
puts "  - Reports: $CTS_CONFIG(report_dir)/"
puts "  - CTS Spec: $CTS_CONFIG(cts_spec_dir)/$CTS_CONFIG(cts_spec_file)"

set viol_counts [get_violation_count]
set final_setup_viol [lindex $viol_counts 0]
set final_hold_viol [lindex $viol_counts 1]

puts "\nTIMING STATUS:"
puts "  - Setup Violations: $final_setup_viol"
puts "  - Hold Violations : $final_hold_viol"

if {$final_setup_viol == 0 && $final_hold_viol == 0} {
    puts "\n✓ STATUS: CTS completed with CLEAN timing!"
} else {
    puts "\n⚠ WARNING: Violations present. Review reports."
}
}

