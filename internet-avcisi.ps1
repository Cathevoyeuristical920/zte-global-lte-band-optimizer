# ============================================================================
#  Internet Avcisi - LTE Band Optimizer (Global) - PowerShell Edition
#  Created by: Kaan (wilsonbia7)
#  PowerShell conversion for native Windows support (no Git Bash/WSL needed)
#
#  Usage:
#    .\internet-avcisi.ps1                  # Test all bands, pick the best
#    .\internet-avcisi.ps1 --set 3          # Switch to Band 3
#    .\internet-avcisi.ps1 --status         # Show signal + gaming stats
#    .\internet-avcisi.ps1 --auto           # Return to automatic mode
#    .\internet-avcisi.ps1 --watch          # Monitor and re-optimize if needed
#    .\internet-avcisi.ps1 --servers        # Show test servers
#    .\internet-avcisi.ps1 --help           # Help
#
#  Requirements: Windows PowerShell 5.1+ (built-in on Windows 10/11)
#  License: MIT
# ============================================================================

param(
    [Parameter(Position=0)][string]$Action,
    [Parameter(Position=1)][string]$Param1,
    [Parameter(Position=2)][string]$Param2
)

# ======================== ENCODING & CONSOLE ========================
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { [Console]::InputEncoding  = [System.Text.Encoding]::UTF8 } catch {}
try { $null = chcp 65001 2>&1 } catch {}

# ======================== CONFIG VARIABLES ========================
$script:ConfigFile       = Join-Path $env:USERPROFILE ".lte-optimizer.conf"
$script:PingCount        = 10
$script:WaitAfterSwitch  = 15
$script:Region           = ""
$script:LangPref         = ""
$script:ModemIP          = ""
$script:ModemUser        = ""
$script:ModemPassword    = ""
$script:Modem            = ""
$script:WebSession       = $null
$script:RD0              = ""
$script:RD1              = ""
$script:WeightAvgPing    = 40
$script:WeightJitter     = 35
$script:WeightPacketLoss = 25
$global:_spinnerMsg      = ""
$global:_spinnerFrame    = 0
$script:_spinnerTimer    = $null
$script:_spinnerEvt      = $null

# ======================== i18n - TRANSLATION SYSTEM ========================
$script:MSG_TR = @{
    "excellent"="MUKEMMEL"; "very_good"="COK IYI"; "good"="IYI"; "playable"="OYNANIR"
    "poor"="KOTU"; "stable"="STABIL"; "medium"="ORTA"; "unstable"="DENGESIZ"
    "yes_no"="[e/H]"; "waiting"="Bekleniyor"
    "setup_title"="Internet Avcisi - Kurulum Sihirbazi"
    "setup_desc1"="LTE modeminizin bantlarini test ederek oyun icin"
    "setup_desc2"="en iyi banti otomatik olarak secer."
    "setup_compat"="Uyumlu: ZTE tabanli LTE modemler (tum dunya)"
    "step_region"="Bolge secimi"; "step_gateway"="Ag gecidi algilaniyor..."
    "gw_found"="Varsayilan ag gecidi bulundu"
    "gw_hint"="Modeminizin IP adresi genellikle ag gecidinizdir."
    "modem_ip_prompt"="Modem IP adresi"
    "gw_not_found"="Ag gecidi otomatik algilanamadi."
    "enter_ip"="Modem IP adresini girin (genellikle 192.168.1.1)"
    "ip_empty"="IP adresi bos olamaz!"; "invalid_ip"="Gecersiz IP adresi formati!"
    "step_access"="Modem erisim kontrolu..."; "connecting"="baglaniliyor..."
    "modem_ok"="Modem erisime acik"; "modem_fail"="Modeme erisilemiyor"
    "reason_ip"="IP adresi yanlis olabilir"; "reason_off"="Modem kapali olabilir"
    "reason_net"="Farkli bir aga bagli olabilirsiniz (VPN, Wi-Fi vb.)"
    "continue_q"="Yine de devam etmek istiyor musunuz?"
    "check_retry"="IP adresinizi kontrol edip tekrar deneyin."
    "exiting"="Cikis yapiliyor..."
    "step_modem"="Modem tipi kontrol ediliyor..."
    "detecting_modem"="Modem tipi algilaniyor..."
    "zte_found"="ZTE modem tespit edildi - Tam uyumlu!"
    "modem_unknown"="Modem tipi tespit edilemedi."
    "zte_warn1"="Bu arac ZTE tabanli modemler icin tasarlanmistir."
    "zte_warn2"="Farkli modem kullaniyorsaniz bazi ozellikler calismayabilir."
    "step_creds"="Modem giris bilgileri"
    "creds_hint1"="Giris icin kullanici adi ve sifre gereklidir."
    "creds_hint2"="Varsayilan bilgiler modem altindaki etikette yazar."
    "creds_hint3"="Cogu ZTE modemde varsayilan kullanici adi 'admin' dir."
    "username"="Kullanici adi"; "password"="Sifre"
    "pw_hint"="(Karakterler guvenlik icin gizli kalir, yazip Enter'a basin)"
    "user_invalid"="Kullanici adi sadece harf, rakam, nokta, tire ve alt cizgi icermelidir!"
    "pw_empty"="Sifre bos olamaz!"
    "setup_done"="Kurulum tamamlandi!"; "config_saved"="Ayarlar kaydedildi"
    "pw_not_saved"="(Sifre guvenlik icin kaydedilmez, her seferinde sorulur)"
    "config_loaded"="Yapilandirma yuklendi"; "modem_pw"="Modem sifresi"
    "conn_fail"="Modeme baglanilamadi. IP ve ag baglantisini kontrol edin."
    "login_ok"="Modeme giris yapildi"
    "login_fail"="Modem girisi basarisiz (kod: {0})"
    "reason_pw"="Sifre yanlis olabilir"
    "reason_busy"="Baska biri modem paneline giris yapmis olabilir"
    "reason_restart"="Modeminizi yeniden baslatmayi deneyin"
    "status_title"="LTE Modem Oyun Durumu"; "net_type"="Ag Tipi"
    "band_label"="Bant"; "signal_label"="Sinyal"
    "server_tests"="Oyun Sunucu Testleri"; "col_server"="SUNUCU"
    "col_loss"="KAYIP"; "col_status"="DURUM"
    "no_access"="ERISIM YOK"; "no_conn"="BAGLANTI YOK"
    "opt_title"="LTE BANT OPTIMIZASYONU - OYUN MODU"
    "score_weights"="Skor agirliklari:"; "server_count"="Sunucu sayisi"
    "ping_count"="Ping sayisi"; "band_count"="Test edilecek bant"
    "testing_current"="Mevcut baglanti test ediliyor..."
    "current_pre"="Mevcut: Band"; "game_score"="Oyun Skoru"
    "lower_better"="dusuk = daha iyi"
    "testing_all"="Tum bantlar test ediliyor..."
    "col_band"="BANT"; "col_score"="SKOR"
    "switching_band"="bandina geciliyor..."
    "band_changed"="Bant degistirildi, sinyal bekleniyor..."
    "signal_stab"="Sinyal stabilize oluyor"
    "pinging"="sunucuya ping atiliyor..."
    "best_band"="Oyun icin en iyi bant"
    "switching_best"="En iyi banda geciliyor"
    "verify_wait"="Son dogrulama bekleniyor"
    "verifying"="Dogrulama testi yapiliyor..."
    "opt_done"="OPTIMIZASYON TAMAMLANDI!"
    "selected_band"="Secilen Bant"
    "done_msg"="Islem tamamlandi. Bu pencereyi kapatabilirsiniz."
    "gg"="Iyi oyunlar!"
    "no_band"="HICBIR BANT CALISMADI!"
    "auto_return"="Otomatik moda donuluyor..."
    "restart_hint"="Modeminizi yeniden baslatip tekrar deneyin."
    "close_win"="Bu pencereyi kapatabilirsiniz."
    "stability_keep"="Mevcut bant yeterince iyi, degistirilmedi"
    "verify_warn"="Dogrulama beklentinin altinda! Bant stabil olmayabilir."
    "selecting"="seciliyor..."; "activated"="aktif edildi."
    "testing_servers"="Sunucular test ediliyor..."
    "band_ready"="aktif ve hazir!"; "band_error"="Bant degisikliginde hata!"
    "invalid_band"="Gecersiz bant numarasi"
    "avail_bands"="Kullanilabilir bantlar:"
    "watch_title"="LTE Oyun Watch Modu"
    "ping_thresh"="Ping esigi"; "jitter_thresh"="Jitter esigi"
    "stop_hint"="Durdurmak icin: Ctrl+C"
    "bad_gaming"="OYUN ICIN KOTU!"
    "auto_scan"="Otomatik bant taramasi baslatiliyor..."
    "scan_done"="Tarama tamamlandi, izlemeye devam..."
    "watch_sel"="Watch: {0} secildi (Skor: {1})"
    "no_band_auto"="Hicbir bant calismadi, otomatik moda donuluyor."
    "max_retry_reached"="Ust uste 5 basarisiz deneme, 5 dk bekleniyor..."
    "cfg_reset"="Yapilandirma sifirlandi."
    "next_setup"="Sonraki calistirmada kurulum sihirbazi acilacak."
    "no_config"="Kayitli yapilandirma bulunamadi."
    "auto_ok"="Otomatik moda donuldu."
    "inet_check"="Internet baglantisi kontrol ediliyor..."
    "inet_ok"="Internet baglantisi aktif"
    "inet_fail"="Internet baglantisi yok!"
    "inet_hint1"="Modem internete bagli olmayabilir."
    "inet_hint2"="ISP tarafinda bir sorun olabilir."
    "inet_hint3"="Modem yeniden baslatilip tekrar denenebilir."
    "menu_title"="ISLEM TAMAMLANDI"; "menu_speedtest"="Internet hizi testi"
    "menu_exit"="Cikis"; "menu_prompt"="Seciminiz"
    "speedtest_title"="INTERNET HIZI TESTI"
    "speedtest_running"="Sunuculara ping atiliyor..."
    "speedtest_done"="Hiz testi tamamlandi."
    "exit_msg"="Cikmak icin herhangi bir tusa basin..."
    "any_key"="Devam etmek icin herhangi bir tusa basin..."
    "srv_title"="Oyun Test Sunuculari (Bolge: {0})"
    "srv_note1"="Bu sunuculara her bant icin ping atilarak"
    "srv_note2"="en dusuk gecikme saglayan bant secilir."
}

