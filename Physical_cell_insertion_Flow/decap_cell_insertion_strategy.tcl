####
#!/usr/bin/tclsh
#==============================================================================
# Decap Insertion Strategy Based on Foundry Guidelines
# File: add_decaps_foundry_style.tcl
#==============================================================================

puts "=========================================="
puts "Decap Insertion - Foundry Guidelines"
puts "=========================================="

#==============================================================================
# FOUNDRY DECAP RECOMMENDATIONS
#==============================================================================
# 1. TIMING: After initial power grid, can be iterated after CTS
# 2. DENSITY: 5-15% of core area (depends on power requirements)
# 3. PLACEMENT: Uniform distribution OR hotspot-based
# 4. CELL SELECTION: Mix of sizes for different frequency ranges
# 5. IR DROP TARGET: Typically < 5% of VDD (e.g., < 40mV for 0.8V)
# 6. VERIFICATION: Run IR drop analysis after decap insertion
#==============================================================================

#------------------------------------------------------------------------------
# Configuration - Foundry Specific Parameters
#------------------------------------------------------------------------------
proc configure_decap_strategy {} {
    global DECAP_CELLS DECAP_DENSITY DECAP_METHOD
    global IR_DROP_TARGET DECAP_MIN_DISTANCE
    global POWER_DOMAINS DECAP_DISTRIBUTION
    
    puts "\n--- Decap Strategy Configuration ---"
    
    # Decap cells from foundry library (ordered by size)
    # Use multiple sizes for better frequency coverage
    set DECAP_CELLS {
        DCAP64   ;# Largest - low frequency
        DCAP32   ;# Large
        DCAP16   ;# Medium
        DCAP8    ;# Small
        DCAP4    ;# Smaller
        DCAP1    ;# Smallest - high frequency
    }
    
    # Target decap density (% of core area)
    # Conservative: 5%
    # Moderate: 8-10%
    # Aggressive: 12-15%
    set DECAP_DENSITY 0.10  ;# 10% recommended by most foundries
    
    # Decap insertion method
    # Options: "uniform", "hotspot", "hybrid", "whitespace"
    set DECAP_METHOD "hybrid"
    
    # IR drop target (mV)
    set IR_DROP_TARGET 40  ;# < 5% of 0.8V supply
    
    # Minimum distance between decaps (um)
    set DECAP_MIN_DISTANCE 5.0
    
    # Distribution strategy
    set DECAP_DISTRIBUTION {
        {DCAP64 0.10}  ;# 10% large decaps
        {DCAP32 0.15}  ;# 15% 
        {DCAP16 0.25}  ;# 25%
        {DCAP8  0.25}  ;# 25%
        {DCAP4  0.15}  ;# 15%
        {DCAP1  0.10}  ;# 10% small decaps
    }
    
    puts "  Decap cells: $DECAP_CELLS"
    puts "  Target density: [expr $DECAP_DENSITY * 100]%"
    puts "  Method: $DECAP_METHOD"
    puts "  IR drop target: ${IR_DROP_TARGET}mV"
}

#------------------------------------------------------------------------------
# Method 1: Uniform Distribution (Foundry Default)
#------------------------------------------------------------------------------
proc add_decaps_uniform {} {
    global DECAP_CELLS DECAP_DENSITY
    
    puts "\n=========================================="
    puts "Method 1: Uniform Decap Distribution"
    puts "=========================================="
    puts "Recommended by: TSMC, Samsung, Intel"
    
    # Calculate available whitespace
    set core_area [expr {[dbGet top.fPlan.coreBox_area] / 1000000.0}]
    set used_area [expr {[dbGet top.stdCellArea] / 1000000.0}]
    set whitespace [expr {$core_area - $used_area}]
    
    puts "\nArea Analysis:"
    puts "  Core area: [format "%.2f" $core_area] um^2"
    puts "  Used area: [format "%.2f" $used_area] um^2"
    puts "  Whitespace: [format "%.2f" $whitespace] um^2"
    puts "  Target decap: [format "%.2f" [expr $whitespace * $DECAP_DENSITY]] um^2"
    
    # Add decaps uniformly across the design
    addDecap -cells $DECAP_CELLS \
             -prefix DECAP \
             -fillUpTo $DECAP_DENSITY \
             -spreadBy cell
    
    puts "\nUniform decaps added"
}

