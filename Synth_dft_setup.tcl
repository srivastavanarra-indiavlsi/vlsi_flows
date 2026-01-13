################################################################################
# DFT Setup Configuration
# File: scripts/dft_setup.tcl
################################################################################

################################################################################
# DFT ENABLE/DISABLE
################################################################################
set ENABLE_SCAN 1              ;# 1=enable scan insertion, 0=disable

################################################################################
# DFT SIGNAL DEFINITIONS
################################################################################
set DFT_CLK_PORT "clk"
set DFT_RST_PORT "rst_n"
set DFT_RST_ACTIVE_STATE 0     ;# 0=active low, 1=active high

# Scan signals (will be created during DFT)
set SCAN_DATA_IN_PORT "scan_in"
set SCAN_DATA_OUT_PORT "scan_out"
set SCAN_ENABLE_PORT "scan_en"
set SCAN_ENABLE_ACTIVE_STATE 1 ;# 1=active high, 0=active low

################################################################################
# SCAN CHAIN CONFIGURATION
################################################################################
set SCAN_CHAIN_COUNT 4         ;# Number of scan chains
set SCAN_MAX_LENGTH 500        ;# Maximum cells per chain
set SCAN_STYLE "multiplexed_flip_flop"  ;# Options: multiplexed_flip_flop, clocked_scan, lssd

################################################################################
# SCAN CLOCK CONFIGURATION
################################################################################
set SCAN_CLOCK_MIXING "mix_clocks"  ;# Options: no_mix, mix_clocks, mix_clock_edges
set SCAN_CLOCK_TIMING_START 45      ;# % duty cycle
set SCAN_CLOCK_TIMING_END 55        ;# % duty cycle

################################################################################
# COMPRESSION AND ADVANCED DFT
################################################################################
set ENABLE_COMPRESSION 0       ;# 1=enable test compression, 0=disable
set COMPRESSION_RATIO 10       ;# Compression ratio (if enabled)

set ENABLE_X_BOUNDING 1        ;# 1=enable X-bounding, 0=disable
set ENABLE_LOCKUP_LATCH 1      ;# 1=add lockup latches, 0=disable

################################################################################
# SCAN SEGMENT CONFIGURATION
################################################################################
set ENABLE_SCAN_SEGMENT 0      ;# 1=enable scan segmentation, 0=disable
set SEGMENT_LENGTH 100         ;# Cells per segment

################################################################################
# DFT OPTIMIZATION SETTINGS
################################################################################
set DFT_SYNTHESIS_OPTIMIZATION "full"  ;# Options: none, simple, full
set PRESERVE_DESIGN_NAME 1             ;# 1=preserve names, 0=allow renaming

################################################################################
# TEST MODE CONFIGURATION
################################################################################
set TEST_MODE_PORT "test_mode"
set TEST_MODE_ACTIVE_STATE 1

