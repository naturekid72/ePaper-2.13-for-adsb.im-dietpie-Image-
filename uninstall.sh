#!/bin/bash
set -e

INSTALL_DIR="/opt/adsb-epaper"
SERVICE_FILE="/etc/systemd/system/adsb-display.service"

echo "=== Starte Deinstallation: ADS-B e-Paper Display ==="

if [ "$EUID" -ne 0 ]; then
  echo "Bitte als root ausführen (sudo bash uninstall.sh)"
  exit 1
fi

# 1. Dienst stoppen und deaktivieren
if systemctl is-active --quiet adsb-display 2>/dev/null; then
    echo "[1/4] Stoppe laufenden Service..."
    systemctl stop adsb-display
fi

if [ -f "$SERVICE_FILE" ]; then
    echo "[2/4] Entferne Systemd-Service..."
    systemctl disable adsb-display 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
fi

# 2. Display sauber löschen (Weißbild gegen Ghosting/Einbrennen)
echo "[3/4] Schalte e-Paper Display sauber ab..."
python3 - << 'EOF' 2>/dev/null || true
try:
    from waveshare_epd import epd2in13_V4
    epd = epd2in13_V4.EPD()
    epd.init()
    epd.Clear(0xFF)
    epd.sleep()
except Exception:
    pass
EOF

# 3. Dateien und Cache bereinigen
echo "[4/4] Entferne Installationsverzeichnis und Cache..."
rm -rf "$INSTALL_DIR"
rm -f /tmp/adsb_daily_state.json

echo "================================================================="
echo "Deinstallation erfolgreich abgeschlossen!"
echo "Das Verzeichnis $INSTALL_DIR und der Dienst wurden entfernt."
echo "================================================================="