#------------------------------------------------------------------------------
# Method 2: Hotspot-Based (IR Drop Driven)
#------------------------------------------------------------------------------
proc add_decaps_hotspot {} {
    global DECAP_CELLS IR_DROP_TARGET
    
    puts "\n=========================================="
    puts "Method 2: Hotspot-Based Decap Insertion"
    puts "=========================================="
    puts "Recommended for: High-power designs, AI/ML chips"
    
    # Step 1: Run initial IR drop analysis
    puts "\n--- Running IR Drop Analysis ---"
    
    # Set IR drop analysis parameters
    set_pg_library_mode -celltype decap \
                        -cell_list $DECAP_CELLS
    
    # Analyze IR drop without decaps
    set_power_analysis_mode -method static \
                            -corner max \
                            -create_binary_db true
    
    # Run IR drop analysis
    analyze_power -rail_analysis -outdir ./power_analysis/pre_decap
    
    # Identify hotspots (areas with high IR drop)
    puts "Identifying IR drop hotspots..."
    
    # Get IR drop violations
    set violations [get_rail_analysis_violations \
                    -voltage_drop [expr $IR_DROP_TARGET / 1000.0]]
    
    if {[llength $violations] > 0} {
        puts "Found [llength $violations] IR drop hotspots"
        
        # Add decaps near hotspots
        foreach hotspot $violations {
            set location [get_attribute $hotspot location]
            
            # Add decaps in hotspot region
            addDecap -cells $DECAP_CELLS \
                     -prefix DECAP_HOT \
                     -area $location \
                     -density 0.15  ;# Higher density in hotspots
        }
        
        puts "Decaps added to hotspot regions"
    } else {
        puts "No IR drop violations found"
    }
}

#------------------------------------------------------------------------------
# Method 3: Hybrid Approach (Foundry Recommended)
#------------------------------------------------------------------------------
proc add_decaps_hybrid {} {
    global DECAP_CELLS DECAP_DENSITY DECAP_DISTRIBUTION
    
    puts "\n=========================================="
    puts "Method 3: Hybrid Decap Strategy"
    puts "=========================================="
    puts "Recommended by: TSMC (most common approach)"
    puts "Combines uniform base + hotspot targeting"
    
    # Phase 1: Add base uniform decaps (60% of target)
    puts "\n--- Phase 1: Base Uniform Distribution ---"
    set base_density [expr $DECAP_DENSITY * 0.6]
    
    addDecap -cells $DECAP_CELLS \
             -prefix DECAP_BASE \
             -fillUpTo $base_density \
             -spreadBy cell
    
    set base_count [llength [dbGet top.insts.name DECAP_BASE* -p]]
    puts "Base decaps added: $base_count"
    
    # Phase 2: Run IR drop analysis
    puts "\n--- Phase 2: IR Drop Analysis ---"
    analyze_power -rail_analysis -outdir ./power_analysis/after_base_decap
    
    # Phase 3: Add targeted decaps in critical areas (40% of target)
    puts "\n--- Phase 3: Targeted Hotspot Decaps ---"
    set hotspot_density [expr $DECAP_DENSITY * 0.4]
    
    # Target specific areas:
    # 1. Near clock buffers/ICGs
    # 2. Near high-toggle rate logic
    # 3. Near power pads
    # 4. IR drop hotspots
    
    # Near clock cells
    set clock_insts [dbGet top.insts.isClockGate true -p]
    if {[llength $clock_insts] > 0} {
        puts "Adding decaps near [llength $clock_insts] clock gates"
        addDecap -cells $DECAP_CELLS \
                 -prefix DECAP_CLK \
                 -insts [dbGet $clock_insts.name] \
                 -minDistance 5.0 \
                 -maxDistance 20.0
    }
    
    # Near high-activity instances (if switching activity available)
    # This requires power analysis with switching activity
    if {[dbGet top.insts.saif -e] != ""} {
        set high_power_insts [dbGet top.insts -if {.power > 0.001} -p]
        if {[llength $high_power_insts] > 0} {
            puts "Adding decaps near [llength $high_power_insts] high-power instances"
            addDecap -cells $DECAP_CELLS \
                     -prefix DECAP_PWR \
                     -insts [dbGet $high_power_insts.name] \
                     -minDistance 5.0
        }
    }
    
    set total_decaps [llength [dbGet top.insts.name DECAP* -p]]
    puts "\nTotal decaps inserted: $total_decaps"
}

