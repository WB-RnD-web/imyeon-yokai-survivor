class_name OrbitWeapon
extends Node2D
## 특수무기: 주위를 도는 오브가 접촉한 적을 타격. 레벨업=오브 수/크기/데미지↑.

var level: int = 1
var _orbs: Array = []
var _ang: float = 0.0


func _ready() -> void:
	_rebuild()


func level_up() -> void:
	level += 1
	_rebuild()


func _rebuild() -> void:
	for o in _orbs:
		if is_instance_valid(o):
			o.queue_free()
	_orbs = []
	var n: int = 2 + G.w_grade("wpn_orb", level, "count") + G.sp_units()
	for i in n:
		var o := Area2D.new()
		o.collision_layer = 0
		o.collision_mask = 2  # 적
		o.monitoring = true
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 13.0
		cs.shape = c
		o.add_child(cs)
		var orb_art := FxLib.sprite("wpn_orb", "orb", true)   # 8차 시트 — 위로 타오르는 불꽃이라 돌리지 않는다
		o.add_child(orb_art if orb_art != null else CharForge.pet_art("summon_orb", "res://assets/sprites/summons/summon_orb.png", 13.0))
		o.set_meta("cd", {})
		o.body_entered.connect(_on_orb_hit.bind(o))
		add_child(o)
		_orbs.append(o)


var _scan: float = 0.0


## ★ _process(렌더 프레임)가 아니라 _physics_process 다. Area2D 의 겹침 정보는 물리
##   프레임에 갱신되므로, 렌더 프레임에서 위치를 옮기고 바로 물어보면 어긋난 답이 온다.
func _physics_process(delta: float) -> void:
	_ang += delta * 2.0 / maxf(0.5, G.w_rate_mult("wpn_orb", level))
	var n: int = _orbs.size()
	var rad: float = float(G.SP_BASE["wpn_orb"]["rad"]) * G.w_area_mult("wpn_orb", level)
	for i in n:
		var a: float = _ang + TAU * float(i) / float(n)
		(_orbs[i] as Node2D).position = Vector2(cos(a), sin(a)) * rad
	# ★ body_entered 만으로는 **겹쳐 있는 동안 한 번도 안 때린다.** 그 신호는 '처음 닿을 때'
	#   한 번뿐이라, 오브 안에 적이 들어와 머무르면 그대로 무해해진다.
	#   (--weapondps 실측: wpn_orb 가 Lv2 도 Lv6 도 0.0 /s — 2026-09-05)
	#   소환수에서 이미 같은 자리를 고쳤다. 주기적으로 겹친 적을 훑는다.
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.06
		for o in _orbs:
			if not is_instance_valid(o):
				continue
			for b in (o as Area2D).get_overlapping_bodies():
				_on_orb_hit(b, o as Area2D)
			# 만렙 '요격' — 오브가 적의 탄을 쳐낸다. 게임에서 유일한 방어형 특수무기가 된다.
			# 피해는 안 오르지만 생존이 오른다 — 이 무기가 원래 하던 '몸 주위를 지킨다'의 연장.
			if G.w_maxed("wpn_orb", level):
				for a2 in (o as Area2D).get_overlapping_areas():
					# 유효성 먼저 — 이번 프레임에 이미 사라진 탄에 `is` 를 걸면 캐스트가 터진다
					if is_instance_valid(a2) and a2 is EnemyBullet:
						G.tally("오브요격", 0.0)
						(a2 as Node).queue_free()


func _on_orb_hit(body: Node, orb: Area2D) -> void:
	# ★ 유효성 먼저. 겹침 목록은 이번 프레임에 이미 해제된 개체를 담을 수 있고,
	#   해제된 것에 `is` 를 걸면 "Trying to cast a freed object" 로 터진다.
	if not is_instance_valid(body):
		return
	if body is Enemy:
		var cd: Dictionary = orb.get_meta("cd")
		var key: int = body.get_instance_id()
		var now: int = Time.get_ticks_msec()
		if now < int(cd.get(key, 0)):
			return
		cd[key] = now + G.sp_hit_cd(380, level)
		if cd.size() > 48:  # 죽은 적의 쿨 기록이 런 내내 쌓이던 것 정리
			for k in cd.keys():
				if now > int(cd[k]) + 4000:
					cd.erase(k)
		(body as Enemy).take_damage(float(G.SP_BASE["wpn_orb"]["dmg"]) * G.w_dmg_mult("wpn_orb", level) * G.sp_pow(), body.global_position - global_position, false, "wpn_orb")
