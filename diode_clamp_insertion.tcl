#!/usr/bin/tclsh
###############################################################################
# IC ESD and Power Clamp Insertion Script
# Adds ESD protection and power clamps to IC designs
# Compatible with Cadence Innovus/EDI, Synopsys ICC2/IC Compiler
###############################################################################

namespace eval ::clamp_inserter {
    variable esd_clamps {}
    variable power_clamps {}
    variable report_file "clamp_insertion_report.log"
    variable resistance_report {}
    variable drc_violations {}
    variable pdn_analysis {}
}

###############################################################################
# Procedure: calculate_decap_requirements
# Description: Calculate decap requirements based on power network analysis
###############################################################################
proc ::clamp_inserter::calculate_decap_requirements {args} {
    
    # Parse arguments
    set max_voltage_droop 0.05  ;# 5% voltage droop limit (50mV for 1V supply)
    set switching_current 100   ;# Peak switching current in mA
    set frequency 1000          ;# Target frequency in MHz
    set supply_voltage 1.0      ;# Supply voltage in V
    set target_impedance 0.5    ;# Target impedance in ohms
    
    parse_proc_arguments -args $args options
    
    if {[info exists options(-max_droop)]} {
        set max_voltage_droop $options(-max_droop)
    }
    if {[info exists options(-switching_current)]} {
        set switching_current $options(-switching_current)
    }
    if {[info exists options(-frequency)]} {
        set frequency $options(-frequency)
    }
    if {[info exists options(-supply_voltage)]} {
        set supply_voltage $options(-supply_voltage)
    }
    if {[info exists options(-target_impedance)]} {
        set target_impedance $options(-target_impedance)
    }
    
    puts "\n=========================================="
    puts "INFO: Calculating Decap Requirements"
    puts "=========================================="
    
    # Calculate target impedance from voltage droop
    # Z_target = ΔV / I_peak
    set calc_impedance [expr {($max_voltage_droop * $supply_voltage) / ($switching_current / 1000.0)}]
    
    puts "Supply Voltage: ${supply_voltage}V"
    puts "Max Voltage Droop: [expr {$max_voltage_droop * 100}]% ([expr {$max_voltage_droop * $supply_voltage * 1000}]mV)"
    puts "Switching Current: ${switching_current}mA"
    puts "Target Frequency: ${frequency}MHz"
    puts "Calculated Target Impedance: [format %.3f $calc_impedance]Ω"
    puts "Design Target Impedance: [format %.3f $target_impedance]Ω"
    
    # Use the more stringent requirement
    set final_impedance [expr {min($calc_impedance, $target_impedance)}]
    
    # Calculate required capacitance
    # C = 1 / (2π * f * Z)
    set pi 3.14159265359
    set freq_hz [expr {$frequency * 1.0e6}]
    set required_cap [expr {1.0 / (2 * $pi * $freq_hz * $final_impedance)}]
    set required_cap_nf [expr {$required_cap * 1.0e9}]  ;# Convert to nF
    
    puts "Required Total Capacitance: [format %.2f $required_cap_nf]nF"
    
    # Calculate ESR and ESL requirements
    # ESR should be < Z_target
    set max_esr $final_impedance
    # ESL calculation: ωL < Z_target, so L < Z/(2πf)
    set max_esl [expr {$final_impedance / (2 * $pi * $freq_hz)}]
    set max_esl_ph [expr {$max_esl * 1.0e12}]  ;# Convert to pH
    
    puts "Maximum ESR: [format %.3f $max_esr]Ω"
    puts "Maximum ESL: [format %.1f $max_esl_ph]pH"
    
    # Recommend decap distribution strategy
    puts "\n--- Decap Distribution Strategy ---"
    
    # Typical decap values and their characteristics
    array set decap_types {
        LARGE   {cap 10.0  esr 0.1  esl 500  desc "Bulk capacitor (10nF)"}
        MEDIUM  {cap 1.0   esr 0.3  esl 200  desc "Mid-frequency (1nF)"}
        SMALL   {cap 0.1   esr 0.5  esl 100  desc "High-frequency (100pF)"}
    }
    
    # Calculate number of each type needed
    set decap_plan {}
    
    # Strategy: Use mix of sizes for different frequency ranges
    # Large caps: Low frequency, near power pads (10-100MHz)
    set large_cap_nf 10.0
    set num_large [expr {int(ceil($required_cap_nf * 0.5 / $large_cap_nf))}]
    lappend decap_plan [list "LARGE" $num_large $large_cap_nf "Near power pads" "10-100MHz"]
    
    # Medium caps: Mid frequency, distributed (100MHz-1GHz)
    set medium_cap_nf 1.0
    set num_medium [expr {int(ceil($required_cap_nf * 0.3 / $medium_cap_nf))}]
    lappend decap_plan [list "MEDIUM" $num_medium $medium_cap_nf "Along power rails" "100MHz-1GHz"]
    
    # Small caps: High frequency, near logic blocks (1GHz+)
    set small_cap_nf 0.1
    set num_small [expr {int(ceil($required_cap_nf * 0.2 / $small_cap_nf))}]
    lappend decap_plan [list "SMALL" $num_small $small_cap_nf "Near logic blocks" "1GHz+"]
    
    puts ""
    puts "Type      Qty    Value    Location              Frequency"
    puts "--------  -----  -------  --------------------  ----------"
    foreach plan $decap_plan {
        set type [lindex $plan 0]
        set qty [lindex $plan 1]
        set val [lindex $plan 2]
        set loc [lindex $plan 3]
        set freq [lindex $plan 4]
        puts [format "%-8s  %-5d  %6.1fnF  %-20s  %s" $type $qty $val $loc $freq]
    }
    
    set total_decaps [expr {$num_large + $num_medium + $num_small}]
    puts "\nTotal Decaps Required: $total_decaps"
    
    return [list $required_cap_nf $decap_plan $final_impedance]
}

