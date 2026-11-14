class_name TelegraphAoE
extends Node2D
## 보스 예고형 장판 — 붉은 경고 원이 잠깐 뜬 뒤 폭발. 폭발 순간 반경 안에 있으면 피해(비켜야 함).

var radius: float = 130.0
var warn: float = 1.0
var dmg: float = 20.0
var _t: float = 0.0
var _struck: bool = false
var _fill: Polygon2D
var _ring: Line2D


static func spawn(parent: Node, pos: Vector2, radius: float, warn: float, dmg: float) -> void:
	var a := TelegraphAoE.new()
	a.radius = radius
	a.warn = warn
	a.dmg = dmg
	a.global_position = pos
	parent.add_child(a)


func _ready() -> void:
	z_index = -1  # 바닥 경고
	_fill = Polygon2D.new()
	_fill.polygon = G.regular_polygon(30, radius)
	_fill.color = Color(1.0, 0.25, 0.2, 0.1)
	add_child(_fill)
	_ring = Line2D.new()
	_ring.width = 4.0
	_ring.default_color = Color(1.0, 0.35, 0.3, 0.85)
	var pts := G.regular_polygon(30, radius)
	for p: Vector2 in pts:
		_ring.add_point(p)
	_ring.add_point(pts[0])
	add_child(_ring)


func _process(delta: float) -> void:
	if not G.running:
		return  # [감사 C31] 승리/종료 후 예고장판 폭발(흔들림+폭발음) 정지
	_t += delta
	if _struck:
		return
	var pr: float = clampf(_t / warn, 0.0, 1.0)
	# 경고가 점점 진해지고 맥동 → 곧 터진다는 신호
	_fill.color.a = 0.1 + 0.2 * pr
	var pulse: float = 1.0 + sin(_t * 18.0) * 0.02 * pr
	_ring.scale = Vector2(pulse, pulse)
	if _t >= warn:
		_struck = true
		_strike()


func _strike() -> void:
	set_process(false)
	# 반경 안 플레이어에게 피해
	var p := G.player
	if p != null and is_instance_valid(p) and global_position.distance_to((p as Node2D).global_position) < radius:
		if p.has_method("take_damage"):
			p.call("take_damage", dmg, "예고 장판")
	G.add_shake(0.45)
	G.sfx("hurt", 0.5, -2.0)
	# 폭발 링 확산
	var burst := Line2D.new()
	burst.width = 6.0
	burst.default_color = Color(1.0, 0.6, 0.3, 0.9)
	var bp := G.regular_polygon(30, radius)
	for p2: Vector2 in bp:
		burst.add_point(p2)
	burst.add_point(bp[0])
	add_child(burst)
	_fill.color = Color(1.0, 0.55, 0.25, 0.4)
	var tw := create_tween()
	tw.tween_property(burst, "scale", Vector2(1.35, 1.35), 0.25)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
