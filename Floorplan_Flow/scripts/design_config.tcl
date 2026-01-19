#!/bin/tclsh
###############################################################################
# Design Configuration File
# Description: Design-specific variables and parameters
# Author: Design Team
# Date: December 2025
###############################################################################

puts "Loading Design Configuration..." ;# Print status message

###############################################################################
# DESIGN INFORMATION
###############################################################################

set DESIGN_NAME "my_design" ;# Name of the design block
set TOP_MODULE "top_module" ;# Top-level module name from netlist
set TECH_NODE "28nm" ;# Technology node for the design

###############################################################################
# FLOORPLAN PARAMETERS
###############################################################################

set CORE_UTILIZATION 0.70 ;# Target utilization (70% means 30% routing space)
set ASPECT_RATIO 1.0 ;# Core aspect ratio (1.0 = square, 2.0 = width/height)
set CORE_TO_IO_SPACING 10.0 ;# Spacing between core area and die boundary in microns

###############################################################################
# POWER/GROUND NET NAMES
###############################################################################

set VDD_NET "VDD" ;# Name of primary power supply net
set VSS_NET "VSS" ;# Name of primary ground net

# Additional power domains (if multiple voltage domains exist)
set VDDIO_NET "VDDIO" ;# IO power supply net (if different from core)
set VSSIO_NET "VSSIO" ;# IO ground net (if different from core)

###############################################################################
# PIN PLACEMENT PARAMETERS
###############################################################################

set PIN_LAYER_HOR "M4" ;# Metal layer for horizontal pins
set PIN_LAYER_VER "M5" ;# Metal layer for vertical pins
set PIN_CORNER_AVOID 5.0 ;# Keep pins away from corners by this distance (microns)
set PIN_MIN_DISTANCE 2.0 ;# Minimum spacing between adjacent pins (microns)

###############################################################################
# MACRO PLACEMENT PARAMETERS
###############################################################################

set MACRO_CHANNEL_SPACING 10.0 ;# Spacing between adjacent macros (microns)
set MACRO_BOUNDARY_SPACING 5.0 ;# Spacing between macros and core boundary (microns)
set MACRO_HALO 2.0 ;# Halo/keepout zone around each macro (microns)

###############################################################################
# POWER GRID PARAMETERS
###############################################################################

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
# TIMING PARAMETERS
###############################################################################

set CLOCK_PERIOD 2.0 ;# Primary clock period in nanoseconds
set CLOCK_UNCERTAINTY 0.1 ;# Clock uncertainty/jitter in nanoseconds
set INPUT_DELAY 0.2 ;# Input delay as fraction of clock period
set OUTPUT_DELAY 0.2 ;# Output delay as fraction of clock period

###############################################################################
# PLACEMENT PARAMETERS
###############################################################################

set STD_CELL_PLACEMENT_DENSITY 0.75 ;# Standard cell placement density (0.0-1.0)
set PLACEMENT_EFFORT "high" ;# Placement effort level (low/medium/high)

###############################################################################
# ROUTING PARAMETERS
###############################################################################

set MIN_ROUTING_LAYER "M2" ;# Minimum metal layer for signal routing
set MAX_ROUTING_LAYER "M7" ;# Maximum metal layer for signal routing
set ROUTING_EFFORT "high" ;# Routing effort level (low/medium/high)

puts "Design Configuration Loaded Successfully" ;# Print confirmation message
