# SPDX-License-Identifier: CERN-OHL-S-2.0

"""Render a populated tray and two-colour label for README illustrations.

Run with Blender 4.x, for example:
    blender --background --python scripts/render_readme.py -- \
        14 /path/to/Package_DIP.3dshapes
    blender --background --python scripts/render_readme.py -- dip28-slim
    blender --background --python scripts/render_readme.py -- plcc44

The socket model directory is optional. When supplied, it must contain the
matching KiCad ``DIP-*_Socket.wrl`` model. The KiCad files are used as render
inputs only and are not copied into this project. When no DIP model is supplied,
a lightweight procedural reference socket is used. The PLCC renders use
dimensioned procedural socket models based on the MPE series-300 drawing.
"""

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def material(name, colour, metallic=0.0, roughness=0.82):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*colour, 1.0)
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*colour, 1.0)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    return mat


def import_stl(path, name, mat):
    bpy.ops.wm.stl_import(filepath=str(path))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    # STL triangulation must not be visually smoothed across CAD edges; doing
    # so creates diagonal highlights on otherwise planar walls and ridges.
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    return obj


def object_bounds(objects):
    points = [obj.matrix_world @ Vector(corner) for obj in objects
              for corner in obj.bound_box]
    return ([min(point[axis] for point in points) for axis in range(3)],
            [max(point[axis] for point in points) for axis in range(3)])


def join_objects(objects, name, mat):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    return obj


def import_kicad_socket(path, support_z, body_mat, pin_mat):
    """Import, orient, and centre one KiCad VRML socket at the origin."""
    bpy.ops.object.select_all(action="DESELECT")
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.x3d(filepath=str(path))
    imported = [obj for obj in bpy.context.scene.objects
                if obj not in before and obj.type == "MESH"]

    # KiCad WRL units are 2.54 mm and the importer maps the PCB's Z axis to Y.
    for obj in imported:
        bpy.ops.object.select_all(action="DESELECT")
        # X3D imports may retain an axis-conversion parent. Detach it while
        # preserving the world transform so subsequent rotations use Blender's
        # canonical world axes rather than the KiCad/X3D local axes.
        world_transform = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world_transform
        obj.scale = (2.54, 2.54, 2.54)
        obj.rotation_euler.x = math.radians(90)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        obj.select_set(False)

    body_parts = [obj for obj in imported
                  if obj.data.materials
                  and "IC-BODY" in obj.data.materials[0].name]
    pin_parts = [obj for obj in imported if obj not in body_parts]
    body = join_objects(body_parts, "Socket body", body_mat)
    pins = join_objects(pin_parts, "Socket contacts", pin_mat)

    # Roll the socket onto its back around Blender's world X axis. KiCad/X3D
    # uses a different canonical-axis convention, so this must be explicit.
    for obj in (body, pins):
        bpy.ops.object.select_all(action="DESELECT")
        obj.rotation_euler.x = math.radians(90)
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        obj.select_set(False)

    body_min, body_max = object_bounds([body])
    centre_x = (body_min[0] + body_max[0]) / 2
    centre_y = (body_min[1] + body_max[1]) / 2
    offset = Vector((-centre_x, -centre_y, support_z - body_min[2]))
    body.location += offset
    pins.location += offset
    return body, pins


def duplicate_socket(parts, x, y, number):
    for source in parts:
        copy = source.copy()
        copy.data = source.data
        copy.name = f"{source.name} {number}"
        copy.location += Vector((x, y, 0))
        bpy.context.collection.objects.link(copy)


