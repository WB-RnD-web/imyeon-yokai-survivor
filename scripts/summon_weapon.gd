class_name SummonWeapon
extends Node2D
## 특수무기: 소환수가 가까운 적을 쫓아 접촉 타격. 레벨업=소환수 수/데미지↑.

var level: int = 1
var _minions: Array = []


func _ready() -> void:
	_rebuild()


func level_up() -> void:
	level += 1
	_rebuild()


func _exit_tree() -> void:  # 무기 제거 시 월드에 붙은 소환수도 함께 정리
	for m in _minions:
		if is_instance_valid(m):
			(m as Node).queue_free()


func _rebuild() -> void:
	for m in _minions:
		if is_instance_valid(m):
			m.queue_free()
	_minions = []
	var world: Node = get_parent().get_parent() if get_parent() != null else null  # player -> Main
	if world == null:
		return
	var count: int = 2 + G.w_grade("wpn_summon", level, "count") + G.sp_units()
	# ★ 군단 융합 — 얼음 정령을 녹여 넣은 상태인가. 예전엔 이 자리에서 달라지는 게 레벨뿐이라
	#   "얼음정령이 사라지고 초록 소환수만 늘었다"로 읽혔다(2026-09-06 지적).
	#   실제로 b_ice(탄막 빙결)를 얹고 있었는데 소환수는 **탄을 안 쏜다** — 아무 데도 안 걸렸다.
	#   이제 합쳐진 소환수가 정령의 얼음탄을 직접 쏜다. 접촉 + 사격, 두 부모가 다 남는다.
	var legion: bool = false
	if G.player is Player:
		legion = (G.player as Player).fused_marks.get("wpn_summon", "") == "evo_legion"
	for i in count:
		var m := _Minion.new()
		m.dmg = float(G.SP_BASE["wpn_summon"]["dmg"]) * G.w_dmg_mult("wpn_summon", level)
		m.lv = level  # 기본치만 저장 — 실피해는 타격 시점 sp_pow 곱 ([감사 C3] 스냅샷 성장정지 수정)
		m.slot_i = i      # 제 자리 번호 — 목표점을 마리마다 다르게 잡는 데 쓴다
		m.slot_n = count
		m.legion = legion
		if legion:
			m.bolt_dmg = float(G.SP_BASE["summon_ice"]["dmg"]) * G.w_dmg_mult("wpn_summon", level)
			m.bolt_gap = maxf(0.45, float(G.SP_BASE["summon_ice"]["cd"]) * G.w_rate_mult("wpn_summon", level))
			m.ice_lv = 1 + int(level / 3)
			m.bolt_pierce = 1 + int(level / 3)
			# 재료의 특성은 **결과 레벨**로 판정한다. 융합 결과는 Lv13 이라 항상 켜진다 —
			# 재료가 만렙이 아니었더라도 융합했으면 그 특성을 받는 것이 '합쳐진다'의 뜻이다.
			m.shatter = G.w_maxed("summon_ice", level)
			m._bolt_cd = 0.35 + 0.11 * float(i)   # 마리마다 어긋나게 — 한 박자에 몰아 쏘면 지저분하다
		world.add_child(m)
		if G.player != null and is_instance_valid(G.player):
			m.global_position = (G.player as Node2D).global_position + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		_minions.append(m)


