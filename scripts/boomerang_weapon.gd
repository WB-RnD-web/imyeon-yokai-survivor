class_name BoomerangWeapon
extends Node2D
## 특수무기: 부메랑 — 조준 방향으로 던져 최대거리에서 되돌아옴. 오갈 때 모두 타격(관통). 레벨업=개수/데미지/거리.

var level: int = 1
var _cd: float = 0.0


func level_up() -> void:
	level += 1


func _process(delta: float) -> void:
	_cd -= delta
	if _cd > 0.0:
		return
	var p := get_parent() as Player
	if p == null or not is_instance_valid(p):
		return
	_cd = maxf(float(G.SP_BASE["wpn_boomerang"]["cd_min"]), float(G.SP_BASE["wpn_boomerang"]["cd"]) * G.w_rate_mult("wpn_boomerang", level))
	var cnt: int = 1 + G.w_grade("wpn_boomerang", level, "count")
	var base: float = p.aim.angle()
	for i in cnt:
		var a: float = base + (float(i) - float(cnt - 1) * 0.5) * 0.42
		_throw(p, Vector2(cos(a), sin(a)))
	G.sfx_throttled("shoot", 0.7, -9.0, 0.05)


func _throw(p: Player, dir: Vector2) -> void:
	var b := _Boomerang.new()
	b.owner_p = p
	b.dir = dir
	b.max_range = float(G.SP_BASE["wpn_boomerang"]["rad"]) * G.w_area_mult("wpn_boomerang", level)
	b.loops = 1 if G.w_maxed("wpn_boomerang", level) else 0
	b.dmg = float(G.SP_BASE["wpn_boomerang"]["dmg"]) * G.w_dmg_mult("wpn_boomerang", level) * G.sp_pow()
	b.global_position = p.global_position + dir * 18.0
	p.get_parent().add_child(b)
	G.mine(b)   # 19차: 영웅 둘레에서 흐리게


## 날아갔다 되돌아오는 부메랑 (월드에 존재, 플레이어를 향해 귀환)
class _Boomerang:
	extends Node2D
	var owner_p: Player
	var dir: Vector2 = Vector2.RIGHT
	var max_range: float = 260.0
	var loops: int = 0            # 만렙 '선회' — 반환점에서 돌 바퀴 수
	var _loop_t: float = 0.0
	var dmg: float = 12.0
	var _returning: bool = false
	var _traveled: float = 0.0
	var _hit_cd: Dictionary = {}
	var _spr: Node2D

	func _ready() -> void:
		var art := FxLib.sprite("wpn_boomerang", "bullet", true)   # 8차 시트(게임이 돌린다)
		if art != null:
			_spr = art
			add_child(art)
			return
		var poly := Polygon2D.new()
		_spr = poly
		# 부메랑 V자 날
		poly.polygon = PackedVector2Array([
			Vector2(-13, -3), Vector2(2, -12), Vector2(6, -7), Vector2(0, -1),
			Vector2(6, 7), Vector2(2, 12), Vector2(-13, 3), Vector2(-8, 0)])
		poly.color = Color("e8d24a")
		add_child(poly)
		var glow := Polygon2D.new()
		glow.polygon = G.regular_polygon(10, 16.0)
		glow.color = Color(1.0, 0.9, 0.4, 0.22)
		glow.z_index = -1
		add_child(glow)

	func _process(delta: float) -> void:
		if not G.running:
			return  # [감사 C8] 승리/종료 후 비행 중 부메랑 정지
		_spr.rotation += delta * 22.0
		var speed: float = 440.0
		if _loop_t > 0.0:
			# 만렙 '선회' — 반환점에서 반경 50 원을 한 바퀴 그리고 돌아온다.
			# 던진 것이 가장 멀리 간 지점에 한 번 더 머무르므로, 원거리 체류 시간이 는다.
			_loop_t -= delta
			var ang: float = (0.42 - _loop_t) / 0.42 * TAU
			global_position += dir.rotated(ang + PI * 0.5) * speed * delta
			if _loop_t <= 0.0:
				_returning = true
		elif not _returning:
			global_position += dir * speed * delta
			_traveled += speed * delta
			if _traveled >= max_range:
				if loops > 0:
					loops -= 1
					_loop_t = 0.42
				else:
					_returning = true
		else:
			if owner_p == null or not is_instance_valid(owner_p):
				queue_free()
				return
			var to: Vector2 = owner_p.global_position - global_position
			if to.length() < 26.0:
				queue_free()
				return
			global_position += to.normalized() * speed * 1.15 * delta
		_hit_scan()

	func _hit_scan() -> void:
		var now: int = Time.get_ticks_msec()
		for n in G.enemies_cached():
			if not is_instance_valid(n):
				continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
			var e := n as Enemy
			if e == null or not is_instance_valid(e):
				continue
			if global_position.distance_to(e.global_position) > 20.0 + e.rad:
				continue
			var key: int = e.get_instance_id()
			if now < int(_hit_cd.get(key, 0)):
				continue
			_hit_cd[key] = now + 260
			e.take_damage(dmg, dir, false, "wpn_boomerang")
			if owner_p != null and is_instance_valid(owner_p):
				owner_p._apply_melee_fx(e)
