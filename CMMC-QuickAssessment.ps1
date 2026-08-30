#requires -RunAsAdministrator

<#
.SYNOPSIS
    CMMC Quick Endpoint Assessment

.DESCRIPTION
    Read-only Windows endpoint security assessment intended to
    identify common technical configuration gaps relevant to
    CMMC Level 2 / NIST SP 800-171 Rev. 2.

    This tool does NOT certify CMMC compliance.

.OUTPUTS
    CSV
    JSON
    TXT

.EXIT CODES
    0 = No detected failures
    1 = One or more failures
    2 = Assessment error
#>

[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\config\cmmc-policy.json",

    [string]$OutputPath = "$PSScriptRoot\output"
)

$ErrorActionPreference = "Stop"

$ComputerName = $env:COMPUTERNAME
$ScanTime = Get-Date

# ============================================================
# LOAD CONFIGURATION
# ============================================================

if (Test-Path $ConfigPath) {

    try {
        $Config = Get-Content $ConfigPath -Raw |
            ConvertFrom-Json
    }
    catch {
        Write-Error "Unable to load configuration: $($_.Exception.Message)"
        exit 2
    }

}
else {

    Write-Error "Configuration file not found: $ConfigPath"
    exit 2
}

New-Item `
    -Path $OutputPath `
    -ItemType Directory `
    -Force |
    Out-Null

$Results = [System.Collections.Generic.List[object]]::new()

# ============================================================
# RESULT FUNCTION
# ============================================================

function Add-Check {

    param(
        [string]$Control,
        [string]$Check,
        [bool]$Compliant,
        [string]$Expected,
        [string]$Actual,
        [string]$Evidence
    )

    $Results.Add(
        [PSCustomObject]@{
            Computer  = $ComputerName
            Timestamp = $ScanTime
            Control   = $Control
            Check     = $Check
            Status    = if ($Compliant) { "PASS" } else { "FAIL" }
            Expected  = $Expected
            Actual    = $Actual
            Evidence  = $Evidence
        }
    )
}

# ============================================================
# OS
# ============================================================

$OS = Get-CimInstance Win32_OperatingSystem

$BuildOK =
    [int]$OS.BuildNumber -ge
    [int]$Config.minimumWindowsBuild

Add-Check `
    -Control "CM.L2-3.4.1" `
    -Check "Supported Windows version" `
    -Compliant $BuildOK `
    -Expected "Build >= $($Config.minimumWindowsBuild)" `
    -Actual "$($OS.Caption) Build $($OS.BuildNumber)" `
    -Evidence "Win32_OperatingSystem"

# ============================================================
# FIREWALL
# ============================================================

$FirewallProfiles = Get-NetFirewallProfile

$FirewallOK =
    ($FirewallProfiles.Enabled -notcontains $false)

$FirewallState =
    ($FirewallProfiles |
        ForEach-Object {
            "$($_.Name)=$($_.Enabled)"
        }) -join "; "

Add-Check `
    -Control "SC.L2-3.13.1" `
    -Check "Windows Firewall" `
    -Compliant $FirewallOK `
    -Expected "All firewall profiles enabled" `
    -Actual $FirewallState `
    -Evidence "Get-NetFirewallProfile"

# ============================================================
# DEFENDER
# ============================================================

try {

    $Defender = Get-MpComputerStatus

    $DefenderOK =
        $Defender.AntivirusEnabled -and
        $Defender.RealTimeProtectionEnabled

    Add-Check `
        -Control "SI.L2-3.14.2" `
        -Check "Microsoft Defender protection" `
        -Compliant $DefenderOK `
        -Expected "Antivirus and real-time protection enabled" `
        -Actual "AV=$($Defender.AntivirusEnabled); RealTime=$($Defender.RealTimeProtectionEnabled)" `
        -Evidence "Get-MpComputerStatus"
}
catch {

    Add-Check `
        -Control "SI.L2-3.14.2" `
        -Check "Microsoft Defender protection" `
        -Compliant $false `
        -Expected "Endpoint malware protection enabled" `
        -Actual "Unable to query Defender" `
        -Evidence "Get-MpComputerStatus"
}

# ============================================================
# BITLOCKER
# ============================================================

try {

    $BitLocker =
        Get-BitLockerVolume -MountPoint $env:SystemDrive

    $BitLockerOK =
        ($BitLocker.VolumeStatus -eq "FullyEncrypted") -and
        ($BitLocker.ProtectionStatus -eq "On")

    Add-Check `
        -Control "SC.L2-3.13.6" `
        -Check "BitLocker OS volume" `
        -Compliant $BitLockerOK `
        -Expected "Fully encrypted and protection enabled" `
        -Actual "Volume=$($BitLocker.VolumeStatus); Protection=$($BitLocker.ProtectionStatus)" `
        -Evidence "Get-BitLockerVolume"
}
catch {

    Add-Check `
        -Control "SC.L2-3.13.6" `
        -Check "BitLocker OS volume" `
        -Compliant $false `
        -Expected "OS volume encrypted" `
        -Actual "Unable to query BitLocker" `
        -Evidence "Get-BitLockerVolume"
}

# ============================================================
# SECURE BOOT
# ============================================================

try {

    $SecureBoot = Confirm-SecureBootUEFI

    Add-Check `
        -Control "SC.L2-3.13.5" `
        -Check "Secure Boot" `
        -Compliant ($SecureBoot -eq $true) `
        -Expected "Secure Boot enabled" `
        -Actual "$SecureBoot" `
        -Evidence "Confirm-SecureBootUEFI"
}
catch {

    Add-Check `
        -Control "SC.L2-3.13.5" `
        -Check "Secure Boot" `
        -Compliant $false `
        -Expected "Secure Boot enabled" `
        -Actual "Unavailable or disabled" `
        -Evidence "Confirm-SecureBootUEFI"
}

# ============================================================
# UAC
# ============================================================

$PolicyPath =
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

$Policy =
    Get-ItemProperty $PolicyPath

$UACOK =
    $Policy.EnableLUA -eq 1

Add-Check `
    -Control "IA.L2-3.5.2" `
    -Check "User Account Control" `
    -Compliant $UACOK `
    -Expected "UAC enabled" `
    -Actual "EnableLUA=$($Policy.EnableLUA)" `
    -Evidence $PolicyPath

# ============================================================
# SCREEN LOCK
# ============================================================

$LockSeconds =
    $Policy.InactivityTimeoutSecs

if ($null -eq $LockSeconds) {
    $LockSeconds = 0
}

$LockOK =
    ($LockSeconds -gt 0) -and
    ($LockSeconds -le
        ($Config.maxScreenLockMinutes * 60))

Add-Check `
    -Control "IA.L2-3.5.10" `
    -Check "Automatic screen lock" `
    -Compliant $LockOK `
    -Expected "<= $($Config.maxScreenLockMinutes) minutes" `
    -Actual "$LockSeconds seconds" `
    -Evidence $PolicyPath

# ============================================================
# LOGIN BANNER
# ============================================================

$ActualBannerTitle =
    [string]$Policy.legalnoticecaption

$ActualBannerText =
    [string]$Policy.legalnoticetext

$ExpectedTitle =
    $Config.loginBanner.title.Trim() -replace '\s+', ' '

$ExpectedText =
    $Config.loginBanner.text.Trim() -replace '\s+', ' '

$ActualTitle =
    $ActualBannerTitle.Trim() -replace '\s+', ' '

$ActualText =
    $ActualBannerText.Trim() -replace '\s+', ' '

$BannerTitleOK =
    (-not [string]::IsNullOrWhiteSpace($ActualBannerTitle)) -and
    ($ActualTitle -eq $ExpectedTitle)

$BannerTextOK =
    (-not [string]::IsNullOrWhiteSpace($ActualBannerText)) -and
    ($ActualText -eq $ExpectedText)

$BannerOK =
    $BannerTitleOK -and $BannerTextOK

$BannerActual = if ($BannerOK) {
    "Required banner configured"
}
elseif ([string]::IsNullOrWhiteSpace($ActualBannerTitle)) {
    "Banner title missing"
}
elseif (-not $BannerTitleOK) {
    "Banner title does not match policy"
}
elseif ([string]::IsNullOrWhiteSpace($ActualBannerText)) {
    "Banner text missing"
}
else {
    "Banner text does not match policy"
}

Add-Check `
    -Control "AC.L2-3.1.1" `
    -Check "Windows login banner" `
    -Compliant $BannerOK `
    -Expected "Approved corporate login banner" `
    -Actual $BannerActual `
    -Evidence "$PolicyPath\legalnoticecaption; $PolicyPath\legalnoticetext"

# ============================================================
# REMOTE DESKTOP
# ============================================================

$RDP =
    Get-ItemProperty `
        "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"

