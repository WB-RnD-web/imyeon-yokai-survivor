class_name CreatureVisual
extends Node2D
## 캐릭터/몬스터 비주얼. sprite_path 지정 시 실제 픽셀 스프라이트, 없으면 절차적 도형(폴백).
## 공통: 바운스(숨쉬기) + flash(피격). 도형 모드는 눈/눈썹/뿔 등 추가.

var body_color: Color = Color("52e0cf")
var outline_color: Color = Color(0.06, 0.06, 0.10)
var radius: float = 16.0
var sides: int = 18
var angry: bool = false
var eye_scale: float = 1.0
var feature: String = ""  # "" / horns / spikes / crown — 도형 모드 실루엣 구분
var sprite_path: String = ""  # res:// 경로 지정 시 스프라이트 모드
var sprite_hframes: int = 1  # 가로 스트립이면 프레임 수(순환 애니메이션)
# 프로시저럴 애니메이션 스타일: "" 숨쉬기(기본) / hop 슬라임 / flap 날갯짓 / march 행진
# / float 부유(큰 날개) / scurry 종종걸음 / sway 슬리더. 스타일별 부속지(날개/팔/꼬리/방울)가 붙어 움직인다.
var anim_style: String = ""
## 캐릭터 에셋(charforge) ID. 주면 sprite_path 대신 동작별 시트를 쓴다(CharForge 참조).
var cf_id: String = ""

var look_dir: Vector2 = Vector2.DOWN
var _inner: Node2D
var _sprite: Sprite2D
var _body: Polygon2D
var _eye_l: Node2D
var _eye_r: Node2D
var _pupil_l: Polygon2D
var _pupil_r: Polygon2D
var _eye_r_val: float = 4.0
var _t: float = 0.0
var _walk_phase: float = 0.0   # 걸음 위상 — 시간이 아니라 **이동 거리**로 는다
var _last_delta: float = 0.016
var walk_speed: float = 0.0    # 소유자가 매 프레임 넣어 주는 현재 속도(px/s)
const WALK_FPS_MIN: float = 3.0   # 이보다 느리면 걷는 게 아니라 멎어 보인다
const WALK_FPS_MAX: float = 10.0  # 이보다 빠르면 파닥거린다

## 그리는 크기 = radius × 이 값. 충돌 반경(rad)은 밸런스가 걸려 있어 못 건드리므로,
## "몹이 너무 작다"(실플레이 리포트, 2026-09-15)는 여기서만 키운다.
## ★ 2.15 → 2.40 (+12%). 1920 화면에서 흔한 잡몹이 45px → 50px 가 된다.
##   숫자가 두 군데(걸음 속도 식 · 스프라이트 배율)에 흩어져 있었다 — 하나만 고치면
##   걷기가 어긋나 --walkcheck 가 통과해도 화면은 딴판이 된다. 상수 하나로 모은다.
const DRAW_SCALE: float = 2.40


## 걷기 스트립이 초당 몇 칸 도는가. --walkcheck 가 이 함수를 그대로 부른다 —
## 검사와 그리기가 다른 식을 쓰면 검사가 통과해도 화면은 딴판이 된다.
static func walk_fps(sp: float, rad: float) -> float:
	var step_px: float = maxf(6.0, rad * DRAW_SCALE * 0.45)
	return clampf(sp / step_px * 2.0, WALK_FPS_MIN, WALK_FPS_MAX)
var _blink: float = 0.0
var _next_blink: float = 2.0
var _limb_root: Node2D          # 부속지 컨테이너(몸 뒤에 그림) — 좌우 플립도 여기서
var _limbs: Array = []          # 개별 부속지 노드 (스타일별 갱신)
var _face: float = 1.0          # 바라보는 방향(+1 우 / -1 좌)
const FLASH_LIFT: float = 2.2   # 흰 피격 번쩍임의 밝기(스프라이트) — 곱해서 그리므로 1 을 넘겨야 하얘진다
var _flash_t: float = 0.0       # 피격 플래시 잔여시간 (트윈 없이 직접 감쇠)
var _flash_dur: float = 0.16
var _flash_col: Color = Color.WHITE
var always_animate: bool = false  # 플레이어/보스처럼 항상 보이는 개체는 컬링 제외

# ── 캐릭터 에셋 모드 (cf_id) ──
var _cf_on: bool = false        # 시트 모드로 떴는가(실패하면 예전 그림으로 내려간다)
var _cf_k: int = 1              # 정수 배율
var _cf_cur: String = ""        # 지금 시트
var _cf_once: String = ""       # 한 번 재생 중인 동작("" = 기본 걷기/정지)
var _cf_hold: bool = false      # 끝 칸에서 멈춘다(쓰러짐)
var _cf_t: float = 0.0          # 지금 칸에서 흐른 시간
var _cf_hit_gap: float = 0.0    # 피격 자세를 너무 자주 갈아 끼우지 않게
var _cf_lift: float = 1.0
const CF_HIT_GAP: float = 0.35  # 피격 자세 사이 최소 간격 — 탄을 계속 맞으면 내내 굳어 보인다
## 자리 정보(소유자가 build() 전에 넣는다 — CharForge 배역표의 한 줄).
var cf_target_h: float = 0.0    # 자리 키(px). 0 이면 radius 로 짐작한다(예전 방식)
var cf_key: int = 0             # 처음 쓸 px 폴더(졸개·갈라진 판 = mini, 강화 개체 = elite). 없으면 기본 판
var cf_steps: Array = []        # 크기 단계 키들(하글·카리아). cf_step_for 가 고른다
var cf_palette: Array = []      # 팔레트 변종 색 목록(번호 1부터). 비우면 원래 색
var _cf_key_cur: int = 0        # 지금 쓰는 px 폴더(0 = 기본 판)
var _cf_state: String = ""      # 체력 단계 접두어("" / "s1") — s1_anchor·s1_walk 가 있으면 그걸 쓴다
var _cf_pose: bool = false      # 자세 고정(돌진 예고·돌진·사라짐) — 칸을 넘기지 않는다
var _cf_pal_tex: Texture2D = null


