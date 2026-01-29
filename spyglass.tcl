!/bin/bash
# ============================================================================
# SPYGLASS COMPREHENSIVE LINT CHECK SCRIPT
# ============================================================================
# This script runs comprehensive lint checks with all important violations enabled
# Usage: ./run_spyglass_lint.sh <top_module> <rtl_file_list>
# ============================================================================

# Set variables
TOP_MODULE=$1
RTL_FILES=$2
PROJECT_NAME="lint_analysis"
WORK_DIR="./spyglass_lint"
REPORT_DIR="${WORK_DIR}/reports"

# Check arguments
if [ -z "$TOP_MODULE" ] || [ -z "$RTL_FILES" ]; then
    echo "Usage: $0 <top_module> <rtl_file_list>"
    echo "Example: $0 my_top_module rtl_files.f"
    exit 1
fi

# Create directories
mkdir -p ${WORK_DIR}
mkdir -p ${REPORT_DIR}

# Generate Spyglass TCL script
cat > ${WORK_DIR}/spyglass_lint.tcl << 'EOF'
# ============================================================================
# SPYGLASS COMPREHENSIVE LINT TCL SCRIPT
# ============================================================================

# ----------------------------------------------------------------------------
# 1. PROJECT SETUP
# ----------------------------------------------------------------------------
new_project $::env(PROJECT_NAME) -projectwdir $::env(WORK_DIR) -force

# Load project-specific policy file if it exists
if {[file exists $::env(WORK_DIR)/../project_lint.sgdc]} {
    puts "Loading project policy file: project_lint.sgdc"
    source $::env(WORK_DIR)/../project_lint.sgdc
} else {
    puts "No project policy file found, using default settings"
    # Set options for SystemVerilog and mixed language support
    set_option enableSV yes
    set_option language_mode mixed
    set_option enable64bit yes
    set_option designread_enable_synthesis yes
    set_option designread_disable_flatten no
    
    # Set top module
    set_option top $::env(TOP_MODULE)
}

# ----------------------------------------------------------------------------
# 2. READ RTL FILES
# ----------------------------------------------------------------------------
puts "Reading RTL files from: $::env(RTL_FILES)"
read_file -type sourcelist $::env(RTL_FILES)

# ----------------------------------------------------------------------------
# 3. SET LINT METHODOLOGY
# ----------------------------------------------------------------------------
# Use comprehensive lint methodology
set_option methodology $::env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

# ----------------------------------------------------------------------------
# 4. ENABLE ALL CRITICAL LINT RULES
# ----------------------------------------------------------------------------

# === CODING STYLE VIOLATIONS ===
set_parameter report W123 yes    ;# Naming convention violations
set_parameter report W240 yes    ;# Missing default in case statement
set_parameter report W362 yes    ;# Dead/redundant code
set_parameter report W486 yes    ;# Case statement issues
set_parameter report W489 yes    ;# Case item overlap

# === SYNTHESIS ISSUES ===
set_parameter report W18 yes     ;# Combinational loops & latches (CRITICAL)
set_parameter report W240b yes   ;# Multiple drivers
set_parameter report W415 yes    ;# Incomplete sensitivity list
set_parameter report W415a yes   ;# Signal missing from sensitivity
set_parameter report W164 yes    ;# Width mismatch warnings
set_parameter report W164a yes   ;# Width mismatch in assignment
set_parameter report W163 yes    ;# Constant expression width mismatch
set_parameter report W116 yes    ;# Delay in assignment

# === FUNCTIONAL ISSUES ===
set_parameter report W213 yes    ;# Unused signals/variables
set_parameter report W287 yes    ;# Unconnected output ports
set_parameter report W528 yes    ;# Port connection width mismatch
set_parameter report W362 yes    ;# Dead assignment
set_parameter report W417 yes    ;# Mixed blocking/non-blocking assignments

# === FSM CHECKS ===
set_parameter report W226 yes    ;# FSM issues
set_parameter report W227 yes    ;# FSM unreachable states
set_parameter report W230 yes    ;# FSM coding style

# === CLOCK AND RESET ISSUES ===
set_parameter report W391 yes    ;# Async reset synchronization (CRITICAL)
set_parameter report W498 yes    ;# Missing reset for registers (CRITICAL)
set_parameter report W224 yes    ;# Mixed edge sensitivity
set_parameter report W225 yes    ;# Clock signal used as data
set_parameter report report W281 yes    ;# Gated clock without ICG
set_parameter report W455 yes    ;# Combinational logic in reset path
set_parameter report W456 yes    ;# Reset signal issues

# === SIMULATION/SYNTHESIS MISMATCH ===
set_parameter report W446 yes    ;# Blocking in sequential logic (CRITICAL)
set_parameter report W362 yes    ;# Dead code
set_parameter report W480 yes    ;# Race conditions
set_parameter report W484 yes    ;# Inferred priority
set_parameter report W362 yes    ;# Possible sim/synth mismatch

