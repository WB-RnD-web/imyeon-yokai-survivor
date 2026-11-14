class_name XpGem
extends Node2D
## 경험치 젬 — 플레이어가 가까우면 자석 흡수, 근접 시 수집.

const MAGNET_RANGE: float = 130.0
const COLLECT_RANGE: float = 20.0
const MAX_SPEED: float = 640.0

var _value: int = 1
var _speed: float = 0.0
var _spawned_at: float = 0.0
var _life: float = 0.0
var _art: Node2D  # 크리스탈 그림 묶음 — 값이 커지면 통째로 다시 짓는다


const MAX_ACTIVE: int = 150  # 바닥 젬 상한 — 초과분은 즉시 흡수(노드 폭증/프레임드랍 방지)

## 젬 하나가 폴리곤 5장이라 상한 150이면 드로우 아이템만 750개다.
## 모바일/절전에서는 상한을 낮추고, 초과분은 지금처럼 즉시 경험치로 흡수한다(손해 없음).
static func active_cap() -> int:
	if G.mobile:
		return 55 if G.perf_level() == 0 else 80
	return MAX_ACTIVE


static var _live: int = 0
static var _all: Array = []  # 살아있는 젬 — 상한 초과분을 합칠 대상을 찾는다

## ★ 예전엔 상한을 넘으면 G.add_xp() 로 즉시 지급했다. 손해는 없지만 "구슬을 안 주웠는데
##   경험치가 오른다"가 되어 플레이어가 규칙을 못 읽는다(실제 리포트). 게다가 바닥이 꽉 찬
##   구간은 곧 몹이 가장 많은 구간이라, 하필 성장이 제일 빠른 순간에만 규칙이 달라졌다.
##   이제 초과분은 가장 가까운 기존 젬에 '합친다' — 화면 위 젬 수는 그대로, 줍는 규칙은 하나.
static func spawn(parent: Node, pos: Vector2, value: int) -> void:
	if _live >= active_cap():
		var best: XpGem = null
		var bd: float = 1.0e20
		for g2 in _all:
			if not is_instance_valid(g2):
				continue
			var d: float = (g2 as XpGem).global_position.distance_squared_to(pos)
			if d < bd:
				bd = d
				best = g2 as XpGem
		if best != null:
			best.absorb(value)
			return
		G.add_xp(value)  # 젬이 하나도 없는 예외 상황에서만 (손실 방지)
		return
	var g := XpGem.new()
	g._value = value
	g.global_position = pos
	parent.add_child(g)


## 다른 젬을 흡수 — 값이 커지면 등급 색과 크기가 같이 오른다(왜 커졌는지 눈에 보이게).
## ★ 처음엔 흡수할 때마다 그림을 통째로 다시 지었다. 바닥이 꽉 찬 구간은 곧 초당 수십 마리가
##   죽는 구간이라, 폴리곤 5장 해제+생성이 그 빈도로 돌면 예전의 발열 문제가 그대로 돌아온다.
##   지금은 색과 크기만 바꾼다 — 할당이 0이다.
func absorb(value: int) -> void:
	var before: Color = _tier_color()
	_value += value
	if _px_tier > 0 and _art != null and is_instance_valid(_art):
		if _tier() != _px_tier or _px_tier == 4:   # 단계가 바뀌면 그 단계 그림으로 바꿔 끼운다
			_art.queue_free()
			_build_art()
	elif _art != null and is_instance_valid(_art):
		var after: Color = _tier_color()
		if after != before:
			_art.modulate = Color(after.r / maxf(0.05, before.r), after.g / maxf(0.05, before.g),
				after.b / maxf(0.05, before.b), 1.0)
		_art.scale = Vector2.ONE * minf(1.9, _tier_radius() / 6.5)
	scale = Vector2(1.3, 1.3)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)


func _enter_tree() -> void:
	_live += 1
	_all.append(self)


func _exit_tree() -> void:
	_live -= 1
	_all.erase(self)


func _tier_color() -> Color:
	# 값에 따라 색 등급: 초록(소) → 시안(중) → 보라(대) → 금(합쳐진 덩어리).
	# 차가운 계열 = 골드(따뜻)와 구분. 금색 단계는 상한 초과분이 합쳐진 젬 전용이라
	# "저건 여러 개가 뭉친 거다"가 색만 보고 읽힌다.
	if _value >= 25:
		return Color("ffd54a")
	if _value >= 7:
		return Color("c07bff")
	if _value >= 3:
		return Color("35d8ff")
	return Color("6dff9b")