func build() -> void:
	_t = randf() * 6.0
	_next_blink = randf_range(1.5, 4.0)
	_inner = Node2D.new()
	add_child(_inner)
	if cf_id != "" and _try_cf():
		return
	if sprite_path != "" and _try_sprite():
		# ★ 예전엔 스프라이트 모드에서도 부속지를 만들었다. 그 부속지는 '도형 폴백' 시절의
		#   유물이라 삼각형 날개 두 장 · 막대 팔 두 개 · 원 꼬리다. 진짜 픽셀아트에는
		#   이미 날개도 팔도 그려져 있어서, 뒤에서 삼각형이 삐져나오면 그냥 조잡해 보인다
		#   (실플레이 리포트: "몬스터의 날개나 배리어 같은 게 많이 짜친다").
		#   몸 전체의 움직임(홉·부유·행진 록킹)은 _update_anim 이 그대로 해 준다.
		return
	_build_polygon()
	_build_limbs()


## 스타일별 부속지 — 몸색 계열의 폴리곤이 몸 뒤에서 움직인다(날개/팔/꼬리/점액방울).
func _build_limbs() -> void:
	if anim_style == "":
		return
	_limb_root = Node2D.new()
	_limb_root.z_index = -1  # 몸(스프라이트) 뒤
	_inner.add_child(_limb_root)
	var lc: Color = body_color.darkened(0.12)
	match anim_style:
		"flap", "float":  # 날개 한 쌍 (float=크고 느림) — 반투명·몸보다 작게, 스프라이트 뒤에서만 비침
			var big: bool = anim_style == "float"
			var wl: float = radius * (1.0 if big else 0.8)
			for side: float in [-1.0, 1.0]:
				var w := Polygon2D.new()
				w.polygon = PackedVector2Array([
					Vector2(0, 0),
					Vector2(side * wl, -radius * 0.55),
					Vector2(side * wl * 0.86, radius * 0.08),
				])
				w.color = Color(lc.r, lc.g, lc.b, 0.85)
				w.position = Vector2(side * radius * 0.40, -radius * 0.05)
				_limb_root.add_child(w)
				_limbs.append(w)
		"hop":  # 점액 방울 2개 (착지 때 옆으로 퍼짐)
			for side: float in [-1.0, 1.0]:
				var b := Polygon2D.new()
				b.polygon = G.regular_polygon(10, radius * 0.22)
				b.color = lc
				b.position = Vector2(side * radius * 0.72, radius * 0.55)
				_limb_root.add_child(b)
				_limbs.append(b)
		"march", "scurry":  # 팔(뼈다귀/막대) 한 쌍 — 걸을 때 앞뒤로 흔들
			for side: float in [-1.0, 1.0]:
				var a := Polygon2D.new()
				var aw: float = radius * 0.16
				a.polygon = PackedVector2Array([
					Vector2(-aw, 0), Vector2(aw, 0),
					Vector2(aw, radius * 0.62), Vector2(-aw, radius * 0.62),
				])
				a.color = lc
				a.position = Vector2(side * radius * 0.78, -radius * 0.05)
				_limb_root.add_child(a)
				_limbs.append(a)
		"sway":  # 꼬리 마디 2개 (지그재그 슬리더)
			for i in 2:
				var s := Polygon2D.new()
				s.polygon = G.regular_polygon(10, radius * (0.30 - 0.08 * float(i)))
				s.color = lc
				s.position = Vector2(-radius * (0.85 + 0.5 * float(i)), radius * 0.15)
				_limb_root.add_child(s)
				_limbs.append(s)


## 스프라이트는 몬스터 한 마리마다 ResourceLoader.exists + load 를 돌렸다.
## 웨이브 스폰이 한 번에 수십 마리라 그때마다 파일시스템/UID 조회가 프레임을 잡아먹었다.
## 종류 수는 수십 개뿐이니 경로별로 한 번만 찾아 캐시한다.
static var _tex_cache: Dictionary = {}

