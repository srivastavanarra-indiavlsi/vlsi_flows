####
# Spyglass Lint Check - Complete Usage Guide

## Quick Start (3 Steps)

### Step 1: Generate Project Policy File
```bash
chmod +x generate_policy.sh
./generate_policy.sh
```
This interactive script will create a customized `project_lint.sgdc` file for your project.

### Step 2: Create RTL File List
Create a file `rtl_files.f` with your RTL source files:
```
+incdir+../rtl/includes
+incdir+../rtl/defines

../rtl/top_module.sv
../rtl/sub_module1.v
../rtl/sub_module2.sv
../rtl/memory.v

-v ../libs/standard_cells.v
```

### Step 3: Run Lint Check
```bash
chmod +x run_spyglass_lint.sh
./run_spyglass_lint.sh my_top_module rtl_files.f
```

---

## File Structure

```
project/
├── run_spyglass_lint.sh      # Main execution script
├── generate_policy.sh         # Policy file generator
├── project_lint.sgdc          # Project-specific policy (generated)
├── rtl_files.f               # RTL file list
├── rtl/                      # Your RTL source files
│   ├── top_module.sv
│   └── sub_modules/
└── spyglass_lint/            # Output directory (created automatically)
    ├── reports/
    │   ├── lint_detailed.rpt
    │   ├── lint_summary.rpt
    │   ├── lint_report.html
    │   ├── violations.csv
    │   ├── clock_reset_analysis.rpt
    │   ├── rdc_analysis.rpt
    │   └── waiver_template.swl
    └── spyglass_run.log
```

---

## Understanding the Policy File (project_lint.sgdc)

### 1. Clock Definitions
```tcl
# Define your clocks
clock clk -period 10.0 -domain clk_domain
clock clk_slow -period 20.0 -domain clk_slow_domain

# Mark asynchronous clock relationships
set_clock_groups -asynchronous \
    -group {clk} \
    -group {clk_slow}
```

### 2. Reset Definitions
```tcl
# Async active-low reset
reset rst_n -async -active low -domain clk_domain

# Sync active-high reset
reset soft_reset -sync -active high -domain clk_domain
```

### 3. Rule Severity Levels
- **Error**: Violations that MUST be fixed (build fails)
- **Warning**: Should be reviewed and fixed
- **Info**: Informational, review if time permits

```tcl
set_parameter severity W18 Error     # Critical - will fail build
set_parameter severity W164a Warning # Important - should fix
set_parameter severity W213 Info     # Nice to fix
```

### 4. Adding Waivers
Use waivers for intentional violations with proper justification:

```tcl
# Waive intentional latch
waive -rule W18 -instance top/address_latch \
      -comment "Intentional latch for address holding per spec section 3.2"

# Waive by regex pattern
waive -rule W213 -regexp "debug_.*" \
      -comment "Debug signals reserved for future debug features"

# Waive specific file
waive -rule W336 -file legacy_module.v \
      -comment "Legacy code - will be refactored in next release"
```

### 5. Module Exclusions
```tcl
# Exclude third-party IP
set_option stop */vendor_ip/*

# Exclude test benches
set_option exclude_file ./tb/*.sv
```

---

## Critical Violations to Fix

### Priority 1 (Must Fix - Build Breakers)

#### W18 - Combinational Loops & Latches
```verilog
// BAD: Unintentional latch
always @(*) begin
    if (sel)
        out = data;
    // Missing else - creates latch!
end

// GOOD: Complete assignments
always @(*) begin
    if (sel)
        out = data;
    else
        out = 8'h00;
end
```

#### W391 - Reset Synchronization
```verilog
// BAD: Async reset crossing domains
always @(posedge clk_b or negedge rst_a)  // rst_a from domain A!

// GOOD: Synchronized reset
reg rst_sync1, rst_sync2;
always @(posedge clk_b or negedge rst_a) begin
    rst_sync1 <= rst_a;
    rst_sync2 <= rst_sync1;
end
```