###############################################################################
# Procedure: analyze_pdn_impedance
# Description: Analyze PDN impedance across frequency range
###############################################################################
proc ::clamp_inserter::analyze_pdn_impedance {args} {
    variable pdn_analysis
    
    # Parse arguments
    set pkg_l 1.0      ;# Package inductance in nH
    set pkg_r 0.01     ;# Package resistance in ohms
    set pcb_l 0.5      ;# PCB trace inductance in nH
    set pcb_r 0.005    ;# PCB trace resistance in ohms
    
    parse_proc_arguments -args $args options
    
    if {[info exists options(-pkg_l)]} {set pkg_l $options(-pkg_l)}
    if {[info exists options(-pkg_r)]} {set pkg_r $options(-pkg_r)}
    if {[info exists options(-pcb_l)]} {set pcb_l $options(-pcb_l)}
    if {[info exists options(-pcb_r)]} {set pcb_r $options(-pcb_r)}
    
    puts "\n=========================================="
    puts "INFO: PDN Impedance Analysis"
    puts "=========================================="
    puts "Package Inductance: ${pkg_l}nH"
    puts "Package Resistance: ${pkg_r}Ω"
    puts "PCB Inductance: ${pcb_l}nH"
    puts "PCB Resistance: ${pcb_r}Ω"
    
    set pi 3.14159265359
    
    # Analyze impedance at key frequencies
    set frequencies {1 10 100 500 1000 2000}  ;# MHz
    
    puts "\n--- Impedance vs Frequency ---"
    puts "Frequency    Inductive    Resistive    Total"
    puts "(MHz)        Impedance    Component    Impedance"
    puts "----------   ----------   ----------   ----------"
    
    set pdn_analysis {}
    
    foreach freq_mhz $frequencies {
        set freq_hz [expr {$freq_mhz * 1.0e6}]
        set omega [expr {2 * $pi * $freq_hz}]
        
        # Total inductance
        set total_l [expr {($pkg_l + $pcb_l) * 1.0e-9}]  ;# Convert to H
        
        # Inductive reactance: XL = ωL
        set xl [expr {$omega * $total_l}]
        
        # Total resistance
        set total_r [expr {$pkg_r + $pcb_r}]
        
        # Total impedance: Z = sqrt(R² + XL²)
        set z_total [expr {sqrt($total_r * $total_r + $xl * $xl)}]
        
        puts [format "%-10d   %9.3fΩ   %9.3fΩ   %9.3fΩ" \
            $freq_mhz $xl $total_r $z_total]
        
        lappend pdn_analysis [list $freq_mhz $z_total $xl $total_r]
        
        # Check for resonance issues
        if {$z_total > 1.0} {
            puts "  ⚠ WARNING: High impedance at ${freq_mhz}MHz - may cause voltage droop"
        }
    }
    
    return $pdn_analysis
}

###############################################################################
# Procedure: check_anti_resonance
# Description: Check for anti-resonance between decap combinations
###############################################################################
proc ::clamp_inserter::check_anti_resonance {cap1_nf esl1_ph cap2_nf esl2_ph} {
    
    set pi 3.14159265359
    
    # Convert to SI units
    set c1 [expr {$cap1_nf * 1.0e-9}]  ;# F
    set l1 [expr {$esl1_ph * 1.0e-12}] ;# H
    set c2 [expr {$cap2_nf * 1.0e-9}]  ;# F
    set l2 [expr {$esl2_ph * 1.0e-12}] ;# H
    
    # Self-resonant frequencies
    # f_res = 1 / (2π√(LC))
    set f1 [expr {1.0 / (2 * $pi * sqrt($l1 * $c1))}]
    set f2 [expr {1.0 / (2 * $pi * sqrt($l2 * $c2))}]
    
    set f1_mhz [expr {$f1 / 1.0e6}]
    set f2_mhz [expr {$f2 / 1.0e6}]
    
    # Check if resonant frequencies are too close (within 20%)
    set ratio [expr {max($f1, $f2) / min($f1, $f2)}]
    
    if {$ratio < 1.2} {
        puts "⚠ WARNING: Anti-resonance risk!"
        puts "  Cap1 resonance: [format %.1f $f1_mhz]MHz"
        puts "  Cap2 resonance: [format %.1f $f2_mhz]MHz"
        puts "  Recommendation: Use different decap values or add damping"
        return 0
    }
    
    return 1
}

