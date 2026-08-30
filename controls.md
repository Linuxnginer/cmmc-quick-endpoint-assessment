# CMMC Quick Endpoint Assessment — Controls

## Overview

This document provides the technical control mapping for the **CMMC Quick Endpoint Assessment**.

The scanner evaluates selected Windows endpoint configurations that may contribute to satisfying technical requirements associated with **CMMC Level 2 / NIST SP 800-171**.

The purpose of this document is to explain:

- What each check evaluates
- Why the check is useful
- What technical evidence is collected
- What the check does not prove

> **Important:** Passing a technical check does not mean the organization has satisfied the complete CMMC requirement. CMMC requirements can involve technical, administrative, procedural, and organizational evidence.

---

# Control Status

The scanner uses the following result states:

|Status|Description|
|---|---|
|`PASS`|The endpoint meets the configured technical requirement|
|`FAIL`|The endpoint does not meet the configured technical requirement|
|`MANUAL REVIEW`|Additional human or organizational review is required|
|`N/A`|The check does not apply|

The current quick assessment primarily generates `PASS` and `FAIL` results.

---

# Access Control

## AC.L2-3.1.1 — Authorized Access

### Technical Check

The scanner evaluates endpoint access-related configuration, including:

- Local administrator membership
- Windows login/security banner

### Why It Matters

Endpoints should restrict access to authorized users and prevent unnecessary privileged access.

Unexpected local administrators can increase the risk of unauthorized system changes and privilege escalation.

### Evidence Collected

The scanner can collect administrator membership using:

```powershell
Get-LocalGroupMember -Group "Administrators"
```

The Windows legal notice is checked using:

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
```

### Limitation

The scanner cannot determine whether a user is organizationally authorized to access CUI.

---

## AC.L2-3.1.2 — Transaction and Function Control

### Technical Check

The scanner evaluates whether Remote Desktop is enabled.

### Why It Matters

Remote access can increase the attack surface of an endpoint.

Organizations should define when remote access is permitted and how it is protected.

### Evidence Collected

```text
HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server
```

### Limitation

This check only evaluates Windows Remote Desktop configuration.

It does not identify every remote-access mechanism that may exist on the endpoint.

---

## AC.L2-3.1.5 — Least Privilege

### Technical Check

The scanner evaluates membership in the local Administrators group.

### Why It Matters

Users should receive only the privileges necessary to perform their assigned responsibilities.

Excessive administrative privileges can increase the impact of a compromised account.

### Evidence Collected

```powershell
Get-LocalGroupMember -Group "Administrators"
```

### Limitation

The scanner cannot determine whether an administrator has a legitimate business justification.

That determination requires organizational context.

---

# Identification and Authentication

## IA.L2-3.5.2 — Identification and Authentication

### Technical Check

The scanner evaluates User Account Control.

### Expected Configuration

UAC should be enabled according to the organization's approved endpoint security baseline.

### Evidence Collected

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
```

Value:

```text
EnableLUA
```

### Limitation

UAC is only one component of an organization's identification and authentication architecture.

---

## IA.L2-3.5.10 — Device Lock

### Technical Check

The scanner evaluates the Windows inactivity timeout.

### Expected Configuration

The default policy in this project expects the endpoint to lock within:

```text
15 minutes
```

The value can be changed in:

```text
config/cmmc-policy.json
```

### Why It Matters

Automatic device locking reduces the risk of unauthorized access when an endpoint is unattended.

