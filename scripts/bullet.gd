class_name Bullet
extends Area2D
## 직선 이동 · 적 히트 시 데미지 + 원소효과(얼음/화염/독/감전) + 거대/튕김. 수명 후 소멸.

const RADIUS: float = 5.0
const LIFETIME: float = 2.2  # 안전 캡 (4.5→2.2: 장수명 탄 누적 방지)
## ★ 예전 680px 은 화면 반폭(640)보다 길었다. 게다가 유도탄은 1.7배(1,156px)라
##   화면 밖까지 나가 계속 사냥했고, 튕김까지 붙으면 "탄이 안 사라지는" 체감이 된다
##   (실플레이 리포트: "끝까지 유도나 튕기는거때문에 거리가 초기화되는 느낌").
##   이제 무기마다 자기 사거리(WEAPON_DEFS.range × 성장 트랙)를 들고 날아간다.
const MAX_DIST: float = 430.0  # 무기가 사거리를 안 넘겨줬을 때의 기본값

var _vel: Vector2 = Vector2.ZERO
var _dmg: float = 10.0
var _life: float = LIFETIME
var _pierce: int = 0
var _crit: bool = false
var _hit: Array = []
var _traveled: float = 0.0
var max_dist: float = MAX_DIST  # 발사한 무기가 지정 (없으면 기본값)

# 탄막 부여 효과 (player.b_* 레벨)
var _fx_ice: int = 0
var _fx_fire: int = 0
var _fx_poison: int = 0
var _fx_shock: int = 0
var _fx_big: int = 0
var _fx_bounce: int = 0
var _fx_chain: int = 0  # 연쇄: 명중 시 주변 적에게 번개 전이
var _fx_homing: int = 0  # 유도: 가까운 적을 향해 휘어짐
var _elem_tint: Color = Color(0, 0, 0, 0)  # 무기 아키타입 색(원소효과 없을 때)
var _arch: String = ""  # 발사한 무기 아키타입 — 탄환 실루엣 분리 (S4: 무기가 섞여 보이던 문제)
var fusion_id: String = ""  # 비어 있지 않으면 융합 무기가 쏜 탄 — 전용 실루엣 + 금빛 테두리
## 13차 결과 화면 — 이 탄이 누구 몫인지(G.run_dmg). 융합 → 지정 이펙트(특수무기 탄) → 아키타입 카드 id.
func _src_id() -> String:
	if fusion_id != "":
		return fusion_id
	if fx_key.begins_with("wpn_") or fx_key.begins_with("evo_") or fx_key == "summon_ice":
		return fx_key
	return "wp_" + (_arch if _arch != "" else "balanced")


var fx_key: String = ""     # 이펙트 시트 무기 이름을 직접 지정(얼음 정령 · 군단 얼음탄). 비면 융합 → 무기 순
var _trail: Line2D
var _homing_tgt: Enemy = null  # 유도/튕김 재사용 타깃 캐시 (매 프레임 전수 스캔 방지)
var _retarget_t: float = 0.0   # 재조준 쿨(초)
var _trail_accum: float = 0.0  # 트레일 점 간격 누적(px)

# ── 만렙(Lv6) 특성 — G.MAX_TRAIT 참고. 부여는 player._fire_ranged 의 apply_from **뒤**에서 한다 ──
var pierce_decay: float = 0.72  # 각궁 '무뎌지지 않는다' 가 0.82 로 올린다
var relaunch: int = 0           # 신칼 '회수' — 사거리가 다하면 이 횟수만큼 되돌아온다
var burst_on_stop: float = 0.0  # 캐논 '착탄 폭발' · 얼음정령 '파쇄' — 멈추는 자리에서 터지는 비율


func setup(vel: Vector2, dmg: float, pierce: int = 0, crit: bool = false) -> void:
	_vel = vel
	_dmg = dmg
	_pierce = pierce
	_crit = crit


## 플레이어의 탄막 부여 효과를 복사 (add_child 전에 호출)
func apply_from(p: Player) -> void:
	_fx_ice = p.b_ice
	_fx_fire = p.b_fire
	_fx_poison = p.b_poison
	_fx_shock = p.b_shock
	_fx_big = p.b_big
	_fx_bounce = p.b_bounce
	_fx_chain = p.b_chain
	_fx_homing = p.b_homing


## 소환수 등이 개별 원소탄을 쏠 때 사용
func b_set_ice(lv: int) -> void:
	_fx_ice = lv


