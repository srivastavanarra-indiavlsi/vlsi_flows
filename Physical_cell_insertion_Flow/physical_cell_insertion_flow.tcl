####
#!/usr/bin/tclsh
#==============================================================================
# Physical Cells Insertion Flow
# File: add_physical_cells.tcl
# Description: Complete flow for adding physical cells in proper sequence
#==============================================================================

set DESIGN_NAME "my_design"

puts "=========================================="
puts "Physical Cells Insertion Flow"
puts "=========================================="

#==============================================================================
# TIMING OF PHYSICAL CELL INSERTION
#==============================================================================
# 1. Well Taps       -> AFTER Placement (before filler)
# 2. End Caps        -> AFTER Placement (before filler)
# 3. Tie Cells       -> AFTER Placement (can be during optimization)
# 4. Decaps          -> AFTER Placement, BEFORE/AFTER CTS (design dependent)
# 5. Spare Cells     -> AFTER Placement (before filler)
# 6. Filler Cells    -> LAST (after all other physical cells)
#==============================================================================

#------------------------------------------------------------------------------
# STAGE 1: TIE CELLS (Tie-High and Tie-Low)
#------------------------------------------------------------------------------
# WHEN: After placement, can be during pre-CTS optimization
# WHY: Connect floating inputs to VDD/VSS
#------------------------------------------------------------------------------
proc add_tie_cells {} {
    puts "\n=========================================="
    puts "STAGE 1: Adding Tie Cells"
    puts "=========================================="
    
    # Define tie cell names from your library
    set tie_hi_cell "TIEHI_X1"
    set tie_lo_cell "TIELO_X1"
    
    # Set tie cells
    setTieHiLoMode -cell ${tie_hi_cell} -createHierarchyPort false
    setTieHiLoMode -cell ${tie_lo_cell} -createHierarchyPort false
    
    # Maximum fanout for tie cells
    setTieHiLoMode -maxFanout 8
    
    # Add tie cells
    addTieHiLo -prefix TIEHI -cell ${tie_hi_cell}
    addTieHiLo -prefix TIELO -cell ${tie_lo_cell}
    
    puts "Tie cells added"
    puts "  Tie-High cell: $tie_hi_cell"
    puts "  Tie-Low cell: $tie_lo_cell"
    puts "  Max fanout: 8"
    
    # Report tie cell count
    set tie_insts [dbGet top.insts.name TIE* -p]
    puts "  Total tie cells: [llength $tie_insts]"
}

#------------------------------------------------------------------------------
# STAGE 2: WELL TAP CELLS
#------------------------------------------------------------------------------
# WHEN: After placement
# WHY: Prevent latchup, connect n-well/p-substrate to power rails
#------------------------------------------------------------------------------
proc add_well_taps {} {
    puts "\n=========================================="
    puts "STAGE 2: Adding Well Tap Cells"
    puts "=========================================="
    
    # Define well tap cell from your library
    set well_tap_cell "WELLTAP"
    
    # Well tap spacing (distance between taps)
    # Typically 30-60um depending on technology
    set tap_distance 30.0  ;# um
    
    # Add well taps
    setWellTapMode -cell $well_tap_cell \
                   -cellInterval $tap_distance \
                   -prefix WELLTAP
    
    # Add in checkerboard pattern
    addWellTap -checkerboard -cellInterval $tap_distance
    
    puts "Well tap cells added"
    puts "  Cell: $well_tap_cell"
    puts "  Spacing: ${tap_distance}um"
    
    # Report well tap count
    set tap_count [llength [dbGet top.insts.name WELLTAP* -p]]
    puts "  Total well taps: $tap_count"
}

