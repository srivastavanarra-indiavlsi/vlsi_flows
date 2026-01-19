#!/bin/tclsh
###############################################################################
# Floorplan Main Script
# Description: Main script for physical design floorplan flow
# Author: Srivastava
# Date: December 2025
###############################################################################

puts "==========================================" ;# Print section header
puts "Starting Floorplan Setup" ;# Print status message
puts "==========================================" ;# Print section footer


### Can be a seperate file, bit for now
###############################################################################
# 1. DESIGN VARIABLES AND PATHS
###############################################################################

set DESIGN_NAME "my_design" ;# Name of the design block
set TOP_MODULE "top_module" ;# Top-level module name from netlist

# Directory paths
set NETLIST_DIR "./netlist" ;# Directory containing synthesized netlist
set SDC_DIR "./constraints" ;# Directory containing timing constraints
set TECH_DIR "./tech" ;# Directory containing technology files (LEF, etc.)
set DEF_DIR "./def" ;# Directory containing DEF files (pins, macros)
set SCRIPTS_DIR "./scripts" ;# Directory for scripts
set REPORTS_DIR "./reports" ;# Directory where reports will be saved
set RESULTS_DIR "./results" ;# Directory where output files will be saved

# Input files
set GATE_NETLIST "${NETLIST_DIR}/${DESIGN_NAME}_synth.v" ;# Path to gate-level netlist
set SDC_FILE "${SDC_DIR}/${DESIGN_NAME}.sdc" ;# Path to timing constraints file
set PIN_LOC_FILE "${DEF_DIR}/${DESIGN_NAME}_pins.def" ;# Path to pin location DEF file
set TECH_LEF "${TECH_DIR}/tech.lef" ;# Path to technology LEF file
set STD_CELL_LEF "${TECH_DIR}/stdcells.lef" ;# Path to standard cell LEF file
set IO_LEF "${TECH_DIR}/io.lef" ;# Path to IO cell LEF file
set MACRO_LEF_LIST "${TECH_DIR}/macros.lef" ;# Path to macro LEF files list

# Technology parameters
set TECH_NODE "28nm" ;# Technology node for the design
set CORE_UTILIZATION 0.70 ;# Target utilization (70% means 30% routing space)
set ASPECT_RATIO 1.0 ;# Core aspect ratio (1.0 = square, 2.0 = width/height)
set CORE_TO_IO_SPACING 10.0 ;# Spacing between core area and die boundary in microns

# Power/Ground net names
set VDD_NET "VDD" ;# Name of power supply net
set VSS_NET "VSS" ;# Name of ground net

# Subscript paths
set PIN_PLACEMENT_SCRIPT "${SCRIPTS_DIR}/pin_placement.tcl" ;# Path to pin placement script
set MACRO_PLACEMENT_SCRIPT "${SCRIPTS_DIR}/macro_placement.tcl" ;# Path to macro placement script
set POWER_GRID_SCRIPT "${SCRIPTS_DIR}/power_grid.tcl" ;# Path to power grid creation script

###############################################################################
# 2. CREATE DIRECTORIES
###############################################################################

proc create_directories {} { ;# Define procedure to create output directories
    global REPORTS_DIR RESULTS_DIR ;# Access global directory variables
    
    foreach dir [list $REPORTS_DIR $RESULTS_DIR] { ;# Loop through each directory
        if {![file exists $dir]} { ;# Check if directory doesn't exist
            file mkdir $dir ;# Create the directory
            puts "Created directory: $dir" ;# Print confirmation message
        }
    }
}

create_directories ;# Execute directory creation procedure

###############################################################################
# 3. LOAD TECHNOLOGY AND LIBRARIES
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Loading Technology Files" ;# Print section title
puts "==========================================" ;# Print section footer

# Read LEF files
if {[file exists $TECH_LEF]} { ;# Check if technology LEF file exists
    read_lef $TECH_LEF ;# Load technology LEF (layers, vias, design rules)
    puts "Loaded technology LEF: $TECH_LEF" ;# Print confirmation
} else { ;# If file doesn't exist
    puts "ERROR: Technology LEF not found: $TECH_LEF" ;# Print error message
    exit 1 ;# Exit script with error code
}

if {[file exists $STD_CELL_LEF]} { ;# Check if standard cell LEF exists
    read_lef $STD_CELL_LEF ;# Load standard cell library LEF (cell abstracts)
    puts "Loaded standard cell LEF: $STD_CELL_LEF" ;# Print confirmation
}

if {[file exists $IO_LEF]} { ;# Check if IO LEF exists
    read_lef $IO_LEF ;# Load IO pad library LEF (pad cell abstracts)
    puts "Loaded IO LEF: $IO_LEF" ;# Print confirmation
}

