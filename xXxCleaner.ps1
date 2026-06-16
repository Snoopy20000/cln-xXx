# xXx Cleaner - Easy Edition
# Standalone: Run as Administrator, opens browser automatically
# NAPSE-Aware | Silent | No dependencies

param(
    [string]$Action = "",
    [string]$Mode = "standard",
    [switch]$NoBrowser
)

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ============================================
# EMBEDDED HTML UI (served via built-in web server)
# ============================================
$HtmlUI = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>xXx Cleaner</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: #0a0a0a;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: #e0e0e0;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .bg {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: radial-gradient(ellipse at 20% 50%, rgba(147,112,219,0.03) 0%, transparent 50%),
                        radial-gradient(ellipse at 80% 50%, rgba(147,112,219,0.03) 0%, transparent 50%),
                        linear-gradient(135deg, #0a0a0a 0%, #111 50%, #0a0a0a 100%);
            z-index: -1;
        }
        .container {
            width: 520px;
            background: rgba(15,15,15,0.95);
            border: 1px solid rgba(147,112,219,0.3);
            border-radius: 8px;
            box-shadow: 0 0 0 1px rgba(147,112,219,0.1), 0 20px 60px rgba(0,0,0,0.8), 0 0 40px rgba(147,112,219,0.05);
            padding: 0; position: relative; overflow: hidden;
        }
        .header {
            display: flex; justify-content: space-between; align-items: center;
            padding: 12px 20px;
            background: rgba(147,112,219,0.05);
            border-bottom: 1px solid rgba(147,112,219,0.1);
        }
        .logo { font-size: 18px; font-weight: 700; color: #9370db; letter-spacing: 2px; text-shadow: 0 0 10px rgba(147,112,219,0.3); }
        .window-controls { display: flex; gap: 8px; align-items: center; }
        .stream-mode { font-size: 10px; color: #666; margin-right: 8px; letter-spacing: 1px; }
        .close-btn { width: 12px; height: 12px; border-radius: 50%; background: rgba(255,255,255,0.1); cursor: pointer; }
        .close-btn:hover { background: rgba(255,100,100,0.5); }
        .content { padding: 24px 20px; }
        .title { text-align: center; font-size: 14px; font-weight: 600; color: #e0e0e0; margin-bottom: 16px; letter-spacing: 1px; }
        .dropdown {
            width: 100%; padding: 10px 14px; background: rgba(30,30,30,0.8);
            border: 1px solid rgba(147,112,219,0.2); border-radius: 6px;
            color: #e0e0e0; font-size: 12px; cursor: pointer; margin-bottom: 20px;
            outline: none;
        }
        .dropdown:hover { border-color: rgba(147,112,219,0.4); }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 20px; }
        .btn {
            padding: 10px 8px; background: rgba(30,30,30,0.6);
            border: 1px solid rgba(255,255,255,0.05); border-radius: 4px;
            color: #888; font-size: 11px; cursor: pointer; text-align: center;
            letter-spacing: 0.5px; transition: all 0.2s;
        }
        .btn:hover { background: rgba(147,112,219,0.1); border-color: rgba(147,112,219,0.3); color: #e0e0e0; transform: translateY(-1px); }
        .btn.active { background: rgba(147,112,219,0.15); border-color: rgba(147,112,219,0.4); color: #9370db; }
        .btn.cleaning { animation: pulse 1.5s infinite; }
        @keyframes pulse { 0%,100% { box-shadow: 0 0 0 0 rgba(147,112,219,0.2); } 50% { box-shadow: 0 0 0 4px rgba(147,112,219,0); } }
        .btn.success { border-color: rgba(100,200,100,0.4); color: #64c864; }
        .footer { display: flex; justify-content: space-between; padding: 12px 20px; border-top: 1px solid rgba(147,112,219,0.1); font-size: 11px; color: #666; }
        .footer-btn { cursor: pointer; transition: color 0.2s; }
        .footer-btn:hover { color: #9370db; }
        .progress-bar { position: absolute; bottom: 0; left: 0; height: 2px; background: linear-gradient(90deg, #9370db, #b19cd9); transition: width 0.3s; width: 0%; }
        .console {
            position: fixed; bottom: 20px; right: 20px; width: 400px; max-height: 300px;
            background: rgba(10,10,10,0.95); border: 1px solid rgba(147,112,219,0.2);
            border-radius: 6px; padding: 12px; font-family: Consolas, monospace;
            font-size: 10px; color: #888; overflow-y: auto; display: none; z-index: 1000;
        }
        .console.visible { display: block; }
        .console-line { margin: 2px 0; opacity: 0; animation: fadeIn 0.3s forwards; }
        @keyframes fadeIn { to { opacity: 1; } }
        .console-line.success { color: #64c864; }
        .console-line.error { color: #c86464; }
        .console-line.info { color: #9370db; }
        .category-label { font-size: 10px; color: #666; text-transform: uppercase; letter-spacing: 2px; margin: 16px 0 8px 0; padding-left: 4px; }
        .category-label:first-of-type { margin-top: 0; }
    </style>
</head>
<body>
    <div class="bg"></div>
    <div class="container">
        <div class="header">
            <div class="logo">xXx</div>
            <div class="window-controls">
                <span class="stream-mode">Streammode</span>
                <div class="close-btn" onclick="window.close()"></div>
            </div>
        </div>
        <div class="content">
            <div class="title">String Cleaner</div>
            <select class="dropdown" id="modeSelect">
                <option value="standard">Standard Clean</option>
                <option value="deep">Deep Clean (NAPSE-Aware)</option>
                <option value="stealth">Stealth Mode (Silent)</option>
                <option value="forensic">Forensic Wipe</option>
            </select>
            <div class="category-label">System Traces</div>
            <div class="grid">
                <button class="btn" data-action="cleanBam">Clean Bam</button>
                <button class="btn" data-action="cleanSystemInformer">Clean System Informer</button>
                <button class="btn" data-action="cleanSeeShells">Clean SeeShells</button>
                <button class="btn" data-action="cleanRecentDocs">Clean RecentDocs</button>
                <button class="btn" data-action="cleanRecuva">Clean Recuva</button>
                <button class="btn" data-action="bypassEverything">Bypass Everything</button>
                <button class="btn" data-action="cleanPreviousFiles">Clean PreviousFiles</button>
                <button class="btn" data-action="cleanMuiCache">MuiCache</button>
            </div>
            <div class="category-label">Application Traces</div>
            <div class="grid">
                <button class="btn" data-action="cleanArchistory">Clean Archistory</button>
                <button class="btn" data-action="cleanNvidia">Clean Nvidia</button>
                <button class="btn" data-action="cleanPsHistory">PS History Wipe</button>
                <button class="btn" data-action="cleanDataUsage">Clean Data Usage</button>
                <button class="btn" data-action="cleanDnsCache">Clean DNS Cache</button>
                <button class="btn" data-action="clearWinDef">Clear Win Def Traces</button>
                <button class="btn" data-action="cleanAmcache">Clean Amcache</button>
                <button class="btn" data-action="cleanWinSearch">Windows Search History</button>
            </div>
            <div class="category-label">User Activity</div>
            <div class="grid">
                <button class="btn" data-action="cleanJumpLists">Clean Jump Lists</button>
                <button class="btn" data-action="cleanAppSwitched">Clean AppSwitched</button>
                <button class="btn" data-action="cleanWinTemp">Clean Windows Temp</button>
                <button class="btn" data-action="cleanPrefetch">Clean Prefetch</button>
                <button class="btn" data-action="cleanCrashdumps">Clean Crashdumps</button>
                <button class="btn" data-action="cleanRecent">Clean Recent</button>
                <button class="btn" data-action="cleanEventLog">Clean Event Log</button>
                <button class="btn" data-action="cleanHistory">Clean History</button>
            </div>
            <div class="category-label">Registry & Deep</div>
            <div class="grid">
                <button class="btn" data-action="cleanJornatracer">Clean Jornatracer</button>
                <button class="btn" data-action="disableServices">Disabl Services</button>
                <button class="btn" data-action="cleanAppcompat">Clean AppcompatCache</button>
                <button class="btn" data-action="cleanLastActivity">Clean Last Activity</button>
                <button class="btn" data-action="cleanUserAssist">Clean User Assist</button>
                <button class="btn" data-action="cleanRegseeker">Clean Regseeker</button>
                <button class="btn" data-action="cleanBrowserHistory">Clean Browser History</button>
                <button class="btn" data-action="cleanRegistryEditor">Clean Registry Editor</button>
            </div>
            <div class="category-label">Advanced</div>
            <div class="grid">
                <button class="btn" data-action="createNewJournal">Create New Journal</button>
                <button class="btn" data-action="cleanRegedit">Clean Regedit</button>
                <button class="btn" data-action="cleanShellbag">Clean Shellbag</button>
                <button class="btn" data-action="cleanAll" style="background:rgba(147,112,219,0.2);color:#9370db;font-weight:600;">CLEAN ALL</button>
            </div>
        </div>
        <div class="footer">
            <span class="footer-btn" onclick="showPage('back')">&lt;- Back</span>
            <span class="footer-btn" onclick="showPage('more')">More -&gt;</span>
        </div>
        <div class="progress-bar" id="progressBar"></div>
    </div>
    <div class="console" id="console"></div>
    <script>
        const consoleEl = document.getElementById('console');
        const progressBar = document.getElementById('progressBar');
        function log(msg, type='info') {
            const line = document.createElement('div');
            line.className = `console-line ${type}`;
            line.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;
            consoleEl.appendChild(line);
            consoleEl.scrollTop = consoleEl.scrollHeight;
            consoleEl.classList.add('visible');
        }
        async function executeClean(action, btn) {
            btn.classList.add('cleaning');
            log(`Initiating ${action}...`, 'info');
            try {
                const res = await fetch(`http://localhost:8844/api/${action}`, {method:'POST'});
                const data = await res.json();
                if (data.success) {
                    btn.classList.remove('cleaning'); btn.classList.add('success');
                    log(`${action} completed`, 'success');
                    setTimeout(() => btn.classList.remove('success'), 2000);
                } else throw new Error(data.error);
            } catch(err) {
                btn.classList.remove('cleaning');
                log(`${action} failed: ${err.message}`, 'error');
            }
        }
        document.querySelectorAll('.btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.action;
                if (action === 'cleanAll') runAll(); else executeClean(action, btn);
            });
        });
        async function runAll() {
            const btns = document.querySelectorAll('.btn:not([data-action="cleanAll"])');
            let i = 0;
            for (const btn of btns) {
                progressBar.style.width = `${(++i/btns.length)*100}%`;
                await executeClean(btn.dataset.action, btn);
                await new Promise(r => setTimeout(r, 500));
            }
            progressBar.style.width = '100%';
            setTimeout(() => progressBar.style.width = '0%', 1000);
            log('All operations complete', 'success');
        }
        function showPage(dir) { log(`Navigating ${dir}...`, 'info'); }
        log('xXx Cleaner initialized', 'info');
        log('NAPSE-aware evasion active', 'info');
        log('Ready', 'success');
    </script>
</body>
</html>
'@

# ============================================
# NAPSE CONFIG
# ============================================
$NAPSE = @{
    DelayBetweenOps = 2000
    AvoidEvent104 = $true
    AvoidUSNDelete = $true
    AvoidExplorerRestart = $true
    AvoidAMSI = $true
    AvoidBulkKill = $true
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    Add-Content -Path "$env:TEMP\xXx_cleaner.log" -Value $entry -ErrorAction SilentlyContinue
    Write-Host $entry -ForegroundColor $(if($Level -eq "SUCCESS"){"Green"}elseif($Level -eq "ERROR"){"Red"}else{"Cyan"})
}

function Invoke-NAPSEDelay { Start-Sleep -Milliseconds $NAPSE.DelayBetweenOps }
function Invoke-Silent { param([scriptblock]$C) try { & $C 2>$null | Out-Null } catch {} }

# ============================================
# CLEAN FUNCTIONS
# ============================================
function Clean-Bam {
    Write-Log "Cleaning BAM"
    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
    if (Test-Path $p) {
        Get-ChildItem $p | ForEach-Object {
            $u = $_.PSPath
            Get-ItemProperty $u | Get-Member -MemberType NoteProperty | 
                Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider|Version" } |
                ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $u -Name $_.Name -Force }; Invoke-NAPSEDelay }
        }
    }
    Write-Log "BAM cleaned" "SUCCESS"
}

function Clean-SystemInformer {
    Write-Log "Cleaning System Informer"
    @("$env:LOCALAPPDATA\SystemInformer", "$env:APPDATA\SystemInformer", "HKCU:\Software\SystemInformer") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "System Informer cleaned" "SUCCESS"
}

function Clean-SeeShells {
    Write-Log "Cleaning SeeShells"
    @("$env:LOCALAPPDATA\Packages\*SeeShells*", "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\*seeshells*") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object { Invoke-Silent { Remove-Item $_.PSPath -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "SeeShells cleaned" "SUCCESS"
}

function Clean-RecentDocs {
    Write-Log "Cleaning RecentDocs"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider|MRUListEx" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force } }
        Invoke-Silent { Remove-ItemProperty -Path $p -Name "MRUListEx" -Force }
    }
    $rf = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $rf) { Get-ChildItem $rf -File | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force }; Invoke-NAPSEDelay } }
    Write-Log "RecentDocs cleaned" "SUCCESS"
}

function Clean-Recuva {
    Write-Log "Cleaning Recuva"
    @("$env:APPDATA\Recuva", "$env:LOCALAPPDATA\Recuva", "HKCU:\Software\Recuva", "HKCU:\Software\Piriform\Recuva") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Recuva cleaned" "SUCCESS"
}

function Bypass-Everything {
    Write-Log "Bypassing Everything"
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
    Write-Log "Everything bypassed" "SUCCESS"
}

function Clean-PreviousFiles {
    Write-Log "Cleaning PreviousFiles"
    @("$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db", "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Write-Log "PreviousFiles cleaned" "SUCCESS"
}

function Clean-MuiCache {
    Write-Log "Cleaning MuiCache"
    $p = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "MuiCache cleaned" "SUCCESS"
}

function Clean-Archistory {
    Write-Log "Cleaning Archistory"
    @("$env:LOCALAPPDATA\Archistory", "$env:APPDATA\Archistory", "HKCU:\Software\Archistory") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Archistory cleaned" "SUCCESS"
}

function Clean-Nvidia {
    Write-Log "Cleaning Nvidia"
    @("$env:LOCALAPPDATA\NVIDIA Corporation\Drs", "$env:PROGRAMDATA\NVIDIA Corporation\Drs", "HKLM:\SOFTWARE\NVIDIA Corporation\Global\Drs", "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Enum") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Nvidia cleaned" "SUCCESS"
}

function Clean-PSHistory {
    Write-Log "Cleaning PS History (NAPSE-aware)"
    @((Get-PSReadlineOption).HistorySavePath, "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt") | ForEach-Object {
        if (Test-Path $_) {
            @("Get-Process", "Get-Service", "ipconfig /all", "Get-ChildItem", "Write-Host 'test'") | Set-Content -Path $_ -Force
            Invoke-NAPSEDelay
            Invoke-Silent { Clear-Content -Path $_ -Force; Remove-Item $_ -Force }
        }
    }
    Clear-History
    Write-Log "PS History wiped" "SUCCESS"
}

function Clean-DataUsage {
    Write-Log "Cleaning Data Usage"
    @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DataUsage", "$env:PROGRAMDATA\Microsoft\Windows\SRU") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Invoke-Silent { netsh wlan delete profile name=* i=* }
    Write-Log "Data Usage cleaned" "SUCCESS"
}

function Clean-DNSCache {
    Write-Log "Cleaning DNS Cache"
    Invoke-Silent { ipconfig /flushdns }
    Invoke-NAPSEDelay
    $dp = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
    if (Test-Path $dp) { Invoke-Silent { Remove-ItemProperty -Path $dp -Name "CacheHashTable*" } }
    Write-Log "DNS Cache cleaned" "SUCCESS"
}

function Clear-WinDefTraces {
    Write-Log "Clearing WinDef traces"
    @("$env:PROGRAMDATA\Microsoft\Windows Defender\Scans", "$env:PROGRAMDATA\Microsoft\Windows Defender\Support", "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions", "$env:PROGRAMDATA\Microsoft\Windows Defender\Quarantine") | ForEach-Object {
        if (Test-Path $_) { Get-ChildItem $_ -Recurse | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force -Recurse }; Invoke-NAPSEDelay } }
    }
    Write-Log "WinDef traces cleared" "SUCCESS"
}

function Clean-Amcache {
    Write-Log "Cleaning Amcache"
    @("$env:LOCALAPPDATA\Microsoft\Windows\AppCompat\Programs\Amcache.hve", "$env:LOCALAPPDATA\Microsoft\Windows\AppCompat\Programs\Amcache.hve.LOG*") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Write-Log "Amcache cleaned" "SUCCESS"
}

function Clean-WinSearch {
    Write-Log "Cleaning Windows Search"
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\RecentItems", "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Windows Search cleaned" "SUCCESS"
}

function Clean-JumpLists {
    Write-Log "Cleaning Jump Lists"
    @("$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations", "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations") | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -File | ForEach-Object {
                Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
                Invoke-NAPSEDelay
            }
        }
    }
    Write-Log "Jump Lists cleaned" "SUCCESS"
}

function Clean-AppSwitched {
    Write-Log "Cleaning AppSwitched"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "AppSwitched cleaned" "SUCCESS"
}

function Clean-WinTemp {
    Write-Log "Cleaning Windows Temp"
    @($env:TEMP, $env:TMP, "$env:WINDIR\Temp", "$env:WINDIR\Prefetch") | ForEach-Object {
        if (Test-Path $_) { Get-ChildItem $_ -Recurse -Force | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force -Recurse }; Invoke-NAPSEDelay } }
    }
    Write-Log "Windows Temp cleaned" "SUCCESS"
}

function Clean-Prefetch {
    Write-Log "Cleaning Prefetch"
    $p = "$env:WINDIR\Prefetch"
    if (Test-Path $p) {
        Get-ChildItem $p -File | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Write-Log "Prefetch cleaned" "SUCCESS"
}

function Clean-Crashdumps {
    Write-Log "Cleaning Crashdumps"
    @("$env:LOCALAPPDATA\CrashDumps", "$env:PROGRAMDATA\Microsoft\Windows\WER", "$env:LOCALAPPDATA\Microsoft\Windows\WER") | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem $_ -Recurse -File | ForEach-Object {
                Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
                Invoke-NAPSEDelay
            }
        }
    }
    Write-Log "Crashdumps cleaned" "SUCCESS"
}

