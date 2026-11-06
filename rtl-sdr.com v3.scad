// ============================================================================
// Parametrisches ADS-B Flight Tracker Gehäuse (RTL-SDR.com v3 / v4 Edition)
// Für Raspberry Pi Zero 2 W + Waveshare 2.13" e-Paper HAT V4 + RTL-SDR v3/v4
// ============================================================================

$fn = 60;

// --- AUSWAHL FÜR DEN EXPORT ---
// "both" = Beide Teile | "bottom" = Unterschale | "top" = Deckel
part_to_render = "both"; 

// --- ANTENNEN-ANSCHLUSS TYP ---
// "direct"   = Großer Durchlass (Ø 14mm), SMA-Gewinde vom Stick schaut direkt raus
// "bulkhead" = 6.5mm Loch für verschraubbare SMA-Einbaubuchse (Pigtail)
sma_mount_type = "direct";

// --- HAUPTABMESSUNGEN GEHÄUSE (mm) ---
box_l = 115.0;        // Gesamtlänge (X) - Platz für Stick + OTG-Kabelbogen
box_w = 78.0;         // Gesamtbreite (Y) - Pi Zero + RTL-SDR v3 nebeneinander
bottom_h = 26.0;      // Höhe Unterschale (Z)
top_h = 8.0;          // Höhe Deckel (Z)
wall = 2.4;           // Wandstärke
corner_r = 5.0;       // Außenradius der Ecken

// --- RASPBERRY PI ZERO 2 W PARAMETER (vorne links) ---
pi_hole_dx = 58.0;
pi_hole_dy = 23.0;
pi_x_offset = 10.0;   // Abstand von links
pi_y_offset = 42.0;   // Sitzt im hinteren/oberen Bereich unter dem Display
standoff_h = 5.0;

// --- RTL-SDR.COM V3 / V4 PARAMETER (Alu-Gehäuse: 68 x 27 x 13 mm) ---
sdr_l = 69.0;         // Länge Körper inkl. Toleranz
sdr_w = 27.6;         // Breite inkl. 0.6mm Drucktoleranz
sdr_h = 13.2;         // Höhe Alu-Körper
sdr_x = box_l - wall - sdr_l; // Bündig an der rechten Außenwand (SMA-Seite)
sdr_y = 8.0;          // Sitzt im vorderen Bereich neben dem Pi
sdr_z_bed = 3.0;      // 3mm Auflagehöhe über Boden für Unterlüftung

// --- WAVESHARE 2.13" V4 DISPLAY AUSSCHNITT ---
disp_w = 50.0;        // Sichtfenster Länge (X)
disp_h = 25.0;        // Sichtfenster Breite (Y)
disp_x = 12.0;        // Passend über dem Pi Zero
disp_y = 41.0;

// --- KABELKANAL VORNE (Stromversorgung Pi Zero) ---
slot_x = 52.0;
slot_w = 12.0;
slot_depth = 16.0;

// --- HILFSFUNKTION: ABGERUNDETE BOX ---
module rounded_box(l, w, h, r) {
    hull() {
        translate([r, r, 0]) cylinder(r=r, h=h);
        translate([l-r, r, 0]) cylinder(r=r, h=h);
        translate([r, w-r, 0]) cylinder(r=r, h=h);
        translate([l-r, w-r, 0]) cylinder(r=r, h=h);
    }
}

// --- HILFSFUNKTION: FLUGZEUG-PIKTOGRAMM ---
module airplane_icon(depth=1.0) {
    linear_extrude(height=depth) {
        polygon([[0,-12], [1.8,-8], [1.8,10], [0,14], [-1.8,10], [-1.8,-8]]);
        polygon([[0,3], [14,-3], [14,-5.5], [0,-1], [-14,-5.5], [-14,-3]]);
        polygon([[0,-8], [6,-11], [6,-12.5], [0,-10.5], [-6,-12.5], [-6,-11]]);
    }
}

// --- HILFSFUNKTION: HALTERUNG FÜR RTL-SDR V3 ---
module rtlsdr_cradle() {
    // Zwei Querbrücken mit seitlichen Führungsnasen für den 27mm breiten Stick
    for (x_pos = [sdr_x + 12, sdr_x + sdr_l - 18]) {
        translate([x_pos, sdr_y - 2.0, wall]) {
            // Unterbau (3mm hoch für Luftstrom unter dem Alu-Gehäuse)
            cube([8.0, sdr_w + 4.0, sdr_z_bed]);
            // Linke & rechte Klemmwange (8mm hoch)
            cube([8.0, 2.0, sdr_z_bed + 8.0]);
            translate([0, sdr_w + 2.0, 0])
                cube([8.0, 2.0, sdr_z_bed + 8.0]);
        }
    }
    // Anschlag hinten Richtung USB-Port (verhindert Verrutschen beim Antennenanschrauben)
    translate([sdr_x - 2.4, sdr_y + 4, wall])
        cube([2.4, sdr_w - 8, sdr_z_bed + 5.0]);
}

