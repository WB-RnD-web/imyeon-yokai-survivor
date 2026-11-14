class_name WhipWeapon
extends Node2D
## 특수무기: 채찍 — 조준 방향으로 넓은 부채꼴을 빠르게 후려침. 레벨업=길이/폭/데미지, 4레벨↑=양방향.

var level: int = 1
var _cd: float = 0.0
static var fx_drawn: int = 0     # 검사(--crowdshot)용: 휘두른 횟수 중 그림이 실제로 나간 수
static var fx_skipped: int = 0


func level_up() -> void:
	level += 1


## 사신의 낫(evo_reaper) — "휘두르는 반경이 커지고 약한 것은 즉사".
## ★ 예전엔 융합이 채찍 Lv11 + b_exec 6 만 줬다. b_exec 는 처형이라 실제로 걸리긴 했지만
##   "반경이 커진다"는 약속은 코드 어디에도 없었다(2026-09-06). 여기서 실제로 넓힌다.
func _is_reaper() -> bool:
	return G.fused("wpn_whip", "evo_reaper")


func _reach() -> float:
	return float(G.SP_BASE["wpn_whip"]["rad"]) * G.w_area_mult("wpn_whip", level) \
		* (1.45 if _is_reaper() else 1.0)


func _process(delta: float) -> void:
	_cd -= delta
	if _cd > 0.0:
		return
	var p := get_parent() as Player
	if p == null or not is_instance_valid(p):
		return
	_cd = maxf(float(G.SP_BASE["wpn_whip"]["cd_min"]), float(G.SP_BASE["wpn_whip"]["cd"]) * G.w_rate_mult("wpn_whip", level))
	_lash(p, p.aim)
	if level >= 4:  # 고레벨: 반대 방향도 동시 후려침
		_lash(p, -p.aim)


func _lash(p: Player, dir: Vector2) -> void:
	var reach: float = _reach()
	var half: float = deg_to_rad(74.0 if _is_reaper() else 54.0)   # 사신의 낫은 부채꼴도 넓다
	var dmg: float = float(G.SP_BASE["wpn_whip"]["dmg"]) * G.w_dmg_mult("wpn_whip", level) * G.sp_pow()
	var pull: bool = G.w_maxed("wpn_whip", level)
	var hits: int = 0
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Enemy
		if e == null or not is_instance_valid(e):
			continue
		var to: Vector2 = e.global_position - global_position
		if to.length() > reach + e.rad:
			continue
		if absf(to.angle_to(dir)) > half:
			continue
		var crit: bool = randf() < p.eff_crit()  # [감사 C23] 그림자 도적 대시 치명 부스트가 채찍에도 적용되게
		# 만렙 '끌어당김' — 넉백 방향을 뒤집는다. 후려친 것이 밀려나는 대신 딸려와,
		# 채찍이 무리를 뭉쳐 다른 무기 앞에 던져 놓는 무기가 된다.
		var kd: Vector2 = to.normalized() * (-1.0 if pull else 1.0)
		e.take_damage(dmg * (p.crit_mult if crit else 1.0), kd, crit, "wpn_whip")
		p._apply_melee_fx(e)
		hits += 1
	_whip_fx(dir, reach)
	if hits > 0:
		# 17-1 타격감: 대검(player._melee_swing)은 맞히면 히트스톱 0.03 을 거는데 채찍 · 사신의 낫은 흔들림 0.08 뿐이었다.
		#   사신의 낫이 무리를 한 번에 벨 때만(셋 이상) 짧게 멈춘다. 쿨이 0.42초까지 줄어서 매번 멈추면 판이 끊겨 보인다.
		var reaper: bool = _is_reaper()
		G.add_shake(0.14 if reaper else 0.10)
		if reaper and hits >= 3:
			G.hitstop(0.025)
		G.sfx_throttled("hit", randf_range(0.62, 0.74) if reaper else randf_range(0.72, 0.88), -5.0 if reaper else -7.0, 0.05)


## 채찍 후려치기 이펙트: 조준 방향으로 뻗는 빠른 초승달 스트리크
func _whip_fx(dir: Vector2, reach: float) -> void:
	# 17-1: 임팩트 예산(G.fx_budget)에 묶여 있어서 몹이 많으면 사신의 낫이 통째로 안 보였다 — 무기 몸통 예산으로 옮긴다.
	if not G.fx_weapon_budget():
		fx_skipped += 1
		return
	fx_drawn += 1
	# 8차 시트: 채찍 lash(칼끝 반지름 210px) · 사신의 낫 swing(250px). 반경에 맞춰 늘이고,
	# 왼쪽을 칠 땐 위아래를 뒤집어 늘 위에서 내려친다. 플레이어에 붙여 같이 움직인다.
	var reaper: bool = _is_reaper() and FxLib.has("evo_reaper", "swing")
	var wk: String = "evo_reaper" if reaper else "wpn_whip"
	var sh: String = "swing" if reaper else "lash"
	var sw := FxLib.burst(get_parent(), global_position, wk, sh, dir.angle(), reach / (250.0 if reaper else 210.0),
			0.30 if reaper else 0.20, 30, dir.x < 0.0)
	if sw != null:
		sw.modulate.a = FxLib.SWING_ALPHA
		return
	var ri: float = reach * 0.5
	var ro: float = reach * 1.02
	var w: float = deg_to_rad(96.0)
	var seg: int = 16
	var pts := PackedVector2Array()
	var vc := PackedColorArray()
	var edge := Color(1, 1, 1, 0.9)
	var body := Color(0.9, 0.65, 1.0, 0.34)
	for i in seg + 1:
		var a: float = -w * 0.5 + w * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * ro)
		vc.append(edge)
	for i in range(seg, -1, -1):
		var a2: float = -w * 0.5 + w * float(i) / float(seg)
		pts.append(Vector2(cos(a2), sin(a2)) * ri)
		vc.append(body)
	var blade := Polygon2D.new()
	blade.polygon = pts
	blade.vertex_colors = vc
	blade.rotation = dir.angle()
	blade.z_index = 30
	get_parent().add_child(blade)
	G.mine(blade)   # 19차: 영웅 둘레에서 흐리게
	blade.global_position = global_position
	var tw := blade.create_tween()
	tw.tween_property(blade, "scale", Vector2(1.12, 1.12), 0.14)
	tw.parallel().tween_property(blade, "modulate:a", 0.0, 0.16)
	tw.tween_callback(blade.queue_free)
