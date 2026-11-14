class_name ChainWeapon
extends Node2D
## 특수무기: 주기적으로 가까운 적들에게 연쇄 번개. 레벨업=연쇄 수/빈도/데미지↑.

var level: int = 1
var _cd: float = 0.6


func level_up() -> void:
	level += 1


func _process(delta: float) -> void:
	_cd -= delta
	if _cd <= 0.0:
		_cd = maxf(float(G.SP_BASE["wpn_chain"]["cd_min"]), float(G.SP_BASE["wpn_chain"]["cd"]) * G.w_rate_mult("wpn_chain", level))
		_zap()


func _zap() -> void:
	var hit: Array = []
	# ★ 이 무기의 번개 선은 지금까지 G.fx_budget() 회계 밖에서 만들어졌다(Lv6 기준 초당 23개).
	#   묶음 게이트로 막으면 무기가 통째로 안 보이므로, 절전에서는 '연쇄 수'를 줄이는 쪽으로 잇는다.
	# 만렙 '분기' 는 갈래만 늘리는 게 아니라 **닿는 수**를 늘려야 의미가 있다. 갈래만 바꾸면
	# 총 마디가 그대로라 모양만 바뀌고 화력은 1도 안 오른다(실측 912/s → 그대로).
	# 폭풍군주(evo_tempest) — "번개가 더 멀리·많이 옮겨 붙는다". 예전엔 융합해도 마디 수가
	# 그대로였다(사슬 Lv11 + b_shock 6 뿐 — 사슬은 탄을 안 쏘니 b_shock 이 안 걸린다).
	var tempest: bool = G.fused("wpn_chain", "evo_tempest")
	var extra: int = (2 if G.w_maxed("wpn_chain", level) else 0) + (4 if tempest else 0)
	var chains: int = maxi(2, int(round(float(3 + extra + G.w_grade("wpn_chain", level, "count")) * G.fx_scale())))
	var dmg: float = float(G.SP_BASE["wpn_chain"]["dmg"]) * G.w_dmg_mult("wpn_chain", level) * G.sp_pow()
	# 만렙 '분기' — 번개가 한 줄로만 흐르던 것이 갈라져 나무가 된다. 사슬의 정체성 그대로다.
	# 큐를 쓰면 한 지점에서 두 갈래가 나가고, 그 각각이 다시 이어진다.
	var forks: int = 2 if G.w_maxed("wpn_chain", level) else 1
	var q: Array = [global_position]
	while not q.is_empty() and hit.size() < chains:
		var cur: Vector2 = q.pop_front()
		for _f in forks:
			if hit.size() >= chains:
				break
			var e := _nearest(cur, hit)
			if e == null:
				break
			hit.append(e)
			_bolt(cur, e.global_position)
			e.take_damage(dmg, e.global_position - cur, false, "wpn_chain")
			# ★ 폭풍군주(evo_tempest)는 재료가 '탄막 감전'인데, 사슬은 **탄을 안 쏜다** —
			#   b_shock 이 내 총알에만 걸리고 번개 자체엔 아무 영향이 없었다(2026-09-07).
			#   재료의 효과가 결과 무기에 실려야 '합쳐졌다'가 된다. 번개가 직접 감전시킨다.
			if tempest and is_instance_valid(e):
				e.apply_shock(2.0)
			q.append(e.global_position)


func _nearest(from: Vector2, exclude: Array) -> Enemy:
	var best: Enemy = null
	var bd: float = 270.0 * (1.6 if G.fused("wpn_chain", "evo_tempest") else 1.0)  # '더 멀리'
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or e in exclude:
			continue
		var d: float = from.distance_to(e.global_position)
		if d < bd:
			bd = d
			best = e
	return best


func _bolt(a: Vector2, b: Vector2) -> void:
	if not G.fx_weapon_budget():
		return  # 무기 몸통 예산(17-1) — 군중전에서 선이 수십 개씩 쌓이던 것은 막되, 임팩트에 밀려 사라지지는 않게
	# 8차 시트: 이어 붙이는 번개 조각을 a→b 로 깔고(월드에), 맞은 자리에 번쩍. 폭풍군주는 굵은 판.
	var ck: String = "evo_tempest" if G.fused("wpn_chain", "evo_tempest") and FxLib.has("evo_tempest", "bolt") else "wpn_chain"
	var world: Node = get_parent().get_parent() if get_parent() != null else null
	if FxLib.tile_line(world, a, b, ck, "bolt", -1.0, 0.22, 4) != null:
		FxLib.burst(world, b, ck, "zap", 0.0, 1.0, -1.0, 21)
		return
	var pts := _zigzag(to_local(a), to_local(b))
	var line := Line2D.new()
	line.width = 3.5
	line.default_color = Color("cdeeff")
	line.points = pts
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var glow := Line2D.new()  # 굵은 반투명 글로우 (자식 → 함께 페이드/소멸)
	glow.width = 9.0
	glow.default_color = Color(0.55, 0.82, 1.0, 0.3)
	glow.points = pts
	glow.z_index = -1
	line.add_child(glow)
	add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.2)
	tw.tween_callback(line.queue_free)


## 두 점 사이 번개 지그재그 점열
func _zigzag(a: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var seg: int = 6
	var perp: Vector2 = (b - a).orthogonal().normalized()
	for i in seg + 1:
		var t: float = float(i) / float(seg)
		var base: Vector2 = a.lerp(b, t)
		var jit: float = 0.0 if (i == 0 or i == seg) else randf_range(-18.0, 18.0)
		pts.append(base + perp * jit)
	return pts
