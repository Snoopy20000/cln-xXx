# xXx Cleaner - Web Edition
# Backend Engine: License + HWID + Discord + Ocean Check + NAPSE + Auto-Launch UI

param(
    [string]$Action = "",
    [string]$Mode = "standard",
    [string]$LicenseKey = "",
    [switch]$ValidateLicense,
    [switch]$NoBrowser,
    [switch]$ServerOnly
)

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ============================================
# CONFIGURATION
# ============================================
$Global:WebhookURL = "https://discordapp.com/api/webhooks/1516360049662885890/1DPUG9J4H0cSh2CBWL9SvTY14Q6Yz3_ROMykRRrLqb_qraHZRxLF9gi6tndz9vpLqE_Q"
$Global:LicenseFile = "$env:LOCALAPPDATA\xXxCleaner\license.dat"
$Global:LogFile = "$env:LOCALAPPDATA\xXxCleaner\activity.log"
$Global:ServerPort = 8844
$Global:HostedUI = "https://snoopy2000.github.io/cln-xXx/"

# NAPSE Evasion Config
$NAPSE = @{
    DelayBetweenOps = 2000
    AvoidEvent104 = $true
    AvoidUSNDelete = $true
    AvoidExplorerRestart = $true
    AvoidAMSI = $true
    AvoidBulkKill = $true
}

# Ocean Check Detection Patterns
$OceanCheck = @(
    "Ocean.exe",
    "OceanAntiCheat.exe",
    "OceanAC.exe",
    "OceanShield.exe",
    "OceanProtector.exe"
)

# ============================================
# DISCORD LOGGING (FIXED - Uses ConvertTo-Json)
# ============================================
function Send-DiscordMessage {
    param(
        [string]$Title,
        [string]$Description,
        [int]$Color = 3447003,
        [hashtable]$Fields = @{}
    )

    try {
        $embed = @{
            title = $Title
            description = $Description
            color = $Color
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
            footer = @{ text = "xXx Cleaner | $(Get-HWID)" }
        }

        if ($Fields.Count -gt 0) {
            $fieldArray = @()
            foreach ($key in $Fields.Keys) {
                $fieldArray += @{ name = $key; value = $Fields[$key]; inline = $true }
            }
            $embed.fields = $fieldArray
        }

        $payload = @{ embeds = @($embed) } | ConvertTo-Json -Depth 10 -Compress

        Invoke-RestMethod -Uri $Global:WebhookURL -Method Post -ContentType "application/json" -Body $payload -TimeoutSec 10
    } catch {
        Add-Content -Path $Global:LogFile -Value "[$(Get-Date)] DISCORD ERROR: $($_.Exception.Message)"
    }
}

function Log-Action {
    param([string]$Action, [string]$Status = "INFO", [string]$Details = "")

    $hwid = Get-HWID
    $user = $env:USERNAME
    $computer = $env:COMPUTERNAME
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Local log
    $entry = "[$timestamp] [$Status] [$user@$computer] [$hwid] [$Action] $Details"
    Add-Content -Path $Global:LogFile -Value $entry

    # Discord log
    $color = switch ($Status) {
        "SUCCESS" { 3066993 }
        "ERROR"   { 15158332 }
        "WARNING" { 16776960 }
        default   { 3447003 }
    }

    $fields = @{
        "User" = $user
        "Computer" = $computer
        "HWID" = $hwid
        "Action" = $Action
        "Status" = $Status
    }
    if ($Details) { $fields["Details"] = $Details }

    Send-DiscordMessage -Title "xXx Cleaner Activity" -Description "$Action - $Status" -Color $color -Fields $fields
}

# ============================================
# HWID GENERATION
# ============================================
function Get-HWID {
    try {
        $cpu = (Get-WmiObject Win32_Processor).ProcessorId
        $mb = (Get-WmiObject Win32_BaseBoard).SerialNumber
        $disk = (Get-WmiObject Win32_DiskDrive).SerialNumber
        $raw = "$cpu-$mb-$disk"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
        $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash) -replace "-", "").Substring(0, 32)
    } catch {
        return "HWID_ERROR_$(Get-Random)"
    }
}

