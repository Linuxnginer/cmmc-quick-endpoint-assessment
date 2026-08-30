**CMMC Quick Endpoint Assessment**


A lightweight PowerShell-based endpoint assessment tool designed to help organizations quickly identify common Windows security configuration gaps that may affect CMMC Level 2 / NIST SP 800-171 readiness.
This project is intended to provide a fast technical snapshot of an endpoint before a deeper compliance review, assessment, or remediation effort.


Important: This tool does not certify CMMC compliance. CMMC compliance requires organizational policies, procedures, documentation, technical controls, evidence, interviews, and assessment activities. This script focuses specifically on technical endpoint configuration.
Why Is This Useful?
CMMC assessments can involve a large number of endpoints, and manually checking every workstation or server can be time-consuming.
This tool provides a quick way to answer questions such as:

Is Windows Firewall enabled?

Is Microsoft Defender active?

Is BitLocker protecting the operating-system drive?

Is Secure Boot enabled?

Is UAC enabled?

Instead of manually checking each endpoint, the administrator can run one script and receive a standardized report.

**The Goal**

The goal is not to say:

"This computer is CMMC compliant."
The goal is to say:
"Here are the technical configuration checks this endpoint passed or failed, along with evidence that can be reviewed."
That distinction is important.
A CMMC requirement can involve much more than a Windows registry setting or security feature. An organization may need policies, procedures, documentation, centralized security controls, evidence of operation, and personnel interviews.



For example:
{
  "loginBanner": {
    "title": "AUTHORIZED USE ONLY",
    "text": "This computer system is for authorized use only.\nUnauthorized access is prohibited.\nUse of this system may be monitored, recorded, and audited."
  }
}

The scanner compares the configured Windows login banner against the organization's approved text.
This is useful because organizations frequently have a standard security/legal notice that must be consistently deployed across endpoints.

Do not assume the sample language in this repository is your organization's legally approved banner. Have your legal/security team approve the actual language before deployment.

Why Use a Quick Scanner?
1. Find Problems Quickly
A security administrator can run the script on an endpoint and immediately see which checks pass and which require attention.

For example:

[PASS] SC.L2-3.13.1 - Windows Firewall
[PASS] SC.L2-3.13.6 - BitLocker
[FAIL] AC.L2-3.1.2 - Remote Desktop
[PASS] IA.L2-3.5.2 - User Account Control
[FAIL] Windows Login Banner

This gives the administrator an immediate remediation list.



A simple workflow might look like this:
                    ┌──────────────────┐
                    │ Windows Endpoint │
                    └────────┬─────────┘
                             │
                             ▼
                 ┌────────────────────────┐
                 │ CMMC Quick Assessment   │
                 │      PowerShell         │
                 └───────────┬────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
           PASS            FAIL          EVIDENCE
              │              │              │
              │              ▼              │
              │         REMEDIATION         │
              │              │              │
              └──────────────┼──────────────┘
                             ▼
                       RE-SCAN
                             │
                             ▼
                    UPDATED EVIDENCE

**Example**

Run:
.\CMMC-QuickAssessment.ps1

The console produces a summary similar to:
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
[FAIL] AC.L2-3.1.1 - Windows login banner
[PASS] SI.L2-3.14.2 - Microsoft Defender protection

Checks : 15
Passed : 13
Failed : 2
Score  : 86.67%

RESULT: NOT READY


The administrator can then investigate the two failed checks.

Configuration

Organization-specific requirements should be stored in:

config/cmmc-policy.json

For example:

{
  "minimumWindowsBuild": 22621,
  "maxScreenLockMinutes": 15,
  "disableRDP": true,
  "allowedLocalAdmins": [
    "Administrator"
  ],
  "loginBanner": {
    "title": "AUTHORIZED USE ONLY",
    "text": "Approved organizational login banner goes here."
  }
}

This allows organizations to modify their baseline without modifying the main PowerShell script.
Output
Assessment results are written to:
output/

