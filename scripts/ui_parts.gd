class_name UiParts
extends RefCounted
## UI 부품 한 벌(에셋 담당 13차 5절 U1~U4, survivor_ui/parts) — 「부적 · 먹 · 옻칠 · 놋쇠」.
## 창 = 검은 옻칠 판 + 놋쇠 모서리 장석 · 버튼 = 나무 패(눌림 1px) · 탭 = 책갈피 끈 · 칸 = 파인 바닥 ·
## 레벨업 카드 = 부적(한지 + 등급 색 두 겹 테 + 인장) · HUD 막대 틀.
## ★ 14차: 부품은 10/8 에 와 있었는데 13차 회신을 쓸 때 못 보고 화면을 그대로 냈다 —
##   「2015년 웹 관리자 페이지」(에셋 담당 14차). 판 · 버튼 · 탭 · 칸은 전부 여기서 만든다.
##
## 그림 1px = UI 2px(폰 버튼만 3px). 9조각 모서리는 json slice × 배수. 가운데 칸은 무늬가 없어 늘려도 된다.
## 그림이 없으면(지운 경우) 모든 함수가 null/false — 부르는 쪽이 예전 단색 판을 쓴다.

const W: String = "ui/parts"
## 한 벌 팔레트(parts/palette.json names) — 글자 · 장식 색도 여기서만 뽑는다
const INK := Color("120c10")
const LAC_D := Color("2a1518")
const LAC := Color("3d1f22")
const LAC_HI := Color("5a3030")
const BRASS_D := Color("7a5422")
const BRASS := Color("c4913a")
const BRASS_HI := Color("f0d488")
const PAPER_D := Color("b49a64")
const PAPER := Color("e8d6a4")
const PAPER_HI := Color("fff6d8")
const CIN_D := Color("8c2018")
const CIN := Color("d8442e")
const INDIGO := Color("3a5ca8")
const PURPLE := Color("8a4ab0")
const GRAY := Color("6a6068")


static func on() -> bool:
	return FxLib.has(W, "panel")