# ============================================
# OCEAN CHECK BYPASS
# ============================================
function Test-OceanCheck {
    Write-Log "Checking for Ocean Anti-Cheat..." "INFO"
    $detected = $false
    foreach ($proc in $OceanCheck) {
        $running = Get-Process | Where-Object { $_.ProcessName -like "*$proc*" }
        if ($running) {
            $detected = $true
            Log-Action "OceanCheck" "WARNING" "Detected: $($running.ProcessName)"
        }
    }
    return $detected
}

function Bypass-OceanCheck {
    Log-Action "OceanCheck" "INFO" "Applying Ocean bypass techniques"
    $oceanPaths = @(
        "HKLM:\SOFTWARE\Ocean",
        "HKLM:\SOFTWARE\WOW6432Node\Ocean",
        "HKCU:\Software\Ocean",
        "$env:LOCALAPPDATA\Ocean",
        "$env:PROGRAMDATA\Ocean"
    )
    foreach ($path in $oceanPaths) {
        if (Test-Path $path) {
            Invoke-Silent { Remove-Item -Path $path -Recurse -Force }
            Invoke-NAPSEDelay
        }
    }
    $oceanDrivers = @("Ocean.sys", "OceanAC.sys", "OceanShield.sys")
    foreach ($driver in $oceanDrivers) {
        Invoke-Silent { sc.exe delete $driver }
        Invoke-NAPSEDelay
    }
    Log-Action "OceanCheck" "SUCCESS" "Ocean bypass complete"
}

# ============================================
# NAPSE CHECK BYPASS (Enhanced)
# ============================================
function Test-NAPSE {
    Write-Log "Checking NAPSE environment..." "INFO"
    $napseIndicators = @(
        "$env:PROGRAMDATA\NAPSE",
        "$env:LOCALAPPDATA\NAPSE",
        "HKLM:\SOFTWARE\NAPSE"
    )
    $found = $false
    foreach ($ind in $napseIndicators) {
        if (Test-Path $ind) { $found = $true; break }
    }
    if ($found) {
        Log-Action "NAPSE" "WARNING" "NAPSE indicators detected - switching to maximum stealth"
    }
    return $found
}

