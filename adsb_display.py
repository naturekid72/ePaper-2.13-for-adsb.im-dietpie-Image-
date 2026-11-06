#!/usr/bin/env python3
import os
import sys
import time
import math
import json
import yaml
import signal
import requests
from datetime import datetime, date
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.yaml")
EXAMPLE_CONFIG_PATH = os.path.join(BASE_DIR, "config.example.yaml")
STATE_FILE = "/tmp/adsb_daily_state.json"

cfg_file = CONFIG_PATH if os.path.exists(CONFIG_PATH) else EXAMPLE_CONFIG_PATH
with open(cfg_file, "r") as f:
    config = yaml.safe_load(f)

STATION_NAME = str(config.get("station_name", "FR24 T-EHRD735"))
API_BASE = str(config.get("api_base", "http://127.0.0.1:8080/data")).rstrip("/")
HOME_LAT = float(config.get("home_lat", 51.1780))
HOME_LON = float(config.get("home_lon", 7.1890))
REFRESH_INTERVAL = int(config.get("refresh_sec", 10))
ROTATE_180 = bool(config.get("rotate_180", False))

running = True
current_day = date.today().isoformat()
seen_hex_today = set()
max_distance_today = 0.0
last_messages_total = None
last_check_time = None

def handle_exit(signum, frame):
    global running
    running = False

signal.signal(signal.SIGTERM, handle_exit)
signal.signal(signal.SIGINT, handle_exit)

def load_daily_state():
    global current_day, seen_hex_today, max_distance_today
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                st = json.load(f)
            if st.get("day") == date.today().isoformat():
                current_day = st["day"]
                seen_hex_today = set(st.get("hex", []))
                max_distance_today = float(st.get("max_km", 0.0))
        except Exception:
            pass

def save_daily_state():
    try:
        with open(STATE_FILE, "w") as f:
            json.dump({
                "day": current_day,
                "hex": list(seen_hex_today),
                "max_km": max_distance_today
            }, f)
    except Exception:
        pass

def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0)**2
    return 2.0 * R * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))

def compass_bearing(lat1, lon1, lat2, lon2):
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dlon = math.radians(lon2 - lon1)
    x = math.sin(dlon) * math.cos(phi2)
    y = math.cos(phi1) * math.sin(phi2) - (math.sin(phi1) * math.cos(phi2) * math.cos(dlon))
    initial_bearing = math.degrees(math.atan2(x, y))
    compass = (initial_bearing + 360) % 360
    dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    return dirs[round(compass / 45) % 8]

def fetch_data():
    global current_day, seen_hex_today, max_distance_today, last_messages_total, last_check_time

    today_str = date.today().isoformat()
    if today_str != current_day:
        current_day = today_str
        seen_hex_today.clear()
        max_distance_today = 0.0

    try:
        r = requests.get(f"{API_BASE}/aircraft.json", timeout=3)
        r.raise_for_status()
        data = r.json()
    except Exception:
        return {"online": False}

    now = data.get("now", time.time())
    total_msgs = data.get("messages", 0)

    if last_messages_total is not None and last_check_time is not None and (now > last_check_time):
        msg_s = int(round((total_msgs - last_messages_total) / (now - last_check_time)))
    else:
        msg_s = 0
    last_messages_total = total_msgs
    last_check_time = now

    aircraft_list = data.get("aircraft", [])
    total_ac = len(aircraft_list)
    with_pos = 0
    nearest_ac = None
    min_dist = 99999.0

    for ac in aircraft_list:
        hex_code = ac.get("hex")
        if hex_code:
            seen_hex_today.add(hex_code)

        if "lat" in ac and "lon" in ac:
            with_pos += 1
            dist = haversine_km(HOME_LAT, HOME_LON, ac["lat"], ac["lon"])
            if dist > max_distance_today:
                max_distance_today = dist
            if dist < min_dist:
                min_dist = dist
                bearing = compass_bearing(HOME_LAT, HOME_LON, ac["lat"], ac["lon"])
                callsign = (ac.get("flight") or hex_code or "---").strip()
                alt = ac.get("alt_baro", ac.get("alt_geom", "---"))
                if isinstance(alt, (int, float)):
                    alt_str = f"{int(alt)} ft"
                elif str(alt).lower() == "ground":
                    alt_str = "GND"
                else:
                    alt_str = "--- ft"

                nearest_ac = {
                    "callsign": callsign[:8],
                    "alt": alt_str,
                    "dist": f"{int(round(dist))} km",
                    "dir": bearing
                }

    save_daily_state()

    return {
        "online": True,
        "total_ac": total_ac,
        "with_pos": with_pos,
        "msg_s": max(0, msg_s),
        "today": len(seen_hex_today),
        "max_km": int(round(max_distance_today)),
        "nearest": nearest_ac
    }

