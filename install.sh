#!/bin/bash
set -e

REPO_URL="https://github.com/naturekid72/ePaper-2.13-for-adsb.im-dietpie-Image-.git"
INSTALL_DIR="/opt/adsb-epaper"

echo "=== Starte Installation: ADS-B e-Paper Display (Waveshare 2.13 V4) ==="

# 1. Root-Check
if [ "$EUID" -ne 0 ]; then
  echo "Bitte als root ausführen (sudo bash install.sh)"
  exit 1
fi

# 2. SPI aktivieren
echo "[1/5] Aktiviere SPI-Schnittstelle..."
if [ -f /boot/dietpi/func/dietpi-set_hardware ]; then
    /boot/dietpi/func/dietpi-set_hardware spi enable
elif command -v raspi-config >/dev/null 2>&1; then
    raspi-config nonint do_spi 0
else
    for cfg in /boot/config.txt /boot/firmware/config.txt; do
        if [ -f "$cfg" ] && ! grep -q "^dtparam=spi=on" "$cfg"; then
            echo "dtparam=spi=on" >> "$cfg"
        fi
    done
fi

# 3. System-Pakete installieren
echo "[2/5] Installiere System-Abhängigkeiten..."
apt-get update -qq
apt-get install -y -qq git curl python3-pip python3-pil python3-requests python3-yaml python3-spidev python3-gpiozero python3-lgpio fonts-dejavu-core

# 4. Waveshare-Treiber ohne Git installieren (über PyPI oder Fallback)
echo "[3/5] Installiere Waveshare e-Paper Treiber..."
if ! python3 -c "import waveshare_epd" >/dev/null 2>&1; then
    pip3 install waveshare-epd --break-system-packages 2>/dev/null || {
        # Fallback falls PyPI fehlschlägt: Normaler Standard-Clone ohne Blobless-Filter
        TEMP_WS=$(mktemp -d)
        git clone --depth 1 https://github.com/waveshareteam/e-Paper.git "$TEMP_WS"
        python3 -m pip install "$TEMP_WS/RaspberryPi_JetsonNano/python/" --break-system-packages
        rm -rf "$TEMP_WS"
    }
fi

# 5. Projekt einrichten
echo "[4/5] Richte Projektverzeichnis unter $INSTALL_DIR ein..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Einzelne Dateien direkt per raw.githubusercontent laden (kein Git-Login nötig!)
BASE_RAW="https://raw.githubusercontent.com/naturekid72/ePaper-2.13-for-adsb.im-dietpie-Image-/main"
curl -sSL "$BASE_RAW/adsb_display.py" -o "$INSTALL_DIR/adsb_display.py"
curl -sSL "$BASE_RAW/config.example.yaml" -o "$INSTALL_DIR/config.example.yaml"
curl -sSL "$BASE_RAW/adsb-display.service" -o "$INSTALL_DIR/adsb-display.service"
curl -sSL "$BASE_RAW/preview.py" -o "$INSTALL_DIR/preview.py" || true

# 6. Konfiguration erstellen (automatisch aus adsb.im)
echo "[5/5] Erstelle Konfiguration..."
if [ ! -f "$INSTALL_DIR/config.yaml" ]; then
    cp "$INSTALL_DIR/config.example.yaml" "$INSTALL_DIR/config.yaml"
    
    ADSB_ENV="/opt/adsb/config/.env"
    if [ -f "$ADSB_ENV" ]; then
        echo " -> adsb.im Konfiguration gefunden! Übernehme Standort & Stationsname..."
        LAT=$(grep -E '^FEEDER_LAT=' "$ADSB_ENV" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        LON=$(grep -E '^FEEDER_LONG=' "$ADSB_ENV" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        NAME=$(grep -E '^MLAT_SITE_NAME=' "$ADSB_ENV" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        
        [ -n "$LAT" ] && sed -i "s/^home_lat:.*/home_lat: $LAT/" "$INSTALL_DIR/config.yaml"
        [ -n "$LON" ] && sed -i "s/^home_lon:.*/home_lon: $LON/" "$INSTALL_DIR/config.yaml"
        [ -n "$NAME" ] && sed -i "s/^station_name:.*/station_name: \"$NAME\"/" "$INSTALL_DIR/config.yaml"
    fi
fi

# 7. Systemd-Service scharfschalten
cp "$INSTALL_DIR/adsb-display.service" /etc/systemd/system/adsb-display.service
systemctl daemon-reload
systemctl enable adsb-display.service
systemctl restart adsb-display.service

echo "================================================================="
echo "Installation erfolgreich abgeschlossen!"
echo "Status prüfen mit: systemctl status adsb-display"
echo "Falls SPI neu aktiviert wurde: reboot"
echo "================================================================="