$script:MSG_EN = @{
    "excellent"="EXCELLENT"; "very_good"="VERY GOOD"; "good"="GOOD"; "playable"="PLAYABLE"
    "poor"="POOR"; "stable"="STABLE"; "medium"="MEDIUM"; "unstable"="UNSTABLE"
    "yes_no"="[y/N]"; "waiting"="Waiting"
    "setup_title"="Internet Avcisi - Setup Wizard"
    "setup_desc1"="Tests all LTE bands on your modem and picks the best"
    "setup_desc2"="one for gaming (lowest ping, jitter, packet loss)."
    "setup_compat"="Compatible: ZTE based LTE modems (worldwide)"
    "step_region"="Select your region"; "step_gateway"="Detecting gateway..."
    "gw_found"="Default gateway found"
    "gw_hint"="Your modem IP is usually the same as your gateway."
    "modem_ip_prompt"="Modem IP address"
    "gw_not_found"="Could not detect gateway automatically."
    "enter_ip"="Enter modem IP (usually 192.168.1.1)"
    "ip_empty"="IP address cannot be empty!"; "invalid_ip"="Invalid IP address format!"
    "step_access"="Checking modem access..."; "connecting"="connecting..."
    "modem_ok"="Modem accessible"; "modem_fail"="Cannot reach modem"
    "reason_ip"="IP address may be wrong"; "reason_off"="Modem may be off"
    "reason_net"="You may be on a different network (VPN, Wi-Fi, etc.)"
    "continue_q"="Continue anyway?"
    "check_retry"="Check your IP and try again."
    "exiting"="Exiting..."
    "step_modem"="Detecting modem type..."
    "detecting_modem"="Detecting modem type..."
    "zte_found"="ZTE modem detected - Fully compatible!"
    "modem_unknown"="Modem type not detected."
    "zte_warn1"="This tool is designed for ZTE based modems."
    "zte_warn2"="Some features may not work with other modems."
    "step_creds"="Modem credentials"
    "creds_hint1"="Username and password required for admin panel."
    "creds_hint2"="Default credentials are on a label under your modem."
    "creds_hint3"="Default username on ZTE modems is usually 'admin'."
    "username"="Username"; "password"="Password"
    "pw_hint"="(Characters are hidden for security, just type and press Enter)"
    "user_invalid"="Username can only contain letters, numbers, dots, dashes and underscores!"
    "pw_empty"="Password cannot be empty!"
    "setup_done"="Setup complete!"; "config_saved"="Config saved"
    "pw_not_saved"="(Password not saved for security, asked each time)"
    "config_loaded"="Config loaded"; "modem_pw"="Modem password"
    "conn_fail"="Cannot connect to modem. Check IP and network."
    "login_ok"="Logged in to modem"
    "login_fail"="Login failed (code: {0})"
    "reason_pw"="Password may be wrong"
    "reason_busy"="Another user may be logged in"
    "reason_restart"="Try restarting your modem"
    "status_title"="LTE Modem Gaming Status"; "net_type"="Net Type"
    "band_label"="Band"; "signal_label"="Signal"
    "server_tests"="Game Server Tests"; "col_server"="SERVER"
    "col_loss"="LOSS"; "col_status"="STATUS"
    "no_access"="NO ACCESS"; "no_conn"="NO CONNECTION"
    "opt_title"="LTE BAND OPTIMIZATION - GAMING MODE"
    "score_weights"="Score weights:"; "server_count"="Server count"
    "ping_count"="Ping count"; "band_count"="Bands to test"
    "testing_current"="Testing current connection..."
    "current_pre"="Current: Band"; "game_score"="Game Score"
    "lower_better"="lower = better"
    "testing_all"="Testing all bands..."
    "col_band"="BAND"; "col_score"="SCORE"
    "switching_band"="switching band..."
    "band_changed"="Band changed, waiting for signal..."
    "signal_stab"="Signal stabilizing"
    "pinging"="pinging servers..."
    "best_band"="Best band for gaming"
    "switching_best"="Switching to best band"
    "verify_wait"="Waiting for verification"
    "verifying"="Running verification..."
    "opt_done"="OPTIMIZATION COMPLETE!"
    "selected_band"="Selected Band"
    "done_msg"="Done. You can close this window."
    "gg"="Good gaming!"
    "no_band"="NO BAND WORKED!"
    "auto_return"="Returning to auto mode..."
    "restart_hint"="Restart your modem and try again."
    "close_win"="You can close this window."
    "stability_keep"="Current band close enough, kept as is"
    "verify_warn"="Verification below expectations! Band may be unstable."
    "selecting"="selecting..."; "activated"="activated."
    "testing_servers"="Testing servers..."
    "band_ready"="active and ready!"; "band_error"="Band switch error!"
    "invalid_band"="Invalid band number"
    "avail_bands"="Available bands:"
    "watch_title"="LTE Gaming Watch Mode"
    "ping_thresh"="Ping threshold"; "jitter_thresh"="Jitter threshold"
    "stop_hint"="Stop with: Ctrl+C"
    "bad_gaming"="BAD FOR GAMING!"
    "auto_scan"="Starting automatic band scan..."
    "scan_done"="Scan complete, resuming..."
    "watch_sel"="Watch: {0} selected (Score: {1})"
    "no_band_auto"="No band worked, returning to auto."
    "max_retry_reached"="5 consecutive failures, waiting 5 min..."
    "cfg_reset"="Config reset."
    "next_setup"="Setup wizard will run on next launch."
    "no_config"="No saved config found."
    "auto_ok"="Returned to automatic mode."
    "inet_check"="Checking internet connection..."
    "inet_ok"="Internet connection active"
    "inet_fail"="No internet connection!"
    "inet_hint1"="Your modem may not be connected to the internet."
    "inet_hint2"="There may be an ISP-side issue."
    "inet_hint3"="Try restarting your modem and run again."
    "menu_title"="OPERATION COMPLETE"; "menu_speedtest"="Internet speed test"
    "menu_exit"="Exit"; "menu_prompt"="Your choice"
    "speedtest_title"="INTERNET SPEED TEST"
    "speedtest_running"="Pinging servers..."
    "speedtest_done"="Speed test complete."
    "exit_msg"="Press any key to exit..."
    "any_key"="Press any key to continue..."
    "srv_title"="Game Test Servers (Region: {0})"
    "srv_note1"="These servers are pinged on each band to find"
    "srv_note2"="the lowest latency for gaming."
}

function T([string]$Key) {
    if ($script:LangPref -eq "TR") {
        $v = $script:MSG_TR[$Key]; if ($v) { return $v }
    } else {
        $v = $script:MSG_EN[$Key]; if ($v) { return $v }
    }
    return $Key
}

# ======================== HELPERS ========================
function Write-Log([string]$msg)  { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -ForegroundColor Cyan -NoNewline; Write-Host $msg }
function Write-Ok([string]$msg)   { Write-Host "[OK] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Err([string]$msg)  { Write-Host "[!] " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Warn([string]$msg) { Write-Host "[!] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Info([string]$msg) { Write-Host "[i] " -ForegroundColor Blue -NoNewline; Write-Host $msg }

function Read-HiddenInput {
    $pw = ""
    while ($true) {
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'Enter') { [Console]::WriteLine(); break }
        if ($k.Key -eq 'Backspace') {
            if ($pw.Length -gt 0) { $pw = $pw.Substring(0, $pw.Length - 1) }
        } elseif ($k.KeyChar -ne [char]0) { $pw += $k.KeyChar }
    }
    return $pw
}

# ======================== BOX DRAWING HELPERS ========================
function Write-BoxTop([int]$W=64)    { Write-Host ([string][char]0x2554 + ([string][char]0x2550) * ($W-2) + [string][char]0x2557) -ForegroundColor Cyan }
function Write-BoxBottom([int]$W=64) { Write-Host ([string][char]0x255A + ([string][char]0x2550) * ($W-2) + [string][char]0x255D) -ForegroundColor Cyan }
function Write-BoxSep([int]$W=64)    { Write-Host ([string][char]0x2560 + ([string][char]0x2550) * ($W-2) + [string][char]0x2563) -ForegroundColor Cyan }

function Write-BoxLine {
    param([object[]]$Segments, [int]$W=62)
    Write-Host ([char]0x2551) -ForegroundColor Cyan -NoNewline
    $totalLen = 0
    for ($i = 0; $i -lt $Segments.Count; $i += 2) {
        $c = [ConsoleColor]$Segments[$i]; $t = [string]$Segments[$i+1]
        Write-Host $t -ForegroundColor $c -NoNewline; $totalLen += $t.Length
    }
    $pad = [Math]::Max(0, $W - $totalLen)
    if ($pad -gt 0) { Write-Host (' ' * $pad) -NoNewline }
    Write-Host ([char]0x2551) -ForegroundColor Cyan
}

function Write-BoxEmpty([int]$W=64) { Write-BoxLine @("White","") ($W-2) }

# ======================== SPINNER & PROGRESS ========================
function Start-Spinner([string]$Message) {
    Stop-Spinner
    $global:_spinnerMsg = $Message
    $global:_spinnerFrame = 0
    try {
        $t = New-Object System.Timers.Timer(100)
        $t.AutoReset = $true
        $script:_spinnerEvt = Register-ObjectEvent $t Elapsed -Action {
            $f = @([char]0x280B,[char]0x2819,[char]0x2839,[char]0x2838,[char]0x283C,[char]0x2834,[char]0x2826,[char]0x2827,[char]0x2807,[char]0x280F)
            $c = $f[$global:_spinnerFrame % 10]; $global:_spinnerFrame++
            try { [Console]::Write("`r  $c $($global:_spinnerMsg) ") } catch {}
        }
        $script:_spinnerTimer = $t; $t.Start()
    } catch {
        Write-Host "  ~ $Message " -ForegroundColor Cyan -NoNewline
    }
}

function Stop-Spinner {
    if ($script:_spinnerTimer) {
        $script:_spinnerTimer.Stop()
        Start-Sleep -Milliseconds 150
        $script:_spinnerTimer.Dispose()
        $script:_spinnerTimer = $null
    }
    if ($script:_spinnerEvt) {
        Unregister-Event -SourceIdentifier $script:_spinnerEvt.Name -ErrorAction SilentlyContinue
        Remove-Job -Job $script:_spinnerEvt -Force -ErrorAction SilentlyContinue
        $script:_spinnerEvt = $null
    }
    if ($global:_spinnerMsg) {
        $len = [Math]::Max(($global:_spinnerMsg).Length + 10, 80)
        [Console]::Write("`r" + (' ' * $len) + "`r")
        $global:_spinnerMsg = ""
    }
}

