// Wall-mountable Raspberry Pi 4B housing
// Intended orientation: floor against the wall, USB/Ethernet ports facing DOWN.
// Air enters at the bottom (port side, side vents, gap behind the case) and
// exits at the top wall and lid (chimney effect).

/* [Output] */
part = "print"; // [print, base, lid, assembly]
show_pcb = true; // ghost board in assembly view

/* [Raspberry Pi 4B] */
pcb_l = 85;
pcb_w = 56;
pcb_t = 1.4;
hole_off = 3.5;  // mounting hole distance from PCB edges
hole_dx = 58;
hole_dy = 49;

/* [Case] */
wall = 2.2;
floor_t = 2.5;
lid_t = 2.5;
clearance = 1.0;      // gap between PCB edge and inner wall
standoff_h = 5;
standoff_d = 6;
standoff_hole_d = 2.2; // pilot for M2.5 self-tapping screws
top_clear = 22;       // free height above PCB top surface
port_tol = 0.6;       // extra clearance around port cutouts

/* [Lid fit] */
lip_h = 3;
lip_w = 1.6;
lip_tol = 0.25;
boss_d = 7;
boss_off = 1;              // corner boss offset outward from the box corner
lid_screw_pilot_d = 2.5;   // M3 self-tapping
lid_screw_clear_d = 3.4;
boss_hole_depth = 12;

/* [Wall mount] */
wall_gap = 4;          // air gap between wall and case back
ear_w = 22;
ear_len = 14;
keyhole_head_d = 8.5;
keyhole_shank_d = 4.2;
keyhole_slot_len = 7;

/* [Ventilation] */
vent_w = 2;
vent_pitch = 4;
vent_seg_len = 22;     // max slot length before a stiffening bridge
vent_bridge = 3;
floor_vents = true;
lid_vents = true;
top_wall_vents = true;
side_vents = true;

/* [SR-71 lid bridge] */
sr71_bridge = true;
sr71_length = 68;     // nose to tail
sr71_line_w = 2;      // outline stroke width
sr71_filled = false;  // true = solid silhouette instead of outline
sr71_angle = 0;       // 0 = nose toward the top wall (x = 0)

/* [GPIO access] */
gpio_lid_opening = true;  // opening in the lid above the header
gpio_side_slot = true;    // notch in the side wall for flat cables
gpio_margin = 2;
gpio_slot_depth = 10;

/* [Fan] */
use_fan = false;
fan_size = 30;
fan_hole_spacing = 24;
fan_hole_d = 3.2;
fan_x = 30;  // fan centre in PCB coordinates (over the SoC)
fan_y = 30;

$fn = 40;

// ===== Derived values =====
in_x = pcb_l + 2 * clearance;
in_y = pcb_w + 2 * clearance;
out_x = in_x + 2 * wall;
out_y = in_y + 2 * wall;
H = floor_t + standoff_h + pcb_t + top_clear;
po = [wall + clearance, wall + clearance, floor_t + standoff_h + pcb_t]; // PCB origin at top surface

holes = [[hole_off, hole_off], [hole_off + hole_dx, hole_off],
         [hole_off, hole_off + hole_dy], [hole_off + hole_dx, hole_off + hole_dy]];
bosses = [[-boss_off, -boss_off], [out_x + boss_off, -boss_off],
          [-boss_off, out_y + boss_off], [out_x + boss_off, out_y + boss_off]];

gpio_c = [hole_off + 29, pcb_w - hole_off];
gpio_size = [51, 5.1];
gpio_x0 = po.x + gpio_c.x - gpio_size.x / 2 - gpio_margin;
gpio_len = gpio_size.x + 2 * gpio_margin;

lid_vent_l = pcb_l - 8;
lid_vent_w = gpio_c.y - gpio_size.y / 2 - gpio_margin - 7;

// SR-71 top view, right half, normalised to length 1 (nose at x = 0)
sr71_half = [
    [0.00, 0.000], [0.08, 0.012], [0.18, 0.030], [0.28, 0.050],
    [0.38, 0.075], [0.44, 0.088],                       // chine into inlet
    [0.36, 0.115], [0.44, 0.142],                       // inlet spike
    [0.47, 0.145], [0.86, 0.259], [0.90, 0.259],        // outer wing
    [0.88, 0.155], [0.98, 0.145], [1.00, 0.135],        // nacelle
    [1.00, 0.095], [0.98, 0.085], [0.86, 0.075],
    [0.88, 0.035], [0.96, 0.015], [0.99, 0.000]         // tail cone
];
sr71_pts = concat(sr71_half,
    [for (i = [len(sr71_half) - 2 : -1 : 1]) [sr71_half[i].x, -sr71_half[i].y]]);