function Bypass-NAPSE {
    Log-Action "NAPSE" "INFO" "Applying enhanced NAPSE bypass"
    $napseLogPaths = @(
        "$env:PROGRAMDATA\NAPSE\Logs",
        "$env:LOCALAPPDATA\NAPSE\Logs"
    )
    foreach ($path in $napseLogPaths) {
        if (Test-Path $path) {
            Get-ChildItem $path -File | ForEach-Object {
                Invoke-Silent {
                    $fs = [System.IO.File]::Open($_.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)
                    $zeros = New-Object byte[] $_.Length
                    $fs.Write($zeros, 0, $zeros.Length)
                    $fs.Close()
                    Remove-Item $_.FullName -Force
                }
                Invoke-NAPSEDelay
            }
        }
    }
    $napseReg = "HKLM:\SOFTWARE\NAPSE"
    if (Test-Path $napseReg) {
        Get-Item $napseReg | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $napseReg -Name $_.Name -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "NAPSE" "SUCCESS" "NAPSE bypass complete"
}

# ============================================
# LICENSE SYSTEM
# ============================================
function Initialize-LicenseSystem {
    $dir = Split-Path $Global:LicenseFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Get-StoredLicense {
    if (Test-Path $Global:LicenseFile) {
        try {
            $encrypted = Get-Content $Global:LicenseFile -Raw
            $bytes = [System.Convert]::FromBase64String($encrypted)
            $json = [System.Text.Encoding]::UTF8.GetString($bytes)
            return $json | ConvertFrom-Json
        } catch { return $null }
    }
    return $null
}

function Save-License {
    param([string]$Key, [string]$HWID)

    $data = @{ Key = $Key; HWID = $HWID; Activated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") } | ConvertTo-Json
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($data)
    $encrypted = [System.Convert]::ToBase64String($bytes)
    $encrypted | Set-Content $Global:LicenseFile -Force
}

function Validate-License {
    param([string]$Key)

    $currentHWID = Get-HWID
    $stored = Get-StoredLicense

    if ($stored -and $stored.HWID -eq $currentHWID -and $stored.Key -eq $Key) {
        Log-Action "License Validation" "SUCCESS" "Local validation passed"
        return @{ Valid = $true; Message = "License validated (local)" }
    }

    Log-Action "License Activation" "INFO" "Key: $Key | HWID: $currentHWID"

    $fields = @{
        "License Key" = $Key
        "HWID" = $currentHWID
        "User" = $env:USERNAME
        "Computer" = $env:COMPUTERNAME
    }
    try {
        $ip = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5
        $fields["IP"] = $ip
    } catch { $fields["IP"] = "Unknown" }

    Send-DiscordMessage -Title "License Activation Request" -Description "New activation attempt" -Color 16776960 -Fields $fields

    Save-License -Key $Key -HWID $currentHWID
    Log-Action "License Activation" "SUCCESS" "Key: $Key | HWID: $currentHWID"

    return @{ Valid = $true; Message = "License activated and bound to this machine" }
}

function Check-License {
    $stored = Get-StoredLicense
    $currentHWID = Get-HWID

    if (-not $stored) {
        return @{ Valid = $false; Message = "No license found" }
    }

    if ($stored.HWID -ne $currentHWID) {
        Log-Action "License HWID Mismatch" "ERROR" "Stored: $($stored.HWID) | Current: $currentHWID"
        return @{ Valid = $false; Message = "License bound to different machine. Contact support." }
    }

    Log-Action "License Check" "SUCCESS" "Key: $($stored.Key)"
    return @{ Valid = $true; Message = "License valid" }
}

# ============================================
# NAPSE EVASION HELPERS
# ============================================
function Invoke-NAPSEDelay { Start-Sleep -Milliseconds $NAPSE.DelayBetweenOps }
function Invoke-Silent { param([scriptblock]$C) try { & $C 2>$null | Out-Null } catch {} }

# ============================================
# CLEAN FUNCTIONS (All 33 modules)
# ============================================
function Clean-Bam {
    Log-Action "Clean-Bam" "INFO"
    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
    if (Test-Path $p) {
        Get-ChildItem $p | ForEach-Object {
            $u = $_.PSPath
            Get-ItemProperty $u | Get-Member -MemberType NoteProperty | 
                Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider|Version" } |
                ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $u -Name $_.Name -Force }; Invoke-NAPSEDelay }
        }
    }
    Log-Action "Clean-Bam" "SUCCESS"
}

function Clean-SystemInformer {
    Log-Action "Clean-SystemInformer" "INFO"
    @("$env:LOCALAPPDATA\SystemInformer", "$env:APPDATA\SystemInformer", "HKCU:\Software\SystemInformer") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-SystemInformer" "SUCCESS"
}

function Clean-SeeShells {
    Log-Action "Clean-SeeShells" "INFO"
    @("$env:LOCALAPPDATA\Packages\*SeeShells*", "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\*seeshells*") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object { Invoke-Silent { Remove-Item $_.PSPath -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-SeeShells" "SUCCESS"
}

function Clean-RecentDocs {
    Log-Action "Clean-RecentDocs" "INFO"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider|MRUListEx" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force } }
        Invoke-Silent { Remove-ItemProperty -Path $p -Name "MRUListEx" -Force }
    }
    $rf = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $rf) { Get-ChildItem $rf -File | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force }; Invoke-NAPSEDelay } }
    Log-Action "Clean-RecentDocs" "SUCCESS"
}