static func _tex_for(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_tex_cache[path] = t
	return t


## 너무 어두운 스프라이트를 끌어올린다. **테두리로는 못 고치는 문제**라 따로 둔다.
##
## 몹 스프라이트 58종의 평균 밝기가 10 ~ 200 으로 20배 벌어져 있었다.
## 야차는 평균 10, 상위 10% 픽셀조차 16 이다 — 사실상 검정이라 어떤 바닥 위에서도 안 보인다.
## 림라이트가 실루엣은 살리지만 **몸통은 여전히 어두운 얼룩**으로 읽힌다(실플레이 리포트:
## "갈색 몬스터는 어떤 맵이든 잘 안 보인다").
##
## 감마로 들어올린다 — 곱하기와 달리 0 과 255 를 그대로 두고 중간만 밀어서, 명암 관계와
## 도트의 결이 유지된다. 밝은 스프라이트(평균 ≥ 목표)는 손대지 않는다.
## 상한 0.55 를 두는 이유: 평균 10짜리를 목표까지 끌면 형체가 회색 죽이 된다.
## 그 한 종은 '제일 어두운 놈'으로 남되, 10 → 43 이면 형태는 읽힌다.
##
## ★ 처음엔 텍스처 픽셀을 GDScript 로 돌며 직접 고쳤다. 몹 한 종이 **처음 나오는 프레임**마다
##   9만 번 루프가 돌아 판이 멎었다(--perf 최저 60 → 11). 지금은 CPU 에서 평균만 재고
##   (그것도 16픽셀에 한 번), 감마는 테두리 셰이더가 GPU 에서 같이 건다 — 비용이 0 이다.
##
##   재보기: python tools/contrast_qa.py   (먼저 -- --contrastshot 으로 그림을 찍는다)
const LIFT_TARGET: float = 82.0   # 이 평균 밝기까지 끌어올린다
const LIFT_GAMMA_MIN: float = 0.55
static var _lift_cache: Dictionary = {}

static func _lift_gamma(path: String) -> float:
	if _lift_cache.has(path):
		return _lift_cache[path]
	var g: float = 1.0
	var tex: Texture2D = _tex_for(path)
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
			var buf: PackedByteArray = img.get_data()
			var cnt: int = buf.size()
			var sum_l: float = 0.0
			var n: int = 0
			# 16픽셀에 한 번만 본다 — 평균을 내는 데 전수는 필요 없다(실측 오차 1 미만).
			var i: int = 0
			while i < cnt:
				if buf[i + 3] >= 200:
					sum_l += 0.2126 * float(buf[i]) + 0.7152 * float(buf[i + 1]) + 0.0722 * float(buf[i + 2])
					n += 1
				i += 64
			if n > 0:
				var mean: float = sum_l / float(n)
				if mean > 0.5 and mean < LIFT_TARGET:
					g = maxf(LIFT_GAMMA_MIN, log(LIFT_TARGET / 255.0) / log(mean / 255.0))
	_lift_cache[path] = g
	return g


## 스프라이트 테두리 재질. 도형 폴백에는 반경+3 짜리 어두운 테두리가 있었는데
## 스프라이트 모드는 그 코드를 타지 않아 **테두리가 아예 없었다** — 바닥 타일이 그림이라
## 몹이 배경에 녹아 보이는 원인이 여기다.
##
## 두께는 화면 픽셀로 맞춘다. 스프라이트마다 축소율(sc)이 달라서, 텍셀 단위로 고정하면
## 작은 몹은 테두리가 안 보이고 큰 몹은 두꺼워진다. 재질은 (프레임수, 두께)로 캐시해
## 개체 수백이어도 실제 재질은 열몇 개만 만들어진다.
## ★ 셰이더의 COLOR 오해를 고치고 나서야 테두리가 실제로 그려지기 시작했다 —
##   그전엔 2.2 로 올려도 화면에 아무것도 없었다(알파가 항상 0이었다).
##   제대로 나오니 2.2 는 후광처럼 두껍다. 1.5 로 내리고 상한도 4 → 3 텍셀.
const OUTLINE_SCREEN_PX: float = 1.5
static var _ol_shader: Shader = null
static var _ol_mats: Dictionary = {}

## ★ 테두리 색이 **고정 검정**이었다. 밝은 바닥에서는 잘 듣지만 어두운 바닥(용암동굴·던전)
##   에서는 어두운 몹 둘레에 어두운 선을 그리는 셈이라 아무 일도 하지 않는다 —
##   "색상 때문에 보호색처럼 안 보이는 적이 많다, 맵별로 상이하다"(실플레이 리포트)의 절반이 이것이다.
##   지금 맵 바닥의 밝기를 받아서 **반대쪽으로** 잡는다. 어두운 맵이면 밝은 테두리,
##   밝은 맵이면 어두운 테두리 — 어느 맵에 서든 둘레에 반드시 단차가 생긴다.
##   재질은 몇 개뿐이라 테마가 바뀔 때 전부 갱신해도 비용이 없다.
static var _world_luma: float = 0.35

static func set_world_luma(l: float) -> void:
	if absf(l - _world_luma) < 0.02:
		return
	_world_luma = l
	var c: Color = outline_for(l)
	for k in _ol_mats:
		(_ol_mats[k] as ShaderMaterial).set_shader_parameter("line_color", c)


## 바닥 밝기 → 테두리 색. 중간 밝기에서는 어느 쪽도 애매하므로 그 구간만 부드럽게 넘긴다.
static func outline_for(l: float) -> Color:
	var t: float = clampf((l - 0.20) / 0.22, 0.0, 1.0)   # 0.20 이하 = 완전히 밝은 테두리
	var dark := Color(0.03, 0.02, 0.05, 1.0)
	var light := Color(0.80, 0.86, 0.95, 1.0)   # 순백은 후광처럼 튄다 — 살짝 눌러 둔다
	return light.lerp(dark, t)

## pal = 팔레트 바꾸기용 '번호 → 색' 텍스처(CharForge.palette_texture). 주면 텍스처를 번호 그림으로 읽는다.
static func _outline_mat(hf: int, sc: float, lift: float, pal: Texture2D = null) -> ShaderMaterial:
	if _ol_shader == null:
		if not ResourceLoader.exists("res://assets/shaders/outline.gdshader"):
			return null
		_ol_shader = load("res://assets/shaders/outline.gdshader")
	var px: float = clampf(OUTLINE_SCREEN_PX / maxf(0.15, sc), 1.0, 3.0)
	var q: float = snappedf(px, 0.25)
	var diag: bool = G.perf_level() > 0  # 절전이면 대각선을 뺀다 (픽셀당 샘플 9 → 5)
	# 림라이트도 이웃을 넷 더 읽는다. 약한 기기(절전)에서는 뺀다 — 어두운 바깥선과
	# 밝기 끌어올리기(lift)만으로도 실루엣은 남는다.
	var rim: float = [0.0, 0.6, 0.85][G.perf_level()]
	var lq: float = snappedf(clampf(lift, 0.3, 1.0), 0.05)
	var key: String = "%d|%.2f|%s|%.2f|%.2f|%d" % [hf, q, str(diag), lq, rim, pal.get_instance_id() if pal != null else 0]
	if _ol_mats.has(key):
		return _ol_mats[key]
	var m := ShaderMaterial.new()
	m.shader = _ol_shader
	m.set_shader_parameter("hframes", hf)
	m.set_shader_parameter("line_px", q)
	m.set_shader_parameter("diagonal", diag)
	m.set_shader_parameter("lift", lq)
	m.set_shader_parameter("rim_mix", rim)
	m.set_shader_parameter("line_color", outline_for(_world_luma))
	if pal != null:
		m.set_shader_parameter("use_pal", true)
		m.set_shader_parameter("pal_tex", pal)
		m.set_shader_parameter("pal_w", float(pal.get_width()))
	_ol_mats[key] = m
	return m


## 금빛 테두리 재질 — 융합 무기 표식용. 몹 테두리와 같은 셰이더를 쓰되 색만 금색이다.
## 한 벌만 만들어 돌려 쓴다(무기는 화면에 하나뿐이라 캐시 키를 나눌 필요가 없다).
static var _gold_mat: ShaderMaterial = null

static func gold_outline_mat() -> ShaderMaterial:
	if _gold_mat != null:
		return _gold_mat
	if _ol_shader == null:
		if not ResourceLoader.exists("res://assets/shaders/outline.gdshader"):
			return null
		_ol_shader = load("res://assets/shaders/outline.gdshader")
	_gold_mat = ShaderMaterial.new()
	_gold_mat.shader = _ol_shader
	_gold_mat.set_shader_parameter("hframes", 1)
	_gold_mat.set_shader_parameter("line_px", 1.5)
	_gold_mat.set_shader_parameter("diagonal", true)
	_gold_mat.set_shader_parameter("lift", 1.0)
	_gold_mat.set_shader_parameter("rim_mix", 0.0)   # 무기는 안쪽 림라이트 없이 테두리만
	_gold_mat.set_shader_parameter("line_color", Color(1.0, 0.82, 0.28, 1.0))
	return _gold_mat


func _try_sprite() -> bool:
	var tex: Texture2D = _tex_for(sprite_path)
	if tex == null:
		return false
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 픽셀 크리스프
	_sprite.hframes = maxi(1, sprite_hframes)
	_sprite.frame = 0
	var fw: float = float(tex.get_width()) / float(maxi(1, sprite_hframes))
	var fh: float = float(tex.get_height())
	var sc: float = (radius * DRAW_SCALE) / maxf(fw, fh)
	# ★ NEAREST 는 '확대'할 때만 안전하다. 줄일 때 배율이 정수분의 1이 아니면 픽셀 줄이
	#   통째로 솎여서 팔·다리·외곽선이 사라진 것처럼 보인다 — 실플레이 리포트의
	#   "흐릿하거나 일정부분이 비어보이는 현상"이 정확히 이것이다(48px 원화를 30px 로 그림).
	#   정수분의 1에 가까우면 거기에 맞추고, 아니면 LINEAR 로 부드럽게 줄인다.
	#   (부드러워지는 건 감수한다. 팔이 사라지는 것보다 훨씬 낫다.)
	if sc < 0.98:
		var inv: float = 1.0 / sc
		var step: float = round(inv)
		if step >= 1.0 and absf(inv - step) < 0.12:
			sc = 1.0 / step
		else:
			_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.scale = Vector2(sc, sc)
	_sprite.material = _outline_mat(maxi(1, sprite_hframes), sc, _lift_gamma(sprite_path))
	# ★ 예전엔 스프라이트 뒤에 반경 1.22 짜리 어두운 원반 + 1.06 짜리 창백한 원반을 깔았다.
	#   사람 형태는 원의 25% 만 덮기 때문에 나머지 창백한 부분이 그대로 드러나서,
	#   "캐릭터가 뚫려서 뒤가 보인다"로 읽혔다(실플레이 리포트 + 확대 검증).
	#   이제 발밑에 납작한 그림자 하나만 둔다 — 대비도 살고 원반도 안 보인다.
	_inner.add_child(_make_shadow())   # 납작한 타원 = 바닥에 드리운 그림자
	_inner.add_child(_sprite)
	return true


## 11/14 「무한 후반 렉」: 발밑 그림자를 바닥 바로 위 한 층(z -10)으로 내린다.
##   예전엔 몹마다 「그림자(색 다각형) → 몸(테두리 재질 그림)」이 번갈아 그려져서 묶음 그리기가 몹마다 두 번 끊겼다
##   (몹 296 · 드로우 콜 1,100 중 몹 몫 650). 그림자를 한 층에 모으면 그림자끼리 · 같은 몹 몸끼리 묶인다.
##   그림자가 다른 몹 몸 위에 겹쳐 그려지던 것도 같이 없어진다(바닥에 붙은 게 맞다). 바닥(-100) · 바닥 장식(-50) 위.
##   z 는 부모 기준이라 몹(0)은 -10, 영웅(6)은 -4 — 둘 다 바닥 장식 위 · 몸 아래다.
##   ★ 층만 모아서는 드로우 콜이 거의 안 준다 — Godot 2D 는 Polygon2D 를 하나씩 따로 그린다.
##   그래서 그림자를 공용 원판 그림 한 장(Sprite2D)으로 바꾼다. 같은 그림 · 재질 없음이라 한 층의 그림자가 한 번에 그려진다.
##   모양 · 크기 · 색은 예전 16각형(반지름 r×0.72, 가로 1.15 · 세로 0.42, 검정 40%)과 같다. 가장자리만 살짝 부드럽다.
const SHADOW_Z: int = -10
const _SHADOW_PX: int = 64
static var _shadow_tex: Texture2D = null

func _make_shadow() -> Node2D:
	if G.lag_off.has("old_shadow"):
		var poly := Polygon2D.new()
		poly.polygon = G.regular_polygon(16, radius * 0.72)
		poly.color = Color(0.02, 0.02, 0.04, 0.40)
		poly.scale = Vector2(1.15, 0.42)
		poly.position = Vector2(0, radius * 0.86)
		return poly
	if _shadow_tex == null:
		var img := Image.create(_SHADOW_PX, _SHADOW_PX, false, Image.FORMAT_RGBA8)
		var c: float = float(_SHADOW_PX) * 0.5
		for y in _SHADOW_PX:
			for x in _SHADOW_PX:
				var d: float = Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c).length()
				img.set_pixel(x, y, Color(1, 1, 1, clampf(c - d, 0.0, 1.0)))   # 가장자리 한 픽셀만 섞인 단단한 원판
		_shadow_tex = ImageTexture.create_from_image(img)
	var s := Sprite2D.new()
	s.texture = _shadow_tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var d0: float = radius * 0.72 * 2.0 / float(_SHADOW_PX)
	s.scale = Vector2(1.15 * d0, 0.42 * d0)
	s.position = Vector2(0, radius * 0.86)
	s.modulate = Color(0.02, 0.02, 0.04, 0.40)
	s.z_index = SHADOW_Z
	s.visible = not G.lag_off.has("hide_shadow")   # --lagprof 원인 재기 전용
	return s


