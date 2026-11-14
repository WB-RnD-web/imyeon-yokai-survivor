class_name UiKit
extends RefCounted
## 공용 UI 디자인 시스템 — 일관된 패널/버튼/타이틀/배경. 게임 톤(다크 + 골드 강조).
## 각 화면이 제각각 스타일 만들던 것을 통일 → "대충 만든 폼" 탈피.

const BG_TOP := Color("17141f")
const BG_BOT := Color("09080e")
const PANEL_FILL := Color(0.11, 0.10, 0.145, 0.94)
const PANEL_BORDER := Color("c9a24a")   # 골드 보더
const ACCENT := Color("ffcf5a")         # 골드 강조
const CYAN := Color("6fd6ff")
const TEXT := Color("efe9df")
const TEXT_DIM := Color("9a93a8")
const DANGER := Color("ff6b6b")
const TOUCH_MIN: float = 76.0   # 폰 누르는 칸 최소 높이(화면 기준) — 13차


## ─────────────────── 오클릭 방지: 끌면 취소되는 탭 ───────────────────
## Button 의 pressed 는 **놓는 순간** 발동한다. 모바일에서 화면을 스윽 넘기려고
## 카드 위에서 손가락을 끌다 떼면 그 카드가 선택된다 — 영웅 선택과 레벨업 카드에서
## 실제로 신고받은 증상이다(2026-09-15).
##
## 더블탭이나 '확인' 한 단계를 더 두면 매번 두 번 눌러야 해서 더 불편하다.
## 스크롤되는 목록이 어디서나 쓰는 방식으로 간다 — **누른 자리에서 크게 벗어나면 취소**.
## 제자리에서 톡 누르면 그대로 한 번에 선택되므로, 평소 조작감은 하나도 안 변한다.
##
##   guard: 지금 탭을 받아도 되는지. 레벨업 카드처럼 "뜨자마자 0.25초는 무시" 가 필요한 곳에서 쓴다.
##          (이미 손가락이 내려가 있던 경우는 이 방식에서 저절로 걸러진다 —
##           그 버튼이 '누름'을 받은 적이 없으니 떼어도 발동하지 않는다.)
const TAP_SLOP: float = 22.0   # 이 이상 끌면 탭이 아니라 스크롤로 본다

## ★ pressed 를 떼고 gui_input 만으로 처리하면 **키보드·게임패드 선택이 죽는다**
##   (ui_accept 는 pressed 로만 온다). 그래서 pressed 는 그대로 두고,
##   포인터가 크게 끌렸을 때만 그 한 번을 무시한다. 패드/키보드는 끌림이 없으니 영향이 없다.
static func tap_only(b: Button, cb: Callable, guard: Callable = Callable()) -> Button:
	var st := {"drag": false, "from": Vector2.ZERO, "down": false}
	b.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				st["down"] = mb.pressed
				if mb.pressed:
					st["drag"] = false
					st["from"] = mb.position
		elif e is InputEventScreenTouch:
			var t := e as InputEventScreenTouch
			st["down"] = t.pressed
			if t.pressed:
				st["drag"] = false
				st["from"] = t.position
		elif e is InputEventMouseMotion and bool(st["down"]):
			if ((e as InputEventMouseMotion).position - Vector2(st["from"])).length() > TAP_SLOP:
				st["drag"] = true
		elif e is InputEventScreenDrag:
			if ((e as InputEventScreenDrag).position - Vector2(st["from"])).length() > TAP_SLOP:
				st["drag"] = true)
	b.pressed.connect(func() -> void:
		if bool(st["drag"]):
			st["drag"] = false
			return
		if guard.is_valid() and not guard.call():
			return
		cb.call())
	return b


