class_name BeamWeapon
extends Node2D
## 특수무기: 회전 레이저 — 플레이어에서 뻗은 빔이 계속 회전하며 스치는 적을 지짐. 레벨업=길이/폭/데미지, 3레벨↑=빔 추가.

var level: int = 1
var _ang: float = 0.0
var _cd: float = 0.0
var _beams: Array = []  # Line2D (코어)
var _fx_key: String = ""      # 8차 시트로 그리는 중이면 그 무기 이름(wpn_beam / evo_nova)
var _fx_t: float = 0.0
var _core_fx: Node2D = null   # 초신성: 플레이어 둘레 별 고리


func _ready() -> void:
	_rebuild()


func level_up() -> void:
	level += 1
	_rebuild()


func _beam_count() -> int:
	# 만렙 '역회전' — 반대로 도는 얇은 빔이 한 줄 더 붙어 가위처럼 교차한다.
	# 초신성(evo_nova) — "레이저가 여러 갈래로 늘어 사방을 지진다". 예전엔 융합해도 갈래가
	# 하나도 안 늘었다(레이저 Lv11 + b_fire 6 뿐 — 빔은 탄이 아니라 b_fire 가 안 걸린다).
	return 1 + G.w_grade("wpn_beam", level, "count") + (1 if G.w_maxed("wpn_beam", level) else 0) \
		+ (3 if G.fused("wpn_beam", "evo_nova") else 0)


## 그 빔이 역회전 빔인가 (마지막 한 줄). 위력 절반 대신 반대로 돈다.
func _is_reverse(i: int) -> bool:
	return G.w_maxed("wpn_beam", level) and i == _beam_count() - 1


func _length() -> float:
	return float(G.SP_BASE["wpn_beam"]["rad"]) * G.w_area_mult("wpn_beam", level)


func _rebuild() -> void:
	for b in _beams:
		if is_instance_valid(b):
			b.queue_free()
	_beams = []
	var L: float = _length()
	if _core_fx != null and is_instance_valid(_core_fx):
		_core_fx.queue_free()
	_core_fx = null
	_fx_key = "evo_nova" if G.fused("wpn_beam", "evo_nova") and FxLib.has("evo_nova", "body") else \
		("wpn_beam" if FxLib.has("wpn_beam", "body") else "")
	if _fx_key != "":
		_rebuild_fx(L)
		return
	for i in _beam_count():
		var core := Line2D.new()
		core.width = 6.0 + float(level)
		core.default_color = Color("ff4fa0")
		core.begin_cap_mode = Line2D.LINE_CAP_ROUND
		core.end_cap_mode = Line2D.LINE_CAP_ROUND
		core.z_index = -1  # 캐릭터 아래에서 회전 (S4: z=6이 플레이어를 완전히 가리던 문제)
		core.add_point(Vector2(22.0, 0))  # 몸 중심을 비우고 바깥에서 시작 — 캐릭터 항상 보임
		core.add_point(Vector2(L, 0))
		var glow := Line2D.new()
		glow.width = 18.0 + 2.0 * float(level)
		glow.default_color = Color(1.0, 0.4, 0.72, 0.22)
		glow.z_index = -1
		glow.add_point(Vector2(22.0, 0))
		glow.add_point(Vector2(L, 0))
		core.add_child(glow)
		# ★ 예전엔 굵기만 다른 분홍 선 두 줄이었다. 회전하는 '선'이라 에너지로 안 읽힌다.
		#   흰 심지 + 끝단의 뜨거운 점을 얹고, _process 에서 폭을 맥동시킨다.
		var wick := Line2D.new()
		wick.width = maxf(1.6, core.width * 0.34)
		wick.default_color = Color(1.0, 0.94, 1.0, 0.9)
		wick.begin_cap_mode = Line2D.LINE_CAP_ROUND
		wick.end_cap_mode = Line2D.LINE_CAP_ROUND
		wick.add_point(Vector2(26.0, 0))
		wick.add_point(Vector2(L - 4.0, 0))
		core.add_child(wick)
		var tip := Polygon2D.new()
		tip.polygon = G.regular_polygon(7, core.width * 0.9)
		tip.color = Color(1.0, 0.85, 0.95, 0.85)
		tip.position = Vector2(L, 0)
		core.add_child(tip)
		core.set_meta("wick", wick)
		core.set_meta("tip", tip)
		add_child(core)
		_beams.append(core)