#------------------------------------------------------------------------------
# STAGE 3: END CAP CELLS (Boundary Cells)
#------------------------------------------------------------------------------
# WHEN: After placement, before filler
# WHY: Terminate rows at boundaries, prevent DRC violations
#------------------------------------------------------------------------------
proc add_end_caps {} {
    puts "\n=========================================="
    puts "STAGE 3: Adding End Cap Cells"
    puts "=========================================="
    
    # Define end cap cells from your library
    # Usually have different cells for left/right boundaries
    set end_cap_left "ENDCAP_LEFT"
    set end_cap_right "ENDCAP_RIGHT"
    
    # Or single end cap for both sides
    set end_cap "ENDCAP"
    
    # Method 1: If separate left/right cells
    if {[dbGet head.libCells.name $end_cap_left -e] != "" && \
        [dbGet head.libCells.name $end_cap_right -e] != ""} {
        
        setEndCapMode -prefix ENDCAP \
                      -leftEdge $end_cap_left \
                      -rightEdge $end_cap_right
        
        addEndCap
        
        puts "End cap cells added (separate left/right)"
        puts "  Left edge: $end_cap_left"
        puts "  Right edge: $end_cap_right"
    
    # Method 2: If single end cap cell
    } elseif {[dbGet head.libCells.name $end_cap -e] != ""} {
        
        setEndCapMode -prefix ENDCAP \
                      -boundary_tap true
        
        addEndCap -cell $end_cap
        
        puts "End cap cells added (single type)"
        puts "  Cell: $end_cap"
    
    } else {
        puts "WARNING: No end cap cells found in library"
        return
    }
    
    # Report end cap count
    set endcap_count [llength [dbGet top.insts.name ENDCAP* -p]]
    puts "  Total end caps: $endcap_count"
}

#------------------------------------------------------------------------------
# STAGE 4: DECAP CELLS (Decoupling Capacitors)
#------------------------------------------------------------------------------
# WHEN: After placement, can be before or after CTS
# WHY: Improve power supply stability, reduce voltage drop
#------------------------------------------------------------------------------
proc add_decap_cells {} {
    puts "\n=========================================="
    puts "STAGE 4: Adding Decap Cells"
    puts "=========================================="
    
    # Define decap cells from your library (multiple sizes)
    set decap_cells "DECAP_X1 DECAP_X2 DECAP_X4 DECAP_X8"
    
    # Target decap density (percentage of whitespace)
    set decap_density 0.05  ;# 5% of whitespace
    
    # Method 1: Add decaps to fill whitespace
    addDecap -cells $decap_cells \
             -prefix DECAP \
             -fillUpTo $decap_density
    
    puts "Decap cells added"
    puts "  Cells: $decap_cells"
    puts "  Target density: [expr $decap_density * 100]%"
    
    # Method 2: Add decaps near specific instances (optional)
    # addDecap -cells $decap_cells -insts {critical_cell1 critical_cell2}
    
    # Report decap count
    set decap_count [llength [dbGet top.insts.name DECAP* -p]]
    puts "  Total decaps: $decap_count"
    
    # Report total decap capacitance
    set total_cap 0.0
    foreach inst [dbGet top.insts.name DECAP* -p] {
        # This would need actual capacitance extraction
        # Just counting for now
    }
}

#------------------------------------------------------------------------------
# STAGE 5: SPARE CELLS (for ECO)
#------------------------------------------------------------------------------
# WHEN: After placement, before filler
# WHY: Reserve cells for future ECOs (Engineering Change Orders)
#------------------------------------------------------------------------------
proc add_spare_cells {} {
    puts "\n=========================================="
    puts "STAGE 5: Adding Spare Cells"
    puts "=========================================="
    
    # Define spare cell types and quantities
    # These are standard cells reserved for ECOs
    set spare_cells {
        {INV_X1 10}
        {BUF_X1 10}
        {NAND2_X1 5}
        {NOR2_X1 5}
        {AND2_X1 5}
        {OR2_X1 5}
        {XOR2_X1 5}
        {MUX2_X1 5}
        {DFF_X1 10}
    }
    
    set spare_count 0
    foreach cell_info $spare_cells {
        set cell_type [lindex $cell_info 0]
        set quantity [lindex $cell_info 1]
        
        # Check if cell exists in library
        if {[dbGet head.libCells.name $cell_type -e] != ""} {
            # Add spare cells
            for {set i 0} {$i < $quantity} {incr i} {
                createInst -cell $cell_type -inst SPARE_${cell_type}_${i}
                incr spare_count
            }
            puts "  Added $quantity x $cell_type"
        }
    }
    
    puts "Total spare cells added: $spare_count"
    
    # Place spare cells in whitespace
    placeInstance SPARE_* -placed
    
    # Disconnect spare cells (not used in functional path)
    foreach inst [dbGet top.insts.name SPARE_* -p] {
        set inst_name [dbGet $inst.name]
        # Tie inputs appropriately
        # Connect to tie cells or leave floating (design dependent)
    }
}