// ===== Helpers =====

// Rounded slots along X inside an l x w area, extruded by depth
module vent_slots(l, w, depth) {
    n_rows = max(1, floor((w - vent_w) / vent_pitch) + 1);
    n_seg = max(1, ceil((l + vent_bridge) / (vent_seg_len + vent_bridge)));
    seg = (l - (n_seg - 1) * vent_bridge) / n_seg;
    y0 = (w - ((n_rows - 1) * vent_pitch + vent_w)) / 2;
    linear_extrude(depth)
        for (i = [0 : n_rows - 1], j = [0 : n_seg - 1])
            translate([j * (seg + vent_bridge), y0 + i * vent_pitch])
                hull() {
                    translate([vent_w / 2, vent_w / 2]) circle(d = vent_w);
                    translate([seg - vent_w / 2, vent_w / 2]) circle(d = vent_w);
                }
}

module sr71_bridge_2d() {
    module shape() translate([-sr71_length / 2, 0]) scale([sr71_length, sr71_length]) polygon(sr71_pts);
    rotate(sr71_angle)
        if (sr71_filled)
            offset(r = sr71_line_w / 2) shape();
        else
            difference() {
                offset(r = sr71_line_w / 2) shape();
                offset(r = -sr71_line_w / 2) shape();
            }
}

// Large opening toward +X, narrow slot toward -X (= up when mounted ports-down)
module keyhole() {
    translate([keyhole_slot_len / 2, 0]) circle(d = keyhole_head_d);
    hull() {
        translate([ keyhole_slot_len / 2, 0]) circle(d = keyhole_shank_d);
        translate([-keyhole_slot_len / 2, 0]) circle(d = keyhole_shank_d);
    }
}

module ear() {
    ear_t = wall_gap + floor_t;
    r = 3;
    difference() {
        translate([0, 0, -wall_gap]) hull() {
            translate([out_x / 2 - ear_w / 2, 0, 0]) cube([ear_w, wall, ear_t]);
            for (s = [-1, 1])
                translate([out_x / 2 + s * (ear_w / 2 - r), -ear_len + r, 0])
                    cylinder(r = r, h = ear_t);
        }
        translate([out_x / 2, -ear_len / 2, -wall_gap - 1])
            linear_extrude(ear_t + 2) keyhole();
    }
}

// Port on the y = 0 wall (power / HDMI); xc, zc relative to PCB origin
module port_y0(xc, w, h, zc) {
    translate([po.x + xc - w / 2 - port_tol, -1, po.z + zc - h / 2 - port_tol])
        cube([w + 2 * port_tol, wall + 2, h + 2 * port_tol]);
}

// Port on the x = max wall (USB / Ethernet), sitting on the PCB
module port_xmax(yc, w, h) {
    translate([out_x - wall - 1, po.y + yc - w / 2 - port_tol, po.z - 0.5])
        cube([wall + 2, w + 2 * port_tol, h + 0.5 + port_tol]);
}

