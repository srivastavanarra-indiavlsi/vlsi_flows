################################################################################
# QUANTUS RC EXTRACTION - COMPLETE SINGLE FILE
# All inputs, commands, and flow in one script
################################################################################

################################################################################
# INPUT CONFIGURATION SECTION
################################################################################

# Design Information
set DESIGN_NAME "chip_top"                                          ;# Name of your chip/block for output file naming
set TOP_CELL "chip_top"                                            ;# Top-level cell name in the layout hierarchy

# Technology Files
set TECH_FILE "/proj/tech/tsmc7nm/techfile.tf"                     ;# Technology file with layer definitions, units, design rules
set QRC_TECH "/proj/tech/tsmc7nm/qrcTechFile"                      ;# QRC tech file with R/C extraction rules, sheet resistance, dielectric constants
set ITF_FILE "/proj/tech/tsmc7nm/tsmc7.itf"                        ;# Interconnect Technology File with 3D process stack, metal thickness, spacing
set LAYER_MAP "/proj/tech/tsmc7nm/layers/streamout.map"            ;# Maps GDS layer numbers to technology layer names

# LEF Files
set LEF_FILES [list \
    "/proj/tech/tsmc7nm/lef/tech.lef" \                            ;# Technology LEF with routing layers, vias, site definitions
    "/proj/tech/tsmc7nm/lef/stdcells.lef" \                        ;# Standard cell LEF with pin locations, obstructions, macro definitions
    "/proj/tech/tsmc7nm/lef/io_cells.lef" \                        ;# I/O pad cell LEF with pad ring cell abstracts
    "/proj/tech/tsmc7nm/lef/memory.lef" \                          ;# Memory compiler LEF with SRAM/register file abstracts
]

# Input Format Selection
set INPUT_FORMAT "DEF"                                             ;# Which layout format to read: DEF (placed+routed), GDS (mask data), OAS (binary GDS)

# Layout Input Files (only the file matching INPUT_FORMAT will be used)
set DEF_FILE "/proj/designs/${DESIGN_NAME}/output/${DESIGN_NAME}.def"     ;# DEF file with component placement and routing data
set GDS_FILE "/proj/designs/${DESIGN_NAME}/output/${DESIGN_NAME}.gds"     ;# GDSII stream file with complete mask-level layout geometry
set OAS_FILE "/proj/designs/${DESIGN_NAME}/output/${DESIGN_NAME}.oas"     ;# OASIS file (compressed alternative to GDS)

# Netlist
set VERILOG_NETLIST "/proj/designs/${DESIGN_NAME}/netlist/${DESIGN_NAME}.v"  ;# Gate-level netlist for connectivity verification (optional)

# Output Directory
set OUTPUT_DIR "/proj/designs/${DESIGN_NAME}/extraction"           ;# Directory where all extraction outputs and reports will be written

# Output Format
set OUTPUT_FORMAT "BOTH"                                           ;# SPEF=standard parasitic format, DSPEF=detailed w/distributed RC, BOTH=generate both, SPICE=subcircuit format

# Extraction Control
set EXTRACT_COUPLING 1                                             ;# 1=extract coupling caps between nets, 0=only ground caps (faster but less accurate)
set COUPLING_THRESHOLD 0.05                                        ;# Minimum coupling capacitance in pF to extract (filters noise, improves runtime)
set RES_THRESHOLD 0.01                                             ;# Minimum resistance in ohms to extract (filters small resistances)
set EXTRACT_CC_GROUND 1                                            ;# 1=include coupling to ground nets, 0=skip ground coupling
set INCLUDE_LOCATION_INFO 1                                        ;# 1=add X,Y coordinates to SPEF nodes for debug/visualization, 0=omit for smaller files

# Process Corners (must have same number of entries in all three lists)
set CORNER_LIST [list "typical" "fast" "slow"]                     ;# Corner names for output file naming
set TEMP_LIST [list 25 125 -40]                                    ;# Operating temperatures in Celsius for each corner (affects R/C values)
set PROCESS_LIST [list "TT" "FF" "SS"]                             ;# Process corners: TT=typical, FF=fast-fast, SS=slow-slow (NMOS-PMOS)

# Parallel Processing
set NUM_THREADS 16                                                 ;# Number of CPU threads for parallel extraction (speeds up large designs)

################################################################################
# MAIN EXTRACTION FLOW
################################################################################