#### W446 - Blocking in Sequential
```verilog
// BAD: Blocking assignment in clocked block
always @(posedge clk)
    data = input_data;  // Should use <=

// GOOD: Non-blocking for sequential
always @(posedge clk)
    data <= input_data;
```

#### W498 - Missing Reset
```verilog
// BAD: No reset
always @(posedge clk)
    if (enable)
        counter <= counter + 1;

// GOOD: With reset
always @(posedge clk or negedge rst_n)
    if (!rst_n)
        counter <= 0;
    else if (enable)
        counter <= counter + 1;
```

### Priority 2 (Should Fix)

#### W164a - Width Mismatch
```verilog
// BAD: Truncation
wire [3:0] narrow;
wire [7:0] wide = 8'hAB;
assign narrow = wide;  // Loses upper bits!

// GOOD: Explicit truncation
assign narrow = wide[3:0];  // Intentional
```

#### W240 - Missing Case Default
```verilog
// BAD: Incomplete case
case(sel)
    2'b00: out = a;
    2'b01: out = b;
    // Missing 2'b10, 2'b11
endcase

// GOOD: With default
case(sel)
    2'b00: out = a;
    2'b01: out = b;
    default: out = 0;
endcase
```

---

## Viewing Reports

### 1. HTML Report (Recommended)
```bash
firefox spyglass_lint/reports/lint_report.html
# or
google-chrome spyglass_lint/reports/lint_report.html
```
Interactive report with:
- Clickable violations
- Grouped by module/severity
- Hyperlinks to source code
- Violation details and suggestions

### 2. Text Reports
```bash
# Detailed violations with line numbers
less spyglass_lint/reports/lint_detailed.rpt

# Summary only
cat spyglass_lint/reports/lint_summary.rpt

# Clock and reset specific
less spyglass_lint/reports/clock_reset_analysis.rpt

# Reset domain crossing
less spyglass_lint/reports/rdc_analysis.rpt
```

### 3. CSV for Scripting
```bash
# Parse violations programmatically
cat spyglass_lint/reports/violations.csv | \
    awk -F',' '{print $1, $3}' | \
    sort | uniq -c
```

### 4. Violation Statistics
```bash
# Quick summary of most common violations
spyglass_lint/reports/violation_stats.sh \
    spyglass_lint/reports/lint_detailed.rpt
```

---

## Advanced Usage

### Running Specific Goals Only
Edit the TCL script to run only specific analyses:

```tcl
# Only run basic lint
current_goal lint/lint_rtl -top $TOP_MODULE
run_goal

# Skip RDC analysis
# Comment out rdc goals in script
```

### Setting Environment Variables
```bash
# Override top module
export TOP_MODULE=alternate_top
./run_spyglass_lint.sh alternate_top rtl_files.f

# Use specific library
export LIB_PATH=/path/to/libs
./run_spyglass_lint.sh my_top rtl_files.f
```

### Incremental Analysis
```bash
# First run - full analysis
./run_spyglass_lint.sh my_top rtl_files.f

# Fix violations...

# Re-run with existing project
spyglass -project lint_analysis -batch \
    -tcl spyglass_lint/spyglass_lint.tcl
```

### Generating Waiver File
After fixing what you can, generate waivers for remaining violations:

```bash
# Review waiver template
cat spyglass_lint/reports/waiver_template.swl

# Copy relevant waivers to policy file
vim project_lint.sgdc
# Add waivers in the WAIVERS section

# Re-run to verify waivers work
./run_spyglass_lint.sh my_top rtl_files.f
```

---

## Integration with CI/CD

### Return Code Check
```bash
# The script returns non-zero on failure
./run_spyglass_lint.sh my_top rtl_files.f
if [ $? -ne 0 ]; then
    echo "Lint check failed!"
    exit 1
fi

# Check for critical violations
CRITICAL_COUNT=$(grep -c "Error" spyglass_lint/reports/lint_summary.rpt)
if [ $CRITICAL_COUNT -gt 0 ]; then
    echo "Found $CRITICAL_COUNT critical violations!"
    exit 1
fi
```

