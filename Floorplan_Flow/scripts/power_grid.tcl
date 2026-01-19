####
#!/bin/tclsh
###############################################################################
# Power Grid Creation Script
# Description: Creates complete power distribution network
# Author: Design Team
# Date: December 2025
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Power Grid Creation Module" ;# Print module title
puts "==========================================" ;# Print section footer

###############################################################################
# POWER GRID CONFIGURATION
###############################################################################

# Power/Ground net names (should be defined in main script, but set defaults here)
if {![info exists VDD_NET]} { ;# Check if VDD_NET variable exists
    set VDD_NET "VDD" ;# Set default power net name
}
if {![info exists VSS_NET]} { ;# Check if VSS_NET variable exists
    set VSS_NET "VSS" ;# Set default ground net name
}

# Power ring parameters
set RING_HOR_LAYER "M6" ;# Metal layer for horizontal power ring segments
set RING_VER_LAYER "M7" ;# Metal layer for vertical power ring segments
set RING_WIDTH 2.0 ;# Width of power ring traces (microns)
set RING_SPACING 1.0 ;# Spacing between VDD and VSS rings (microns)
set RING_OFFSET 5.0 ;# Distance from core boundary to inner edge of ring (microns)

# Power stripe parameters - M1 (standard cell rails)
set STRIPE_WIDTH_M1 0.5 ;# Width of M1 standard cell power rails (microns)

# Power stripe parameters - M4 (vertical stripes)
set STRIPE_WIDTH_M4 1.0 ;# Width of M4 power stripes (microns)
set STRIPE_PITCH_M4 20.0 ;# Pitch between M4 stripe centers (microns)
set STRIPE_START_M4 10.0 ;# Offset of first M4 stripe from core edge (microns)

# Power stripe parameters - M7 (horizontal stripes)
set STRIPE_WIDTH_M7 2.0 ;# Width of M7 power stripes (microns)
set STRIPE_PITCH_M7 40.0 ;# Pitch between M7 stripe centers (microns)
set STRIPE_START_M7 10.0 ;# Offset of first M7 stripe from core edge (microns)

###############################################################################
# CREATE POWER RINGS
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Creating Power Rings" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Create power rings around core area
create_power_ring \
    -nets "$VDD_NET $VSS_NET" \ ;# Create rings for both power and ground nets
    -horizontal_layer $RING_HOR_LAYER \ ;# Use M6 for horizontal ring segments
    -horizontal_width $RING_WIDTH \ ;# Set horizontal ring width
    -horizontal_spacing $RING_SPACING \ ;# Set spacing between VDD and VSS horizontal segments
    -vertical_layer $RING_VER_LAYER \ ;# Use M7 for vertical ring segments
    -vertical_width $RING_WIDTH \ ;# Set vertical ring width
    -vertical_spacing $RING_SPACING \ ;# Set spacing between VDD and VSS vertical segments
    -offset $RING_OFFSET \ ;# Place ring inside core boundary
    -extend_to_boundary ;# Extend ring to reach core boundary

puts "Power rings created on layers: $RING_HOR_LAYER (horizontal), $RING_VER_LAYER (vertical)" ;# Print confirmation

# Optional: Create additional rings around macros
set macros [get_cells -hierarchical -filter "is_hard_macro==true"] ;# Get list of all hard macros
if {[llength $macros] > 0} { ;# Check if macros exist
    puts "Creating power rings around [llength $macros] macros..." ;# Print info message
    
    foreach macro $macros { ;# Loop through each macro
        # Create ring around each macro for robust power delivery
        create_power_ring \
            -around $macro \ ;# Create ring around specific macro
            -nets "$VDD_NET $VSS_NET" \ ;# Create for both power and ground
            -horizontal_layer "M5" \ ;# Use M5 for horizontal segments around macro
            -horizontal_width 1.0 \ ;# Set width for macro ring
            -horizontal_spacing 0.5 \ ;# Set spacing between VDD and VSS
            -vertical_layer "M6" \ ;# Use M6 for vertical segments around macro
            -vertical_width 1.0 \ ;# Set width for macro ring
            -vertical_spacing 0.5 \ ;# Set spacing between VDD and VSS
            -offset 1.0 ;# Place ring 1.0um away from macro boundary
    }
    
    puts "Macro power rings created" ;# Print confirmation
}

