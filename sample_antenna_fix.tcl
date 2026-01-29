#####
# --- Identify and Fix Antenna Violations Script ---

# 1. Run the antenna check to identify violating nets
verifyProcessAntenna -report antenna.rpt

# 2. Define the antenna diode cell from your library
set diode_cell "ANTENNA_DIODE_MAG1"

# 3. Automatic Fix: Instruct the tool to insert diodes where needed
# This command automatically finds violating pins and attaches the specified diode
set_db route_design_antenna_diode_insertion true
set_db route_design_antenna_diode_cell $diode_cell
refine_high_density_routing -fix_antenna

# 4. Manual Fix for specific nets (Conceptual logic)
# Loop through a list of nets known to have violations
foreach net_name [list net_a net_b net_c] {
    # Place a physical diode instance near the violating input pin
    addInst -cell $diode_cell -inst "ANT_DIODE_${net_name}" -physical
    
    # Attach the diode to the net
    attachTerm "ANT_DIODE_${net_name}" "A" $net_name
}

# 5. Final Verification
verifyProcessAntenna -report post_fix_antenna.rpt

