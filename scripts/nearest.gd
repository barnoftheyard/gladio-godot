@tool
extends Node3D

func _ready():
	set_all_mesh_materials_nearest(self)

#interative function that makes all meshes set to nearest texture filtering
func set_all_mesh_materials_nearest(node):
	for child in node.get_children():
		if child.get_child_count() > 0:
			set_all_mesh_materials_nearest(child)
		if child is MeshInstance3D:
			#check if mesh has an active material
			if child.get_active_material(0) != null:
				#for every surface, set the texture filter setting to nearest
				for surface in range(0, child.mesh.get_surface_count()):
					var material = child.mesh.surface_get_material(surface)
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
