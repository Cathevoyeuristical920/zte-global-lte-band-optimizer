# Internet Avcisi / Internet Hunter

**Global LTE Band Optimizer for Gaming**

ZTE tabanli LTE modemlerde oyun icin en iyi bandi otomatik bulan ve kilitleyen arac.
A tool that automatically finds and locks the best LTE band for gaming on ZTE-based modems.

---

## TR - Turkce

### Ne Yapar?

Internet Avcisi, ZTE tabanli LTE modeminizin tum bantlarini tek tek test eder, her bant icin birden fazla oyun sunucusuna ping atar ve en dusuk gecikme / en az kayip saglayan bandi otomatik olarak kilitler.

### Ozellikler

- **21 LTE bant destegi** (B1-B43, FDD + TDD) - bolgeye gore filtrelenir
- **8 bolge** - TR, EU, NA, LATAM, ASIA, ME, AF, OCEA
- **Oyuncu odakli skorlama** - Ping (%40) + Jitter (%35) + Paket Kaybi (%25)
- **Medyan ping hesabi** - Tek bir spike tum bandi cokmez, gercek deneyiminizi olcer
- **PDV Jitter** - Ardisik ping farklarinin ortalamasi (RFC 3550 uyumlu)
- **Isinma pingi** - Bant gecisi sonrasi PDP context icin warm-up
- **Stabilite bonusu** - Mevcut bant yeterince iyiyse gereksiz gecis yapmaz
- **Minimum sunucu esigi** - 5 sunucudan 2'sine ulasamayan bant direkt elenir
- **Watch modu** - Surekli izler, bozulursa otomatik yeniden optimize eder
- **ZTE Goform API** - Modem paneline HTTP ile baglanir, bant kilidini degistirir
- **Turkce & Ingilizce** - Tam iki dilli arayuz
- **Sifre guvenligi** - Sifre diske kaydedilmez, her calistirmada sorulur

### Gereksinimler

- Windows 10/11
- Windows PowerShell 5.1+ (yerlesik, ekstra kurulum gerekmez)
- ZTE tabanli LTE modem (MF286R, MF283V, MC801A, MF279, Superbox, GigaCube vb.)

### Kurulum

1. Bu repoyu indirin veya klonlayin:
   ```
   git clone https://github.com/wilsonbia7/zte-global-lte-band-optimizer.git
   ```
2. Klasoru acin, hepsi bu kadar. Kurulum gerekmez.

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

```
Skor = Ping(%40) + Jitter(%35) + Paket Kaybi(%25)
Dusuk skor = Daha iyi oyun deneyimi
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
   Her bant icin:
     1. Bant kilidini degistir
     2. 15 sn sinyal stabilizasyonu bekle
     3. 1 isinma pingi at (sonucu kaydetme)
     4. 10 ping at (medyan + PDV jitter hesapla)
     5. 5 oyun sunucusuna tekrarla
     6. Skor hesapla
        |
   Stabilite kontrolu
   (mevcut bant +-5 puan icindeyse degistirme)
        |
   En iyi bandi kilitle + dogrulama testi
```

---

## EN - English

### What Does It Do?

Internet Avcisi tests all LTE bands on your ZTE-based modem one by one, pings multiple game servers per band, and automatically locks the band with the lowest latency and least packet loss for gaming.

### Features

- **21 LTE bands supported** (B1-B43, FDD + TDD) - filtered by region
- **8 regions** - TR, EU, NA, LATAM, ASIA, ME, AF, OCEA
- **Gaming-focused scoring** - Ping (40%) + Jitter (35%) + Packet Loss (25%)
- **Median ping calculation** - A single spike won't ruin a band, measures your real experience
- **PDV Jitter** - Average of consecutive ping differences (RFC 3550 compliant)
- **Warm-up ping** - Pre-test ping after band switch for PDP context
- **Stability bonus** - Won't switch if current band is good enough (within 5 points)
- **Minimum server threshold** - Band is disqualified if fewer than 2/5 servers reachable
- **Watch mode** - Continuous monitoring, auto re-optimizes if quality degrades
- **ZTE Goform API** - Connects to modem panel via HTTP, changes band lock
- **Turkish & English** - Fully bilingual interface
- **Password security** - Password is never saved to disk, asked each run

### Requirements

- Windows 10/11
- Windows PowerShell 5.1+ (built-in, no extra install needed)
- ZTE-based LTE modem (MF286R, MF283V, MC801A, MF279, Superbox, GigaCube, etc.)

### Installation

1. Download or clone this repo:
   ```
   git clone https://github.com/wilsonbia7/zte-global-lte-band-optimizer.git
   ```
2. Open the folder, that's it. No installation required.

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

```
Score = Ping(40%) + Jitter(35%) + Packet Loss(25%)
Lower score = Better gaming experience
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
   For each band:
     1. Set band lock
     2. Wait 15s for signal stabilization
     3. Send 1 warm-up ping (result discarded)
     4. Send 10 pings (median + PDV jitter)
     5. Repeat for 5 game servers
     6. Calculate score
        |
   Stability check
   (keep current band if within +-5 points)
        |
   Lock best band + verification test
```

---

## License

MIT License - See [LICENSE](LICENSE) for details.

## Author

**Kaan** ([@wilsonbia7](https://github.com/wilsonbia7))
