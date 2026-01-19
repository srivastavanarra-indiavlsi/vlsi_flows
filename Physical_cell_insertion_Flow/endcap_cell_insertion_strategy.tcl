####
#!/usr/bin/tclsh
#==============================================================================
# Boundary Cells (End Caps) Insertion - Foundry Rules & Strategies
# File: add_boundary_cells.tcl
#==============================================================================

puts "=========================================="
puts "Boundary Cells Insertion Strategy"
puts "Based on Foundry Design Rules"
puts "=========================================="

#==============================================================================
# FOUNDRY RULES FOR BOUNDARY CELLS (END CAPS)
#==============================================================================
# 
# PURPOSE OF BOUNDARY CELLS:
# 1. N-well/P-well termination at row boundaries
# 2. Prevent DRC violations at core edges
# 3. Provide proper implant layer termination
# 4. Maintain continuous power rails at boundaries
# 5. Meet minimum width/spacing rules for wells
# 6. Protect against manufacturing edge effects
#
# WHEN TO ADD:
# - After Placement
# - Before CTS (so CTS sees boundary conditions)
# - Definitely before Routing
# - Definitely before Fillers
#
# WHERE TO ADD:
# - Left edge of every row
# - Right edge of every row
# - Top boundary (optional, design dependent)
# - Bottom boundary (optional, design dependent)
# - Around macro boundaries (optional)
#
#==============================================================================

#------------------------------------------------------------------------------
# Foundry-Specific Requirements
#------------------------------------------------------------------------------
proc show_foundry_requirements {} {
    puts "\n=========================================="
    puts "FOUNDRY-SPECIFIC REQUIREMENTS"
    puts "=========================================="
    
    puts "\n--- TSMC ---"
    puts "Rules:"
    puts "  • MANDATORY at all row ends (left & right)"
    puts "  • End cap cells MUST be from qualified library"
    puts "  • Minimum end cap width varies by technology:"
    puts "    - 7nm/5nm: Special boundary cells required"
    puts "    - 16nm: BOUNDARY_LEFTRIGHT or separate L/R cells"
    puts "    - 28nm+: ENDCAP cells sufficient"
    puts "  • Must ensure N-well continuity"
    puts "  • Must not have DRC violations at boundaries"
    puts ""
    puts "Cell Types:"
    puts "  - BOUNDARY_LEFTRIGHT (single cell for both edges)"
    puts "  - BOUNDARY_LEFT + BOUNDARY_RIGHT (separate cells)"
    puts "  - ENDCAPLR (left-right symmetric)"
    
    puts "\n--- Samsung ---"
    puts "Rules:"
    puts "  • End caps required at ALL standard cell row boundaries"
    puts "  • Different cells for different row types"
    puts "  • Special cells for multi-height rows"
    puts "  • Boundary tap cells may be required"
    puts ""
    puts "Cell Types:"
    puts "  - ENDCAP_LEFT"
    puts "  - ENDCAP_RIGHT"
    puts "  - ENDCAP_TAP (combined end cap + well tap)"
    
    puts "\n--- Intel ---"
    puts "Rules:"
    puts "  • Mandatory at row boundaries"
    puts "  • Different cells for different voltage domains"
    puts "  • Special handling for power gating regions"
    puts ""
    puts "Cell Types:"
    puts "  - PCELL_END (left)"
    puts "  - PCELL_END_R (right)"
    
    puts "\n--- GlobalFoundries ---"
    puts "Rules:"
    puts "  • End caps at all row edges"
    puts "  • Special boundary cells for FinFET technologies"
    puts "  • Must maintain rail continuity"
    puts ""
    puts "Cell Types:"
    puts "  - ENDCAP"
    puts "  - ENDCAPLR"
    
    puts "\n=========================================="
}

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
proc configure_boundary_cells {} {
    global ENDCAP_LEFT ENDCAP_RIGHT ENDCAP_BOTH
    global USE_BOUNDARY_TAPS ADD_TOP_BOTTOM_CAPS
    global MACRO_ENDCAPS VOLTAGE_DOMAIN_CAPS
    
    puts "\n--- Configuring Boundary Cell Strategy ---"
    
    # Standard cell library end cap cells
    # Check your library for actual cell names
    set ENDCAP_LEFT "BOUNDARY_LEFT"
    set ENDCAP_RIGHT "BOUNDARY_RIGHT"
    set ENDCAP_BOTH "BOUNDARY_LEFTRIGHT"  ;# If single cell for both
    
    # Some foundries provide boundary cells with integrated taps
    set USE_BOUNDARY_TAPS "false"
    set BOUNDARY_TAP_LEFT "BOUNDARY_TAP_LEFT"
    set BOUNDARY_TAP_RIGHT "BOUNDARY_TAP_RIGHT"
    
    # Top and bottom caps (usually not required, but good practice)
    set ADD_TOP_BOTTOM_CAPS "false"
    
    # Macro boundary cells
    set MACRO_ENDCAPS "true"
    
    # Multi-voltage domain boundaries
    set VOLTAGE_DOMAIN_CAPS "false"
    
    puts "  End cap left: $ENDCAP_LEFT"
    puts "  End cap right: $ENDCAP_RIGHT"
    puts "  Combined cap: $ENDCAP_BOTH"
    puts "  Use boundary taps: $USE_BOUNDARY_TAPS"
    puts "  Add top/bottom: $ADD_TOP_BOTTOM_CAPS"
}