def cube_object(name, size, location, mat):
    """Create an unapologetically crisp, CAD-style rectangular component."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def plcc_socket_parts(support_z, body_mat, pin_mat, pins):
    """Build an MPE series-300 PLCC socket for the tray illustration."""
    dimensions = {
        32: (18.10, 20.64, 7, 9, 3.81, 5.08),
        44: (23.18, 23.18, 11, 11, 6.35, 6.35),
    }
    width, length, contacts_x, contacts_y, span_x, span_y = dimensions[pins]
    height = 8.30
    body_parts = []
    contact_parts = []
    rail = 1.50
    base = 1.50
    rail_height = height - base

    body_parts.append(cube_object("PLCC socket base", [width, length, base],
                                  [0, 0, support_z + base / 2], body_mat))
    body_parts.append(cube_object("PLCC socket top rail", [width, rail, rail_height],
                                  [0, (length - rail) / 2,
                                   support_z + base + rail_height / 2], body_mat))
    body_parts.append(cube_object("PLCC socket bottom rail", [width, rail, rail_height],
                                  [0, -(length - rail) / 2,
                                   support_z + base + rail_height / 2], body_mat))
    body_parts.append(cube_object("PLCC socket left rail", [rail, length - 2 * rail, rail_height],
                                  [-(width - rail) / 2, 0,
                                   support_z + base + rail_height / 2], body_mat))
    body_parts.append(cube_object("PLCC socket right rail", [rail, length - 2 * rail, rail_height],
                                  [(width - rail) / 2, 0,
                                   support_z + base + rail_height / 2], body_mat))

    # Shallow contact bars make the open socket recognisable at README scale.
    contact_z = support_z + height - 0.90
    for side in (-1, 1):
        for index in range(contacts_x):
            x = -span_x + index * 1.27
            y = side * (length / 2 - rail - 0.24)
            contact_parts.append(cube_object("PLCC contact", [0.42, 0.60, 1.70],
                                             [x, y, contact_z], pin_mat))
    for side in (-1, 1):
        for index in range(contacts_y):
            x = side * (width / 2 - rail - 0.24)
            y = -span_y + index * 1.27
            contact_parts.append(cube_object("PLCC contact", [0.60, 0.42, 1.70],
                                             [x, y, contact_z], pin_mat))

    body = join_objects(body_parts, f"PLCC{pins} socket body", body_mat)
    contacts = join_objects(contact_parts, f"PLCC{pins} socket contacts", pin_mat)
    return body, contacts


def dip_socket_parts(support_z, body_mat, pin_mat, pins, wide):
    """Build a simple filled DIP socket when a KiCad model is unavailable."""
    width = 17.78 if wide else 10.16
    row_spacing = 15.24 if wide else 7.62
    length = pins / 2 * 2.54
    height = 5.10
    body = cube_object("DIP socket body", [width, length, height],
                       [0, 0, support_z + height / 2], body_mat)
    contacts = []
    for side in (-1, 1):
        for index in range(pins // 2):
            contacts.append(cube_object(
                "DIP contact", [0.48, 0.48, 3.60],
                [side * row_spacing / 2, -length / 2 + 1.27 + index * 2.54,
                 support_z - 1.80], pin_mat))
    contacts = join_objects(contacts, "DIP socket contacts", pin_mat)
    return body, contacts


def populate_dip_tray(parts, pins, wide=None):
    """Fill every channel to the same maximum capacity as the OpenSCAD model."""
    wide = pins >= 28 if wide is None else wide
    socket_width = 17.78 if wide else 10.16
    channel_width = socket_width + 0.60
    guide_width = 0.80
    row_pitch = channel_width + guide_width
    row_count = 8 if wide else 13
    used_width = row_count * channel_width + (row_count - 1) * guide_width
    rows_x0 = (160 - used_width) / 2
    socket_length = pins / 2 * 2.54
    inner_length = 160 - 2 * 3.20
    gap = 0.60
    sockets_per_row = int((inner_length + gap) / (socket_length + gap))
    used_length = (sockets_per_row * socket_length
                   + (sockets_per_row - 1) * gap)
    sockets_y0 = (160 - used_length) / 2

    number = 0
    for row in range(row_count):
        x = rows_x0 + channel_width / 2 + row * row_pitch
        for position in range(sockets_per_row):
            y = (sockets_y0 + socket_length / 2
                 + position * (socket_length + gap))
            duplicate_socket(parts, x, y, number)
            number += 1

    # The imported pair serves only as the duplication source.
    for obj in parts:
        bpy.data.objects.remove(obj, do_unlink=True)


def populate_plcc_tray(parts, pins):
    """Fill the PLCC pocket grid using the OpenSCAD placement equations."""
    socket_size = {32: (18.10, 20.64), 44: (23.18, 23.18)}[pins]
    side_clearance = 0.30
    guide_width = 0.80
    inner_size = (160 - 2 * 3.20, 160 - 2 * 3.20)
    cell_size = (socket_size[0] + 2 * side_clearance,
                 socket_size[1] + 2 * side_clearance)
    pitch = (cell_size[0] + guide_width, cell_size[1] + guide_width)
    columns = int((inner_size[0] + guide_width) / pitch[0])
    rows = int((inner_size[1] + guide_width) / pitch[1])
    used_size = (columns * cell_size[0] + (columns - 1) * guide_width,
                 rows * cell_size[1] + (rows - 1) * guide_width)
    origin = ((160 - used_size[0]) / 2, (160 - used_size[1]) / 2)

    number = 0
    for column in range(columns):
        for row in range(rows):
            x = origin[0] + cell_size[0] / 2 + column * pitch[0]
            y = origin[1] + cell_size[1] / 2 + row * pitch[1]
            duplicate_socket(parts, x, y, number)
            number += 1

    for obj in parts:
        bpy.data.objects.remove(obj, do_unlink=True)


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
variant = args[0].lower() if args else "14"
is_plcc = variant in ("plcc32", "plcc44")
is_slim28 = variant in ("dip28-slim", "28-slim")
if is_plcc:
    plcc_pins = int(variant[4:])
else:
    pins = 28 if is_slim28 else int(variant)
    if pins not in (14, 16, 18, 20, 28, 32, 40):
        raise ValueError("Unsupported pin count")

root = Path(__file__).resolve().parents[1]
if is_plcc:
    tray_path = root / "exports" / f"plcc{plcc_pins}-socket-tray.stl"
    label_path = root / "exports" / f"plcc{plcc_pins}-socket-label.stl"
    output_path = root / "assets" / f"plcc{plcc_pins}-socket-tray.png"
    tray_name = f"PLCC-{plcc_pins} socket tray"
    label_name = f"PLCC-{plcc_pins} socket label"
else:
    file_stem = "dip28-slim" if is_slim28 else f"dip{pins}"
    tray_path = root / "exports" / f"{file_stem}-tray.stl"
    label_path = root / "exports" / f"{file_stem}-label.stl"
    output_path = root / "assets" / f"{file_stem}-tray.png"
    tray_name = f"DIP-28 slim tray" if is_slim28 else f"DIP-{pins} tray"
    label_name = f"DIP-28 slim label" if is_slim28 else f"DIP-{pins} label"
output_path.parent.mkdir(parents=True, exist_ok=True)

socket_model_names = {
    14: "DIP-14_W7.62mm_Socket.wrl",
    16: "DIP-16_W7.62mm_Socket.wrl",
    18: "DIP-18_W7.62mm_Socket.wrl",
    20: "DIP-20_W7.62mm_Socket.wrl",
    28: "DIP-28_W15.24mm_Socket.wrl",
    32: "DIP-32_W15.24mm_Socket.wrl",
    40: "DIP-40_W15.24mm_Socket.wrl",
}

bpy.ops.wm.read_factory_settings(use_empty=True)

tray_mat = material("Matte light sepia PLA", (0.70, 0.47, 0.29), roughness=0.86)
label_mat = material("Black label", (0.008, 0.008, 0.008), roughness=0.90)
socket_mat = material("Black socket body", (0.012, 0.014, 0.016), roughness=0.76)
contact_mat = material("Socket contacts", (0.30, 0.32, 0.34),
                       metallic=0.42, roughness=0.72)

tray = import_stl(tray_path, tray_name, tray_mat)
label = import_stl(label_path, label_name, label_mat)

if is_plcc:
    socket_parts = plcc_socket_parts(5.8, socket_mat, contact_mat, plcc_pins)
    populate_plcc_tray(socket_parts, plcc_pins)
elif len(args) > 1:
    socket_name = ("DIP-28_W7.62mm_Socket.wrl" if is_slim28
                   else socket_model_names[pins])
    socket_path = Path(args[1]) / socket_name
    if not socket_path.is_file():
        raise FileNotFoundError(f"KiCad socket model not found: {socket_path}")
    socket_parts = import_kicad_socket(socket_path, 5.8, socket_mat, contact_mat)
    populate_dip_tray(socket_parts, pins, wide=False if is_slim28 else None)
else:
    socket_parts = dip_socket_parts(5.8, socket_mat, contact_mat, pins,
                                    wide=False if is_slim28 else pins >= 28)
    populate_dip_tray(socket_parts, pins, wide=False if is_slim28 else None)

bpy.ops.object.camera_add(location=(215, -230, 405))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = 232
camera.data.lens = 55
point_at(camera, (80, 80, 3.0))
bpy.context.scene.camera = camera

scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.render.resolution_x = 1000
scene.render.resolution_y = 760
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGB"
scene.render.film_transparent = False
scene.render.filepath = str(output_path)
scene.render.image_settings.color_depth = "8"
scene.render.resolution_percentage = 100

scene.world = bpy.data.worlds.new("White Background")
scene.world.color = (1.0, 1.0, 1.0)

shading = scene.display.shading
shading.light = "STUDIO"
shading.studio_light = "paint.sl"
shading.color_type = "MATERIAL"
shading.background_type = "WORLD"
shading.background_color = (1.0, 1.0, 1.0)
shading.show_shadows = True
shading.show_cavity = True
shading.cavity_type = "BOTH"
shading.curvature_ridge_factor = 1.25
shading.curvature_valley_factor = 1.15
shading.show_specular_highlight = False
shading.show_object_outline = False

scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "Medium High Contrast"
scene.render.image_settings.compression = 45
bpy.ops.render.render(write_still=True)
