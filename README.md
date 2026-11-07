# ADS-B Flight Tracker e-Paper Display (Waveshare 2.13" V4 & adsb.im)

Ein minimalistisches Echtzeit-Statusdisplay für den **Raspberry Pi Zero 2 W** und das **Waveshare 2.13" e-Paper HAT (V4)** auf Basis des **DietPi-basierten [adsb.im](https://adsb.im) Feeder-Images**.

Das Display stellt die wichtigsten Metriken deines lokalen Feeders direkt auf 250×122 Pixeln dar:
- **Kopfzeile:** Stationsname, Feeder-Status (`online`/`offline`) und aktuelle Uhrzeit
- **Links:** Große Anzeige der aktuell empfangenen Flugzeuge (`aircraft`) inkl. Anzahl mit bekannter Position (`with pos`)
- **Rechts:** Nachrichtenrate (`msg/s`), heute empfangene Flugzeuge (`today`) und maximale Tagesdistanz (`km max`)
- **Fußzeile (`nearest`):** Nächstgelegenes Flugzeug mit Rufzeichen/Hex-Code, Höhe (`ft`), Entfernung (`km`) und Kompassrichtung (`N`, `NE`, `NW` etc.)
- **Automatische Einrichtung:** Breitengrad, Längengrad und Stationsname werden bei der Installation automatisch aus der bestehenden Konfiguration von `adsb.im` übernommen.

---

## 3D-Druck Gehäuse (Hardware-Referenz)

Das Layout und die Kabelführung sind auf folgendes Gehäuse abgestimmt:  
👉 **[ADS-B Flight Tracker w/ Pi Zero 2W, Nooelec, Display auf MakerWorld](https://makerworld.com/de/models/3540241-adsb-flight-tracker-w-pi-zero-2w-nooelec-display?from=search#profileId-4048770)**

---

## Hardware-Anforderungen

| Komponente | Details / Empfehlung |
| :--- | :--- |
| **SBC** | Raspberry Pi Zero 2 W (mit 40-Pin GPIO-Stiftleiste) |
| **Display** | Waveshare 2.13inch e-Paper HAT (V4, Schwarz/Weiß, 250×122 Pixel) |
| **SDR-Empfänger** | Nooelec NESDR Nano 3 (oder RTL-SDR v3 / v4 mit kurzem OTG-Kabel) |
| **Speicherkarte** | MicroSD ab 8 GB (Empfehlung: 16/32 GB High Endurance) |
| **Stromversorgung** | 5V / min. 2.5A Micro-USB Netzteil |
| **Antenne** | 1090 MHz Antenne mit passendem SMA-Anschluss |

---

## Benötigtes Betriebssystem-Image

Für die direkte Hardware-Ansteuerung über SPI/GPIO wird das **DietPi-basierte Image** von adsb.im benötigt:

1. Gehe auf **[adsb.im/home](https://adsb.im/home)**.
2. Wähle das **DietPi-basierte Image** für den Raspberry Pi (z. B. `adsb-im-raspberrypi64-pi-2-3-4-5-...img.xz`).
   * *Wichtig:* Nicht das geschlossene Appliance-Image (MicroOS) wählen, da dieses den Host-Zugriff auf die GPIO/SPI-Treiber einschränkt.
3. Image mit dem Raspberry Pi Imager oder BalenaEtcher flashen.
4. Pi starten, im Webinterface unter `http://adsb-feeder.local` die Ersteinrichtung abschließen (Standortkoordinaten & Feeder einrichten).

---

## Installation (One-Liner)

Verbinde dich per SSH mit deinem Raspberry Pi:

```bash
ssh root@adsb-feeder.local
```
*(Standardpasswort bei DietPi ist `dietpi`, sofern noch nicht geändert)*

Führe folgenden Befehl aus:

```bash
curl -sSL https://raw.githubusercontent.com/naturekid72/ePaper-2.13-for-adsb.im-dietpie-Image-/main/install.sh | sudo bash
```

Nach Abschluss des Skripts den Pi einmal neu starten, um den SPI-Bus zu aktivieren:

```bash
reboot
```

---

## Deinstallation (One-Liner)

Um den Hintergrunddienst zu stoppen, das Display spannungsfrei weiß zu schalten und alle installierten Dateien restlos zu entfernen:

```bash
curl -sSL https://raw.githubusercontent.com/naturekid72/ePaper-2.13-for-adsb.im-dietpie-Image-/main/uninstall.sh | sudo bash
```

---

## Optionale Konfiguration

Die Konfiguration wird automatisch unter `/opt/adsb-epaper/config.yaml` angelegt. Bei Bedarf (z. B. um das Display um 180° zu drehen oder den Stationsnamen anzupassen) kann die Datei editiert werden:

```bash
nano /opt/adsb-epaper/config.yaml
```

Beispiel:
```yaml
station_name: "FR24 T-EHRD735"
api_base: "http://127.0.0.1:8080/data"
home_lat: 51.1780
home_lon: 7.1890
refresh_sec: 10
rotate_180: false
```

Nach Änderungen den Dienst neu starten:
```bash
systemctl restart adsb-display
```

## Troubleshooting
- **Live-Logs anzeigen:** `journalctl -u adsb-display -f`
- **Dienst-Status prüfen:** `systemctl status adsb-display`
- **Testbild generieren:** `cd /opt/adsb-epaper && python3 preview.py`

## Lizenz
MIT License