#------------------------------------------------------------------------------
# Check Library for Boundary Cells
#------------------------------------------------------------------------------
proc check_boundary_cells_in_library {} {
    puts "\n=========================================="
    puts "Checking Library for Boundary Cells"
    puts "=========================================="
    
    # Get all cells that might be boundary cells
    set all_cells [dbGet head.libCells.name -e]
    
    puts "\nSearching for boundary/endcap cells..."
    set boundary_cells [list]
    
    foreach cell $all_cells {
        if {[regexp -nocase {boundary|endcap|bound|edge} $cell]} {
            lappend boundary_cells $cell
        }
    }
    
    if {[llength $boundary_cells] == 0} {
        puts "WARNING: No boundary cells found in library!"
        puts "         Check with foundry for required cells"
        return 0
    }
    
    puts "\nFound boundary cells:"
    foreach cell [lsort $boundary_cells] {
        set width [dbGet head.libCells.name $cell -p.size_x]
        set height [dbGet head.libCells.name $cell -p.size_y]
        puts "  $cell : [format "%.3f" [expr $width/1000.0]] x [format "%.3f" [expr $height/1000.0]] um"
    }
    
    return 1
}

#------------------------------------------------------------------------------
# Method 1: Standard End Cap Insertion (Most Common)
#------------------------------------------------------------------------------
proc add_endcaps_standard {} {
    global ENDCAP_LEFT ENDCAP_RIGHT ENDCAP_BOTH
    
    puts "\n=========================================="
    puts "Method 1: Standard End Cap Insertion"
    puts "=========================================="
    puts "Recommended: Use after placement, before CTS"
    
    # Check if cells exist in library
    set left_exists [dbGet head.libCells.name $ENDCAP_LEFT -e]
    set right_exists [dbGet head.libCells.name $ENDCAP_RIGHT -e]
    set both_exists [dbGet head.libCells.name $ENDCAP_BOTH -e]
    
    # Method A: Separate left and right cells
    if {$left_exists != "" && $right_exists != ""} {
        puts "\nUsing separate left/right end cap cells"
        
        setEndCapMode -reset
        setEndCapMode -prefix ENDCAP \
                      -leftEdge $ENDCAP_LEFT \
                      -rightEdge $ENDCAP_RIGHT \
                      -leftTopEdge $ENDCAP_LEFT \
                      -leftBottomEdge $ENDCAP_LEFT \
                      -rightTopEdge $ENDCAP_RIGHT \
                      -rightBottomEdge $ENDCAP_RIGHT
        
        addEndCap
        
        puts "End caps added:"
        puts "  Left edge: $ENDCAP_LEFT"
        puts "  Right edge: $ENDCAP_RIGHT"
    
    # Method B: Single cell for both edges
    } elseif {$both_exists != ""} {
        puts "\nUsing combined left/right end cap cell"
        
        setEndCapMode -reset
        setEndCapMode -prefix ENDCAP \
                      -boundary_tap false
        
        addEndCap -cell $ENDCAP_BOTH
        
        puts "End caps added:"
        puts "  Both edges: $ENDCAP_BOTH"
    
    } else {
        puts "ERROR: No suitable end cap cells found in library"
        puts "Available cells:"
        check_boundary_cells_in_library
        return
    }
    
    # Report count
    set endcap_count [llength [dbGet top.insts.name ENDCAP* -p]]
    puts "\nTotal end caps inserted: $endcap_count"
}