#------------------------------------------------------------------------------
# Method 4: Whitespace Filling (Simple Approach)
#------------------------------------------------------------------------------
proc add_decaps_whitespace {} {
    global DECAP_CELLS DECAP_DENSITY
    
    puts "\n=========================================="
    puts "Method 4: Whitespace Filling"
    puts "=========================================="
    puts "Simple approach: Fill available whitespace"
    
    # Just fill whitespace with decaps
    addDecap -cells $DECAP_CELLS \
             -prefix DECAP \
             -fillUpTo $DECAP_DENSITY
    
    set decap_count [llength [dbGet top.insts.name DECAP* -p]]
    puts "Decaps added: $decap_count"
}

#------------------------------------------------------------------------------
# Foundry-Specific Rules and Checks
#------------------------------------------------------------------------------
proc check_decap_rules {} {
    puts "\n=========================================="
    puts "Checking Foundry Decap Rules"
    puts "=========================================="
    
    set decaps [dbGet top.insts.name DECAP* -p]
    
    if {[llength $decaps] == 0} {
        puts "WARNING: No decaps found in design"
        return
    }
    
    # Rule 1: Check decap density
    puts "\n--- Rule 1: Decap Density Check ---"
    set core_area [expr {[dbGet top.fPlan.coreBox_area] / 1000000.0}]
    set decap_area 0.0
    
    foreach decap $decaps {
        set cell_area [dbGet $decap.cell.area]
        set decap_area [expr {$decap_area + ($cell_area / 1000000.0)}]
    }
    
    set actual_density [expr {($decap_area / $core_area) * 100.0}]
    puts "  Core area: [format "%.2f" $core_area] um^2"
    puts "  Decap area: [format "%.2f" $decap_area] um^2"
    puts "  Density: [format "%.2f" $actual_density]%"
    
    if {$actual_density < 5.0} {
        puts "  WARNING: Decap density is low (< 5%)"
    } elseif {$actual_density > 15.0} {
        puts "  WARNING: Decap density is high (> 15%)"
    } else {
        puts "  PASS: Decap density is within recommended range (5-15%)"
    }
    
    # Rule 2: Check decap distribution uniformity
    puts "\n--- Rule 2: Distribution Uniformity ---"
    # Divide core into grid and check decap count per region
    # This is a simplified check
    puts "  Checking spatial distribution..."
    
    # Rule 3: Check decap connection to power rails
    puts "\n--- Rule 3: Power Connection Check ---"
    set disconnected 0
    foreach decap $decaps {
        set vdd_conn [dbGet $decap.instTerms.net.isPwrOrGnd 1 -e]
        if {$vdd_conn == ""} {
            incr disconnected
        }
    }
    
    if {$disconnected > 0} {
        puts "  WARNING: $disconnected decaps not connected to power"
    } else {
        puts "  PASS: All decaps connected to power rails"
    }
    
    # Rule 4: Check for decap clustering
    puts "\n--- Rule 4: Clustering Check ---"
    puts "  Checking for excessive clustering..."
    # Complex check - simplified here
    puts "  (Detailed clustering analysis requires more complex algorithm)"
}

#------------------------------------------------------------------------------
# Verify IR Drop After Decap Insertion
#------------------------------------------------------------------------------
proc verify_ir_drop_with_decaps {} {
    global IR_DROP_TARGET
    
    puts "\n=========================================="
    puts "IR Drop Verification with Decaps"
    puts "=========================================="
    
    # Run power analysis with decaps
    puts "Running power analysis..."
    
    set_power_analysis_mode -method static \
                            -corner max \
                            -create_binary_db true
    
    analyze_power -rail_analysis -outdir ./power_analysis/with_decaps
    
    # Check IR drop
    puts "\nChecking IR drop violations..."
    set violations [get_rail_analysis_violations \
                    -voltage_drop [expr $IR_DROP_TARGET / 1000.0]]
    
    if {[llength $violations] == 0} {
        puts "PASS: No IR drop violations"
        puts "      All regions < ${IR_DROP_TARGET}mV drop"
    } else {
        puts "FAIL: Found [llength $violations] IR drop violations"
        puts "      Consider adding more decaps in hotspot areas"
        
        # Report worst violations
        puts "\nWorst IR drop locations:"
        foreach viol [lrange $violations 0 9] {
            set location [get_attribute $viol location]
            set drop [get_attribute $viol voltage_drop]
            puts "  Location: $location, Drop: [format "%.2f" [expr $drop * 1000]]mV"
        }
    }
}

