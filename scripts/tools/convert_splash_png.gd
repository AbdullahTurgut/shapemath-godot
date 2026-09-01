extends SceneTree

func _init() -> void:
	print("CONVERTING BRANDING SVGS TO PNG...")
	var splash_img: Image = Image.load_from_file("res://assets/branding/shapemath_splash.svg")
	if splash_img:
		splash_img.save_png("res://assets/branding/shapemath_splash.png")
		print("Saved res://assets/branding/shapemath_splash.png")

	var icon_img: Image = Image.load_from_file("res://assets/branding/shapemath_icon.svg")
	if icon_img:
		icon_img.save_png("res://assets/branding/shapemath_icon.png")
		print("Saved res://assets/branding/shapemath_icon.png")

	var fg_img: Image = Image.load_from_file("res://assets/branding/icon_foreground.svg")
	if fg_img:
		fg_img.save_png("res://assets/branding/icon_foreground.png")
		print("Saved res://assets/branding/icon_foreground.png")

	var bg_img: Image = Image.load_from_file("res://assets/branding/icon_background.svg")
	if bg_img:
		bg_img.save_png("res://assets/branding/icon_background.png")
		print("Saved res://assets/branding/icon_background.png")

	quit(0)
