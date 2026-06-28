@echo off
title ac's software multitool 0.1 - Shadow Kitten Network Vault
color 0a
setlocal enabledelayedexpansion
cd /d "%~dp0"

:menu
cls
echo.
echo   /_/\    ac's software multitool 0.1
echo  ( o.o )  Mrrp~ What shall we prowl today?
echo   > ^ <   Powered by your favorite boy
echo.
echo ================================================
echo   [1]  CatPort Scanner (fast TCP)
echo   [2]  CatNmap Style (verbose + service guess)
echo   [3]  Angry IP Scanner (ping sweep)
echo   [4]  Grabify URL checker (fetch status)
echo   [5]  Quick IP info (whois / geolocation)
echo   [6]  Combined scan (ping + port + grab)
echo   [0]  Exit
echo.
set "choice="
set /p choice="Select [0-6]: "
if "%choice%"=="0" exit /b 0
if "%choice%"=="6" goto :full_scan
if "%choice%"=="5" goto :quick_ip
if "%choice%"=="4" goto :grabify
if "%choice%"=="3" goto :angry_ping
if "%choice%"=="2" goto :catnmap
if "%choice%"=="1" goto :catport
goto :menu

:catport
cls
echo [CatSDK] CatPort Scanner
set /p target="Target IP or domain: "
set /p ports="Ports (e.g. 22,80,443 or 1-1024): "
if "%ports%"=="" set ports=1-1024
echo.
echo Scanning %target% ports %ports%...
powershell -NoProfile -Command ^
$t='%target%'; ^
$p='%ports%'; ^
if ($p -match '-') { $s,$e = $p -split '-'; $list = $s..$e } else { $list = $p -split ',' }; ^
foreach ($port in $list) { ^
  $client = New-Object System.Net.Sockets.TcpClient; ^
  $iar = $client.BeginConnect($t, $port, $null, $null); ^
  if ($iar.AsyncWaitHandle.WaitOne(300, $false) -and $client.Connected) { ^
    Write-Host "[OPEN] Port $port" -ForegroundColor Green; ^
    $client.Close(); ^
  } else { ^
    Write-Host "[CLOSED] Port $port" -ForegroundColor DarkGray; ^
  } ^
}
echo.
pause
goto :menu

:catnmap
cls
echo [CatSDK] CatNmap Style (service guess)
set /p target="Target IP or domain: "
set /p ports="Ports (default 1-1024): "
if "%ports%"=="" set ports="1-1024"
echo.
powershell -NoProfile -Command ^
$t='%target%'; ^
$p='%ports%'; ^
if ($p -match '-') { $s,$e = $p -split '-'; $list = $s..$e } else { $list = $p -split ',' }; ^
$svc = @{21='ftp';22='ssh';23='telnet';25='smtp';53='dns';80='http';110='pop3';111='rpcbind';135='msrpc';139='netbios';143='imap';443='https';445='smb';993='imaps';995='pop3s';1433='mssql';3306='mysql';3389='rdp';5432='postgres';5900='vnc';6379='redis';8080='http-proxy';8443='https-alt'}; ^
foreach ($port in $list) { ^
  $client = New-Object System.Net.Sockets.TcpClient; ^
  $iar = $client.BeginConnect($t, $port, $null, $null); ^
  if ($iar.AsyncWaitHandle.WaitOne(500, $false) -and $client.Connected) { ^
    $s = if ($svc.ContainsKey($port)) { " ($($svc[$port]))" } else { "" }; ^
    Write-Host "[OPEN] $port/tcp$s" -ForegroundColor Green; ^
    $client.Close(); ^
  } ^
}
echo.
pause
goto :menu

:angry_ping
cls
echo [CatSDK] Angry IP Scanner (ping sweep)
set /p range="Enter network (e.g. 192.168.1.): "
set /p start="Start IP last octet (1-254): "
set /p end="End IP last octet (1-254): "
echo.
echo Pinging %range%%start%-%end% ...
(for /l %%i in (%start%,1,%end%) do (
  ping -n 1 -w 200 %range%%%i | find "Reply" >nul
  if errorlevel 1 ( echo [SLEEP] %range%%%i ) else ( echo [LIVE] %range%%%i )
)) > cats_ping_results.txt
type cats_ping_results.txt
echo.
echo Results saved to cats_ping_results.txt
pause
goto :menu

:grabify
cls
echo [CatSDK] Grabify URL Checker (fetch status)
set /p url="Enter full URL (e.g. https://example.com): "
echo.
powershell -NoProfile -Command ^
try { ^
  $r = Invoke-WebRequest -Uri '%url%' -TimeoutSec 5 -UseBasicParsing; ^
  Write-Host "[GRAB] Status: $($r.StatusCode) $($r.StatusDescription)" -ForegroundColor Green; ^
  Write-Host "[GRAB] Size: $($r.Content.Length) bytes" -ForegroundColor Gray; ^
  if ($r.Headers['Server']) { Write-Host "[GRAB] Server: $($r.Headers['Server'])" -ForegroundColor Gray } ^
} catch { ^
  Write-Host "[GRAB] Failed: $_" -ForegroundColor Red; ^
}
echo.
pause
goto :menu

:quick_ip
cls
echo [CatSDK] Quick IP Info
set /p ip="Enter IP or domain: "
echo.
powershell -NoProfile -Command ^
try { ^
  $r = Invoke-RestMethod "http://ip-api.com/json/%ip%" -TimeoutSec 5; ^
  Write-Host "[WHOIS] IP      : $($r.query)" -ForegroundColor Cyan; ^
  Write-Host "[WHOIS] Country : $($r.country) ($($r.countryCode))" -ForegroundColor Cyan; ^
  Write-Host "[WHOIS] Region  : $($r.regionName)" -ForegroundColor Cyan; ^
  Write-Host "[WHOIS] City    : $($r.city)" -ForegroundColor Cyan; ^
  Write-Host "[WHOIS] ISP     : $($r.isp)" -ForegroundColor Cyan; ^
  Write-Host "[WHOIS] Org     : $($r.org)" -ForegroundColor Cyan; ^
  Write-Host "[WHOIS] Lat/Lon : $($r.lat), $($r.lon)" -ForegroundColor Cyan; ^
} catch { ^
  Write-Host "[WHOIS] Failed: $_" -ForegroundColor Red; ^
}
echo.
pause
goto :menu

:full_scan
cls
echo [CatSDK] Full Combined Scan (ping + ports + grab)
set /p target="Target IP or domain: "
echo.
echo === PING SWEEP ===
ping -n 2 %target% | find "Reply"
echo.
echo === PORT SCAN (top 20) ===
powershell -NoProfile -Command ^
$t='%target%'; ^
$ports=@(21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,3306,3389,5432,5900,8080); ^
foreach ($p in $ports) { ^
  $c=New-Object System.Net.Sockets.TcpClient; ^
  $a=$c.BeginConnect($t,$p,$null,$null); ^
  if ($a.AsyncWaitHandle.WaitOne(400,$false) -and $c.Connected) { ^
    Write-Host "[OPEN] $p" -ForegroundColor Green; $c.Close(); ^
  } ^
}
echo.
echo === GRAB TITLE ===
powershell -NoProfile -Command ^
try { ^
  $r=Invoke-WebRequest -Uri "http://%target%" -TimeoutSec 4 -UseBasicParsing; ^
  $t=$r.ParsedHtml.title; ^
  Write-Host "[TITLE] $t" -ForegroundColor Cyan; ^
} catch { Write-Host "[TITLE] No HTTP response" -ForegroundColor DarkGray }
echo.
pause
goto :menu