###############################################################################
# CREATE POWER STRIPES - M1 LAYER (Standard Cell Rails)
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Creating M1 Power Rails" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# M1 rails are typically handled automatically during standard cell placement
# This section can be used to verify or explicitly create M1 rails

# Note: Most tools auto-generate M1 rails during placement
puts "M1 power rails will be created during standard cell placement" ;# Print info message

###############################################################################
# CREATE POWER STRIPES - M4 LAYER (Vertical Stripes)
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Creating M4 Vertical Power Stripes" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Create VDD stripes on M4
create_power_stripes \
    -nets $VDD_NET \ ;# Create stripes for power net
    -layer "M4" \ ;# Use M4 metal layer
    -width $STRIPE_WIDTH_M4 \ ;# Set stripe width
    -pitch $STRIPE_PITCH_M4 \ ;# Set distance between stripe centers
    -direction vertical \ ;# Create vertical stripes
    -start_offset $STRIPE_START_M4 \ ;# Start first stripe at this offset from left edge
    -extend_to_boundary ;# Extend stripes to core boundary

puts "Created VDD stripes on M4" ;# Print confirmation

# Create VSS stripes on M4 (interleaved with VDD)
create_power_stripes \
    -nets $VSS_NET \ ;# Create stripes for ground net
    -layer "M4" \ ;# Use M4 metal layer
    -width $STRIPE_WIDTH_M4 \ ;# Set stripe width
    -pitch $STRIPE_PITCH_M4 \ ;# Set distance between stripe centers (same as VDD)
    -direction vertical \ ;# Create vertical stripes
    -start_offset [expr {$STRIPE_START_M4 + $STRIPE_WIDTH_M4 + $RING_SPACING}] \ ;# Offset from VDD by width + spacing
    -extend_to_boundary ;# Extend stripes to core boundary

puts "Created VSS stripes on M4" ;# Print confirmation
puts "M4 stripes: Width=${STRIPE_WIDTH_M4}um, Pitch=${STRIPE_PITCH_M4}um" ;# Print stripe parameters

###############################################################################
# CREATE POWER STRIPES - M7 LAYER (Horizontal Stripes)
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Creating M7 Horizontal Power Stripes" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Create VDD stripes on M7 (orthogonal to M4)
create_power_stripes \
    -nets $VDD_NET \ ;# Create stripes for power net
    -layer "M7" \ ;# Use M7 metal layer (top thick metal)
    -width $STRIPE_WIDTH_M7 \ ;# Set stripe width (wider for lower resistance)
    -pitch $STRIPE_PITCH_M7 \ ;# Set distance between stripe centers
    -direction horizontal \ ;# Create horizontal stripes (orthogonal to M4)
    -start_offset $STRIPE_START_M7 \ ;# Start first stripe at this offset from bottom edge
    -extend_to_boundary ;# Extend stripes to core boundary

puts "Created VDD stripes on M7" ;# Print confirmation

# Create VSS stripes on M7 (interleaved with VDD)
create_power_stripes \
    -nets $VSS_NET \ ;# Create stripes for ground net
    -layer "M7" \ ;# Use M7 metal layer
    -width $STRIPE_WIDTH_M7 \ ;# Set stripe width
    -pitch $STRIPE_PITCH_M7 \ ;# Set distance between stripe centers (same as VDD)
    -direction horizontal \ ;# Create horizontal stripes
    -start_offset [expr {$STRIPE_START_M7 + $STRIPE_WIDTH_M7 + $RING_SPACING}] \ ;# Offset from VDD by width + spacing
    -extend_to_boundary ;# Extend stripes to core boundary