$RDPEnabled =
    $RDP.fDenyTSConnections -eq 0

$RDPOK =
    if ($Config.disableRDP) {
        -not $RDPEnabled
    }
    else {
        $true
    }

Add-Check `
    -Control "AC.L2-3.1.2" `
    -Check "Remote Desktop" `
    -Compliant $RDPOK `
    -Expected "RDP disabled unless authorized" `
    -Actual $(if ($RDPEnabled) {
        "Enabled"
    } else {
        "Disabled"
    }) `
    -Evidence "Terminal Server registry configuration"

# ============================================================
# SMBv1
# ============================================================

try {

    $SMB1 =
        Get-WindowsOptionalFeature `
            -Online `
            -FeatureName SMB1Protocol

    $SMBOK =
        $SMB1.State -ne "Enabled"

    Add-Check `
        -Control "SC.L2-3.13.16" `
        -Check "SMBv1" `
        -Compliant $SMBOK `
        -Expected "SMBv1 disabled" `
        -Actual "$($SMB1.State)" `
        -Evidence "SMB1Protocol Windows feature"
}
catch {

    Add-Check `
        -Control "SC.L2-3.13.16" `
        -Check "SMBv1" `
        -Compliant $false `
        -Expected "SMBv1 disabled" `
        -Actual "Unable to determine SMBv1 state" `
        -Evidence "SMB1Protocol"
}