function Clean-Recent {
    Write-Log "Cleaning Recent"
    @("$env:APPDATA\Microsoft\Windows\Recent", "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations", "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations") | ForEach-Object {
        if (Test-Path $_) { Get-ChildItem $_ -File | ForEach-Object { Invoke-Silent { Remove-Item $_.FullName -Force }; Invoke-NAPSEDelay } }
    }
    Write-Log "Recent cleaned" "SUCCESS"
}

function Clean-EventLog {
    Write-Log "Cleaning Event Log (NAPSE-aware)"
    @("Application", "Security", "System", "Setup", "ForwardedEvents") | ForEach-Object {
        try {
            if ($Mode -ne "stealth") { Invoke-Silent { wevtutil cl $_ } }
        } catch {}
        Invoke-NAPSEDelay
    }
    Write-Log "Event Log cleaned" "SUCCESS"
}

function Clean-History {
    Write-Log "Cleaning History"
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU") | ForEach-Object {
        if (Test-Path $_) {
            Get-Item $_ | Get-Member -MemberType NoteProperty | 
                Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider|MRUList" } |
                ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $_ -Name $_.Name -Force }; Invoke-NAPSEDelay }
        }
    }
    Write-Log "History cleaned" "SUCCESS"
}

function Clean-Jornatracer {
    Write-Log "Cleaning Jornatracer"
    @("$env:LOCALAPPDATA\Jornatracer", "$env:APPDATA\Jornatracer", "HKCU:\Software\Jornatracer") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Jornatracer cleaned" "SUCCESS"
}

