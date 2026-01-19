#!/usr/bin/tclsh
#==============================================================================
# Well Tap Insertion Strategy
# File: add_well_taps.tcl
#==============================================================================

puts "=========================================="
puts "Well Tap Insertion Strategy"
puts "=========================================="

#==============================================================================
# WHY NOT AFTER FLOORPLAN? - Detailed Explanation
#==============================================================================
puts "\n=========================================="
puts "WHY WELL TAPS CANNOT BE ADDED AFTER FLOORPLAN"
puts "=========================================="
puts ""

#------------------------------------------------------------------------------
# Problem 1: No Standard Cells Placed Yet
#------------------------------------------------------------------------------
puts "PROBLEM 1: No Standard Cells Present"
puts "--------------------------------------"
puts "After floorplan:"
puts "  ✗ Only rows are defined"
puts "  ✗ Standard cells NOT placed yet"
puts "  ✗ Cannot calculate actual well spacing"
puts "  ✗ Don't know where whitespace will be"
puts ""
puts "Well taps need to fill gaps BETWEEN cells:"
puts "  - If added before placement, they block cell locations"
puts "  - Placement will fail due to insufficient space"
puts "  - Well taps would need to be removed and re-added"
puts ""

#------------------------------------------------------------------------------
# Problem 2: Unknown Cell Density Distribution
#------------------------------------------------------------------------------
puts "PROBLEM 2: Unknown Density Distribution"
puts "----------------------------------------"
puts "After floorplan, we don't know:"
puts "  ✗ Where cells will be dense"
puts "  ✗ Where whitespace will exist"
puts "  ✗ How cells will cluster"
puts "  ✗ Actual row utilization"
puts ""
puts "Example scenario:"
puts "  - Floorplan allows 70% utilization"
puts "  - Add taps uniformly at 30um spacing"
puts "  - Placement tries to place cells"
puts "  - Some areas become 85% utilized (cells + taps)"
puts "  - Placement FAILS - not enough space!"
puts ""

#------------------------------------------------------------------------------
# Problem 3: Well Taps Would Block Placement
#------------------------------------------------------------------------------
puts "PROBLEM 3: Well Taps Block Placement"
puts "-------------------------------------"
puts "Well taps are FIXED instances:"
puts "  - They occupy physical space"
puts "  - Placement cannot move them"
puts "  - They reduce available space for standard cells"
puts ""
puts "If added after floorplan:"
puts "  - Target utilization: 70%"
puts "  - Well taps consume: ~2-5% more"
puts "  - Effective available: only 65-68%"
puts "  - Placement quality degrades significantly"
puts ""

#------------------------------------------------------------------------------
# Problem 4: Cannot Optimize Tap Placement
#------------------------------------------------------------------------------
puts "PROBLEM 4: Cannot Optimize Placement"
puts "-------------------------------------"
puts "Well taps should be placed intelligently:"
puts "  ✓ In whitespace between cells"
puts "  ✓ Avoiding congested areas"
puts "  ✓ Respecting macro blockages"
puts "  ✓ Maintaining uniform spacing"
puts ""
puts "After floorplan, we cannot:"
puts "  ✗ Identify whitespace (no cells yet)"
puts "  ✗ Avoid congested regions (unknown)"
puts "  ✗ Optimize tap distribution"
puts ""

#------------------------------------------------------------------------------
# Problem 5: Practical Example with Numbers
#------------------------------------------------------------------------------
puts "PROBLEM 5: Practical Example"
puts "----------------------------"
puts ""
puts "Scenario: 1mm x 1mm core, 70% target utilization"
puts ""
puts "APPROACH 1: Add Taps After Floorplan (WRONG)"
puts "  1. Core area: 1,000,000 um^2"
puts "  2. Add taps at 30um spacing"
puts "  3. Taps needed: ~1,111 taps"
puts "  4. Tap area: ~1,111 × 1um × 2um = 2,222 um^2"
puts "  5. Tap overhead: 0.22% (seems small)"
puts ""
puts "  BUT WAIT - Problem with distribution:"
puts "  6. Try to place cells in 70% of core"
puts "  7. Some areas have high cell density"
puts "  8. Taps already occupy 'best' whitespace"
puts "  9. Placement fails in dense regions"
puts "  10. Result: Cannot achieve 70% utilization"
puts ""
puts "APPROACH 2: Add Taps After Placement (CORRECT)"
puts "  1. Core area: 1,000,000 um^2"
puts "  2. Place cells first (70% utilization)"
puts "  3. Cell area: 700,000 um^2"
puts "  4. Whitespace: 300,000 um^2"
puts "  5. Add taps in whitespace"
puts "  6. Taps intelligently fill gaps"
puts "  7. No placement conflicts"
puts "  8. Result: SUCCESS - 70% + taps in whitespace"
puts ""

