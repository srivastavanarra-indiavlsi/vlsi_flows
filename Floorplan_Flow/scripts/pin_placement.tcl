####
#!/bin/tclsh
###############################################################################
# Pin Placement Script
# Description: Handles pin placement for the design
# Author: Design Team
# Date: December 2025
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Pin Placement Module" ;# Print module title
puts "==========================================" ;# Print section footer

###############################################################################
# PIN PLACEMENT CONFIGURATION
###############################################################################

# Pin placement parameters
set PIN_LAYER_HOR "M4" ;# Metal layer for horizontal pins
set PIN_LAYER_VER "M5" ;# Metal layer for vertical pins
set PIN_CORNER_AVOID 5.0 ;# Keep pins away from corners by this distance (microns)
set PIN_MIN_DISTANCE 2.0 ;# Minimum spacing between adjacent pins (microns)

# Side-specific pin constraints
set NORTH_LAYERS "M4" ;# Metal layers allowed on north side
set SOUTH_LAYERS "M4" ;# Metal layers allowed on south side
set EAST_LAYERS "M5" ;# Metal layers allowed on east side
set WEST_LAYERS "M5" ;# Metal layers allowed on west side

###############################################################################
# IMPORT OR AUTO-PLACE PINS
###############################################################################

if {[file exists $PIN_LOC_FILE]} { ;# Check if pin location DEF file exists
    puts "Importing pin locations from: $PIN_LOC_FILE" ;# Print info message
    
    # Read pin locations from DEF file
    read_def $PIN_LOC_FILE ;# Import pre-defined pin locations from DEF
    puts "Successfully imported pin locations" ;# Print success message
    
} else { ;# If pin location file doesn't exist
    puts "Pin location file not found: $PIN_LOC_FILE" ;# Print info message
    puts "Using automatic pin placement..." ;# Inform about fallback method
    
    ###########################################################################
    # AUTOMATIC PIN PLACEMENT
    ###########################################################################
    
    # Basic automatic pin placement
    place_pins \
        -hor_layers $PIN_LAYER_HOR \ ;# Use M4 for horizontal pins
        -ver_layers $PIN_LAYER_VER \ ;# Use M5 for vertical pins
        -corner_avoidance $PIN_CORNER_AVOID \ ;# Keep pins away from corners
        -min_distance $PIN_MIN_DISTANCE ;# Maintain minimum spacing between pins
    
    puts "Automatic pin placement completed" ;# Print completion message
    
    ###########################################################################
    # OPTIONAL: PIN GROUPING AND CONSTRAINTS
    ###########################################################################
    
    # Example: Group related pins together
    # set clock_pins [get_ports clk*] ;# Get all clock ports
    # if {[llength $clock_pins] > 0} { ;# Check if clock pins exist
    #     set_pin_group -pins $clock_pins -side bottom ;# Place clock pins on bottom side
    # }
    
    # Example: Place specific pins on specific sides
    # set_pin_constraints -ports [get_ports data_in*] -side left ;# Place data input on left
    # set_pin_constraints -ports [get_ports data_out*] -side right ;# Place data output on right
    # set_pin_constraints -ports [get_ports clk] -side bottom ;# Place clock on bottom
    # set_pin_constraints -ports [get_ports rst_n] -side bottom ;# Place reset on bottom
    
    # Re-run pin placement with constraints
    # place_pins \
    #     -hor_layers $PIN_LAYER_HOR \
    #     -ver_layers $PIN_LAYER_VER \
    #     -corner_avoidance $PIN_CORNER_AVOID \
    #     -min_distance $PIN_MIN_DISTANCE
}

###############################################################################
# PIN PLACEMENT VERIFICATION
###############################################################################

# Get pin statistics
set total_pins [llength [get_ports *]] ;# Count total number of design pins/ports
set input_pins [llength [get_ports * -filter "direction==in"]] ;# Count input pins
set output_pins [llength [get_ports * -filter "direction==out"]] ;# Count output pins
set inout_pins [llength [get_ports * -filter "direction==inout"]] ;# Count bidirectional pins

puts "\nPin Statistics:" ;# Print statistics header
puts "  Total pins: $total_pins" ;# Print total pin count
puts "  Input pins: $input_pins" ;# Print input pin count
puts "  Output pins: $output_pins" ;# Print output pin count
puts "  Inout pins: $inout_pins" ;# Print bidirectional pin count

###############################################################################
# CHECK PIN PLACEMENT
###############################################################################

# Check for pin placement issues
if {[catch {check_pin_placement} err]} { ;# Try to check pin placement
    puts "WARNING: Pin placement check failed: $err" ;# Print warning if check fails
} else { ;# If check succeeds
    puts "Pin placement check passed" ;# Print success message
}

###############################################################################
# SAVE PIN PLACEMENT
###############################################################################

# Optionally save pin placement to DEF for future use
set pin_def_output "${DEF_DIR}/${DESIGN_NAME}_pins_generated.def" ;# Define output path
write_def -pins_only $pin_def_output ;# Save only pin information to DEF file
puts "Pin placement saved to: $pin_def_output" ;# Print confirmation

###############################################################################
# GENERATE PIN REPORTS
###############################################################################

report_pin_placement > ${REPORTS_DIR}/pin_placement.rpt ;# Generate detailed pin placement report
puts "Pin placement report generated: ${REPORTS_DIR}/pin_placement.rpt" ;# Print report location

puts "\nPin Placement Module Complete" ;# Print completion message