## 8차 시트: 몸통 조각을 가로로 이어 붙인 선 + 몸 쪽 시작점(root) + 끝(tip). 초신성은 몸 둘레 별 고리(core).
## 판정 반폭(18+2·레벨)이 자라는 만큼 선도 조금씩 굵어진다. _process 가 회전·맥동·칸 넘김을 한다.
func _rebuild_fx(L: float) -> void:
	var w: float = float(FxLib.info(_fx_key, "body")["h"]) * (1.0 + 0.07 * float(level - 1))
	for i in _beam_count():
		var core := FxLib.tiled_line(_fx_key, "body", w)
		core.z_index = -1   # 캐릭터 아래에서 회전
		core.add_point(Vector2(22.0, 0))
		core.add_point(Vector2(L, 0))
		var rt := FxLib.sprite("wpn_beam", "root", true)   # 시작점은 레이저 공용
		if rt != null:
			rt.position = Vector2(22.0, 0)
			core.add_child(rt)
		var tp := FxLib.sprite(_fx_key, "tip", true)
		if tp != null:
			tp.position = Vector2(L, 0)
			core.add_child(tp)
			core.set_meta("tip", tp)
		add_child(core)
		_beams.append(core)
	if _fx_key == "evo_nova" and FxLib.has("evo_nova", "core"):
		_core_fx = FxLib.sprite("evo_nova", "core", true)
		_core_fx.z_index = -1
		add_child(_core_fx)


func _process(delta: float) -> void:
	if _fx_key != "":
		_fx_t += delta
		var bt: Texture2D = FxLib.tile(_fx_key, "body", FxLib.frame_at(_fx_key, "body", _fx_t))
		for b in _beams:
			if is_instance_valid(b):
				(b as Line2D).texture = bt
	_ang += delta * 1.45
	var n: int = _beams.size()
	var pulse: float = 0.85 + 0.15 * sin(_ang * 9.0)   # 지글거리는 출력 (에너지처럼 보이게)
	for i in n:
		var bm := _beams[i] as Line2D
		# 만렙 '역회전' — 마지막 한 줄이 반대로 돈다. 두 줄이 가위처럼 엇갈린다.
		bm.rotation = (-_ang if _is_reverse(i) else _ang) + TAU * float(i) / float(n)
		var wk: Line2D = (bm.get_meta("wick") as Line2D) if bm.has_meta("wick") else null   # 8차 시트 선엔 심지가 없다
		if wk != null:
			wk.width = maxf(1.2, bm.width * 0.34 * pulse)
		var tp: Node2D = (bm.get_meta("tip") as Node2D) if bm.has_meta("tip") else null
		if tp != null:
			tp.scale = Vector2.ONE * pulse
			tp.rotation += delta * 6.0
	_cd -= delta
	if _cd > 0.0:
		return
	_cd = 0.1  # 10Hz 판정
	_damage_scan()


func _damage_scan() -> void:
	var L: float = _length()
	var hw: float = 18.0 + 2.0 * float(level)  # 빔 반폭
	var dmg: float = float(G.SP_BASE["wpn_beam"]["dmg"]) * 0.1 * G.w_dmg_mult("wpn_beam", level) * G.sp_pow() / maxf(0.4, G.w_rate_mult("wpn_beam", level))  # 틱당(10Hz)
	var nova: bool = G.fused("wpn_beam", "evo_nova")
	var n: int = _beams.size()
	for i in n:
		var rev: bool = _is_reverse(i)
		var a: float = (-_ang if rev else _ang) + TAU * float(i) / float(n)
		var bd := Vector2(cos(a), sin(a))
		var perpv := bd.orthogonal()
		for m in G.enemies_cached():
			if not is_instance_valid(m):
				continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
			var e := m as Enemy
			if e == null or not is_instance_valid(e):
				continue
			var rel: Vector2 = e.global_position - global_position
			var proj: float = rel.dot(bd)
			if proj < 0.0 or proj > L:
				continue
			if absf(rel.dot(perpv)) > hw + e.rad:
				continue
			var hit_dmg: float = dmg * (0.5 if rev else 1.0)
			e.take_damage(hit_dmg, bd, false, "wpn_beam")
			# ★ 초신성(evo_nova)은 재료가 '탄막 화염'인데, 빔은 **탄이 아니다** — b_fire 가
			#   내 총알에만 걸리고 레이저엔 아무 영향이 없었다(2026-09-07). 빔이 직접 태운다.
			if nova and is_instance_valid(e):
				e.apply_burn(maxf(2.0, hit_dmg * 0.9), 1.6)