## 트레일 리소스 공유 — 색 종류는 대여섯 개뿐이라 캐시하면 탄 수와 무관하게 상수 개다.
static var _grad_cache: Dictionary = {}
static var _curve_shared: Curve = null


static func _trail_gradient(c: Color) -> Gradient:
	var key: String = c.to_html(false)
	if _grad_cache.has(key):
		return _grad_cache[key]
	var g := Gradient.new()
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.set_color(1, Color(c.r, c.g, c.b, 0.55))
	_grad_cache[key] = g
	return g


static func _trail_curve() -> Curve:
	if _curve_shared == null:
		_curve_shared = Curve.new()
		_curve_shared.add_point(Vector2(0.0, 0.15))
		_curve_shared.add_point(Vector2(1.0, 1.0))
	return _curve_shared


## 탄 중심(코어) 색 — '무엇이 붙었나'(원소)를 먼저 말한다.
func _elem_color() -> Color:
	if _fx_fire > 0:
		return Color("ff7a3c")
	if _fx_ice > 0:
		return Color("7fd4ff")
	if _fx_poison > 0:
		return Color("8fe36b")
	if _fx_shock > 0:
		return Color("ffe23f")
	if _elem_tint.a > 0.0:
		return _elem_tint
	return Color("fff0b0")


## 탄 외곽(글로우·트레일) 색 — '누가 쐈나'(무기)를 말한다.
## ★ 예전엔 코어와 외곽이 같은 함수를 썼다. 그래서 탄막 화염 한 장만 먹으면 원거리 무기 7종의
##   탄체·글로우·트레일·착탄이 전부 같은 주황이 되어, 무기를 6정 들어도 화면은 한 무기로 보였다.
##   "중반부터 무기가 뭉개진다"는 체감이 여기서 나온다. 코어=원소 / 외곽=무기로 갈라 둘 다 읽히게 한다.
func _ident_color() -> Color:
	if _elem_tint.a > 0.0:
		return _elem_tint
	return _elem_color()  # 무기색이 없는 탄(소환수 얼음탄 등)은 원소색을 그대로 쓴다