#------------------------------------------------------------------------------
# Method 2: Boundary Cells with Integrated Taps
#------------------------------------------------------------------------------
proc add_boundary_taps {} {
    global BOUNDARY_TAP_LEFT BOUNDARY_TAP_RIGHT
    
    puts "\n=========================================="
    puts "Method 2: Boundary Cells with Taps"
    puts "=========================================="
    puts "Some foundries provide combined boundary+tap cells"
    
    set left_exists [dbGet head.libCells.name $BOUNDARY_TAP_LEFT -e]
    set right_exists [dbGet head.libCells.name $BOUNDARY_TAP_RIGHT -e]
    
    if {$left_exists != "" && $right_exists != ""} {
        setEndCapMode -reset
        setEndCapMode -prefix BOUNDTAP \
                      -leftEdge $BOUNDARY_TAP_LEFT \
                      -rightEdge $BOUNDARY_TAP_RIGHT \
                      -boundary_tap true
        
        addEndCap
        
        puts "Boundary tap cells added"
        puts "  Left: $BOUNDARY_TAP_LEFT"
        puts "  Right: $BOUNDARY_TAP_RIGHT"
        puts "  (Combined boundary + well tap function)"
    } else {
        puts "Boundary tap cells not found in library"
        puts "Using standard end caps instead"
        add_endcaps_standard
    }
}

#------------------------------------------------------------------------------
# Method 3: Top and Bottom Boundary Cells (Optional)
#------------------------------------------------------------------------------
proc add_top_bottom_caps {} {
    puts "\n=========================================="
    puts "Method 3: Top and Bottom Boundary Cells"
    puts "=========================================="
    puts "Optional: Not always required by foundry"
    
    # Top and bottom caps are usually not required for standard designs
    # But may be needed for:
    # 1. Designs with top-level I/O cells
    # 2. Special manufacturing requirements
    # 3. Extreme reliability requirements
    
    puts "Note: Top/bottom caps typically not required"
    puts "      Only add if specifically required by foundry"
    
    # If needed, would be added similar to left/right
    # Usually just regular endcap cells at top/bottom rows
}

#------------------------------------------------------------------------------
# Method 4: Macro Boundary Cells
#------------------------------------------------------------------------------
proc add_macro_boundary_cells {} {
    puts "\n=========================================="
    puts "Method 4: Macro Boundary Cells"
    puts "=========================================="
    
    set macros [dbGet top.insts.cell.subClass block -p2]
    
    if {[llength $macros] == 0} {
        puts "No macros found in design"
        return
    }
    
    puts "Found [llength $macros] macros"
    puts "Adding boundary cells around macros..."
    
    global ENDCAP_LEFT ENDCAP_RIGHT
    
    foreach macro $macros {
        set inst_name [dbGet $macro.name]
        set bbox [dbGet $macro.box]
        
        puts "\n  Macro: $inst_name"
        
        # Add end caps around macro boundaries
        # This is more complex and may require manual placement
        # or specific foundry guidelines
        
        # Example: Add endcaps at macro edges
        # Implementation depends on foundry requirements
        puts "    (Macro boundary cells require specific placement strategy)"
    }
    
    puts "\nNote: Macro boundary cells may need manual review"
}

