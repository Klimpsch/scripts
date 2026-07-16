<#
.SYNOPSIS
    Retrieves temperatures and fan speeds from a list of iDRAC servers via the Redfish REST API.

.NOTES
    - Works with iDRAC7/8/9 (Redfish endpoint: /redfish/v1/Chassis/System.Embedded.1/Thermal)
    - Works in Windows PowerShell 5.1 and PowerShell 7+
    - Uses the same credentials for all iDRACs (typical for iDRAC Enterprise fleets)

.USAGE
    .\Get-iDracThermals.ps1
    (You will be prompted once for iDRAC credentials)
#>

# ============================================================
#  EDIT THIS LIST - add/remove iDRAC hostnames or IPs
# ============================================================
$Servers = @(
    "192.168.1.120",
    "192.168.1.121",
    "idrac-r740-01.mydomain.local"
    # "idrac-r650-02.mydomain.local"
)
# ============================================================

# Prompt once for credentials (used for all servers)
$Credential = Get-Credential -Message "Enter iDRAC credentials (e.g. root)"

# --- Allow self-signed certificates ---
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PowerShell 7+: use -SkipCertificateCheck on each call
    $SkipCert = @{ SkipCertificateCheck = $true }
}
else {
    # Windows PowerShell 5.1: global cert bypass
    $SkipCert = @{}
    Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert,
        WebRequest req, int problem) { return true; }
}
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}

$Results = foreach ($Server in $Servers) {
    $Uri = "https://$Server/redfish/v1/Chassis/System.Embedded.1/Thermal"
    Write-Host "Querying $Server ..." -ForegroundColor Cyan

    try {
        $Thermal = Invoke-RestMethod -Uri $Uri -Method Get -Credential $Credential @SkipCert -TimeoutSec 15

        # --- Temperatures ---
        foreach ($t in $Thermal.Temperatures) {
            if ($null -ne $t.ReadingCelsius) {
                [PSCustomObject]@{
                    Server  = $Server
                    Type    = "Temperature"
                    Sensor  = $t.Name
                    Reading = "$($t.ReadingCelsius) C"
                    Health  = $t.Status.Health
                }
            }
        }

        # --- Fans ---
        foreach ($f in $Thermal.Fans) {
            # iDRAC reports fan speed as Reading + ReadingUnits (usually RPM)
            if ($null -ne $f.Reading) {
                $FanName = if ($f.FanName) { $f.FanName } else { $f.Name }
                [PSCustomObject]@{
                    Server  = $Server
                    Type    = "Fan"
                    Sensor  = $FanName
                    Reading = "$($f.Reading) $($f.ReadingUnits)"
                    Health  = $f.Status.Health
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to query ${Server}: $($_.Exception.Message)"
        [PSCustomObject]@{
            Server  = $Server
            Type    = "ERROR"
            Sensor  = "-"
            Reading = $_.Exception.Message
            Health  = "-"
        }
    }
}

# --- Output ---
$Results | Format-Table -AutoSize

# Optional: export to CSV (uncomment)
# $Results | Export-Csv -Path ".\iDRAC_Thermals_$(Get-Date -Format yyyyMMdd_HHmm).csv" -NoTypeInformation