## ── 캐릭터 에셋 모드 ──
## 시트는 칸 크기가 동작마다 다르다(스킬은 이펙트만큼 크다). 그래서 칸의 가운데가 아니라
## **발밑**(가로 가운데 · 아래에서 2px 위)을 노드의 한 점에 고정한다. 그러면 동작을 바꿔도 발이 안 튄다.
## 그 점은 그림자 자리(radius × 0.86 아래)다 — 몸이 충돌 원 위에 서 있게.
## 확대는 정수배 · 최근접만. 숨쉬기 스쿼시나 회전은 걸지 않는다(배율이 소수가 되면 도트가 끓는다).
func _try_cf() -> bool:
	var key: int = cf_key
	if key > 0 and not CharForge.has_anim(cf_id, "anchor", key):
		key = 0                     # 그 크기 판이 아직 없으면 기본 판으로(작게 줄이지는 않는다)
	if not CharForge.has(cf_id) or not CharForge.has_anim(cf_id, "anchor", key):
		return false
	_cf_key_cur = key
	_cf_k = _cf_scale_for(key)
	var a0: Dictionary = CharForge.anim(cf_id, "anchor")
	_cf_lift = _lift_gamma((a0["tex"] as Texture2D).resource_path)
	if not cf_palette.is_empty() and not CharForge.palette(cf_id).is_empty():
		_cf_pal_tex = CharForge.palette_texture(cf_palette)
	_inner.add_child(_make_shadow())
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(_cf_k, _cf_k)
	_sprite.position = Vector2(0, roundf(radius * 0.86))
	_inner.add_child(_sprite)
	_cf_on = true
	_cf_set("anchor")
	return true


