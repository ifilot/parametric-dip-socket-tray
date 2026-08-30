# SPDX-License-Identifier: CERN-OHL-S-2.0

"""Render the exported tray and two-colour label for README illustrations.

Run with Blender 4.x, for example:
    blender --background --python scripts/render_readme.py -- 14
"""

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


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
pins = int(args[0]) if args else 14
if pins not in (14, 16, 18, 20, 28, 32, 40):
    raise ValueError("Unsupported pin count")

root = Path(__file__).resolve().parents[1]
tray_path = root / "exports" / f"dip{pins}-tray.stl"
label_path = root / "exports" / f"dip{pins}-label.stl"
output_path = root / "assets" / f"dip{pins}-tray.png"
output_path.parent.mkdir(parents=True, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)

tray_mat = material("Matte sepia PLA", (0.58, 0.32, 0.16), roughness=0.86)
label_mat = material("Black label", (0.008, 0.008, 0.008), roughness=0.90)

tray = import_stl(tray_path, f"DIP-{pins} tray", tray_mat)
label = import_stl(label_path, f"DIP-{pins} label", label_mat)

bpy.ops.object.camera_add(location=(240, -250, 315))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = 218
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
