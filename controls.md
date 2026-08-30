CMMC Quick Endpoint Assessment — Control Mapping
Purpose
This document describes how the technical checks performed by the CMMC Quick Endpoint Assessment relate to security requirements commonly associated with CMMC Level 2 and NIST SP 800-171 Rev. 2.
The mappings are provided to help security teams understand why a check exists and what technical evidence it produces.

Important: A passing technical check does not, by itself, demonstrate that the corresponding CMMC requirement has been fully satisfied. CMMC assessments can require examination of policies, procedures, documentation, organizational processes, interviews, and other evidence.
Assessment Status
The scanner uses the following statuses:
Status	Meaning
PASS	The endpoint passed the technical check
FAIL	The endpoint did not meet the configured technical expectation
MANUAL REVIEW	Human or organizational review is required
N/A	The check does not apply to the endpoint

The current quick scanner primarily produces PASS and FAIL results.
Access Control
AC.L2-3.1.1 — Authorized Access
Endpoint Check
The scanner evaluates:
Local administrator membership
Windows login/security banner
Why It Matters
Organizations should control access to systems and ensure users are appropriately authorized.
Unexpected local administrator accounts can increase the risk of unauthorized configuration changes or privilege escalation.

Evidence
The scanner can record:
Get-LocalGroupMember Administrators

and:
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System

for the Windows legal notice configuration.
Limitation
This technical check does not determine whether an individual is organizationally authorized to access CUI.
AC.L2-3.1.2 — Transaction and Function Control
Endpoint Check
The scanner evaluates whether Remote Desktop is enabled.
Why It Matters
Remote access increases the attack surface of an endpoint and should be controlled according to organizational requirements.
Evidence
The scanner examines:
HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server

Limitation
A disabled RDP service does not prove that all remote-access mechanisms are controlled.
AC.L2-3.1.5 — Least Privilege
Endpoint Check
The scanner evaluates membership in the local Administrators group.
Why It Matters
Excessive administrative privileges increase the potential impact of compromised accounts.
Evidence
Get-LocalGroupMember -Group "Administrators"

Limitation
The scanner does not determine whether every privilege assignment is appropriate for a user's job function.
Identification and Authentication
IA.L2-3.5.2 — Device Identification and Authentication
Endpoint Check
The scanner checks whether Windows User Account Control is enabled.
Evidence
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System

Specifically:
EnableLUA

Limitation
UAC is only one component of endpoint authentication and privilege protection.
IA.L2-3.5.8 — Password Management
Endpoint Check
The scanner collects Windows password-policy information, including minimum password length.
Evidence
net accounts

Limitation
A local Windows password policy does not necessarily represent the organization's complete identity-management policy, especially in Active Directory environments.
IA.L2-3.5.10 — Device Lock
Endpoint Check
The scanner evaluates the Windows inactivity timeout.
Expected Configuration
The default configuration expects:
15 minutes or less

Evidence
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System

Limitation
The organization should verify the actual policy requirement for its environment.
Audit and Accountability
AU.L2-3.3.1 — System Auditing
Endpoint Check
The scanner evaluates Windows audit-policy configuration and PowerShell logging.
Evidence
auditpol /get /category:*

and:
HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging

Limitation
The presence of logging configuration does not prove that logs are:
Reviewed
Protected
Retained
Centrally collected
Correlated
Monitored
Those activities require additional controls and evidence.
AU.L2-3.3.8 — Time Stamps
Endpoint Check
The scanner checks the Windows Time service.
Evidence
Get-Service W32Time

Why It Matters
Accurate system time helps correlate security events across endpoints, servers, authentication systems, and security-monitoring platforms.
Limitation
A running Windows Time service does not prove that the endpoint is synchronized with the organization's approved authoritative time source.
Configuration Management
CM.L2-3.4.1 — System Baselines
Endpoint Check
The scanner records the Windows version and build.
Why It Matters
Organizations should maintain approved system configurations and identify endpoints that have fallen outside the approved baseline.
Evidence
Get-CimInstance Win32_OperatingSystem

