class_name IconBadge
extends Control
## 원형 색 배지 + 흰 심볼. 카드/픽업 공용 아이콘.

var id: String = ""
var override_color: Color = Color(0, 0, 0, 0)
var _tex: Texture2D = null
var _px: bool = false   # 12차 B 도트 아이콘(24×24, 원 바탕 · 테는 여기서 그린다) — 정수배로만 그린다
var bare: bool = false  # 14차: 칸(cell) 안에 넣을 때 — 도트 아이콘이면 원 바탕 없이 그림만


## 16차: B 79 에 없는 id — 영웅 시그니처 카드 14 · 휴식/노다지 카드 · 옛 이름(item_magnet · bigxp)은 우리 B 표에서 빠졌다.
##   새 그림이 올 때까지 효과가 가장 가까운 B 아이콘을 빌려 쓴다(예전엔 절차적 도형 · 옛 PixelLab 그림이 나왔다).
const ALIAS: Dictionary = {
	# 17차: 시그니처 카드 14 · 휴식 · 노다지 카드는 진짜 그림(icons/<id>)이 와서 빌려 쓰기를 뺐다
	"item_magnet": "magnet", "bigxp": "xp_gain",
}


func setup(icon_id: String, sz: float, ov: Color = Color(0, 0, 0, 0)) -> IconBadge:
	id = icon_id
	override_color = ov
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 픽셀 아이콘 크리스프
	_tex = FxLib.tile("ui/icons/" + icon_id, "icon", 0)
	if _tex == null and ALIAS.has(icon_id):
		_tex = FxLib.tile("ui/icons/" + String(ALIAS[icon_id]), "icon", 0)
	_px = _tex != null
	var p: String = "res://assets/sprites/icons/%s.png" % icon_id  # PixelLab 아이콘 있으면 사용
	if _tex == null and ResourceLoader.exists(p):
		_tex = load(p)
	queue_redraw()
	return self


func _draw() -> void:
	var s: Vector2 = size
	var c: Vector2 = s * 0.5
	var r: float = minf(s.x, s.y) * 0.5
	var col: Color = override_color if override_color.a > 0.0 else Icons.color_of(id)
	if _px and bare:
		# 그림 둘레 2px 은 비어 있어 칸 테(4) 위로 넘쳐도 된다 — 무기 칸 48(안 40) → ×2, 그 밖 칸 36(안 28) → ×1
		var kb: float = maxf(1.0, floorf((minf(s.x, s.y) + 8.0) / 24.0))
		var db: float = 24.0 * kb
		draw_texture_rect(_tex, Rect2(floorf(c.x - db * 0.5), floorf(c.y - db * 0.5), db, db), false)
		return
	if _px:
		# 새 도트 아이콘은 그 무기 이펙트 색 그대로라 배지 색(같은 무기 색)과 한 계열이다 — 밝은 바탕이면
		# 소총 · 각궁 · 기관총 · 신칼이 바탕에 묻힌다(12차 화면). 바탕은 어둡게, 배지 색은 테로만.
		draw_circle(c, r, Color("23253a").lerp(col, 0.18))
		draw_arc(c, r - 1.5, 0, TAU, 28, col, 3.0)
	else:
		draw_circle(c, r, col.darkened(0.12))
		draw_arc(c, r - 1.5, 0, TAU, 28, col.lightened(0.28), 3.0)
	if _tex != null and _px:
		# 24칸 그림을 정수배로. 그림은 지름 20 원 안이라 배지 원(테 안쪽)에 20 × k 가 들어가는 가장 큰 배수 —
		# 카드 배지 64 → ×3 · 상자 창 44 → ×2 · HUD 26 → ×1.
		var k: float = maxf(1.0, floorf((minf(s.x, s.y) - 4.0) / 20.0))
		var d2: float = 24.0 * k
		draw_texture_rect(_tex, Rect2(floorf(c.x - d2 * 0.5), floorf(c.y - d2 * 0.5), d2, d2), false)
	elif _tex != null:  # 실제 픽셀 아이콘
		var d: float = r * 1.55
		# 14차: 방어(armor) 아이콘은 검은 덩어리라 안 읽혔다 — B 79 가 올 때까지 밝게 그린다
		var lift: Color = Color(2.0, 2.0, 2.2) if id == "armor" else Color.WHITE
		draw_texture_rect(_tex, Rect2(c.x - d * 0.5, c.y - d * 0.5, d, d), false, lift)
	else:  # 폴백: 절차적 심볼
		Icons.draw_symbol(self, id, c, r * 0.6, Color(1, 1, 1, 0.96))