################################################################################
# PROCEDURE: SETUP DFT
################################################################################
proc setup_dft {} {
    global ENABLE_SCAN
    global DFT_CLK_PORT DFT_RST_PORT DFT_RST_ACTIVE_STATE
    global SCAN_DATA_IN_PORT SCAN_DATA_OUT_PORT SCAN_ENABLE_PORT
    global SCAN_ENABLE_ACTIVE_STATE
    global SCAN_CHAIN_COUNT SCAN_MAX_LENGTH SCAN_STYLE
    global SCAN_CLOCK_MIXING SCAN_CLOCK_TIMING_START SCAN_CLOCK_TIMING_END
    global ENABLE_COMPRESSION COMPRESSION_RATIO
    global ENABLE_X_BOUNDING ENABLE_LOCKUP_LATCH
    global ENABLE_SCAN_SEGMENT SEGMENT_LENGTH
    global DFT_SYNTHESIS_OPTIMIZATION PRESERVE_DESIGN_NAME
    global TEST_MODE_PORT TEST_MODE_ACTIVE_STATE
    
    if {$ENABLE_SCAN == 0} {
        puts "DFT is disabled - skipping DFT setup"
        return
    }
    
    puts "Setting up DFT configuration..."
    
    ############################################################################
    # 1. DEFINE EXISTING DFT SIGNALS
    ############################################################################
    # Define scan clock
    if {[sizeof_collection [get_ports $DFT_CLK_PORT -quiet]] > 0} {
        set_dft_signal -view existing_dft \
                       -type ScanClock \
                       -port $DFT_CLK_PORT \
                       -timing [list $SCAN_CLOCK_TIMING_START $SCAN_CLOCK_TIMING_END]
        puts "Scan clock defined: $DFT_CLK_PORT"
    }
    
    # Define reset signal
    if {[sizeof_collection [get_ports $DFT_RST_PORT -quiet]] > 0} {
        set_dft_signal -view existing_dft \
                       -type Reset \
                       -port $DFT_RST_PORT \
                       -active_state $DFT_RST_ACTIVE_STATE
        puts "Reset signal defined: $DFT_RST_PORT"
    }
    
    # Define test mode (if exists)
    if {[sizeof_collection [get_ports $TEST_MODE_PORT -quiet]] > 0} {
        set_dft_signal -view existing_dft \
                       -type TestMode \
                       -port $TEST_MODE_PORT \
                       -active_state $TEST_MODE_ACTIVE_STATE
        puts "Test mode defined: $TEST_MODE_PORT"
    }
    
    ############################################################################
    # 2. SPECIFY NEW SCAN PORTS
    ############################################################################
    # Scan data input
    set_dft_signal -view spec \
                   -type ScanDataIn \
                   -port $SCAN_DATA_IN_PORT
    
    # Scan data output
    set_dft_signal -view spec \
                   -type ScanDataOut \
                   -port $SCAN_DATA_OUT_PORT
    
    # Scan enable
    set_dft_signal -view spec \
                   -type ScanEnable \
                   -port $SCAN_ENABLE_PORT \
                   -active_state $SCAN_ENABLE_ACTIVE_STATE
    
    puts "Scan ports specified: $SCAN_DATA_IN_PORT, $SCAN_DATA_OUT_PORT, $SCAN_ENABLE_PORT"
    
    ############################################################################
    # 3. SCAN CONFIGURATION
    ############################################################################
    # Set number of scan chains
    set_scan_configuration -chain_count $SCAN_CHAIN_COUNT
    
    # Set maximum chain length
    set_scan_configuration -max_length $SCAN_MAX_LENGTH
    
    # Set scan style
    set_scan_configuration -style $SCAN_STYLE
    
    # Clock mixing strategy
    set_scan_configuration -clock_mixing $SCAN_CLOCK_MIXING
    
    # Lockup latch insertion
    if {$ENABLE_LOCKUP_LATCH} {
        set_scan_configuration -add_lockup true
    } else {
        set_scan_configuration -add_lockup false
    }
    
    puts "Scan configuration: $SCAN_CHAIN_COUNT chains, max length $SCAN_MAX_LENGTH"
    
    ############################################################################
    # 4. SCAN SEGMENT CONFIGURATION (Optional)
    ############################################################################
    if {$ENABLE_SCAN_SEGMENT} {
        set_scan_configuration -chain_type segment
        set_scan_configuration -segment_length $SEGMENT_LENGTH
        puts "Scan segmentation enabled: $SEGMENT_LENGTH cells per segment"
    }
    
    ############################################################################
    # 5. DFT INSERTION CONFIGURATION
    ############################################################################
    # Synthesis optimization level
    set_dft_insertion_configuration -synthesis_optimization $DFT_SYNTHESIS_OPTIMIZATION
    
    # Preserve design names
    set_dft_insertion_configuration -preserve_design_name $PRESERVE_DESIGN_NAME
    
    # Prefix for inserted cells
    set_dft_insertion_configuration -prefix SCAN
    
    ############################################################################
    # 6. X-BOUNDING (Unknown State Handling)
    ############################################################################
    if {$ENABLE_X_BOUNDING} {
        # Enable X-bounding for better fault coverage
        set_dft_configuration -fix_set enable
        set_dft_configuration -fix_reset enable
        puts "X-bounding enabled"
    }
    
    ############################################################################
    # 7. TEST COMPRESSION (Optional)
    ############################################################################
    if {$ENABLE_COMPRESSION} {
        set_scan_compression -enable
        set_scan_compression -minimum_compression $COMPRESSION_RATIO
        puts "Test compression enabled with ratio $COMPRESSION_RATIO"
    }
    
    ############################################################################
    # 8. SCAN CELL SPECIFICATION
    ############################################################################
    # Specify scan equivalent cells (library-specific)
    # set_scan_element <non_scan_cell> <scan_equivalent>
    # Example:
    # set_scan_element DFF SDFF
    # set_scan_element DFFR SDFFR
    
    ############################################################################
    # 9. NON-SCAN CELLS AND EXCLUSIONS
    ############################################################################
    # Specify cells that should NOT be converted to scan
    # set_dont_touch [get_cells async_fifo/*]
    # set_dont_touch [get_cells clock_domain_crossing/*]
    
    # Exclude specific flip-flops from scan
    # set_scan_element false [get_cells special_ff*]
    
    ############################################################################
    # 10. SCAN PATH ORDERING
    ############################################################################
    # Control scan chain ordering for better routing
    # set_scan_path <chain_id> [get_cells {ff1 ff2 ff3}]
    
    ############################################################################
    # 11. ADDITIONAL DFT CONSTRAINTS
    ############################################################################
    # Set scan state
    set_scan_state scan_existing_dft_mode
    
    # Autofix DFT violations
    set_autofix_configuration -enable true
    set_autofix_configuration -type { clock reset }
    
    ############################################################################
    # 12. CREATE TEST PROTOCOL
    ############################################################################
    # Automatically infer test protocol
    create_test_protocol -infer_clock -infer_asynch
    
    puts "DFT setup completed successfully"
    puts "Scan chains: $SCAN_CHAIN_COUNT"
    puts "Scan style: $SCAN_STYLE"
}

