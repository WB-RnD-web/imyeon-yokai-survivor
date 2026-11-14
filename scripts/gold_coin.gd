class_name GoldCoin
extends Node2D
## 몬스터가 드랍하는 금화 — 자석 흡수 후 수집 시 골드 획득. (킬 시 자동증가 아님)

const MAGNET_RANGE: float = 120.0
const COLLECT_RANGE: float = 22.0
const MAX_SPEED: float = 620.0

var _value: int = 1
var _speed: float = 0.0
var _t: float = 0.0
var _art: _CoinArt
var _px: AnimatedSprite2D = null   # 10차 C 엽전 금화(도는 4칸) — 있으면 도형 대신


const MAX_ACTIVE: int = 120  # 바닥 금화 상한 — 초과분은 즉시 골드로 흡수


static func spawn(parent: Node, pos: Vector2, value: int) -> void:
	if value <= 0:
		return
	var tree := parent.get_tree()
	if tree != null and tree.get_nodes_in_group("coin").size() >= MAX_ACTIVE:
		G.add_gold(value)  # 바닥 금화 상한 초과 → 즉시 전액 적립
		return
	var c := GoldCoin.new()
	c._value = value
	c.global_position = pos
	parent.add_child(c)


func _ready() -> void:
	add_to_group("coin")
	_px = FxLib.sprite("ui/pickup", "coin", true)
	if _px != null:
		add_child(_px)
	else:
		_art = _CoinArt.new()
		add_child(_art)
	# 드랍 팝 + 살짝 튀어오르기
	scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	var off := Vector2(randf_range(-14.0, 14.0), randf_range(-18.0, -6.0))
	var land := global_position
	global_position = land + off
	var tw2 := create_tween()
	tw2.tween_property(self, "global_position", land, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not G.running:
		return  # [감사 C18] 승리 화면 중 수집(정산 후 증발) 방지 — 클리어 시 일괄 수거됨
	_t += delta
	# 동전이 도는 느낌(가로 플립) + 위아래 바운스 — 트랜스폼만 변경 ([감사 C32] 매 프레임 재드로우 제거)
	if _art != null:
		_art.scale.x = 0.4 + 0.6 * absf(cos(_t * 3.2))
		_art.position.y = sin(_t * 3.0) * 1.6
	elif _px != null:
		_px.position.y = roundf(sin(_t * 3.0) * 1.6)   # 도는 건 시트가 한다 — 둥실만
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	var d: float = global_position.distance_to(p.global_position)
	if d < COLLECT_RANGE:
		G.add_gold(_value)  # 주운 금화는 항상 전액 적립 (상한은 드랍 확률에서만)
		G.sfx("pickup", G.pickup_pitch() + 0.3, -10.0)  # 연속 줍기 = 점점 높은 소리
		_pop()
		return
	var mrange: float = MAGNET_RANGE + (p as Player).magnet_bonus
	if d < mrange or _speed > 0.0 or G.magnet_active():
		_speed = minf(MAX_SPEED, _speed + 2200.0 * delta)
		global_position = global_position.move_toward(p.global_position, _speed * delta)


func _pop() -> void:
	set_process(false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.7, 1.7), 0.1)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(queue_free)


## 진짜 금화처럼 — 동심원 림 음영 + 각인 + 광택(하이라이트)
class _CoinArt:
	extends Node2D
	var t: float = 0.0

	func _draw() -> void:
		# 은은한 후광
		draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.85, 0.35, 0.22))
		# 테두리(어두운 금) → 중간 금 → 밝은 면 → 안쪽 밝은 금
		draw_circle(Vector2.ZERO, 9.0, Color("8a5a12"))
		draw_circle(Vector2.ZERO, 8.0, Color("c8901f"))
		draw_circle(Vector2.ZERO, 6.5, Color("ffdb4a"))
		draw_circle(Vector2.ZERO, 4.6, Color("ffe98a"))
		# 안쪽 각인 링
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 28, Color("a9781c"), 1.2)
		# 중앙 조폐 마크(마름모)
		var d: float = 2.6
		draw_colored_polygon(
			PackedVector2Array([Vector2(0, -d), Vector2(d * 0.55, 0), Vector2(0, d), Vector2(-d * 0.55, 0)]),
			Color("b8860b"))
		# 광택 — 좌상단 점 + 곡선 하이라이트
		draw_circle(Vector2(-2.4, -3.0), 1.5, Color(1, 1, 1, 0.85))
		draw_arc(Vector2.ZERO, 5.4, deg_to_rad(200.0), deg_to_rad(275.0), 10, Color(1, 1, 1, 0.5), 1.4)
