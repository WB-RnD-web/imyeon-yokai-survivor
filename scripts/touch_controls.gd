class_name TouchControls
extends CanvasLayer
## 모바일 터치 조작: 왼쪽 가상 조이스틱(이동) + 오른쪽 대시 버튼.
## 조이스틱 자리는 설정에서 고른다 — **고정(기본)** / 따라옴. G.stick_fixed() 참조.
## 기존 액션(move_left/right/up/down, dash)에 강도를 주입 → 플레이어 코드 무수정.
## PROCESS_MODE_ALWAYS: 레벨업 모달 등 일시정지 중에도 터치 상태를 계속 추적해
## 재개 시 스틱 강도를 즉시 재주입 — "레벨업 후 안 움직이는" 유령 그랩 버그 근본 수정.

## 조이스틱 응답 — 설정에서 고른다 (G.stick_preset).
## ★ 예전엔 반경 165px · 곡선 1.45 고정이었다. 절반을 밀어도 속도가 37% 밖에 안 나와서
##   "끝까지 땡겨야 속도가 난다"는 체감이 맞았다. 미세 조작을 주려는 의도였지만 이 게임은
##   탄막 회피물이라 천천히 걷고 싶은 순간이 거의 없다 — 이동속도가 곧 방어다.
##   기본을 '표준'(반경 105 · 곡선 1.15)으로 낮추고, 예전 감각은 '정밀'로 남겨 뒀다.
const STICK_PRESETS: Array = [
	{"name": "정밀", "radius": 150.0, "curve": 1.45},   # 예전 기본값 — 저속 미세 조작 우선
	{"name": "표준", "radius": 105.0, "curve": 1.15},   # 기본 — 엄지 한 뼘이면 최대 속도
	{"name": "즉각", "radius": 78.0, "curve": 1.0},     # 살짝만 밀어도 최고 속도(선형)
]
const STICK_DEAD: float = 0.10      # 데드존
## 고정형 조이스틱의 자리 — 화면 왼쪽 아래. 엄지가 자연스럽게 닿는 위치다.
## 화면비가 어떻든 같은 자리에 오도록 좌하단 기준으로 잡는다.
const FIX_MARGIN: Vector2 = Vector2(150.0, 150.0)
const DASH_R: float = 82.0          # 대시 버튼 반경
const MOVE_ACTIONS: Array = ["move_left", "move_right", "move_up", "move_down"]


static func stick_radius() -> float:
	return float((STICK_PRESETS[G.stick_preset()] as Dictionary)["radius"])


static func stick_curve() -> float:
	return float((STICK_PRESETS[G.stick_preset()] as Dictionary)["curve"])

var _stick_idx: int = -1            # 조이스틱 잡은 손가락
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_cur: Vector2 = Vector2.ZERO
var _dash_idx: int = -1
var _painter: _Painter
var _was_active: bool = false       # 직전 프레임에 액션 주입이 유효했는지 (전환 감지)


func _ready() -> void:
	layer = 60  # HUD 위, 레벨업/일시정지 모달(더 높음)은 아래로 통과
	process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 터치 추적
	_painter = _Painter.new()
	_painter.tc = self
	_painter.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE  # GUI 클릭 방해 안 함
	add_child(_painter)


func _dash_center() -> Vector2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var s: float = _btn_scale()
	return Vector2(vp.x - 128.0 * s, vp.y - 118.0 * s)


## 고정형 조이스틱의 원점. 힌트 고리도 같은 자리에 그린다 — 눌러야 할 곳과 원점이 같아야
## "여기가 가운데"가 손에 남는다.
func _fixed_origin() -> Vector2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(FIX_MARGIN.x, vp.y - FIX_MARGIN.y)


func _hint_center() -> Vector2:
	if G.stick_fixed():
		return _fixed_origin()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(150.0, vp.y - 140.0)


## 대시 버튼 크기 배수 — 인터페이스 크기 설정 연동 (가독성)
func _btn_scale() -> float:
	return clampf(G.hud_scale(), 1.0, 1.3)


## 지금 액션을 주입해도 되는가 (게임 진행 중 + 모달 일시정지 아님)
func _active() -> bool:
	return G.running and not get_tree().paused


func _process(_d: float) -> void:
	var act: bool = _active()
	var show: bool = G.running and not get_tree().paused   # QA 10/13: 멈춘 동안(레벨업 · 일시정지 · 상자)엔 창 위에 안 그린다
	if _painter.visible != show:
		_painter.visible = show
	if act != _was_active:
		_was_active = act
		if act:
			_resync()          # 일시정지 해제 → 잡고 있던 스틱 강도 즉시 재주입
		else:
			_release_actions() # 일시정지/종료 → 액션만 해제 (터치 추적은 유지)
	if G.running:
		_painter.queue_redraw()


