CMMC Quick Endpoint Assessment
A lightweight PowerShell tool for performing a technical Windows endpoint readiness assessment against common security requirements relevant to CMMC Level 2 / NIST SP 800-171 Rev. 2.
Important: This project does not certify CMMC compliance. CMMC assessment requires organizational, procedural, technical, and documentary evidence. This tool is intended to help identify endpoint configuration gaps and collect technical evidence.
Features
The scanner currently checks:
Windows version/build
Windows Firewall
Microsoft Defender
BitLocker
Secure Boot
User Account Control
Automatic screen locking
Windows login/legal banner
Remote Desktop
SMBv1
Windows Update
LSA Protection
Windows Time
Pending reboot
PowerShell Script Block logging
PowerShell Module logging
Local Administrators
Requirements
Windows 10/11 or supported Windows Server
PowerShell 5.1+
Administrator privileges
Usage
Clone the repository:
git clone https://github.com/YOUR-ORG/cmmc-quick-endpoint-assessment.git

cd cmmc-quick-endpoint-assessment

Run the assessment:
Set-ExecutionPolicy -Scope Process Bypass

.\CMMC-QuickAssessment.ps1

Specify a different configuration:
.\CMMC-QuickAssessment.ps1 `
    -ConfigPath .\config\cmmc-policy.json

Specify an output directory:
.\CMMC-QuickAssessment.ps1 `
    -OutputPath C:\CMMC-Evidence

Results
The scanner produces three files:
output/
├── COMPUTER-20260830-102500.csv
├── COMPUTER-20260830-102500.json
└── COMPUTER-20260830-102500.txt

CSV
Designed for importing endpoint results into Excel, Power BI, SIEM platforms, or a central compliance database.
JSON
Designed for automation and integration with an endpoint-management or compliance platform.
TXT
Designed for quick human review.
Exit Codes
Code	Meaning
0	No detected endpoint failures
1	One or more endpoint failures
2	Assessment error

This makes the scanner suitable for automation.
Example:

.\CMMC-QuickAssessment.ps1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Endpoint passed assessment"
}
else {
    Write-Host "Endpoint requires remediation"
}

Login Banner
The scanner validates the Windows legal notice configured under:
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System

The expected banner is defined in:
config/cmmc-policy.json

Update the policy file to match the exact language approved by your organization.
Configuration
Do not hard-code organization-specific requirements into the PowerShell scanner.
Instead, modify:

config/cmmc-policy.json

For example:
{
  "minimumWindowsBuild": 22621,
  "maxScreenLockMinutes": 15,
  "disableRDP": true
}

This allows the same scanner to be deployed across different endpoint groups.
Compliance Mapping
The control identifiers in the reports are intended as assessment references, not a claim that a single endpoint check completely satisfies the associated CMMC requirement.
A CMMC requirement may require:

Technical configuration
Policies
Procedures
Interviews
Documentation
Centralized logging
Evidence of operation over time
Organizational processes
Therefore:
PASS

means:
The endpoint passed this particular technical check.
It does not mean:
The organization has satisfied the complete CMMC requirement.
Evidence Handling
Assessment output may contain sensitive system information.
Treat the generated files as potentially sensitive and store them according to your organization's security policy.

Do not commit production endpoint reports to this Git repository.

Scope
This project is intentionally designed as a quick endpoint assessment.
It should not replace:

An enterprise vulnerability scanner
Microsoft Defender for Endpoint
Microsoft Intune
Configuration Manager
A SIEM
A CMMC assessment
An SSP
A POA&M
An organizational risk assessment
Roadmap
Potential future functionality:
Full NIST SP 800-171 Rev. 2 control mapping
CIS benchmark checks
Microsoft Security Baseline checks
Intune integration
Microsoft Defender for Endpoint integration
Remote endpoint scanning
Centralized JSON ingestion
HTML dashboard
Compliance trend reporting
Remediation scripts
GPO verification
Evidence package generation
CMMC Level 2 assessment workbook generation
License
See LICENSE.