function Wait-Countdown([int]$Seconds, [string]$Message) {
    if (-not $Message) { $Message = T "waiting" }
    for ($i = $Seconds; $i -gt 0; $i--) {
        $filled = [int](($Seconds - $i) * 20 / $Seconds)
        $empty  = 20 - $filled
        $bar = ([string][char]0x2588) * $filled + ([string][char]0x2591) * $empty
        Write-Host "`r  " -NoNewline
        Write-Host "$([char]0x23F3) " -ForegroundColor Yellow -NoNewline
        Write-Host "$Message $bar " -NoNewline
        Write-Host "${i}s  " -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host "`r$(' ' * 80)`r" -NoNewline
}

# ======================== GLOBAL LTE BANDS (3GPP hex bitmask) ========================
$script:Bands = @{
    "Band 1 (2100 MHz FDD)"  = "0x1"
    "Band 2 (1900 MHz FDD)"  = "0x2"
    "Band 3 (1800 MHz FDD)"  = "0x4"
    "Band 4 (AWS 1700 FDD)"  = "0x8"
    "Band 5 (850 MHz FDD)"   = "0x10"
    "Band 7 (2600 MHz FDD)"  = "0x40"
    "Band 8 (900 MHz FDD)"   = "0x80"
    "Band 12 (700a MHz FDD)" = "0x800"
    "Band 13 (700c MHz FDD)" = "0x1000"
    "Band 17 (700b MHz FDD)" = "0x10000"
    "Band 20 (800 MHz FDD)"  = "0x80000"
    "Band 25 (1900+ MHz FDD)"= "0x1000000"
    "Band 26 (850+ MHz FDD)" = "0x2000000"
    "Band 28 (700 APT FDD)"  = "0x8000000"
    "Band 32 (1500 SDL)"     = "0x80000000"
    "Band 38 (2600 TDD)"     = "0x2000000000"
    "Band 39 (1900 TDD)"     = "0x4000000000"
    "Band 40 (2300 TDD)"     = "0x8000000000"
    "Band 41 (2500 TDD)"     = "0x10000000000"
    "Band 42 (3500 TDD)"     = "0x20000000000"
    "Band 43 (3700 TDD)"     = "0x40000000000"
}

# ======================== REGION CONFIG ========================
$script:GameServers     = @{}
$script:GameServerOrder = @()
$script:BandOrder       = @()

function Set-RegionConfig {
    $script:GameServers = @{}; $script:GameServerOrder = @(); $script:BandOrder = @()

    switch ($script:Region) {
        "TR" {
            $script:BandOrder = @("Band 3 (1800 MHz FDD)","Band 7 (2600 MHz FDD)","Band 1 (2100 MHz FDD)","Band 20 (800 MHz FDD)","Band 8 (900 MHz FDD)","Band 38 (2600 TDD)","Band 40 (2300 TDD)","Band 42 (3500 TDD)")
            $script:GameServerOrder = @("Riot EU","Valve EU","EA EU","Cloudflare","Google")
        }
        "EU" {
            $script:BandOrder = @("Band 1 (2100 MHz FDD)","Band 3 (1800 MHz FDD)","Band 7 (2600 MHz FDD)","Band 8 (900 MHz FDD)","Band 20 (800 MHz FDD)","Band 28 (700 APT FDD)","Band 32 (1500 SDL)","Band 38 (2600 TDD)","Band 42 (3500 TDD)")
            $script:GameServerOrder = @("Riot EU","Valve EU","EA EU","Cloudflare","Google")
        }
        "NA" {
            $script:BandOrder = @("Band 2 (1900 MHz FDD)","Band 4 (AWS 1700 FDD)","Band 5 (850 MHz FDD)","Band 7 (2600 MHz FDD)","Band 12 (700a MHz FDD)","Band 13 (700c MHz FDD)","Band 17 (700b MHz FDD)","Band 25 (1900+ MHz FDD)","Band 26 (850+ MHz FDD)","Band 41 (2500 TDD)")
            $script:GameServerOrder = @("Riot NA","Valve NA","EA NA","Cloudflare","Google")
        }
        "LATAM" {
            $script:BandOrder = @("Band 2 (1900 MHz FDD)","Band 3 (1800 MHz FDD)","Band 4 (AWS 1700 FDD)","Band 5 (850 MHz FDD)","Band 7 (2600 MHz FDD)","Band 28 (700 APT FDD)","Band 38 (2600 TDD)")
            $script:GameServerOrder = @("Riot LATAM","Valve SA","Cloudflare","Google","Level3")
        }
        "ASIA" {
            $script:BandOrder = @("Band 1 (2100 MHz FDD)","Band 3 (1800 MHz FDD)","Band 5 (850 MHz FDD)","Band 7 (2600 MHz FDD)","Band 8 (900 MHz FDD)","Band 28 (700 APT FDD)","Band 38 (2600 TDD)","Band 39 (1900 TDD)","Band 40 (2300 TDD)","Band 41 (2500 TDD)")
            $script:GameServerOrder = @("Riot ASIA","Valve SG","Valve JP","Cloudflare","Google")
        }
        "ME" {
            $script:BandOrder = @("Band 1 (2100 MHz FDD)","Band 3 (1800 MHz FDD)","Band 7 (2600 MHz FDD)","Band 8 (900 MHz FDD)","Band 20 (800 MHz FDD)","Band 28 (700 APT FDD)","Band 38 (2600 TDD)","Band 40 (2300 TDD)","Band 41 (2500 TDD)")
            $script:GameServerOrder = @("Valve Dubai","Riot EU","Cloudflare","Google","Quad9")
        }
        "AF" {
            $script:BandOrder = @("Band 1 (2100 MHz FDD)","Band 3 (1800 MHz FDD)","Band 7 (2600 MHz FDD)","Band 8 (900 MHz FDD)","Band 20 (800 MHz FDD)","Band 28 (700 APT FDD)","Band 38 (2600 TDD)","Band 40 (2300 TDD)")
            $script:GameServerOrder = @("Valve SA","Riot EU","Cloudflare","Google","Quad9")
        }
        "OCEA" {
            $script:BandOrder = @("Band 1 (2100 MHz FDD)","Band 3 (1800 MHz FDD)","Band 5 (850 MHz FDD)","Band 7 (2600 MHz FDD)","Band 8 (900 MHz FDD)","Band 28 (700 APT FDD)","Band 40 (2300 TDD)","Band 42 (3500 TDD)")
            $script:GameServerOrder = @("Riot OCE","Valve AU","Cloudflare","Google","Quad9")
        }
        default {
            $script:BandOrder = @("Band 1 (2100 MHz FDD)","Band 3 (1800 MHz FDD)","Band 7 (2600 MHz FDD)","Band 8 (900 MHz FDD)","Band 20 (800 MHz FDD)","Band 28 (700 APT FDD)","Band 38 (2600 TDD)","Band 40 (2300 TDD)","Band 41 (2500 TDD)")
            $script:GameServerOrder = @("Cloudflare","Google","Quad9","Valve EU","Riot EU")
        }
    }

    $serverIPs = @{
        "Riot EU"="185.40.64.65"; "Riot NA"="104.160.131.3"; "Riot ASIA"="104.160.141.3"
        "Riot LATAM"="104.160.131.3"; "Riot OCE"="162.249.72.1"
        "Valve EU"="155.133.248.34"; "Valve NA"="162.254.197.36"; "Valve SG"="103.10.124.1"
        "Valve JP"="45.121.184.1"; "Valve SA"="205.185.194.20"; "Valve AU"="103.10.124.10"
        "Valve Dubai"="155.133.238.34"
        "EA EU"="159.153.64.175"; "EA NA"="159.153.92.175"
        "Cloudflare"="1.1.1.1"; "Google"="8.8.8.8"; "Quad9"="9.9.9.9"; "Level3"="4.2.2.1"
    }
    foreach ($srv in $script:GameServerOrder) {
        if ($serverIPs.ContainsKey($srv)) { $script:GameServers[$srv] = $serverIPs[$srv] }
    }
}

# ======================== NETWORK DETECTION ========================
function Get-DefaultGateway {
    try {
        $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop | Select-Object -First 1
        if ($route -and $route.NextHop) { return $route.NextHop }
    } catch {}
    try {
        $ipc = & ipconfig.exe 2>$null
        $gwLine = $ipc | Where-Object { $_ -match 'Default Gateway|Varsay|Standardgateway|Passerelle|Puerta de enlace' } | Select-Object -First 1
        if ($gwLine -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') { return $Matches[1] }
    } catch {}
    return ""
}

function Test-ValidIP([string]$IP) {
    return ($IP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')
}

function Test-ModemReachable([string]$IP) {
    if (-not (Test-ValidIP $IP)) { return $false }
    try {
        $null = Invoke-WebRequest -Uri "http://${IP}/" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return $true
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) { return $true }
        return $false
    } catch { return $false }
}

function Test-Internet {
    $pinger = New-Object System.Net.NetworkInformation.Ping
    try {
        $reply = $pinger.Send("1.1.1.1", 2000)
        if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) { return $true }
        $reply = $pinger.Send("8.8.8.8", 2000)
        if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) { return $true }
        return $false
    } catch { return $false }
    finally { $pinger.Dispose() }
}

function Get-ModemType([string]$IP) {
    if (-not (Test-ValidIP $IP)) { return "UNKNOWN" }
    try {
        $resp = Invoke-WebRequest -Uri "http://${IP}/" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($resp.Content -match "ZTE|goform|MF286|MF283|MC801|MF279") { return "ZTE" }
    } catch {}
    try {
        $resp = Invoke-WebRequest -Uri "http://${IP}/goform/goform_get_cmd_process?cmd=wa_inner_version&multi_data=1" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($resp.Content -match "wa_inner_version") { return "ZTE" }
    } catch {}
    return "UNKNOWN"
}

# ======================== CONFIG MANAGEMENT ========================
function Save-Config {
    $lines = @(
        "# Internet Avcisi - LTE Optimizer Config"
        "MODEM_IP=$($script:ModemIP)"
        "MODEM_USER=$($script:ModemUser)"
        "REGION=$($script:Region)"
        "LANG_PREF=$($script:LangPref)"
    )
    $lines | Set-Content -Path $script:ConfigFile -Encoding UTF8 -Force
}

function Load-Config {
    if (-not (Test-Path $script:ConfigFile)) { return $false }
    $lines = Get-Content $script:ConfigFile -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        if ($line -match '^#' -or $line -notmatch '=') { continue }
        $parts = $line -split '=', 2
        $key   = $parts[0].Trim()
        $value = $parts[1].Trim()
        switch ($key) {
            "MODEM_IP"  { if (Test-ValidIP $value) { $script:ModemIP = $value } }
            "MODEM_USER"{ if ($value -match '^[a-zA-Z0-9._-]+$') { $script:ModemUser = $value } }
            "REGION"    { if ($value -match '^(TR|EU|NA|LATAM|ASIA|ME|AF|OCEA)$') { $script:Region = $value } }
            "LANG_PREF" { if ($value -match '^(TR|EN)$') { $script:LangPref = $value } }
        }
    }
    return $true
}

function Update-ConfigLang {
    if ($script:LangPref -notmatch '^(TR|EN)$') { return }
    if (Test-Path $script:ConfigFile) {
        $lines = Get-Content $script:ConfigFile; $found = $false; $newLines = @()
        foreach ($line in $lines) {
            if ($line -match '^LANG_PREF=') { $newLines += "LANG_PREF=$($script:LangPref)"; $found = $true }
            else { $newLines += $line }
        }
        if (-not $found) { $newLines += "LANG_PREF=$($script:LangPref)" }
        $newLines | Set-Content -Path $script:ConfigFile -Encoding UTF8 -Force
    } else {
        "LANG_PREF=$($script:LangPref)" | Set-Content -Path $script:ConfigFile -Encoding UTF8 -Force
    }
}

function Preload-Lang {
    if (-not $script:LangPref -and (Test-Path $script:ConfigFile)) {
        $match = Select-String -Path $script:ConfigFile -Pattern '^LANG_PREF=' -ErrorAction SilentlyContinue
        if ($match) {
            $val = ($match.Line -split '=',2)[1].Trim()
            if ($val) { $script:LangPref = $val }
        }
    }
    if (-not $script:LangPref) { $script:LangPref = "__ASK__" }
}