# Load macro LEFs if they exist
if {[file exists $MACRO_LEF_LIST]} { ;# Check if macro LEF list file exists
    set fp [open $MACRO_LEF_LIST r] ;# Open file for reading
    while {[gets $fp lef_file] >= 0} { ;# Read each line from file
        if {[file exists $lef_file]} { ;# Check if macro LEF file exists
            read_lef $lef_file ;# Load macro LEF (RAM, analog blocks, etc.)
            puts "Loaded macro LEF: $lef_file" ;# Print confirmation
        }
    }
    close $fp ;# Close the file handle
}

###############################################################################
# 4. READ SYNTHESIZED NETLIST
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Reading Synthesized Netlist" ;# Print section title
puts "==========================================" ;# Print section footer

if {[file exists $GATE_NETLIST]} { ;# Check if netlist file exists
    read_verilog $GATE_NETLIST ;# Read the gate-level Verilog netlist
    link_design $TOP_MODULE ;# Link/elaborate the top module and resolve references
    puts "Successfully loaded netlist: $GATE_NETLIST" ;# Print success message
    puts "Top module: $TOP_MODULE" ;# Print top module name
} else { ;# If netlist doesn't exist
    puts "ERROR: Netlist not found: $GATE_NETLIST" ;# Print error message
    exit 1 ;# Exit script with error code
}

###############################################################################
# 5. READ TIMING CONSTRAINTS (SDC)
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Reading Timing Constraints" ;# Print section title
puts "==========================================" ;# Print section footer

if {[file exists $SDC_FILE]} { ;# Check if SDC file exists
    read_sdc $SDC_FILE ;# Read SDC file (clocks, IO delays, timing exceptions)
    puts "Successfully loaded SDC: $SDC_FILE" ;# Print success message
    
    # Report constraints
    report_clock -all > ${REPORTS_DIR}/clocks.rpt ;# Generate report of all clock definitions
    report_timing_requirements > ${REPORTS_DIR}/timing_requirements.rpt ;# Generate timing constraints summary
} else { ;# If SDC doesn't exist
    puts "WARNING: SDC file not found: $SDC_FILE" ;# Print warning (not fatal)
}

###############################################################################
# 6. INITIALIZE FLOORPLAN
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Initializing Floorplan" ;# Print section title
puts "==========================================" ;# Print section footer

# Calculate die and core area
set total_cell_area [get_attribute [get_cells *] area] ;# Get total area of all cells in design
set core_area [expr {$total_cell_area / $CORE_UTILIZATION}] ;# Calculate core area based on utilization
set core_width [expr {sqrt($core_area * $ASPECT_RATIO)}] ;# Calculate core width from area and aspect ratio
set core_height [expr {$core_area / $core_width}] ;# Calculate core height from area and width

set die_width [expr {$core_width + 2 * $CORE_TO_IO_SPACING}] ;# Add spacing on left and right for die width
set die_height [expr {$core_height + 2 * $CORE_TO_IO_SPACING}] ;# Add spacing on top and bottom for die height

puts "Design Statistics:" ;# Print statistics header
puts "  Total cell area: $total_cell_area" ;# Print sum of all cell areas
puts "  Core utilization: $CORE_UTILIZATION" ;# Print target utilization percentage
puts "  Core dimensions: ${core_width} x ${core_height}" ;# Print core width and height
puts "  Die dimensions: ${die_width} x ${die_height}" ;# Print die width and height

# Initialize floorplan
initialize_floorplan \
    -die_area "0 0 $die_width $die_height" \
    -core_area "$CORE_TO_IO_SPACING $CORE_TO_IO_SPACING \
                [expr {$die_width - $CORE_TO_IO_SPACING}] \
                [expr {$die_height - $CORE_TO_IO_SPACING}]" \
    -site unit ;# Specify placement site (from LEF)

puts "Floorplan initialized successfully" ;# Print success message

###############################################################################
# 7. CALL PIN PLACEMENT SCRIPT
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Calling Pin Placement Script" ;# Print section title
puts "==========================================" ;# Print section footer

if {[file exists $PIN_PLACEMENT_SCRIPT]} { ;# Check if pin placement script exists
    source $PIN_PLACEMENT_SCRIPT ;# Execute pin placement script
    puts "Pin placement script completed" ;# Print completion message
} else { ;# If script doesn't exist
    puts "WARNING: Pin placement script not found: $PIN_PLACEMENT_SCRIPT" ;# Print warning
    puts "Skipping pin placement step" ;# Inform about skipping
}

###############################################################################
# 8. CALL MACRO PLACEMENT SCRIPT
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Calling Macro Placement Script" ;# Print section title
puts "==========================================" ;# Print section footer