func _ready() -> void:
	add_to_group("bullet")
	G.mine.call_deferred(self)   # 19차: 내 탄도 영웅 둘레에서 흐리게(그림은 아래에서 만들고 다 만든 뒤 표시)
	collision_layer = 0
	collision_mask = 2 | 8  # 적(layer 2) + 지형 장애물(layer 8) 감지 → 장애물에 막힘
	monitoring = true
	# ★ 탄과 몹이 둘 다 z_index 0 이고 부모도 같아서, 그리는 순서가 **노드가 붙은 순서**였다.
	#   몹은 계속 새로 스폰되므로 시간이 지날수록 내 탄이 몹 무더기 밑으로 깔린다 —
	#   "탄환이 잘 안 보인다"의 절반이 여기서 나온다. 층을 못박는다.
	#   몹 0 < 내 탄 3 < 적 탄 5 < 영웅 6
	z_index = 3
	var rscale: float = 1.0 + 0.4 * float(_fx_big)
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = RADIUS * rscale
	col.shape = cs
	add_child(col)
	rotation = _vel.angle()
	var vroot := Node2D.new()
	vroot.scale = Vector2(rscale, rscale)
	add_child(vroot)
	# ── 8차: 무기 이펙트 시트가 있으면 그 그림으로. 없으면 아래 예전 도형 ──
	var idc: Color = _ident_color()   # 트레일 색(무기) — 시트 탄도 같이 쓴다
	var fxk: String = _fx_key()
	if fxk != "":
		_build_fx_art(vroot, fxk)
	else:
		var ec: Color = _elem_color()
		var vis := Polygon2D.new()
		# 아키타입별 실루엣: 캐논=둥근 포탄(크게) / 속사=가느다란 트레이서 / 산탄=작은 펠릿 / 기본=화살촉
		match _arch:
			"heavy":
				vis.polygon = G.regular_polygon(10, 8.0)
				vis.color = ec.darkened(0.12)
				var hcore := Polygon2D.new()  # 포탄 심지 하이라이트
				hcore.polygon = G.regular_polygon(8, 4.0)
				hcore.color = Color(1, 0.95, 0.8, 0.9)
				hcore.position = Vector2(1.5, -1.5)
				hcore.z_index = 1  # 포탄 본체 위에
				vroot.add_child(hcore)
			"rapid":
				vis.polygon = PackedVector2Array([Vector2(11, 0), Vector2(-8, -1.6), Vector2(-8, 1.6)])
				vis.color = ec.lightened(0.2)
			"mid":
				vis.polygon = G.regular_polygon(6, 4.2)
				vis.color = ec
			"bow":  # 각궁 — 길고 가는 화살. 화면을 가로지르는 선으로 읽힌다
				vis.polygon = PackedVector2Array([Vector2(16, 0), Vector2(-10, -2.2), Vector2(-6, 0), Vector2(-10, 2.2)])
				vis.color = ec.lightened(0.12)
			"fan":  # 태극 부채 — 넓적한 반달 조각(여러 장이 부챗살처럼 퍼진다)
				vis.polygon = PackedVector2Array([Vector2(6, 0), Vector2(-2, -5.5), Vector2(-5, 0), Vector2(-2, 5.5)])
				vis.color = ec
			"sinkal":  # 신칼 — 짧고 날카로운 마름모. 연사가 빨라 작고 촘촘하게
				vis.polygon = PackedVector2Array([Vector2(7, 0), Vector2(0, -2.6), Vector2(-4, 0), Vector2(0, 2.6)])
				vis.color = ec.lightened(0.25)
			_:
				vis.polygon = PackedVector2Array([Vector2(9, 0), Vector2(-6, -4), Vector2(-6, 4)])
				vis.color = ec
		# ── 융합 무기의 탄 — 한눈에 "이건 초월한 무기다" ──
		if fusion_id != "":
			if fusion_id == "evo_railcannon":  # 레일건: 포탄이 아니라 길게 뻗는 창
				vis.polygon = PackedVector2Array([
					Vector2(30, 0), Vector2(6, -2.6), Vector2(-16, -1.4),
					Vector2(-16, 1.4), Vector2(6, 2.6)])
				vis.color = Color(0.85, 0.95, 1.0)
			elif fusion_id == "evo_deadeye":  # 필중의 눈: 가늘고 새하얀 침
				vis.polygon = PackedVector2Array([Vector2(15, 0), Vector2(-9, -1.2), Vector2(-9, 1.2)])
				vis.color = Color(1, 1, 1)
			vroot.scale *= 1.18
			var rim := Polygon2D.new()  # 금빛 테두리 — 융합 공통 표식
			rim.polygon = G.regular_polygon(12, 11.0)
			rim.color = Color(1.0, 0.84, 0.29, 0.30)
			rim.z_index = -2
			vroot.add_child(rim)
		# ★ 탄체 뒤에 같은 모양의 어두운 판을 한 겹 깐다. 글로우(알파 0.28)만으로는 밝은 타일
		#   위에서 그냥 사라졌다 — 몹에는 테두리를 줬는데 탄환만 안 준 상태였다.
		#   원반이 아니라 **같은 실루엣을 키운 것**이라, 가느다란 트레이서가 동그라미가 되지 않는다.
		var rim0 := Polygon2D.new()
		rim0.polygon = vis.polygon
		rim0.scale = Vector2(1.34, 1.34)
		rim0.color = Color(0.03, 0.02, 0.05, 0.85)
		rim0.z_index = -1
		vroot.add_child(rim0)
		vroot.add_child(vis)
		var glow := Polygon2D.new()
		glow.polygon = G.regular_polygon(10, RADIUS + (7.0 if _arch == "heavy" else 4.0))
		glow.color = Color(idc.r, idc.g, idc.b, 0.34 if _arch == "heavy" else 0.28)
		glow.z_index = -1
		vroot.add_child(glow)
	# 모션 트레일 (원소색, 꼬리로 갈수록 투명) — 다이나믹한 탄막.
	# ★ 예전엔 탄 하나마다 Gradient·Curve 리소스를 새로 만들었다. 초당 수백 발이면 그만큼의
	#   리소스 할당/해제가 돌고, Line2D 는 점이 바뀔 때마다 폴리곤을 다시 짠다.
	#   지금은 색별로 캐시한 Gradient 와 공용 Curve 를 쓰고, 절전 모드에서는 트레일을 아예 뺀다.
	if G.perf_level() > 0 and _arch != "sinkal":  # 신칼은 초당 25발이라 트레일이 화면을 덮는다
		_trail = Line2D.new()
		_trail.top_level = true  # 월드 좌표(탄과 함께 회전 안 함)
		_trail.width = (4.0 if fxk != "" else 7.0) * rscale
		_trail.z_index = -1
		_trail.gradient = _trail_gradient(idc)
		_trail.width_curve = _trail_curve()
		if fxk == "evo_railcannon" and FxLib.has(fxk, "trail"):
			# 레일건: 지나간 자리에 잔광 조각을 이어 붙인다(8차 trail). 색은 그림 그대로, 꼬리 쪽으로 옅게.
			_trail.texture = FxLib.tile(fxk, "trail", 0)
			_trail.texture_mode = Line2D.LINE_TEXTURE_TILE
			_trail.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			_trail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_trail.width = 12.0 * rscale
			_trail.gradient = _trail_gradient(Color.WHITE)
		add_child(_trail)
	if _fx_homing > 0:
		_retarget_t = randf() * 0.1  # 스캔 프레임 분산(동시 발사 스파이크 방지)
	body_entered.connect(_on_body_entered)