### Jenkins/CI Integration
```groovy
stage('Spyglass Lint') {
    steps {
        sh './run_spyglass_lint.sh ${TOP_MODULE} rtl_files.f'
        publishHTML([
            reportDir: 'spyglass_lint/reports',
            reportFiles: 'lint_report.html',
            reportName: 'Spyglass Lint Report'
        ])
    }
}
```

---

## Troubleshooting

### Common Issues

#### 1. "Module not found"
- Check rtl_files.f includes all dependencies
- Verify +incdir paths are correct
- Ensure all files use correct module names

#### 2. "License error"
- Check Spyglass license: `lmstat -a`
- Set license server: `export LM_LICENSE_FILE=port@server`

#### 3. "Too many violations"
- Start with only Error severity rules
- Fix critical violations first
- Gradually enable more rules

#### 4. "False positives"
- Review violation context in HTML report
- Add specific waivers with justification
- Check if violation is actually correct

#### 5. "Analysis takes too long"
- Exclude test benches and IPs
- Run goals incrementally
- Use `set_option stop` for large sub-modules

---

## Best Practices

### 1. Progressive Analysis
- Start: Only W18, W391, W446, W498
- Next: Add width mismatches (W164a)
- Later: Add coding style (W240, W287)
- Finally: Add informational rules

### 2. Waiver Management
- Always add justification comments
- Reference design spec sections
- Review waivers during code reviews
- Periodically audit and clean up waivers

### 3. Regular Runs
- Run lint after major changes
- Include in pre-commit hooks
- Gate merges on clean lint
- Track violation trends over time

### 4. Team Guidelines
- Document project-specific conventions
- Share common waiver patterns
- Maintain centralized policy file
- Regular training on lint rules

---

## Example Workflow

```bash
# 1. Setup project
./generate_policy.sh
# Answer prompts for your project

# 2. First run
./run_spyglass_lint.sh my_chip rtl_files.f

# 3. Review HTML report
firefox spyglass_lint/reports/lint_report.html

# 4. Fix critical violations (W18, W391, W446, W498)
vim rtl/problematic_module.sv
# Fix issues...

# 5. Re-run to verify
./run_spyglass_lint.sh my_chip rtl_files.f

# 6. Add justified waivers for remaining issues
vim project_lint.sgdc
# Add waivers with comments

# 7. Final run
./run_spyglass_lint.sh my_chip rtl_files.f

# 8. Check for zero critical violations
grep "Error" spyglass_lint/reports/lint_summary.rpt
# Should return nothing or "0 Errors"
```

---

## Rule Reference Quick Guide

| Rule | Severity | Description | Fix Priority |
|------|----------|-------------|--------------|
| W18 | Error | Latches/Loops | Critical |
| W391 | Error | Reset Sync | Critical |
| W446 | Error | Blocking in Seq | Critical |
| W498 | Error | Missing Reset | Critical |
| W240b | Error | Multiple Drivers | Critical |
| W164a | Warning | Width Mismatch | High |
| W240 | Warning | Missing Default | High |
| W287 | Warning | Unconnected Port | High |
| W455 | Warning | Reset Glitch | High |
| W528 | Warning | Port Mismatch | Medium |
| W213 | Info | Unused Signal | Low |
| W336 | Info | Non-parameterized | Low |

---

## Support and Documentation

- Spyglass User Guide: `$SPYGLASS_HOME/doc/`
- Rule descriptions: `spyglass -help <rule_name>`
- Example: `spyglass -help W18`
- Online docs: Check Synopsys SolvNet

---

## Summary

You now have:
1. ✅ Comprehensive lint script with all critical checks
2. ✅ Customizable policy file (.sgdc)
3. ✅ Interactive policy generator
4. ✅ Multiple report formats (HTML, text, CSV)
5. ✅ CI/CD integration ready
6. ✅ Waiver management system

**Start with**: `./generate_policy.sh` then `./run_spyglass_lint.sh`