// ============================================================================
// 1. UNTERSCHALE (BOTTOM CASE)
// ============================================================================
module bottom_case() {
    sma_center_y = sdr_y + sdr_w / 2.0;
    sma_center_z = wall + sdr_z_bed + sdr_h / 2.0;

    difference() {
        union() {
            rounded_box(box_l, box_w, bottom_h, corner_r);
            // Snap-Fit Lippe
            translate([wall/2, wall/2, bottom_h])
                rounded_box(box_l - wall, box_w - wall, 1.6, corner_r - wall/2);
        }

        // Innenraum aushöhlen
        translate([wall, wall, wall])
            rounded_box(box_l - 2*wall, box_w - 2*wall, bottom_h + 5, corner_r - wall);

        // Vorderer Kabelschacht (USB-Power Kanal)
        translate([slot_x, -1, wall])
            cube([slot_w, slot_depth + 1, bottom_h + 5]);

        // SMA-Antennenauslass (Rechte Seitenwand, exakt mittig vor dem RTL-SDR v3)
        translate([box_l - wall - 1, sma_center_y, sma_center_z])
            rotate([0, 90, 0]) {
                if (sma_mount_type == "bulkhead") {
                    cylinder(d=6.6, h=wall + 2); // Für SMA-Schottbuchse mit Mutter
                } else {
                    cylinder(d=14.0, h=wall + 2); // Freier Durchgang für SMA-Stecker/Kappe
                }
            }

        // Boden-Lüftungsschlitze direkt unter dem RTL-SDR v3 (Kamineffekt)
        for (i = [0:5]) {
            translate([sdr_x + 22 + i*6, sdr_y + 4, -1])
                cube([2.5, sdr_w - 8, wall + 2]);
        }
    }

    // Wandung um den vorderen USB-Kabelschacht schließen
    difference() {
        translate([slot_x - wall, 0, 0])
            cube([slot_w + 2*wall, slot_depth + wall, bottom_h]);
        translate([slot_x, -1, wall])
            cube([slot_w, slot_depth + 1, bottom_h + 2]);
        // Durchlass für das Micro-USB-Stromkabel zum Pi
        translate([slot_x + 1.5, slot_depth - 1, wall + 2])
            cube([slot_w - 3.0, wall + 2, bottom_h]);
    }

    // Pi Zero 2 W Standoffs (M2.5)
    holes = [
        [0, 0],
        [pi_hole_dx, 0],
        [0, pi_hole_dy],
        [pi_hole_dx, pi_hole_dy]
    ];
    for (p = holes) {
        translate([pi_x_offset + 3.5 + p[0], pi_y_offset + 3.5 + p[1], wall]) {
            difference() {
                cylinder(d=5.8, h=standoff_h);
                translate([0, 0, -0.5]) cylinder(d=2.2, h=standoff_h + 1);
            }
        }
    }

    // RTL-SDR v3/v4 Halterung einfügen
    rtlsdr_cradle();
}

// ============================================================================
// 2. DECKEL (TOP LID)
// ============================================================================
module top_lid() {
    difference() {
        rounded_box(box_l, box_w, top_h, corner_r);

        // Snap-Fit Gegenstück (0.15mm Toleranz)
        translate([wall/2 - 0.15, wall/2 - 0.15, -0.1])
            rounded_box(box_l - wall + 0.3, box_w - wall + 0.3, 1.8, corner_r - wall/2);

        // Deckel innen aussparen
        translate([wall, wall, -0.1])
            rounded_box(box_l - 2*wall, box_w - 2*wall, top_h - wall + 0.1, corner_r - wall);

        // 1. Display-Sichtfenster (mit 45°-Fase)
        translate([disp_x, disp_y, -1])
            cube([disp_w, disp_h, top_h + 2]);
        hull() {
            translate([disp_x, disp_y, top_h - 1.2])
                cube([disp_w, disp_h, 0.1]);
            translate([disp_x - 1.5, disp_y - 1.5, top_h])
                cube([disp_w + 3.0, disp_h + 3.0, 0.1]);
        }

        // 2. Vorderer Kabelschacht-Ausschnitt
        translate([slot_x, -1, -1])
            cube([slot_w, slot_depth + 1, top_h + 2]);

        // 3. Lüftungsschlitze rechts oben (7 Schlitze für Abwärme)
        for (i = [0:6]) {
            translate([76 + i*4.2, 48, -1])
                cube([2.2, 18, top_h + 2]);
        }

        // 4. Eingelassenes Flugzeug-Piktogramm rechts unten (über dem RTL-SDR)
        translate([90, 22, top_h - 0.8])
            rotate([0, 0, 35])
            airplane_icon(1.2);
    }
}

// ============================================================================
// RENDER-AUSGABE
// ============================================================================
if (part_to_render == "bottom") {
    bottom_case();
} else if (part_to_render == "top") {
    translate([0, box_w, top_h]) rotate([180, 0, 0]) top_lid();
} else {
    bottom_case();
    translate([0, box_w + 15 + box_w, top_h])
        rotate([180, 0, 0])
        top_lid();
}
