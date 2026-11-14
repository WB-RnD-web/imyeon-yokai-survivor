class_name PoisonWeapon
extends Node2D
## 특수무기: 주기적으로 독극물 장판(보라 웅덩이)을 깔아 그 안의 적을 지속 중독. 레벨업=크기/데미지/빈도↑.

var level: int = 1
var _cd: float = 0.0


func level_up() -> void:
	level += 1


func _process(delta: float) -> void:
	_cd -= delta
	if _cd <= 0.0:
		_cd = maxf(1.4, 2.5 * G.w_rate_mult("wpn_poison", level))
		_drop_puddle()


func _drop_puddle() -> void:
	var pos: Vector2 = global_position
	var e := _nearest()
	if e != null:
		pos = e.global_position
	var pud := _Puddle.new()
	pud.radius = float(G.SP_BASE["wpn_poison"]["rad"]) * G.w_area_mult("wpn_poison", level)
	# ★ 8.0 이었다. 중첩(최대 5스택, 스택당 +50%)이 붙었으니 1스택 기준값을 낮춰
	#   총량을 맞춘다 — 5스택이면 예전의 1.5배가 된다. 밟고 버티면 점점 아프다.
	pud.dps = float(G.SP_BASE["wpn_poison"]["dmg"]) * G.w_dmg_mult("wpn_poison", level) * G.sp_pow()
	pud.life = 4.0
	pud.plague = G.fused("wpn_poison", "evo_plague")
	if pud.plague:
		# 역병은 12종 중 가장 약했다(×2.47). 전염이 '독에 죽어야' 도는 조건부라 재료가
		# 단단한 상대에겐 한 번도 안 돈다 — 웅덩이 자체를 넓고 오래 가게 해서 바닥을 올린다.
		pud.radius *= 1.35
		pud.life = 6.0
	# 월드(main)에 붙여 깔린 자리에 고정 — 예전엔 플레이어 자식이라 따라다녔음
	var world: Node = get_parent()
	if world != null and world.get_parent() != null:
		world = world.get_parent()
	world.add_child(pud)
	G.mine(pud)   # 19차: 영웅 둘레에서 흐리게
	pud.global_position = pos


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