// ===== Base =====
module base() {
    difference() {
        union() {
            difference() {
                cube([out_x, out_y, H]);
                translate([wall, wall, floor_t]) cube([in_x, in_y, H]);
            }
            // corner bosses double as wall spacers
            for (b = bosses)
                translate([b.x, b.y, -wall_gap]) cylinder(d = boss_d, h = H + wall_gap);
            ear();
            translate([0, out_y, 0]) mirror([0, 1, 0]) ear();
            for (h = holes)
                translate([po.x + h.x, po.y + h.y, floor_t - 0.01])
                    cylinder(d = standoff_d, h = standoff_h + 0.01);
        }

        for (h = holes)
            translate([po.x + h.x, po.y + h.y, 1])
                cylinder(d = standoff_hole_d, h = floor_t + standoff_h);

        for (b = bosses)
            translate([b.x, b.y, H - boss_hole_depth])
                cylinder(d = lid_screw_pilot_d, h = boss_hole_depth + 1);

        // y = 0 side: USB-C power, 2x micro HDMI, audio (sized for plug bodies)
        port_y0(11.2, 12, 7, 1.6);
        port_y0(26.0, 11, 7.5, 1.8);
        port_y0(39.5, 11, 7.5, 1.8);
        translate([po.x + 54, -1, po.z + 3])
            rotate([-90, 0, 0]) cylinder(d = 8 + 2 * port_tol, h = wall + 2);

        // x = max side: Ethernet, 2x dual USB
        port_xmax(45.75, 16, 13.5);
        port_xmax(27, 15, 16);
        port_xmax(9, 15, 16);

        // microSD slot (x = 0 side, below the PCB)
        translate([-1, po.y + 28 - 8, po.z - pcb_t - 3.5])
            cube([wall + 2, 16, pcb_t + 4]);

        if (floor_vents) {
            translate([po.x + 9, po.y + 2, -1]) vent_slots(47, pcb_w - 4, floor_t + 2);
            translate([po.x + 67, po.y + 2, -1]) vent_slots(pcb_l - 69, pcb_w - 4, floor_t + 2);
        }

        if (top_wall_vents) {
            z0 = po.z + 2;
            z1 = H - lip_h - 2;
            translate([wall + 1, wall + 3, z0]) rotate([0, -90, 0])
                vent_slots(z1 - z0, out_y - 2 * wall - 6, wall + 2);
        }

        if (side_vents) {
            z0 = po.z + 1;
            z1 = H - lip_h - 2;
            for (y = [wall + 1, out_y + 1])
                translate([po.x + 62, y, z0]) rotate([90, 0, 0])
                    vent_slots(20, z1 - z0, wall + 2);
        }

        if (gpio_side_slot)
            translate([gpio_x0, out_y - wall - 1, H - gpio_slot_depth])
                cube([gpio_len, wall + 2, gpio_slot_depth + 1]);
    }
}

// ===== Lid (z = 0 is the underside, lip points down) =====
module lid() {
    difference() {
        union() {
            linear_extrude(lid_t) {
                square([out_x, out_y]);
                for (b = bosses) translate(b) circle(d = boss_d);
            }
            translate([wall + lip_tol, wall + lip_tol, -lip_h]) difference() {
                cube([in_x - 2 * lip_tol, in_y - 2 * lip_tol, lip_h + 0.01]);
                translate([lip_w, lip_w, -1])
                    cube([in_x - 2 * lip_tol - 2 * lip_w, in_y - 2 * lip_tol - 2 * lip_w, lip_h + 2]);
            }
        }

        for (b = bosses)
            translate([b.x, b.y, -1]) cylinder(d = lid_screw_clear_d, h = lid_t + 2);

        if (lid_vents)
            difference() {
                translate([po.x + 4, po.y + 4, -1])
                    vent_slots(lid_vent_l, lid_vent_w, lid_t + 2);
                if (sr71_bridge)
                    translate([po.x + 4 + lid_vent_l / 2, po.y + 4 + lid_vent_w / 2, -2])
                        linear_extrude(lid_t + 4) sr71_bridge_2d();
                if (use_fan)
                    translate([po.x + fan_x, po.y + fan_y, 0])
                        cube([fan_size + 4, fan_size + 4, 10], center = true);
            }

        if (use_fan)
            translate([po.x + fan_x, po.y + fan_y, -1]) {
                cylinder(d = fan_size - 2, h = lid_t + 2, $fn = 80);
                for (sx = [-1, 1], sy = [-1, 1])
                    translate([sx * fan_hole_spacing / 2, sy * fan_hole_spacing / 2, 0])
                        cylinder(d = fan_hole_d, h = lid_t + 2);
            }

        if (gpio_lid_opening)
            translate([gpio_x0, po.y + gpio_c.y - gpio_size.y / 2 - gpio_margin, -lip_h - 1])
                cube([gpio_len, gpio_size.y + 2 * gpio_margin, lid_t + lip_h + 2]);

        if (gpio_side_slot)
            translate([gpio_x0, out_y - wall - lip_tol - lip_w - 1, -lip_h - 1])
                cube([gpio_len, wall + lip_tol + lip_w + 2, lip_h + 1.01]);
    }
}

module pcb_ghost() {
    %translate([po.x, po.y, po.z - pcb_t]) {
        cube([pcb_l, pcb_w, pcb_t]);
        translate([gpio_c.x - gpio_size.x / 2, gpio_c.y - gpio_size.y / 2, pcb_t])
            cube([gpio_size.x, gpio_size.y, 8.5]);
    }
}

// ===== Output =====
if (part == "base") base();
else if (part == "lid") lid();
else if (part == "assembly") {
    base();
    translate([0, 0, H]) lid();
    if (show_pcb) pcb_ghost();
}
else {
    base();
    translate([out_x + 20, out_y, lid_t]) rotate([180, 0, 0]) lid();
}