################################################################################
# PROCEDURE: REPORT DFT CONFIGURATION
################################################################################
proc report_dft_config {} {
    global ENABLE_SCAN SCAN_CHAIN_COUNT SCAN_STYLE
    global SCAN_DATA_IN_PORT SCAN_DATA_OUT_PORT SCAN_ENABLE_PORT
    
    puts "=========================================="
    puts "DFT Configuration Summary"
    puts "=========================================="
    puts "DFT Enabled: $ENABLE_SCAN"
    if {$ENABLE_SCAN} {
        puts "Scan Chains: $SCAN_CHAIN_COUNT"
        puts "Scan Style: $SCAN_STYLE"
        puts "Scan In: $SCAN_DATA_IN_PORT"
        puts "Scan Out: $SCAN_DATA_OUT_PORT"
        puts "Scan Enable: $SCAN_ENABLE_PORT"
    }
    puts "=========================================="
}

################################################################################
# DFT TEMPLATES (Commented Examples)
################################################################################

# MULTIPLE SCAN CLOCKS
# --------------------
# set_dft_signal -view existing_dft -type ScanClock -port clk_func -timing {45 55}
# set_dft_signal -view existing_dft -type ScanClock -port clk_test -timing {40 60}
# set_scan_configuration -clock_mixing mix_clocks

# SCAN COMPRESSION WITH EDT
# -------------------------
# set_scan_compression -enable
# set_scan_compression -minimum_compression 10
# set_scan_compression -locations <compressor_locations>

# BUILT-IN SELF-TEST (BIST)
# -------------------------
# set_bist_configuration -enable
# set_bist_pattern_type prpg  ;# Pseudo-random pattern generator

# BOUNDARY SCAN (JTAG)
# --------------------
# set_boundary_scan_configuration -enable
# set_dft_signal -view spec -type TCK -port jtag_tck
# set_dft_signal -view spec -type TDI -port jtag_tdi
# set_dft_signal -view spec -type TDO -port jtag_tdo
# set_dft_signal -view spec -type TMS -port jtag_tms

# Call the setup procedure when this file is sourced
if {$ENABLE_SCAN} {
    setup_dft
    report_dft_config
}

puts "DFT setup file loaded successfully"