if {[file exists $MACRO_PLACEMENT_SCRIPT]} { ;# Check if macro placement script exists
    source $MACRO_PLACEMENT_SCRIPT ;# Execute macro placement script
    puts "Macro placement script completed" ;# Print completion message
} else { ;# If script doesn't exist
    puts "WARNING: Macro placement script not found: $MACRO_PLACEMENT_SCRIPT" ;# Print warning
    puts "Skipping macro placement step" ;# Inform about skipping
}

###############################################################################
# 9. CALL POWER GRID SCRIPT
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Calling Power Grid Script" ;# Print section title
puts "==========================================" ;# Print section footer

if {[file exists $POWER_GRID_SCRIPT]} { ;# Check if power grid script exists
    source $POWER_GRID_SCRIPT ;# Execute power grid creation script
    puts "Power grid script completed" ;# Print completion message
} else { ;# If script doesn't exist
    puts "WARNING: Power grid script not found: $POWER_GRID_SCRIPT" ;# Print warning
    puts "Skipping power grid creation step" ;# Inform about skipping
}

###############################################################################
# 10. CREATE PLACEMENT BLOCKAGES
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Creating Placement Blockages" ;# Print section title
puts "==========================================" ;# Print section footer

# Get list of macros (may have been placed by macro script)
set macros [get_cells -hierarchical -filter "is_hard_macro==true"] ;# Get list of all hard macros

# Block placement around macros
if {[llength $macros] > 0} { ;# Check if macros exist
    foreach macro $macros { ;# Loop through each macro in the design
        set bbox [get_attribute $macro bbox] ;# Get bounding box coordinates of macro
        set halo 2.0 ;# Define halo distance around macro in microns
        create_placement_blockage \
            -bbox "[expr [lindex $bbox 0] - $halo] \
                   [expr [lindex $bbox 1] - $halo] \
                   [expr [lindex $bbox 2] + $halo] \
                   [expr [lindex $bbox 3] + $halo]" ;# Create blockage with halo around macro
    }
    puts "Placement blockages created around [llength $macros] macros" ;# Print confirmation
} else { ;# If no macros
    puts "No macros found - no placement blockages created" ;# Print info message
}

###############################################################################
# 11. CREATE ROUTING BLOCKAGES (if needed)
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Creating Routing Blockages" ;# Print section title
puts "==========================================" ;# Print section footer

# Example: Block routing in specific areas
# create_routing_blockage -layers "M1 M2" -bbox "100 100 200 200" ;# Block M1 and M2 routing in specified rectangle

puts "Routing blockages configured" ;# Print confirmation message

###############################################################################
# 12. GENERATE REPORTS
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Generating Reports" ;# Print section title
puts "==========================================" ;# Print section footer

report_design_area > ${REPORTS_DIR}/design_area.rpt ;# Generate report of die/core area and utilization
report_floorplan > ${REPORTS_DIR}/floorplan.rpt ;# Generate comprehensive floorplan summary report
report_power_grid > ${REPORTS_DIR}/power_grid.rpt ;# Generate power grid structure and connectivity report
report_placement_utilization > ${REPORTS_DIR}/placement_util.rpt ;# Generate report of placement density and utilization

puts "Reports generated in: $REPORTS_DIR" ;# Print location where reports were saved

###############################################################################
# 13. SAVE FLOORPLAN
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Saving Floorplan" ;# Print section title
puts "==========================================" ;# Print section footer

# Save DEF
write_def ${RESULTS_DIR}/${DESIGN_NAME}_floorplan.def ;# Save floorplan in DEF format (standard exchange format)
puts "Saved DEF: ${RESULTS_DIR}/${DESIGN_NAME}_floorplan.def" ;# Print DEF file path

# Save design database
save_design ${RESULTS_DIR}/${DESIGN_NAME}_floorplan.db ;# Save complete design database (tool-specific format)
puts "Saved database: ${RESULTS_DIR}/${DESIGN_NAME}_floorplan.db" ;# Print database file path

###############################################################################
# 14. FINAL CHECKS
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Running Final Checks" ;# Print section title
puts "==========================================" ;# Print section footer

check_design > ${REPORTS_DIR}/check_design.rpt ;# Check for design issues (unconnected pins, missing cells, etc.)
check_floorplan > ${REPORTS_DIR}/check_floorplan.rpt ;# Check floorplan validity (overlaps, violations, etc.)

puts "\n==========================================" ;# Print final section header
puts "Floorplan Setup Complete!" ;# Print success message
puts "==========================================" ;# Print section footer
puts "Output files:" ;# Print output files header
puts "  DEF: ${RESULTS_DIR}/${DESIGN_NAME}_floorplan.def" ;# Print DEF file path
puts "  Database: ${RESULTS_DIR}/${DESIGN_NAME}_floorplan.db" ;# Print database file path
puts "  Reports: ${REPORTS_DIR}/" ;# Print reports directory path
puts "==========================================" ;# Print final section footer