#------------------------------------------------------------------------------
# Problem 6: What About Macros?
#------------------------------------------------------------------------------
puts "PROBLEM 6: Macro Interaction"
puts "-----------------------------"
puts "Even if macros are placed after floorplan:"
puts "  ✗ Standard cells not placed yet"
puts "  ✗ Cannot calculate tap spacing around macros"
puts "  ✗ Don't know channel widths between macros"
puts "  ✗ Cannot optimize tap placement"
puts ""
puts "Correct approach:"
puts "  1. Floorplan with macro placement"
puts "  2. Add macro halos and blockages"
puts "  3. Place standard cells"
puts "  4. THEN add well taps (knows all constraints)"
puts ""

#------------------------------------------------------------------------------
# Problem 7: Tool Behavior
#------------------------------------------------------------------------------
puts "PROBLEM 7: EDA Tool Behavior"
puts "----------------------------"
puts "Most EDA tools (Innovus, ICC2) expect:"
puts "  1. Floorplan first"
puts "  2. Placement second"
puts "  3. Well taps third"
puts ""
puts "If taps added after floorplan:"
puts "  - Placement tool sees taps as obstacles"
puts "  - Reduces effective utilization"
puts "  - Degrades timing QoR"
puts "  - May cause placement failures"
puts ""

#------------------------------------------------------------------------------
# Exception: Can Well Taps Ever Go Before Placement?
#------------------------------------------------------------------------------
puts "\n=========================================="
puts "EXCEPTION: When Can Taps Go Earlier?"
puts "=========================================="
puts ""
puts "VERY RARE CASES (almost never recommended):"
puts ""
puts "1. LOW UTILIZATION DESIGNS (< 40%)"
puts "   - Plenty of whitespace guaranteed"
puts "   - Taps won't interfere with placement"
puts "   - Still not optimal, but might work"
puts ""
puts "2. ANALOG/CUSTOM LAYOUTS"
puts "   - Fully manual placement"
puts "   - Designer controls everything"
puts "   - Different from standard cell flow"
puts ""
puts "3. BLOCK-LEVEL DESIGNS WITH FIXED PATTERNS"
puts "   - Repetitive structures"
puts "   - Predictable whitespace"
puts "   - Very specific use case"
puts ""
puts "FOR STANDARD DIGITAL DESIGNS:"
puts "   >>> ALWAYS ADD TAPS AFTER PLACEMENT <<<"
puts ""

#------------------------------------------------------------------------------
# The Correct Sequence - Visual Timeline
#------------------------------------------------------------------------------
puts "=========================================="
puts "CORRECT SEQUENCE - VISUAL TIMELINE"
puts "=========================================="
puts ""
puts "STAGE          | STATUS OF DESIGN"
puts "---------------|------------------------------------------"
puts "Floorplan      | Rows defined, NO cells, NO taps"
puts "               | [========================================]"
puts "               | Empty rows ready for placement"
puts ""
puts "Placement      | Cells placed, still NO taps"
puts "               | [CCCC..CCC.CCCCCC..CCC..CCCCCC.CCC.CCC]"
puts "               | C = Cell, . = Whitespace"
puts ""
puts "Add Well Taps  | Taps fill whitespace"
puts "               | [CCCCTCCCTCCCCCCTCCCTCCCCCCTCCCTCCC]"
puts "               | C = Cell, T = Tap"
puts ""
puts "After Routing  | All connected"
puts "               | [CCCCTCCCTCCCCCCTCCCTCCCCCCTCCCTCCC]"
puts "               | + Power routing to all taps"
puts ""

