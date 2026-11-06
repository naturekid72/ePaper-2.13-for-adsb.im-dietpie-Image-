#!/usr/bin/env python3
from adsb_display import render_frame, fetch_data

stats = fetch_data()
if not stats.get("online"):
    stats = {
        "online": True,
        "total_ac": 2,
        "with_pos": 2,
        "msg_s": 15,
        "today": 58,
        "max_km": 45,
        "nearest": {
            "callsign": "KLM1938",
            "alt": "6275 ft",
            "dist": "6 km",
            "dir": "NW"
        }
    }

img = render_frame(stats)
img.save("preview.png")
print("Vorschau erfolgreich gespeichert unter: preview.png")
