class_name PixelText
extends Control
## 픽셀 숫자 한 줄 — 10차 A 묶음(ui/text 의 num · num_crit). 칸마다 칠한 폭(advance)으로 붙여 쓴다.
## num 은 흰 그림이라 색은 modulate 로 입힌다(「게임이 색을 입힘」). num_crit 은 색이 그려져 있다.
## 전투(Node2D 아래)에서도 UI 에서도 쓴다 — 크기는 정수배 px 로만.

var sheet: String = "num"
var px: float = 2.0
var text: String = "":
	set(v):
		text = v
		_fit()
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()


func _fit() -> void:
	var m: Dictionary = FxLib.info("ui/text", sheet)
	if m.is_empty():
		return
	custom_minimum_size = Vector2(float(FxLib.text_width("ui/text", sheet, text)), float(m["h"])) * px
	size = custom_minimum_size


func _draw() -> void:
	FxLib.draw_text(self, Vector2.ZERO, text, "ui/text", sheet, px)