## 도트 체크(7 × 6) — 갈무리에 ✔ 가 없다. 그림 1px = UI k px.
static func check_icon(col: Color, k: int = 2) -> TextureRect:
	var rows: PackedStringArray = ["......#", ".....##", "#...##.", "##.##..", ".###...", "..#...."]
	var img := Image.create(7, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == "#":
				img.set_pixel(x, y, col)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(7 * k, 6 * k)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## 스크롤 막대 — 부품에 그림이 없어 Godot 기본 회색 막대가 상점 · 설정 오른쪽에 그대로 보였다(14차 화면).
## 기본 테마에 팔레트 색(옻칠 홈 · 놋쇠 손잡이)을 한 번 걸면 모든 화면 스크롤 막대가 따라온다. 부팅 때 한 번.
static func skin_scrollbars() -> void:
	if not on():
		return
	var th: Theme = ThemeDB.get_default_theme()
	if th == null:
		return
	# 15차: 툴팁도 부품(tooltip — 한지, 글자 먹색). 잠긴 영웅의 해금 조건 등.
	var tp: StyleBoxTexture = box("tooltip", 2)
	if tp != null:
		tp.content_margin_left = 12.0
		tp.content_margin_right = 12.0
		tp.content_margin_top = 6.0
		tp.content_margin_bottom = 6.0
		th.set_stylebox("panel", "TooltipPanel", tp)
		th.set_color("font_color", "TooltipLabel", INK)
		var tf: Font = UiFont.font_for(20)
		if tf != null:
			th.set_font("font", "TooltipLabel", tf)
		th.set_font_size("font_size", "TooltipLabel", UiFont.px(20))
	for cls in ["VScrollBar", "HScrollBar"]:
		var vert: bool = cls == "VScrollBar"
		var track := StyleBoxFlat.new()
		track.bg_color = INK
		track.border_color = LAC
		track.set_border_width_all(2)
		track.content_margin_left = 6.0 if vert else 0.0
		track.content_margin_right = 6.0 if vert else 0.0
		track.content_margin_top = 0.0 if vert else 6.0
		track.content_margin_bottom = 0.0 if vert else 6.0
		th.set_stylebox("scroll", cls, track)
		th.set_stylebox("scroll_focus", cls, track)
		# 15차: 세로 막대는 받은 부품(scroll_track · scroll_thumb 6×12, 세로 9조각). 가로는 그림이 없어 팔레트 색 그대로.
		var tk: StyleBoxTexture = box("scroll_track", 2, 0, 0.0) if vert else null
		var tb: StyleBoxTexture = box("scroll_thumb", 2, 0, 0.0) if vert else null
		if tk != null and tb != null:
			# 홈의 안쪽 여백 = 손잡이 자리(README: 홈 안 1px 안쪽). 손잡이 폭 8 + 2 + 2 = 그림 폭 12.
			tk.content_margin_left = 2.0
			tk.content_margin_right = 2.0
			tk.content_margin_top = 2.0
			tk.content_margin_bottom = 2.0
			tb.content_margin_left = 4.0
			tb.content_margin_right = 4.0
			tb.content_margin_top = 4.0
			tb.content_margin_bottom = 4.0
			th.set_stylebox("scroll", cls, tk)
			th.set_stylebox("scroll_focus", cls, tk)
			th.set_stylebox("grabber", cls, tb)
			var hi: StyleBoxTexture = tb.duplicate()
			hi.modulate_color = Color(1.2, 1.2, 1.2)
			th.set_stylebox("grabber_highlight", cls, hi)
			th.set_stylebox("grabber_pressed", cls, hi)
			continue
		for st: Array in [["grabber", BRASS_D], ["grabber_highlight", BRASS], ["grabber_pressed", BRASS_HI]]:
			var g := StyleBoxFlat.new()
			g.bg_color = st[1]
			g.border_color = INK
			g.set_border_width_all(2)
			th.set_stylebox(String(st[0]), cls, g)


## ---- 16차 U5 · U6 작은 아이콘(survivor_ui/icons_small) — 이모지 · 글꼴 기호(★ ☆ ◆ ▲ ← ≡ ∞) 자리 ----
## 12px 는 HUD · 능력치 줄 · 글 줄 옆, 16px 는 버튼 안. 한 화면 안에서는 한 크기만(에셋 담당 U5 · U6 절).
const SMALL: String = "ui/icons_small"

## 아이콘 텍스처. name 은 "star_full" 처럼 U5 이름(u5_<name>_<px>) 또는 U6 이름(u6_<name>, 12 만).
static func icon_tex(name: String, px: int = 12, k: int = 2) -> Texture2D:
	var sheet: String = "u5_%s_%d" % [name, px]
	if not FxLib.has(SMALL, sheet):
		sheet = "u6_" + name
	return FxLib.scaled(SMALL, sheet, 0, k) if FxLib.has(SMALL, sheet) else null


static func icon(name: String, px: int = 12, k: int = 2, tint: Color = Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = icon_tex(name, px, k)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = tint
	return tr


## 버튼 글자 앞에 16px 아이콘(Button.icon). 그림이 없으면 글자만 남는다.
static func button_icon(b: Button, name: String, k: int = 2) -> void:
	var t: Texture2D = icon_tex(name, 16, k)
	if t == null:
		return
	b.icon = t
	b.add_theme_constant_override("h_separation", 8)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static func with_icon(b: Button, name: String) -> Button:
	button_icon(b, name)
	return b


## 별 n 개(찬 · 빈) 한 줄 — 정복 · 결과 · 출격 준비의 ★☆ 글자 자리.
static func stars(on_n: int, total: int = 3, px: int = 12, k: int = 2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in total:
		row.add_child(icon("star_full" if i < on_n else "star_empty", px, k))
	return row


## 칸 하나를 배수로 키운 텍스처(9조각 · 아이콘용).
static func tex(sheet: String, frame: int = 0, k: int = 2) -> Texture2D:
	return FxLib.scaled(W, sheet, frame, k) if FxLib.has(W, sheet) else null


## 9조각 StyleBoxTexture. content < 0 이면 글자 여백 = 모서리 크기.
static func box(sheet: String, k: int = 2, frame: int = 0, content: float = -1.0) -> StyleBoxTexture:
	var t: Texture2D = tex(sheet, frame, k)
	if t == null:
		return null
	var sl: Array = FxLib.json_of(W, sheet).get("slice", [0, 0, 0, 0])
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.texture_margin_left = float(sl[0]) * k
	sb.texture_margin_top = float(sl[1]) * k
	sb.texture_margin_right = float(sl[2]) * k
	sb.texture_margin_bottom = float(sl[3]) * k
	if content >= 0.0:
		sb.set_content_margin_all(content)
	else:
		sb.content_margin_left = sb.texture_margin_left
		sb.content_margin_top = sb.texture_margin_top
		sb.content_margin_right = sb.texture_margin_right
		sb.content_margin_bottom = sb.texture_margin_bottom
	return sb


## 큰 판(창 · 일시정지 · 결과 · 상점 상세) — 장석 안쪽으로 글자 여백 넉넉히.
static func panel_box(small: bool = false) -> StyleBoxTexture:
	return box("panel_small" if small else "panel", 2, 0, 12.0 if small else 22.0)


static func cell_box(sel: bool = false, content: float = 6.0) -> StyleBoxTexture:
	return box("cell_sel" if sel else "cell", 2, 0, content)


## 나무 패 버튼. kind = normal · primary(금) · danger(주사). 폰은 ×3(누르는 칸).
static func style_button(b: Button, kind: String = "normal") -> bool:
	if not on():
		return false
	var k: int = 3 if G.mobile else 2
	var n: StyleBoxTexture = box("btn_%s_normal" % kind, k, 0, -1.0)
	var pr: StyleBoxTexture = box("btn_%s_pressed" % kind, k, 0, -1.0)
	var ds: StyleBoxTexture = box("btn_%s_disabled" % kind, k, 0, -1.0)
	if n == null or pr == null or ds == null:
		return false
	for sb: StyleBoxTexture in [n, pr, ds]:
		sb.content_margin_left = maxf(sb.content_margin_left, 14.0)
		sb.content_margin_right = maxf(sb.content_margin_right, 14.0)
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 6.0
	pr.content_margin_top = 4.0 + float(k)       # 눌리면 글자도 1px 내려앉는다
	pr.content_margin_bottom = 6.0 - float(k)
	var h: StyleBoxTexture = n.duplicate()
	h.modulate_color = Color(1.18, 1.14, 1.08)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("hover_pressed", pr)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", ds)
	var fc: Color = INK if kind == "primary" else PAPER_HI
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, fc)
	b.add_theme_color_override("font_disabled_color", GRAY)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, 20.0 * float(k))
	return true


## 탭(안 고름 · 고름). 고른 탭은 올라오고 오른쪽 위에 주사 책갈피 끈.
static func style_tab(b: Button, sel: bool) -> bool:
	if not on():
		return false
	var t: StyleBoxTexture = box("tab_sel" if sel else "tab", 2, 0, -1.0)
	if t == null:
		return false
	t.content_margin_left = maxf(t.content_margin_left, 12.0)
	t.content_margin_right = maxf(t.content_margin_right, 18.0)
	t.content_margin_top = 4.0
	t.content_margin_bottom = 4.0
	var h: StyleBoxTexture = t.duplicate()
	h.modulate_color = Color(1.15, 1.12, 1.06)
	for st in ["normal", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, t)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", t)
	var fc: Color = BRASS_HI if sel else PAPER_D
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, fc)
	b.add_theme_color_override("font_disabled_color", GRAY)
	b.modulate = Color.WHITE
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, 32.0)
	return true


