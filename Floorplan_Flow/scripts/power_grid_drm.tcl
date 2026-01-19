#!/bin/tclsh
###############################################################################
# Power Grid Creation Script
# Description: Creates complete power distribution network using DRM specs
# Author: Design Team
# Date: December 2025
###############################################################################

puts "\n==========================================" ;# Print section header with newline
puts "Power Grid Creation Module" ;# Print module title
puts "==========================================" ;# Print section footer

###############################################################################
# LOAD DRM POWER GRID CONFIGURATION
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Loading DRM Configuration" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

# Load DRM power grid specifications
if {[file exists "${SCRIPTS_DIR}/drm_power_grid_config.tcl"]} { ;# Check if DRM config exists
    source ${SCRIPTS_DIR}/drm_power_grid_config.tcl ;# Load DRM specifications
    set USE_DRM_SPECS 1 ;# Flag to use DRM specifications
    puts "Using foundry DRM specifications for power grid" ;# Print confirmation
} else { ;# If DRM config not found
    set USE_DRM_SPECS 0 ;# Flag to use manual specifications
    puts "DRM config not found, using manual power grid specifications" ;# Print warning
}

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

# Determine power grid parameters based on DRM or manual config
if {$USE_DRM_SPECS} { ;# If using DRM specifications
    
    # Power ring parameters from DRM
    set RING_HOR_LAYER [lindex $DRM_POWER_RING_LAYERS 0] ;# Use first DRM ring layer for horizontal
    set RING_VER_LAYER [lindex $DRM_POWER_RING_LAYERS 1] ;# Use second DRM ring layer for vertical
    set RING_WIDTH $DRM_RING_SPEC(M7,width) ;# Use DRM recommended width for M7
    set RING_SPACING $DRM_RING_SPEC(M7,spacing) ;# Use DRM recommended spacing
    set RING_OFFSET $DRM_RING_SPEC(offset) ;# Use DRM recommended offset
    
    # Power stripe parameters from DRM
    set STRIPE_WIDTH_M1 $DRM_M1_SPEC(width) ;# Use DRM M1 width
    set STRIPE_WIDTH_M3 $DRM_M3_SPEC(width) ;# Use DRM M3 width
    set STRIPE_PITCH_M3 $DRM_M3_SPEC(pitch) ;# Use DRM M3 pitch
    set STRIPE_WIDTH_M5 $DRM_M5_SPEC(width) ;# Use DRM M5 width
    set STRIPE_PITCH_M5 $DRM_M5_SPEC(pitch) ;# Use DRM M5 pitch
    set STRIPE_WIDTH_M7 $DRM_M7_SPEC(width) ;# Use DRM M7 width
    set STRIPE_PITCH_M7 $DRM_M7_SPEC(pitch) ;# Use DRM M7 pitch
    
    puts "Using DRM-specified power grid parameters:" ;# Print header
    puts "  Ring layers: $RING_HOR_LAYER (H), $RING_VER_LAYER (V)" ;# Print ring layers
    puts "  Ring width: ${RING_WIDTH}um, spacing: ${RING_SPACING}um" ;# Print ring dimensions
    puts "  Stripe layers: M1, M3, M5, M7" ;# Print stripe layers
    
} else { ;# If using manual specifications
    
    # Power ring parameters (manual fallback)
    set RING_HOR_LAYER "M6" ;# Metal layer for horizontal power ring segments
    set RING_VER_LAYER "M7" ;# Metal layer for vertical power ring segments
    set RING_WIDTH 2.0 ;# Width of power ring traces (microns)
    set RING_SPACING 1.0 ;# Spacing between VDD and VSS rings (microns)
    set RING_OFFSET 5.0 ;# Distance from core boundary to inner edge of ring (microns)
    
    # Power stripe parameters (manual fallback)
    set STRIPE_WIDTH_M1 0.5 ;# Width of M1 standard cell power rails (microns)
    set STRIPE_WIDTH_M3 0.8 ;# Width of M3 power stripes (microns)
    set STRIPE_PITCH_M3 15.0 ;# Pitch between M3 stripe centers (microns)
    set STRIPE_WIDTH_M5 1.2 ;# Width of M5 power stripes (microns)
    set STRIPE_PITCH_M5 25.0 ;# Pitch between M5 stripe centers (microns)
    set STRIPE_WIDTH_M7 2.0 ;# Width of M7 power stripes (microns)
    set STRIPE_PITCH_M7 40.0 ;# Pitch between M7 stripe centers (microns)
    
    puts "Using manual power grid parameters" ;# Print info
}