puts "################################################################################"
puts "# QUANTUS RC EXTRACTION STARTED"
puts "# Design: $DESIGN_NAME"
puts "# Date: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
puts "################################################################################"

# Create output directory
file mkdir $OUTPUT_DIR
cd $OUTPUT_DIR

################################################################################
# STEP 1: LOAD TECHNOLOGY
################################################################################

puts "\n==> STEP 1: Loading Technology Files..."

# Load QRC technology file
qrcSetExtractorMode -useTechFile $QRC_TECH

# Load ITF if available
if {[file exists $ITF_FILE]} {
    qrcSetExtractorMode -itf $ITF_FILE
    puts "    Loaded ITF: $ITF_FILE"
}

# Set layer mapping
if {[file exists $LAYER_MAP]} {
    qrcSetExtractorMode -layerMap $LAYER_MAP
    puts "    Loaded layer map: $LAYER_MAP"
}

puts "    Technology files loaded successfully"

################################################################################
# STEP 2: READ LEF FILES
################################################################################

puts "\n==> STEP 2: Reading LEF Files..."

foreach lef $LEF_FILES {
    if {[file exists $lef]} {
        qrcReadLef $lef
        puts "    Loaded: [file tail $lef]"
    } else {
        puts "    WARNING: LEF not found: $lef"
    }
}

################################################################################
# STEP 3: READ DESIGN LAYOUT
################################################################################

puts "\n==> STEP 3: Reading Design Layout ($INPUT_FORMAT format)..."

switch $INPUT_FORMAT {
    "DEF" {
        qrcReadDef $DEF_FILE
        puts "    Loaded DEF: [file tail $DEF_FILE]"
    }
    "GDS" {
        qrcReadGds -layerMap $LAYER_MAP $GDS_FILE
        puts "    Loaded GDS: [file tail $GDS_FILE]"
    }
    "OAS" {
        qrcReadOasis -layerMap $LAYER_MAP $OAS_FILE
        puts "    Loaded OAS: [file tail $OAS_FILE]"
    }
}

# Set top cell
qrcSetExtractorMode -topCell $TOP_CELL
puts "    Top cell set to: $TOP_CELL"

################################################################################
# STEP 4: CONFIGURE EXTRACTION PARAMETERS
################################################################################

puts "\n==> STEP 4: Configuring Extraction Parameters..."

# Basic extraction modes
qrcSetExtractorMode -coupled $EXTRACT_COUPLING
qrcSetExtractorMode -ccThreshold $COUPLING_THRESHOLD
qrcSetExtractorMode -resThreshold $RES_THRESHOLD
qrcSetExtractorMode -ccToGround $EXTRACT_CC_GROUND

# Resistance extraction
qrcSetExtractorMode -resMode detail
qrcSetExtractorMode -resistanceModel detailed

# Capacitance extraction
qrcSetExtractorMode -capMode detail
qrcSetExtractorMode -capacitanceModel detailed

# Coupling options
qrcSetExtractorMode -couplingCapMode detail
qrcSetExtractorMode -couplingReportThreshold $COUPLING_THRESHOLD

# Multi-threading
qrcSetExtractorMode -numThreads $NUM_THREADS

# Fracture settings
qrcSetExtractorMode -maxFractureLength 1000
qrcSetExtractorMode -fractureMode auto

# Reduction options
qrcSetExtractorMode -reductionMode none
qrcSetExtractorMode -groundNetName "VSS"
qrcSetExtractorMode -powerNetName "VDD"

puts "    Coupling capacitance: [expr {$EXTRACT_COUPLING ? "ENABLED" : "DISABLED"}]"
puts "    Coupling threshold: ${COUPLING_THRESHOLD} pF"
puts "    Resistance threshold: ${RES_THRESHOLD} ohm"
puts "    Number of threads: $NUM_THREADS"

################################################################################
# STEP 5: MULTI-CORNER EXTRACTION LOOP
################################################################################

puts "\n==> STEP 5: Starting Multi-Corner Extraction..."

