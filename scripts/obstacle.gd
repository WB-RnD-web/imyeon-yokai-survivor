class_name Obstacle
extends StaticBody2D
## 테마별 지형 장애물 — 이동/총알을 막는 입체 오브젝트(원형 충돌).
## 바닥 그림자 + 아웃라인 + 2톤 음영 + 상단 하이라이트로 "솟은 물체"처럼 보이게.

var theme: int = 0
var _rad: float = 40.0
## 12차 E — 테마마다 그림 한 벌(survivor_ui/obstacle/<테마>/<테마>_s · _l). 순서는 PAL 과 같다.
const ART_KEY: Array = ["dungeon", "library", "garden", "lava", "heaven", "jeoseung"]   # 5 = 저승길(스테이지 준비 중)

# 테마 팔레트: [아웃라인/그림자, 몸통-어둠, 몸통, 상단-밝음, 강조]
const PAL: Array = [
	[Color("0e0c12"), Color("34303f"), Color("5a5468"), Color("8b849c"), Color("7fd47f")],  # 던전 돌기둥(+이끼)
	[Color("140f08"), Color("2a1e10"), Color("4a3420"), Color("6e5030"), Color("d0a840")],  # 도서관 책장
	[Color("0c1a0e"), Color("214525"), Color("356538"), Color("62ad64"), Color("ffd6e0")],  # 정원 덤불(+꽃)
	[Color("0a0605"), Color("1e1211"), Color("3a2422"), Color("5c3a33"), Color("ff6a2a")],  # 용암 바위(+균열)
	[Color("0c0c1a"), Color("2a2450"), Color("5040a0"), Color("9a6cff"), Color("ffffff")],  # 천상 크리스탈
]


static func spawn(parent: Node, pos: Vector2, theme_i: int, r: float) -> Obstacle:
	var o := Obstacle.new()
	o.theme = theme_i
	o._rad = r
	o.global_position = pos
	parent.add_child(o)
	return o


func _ready() -> void:
	collision_layer = 8  # 지형 장애물 (플레이어 mask 8, 몹 mask 8, 총알 mask 8 로 막힘)
	collision_mask = 0
	add_to_group("obstacle")
	var art: Sprite2D = _art()
	var shape := CollisionShape2D.new()
	# 11/5 스팀 피드백 6: 그림이 있으면 그 그림의 바닥 자리(발판 다각형)로 막는다 — 예전 동그라미는 그림자보다
	#   위아래로 두세 배 길어서 기둥 앞 빈 바닥에서 미리 막혔다(보이지 않는 벽). 발판은 tools/obstacle_footprint.py.
	var foot: PackedVector2Array = _footprint() if art != null else PackedVector2Array()
	if foot.size() >= 3:
		var cp := ConvexPolygonShape2D.new()
		cp.points = foot
		shape.shape = cp
		var ys: float = 0.0
		for q: Vector2 in foot:
			ys += q.y
		_foot_mid_y = ys / float(foot.size())
	else:
		var c := CircleShape2D.new()
		c.radius = _rad * 0.9
		shape.shape = c
	add_child(shape)
	if art != null:
		add_child(art)
		_art_node = art
		_pop()
		return
	# 바닥 그림자 (넓고 납작하게 → 물체가 떠 있는 느낌)
	var sh := Polygon2D.new()
	sh.polygon = _irr(_rad * 1.18, 3, 0.1)
	sh.color = Color(0, 0, 0, 0.34)
	sh.position = Vector2(_rad * 0.14, _rad * 0.42)
	sh.scale = Vector2(1.06, 0.44)
	sh.z_index = -1
	add_child(sh)
	var pal: Array = PAL[theme % PAL.size()]
	match theme:
		1: _bookshelf(pal)
		4: _crystal(pal)
		_: _boulder(pal, theme)
	_pop()


## 등장 팝
func _pop() -> void:
	scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


## 그림이 있으면 그 판의 바닥 원(작은 판 지름 72 · 큰 판 100)을 충돌 크기로 삼는다.
## 반지름 43 이상이면 큰 판. 그림 1px = 게임 1px, 기준점(바닥 원 중심)이 노드 자리. 그림자는 그림에 들어 있다.
func _art() -> Sprite2D:
	var key: String = String(ART_KEY[theme % ART_KEY.size()])
	var wid: String = "ui/obstacle/" + key
	var sheet: String = key + ("_l" if _rad >= 43.0 else "_s")
	var t: Texture2D = FxLib.tile(wid, sheet, 0)
	if t == null:
		return null
	var j: Dictionary = FxLib.json_of(wid, sheet)
	var an: Array = j.get("anchor", [t.get_width() / 2, t.get_height() - 28])
	_rad = float(j.get("ground_circle", _rad * 2.0)) * 0.5
	var s := Sprite2D.new()
	s.texture = t
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -Vector2(float(an[0]), float(an[1]))
	_sheet = sheet
	_art_rect = Rect2(s.offset, Vector2(t.get_width(), t.get_height()))
	return s


