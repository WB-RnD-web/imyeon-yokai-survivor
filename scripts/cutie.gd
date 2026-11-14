class_name Cutie
extends Object
## 소환수 전용 "귀염뽀짝" 픽셀 펫 — 둥근 몸 + 귀 + 꼬리 + 반짝 눈 + 볼터치.
## 자체 애니메이션(깜빡임/귀 쫑긋/꼬리 살랑/눈 반짝). 소유자는 root의 bob/squash/lean만 준다.

static func make(body_col: Color, belly_col: Color, gem: bool = false) -> Node2D:
	var pet := _Pet.new()
	pet.body_col = body_col
	pet.belly_col = belly_col
	pet.gem = gem
	return pet


## 실제 픽셀 스프라이트 소환수 (PixelLab 생성). 없으면 프로시저럴 폴백.
static func sprite(path: String, radius: float) -> Node2D:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex != null:
			var n := Node2D.new()
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var sc: float = (radius * 2.3) / float(maxi(tex.get_width(), tex.get_height()))
			s.scale = Vector2(sc, sc)
			n.add_child(s)
			return n
	return make(Color("8ce6a8"), Color("eafff0"))


class _Pet:
	extends Node2D
	var body_col: Color = Color("8ce6a8")
	var belly_col: Color = Color("eafff0")
	var gem: bool = false
	var _ear_l: Node2D
	var _ear_r: Node2D
	var _tail: Node2D
	var _eyes: Node2D
	var _spark: Polygon2D
	var _t: float = 0.0
	var _blink: float = 0.0
	var _next_blink: float = 2.0

	func _ready() -> void:
		_t = randf() * 6.0
		_next_blink = randf_range(1.6, 3.6)
		var dark: Color = body_col.darkened(0.22)
		# 후광
		var glow := Polygon2D.new()
		glow.polygon = G.regular_polygon(24, 18.0)
		glow.color = Color(body_col.r, body_col.g, body_col.b, 0.26)
		glow.z_index = -2
		add_child(glow)
		# 꼬리 (몸 뒤, 살랑살랑) — 점점 작아지는 3구슬
		_tail = Node2D.new()
		_tail.position = Vector2(9.0, 4.0)
		_tail.z_index = -1
		add_child(_tail)
		var tr: Array = [[Vector2(4.0, -2.0), 3.6], [Vector2(8.0, -6.0), 2.8], [Vector2(11.0, -11.0), 2.0]]
		for seg: Array in tr:
			var tb := Polygon2D.new()
			tb.polygon = G.regular_polygon(12, float(seg[1]) + 1.2)
			tb.color = Color(1, 1, 1, 0.9)
			tb.position = seg[0]
			_tail.add_child(tb)
			var tc := Polygon2D.new()
			tc.polygon = G.regular_polygon(12, float(seg[1]))
			tc.color = body_col
			tc.position = seg[0]
			_tail.add_child(tc)
		# 귀 (몸 뒤 위, 쫑긋) — 흰 테두리 삼각 + 핑크 속귀
		_ear_l = _make_ear(Vector2(-6.5, -9.0), dark, true)
		_ear_r = _make_ear(Vector2(6.5, -9.0), dark, false)
		# 몸 (흰 외곽선 + 본체 + 배)
		var out := Polygon2D.new()
		out.polygon = G.regular_polygon(6 if gem else 26, 13.5)
		out.color = Color(1, 1, 1, 0.96)
		add_child(out)
		var bod := Polygon2D.new()
		bod.polygon = G.regular_polygon(6 if gem else 24, 12.0)
		bod.color = body_col
		add_child(bod)
		var belly := Polygon2D.new()
		belly.polygon = G.regular_polygon(20, 8.5)
		belly.color = belly_col
		belly.position = Vector2(0, 3.5)
		add_child(belly)
		# 눈 (반짝반짝) + 입 + 볼터치
		_eyes = Node2D.new()
		add_child(_eyes)
		_make_eye(Vector2(-3.8, -1.0))
		_make_eye(Vector2(3.8, -1.0))
		var mouth := Polygon2D.new()  # 앙증맞은 입 (작은 삼각)
		mouth.polygon = PackedVector2Array([Vector2(-1.6, 2.2), Vector2(1.6, 2.2), Vector2(0, 4.0)])
		mouth.color = Color(0.32, 0.18, 0.22, 0.85)
		add_child(mouth)
		for cx: float in [-7.0, 7.0]:
			var cheek := Polygon2D.new()
			cheek.polygon = G.regular_polygon(12, 2.1)
			cheek.color = Color(1.0, 0.6, 0.76, 0.7)
			cheek.position = Vector2(cx, 2.2)
			add_child(cheek)
		# 젬(얼음정령)은 머리 위 반짝이는 별
		if gem:
			_spark = Polygon2D.new()
			_spark.polygon = _star_pts(3.0)
			_spark.color = Color(1, 1, 1, 0.9)
			_spark.position = Vector2(7.0, -11.0)
			add_child(_spark)

	func _make_ear(pos: Vector2, dark: Color, left: bool) -> Node2D:
		var n := Node2D.new()
		n.position = pos
		add_child(n)
		var tip: float = -11.0
		var sx: float = -1.0 if left else 1.0
		var outline := Polygon2D.new()
		outline.polygon = PackedVector2Array([Vector2(-4.6, 2.0), Vector2(4.6, 2.0), Vector2(sx * 2.5, tip)])
		outline.color = Color(1, 1, 1, 0.96)
		n.add_child(outline)
		var e := Polygon2D.new()
		e.polygon = PackedVector2Array([Vector2(-3.6, 1.6), Vector2(3.6, 1.6), Vector2(sx * 2.2, tip + 1.4)])
		e.color = dark
		n.add_child(e)
		var inner := Polygon2D.new()
		inner.polygon = PackedVector2Array([Vector2(-1.8, 0.6), Vector2(1.8, 0.6), Vector2(sx * 1.2, tip + 4.0)])
		inner.color = Color(1.0, 0.68, 0.78, 0.9)
		n.add_child(inner)
		return n

	func _make_eye(pos: Vector2) -> void:
		var n := Node2D.new()
		n.position = pos
		_eyes.add_child(n)
		var white := Polygon2D.new()
		white.polygon = G.regular_polygon(14, 3.2)
		white.color = Color(1, 1, 1, 0.98)
		n.add_child(white)
		var pupil := Polygon2D.new()
		pupil.polygon = G.regular_polygon(14, 2.3)
		pupil.color = Color(0.16, 0.13, 0.22)
		n.add_child(pupil)
		var hi := Polygon2D.new()  # 큰 하이라이트
		hi.polygon = G.regular_polygon(10, 1.1)
		hi.color = Color(1, 1, 1, 0.95)
		hi.position = Vector2(-0.8, -1.0)
		n.add_child(hi)
		var hi2 := Polygon2D.new()  # 작은 반짝
		hi2.polygon = G.regular_polygon(8, 0.55)
		hi2.color = Color(1, 1, 1, 0.9)
		hi2.position = Vector2(0.9, 0.9)
		n.add_child(hi2)

	func _star_pts(r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 8:
			var a: float = TAU * float(i) / 8.0
			var rr: float = r if i % 2 == 0 else r * 0.42
			pts.append(Vector2(cos(a), sin(a)) * rr)
		return pts

	func _process(delta: float) -> void:
		_t += delta
		# 귀 쫑긋 (좌우 반대로 살짝)
		if _ear_l != null:
			_ear_l.rotation = -0.12 + sin(_t * 2.3) * 0.14
			_ear_r.rotation = 0.12 - sin(_t * 2.3) * 0.14
		# 꼬리 살랑
		if _tail != null:
			_tail.rotation = sin(_t * 3.2) * 0.35
		# 별 반짝 (젬)
		if _spark != null:
			var s: float = 0.6 + 0.5 * absf(sin(_t * 4.0))
			_spark.scale = Vector2(s, s)
			_spark.rotation = _t * 1.5
		# 깜빡임
		_blink = maxf(0.0, _blink - delta)
		_next_blink -= delta
		if _next_blink <= 0.0:
			_next_blink = randf_range(2.2, 4.5)
			_blink = 0.12
		if _eyes != null:
			var ey: float = 0.12 if _blink > 0.0 else 1.0
			_eyes.scale.y = lerpf(_eyes.scale.y, ey, 0.5)