#------------------------------------------------------------------------------
# Method 5: Voltage Domain Boundary Cells
#------------------------------------------------------------------------------
proc add_voltage_domain_boundaries {} {
    puts "\n=========================================="
    puts "Method 5: Voltage Domain Boundaries"
    puts "=========================================="
    puts "For multi-voltage designs (UPF/CPF)"
    
    # Check if design has multiple voltage domains
    set power_domains [dbGet top.powerDomains -e]
    
    if {[llength $power_domains] <= 1} {
        puts "Single voltage domain - not applicable"
        return
    }
    
    puts "Found [llength $power_domains] power domains"
    
    # Voltage domain boundaries need special cells
    # These prevent latch-up between different voltage domains
    # Specific cells: ISOLATION_BOUNDARY, LEVEL_SHIFTER_BOUNDARY, etc.
    
    puts "Voltage domain boundary cells:"
    puts "  • Isolation cells at domain boundaries"
    puts "  • Level shifters at voltage transitions"
    puts "  • Special boundary cells may be required"
    puts "  • Consult foundry UPF guidelines"
}

#------------------------------------------------------------------------------
# Verify Boundary Cell Placement
#------------------------------------------------------------------------------
proc verify_boundary_cells {} {
    puts "\n=========================================="
    puts "Verifying Boundary Cell Placement"
    puts "=========================================="
    
    set endcaps [dbGet top.insts.name *ENDCAP* -p]
    set boundary_cells [dbGet top.insts.name *BOUND* -p]
    
    set total_boundary [expr [llength $endcaps] + [llength $boundary_cells]]
    
    if {$total_boundary == 0} {
        puts "ERROR: No boundary cells found!"
        return 0
    }
    
    puts "\nBoundary Cell Count:"
    puts "  End caps: [llength $endcaps]"
    puts "  Boundary cells: [llength $boundary_cells]"
    puts "  Total: $total_boundary"
    
    # Check if all rows have end caps
    puts "\n--- Checking Row Coverage ---"
    
    # Get all standard cell rows
    set rows [dbGet top.fPlan.rows]
    set num_rows [llength $rows]
    
    puts "Total standard cell rows: $num_rows"
    puts "Expected boundary cells: [expr $num_rows * 2] (left + right)"
    
    if {$total_boundary < [expr $num_rows * 2]} {
        puts "WARNING: Insufficient boundary cells"
        puts "         Some rows may not have end caps"
    } else {
        puts "PASS: Sufficient boundary cells present"
    }
    
    # Check for DRC violations at boundaries
    puts "\n--- Checking for Boundary DRCs ---"
    puts "(Run full DRC check to verify boundary compliance)"
    
    return 1
}

#------------------------------------------------------------------------------
# Check Boundary Cell Connections
#------------------------------------------------------------------------------
proc verify_boundary_connections {} {
    puts "\n=========================================="
    puts "Verifying Boundary Cell Connections"
    puts "=========================================="
    
    set boundary_cells [dbGet top.insts.name {*ENDCAP* *BOUND*} -p]
    
    if {[llength $boundary_cells] == 0} {
        puts "No boundary cells to check"
        return 0
    }
    
    set disconnected 0
    set vdd_connected 0
    set vss_connected 0
    
    foreach cell $boundary_cells {
        set terms [dbGet $cell.instTerms]
        set has_vdd 0
        set has_vss 0
        
        foreach term $terms {
            set net_name [dbGet $term.net.name]
            if {[regexp -nocase {vdd|vcc} $net_name]} {
                set has_vdd 1
            } elseif {[regexp -nocase {vss|gnd} $net_name]} {
                set has_vss 1
            }
        }
        
        if {$has_vdd && $has_vss} {
            incr vdd_connected
            incr vss_connected
        } else {
            incr disconnected
        }
    }
    
    puts "Connection Status:"
    puts "  Total boundary cells: [llength $boundary_cells]"
    puts "  VDD connected: $vdd_connected"
    puts "  VSS connected: $vss_connected"
    puts "  Disconnected: $disconnected"
    
    if {$disconnected > 0} {
        puts "WARNING: Some boundary cells not properly connected"
    } else {
        puts "PASS: All boundary cells connected to power rails"
    }
}