## 그 판(px 키)을 자리 키에 맞출 정수 배율. px 판은 자기 키로 뽑혀 왔으니 1.
func _cf_scale_for(key: int) -> int:
	if key > 0:
		return 1
	var target: float = cf_target_h if cf_target_h > 0.0 else radius * DRAW_SCALE
	return CharForge.scale_to(cf_id, 0, target)


## 지금 판에서 그 동작(없으면 {}).
func _an(a: String) -> Dictionary:
	return CharForge.anim(cf_id, a, _cf_key_cur)


## 체력 단계가 있으면 그 단계의 시트 이름(s1_anchor 등), 없으면 그대로.
func _cf_name(a: String) -> String:
	if _cf_state != "" and not _an(_cf_state + "_" + a).is_empty():
		return _cf_state + "_" + a
	return a


func cf_has(a: String) -> bool:
	return _cf_on and not _an(a).is_empty()


## 지금 판의 그 동작(이펙트 띄우기 등). 없으면 {}.
func cf_anim(a: String) -> Dictionary:
	return _an(a) if _cf_on else {}


func _cf_set(a: String) -> void:
	var an: Dictionary = _an(a)
	if an.is_empty():
		return
	_cf_cur = a
	_cf_t = 0.0
	var tex: Texture2D = an["tex"]
	if _cf_pal_tex != null:
		var it: Texture2D = CharForge.index_tex(cf_id, a, _cf_key_cur)
		if it != null:
			tex = it
	_sprite.texture = tex
	_sprite.hframes = int(an["n"])
	_sprite.frame = 0
	# 발밑 = 칸 가로 가운데 · 아래에서 2px 위. centered=false 라 왼쪽 위 모서리를 옮긴다.
	_sprite.offset = Vector2(-floorf(float(an["fw"]) * 0.5), -(float(an["fh"]) - 2.0))
	_sprite.material = _outline_mat(int(an["n"]), float(_cf_k), _cf_lift, _cf_pal_tex if tex != an["tex"] else null)


## 동작을 한 번 재생한다. 시트가 없으면 false (그 등급엔 없는 동작 — 하던 걸 계속한다).
## hold = 끝 칸에서 멈춘다(쓰러짐).
func play_once(a: String, hold: bool = false) -> bool:
	if not _cf_on or _an(a).is_empty():
		return false
	if _cf_hold:
		return false            # 쓰러진 뒤에는 아무것도 안 바꾼다
	_cf_pose = false
	_cf_once = a
	_cf_hold = hold
	_cf_set(a)
	return true


## 한 칸에 멈춰 세운다 — 돌진 예고(charge 0) · 돌진(charge 1) · 사라짐(vanish 0) · 다시 나타남(vanish 1).
## 같은 자세를 매 프레임 불러도 처음부터 다시 그리지 않는다. 시트가 없으면 false.
func pose(a: String, f: int) -> bool:
	if not _cf_on or _cf_hold:
		return false
	var name: String = _cf_name(a)
	var an: Dictionary = _an(name)
	if an.is_empty():
		return false
	if not (_cf_pose and _cf_cur == name):
		_cf_set(name)
	_cf_pose = true
	_cf_once = name
	_sprite.frame = clampi(f, 0, int(an["n"]) - 1)
	return true


## 자세를 푼다. a 를 주면 그 자세일 때만 푼다(다른 자세를 잘못 풀지 않게).
func release_pose(a: String = "") -> void:
	if not _cf_pose:
		return
	if a != "" and _cf_cur != a and _cf_cur != _cf_name(a):
		return
	_cf_pose = false
	_cf_once = ""
	_cf_cur = ""


func is_posing(a: String = "") -> bool:
	return _cf_pose and (a == "" or _cf_cur == a or _cf_cur == _cf_name(a))


## 그 동작의 첫 칸 길이(초) — 준비 칸이 지나 가운데 칸에 탄이 나가게, 이만큼 먼저 시작한다. 없으면 -1.
func lead_time(a: String) -> float:
	var an: Dictionary = _an(a) if _cf_on else {}
	if an.is_empty() or (an["ms"] as Array).is_empty():
		return -1.0
	return float((an["ms"] as Array)[0]) / 1000.0


## 체력 단계를 바꾼다("" = 기본, "s1" = 분노 등). 그 단계 시트가 없으면 기본 시트를 그대로 쓴다.
func cf_set_state(s: String) -> void:
	if s == _cf_state:
		return
	_cf_state = s
	if _cf_once == "":
		_cf_cur = ""            # 다음 프레임에 단계 시트로 갈아 끼운다


## 판(px 폴더)을 바꾼다 — 크기 단계. 그 판이 없으면 그대로 둔다. 지금 동작·칸은 이어 간다.
func cf_set_key(key: int) -> void:
	if not _cf_on or key == _cf_key_cur:
		return
	if key > 0 and CharForge.anim(cf_id, "anchor", key).is_empty():
		return
	_cf_key_cur = key
	_cf_k = _cf_scale_for(key)
	_sprite.scale = Vector2(_cf_k, _cf_k)
	if _cf_cur != "":
		var cur: String = _cf_cur
		var fr: int = _sprite.frame
		var t: float = _cf_t
		_cf_set(cur)
		_sprite.frame = mini(fr, _sprite.hframes - 1)
		_cf_t = t