###############################################################################
# Procedure: calculate_resistance
# Description: Calculate resistance of ESD discharge path
###############################################################################
proc ::clamp_inserter::calculate_resistance {inst_name pin_name top_layer} {
    variable resistance_report
    
    # Typical resistance values (ohms per square and per via)
    # These should be updated based on your technology node
    array set metal_rs {
        M1  0.080
        M2  0.080
        M3  0.040
        M4  0.040
        M5  0.020
        M6  0.010
        M7  0.008
        M8  0.006
        M9  0.004
    }
    
    array set via_r {
        V1  0.5
        V2  0.5
        V3  0.3
        V4  0.3
        V5  0.2
        V6  0.15
        V7  0.10
        V8  0.08
    }
    
    set pin [get_pins -quiet -of_object [get_cells $inst_name] -filter "name==$pin_name"]
    
    if {[sizeof_collection $pin] == 0} {
        return -1
    }
    
    set pin_layer [get_attribute $pin layer]
    
    # Calculate total resistance through via stack
    set total_r 0.0
    set path_layers {}
    
    # Parse layer numbers
    regexp {M(\d+)} $pin_layer match pin_layer_num
    regexp {M(\d+)} $top_layer match top_layer_num
    
    if {![info exists pin_layer_num] || ![info exists top_layer_num]} {
        puts "WARNING: Could not parse layer numbers"
        return -1
    }
    
    # Sum resistance through each via and metal segment
    for {set i $pin_layer_num} {$i < $top_layer_num} {incr i} {
        set metal_layer "M$i"
        set via_layer "V$i"
        
        # Metal segment resistance (assume 2um width, 1um length)
        if {[info exists metal_rs($metal_layer)]} {
            set metal_r [expr {$metal_rs($metal_layer) * 0.5}]  # 0.5 squares
            set total_r [expr {$total_r + $metal_r}]
            lappend path_layers "$metal_layer: [format %.3f $metal_r]Ω"
        }
        
        # Via resistance (for 2x2 array, divide by 4)
        if {[info exists via_r($via_layer)]} {
            set single_via_r $via_r($via_layer)
            set via_array_r [expr {$single_via_r / 4.0}]  # 4 vias in parallel
            set total_r [expr {$total_r + $via_array_r}]
            lappend path_layers "$via_layer: [format %.3f $via_array_r]Ω (2x2)"
        }
    }
    
    # Add top metal routing resistance (assume 10um length, 5um width)
    if {[info exists metal_rs($top_layer)]} {
        set top_metal_r [expr {$metal_rs($top_layer) * 2.0}]  # 2 squares
        set total_r [expr {$total_r + $top_metal_r}]
        lappend path_layers "$top_layer: [format %.3f $top_metal_r]Ω"
    }
    
    # Store result
    lappend resistance_report [list $inst_name $pin_name $total_r $path_layers]
    
    # Check against ESD requirement (typically < 5 ohms)
    set status "PASS"
    if {$total_r > 5.0} {
        set status "FAIL"
        puts "WARNING: High resistance path for $inst_name/$pin_name: [format %.2f $total_r]Ω (> 5Ω)"
    }
    
    puts "INFO: Resistance $inst_name/$pin_name: [format %.2f $total_r]Ω [$status]"
    
    return $total_r
}

###############################################################################
# Procedure: check_via_drc
# Description: Check DRC violations for via stacks
###############################################################################
proc ::clamp_inserter::check_via_drc {inst_name pin_name} {
    variable drc_violations
    
    set violations {}
    
    set pin [get_pins -quiet -of_object [get_cells $inst_name] -filter "name==$pin_name"]
    
    if {[sizeof_collection $pin] == 0} {
        return $violations
    }
    
    # Get pin geometry
    set pin_bbox [get_attribute $pin bbox]
    set pin_x [expr {([lindex [lindex $pin_bbox 0] 0] + [lindex [lindex $pin_bbox 1] 0]) / 2.0}]
    set pin_y [expr {([lindex [lindex $pin_bbox 0] 1] + [lindex [lindex $pin_bbox 1] 1]) / 2.0}]
    set pin_width [expr {[lindex [lindex $pin_bbox 1] 0] - [lindex [lindex $pin_bbox 0] 0]}]
    set pin_height [expr {[lindex [lindex $pin_bbox 1] 1] - [lindex [lindex $pin_bbox 0] 1]}]
    
    # Check minimum pin size for via array
    set min_pin_size 0.5  ;# minimum 0.5um for 2x2 via array
    
    if {$pin_width < $min_pin_size || $pin_height < $min_pin_size} {
        set violation "Pin too small for via array: ${pin_width}x${pin_height} (min: ${min_pin_size}x${min_pin_size})"
        lappend violations $violation
        lappend drc_violations [list $inst_name $pin_name $violation]
        puts "DRC WARNING: $inst_name/$pin_name - $violation"
    }
    
    # Check for overlapping instances nearby
    set nearby_cells [get_cells -quiet -within [list \
        [expr {$pin_x - 5}] [expr {$pin_y - 5}] \
        [expr {$pin_x + 5}] [expr {$pin_y + 5}]]]
    
    set num_nearby [sizeof_collection $nearby_cells]
    if {$num_nearby > 10} {
        set violation "High cell density near via location (${num_nearby} cells within 5um)"
        lappend violations $violation
        puts "DRC WARNING: $inst_name/$pin_name - $violation"
    }
    
    # Check metal density (simplified check)
    # In production, you'd use actual DRC deck
    
    return $violations
}

###############################################################################
# Procedure: run_full_drc_check
# Description: Run comprehensive DRC checks on all inserted clamps
###############################################################################
proc ::clamp_inserter::run_full_drc_check {} {
    variable esd_clamps
    variable power_clamps
    variable drc_violations
    
    puts "\n=========================================="
    puts "INFO: Running DRC Checks"
    puts "=========================================="
    
    set total_violations 0
    
    # Check ESD clamps
    foreach clamp $esd_clamps {
        set viols_a [check_via_drc $clamp "A"]
        set viols_k [check_via_drc $clamp "K"]
        set total_violations [expr {$total_violations + [llength $viols_a] + [llength $viols_k]}]
    }
    
    # Check spacing between clamps
    if {[llength $esd_clamps] > 1} {
        for {set i 0} {$i < [llength $esd_clamps] - 1} {incr i} {
            set clamp1 [lindex $esd_clamps $i]
            set clamp2 [lindex $esd_clamps [expr {$i + 1}]]
            
            set cell1 [get_cells $clamp1]
            set cell2 [get_cells $clamp2]
            
            if {[sizeof_collection $cell1] > 0 && [sizeof_collection $cell2] > 0} {
                set bbox1 [get_attribute $cell1 bbox]
                set bbox2 [get_attribute $cell2 bbox]
                
                set x1 [lindex [lindex $bbox1 0] 0]
                set x2 [lindex [lindex $bbox2 0] 0]
                
                set spacing [expr {abs($x2 - $x1)}]
                
                # Check minimum spacing (e.g., 2um)
                if {$spacing < 2.0} {
                    set violation "Insufficient spacing between clamps: [format %.2f $spacing]um (min: 2.0um)"
                    lappend drc_violations [list "$clamp1-$clamp2" "SPACING" $violation]
                    puts "DRC WARNING: $violation"
                    incr total_violations
                }
            }
        }
    }
    
    puts "\nDRC Check Summary:"
    puts "Total violations: $total_violations"
    
    if {$total_violations == 0} {
        puts "STATUS: PASS - No DRC violations found"
    } else {
        puts "STATUS: FAIL - Review violations in report"
    }
    
    return $total_violations
}

