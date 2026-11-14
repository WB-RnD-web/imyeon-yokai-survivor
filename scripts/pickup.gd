class_name Pickup
extends Node2D
## 특수 드랍 — 체력회복 / 경험치자석 / 주변빙결 / 대형경험치.

const HEAL: int = 0
const MAGNET: int = 1
const FREEZE: int = 2
const BIGXP: int = 3
const CHEST: int = 4  # 능력 만렙 보상 — 획득 시 진화
const CHEST_BOSS: int = 5  # 보스 드랍 상자 — 무작위 강화 1~5개 (5개는 극악, M37)

const MAGNET_RANGE: float = 150.0
const COLLECT_RANGE: float = 24.0

## 보물상자가 아닌 픽업의 수명(초). 예전엔 수명도 상한도 없어 한 판 내내 바닥에 쌓였다
## — 잡몹 처치 3.2% 확률 × 수천 킬이면 수백 개가 상주한다. 상자류는 보상이라 수명이 없다.
const LIFE: float = 55.0

var kind: int = 0
var _speed: float = 0.0
var _life: float = LIFE


static func spawn(parent: Node, pos: Vector2, kind: int) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.global_position = pos
	parent.add_child(p)


func _icon_id() -> String:
	match kind:
		HEAL:
			return "heal"
		MAGNET:
			return "item_magnet"
		FREEZE:
			return "freeze"
		CHEST, CHEST_BOSS:
			return "chest"
		_:
			return "bigxp"


## 10차 C: 줍는 것 그림(원 바탕 없이 물건 자체, 2칸 둥실 · 반짝).
func _sheet() -> String:
	match kind:
		HEAL:
			return "heal"
		MAGNET:
			return "magnet"
		FREEZE:
			return "freeze"
		CHEST:
			return "chest"
		CHEST_BOSS:
			return "chest_boss"
	return "bigxp"


var _px: bool = false


func _ready() -> void:
	var ps := FxLib.sprite("ui/pickup", _sheet(), true)
	if ps != null:
		_px = true
		add_child(ps)
		scale = Vector2(0.1, 0.1)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
		return
	var id: String = _icon_id()
	var col: Color = Icons.color_of(id)
	var big: bool = kind == CHEST or kind == CHEST_BOSS
	var gr: float = 34.0 if big else 21.0
	var bs: float = 48.0 if big else 30.0
	var glow := Polygon2D.new()
	glow.polygon = G.regular_polygon(18, gr)
	glow.color = Color(col.r, col.g, col.b, 0.35 if big else 0.3)
	glow.z_index = -1
	add_child(glow)
	var badge := IconBadge.new().setup(id, bs)
	badge.position = Vector2(-bs * 0.5, -bs * 0.5)
	add_child(badge)
	scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	if big:  # 보물상자는 둥실 강조
		var tw2 := create_tween().set_loops()
		tw2.tween_property(glow, "scale", Vector2(1.25, 1.25), 0.6)
		tw2.tween_property(glow, "scale", Vector2(1.0, 1.0), 0.6)


func _process(delta: float) -> void:
	if not G.running:
		return  # 종료 후 수집(보스 상자 등) 정지 — 승리 화면 연출 오염 방지 (S4)
	if not _px:
		rotation += delta * 1.5   # 그림은 돌리지 않는다(도트 계단)
	if kind != CHEST and kind != CHEST_BOSS:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		if _life < 6.0:  # 사라지기 전 깜빡임 — 유저가 "없어지는구나"를 알 수 있게
			modulate.a = 0.35 + 0.65 * absf(sin(_life * 6.0))
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	var d: float = global_position.distance_to(p.global_position)
	if d < COLLECT_RANGE:
		_collect()
		return
	var pull: float = MAGNET_RANGE
	if p.has_method("get") and (p as Player).magnet_bonus > 0.0:
		pull += (p as Player).magnet_bonus
	if d < pull or _speed > 0.0 or G.magnet_active():
		_speed = minf(560.0, _speed + 1800.0 * delta)
		global_position = global_position.move_toward(p.global_position, _speed * delta)


func _collect() -> void:
	set_process(false)
	var p := G.player as Player
	match kind:
		HEAL:
			if p != null:
				p.heal(16.0)  # 하향: 서서 주워먹으며 버티기 방지
			G.sfx("pickup", 1.4)
		MAGNET:
			G.magnet_all(1.0)
			G.sfx("pickup", 0.8)
		FREEZE:
			G.freeze_enemies(G.freeze_pickup_sec())   # 11/7: 어려움부터 짧게(2.6 → 지옥 1.4초)
			G.add_shake(0.4)
			G.sfx("levelup", 0.7)
		BIGXP:
			G.add_xp(10)
			G.sfx("pickup", 1.1)
		CHEST:
			_open_chest("chest_open", &"chest_collected")
			G.add_shake(0.5)
			G.sfx("levelup", 1.3)
		CHEST_BOSS:
			_open_chest("chest_open_boss", &"boss_chest_collected")
			G.add_shake(0.5)
			G.sfx("levelup", 1.3)
	if _opening:
		visible = false        # 상자 그림은 열리는 연출이 이어받는다
		queue_free()
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(2.0, 2.0), 0.12)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)


var _opening: bool = false

## 12차 F — 상자가 그 자리에서 열린다(흔들림 → 틈 빛 → 뚜껑). 뚜껑이 젖히는 칸(4번째, 0.37초)에 보상을 연다.
## 보스 상자는 보상 창이 판을 멈추므로, 연출은 멈춘 화면 밑에서도 끝까지 돈다.
## 그림이 없으면 예전처럼 바로 연다.
func _open_chest(sheet: String, sig: StringName) -> void:
	var host: Node = get_parent()
	var s: AnimatedSprite2D = null
	if _px and host != null:
		# 줍는 상자(40×40, 칸 가운데가 노드 자리)와 첫 칸이 같은 그림이다 — 상자 칸 (x, y) = 연출 칸 (x+12, y+24).
		# 기준점 [32, 59] 를 노드 아래 15px 에 두면 두 그림이 같은 자리에 겹친다.
		s = FxLib.burst(host, global_position + Vector2(0.0, 15.0), "ui/moment", sheet, 0.0, 1.0, -1.0, z_index + 1)
	if s == null:
		G.emit_signal(sig)
		return
	_opening = true
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	# 상자 노드는 곧 사라지니 G 에 묶어 둔다
	# QA 10/13: 타이머가 멈춤을 무시해서(기본값) 일시정지 중에 상자 창이 그 아래로 떴다 — 판과 같이 멈춘다
	get_tree().create_timer(0.37, false).timeout.connect(Callable(G, "emit_signal").bind(sig))
