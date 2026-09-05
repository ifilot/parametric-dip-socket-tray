// SPDX-License-Identifier: CERN-OHL-S-2.0

/*
 * Stackable tray for MPE series-300 PLCC32 through-hole sockets.
 * The socket dimensions are taken from the M-PLCC 32 T datasheet.
 * Uses the same 160 x 160 mm stacking interface as dip_socket_tray.scad.
 *
 * Export examples:
 *   openscad -o plcc32-socket-tray.stl -D 'part="tray"' plcc32_socket_tray.scad
 *   openscad -o plcc32-socket-label.stl -D 'part="label"' plcc32_socket_tray.scad
 *   openscad -o plcc32-socket-fit-test.stl -D 'part="fit_test"' plcc32_socket_tray.scad
 */

/* [Main] */
part = "assembly";            // [assembly,tray,lid,label,fit_test]
show_sockets = true;          // Preview-only reference sockets

/* [PLCC32 socket] */
socket_size = [18.10, 20.64]; // Datasheet dimension B (width x length)
socket_height = 8.30;
pin_drop = 3.70;
side_clearance = 0.30;       // Body-to-guide clearance per side
pin_pitch = 1.27;
pin_row_spacing = [12.70, 15.24]; // PCB hole-row spacing, datasheet dimension D
pin_span = [7.62, 10.16];         // Datasheet dimension A
pin_width = 0.48;
support_size = [6.00, 8.00]; // Fits inside the socket's bent pins
support_height = 4.00;       // Height above the tray floor

/* [Tray] */
tray_size = [160, 160];
base_thickness = 1.80;
outer_wall = 3.20;
corner_radius = 6;
guide_width = 0.80;
guide_height = 8.00;         // Guide height above the body support
vertical_clearance = 2.00;   // Socket top to the next tray bottom

/* [Stacking interface] */
stack_lip_width = 1.20;
stack_lip_height = 1.20;
stack_fit = 0.30;
stack_groove_depth = 1.40;
stack_inset = 1.00;

/* [Lid] */
lid_thickness = 2.40;

/* [Label] */
label_depth = 0.60;
label_height = 6.0;
label_font = "Liberation Sans:style=Bold";

/* [Quality] */
$fn = $preview ? 40 : 80;

eps = 0.01;
pin_clearance = support_height - pin_drop;
support_z = base_thickness + support_height;
stack_plane_z = support_z + socket_height + vertical_clearance;
label_z = stack_plane_z / 2;
cell_size = [socket_size[0] + 2 * side_clearance,
             socket_size[1] + 2 * side_clearance];
cell_pitch = [cell_size[0] + guide_width,
              cell_size[1] + guide_width];
inner_size = [tray_size[0] - 2 * outer_wall,
              tray_size[1] - 2 * outer_wall];
column_count = floor((inner_size[0] + guide_width) / cell_pitch[0]);
row_count = floor((inner_size[1] + guide_width) / cell_pitch[1]);
used_grid_size = [column_count * cell_size[0]
                  + (column_count - 1) * guide_width,
                  row_count * cell_size[1]
                  + (row_count - 1) * guide_width];
grid_origin = [(tray_size[0] - used_grid_size[0]) / 2,
               (tray_size[1] - used_grid_size[1]) / 2];
label_text = "PLCC-32";

assert(base_thickness > stack_groove_depth,
       "The stacking groove must leave some base thickness");
assert(lid_thickness > stack_groove_depth,
       "The stacking groove must leave some lid thickness");
assert(pin_clearance > 0,
       "The support must leave clearance below the socket pin tips");
assert(support_size[0] + pin_width < pin_row_spacing[0]
       && support_size[1] + pin_width < pin_row_spacing[1],
       "The support island may contact the socket pins");
assert(column_count > 0 && row_count > 0,
       "Socket dimensions leave no usable storage positions");

if (part == "lid") {
    echo(str("Universal lid: ", tray_size[0], " x ", tray_size[1],
             " x ", lid_thickness + stack_lip_height, " mm"));
} else {
    echo(str("PLCC-32 socket: ", column_count, " columns x ",
             row_count, " rows = ", column_count * row_count,
             " sockets"));
    echo(str("Stacking pitch: ", stack_plane_z,
             " mm; overall printed height: ",
             stack_plane_z + stack_lip_height, " mm"));
    echo(str("Support: ", support_size[0], " x ", support_size[1],
             " x ", support_height, " mm; pin-tip clearance: ",
             pin_clearance, " mm"));
}

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

module tray_base(thickness = base_thickness) {
    translate([tray_size[0] / 2, tray_size[1] / 2, 0])
        linear_extrude(thickness)
            rounded_rect_2d(tray_size, corner_radius);
}

module perimeter_wall() {
    translate([tray_size[0] / 2, tray_size[1] / 2,
               base_thickness - eps])
        linear_extrude(stack_plane_z - base_thickness + 2 * eps)
            rounded_ring_2d(tray_size, outer_wall, corner_radius);
}