# ============================================================
# WINDOWS UPDATE
# ============================================================

$WU =
    Get-Service -Name wuauserv

$WUOK =
    $WU.Status -eq "Running"

Add-Check `
    -Control "SI.L2-3.14.1" `
    -Check "Windows Update service" `
    -Compliant $WUOK `
    -Expected "Windows Update service running" `
    -Actual "$($WU.Status)" `
    -Evidence "Get-Service wuauserv"

# ============================================================
# LSA PROTECTION
# ============================================================

$LSAPath =
    "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

$LSA =
    Get-ItemProperty $LSAPath

$LSAOK =
    $LSA.RunAsPPL -eq 1

Add-Check `
    -Control "CM.L2-3.4.2" `
    -Check "LSA Protection" `
    -Compliant $LSAOK `
    -Expected "LSA Protection enabled" `
    -Actual "RunAsPPL=$($LSA.RunAsPPL)" `
    -Evidence $LSAPath

# ============================================================
# WINDOWS TIME
# ============================================================

$TimeService =
    Get-Service -Name W32Time

$TimeOK =
    $TimeService.Status -eq "Running"

Add-Check `
    -Control "AU.L2-3.3.8" `
    -Check "Windows Time service" `
    -Compliant $TimeOK `
    -Expected "Windows Time service running" `
    -Actual "$($TimeService.Status)" `
    -Evidence "Get-Service W32Time"

# ============================================================
# PENDING REBOOT
# ============================================================

$RebootRequired = $false

$RebootPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
)

foreach ($Path in $RebootPaths) {

    if (Test-Path $Path) {
        $RebootRequired = $true
    }
}

Add-Check `
    -Control "SI.L2-3.14.3" `
    -Check "Pending reboot" `
    -Compliant (-not $RebootRequired) `
    -Expected "No pending reboot" `
    -Actual $(if ($RebootRequired) {
        "Reboot required"
    } else {
        "No reboot required"
    }) `
    -Evidence "CBS/Windows Update reboot state"

# ============================================================
# POWERSHELL LOGGING
# ============================================================

$ScriptBlockPath =
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

$ModulePath =
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"

$ScriptBlock =
    Get-ItemProperty $ScriptBlockPath

$Module =
    Get-ItemProperty $ModulePath

$PSLoggingOK =
    ($ScriptBlock.EnableScriptBlockLogging -eq 1) -and
    ($Module.EnableModuleLogging -eq 1)

Add-Check `
    -Control "AU.L2-3.3.1" `
    -Check "PowerShell logging" `
    -Compliant $PSLoggingOK `
    -Expected "Script Block and Module logging enabled" `
    -Actual "ScriptBlock=$($ScriptBlock.EnableScriptBlockLogging); Module=$($Module.EnableModuleLogging)" `
    -Evidence "$ScriptBlockPath; $ModulePath"

# ============================================================
# LOCAL ADMINISTRATORS
# ============================================================