## 테마 패널 스타일 (다크 반투명 + 라운드 + 강조 보더 + 드롭섀도)
static func panel_style(accent: Color = PANEL_BORDER, fill: Color = PANEL_FILL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(13)
	sb.set_border_width_all(2)
	sb.border_color = accent
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(20)
	return sb


static func make_panel(accent: Color = PANEL_BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	# 14차: 옻칠 판 + 놋쇠 장석(UiParts). 테는 놋쇠 한 색이라 accent 는 부품이 없을 때만 쓴다.
	var pb: StyleBoxTexture = UiParts.panel_box()
	p.add_theme_stylebox_override("panel", pb if pb != null else panel_style(accent))
	return p


## 고르는 버튼(설정 · 모드 · 난이도) — 고른 것은 금 나무 패, 나머지는 보통 나무 패(14차). 부품이 없으면 예전 흐림.
static func choice(b: Button, sel: bool) -> void:
	if UiParts.style_button(b, "primary" if sel else "normal"):
		b.modulate = Color.WHITE
		return
	b.modulate = Color.WHITE if sel else Color(0.6, 0.6, 0.66)
	b.add_theme_color_override("font_color", Color("9dff6b") if sel else Color(0.82, 0.82, 0.88))


## 탭 — 부품 탭(고름은 올라오고 책갈피 끈). 부품이 없으면 choice 와 같게.
static func tab(b: Button, sel: bool) -> void:
	if not UiParts.style_tab(b, sel):
		choice(b, sel)


## 낱말 단위 줄바꿈 — ★ 자동 줄바꿈은 한글을 글자 사이에서도 끊는다(「등 / 장」, 14차). 띄어쓰기에서만 줄을 바꾼 글을 돌려준다.
static func wrap_words(text: String, size: int, width: float) -> String:
	var f: Font = UiFont.font_for(size)
	if f == null:
		return text
	var px: int = UiFont.px(size)
	var out: PackedStringArray = []
	for para: String in I18n.t(text).split("\n"):   # 번역 먼저 — 한글을 꺾어 두면 영어판에서 키가 안 맞아 한 줄로 길게 나왔다
		var lines: PackedStringArray = _greedy_lines(f, px, para, width)
		# 11/5 스팀 피드백 3: 글자를 키우니 한 줄이던 설명이 두 줄로 넘어가며 「던져서 되돌아오는 관통 / 무기」처럼
		#   끝 줄에 낱말 하나만 남았다. 줄 수는 그대로 두고 폭을 줄여 가며 가장 고르게 나뉘는 폭을 찾는다.
		if lines.size() >= 2:
			var lo: float = width * 0.4
			var hi: float = width
			for _i in 12:
				var mid: float = (lo + hi) * 0.5
				if _greedy_lines(f, px, para, mid).size() == lines.size():
					hi = mid
				else:
					lo = mid
			lines = _greedy_lines(f, px, para, hi)
		out.append_array(lines)
	return "\n".join(out)


## 11/5 스팀 피드백 3: 「A · B · C」 처럼 가운뎃점으로 이은 줄 — 항목 사이에서만 꺾고, 꺾인 자리의 가운뎃점은 뺀다.
##   엔진 자동 줄바꿈은 한글 음절 사이도 끊어서 「무피격」이 「무피 / 격」으로, 줄 끝에 「·」 하나가 남았다.
##   줄 수는 그대로 두고 가장 고르게 나뉘는 폭을 찾는다. 항목 하나가 폭보다 길면 그 항목만 낱말 단위로 꺾는다.
static func wrap_items(text: String, size: int, width: float) -> String:
	var f: Font = UiFont.font_for(size)
	if f == null:
		return text
	var px: int = UiFont.px(size)
	var out: PackedStringArray = []
	for para: String in text.split("\n"):
		# 괄호 안의 가운뎃점(「(첫 클리어 +360 · 별 보너스 +131 포함)」)은 항목 경계가 아니다
		var items: PackedStringArray = []
		var cur: String = ""
		var depth: int = 0
		for ch: String in para:
			if ch == "(" or ch == "（":
				depth += 1
			elif (ch == ")" or ch == "）") and depth > 0:
				depth -= 1
			if ch == "·" and depth == 0:
				if cur.strip_edges() != "":
					items.append(cur.strip_edges())
				cur = ""
			else:
				cur += ch
		if cur.strip_edges() != "":
			items.append(cur.strip_edges())
		if items.size() <= 1:
			out.append_array(wrap_words(para.strip_edges(), size, width).split("\n"))
			continue
		var lines: PackedStringArray = _pack_items(f, px, items, width)
		if lines.size() >= 2:
			var lo: float = width * 0.4
			var hi: float = width
			for _i in 12:
				var mid: float = (lo + hi) * 0.5
				if _pack_items(f, px, items, mid).size() == lines.size():
					hi = mid
				else:
					lo = mid
			lines = _pack_items(f, px, items, hi)
		for ln: String in lines:
			if f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > width:
				out.append_array(wrap_words(ln, size, width).split("\n"))
			else:
				out.append(ln)
	return "\n".join(out)


static func _pack_items(f: Font, px: int, items: PackedStringArray, width: float) -> PackedStringArray:
	var out: PackedStringArray = []
	var line: String = ""
	for it: String in items:
		var cand: String = it if line == "" else line + "  ·  " + it
		if line == "" or f.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= width:
			line = cand
		else:
			out.append(line)
			line = it
	out.append(line)
	return out


## 글자칸에 낱말 단위 · 고른 줄바꿈을 건다(엔진 자동 줄바꿈 대신). 칸 폭이 바뀌면 다시 꺾는다.
## items = true 면 가운뎃점 항목 사이에서만 꺾는다. 글을 바꿀 때도 이 함수로 넣는다.
## fixed_w > 0 이면 칸 폭 대신 그 폭에서 꺾는다 — 내용 폭만큼 커지는 판(SHRINK) 안 글자칸에 쓴다.
## ★ 11/7: 출격 화면 상세 판은 칸 폭으로 꺾다 보니, 긴 글로 한 번 넓어진 칸이 그 폭으로 다시 꺾여 줄어들지 않았다
##   — 영웅 13명에서 화면이 옆으로 밀려 나갔다(--herofit ③).
static func set_wrapped(l: Label, text: String, size: int, items: bool = false, fixed_w: float = 0.0) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.set_meta("wrap_raw", text)
	l.set_meta("wrap_items", items)
	l.set_meta("wrap_size", size)
	l.set_meta("wrap_w", fixed_w)
	if not l.has_meta("wrap_hooked"):
		l.set_meta("wrap_hooked", true)
		l.resized.connect(_rewrap.bind(l))
	_rewrap(l)


static func _rewrap(l: Label) -> void:
	if not is_instance_valid(l) or not l.has_meta("wrap_raw"):
		return
	var w: float = maxf(l.size.x, l.custom_minimum_size.x)
	var fw: float = float(l.get_meta("wrap_w", 0.0))
	if fw > 0.0:
		w = fw
	if w < 8.0:
		return
	var raw: String = I18n.t(String(l.get_meta("wrap_raw")))
	var sz: int = int(l.get_meta("wrap_size"))
	var t: String = wrap_items(raw, sz, w) if bool(l.get_meta("wrap_items")) else wrap_words(raw, sz, w)
	if l.text != t:
		l.text = t


static func _greedy_lines(f: Font, px: int, para: String, width: float) -> PackedStringArray:
	var out: PackedStringArray = []
	var line: String = ""
	for w: String in para.split(" "):
		var cand: String = w if line == "" else line + " " + w
		if line == "" or f.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= width:
			line = cand
		else:
			out.append(line)
			line = w
	out.append(line)
	return out


## 창 제목 — 현판(title_band) 위 글자. 부품이 없으면 예전 큰 금빛 글자.
static func title_band(text: String, size: int = 38) -> Control:
	return UiParts.title_band(text, mini(size, 30)) if UiParts.on() else title(text, size)


## 큰 타이틀 (골드 + 두꺼운 외곽선 + 그림자로 도드라짐)
static func title(text: String, size: int = 58) -> Label:
	var l := Label.new()
	l.text = text
	UiFont.apply(l, size)
	l.add_theme_color_override("font_color", ACCENT)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.0, 0.95))
	l.add_theme_constant_override("outline_size", 9)
	l.add_theme_color_override("font_shadow_color", Color(0.4, 0.22, 0.0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 5)
	l.add_theme_constant_override("shadow_outline_size", 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func header(text: String, col: Color = ACCENT, size: int = 22) -> Label:
	var l := Label.new()
	l.text = text
	UiFont.apply(l, size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 4)
	return l


## 통일된 버튼 (다크 채움 + 왼쪽 골드 강조바 + hover 밝아짐/바 두꺼워짐)
static func button(text: String, cb: Callable, primary: bool = false, accent: Color = ACCENT) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(330, 56)
	UiFont.apply(b, 24)
	if G.mobile:
		# 13차 4절: 폰에서 누르는 칸은 최소 48dp(2340×1080 폰에서 약 120px = 화면 기준 76) — 부르는 쪽이 크기를 정한 뒤 붙는다
		b.ready.connect(func() -> void: b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, TOUCH_MIN))
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var base := Color(0.17, 0.15, 0.21) if primary else Color(0.125, 0.12, 0.16)
	var n := StyleBoxFlat.new()
	n.bg_color = base
	n.set_corner_radius_all(10)
	n.border_width_left = 5  # 왼쪽 강조 바
	n.border_color = accent if primary else Color(accent.r, accent.g, accent.b, 0.5)
	n.set_content_margin_all(10)
	n.content_margin_left = 22
	n.shadow_color = Color(0, 0, 0, 0.42)
	n.shadow_size = 6
	n.shadow_offset = Vector2(0, 3)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = base.lightened(0.16)
	h.border_width_left = 9
	h.border_color = accent
	var pr: StyleBoxFlat = n.duplicate()
	pr.bg_color = base.darkened(0.12)
	pr.shadow_size = 2
	pr.shadow_offset = Vector2(0, 1)
	var ds: StyleBoxFlat = n.duplicate()
	ds.bg_color = Color(0.09, 0.09, 0.11)
	ds.border_color = Color(0.3, 0.3, 0.34)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("disabled", ds)
	b.add_theme_color_override("font_color", accent if primary else TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.5))
	# 14차: 나무 패(UiParts) — 주(primary)는 금, 위험색이면 주사, 나머지는 보통. 높이는 부품 그대로(PC 40)
	if UiParts.style_button(b, "primary" if primary else ("danger" if accent == DANGER else "normal")):
		b.custom_minimum_size.y = 44.0 if not G.mobile else b.custom_minimum_size.y
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