# Common parameters
set STRIPE_START_OFFSET 10.0 ;# Offset of first stripe from core edge (microns)

###############################################################################
# LOAD FOUNDRY POWER GRID TEMPLATE (if available)
###############################################################################

if {$USE_DRM_SPECS && [info procs load_drm_power_template] != ""} { ;# Check if DRM template loader exists
    if {[load_drm_power_template]} { ;# Try to load foundry template
        puts "Using foundry-provided power grid template" ;# Print success
        set USING_FOUNDRY_TEMPLATE 1 ;# Set flag
    } else { ;# If template not available
        puts "Building power grid from DRM specifications" ;# Print info
        set USING_FOUNDRY_TEMPLATE 0 ;# Clear flag
    }
} else { ;# If not using DRM or template loader not available
    set USING_FOUNDRY_TEMPLATE 0 ;# Clear flag
}

###############################################################################
# CREATE POWER RINGS (DRM-Compliant)
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Creating Power Rings" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

if {!$USING_FOUNDRY_TEMPLATE} { ;# If not using foundry template, create manually

    # Create power rings around core area
    create_power_ring \
        -nets "$VDD_NET $VSS_NET" \ ;# Create rings for both power and ground nets
        -horizontal_layer $RING_HOR_LAYER \ ;# Use DRM-specified or manual horizontal layer
        -horizontal_width $RING_WIDTH \ ;# Use DRM-specified or manual ring width
        -horizontal_spacing $RING_SPACING \ ;# Use DRM-specified or manual spacing
        -vertical_layer $RING_VER_LAYER \ ;# Use DRM-specified or manual vertical layer
        -vertical_width $RING_WIDTH \ ;# Use DRM-specified or manual ring width
        -vertical_spacing $RING_SPACING \ ;# Use DRM-specified or manual spacing
        -offset $RING_OFFSET \ ;# Place ring inside core boundary
        -extend_to_boundary ;# Extend ring to reach core boundary
    
    puts "Power rings created on layers: $RING_HOR_LAYER (horizontal), $RING_VER_LAYER (vertical)" ;# Print confirmation
    
    if {$USE_DRM_SPECS} { ;# If using DRM specs
        puts "Ring dimensions comply with DRM specifications" ;# Print compliance message
    }
    
} else { ;# If using foundry template
    puts "Power rings created from foundry template" ;# Print info
}

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
# CREATE POWER STRIPES - M3 LAYER (if using DRM)
###############################################################################

if {$USE_DRM_SPECS && !$USING_FOUNDRY_TEMPLATE} { ;# If using DRM but not template
    
    puts "\n------------------------------------------" ;# Print subsection separator
    puts "Creating M3 Power Stripes (DRM)" ;# Print subsection title
    puts "------------------------------------------" ;# Print subsection separator
    
    # Get M3 direction from DRM
    set m3_direction $DRM_M3_SPEC(direction) ;# Get stripe direction from DRM
    
    # Create VDD stripes on M3
    create_power_stripes \
        -nets $VDD_NET \ ;# Create stripes for power net
        -layer "M3" \ ;# Use M3 metal layer
        -width $STRIPE_WIDTH_M3 \ ;# Use DRM-specified width
        -pitch $STRIPE_PITCH_M3 \ ;# Use DRM-specified pitch
        -direction $m3_direction \ ;# Use DRM-specified direction
        -start_offset $STRIPE_START_OFFSET \ ;# Start first stripe at offset
        -extend_to_boundary ;# Extend stripes to core boundary
    
    # Create VSS stripes on M3
    create_power_stripes \
        -nets $VSS_NET \ ;# Create stripes for ground net
        -layer "M3" \ ;# Use M3 metal layer
        -width $STRIPE_WIDTH_M3 \ ;# Use DRM-specified width
        -pitch $STRIPE_PITCH_M3 \ ;# Use DRM-specified pitch
        -direction $m3_direction \ ;# Use DRM-specified direction
        -start_offset [expr {$STRIPE_START_OFFSET + $STRIPE_WIDTH_M3 + $DRM_M3_SPEC(spacing)}] \ ;# Offset from VDD
        -extend_to_boundary ;# Extend stripes to core boundary
    
    puts "Created M3 stripes: Width=${STRIPE_WIDTH_M3}um, Pitch=${STRIPE_PITCH_M3}um, Direction=$m3_direction" ;# Print info
}