###############################################################################
# Procedure: get_io_pads
# Description: Find all IO pad instances in the design
###############################################################################
proc ::clamp_inserter::get_io_pads {} {
    puts "INFO: Searching for IO pads..."
    
    # Get all instances matching IO pad patterns
    set io_pads {}
    
    # Try different IO pad naming patterns
    set patterns {*PAD* *IO* *IOPAD* *pad* *io*}
    
    foreach pattern $patterns {
        set found_cells [get_cells -quiet -hierarchical $pattern]
        if {[sizeof_collection $found_cells] > 0} {
            foreach_in_collection cell $found_cells {
                set cell_name [get_object_name $cell]
                set ref_name [get_attribute $cell ref_name]
                
                # Check if it's really an IO pad
                if {[regexp -nocase {pad|io} $ref_name]} {
                    lappend io_pads $cell_name
                }
            }
        }
    }
    
    set io_pads [lsort -unique $io_pads]
    puts "INFO: Found [llength $io_pads] IO pads"
    return $io_pads
}

###############################################################################
# Procedure: get_pad_location
# Description: Get the physical location of a pad
###############################################################################
proc ::clamp_inserter::get_pad_location {pad_name} {
    set pad_cell [get_cells $pad_name]
    
    if {[sizeof_collection $pad_cell] == 0} {
        puts "WARNING: Cannot find pad $pad_name"
        return {0 0}
    }
    
    set bbox [get_attribute $pad_cell bbox]
    set x_coord [lindex [lindex $bbox 0] 0]
    set y_coord [lindex [lindex $bbox 0] 1]
    
    return [list $x_coord $y_coord]
}

###############################################################################
# Procedure: create_power_taps
# Description: Create via stacks to connect ESD cells to top metal power grid
###############################################################################
proc ::clamp_inserter::create_power_taps {inst_name pin_name net_name top_layer} {
    
    set pin [get_pins -of_object [get_cells $inst_name] -filter "name==$pin_name"]
    
    if {[sizeof_collection $pin] == 0} {
        puts "WARNING: Pin $pin_name not found on $inst_name"
        return 0
    }
    
    # Get pin location and layer
    set pin_layer [get_attribute $pin layer]
    set pin_bbox [get_attribute $pin bbox]
    set pin_x [expr {([lindex [lindex $pin_bbox 0] 0] + [lindex [lindex $pin_bbox 1] 0]) / 2.0}]
    set pin_y [expr {([lindex [lindex $pin_bbox 0] 1] + [lindex [lindex $pin_bbox 1] 1]) / 2.0}]
    
    puts "INFO: Creating via stack from $pin_layer to $top_layer for $inst_name/$pin_name"
    
    # Create via stack from pin layer to top metal
    if {[catch {
        # Method 1: Using create_via_array (for Innovus)
        create_via_array -from_layer $pin_layer \
                        -to_layer $top_layer \
                        -location [list $pin_x $pin_y] \
                        -net $net_name \
                        -via_array_size {2 2}
        
        puts "INFO: Created 2x2 via array to $top_layer"
        return 1
        
    } err1]} {
        # Method 2: Using add_pg_via (for ICC2)
        if {[catch {
            add_route -layer $top_layer \
                     -net $net_name \
                     -coordinates [list [list [expr {$pin_x - 1}] [expr {$pin_y - 1}]] \
                                        [list [expr {$pin_x + 1}] [expr {$pin_y + 1}]]]
            
            create_pg_via -from_layer $pin_layer \
                         -to_layer $top_layer \
                         -net $net_name \
                         -x $pin_x \
                         -y $pin_y
            
            puts "INFO: Created PG via to $top_layer"
            return 1
            
        } err2]} {
            puts "WARNING: Could not create via stack: $err1 | $err2"
            puts "WARNING: Manual routing may be required for $inst_name/$pin_name"
            return 0
        }
    }
}