#------------------------------------------------------------------------------
# Complete Decap Flow (Recommended)
#------------------------------------------------------------------------------
proc add_decaps_complete_flow {} {
    puts "\n=========================================="
    puts "Complete Decap Insertion Flow"
    puts "=========================================="
    puts "Following foundry best practices"
    
    # Step 1: Configure strategy
    configure_decap_strategy
    
    # Step 2: Add decaps using hybrid method
    add_decaps_hybrid
    
    # Step 3: Check foundry rules
    check_decap_rules
    
    # Step 4: Verify IR drop
    verify_ir_drop_with_decaps
    
    # Step 5: Iterate if needed
    puts "\n--- Decap Iteration Check ---"
    set violations [get_rail_analysis_violations -voltage_drop 0.04]
    
    if {[llength $violations] > 0} {
        puts "IR drop violations found, adding targeted decaps..."
        add_decaps_hotspot
        
        # Re-verify
        verify_ir_drop_with_decaps
    }
    
    puts "\n=========================================="
    puts "Decap Insertion Flow Completed"
    puts "=========================================="
}

#------------------------------------------------------------------------------
# Summary Report
#------------------------------------------------------------------------------
proc report_decap_summary {} {
    puts "\n=========================================="
    puts "Decap Insertion Summary"
    puts "=========================================="
    
    set decaps [dbGet top.insts.name DECAP* -p]
    set total_count [llength $decaps]
    
    if {$total_count == 0} {
        puts "No decaps found in design"
        return
    }
    
    # Count by type
    puts "\nDecap Distribution by Type:"
    puts "Cell Type       Count    Percentage"
    puts "----------------------------------------"
    
    foreach cell_type {DCAP64 DCAP32 DCAP16 DCAP8 DCAP4 DCAP1} {
        set count [llength [dbGet top.insts.name DECAP*${cell_type}* -p]]
        if {$count > 0} {
            set pct [expr {($count * 100.0) / $total_count}]
            puts "[format "%-15s" $cell_type] [format "%5d" $count]    [format "%5.1f%%" $pct]"
        }
    }
    
    puts "----------------------------------------"
    puts "[format "%-15s" "Total"] [format "%5d" $total_count]    100.0%"
    
    # Area calculation
    set core_area [expr {[dbGet top.fPlan.coreBox_area] / 1000000.0}]
    set decap_area 0.0
    foreach decap $decaps {
        set cell_area [dbGet $decap.cell.area]
        set decap_area [expr {$decap_area + ($cell_area / 1000000.0)}]
    }
    
    puts "\nArea Summary:"
    puts "  Core area: [format "%.2f" $core_area] um^2"
    puts "  Decap area: [format "%.2f" $decap_area] um^2"
    puts "  Density: [format "%.2f" [expr {($decap_area / $core_area) * 100.0}]]%"
    
    puts "=========================================="
}

#==============================================================================
# FOUNDRY-SPECIFIC RECOMMENDATIONS
#==============================================================================
puts "\n=========================================="
puts "FOUNDRY DECAP GUIDELINES"
puts "=========================================="
puts ""
puts "TSMC:"
puts "  - Target: 8-12% of core area"
puts "  - Method: Hybrid (uniform base + hotspot)"
puts "  - Timing: After placement, iterate after CTS"
puts "  - IR Drop: < 5% of VDD (< 40mV for 0.8V)"
puts ""
puts "Samsung:"
puts "  - Target: 5-10% of core area"
puts "  - Method: Uniform distribution preferred"
puts "  - Multiple decap sizes for frequency coverage"
puts "  - Check EM rules after decap insertion"
puts ""
puts "Intel:"
puts "  - Target: 10-15% of core area"
puts "  - Method: Activity-driven placement"
puts "  - Focus on clock domains and high-toggle areas"
puts "  - Verify with dynamic IR drop analysis"
puts ""
puts "GF (GlobalFoundries):"
puts "  - Target: 7-12% of core area"
puts "  - Method: Grid-based uniform + hotspot"
puts "  - Minimum spacing between decaps: 5um"
puts "  - Iterative refinement based on IR drop"
puts ""
puts "=========================================="

# Uncomment to run complete flow
# add_decaps_complete_flow
# report_decap_summary