## 몸집 배수(1.0 = 자리 키)에 가장 가까운 크기 단계로 바꾼다. 소수배로 늘이지 않는다.
## 단계 그림이 아직 없으면 아무것도 안 한다(그림은 자리 키 그대로, 판정만 커진다).
func cf_step_for(mult: float) -> void:
	if not _cf_on or cf_steps.is_empty() or cf_target_h <= 0.0:
		return
	var want: float = cf_target_h * mult
	var best: int = int(cf_target_h)
	var bd: float = absf(want - cf_target_h)
	for s in cf_steps:
		var d: float = absf(want - float(s))
		if d < bd:
			bd = d
			best = int(s)
	cf_set_key(0 if best == int(cf_target_h) else best)


func cf_key_now() -> int:
	return _cf_key_cur


## 피격 자세 — 흰색 깜빡임과 같이 쓴다. 다른 동작(스킬·등장·자세) 중이면 끊지 않는다.
func hurt() -> void:
	if not _cf_on or _cf_hit_gap > 0.0:
		return
	if _cf_once != "" and _cf_once != "hit":
		return
	if play_once("hit"):
		_cf_hit_gap = CF_HIT_GAP + float(_an("hit").get("len", 0.26))


## 쓰러진 자세에서 일으킨다(부활).
func cf_reset() -> void:
	_cf_hold = false
	_cf_pose = false
	_cf_once = ""
	_cf_cur = ""


func cf_scale() -> int:
	return _cf_k


func is_cf() -> bool:
	return _cf_on


## 그 동작이 몇 초인지(없으면 0).
func anim_len(a: String) -> float:
	return float(_an(a).get("len", 0.0))


## 이 캐릭터의 시그니처 이펙트(vfx) 한 장 — 같은 판·같은 배율·같은 팔레트로. 없으면 null.
func make_vfx() -> Sprite2D:
	var an: Dictionary = cf_anim("vfx")
	if an.is_empty():
		return null
	var fx := Sprite2D.new()
	fx.texture = an["tex"]
	fx.hframes = int(an["n"])
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.scale = Vector2(_cf_k, _cf_k)
	if _cf_pal_tex != null:
		var it: Texture2D = CharForge.index_tex(cf_id, "vfx", _cf_key_cur)
		if it != null:
			fx.texture = it
			fx.material = _outline_mat(int(an["n"]), float(_cf_k), 1.0, _cf_pal_tex)
	return fx


## 지금 그려진 칸을 그대로 떠서 잔상으로 쓴다(대시 잔상).
func snapshot() -> Sprite2D:
	if not _cf_on:
		return null
	var g := Sprite2D.new()
	g.texture = _sprite.texture
	g.hframes = _sprite.hframes
	g.frame = _sprite.frame
	g.centered = _sprite.centered
	g.offset = _sprite.offset
	g.flip_h = _sprite.flip_h
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.scale = _sprite.scale * scale
	g.position = (_inner.position + _sprite.position) * scale
	if _cf_pal_tex != null:
		g.material = _sprite.material   # 번호 그림이라 팔레트 재질 없이는 색이 안 나온다
	return g


func _cf_update() -> void:
	# 시트는 **오른쪽을 본다** — 왼쪽으로 갈 때 뒤집는다(예전 스파크 산출물과 반대).
	_sprite.flip_h = _face < 0.0
	_cf_hit_gap = maxf(0.0, _cf_hit_gap - _last_delta)
	if _cf_pose:
		return                  # 자세 고정 — 소유자가 풀 때까지 그 칸
	if _cf_once != "":
		var an: Dictionary = _an(_cf_once)
		var ms: Array = an.get("ms", [])
		_cf_t += _last_delta
		var f: int = _sprite.frame
		while f < ms.size() and _cf_t >= float(ms[f]) / 1000.0:
			_cf_t -= float(ms[f]) / 1000.0
			f += 1
		if f >= int(an.get("n", 1)):
			if _cf_hold:
				_sprite.frame = int(an.get("n", 1)) - 1
				return
			_cf_once = ""
			_cf_cur = ""
		else:
			_sprite.frame = f
			return
	# 기본: 움직이면 walk, 서 있으면 idle(숨쉬기, 있으면) 아니면 anchor. 체력 단계 시트가 있으면 그걸로.
	var moving: bool = walk_speed > 4.0
	var base: String = "anchor"
	if moving and not _an(_cf_name("walk")).is_empty():
		base = "walk"
	elif not moving and _cf_state == "" and not _an("idle").is_empty():
		base = "idle"
	var want: String = _cf_name(base)
	if want != _cf_cur:
		_cf_set(want)
	if base == "walk":
		# 걸음은 시간이 아니라 이동 거리에 붙인다(walk_fps) — 시트의 140ms 는 기본값일 뿐이고,
		# 그대로 돌리면 빠른 몹은 발이 바닥을 미끄러진다. --walkcheck 와 같은 식을 쓴다.
		_walk_phase += walk_fps(walk_speed, radius) * _last_delta
		_sprite.frame = int(_walk_phase) % _sprite.hframes
	elif base == "idle":
		# 숨쉬기는 시트의 ms 대로 돈다(450ms 두 칸).
		var ms2: Array = _an(want).get("ms", [])
		_cf_t += _last_delta
		var f2: int = _sprite.frame
		while not ms2.is_empty() and _cf_t >= float(ms2[f2 % ms2.size()]) / 1000.0:
			_cf_t -= float(ms2[f2 % ms2.size()]) / 1000.0
			f2 = (f2 + 1) % _sprite.hframes
		_sprite.frame = f2


func _build_polygon() -> void:
	_eye_r_val = maxf(2.6, radius * 0.26) * eye_scale
	var outline := Polygon2D.new()
	outline.polygon = G.regular_polygon(sides, radius + 3.0)
	outline.color = outline_color
	_inner.add_child(outline)
	_body = Polygon2D.new()
	_body.polygon = G.regular_polygon(sides, radius)
	_body.color = body_color
	_inner.add_child(_body)
	var hi := Polygon2D.new()
	hi.polygon = G.regular_polygon(10, radius * 0.32)
	hi.color = Color(1, 1, 1, 0.16)
	hi.position = Vector2(-radius * 0.28, -radius * 0.4)
	_inner.add_child(hi)
	_add_feature()
	var ey: float = -radius * 0.08
	var gap: float = radius * 0.40
	_eye_l = _make_eye(Vector2(-gap, ey))
	_eye_r = _make_eye(Vector2(gap, ey))
	_pupil_l = _eye_l.get_meta("pupil")
	_pupil_r = _eye_r.get_meta("pupil")
	if angry:
		_make_brow(Vector2(-gap, ey - _eye_r_val - 2.0), false)
		_make_brow(Vector2(gap, ey - _eye_r_val - 2.0), true)