## 메뉴가 열릴 때 첫 버튼에 포커스를 준다 — 게임패드로 메뉴를 넘기기 위한 시작점.
##
## ★ 버튼은 원래부터 focus_mode=FOCUS_ALL 이고 focus 스타일박스도 있었다.
##   그런데 아무도 grab_focus() 를 안 불러서, 화면을 열면 포커스가 '아무 데도' 없었다.
##   그 상태에서는 D패드를 눌러도 옮길 대상이 없어 아무 일도 안 일어난다
##   = 스팀덱처럼 마우스가 없는 기기에서는 메뉴에서 그대로 갇힌다.
##
## 패드가 안 꽂혀 있으면 아무것도 하지 않는다. 마우스만 쓰는 사람에게
## 난데없이 밝아진 버튼을 보여 줄 이유가 없다.
static var force_pad: bool = false   # 검사 하니스(--padcheck)용 — 패드가 안 꽂혀 있어도 꽂힌 것처럼


static func focus_first(root: Node) -> void:
	if root == null or (Input.get_connected_joypads().is_empty() and not force_pad):
		return
	var b: Button = _first_button(root)
	if b != null:
		b.grab_focus()


static func _first_button(n: Node) -> Button:
	for c: Node in n.get_children():
		var b := c as Button
		if b != null and b.visible and not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			return b
		var deep: Button = _first_button(c)
		if deep != null:
			return deep
	return null


