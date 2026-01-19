#!/usr/bin/tclsh
#==============================================================================
# Basic Placement Script for Cadence Innovus
# Simple and straightforward placement flow
#==============================================================================

set DESIGN_NAME "my_design"

puts "=========================================="
puts "Starting Basic Placement"
puts "Design: $DESIGN_NAME"
puts "=========================================="

#------------------------------------------------------------------------------
# Step 1: Check if design is loaded
#------------------------------------------------------------------------------
if {[dbGet top.name] == ""} {
    puts "ERROR: No design loaded. Please load design first."
    puts "Example:"
    puts "  set init_lef_file \{tech.lef stdcells.lef\}"
    puts "  set init_verilog netlist.v"
    puts "  set init_top_cell $DESIGN_NAME"
    puts "  init_design"
    exit 1
}

puts "\nDesign loaded: [dbGet top.name]"

#------------------------------------------------------------------------------
# Step 2: Set Placement Mode
#------------------------------------------------------------------------------
puts "\n--- Setting Placement Mode ---"

# Reset to defaults
setPlaceMode -reset

# Basic settings
setPlaceMode -place_global_place_io_pins false
setPlaceMode -timingDriven true
setPlaceMode -congEffort medium

puts "Placement mode configured"

#------------------------------------------------------------------------------
# Step 3: Add Macro Halos (if macros exist)
#------------------------------------------------------------------------------
set macros [dbGet top.insts.cell.subClass block -p2]
if {[llength $macros] > 0} {
    puts "\n--- Adding Macro Halos ---"
    foreach macro $macros {
        set inst_name [dbGet $macro.name]
        puts "  Macro: $inst_name"
        # Add 2um halo on all sides
        addHaloToBlock 2 2 2 2 $inst_name
    }
}

#------------------------------------------------------------------------------
# Step 4: Run Placement
#------------------------------------------------------------------------------
puts "\n--- Running Placement ---"

# Place standard cells
place_design

puts "Placement completed"

#------------------------------------------------------------------------------
# Step 5: Check Placement
#------------------------------------------------------------------------------
puts "\n--- Checking Placement ---"

# Check legality
checkPlace ${DESIGN_NAME}.check

# Report statistics
puts "\nPlacement Statistics:"
puts "  Total Instances: [dbGet top.numInsts]"
puts "  Placed: [llength [dbGet top.insts.pStatus placed -p]]"
puts "  Fixed: [llength [dbGet top.insts.pStatus fixed -p]]"

set core_area [expr {[dbGet top.fPlan.coreBox_area] / 1000000.0}]
set cell_area [expr {[dbGet top.stdCellArea] / 1000000.0}]
set util [expr {($cell_area / $core_area) * 100.0}]
puts "  Utilization: [format "%.2f" $util]%"

#------------------------------------------------------------------------------
# Step 6: Save Results
#------------------------------------------------------------------------------
puts "\n--- Saving Results ---"

# Create output directory
file mkdir ./results

# Save design
saveDesign ./results/${DESIGN_NAME}_placed.enc

# Write DEF
defOut -floorplan -netlist ./results/${DESIGN_NAME}_placed.def

puts "\nResults saved to ./results/"

puts "\n=========================================="
puts "Basic Placement Completed Successfully"
puts "=========================================="