###############################################################################
# Procedure: insert_esd_clamps
# Description: Insert ESD protection clamps near IO pads with power taps
###############################################################################
proc ::clamp_inserter::insert_esd_clamps {args} {
    variable esd_clamps
    
    # Parse arguments
    set esd_cell "ESD_DIODE"
    set spacing 5.0
    set power_net "VDD"
    set ground_net "VSS"
    set top_metal "M8"
    set create_via_stacks 1
    
    parse_proc_arguments -args $args options
    
    if {[info exists options(-esd_cell)]} {
        set esd_cell $options(-esd_cell)
    }
    if {[info exists options(-spacing)]} {
        set spacing $options(-spacing)
    }
    if {[info exists options(-power_net)]} {
        set power_net $options(-power_net)
    }
    if {[info exists options(-ground_net)]} {
        set ground_net $options(-ground_net)
    }
    if {[info exists options(-top_metal)]} {
        set top_metal $options(-top_metal)
    }
    if {[info exists options(-create_via_stacks)]} {
        set create_via_stacks $options(-create_via_stacks)
    }
    
    puts "\n=========================================="
    puts "INFO: Inserting ESD Clamps"
    puts "=========================================="
    puts "ESD Cell: $esd_cell"
    puts "Spacing: $spacing um"
    puts "Top Metal Layer: $top_metal"
    puts "Via Stack Creation: $create_via_stacks"
    
    # Get IO pads
    set io_pads [get_io_pads]
    
    if {[llength $io_pads] == 0} {
        puts "ERROR: No IO pads found!"
        return 0
    }
    
    set esd_clamps {}
    set clamp_count 0
    
    foreach pad $io_pads {
        # Get pad location
        set location [get_pad_location $pad]
        set x [lindex $location 0]
        set y [lindex $location 1]
        
        # Calculate ESD clamp position (offset from pad)
        set esd_x [expr {$x + $spacing}]
        set esd_y $y
        
        # Create unique instance name
        set esd_inst_name "ESD_CLAMP_${pad}_${clamp_count}"
        
        # Create ESD clamp instance
        if {[catch {
            create_inst -cell $esd_cell -inst $esd_inst_name \
                        -location [list $esd_x $esd_y] \
                        -status placed
            
            # Connect to power nets (basic connection)
            connect_net -inst $esd_inst_name -pin A -net $power_net
            connect_net -inst $esd_inst_name -pin K -net $ground_net
            
            # Create via stacks to top metal for low-resistance ESD path
            if {$create_via_stacks} {
                puts "INFO: Creating via stacks for $esd_inst_name to $top_metal"
                create_power_taps $esd_inst_name "A" $power_net $top_metal
                create_power_taps $esd_inst_name "K" $ground_net $top_metal
                
                # Calculate resistance of discharge path
                set r_vdd [calculate_resistance $esd_inst_name "A" $top_metal]
                set r_vss [calculate_resistance $esd_inst_name "K" $top_metal]
                
                # Check DRC
                check_via_drc $esd_inst_name "A"
                check_via_drc $esd_inst_name "K"
            }
            
            # Connect to IO pad signal
            set pad_net [get_nets -of [get_pins -of $pad -filter "direction==inout || direction==input || direction==output"]]
            if {[sizeof_collection $pad_net] > 0} {
                set net_name [get_object_name $pad_net]
                connect_net -inst $esd_inst_name -pin IO -net $net_name
            }
            
            lappend esd_clamps $esd_inst_name
            incr clamp_count
            
            puts "INFO: Created $esd_inst_name at ($esd_x, $esd_y) for pad $pad"
            
        } err]} {
            puts "WARNING: Failed to create ESD clamp for $pad: $err"
        }
    }
    
    puts "INFO: Successfully inserted $clamp_count ESD clamps with via stacks"
    return $clamp_count
}

###############################################################################
# Procedure: insert_power_pad_clamps
# Description: Insert VDD-VSS clamps near power pads with optimized decaps
###############################################################################
proc ::clamp_inserter::insert_power_pad_clamps {args} {
    variable power_clamps
    
    # Parse arguments
    set rail_clamp_cell "RAIL_CLAMP"
    set large_decap_cell "DECAP_10NF"
    set spacing 10.0
    set power_net "VDD"
    set ground_net "VSS"
    set add_decaps 1
    
    parse_proc_arguments -args $args options
    
    if {[info exists options(-rail_clamp_cell)]} {
        set rail_clamp_cell $options(-rail_clamp_cell)
    }
    if {[info exists options(-large_decap_cell)]} {
        set large_decap_cell $options(-large_decap_cell)
    }
    if {[info exists options(-spacing)]} {
        set spacing $options(-spacing)
    }
    if {[info exists options(-power_net)]} {
        set power_net $options(-power_net)
    }
    if {[info exists options(-ground_net)]} {
        set ground_net $options(-ground_net)
    }
    if {[info exists options(-add_decaps)]} {
        set add_decaps $options(-add_decaps)
    }
    
    puts "\n=========================================="
    puts "INFO: Inserting Power Pad Clamps (VDD-VSS)"
    puts "=========================================="
    puts "Rail Clamp Cell: $rail_clamp_cell"
    puts "Large Decap Cell: $large_decap_cell"
    puts "Add Decaps: $add_decaps"
    
    # Find power pads
    set power_pads {}
    set patterns {*VDD* *VDDPST* *VDDIO* *PWR*}
    
    foreach pattern $patterns {
        set found_cells [get_cells -quiet -hierarchical $pattern]
        if {[sizeof_collection $found_cells] > 0} {
            foreach_in_collection cell $found_cells {
                set cell_name [get_object_name $cell]
                set ref_name [get_attribute $cell ref_name]
                
                if {[regexp -nocase {pad|pwr|power} $ref_name]} {
                    lappend power_pads $cell_name
                }
            }
        }
    }
    
    set power_pads [lsort -unique $power_pads]
    puts "INFO: Found [llength $power_pads] power pads"
    
    set clamp_count 0
    set decap_count 0
    
    foreach pad $power_pads {
        set location [get_pad_location $pad]
        set x [lindex $location 0]
        set y [lindex $location 1]
        
        # Place rail clamp adjacent to power pad
        set clamp_x [expr {$x + $spacing}]
        set clamp_y $y
        
        set inst_name "RAIL_CLAMP_${pad}_${clamp_count}"
        
        if {[catch {
            create_inst -cell $rail_clamp_cell -inst $inst_name \
                       -location [list $clamp_x $clamp_y] -status placed
            
            # Connect VDD-VSS clamp
            connect_net -inst $inst_name -pin AVDD -net $power_net
            connect_net -inst $inst_name -pin AVSS -net $ground_net
            
            lappend power_clamps $inst_name
            incr clamp_count
            
            puts "INFO: Created rail clamp $inst_name at ($clamp_x, $clamp_y) for $pad"
            
            # Add large bulk decap near power pad
            if {$add_decaps} {
                set decap_x [expr {$x + $spacing * 2}]
                set decap_y $y
                set decap_name "DECAP_BULK_${pad}_${decap_count}"
                
                if {[catch {
                    create_inst -cell $large_decap_cell -inst $decap_name \
                               -location [list $decap_x $decap_y] -status placed
                    connect_net -inst $decap_name -pin VDD -net $power_net
                    connect_net -inst $decap_name -pin VSS -net $ground_net
                    
                    lappend power_clamps $decap_name
                    incr decap_count
                    
                    puts "INFO: Created bulk decap $decap_name at power pad"
                } err]} {
                    puts "WARNING: Failed to create bulk decap: $err"
                }
            }
            
        } err]} {
            puts "WARNING: Failed to create rail clamp for $pad: $err"
        }
    }
    
    puts "INFO: Successfully inserted $clamp_count power pad rail clamps"
    puts "INFO: Successfully inserted $decap_count bulk decaps at power pads"
    return $clamp_count
}

