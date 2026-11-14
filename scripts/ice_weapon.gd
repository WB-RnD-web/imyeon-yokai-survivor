class_name IceWeapon
extends Node2D
## 특수무기: 주기적으로 서리 장판을 깔아 그 안의 적을 지속 데미지 + 감속.
## (예전엔 시전 순간 1회 펄스뿐 → 장판이 '가짜'였음. 이제 독처럼 지속 판정.)

var level: int = 1
var _cd: float = 0.0


func level_up() -> void:
	level += 1


func _process(delta: float) -> void:
	_cd -= delta
	if _cd <= 0.0:
		# ★ 예전엔 `2.2 - level*0.15` 이라는 **자체 선형식**이라 성장 트랙의 rate 칸을
		#   아예 안 읽었다. 카드는 "공격주기 -14%" 라고 예고하는데 실제로는 다른 폭으로
		#   줄었다 — 소환수에서 고쳤던 것과 같은 어긋남이다(2026-09-06).
		_cd = maxf(0.9, 2.2 * G.w_rate_mult("wpn_ice", level))
		_drop_field()


## 절대영도(evo_blizzard) — "서리 장판이 겹겹이 깔려 얼려 세운다".
## ★ 예전엔 융합이 얼음 Lv11 + b_ice 6 뿐이었다. 장판은 탄이 아니라 b_ice 가 안 걸리고,
##   '겹겹이'도 '얼려 세운다'도 코드에 없었다(2026-09-06). 이제 겹쳐 깔리고
##   그 안의 적은 감속이 아니라 **완전히 멈춘다**(enemy.apply_freeze).
func _drop_field() -> void:
	var pos: Vector2 = global_position
	var e := _nearest()
	if e != null:
		pos = e.global_position
	var bliz: bool = G.fused("wpn_ice", "evo_blizzard")
	var world: Node = get_parent()
	if world != null and world.get_parent() != null:
		world = world.get_parent()
	# 겹은 둘이면 충분하다. 셋으로 깔았더니 면적이 그대로 화력이 되어 ×8.5 로 튀었다
	# (--fusepower 실측). 이 융합의 핵심은 넓이가 아니라 **얼려 세우는 것**이다.
	var layers: int = 2 if bliz else 1
	for i in layers:
		var field := _IceField.new()
		field.radius = float(G.SP_BASE["wpn_ice"]["rad"]) * G.w_area_mult("wpn_ice", level)
		field.dps = float(G.SP_BASE["wpn_ice"]["dmg"]) * G.w_dmg_mult("wpn_ice", level) * G.sp_pow()
		field.maxed = G.w_maxed("wpn_ice", level)
		field.freezes = bliz
		field.life = 2.8
		world.add_child(field)
		G.mine(field)   # 19차: 영웅 둘레에서 흐리게
		# 겹겹이 — 한 점에 포개면 그냥 한 장이다. 조금씩 어긋나게 깔아 띠를 만든다.
		var a: float = TAU * float(i) / float(layers)
		field.global_position = pos + (Vector2(cos(a), sin(a)) * field.radius * 0.62 if i > 0 else Vector2.ZERO)


func _nearest() -> Enemy:
	var best: Enemy = null
	var bd: float = 340.0
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Enemy
		if e != null and is_instance_valid(e):
			var d: float = global_position.distance_to(e.global_position)
			if d < bd:
				bd = d
				best = e
	return best