## 종류별 실루엣 장식 (뿔/가시/왕관)
func _add_feature() -> void:
	match feature:
		"horns":
			_horn(Vector2(-radius * 0.5, -radius * 0.55), -0.5)
			_horn(Vector2(radius * 0.5, -radius * 0.55), 0.5)
		"spikes":
			for i in 7:
				var a: float = TAU * float(i) / 7.0
				_spike(Vector2(cos(a), sin(a)) * radius * 0.92, a, radius * 0.42)
		"crown":
			for i in 5:
				var a: float = lerpf(-2.5, -0.64, float(i) / 4.0)
				_spike(Vector2(cos(a), sin(a)) * radius * 0.95, a, radius * 0.55)


func _horn(pos: Vector2, tilt: float) -> void:
	var s := Polygon2D.new()
	var l: float = radius * 0.6
	s.polygon = PackedVector2Array([Vector2(-radius * 0.16, 0), Vector2(radius * 0.16, 0), Vector2(tilt * l * 0.6, -l)])
	s.color = body_color.darkened(0.28)
	s.position = pos
	_inner.add_child(s)


func _spike(base: Vector2, ang: float, l: float) -> void:
	var dir: Vector2 = Vector2(cos(ang), sin(ang))
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([base + perp * radius * 0.16, base - perp * radius * 0.16, base + dir * l])
	s.color = body_color.darkened(0.2)
	_inner.add_child(s)


func _make_eye(pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	_inner.add_child(n)
	var white := Polygon2D.new()
	white.polygon = G.regular_polygon(12, _eye_r_val + 1.6)
	white.color = Color(0.98, 0.98, 1.0)
	n.add_child(white)
	var pupil := Polygon2D.new()
	pupil.polygon = G.regular_polygon(10, _eye_r_val * 0.68)
	pupil.color = Color(0.07, 0.07, 0.12)
	n.add_child(pupil)
	n.set_meta("pupil", pupil)
	return n


func _make_brow(pos: Vector2, right: bool) -> void:
	var b := Polygon2D.new()
	var w: float = _eye_r_val + 2.5
	b.polygon = PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w, 2.6), Vector2(-w, 2.6)])
	b.color = outline_color
	b.position = pos
	b.rotation = deg_to_rad(24.0 if right else -24.0)
	_inner.add_child(b)


## 화면 밖 개체는 애니메이션을 돌릴 이유가 없다.
## 상한 근처(모바일 190 / PC 440)에서는 대부분이 화면 밖인데도 전원이 매 렌더프레임
## 트랜스폼을 갱신하고 있었다 — 이게 몹이 많아질 때 발열이 오르던 큰 축이다.
##
## ★ 컷오프를 상수(780)로 두면 안 된다. 20:9 폰의 가시영역 반대각선은 876 이라 화면 안의 몹이
##   얼어붙는다. 실제 뷰포트에서 매 프레임 한 번만 재서 공유한다(개체 수와 무관하게 1회).
static var _cull_frame: int = -1
static var _cull_r2: float = 1.0e12

static func _cull_radius_sq(node: Node2D) -> float:
	var f: int = Engine.get_frames_drawn()
	if f == _cull_frame:
		return _cull_r2
	_cull_frame = f
	var vp := node.get_viewport()
	if vp == null:
		_cull_r2 = 1.0e12
		return _cull_r2
	var inv := vp.get_canvas_transform().affine_inverse()
	var half: Vector2 = ((inv * vp.get_visible_rect().size) - (inv * Vector2.ZERO)).abs() * 0.5
	var r: float = half.length() + 140.0  # 반대각선 + 개체 반경/부속지 여유
	_cull_r2 = r * r
	return _cull_r2

func _process(delta: float) -> void:
	_last_delta = delta
	_t += delta
	if _flash_t > 0.0:
		_flash_t -= delta
		var k: float = clampf(_flash_t / _flash_dur, 0.0, 1.0)
		if _sprite != null:
			_sprite.modulate = Color.WHITE.lerp(_flash_col, k)
		elif _body != null:
			_body.color = body_color.lerp(_flash_col, k)
	if not always_animate:
		var cam: Node2D = G.camera as Node2D
		if cam != null and is_instance_valid(cam):
			if global_position.distance_squared_to(cam.global_position) > _cull_radius_sq(self):
				return  # 화면 밖 — 포즈를 그대로 두고 다음 프레임에
	_update_anim()
	if _pupil_l == null:
		return  # 스프라이트 모드는 눈 추적/깜빡임 없음
	# 눈동자 추적
	var lp: Vector2 = look_dir.normalized() * (_eye_r_val * 0.55) if look_dir.length() > 0.01 else Vector2.ZERO
	_pupil_l.position = _pupil_l.position.lerp(lp, 0.35)
	_pupil_r.position = _pupil_r.position.lerp(lp, 0.35)
	# 깜빡임
	_blink = maxf(0.0, _blink - delta)
	_next_blink -= delta
	if _next_blink <= 0.0:
		_next_blink = randf_range(2.0, 5.0)
		_blink = 0.11
	var target_ey: float = 0.12 if _blink > 0.0 else 1.0
	_eye_l.scale.y = lerpf(_eye_l.scale.y, target_ey, 0.5)
	_eye_r.scale.y = lerpf(_eye_r.scale.y, target_ey, 0.5)