###############################################################################
# Procedure: insert_power_clamps
# Description: Insert power clamps (decaps) along power rails with smart distribution
###############################################################################
proc ::clamp_inserter::insert_power_clamps {args} {
    variable power_clamps
    
    # Parse arguments
    set pwr_clamp_cell "DECAP"
    set medium_decap_cell "DECAP_1NF"
    set small_decap_cell "DECAP_100PF"
    set spacing 50.0
    set power_net "VDD"
    set ground_net "VSS"
    set rail_type "horizontal"
    set smart_distribution 1
    
    parse_proc_arguments -args $args options
    
    if {[info exists options(-pwr_clamp_cell)]} {
        set pwr_clamp_cell $options(-pwr_clamp_cell)
    }
    if {[info exists options(-medium_decap_cell)]} {
        set medium_decap_cell $options(-medium_decap_cell)
    }
    if {[info exists options(-small_decap_cell)]} {
        set small_decap_cell $options(-small_decap_cell)
    }
    if {[info exists options(-spacing)]} {
        set spacing $options(-spacing)
    }
    if {[info exists options(-power_net)]} {
        set power_net $options(-power_net)
    }
    if {[info exists options(-ground_net)]} {
        set ground_net $options(-ground_net)
    }
    if {[info exists options(-rail_type)]} {
        set rail_type $options(-rail_type)
    }
    if {[info exists options(-smart_distribution)]} {
        set smart_distribution $options(-smart_distribution)
    }
    
    puts "\n=========================================="
    puts "INFO: Inserting Power Clamps (Decaps)"
    puts "=========================================="
    puts "Power Clamp Cell: $pwr_clamp_cell"
    puts "Spacing: $spacing um"
    puts "Smart Distribution: $smart_distribution"
    
    # Get die area
    set die_area [get_attribute [get_designs] boundary]
    set x_min [lindex [lindex $die_area 0] 0]
    set y_min [lindex [lindex $die_area 0] 1]
    set x_max [lindex [lindex $die_area 1] 0]
    set y_max [lindex [lindex $die_area 1] 1]
    
    puts "INFO: Die area: ($x_min, $y_min) to ($x_max, $y_max)"
    
    set power_clamps {}
    set clamp_count 0
    
    if {$rail_type == "horizontal"} {
        # Place clamps along horizontal rails (top and bottom)
        set num_clamps [expr {int(($x_max - $x_min) / $spacing)}]
        
        # Smart distribution: alternate between medium and small decaps
        # Bottom rail
        for {set i 0} {$i < $num_clamps} {incr i} {
            set x [expr {$x_min + ($i * $spacing)}]
            set y $y_min
            
            # Alternate decap sizes for better frequency coverage
            if {$smart_distribution} {
                # Every 3rd position gets medium cap, others get small
                if {$i % 3 == 0} {
                    set cell $medium_decap_cell
                    set type "MED"
                } else {
                    set cell $small_decap_cell
                    set type "SML"
                }
            } else {
                set cell $pwr_clamp_cell
                set type "STD"
            }
            
            set inst_name "PWR_CLAMP_BOT_${type}_${i}"
            
            if {[catch {
                create_inst -cell $cell -inst $inst_name \
                           -location [list $x $y] -status placed
                connect_net -inst $inst_name -pin VDD -net $power_net
                connect_net -inst $inst_name -pin VSS -net $ground_net
                
                lappend power_clamps $inst_name
                incr clamp_count
            } err]} {
                puts "WARNING: Failed to create power clamp at ($x, $y): $err"
            }
        }
        
        # Top rail - similar strategy
        for {set i 0} {$i < $num_clamps} {incr i} {
            set x [expr {$x_min + ($i * $spacing)}]
            set y $y_max
            
            if {$smart_distribution} {
                if {$i % 3 == 0} {
                    set cell $medium_decap_cell
                    set type "MED"
                } else {
                    set cell $small_decap_cell
                    set type "SML"
                }
            } else {
                set cell $pwr_clamp_cell
                set type "STD"
            }
            
            set inst_name "PWR_CLAMP_TOP_${type}_${i}"
            
            if {[catch {
                create_inst -cell $cell -inst $inst_name \
                           -location [list $x $y] -status placed
                connect_net -inst $inst_name -pin VDD -net $power_net
                connect_net -inst $inst_name -pin VSS -net $ground_net
                
                lappend power_clamps $inst_name
                incr clamp_count
            } err]} {
                puts "WARNING: Failed to create power clamp at ($x, $y): $err"
            }
        }
    } else {
        # Vertical rails (left and right)
        set num_clamps [expr {int(($y_max - $y_min) / $spacing)}]
        
        for {set i 0} {$i < $num_clamps} {incr i} {
            set y [expr {$y_min + ($i * $spacing)}]
            
            if {$smart_distribution} {
                if {$i % 3 == 0} {
                    set cell $medium_decap_cell
                    set type "MED"
                } else {
                    set cell $small_decap_cell
                    set type "SML"
                }
            } else {
                set cell $pwr_clamp_cell
                set type "STD"
            }
            
            # Left rail
            set inst_name "PWR_CLAMP_LEFT_${type}_${i}"
            if {[catch {
                create_inst -cell $cell -inst $inst_name \
                           -location [list $x_min $y] -status placed
                connect_net -inst $inst_name -pin VDD -net $power_net
                connect_net -inst $inst_name -pin VSS -net $ground_net
                lappend power_clamps $inst_name
                incr clamp_count
            } err]} {}
            
            # Right rail
            set inst_name "PWR_CLAMP_RIGHT_${type}_${i}"
            if {[catch {
                create_inst -cell $cell -inst $inst_name \
                           -location [list $x_max $y] -status placed
                connect_net -inst $inst_name -pin VDD -net $power_net
                connect_net -inst $inst_name -pin VSS -net $ground_net
                lappend power_clamps $inst_name
                incr clamp_count
            } err]} {}
        }
    }
    
    puts "INFO: Successfully inserted $clamp_count distributed power clamps"
    return $clamp_count
}