#------------------------------------------------------------------------------
# Summary Checklist
#------------------------------------------------------------------------------
puts "=========================================="
puts "SUMMARY CHECKLIST - WHY AFTER PLACEMENT"
puts "=========================================="
puts ""
puts "✓ Reasons to add well taps AFTER placement:"
puts "  1. Need to know where cells actually are"
puts "  2. Need to identify actual whitespace"
puts "  3. Need to avoid placement conflicts"
puts "  4. Need to optimize tap distribution"
puts "  5. Need to respect final cell density"
puts "  6. Need to maintain target utilization"
puts "  7. Tools expect this sequence"
puts "  8. Industry best practice"
puts ""
puts "✗ Problems if added AFTER floorplan:"
puts "  1. Blocks space needed for cells"
puts "  2. Cannot predict whitespace"
puts "  3. Reduces effective utilization"
puts "  4. Causes placement failures"
puts "  5. Non-optimal tap distribution"
puts "  6. Increases design iterations"
puts "  7. Degrades timing QoR"
puts "  8. Against industry standards"
puts ""
puts "=========================================="

#==============================================================================
# WHEN TO ADD WELL TAPS - CRITICAL TIMING
#==============================================================================
# OPTIMAL TIMING: After Placement, BEFORE Clock Tree Synthesis
#
# Detailed Flow:
# 1. Floorplan
# 2. Power Planning
# 3. Pin Placement
# 4. Placement          ← Standard cells placed
# 5. Add Tie Cells      ← Optional, can be during optimization
# 6. Add Well Taps      ← INSERT HERE (Most Common)
# 7. Add End Caps       ← Before CTS
# 8. Pre-CTS Opt        ← Well taps present for optimization
# 9. Clock Tree
# 10. Post-CTS Opt
# 11. Routing
# 12. Add Fillers       ← Last step
#
# WHY AFTER PLACEMENT:
# - Need to know final cell positions
# - Calculate actual distances between wells
# - Ensure proper distribution
#
# WHY BEFORE CTS:
# - CTS optimization considers well tap locations
# - Avoids placement disturbance after clock tree
# - Well taps stable during timing optimization
#==============================================================================

#------------------------------------------------------------------------------
# Well Tap Configuration - Technology Dependent
#------------------------------------------------------------------------------
proc configure_well_tap_strategy {} {
    global WELL_TAP_CELL TAP_DISTANCE TAP_PATTERN
    global MAX_TAP_DISTANCE EDGE_TAP_DISTANCE
    
    puts "\n--- Well Tap Configuration ---"
    
    # Well tap cell from library
    set WELL_TAP_CELL "WELLTAP"
    
    # Technology-dependent maximum distance
    # 7nm/5nm: 20-30um
    # 16nm/14nm: 30-40um
    # 28nm: 40-60um
    # 65nm and above: 60-80um
    set MAX_TAP_DISTANCE 30.0  ;# um (for advanced nodes)
    
    # Actual tap placement distance (should be less than max)
    set TAP_DISTANCE 25.0  ;# um (safety margin)
    
    # Distance from core edges
    set EDGE_TAP_DISTANCE 10.0  ;# um
    
    # Tap pattern: "checkerboard", "regular", "sparse"
    set TAP_PATTERN "checkerboard"
    
    puts "  Well tap cell: $WELL_TAP_CELL"
    puts "  Max distance (foundry): ${MAX_TAP_DISTANCE}um"
    puts "  Target spacing: ${TAP_DISTANCE}um"
    puts "  Edge distance: ${EDGE_TAP_DISTANCE}um"
    puts "  Pattern: $TAP_PATTERN"
}