## 이 탄이 쓸 이펙트 시트의 무기 이름(8차). 지정 → 융합 → 무기 순. 없으면 "" — 예전 도형.
func _fx_key() -> String:
	for k: String in [fx_key, fusion_id, _arch]:
		if k != "" and FxLib.has(k, "bullet"):
			return k
	return ""


## 탄막 원소 카드가 붙은 탄은 뒤에 원소 꼬리(공통 시트)가 붙는다. 우선순위는 _elem_color 와 같다.
func _elem_sheet() -> String:
	if _fx_fire > 0:
		return "elem_fire"
	if _fx_ice > 0:
		return "elem_ice"
	if _fx_poison > 0:
		return "elem_poison"
	if _fx_shock > 0:
		return "elem_shock"
	return ""


func _build_fx_art(vroot: Node2D, key: String) -> void:
	var el: String = _elem_sheet()
	if el != "":
		var tail := FxLib.sprite("common", el, true)
		if tail != null:
			tail.z_index = -1   # 탄 뒤에 — 칸 가운데가 탄 중심, 꼬리는 왼쪽(뒤)
			vroot.add_child(tail)
	vroot.add_child(FxLib.sprite(key, "bullet", true))


## 맞은 자리 시트 [무기, 시트]. 캐논·필중의 눈·얼음탄은 전용, 치명타는 공통 crit, 나머지는 공통 hit.
func _hit_sheet() -> Array:
	var k: String = _fx_key()
	if k == "evo_legion":
		k = "summon_ice"   # 군단은 정령의 얼음탄이다 — 맞은 자리도 같다
	if k != "" and FxLib.has(k, "hit"):
		return [k, "hit"]
	if _crit and FxLib.has("common", "crit"):
		return ["common", "crit"]
	if FxLib.has("common", "hit"):
		return ["common", "hit"]
	return []


func _physics_process(delta: float) -> void:
	# 유도: 캐시된 타깃으로 매 프레임 조향, 재조준(전수 스캔)은 ~0.1s마다만 (매프레임 O(적) 스캔 제거)
	if _fx_homing > 0:
		_retarget_t -= delta
		if _retarget_t <= 0.0 or not is_instance_valid(_homing_tgt) or _hit.has(_homing_tgt):
			_homing_tgt = _nearest_other()
			_retarget_t = 0.1
		if _homing_tgt != null:
			var cur: float = _vel.angle()
			var want: float = (_homing_tgt.global_position - global_position).angle()
			var turn: float = (2.2 + 1.4 * float(_fx_homing)) * delta
			var na: float = cur + clampf(wrapf(want - cur, -PI, PI), -turn, turn)
			_vel = Vector2(cos(na), sin(na)) * _vel.length()
			rotation = _vel.angle()
	var step: Vector2 = _vel * delta
	global_position += step
	var slen: float = step.length()
	# 트레일: 매 프레임 대신 이동거리 20px마다 점 추가 (재테셀레이션 비용 절감)
	if _trail != null:
		_trail_accum += slen
		if _trail_accum >= 20.0:
			_trail_accum = 0.0
			_trail.add_point(global_position)
			if _trail.get_point_count() > 6:
				_trail.remove_point(0)
	_traveled += slen
	_life -= delta
	# 유도탄은 휘어 도느라 실제 이동거리가 길어지므로 1.2배까지만 봐준다 (예전 1.7배 = 전맵 사냥)
	var maxd: float = max_dist * (1.2 if _fx_homing > 0 else 1.0)
	if _life <= 0.0 or _traveled > maxd:
		# 신칼 '회수' — 사거리가 다한 칼이 소멸 대신 한 번 되돌아온다. 유도는 그대로 살아 있어서
		# 돌아오는 길에 다시 적을 문다. 던진 칼을 회수하는 동작이라 무기 정체성의 연장이다.
		if relaunch > 0:
			relaunch -= 1
			_traveled = 0.0
			_life = LIFETIME
			_hit.clear()
			_vel = -_vel
			rotation = _vel.angle()
			return
		_expire()