###############################################################################
# Procedure: generate_report
# Description: Generate comprehensive clamp insertion report with resistance and DRC
###############################################################################
proc ::clamp_inserter::generate_report {} {
    variable esd_clamps
    variable power_clamps
    variable report_file
    variable resistance_report
    variable drc_violations
    
    set fp [open $report_file w]
    
    puts $fp "=============================================="
    puts $fp "  ESD and Power Clamp Insertion Report"
    puts $fp "=============================================="
    puts $fp "Date: [clock format [clock seconds]]"
    puts $fp ""
    
    puts $fp "SUMMARY"
    puts $fp "-------"
    puts $fp "ESD Clamps Inserted: [llength $esd_clamps]"
    puts $fp "Power Clamps Inserted: [llength $power_clamps]"
    puts $fp "Total Resistance Calculations: [llength $resistance_report]"
    puts $fp "Total DRC Violations: [llength $drc_violations]"
    puts $fp ""
    
    # ESD Clamps section
    puts $fp "ESD CLAMP INSTANCES"
    puts $fp "-------------------"
    foreach clamp $esd_clamps {
        puts $fp "  $clamp"
    }
    puts $fp ""
    
    # Power Clamps section
    puts $fp "POWER CLAMP INSTANCES"
    puts $fp "---------------------"
    foreach clamp $power_clamps {
        puts $fp "  $clamp"
    }
    puts $fp ""
    
    # Resistance Analysis section
    puts $fp "RESISTANCE ANALYSIS"
    puts $fp "-------------------"
    puts $fp "Target: < 5.0 Ohms for ESD protection"
    puts $fp ""
    
    set pass_count 0
    set fail_count 0
    
    foreach entry $resistance_report {
        set inst [lindex $entry 0]
        set pin [lindex $entry 1]
        set total_r [lindex $entry 2]
        set path [lindex $entry 3]
        
        set status "PASS"
        if {$total_r > 5.0} {
            set status "FAIL"
            incr fail_count
        } else {
            incr pass_count
        }
        
        puts $fp "Instance: $inst, Pin: $pin"
        puts $fp "  Total Resistance: [format %.3f $total_r] Ohms \[$status\]"
        puts $fp "  Path breakdown:"
        foreach layer_r $path {
            puts $fp "    $layer_r"
        }
        puts $fp ""
    }
    
    puts $fp "Resistance Summary: $pass_count PASS, $fail_count FAIL"
    puts $fp ""
    
    # DRC Violations section
    puts $fp "DRC VIOLATIONS"
    puts $fp "--------------"
    
    if {[llength $drc_violations] == 0} {
        puts $fp "No DRC violations found - PASS"
    } else {
        puts $fp "Total violations: [llength $drc_violations]"
        puts $fp ""
        foreach viol $drc_violations {
            set inst [lindex $viol 0]
            set pin [lindex $viol 1]
            set desc [lindex $viol 2]
            puts $fp "  \[$inst/$pin\] $desc"
        }
    }
    puts $fp ""
    
    # Recommendations section
    puts $fp "RECOMMENDATIONS"
    puts $fp "---------------"
    
    if {$fail_count > 0} {
        puts $fp "- $fail_count path(s) exceed 5 Ohm resistance target"
        puts $fp "  * Increase via count (use 3x3 or 4x4 arrays)"
        puts $fp "  * Widen top metal straps (>5um recommended)"
        puts $fp "  * Reduce distance to power grid"
    }
    
    if {[llength $drc_violations] > 0} {
        puts $fp "- DRC violations detected:"
        puts $fp "  * Review via array placement"
        puts $fp "  * Check metal density rules"
        puts $fp "  * Verify minimum spacing requirements"
    }
    
    if {$fail_count == 0 && [llength $drc_violations] == 0} {
        puts $fp "- All checks passed successfully"
        puts $fp "- ESD protection network meets design targets"
    }
    
    puts $fp ""
    puts $fp "=============================================="
    
    close $fp
    puts "\nINFO: Detailed report written to $report_file"
}