Limitation
The Windows build alone does not establish complete configuration compliance.
CM.L2-3.4.2 — Security Configuration
Endpoint Check
The scanner checks LSA Protection.
Evidence
HKLM\SYSTEM\CurrentControlSet\Control\Lsa

Specifically:
RunAsPPL

Limitation
LSA Protection is one security configuration setting and is not a complete configuration baseline.
CM.L2-3.4.7 — Least Functionality
Endpoint Check
The scanner examines SMB-related configuration and SMBv1.
Why It Matters
Legacy network protocols can introduce unnecessary attack surface.
System and Communications Protection
SC.L2-3.13.1 — Boundary Protection
Endpoint Check
The scanner evaluates Windows Firewall profiles.
Expected Configuration
All applicable Windows Firewall profiles should be enabled unless an approved organizational architecture provides equivalent protection.
Evidence
Get-NetFirewallProfile

Limitation
The scanner does not evaluate the quality of every firewall rule.
SC.L2-3.13.5 — Publicly Accessible Systems
Endpoint Check
The scanner checks Secure Boot.
Evidence
Confirm-SecureBootUEFI

Limitation
Secure Boot is a platform-integrity mechanism and should not be interpreted as complete protection against all boot-level attacks.
SC.L2-3.13.6 — CUI Confidentiality
Endpoint Check
The scanner evaluates BitLocker protection of the Windows operating-system volume.
Expected Configuration
The OS volume should be:
FullyEncrypted

and:
ProtectionStatus = On

Evidence
Get-BitLockerVolume

Limitation
The scanner does not validate every CUI storage location or removable-media encryption requirement.
SC.L2-3.13.8 — Transmission and Storage Confidentiality
Endpoint Check
The scanner checks TLS configuration.
Limitation
A single TLS registry setting cannot demonstrate that every application or communication path uses approved cryptographic mechanisms.
SC.L2-3.13.16 — CUI at Rest / Network Protection
Endpoint Check
The scanner verifies that SMBv1 is not enabled.
Evidence
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

Why It Matters
SMBv1 is a legacy protocol and should generally be removed or disabled where it is not required.
System and Information Integrity
SI.L2-3.14.1 — Flaw Remediation
Endpoint Check
The scanner checks the Windows Update service.
Evidence
Get-Service wuauserv

Limitation
A running Windows Update service does not prove that all required patches are installed.
SI.L2-3.14.2 — Malicious Code Protection
Endpoint Check
The scanner evaluates Microsoft Defender:
Antivirus status
Real-time protection
Evidence
Get-MpComputerStatus

Limitation
The organization may use a different approved endpoint protection product. In that case, the scanner should be customized to validate that product.
SI.L2-3.14.3 — Security Alerts
Endpoint Check
The scanner identifies whether Windows reports a pending reboot.
Why It Matters
Security and operating-system updates sometimes require a reboot before protections become fully active.
Limitation
A pending reboot check does not prove that the endpoint has received all required security updates.
Login Banner
Purpose
The scanner validates the Windows legal notice configured through:
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System

The following registry values are examined:
legalnoticecaption
legalnoticetext

The expected values are stored in:
config/cmmc-policy.json

Why It Matters
Organizations may use a standardized warning banner to notify users that:
The system is restricted to authorized use.
Unauthorized access is prohibited.
System activity may be monitored.
Users are subject to organizational security policies.
Important
The sample banner included with this project is not legal advice.
Organizations should use language approved by their legal, security, and compliance teams.

Summary
The scanner should be viewed as a technical endpoint readiness tool.
Its results can help answer:

"Does this endpoint appear to match our technical security baseline?"
It cannot independently answer:
"Is the organization CMMC compliant?"
A complete CMMC program requires additional organizational and system-level evidence.