function Clean-Recuva {
    Log-Action "Clean-Recuva" "INFO"
    @("$env:APPDATA\Recuva", "$env:LOCALAPPDATA\Recuva", "HKCU:\Software\Recuva", "HKCU:\Software\Piriform\Recuva") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-Recuva" "SUCCESS"
}

function Bypass-Everything {
    Log-Action "Bypass-Everything" "INFO"
    $sp = "HKLM:\SYSTEM\CurrentControlSet\Services\Everything"
    if (Test-Path $sp) { Invoke-Silent { Set-ItemProperty -Path $sp -Name "Start" -Value 4 }; Invoke-NAPSEDelay }
    @("$env:LOCALAPPDATA\Everything", "C:\ProgramData\Everything") | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -File | Where-Object { $_.Extension -eq ".db" } | ForEach-Object {
                Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
                Invoke-NAPSEDelay
            }
        }
    }
    Log-Action "Bypass-Everything" "SUCCESS"
}

function Clean-PreviousFiles {
    Log-Action "Clean-PreviousFiles" "INFO"
    @("$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db", "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Log-Action "Clean-PreviousFiles" "SUCCESS"
}

function Clean-MuiCache {
    Log-Action "Clean-MuiCache" "INFO"
    $p = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-MuiCache" "SUCCESS"
}

function Clean-Archistory {
    Log-Action "Clean-Archistory" "INFO"
    @("$env:LOCALAPPDATA\Archistory", "$env:APPDATA\Archistory", "HKCU:\Software\Archistory") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-Archistory" "SUCCESS"
}

function Clean-Nvidia {
    Log-Action "Clean-Nvidia" "INFO"
    @("$env:LOCALAPPDATA\NVIDIA Corporation\Drs", "$env:PROGRAMDATA\NVIDIA Corporation\Drs", "HKLM:\SOFTWARE\NVIDIA Corporation\Global\Drs", "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Enum") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-Nvidia" "SUCCESS"
}

function Clean-PSHistory {
    Log-Action "Clean-PSHistory" "INFO"
    @((Get-PSReadlineOption).HistorySavePath, "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt") | ForEach-Object {
        if (Test-Path $_) {
            @("Get-Process", "Get-Service", "ipconfig /all", "Get-ChildItem", "Write-Host 'test'") | Set-Content -Path $_ -Force
            Invoke-NAPSEDelay
            Invoke-Silent { Clear-Content -Path $_ -Force; Remove-Item $_ -Force }
        }
    }
    Clear-History
    Log-Action "Clean-PSHistory" "SUCCESS"
}

function Clean-DataUsage {
    Log-Action "Clean-DataUsage" "INFO"
    @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DataUsage", "$env:PROGRAMDATA\Microsoft\Windows\SRU") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Invoke-Silent { netsh wlan delete profile name=* i=* }
    Log-Action "Clean-DataUsage" "SUCCESS"
}

function Clean-DNSCache {
    Log-Action "Clean-DNSCache" "INFO"
    Invoke-Silent { ipconfig /flushdns }
    Invoke-NAPSEDelay
    $dp = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
    if (Test-Path $dp) { Invoke-Silent { Remove-ItemProperty -Path $dp -Name "CacheHashTable*" } }
    Log-Action "Clean-DNSCache" "SUCCESS"
}

function Clear-WinDefTraces {
    Log-Action "Clear-WinDefTraces" "INFO"
    @("$env:PROGRAMDATA\Microsoft\Windows Defender\Scans", "$env:PROGRAMDATA\Microsoft\Windows Defender\Support", "$env:PROGRAMDATA\Microsoft\Windows Defender\Quarantine") | ForEach-Object {
        if (Test-Path $_) { Get-ChildItem $_ -Recurse | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force -Recurse }; Invoke-NAPSEDelay } }
    }
    Log-Action "Clear-WinDefTraces" "SUCCESS"
}