# ======================== SETUP WIZARD ========================
function Run-Setup {
    Write-Host ""
    Write-Host ([char]0x2554 + ([string][char]0x2550)*56 + [char]0x2557) -ForegroundColor White
    $suLine = "  Internet Avcisi - Setup / Kurulum".PadRight(56)
    Write-Host "$([char]0x2551)" -ForegroundColor White -NoNewline
    Write-Host $suLine -ForegroundColor Magenta -NoNewline
    Write-Host "$([char]0x2551)" -ForegroundColor White
    Write-Host ([char]0x255A + ([string][char]0x2550)*56 + [char]0x255D) -ForegroundColor White
    Write-Host ""
    Write-Host ("$([char]0x2500)" * 58) -ForegroundColor White

    # Step 1: Language
    Write-Host ""
    Write-Host "  Step 1/6: " -ForegroundColor Magenta -NoNewline; Write-Host "Language / Dil"
    Write-Host ""
    Write-Host "    1) Turkce"
    Write-Host "    2) English"
    Write-Host ""
    Write-Host "  [1-2]: " -NoNewline; $lc = Read-Host
    switch ($lc) { "1" { $script:LangPref = "TR" } default { $script:LangPref = "EN" } }
    if ($script:LangPref -eq "TR") { Write-Ok "Dil: Turkce" } else { Write-Ok "Language: English" }

    Write-Host ""
    Write-Host "  $(T 'setup_desc1')"
    Write-Host "  $(T 'setup_desc2')"
    Write-Host ""
    Write-Host "  $(T 'setup_compat')" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("$([char]0x2500)" * 58) -ForegroundColor White

    # Step 2: Region
    Write-Host ""
    Write-Host "  Step 2/6: " -ForegroundColor Magenta -NoNewline; Write-Host (T "step_region")
    Write-Host ""
    Write-Host "    1) TR     - Turkiye"
    Write-Host "    2) EU     - Europe"
    Write-Host "    3) NA     - North America"
    Write-Host "    4) LATAM  - Latin America"
    Write-Host "    5) ASIA   - Asia-Pacific"
    Write-Host "    6) ME     - Middle East"
    Write-Host "    7) AF     - Africa"
    Write-Host "    8) OCEA   - Oceania"
    Write-Host ""
    Write-Host "  [1-8]: " -NoNewline; $rc = Read-Host
    switch ($rc) {
        "1" { $script:Region = "TR" }
        "2" { $script:Region = "EU" }
        "3" { $script:Region = "NA" }
        "4" { $script:Region = "LATAM" }
        "5" { $script:Region = "ASIA" }
        "6" { $script:Region = "ME" }
        "7" { $script:Region = "AF" }
        "8" { $script:Region = "OCEA" }
        default { $script:Region = "EU"; Write-Warn "Defaulting to EU." }
    }
    Write-Ok "Region: $($script:Region)"

    # Step 3: Gateway
    Write-Host ""
    Write-Host "  Step 3/6: " -ForegroundColor Magenta -NoNewline; Write-Host (T "step_gateway")
    Write-Host ""

    Start-Spinner (T "step_gateway")
    $detectedGw = Get-DefaultGateway
    Stop-Spinner

    if ($detectedGw) {
        Write-Ok "$(T 'gw_found'): $detectedGw"
        Write-Host ""
        Write-Host "  $(T 'gw_hint')"
        Write-Host "  $(T 'modem_ip_prompt') [$detectedGw]: " -NoNewline
        $userIp = Read-Host
        if ($userIp) { $script:ModemIP = $userIp } else { $script:ModemIP = $detectedGw }
    } else {
        Write-Warn (T "gw_not_found")
        Write-Host ""
        Write-Host "  $(T 'enter_ip')"
        Write-Host "  $(T 'modem_ip_prompt'): " -NoNewline
        $script:ModemIP = Read-Host
        if (-not $script:ModemIP) { Write-Err (T "ip_empty"); exit 1 }
    }

    if (-not (Test-ValidIP $script:ModemIP)) { Write-Err (T "invalid_ip"); exit 1 }

    # Step 4: Access check
    Write-Host ""
    Write-Host "  Step 4/6: " -ForegroundColor Magenta -NoNewline; Write-Host (T "step_access")
    Write-Host ""

    Start-Spinner "http://$($script:ModemIP) $(T 'connecting')"
    $reachable = Test-ModemReachable $script:ModemIP
    Stop-Spinner

    if ($reachable) {
        Write-Ok "$(T 'modem_ok'): http://$($script:ModemIP)"
    } else {
        Write-Err "$(T 'modem_fail'): http://$($script:ModemIP)"
        Write-Host ""
        Write-Host "  $(T 'reason_ip')" -ForegroundColor Yellow
        Write-Host "  $(T 'reason_off')" -ForegroundColor Yellow
        Write-Host "  $(T 'reason_net')" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  $(T 'continue_q') $(T 'yes_no'): " -NoNewline; $cont = Read-Host
        if ($cont -notmatch '^[eEyY]$') {
            Write-Host ""; Write-Info (T "check_retry"); exit 0
        }
    }

    # Step 5: Modem type
    Write-Host ""
    Write-Host "  Step 5/6: " -ForegroundColor Magenta -NoNewline; Write-Host (T "step_modem")
    Write-Host ""

    Start-Spinner (T "detecting_modem")
    $modemType = Get-ModemType $script:ModemIP
    Stop-Spinner

    if ($modemType -eq "ZTE") {
        Write-Ok (T "zte_found")
    } else {
        Write-Warn (T "modem_unknown")
        Write-Host ""
        Write-Host "  $(T 'zte_warn1')" -ForegroundColor Yellow
        Write-Host "  $(T 'zte_warn2')" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  $(T 'continue_q') $(T 'yes_no'): " -NoNewline; $cont = Read-Host
        if ($cont -notmatch '^[eEyY]$') { Write-Info (T "exiting"); exit 0 }
    }

    # Step 6: Credentials
    Write-Host ""
    Write-Host "  Step 6/6: " -ForegroundColor Magenta -NoNewline; Write-Host (T "step_creds")
    Write-Host ""
    Write-Host "  $(T 'creds_hint1')" -ForegroundColor DarkGray
    Write-Host "  $(T 'creds_hint2')" -ForegroundColor DarkGray
    Write-Host "  $(T 'creds_hint3')" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  $(T 'username') [admin]: " -NoNewline; $un = Read-Host
    if ($un) { $script:ModemUser = $un } else { $script:ModemUser = "admin" }

    if ($script:ModemUser -notmatch '^[a-zA-Z0-9._-]+$') { Write-Err (T "user_invalid"); exit 1 }

    Write-Host "  $(T 'pw_hint')" -ForegroundColor DarkGray
    Write-Host "  $(T 'password'): " -NoNewline
    $script:ModemPassword = Read-HiddenInput

    if (-not $script:ModemPassword) { Write-Err (T "pw_empty"); exit 1 }

    Save-Config

    Write-Host ""
    Write-Host ("$([char]0x2500)" * 58) -ForegroundColor Green
    Write-Ok (T "setup_done")
    Write-Host "  Region   : $($script:Region)"
    Write-Host "  Modem    : http://$($script:ModemIP)"
    Write-Host "  $(T 'username') : $($script:ModemUser)"
    Write-Host "  $(T 'password') : ********"
    Write-Host ""
    Write-Host "  $(T 'config_saved'): $($script:ConfigFile)" -ForegroundColor DarkGray
    Write-Host "  $(T 'pw_not_saved')" -ForegroundColor DarkGray
    Write-Host ("$([char]0x2500)" * 58) -ForegroundColor Green
    Write-Host ""
}

# ======================== INIT CONFIG ========================
function Initialize-Config {
    $script:ModemIP = ""; $script:ModemUser = ""; $script:ModemPassword = ""

    if (Load-Config) {
        if (-not $script:ModemIP) {
            # Config exists but no IP saved yet (e.g., only lang pref) - go to setup
            Run-Setup
        } elseif (-not (Test-ValidIP $script:ModemIP)) {
            Write-Warn (T "invalid_ip")
            Run-Setup
        } else {
            Write-Host ""
            Write-Host "[i] " -ForegroundColor Blue -NoNewline
            Write-Host "$(T 'config_loaded'): http://$($script:ModemIP) ($($script:ModemUser), $($script:Region))"
            Write-Host "  $(T 'pw_hint')" -ForegroundColor DarkGray
            Write-Host "  $(T 'modem_pw'): " -NoNewline
            $script:ModemPassword = Read-HiddenInput
            if (-not $script:ModemPassword) { Write-Err (T "pw_empty"); exit 1 }
        }
    } else {
        Run-Setup
    }

    Set-RegionConfig
    $script:Modem = "http://$($script:ModemIP)"
}

# ======================== PING RATING ========================
function Get-PingRating([int]$Avg) {
    if ($Avg -le 30)  { return @{Text=(T "excellent"); Color="Green"} }
    if ($Avg -le 50)  { return @{Text=(T "very_good"); Color="Green"} }
    if ($Avg -le 80)  { return @{Text=(T "good");      Color="Yellow"} }
    if ($Avg -le 120) { return @{Text=(T "playable");   Color="Yellow"} }
    return @{Text=(T "poor"); Color="Red"}
}

function Get-JitterRating([int]$J) {
    # PDV (ardisik fark ortalamasi) icin kalibre edilmis esikler
    if ($J -le 3)  { return @{Text=(T "stable");   Color="Green"} }
    if ($J -le 8)  { return @{Text=(T "good");     Color="Green"} }
    if ($J -le 15) { return @{Text=(T "medium");   Color="Yellow"} }
    if ($J -le 30) { return @{Text=(T "unstable"); Color="Yellow"} }
    return @{Text=(T "poor"); Color="Red"}
}

# ======================== CRYPTO HELPERS ========================
function Get-MD5Hash([string]$Text) {
    $md5   = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash  = $md5.ComputeHash($bytes)
    $md5.Dispose()
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
}

# ======================== MODEM API (ZTE) ========================
function Login-Modem {
    $script:WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $headers = @{ Referer = "$($script:Modem)/index.html" }

    # Get version info
    try {
        $resp = Invoke-WebRequest -Uri "$($script:Modem)/goform/goform_get_cmd_process?cmd=wa_inner_version,cr_version&multi_data=1" `
            -Headers $headers -WebSession $script:WebSession -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        $verData = $resp.Content | ConvertFrom-Json
    } catch {
        Write-Err (T "conn_fail"); return $false
    }

    $script:RD0 = $verData.wa_inner_version
    $script:RD1 = $verData.cr_version

    # Base64 encode password (UTF-8, matching ZTE API expectation)
    $pwB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($script:ModemPassword))

    # Login POST
    $body = "isTest=false&goformId=LOGIN_MULTI_USER&user=$($script:ModemUser)&password=$pwB64"
    try {
        $resp = Invoke-WebRequest -Uri "$($script:Modem)/goform/goform_set_cmd_process" `
            -Method POST -Body $body -Headers $headers `
            -WebSession $script:WebSession -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        $loginData = $resp.Content | ConvertFrom-Json
    } catch {
        Write-Err (T "conn_fail"); return $false
    }

    $result = [string]$loginData.result
    if ($result -eq "0" -or $result -eq "4") {
        Write-Ok (T "login_ok"); return $true
    } else {
        Write-Err ((T "login_fail") -f $result)
        Write-Host "  - $(T 'reason_pw')" -ForegroundColor Yellow
        Write-Host "  - $(T 'reason_busy')" -ForegroundColor Yellow
        Write-Host "  - $(T 'reason_restart')" -ForegroundColor Yellow
        return $false
    }
}

function Get-ADToken {
    $baseHash = Get-MD5Hash "$($script:RD0)$($script:RD1)"
    $headers  = @{ Referer = "$($script:Modem)/index.html" }
    try {
        $resp = Invoke-WebRequest -Uri "$($script:Modem)/goform/goform_get_cmd_process?cmd=RD&multi_data=1" `
            -Headers $headers -WebSession $script:WebSession -UseBasicParsing -ErrorAction Stop
        $rdData = $resp.Content | ConvertFrom-Json
        $rdVal  = $rdData.RD
    } catch { $rdVal = "" }
    return (Get-MD5Hash "$baseHash$rdVal")
}