## 통일 뒤로가기 버튼 (S6): 모든 전체화면 메뉴의 좌상단 고정 — 화면마다 위치/문구가 달랐던 것 통일.
## 스크롤 밖(_root 직속, 콘텐츠 뒤에 add)에 붙여 어디를 스크롤해도 항상 같은 자리.
static func back_button(cb: Callable) -> Button:
	var b := button("뒤로", cb, false)
	UiParts.button_icon(b, "back")   # 16차 U5: 「←」 글꼴 기호 대신
	b.custom_minimum_size = Vector2(150, 44)
	UiFont.apply(b, 19)
	b.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	b.offset_left = 24
	b.offset_top = 20
	b.offset_right = 174
	b.offset_bottom = 68
	return b


## 한 줄 글자가 칸 폭(max_w)을 넘으면 글자 크기를 줄여 맞춘다.
## 영어 이름은 한국어보다 두세 배 길다 — "갈기 셋째 마루" 가 "Maru, Third of the Mane" 이 된다.
## 잘라내기(clip_text)만 걸어 두면 이름 끝이 잘린 채로 나간다.
static func fit_font(lbl: Label, max_w: float, size: int, min_size: int = 12) -> void:
	var f: Font = lbl.get_theme_font("font")
	var txt: String = lbl.atr(lbl.text)
	var s: int = size
	while s > min_size and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > max_w:
		s -= 1
	UiFont.apply(lbl, s)


