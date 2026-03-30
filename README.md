# Internet Avcisi / Internet Hunter

**Global LTE Band Optimizer for Gaming**

A tool that automatically finds and locks the best LTE band for gaming on ZTE-based modems.
ZTE tabanli LTE modemlerde oyun icin en iyi bandi otomatik bulan ve kilitleyen arac.

---

## EN - English

### What Does It Do?

Internet Avcisi optimizes your LTE connection for gaming using a **2-phase approach**:

1. **Signal Scan** - Measures hardware-level signal quality (RSRP, SNR, RSRQ) on every band, applies bandwidth preference (wider bands = lower latency), and selects the top 3 candidates
2. **Gaming Test** - Runs ping/jitter/packet loss tests only on the best candidates and locks the winner

This is far more reliable than testing all bands blindly, because signal metrics are hardware-level measurements that don't fluctuate like ping tests do.

### Features

- **2-phase optimization** - Signal scan first, gaming test only on top candidates
- **Signal quality scoring** - RSRP (40%) + SNR (40%) + RSRQ (20%) from modem hardware
- **Bandwidth preference** - Wide bands (B3, B7, B42) get bonus, narrow bands (B20, B28) get penalty
- **21 LTE bands supported** (B1-B43, FDD + TDD) - filtered by region
- **8 regions** - TR, EU, NA, LATAM, ASIA, ME, AF, OCEA
- **Gaming-focused scoring** - Ping (40%) + Jitter (35%) + Packet Loss (25%)
- **Median ping calculation** - A single spike won't ruin a band's score
- **PDV Jitter** - Average of consecutive ping differences (RFC 3550 compliant)
- **Warm-up ping** - Pre-test ping after band switch for PDP context
- **Watch mode** - Continuous monitoring, auto re-optimizes if quality degrades
- **ZTE Goform API** - Connects to modem panel via HTTP, changes band lock
- **Turkish & English** - Fully bilingual interface
- **Password security** - Password is never saved to disk, asked each run

### Requirements

- Windows 10/11
- Windows PowerShell 5.1+ (built-in, no extra install needed)
- ZTE-based LTE modem (MF286R, MF283V, MC801A, MF279, Superbox, GigaCube, etc.)

### Installation