class _IceField:
	extends Node2D
	var radius: float = 100.0
	var dps: float = 6.0
	var life: float = 2.8
	var _t: float = 0.0
	var _tick: float = 0.0
	var _dwell: Dictionary = {}   # 적별 체류 시간 — 만렙 '빙결' 판정용
	var maxed: bool = false
	var freezes: bool = false     # 절대영도 — 체류 없이 즉시 얼려 세운다

	func _ready() -> void:
		add_to_group("hazard")   # 런이 끝나면 같이 치운다 (_clear_run_entities)
		z_index = -1  # 몹 아래 바닥
		# 8차 시트: 서리 원(그림 속 반지름 빙결 110 · 절대영도 136) + 눈 결정 입자
		var fk: String = "evo_blizzard" if freezes and FxLib.has("evo_blizzard", "field") else "wpn_ice"
		var art := FxLib.sprite(fk, "field", true)
		if art != null:
			var fs: float = radius / (136.0 if fk == "evo_blizzard" else 110.0)
			art.scale = Vector2(fs, fs)
			add_child(art)
			var sn := CPUParticles2D.new()
			sn.amount = 10
			sn.lifetime = 1.1
			sn.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			sn.emission_sphere_radius = radius * 0.8
			sn.gravity = Vector2(0, 10)
			sn.initial_velocity_min = 4.0
			sn.initial_velocity_max = 16.0
			sn.texture = FxLib.tile("wpn_ice", "shard", 0)
			sn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(sn)
			scale = Vector2(0.2, 0.2)
			create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
			return
		# 서리 장판(반투명 원판)
		var patch := Polygon2D.new()
		patch.polygon = G.regular_polygon(28, radius)
		patch.color = Color(0.55, 0.85, 1.0, 0.24)
		add_child(patch)
		# 바깥으로 뻗는 얼음 크리스탈 스파이크
		for i in maxi(4, int(round(10.0 * G.fx_scale()))):  # 장식 스파이크만 밀도 연동(장판 판정은 그대로)
			var a: float = TAU * float(i) / 10.0
			var dir := Vector2(cos(a), sin(a))
			var perp := dir.orthogonal()
			var base := dir * radius * 0.5
			var spike := Polygon2D.new()
			spike.polygon = PackedVector2Array([base + perp * 9.0, base - perp * 9.0, dir * radius])
			spike.color = Color(0.78, 0.93, 1.0, 0.6)
			add_child(spike)
		var core := Polygon2D.new()
		core.polygon = G.regular_polygon(12, radius * 0.26)
		core.color = Color(0.92, 0.98, 1.0, 0.5)
		add_child(core)
		# 반짝이는 서리 입자
		var snow := CPUParticles2D.new()
		snow.amount = 14
		snow.lifetime = 1.1
		snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		snow.emission_sphere_radius = radius * 0.85
		snow.gravity = Vector2(0, 10)
		snow.initial_velocity_min = 4.0
		snow.initial_velocity_max = 16.0
		snow.scale_amount_min = 1.5
		snow.scale_amount_max = 3.5
		snow.color = Color(0.85, 0.96, 1.0, 0.8)
		add_child(snow)
		scale = Vector2(0.2, 0.2)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

	func _process(delta: float) -> void:
		if not G.running:
			return  # [감사 C8] 승리/종료 후 장판 정지
		_t += delta
		_tick -= delta
		if _tick <= 0.0:
			# ★ 0.4 → 0.2 (Enemy.HAZARD_TICK). 피해는 틱을 곱하므로 초당 피해는 그대로다.
			_tick = Enemy.HAZARD_TICK
			for n in G.enemies_cached():
				if not is_instance_valid(n):
					continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
				var e := n as Enemy
				if e != null and is_instance_valid(e) and global_position.distance_to(e.global_position) < radius:
					e.take_damage(dps * Enemy.HAZARD_TICK, Vector2.ZERO, false, "wpn_ice")  # dps * tick
					e.apply_slow(0.6)  # 판 위에 있는 동안 계속 감속 갱신
					# 절대영도 — "얼려 세운다". 체류를 기다리지 않고 판에 들어오는 즉시 멈춘다.
					if freezes:
						e.apply_freeze(0.55)
					# 만렙 '빙결' — 판 위에 1초 넘게 머문 것이 0.8초 완전히 멈춘다.
					# 감속의 연장이라 무기 정체성이 유지되고, 체류를 요구해서 도망칠 여지도 남는다.
					if maxed:
						var k: int = e.get_instance_id()
						var dw: float = float(_dwell.get(k, 0.0)) + Enemy.HAZARD_TICK
						if dw >= 1.0:
							e.apply_freeze(0.8)
							dw = 0.0
						_dwell[k] = dw
		life -= delta
		if life <= 0.0:
			set_process(false)
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.5)
			tw.tween_callback(queue_free)