## 칸 버튼(영웅 · 상점 · 도감 격자). 고른 칸은 놋쇠 밝은 테.
static func style_cell(b: Button, sel: bool) -> bool:
	var n: StyleBoxTexture = cell_box(sel, 4.0)
	if n == null:
		return false
	var h: StyleBoxTexture = cell_box(true, 4.0)
	for st in ["normal", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return true


## 부적 카드 판 — 등급 키(main_cards RARITY) → 부적 넷.
static func talisman_box(rarity: String) -> StyleBoxTexture:
	# 10/13: 납품 부적(talisman_*)은 일반이 진한 빨강 띠, 전설 띠는 종이 색이라 등급이 거꾸로 읽혔다.
	#   등급마다 따로 구운 talisman_g_*(tools/make_talisman_frames.py)를 쓴다 — 오를수록 띠가 굵고 금속 테가 붙는다.
	var sheet: String = "talisman_g_common"
	match rarity:
		"rare":
			sheet = "talisman_g_rare"
		"epic":
			sheet = "talisman_g_epic"
		"unique":
			sheet = "talisman_g_unique"
		"legendary":
			sheet = "talisman_g_legend"
		"evo":
			sheet = "talisman_g_evo"
		"mythic":
			sheet = "talisman_g_mythic"
	return box(sheet, 2, 0, 16.0)


## 창 제목 현판 — 가운데 글자(갈무리 보통 꼴, 놋쇠 밝은 색).
static func title_band(text: String, size: int) -> Control:
	var sb: StyleBoxTexture = box("title_band", 2, 0, -1.0)
	var l := Label.new()
	l.text = text
	UiFont.apply(l, size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", BRASS_HI)
	if sb == null:
		return l
	sb.content_margin_left = 40.0
	sb.content_margin_right = 40.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(0, 32)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## 레벨 점(찬 · 빈) 한 줄 — 4×4 그림 ×2.
static func pips(on_n: int, total: int, gap: int = 4) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", gap)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t_on: Texture2D = tex("pip_on")
	var t_off: Texture2D = tex("pip_off")
	if t_on == null or t_off == null:
		return row
	for i in total:
		var r := TextureRect.new()
		r.texture = t_on if i < on_n else t_off
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(r)
	return row


## 「새로!」 · 「Lv 3 → 4」 배지 — 주사 바탕 + 한지색 글자.
static func badge(text: String, fs: int = 16) -> Control:
	var sb: StyleBoxTexture = box("new_badge", 2, 0, -1.0)
	var l := Label.new()
	l.text = text
	UiFont.apply(l, fs)
	l.add_theme_color_override("font_color", PAPER_HI)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if sb == null:
		return l
	sb.content_margin_left = 10.0 + float(fs - 16)
	sb.content_margin_right = 10.0 + float(fs - 16)
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.add_child(l)
	return p