## 현재 스틱 상태를 액션에 다시 반영 (재개 직후)
func _resync() -> void:
	if _stick_idx != -1:
		var o: Vector2 = _clamped_off(_stick_cur) if G.stick_fixed() else (_stick_cur - _stick_origin)
		_apply_move(o / stick_radius())
	else:
		_apply_move(Vector2.ZERO)
	if _dash_idx == -1:
		Input.action_release("dash")


func _release_actions() -> void:
	for a in MOVE_ACTIONS:
		Input.action_release(a)
	Input.action_release("dash")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			# 일시정지 중엔 새 그랩을 만들지 않음 (카드 탭이 스틱을 훔치는 것 방지)
			if not _active():
				return
			if _dash_idx == -1 and t.position.distance_to(_dash_center()) <= DASH_R * _btn_scale():
				_dash_idx = t.index
				Input.action_press("dash")
			elif _stick_idx == -1 and t.position.x < get_viewport().get_visible_rect().size.x * 0.5:
				_stick_idx = t.index
				# 고정형: 원점은 늘 같은 자리다. 누른 곳이 원점에서 떨어져 있으면 그 방향으로
				# 바로 움직인다 — 왼쪽 아무 데나 눌러도 되는 편의는 그대로 두고,
				# '가운데가 어디냐'만 고정한다.
				_stick_origin = _fixed_origin() if G.stick_fixed() else t.position
				_stick_cur = t.position
				if G.stick_fixed() and _active():
					_apply_move(_clamped_off(t.position) / stick_radius())
		else:
			# 릴리즈는 일시정지 중에도 반드시 처리 → 유령 그랩(인덱스 잔류) 제거
			if t.index == _stick_idx:
				_stick_idx = -1
				_stick_cur = _stick_origin
				if _active():
					_apply_move(Vector2.ZERO)
			elif t.index == _dash_idx:
				_dash_idx = -1
				Input.action_release("dash")
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _stick_idx:
			var rr: float = stick_radius()
			var off: Vector2
			if G.stick_fixed():
				# 고정형: 원점을 절대 안 옮긴다. 반경 밖은 방향만 취하고 강도는 최대.
				off = _clamped_off(d.position)
			else:
				off = d.position - _stick_origin
				# 원점 트레일: 손가락이 반경을 벗어나면 원점을 끌어당겨 방향전환/턴에도 풀강도 유지
				if off.length() > rr:
					_stick_origin = d.position - off.normalized() * rr
					off = d.position - _stick_origin
			_stick_cur = d.position
			if _active():
				_apply_move(off / rr)


## 고정 원점에서 손가락까지의 벡터를 반경 안으로 자른다.
func _clamped_off(pos: Vector2) -> Vector2:
	var off: Vector2 = pos - _fixed_origin()
	var rr: float = stick_radius()
	return off.limit_length(rr)


## 조이스틱 벡터(-1~1, 화면좌표 y아래+)를 이동 액션 강도로 주입.
## 곡선 지수만큼 저속 구간이 늘어난다 — 표준(1.15)에서 절반을 밀면 약 45%, 즉각(1.0)이면 정확히 50%.
func _apply_move(v: Vector2) -> void:
	var len: float = v.length()
	if len < STICK_DEAD:
		v = Vector2.ZERO
	else:
		v = v.normalized() * pow(clampf(len, 0.0, 1.0), stick_curve())
	_axis("move_left", "move_right", v.x)
	_axis("move_up", "move_down", v.y)


func _axis(neg: String, pos: String, val: float) -> void:
	if val > 0.01:
		Input.action_release(neg)
		Input.action_press(pos, minf(1.0, val))
	elif val < -0.01:
		Input.action_release(pos)
		Input.action_press(neg, minf(1.0, -val))
	else:
		Input.action_release(neg)
		Input.action_release(pos)