#------------------------------------------------------------------------------
# Check Well Tap Requirements
#------------------------------------------------------------------------------
proc check_well_tap_requirements {} {
    puts "\n=========================================="
    puts "Checking Well Tap Requirements"
    puts "=========================================="
    
    # Check 1: Is design placed?
    set placed_insts [llength [dbGet top.insts.pStatus placed -p]]
    set total_insts [dbGet top.numInsts]
    
    puts "\n--- Placement Status ---"
    if {$placed_insts == 0} {
        puts "ERROR: No instances placed"
        puts "       Please run placement first"
        return 0
    }
    
    set placed_pct [expr {($placed_insts * 100.0) / $total_insts}]
    puts "  Total instances: $total_insts"
    puts "  Placed instances: $placed_insts ([format "%.1f%%" $placed_pct])"
    
    if {$placed_pct < 95} {
        puts "WARNING: Less than 95% of instances are placed"
    } else {
        puts "PASS: Design is properly placed"
    }
    
    # Check 2: Is well tap cell available in library?
    global WELL_TAP_CELL
    set tap_cell_exists [dbGet head.libCells.name $WELL_TAP_CELL -e]
    
    puts "\n--- Library Check ---"
    if {$tap_cell_exists == ""} {
        puts "ERROR: Well tap cell '$WELL_TAP_CELL' not found in library"
        puts "       Available cells:"
        set all_cells [dbGet head.libCells.name -e]
        foreach cell $all_cells {
            if {[regexp -nocase "tap|well|sub" $cell]} {
                puts "         $cell"
            }
        }
        return 0
    } else {
        puts "PASS: Well tap cell '$WELL_TAP_CELL' found"
        set cell_width [dbGet head.libCells.name $WELL_TAP_CELL -p.size_x]
        puts "      Width: [format "%.3f" [expr $cell_width / 1000.0]]um"
    }
    
    # Check 3: Are existing well taps already present?
    set existing_taps [llength [dbGet top.insts.name *TAP* -p]]
    
    puts "\n--- Existing Well Taps ---"
    if {$existing_taps > 0} {
        puts "WARNING: Found $existing_taps existing well tap instances"
        puts "         Consider deleting before re-insertion"
        
        # Option to delete
        puts "\nDelete existing taps? (This script will not delete automatically)"
        # deleteInst [dbGet top.insts.name *TAP* -p]
    } else {
        puts "PASS: No existing well taps found"
    }
    
    return 1
}

#------------------------------------------------------------------------------
# Method 1: Checkerboard Pattern (Most Common)
#------------------------------------------------------------------------------
proc add_well_taps_checkerboard {} {
    global WELL_TAP_CELL TAP_DISTANCE
    
    puts "\n=========================================="
    puts "Method 1: Checkerboard Pattern"
    puts "=========================================="
    puts "Most common method - recommended by foundries"
    
    # Configure well tap mode
    setWellTapMode -reset
    setWellTapMode -cell $WELL_TAP_CELL \
                   -cellInterval $TAP_DISTANCE \
                   -prefix WELLTAP \
                   -checkerMode true
    
    # Add in checkerboard pattern
    addWellTap -checkerboard -cellInterval $TAP_DISTANCE
    
    # Report
    set tap_count [llength [dbGet top.insts.name WELLTAP* -p]]
    puts "\nWell taps inserted: $tap_count"
    puts "Pattern: Checkerboard"
    puts "Spacing: ${TAP_DISTANCE}um"
}

#------------------------------------------------------------------------------
# Method 2: Regular Grid Pattern
#------------------------------------------------------------------------------
proc add_well_taps_regular {} {
    global WELL_TAP_CELL TAP_DISTANCE
    
    puts "\n=========================================="
    puts "Method 2: Regular Grid Pattern"
    puts "=========================================="
    puts "Uniform grid - simpler but may use more taps"
    
    # Configure well tap mode
    setWellTapMode -reset
    setWellTapMode -cell $WELL_TAP_CELL \
                   -cellInterval $TAP_DISTANCE \
                   -prefix WELLTAP
    
    # Add in regular grid pattern
    addWellTap -cellInterval $TAP_DISTANCE
    
    # Report
    set tap_count [llength [dbGet top.insts.name WELLTAP* -p]]
    puts "\nWell taps inserted: $tap_count"
    puts "Pattern: Regular grid"
    puts "Spacing: ${TAP_DISTANCE}um"
}

#------------------------------------------------------------------------------
# Method 3: Respect Existing Placement (Advanced)
#------------------------------------------------------------------------------
proc add_well_taps_smart {} {
    global WELL_TAP_CELL TAP_DISTANCE
    
    puts "\n=========================================="
    puts "Method 3: Smart Placement"
    puts "=========================================="
    puts "Respects existing cells and blockages"
    
    # Configure well tap mode with advanced options
    setWellTapMode -reset
    setWellTapMode -cell $WELL_TAP_CELL \
                   -cellInterval $TAP_DISTANCE \
                   -prefix WELLTAP \
                   -checkerMode true \
                   -respectMacroBlkg true \
                   -respectCellBlkg true
    
    # Add with optimization
    addWellTap -checkerboard \
               -cellInterval $TAP_DISTANCE \
               -area [dbGet top.fPlan.coreBox]
    
    # Report
    set tap_count [llength [dbGet top.insts.name WELLTAP* -p]]
    puts "\nWell taps inserted: $tap_count"
    puts "Pattern: Smart checkerboard"
    puts "Respects: Macros and cell blockages"
}