#------------------------------------------------------------------------------
# Complete Boundary Cell Flow
#------------------------------------------------------------------------------
proc add_boundary_cells_complete_flow {} {
    puts "\n=========================================="
    puts "Complete Boundary Cell Insertion Flow"
    puts "=========================================="
    
    # Step 1: Show foundry requirements
    show_foundry_requirements
    
    # Step 2: Check library
    if {![check_boundary_cells_in_library]} {
        puts "\nERROR: Cannot proceed without boundary cells in library"
        return
    }
    
    # Step 3: Configure strategy
    configure_boundary_cells
    
    # Step 4: Add standard end caps
    add_endcaps_standard
    
    # Step 5: Add macro boundaries if needed
    global MACRO_ENDCAPS
    if {$MACRO_ENDCAPS == "true"} {
        add_macro_boundary_cells
    }
    
    # Step 6: Verify placement
    verify_boundary_cells
    
    # Step 7: Verify connections
    verify_boundary_connections
    
    # Step 8: Report summary
    report_boundary_summary
    
    puts "\n=========================================="
    puts "Boundary Cell Insertion Completed"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Report Summary
#------------------------------------------------------------------------------
proc report_boundary_summary {} {
    puts "\n=========================================="
    puts "Boundary Cell Summary"
    puts "=========================================="
    
    set endcaps [dbGet top.insts.name *ENDCAP* -p]
    set boundary_cells [dbGet top.insts.name *BOUND* -p]
    
    puts "\nCell Counts:"
    puts "  End caps: [llength $endcaps]"
    puts "  Boundary cells: [llength $boundary_cells]"
    puts "  Total: [expr [llength $endcaps] + [llength $boundary_cells]]"
    
    # Row coverage
    set num_rows [llength [dbGet top.fPlan.rows]]
    set expected [expr $num_rows * 2]
    set actual [expr [llength $endcaps] + [llength $boundary_cells]]
    
    puts "\nRow Coverage:"
    puts "  Total rows: $num_rows"
    puts "  Expected boundary cells: $expected"
    puts "  Actual boundary cells: $actual"
    
    if {$actual >= $expected} {
        puts "  Status: PASS"
    } else {
        puts "  Status: WARNING - Insufficient coverage"
    }
}

#==============================================================================
# BLOCK-LEVEL SPECIFIC CONSIDERATIONS
#==============================================================================
puts "\n=========================================="
puts "BLOCK-LEVEL SPECIFIC CONSIDERATIONS"
puts "=========================================="
puts ""
puts "For hierarchical block-level designs:"
puts ""
puts "1. BLOCK BOUNDARIES"
puts "   • Add boundary cells at block edges"
puts "   • Ensure well continuity at block interface"
puts "   • Match parent-level power rail structure"
puts ""
puts "2. HIERARCHICAL INTERFACE"
puts "   • Boundary cells help with block integration"
puts "   • Prevent DRC at block boundaries"
puts "   • Enable clean block-to-block abutment"
puts ""
puts "3. POWER PLANNING"
puts "   • Boundary cells maintain power rail continuity"
puts "   • Critical for hierarchical power distribution"
puts "   • Check power strap alignment at boundaries"
puts ""
puts "4. TIMING CLOSURE"
puts "   • Boundary cells affect block interface timing"
puts "   • Include in block-level timing models"
puts "   • Consider in partition planning"
puts ""
puts "5. PHYSICAL VERIFICATION"
puts "   • Boundary cells prevent edge DRCs"
puts "   • Required for LVS/DRC clean design"
puts "   • Help with antenna rule compliance"
puts ""
puts "=========================================="

#==============================================================================
# TIMING IN FLOW
#==============================================================================
puts "\n=========================================="
puts "WHEN TO ADD BOUNDARY CELLS"
puts "=========================================="
puts ""
puts "Recommended Flow:"
puts "  1. Floorplan"
puts "  2. Power Planning"
puts "  3. Pin Placement"
puts "  4. Placement"
puts "  5. Add Tie Cells"
puts "  6. Add Well Taps"
puts "  7. >>> ADD BOUNDARY CELLS <<< (HERE)"
puts "  8. Pre-CTS Optimization"
puts "  9. Clock Tree Synthesis"
puts "  10. Routing"
puts "  11. Add Fillers (Last)"
puts ""
puts "Key Points:"
puts "  • After placement (need cell positions)"
puts "  • Before CTS (CTS sees boundaries)"
puts "  • Before routing (routing knows boundaries)"
puts "  • Definitely before fillers"
puts ""
puts "=========================================="

# Uncomment to run complete flow
# add_boundary_cells_complete_flow
