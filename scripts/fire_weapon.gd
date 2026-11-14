class_name FireWeapon
extends Node2D
## 특수무기: 주위에 화염 오라 — 반경 내 적을 지속 화상. 넘실대는 불꽃 혀 + 잔불. 레벨업=반경/데미지↑.

var level: int = 1
var _cd: float = 0.0
var _t: float = 0.0
var _ring: Polygon2D
var _flames: Array = []
var _fx_mode: bool = false     # 8차 시트로 그린다(불꽃 고리 + 불씨)
var _aura: AnimatedSprite2D = null
var _aura_key: String = ""
var _emb: CPUParticles2D = null


func _ready() -> void:
	_fx_mode = FxLib.has("wpn_fire", "aura")
	if _fx_mode:
		_emb = _make_embers()
		var et: Texture2D = FxLib.tile("wpn_fire", "ember", 0)
		if et != null:
			_emb.texture = et
			_emb.scale_amount_min = 1.0
			_emb.scale_amount_max = 1.5
			_emb.color = Color.WHITE
			_emb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_refresh()
		return
	# 바닥 열기(은은)
	_ring = Polygon2D.new()
	_ring.color = Color(1.0, 0.45, 0.15, 0.15)
	_ring.z_index = -2
	add_child(_ring)
	# 넘실대는 불꽃 혀
	for i in 14:
		var f := Polygon2D.new()
		f.z_index = -1
		add_child(f)
		_flames.append(f)
	_emb = _make_embers()
	_refresh()


## 잔불(위로 올라가는 불티)
func _make_embers() -> CPUParticles2D:
	var emb := CPUParticles2D.new()
	emb.amount = 22
	emb.lifetime = 0.9
	emb.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emb.emission_sphere_radius = 70.0
	emb.direction = Vector2(0, -1)
	emb.spread = 25.0
	emb.gravity = Vector2(0, -60)
	emb.initial_velocity_min = 20.0
	emb.initial_velocity_max = 60.0
	emb.scale_amount_min = 1.5
	emb.scale_amount_max = 3.5
	emb.color = Color(1.0, 0.6, 0.2, 0.8)
	emb.z_index = -1
	add_child(emb)
	return emb


## 만렙 '전염' — 타 죽은 자리 주변 2마리에 화상을 옮긴다. 직접 피해는 안 준다:
## 피해까지 주면 죽음이 죽음을 부르는 연쇄가 되고, 그건 폭발 개화(b_bloom)의 몫이다.
func _spread_burn(at: Vector2, fd: float) -> void:
	var n: int = 0
	for m in G.enemies_cached():
		if n >= 2:
			break
		if not is_instance_valid(m):
			continue
		var e2 := m as Enemy
		if e2 == null or not is_instance_valid(e2):
			continue
		if at.distance_to(e2.global_position) > 84.0 + e2.rad:
			continue
		e2.apply_burn(maxf(2.0, fd * 0.8), 1.4)
		n += 1


## 지옥불(evo_inferno) — "불길이 훨씬 넓게 타올라 닿는 것을 태운다".
## ★ 예전엔 융합이 오라 Lv11 + b_fire 6 뿐이었다. 그런데 **오라는 탄을 안 쏜다** — b_fire 는
##   내 총알에만 걸리고 불길에는 아무 영향이 없었다. 그래서 '훨씬 넓게'가 거짓말이었다
##   (2026-09-06). 이제 실제로 넓어지고, 만렙에서만 되던 전염이 상시가 된다.
func _is_inferno() -> bool:
	return G.fused("wpn_fire", "evo_inferno")


func _radius() -> float:
	return float(G.SP_BASE["wpn_fire"]["rad"]) * G.w_area_mult("wpn_fire", level) \
		* (1.7 if _is_inferno() else 1.0)


func level_up() -> void:
	level += 1
	_refresh()


## 8차: 불꽃 고리 시트를 반경에 맞춘다(그림 속 바깥 반지름 화염 오라 100 · 지옥불 136). 바닥(몹 아래)에 깐다.
func _aura_sync() -> void:
	var k: String = "evo_inferno" if _is_inferno() and FxLib.has("evo_inferno", "aura") else "wpn_fire"
	if _aura == null or _aura_key != k:
		if _aura != null:
			_aura.queue_free()
		_aura = FxLib.sprite(k, "aura", true)
		_aura.z_as_relative = false
		_aura.z_index = -1
		add_child(_aura)
		_aura_key = k
	var s: float = _radius() / (136.0 if k == "evo_inferno" else 100.0)
	_aura.scale = Vector2(s, s)
	if _emb != null:
		_emb.emission_sphere_radius = _radius() * 0.85


func _refresh() -> void:
	if _fx_mode:
		_aura_sync()
		return
	var r: float = _radius()
	_ring.polygon = G.regular_polygon(30, r)
	var n: int = _flames.size()
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var f := _flames[i] as Polygon2D
		f.polygon = PackedVector2Array([Vector2(0, -7), Vector2(0, 7), Vector2(30, 0)])
		f.vertex_colors = PackedColorArray([Color(1.0, 0.9, 0.35, 0.9), Color(1.0, 0.9, 0.35, 0.9), Color(1.0, 0.32, 0.08, 0.7)])
		f.position = Vector2(cos(a), sin(a)) * (r * 0.88)
		f.rotation = a
		f.set_meta("phase", float(i) * 1.3)


func _process(delta: float) -> void:
	_t += delta
	if _fx_mode:
		_aura_sync()   # 지옥불로 바뀌는 순간을 놓치지 않게 매 프레임(값 비교뿐이라 싸다)
	else:
		_ring.rotation += delta * 0.3
	for f: Polygon2D in _flames:
		var ph: float = float(f.get_meta("phase", 0.0))
		f.scale = Vector2(0.8 + 0.4 * absf(sin(_t * 9.0 + ph)), 0.7 + 0.5 * sin(_t * 11.0 + ph))
	_cd -= delta
	if _cd <= 0.0:
		_cd = 0.5 * G.w_rate_mult("wpn_fire", level)
		var r: float = _radius()
		var spread: bool = G.w_maxed("wpn_fire", level) or _is_inferno()  # 지옥불은 상시 전염
		for n in G.enemies_cached():
			if not is_instance_valid(n):
				continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
			var e := n as Enemy
			if e == null or not is_instance_valid(e):
				continue
			if global_position.distance_to(e.global_position) < r:
				var fd: float = float(G.SP_BASE["wpn_fire"]["dmg"]) * 0.5 * G.w_dmg_mult("wpn_fire", level) * G.sp_pow()
				var was_alive: bool = e.hp > 0.0
				var at: Vector2 = e.global_position   # 죽으면 못 읽는다 — 미리 잡아 둔다
				e.take_damage(fd, Vector2.ZERO, false, "wpn_fire")
				# 만렙 '전염' — 오라에서 타 죽은 것이 옆으로 불을 옮긴다. 죽은 자리에서만
				# 번지므로 세대가 저절로 끊긴다(오라 밖 적은 다시 안 태운다).
				if spread and was_alive and (not is_instance_valid(e) or e.hp <= 0.0):
					_spread_burn(at, fd)
				if is_instance_valid(e):
					e.apply_burn(maxf(2.0, fd * 0.8), 1.0)