function Get-ModemData([string]$Cmd) {
    $headers = @{ Referer = "$($script:Modem)/index.html" }
    try {
        $resp = Invoke-WebRequest -Uri "$($script:Modem)/goform/goform_get_cmd_process?cmd=$Cmd&multi_data=1" `
            -Headers $headers -WebSession $script:WebSession -UseBasicParsing -ErrorAction Stop
        return ($resp.Content | ConvertFrom-Json)
    } catch { return $null }
}

function Set-ModemData([string]$Data) {
    $ad = Get-ADToken
    $headers = @{ Referer = "$($script:Modem)/index.html" }
    try {
        $resp = Invoke-WebRequest -Uri "$($script:Modem)/goform/goform_set_cmd_process" `
            -Method POST -Body "$Data&AD=$ad" -Headers $headers `
            -WebSession $script:WebSession -UseBasicParsing -ErrorAction Stop
        return ($resp.Content | ConvertFrom-Json)
    } catch { return $null }
}

# ======================== BAND OPERATIONS ========================
function Set-Band([string]$HexVal) {
    if ($HexVal -notmatch '^0x[0-9a-fA-F]+$') { return $false }
    $resp = Set-ModemData "isTest=false&goformId=SET_NETWORK_BAND_LOCK&lte_band_lock=$HexVal"
    return ($resp -and [string]$resp.result -eq "success")
}

function Set-Auto { Set-Band "0x7FFFFFFFFFFFFFFF" | Out-Null }

function Get-SignalInfo {
    return (Get-ModemData "lte_ca_pcell_band,lte_rsrp,lte_rsrq,lte_snr,network_type,cell_id,lte_pci,signalbar,wan_ipaddr")
}

function Get-CurrentBand {
    $info = Get-ModemData "lte_ca_pcell_band"
    if ($info) { return $info.lte_ca_pcell_band }; return ""
}

# ======================== PING TEST ========================
function Run-PingTest([string]$Target = "8.8.8.8") {
    if ($Target -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { return "FAIL|0|100|0|0|0" }

    $pinger  = New-Object System.Net.NetworkInformation.Ping
    $timeout = 1500
    $times   = @()
    $lost    = 0

    try {
        # Warm-up ping: hatti ac, sonucu kaydetme
        try { $null = $pinger.Send($Target, $timeout) } catch {}
        Start-Sleep -Milliseconds 250

        for ($i = 0; $i -lt $script:PingCount; $i++) {
            try {
                $reply = $pinger.Send($Target, $timeout)
                if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                    $times += [int]$reply.RoundtripTime
                } else { $lost++ }
            } catch { $lost++ }
            if ($i -lt ($script:PingCount - 1)) { Start-Sleep -Milliseconds 250 }
        }
    } finally { $pinger.Dispose() }

    if ($times.Count -eq 0) { return "FAIL|0|100|0|0|0" }

    $loss   = [int]($lost * 100 / $script:PingCount)
    $min    = [int]($times | Measure-Object -Minimum).Minimum
    $max    = [int]($times | Measure-Object -Maximum).Maximum

    # Median: tek bir spike tum bandi cokmez, oyuncunun gercek hissettigi deger
    $sorted = $times | Sort-Object
    $mid    = [int]($sorted.Count / 2)
    if ($sorted.Count % 2 -eq 0) {
        $avg = [int](($sorted[$mid - 1] + $sorted[$mid]) / 2)
    } else {
        $avg = [int]$sorted[$mid]
    }

    # PDV: ardisik pingler arasi farklarin mutlak degerinin ortalamasi
    $jitter = 0
    if ($times.Count -gt 1) {
        $diffSum = 0
        for ($j = 1; $j -lt $times.Count; $j++) {
            $diffSum += [Math]::Abs($times[$j] - $times[$j - 1])
        }
        $jitter = [int]($diffSum / ($times.Count - 1))
    }

    return "OK|$avg|$loss|$min|$max|$jitter"
}

function Run-GamingTest {
    $totalAvg = 0; $totalJitter = 0; $totalLoss = 0; $srvCount = 0; $reachable = 0

    foreach ($sn in $script:GameServerOrder) {
        $target = $script:GameServers[$sn]
        $result = Run-PingTest $target
        $p = $result -split '\|'
        if ($p[0] -eq "OK") {
            $totalAvg    += [int]$p[1]
            $totalLoss   += [int]$p[2]
            $totalJitter += [int]$p[5]
            $reachable++
        } else {
            # Ulasilamayan sunucuya agir ceza
            $totalAvg    += 500
            $totalLoss   += 100
            $totalJitter += 100
        }
        $srvCount++
    }

    if ($srvCount -eq 0) { return "FAIL|0|0|100|0" }
    # En az 2 sunucuya ulasamiyorsa bu bant guvenilmez
    if ($reachable -lt 2) { return "FAIL|0|0|100|0" }
    $aP = [int]($totalAvg / $srvCount); $aJ = [int]($totalJitter / $srvCount); $aL = [int]($totalLoss / $srvCount)
    return "OK|$aP|$aJ|$aL|$srvCount"
}

function Get-GameScore([int]$AvgPing, [int]$Jitter, [int]$Loss) {
    $ps = [Math]::Min(100, [int]($AvgPing * 100 / 300))
    $js = [Math]::Min(100, $Jitter * 2)   # PDV degerleri range'den 2-3x kucuk, kompanze et
    $ls = [Math]::Min(100, $Loss * 4)      # Paket kaybi agir cezalandirilir
    return [int](($ps * $script:WeightAvgPing + $js * $script:WeightJitter + $ls * $script:WeightPacketLoss) / 100)
}

# ======================== SHOW STATUS ========================
function Show-Status {
    Initialize-Config
    if (-not (Login-Modem)) { return }

    Start-Spinner (T "inet_check")
    $inetOk = Test-Internet
    Stop-Spinner
    if ($inetOk) { Write-Ok (T "inet_ok") } else { Write-Warn (T "inet_fail") }

    $info = Get-SignalInfo
    Write-Host ""
    Write-Host "=== $(T 'status_title') ===" -ForegroundColor White
    Write-Host "  $(T 'net_type')  : $($info.network_type)"
    Write-Host "  $(T 'band_label')     : Band $($info.lte_ca_pcell_band)"
    Write-Host "  RSRP       : $($info.lte_rsrp) dBm"
    Write-Host "  RSRQ       : $($info.lte_rsrq) dB"
    Write-Host "  SNR        : $($info.lte_snr) dB"
    Write-Host "  $(T 'signal_label')   : $($info.signalbar)/5"
    Write-Host "  Cell ID    : $($info.cell_id)"
    Write-Host "  WAN IP     : $($info.wan_ipaddr)"

    Write-Host ""
    Write-Host "--- $(T 'server_tests') ---" -ForegroundColor White
    Write-Host ("{0,-25} {1,8} {2,8} {3,8} {4,8}" -f (T "col_server"),"PING","JITTER",(T "col_loss"),(T "col_status"))
    Write-Host ("$([char]0x2500)" * 61)

    foreach ($sn in $script:GameServerOrder) {
        $target = $script:GameServers[$sn]
        $result = Run-PingTest $target
        $p = $result -split '\|'
        if ($p[0] -eq "OK") {
            $rating = Get-PingRating ([int]$p[1])
            $line = "{0,-25} {1,6}ms {2,6}ms {3,6}% " -f $sn, $p[1], $p[5], $p[2]
            Write-Host $line -NoNewline; Write-Host $rating.Text -ForegroundColor $rating.Color
        } else {
            Write-Host ("{0,-25} {1}" -f $sn, (T "no_access")) -ForegroundColor Red
        }
    }
    Write-Host ""
}

function Show-Servers {
    if (-not $script:Region) {
        $null = Load-Config
        if (-not $script:Region) { $script:Region = "EU" }
        if (-not $script:LangPref -or $script:LangPref -eq "__ASK__") { $script:LangPref = "EN" }
        Set-RegionConfig
    }
    Write-Host ""
    Write-Host "=== $((T 'srv_title') -f $script:Region) ===" -ForegroundColor White
    Write-Host ""
    foreach ($sn in $script:GameServerOrder) {
        Write-Host "  $sn" -ForegroundColor White -NoNewline; Write-Host " -> $($script:GameServers[$sn])"
    }
    Write-Host ""
    Write-Host "  $(T 'srv_note1')"
    Write-Host "  $(T 'srv_note2')"
    Write-Host ""
}

# ======================== MAIN OPTIMIZATION ========================
function Start-Optimization {
    Initialize-Config

    Write-Host ""
    $otText = T "opt_title"
    Write-Host ([char]0x2554 + ([string][char]0x2550)*56 + [char]0x2557) -ForegroundColor White
    $otLine = "  $otText".PadRight(56)
    Write-Host "$([char]0x2551)" -ForegroundColor White -NoNewline
    Write-Host $otLine -ForegroundColor Magenta -NoNewline
    Write-Host "$([char]0x2551)" -ForegroundColor White
    Write-Host ([char]0x255A + ([string][char]0x2550)*56 + [char]0x255D) -ForegroundColor White
    Write-Host ""
    Write-Host "  $(T 'score_weights')"
    Write-Host "    Ping: %$($script:WeightAvgPing) | Jitter: %$($script:WeightJitter) | $(T 'col_loss'): %$($script:WeightPacketLoss)"
    Write-Host "  $(T 'server_count'): $($script:GameServers.Count)"
    Write-Host "  $(T 'ping_count'): $($script:PingCount)"
    Write-Host "  $(T 'band_count'): $($script:BandOrder.Count)"
    Write-Host ""

    if (-not (Login-Modem)) { return }

    Start-Spinner (T "inet_check")
    $inetOk = Test-Internet
    Stop-Spinner

    if ($inetOk) {
        Write-Ok (T "inet_ok")
    } else {
        Write-Err (T "inet_fail"); Write-Host ""
        Write-Host "  - $(T 'inet_hint1')" -ForegroundColor Yellow
        Write-Host "  - $(T 'inet_hint2')" -ForegroundColor Yellow
        Write-Host "  - $(T 'inet_hint3')" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  $(T 'continue_q') $(T 'yes_no'): " -NoNewline; $c = Read-Host
        if ($c -notmatch '^[eEyY]$') { return }
    }
    Write-Host ""

    # Test current connection
    Start-Spinner (T "testing_current")
    $curBand   = Get-CurrentBand
    $curResult = Run-GamingTest
    Stop-Spinner

    $cp = $curResult -split '\|'
    if ($cp[0] -eq "OK") {
        $cAvg = [int]$cp[1]; $cJit = [int]$cp[2]; $cLoss = [int]$cp[3]
        $cScore = Get-GameScore $cAvg $cJit $cLoss
        $cPR = Get-PingRating $cAvg; $cJR = Get-JitterRating $cJit
        Write-Host "  $(T 'current_pre') $curBand"
        Write-Host "    Ping: " -NoNewline; Write-Host "${cAvg}ms" -NoNewline
        Write-Host " (" -NoNewline; Write-Host $cPR.Text -ForegroundColor $cPR.Color -NoNewline
        Write-Host ") | Jitter: " -NoNewline; Write-Host "${cJit}ms" -NoNewline
        Write-Host " (" -NoNewline; Write-Host $cJR.Text -ForegroundColor $cJR.Color -NoNewline
        Write-Host ") | $(T 'col_loss'): ${cLoss}%"
        Write-Host "    $(T 'game_score'): " -NoNewline; Write-Host "${cScore}/100" -NoNewline
        Write-Host " ($(T 'lower_better'))"
    } else {
        Write-Host "  $(T 'current_pre') $curBand - " -NoNewline; Write-Host (T "no_conn") -ForegroundColor Red
    }
    Write-Host ""

    # Test all bands
    $bestBand = ""; $bestScore = 99999; $bestHex = ""; $bestAvg = 0; $bestJit = 0; $bestLoss = 0
    $curLockedScore = $null; $curLockedBand = ""; $curLockedHex = ""
    $curLockedAvg = 0; $curLockedJit = 0; $curLockedLoss = 0

    Write-Host (T "testing_all") -ForegroundColor White
    Write-Host ("$([char]0x2500)" * 70)
    Write-Host ("{0,-22} {1,7} {2,7} {3,6} {4,6} {5,8}" -f (T "col_band"),"PING","JITTER",(T "col_loss"),(T "col_score"),(T "col_status"))
    Write-Host ("$([char]0x2500)" * 70)

    $bIdx = 0; $bTotal = $script:BandOrder.Count

    foreach ($bandName in $script:BandOrder) {
        $hexVal = $script:Bands[$bandName]; $bIdx++

        Write-Host ""
        Write-Host "  [$bIdx/$bTotal] " -ForegroundColor Magenta -NoNewline
        Write-Host $bandName -ForegroundColor White

        Start-Spinner "$bandName $(T 'switching_band')"
        $null = Set-Band $hexVal
        Stop-Spinner
        Write-Host "  " -NoNewline; Write-Host "$([char]0x2713)" -ForegroundColor Green -NoNewline
        Write-Host " $(T 'band_changed')"
        Wait-Countdown $script:WaitAfterSwitch (T "signal_stab")

        Start-Spinner "$bandName - $($script:GameServers.Count) $(T 'pinging')"
        $result = Run-GamingTest
        Stop-Spinner

        $rp = $result -split '\|'
        if ($rp[0] -eq "OK") {
            $avg = [int]$rp[1]; $jit = [int]$rp[2]; $loss = [int]$rp[3]
            $score = Get-GameScore $avg $jit $loss
            $color = "Red"
            if ($score -le 20) { $color = "Green" } elseif ($score -le 40) { $color = "Yellow" }
            $rating = Get-PingRating $avg
            $line = "{0,-22} {1,5}ms {2,5}ms {3,5}% {4,4}/100" -f $bandName, $avg, $jit, $loss, $score
            Write-Host "  $line " -ForegroundColor $color -NoNewline
            Write-Host $rating.Text -ForegroundColor $rating.Color

            if ($score -lt $bestScore) {
                $bestScore = $score; $bestBand = $bandName; $bestHex = $hexVal
                $bestAvg = $avg; $bestJit = $jit; $bestLoss = $loss
            }
            # Mevcut bandin kilitli performansini kaydet (stabilite karsilastirmasi icin)
            if ($bandName -match 'Band (\d+)' -and $Matches[1] -eq $curBand) {
                $curLockedScore = $score; $curLockedBand = $bandName; $curLockedHex = $hexVal
                $curLockedAvg = $avg; $curLockedJit = $jit; $curLockedLoss = $loss
            }
        } else {
            Write-Host ("  {0,-22} {1}" -f $bandName, (T "no_conn")) -ForegroundColor Red
        }
    }

    Write-Host ("$([char]0x2500)" * 70)
    Write-Host ""

    # Stabilite bonusu: mevcut bant en iyinin 5 puani icindeyse, gereksiz gecis yapma
    if ($null -ne $curLockedScore -and $bestBand -and $curLockedBand -ne $bestBand `
        -and $curLockedScore -le ($bestScore + 5)) {
        Write-Host ""
        Write-Info "$(T 'stability_keep')"
        Write-Host "    $curLockedBand ($(T 'col_score'): $curLockedScore) vs $bestBand ($(T 'col_score'): $bestScore)" -ForegroundColor DarkGray
        $bestScore = $curLockedScore; $bestBand = $curLockedBand; $bestHex = $curLockedHex
        $bestAvg = $curLockedAvg; $bestJit = $curLockedJit; $bestLoss = $curLockedLoss
    }

    if ($bestBand) {
        Write-Host ("$([char]0x2500)" * 70) -ForegroundColor White
        $bPR = Get-PingRating $bestAvg; $bJR = Get-JitterRating $bestJit
        Write-Host "  >>> $(T 'best_band'): $bestBand" -ForegroundColor Green
        Write-Host "    Ping: " -NoNewline; Write-Host "${bestAvg}ms" -NoNewline
        Write-Host " (" -NoNewline; Write-Host $bPR.Text -ForegroundColor $bPR.Color -NoNewline; Write-Host ")"
        Write-Host "    Jitter: " -NoNewline; Write-Host "${bestJit}ms" -NoNewline
        Write-Host " (" -NoNewline; Write-Host $bJR.Text -ForegroundColor $bJR.Color -NoNewline; Write-Host ")"
        Write-Host "    $(T 'col_loss'): ${bestLoss}%"
        Write-Host "    $(T 'col_score'): " -NoNewline; Write-Host "${bestScore}/100"
        Write-Host ""

        Start-Spinner "$(T 'switching_best'): $bestBand..."
        $null = Set-Band $bestHex
        Stop-Spinner
        Write-Host "  " -NoNewline; Write-Host "$([char]0x2713)" -ForegroundColor Green -NoNewline
        Write-Host " $(T 'band_changed')"
        Wait-Countdown $script:WaitAfterSwitch (T "verify_wait")

        Start-Spinner (T "verifying")
        $vResult = Run-GamingTest
        Stop-Spinner

        $vp = $vResult -split '\|'

        # Dogrulama kalite kontrolu
        if ($vp[0] -eq "OK") {
            $vScore = Get-GameScore ([int]$vp[1]) ([int]$vp[2]) ([int]$vp[3])
            if ($vScore -gt [Math]::Max($bestScore * 2, 30)) {
                Write-Host ""
                Write-Warn (T "verify_warn")
            }
        }

        Write-Host ""
        $odText = T "opt_done"
        $odLine = "           $([char]0x2713) ${odText}".PadRight(56)
        Write-Host ([char]0x2554 + ([string][char]0x2550)*56 + [char]0x2557) -ForegroundColor Green
        Write-Host "$([char]0x2551)${odLine}$([char]0x2551)" -ForegroundColor Green
        Write-Host ([char]0x2560 + ([string][char]0x2550)*56 + [char]0x2563) -ForegroundColor Green
        $sbLine = "  $(T 'selected_band') : $bestBand".PadRight(56)
        Write-Host "$([char]0x2551)${sbLine}$([char]0x2551)" -ForegroundColor Green

        if ($vp[0] -eq "OK") {
            $vAvg = [int]$vp[1]; $vJit = [int]$vp[2]; $vLoss = [int]$vp[3]
            $vPR = Get-PingRating $vAvg; $vJR = Get-JitterRating $vJit
            $pingLine = "  Ping         : ${vAvg}ms ($($vPR.Text))".PadRight(56)
            Write-Host "$([char]0x2551)${pingLine}$([char]0x2551)" -ForegroundColor Green
            $jitLine = "  Jitter       : ${vJit}ms ($($vJR.Text))".PadRight(56)
            Write-Host "$([char]0x2551)${jitLine}$([char]0x2551)" -ForegroundColor Green
            $lossLine = "  $(T 'col_loss')        : ${vLoss}%".PadRight(56)
            Write-Host "$([char]0x2551)${lossLine}$([char]0x2551)" -ForegroundColor Green
        } else {
            $scoreLine = "  $(T 'col_score')        : ${bestScore}/100".PadRight(56)
            Write-Host "$([char]0x2551)${scoreLine}$([char]0x2551)" -ForegroundColor Green
        }
        Write-Host ([char]0x2560 + ([string][char]0x2550)*56 + [char]0x2563) -ForegroundColor Green
        $doneLine = "  $(T 'done_msg')".PadRight(56)
        Write-Host "$([char]0x2551)${doneLine}$([char]0x2551)" -ForegroundColor Green
        $ggLine = "  $(T 'gg')".PadRight(56)
        Write-Host "$([char]0x2551)${ggLine}$([char]0x2551)" -ForegroundColor Green
        Write-Host ([char]0x255A + ([string][char]0x2550)*56 + [char]0x255D) -ForegroundColor Green
    } else {
        Write-Host ""
        $nbText = T "no_band"
        $nbLine = "           $([char]0x2717) ${nbText}".PadRight(56)
        Write-Host ([char]0x2554 + ([string][char]0x2550)*56 + [char]0x2557) -ForegroundColor Red
        Write-Host "$([char]0x2551)${nbLine}$([char]0x2551)" -ForegroundColor Red
        Write-Host ([char]0x2560 + ([string][char]0x2550)*56 + [char]0x2563) -ForegroundColor Red
        $arLine = "  $(T 'auto_return')".PadRight(56)
        Write-Host "$([char]0x2551)${arLine}$([char]0x2551)" -ForegroundColor Red
        $rhLine = "  $(T 'restart_hint')".PadRight(56)
        Write-Host "$([char]0x2551)${rhLine}$([char]0x2551)" -ForegroundColor Red
        $cwLine = "  $(T 'close_win')".PadRight(56)
        Write-Host "$([char]0x2551)${cwLine}$([char]0x2551)" -ForegroundColor Red
        Write-Host ([char]0x255A + ([string][char]0x2550)*56 + [char]0x255D) -ForegroundColor Red
        Set-Auto
    }
    Write-Host ""
}