try {

    $Admins =
        Get-LocalGroupMember -Group "Administrators"

    $UnexpectedAdmins = @()

    foreach ($Admin in $Admins) {

        $Name =
            $Admin.Name.Split("\")[-1]

        if ($Config.allowedLocalAdmins -notcontains $Name) {

            $UnexpectedAdmins += $Admin.Name
        }
    }

    $AdminsOK =
        $UnexpectedAdmins.Count -eq 0

    Add-Check `
        -Control "AC.L2-3.1.5" `
        -Check "Local administrator membership" `
        -Compliant $AdminsOK `
        -Expected "Only approved administrators" `
        -Actual $(if ($AdminsOK) {
            "No unexpected administrators"
        } else {
            $UnexpectedAdmins -join "; "
        }) `
        -Evidence "Get-LocalGroupMember Administrators"
}
catch {

    Add-Check `
        -Control "AC.L2-3.1.5" `
        -Check "Local administrator membership" `
        -Compliant $false `
        -Expected "Only approved administrators" `
        -Actual "Unable to enumerate administrators" `
        -Evidence "Get-LocalGroupMember"
}

# ============================================================
# SUMMARY
# ============================================================

$Total =
    $Results.Count

$Passed =
    @($Results | Where-Object Status -eq "PASS").Count

$Failed =
    @($Results | Where-Object Status -eq "FAIL").Count

$Score =
    if ($Total -gt 0) {
        [math]::Round(($Passed / $Total) * 100, 2)
    }
    else {
        0
    }

$OverallStatus =
    if ($Failed -eq 0) {
        "READY"
    }
    else {
        "NOT READY"
    }

# ============================================================
# REPORT
# ============================================================

$BaseName =
    "$($ComputerName)-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$CSV =
    Join-Path $OutputPath "$BaseName.csv"

$JSON =
    Join-Path $OutputPath "$BaseName.json"

$TXT =
    Join-Path $OutputPath "$BaseName.txt"

$Results |
    Export-Csv `
        -Path $CSV `
        -NoTypeInformation `
        -Encoding UTF8

$Report = [PSCustomObject]@{

    Tool = "CMMC Quick Endpoint Assessment"

    Version = "1.0.0"

    Computer = $ComputerName

    ScanTime = $ScanTime

    OperatingSystem = $OS.Caption

    Build = $OS.BuildNumber

    Status = $OverallStatus

    Score = $Score

    TotalChecks = $Total

    Passed = $Passed

    Failed = $Failed

    Results = $Results
}

$Report |
    ConvertTo-Json -Depth 8 |
    Out-File `
        -FilePath $JSON `
        -Encoding UTF8

@"
CMMC QUICK ENDPOINT ASSESSMENT
==============================

Computer: $ComputerName
Scan Time: $ScanTime

OS: $($OS.Caption)
Build: $($OS.BuildNumber)

STATUS: $OverallStatus
SCORE: $Score%

Checks: $Total
Passed: $Passed
Failed: $Failed

FAILED CHECKS
=============

$(
    ($Results |
        Where-Object Status -eq "FAIL" |
        ForEach-Object {
            "[$($_.Control)] $($_.Check)`r`nExpected: $($_.Expected)`r`nActual: $($_.Actual)`r`n"
        }) -join "`r`n"
)
"@ |
    Out-File `
        -FilePath $TXT `
        -Encoding UTF8

# ============================================================
# CONSOLE
# ============================================================

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       CMMC QUICK ENDPOINT ASSESSMENT" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computer : $ComputerName"
Write-Host "OS       : $($OS.Caption)"
Write-Host "Build    : $($OS.BuildNumber)"
Write-Host ""

$Results |
    Select-Object Control, Check, Status, Actual |
    Format-Table -AutoSize

Write-Host ""

Write-Host "Checks : $Total"
Write-Host "Passed : $Passed" -ForegroundColor Green
Write-Host "Failed : $Failed" -ForegroundColor Red
Write-Host "Score  : $Score%"
Write-Host ""

if ($OverallStatus -eq "READY") {

    Write-Host "RESULT: READY" -ForegroundColor Green
}
else {

    Write-Host "RESULT: NOT READY" -ForegroundColor Red
}

Write-Host ""
Write-Host "Reports:"
Write-Host "  $CSV"
Write-Host "  $JSON"
Write-Host "  $TXT"
Write-Host ""

if ($Failed -eq 0) {
    exit 0
}
else {
    exit 1
}
