#####
#voltus_5nm_emir_signoff.tcl
#Both V=IR (Voltage drop) and J = I/A (current density)
############################################################
# Cadence Voltus – 5nm EM / IR Signoff Script
############################################################

##############################
# User Configuration
##############################
set DESIGN_NAME    ""
set TOP_CELL       ""

set TECH_LEF       ./inputs/tech.lef
set CELL_LEF       ./inputs/stdcell.lef
set MACRO_LEF      ./inputs/macro.lef
set DEF_FILE       ./inputs/design.def
set NETLIST        ./inputs/design.v
set LIB_FILE       ./inputs/design.lib

set ACTIVITY_PEAK  ./inputs/max_activity.saif
set ACTIVITY_TYP   ./inputs/typical_activity.saif

set REPORT_DIR     ./reports
set DATABASE_DIR   ./voltus_db
file mkdir $REPORT_DIR
file mkdir $DATABASE_DIR

##############################
# Load Design
##############################
read_liberty  $LIB_FILE
read_lef      $TECH_LEF
read_lef      $CELL_LEF
read_lef      $MACRO_LEF
read_verilog  $NETLIST
read_def      $DEF_FILE

set_top $TOP_CELL

##############################
# Power / Ground Definition
##############################
set_power_nets   {VDD}
set_ground_nets  {VSS}

# Always-on rails (important at 5nm)
set_always_on_nets {VDD VSS}

##############################
# Enable Voltus Signoff Engine
##############################
set_power_analysis_mode \
    -engine signoff \
    -accuracy high \
    -database_path $DATABASE_DIR

##############################
# Read Switching Activity
##############################
read_activity_file \
    -format saif \
    -file $ACTIVITY_PEAK \
    -top  $TOP_CELL \
    -mode peak

read_activity_file \
    -format saif \
    -file $ACTIVITY_TYP \
    -top  $TOP_CELL \
    -mode typical

##############################
# Power Modeling (5nm Specific)
##############################
# Use current-based modeling (mandatory at advanced nodes)
set_power_model \
    -type current \
    -use_effective_resistance true \
    -enable_temperature true

##############################
# Static IR Drop Analysis
##############################
analyze_power_grid \
    -analysis_type static \
    -power_nets {VDD} \
    -ground_nets {VSS} \
    -accuracy signoff

##############################
# Dynamic IR Drop Analysis
##############################
analyze_power_grid \
    -analysis_type dynamic \
    -power_nets {VDD} \
    -ground_nets {VSS} \
    -mode peak \
    -window 10ns \
    -step   100ps

##############################
# EM Analysis (5nm Signoff)
##############################
analyze_em \
    -power_nets {VDD} \
    -ground_nets {VSS} \
    -analysis_type dynamic \
    -mode peak \
    -temperature 125 \
    -aging_factor 1.1

##############################
# Reports – IR Drop
##############################
report_ir_drop \
    -analysis_type static \
    -power_nets {VDD} \
    -limit 0.03 \
    > $REPORT_DIR/static_ir_5nm.rpt

report_ir_drop \
    -analysis_type dynamic \
    -power_nets {VDD} \
    -limit 0.05 \
    > $REPORT_DIR/dynamic_ir_5nm.rpt

##############################
# Reports – EM
##############################
report_em \
    -power_nets {VDD} \
    -severity all \
    > $REPORT_DIR/em_5nm.rpt

##############################
# Hotspot Reports (Critical at 5nm)
##############################
report_power_hotspots \
    -threshold 0.9 \
    -power_nets {VDD} \
    > $REPORT_DIR/hotspots_5nm.rpt

##############################
# Final Summary
##############################
puts "========================================"
puts "5nm EM/IR SIGNOFF ANALYSIS COMPLETE"
puts "Reports available in $REPORT_DIR"
puts "========================================"