Example:
output/
├── WORKSTATION-001-20260830-173500.csv
├── WORKSTATION-001-20260830-173500.json
└── WORKSTATION-001-20260830-173500.txt

CSV
Useful for:
Excel
Power BI
Centralized reporting
Compliance dashboards
Endpoint comparisons
JSON
Useful for:
Automation
APIs
SIEM ingestion
Databases
Custom dashboards
TXT
Useful for:
Human review
Ticket attachments
Quick troubleshooting
Assessment notes


Important: What This Tool Does NOT Do
This tool does not replace a CMMC assessment.
It does not automatically determine whether an organization satisfies all CMMC requirements.

For example, a technical check cannot determine whether an organization has:

An adequate System Security Plan (SSP)
Appropriate policies and procedures
Proper incident-response processes
Appropriate personnel training
Required documentation
Correct CUI boundaries
Appropriate asset inventories
Adequate organizational processes
Required evidence over the assessment period
Those areas require additional organizational and assessment activities.
Read-Only by Design
The quick assessment is designed to inspect rather than modify the endpoint.
That means:

Scanner
   │
   ├── Reads configuration
   ├── Tests security state
   ├── Records evidence
   └── Reports gaps

It does not automatically:
X Change Group Policy
X Enable BitLocker
X Disable services
X Modify firewall rules
X Change passwords
X Change security policy
X Modify the login banner

This makes it safer to run during an assessment or baseline review.
Recommended Use
A good operational approach is:
Initial Assessment
Run the scanner against your endpoint population.
Remediation
Investigate and correct failed checks using your organization's approved configuration-management process.
Validation
Run the scanner again.
Evidence
Retain appropriate results according to your organization's evidence-retention and security requirements.
Continuous Monitoring
Periodically repeat the assessment to identify configuration drift.
Security Considerations
Assessment reports can contain sensitive information about your environment.
They may include:

Computer names
Operating system versions
Security configuration
Local administrator information
Security-control status
Configuration details
Do not commit production endpoint reports to a public GitHub repository.
The repository's .gitignore is configured to prevent normal assessment output from being committed.

Store reports according to your organization's security and evidence-handling requirements.

Requirements
Windows 10/11 or supported Windows Server
PowerShell 5.1 or later
Administrator privileges
Appropriate organizational authorization to scan the endpoint
Run from an elevated PowerShell session:
Set-ExecutionPolicy -Scope Process Bypass

.\CMMC-QuickAssessment.ps1

CMMC Disclaimer
This project is provided as a technical security assessment aid.
Passing all checks does not mean that an organization is CMMC compliant or ready for certification.

The results should be reviewed by qualified security/compliance personnel and evaluated against the organization's actual:

CMMC scope
System Security Plan
policies
procedures
security architecture
configuration baselines
evidence
CUI environment
Control mappings in this project are provided as technical references and should be validated against the applicable CMMC assessment objectives and current authoritative requirements.
Roadmap
Future versions may include:
Full CMMC Level 2 assessment-objective coverage
NIST SP 800-171 control/objective mapping
PASS / FAIL / MANUAL REVIEW / N/A
HTML reporting
Enterprise dashboard
Intune integration
Microsoft Defender for Endpoint integration
Active Directory/GPO validation
Centralized endpoint collection
Remediation recommendations
Evidence-package generation
Historical compliance tracking
Configuration-drift detection
Export to Power BI
Automated ticket creation
Contributing
Pull requests and improvements are welcome.
When adding a new check, include:

Control/reference
Assessment objective being evaluated
Technical rationale
Expected configuration
Evidence collected
Limitations
Test instructions
Avoid adding automated remediation to the assessment script unless it is explicitly separated from the read-only assessment functionality.
License
See LICENSE.
Project Purpose
The purpose of this project is simple:
Give security teams a fast, repeatable way to identify Windows endpoint configuration gaps that may affect CMMC readiness.
