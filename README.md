# NIST/CMMC Quick Endpoint Assessment

A lightweight PowerShell tool that helps security and compliance teams quickly assess the security configuration of Windows endpoints against technical requirements relevant to **CMMC Level 2 and NIST SP 800-171**.

The purpose of this project is simple:

> **Quickly identify endpoint configuration gaps before they become compliance problems.**

---

## Why This Tool Exists

Preparing an environment for CMMC can involve reviewing a large number of Windows workstations and servers.

Manually checking every endpoint for security settings is slow, inconsistent, and difficult to document.

This tool automates a set of common endpoint security checks and produces a standardized report showing:

- What was checked
- What the expected configuration was
- What the endpoint actually reported
- Whether the check passed or failed
- Where the technical evidence came from

Instead of manually checking each machine, an administrator can run one PowerShell script and receive a consistent assessment report.

---

## What Does It Do?

The assessment checks common Windows security configurations, including:

|Area|Example Checks|
|---|---|
|Access Control|Local Administrators, Remote Desktop|
|Authentication|UAC, workstation lock|
|Audit & Accountability|PowerShell logging, Windows Time|
|Configuration Management|Windows version, LSA Protection|
|System & Communications Protection|Firewall, BitLocker, Secure Boot, SMBv1|
|System & Information Integrity|Defender, Windows Update|
|Security Notice|Windows login banner|

The tool is designed to provide a **quick technical snapshot** of the endpoint.

---

## Example Assessment

Running the scanner produces results similar to:

```text
==============================================
       CMMC QUICK ENDPOINT ASSESSMENT
==============================================

Computer : WORKSTATION-001
OS       : Microsoft Windows 11 Pro
Build    : 26100

[PASS] SC.L2-3.13.1 - Windows Firewall
[PASS] SC.L2-3.13.6 - BitLocker OS volume
[PASS] SC.L2-3.13.5 - Secure Boot
[PASS] IA.L2-3.5.2 - User Account Control
[FAIL] AC.L2-3.1.2 - Remote Desktop
[FAIL] Login Banner
[PASS] SI.L2-3.14.2 - Microsoft Defender

Checks : 15
Passed : 13
Failed : 2
Score  : 86.67%

RESULT: NOT READY
```

The important part is that the tool does not simply provide a score.

It identifies **which configuration needs attention**.

---

# Key Features

## Quick Endpoint Assessment

Run a single PowerShell script to evaluate multiple security configurations.

```powershell
.\CMMC-QuickAssessment.ps1
```

The assessment is designed to be fast enough for routine endpoint validation.

---

## Login Banner Validation

The tool checks whether the Windows legal notice/login banner matches the organization's approved configuration.

The expected banner is defined in:

```text
config/cmmc-policy.json
```

Example:

```json
{
  "loginBanner": {
    "title": "AUTHORIZED USE ONLY",
    "text": "This computer system is for authorized use only."
  }
}
```

Organizations should replace the example with their own approved legal/security language.

> The sample login banner is provided for demonstration purposes only and is not legal advice.

---

## Security Configuration Checks

The scanner can identify common endpoint security gaps such as:

- Firewall disabled
- BitLocker not enabled
- Secure Boot disabled
- Defender protection disabled
- UAC disabled
- Remote Desktop enabled
- SMBv1 enabled
- Windows Update service stopped
- LSA Protection disabled
- PowerShell logging not configured
- Unexpected local administrators
- Missing or incorrect login banner
- Pending reboot

---

## Read-Only Assessment

The assessment script is designed primarily to **inspect the endpoint rather than modify it**.

The scanner does not automatically:

- Change passwords
- Modify Group Policy
- Enable BitLocker
- Disable Remote Desktop
- Change firewall rules
- Modify security policies
- Change the login banner

This makes it appropriate for an initial assessment or validation scan.

Remediation should be performed through the organization's approved configuration-management process.

---

# Assessment Workflow

A typical workflow looks like this:

```text
             Windows Endpoint
                    |
                    v
        +-----------------------+
        | Quick Assessment      |
        | PowerShell Script     |
        +-----------+-----------+
                    |
             +------+------+
             |             |
             v             v
           PASS           FAIL
             |             |
             |             v
             |        Remediation
             |             |
             |             v
             |          Re-scan
             |             |
             +------+------+
                    |
                    v
             Final Evidence
```

This makes the tool useful not only for an initial assessment, but also for **remediation validation**.

---

# Reports

The scanner generates three report formats.

```text
output/
├── WORKSTATION-001-20260830-173500.csv
├── WORKSTATION-001-20260830-173500.json
└── WORKSTATION-001-20260830-173500.txt
```

## CSV

Useful for:

- Excel
- Power BI
- Compliance reporting
- Endpoint comparison
- Remediation tracking

## JSON

Useful for:

- Automation
- APIs
- Databases
- SIEM integration
- Custom dashboards

## TXT

Useful for:

- Human review
- Troubleshooting
- Remediation tickets
- Quick assessment summaries

---

# Installation

Clone the repository:

```powershell
git clone https://github.com/YOUR-ORG/cmmc-quick-endpoint-assessment.git
```

Change to the repository directory:

