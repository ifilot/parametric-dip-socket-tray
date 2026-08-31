// SPDX-License-Identifier: CERN-OHL-S-2.0

/*
 * Parametric stackable tray for inexpensive 300/600 mil DIP sockets.
 * Designed for FDM printing, with a common 160 x 160 mm stacking interface.
 *
 * Export examples:
 *   openscad -o dip14-tray.stl -D 'pins=14' -D 'part="tray"' dip_socket_tray.scad
 *   openscad -o dip14-label.stl -D 'pins=14' -D 'part="label"' dip_socket_tray.scad
 *   openscad -o fit-test.stl   -D 'part="fit_test"' dip_socket_tray.scad
 */

/* [Main] */
pins = 14;                    // [14,16,18,20,28,32,40]
part = "assembly";            // [assembly,tray,label,fit_test]
show_sockets = true;          // Preview-only reference sockets

/* [Socket] */
narrow_socket_width = 10.16;  // Overall width for 300 mil sockets
wide_socket_width = 17.78;    // Overall width for 600 mil sockets
socket_height = 5.10;         // Body height above its underside
pin_pitch = 2.54;
narrow_row_spacing = 7.62;
wide_row_spacing = 15.24;
pin_drop = 3.60;              // Conservative pins-below-body allowance
pin_clearance = 0.40;         // Free space below pin tips
side_clearance = 0.30;        // Body-to-guide clearance per side
socket_end_gap = 0.60;        // Gap between sockets in a row
narrow_support_ridge_width = 4.00;
wide_support_ridge_width = 11.50;

/* [Tray] */
tray_size = [160, 160];
base_thickness = 1.80;
outer_wall = 3.20;
corner_radius = 6;
guide_width = 0.80;
guide_height = 4.20;          // Guide height above body support
vertical_clearance = 2.00;    // Socket top to the next tray bottom

/* [Stacking interface] */
stack_lip_width = 1.20;
stack_lip_height = 1.20;
stack_fit = 0.30;             // Horizontal clearance on each side
stack_groove_depth = 1.40;
stack_inset = 1.00;

/* [Label] */
label_depth = 0.60;
label_height = 4.5;
label_font = "Liberation Sans:style=Bold";
label_z = 7.0;

/* [Quality] */
$fn = $preview ? 40 : 80;

eps = 0.01;
valid_pins = pins == 14 || pins == 16 || pins == 18 || pins == 20
          || pins == 28 || pins == 32 || pins == 40;
is_wide_socket = pins == 28 || pins == 32 || pins == 40;
socket_width = is_wide_socket ? wide_socket_width : narrow_socket_width;
pin_row_spacing = is_wide_socket ? wide_row_spacing : narrow_row_spacing;
support_ridge_width = is_wide_socket
                    ? wide_support_ridge_width
                    : narrow_support_ridge_width;
socket_length = pins / 2 * pin_pitch;
support_z = base_thickness + pin_drop + pin_clearance;
stack_plane_z = support_z + socket_height + vertical_clearance;
channel_width = socket_width + 2 * side_clearance;
row_pitch = channel_width + guide_width;
inner_size = [tray_size[0] - 2 * outer_wall,
              tray_size[1] - 2 * outer_wall];
row_count = floor((inner_size[0] + guide_width) / row_pitch);
socket_count_per_row = floor((inner_size[1] + socket_end_gap) /
                             (socket_length + socket_end_gap));
used_rows_width = row_count * channel_width + (row_count - 1) * guide_width;
rows_x0 = (tray_size[0] - used_rows_width) / 2;
used_socket_length = socket_count_per_row * socket_length
                   + (socket_count_per_row - 1) * socket_end_gap;
sockets_y0 = (tray_size[1] - used_socket_length) / 2;
label_text = str("DIP-", pins);

assert(valid_pins, "pins must be 14, 16, 18, 20, 28, 32, or 40");
assert(base_thickness > stack_groove_depth,
       "The stacking groove must leave some base thickness");
assert(support_ridge_width < pin_row_spacing - 1.0,
       "Support ridge is too wide and may contact inward-bent pins");
assert(row_count > 0 && socket_count_per_row > 0,
       "Socket dimensions leave no usable storage positions");

echo(str("DIP-", pins, ": ", row_count, " rows x ",
         socket_count_per_row, " sockets = ",
         row_count * socket_count_per_row, " sockets"));
echo(str("Stacking pitch: ", stack_plane_z, " mm; overall printed height: ",
         stack_plane_z + stack_lip_height, " mm"));

module rounded_rect_2d(size, radius) {
    offset(r = radius)
        square([size[0] - 2 * radius, size[1] - 2 * radius], center = true);
}

module rounded_ring_2d(outer_size, width, radius) {
    difference() {
        rounded_rect_2d(outer_size, radius);
        rounded_rect_2d([outer_size[0] - 2 * width,
                         outer_size[1] - 2 * width],
                        max(radius - width, 0.01));
    }
}