### Evidence Collected

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
```

### Limitation

The organization's approved security policy should determine the actual timeout requirement.

---

# Audit and Accountability

## AU.L2-3.3.1 — System Auditing

### Technical Check

The scanner evaluates Windows auditing and PowerShell logging configuration.

### Areas Evaluated

- PowerShell Script Block Logging
- PowerShell Module Logging
- Windows audit configuration

### Evidence Collected

```text
HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging
```

and:

```text
HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging
```

### Why It Matters

Security logging can help organizations investigate suspicious activity and establish an audit trail.

### Limitation

A configured logging policy does not prove that logs are:

- Centrally collected
- Reviewed
- Protected
- Retained
- Correlated
- Monitored

Those activities require additional controls and evidence.

---

## AU.L2-3.3.8 — Time Stamps

### Technical Check

The scanner checks the Windows Time service.

### Evidence Collected

```powershell
Get-Service W32Time
```

### Why It Matters

Consistent system time helps correlate security events between:

- Workstations
- Servers
- Domain controllers
- Security tools
- SIEM systems

### Limitation

A running Windows Time service does not prove that the endpoint is correctly synchronized with the organization's approved time source.

---

# Configuration Management

## CM.L2-3.4.1 — System Baselines

### Technical Check

The scanner records the Windows operating system and build number.

### Evidence Collected

```powershell
Get-CimInstance Win32_OperatingSystem
```

### Why It Matters

Organizations should maintain approved configurations and identify systems that have fallen outside the established baseline.

### Limitation

The Windows build number alone does not demonstrate that the complete endpoint configuration matches the organization's baseline.

---

## CM.L2-3.4.2 — Security Configuration

### Technical Check

The scanner evaluates LSA Protection.

### Evidence Collected

```text
HKLM\SYSTEM\CurrentControlSet\Control\Lsa
```

Value:

```text
RunAsPPL
```

### Why It Matters

LSA Protection is designed to help protect sensitive authentication-related processes.

### Limitation

LSA Protection is only one component of endpoint security configuration.

---

## CM.L2-3.4.7 — Least Functionality

### Technical Check

The scanner evaluates legacy SMB functionality, specifically SMBv1.

### Evidence Collected

```powershell
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

### Why It Matters

Legacy protocols can introduce unnecessary attack surface.

Where SMBv1 is not required, disabling it reduces exposure to known legacy-protocol risks.

---

# System and Communications Protection

## SC.L2-3.13.1 — Boundary Protection

### Technical Check

The scanner evaluates Windows Firewall profiles.

### Expected Configuration

Applicable Windows Firewall profiles should be enabled unless an approved security architecture provides equivalent protection.

### Evidence Collected

```powershell
Get-NetFirewallProfile
```

### Why It Matters

Host-based firewalls provide an additional security boundary around Windows endpoints.

### Limitation

The scanner does not validate whether every firewall rule is appropriate.

---

## SC.L2-3.13.5 — Protection of System Integrity

### Technical Check

The scanner evaluates Secure Boot.

### Evidence Collected

```powershell
Confirm-SecureBootUEFI
```

### Expected Configuration

Secure Boot should be enabled where supported and required by the organization's security baseline.

### Limitation

Secure Boot provides platform-integrity protection but does not establish complete endpoint security.

---

## SC.L2-3.13.6 — CUI Confidentiality

### Technical Check

The scanner evaluates BitLocker protection of the Windows operating-system volume.

### Expected Configuration

The system volume should be:

```text
FullyEncrypted
```

and protection should be:

```text
On
```

### Evidence Collected

```powershell
Get-BitLockerVolume
```

### Why It Matters

Encryption can help protect information stored on a device if the device is lost or stolen.

### Limitation

This check only evaluates the operating-system volume.

It does not prove that all CUI storage locations or removable media are appropriately encrypted.

---

## SC.L2-3.13.8 — Transmission and Storage Confidentiality

### Technical Check

The scanner may evaluate selected TLS configuration.

### Why It Matters

Organizations should use approved cryptographic protections for sensitive information.

### Limitation

A Windows TLS configuration check cannot prove that every application and communication path uses approved cryptography.

Application-level configuration may require separate validation.

---

## SC.L2-3.13.16 — Protection of CUI

### Technical Check

The scanner evaluates SMBv1.

### Expected Configuration

SMBv1 should be disabled unless a documented and approved business requirement exists.

### Evidence Collected