class _Puddle:
	extends Node2D
	var radius: float = 80.0
	var dps: float = 5.0
	var life: float = 4.0
	var _t: float = 0.0
	var _tick: float = 0.0
	var _blob: Polygon2D
	var plague: bool = false   # 역병 — 독에 죽은 자리에서 새 웅덩이가 돋는다
	var gen: int = 0           # 몇 대째인가 (2대에서 끊는다 — 화면이 독으로 덮이지 않게)


	## 죽은 자리에 한 대 아래 웅덩이를 남긴다. 작고 짧게 — 번지는 것이지 세지는 게 아니다.
	func _spawn_child(at: Vector2) -> void:
		var c := _Puddle.new()
		c.radius = radius * 0.62
		c.dps = dps * 0.7
		c.life = 2.6
		c.plague = true
		c.gen = gen + 1
		get_parent().add_child(c)
		G.mine(c)   # 19차: 영웅 둘레에서 흐리게
		c.global_position = at

	func _ready() -> void:
		add_to_group("hazard")   # 런이 끝나면 같이 치운다 (_clear_run_entities)
		z_index = -1  # 몹 아래 바닥
		# 8차 시트: 흐물거리는 테 + 거품(그림 속 반지름 맹독 96 · 역병 128)
		var pk: String = "evo_plague" if plague and FxLib.has("evo_plague", "pool") else "wpn_poison"
		var art := FxLib.sprite(pk, "pool", true)
		if art != null:
			var ps: float = radius / (128.0 if pk == "evo_plague" else 96.0)
			art.scale = Vector2(ps, ps)
			add_child(art)
			var bb := CPUParticles2D.new()
			bb.amount = 10
			bb.lifetime = 1.0
			bb.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			bb.emission_sphere_radius = radius * 0.7
			bb.direction = Vector2(0, -1)
			bb.spread = 18.0
			bb.gravity = Vector2(0, -20)
			bb.initial_velocity_min = 4.0
			bb.initial_velocity_max = 12.0
			bb.texture = FxLib.tile("wpn_poison", "bubble", 2)
			bb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(bb)
			scale = Vector2(0.3, 0.3)
			create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
			return
		var glow := Polygon2D.new()
		glow.polygon = _blob_pts(radius * 1.14, 0.16, 1)
		glow.color = Color(0.62, 0.16, 0.9, 0.3)
		add_child(glow)
		_blob = Polygon2D.new()
		_blob.polygon = _blob_pts(radius, 0.15, 7)
		_blob.color = Color(0.4, 0.07, 0.58, 0.66)
		add_child(_blob)
		# 밝은 독액 반점
		for i in 4:
			var a: float = TAU * float(i) / 4.0 + 0.6
			var sp := Polygon2D.new()
			sp.polygon = G.regular_polygon(10, radius * 0.22)
			sp.color = Color(0.82, 0.36, 1.0, 0.5)
			sp.position = Vector2(cos(a), sin(a)) * radius * 0.42
			add_child(sp)
		# 보글보글 거품
		var bub := CPUParticles2D.new()
		bub.amount = 18
		bub.lifetime = 1.2
		bub.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		bub.emission_sphere_radius = radius * 0.8
		bub.direction = Vector2(0, -1)
		bub.spread = 18.0
		bub.gravity = Vector2(0, -34)
		bub.initial_velocity_min = 8.0
		bub.initial_velocity_max = 26.0
		bub.scale_amount_min = 2.0
		bub.scale_amount_max = 5.0
		bub.color = Color(0.78, 0.42, 1.0, 0.7)
		add_child(bub)
		scale = Vector2(0.3, 0.3)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

	func _process(delta: float) -> void:
		if not G.running:
			return  # [감사 C8] 승리/종료 후 장판 정지
		_t += delta
		if _blob != null:
			var pl: float = 1.0 + sin(_t * 4.0) * 0.04
			_blob.scale = Vector2(pl, pl)
		_tick -= delta
		if _tick <= 0.0:
			# ★ 2026-09-15: 0.4 → 0.2. 밟고 나서 반 박자 뒤에 반응하니 "지금 독 위에 있나"가
			#   손에 안 잡혔다(실플레이 리포트). apply_poison 은 초당 피해로 환산되므로
			#   틱을 줄여도 **세기는 그대로**고 반응만 빨라진다.
			_tick = Enemy.HAZARD_TICK
			for n in G.enemies_cached():
				if not is_instance_valid(n):
					continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
				var e := n as Enemy
				if e != null and is_instance_valid(e) and global_position.distance_to(e.global_position) < radius:
					var alive0: bool = e.hp > 0.0
					var at0: Vector2 = e.global_position   # 죽으면 못 읽는다 — 미리 잡아 둔다
					e.apply_poison(dps, 1.0)
					# ★ 역병 — "독이 계속 번져 지나간 자리가 썩는다". 예전엔 융합이 독 Lv11 +
					#   b_poison 6 뿐이었고, 장판은 탄이 아니라 b_poison 이 안 걸렸다 — 번지는
					#   부분이 코드에 아예 없었다(2026-09-06). 독에 죽은 자리에서 새 웅덩이가 돋는다.
					#   세대 상한을 둬서 화면이 독으로 덮이지 않게 한다.
					if plague and gen < 2 and alive0 and (not is_instance_valid(e) or e.hp <= 0.0):
						_spawn_child(at0)
		life -= delta
		if life <= 0.0:
			set_process(false)
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.5)
			tw.tween_callback(queue_free)

	## 유기적인 웅덩이 외곽 (약간 울퉁불퉁)
	func _blob_pts(r: float, noise: float, seed_i: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var n: int = 22
		for i in n:
			var a: float = TAU * float(i) / float(n)
			var rr: float = r * (1.0 - noise + noise * (1.0 + sin(a * 3.0 + float(seed_i)) * 0.5))
			pts.append(Vector2(cos(a), sin(a)) * rr)
		return pts