# ======================== DIRECT BAND SELECT ========================
function Set-SpecificBand([string]$BandNum) {
    $hex = ""; $name = ""
    switch ($BandNum) {
        "1"  { $hex="0x1";              $name="Band 1 (2100 MHz FDD)" }
        "2"  { $hex="0x2";              $name="Band 2 (1900 MHz FDD)" }
        "3"  { $hex="0x4";              $name="Band 3 (1800 MHz FDD)" }
        "4"  { $hex="0x8";              $name="Band 4 (AWS 1700 FDD)" }
        "5"  { $hex="0x10";             $name="Band 5 (850 MHz FDD)" }
        "7"  { $hex="0x40";             $name="Band 7 (2600 MHz FDD)" }
        "8"  { $hex="0x80";             $name="Band 8 (900 MHz FDD)" }
        "12" { $hex="0x800";            $name="Band 12 (700a MHz FDD)" }
        "13" { $hex="0x1000";           $name="Band 13 (700c MHz FDD)" }
        "17" { $hex="0x10000";          $name="Band 17 (700b MHz FDD)" }
        "20" { $hex="0x80000";          $name="Band 20 (800 MHz FDD)" }
        "25" { $hex="0x1000000";        $name="Band 25 (1900+ MHz FDD)" }
        "26" { $hex="0x2000000";        $name="Band 26 (850+ MHz FDD)" }
        "28" { $hex="0x8000000";        $name="Band 28 (700 APT FDD)" }
        "32" { $hex="0x80000000";       $name="Band 32 (1500 SDL)" }
        "38" { $hex="0x2000000000";     $name="Band 38 (2600 TDD)" }
        "39" { $hex="0x4000000000";     $name="Band 39 (1900 TDD)" }
        "40" { $hex="0x8000000000";     $name="Band 40 (2300 TDD)" }
        "41" { $hex="0x10000000000";    $name="Band 41 (2500 TDD)" }
        "42" { $hex="0x20000000000";    $name="Band 42 (3500 TDD)" }
        "43" { $hex="0x40000000000";    $name="Band 43 (3700 TDD)" }
        default {
            Write-Err "$(T 'invalid_band'): $BandNum"
            Write-Host ""
            Write-Host "  $(T 'avail_bands')" -ForegroundColor White
            Write-Host "  FDD:" -ForegroundColor Cyan
            Write-Host "    1  - Band 1  (2100 MHz)    2  - Band 2  (1900 MHz)"
            Write-Host "    3  - Band 3  (1800 MHz)    4  - Band 4  (AWS 1700)"
            Write-Host "    5  - Band 5  (850 MHz)     7  - Band 7  (2600 MHz)"
            Write-Host "    8  - Band 8  (900 MHz)     12 - Band 12 (700a MHz)"
            Write-Host "    13 - Band 13 (700c MHz)    17 - Band 17 (700b MHz)"
            Write-Host "    20 - Band 20 (800 MHz)     25 - Band 25 (1900+ MHz)"
            Write-Host "    26 - Band 26 (850+ MHz)    28 - Band 28 (700 APT)"
            Write-Host "    32 - Band 32 (1500 SDL)"
            Write-Host "  TDD:" -ForegroundColor Cyan
            Write-Host "    38 - Band 38 (2600 TDD)    39 - Band 39 (1900 TDD)"
            Write-Host "    40 - Band 40 (2300 TDD)    41 - Band 41 (2500 TDD)"
            Write-Host "    42 - Band 42 (3500 TDD)    43 - Band 43 (3700 TDD)"
            Write-Host ""
            return
        }
    }

    Initialize-Config
    if (-not (Login-Modem)) { return }

    Start-Spinner "$name $(T 'selecting')"
    $success = Set-Band $hex
    Stop-Spinner

    if ($success) {
        Write-Ok "$name $(T 'activated')"
        Wait-Countdown $script:WaitAfterSwitch (T "signal_stab")

        Write-Host ""
        Write-Host "--- $(T 'server_tests') ---" -ForegroundColor White
        Write-Host ("{0,-25} {1,8} {2,8} {3,8}" -f (T "col_server"),"PING","JITTER",(T "col_loss"))
        Write-Host ("$([char]0x2500)" * 53)

        Start-Spinner (T "testing_servers")
        $testOutput = @()
        foreach ($sn in $script:GameServerOrder) {
            $target = $script:GameServers[$sn]
            $result = Run-PingTest $target
            $p = $result -split '\|'
            if ($p[0] -eq "OK") {
                $testOutput += "{0,-25} {1,6}ms {2,6}ms {3,6}%" -f $sn, $p[1], $p[5], $p[2]
            } else {
                $testOutput += "RED|{0,-25} {1}" -f $sn, (T "no_access")
            }
        }
        Stop-Spinner

        foreach ($line in $testOutput) {
            if ($line.StartsWith("RED|")) {
                Write-Host $line.Substring(4) -ForegroundColor Red
            } else { Write-Host $line }
        }

        Write-Host ""
        Write-Host "  $([char]0x2713) $name $(T 'band_ready') $(T 'close_win')" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Err (T "band_error")
    }
}