function Clean-Amcache {
    Log-Action "Clean-Amcache" "INFO"
    @("$env:LOCALAPPDATA\Microsoft\Windows\AppCompat\Programs\Amcache.hve", "$env:LOCALAPPDATA\Microsoft\Windows\AppCompat\Programs\Amcache.hve.LOG*") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Log-Action "Clean-Amcache" "SUCCESS"
}

function Clean-WinSearch {
    Log-Action "Clean-WinSearch" "INFO"
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\RecentItems", "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-WinSearch" "SUCCESS"
}

function Clean-JumpLists {
    Log-Action "Clean-JumpLists" "INFO"
    @("$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations", "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations") | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -File | ForEach-Object {
                Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
                Invoke-NAPSEDelay
            }
        }
    }
    Log-Action "Clean-JumpLists" "SUCCESS"
}

function Clean-AppSwitched {
    Log-Action "Clean-AppSwitched" "INFO"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-AppSwitched" "SUCCESS"
}

function Clean-WinTemp {
    Log-Action "Clean-WinTemp" "INFO"
    @($env:TEMP, $env:TMP, "$env:WINDIR\Temp", "$env:WINDIR\Prefetch") | ForEach-Object {
        if (Test-Path $_) { Get-ChildItem $_ -Recurse -Force | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force -Recurse }; Invoke-NAPSEDelay } }
    }
    Log-Action "Clean-WinTemp" "SUCCESS"
}

function Clean-Prefetch {
    Log-Action "Clean-Prefetch" "INFO"
    $p = "$env:WINDIR\Prefetch"
    if (Test-Path $p) {
        Get-ChildItem $p -File | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Log-Action "Clean-Prefetch" "SUCCESS"
}

function Clean-Crashdumps {
    Log-Action "Clean-Crashdumps" "INFO"
    @("$env:LOCALAPPDATA\CrashDumps", "$env:PROGRAMDATA\Microsoft\Windows\WER", "$env:LOCALAPPDATA\Microsoft\Windows\WER") | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -Recurse -File | ForEach-Object {
                Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
                Invoke-NAPSEDelay
            }
        }
    }
    Log-Action "Clean-Crashdumps" "SUCCESS"
}

function Clean-Recent {
    Log-Action "Clean-Recent" "INFO"
    @("$env:APPDATA\Microsoft\Windows\Recent", "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations", "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations") | ForEach-Object {
        if (Test-Path $_) { Get-ChildItem $_ -File | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force }; Invoke-NAPSEDelay } }
    }
    Log-Action "Clean-Recent" "SUCCESS"
}

function Clean-EventLog {
    Log-Action "Clean-EventLog" "INFO"
    @("Application", "Security", "System", "Setup", "ForwardedEvents") | ForEach-Object {
        try {
            if ($Mode -ne "stealth") { Invoke-Silent { wevtutil cl $_ } }
        } catch {}
        Invoke-NAPSEDelay
    }
    Log-Action "Clean-EventLog" "SUCCESS"
}

function Clean-History {
    Log-Action "Clean-History" "INFO"
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU") | ForEach-Object {
        if (Test-Path $_) {
            Get-Item $_ | Get-Member -MemberType NoteProperty | 
                Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider|MRUList" } |
                ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $_ -Name $_.Name -Force }; Invoke-NAPSEDelay }
        }
    }
    Log-Action "Clean-History" "SUCCESS"
}

function Clean-Jornatracer {
    Log-Action "Clean-Jornatracer" "INFO"
    @("$env:LOCALAPPDATA\Jornatracer", "$env:APPDATA\Jornatracer", "HKCU:\Software\Jornatracer") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-Jornatracer" "SUCCESS"
}

function Disable-Services {
    Log-Action "Disable-Services" "INFO"
    @("DiagTrack", "dmwappushservice", "WMPNetworkSvc") | ForEach-Object {
        Invoke-Silent { Set-Service -Name $_ -StartupType Disabled }
        Invoke-NAPSEDelay
    }
    Log-Action "Disable-Services" "SUCCESS"
}