module stack_lip(z = stack_plane_z) {
    lip_outer = [tray_size[0] - 2 * stack_inset,
                 tray_size[1] - 2 * stack_inset];
    translate([tray_size[0] / 2, tray_size[1] / 2, z - eps])
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

module support_island(cx, cy) {
    translate([cx - support_size[0] / 2,
               cy - support_size[1] / 2,
               base_thickness - eps])
        cube([support_size[0], support_size[1],
              support_z - base_thickness + eps]);
}

module storage_pockets() {
    guide_top = support_z + guide_height;

    // One central island supports each socket body while all four rows of
    // through-hole pins hang freely around it.
    for (column = [0 : column_count - 1], row = [0 : row_count - 1]) {
        cx = grid_origin[0] + cell_size[0] / 2
           + column * cell_pitch[0];
        cy = grid_origin[1] + cell_size[1] / 2
           + row * cell_pitch[1];
        support_island(cx, cy);
    }

    // Shared walls locate every socket and rise to approximately the top of
    // the socket body.
    for (divider = [1 : column_count - 1]) {
        x = grid_origin[0] + divider * cell_size[0]
          + (divider - 1) * guide_width;
        translate([x, grid_origin[1], base_thickness - eps])
            cube([guide_width, used_grid_size[1],
                  guide_top - base_thickness + eps]);
    }

    for (divider = [1 : row_count - 1]) {
        y = grid_origin[1] + divider * cell_size[1]
          + (divider - 1) * guide_width;
        translate([grid_origin[0], y, base_thickness - eps])
            cube([used_grid_size[0], guide_width,
                  guide_top - base_thickness + eps]);
    }

    // Fill the margins up to the perimeter so the outermost positions have
    // the same body clearance as all internal positions.
    translate([outer_wall, outer_wall, base_thickness - eps])
        cube([grid_origin[0] - outer_wall, inner_size[1],
              guide_top - base_thickness + eps]);
    translate([grid_origin[0] + used_grid_size[0], outer_wall,
               base_thickness - eps])
        cube([tray_size[0] - outer_wall
              - grid_origin[0] - used_grid_size[0], inner_size[1],
              guide_top - base_thickness + eps]);
    translate([outer_wall, outer_wall, base_thickness - eps])
        cube([inner_size[0], grid_origin[1] - outer_wall,
              guide_top - base_thickness + eps]);
    translate([outer_wall, grid_origin[1] + used_grid_size[1],
               base_thickness - eps])
        cube([inner_size[0], tray_size[1] - outer_wall
              - grid_origin[1] - used_grid_size[1],
              guide_top - base_thickness + eps]);
}

module front_label(depth = label_depth + 2 * eps) {
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
            storage_pockets();
            stack_lip();
        }
        stack_groove_cut();
        front_label();
    }
}

module lid() {
    difference() {
        union() {
            tray_base(lid_thickness);
            stack_lip(lid_thickness);
        }
        stack_groove_cut();
    }
}

module label_inlay() {
    front_label();
}

module reference_socket() {
    color([0.12, 0.12, 0.12, 0.75])
        translate([-socket_size[0] / 2, -socket_size[1] / 2, support_z])
            cube([socket_size[0], socket_size[1], socket_height]);

    color([0.75, 0.75, 0.75, 0.8]) {
        for (side = [-1, 1], i = [0 : 6])
            translate([-pin_span[0] / 2 + i * pin_pitch - pin_width / 2,
                       side * pin_row_spacing[1] / 2 - pin_width / 2,
                       support_z - pin_drop])
                cube([pin_width, pin_width, pin_drop]);

        for (side = [-1, 1], i = [0 : 8])
            translate([side * pin_row_spacing[0] / 2 - pin_width / 2,
                       -pin_span[1] / 2 + i * pin_pitch - pin_width / 2,
                       support_z - pin_drop])
                cube([pin_width, pin_width, pin_drop]);
    }
}

module socket_preview_array() {
    if ($preview && show_sockets)
        for (column = [0 : column_count - 1], row = [0 : row_count - 1]) {
            cx = grid_origin[0] + cell_size[0] / 2
               + column * cell_pitch[0];
            cy = grid_origin[1] + cell_size[1] / 2
               + row * cell_pitch[1];
            translate([cx, cy, 0]) reference_socket();
        }
}

module fit_test() {
    test_size = [cell_size[0] + 2 * guide_width,
                 cell_size[1] + 2 * guide_width];
    guide_top = support_z + guide_height;

    union() {
        cube([test_size[0], test_size[1], base_thickness]);
        support_island(test_size[0] / 2, test_size[1] / 2);
        for (x = [0, test_size[0] - guide_width])
            translate([x, 0, base_thickness - eps])
                cube([guide_width, test_size[1],
                      guide_top - base_thickness + eps]);
        for (y = [0, test_size[1] - guide_width])
            translate([0, y, base_thickness - eps])
                cube([test_size[0], guide_width,
                      guide_top - base_thickness + eps]);
    }

    if ($preview && show_sockets)
        translate([test_size[0] / 2, test_size[1] / 2, 0])
            reference_socket();
}

if (part == "tray") {
    tray();
} else if (part == "lid") {
    lid();
} else if (part == "label") {
    label_inlay();
} else if (part == "fit_test") {
    fit_test();
} else {
    color("LightSteelBlue") tray();
    color("white") label_inlay();
    socket_preview_array();
}
