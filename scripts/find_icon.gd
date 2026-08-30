class_name FindIcon
extends Node2D
## A museum find, drawn in code. Used in the world when dug up, in the museum
## tray, and on the shelf. Swap in real art later by changing _draw() only.

var kind := "ammonite"
var icon_size := 32.0


func _init(k := "ammonite", s := 32.0) -> void:
	kind = k
	icon_size = s


func _draw() -> void:
	DrawKit.draw_find(self, kind, icon_size)