```powershell
cd cmmc-quick-endpoint-assessment
```

---

# Requirements

The scanner requires:

- Windows 10, Windows 11, or supported Windows Server
- PowerShell 5.1 or later
- Administrator privileges
- Authorization to assess the endpoint

Run PowerShell as Administrator.

---

# Running the Assessment

If PowerShell execution policy prevents the script from running, use a process-scoped policy change:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Then run:

```powershell
.\CMMC-QuickAssessment.ps1
```

Specify a custom configuration file:

```powershell
.\CMMC-QuickAssessment.ps1 `
    -ConfigPath .\config\cmmc-policy.json
```

Specify a custom output directory:

```powershell
.\CMMC-QuickAssessment.ps1 `
    -OutputPath C:\CMMC-Evidence
```

---

# Configuration

Organization-specific settings are stored in:

```text
config/cmmc-policy.json
```

Example:

```json
{
  "minimumWindowsBuild": 22621,
  "maxScreenLockMinutes": 15,
  "disableRDP": true,
  "allowedLocalAdmins": [
    "Administrator"
  ],
  "loginBanner": {
    "title": "AUTHORIZED USE ONLY",
    "text": "This computer system is for authorized use only."
  }
}
```

Keeping policy settings separate from the PowerShell code makes it easier to customize the scanner for different environments.

---

# Exit Codes

The script returns an exit code that can be used for automation.

|Exit Code|Meaning|
|---|---|
|`0`|No detected failures|
|`1`|One or more checks failed|
|`2`|Assessment error|

Example:

```powershell
.\CMMC-QuickAssessment.ps1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Endpoint passed assessment."
}
else {
    Write-Host "Endpoint requires review."
}
```

---

# CMMC and NIST SP 800-171

The checks in this project are mapped to technical requirements commonly associated with CMMC Level 2 and NIST SP 800-171.

The mapping is documented in:

```text
docs/controls.md
```

The evidence generated by the scanner is documented in:

```text
docs/evidence.md
```

These documents explain what each check is intended to evaluate and what evidence is collected.

---

# Important Compliance Disclaimer

This project is **not a CMMC certification tool**.

A successful endpoint scan does not mean that an organization is CMMC compliant.

CMMC assessment can require evidence covering areas such as:

- Policies
- Procedures
- System Security Plans
- Plans of Action and Milestones
- Asset inventories
- Configuration management
- Incident response
- Security awareness
- Personnel responsibilities
- Access control
- Organizational processes
- Technical controls
- Assessment evidence

This project focuses primarily on **technical endpoint configuration**.

Think of it as:

```text
CMMC Program
     |
     +-- Policies
     +-- Procedures
     +-- Documentation
     +-- People
     +-- Processes
     +-- Architecture
     +-- Technical Controls
             |
             +-- CMMC Quick Endpoint Assessment
```

The scanner is one component of a larger compliance program.

---

# Recommended Use

The recommended process is:

### 1. Establish Your Baseline

Configure `config/cmmc-policy.json` to match your organization's approved security baseline.

### 2. Assess

Run the scanner against your endpoints.

### 3. Review

Identify failed checks.

### 4. Remediate

Correct the configuration using your approved security-management process.

### 5. Validate

Run the assessment again.

### 6. Document

Retain appropriate assessment and remediation evidence according to your organization's requirements.

---

# Security Considerations

Assessment reports may contain sensitive information such as:

- Computer names
- Operating-system information
- Security configuration
- Local administrator information
- Security-control status

Do not upload production endpoint reports to a public GitHub repository.

The repository includes a `.gitignore` intended to prevent normal assessment output from being committed.

Store assessment results according to your organization's security and evidence-handling requirements.

---

# Project Structure

```text
cmmc-quick-endpoint-assessment/
│
├── CMMC-QuickAssessment.ps1
│
├── config/
│   └── cmmc-policy.json
│
├── docs/
│   ├── controls.md
│   └── evidence.md
│
├── examples/
│   └── sample-report.json
│
├── output/
│   └── .gitkeep
│
├── .gitignore
├── LICENSE
└── README.md
```

---

# Roadmap

Planned or potential future improvements include:

- Full CMMC Level 2 assessment-objective mapping
- `PASS / FAIL / MANUAL REVIEW / N/A` status
- HTML reports
- Enterprise dashboard
- Intune integration
- Microsoft Defender for Endpoint integration
- Active Directory and GPO validation
- Centralized endpoint collection
- Remediation recommendations
- Configuration-drift detection
- Historical assessment tracking
- Power BI integration
- Evidence package generation
- Automated ticket creation

---

# Contributing

Contributions are welcome.

When adding a new security check, include:

1. The control/reference
2. The technical check being performed
3. The expected configuration
4. The actual configuration being evaluated
5. The evidence source
6. Known limitations
7. Testing instructions

Keep the core assessment functionality read-only whenever possible.

---

# License

See LICENSE for licensing information.

---

## Project Goal

The goal of this project is to make endpoint security assessment:

**Fast. Repeatable. Documentable. Actionable.**

It is designed to help security teams answer one practical question:

> **"What technical security gaps exist on this endpoint that we should investigate before a CMMC assessment?"**