puts "Created VSS stripes on M7" ;# Print confirmation
puts "M7 stripes: Width=${STRIPE_WIDTH_M7}um, Pitch=${STRIPE_PITCH_M7}um" ;# Print stripe parameters

###############################################################################
# CONNECT POWER GRID LAYERS
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Connecting Power Grid Layers" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Create vias to connect all power grid layers
connect_power_grid \
    -all \ ;# Connect all power/ground nets across all layers
    -verbose ;# Print detailed connection information

puts "Power grid layers connected with vias" ;# Print confirmation

# Verify power grid connectivity
if {[catch {verify_power_grid -nets "$VDD_NET $VSS_NET"} err]} { ;# Try to verify connectivity
    puts "WARNING: Power grid verification failed: $err" ;# Print warning if verification fails
} else { ;# If verification succeeds
    puts "Power grid connectivity verified" ;# Print success message
}

###############################################################################
# CONNECT MACROS TO POWER GRID
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Connecting Macros to Power Grid" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Connect macro power pins to power grid
set macros [get_cells -hierarchical -filter "is_hard_macro==true"] ;# Get list of all hard macros

if {[llength $macros] > 0} { ;# Check if macros exist
    foreach macro $macros { ;# Loop through each macro
        # Connect macro VDD pins
        connect_macro_to_power_grid \
            -macro $macro \ ;# Specify macro to connect
            -power_net $VDD_NET \ ;# Connect to power net
            -ground_net $VSS_NET ;# Connect to ground net
    }
    
    puts "Connected [llength $macros] macros to power grid" ;# Print confirmation
} else { ;# If no macros
    puts "No macros to connect" ;# Print info message
}

###############################################################################
# POWER GRID ANALYSIS
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Power Grid Analysis" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Calculate total metal usage for power grid
set power_metal_area [get_power_grid_metal_area] ;# Get total area used by power grid

# Report power grid statistics
puts "\nPower Grid Statistics:" ;# Print statistics header
puts "  Power nets: $VDD_NET, $VSS_NET" ;# Print power net names
puts "  Ring layers: $RING_HOR_LAYER (H), $RING_VER_LAYER (V)" ;# Print ring layers
puts "  Stripe layers: M4 (vertical), M7 (horizontal)" ;# Print stripe layers
puts "  M4 pitch: ${STRIPE_PITCH_M4}um" ;# Print M4 pitch
puts "  M7 pitch: ${STRIPE_PITCH_M7}um" ;# Print M7 pitch
# puts "  Total metal area: $power_metal_area" ;# Print total metal usage (if available)

###############################################################################
# GENERATE POWER GRID REPORTS
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Generating Power Grid Reports" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

report_power_grid > ${REPORTS_DIR}/power_grid_detailed.rpt ;# Generate detailed power grid structure report
report_power_grid_connectivity > ${REPORTS_DIR}/power_grid_connectivity.rpt ;# Generate connectivity verification report

puts "Power grid reports generated:" ;# Print header
puts "  - ${REPORTS_DIR}/power_grid_detailed.rpt" ;# Print report path
puts "  - ${REPORTS_DIR}/power_grid_connectivity.rpt" ;# Print report path

###############################################################################
# OPTIONAL: IR DROP ANALYSIS SETUP
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "IR Drop Analysis Setup" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Set up for IR drop analysis (typically done after placement)
# set_power_analysis_mode -method static ;# Set analysis method
# set_power_analysis_mode -corner max ;# Set corner for worst-case analysis
# analyze_power_grid -net $VDD_NET ;# Analyze power grid for IR drop
# analyze_power_grid -net $VSS_NET ;# Analyze ground grid for IR drop

puts "IR drop analysis can be performed after placement" ;# Print info message

puts "\nPower Grid Creation Module Complete" ;# Print completion message