# === TIMING ISSUES ===
set_parameter report W430 yes    ;# Invalid path through combinational logic
set_parameter report W464 yes    ;# Timing path issues

# === X-PROPAGATION ===
set_parameter report W157 yes    ;# X-value propagation
set_parameter report W458 yes    ;# Possible X-propagation

# === MEMORY INFERENCE ===
set_parameter report W484 yes    ;# Memory inference issues
set_parameter report W485 yes    ;# Memory specification

# === INTERFACE ISSUES ===
set_parameter report W287 yes    ;# Output not driven
set_parameter report W528 yes    ;# Port width mismatch
set_parameter report W530 yes    ;# Port not connected

# === BEST PRACTICES ===
set_parameter report W336 yes    ;# Non-parameterized design
set_parameter report W213 yes    ;# Unused declarations
set_parameter report W241 yes    ;# Empty blocks

# ----------------------------------------------------------------------------
# 5. CONFIGURE LINT GOALS
# ----------------------------------------------------------------------------

# Design Read Goal
current_goal Design_Read -top $::env(TOP_MODULE)
set_goal_option enableSV yes
set_goal_option language_mode mixed
puts "Running Design_Read goal..."
run_goal

# Basic Lint Goal
current_goal lint/lint_rtl -top $::env(TOP_MODULE)
set_goal_option enableSV yes
set_goal_option report_all yes
set_goal_option enable_reset_checks yes
set_goal_option check_fsm yes
puts "Running lint/lint_rtl goal..."
run_goal

# Advanced Lint Checks
current_goal lint/lint_rtl_enhanced -top $::env(TOP_MODULE)
set_goal_option enableSV yes
set_goal_option enable_clock_checks yes
set_goal_option enable_gated_clock_checks yes
set_goal_option enable_reset_checks yes
puts "Running lint/lint_rtl_enhanced goal..."
run_goal

# Functional Lint
current_goal lint/lint_functional -top $::env(TOP_MODULE)
puts "Running lint/lint_functional goal..."
run_goal

# Synthesis Lint
current_goal lint/lint_synthesis -top $::env(TOP_MODULE)
puts "Running lint/lint_synthesis goal..."
run_goal

# ----------------------------------------------------------------------------
# 6. RDC (RESET DOMAIN CROSSING) CHECKS
# ----------------------------------------------------------------------------
current_goal rdc/rdc_setup -top $::env(TOP_MODULE)
set_goal_option enable_rdc yes
set_goal_option rdc_report_all yes
puts "Running RDC analysis..."
run_goal

current_goal rdc/rdc_verify -top $::env(TOP_MODULE)
puts "Running RDC verification..."
run_goal

# ----------------------------------------------------------------------------
# 7. GENERATE COMPREHENSIVE REPORTS
# ----------------------------------------------------------------------------

# Set report directory
set REPORT_DIR "$::env(REPORT_DIR)"

# Detailed report with all violations
puts "Generating detailed violation report..."
current_goal lint/lint_rtl -top $::env(TOP_MODULE)
write_report moresimple > ${REPORT_DIR}/lint_detailed.rpt

# Summary report
puts "Generating summary report..."
write_report summary > ${REPORT_DIR}/lint_summary.rpt

# Violation by severity
puts "Generating severity report..."
write_report violations > ${REPORT_DIR}/violations_by_severity.rpt

# Clock and Reset specific report
puts "Generating clock/reset report..."
current_goal lint/lint_rtl_enhanced -top $::env(TOP_MODULE)
write_report clock_reset > ${REPORT_DIR}/clock_reset_analysis.rpt

# RDC report
puts "Generating RDC report..."
current_goal rdc/rdc_verify -top $::env(TOP_MODULE)
write_report rdc > ${REPORT_DIR}/rdc_analysis.rpt

# Generate HTML report
puts "Generating HTML report..."
write_report html -out ${REPORT_DIR}/lint_report.html

# Generate waiver template
puts "Generating waiver template..."
write_report waiver -out ${REPORT_DIR}/waiver_template.swl

# CSV format for scripting
puts "Generating CSV report..."
write_report csv -out ${REPORT_DIR}/violations.csv

# Generate metrics
puts "Generating metrics report..."
write_report metrics > ${REPORT_DIR}/design_metrics.rpt

# ----------------------------------------------------------------------------
# 8. PRINT SUMMARY TO CONSOLE
# ----------------------------------------------------------------------------
puts "\n=========================================="
puts "SPYGLASS LINT CHECK COMPLETE"
puts "=========================================="
puts "Reports generated in: ${REPORT_DIR}"
puts "\nReport Files:"
puts "  - lint_detailed.rpt       : Detailed violations"
puts "  - lint_summary.rpt        : Summary of all checks"
puts "  - violations_by_severity.rpt : Violations by severity"
puts "  - clock_reset_analysis.rpt   : Clock and reset issues"
puts "  - rdc_analysis.rpt        : Reset domain crossing"
puts "  - lint_report.html        : HTML report (view in browser)"
puts "  - violations.csv          : CSV format for parsing"
puts "  - waiver_template.swl     : Template for waivers"
puts "  - design_metrics.rpt      : Design quality metrics"
puts "=========================================="