#------------------------------------------------------------------------------
# Method 4: Area-Specific Insertion
#------------------------------------------------------------------------------
proc add_well_taps_by_area {area_box} {
    global WELL_TAP_CELL TAP_DISTANCE
    
    puts "\n=========================================="
    puts "Method 4: Area-Specific Insertion"
    puts "=========================================="
    puts "For specific regions only"
    
    # Configure well tap mode
    setWellTapMode -reset
    setWellTapMode -cell $WELL_TAP_CELL \
                   -cellInterval $TAP_DISTANCE \
                   -prefix WELLTAP_AREA
    
    # Add in specific area
    addWellTap -cellInterval $TAP_DISTANCE -area $area_box
    
    puts "\nWell taps added in specified area: $area_box"
}

#------------------------------------------------------------------------------
# Verify Well Tap Spacing
#------------------------------------------------------------------------------
proc verify_well_tap_spacing {} {
    global MAX_TAP_DISTANCE
    
    puts "\n=========================================="
    puts "Verifying Well Tap Spacing"
    puts "=========================================="
    
    set taps [dbGet top.insts.name WELLTAP* -p]
    
    if {[llength $taps] == 0} {
        puts "ERROR: No well taps found"
        return 0
    }
    
    puts "Total well taps: [llength $taps]"
    
    # Calculate average spacing
    set core_area [expr {[dbGet top.fPlan.coreBox_area] / 1000000.0}]
    set tap_area [expr {$core_area / [llength $taps]}]
    set avg_spacing [expr {sqrt($tap_area)}]
    
    puts "Average spacing: [format "%.2f" $avg_spacing]um"
    
    if {$avg_spacing > $MAX_TAP_DISTANCE} {
        puts "WARNING: Average spacing exceeds maximum (${MAX_TAP_DISTANCE}um)"
        puts "         Consider reducing tap interval"
    } else {
        puts "PASS: Spacing within limits"
    }
    
    # Check for large gaps (simplified check)
    puts "\nChecking for large gaps..."
    set violations 0
    
    # This is a simplified check
    # Real implementation would calculate actual distances between all taps
    puts "(Detailed gap analysis requires complex algorithm)"
    
    return 1
}

#------------------------------------------------------------------------------
# Check Well Tap Connections
#------------------------------------------------------------------------------
proc verify_well_tap_connections {} {
    puts "\n=========================================="
    puts "Verifying Well Tap Connections"
    puts "=========================================="
    
    set taps [dbGet top.insts.name WELLTAP* -p]
    
    if {[llength $taps] == 0} {
        puts "ERROR: No well taps found"
        return 0
    }
    
    # Check if taps are connected to power rails
    set disconnected 0
    set vdd_connected 0
    set vss_connected 0
    
    foreach tap $taps {
        set terms [dbGet $tap.instTerms]
        set connected_to_pwr 0
        
        foreach term $terms {
            set net [dbGet $term.net.name]
            set is_power [dbGet $term.net.isPwrOrGnd]
            
            if {$is_power} {
                set connected_to_pwr 1
                if {[regexp -nocase "vdd|vcc" $net]} {
                    incr vdd_connected
                } elseif {[regexp -nocase "vss|gnd" $net]} {
                    incr vss_connected
                }
            }
        }
        
        if {!$connected_to_pwr} {
            incr disconnected
        }
    }
    
    puts "Connection Status:"
    puts "  Total taps: [llength $taps]"
    puts "  VDD connected: $vdd_connected"
    puts "  VSS connected: $vss_connected"
    puts "  Disconnected: $disconnected"
    
    if {$disconnected > 0} {
        puts "WARNING: Some well taps are not connected to power rails"
        return 0
    } else {
        puts "PASS: All well taps properly connected"
        return 1
    }
}