func _tier_radius() -> float:
	if _value >= 25:
		return minf(15.0, 9.5 + float(_value) * 0.05)
	return 6.5 if _value < 7 else 8.0


func _ready() -> void:
	add_to_group("xpgem")
	# 11/14 「무한 후반 렉」: 구슬을 몹 아래 한 층(z -4)에 모은다. 예전엔 몹과 생긴 순서대로 섞여 그려져서
	#   구슬(같은 그림 한 장)과 몹 몸이 번갈아 나올 때마다 묶음 그리기가 끊겼다. 바닥에 떨어진 것이라 몹 아래가 자연스럽다.
	if not G.lag_off.has("old_z"):
		z_index = -4
	_build_art()
	# 드랍 팝
	scale = Vector2(0.1, 0.1)
	var tw0 := create_tween()
	tw0.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


## 10차 C: 단계 1~4(값 1~2 · 3~6 · 7~24 · 25 이상). 단계마다 모양 · 크기 · 색이 같이 커지는 보석 그림.
func _tier() -> int:
	if _value >= 25:
		return 4
	if _value >= 7:
		return 3
	return 2 if _value >= 3 else 1


var _px_tier: int = 0   # 그림(시트)으로 그리는 중이면 그 단계, 아니면 0


func _build_art() -> void:
	var gs := FxLib.sprite("ui/pickup", "gem_%d" % _tier(), true)
	if gs != null:
		_art = gs
		_px_tier = _tier()
		if _px_tier == 4:   # 뭉친 덩어리는 값에 따라 1~1.25배
			_art.scale = Vector2.ONE * clampf(1.0 + float(_value - 25) / 200.0, 1.0, 1.25)
		add_child(_art)
		return
	_art = Node2D.new()
	add_child(_art)
	var col: Color = _tier_color()
	var r: float = _tier_radius()
	# 차가운 후광 (골드의 따뜻한 후광과 대비)
	var glow := Polygon2D.new()
	glow.polygon = G.regular_polygon(4, r + 5.0)
	glow.color = Color(col.r, col.g, col.b, 0.28)
	glow.z_index = -1
	_art.add_child(glow)
	# 크리스탈: 흰 외곽 마름모 + 본체 + 위/아래 면 음영 + 반짝
	var edge := Polygon2D.new()
	edge.polygon = G.regular_polygon(4, r + 1.4)
	edge.color = Color(1, 1, 1, 0.85)
	_art.add_child(edge)
	var body := Polygon2D.new()
	body.polygon = G.regular_polygon(4, r)
	body.color = col
	_art.add_child(body)
	var top := Polygon2D.new()  # 윗면 밝은 컷
	top.polygon = PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, 0), Vector2(-r, 0)])
	top.color = col.lightened(0.4)
	_art.add_child(top)
	var glint := Polygon2D.new()
	glint.polygon = G.regular_polygon(8, 1.2)
	glint.color = Color(1, 1, 1, 0.95)
	glint.position = Vector2(-r * 0.32, -r * 0.32)
	_art.add_child(glint)


func _process(delta: float) -> void:
	if not G.running:
		return  # 종료 후 진공/수집 정지 (S4 게이팅 일관)
	_life += delta
	if _px_tier == 0:
		rotation += delta * 3.0   # 도형만 돈다 — 그림은 시트가 반짝이고, 돌리면 도트에 계단이 생긴다
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	var d: float = global_position.distance_to(p.global_position)
	if d < COLLECT_RANGE:
		G.add_xp(_value)
		G.sfx("pickup", G.pickup_pitch(), -8.0)  # 진공 청소 연쇄 = 점점 높은 소리
		_pop()
		return
	var mrange: float = MAGNET_RANGE + (p as Player).magnet_bonus
	if d < mrange or _speed > 0.0 or G.magnet_active():
		_speed = minf(MAX_SPEED, _speed + 2400.0 * delta)
		global_position = global_position.move_toward(p.global_position, _speed * delta)


func _pop() -> void:
	set_process(false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.8, 1.8), 0.1)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(queue_free)