func _on_body_entered(body: Node) -> void:
	if body is Obstacle:  # 지형 장애물에 맞으면 소멸(관통/튕김 무시)
		_hit_spark()
		queue_free()
		return
	if not (body is Enemy) or _hit.has(body):
		return
	var en := body as Enemy
	_hit.append(en)
	G.tally("탄환직격", _dmg)
	en.take_damage(_dmg, _vel, _crit, _src_id())
	_apply_status(en)
	if G.player != null and is_instance_valid(G.player):
		(G.player as Player).hit_lifesteal()  # 흡혈(b_vamp) — 내부 쿨 게이트
	if _fx_chain > 0:  # 연쇄: 주변 적에게 번개 전이
		_chain_zap(en)
	G.sfx_throttled("hit", randf_range(0.94, 1.1), -7.0)
	_hit_spark()
	# 히트 감쇠: 관통/튕김으로 이어지는 다음 히트부터 피해 -28% (등급 대비 과잉 성능 억제, M37)
	_dmg *= pierce_decay
	# 튕김: 남은 튕김이 있으면 다른 적에게 방향 전환 (관통 소모 안 함)
	if _fx_bounce > 0:
		var nxt: Enemy = null
		# 유도 캐시가 살아있으면 재사용(중복 전수 스캔 방지), 아니면 1회 스캔
		if _fx_homing > 0 and is_instance_valid(_homing_tgt) and not _hit.has(_homing_tgt):
			nxt = _homing_tgt
		else:
			nxt = _nearest_other()
		if nxt != null:
			_vel = (nxt.global_position - global_position).normalized() * _vel.length()
			rotation = _vel.angle()
			_fx_bounce -= 1
			_dmg *= 0.85  # 튕김은 추가 감쇠 (합산 튕김당 약 -39%)
			_traveled = maxf(0.0, _traveled - max_dist * 0.25)  # 튕길 때마다 사거리를 조금만 돌려준다
			return
	if _pierce <= 0:
		_expire()
	else:
		_pierce -= 1


## 탄이 사라지는 유일한 자리. 만렙 '착탄 폭발'(캐논)·'파쇄'(얼음정령)이 여기서 터진다.
## queue_free 를 직접 부르던 곳을 전부 이쪽으로 모았다 — 안 그러면 소멸 경로가 둘이라
## 사거리 끝에서는 안 터지고 관통 소진 때만 터지는 반쪽이 된다.
func _expire() -> void:
	if burst_on_stop > 0.0 and _dmg > 0.0:
		_burst()
	queue_free()


func _burst() -> void:
	var r: float = 52.0 + 8.0 * float(_fx_big)
	var d: float = _dmg * burst_on_stop
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or _hit.has(e):
			continue
		if global_position.distance_to(e.global_position) > r + e.rad:
			continue
		G.tally("착탄폭발", d)
		e.take_damage(d, e.global_position - global_position, false, _src_id())
	if not G.fx_budget():
		return
	var bk: String = _fx_key()
	bk = "summon_ice" if bk in ["summon_ice", "evo_legion"] else "heavy"
	if FxLib.has(bk, "hit"):
		# 시트 반지름(캐논 폭발 약 22px · 서리 파편 약 14px)을 터지는 반경에 맞춘다
		FxLib.burst(get_parent(), global_position, bk, "hit", 0.0, r / (22.0 if bk == "heavy" else 14.0), 0.24, 3)
		return
	var ring := Polygon2D.new()
	ring.polygon = G.regular_polygon(16, r)
	ring.color = Color(1.0, 0.72, 0.32, 0.42)
	ring.z_index = 3
	ring.global_position = global_position
	var world: Node = get_parent()
	if world != null:
		world.add_child(ring)
		G.mine(ring)   # 19차: 영웅 둘레에서 흐리게
		var tw := ring.create_tween()
		tw.set_parallel(true)
		tw.tween_property(ring, "scale", Vector2(1.35, 1.35), 0.22)
		tw.tween_property(ring, "modulate:a", 0.0, 0.22)
		tw.chain().tween_callback(ring.queue_free)