def render_frame(stats):
    img = Image.new("1", (250, 122), 255)
    draw = ImageDraw.Draw(img)

    f_path = "/usr/share/fonts/truetype/dejavu/"
    f_bold_11 = ImageFont.truetype(f_path + "DejaVuSans-Bold.ttf", 11)
    f_reg_10 = ImageFont.truetype(f_path + "DejaVuSans.ttf", 10)
    f_bold_12 = ImageFont.truetype(f_path + "DejaVuSans-Bold.ttf", 12)
    f_reg_11 = ImageFont.truetype(f_path + "DejaVuSans.ttf", 11)
    f_huge = ImageFont.truetype(f_path + "DejaVuSans-Bold.ttf", 34)
    f_bottom = ImageFont.truetype(f_path + "DejaVuSans-Bold.ttf", 14)

    draw.ellipse((4, 5, 14, 15), outline=0, width=1)
    draw.point((9, 10), fill=0)
    draw.text((19, 4), STATION_NAME, font=f_bold_11, fill=0)

    time_str = datetime.now().strftime("%H:%M")
    status_txt = f"online  {time_str}" if stats.get("online") else f"offline {time_str}"
    tw = draw.textlength(status_txt, font=f_reg_10)
    draw.text((246 - tw, 5), status_txt, font=f_reg_10, fill=0)
    if stats.get("online"):
        draw.ellipse((246 - tw - 9, 8, 246 - tw - 4, 13), fill=0)

    draw.line((0, 21, 250, 21), fill=0, width=1)

    if not stats.get("online"):
        draw.text((18, 52), "Waiting for adsb.im data...", font=f_bold_12, fill=0)
        if ROTATE_180:
            img = img.rotate(180)
        return img

    draw.text((8, 24), str(stats["total_ac"]), font=f_huge, fill=0)
    draw.text((8, 64), f"aircraft · {stats['with_pos']} with pos", font=f_reg_10, fill=0)

    x_right = 152
    val1 = f"{stats['msg_s']} "
    w1 = draw.textlength(val1, font=f_bold_12)
    draw.text((x_right, 25), val1, font=f_bold_12, fill=0)
    draw.text((x_right + w1, 26), "msg/s", font=f_reg_11, fill=0)

    val2 = f"{stats['today']} "
    w2 = draw.textlength(val2, font=f_bold_12)
    draw.text((x_right, 43), val2, font=f_bold_12, fill=0)
    draw.text((x_right + w2, 44), "today", font=f_reg_11, fill=0)

    val3 = f"{stats['max_km']} "
    w3 = draw.textlength(val3, font=f_bold_12)
    draw.text((x_right, 61), val3, font=f_bold_12, fill=0)
    draw.text((x_right + w3, 62), "km max", font=f_reg_11, fill=0)

    draw.line((0, 82, 250, 82), fill=0, width=1)
    draw.text((8, 85), "nearest", font=f_reg_10, fill=0)

    n = stats.get("nearest")
    if n:
        bottom_line = f"{n['callsign']}  {n['alt']}  {n['dist']}  {n['dir']}"
    else:
        bottom_line = "No aircraft in range"
    draw.text((8, 100), bottom_line, font=f_bottom, fill=0)

    if ROTATE_180:
        img = img.rotate(180)

    return img

def main():
    from waveshare_epd import epd2in13_V4

    load_daily_state()
    epd = epd2in13_V4.EPD()
    epd.init()
    epd.Clear(0xFF)

    refresh_counter = 0
    try:
        while running:
            stats = fetch_data()
            image = render_frame(stats)
            buf = epd.getbuffer(image)

            if refresh_counter % 30 == 0:
                epd.init()
                epd.displayPartBaseImage(buf)
            else:
                epd.displayPartial(buf)

            refresh_counter += 1

            for _ in range(REFRESH_INTERVAL * 10):
                if not running:
                    break
                time.sleep(0.1)
    finally:
        try:
            epd.sleep()
        except Exception:
            pass
        sys.exit(0)

if __name__ == "__main__":
    main()