## 스타일별 몸통+부속지 갱신 (전부 사인 기반 — 할당 없음, 수백 마리에도 저렴)
func _update_anim() -> void:
	# 이동 방향 좌우 플립 (스프라이트 + 부속지 동시, 약간의 데드존으로 떨림 방지)
	if absf(look_dir.x) > 0.3:
		_face = 1.0 if look_dir.x > 0.0 else -1.0
	if _cf_on:
		_cf_update()
		return
	if _sprite != null:
		# ★ 스파크 산출물은 **왼쪽을 보는** 옆모습이다(2026-09-02 확정, 심연의 섬과 같은 규약).
		#   예전 자산은 정면이라 어느 쪽으로 뒤집어도 화면이 안 바뀌어서 이 줄이 틀린 채로 남아 있었다.
		_sprite.flip_h = _face > 0.0
		if _sprite.hframes > 1:
			# ★ 예전엔 4fps 고정이었다. 그러면 4프레임 한 사이클이 1초인데 몹은 초당 118px 를
			#   달리므로, 화면 21px 짜리 캐릭터가 한 걸음에 59px 를 미끄러진다(발이 땅을 지치는
			#   것처럼 보인다). 걸음 수를 이동 거리에 붙여 발이 바닥을 무는 것처럼 만든다.
			#   step_px = 한 걸음이 나아가는 화면 거리. 사람 보폭이 대략 키의 0.45 배다.
			#   ★ 4칸은 한 걸음이 아니라 **한 사이클(두 걸음)**이다. 시트 메타가
			#     0% / 25% / 50% / 75% 지점이라고 적어 준다. 그래서 걸음 하나가 2칸이고,
			#     칸이 도는 속도는 걸음 수의 **두 배**다.
			#   ★ 그리고 상한이 있어야 한다. 플레이어는 330px/s 로 달리는데 보폭이 14.5px 라
			#     계산대로면 초당 45칸 — 60fps 화면에서 그림이 45번 바뀐다. 걷는 게 아니라
			#     떠는 것으로 보인다(2026-09-03 실측 지적). 4칸 걷기는 8~12fps 가 한계다.
			var sp: float = walk_speed
			if sp > 4.0:
				_walk_phase += walk_fps(sp, radius) * _last_delta
			else:
				_walk_phase += 2.0 * _last_delta      # 멈춰 있을 때는 제자리걸음만
			_sprite.frame = int(_walk_phase) % _sprite.hframes
	if _limb_root != null:
		_limb_root.scale.x = _face
	match anim_style:
		"hop":  # 통통 뛰기 + 착지 스쿼시
			var jump: float = absf(sin(_t * 4.2))
			var squat: float = 1.0 - jump  # 0=공중, 1=착지
			_inner.position.y = -jump * radius * 0.34
			_inner.scale = Vector2(1.0 + squat * 0.16, 1.0 - squat * 0.14)
			for i in _limbs.size():  # 점액 방울: 착지 때 옆으로 퍼짐
				var b := _limbs[i] as Node2D
				b.position.x = (radius * 0.72 + squat * radius * 0.2) * (-1.0 if i == 0 else 1.0)
				b.scale = Vector2(1.0 + squat * 0.5, 1.0 - squat * 0.3)
		"flap":  # 빠른 날갯짓 + 파닥 부유
			_inner.position.y = sin(_t * 7.0) * radius * 0.16
			_inner.scale = Vector2(1.0, 1.0 + sin(_t * 14.0) * 0.03)
			var wf: float = sin(_t * 12.0) * 0.65
			for i in _limbs.size():
				(_limbs[i] as Node2D).rotation = wf * (1.0 if i == 0 else -1.0)
		"float":  # 느린 부유 + 큰 날개
			_inner.position.y = sin(_t * 2.1) * radius * 0.15
			_inner.scale = Vector2(1.0 + sin(_t * 2.1) * 0.02, 1.0 - sin(_t * 2.1) * 0.02)
			var ws: float = sin(_t * 3.4) * 0.42
			for i in _limbs.size():
				(_limbs[i] as Node2D).rotation = ws * (1.0 if i == 0 else -1.0)
		"march":  # 뚜벅뚜벅 행진 (좌우 록킹) + 팔 앞뒤 스윙
			_inner.rotation = sin(_t * 5.2) * 0.085
			_inner.position.y = -absf(sin(_t * 5.2)) * radius * 0.10
			for i in _limbs.size():
				(_limbs[i] as Node2D).rotation = sin(_t * 5.2 + (0.0 if i == 0 else PI)) * 0.5
		"scurry":  # 종종걸음 (빠른 잔발) + 팔 파닥
			_inner.position.y = -absf(sin(_t * 9.0)) * radius * 0.12
			_inner.rotation = sin(_t * 9.0) * 0.05
			for i in _limbs.size():
				(_limbs[i] as Node2D).rotation = sin(_t * 9.0 + (0.0 if i == 0 else PI)) * 0.7
		"sway":  # 지그재그 슬리더 + 꼬리 물결
			_inner.position.x = sin(_t * 4.6) * radius * 0.14
			_inner.rotation = sin(_t * 4.6) * 0.10
			for i in _limbs.size():
				var seg := _limbs[i] as Node2D
				seg.position.y = radius * 0.15 + sin(_t * 4.6 - 1.1 * float(i + 1)) * radius * 0.20
		_:  # 기본: 잔잔한 숨쉬기
			_inner.position.y = sin(_t * 3.2) * (radius * 0.06)
			_inner.scale = Vector2(1.0 + sin(_t * 3.2) * 0.02, 1.0 - sin(_t * 3.2) * 0.02)


## 피격 플래시.
## ★ 예전엔 히트마다 create_tween() 이었다. 탄막 게임이라 초당 수백 번 호출되고,
##   같은 프로퍼티에 트윈이 겹쳐 쌓이면서 SceneTree 가 매 프레임 그걸 전부 순회했다.
##   지금은 색만 찍어두고 _process 에서 직접 되돌린다 — 할당이 0이다.
func flash(c: Color, dur: float = 0.16) -> void:
	_flash_col = c
	# ★ 스프라이트(캐릭터 에셋)는 색을 '곱해서' 그린다(outline.gdshader: col * modulate). 흰색(1,1,1)을
	#   곱하면 아무 변화가 없어서, 새 도트로 바뀐 뒤 몹의 피격 번쩍임이 통째로 사라져 있었다
	#   (9차 지시서 '새 그림에만 안 먹는 장치' 전수 때 발견). 흰 번쩍임은 1 을 넘는 값으로 밝힌다.
	if _sprite != null and c.r >= 0.99 and c.g >= 0.99 and c.b >= 0.99:
		_flash_col = Color(FLASH_LIFT, FLASH_LIFT, FLASH_LIFT, c.a)
	_flash_t = dur
	_flash_dur = maxf(0.01, dur)
	if _sprite != null:
		_sprite.modulate = c
	elif _body != null:
		_body.color = c


func set_base_color(c: Color) -> void:
	body_color = c
	if _body != null:
		_body.color = c