# ======================== WATCH MODE ========================
function Start-WatchReoptimize {
    if (-not (Login-Modem)) { return }

    $prevBand = Get-CurrentBand
    $wBest = ""; $wBestScore = 99999; $wBestHex = ""
    $prevScore = $null; $prevBandName = ""; $prevHex = ""

    foreach ($bandName in $script:BandOrder) {
        $hexVal = $script:Bands[$bandName]
        Start-Spinner "$bandName..."
        $null = Set-Band $hexVal
        Stop-Spinner
        Wait-Countdown $script:WaitAfterSwitch (T "signal_stab")

        Start-Spinner "$bandName - test..."
        $result = Run-GamingTest
        Stop-Spinner
        $p = $result -split '\|'

        if ($p[0] -eq "OK") {
            $avg = [int]$p[1]; $jit = [int]$p[2]; $loss = [int]$p[3]
            $score = Get-GameScore $avg $jit $loss
            Write-Log "${bandName}: Ping=${avg}ms Jitter=${jit}ms $(T 'col_loss')=${loss}% $(T 'col_score')=$score"
            if ($score -lt $wBestScore) {
                $wBestScore = $score; $wBest = $bandName; $wBestHex = $hexVal
            }
            # Onceki bandin kilitli skorunu kaydet
            if ($bandName -match 'Band (\d+)' -and $Matches[1] -eq $prevBand) {
                $prevScore = $score; $prevBandName = $bandName; $prevHex = $hexVal
            }
        } else {
            Write-Warn "${bandName}: $(T 'no_conn')"
        }
    }

    if ($wBest) {
        # Stabilite: onceki bant en iyinin 5 puani icindeyse gereksiz gecis yapma
        if ($null -ne $prevScore -and $prevBandName -ne $wBest -and $prevScore -le ($wBestScore + 5)) {
            $wBest = $prevBandName; $wBestHex = $prevHex; $wBestScore = $prevScore
        }
        Start-Spinner "$(T 'switching_best'): $wBest..."
        $null = Set-Band $wBestHex
        Stop-Spinner
        Write-Ok ((T "watch_sel") -f $wBest, $wBestScore)
        Wait-Countdown $script:WaitAfterSwitch (T "signal_stab")
    } else {
        Write-Warn (T "no_band_auto")
        Set-Auto
    }
}

function Start-WatchMode([string]$PingTh, [string]$JitterTh) {
    Initialize-Config

    $pt = 80; $jt = 30
    if ($PingTh -match '^\d+$') { $pt = [int]$PingTh }
    if ($JitterTh -match '^\d+$') { $jt = [int]$JitterTh }

    Write-Host ""
    Write-Host "=== $(T 'watch_title') ===" -ForegroundColor White
    Write-Host "  $(T 'ping_thresh')   : ${pt}ms"
    Write-Host "  $(T 'jitter_thresh') : ${jt}ms"
    Write-Host "  $(T 'stop_hint')"
    Write-Host ""

    if (-not (Login-Modem)) { return }

    $consecutiveFails = 0; $maxRetries = 5

    while ($true) {
        $result = Run-GamingTest
        $p = $result -split '\|'
        $status = $p[0]; $avg = [int]$p[1]; $jit = [int]$p[2]; $loss = [int]$p[3]
        $band = Get-CurrentBand

        if ($status -eq "FAIL" -or $avg -gt $pt -or $jit -gt $jt -or $loss -gt 5) {
            $consecutiveFails++
            Write-Warn "Ping: ${avg}ms | Jitter: ${jit}ms | $(T 'col_loss'): ${loss}% | Band: $band - $(T 'bad_gaming')"
            if ($consecutiveFails -ge $maxRetries) {
                Write-Warn (T "max_retry_reached")
                $consecutiveFails = 0
                Start-Sleep -Seconds 300
            } else {
                Write-Log (T "auto_scan")
                Start-WatchReoptimize
                Write-Log (T "scan_done")
            }
        } else {
            $consecutiveFails = 0
            $color = "Green"; if ($avg -gt 50) { $color = "Yellow" }
            $rating = Get-PingRating $avg
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -ForegroundColor $color -NoNewline
            Write-Host "Ping: ${avg}ms | Jitter: ${jit}ms | $(T 'col_loss'): ${loss}% | Band: $band | " -NoNewline
            Write-Host $rating.Text -ForegroundColor $rating.Color
        }

        Start-Sleep -Seconds 60
    }
}

# ======================== SPEED TEST & POST-ACTION MENU ========================
function Run-SpeedTest {
    Write-Host ""
    $stText = T "speedtest_title"
    Write-Host ([char]0x2554 + ([string][char]0x2550)*56 + [char]0x2557) -ForegroundColor White
    $stLine = "  $stText".PadRight(56)
    Write-Host "$([char]0x2551)" -ForegroundColor White -NoNewline
    Write-Host $stLine -ForegroundColor Cyan -NoNewline
    Write-Host "$([char]0x2551)" -ForegroundColor White
    Write-Host ([char]0x255A + ([string][char]0x2550)*56 + [char]0x255D) -ForegroundColor White
    Write-Host ""

    Start-Spinner (T "speedtest_running")
    $testOutput = @()
    foreach ($sn in $script:GameServerOrder) {
        $target = $script:GameServers[$sn]
        $result = Run-PingTest $target
        $p = $result -split '\|'
        if ($p[0] -eq "OK") {
            $rating = Get-PingRating ([int]$p[1])
            $testOutput += @{ Line = ("  {0,-25} {1,6}ms {2,6}ms {3,6}%" -f $sn,$p[1],$p[5],$p[2]); Rating = $rating }
        } else {
            $testOutput += @{ Line = ("  {0,-25} {1}" -f $sn, (T "no_access")); Rating = @{Text="";Color="Red"}; IsError = $true }
        }
    }
    Stop-Spinner

    Write-Host ("  {0,-25} {1,8} {2,8} {3,8} {4,8}" -f (T "col_server"),"PING","JITTER",(T "col_loss"),(T "col_status"))
    Write-Host "  $("$([char]0x2500)" * 59)"
    foreach ($item in $testOutput) {
        if ($item.IsError) {
            Write-Host $item.Line -ForegroundColor Red
        } else {
            Write-Host "$($item.Line) " -NoNewline
            Write-Host $item.Rating.Text -ForegroundColor $item.Rating.Color
        }
    }
    Write-Host ""
    Write-Ok (T "speedtest_done")
}

function Show-PostActionMenu {
    while ($true) {
        Write-Host ""
        $mtText = T "menu_title"; $msText = T "menu_speedtest"; $meText = T "menu_exit"
        Write-Host ([char]0x2554 + ([string][char]0x2550)*46 + [char]0x2557) -ForegroundColor White
        Write-Host ("$([char]0x2551)" + ' '*46 + "$([char]0x2551)") -ForegroundColor White
        $mtLine = "  $mtText".PadRight(46)
        Write-Host "$([char]0x2551)" -ForegroundColor White -NoNewline
        Write-Host $mtLine -ForegroundColor Green -NoNewline
        Write-Host "$([char]0x2551)" -ForegroundColor White
        Write-Host ("$([char]0x2551)" + ' '*46 + "$([char]0x2551)") -ForegroundColor White
        $msLine = "  1) $msText".PadRight(46)
        Write-Host "$([char]0x2551)${msLine}$([char]0x2551)" -ForegroundColor White
        $meLine = "  2) $meText".PadRight(46)
        Write-Host "$([char]0x2551)${meLine}$([char]0x2551)" -ForegroundColor White
        Write-Host ("$([char]0x2551)" + ' '*46 + "$([char]0x2551)") -ForegroundColor White
        Write-Host ([char]0x255A + ([string][char]0x2550)*46 + [char]0x255D) -ForegroundColor White
        Write-Host ""
        Write-Host "  $(T 'menu_prompt') [1-2]: " -NoNewline; $mc = Read-Host

        switch ($mc) {
            "1" {
                Run-SpeedTest
                Write-Host ""; Write-Host "  $(T 'any_key') " -ForegroundColor DarkGray -NoNewline
                $null = [Console]::ReadKey($true); Write-Host ""
            }
            "2" { Wait-AndExit }
            default { Write-Warn "$(T 'menu_prompt'): 1 / 2" }
        }
    }
}

# ======================== RESET & LANGUAGE ========================
function Reset-Config {
    if (Test-Path $script:ConfigFile) {
        Remove-Item $script:ConfigFile -Force
        Write-Ok (T "cfg_reset"); Write-Info (T "next_setup")
    } else { Write-Info (T "no_config") }
}

function Change-Language([string]$Choice) {
    if (-not $Choice) {
        Write-Host ""; Write-Host "  1) Turkce"; Write-Host "  2) English"
        Write-Host ""; Write-Host "  [1-2]: " -NoNewline; $Choice = Read-Host
    }
    switch -Regex ($Choice) {
        '^(1|tr|TR|turkce)$'  { $script:LangPref = "TR"; break }
        '^(2|en|EN|english)$' { $script:LangPref = "EN"; break }
        default { Write-Warn "TR / EN"; return }
    }
    Update-ConfigLang
    if ($script:LangPref -eq "TR") { Write-Ok "Dil: Turkce olarak ayarlandi." }
    else { Write-Ok "Language: Set to English." }
}