function Clean-AppcompatCache {
    Log-Action "Clean-AppcompatCache" "INFO"
    $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache"
    if (Test-Path $p) { Invoke-Silent { Remove-ItemProperty -Path $p -Name "AppCompatCache" -Force }; Invoke-NAPSEDelay }
    Log-Action "Clean-AppcompatCache" "SUCCESS"
}

function Clean-LastActivity {
    Log-Action "Clean-LastActivity" "INFO"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\ShowJumpView"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-LastActivity" "SUCCESS"
}

function Clean-UserAssist {
    Log-Action "Clean-UserAssist" "INFO"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
    if (Test-Path $p) {
        Get-ChildItem $p -Recurse | ForEach-Object {
            if ($_.PSIsContainer) {
                Get-Item $_.PSPath | Get-Member -MemberType NoteProperty | 
                    Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
                    ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $_.PSPath -Name $_.Name -Force }; Invoke-NAPSEDelay }
            }
        }
    }
    Log-Action "Clean-UserAssist" "SUCCESS"
}

function Clean-Regseeker {
    Log-Action "Clean-Regseeker" "INFO"
    @("$env:APPDATA\RegSeeker", "$env:LOCALAPPDATA\RegSeeker", "HKCU:\Software\RegSeeker") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-Regseeker" "SUCCESS"
}

function Clean-BrowserHistory {
    Log-Action "Clean-BrowserHistory" "INFO"
    @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History", "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History-journal", "$env:APPDATA\Mozilla\Firefox\Profiles\*.default\places.sqlite", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Log-Action "Clean-BrowserHistory" "SUCCESS"
}

function Clean-RegistryEditor {
    Log-Action "Clean-RegistryEditor" "INFO"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit"
    if (Test-Path $p) { Invoke-Silent { Remove-Item $p -Recurse -Force }; Invoke-NAPSEDelay }
    Log-Action "Clean-RegistryEditor" "SUCCESS"
}

function Create-NewJournal {
    Log-Action "Create-NewJournal" "INFO"
    Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter | ForEach-Object {
        $d = "${_}:\"
        try {
            Invoke-Silent { fsutil usn createjournal m=1000000 a=100000 $d }
            Invoke-NAPSEDelay
            Invoke-Silent { fsutil usn deletejournal /d $d }
            Invoke-NAPSEDelay
            Invoke-Silent { fsutil usn createjournal m=1000000 a=100000 $d }
        } catch {}
    }
    Log-Action "Create-NewJournal" "SUCCESS"
}

function Clean-Regedit {
    Log-Action "Clean-Regedit" "INFO"
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-Regedit" "SUCCESS"
}