# Print violation summary
puts "\n===== VIOLATION SUMMARY ====="
current_goal lint/lint_rtl -top $::env(TOP_MODULE)
report_goal_summary

# Exit Spyglass
exit
EOF

# ============================================================================
# RUN SPYGLASS WITH GENERATED SCRIPT
# ============================================================================

echo "========================================"
echo "Starting Spyglass Comprehensive Lint"
echo "========================================"
echo "Top Module: ${TOP_MODULE}"
echo "RTL Files: ${RTL_FILES}"
echo "Work Directory: ${WORK_DIR}"
echo "Report Directory: ${REPORT_DIR}"
echo "========================================"

# Export environment variables for TCL script
export PROJECT_NAME
export TOP_MODULE
export RTL_FILES
export WORK_DIR
export REPORT_DIR

# Run Spyglass
spyglass -tcl ${WORK_DIR}/spyglass_lint.tcl -batch \
         -project ${PROJECT_NAME} \
         -log ${WORK_DIR}/spyglass_run.log

# Check if Spyglass ran successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Spyglass Lint Check Completed Successfully"
    echo "========================================"
    echo "View reports at: ${REPORT_DIR}"
    echo ""
    
    # Display summary if available
    if [ -f "${REPORT_DIR}/lint_summary.rpt" ]; then
        echo "===== QUICK SUMMARY ====="
        head -50 ${REPORT_DIR}/lint_summary.rpt
    fi
    
    # Check for critical violations
    echo ""
    echo "===== CRITICAL VIOLATIONS CHECK ====="
    echo "Searching for W18 (Latches/Loops):"
    grep -c "W18" ${REPORT_DIR}/lint_detailed.rpt || echo "  No W18 violations found"
    
    echo "Searching for W391 (Reset Sync):"
    grep -c "W391" ${REPORT_DIR}/lint_detailed.rpt || echo "  No W391 violations found"
    
    echo "Searching for W446 (Blocking in Sequential):"
    grep -c "W446" ${REPORT_DIR}/lint_detailed.rpt || echo "  No W446 violations found"
    
    echo "Searching for W498 (Missing Reset):"
    grep -c "W498" ${REPORT_DIR}/lint_detailed.rpt || echo "  No W498 violations found"
    
    echo ""
    echo "Open HTML report: file://${PWD}/${REPORT_DIR}/lint_report.html"
    
else
    echo ""
    echo "========================================"
    echo "ERROR: Spyglass Run Failed"
    echo "========================================"
    echo "Check log file: ${WORK_DIR}/spyglass_run.log"
    exit 1
fi

# ============================================================================
# OPTIONAL: Generate violation statistics
# ============================================================================

cat > ${REPORT_DIR}/violation_stats.sh << 'STATS_EOF'
#!/bin/bash
# Generate violation statistics

REPORT_FILE=$1

if [ ! -f "$REPORT_FILE" ]; then
    echo "Report file not found: $REPORT_FILE"
    exit 1
fi

echo "=========================================="
echo "VIOLATION STATISTICS"
echo "=========================================="

# Count violations by rule
echo ""
echo "Top 20 Violations by Rule:"
grep "^W[0-9]" $REPORT_FILE | awk '{print $1}' | sort | uniq -c | sort -rn | head -20

# Count by severity
echo ""
echo "Violations by Severity:"
grep -E "(Error|Warning|Info)" $REPORT_FILE | awk '{print $1}' | sort | uniq -c

# Count by module
echo ""
echo "Top 10 Modules with Most Violations:"
grep "Module:" $REPORT_FILE | awk '{print $2}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=========================================="
STATS_EOF

chmod +x ${REPORT_DIR}/violation_stats.sh

# Run statistics
if [ -f "${REPORT_DIR}/lint_detailed.rpt" ]; then
    ${REPORT_DIR}/violation_stats.sh ${REPORT_DIR}/lint_detailed.rpt
fi

echo ""
echo "Script completed at: $(date)"

/ ============================================================================
// SPYGLASS COMMAND TO CHECK RESET SYNCHRONIZATION
// ============================================================================
/*
To run these checks in Spyglass, use:

# In Tcl script:
current_goal lint/lint_rtl -top <module_name>
set_option enableSV yes
set_option enable_reset_checks yes

# Enable specific reset-related rules:
set_parameter report W391 yes    # Async reset issues
set_parameter report W498 yes    # Missing reset
set_parameter report W455 yes    # Reset glitch
set_parameter report W224 yes    # Mixed edge

# For comprehensive RDC analysis:
current_goal rdc/rdc_setup -top <module_name>
set_option enable_rdc yes
run_goal

# Generate report:
write_report moresimple > reset_sync_report.rpt
*/