set corner_count 0
foreach corner $CORNER_LIST temp $TEMP_LIST process $PROCESS_LIST {
    incr corner_count
    
    puts "\n    ----------------------------------------"
    puts "    Corner $corner_count: $corner ($process) @ ${temp}C"
    puts "    ----------------------------------------"
    
    # Set corner name
    qrcSetExtractorMode -corner $corner
    qrcSetExtractorMode -temperature $temp
    qrcSetExtractorMode -process $process
    
    # RUN EXTRACTION
    puts "    Running extraction..."
    qrcExtract
    
    # Generate output files based on format selection
    if {$OUTPUT_FORMAT == "SPEF" || $OUTPUT_FORMAT == "BOTH"} {
        
        # Configure SPEF output
        qrcSetOutputMode -spef
        qrcSetOutputMode -spefNetNameDelimiter "/"
        qrcSetOutputMode -spefPortNameMap physical
        
        if {$INCLUDE_LOCATION_INFO} {
            qrcSetOutputMode -includeCoordinates 1
            qrcSetOutputMode -coordinateFormat absolute
        }
        
        # Write SPEF
        set spef_file "${DESIGN_NAME}_${corner}.spef"
        qrcWriteSpef $spef_file
        puts "    Generated SPEF: $spef_file"
    }
    
    if {$OUTPUT_FORMAT == "DSPEF" || $OUTPUT_FORMAT == "BOTH"} {
        
        # Configure DSPEF output
        qrcSetOutputMode -dspef
        qrcSetOutputMode -dspefNetNameDelimiter "/"
        qrcSetOutputMode -dspefPortNameMap physical
        qrcSetOutputMode -distributedParasitics 1
        
        if {$INCLUDE_LOCATION_INFO} {
            qrcSetOutputMode -includeCoordinates 1
            qrcSetOutputMode -coordinateFormat absolute
            qrcSetOutputMode -includeNodeLocation 1
        }
        
        # Write DSPEF
        set dspef_file "${DESIGN_NAME}_${corner}.dspef"
        qrcWriteDspef $dspef_file
        puts "    Generated DSPEF: $dspef_file"
    }
    
    if {$OUTPUT_FORMAT == "SPICE"} {
        qrcSetOutputMode -spice
        set spice_file "${DESIGN_NAME}_${corner}_rc.sp"
        qrcWriteSpice $spice_file
        puts "    Generated SPICE: $spice_file"
    }
}

################################################################################
# STEP 6: GENERATE REPORTS
################################################################################

puts "\n==> STEP 6: Generating Reports..."

# Summary report
set summary_file "${DESIGN_NAME}_extraction_summary.rpt"
set fp [open $summary_file w]
puts $fp "QUANTUS RC EXTRACTION SUMMARY"
puts $fp "Design: $DESIGN_NAME"
puts $fp "Date: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
puts $fp "Corners extracted: $CORNER_LIST"
puts $fp "Temperatures: $TEMP_LIST"
close $fp

# Net statistics
qrcReport -summary > ${DESIGN_NAME}_net_summary.rpt

# Coupling report
if {$EXTRACT_COUPLING} {
    qrcReport -couplingCap > ${DESIGN_NAME}_coupling.rpt
}

# Resistance report
qrcReport -resistance > ${DESIGN_NAME}_resistance.rpt

# Capacitance report
qrcReport -capacitance > ${DESIGN_NAME}_capacitance.rpt

puts "    Reports generated in: $OUTPUT_DIR"

################################################################################
# STEP 7: CLEANUP AND SUMMARY
################################################################################

puts "\n==> STEP 7: Cleanup..."

qrcCleanup

puts "\n################################################################################"
puts "# EXTRACTION COMPLETED SUCCESSFULLY"
puts "# Output directory: $OUTPUT_DIR"
puts "# Corners processed: [llength $CORNER_LIST]"
puts "# Files generated:"

if {$OUTPUT_FORMAT == "SPEF" || $OUTPUT_FORMAT == "BOTH"} {
    foreach corner $CORNER_LIST {
        puts "#   - ${DESIGN_NAME}_${corner}.spef"
    }
}

if {$OUTPUT_FORMAT == "DSPEF" || $OUTPUT_FORMAT == "BOTH"} {
    foreach corner $CORNER_LIST {
        puts "#   - ${DESIGN_NAME}_${corner}.dspef"
    }
}

puts "# Reports:"
puts "#   - ${DESIGN_NAME}_extraction_summary.rpt"
puts "#   - ${DESIGN_NAME}_net_summary.rpt"
puts "#   - ${DESIGN_NAME}_coupling.rpt"
puts "#   - ${DESIGN_NAME}_resistance.rpt"
puts "#   - ${DESIGN_NAME}_capacitance.rpt"
puts "################################################################################"

exit 0