module tray_base() {
    translate([tray_size[0] / 2, tray_size[1] / 2, 0])
        linear_extrude(base_thickness)
            rounded_rect_2d(tray_size, corner_radius);
}

module perimeter_wall() {
    translate([tray_size[0] / 2, tray_size[1] / 2,
               base_thickness - eps])
        linear_extrude(stack_plane_z - base_thickness + 2 * eps)
            rounded_ring_2d(tray_size, outer_wall, corner_radius);
}

module stack_lip() {
    lip_outer = [tray_size[0] - 2 * stack_inset,
                 tray_size[1] - 2 * stack_inset];
    translate([tray_size[0] / 2, tray_size[1] / 2,
               stack_plane_z - eps])
        linear_extrude(stack_lip_height + eps)
            rounded_ring_2d(lip_outer, stack_lip_width,
                            corner_radius - stack_inset);
}

module stack_groove_cut() {
    groove_outer = [tray_size[0] - 2 * (stack_inset - stack_fit),
                    tray_size[1] - 2 * (stack_inset - stack_fit)];
    groove_width = stack_lip_width + 2 * stack_fit;
    translate([tray_size[0] / 2, tray_size[1] / 2, -eps])
        linear_extrude(stack_groove_depth + eps)
            rounded_ring_2d(groove_outer, groove_width,
                            corner_radius - stack_inset + stack_fit);
}

module storage_rails() {
    // Each socket bridges two uninterrupted pin trenches and rests only on
    // the central dike. Guides on both sides of every channel keep the bodies
    // upright, including in the two channels next to the perimeter wall.
    for (row = [0 : row_count - 1]) {
        cx = rows_x0 + channel_width / 2 + row * row_pitch;

        translate([cx - support_ridge_width / 2, outer_wall,
                   base_thickness - eps])
            cube([support_ridge_width, inner_size[1],
                  support_z - base_thickness + eps]);
    }

    for (divider = [0 : row_count]) {
        x = rows_x0 + divider * channel_width
          + (divider - 1) * guide_width;
        translate([x, outer_wall, base_thickness - eps])
            cube([guide_width, inner_size[1],
                  support_z + guide_height - base_thickness + eps]);
    }
}

module front_label(depth = label_depth + 2 * eps) {
    // Text lies on the outside of the front wall. Rotating about X maps the
    // text extrusion into Y, leaving Z as the readable vertical direction.
    translate([tray_size[0] / 2, depth - eps, label_z])
        rotate([90, 0, 0])
            linear_extrude(depth)
                text(label_text, size = label_height, font = label_font,
                     halign = "center", valign = "center");
}

module tray() {
    difference() {
        union() {
            tray_base();
            perimeter_wall();
            storage_rails();
            stack_lip();
        }
        stack_groove_cut();
        front_label();
    }
}

module label_inlay() {
    // Export as a second STL and load it as another part of the same object
    // in PrusaSlicer. It occupies exactly the volume removed from the tray.
    front_label();
}

module reference_socket() {
    color([0.12, 0.12, 0.12, 0.75])
        translate([-socket_width / 2, -socket_length / 2, support_z])
            cube([socket_width, socket_length, socket_height]);

    color([0.75, 0.75, 0.75, 0.8])
        for (side = [-1, 1], i = [0 : pins / 2 - 1])
            translate([side * pin_row_spacing / 2 - 0.25,
                       -socket_length / 2 + pin_pitch / 2 + i * pin_pitch,
                       support_z - pin_drop])
                cube([0.5, 0.5, pin_drop]);
}

module socket_preview_array() {
    if ($preview && show_sockets)
        for (row = [0 : row_count - 1], item = [0 : socket_count_per_row - 1]) {
            cx = rows_x0 + channel_width / 2 + row * row_pitch;
            cy = sockets_y0 + socket_length / 2
               + item * (socket_length + socket_end_gap);
            translate([cx, cy, 0]) reference_socket();
        }
}

module fit_test() {
    test_length = socket_length + 10;
    test_width = channel_width + 2 * guide_width;

    difference() {
        union() {
            cube([test_width, test_length, base_thickness]);
            translate([(test_width - support_ridge_width) / 2, 0,
                       base_thickness - eps])
                cube([support_ridge_width, test_length,
                      support_z - base_thickness + eps]);
            for (x = [0, test_width - guide_width])
                translate([x, 0, base_thickness - eps])
                    cube([guide_width, test_length,
                          support_z + guide_height - base_thickness + eps]);
        }
    }

    if ($preview && show_sockets)
        translate([test_width / 2, test_length / 2, 0]) reference_socket();
}

if (part == "tray") {
    tray();
} else if (part == "label") {
    label_inlay();
} else if (part == "fit_test") {
    fit_test();
} else {
    color("LightSteelBlue") tray();
    color("white") label_inlay();
    socket_preview_array();
}
