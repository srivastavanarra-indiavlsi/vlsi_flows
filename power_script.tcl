########################################################
# Post-Synthesis Power Script (PrimeTime-PX)
# Static + Dynamic Power
########################################################

########################
# User Variables
########################
set DESIGN_NAME   my_design
set TOP_MODULE    my_design

set NETLIST       ./netlist/design_syn.v
set LIBRARY       ./lib/slow.lib

# Optional switching activity
set SAIF_FILE     ./activity/design.saif
set SAIF_INSTANCE $TOP_MODULE

# Output
set REPORT_DIR    ./reports
file mkdir $REPORT_DIR

########################
# Read Design
########################
set_app_var search_path [list ./lib ./netlist]
set_app_var target_library [list $LIBRARY]
set_app_var link_library   "* $LIBRARY"

read_verilog $NETLIST
current_design $TOP_MODULE
link_design

########################
# Power Analysis Setup
########################
set_power_analysis_mode -analysis_type time_based

########################
# Read Switching Activity (If Available)
########################
if {[file exists $SAIF_FILE]} {
    puts "INFO: Using SAIF activity file"
    read_saif \
        -input $SAIF_FILE \
        -instance_name $SAIF_INSTANCE
} else {
    puts "WARNING: SAIF not found – using vectorless defaults"
}

########################
# Vectorless Defaults (Fallback)
########################
# Nets
set_switching_activity \
    -default_toggle_rate 0.1 \
    -default_static_probability 0.5 \
    -type nets

# Registers
set_switching_activity \
    -default_toggle_rate 0.2 \
    -default_static_probability 0.5 \
    -type registers

# Clocks (must toggle every cycle)
set_switching_activity \
    -toggle_rate 1.0 \
    -static_probability 0.5 \
    [get_clocks *]

########################
# Update Power
########################
update_power

########################
# Extract Power Numbers
########################
set total_power   [get_power -total   [current_design]]
set dynamic_power [get_power -dynamic [current_design]]
set leakage_power [get_power -leakage [current_design]]

# Convert W → mW
set total_mw   [expr {$total_power   * 1000}]
set dynamic_mw [expr {$dynamic_power * 1000}]
set leakage_mw [expr {$leakage_power * 1000}]

########################
# Print Results
########################
puts "========================================"
puts "Post-Synthesis Power Summary (mW)"
puts "========================================"
puts "Total Power   : [format %.3f $total_mw]"
puts "Dynamic Power : [format %.3f $dynamic_mw]"
puts "Leakage Power : [format %.3f $leakage_mw]"
puts "========================================"

########################
# Save Report
########################
set rpt_file "$REPORT_DIR/power_summary.rpt"
set fp [open $rpt_file w]

puts $fp "Post-Synthesis Power Summary (mW)"
puts $fp "--------------------------------"
puts $fp "Total Power   : [format %.3f $total_mw]"
puts $fp "Dynamic Power : [format %.3f $dynamic_mw]"
puts $fp "Leakage Power : [format %.3f $leakage_mw]"

close $fp

puts "INFO: Power report written to $rpt_file"