#------------------------------------------------------------------------------
# STAGE 6: FILLER CELLS (Must be LAST)
#------------------------------------------------------------------------------
# WHEN: After ALL other physical cells
# WHY: Fill gaps, ensure continuous n-well and power rails
#------------------------------------------------------------------------------
proc add_filler_cells {} {
    puts "\n=========================================="
    puts "STAGE 6: Adding Filler Cells (FINAL STEP)"
    puts "=========================================="
    
    # Define filler cells from your library
    # Usually multiple sizes to fill different gap sizes
    set filler_cells "FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1"
    
    # Add filler cells
    addFiller -cell $filler_cells \
              -prefix FILLER \
              -doDRC
    
    puts "Filler cells added"
    puts "  Cells: $filler_cells"
    
    # Report filler count
    set filler_count [llength [dbGet top.insts.name FILLER* -p]]
    puts "  Total fillers: $filler_count"
    
    # Verify no gaps remain
    checkFiller -verbose
}

#------------------------------------------------------------------------------
# Complete Physical Cells Flow
#------------------------------------------------------------------------------
proc add_all_physical_cells {} {
    puts "\n=========================================="
    puts "Adding All Physical Cells in Sequence"
    puts "=========================================="
    
    # Step 1: Tie cells (can be added during optimization)
    add_tie_cells
    
    # Step 2: Well taps
    add_well_taps
    
    # Step 3: End caps
    add_end_caps
    
    # Step 4: Decaps (optional, can be after CTS)
    add_decap_cells
    
    # Step 5: Spare cells (optional)
    add_spare_cells
    
    # Step 6: Filler cells (MUST BE LAST)
    add_filler_cells
    
    puts "\n=========================================="
    puts "All Physical Cells Added Successfully"
    puts "=========================================="
    
    # Final report
    report_physical_cells
}

#------------------------------------------------------------------------------
# Report Physical Cells Summary
#------------------------------------------------------------------------------
proc report_physical_cells {} {
    puts "\n=========================================="
    puts "Physical Cells Summary"
    puts "=========================================="
    
    set tie_count [llength [dbGet top.insts.name TIE* -p]]
    set tap_count [llength [dbGet top.insts.name WELLTAP* -p]]
    set endcap_count [llength [dbGet top.insts.name ENDCAP* -p]]
    set decap_count [llength [dbGet top.insts.name DECAP* -p]]
    set spare_count [llength [dbGet top.insts.name SPARE_* -p]]
    set filler_count [llength [dbGet top.insts.name FILLER* -p]]
    
    puts "Cell Type          Count"
    puts "--------------------------------"
    puts "Tie Cells:         $tie_count"
    puts "Well Taps:         $tap_count"
    puts "End Caps:          $endcap_count"
    puts "Decaps:            $decap_count"
    puts "Spare Cells:       $spare_count"
    puts "Filler Cells:      $filler_count"
    puts "--------------------------------"
    set total [expr $tie_count + $tap_count + $endcap_count + $decap_count + $spare_count + $filler_count]
    puts "Total Physical:    $total"
    puts "=========================================="
}

#==============================================================================
# MAIN EXECUTION
#==============================================================================

puts "\n=========================================="
puts "RECOMMENDED FLOW SEQUENCE"
puts "=========================================="
puts "1. Floorplan"
puts "2. Power Planning"
puts "3. Pin Placement"
puts "4. Placement        <- You are here"
puts "5. Add Tie Cells    <- Run now"
puts "6. Pre-CTS Opt"
puts "7. Add Well Taps    <- Run before CTS"
puts "8. Add End Caps     <- Run before CTS"
puts "9. Clock Tree"
puts "10. Add Decaps      <- Run after CTS (optional)"
puts "11. Post-CTS Opt"
puts "12. Add Spare Cells <- Run before routing (optional)"
puts "13. Routing"
puts "14. Add Fillers     <- Run LAST, after routing"
puts "=========================================="

# Uncomment to run the complete flow
# add_all_physical_cells