#------------------------------------------------------------------------------
# Complete Well Tap Insertion Flow
#------------------------------------------------------------------------------
proc add_well_taps_complete_flow {} {
    puts "\n=========================================="
    puts "Complete Well Tap Insertion Flow"
    puts "=========================================="
    
    # Step 1: Configure strategy
    configure_well_tap_strategy
    
    # Step 2: Check requirements
    if {![check_well_tap_requirements]} {
        puts "\nERROR: Requirements not met. Exiting."
        return
    }
    
    # Step 3: Add well taps using checkerboard (recommended)
    add_well_taps_checkerboard
    
    # Step 4: Verify spacing
    verify_well_tap_spacing
    
    # Step 5: Verify connections
    verify_well_tap_connections
    
    # Step 6: Report summary
    report_well_tap_summary
    
    puts "\n=========================================="
    puts "Well Tap Insertion Completed"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Report Well Tap Summary
#------------------------------------------------------------------------------
proc report_well_tap_summary {} {
    puts "\n=========================================="
    puts "Well Tap Summary Report"
    puts "=========================================="
    
    set taps [dbGet top.insts.name WELLTAP* -p]
    
    if {[llength $taps] == 0} {
        puts "No well taps found"
        return
    }
    
    # Basic statistics
    puts "\nBasic Statistics:"
    puts "  Total well taps: [llength $taps]"
    
    # Area calculation
    set core_area [expr {[dbGet top.fPlan.coreBox_area] / 1000000.0}]
    set tap_area 0.0
    
    foreach tap $taps {
        set cell_area [dbGet $tap.cell.area]
        set tap_area [expr {$tap_area + ($cell_area / 1000000.0)}]
    }
    
    set tap_density [expr {($tap_area / $core_area) * 100.0}]
    
    puts "\nArea Analysis:"
    puts "  Core area: [format "%.2f" $core_area] um^2"
    puts "  Tap area: [format "%.4f" $tap_area] um^2"
    puts "  Density: [format "%.3f" $tap_density]%"
    
    # Average spacing
    set avg_spacing [expr {sqrt($core_area / [llength $taps])}]
    puts "\nSpacing:"
    puts "  Average spacing: [format "%.2f" $avg_spacing] um"
    
    # Distribution check
    puts "\nDistribution:"
    set core_box [dbGet top.fPlan.coreBox]
    set x_min [lindex $core_box 0]
    set y_min [lindex $core_box 1]
    set x_max [lindex $core_box 2]
    set y_max [lindex $core_box 3]
    
    set width [expr {($x_max - $x_min) / 1000.0}]
    set height [expr {($y_max - $y_min) / 1000.0}]
    
    puts "  Core dimensions: [format "%.2f" $width] x [format "%.2f" $height] um"
    puts "  Taps per 1000 um^2: [format "%.2f" [expr {[llength $taps] / ($width * $height / 1000.0)}]]"
    
    puts "=========================================="
}

#==============================================================================
# TECHNOLOGY-SPECIFIC GUIDELINES
#==============================================================================
puts "\n=========================================="
puts "TECHNOLOGY-SPECIFIC WELL TAP SPACING"
puts "=========================================="
puts ""
puts "Technology    Max Distance    Recommended"
puts "------------------------------------------------"
puts "5nm/7nm       20-30 um        20-25 um"
puts "10nm/12nm     25-35 um        25-30 um"
puts "14nm/16nm     30-40 um        30-35 um"
puts "22nm/28nm     40-60 um        40-50 um"
puts "40nm/45nm     50-70 um        50-60 um"
puts "65nm          60-80 um        60-70 um"
puts "90nm+         70-100 um       70-80 um"
puts "------------------------------------------------"
puts ""
puts "TIMING IN FLOW:"
puts "  ✓ AFTER:  Placement completed"
puts "  ✓ BEFORE: Clock Tree Synthesis"
puts "  ✓ REASON: Stable for CTS optimization"
puts ""
puts "COMMON PATTERNS:"
puts "  1. Checkerboard - Most efficient (RECOMMENDED)"
puts "  2. Regular Grid - Simpler but more taps"
puts "  3. Smart - Respects blockages"
puts ""
puts "WHY WELL TAPS ARE NEEDED:"
puts "  - Prevent latchup in CMOS circuits"
puts "  - Connect n-well to VDD"
puts "  - Connect p-substrate to VSS"
puts "  - Required by foundry DRC rules"
puts ""
puts "=========================================="

#==============================================================================
# MAIN EXECUTION
#==============================================================================

# Uncomment to run complete flow
# add_well_taps_complete_flow

# Or run individual methods:
# configure_well_tap_strategy
# check_well_tap_requirements
# add_well_taps_checkerboard
# verify_well_tap_spacing
# verify_well_tap_connections
# report_well_tap_summary