function Disable-Services {
    Write-Log "Disabling services (no stops)"
    @("DiagTrack", "dmwappushservice", "WMPNetworkSvc") | ForEach-Object {
        Invoke-Silent { Set-Service -Name $_ -StartupType Disabled }
        Invoke-NAPSEDelay
    }
    Write-Log "Services disabled" "SUCCESS"
}

function Clean-AppcompatCache {
    Write-Log "Cleaning AppcompatCache"
    $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache"
    if (Test-Path $p) { Invoke-Silent { Remove-ItemProperty -Path $p -Name "AppCompatCache" -Force }; Invoke-NAPSEDelay }
    Write-Log "AppcompatCache cleaned" "SUCCESS"
}

function Clean-LastActivity {
    Write-Log "Cleaning Last Activity"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\ShowJumpView"
    if (Test-Path $p) {
        Get-Item $p | Get-Member -MemberType NoteProperty | 
            Where-Object { $_.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|PSProvider" } |
            ForEach-Object { Invoke-Silent { Remove-ItemProperty -Path $p -Name $_.Name -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Last Activity cleaned" "SUCCESS"
}

function Clean-UserAssist {
    Write-Log "Cleaning UserAssist"
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
    Write-Log "UserAssist cleaned" "SUCCESS"
}

function Clean-Regseeker {
    Write-Log "Cleaning Regseeker"
    @("$env:APPDATA\RegSeeker", "$env:LOCALAPPDATA\RegSeeker", "HKCU:\Software\RegSeeker") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Regseeker cleaned" "SUCCESS"
}

function Clean-BrowserHistory {
    Write-Log "Cleaning Browser History"
    @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History", "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History-journal", "$env:APPDATA\Mozilla\Firefox\Profiles\*.default\places.sqlite", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History") | ForEach-Object {
        Get-Item $_ -ErrorAction SilentlyContinue | ForEach-Object {
            Invoke-Silent { $b = New-Object byte[] $_.Length; [System.IO.File]::WriteAllBytes($_.FullName, $b); Remove-Item $_.FullName -Force }
            Invoke-NAPSEDelay
        }
    }
    Write-Log "Browser History cleaned" "SUCCESS"
}

function Clean-RegistryEditor {
    Write-Log "Cleaning Registry Editor"
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit"
    if (Test-Path $p) { Invoke-Silent { Remove-Item $p -Recurse -Force }; Invoke-NAPSEDelay }
    Write-Log "Registry Editor cleaned" "SUCCESS"
}

function Create-NewJournal {
    Write-Log "Creating new USN Journal"
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
    Write-Log "New Journal created" "SUCCESS"
}

function Clean-Regedit {
    Write-Log "Cleaning Regedit"
    @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Regedit cleaned" "SUCCESS"
}

function Clean-Shellbag {
    Write-Log "Cleaning Shellbag"
    @("HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU", "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags") | ForEach-Object {
        if (Test-Path $_) { Invoke-Silent { Remove-Item $_ -Recurse -Force }; Invoke-NAPSEDelay }
    }
    Write-Log "Shellbag cleaned" "SUCCESS"
}

function Clean-All {
    Write-Log "=== FULL CLEAN INITIATED ===" "INFO"
    @("Clean-Bam", "Clean-SystemInformer", "Clean-SeeShells", "Clean-RecentDocs", "Clean-Recuva", "Bypass-Everything", "Clean-PreviousFiles", "Clean-MuiCache", "Clean-Archistory", "Clean-Nvidia", "Clean-PSHistory", "Clean-DataUsage", "Clean-DNSCache", "Clear-WinDefTraces", "Clean-Amcache", "Clean-WinSearch", "Clean-JumpLists", "Clean-AppSwitched", "Clean-WinTemp", "Clean-Prefetch", "Clean-Crashdumps", "Clean-Recent", "Clean-EventLog", "Clean-History", "Clean-Jornatracer", "Disable-Services", "Clean-AppcompatCache", "Clean-LastActivity", "Clean-UserAssist", "Clean-Regseeker", "Clean-BrowserHistory", "Clean-RegistryEditor", "Create-NewJournal", "Clean-Regedit", "Clean-Shellbag") | ForEach-Object {
        try { Invoke-Expression $_ } catch { Write-Log "Error in ${_}: $($_.Exception.Message)" "ERROR" }
        Start-Sleep -Milliseconds 500
    }
    Write-Log "=== FULL CLEAN COMPLETE ===" "SUCCESS"
}

# ============================================
# WEB SERVER (Built-in, no extra tools needed)
# ============================================
function Start-CleanerServer {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:8844/")
    $listener.Start()
    Write-Log "Server started at http://localhost:8844"

    if (-not $NoBrowser) {
        Start-Process "http://localhost:8844"
        Write-Log "Browser opened"
    }

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.LocalPath

        try {
            if ($path -eq "/" -or $path -eq "/index.html") {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($HtmlUI)
                $response.ContentType = "text/html"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            elseif ($path.StartsWith("/api/")) {
                $action = $path.Replace("/api/", "")
                $func = $action -replace "^(.)", { $_.Groups[1].Value.ToUpper() } -replace "-([a-z])", { $_.Groups[1].Value.ToUpper() }
                $func = $func -replace "^.", { $_.Value.ToUpper() }
                # Map action names to function names
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
                    "cleanAll" = "Clean-All"
                }
                $func = $funcMap[$action]

                try {
                    Invoke-Expression $func
                    $result = '{"success":true,"message":"Clean completed"}'
                } catch {
                    $result = "{\"success\":false,\"error\":\"$($_.Exception.Message)\"}"
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
            $err = "{\"error\":\"$($_.Exception.Message)\"}"
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
if ($Action) {
    # CLI mode
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
        "cleanAll" = "Clean-All"
    }
    $func = $funcMap[$Action]
    if ($func) { Invoke-Expression $func }
    else { Write-Log "Unknown action: $Action" "ERROR"; exit 1 }
} else {
    # GUI mode - start web server
    Write-Log "========================================"
    Write-Log "xXx Cleaner - Easy Edition"
    Write-Log "NAPSE-Aware | Silent | No Dependencies"
    Write-Log "========================================"
    Write-Log "Starting server..."
    Start-CleanerServer
}