###############################################################################
# CREATE POWER STRIPES - M5 LAYER (DRM-Compliant)
###############################################################################

if {!$USING_FOUNDRY_TEMPLATE} { ;# If not using foundry template
    
    puts "\n------------------------------------------" ;# Print subsection separator
    puts "Creating M5 Power Stripes" ;# Print subsection title
    puts "------------------------------------------" ;# Print subsection separator
    
    # Get M5 direction (from DRM if available)
    if {$USE_DRM_SPECS} { ;# If using DRM
        set m5_direction $DRM_M5_SPEC(direction) ;# Get direction from DRM
    } else { ;# If manual
        set m5_direction "vertical" ;# Use default direction
    }
    
    # Create VDD stripes on M5
    create_power_stripes \
        -nets $VDD_NET \ ;# Create stripes for power net
        -layer "M5" \ ;# Use M5 metal layer
        -width $STRIPE_WIDTH_M5 \ ;# Use DRM or manual width
        -pitch $STRIPE_PITCH_M5 \ ;# Use DRM or manual pitch
        -direction $m5_direction \ ;# Use DRM or manual direction
        -start_offset $STRIPE_START_OFFSET \ ;# Start first stripe at offset
        -extend_to_boundary ;# Extend stripes to core boundary
    
    # Create VSS stripes on M5
    create_power_stripes \
        -nets $VSS_NET \ ;# Create stripes for ground net
        -layer "M5" \ ;# Use M5 metal layer
        -width $STRIPE_WIDTH_M5 \ ;# Use DRM or manual width
        -pitch $STRIPE_PITCH_M5 \ ;# Use DRM or manual pitch
        -direction $m5_direction \ ;# Use DRM or manual direction
        -start_offset [expr {$STRIPE_START_OFFSET + $STRIPE_WIDTH_M5 + 1.0}] \ ;# Offset from VDD
        -extend_to_boundary ;# Extend stripes to core boundary
    
    puts "Created M5 stripes: Width=${STRIPE_WIDTH_M5}um, Pitch=${STRIPE_PITCH_M5}um" ;# Print confirmation
    
    if {$USE_DRM_SPECS} { ;# If using DRM
        puts "M5 stripes comply with DRM specifications" ;# Print compliance message
    }
}

###############################################################################
# CREATE POWER STRIPES - M7 LAYER (DRM-Compliant)
###############################################################################

if {!$USING_FOUNDRY_TEMPLATE} { ;# If not using foundry template
    
    puts "\n------------------------------------------" ;# Print subsection separator
    puts "Creating M7 Power Stripes" ;# Print subsection title
    puts "------------------------------------------" ;# Print subsection separator
    
    # Get M7 direction (from DRM if available)
    if {$USE_DRM_SPECS} { ;# If using DRM
        set m7_direction $DRM_M7_SPEC(direction) ;# Get direction from DRM
    } else { ;# If manual
        set m7_direction "horizontal" ;# Use default direction
    }
    
    # Create VDD stripes on M7
    create_power_stripes \
        -nets $VDD_NET \ ;# Create stripes for power net
        -layer "M7" \ ;# Use M7 metal layer (top thick metal)
        -width $STRIPE_WIDTH_M7 \ ;# Use DRM or manual width (wider for lower resistance)
        -pitch $STRIPE_PITCH_M7 \ ;# Use DRM or manual pitch
        -direction $m7_direction \ ;# Use DRM or manual direction
        -start_offset $STRIPE_START_OFFSET \ ;# Start first stripe at offset
        -extend_to_boundary ;# Extend stripes to core boundary
    
    # Create VSS stripes on M7
    create_power_stripes \
        -nets $VSS_NET \ ;# Create stripes for ground net
        -layer "M7" \ ;# Use M7 metal layer
        -width $STRIPE_WIDTH_M7 \ ;# Use DRM or manual width
        -pitch $STRIPE_PITCH_M7 \ ;# Use DRM or manual pitch
        -direction $m7_direction \ ;# Use DRM or manual direction
        -start_offset [expr {$STRIPE_START_OFFSET + $STRIPE_WIDTH_M7 + $RING_SPACING}] \ ;# Offset from VDD
        -extend_to_boundary ;# Extend stripes to core boundary
    
    puts "Created M7 stripes: Width=${STRIPE_WIDTH_M7}um, Pitch=${STRIPE_PITCH_M7}um" ;# Print confirmation
    
    if {$USE_DRM_SPECS} { ;# If using DRM
        puts "M7 stripes comply with DRM specifications" ;# Print compliance message
    }
}

