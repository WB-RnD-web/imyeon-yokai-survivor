class_name IceSummon
extends Node2D
## 특수무기: 얼음 정령 소환수가 가까운 적에게 얼음 탄을 발사(명중 시 감속). 레벨업=정령 수/발사속도↑.

var level: int = 1
var _spirits: Array = []


func _ready() -> void:
	_rebuild()


func level_up() -> void:
	level += 1
	_rebuild()


func _exit_tree() -> void:  # 무기 제거 시 월드에 붙은 정령도 함께 정리
	for s in _spirits:
		if is_instance_valid(s):
			(s as Node).queue_free()


func _rebuild() -> void:
	for s in _spirits:
		if is_instance_valid(s):
			s.queue_free()
	_spirits = []
	var world: Node = get_parent().get_parent() if get_parent() != null else null  # player -> Main
	if world == null:
		return
	var count: int = 2 + G.w_grade("summon_ice", level, "count") + G.sp_units()  # 멀티샷 카드도 정령 수를 늘린다
	for i in count:
		var s := _Spirit.new()
		# ★ 9.0 이었다. 관통 0 에 계수까지 낮아 특수무기 최하위였다(실측 Lv6 1604 /s,
		#   같은 급 화염 오라 2688 · 독장판 2607). 관통을 준 위에 계수도 올려 급을 맞춘다.
		s.dmg = float(G.SP_BASE["summon_ice"]["dmg"]) * G.w_dmg_mult("summon_ice", level)  # 기본치만 — 발사 시점에 sp_pow 곱 ([감사 C3])
		s.fire_gap = maxf(float(G.SP_BASE["summon_ice"]["cd_min"]), float(G.SP_BASE["summon_ice"]["cd"]) * G.w_rate_mult("summon_ice", level))
		s.orbit_i = i
		s.orbit_n = count
		s.ice_lv = 1 + int(level / 3)
		s.pierce = 1 + int(level / 3)   # Lv3 부터 2명, Lv6 이면 3명을 꿰뚫는다
		s.shatter = G.w_maxed("summon_ice", level)
		world.add_child(s)
		if G.player != null and is_instance_valid(G.player):
			s.global_position = (G.player as Node2D).global_position
		_spirits.append(s)


class _Spirit:
	extends Node2D
	var dmg: float = 6.0
	var fire_gap: float = 1.1
	var ice_lv: int = 1
	## ★ 예전엔 관통 0 이라 한 발에 한 마리만 맞고 사라졌다 — 특수무기 10종 중
	##   광역 성분이 0인 유일한 무기였고, 그래서 실측 최하위권이었다(2026-09-05).
	##   얼음탄이 줄을 꿰뚫고 지나가며 지나간 적을 전부 얼린다.
	var pierce: int = 1
	var shatter: bool = false   # 만렙 파쇄
	var orbit_i: int = 0
	var orbit_n: int = 1
	var _cd: float = 0.6
	var _t: float = 0.0
	var _art: Node2D
	var _atk_primed: bool = false

	func _ready() -> void:
		z_index = 4      # 초록 소환수와 같은 층 (적 위, 영웅 아래)
		_art = CharForge.pet_art("summon_ice", "res://assets/sprites/summons/summon_ice.png", 15.0)
		add_child(_art)

	func _physics_process(delta: float) -> void:
		if not G.running:
			return  # [감사 C8] 승리/종료 후 정지
		if G.player == null or not is_instance_valid(G.player):
			return
		_t += delta
		# 플레이어 주위 궤도
		var ang: float = _t * 1.2 + TAU * float(orbit_i) / float(maxi(1, orbit_n))
		var target: Vector2 = (G.player as Node2D).global_position + Vector2(cos(ang), sin(ang)) * 62.0
		var prev: Vector2 = global_position
		global_position = global_position.move_toward(target, 340.0 * delta)
		if _art is CreatureVisual:  # 시트는 스스로 걷는다 — 통통 튀기는 배율이 소수가 되므로 걸지 않는다
			var cv := _art as CreatureVisual
			cv.walk_speed = (global_position - prev).length() / maxf(delta, 0.0001)
			cv.look_dir = global_position - prev
			if not _atk_primed and _cd - delta <= cv.lead_time("attack"):
				_atk_primed = cv.play_once("attack")   # 준비 칸 → 쏘는 칸에 맞춰 얼음탄
		elif _art != null:  # 통통 튀는 애니메이션
			var bob: float = sin(_t * 5.0 + float(orbit_i))
			_art.position.y = bob * 2.0
			_art.scale = Vector2(1.0 + bob * 0.08, 1.0 - bob * 0.08)
		_cd -= delta
		if _cd <= 0.0:
			var e := _nearest()
			_atk_primed = false
			if e != null:
				_shoot(e)
				_cd = fire_gap

	func _shoot(e: Enemy) -> void:
		var dir: Vector2 = (e.global_position - global_position).normalized()
		var b := Bullet.new()
		b.setup(dir * 560.0, dmg * G.sp_pow(), pierce, false)  # 실시간 성장 반영 ([감사 C3])
		b.fx_key = "summon_ice"
		b.b_set_ice(ice_lv)
		# 만렙 '파쇄' — 멈춘 얼음탄이 파편으로 흩어진다. 캐논의 착탄 폭발과 같은 훅을 쓴다.
		if shatter:
			b.burst_on_stop = 0.5
		b.global_position = global_position
		get_parent().add_child(b)
		G.sfx_throttled("shoot", randf_range(1.2, 1.4), -12.0, 0.06)

	func _nearest() -> Enemy:
		var best: Enemy = null
		var bd: float = 345.0
		for n in G.enemies_cached():
			if not is_instance_valid(n):
				continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
			var en := n as Enemy
			if en == null or not is_instance_valid(en):
				continue
			var d: float = global_position.distance_to(en.global_position)
			if d < bd:
				bd = d
				best = en
		return best