var _sheet: String = ""
var _art_node: Sprite2D
var _art_rect: Rect2            # 그림이 차지하는 자리(노드 기준)
var _foot_mid_y: float = 0.0    # 발판 가운데 높이 — 영웅 발이 이보다 위면 「뒤에 서 있다」
static var _foot_db: Dictionary = {}


## 시트 이름(dungeon_s …) → 발판 다각형. 납품 json 은 읽기 전용이라 따로 둔 assets/ui/obstacle/footprint.json.
func _footprint() -> PackedVector2Array:
	if _foot_db.is_empty():
		var f := FileAccess.open("res://assets/ui/obstacle/footprint.json", FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_foot_db = d
		if _foot_db.is_empty():
			_foot_db = {"_none": true}
	var out := PackedVector2Array()
	for q: Variant in (_foot_db.get(_sheet, []) as Array):
		out.append(Vector2(float((q as Array)[0]), float((q as Array)[1])))
	return out


## 11/5: 충돌을 바닥 자리로 줄이면 영웅이 기둥 뒤까지 들어간다. 그런데 영웅은 늘 몹 위(z 6)에 그려서
##   기둥 뒤에 서면 기둥 위에 올라선 것처럼 보였다. 영웅 발이 발판보다 위(뒤)이고 그림과 겹치면
##   장애물을 영웅 위로 올리고 반투명으로 비춰 영웅이 보이게 한다.
const _FRONT_Z: int = 7
var _behind_a: float = 1.0


func _process(delta: float) -> void:
	if _art_node == null:
		return
	var p := G.player as Node2D
	var hide: bool = false
	if p != null and is_instance_valid(p):
		var lp: Vector2 = p.global_position - global_position
		var r: float = Player.RADIUS
		var feet_y: float = lp.y + r * 0.86
		var hero := Rect2(lp.x - r * 1.1, lp.y - r * 1.6, r * 2.2, r * 2.6)
		hide = feet_y < _foot_mid_y and hero.intersects(_art_rect)
	z_index = _FRONT_Z if hide else 0
	var want: float = 0.55 if hide else 1.0
	if absf(_behind_a - want) > 0.01:
		_behind_a = move_toward(_behind_a, want, delta * 4.0)
		_art_node.modulate.a = _behind_a


## 울퉁불퉁한 유기적 폴리곤
func _irr(r: float, seed_i: int, wob: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n: int = 15
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var rr: float = r * (1.0 - wob + wob * (1.0 + sin(a * 3.0 + float(seed_i) * 1.7) * 0.5))
		pts.append(Vector2(cos(a), sin(a)) * rr)
	return pts


func _poly(pts: PackedVector2Array, col: Color, off: Vector2 = Vector2.ZERO) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.position = off
	add_child(p)
	return p


func _circle(r: float, col: Color, off: Vector2 = Vector2.ZERO) -> void:
	var p := Polygon2D.new()
	p.polygon = G.regular_polygon(14, r)
	p.color = col
	p.position = off
	add_child(p)


## 솟은 둥근 바위/덤불 몸통 (아웃라인 → 어둠 → 몸통 → 하이라이트)
func _boulder(pal: Array, th: int) -> void:
	var lift: float = -_rad * 0.32  # 몸통을 위로 올려 높이감
	_poly(_irr(_rad * 1.07, 1, 0.15), pal[0], Vector2(0, lift + _rad * 0.06))  # 아웃라인/뒤 그림자
	_poly(_irr(_rad, 1, 0.15), pal[1], Vector2(0, lift + _rad * 0.14))          # 아랫부분(어둠)
	_poly(_irr(_rad * 0.94, 2, 0.13), pal[2], Vector2(0, lift))                 # 몸통
	_poly(_irr(_rad * 0.5, 5, 0.2), pal[3], Vector2(-_rad * 0.22, lift - _rad * 0.26))  # 상단 하이라이트
	match th:
		0:  # 던전: 이끼 얼룩
			_circle(_rad * 0.2, Color(pal[4].r, pal[4].g, pal[4].b, 0.45), Vector2(_rad * 0.25, lift + _rad * 0.2))
			_circle(_rad * 0.12, Color(pal[4].r, pal[4].g, pal[4].b, 0.4), Vector2(-_rad * 0.35, lift + _rad * 0.35))
		2:  # 정원: 꽃 몇 송이
			for off: Vector2 in [Vector2(-_rad * 0.3, lift - _rad * 0.1), Vector2(_rad * 0.32, lift + _rad * 0.05), Vector2(0.0, lift - _rad * 0.35)]:
				_circle(_rad * 0.13, pal[4], off)
				_circle(_rad * 0.05, Color("ffe08a"), off)
		3:  # 용암: 빛나는 균열
			var line := Line2D.new()
			line.width = 3.4
			line.default_color = pal[4]
			line.position = Vector2(0, lift)
			for pt: Vector2 in [Vector2(-_rad * 0.55, -_rad * 0.2), Vector2(-_rad * 0.1, _rad * 0.12), Vector2(_rad * 0.5, -_rad * 0.15)]:
				line.add_point(pt)
			var glow := Line2D.new()
			glow.width = 8.0
			glow.default_color = Color(pal[4].r, pal[4].g, pal[4].b, 0.32)
			glow.points = line.points
			glow.position = line.position
			glow.z_index = -1
			add_child(glow)
			add_child(line)
			_circle(_rad * 0.14, Color(pal[4].r, pal[4].g, pal[4].b, 0.9), Vector2(0, lift + _rad * 0.08))


func _bookshelf(pal: Array) -> void:  # 도서관 책장(솟은 나무 궤짝 + 책등)
	var w: float = _rad * 1.02
	var h: float = _rad * 1.4
	var top: float = -_rad * 0.5
	# 아웃라인 + 나무 몸통
	_poly(PackedVector2Array([Vector2(-w - 3, top - 3), Vector2(w + 3, top - 3), Vector2(w + 3, h + 3), Vector2(-w - 3, h + 3)]), pal[0])
	_poly(PackedVector2Array([Vector2(-w, top), Vector2(w, top), Vector2(w, h), Vector2(-w, h)]), pal[1])
	# 안쪽(선반)
	_poly(PackedVector2Array([Vector2(-w * 0.88, top + h * 0.14), Vector2(w * 0.88, top + h * 0.14), Vector2(w * 0.88, h * 0.9), Vector2(-w * 0.88, h * 0.9)]), pal[2])
	# 책등
	var cols: Array = [Color("c05a4a"), Color("4a80c0"), Color("d0a840"), Color("6ab04a"), Color("a05ac0")]
	var bw: float = w * 1.7 / 5.0
	for i in 5:
		var bx: float = -w * 0.85 + bw * float(i)
		var bh: float = h * 0.7 * (0.8 + 0.2 * sin(float(i) * 2.1))
		_poly(PackedVector2Array([Vector2(bx, h * 0.88 - bh), Vector2(bx + bw * 0.82, h * 0.88 - bh), Vector2(bx + bw * 0.82, h * 0.88), Vector2(bx, h * 0.88)]), cols[i % cols.size()])
	# 상단 나무 하이라이트
	_poly(PackedVector2Array([Vector2(-w, top), Vector2(w, top), Vector2(w * 0.9, top + h * 0.1), Vector2(-w * 0.9, top + h * 0.1)]), pal[3])


func _crystal(pal: Array) -> void:  # 천상 크리스탈(빛나는 다면체)
	_circle(_rad * 1.15, Color(pal[3].r, pal[3].g, pal[3].b, 0.22), Vector2(0, -_rad * 0.3))  # 오라 글로우
	var lift: float = -_rad * 0.35
	# 아웃라인
	_poly(PackedVector2Array([Vector2(0, -_rad * 1.25 + lift), Vector2(_rad * 0.72, _rad * 0.5 + lift), Vector2(0, _rad * 1.1 + lift), Vector2(-_rad * 0.72, _rad * 0.5 + lift)]), pal[0])
	# 몸통(어둠쪽 오른면 / 밝음쪽 왼면)
	_poly(PackedVector2Array([Vector2(0, -_rad * 1.15 + lift), Vector2(_rad * 0.62, _rad * 0.45 + lift), Vector2(0, _rad + lift)]), pal[1])
	_poly(PackedVector2Array([Vector2(0, -_rad * 1.15 + lift), Vector2(-_rad * 0.62, _rad * 0.45 + lift), Vector2(0, _rad + lift)]), pal[2])
	# 상단 밝은 면 + 반짝
	_poly(PackedVector2Array([Vector2(0, -_rad * 1.15 + lift), Vector2(-_rad * 0.3, -_rad * 0.2 + lift), Vector2(0, _rad * 0.1 + lift)]), pal[3])
	_circle(_rad * 0.12, Color(1, 1, 1, 0.95), Vector2(-_rad * 0.18, -_rad * 0.5 + lift))