# ======================== BANNER ========================
function Show-Banner {
    Write-Host ""
    if ($script:LangPref -eq "TR") {
        Write-BoxTop
        Write-BoxLine @("White","  ","Magenta","INTERNET AVCISI","White"," - LTE Bant Optimizasyonu (Global)")
        Write-BoxSep
        Write-BoxEmpty
        Write-BoxLine @("White","  Ne yapar?")
        Write-BoxLine @("White","  ZTE LTE modeminizin tum bantlarini test eder, her bant")
        Write-BoxLine @("White","  icin 5 oyun sunucusuna ping atar, ping/jitter/kayip")
        Write-BoxLine @("White","  olcer ve en iyi bandi otomatik secer.")
        Write-BoxEmpty
        Write-BoxLine @("White","  Nasil calisir?")
        Write-BoxLine @("White","  Modem paneline (goform API) HTTP ile baglanir, bant")
        Write-BoxLine @("White","  kilidini degistirir, sinyal olcumu yapar, en iyi")
        Write-BoxLine @("White","  bandi kalici olarak ayarlar.")
        Write-BoxEmpty
        Write-BoxLine @("White","  Bolgeler: ","Cyan","TR EU NA LATAM ASIA ME AF OCEA")
        Write-BoxLine @("White","  Bantlar:  ","Cyan","21 LTE bant (B1-B43, bolgeye gore filtrelenir)")
        Write-BoxEmpty
        Write-BoxSep
        Write-BoxLine @("White","  Komutlar:")
        Write-BoxLine @("Green","  (parametresiz)","White","    Tum bantlari test et, en iyisini sec")
        Write-BoxLine @("Green","  --set <bant>","White","      Belirli bir banda gec (orn: 3, 20)")
        Write-BoxLine @("Green","  --status","White","          Sinyal durumu + oyun performansi")
        Write-BoxLine @("Green","  --watch","White","           Izle, kotulesirse tekrar optimize et")
        Write-BoxLine @("Green","  --auto","White","            Bant kilidini kaldir, otomatik mod")
        Write-BoxLine @("Green","  --servers","White","         Test edilen sunuculari goster")
        Write-BoxLine @("Green","  --lang","White","            Dil degistir (TR/EN)")
        Write-BoxLine @("Green","  --reset","White","           Ayarlari sifirla (kurulumu tekrarla)")
        Write-BoxLine @("Green","  --help","White","            Detayli yardim")
        Write-BoxEmpty
        Write-BoxLine @("DarkGray","  Gereksinimler: Windows PowerShell 5.1+ (yerlesik)")
        Write-BoxLine @("DarkGray","  Skor: Ping(%40) + Jitter(%35) + Kayip(%25) | Dusuk=Iyi")
        Write-BoxSep
        Write-BoxLine @("DarkGray","  Yapimci: ","White","Kaan (wilsonbia7)")
        Write-BoxBottom
    } else {
        Write-BoxTop
        Write-BoxLine @("White","  ","Magenta","INTERNET AVCISI","White"," - LTE Band Optimizer (Global)")
        Write-BoxSep
        Write-BoxEmpty
        Write-BoxLine @("White","  What does it do?")
        Write-BoxLine @("White","  Tests all LTE bands on your ZTE modem, pings 5 game")
        Write-BoxLine @("White","  servers per band, measures ping/jitter/packet loss,")
        Write-BoxLine @("White","  and locks the best band for gaming automatically.")
        Write-BoxEmpty
        Write-BoxLine @("White","  How does it work?")
        Write-BoxLine @("White","  Connects to modem admin panel (goform API) via HTTP,")
        Write-BoxLine @("White","  switches band lock, waits for signal, runs tests,")
        Write-BoxLine @("White","  then sets the winning band permanently.")
        Write-BoxEmpty
        Write-BoxLine @("White","  Regions: ","Cyan","TR EU NA LATAM ASIA ME AF OCEA")
        Write-BoxLine @("White","  Bands:   ","Cyan","21 LTE bands (B1-B43, region-filtered)")
        Write-BoxEmpty
        Write-BoxSep
        Write-BoxLine @("White","  Commands:")
        Write-BoxLine @("Green","  (no args)","White","         Test all bands, pick the best")
        Write-BoxLine @("Green","  --set <band>","White","      Lock to a specific band (e.g. 3, 20)")
        Write-BoxLine @("Green","  --status","White","          Show signal info + game performance")
        Write-BoxLine @("Green","  --watch","White","           Monitor and re-optimize if degraded")
        Write-BoxLine @("Green","  --auto","White","            Remove band lock, return to auto")
        Write-BoxLine @("Green","  --servers","White","         List game servers being tested")
        Write-BoxLine @("Green","  --lang","White","            Change language (TR/EN)")
        Write-BoxLine @("Green","  --reset","White","           Reset saved config (re-run setup)")
        Write-BoxLine @("Green","  --help","White","            Full help")
        Write-BoxEmpty
        Write-BoxLine @("DarkGray","  Requires: Windows PowerShell 5.1+ (built-in)")
        Write-BoxLine @("DarkGray","  Score: Ping(40%) + Jitter(35%) + Loss(25%) | Lower=Better")
        Write-BoxSep
        Write-BoxLine @("DarkGray","  Created by: ","White","Kaan (wilsonbia7)")
        Write-BoxBottom
    }
    Write-Host ""
}

# ======================== HELP ========================
function Show-Help {
    if ($script:LangPref -eq "TR") {
        Write-Host "Internet Avcisi - LTE Bant Optimizasyonu (Global)" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "Kullanim:" -ForegroundColor White
        Write-Host "  .\internet-avcisi.ps1                  Oyun icin en iyi bandi bul"
        Write-Host "  .\internet-avcisi.ps1 --set 3          Belirli bir banda gec"
        Write-Host "  .\internet-avcisi.ps1 --status         Sinyal + oyun durumunu goster"
        Write-Host "  .\internet-avcisi.ps1 --auto           Otomatik moda don"
        Write-Host "  .\internet-avcisi.ps1 --watch          Izle, kotulesirse optimize et"
        Write-Host "  .\internet-avcisi.ps1 --watch 60 20    Ozel esiklerle izle (ping jitter)"
        Write-Host "  .\internet-avcisi.ps1 --servers        Bolge sunucularini goster"
        Write-Host "  .\internet-avcisi.ps1 --lang           Dil degistir (TR/EN)"
        Write-Host "  .\internet-avcisi.ps1 --lang tr        Direkt Turkce'ye gecis"
        Write-Host "  .\internet-avcisi.ps1 --reset          Ayarlari sifirla"
        Write-Host ""
        Write-Host "Desteklenen bantlar (--set):" -ForegroundColor White
        Write-Host "  FDD:" -ForegroundColor Cyan -NoNewline; Write-Host " 1, 2, 3, 4, 5, 7, 8, 12, 13, 17, 20, 25, 26, 28, 32"
        Write-Host "  TDD:" -ForegroundColor Cyan -NoNewline; Write-Host " 38, 39, 40, 41, 42, 43"
        Write-Host ""
        Write-Host "Bolgeler:" -ForegroundColor White
        Write-Host "  TR (Turkiye)  EU (Avrupa)    NA (K. Amerika)  LATAM (Latin Am.)"
        Write-Host "  ASIA (Asya)   ME (Orta Dogu) AF (Afrika)      OCEA (Okyanusya)"
        Write-Host "  Bolge ilk kurulumda secilir."
        Write-Host ""
        Write-Host "Skor sistemi:" -ForegroundColor White
        Write-Host "  Ping (%$($script:WeightAvgPing)) + Jitter (%$($script:WeightJitter)) + Kayip (%$($script:WeightPacketLoss)) = Oyun Skoru"
        Write-Host "  Dusuk skor = daha iyi oyun deneyimi"
        Write-Host ""
        Write-Host "Ping degerlendirmesi:" -ForegroundColor White
        Write-Host "  0-30ms  MUKEMMEL  |  30-50ms  COK IYI"
        Write-Host "  50-80ms IYI       |  80-120ms OYNANIR"
        Write-Host "  120ms+  KOTU"
        Write-Host ""
        Write-Host "Uyumlu modemler:" -ForegroundColor White
        Write-Host "  ZTE tabanli LTE modemler (MF286R, MF283V, MC801A,"
        Write-Host "  MF279, Superbox, GigaCube ve benzeri ZTE cihazlar)"
    } else {
        Write-Host "Internet Avcisi - LTE Band Optimizer (Global)" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "Usage:" -ForegroundColor White
        Write-Host "  .\internet-avcisi.ps1                  Find best band for gaming"
        Write-Host "  .\internet-avcisi.ps1 --set 3          Lock to a specific band"
        Write-Host "  .\internet-avcisi.ps1 --status         Show signal + gaming stats"
        Write-Host "  .\internet-avcisi.ps1 --auto           Return to automatic mode"
        Write-Host "  .\internet-avcisi.ps1 --watch          Monitor, re-optimize if needed"
        Write-Host "  .\internet-avcisi.ps1 --watch 60 20    Custom thresholds (ping jitter)"
        Write-Host "  .\internet-avcisi.ps1 --servers        Show test servers for region"
        Write-Host "  .\internet-avcisi.ps1 --lang           Change language (TR/EN)"
        Write-Host "  .\internet-avcisi.ps1 --lang en        Switch directly to English"
        Write-Host "  .\internet-avcisi.ps1 --reset          Reset config (re-run setup)"
        Write-Host ""
        Write-Host "Supported bands (--set):" -ForegroundColor White
        Write-Host "  FDD:" -ForegroundColor Cyan -NoNewline; Write-Host " 1, 2, 3, 4, 5, 7, 8, 12, 13, 17, 20, 25, 26, 28, 32"
        Write-Host "  TDD:" -ForegroundColor Cyan -NoNewline; Write-Host " 38, 39, 40, 41, 42, 43"
        Write-Host ""
        Write-Host "Regions:" -ForegroundColor White
        Write-Host "  TR (Turkey)  EU (Europe)   NA (N. America)  LATAM (Latin Am.)"
        Write-Host "  ASIA (Asia)  ME (Mid East) AF (Africa)      OCEA (Oceania)"
        Write-Host "  Region is selected during first-run setup."
        Write-Host ""
        Write-Host "Score system:" -ForegroundColor White
        Write-Host "  Ping ($($script:WeightAvgPing)%) + Jitter ($($script:WeightJitter)%) + Packet Loss ($($script:WeightPacketLoss)%) = Game Score"
        Write-Host "  Lower score = better gaming experience"
        Write-Host ""
        Write-Host "Ping rating:" -ForegroundColor White
        Write-Host "  0-30ms  EXCELLENT  |  30-50ms  VERY GOOD"
        Write-Host "  50-80ms GOOD       |  80-120ms PLAYABLE"
        Write-Host "  120ms+  POOR"
        Write-Host ""
        Write-Host "Compatible modems:" -ForegroundColor White
        Write-Host "  ZTE based LTE modems worldwide (MF286R, MF283V, MC801A,"
        Write-Host "  MF279, Superbox, GigaCube, and similar ZTE devices)"
    }
    Write-Host ""
    Write-Host "Config: $env:USERPROFILE\.lte-optimizer.conf | Reset: --reset" -ForegroundColor DarkGray
    Write-Host ""
}

# ======================== CLEANUP ========================
function Invoke-Cleanup {
    Stop-Spinner 2>$null
    $script:ModemPassword = ""
    $script:WebSession = $null
    try { [Console]::CursorVisible = $true } catch {}
}

function Wait-AndExit {
    Invoke-Cleanup
    Write-Host ""
    Write-Host "  $(T 'exit_msg') " -ForegroundColor DarkGray -NoNewline
    $null = [Console]::ReadKey($true)
    Write-Host ""
    exit 0
}

# ======================== MAIN EXECUTION ========================
try {
    Preload-Lang

    # Language selection on first run
    if ($script:LangPref -eq "__ASK__") {
        Write-Host ""
        Write-Host ([char]0x2554 + ([string][char]0x2550)*36 + [char]0x2557) -ForegroundColor White
        $iaLine = "  INTERNET AVCISI".PadRight(36)
        Write-Host "$([char]0x2551)" -ForegroundColor White -NoNewline
        Write-Host $iaLine -ForegroundColor Magenta -NoNewline
        Write-Host "$([char]0x2551)" -ForegroundColor White
        Write-Host ([char]0x2560 + ([string][char]0x2550)*36 + [char]0x2563) -ForegroundColor White
        Write-Host ("$([char]0x2551)" + ' '*36 + "$([char]0x2551)") -ForegroundColor White
        $trLine = "  1) Turkce".PadRight(36)
        Write-Host "$([char]0x2551)${trLine}$([char]0x2551)" -ForegroundColor White
        $enLine = "  2) English".PadRight(36)
        Write-Host "$([char]0x2551)${enLine}$([char]0x2551)" -ForegroundColor White
        Write-Host ("$([char]0x2551)" + ' '*36 + "$([char]0x2551)") -ForegroundColor White
        Write-Host ([char]0x255A + ([string][char]0x2550)*36 + [char]0x255D) -ForegroundColor White
        Write-Host ""
        Write-Host "  Dil / Language [1-2]: " -NoNewline; $lc = Read-Host
        switch ($lc) { "1" { $script:LangPref = "TR" } default { $script:LangPref = "EN" } }
        Update-ConfigLang
        Write-Host ""
    }

    Show-Banner

    # CLI dispatch
    switch -Regex ($Action) {
        '^(--status|-s)$' {
            Show-Status
            Show-PostActionMenu
        }
        '^(--set|-b)$' {
            Set-SpecificBand $Param1
            Show-PostActionMenu
        }
        '^(--auto|-a)$' {
            Initialize-Config
            if (Login-Modem) { Set-Auto; Write-Ok (T "auto_ok") }
            Show-PostActionMenu
        }
        '^(--watch|-w)$' {
            Start-WatchMode $Param1 $Param2
        }
        '^--servers$' {
            Show-Servers
            Wait-AndExit
        }
        '^--reset$' {
            Reset-Config
            Wait-AndExit
        }
        '^--lang$' {
            Change-Language $Param1
            Wait-AndExit
        }
        '^(--help|-h)$' {
            Show-Help
            Wait-AndExit
        }
        default {
            Start-Optimization
            Show-PostActionMenu
        }
    }
} finally {
    Invoke-Cleanup
}