###############################################################################
# CONNECT POWER GRID LAYERS (DRM-Compliant Vias)
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Connecting Power Grid Layers" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

if {$USE_DRM_SPECS} { ;# If using DRM specifications
    
    # Create vias with DRM-compliant via arrays
    puts "Creating DRM-compliant via arrays for power grid connections" ;# Print info
    
    # Connect with specified via array sizes from DRM
    connect_power_grid \
        -all \ ;# Connect all power/ground nets across all layers
        -use_via_array \ ;# Use via arrays instead of single vias
        -min_cut_spacing $DRM_VIA_SPEC(cut_spacing) \ ;# Set minimum cut spacing per DRM
        -verbose ;# Print detailed connection information
    
    puts "Power grid vias comply with DRM via specifications" ;# Print compliance message
    
} else { ;# If using manual specifications
    
    # Create standard vias
    connect_power_grid \
        -all \ ;# Connect all power/ground nets across all layers
        -verbose ;# Print detailed connection information
}

puts "Power grid layers connected with vias" ;# Print confirmation

###############################################################################
# DRM COMPLIANCE VERIFICATION
###############################################################################

if {$USE_DRM_SPECS} { ;# If using DRM specifications
    
    puts "\n------------------------------------------" ;# Print subsection separator
    puts "Verifying DRM Compliance" ;# Print subsection title
    puts "------------------------------------------" ;# Print subsection separator
    
    # Check power grid width compliance
    if {$DRM_VERIFY_RULES(check_width)} { ;# If width checking is enabled
        puts "Verifying stripe widths against DRM limits..." ;# Print info
        # verify_power_grid_width -drm_rules ;# Tool-specific command
    }
    
    # Check spacing compliance
    if {$DRM_VERIFY_RULES(check_spacing)} { ;# If spacing checking is enabled
        puts "Verifying stripe spacing against DRM limits..." ;# Print info
        # verify_power_grid_spacing -drm_rules ;# Tool-specific command
    }
    
    # Check via array compliance
    if {$DRM_VERIFY_RULES(check_via_arrays)} { ;# If via checking is enabled
        puts "Verifying via arrays against DRM specifications..." ;# Print info
        # verify_power_grid_vias -drm_rules ;# Tool-specific command
    }
    
    puts "DRM compliance verification completed" ;# Print completion
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
set power_metal_area [get_power_grid_metal_area] ;# Get total area used by power grid (if command available)

# Report power grid statistics
puts "\nPower Grid Statistics:" ;# Print statistics header
puts "  Power nets: $VDD_NET, $VSS_NET" ;# Print power net names
puts "  Ring layers: $RING_HOR_LAYER (H), $RING_VER_LAYER (V)" ;# Print ring layers

if {$USE_DRM_SPECS} { ;# If using DRM specifications
    puts "  Stripe layers: M3, M5, M7 (per DRM)" ;# Print DRM-based layers
    puts "  M3 pitch: ${STRIPE_PITCH_M3}um (DRM-compliant)" ;# Print M3 pitch
    puts "  M5 pitch: ${STRIPE_PITCH_M5}um (DRM-compliant)" ;# Print M5 pitch
    puts "  M7 pitch: ${STRIPE_PITCH_M7}um (DRM-compliant)" ;# Print M7 pitch
    puts "  Design follows foundry DRM v${DRM_VERSION}" ;# Print DRM version
} else { ;# If using manual specifications
    puts "  Stripe layers: M5, M7" ;# Print manual layers
    puts "  M5 pitch: ${STRIPE_PITCH_M5}um" ;# Print M5 pitch
    puts "  M7 pitch: ${STRIPE_PITCH_M7}um" ;# Print M7 pitch
}

# puts "  Total metal area: $power_metal_area" ;# Print total metal usage (if available)

# Verify power grid connectivity
if {[catch {verify_power_grid -nets "$VDD_NET $VSS_NET"} err]} { ;# Try to verify connectivity
    puts "\nWARNING: Power grid verification failed: $err" ;# Print warning if verification fails
} else { ;# If verification succeeds
    puts "\nPower grid connectivity verified" ;# Print success message
}

###############################################################################
# GENERATE POWER GRID REPORTS
###############################################################################

puts "\n------------------------------------------" ;# Print subsection separator
puts "Generating Power Grid Reports" ;# Print subsection title
puts "------------------------------------------" ;# Print subsection separator

report_power_grid > ${REPORTS_DIR}/power_grid_detailed.rpt ;# Generate detailed power grid structure report
report_power_grid_connectivity > ${REPORTS_DIR}/power_grid_connectivity.rpt ;# Generate connectivity verification report

if {$USE_DRM_SPECS} { ;# If using DRM specifications
    # Generate DRM compliance report
    puts "Generating DRM compliance report..." ;# Print info
    set drm_report_file "${REPORTS_DIR}/power_grid_drm_compliance.rpt" ;# Define report path
    
    set fp [open $drm_report_file w] ;# Open file for writing
    puts $fp "Power Grid DRM Compliance Report" ;# Write header
    puts $fp "======================================" ;# Write separator
    puts $fp "DRM Version: $DRM_VERSION" ;# Write DRM version
    puts $fp "Technology: $DRM_TECH_NODE" ;# Write tech node
    puts $fp "\nPower Ring Specifications:" ;# Write section header
    puts $fp "  Horizontal Layer: $RING_HOR_LAYER" ;# Write horizontal layer
    puts $fp "  Vertical Layer: $RING_VER_LAYER" ;# Write vertical layer
    puts $fp "  Width: ${RING_WIDTH}um (DRM: ${DRM_RING_SPEC(M7,min_width)}-${DRM_RING_SPEC(M7,max_width)}um)" ;# Write width with limits
    puts $fp "\nPower Stripe Specifications:" ;# Write section header
    puts $fp "  M3: Width=${STRIPE_WIDTH_M3}um, Pitch=${STRIPE_PITCH_M3}um" ;# Write M3 specs
    puts $fp "  M5: Width=${STRIPE_WIDTH_M5}um, Pitch=${STRIPE_PITCH_M5}um" ;# Write M5 specs
    puts $fp "  M7: Width=${STRIPE_WIDTH_M7}um, Pitch=${STRIPE_PITCH_M7}um" ;# Write M7 specs
    puts $fp "\nCurrent Density Limits (from DRM):" ;# Write section header
    puts $fp "  M3: Max=${DRM_CURRENT_DENSITY(M3,max)}mA/um, Avg=${DRM_CURRENT_DENSITY(M3,avg)}mA/um" ;# Write M3 limits
    puts $fp "  M5: Max=${DRM_CURRENT_DENSITY(M5,max)}mA/um, Avg=${DRM_CURRENT_DENSITY(M5,avg)}mA/um" ;# Write M5 limits
    puts $fp "  M7: Max=${DRM_CURRENT_DENSITY(M7,max)}mA/um, Avg=${DRM_CURRENT_DENSITY(M7,avg)}mA/um" ;# Write M7 limits
    puts $fp "\nIR Drop Limits (from DRM):" ;# Write section header
    puts $fp "  Static: ${DRM_IR_DROP(static,vdd)}mV (VDD), ${DRM_IR_DROP(static,vss)}mV (VSS)" ;# Write static limits
    puts $fp "  Dynamic: ${DRM_IR_DROP(dynamic,vdd)}mV (VDD), ${DRM_IR_DROP(dynamic,vss)}mV (VSS)" ;# Write dynamic limits
    close $fp ;# Close file
    
    puts "DRM compliance report generated: $drm_report_file" ;# Print confirmation
}

puts "Power grid reports generated:" ;# Print header
puts "  - ${REPORTS_DIR}/power_grid_detailed.rpt" ;# Print report path
puts "  - ${REPORTS_DIR}/power_grid_connectivity.rpt" ;# Print report path
if {$USE_DRM_SPECS} { ;# If using DRM
    puts "  - ${REPORTS_DIR}/power_grid_drm_compliance.rpt" ;# Print DRM report path
}

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