## 가운데가 밝은 골드 구분선 (w x 3)
static func divider(w: float = 400.0) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.0))
	g.set_color(1, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.0))
	g.add_point(0.5, ACCENT)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.0, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 1
	var tr := TextureRect.new()
	tr.texture = gt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(w, 3)
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## 세로 그라데이션 배경 (full rect)
static func gradient_bg() -> TextureRect:
	var grad := Gradient.new()
	grad.set_color(0, BG_TOP)
	grad.set_color(1, BG_BOT)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 256
	var tr := TextureRect.new()
	tr.texture = gt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## 방사형 비네트 오버레이 (가장자리 어둡게 → 집중감)
static func vignette() -> TextureRect:
	var vg := Gradient.new()
	vg.set_color(0, Color(0, 0, 0, 0))
	vg.set_color(1, Color(0, 0, 0, 0.55))
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5)
	vt.fill_to = Vector2(1.05, 0.5)
	vt.width = 256
	vt.height = 256
	var tr := TextureRect.new()
	tr.texture = vt
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## 터치/마우스 드래그 패닝 (S2) — 모바일에서 ScrollContainer가 손가락 드래그로 안 밀리는 문제 해결.
## 사용: sc.add_child(UiKit.TouchScroll.new(sc)). 데드존(16px)을 넘겨 끌면 패닝 모드로 전환,
## 이후 릴리즈를 소비해 스크롤하다 버튼이 눌리는 오발동을 방지. (에뮬레이트 마우스 경로라 데스크톱 드래그도 동작)
class TouchScroll:
	extends Node
	var _sc: ScrollContainer
	var _pressed: bool = false
	var _panning: bool = false
	var _start: Vector2 = Vector2.ZERO
	var _sv0: int = 0
	var _sh0: int = 0

	func _init(sc: ScrollContainer) -> void:
		_sc = sc
		process_mode = Node.PROCESS_MODE_ALWAYS  # 메뉴는 tree paused 상태에서 열림

	## [감사 C14] 슬라이더(Range 계열) 위에서 시작한 드래그는 팬 대상에서 제외 — 음량 조절이 16px에서 끊기던 것
	func _over_range(pos: Vector2) -> bool:
		var hov: Control = get_viewport().gui_get_hovered_control()
		while hov != null:
			if hov is Range:
				return true
			hov = hov.get_parent() as Control
		return false

	func _input(e: InputEvent) -> void:
		if _sc == null or not is_instance_valid(_sc) or not _sc.is_visible_in_tree():
			return
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := e as InputEventMouseButton
			if mb.pressed:
				if _sc.get_global_rect().has_point(mb.position) and not _over_range(mb.position):
					_pressed = true
					_panning = false
					_start = mb.position
					_sv0 = _sc.scroll_vertical
					_sh0 = _sc.scroll_horizontal
			else:
				if _panning:
					get_viewport().set_input_as_handled()  # 릴리즈 소비 → 스크롤 중 버튼 오발동 방지
				_pressed = false
				_panning = false
		elif e is InputEventMouseMotion and _pressed:
			var d: Vector2 = (e as InputEventMouseMotion).position - _start
			if not _panning and d.length() > 16.0:
				_panning = true
			if _panning:
				if _sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
					_sc.scroll_vertical = _sv0 - int(d.y)
				if _sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
					_sc.scroll_horizontal = _sh0 - int(d.x)
				get_viewport().set_input_as_handled()


## 떠다니는 먼지 입자 (분위기). parent 좌표계 중심/범위 지정.
static func motes(center: Vector2, extents: Vector2, col: Color = Color(1.0, 0.85, 0.5, 0.14)) -> CPUParticles2D:
	var m := CPUParticles2D.new()
	m.position = center
	m.amount = 60
	m.lifetime = 9.0
	m.preprocess = 9.0
	m.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	m.emission_rect_extents = extents
	m.direction = Vector2(0.1, -1.0)
	m.spread = 22.0
	m.gravity = Vector2.ZERO
	m.initial_velocity_min = 4.0
	m.initial_velocity_max = 16.0
	m.scale_amount_min = 1.4
	m.scale_amount_max = 3.6
	m.color = col
	return m