###############################################################################
# Main Procedure
###############################################################################
proc insert_all_clamps {args} {
    # Default values
    set esd_cell "ESD_DIODE"
    set pwr_clamp_cell "DECAP"
    set medium_decap_cell "DECAP_1NF"
    set small_decap_cell "DECAP_100PF"
    set large_decap_cell "DECAP_10NF"
    set rail_clamp_cell "RAIL_CLAMP"
    set esd_spacing 5.0
    set pwr_spacing 50.0
    set rail_spacing 10.0
    set power_net "VDD"
    set ground_net "VSS"
    set add_rail_clamps 1
    set top_metal "M8"
    set create_via_stacks 1
    set run_pdn_analysis 1
    set switching_current 100
    set target_impedance 0.5
    
    # Parse command line arguments
    foreach {key value} $args {
        switch -exact -- $key {
            -esd_cell           { set esd_cell $value }
            -pwr_clamp_cell     { set pwr_clamp_cell $value }
            -medium_decap_cell  { set medium_decap_cell $value }
            -small_decap_cell   { set small_decap_cell $value }
            -large_decap_cell   { set large_decap_cell $value }
            -rail_clamp_cell    { set rail_clamp_cell $value }
            -esd_spacing        { set esd_spacing $value }
            -pwr_spacing        { set pwr_spacing $value }
            -rail_spacing       { set rail_spacing $value }
            -power_net          { set power_net $value }
            -ground_net         { set ground_net $value }
            -add_rail_clamps    { set add_rail_clamps $value }
            -top_metal          { set top_metal $value }
            -create_via_stacks  { set create_via_stacks $value }
            -run_pdn_analysis   { set run_pdn_analysis $value }
            -switching_current  { set switching_current $value }
            -target_impedance   { set target_impedance $value }
            default {
                puts "WARNING: Unknown option $key"
            }
        }
    }
    
    puts "\n=============================================="
    puts "  Starting Clamp Insertion with PDN Analysis"
    puts "=============================================="
    
    # Run PDN analysis first
    if {$run_pdn_analysis} {
        set decap_results [::clamp_inserter::calculate_decap_requirements \
                              -switching_current $switching_current \
                              -target_impedance $target_impedance]
        
        ::clamp_inserter::analyze_pdn_impedance
        
        # Check anti-resonance between decap types
        puts "\n--- Anti-Resonance Check ---"
        ::clamp_inserter::check_anti_resonance 10.0 500 1.0 200
        ::clamp_inserter::check_anti_resonance 1.0 200 0.1 100
    }
    
    # Insert ESD clamps for signal pads with via stacks
    set esd_count [::clamp_inserter::insert_esd_clamps \
                       -esd_cell $esd_cell \
                       -spacing $esd_spacing \
                       -power_net $power_net \
                       -ground_net $ground_net \
                       -top_metal $top_metal \
                       -create_via_stacks $create_via_stacks]
    
    # Insert VDD-VSS rail clamps and bulk decaps for power pads
    set rail_count 0
    if {$add_rail_clamps} {
        set rail_count [::clamp_inserter::insert_power_pad_clamps \
                           -rail_clamp_cell $rail_clamp_cell \
                           -large_decap_cell $large_decap_cell \
                           -spacing $rail_spacing \
                           -power_net $power_net \
                           -ground_net $ground_net \
                           -add_decaps 1]
    }
    
    # Insert distributed decap power clamps along rails
    set pwr_count [::clamp_inserter::insert_power_clamps \
                       -pwr_clamp_cell $pwr_clamp_cell \
                       -medium_decap_cell $medium_decap_cell \
                       -small_decap_cell $small_decap_cell \
                       -spacing $pwr_spacing \
                       -power_net $power_net \
                       -ground_net $ground_net \
                       -smart_distribution 1]
    
    # Generate report
    ::clamp_inserter::generate_report
    
    # Run DRC check
    puts "\n"
    set drc_count [::clamp_inserter::run_full_drc_check]
    
    puts "\n=============================================="
    puts "  Clamp Insertion Complete"
    puts "=============================================="
    puts "Total ESD clamps (signal): $esd_count"
    puts "Total Rail clamps (power): $rail_count"
    puts "Total Decap clamps: $pwr_count"
    puts "Via stacks to $top_metal: [expr {$create_via_stacks ? "CREATED" : "SKIPPED"}]"
    puts "DRC violations: $drc_count"
    puts "PDN Analysis: [expr {$run_pdn_analysis ? "COMPLETE" : "SKIPPED"}]"
    puts "=============================================="
    puts ""
    puts "Review detailed report: [set ::clamp_inserter::report_file]"
}

# Example usage:
# Complete insertion with PDN analysis
# insert_all_clamps \
#     -esd_cell "ESD_DIODE_CELL" \
#     -large_decap_cell "DECAP_10NF" \
#     -medium_decap_cell "DECAP_1NF" \
#     -small_decap_cell "DECAP_100PF" \
#     -rail_clamp_cell "VDD_VSS_CLAMP" \
#     -esd_spacing 10.0 \
#     -pwr_spacing 50.0 \
#     -rail_spacing 15.0 \
#     -power_net "VDDCORE" \
#     -ground_net "VSS" \
#     -top_metal "M7" \
#     -create_via_stacks 1 \
#     -add_rail_clamps 1 \
#     -run_pdn_analysis 1 \
#     -switching_current 150 \
#     -target_impedance 0.3

# Run standalone PDN analysis
# ::clamp_inserter::calculate_decap_requirements \
#     -max_droop 0.05 \
#     -switching_current 100 \
#     -frequency 1000 \
#     -supply_voltage 1.0 \
#     -target_impedance 0.5

# Analyze PDN impedance
# ::clamp_inserter::analyze_pdn_impedance \
#     -pkg_l 1.0 \
#     -pkg_r 0.01 \
#     -pcb_l 0.5 \
#     -pcb_r 0.005
