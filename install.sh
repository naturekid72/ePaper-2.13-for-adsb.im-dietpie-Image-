#!/bin/bash
set -e

REPO_URL="https://github.com/naturekid72/adsb-epaper-2in13.git"
INSTALL_DIR="/opt/adsb-epaper"

echo "=== Starte Installation: ADS-B e-Paper Display (Waveshare 2.13 V4) ==="

if [ "$EUID" -ne 0 ]; then
  echo "Bitte als root ausführen (sudo bash install.sh)"
  exit 1
fi

echo "[1/6] Aktiviere SPI-Schnittstelle..."
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

echo "[2/6] Installiere System-Abhängigkeiten..."
apt-get update -qq
apt-get install -y -qq git python3-pil python3-requests python3-yaml python3-spidev python3-gpiozero python3-lgpio fonts-dejavu-core

echo "[3/6] Installiere Waveshare e-Paper Treiber..."
if ! python3 -c "import waveshare_epd" >/dev/null 2>&1; then
    TEMP_WS=$(mktemp -d)
    git clone --depth 1 --filter=blob:none --sparse https://github.com/waveshareteam/e-Paper.git "$TEMP_WS"
    cd "$TEMP_WS"
    git sparse-checkout set RaspberryPi_JetsonNano/python/lib/waveshare_epd
    cp -r RaspberryPi_JetsonNano/python/lib/waveshare_epd /usr/local/lib/python3.*/dist-packages/
    cd /
    rm -rf "$TEMP_WS"
fi

echo "[4/6] Richte Projektverzeichnis unter $INSTALL_DIR ein..."
if [ -d "$INSTALL_DIR/.git" ]; then
    cd "$INSTALL_DIR"
    git pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo "[5/6] Erstelle Konfiguration..."
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

echo "[6/6] Richte Systemd-Autostart ein..."
cp "$INSTALL_DIR/adsb-display.service" /etc/systemd/system/adsb-display.service
systemctl daemon-reload
systemctl enable adsb-display.service
systemctl restart adsb-display.service

echo "================================================================="
echo "Installation abgeschlossen!"
echo "Konfigurationsdatei: $INSTALL_DIR/config.yaml"
echo "HINWEIS: Falls SPI gerade erst aktiviert wurde, bitte einmal neu starten: reboot"
echo "================================================================="