function Clean-Shellbag {
    Log-Action "Clean-Shellbag" "INFO"
    @("HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU", "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Log-Action "Clean-Shellbag" "SUCCESS"
}

# ============================================
# SYSTEM OPTIMIZATION (CLEAN ALL - RENAMED)
# ============================================
function Start-SystemOptimization {
    $oceanDetected = Test-OceanCheck
    $napseDetected = Test-NAPSE

    if ($oceanDetected) { Bypass-OceanCheck }
    if ($napseDetected) { Bypass-NAPSE }

    Log-Action "SystemOptimization" "INFO" "Full system optimization initiated"
    @("Clean-Bam", "Clean-SystemInformer", "Clean-SeeShells", "Clean-RecentDocs", "Clean-Recuva", "Bypass-Everything", "Clean-PreviousFiles", "Clean-MuiCache", "Clean-Archistory", "Clean-Nvidia", "Clean-PSHistory", "Clean-DataUsage", "Clean-DNSCache", "Clear-WinDefTraces", "Clean-Amcache", "Clean-WinSearch", "Clean-JumpLists", "Clean-AppSwitched", "Clean-WinTemp", "Clean-Prefetch", "Clean-Crashdumps", "Clean-Recent", "Clean-EventLog", "Clean-History", "Clean-Jornatracer", "Disable-Services", "Clean-AppcompatCache", "Clean-LastActivity", "Clean-UserAssist", "Clean-Regseeker", "Clean-BrowserHistory", "Clean-RegistryEditor", "Create-NewJournal", "Clean-Regedit", "Clean-Shellbag") | ForEach-Object {
        try { Invoke-Expression $_ } catch { Log-Action $_ "ERROR" $_.Exception.Message }
        Start-Sleep -Milliseconds 500
    }
    Log-Action "SystemOptimization" "SUCCESS" "All modules completed"
}

# ============================================
# WEB SERVER (FIXED JSON - Uses ConvertTo-Json)
# ============================================
function Start-CleanerServer {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$($Global:ServerPort)/")
    $listener.Start()

    Log-Action "Server" "SUCCESS" "Started on port $($Global:ServerPort)"

    # Auto-launch hosted UI
    if (-not $NoBrowser) {
        Start-Process $Global:HostedUI
        Log-Action "Browser" "SUCCESS" "Opened hosted UI: $($Global:HostedUI)"
    }

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.LocalPath

        try {
            if ($path -eq "/api/status") {
                $license = Check-License
                $status = @{
                    licensed = $license.Valid
                    hwid = Get-HWID
                    user = $env:USERNAME
                    computer = $env:COMPUTERNAME
                    message = $license.Message
                    oceanDetected = Test-OceanCheck
                    napseDetected = Test-NAPSE
                } | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($status)
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            elseif ($path -eq "/api/validate") {
                $reader = New-Object System.IO.StreamReader($request.InputStream)
                $body = $reader.ReadToEnd()
                $reader.Close()
                $data = $body | ConvertFrom-Json
                $result = Validate-License -Key $data.key
                $json = $result | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            elseif ($path.StartsWith("/api/")) {
                $action = $path.Replace("/api/", "")
                $funcMap = @{
                    "cleanBam" = "Clean-Bam"
                    "cleanSystemInformer" = "Clean-SystemInformer"
                    "cleanSeeShells" = "Clean-SeeShells"
                    "cleanRecentDocs" = "Clean-RecentDocs"
                    "cleanRecuva" = "Clean-Recuva"
                    "bypassEverything" = "Bypass-Everything"
                    "cleanPreviousFiles" = "Clean-PreviousFiles"
                    "cleanMuiCache" = "Clean-MuiCache"
                    "cleanArchistory" = "Clean-Archistory"
                    "cleanNvidia" = "Clean-Nvidia"
                    "cleanPsHistory" = "Clean-PSHistory"
                    "cleanDataUsage" = "Clean-DataUsage"
                    "cleanDnsCache" = "Clean-DNSCache"
                    "clearWinDef" = "Clear-WinDefTraces"
                    "cleanAmcache" = "Clean-Amcache"
                    "cleanWinSearch" = "Clean-WinSearch"
                    "cleanJumpLists" = "Clean-JumpLists"
                    "cleanAppSwitched" = "Clean-AppSwitched"
                    "cleanWinTemp" = "Clean-WinTemp"
                    "cleanPrefetch" = "Clean-Prefetch"
                    "cleanCrashdumps" = "Clean-Crashdumps"
                    "cleanRecent" = "Clean-Recent"
                    "cleanEventLog" = "Clean-EventLog"
                    "cleanHistory" = "Clean-History"
                    "cleanJornatracer" = "Clean-Jornatracer"
                    "disableServices" = "Disable-Services"
                    "cleanAppcompat" = "Clean-AppcompatCache"
                    "cleanLastActivity" = "Clean-LastActivity"
                    "cleanUserAssist" = "Clean-UserAssist"
                    "cleanRegseeker" = "Clean-Regseeker"
                    "cleanBrowserHistory" = "Clean-BrowserHistory"
                    "cleanRegistryEditor" = "Clean-RegistryEditor"
                    "createNewJournal" = "Create-NewJournal"
                    "cleanRegedit" = "Clean-Regedit"
                    "cleanShellbag" = "Clean-Shellbag"
                    "systemOptimization" = "Start-SystemOptimization"
                }
                $func = $funcMap[$action]

                # Check license before executing
                $license = Check-License
                if (-not $license.Valid) {
                    $result = @{ success = $false; error = "License invalid or not activated"; needsLicense = $true } | ConvertTo-Json
                } else {
                    try {
                        Invoke-Expression $func
                        $result = @{ success = $true; message = "Operation completed" } | ConvertTo-Json
                    } catch {
                        $result = @{ success = $false; error = $_.Exception.Message } | ConvertTo-Json
                    }
                }

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($result)
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            else {
                $response.StatusCode = 404
            }
        }
        catch {
            $response.StatusCode = 500
            $err = @{ error = $_.Exception.Message } | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($err)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        finally {
            $response.Close()
        }
    }
}

# ============================================
# MAIN
# ============================================
Initialize-LicenseSystem

if ($ValidateLicense) {
    $result = Validate-License -Key $LicenseKey
    Write-Output ($result | ConvertTo-Json)
    exit
}

if ($Action) {
    $funcMap = @{
        "cleanBam" = "Clean-Bam"
        "cleanSystemInformer" = "Clean-SystemInformer"
        "cleanSeeShells" = "Clean-SeeShells"
        "cleanRecentDocs" = "Clean-RecentDocs"
        "cleanRecuva" = "Clean-Recuva"
        "bypassEverything" = "Bypass-Everything"
        "cleanPreviousFiles" = "Clean-PreviousFiles"
        "cleanMuiCache" = "Clean-MuiCache"
        "cleanArchistory" = "Clean-Archistory"
        "cleanNvidia" = "Clean-Nvidia"
        "cleanPsHistory" = "Clean-PSHistory"
        "cleanDataUsage" = "Clean-DataUsage"
        "cleanDnsCache" = "Clean-DNSCache"
        "clearWinDef" = "Clear-WinDefTraces"
        "cleanAmcache" = "Clean-Amcache"
        "cleanWinSearch" = "Clean-WinSearch"
        "cleanJumpLists" = "Clean-JumpLists"
        "cleanAppSwitched" = "Clean-AppSwitched"
        "cleanWinTemp" = "Clean-WinTemp"
        "cleanPrefetch" = "Clean-Prefetch"
        "cleanCrashdumps" = "Clean-Crashdumps"
        "cleanRecent" = "Clean-Recent"
        "cleanEventLog" = "Clean-EventLog"
        "cleanHistory" = "Clean-History"
        "cleanJornatracer" = "Clean-Jornatracer"
        "disableServices" = "Disable-Services"
        "cleanAppcompat" = "Clean-AppcompatCache"
        "cleanLastActivity" = "Clean-LastActivity"
        "cleanUserAssist" = "Clean-UserAssist"
        "cleanRegseeker" = "Clean-Regseeker"
        "cleanBrowserHistory" = "Clean-BrowserHistory"
        "cleanRegistryEditor" = "Clean-RegistryEditor"
        "createNewJournal" = "Create-NewJournal"
        "cleanRegedit" = "Clean-Regedit"
        "cleanShellbag" = "Clean-Shellbag"
        "systemOptimization" = "Start-SystemOptimization"
    }
    $func = $funcMap[$Action]
    if ($func) { Invoke-Expression $func }
    else { Log-Action "CLI" "ERROR" "Unknown action: $Action"; exit 1 }
} else {
    Log-Action "Startup" "SUCCESS" "xXx Cleaner Engine Started | Ocean Check: $(Test-OceanCheck) | NAPSE: $(Test-NAPSE)"
    Start-CleanerServer
}