func _apply_status(en: Enemy) -> void:
	if _fx_ice > 0:
		en.apply_slow(0.5 + 0.25 * float(_fx_ice))
	# ★ 화상은 0.4초마다 2.2초(5.5틱) 들어간다. 틱당 계수 0.10×Lv 이면 5레벨에서
	#   '한 방 맞힐 때마다 직격의 2.75배'가 도트로 더 들어갔다 — 실측 총피해의 38%.
	#   레어 한 장이 직격 전체를 앞지르면 등급 서열이 뒤집힌다. 계수를 절반으로 내린다.
	# 실측 2차: 절반으로 줄여도 화상이 총피해의 47%, 직격은 9% 였다. 대부분의 잔몹은
	# 한 발 맞고 도트로 죽기 때문에, 도트 총량이 '한 발의 1.4배'면 그 판의 주력은 화상이 된다.
	# 지속시간과 계수를 함께 줄여 '한 발의 0.6배' 선으로 맞춘다 — 붙이는 값은 여전히 크다.
	if _fx_fire > 0:
		en.apply_burn(maxf(0.8, _dmg * 0.035 * float(_fx_fire)), 1.4)
	if _fx_poison > 0:  # 중독은 더 길게 대신 틱당 약하게 (화상과 역할 분리)
		en.apply_poison(maxf(0.8, _dmg * 0.030 * float(_fx_poison)), 3.0)
	# ★ 감전 즉발은 명중마다 쿨 없이 들어가서, 5레벨이면 모든 탄환 피해가 그대로 2배였다
	#   (실측 총피해의 33%). 커먼 '공격력' 한 장이 +16% 인데 레어 한 장이 +100% 였다.
	if _fx_shock > 0:
		G.tally("감전즉발", _dmg * 0.09 * float(_fx_shock))
		# ★ 넉백 방향을 주면 감전 즉발이 히트마다 '추가 넉백'을 한 번 더 넣어 군집을 흩는다.
		#   그러면 관통·거대탄 다중히트와 오라/장판 체류가 같이 깎여서, 실측상 감전은 자기 빌드의
		#   광역 딜을 스스로 줄이는 카드였다(픽당 DPS 배수 0.87~1.01). 즉발은 넉백 없이 넣는다.
		en.take_damage(_dmg * 0.09 * float(_fx_shock), Vector2.ZERO, false, "b_shock")  # M39: 0.35→0.20 → M41: 0.09/Lv
		en.apply_shock(2.0)  # 감전 잔류 → 원소 반응 재료


func _nearest_other() -> Enemy:
	var best: Enemy = null
	var bd: float = 345.0 * 345.0  # 제곱거리 비교(sqrt 제거)
	for n in G.enemies_cached():  # 프레임당 1회 조회 공유(수백 탄이 각자 스캔하던 것 제거)
		if not is_instance_valid(n):
			continue  # 캐시에 이번 프레임 사망분이 남을 수 있다 — 캐스트 전에 거른다
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or _hit.has(e):
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < bd:
			bd = d
			best = e
	return best


## 연쇄 번개: 명중 지점 주변의 적 N마리에게 옮겨 가며 약해지는 피해 + 번개 아크
## ★ 11/14 이용자 보고(무한 쉬움 30분 · Lv142): 결과 표에서 연쇄가 총피해의 63% 로 융합 무기 넷을 다 합친 것보다 컸다.
##   예전 식은 옮겨 붙는 적마다 한 발의 (0.35 + 0.05×Lv) 를 그대로 줘서, 몹이 빽빽한 무한 후반엔
##   명중 한 번마다 한 발의 Lv×(0.35+0.05×Lv) = 5단계 3.0배 · 구미호의 꼬리 6단계 3.9배가 더 들어갔다.
##   관통 · 튕김 명중마다 또 터지니 레일건 같은 융합 무기의 피해가 「연쇄」 줄로 넘어가 보였다.
##   첫 번째로 옮겨 가는 피해를 한 발의 (0.25 + 0.03×Lv) 로 낮추고 한 번 옮길 때마다 0.55배씩 약해지게 한다.
##   명중 한 번에 더 들어가는 몫이 1단계 0.28 · 3단계 0.63 · 5단계 0.84 · 6단계 0.93배가 된다(예전 0.40 · 1.5 · 3.0 · 3.9).
##   감전 5단계 0.45배보다는 여전히 세다 — 대신 몰려 있을 때만 들어가고 보스 혼자면 0 이다.
##   --dmgshare 로 앞뒤를 잰다(--oldchain = 예전 식).
const CHAIN_FALLOFF: float = 0.55