```powershell
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

### Why It Matters

SMBv1 is a legacy network protocol and should generally be removed from modern environments where it is not required.

---

# System and Information Integrity

## SI.L2-3.14.1 — Flaw Remediation

### Technical Check

The scanner evaluates the Windows Update service.

### Evidence Collected

```powershell
Get-Service wuauserv
```

### Why It Matters

Keeping Windows systems updated is an important component of endpoint security.

### Limitation

A running Windows Update service does not prove that all required patches have been installed.

Organizations should use their approved patch-management platform for complete patch compliance validation.

---

## SI.L2-3.14.2 — Malicious Code Protection

### Technical Check

The scanner evaluates Microsoft Defender status.

### Areas Evaluated

- Antivirus enabled
- Real-time protection enabled

### Evidence Collected

```powershell
Get-MpComputerStatus
```

### Why It Matters

Endpoint malware protection is an important component of system and information integrity.

### Limitation

Organizations using a third-party endpoint protection platform should modify the scanner to validate the approved security product instead of relying solely on Microsoft Defender.

---

## SI.L2-3.14.3 — Security Updates

### Technical Check

The scanner checks whether Windows reports a pending reboot.

### Why It Matters

Some operating-system and security updates require a reboot before they become fully active.

### Evidence Collected

The scanner evaluates Windows Update and Component Based Servicing reboot indicators.

### Limitation

A clean reboot state does not prove that all required security updates are installed.

---

# Login Banner

## Technical Check

The scanner evaluates the Windows legal notice configuration.

### Registry Location

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
```

### Values

```text
legalnoticecaption
legalnoticetext
```

### Expected Configuration

The expected banner is defined in:

```text
config/cmmc-policy.json
```

### Why It Matters

Organizations may use a standardized login notice to communicate that:

- The system is intended for authorized use
- Unauthorized access is prohibited
- System activity may be monitored
- Users are subject to organizational security requirements

### Important

The sample banner included in this project is not legal advice.

Organizations should obtain approval from the appropriate legal, security, and compliance personnel before deploying a login banner.

---

# How to Interpret a PASS

A result such as:

```text
PASS
```

means:

> The endpoint satisfied the specific technical test performed by the scanner.

It does **not** mean:

> The organization has satisfied the complete CMMC requirement.

For example:

```text
BitLocker = PASS
```

means the scanner observed the expected BitLocker state.

It does not prove that the organization's complete CUI encryption requirements have been satisfied.

---

# How to Interpret a FAIL

A result such as:

```text
FAIL
```

means:

> The endpoint did not satisfy the technical expectation configured in the assessment policy.

A failure should be investigated before remediation.

For example:

```text
Remote Desktop = FAIL
```

could mean:

- RDP is unauthorized
- RDP is required for a documented business purpose
- The endpoint has drifted from its baseline
- The policy configuration is incorrect

The scanner identifies the condition; the organization determines the appropriate response.

---

# Point-in-Time Assessment

The scanner produces a snapshot of the endpoint at the time of execution.

For example:

```text
August 30
    |
    +-- Firewall: PASS
```

This demonstrates the observed configuration at that point in time.

It does not automatically demonstrate that the configuration remained unchanged during:

```text
September
October
November
December
```

Continuous compliance requires appropriate monitoring, configuration management, and historical evidence.

---

# Control Mapping Summary

|Reference|Technical Check|
|---|---|
|AC.L2-3.1.1|Endpoint access / login banner|
|AC.L2-3.1.2|Remote Desktop|
|AC.L2-3.1.5|Local administrator membership|
|IA.L2-3.5.2|User Account Control|
|IA.L2-3.5.10|Automatic device lock|
|AU.L2-3.3.1|PowerShell and Windows auditing|
|AU.L2-3.3.8|Windows Time|
|CM.L2-3.4.1|Windows version/build|
|CM.L2-3.4.2|LSA Protection|
|CM.L2-3.4.7|SMBv1|
|SC.L2-3.13.1|Windows Firewall|
|SC.L2-3.13.5|Secure Boot|
|SC.L2-3.13.6|BitLocker|
|SC.L2-3.13.8|TLS configuration|
|SC.L2-3.13.16|SMBv1|
|SI.L2-3.14.1|Windows Update|
|SI.L2-3.14.2|Microsoft Defender|
|SI.L2-3.14.3|Pending reboot|

---

# Final Note

This project is intended to make endpoint assessment faster and more repeatable.

The scanner should be used as one component of a larger CMMC readiness program:

```text
CMMC Readiness
│
├── Policies
├── Procedures
├── System Security Plan
├── Asset Management
├── Configuration Management
├── Identity & Access Management
├── Security Monitoring
├── Incident Response
├── Personnel & Training
└── Technical Endpoint Assessment
        │
        └── CMMC Quick Endpoint Assessment
```

The objective is not simply to produce a green report.

The objective is to identify gaps, remediate them, validate the remediation, and maintain appropriate evidence over time.