## 반투명 조이스틱/대시 버튼 렌더러
class _Painter:
	extends Control
	var tc: TouchControls

	func _draw() -> void:
		if tc == null:
			return
		# ── 대시 버튼 ──
		var bs: float = tc._btn_scale()
		var dc: Vector2 = tc._dash_center()
		var dr: float = TouchControls.DASH_R * bs
		var pressed: bool = tc._dash_idx != -1
		var dcol: Color = Color(1.0, 0.85, 0.3, 0.55 if pressed else 0.32)
		draw_circle(dc, dr, Color(0.1, 0.1, 0.14, 0.35))
		draw_arc(dc, dr - 3.0, 0.0, TAU, 40, dcol, 4.0)
		# 번개 아이콘
		var b: PackedVector2Array = PackedVector2Array([
			dc + Vector2(6, -34) * bs, dc + Vector2(-14, 6) * bs, dc + Vector2(-1, 6) * bs,
			dc + Vector2(-6, 34) * bs, dc + Vector2(16, -8) * bs, dc + Vector2(2, -8) * bs,
		])
		draw_colored_polygon(b, Color(1.0, 0.9, 0.4, 0.85 if pressed else 0.6))
		# ── 조이스틱 ──
		# 고정형은 **안 잡고 있을 때도** 자리를 보여 준다. 기준점이 늘 보여야
		# "가운데가 어디냐"를 눈으로 확인 안 해도 손이 안다.
		# 14차 U4: 조이스틱 판(48, 테만) · 손잡이(20) 부품 — 반지름에 가장 가까운 정수배로
		var jb: Texture2D = null
		var jk: Texture2D = null
		var jkk: int = maxi(2, roundi(TouchControls.stick_radius() * 2.0 / 48.0))
		if UiParts.on():
			jb = UiParts.tex("joystick_base", 0, jkk)
			jk = UiParts.tex("joystick_knob", 0, jkk)
		if jb != null and jk != null:
			var bo: Vector2 = Vector2.ZERO
			var ko: Vector2 = Vector2.ZERO
			var ja: float = 1.0
			if tc._stick_idx != -1:
				bo = tc._stick_origin
				var sr0: float = TouchControls.stick_radius()
				ko = bo + ((tc._stick_cur - bo).limit_length(sr0) if G.stick_fixed() else (tc._stick_cur - bo))
			elif G.stick_fixed():
				bo = tc._fixed_origin()
				ko = bo
				ja = 0.8
			else:
				bo = tc._hint_center()
				ko = bo
				ja = 0.55       # 따라옴 모드 쉬는 자리 — 은은하게
			draw_texture(jb, (bo - jb.get_size() * 0.5).round(), Color(1, 1, 1, ja))
			draw_texture(jk, (ko - jk.get_size() * 0.5).round(), Color(1, 1, 1, ja))
			return
		if tc._stick_idx == -1 and G.stick_fixed():
			var fo: Vector2 = tc._fixed_origin()
			var fr: float = TouchControls.stick_radius()
			# 13차: 0.14~0.22 라 판 위에서 거의 안 보였다(에셋 담당 검토 「조이스틱이 보이지 않는다」)
			draw_circle(fo, fr, Color(0.2, 0.22, 0.3, 0.26))
			draw_arc(fo, fr, 0.0, TAU, 48, Color(1, 1, 1, 0.32), 3.0)
			draw_circle(fo, 46.0, Color(0.6, 0.8, 1.0, 0.3))
			draw_arc(fo, 46.0, 0.0, TAU, 32, Color(1, 1, 1, 0.4), 2.0)
			return
		if tc._stick_idx != -1:
			var o: Vector2 = tc._stick_origin
			var sr: float = TouchControls.stick_radius()
			# 고정형은 손가락이 고리 밖으로 나가도 노브는 테두리에 붙어 있어야 한다 —
			# 노브가 화면을 가로질러 날아다니면 기준점이 고정이라는 게 안 읽힌다.
			var off: Vector2 = (tc._stick_cur - o).limit_length(sr) if G.stick_fixed() else (tc._stick_cur - o)
			var knob_pos: Vector2 = o + off
			var strength: float = clampf(off.length() / sr, 0.0, 1.0)
			draw_circle(o, sr, Color(0.2, 0.22, 0.3, 0.22))
			draw_arc(o, sr, 0.0, TAU, 48, Color(1, 1, 1, 0.22), 3.0)
			# 강도 게이지: 당긴 만큼 호가 차오름 (최대 속도 도달 시각 피드백)
			if strength > 0.03:
				var a0: float = off.angle()
				draw_arc(o, sr - 7.0, a0 - strength * PI, a0 + strength * PI, 32,
					Color(0.6, 0.85, 1.0, 0.25 + 0.35 * strength), 5.0)
			var knob: Color = Color(0.6, 0.8, 1.0, 0.4) if strength < 0.98 else Color(0.95, 0.85, 0.4, 0.55)
			draw_circle(knob_pos, 46.0, knob)
			draw_arc(knob_pos, 46.0, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 3.0)
		else:
			# 힌트(어디를 잡으면 되는지) — 왼쪽 하단 은은하게 (따라옴 모드 전용)
			var h: Vector2 = tc._hint_center()
			draw_arc(h, 74.0, 0.0, TAU, 40, Color(1, 1, 1, 0.3), 3.0)
			draw_circle(h, 34.0, Color(0.6, 0.8, 1.0, 0.28))