func _chain_zap(from: Enemy) -> void:
	var origin: Vector2 = from.global_position
	var cand: Array = []
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue
		var e := n as Enemy
		if e == null or _hit.has(e) or e == from:
			continue
		var d: float = origin.distance_squared_to(e.global_position)  # 제곱거리(정렬 순서 동일)
		if d < 240.0 * 240.0:
			cand.append({"e": e, "d": d})
	cand.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	var cnt: int = mini(_fx_chain, cand.size())
	var prev: Vector2 = origin
	var amt: float = _dmg * ((0.35 + 0.05 * float(_fx_chain)) if G.harness_oldchain else (0.25 + 0.03 * float(_fx_chain)))
	for i in cnt:
		var e: Enemy = cand[i]["e"]
		_hit.append(e)  # 중복 타격/관통 재소모 방지
		e.take_damage(amt, (e.global_position - origin).normalized(), false, "b_chain")
		if not G.harness_oldchain:
			amt *= CHAIN_FALLOFF
		_chain_arc(prev, e.global_position)
		prev = e.global_position


func _chain_arc(a: Vector2, b: Vector2) -> void:
	if not G.fx_budget():
		return  # 아크 비주얼만 예산 게이트 (연쇄 데미지는 이미 적용됨)
	if FxLib.tile_line(get_parent(), a, b, "wpn_chain", "bolt", -1.0, 0.2, 4) != null:
		FxLib.burst(get_parent(), b, "wpn_chain", "zap", 0.0, 0.8, -1.0, 21)
		return
	var pts := PackedVector2Array()
	var seg: int = 6
	var perp: Vector2 = (b - a).orthogonal().normalized()
	for i in seg + 1:
		var t: float = float(i) / float(seg)
		var base: Vector2 = a.lerp(b, t)
		var jit: float = 0.0 if (i == 0 or i == seg) else randf_range(-16.0, 16.0)
		pts.append(base + perp * jit)
	var line := Line2D.new()
	line.width = 3.5
	line.default_color = Color("cdeeff")
	line.points = pts
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var glow := Line2D.new()
	glow.width = 9.0
	glow.default_color = Color(0.55, 0.82, 1.0, 0.3)
	glow.points = pts
	glow.z_index = -1
	line.add_child(glow)
	get_parent().add_child(line)
	G.mine(line)   # 19차: 영웅 둘레에서 흐리게
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.2)
	tw.tween_callback(line.queue_free)


func _hit_spark() -> void:
	if not G.fx_budget():
		return  # 프레임당 스파크 상한 — 관통/튕김/연쇄 다중히트 폭주 차단
	var hs: Array = _hit_sheet()
	if not hs.is_empty():
		FxLib.burst(get_parent(), global_position, String(hs[0]), String(hs[1]), 0.0, 1.0, -1.0, 21, randf() < 0.5)
		return
	var ec: Color = _elem_color()
	# 4갈래 스파크
	var s := Polygon2D.new()
	s.polygon = G.regular_polygon(4, 10.0)
	s.color = ec.lightened(0.3)
	s.global_position = global_position
	get_parent().add_child(s)
	G.mine(s)   # 19차: 영웅 둘레에서 흐리게
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(2.0, 2.0), 0.12)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.12)
	tw.tween_callback(s.queue_free)
	# 확산 링 (임팩트)
	var ring := Line2D.new()
	ring.width = 2.6
	ring.default_color = Color(ec.r, ec.g, ec.b, 0.85)
	var pts := G.regular_polygon(16, 7.0)
	for pt: Vector2 in pts:
		ring.add_point(pt)
	ring.add_point(pts[0])
	ring.global_position = global_position
	get_parent().add_child(ring)
	G.mine(ring)   # 19차: 영웅 둘레에서 흐리게
	var tw2 := ring.create_tween()
	tw2.tween_property(ring, "scale", Vector2(2.6, 2.6), 0.2)
	tw2.parallel().tween_property(ring, "modulate:a", 0.0, 0.2)
	tw2.tween_callback(ring.queue_free)