class _Minion:
	extends Area2D
	var dmg: float = 8.0
	var lv: int = 1          # 내부 클래스는 바깥 스코프를 못 본다 — 생성 시점에 넘겨받는다
	var slot_i: int = 0      # 몇 번째 소환수인가 (0..slot_n-1)
	var slot_n: int = 1      # 전부 몇 마리인가

	## ★ 예전엔 전원이 **같은 한 점**(적 중심, 적 없으면 플레이어 중심)을 목표로 삼고
	##   같은 속도로 move_toward 했다. move_toward 는 목표를 넘지 않고 정확히 도달하므로
	##   3~4마리가 같은 좌표에 스냅해 한 덩어리가 됐다(2026-09-04 지적).
	##   목표점 자체를 마리마다 다른 점으로 잡으면 수렴이 오히려 '대형 유지'가 된다.
	##   얼음 정령(summon_ice_weapon.gd:68)이 이미 쓰던 방식이고, 그래서 그쪽은 안 뭉쳤다.
	const RING_IDLE: float = 46.0    # 적이 없을 때 플레이어 주위에 서는 반지름
	const RING_SPIN: float = 0.8     # 대형이 도는 속도(rad/s) — 정지 중에도 마리가 구분된다
	## 취득은 **플레이어 기준**이다. 소환수 자신 기준이면 한 걸음 갈 때마다 탐지 원도 따라가서
	## 화면 밖 적을 계속 물고 나간다 — "어디 있는지 뭘 하는지 모르겠다"의 원인.
	##
	## ★ 2026-09-06: 레벨과 무관하게 300 고정이었다. 강화해도 닿는 거리가 안 늘어난다.
	##   기준을 원거리 몹에 맞춘다 — 저들은 플레이어에서 190~280px 를 유지하며 쏜다
	##   (enemy.gd 의 _ranged 분기). 만렙 소환수는 그 **바깥**까지 닿아야 원거리 몹을
	##   쫓아낼 수 있다. 260 × w_area_mult 이라 Lv6 에 304, 융합·초월이면 그 위로 간다.
	const LEASH_BASE: float = 260.0
	const LEASH_SLACK: float = 1.27  # 취득보다 넓게 놔줘야 경계에서 깜빡이지 않는다
	const MOVE_SPD: float = 340.0    # 플레이어 기본 330 보다 살짝 빠르게 — 안 그러면 영영 못 따라온다
	var _cd: Dictionary = {}
	var _art: Node2D
	var _prev_pos: Vector2 = Vector2.ZERO
	var _t: float = 0.0
	var _tick: float = 0.0
	## 군단 융합분 — 합쳐진 얼음 정령의 사격. 융합 전에는 전부 꺼져 있다.
	var legion: bool = false
	var bolt_dmg: float = 0.0
	var bolt_gap: float = 1.15
	var bolt_pierce: int = 1
	var ice_lv: int = 1
	var shatter: bool = false   # 얼음 정령의 만렙 특성 '파쇄' 승계분
	var _bolt_cd: float = 0.5
	## 지금 맡은 적. 마리마다 다른 적을 물어야 대형이 퍼진다.
	var _target: Enemy = null
	var _retarget: float = 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		monitoring = true
		z_index = 4      # 적(0) 위, 영웅(6) 아래 — 셋이 겹쳐도 누가 누군지 읽힌다

		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		# 반경도 레벨을 탄다. 예전엔 13 고정이라 몹이 몰려 있어도 한 마리가 겹치는 적이
		# 한둘뿐이었다. 트랙의 죽은 "rate" 칸을 "area" 로 바꿔 이 값이 자라게 했다.
		c.radius = float(G.SP_BASE["wpn_summon"]["rad"]) * G.w_area_mult("wpn_summon", maxi(1, lv))
		cs.shape = c
		add_child(cs)
		# 캐릭터 에셋 배역표에 펫이 있으면 시트로 그린다(없으면 예전 한 장 그림)
		_art = CharForge.pet_art("summon_green", "res://assets/sprites/summons/summon_green.png", 15.0)
		add_child(_art)


	func _physics_process(delta: float) -> void:
		if not G.running:
			return  # [감사 C8] 승리/종료 후 월드 소속 소환수 활동 정지
		if G.player == null or not is_instance_valid(G.player):
			return
		_t += delta
		_tick -= delta
		if _tick <= 0.0:
			# ★ 0.12 였다. 재타격 쿨(sp_hit_cd)이 이 격자에 올림돼서 Lv3~Lv6 의 쿨
			#   466·448·430·412ms 가 **전부 480ms 로 뭉개졌다** — 세 번 레벨을 올려도
			#   타격 빈도가 1도 안 올랐다(2026-09-05). 격자를 절반으로 줄여 성장이 보이게 한다.
			_tick = 0.06
			_damage_tick()
		var pp: Vector2 = (G.player as Node2D).global_position
		var e := _nearest()
		if e != null and pp.distance_to(global_position) > _leash() * LEASH_SLACK:
			e = null                      # 너무 멀리 나왔다 — 대상을 버리고 복귀
		# 제 자리 각도. 대형째 천천히 돌아서 멈춰 있어도 몇 마리인지 세어진다.
		var ang: float = _t * RING_SPIN + TAU * float(slot_i) / float(maxi(1, slot_n))
		var off: Vector2 = Vector2(cos(ang), sin(ang))
		var target: Vector2
		var spd: float = MOVE_SPD
		if e != null:
			# 적 주위 링. 피해는 겹침 판정(get_overlapping_bodies)이라 **적 반지름 + 13 안**에
			# 있어야 때린다 — 링을 적 크기에 비례시켜 큰 적일수록 넓게 벌어지게 한다.
			target = e.global_position + off * clampf(e.rad * 0.8, 8.0, 26.0)
		else:
			target = pp + off * RING_IDLE
			# 복귀 중엔 플레이어보다 빨라야 한다. 이동속도 카드를 많이 먹으면 340 으로도 못 따라온다.
			if G.player is Player:
				spd = maxf(MOVE_SPD, (G.player as Player).move_speed * 1.15)
		# 군단 — 합쳐진 얼음 정령의 사격. 접촉 사거리 밖의 적도 이걸로 닿는다.
		if legion:
			_bolt_cd -= delta
			if _bolt_cd <= 0.0 and e != null:
				_bolt_cd = bolt_gap
				_shoot_bolt(e)
		var prev_x: float = global_position.x
		global_position = global_position.move_toward(target, spd * delta)
		if _art is CreatureVisual:  # 시트는 스스로 걷는다 — 통통·기울임은 배율이 소수가 되므로 걸지 않는다
			var cv := _art as CreatureVisual
			var moved: Vector2 = global_position - _prev_pos if _prev_pos != Vector2.ZERO else Vector2.ZERO
			cv.walk_speed = moved.length() / maxf(delta, 0.0001)
			cv.look_dir = moved
			_prev_pos = global_position
		elif _art != null:  # 젤리처럼 통통 튀기 + 진행방향 살짝 기울임
			var bob: float = sin(_t * 5.0)
			_art.position.y = bob * 2.0
			_art.scale = Vector2(1.0 + bob * 0.08, 1.0 - bob * 0.08)
			_art.rotation = clampf((global_position.x - prev_x) * 0.02, -0.14, 0.14)

	## 군단의 얼음탄. 얼음 정령이 쏘던 것과 **같은 탄**이다 — 사라진 게 아니라 여기로 옮겨왔다.
	## ★ 처음엔 감속(b_set_ice)만 옮기고 정령의 만렙 특성 '파쇄'를 빼먹었다. 그래서 융합하면
	##   탄이 날아가기만 하고 안 터졌다 — "차라리 따로 들고 다니는 게 낫지 않나"가 나온 이유다
	##   (2026-09-07 지적). 융합은 재료의 특성을 **잃는 자리가 아니라 합치는 자리**여야 한다.
	##   군단은 12종 중 유일한 무기+무기 융합이라 이 손실이 여기서만 일어났다.
	func _shoot_bolt(e: Enemy) -> void:
		if not is_instance_valid(e):
			return
		if _art is CreatureVisual:   # 군단 사격 — 쏘는 시트가 있으면 그걸로, 없으면 부딪치기 동작
			var cv := _art as CreatureVisual
			if not cv.play_once("attack"):
				cv.play_once("skill")
		var b := Bullet.new()
		var dir: Vector2 = (e.global_position - global_position).normalized()
		b.setup(dir * 560.0, bolt_dmg * G.sp_pow(), bolt_pierce, false)  # 실시간 성장 반영
		b.fx_key = "evo_legion"
		b.b_set_ice(ice_lv)
		if shatter:
			b.burst_on_stop = 0.5   # 정령의 만렙 특성 '파쇄' — 멈춘 얼음탄이 파편으로 흩어진다
		b.global_position = global_position
		get_parent().add_child(b)
		G.sfx_throttled("shoot", randf_range(1.2, 1.4), -13.0, 0.08)

	## 이 소환수가 대상을 잡는 거리. 레벨이 오르면 같이 늘어난다.
	## 군단은 쏘기까지 하므로 더 멀리 본다 — "사거리가 그대로다"의 답이다.
	func _leash() -> float:
		return LEASH_BASE * G.w_area_mult("wpn_summon", maxi(1, lv)) * (1.35 if legion else 1.0)

	## ★ 뭉침의 진짜 원인은 이동 코드가 아니라 **목표가 같다**는 것이었다.
	##   2026-09-04 에 목표점을 마리마다 흩는 대형 코드를 넣었는데도 여전히 뭉치는 이유가 이거다 —
	##   전원이 같은 한 마리를 물면 그 적 주위 8~26px 링에 다 모인다. 그건 대형이 아니라 덩어리다.
	##   이제 slot_i 번째로 가까운 적을 맡는다. 적이 많으면 군중 속으로 퍼지고, 적으면 자연히 겹친다.
	##   매 프레임 k번째를 고르면 비싸고 목표가 떨리므로 0.22초마다만 다시 고른다.
	func _nearest() -> Enemy:
		_retarget -= get_physics_process_delta_time()
		if _retarget > 0.0 and is_instance_valid(_target) and not (_target as Enemy)._dead:
			return _target
		_retarget = 0.22
		_target = _pick_nth(slot_i)
		return _target

	## 플레이어에서 n 번째로 가까운 적. 후보를 n+1 칸짜리 작은 배열에 끼워 넣는 방식이라
	## 전체 정렬을 안 한다 (적 90마리 × 칸 8개면 한 마리당 720 비교, 0.22초에 한 번).
	func _pick_nth(n: int) -> Enemy:
		if G.player == null or not is_instance_valid(G.player):
			return null
		var pp: Vector2 = (G.player as Node2D).global_position
		var lim: float = _leash()
		var keep: int = n + 1
		var best: Array = []   # [{e, d}] — 가까운 순으로 최대 keep 칸
		for nd in G.enemies_cached():
			if not is_instance_valid(nd):
				continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
			var en := nd as Enemy
			if en == null or not is_instance_valid(en) or en._dead:
				continue
			var d: float = pp.distance_to(en.global_position)   # ★ 소환수가 아니라 **플레이어** 기준
			if d >= lim:
				continue
			if best.size() >= keep and d >= float((best[keep - 1] as Dictionary)["d"]):
				continue
			var ins: int = best.size()
			for i in best.size():
				if d < float((best[i] as Dictionary)["d"]):
					ins = i
					break
			best.insert(ins, {"e": en, "d": d})
			if best.size() > keep:
				best.resize(keep)
		if best.is_empty():
			return null
		# 맡을 적이 마리 수보다 적으면 앞에서부터 돌려 쓴다 — 남는 소환수가 놀지 않게
		return (best[mini(n, best.size() - 1)] as Dictionary)["e"] as Enemy

	## ★ 예전엔 body_entered 시그널만 썼다. 그건 '처음 겹칠 때 한 번'만 오는 신호라,
	##   소환수가 적 위에 올라타 있어도 그 뒤로는 영영 안 때렸다 — 적이 빠졌다 다시 들어와야 했다.
	##   피해량을 올려도 DPS 가 안 움직이던 이유가 이거였다(실측: 데미지 +55% 에 DPS +2%).
	##   이제 겹친 적을 주기적으로 훑어 쿨이 찬 대상을 때린다.
	## 만렙 충격파 — 때린 적 주위 반경 30 에 절반 위력. 본체 타격을 받은 적은 제외한다.
	func _shock(src: Enemy, d: float) -> void:
		for n in G.enemies_cached():
			if not is_instance_valid(n):
				continue
			var e := n as Enemy
			if e == null or not is_instance_valid(e) or e == src:
				continue
			if src.global_position.distance_to(e.global_position) > 30.0 + e.rad:
				continue
			G.tally("소환수충격파", d)
			e.take_damage(d, e.global_position - src.global_position, false, "wpn_summon")

	func _damage_tick() -> void:
		var now: int = Time.get_ticks_msec()
		for body in get_overlapping_bodies():
			if not (body is Enemy) or not is_instance_valid(body):
				continue
			var key: int = body.get_instance_id()
			if now < int(_cd.get(key, 0)):
				continue
			_cd[key] = now + G.sp_hit_cd(520, lv)
			var hit: float = dmg * G.sp_pow()
			(body as Enemy).take_damage(hit, body.global_position - global_position, false, "wpn_summon")  # 실시간 성장 반영
			if _art is CreatureVisual:
				(_art as CreatureVisual).play_once("skill")   # 부딪치기
			if G.fx_budget():
				FxLib.burst(get_parent(), (body as Node2D).global_position, "wpn_summon", "bite", 0.0, 1.0, -1.0, 21, randf() < 0.5)
			# 만렙 '충격파' — 때린 자리에 작은 파문. 접촉 타격이 정체성이니 그 연장이다.
			# ★ 같은 패치에서 기본 접촉 피해를 7.0 → 5.5 로 내렸다. 소환수는 실측 화력 1위라
			#   특성만 얹으면 +50% 가 되어 나머지 무기를 통째로 밀어낸다.
			if G.w_maxed("wpn_summon", lv):
				_shock(body as Enemy, hit * 0.45)
		if _cd.size() > 48:  # 죽은 적의 쿨 기록이 런 내내 쌓이던 것 정리
			for k in _cd.keys():
				if now > int(_cd[k]) + 4000:
					_cd.erase(k)
