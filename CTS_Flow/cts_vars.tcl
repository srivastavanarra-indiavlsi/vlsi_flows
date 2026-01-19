################################################################################
# FILE 1: cts_vars.tcl
# Clock Tree Synthesis Configuration Variables
################################################################################

################################################################################
# INPUT FILES - Post-Placement Database
################################################################################
set CTS_CONFIG(input_db)            "placement.enc"     ;# Post-placement database
set CTS_CONFIG(input_sdc)           "design.sdc"        ;# SDC constraints file
set CTS_CONFIG(load_db)             true                ;# Load existing database

################################################################################
# DESIGN INFORMATION
################################################################################
set CTS_CONFIG(design_name)         "my_design"
set CTS_CONFIG(top_module)          "top"

################################################################################
# CTS SPECIFICATION FILE
################################################################################
set CTS_CONFIG(cts_spec_file)       "cts_spec.tcl"      ;# Output CTS spec file
set CTS_CONFIG(dump_cts_spec)       true                ;# Dump CTS spec to file
set CTS_CONFIG(cts_spec_dir)        "specs"             ;# Directory for CTS specs

################################################################################
# CTS MODE - CCOpt
################################################################################
set CTS_CONFIG(use_ccopt)           true                ;# Use CCOpt method
set CTS_CONFIG(cts_method)          "ccopt"

################################################################################
# CTS TARGET SPECIFICATIONS
################################################################################
set CTS_CONFIG(target_skew)         0.100               ;# Target skew (ns)
set CTS_CONFIG(global_skew)         0.100               ;# Global skew target
set CTS_CONFIG(local_skew)          0.050               ;# Local skew target
set CTS_CONFIG(max_trans)           0.200               ;# Max transition (ns)
set CTS_CONFIG(max_cap)             0.300               ;# Max capacitance (pF)
set CTS_CONFIG(target_latency)      0.500               ;# Target insertion delay (ns)
set CTS_CONFIG(max_fanout)          32                  ;# Max fanout

################################################################################
# CLOCK BUFFER AND INVERTER CELLS
################################################################################
set CTS_CONFIG(buffer_cells)        {CLKBUF_X1 CLKBUF_X2 CLKBUF_X4 CLKBUF_X8 CLKBUF_X16}
set CTS_CONFIG(inverter_cells)      {CLKINV_X1 CLKINV_X2 CLKINV_X4 CLKINV_X8}
set CTS_CONFIG(excluded_buffers)    {CLKBUF_X32}
set CTS_CONFIG(root_buffer)         "CLKBUF_X8"
set CTS_CONFIG(leaf_buffer)         "CLKBUF_X2"
set CTS_CONFIG(auto_buffer_sizing)  true

################################################################################
# ADVANCED CLOCK TREE ARCHITECTURE
################################################################################
set CTS_CONFIG(tree_structure)      "auto"              ;# auto, hTree, spine, mesh
set CTS_CONFIG(use_useful_skew)     true
set CTS_CONFIG(use_data_driven)     true
set CTS_CONFIG(balance_mode)        "path_length"

# Advanced CCOpt options
set CTS_CONFIG(enable_si_aware)     true
set CTS_CONFIG(enable_ocv)          true
set CTS_CONFIG(enable_cppr)         true
set CTS_CONFIG(enable_aocv)         true

################################################################################
# USEFUL SKEW OPTIMIZATION
################################################################################
set CTS_CONFIG(useful_skew_mode)    "global"            ;# global, local, none
set CTS_CONFIG(useful_skew_ccopt)   "setup_and_hold"    ;# setup, hold, setup_and_hold
set CTS_CONFIG(max_useful_skew)     0.200

################################################################################
# CLOCK GATING
################################################################################
set CTS_CONFIG(integrate_icg)       true
set CTS_CONFIG(use_clock_gating)    true
set CTS_CONFIG(clock_gate_cells)    {CLKGATE_X1 CLKGATE_X2 CLKGATE_X4}
set CTS_CONFIG(icg_flow)            "concurrent"

################################################################################
# ROUTING CONFIGURATION
################################################################################
set CTS_CONFIG(shield_clocks)       true
set CTS_CONFIG(shield_nets)         "critical"
set CTS_CONFIG(ndr_name)            "clk_2W2S"
set CTS_CONFIG(ndr_spacing)         "2W2S"
set CTS_CONFIG(route_top_layer)     "M6"
set CTS_CONFIG(route_bot_layer)     "M3"
set CTS_CONFIG(preferred_layers)    {M4 M5}
set CTS_CONFIG(route_with_tieoff)   true
set CTS_CONFIG(enable_routing_eco)  true
set CTS_CONFIG(detailed_route_cts)  true

################################################################################
# OPTIMIZATION OPTIONS
################################################################################
set CTS_CONFIG(opt_hold)            true
set CTS_CONFIG(opt_setup)           true
set CTS_CONFIG(buffer_relocation)   true
set CTS_CONFIG(buffer_sizing)       true
set CTS_CONFIG(delay_insertion)     true
set CTS_CONFIG(power_priority)      "medium"
set CTS_CONFIG(power_opt)           true
set CTS_CONFIG(opt_area)            true
set CTS_CONFIG(fix_drc)             true
set CTS_CONFIG(fix_fanout_load)     true

################################################################################
# POWER OPTIMIZATION
################################################################################
set CTS_CONFIG(dynamic_power_opt)   true
set CTS_CONFIG(leakage_power_opt)   true
set CTS_CONFIG(clock_gate_aware)    true
set CTS_CONFIG(power_effort)        "high"
set CTS_CONFIG(multi_vt_opt)        true

################################################################################
# MCMM CONFIGURATION
################################################################################
set CTS_CONFIG(setup_views)         {view_wc_setup view_bc_setup}
set CTS_CONFIG(hold_views)          {view_wc_hold view_bc_hold}
set CTS_CONFIG(active_corners)      {corner_ss corner_ff corner_tt}
set CTS_CONFIG(update_mcmm)         true
set CTS_CONFIG(concurrent_mcmm)     true

################################################################################
# POST-CTS OPTIMIZATION
################################################################################
set CTS_CONFIG(postcts_effort)      "high"
set CTS_CONFIG(postcts_iterations)  3
set CTS_CONFIG(incremental_opt)     true
set CTS_CONFIG(slack_threshold)     -0.050
set CTS_CONFIG(postcts_detail_place) true
set CTS_CONFIG(postcts_route_opt)   true

################################################################################
# CLOCK-SPECIFIC SETTINGS
################################################################################
array set CTS_CONFIG(clock_specs) {
    clk_main    {0.080 0.150 auto}
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
set CTS_CONFIG(generate_power_rpt)  true

################################################################################
# OUTPUT FILES
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

puts "INFO: CTS configuration variables loaded!"

################################################################################
# END OF cts_vars.tcl
################################################################################