1. **[Download the latest release](https://github.com/wilsonbia7/zte-global-lte-band-optimizer/releases/latest)** (.zip file)
2. Extract the zip
3. Double-click `baslat.bat`

That's it. No installation required.

**Alternative (for developers):**
```
git clone https://github.com/wilsonbia7/zte-global-lte-band-optimizer.git
```

### Usage

**Easiest way** - Double-click `baslat.bat`. The script handles the rest.

**Via PowerShell:**

```powershell
# Test all bands, pick the best
.\internet-avcisi.ps1

# Lock to a specific band
.\internet-avcisi.ps1 --set 3

# Show signal info + gaming stats
.\internet-avcisi.ps1 --status

# Monitor and re-optimize if degraded
.\internet-avcisi.ps1 --watch

# Custom thresholds (ping 60ms, jitter 20ms)
.\internet-avcisi.ps1 --watch 60 20

# Remove band lock, return to auto
.\internet-avcisi.ps1 --auto

# List game servers being tested
.\internet-avcisi.ps1 --servers

# Change language
.\internet-avcisi.ps1 --lang

# Reset saved config
.\internet-avcisi.ps1 --reset

# Full help
.\internet-avcisi.ps1 --help
```

### Score System

**Phase 1 - Signal Score (higher = better):**

```
Signal = RSRP(40%) + SNR(40%) + RSRQ(20%) x Bandwidth Multiplier
```

| Band Type | Bandwidth | Multiplier | Examples |
|-----------|-----------|------------|----------|
| Wide      | 15-20 MHz | x1.3 bonus | B3, B7, B38, B41, B42 |
| Medium    | 10-15 MHz | x1.0-1.2   | B1, B2, B4, B40 |
| Narrow    | 5-10 MHz  | x0.7 penalty | B5, B8, B20, B28 |

**Phase 2 - Gaming Score (lower = better):**

```
Score = Ping(40%) + Jitter(35%) + Packet Loss(25%)
```

| Ping      | Rating    |
|-----------|-----------|
| 0-30 ms   | EXCELLENT |
| 30-50 ms  | VERY GOOD |
| 50-80 ms  | GOOD      |
| 80-120 ms | PLAYABLE  |
| 120+ ms   | POOR      |

### Supported Bands

| Type | Bands |
|------|-------|
| FDD  | 1, 2, 3, 4, 5, 7, 8, 12, 13, 17, 20, 25, 26, 28, 32 |
| TDD  | 38, 39, 40, 41, 42, 43 |

### How It Works

```
baslat.bat / PowerShell
        |
   Setup Wizard (first run)
   [Language -> Region -> IP -> Modem -> Login]
        |
   Connect to modem via HTTP (Goform API)
        |
   PHASE 1: SIGNAL SCAN
   For each band in region:
     1. Set band lock
     2. Wait 20s for signal stabilization
     3. Read RSRP, SNR, RSRQ from modem API
     4. Apply bandwidth multiplier
     5. Calculate signal score
        |
   Select top 3 bands by signal score
        |
   PHASE 2: GAMING TEST
   For each top candidate:
     1. Set band lock
     2. Wait 20s for signal stabilization
     3. Send warm-up ping (discarded)
     4. Send 10 pings to 5 servers
     5. Calculate median ping + PDV jitter
     6. Calculate gaming score
        |
   Lock best band + verification test
```

---

## TR - Turkce

### Ne Yapar?

Internet Avcisi, LTE baglantisinizi oyun icin **2 asamali yaklasimla** optimize eder:

1. **Sinyal Taramasi** - Her bandin donanim seviyesinde sinyal kalitesini (RSRP, SNR, RSRQ) olcer, bant genisligi tercihini uygular (genis bant = dusuk gecikme) ve en iyi 3 adayi secer
2. **Oyun Testi** - Sadece en iyi adaylara ping/jitter/kayip testi yapar ve kazanani kilitler

Bu, tum bantlari koru korune test etmekten cok daha guvenilirdir cunku sinyal metrikleri ping testleri gibi dalgalanmayan donanim seviyesi olcumlerdir.

### Ozellikler

- **2 asamali optimizasyon** - Once sinyal taramasi, oyun testi sadece en iyi adaylara
- **Sinyal kalitesi skorlamasi** - RSRP (%40) + SNR (%40) + RSRQ (%20) modem donanimdan
- **Bant genisligi tercihi** - Genis bantlar (B3, B7, B42) bonus, dar bantlar (B20, B28) ceza alir
- **21 LTE bant destegi** (B1-B43, FDD + TDD) - bolgeye gore filtrelenir
- **8 bolge** - TR, EU, NA, LATAM, ASIA, ME, AF, OCEA
- **Oyuncu odakli skorlama** - Ping (%40) + Jitter (%35) + Paket Kaybi (%25)
- **Medyan ping hesabi** - Tek bir spike tum bandin skorunu cokmez
- **PDV Jitter** - Ardisik ping farklarinin ortalamasi (RFC 3550 uyumlu)
- **Isinma pingi** - Bant gecisi sonrasi PDP context icin warm-up
- **Watch modu** - Surekli izler, bozulursa otomatik yeniden optimize eder
- **ZTE Goform API** - Modem paneline HTTP ile baglanir, bant kilidini degistirir
- **Turkce & Ingilizce** - Tam iki dilli arayuz
- **Sifre guvenligi** - Sifre diske kaydedilmez, her calistirmada sorulur

### Gereksinimler

- Windows 10/11
- Windows PowerShell 5.1+ (yerlesik, ekstra kurulum gerekmez)
- ZTE tabanli LTE modem (MF286R, MF283V, MC801A, MF279, Superbox, GigaCube vb.)

### Kurulum

1. **[Son surumu indirin](https://github.com/wilsonbia7/zte-global-lte-band-optimizer/releases/latest)** (.zip dosyasi)
2. Zip'i cikartin
3. `baslat.bat` dosyasina cift tiklayin

Hepsi bu kadar. Kurulum gerekmez.

**Alternatif (gelistiriciler icin):**
```
git clone https://github.com/wilsonbia7/zte-global-lte-band-optimizer.git
```

### Kullanim

**En kolay yol** - `baslat.bat` dosyasini cift tiklayin. Gerisini script halleder.

**PowerShell ile:**

```powershell
# Tum bantlari test et, en iyisini sec
.\internet-avcisi.ps1

# Belirli bir banda gec
.\internet-avcisi.ps1 --set 3

# Sinyal durumu + oyun performansi
.\internet-avcisi.ps1 --status

# Izle, kotulesirse tekrar optimize et
.\internet-avcisi.ps1 --watch

# Ozel esiklerle izle (ping 60ms, jitter 20ms)
.\internet-avcisi.ps1 --watch 60 20

# Bant kilidini kaldir, otomatik mod
.\internet-avcisi.ps1 --auto

# Test edilen sunuculari goster
.\internet-avcisi.ps1 --servers

# Dil degistir
.\internet-avcisi.ps1 --lang

# Ayarlari sifirla
.\internet-avcisi.ps1 --reset

# Yardim
.\internet-avcisi.ps1 --help
```

### Skor Sistemi

**Faz 1 - Sinyal Skoru (yuksek = iyi):**

```
Sinyal = RSRP(%40) + SNR(%40) + RSRQ(%20) x Bant Genisligi Carpani
```

| Bant Tipi | Genislik  | Carpan    | Ornekler |
|-----------|-----------|-----------|----------|
| Genis     | 15-20 MHz | x1.3 bonus | B3, B7, B38, B41, B42 |
| Orta      | 10-15 MHz | x1.0-1.2   | B1, B2, B4, B40 |
| Dar       | 5-10 MHz  | x0.7 ceza  | B5, B8, B20, B28 |

**Faz 2 - Oyun Skoru (dusuk = iyi):**

```
Skor = Ping(%40) + Jitter(%35) + Paket Kaybi(%25)
```

| Ping      | Degerlendirme |
|-----------|---------------|
| 0-30 ms   | MUKEMMEL      |
| 30-50 ms  | COK IYI       |
| 50-80 ms  | IYI           |
| 80-120 ms | OYNANIR       |
| 120+ ms   | KOTU          |

### Desteklenen Bantlar

| Tip | Bantlar |
|-----|---------|
| FDD | 1, 2, 3, 4, 5, 7, 8, 12, 13, 17, 20, 25, 26, 28, 32 |
| TDD | 38, 39, 40, 41, 42, 43 |

### Nasil Calisir?

```
baslat.bat / PowerShell
        |
   Kurulum Sihirbazi (ilk calistirma)
   [Dil -> Bolge -> IP -> Modem -> Giris]
        |
   Modeme HTTP ile baglan (Goform API)
        |
   FAZ 1: SINYAL TARAMASI
   Bolgedeki her bant icin:
     1. Bant kilidini degistir
     2. 20 sn sinyal stabilizasyonu bekle
     3. Modem API'den RSRP, SNR, RSRQ oku
     4. Bant genisligi carpanini uygula
     5. Sinyal skoru hesapla
        |
   Sinyal skoruna gore en iyi 3 banti sec
        |
   FAZ 2: OYUN TESTI
   Her aday icin:
     1. Bant kilidini degistir
     2. 20 sn sinyal stabilizasyonu bekle
     3. Isinma pingi at (sonucu kaydetme)
     4. 5 sunucuya 10'ar ping at
     5. Medyan ping + PDV jitter hesapla
     6. Oyun skoru hesapla
        |
   En iyi bandi kilitle + dogrulama testi
```

---

## License

MIT License - See [LICENSE](LICENSE) for details.

## Author

**Kaan** ([@wilsonbia7](https://github.com/wilsonbia7))
