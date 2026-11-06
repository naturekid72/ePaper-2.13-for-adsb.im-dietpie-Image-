# ADS-B Flight Tracker e-Paper Display (Waveshare 2.13" V4 & adsb.im)

Ein minimalistisches Echtzeit-Statusdisplay für einen **Raspberry Pi Zero 2 W** und das **Waveshare 2.13" e-Paper HAT (V4)** auf Basis des **DietPi-basierten [adsb.im](https://adsb.im) Feeder-Images**.

## Features & Display-Aufbau
Das Display bildet auf 250×122 Pixeln alle wichtigen Metriken des lokalen Feeders ab:
- **Kopfzeile:** Eigener Stationsname, Online-Status und aktuelle Uhrzeit
- **Links:** Große Anzeige der aktuell empfangenen Flugzeuge (inkl. Anzahl mit GPS-Position)
- **Rechts:** Aktuelle Nachrichtenrate (`msg/s`), getrackte eindeutige Flugzeuge seit Mitternacht (`today`) und maximale Tagesreichweite (`km max`)
- **Fußzeile (`nearest`):** Nächstgelegenes Flugzeug mit Callsign, Flughöhe (`ft`), Distanz (`km`) und Himmelsrichtung (`N`, `NE`, `NW` etc.)
- **Automatische Konfiguration:** Liest Koordinaten und Stationsnamen automatisch aus der bestehenden `adsb.im`-Konfiguration aus.

---

## 3D-gedrucktes Gehäuse (Hardware-Referenz)

Dieses Projekt wurde speziell für dieses kompakte 3D-Druck-Gehäuse entwickelt:
👉 **[ADS-B Flight Tracker w/ Pi Zero 2W, Nooelec, Display auf MakerWorld](https://makerworld.com/de/models/3540241-adsb-flight-tracker-w-pi-zero-2w-nooelec-display?from=search#profileId-4048770)**

### Benötigte Hardware
- **Board:** Raspberry Pi Zero 2 W (mit aufgelöteter GPIO-Stiftleiste)
- **Display:** Waveshare 2.13inch e-Paper HAT V4 (250×122 Pixel, Schwarz/Weiß)
- **SDR-Stick:** Nooelec NESDR Nano 3 (oder kompakter RTL-SDR) + 1090 MHz Antenne

---

## Installation mit einem Befehl

1. Verbinde dich per SSH mit deinem Raspberry Pi (`ssh root@adsb-feeder.local`).
2. Führe das Installationsskript aus:
   ```bash
   curl -sSL [https://raw.githubusercontent.com/DEIN_GITHUB_USER/adsb-epaper-2in13/main/install.sh](https://raw.githubusercontent.com/DEIN_GITHUB_USER/adsb-epaper-2in13/main/install.sh) | sudo bash
