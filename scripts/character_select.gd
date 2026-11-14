class_name CharacterSelect
extends CanvasLayer
## 캐릭터(직업) 선택. 초상화 카드 + 난이도 + 등급 강화(골드). 호버/우클릭 시 상세 능력.
## UiKit 디자인 시스템(다크+골드) 적용 — 메인 메뉴와 톤 통일.

signal picked(def: Dictionary)
signal closed  # 뒤로가기(버튼/모바일 하드웨어) → 메인 메뉴

const DIFF_COLORS: Array = [Color("62d162"), Color("54c6ff"), Color("ff9f43"), Color("ff5a5a"), Color("b44dff")]
## 상세 판 폭과 그 안 두 글자 칸이 꺾는 폭. 영웅 격자(7 × 96 + 판 여백 ≈ 740) + 사이 14 + 이 판이 1280 안에 든다.
## ★ 11/7 스팀 플레이 보고: 영웅을 고르면 화면이 옆으로 늘어나 다 안 보였다. 두 글자 칸이 칸 폭으로 꺾다 보니
##   긴 설명(영어는 더 길다)이 판을 최대 780 까지 밀었다. 이제 고정 폭에서 꺾는다(판 안쪽 여백 좌우 22씩).
const DETAIL_W: float = 500.0
const LBL_W: float = DETAIL_W - 44.0
const ABIL_W: float = LBL_W - 132.0 - 14.0 - 32.0   # 큰 초상 132 · 사이 14 · 능력 아이콘 26 + 6
# 캐릭터별 실루엣 장식 (괴물 방향 개성)
## 스프라이트가 아직 없는 캐릭터의 도형 폴백 실루엣 — 초상이 전부 같은 동그라미가 되지 않게.
const FEATURES: Dictionary = {
	"berserker": "horns", "gunner": "spikes", "gambler": "crown",
	"knight": "crown", "pyro": "spikes", "rogue": "horns",
	"mudang": "crown", "hwarang": "spikes", "smith": "horns",
	"monk": "", "falconer": "spikes",
}

var _root: Control
var _diff_btns: Array = []
var _mode_btns: Array = []        # [∞ 무한, 스테이지1..6] (S1)
var _back_btn: Button             # 좌상단 뒤로 — 탭 줄이 그 밑으로 들어가지 않게 잰다(10/13 QA B13)
var _mode_pad: Control            # 탭 줄 맨 앞 빈칸 — 겹치는 만큼만 벌린다
var _mode_row: HBoxContainer      # 탭 줄
var _mode_compact: bool = false   # 좁은 화면: 스테이지 탭을 번호 + 별만(이름은 아래 설명 줄에 나온다)
var _diff_desc_lbl: Label
var _row: Container        # 13차: 영웅 격자(GridContainer 7열)
var _detail_rank: Label
var _detail_abil: Label
var _detail_icon: IconBadge
var _detail_stats: HBoxContainer
var _up_btn: Button
var _star_row: Control
var _go_btn: Button
var _gold_lbl: Label
var _detail_lbl: Label
var _detail_name: Label
var _detail_port: CenterContainer   # 캐릭터 에셋 초상화(전설 이상) — 없으면 숨김
var _skin_row: HBoxContainer        # 16차: 차림 고르기(기본 / 저승길)
var _card_btns: Dictionary = {}   # id -> Button (선택 골드 보더 표시용)
var _selected_id: String = ""
# [감사 C5] 모드/스테이지/난이도는 로컬 선택값 — G에는 출격(_pick) 시점에만 커밋 (진행 중 런 오염/기록 위조 방지)
var _sel_mode: int = -1   # -1 무한 / 0~5 스테이지
var _sel_diff: int = 1
## 사용자가 고른 난이도(설정 값). _sel_diff 는 스테이지마다 잠긴 단계를 피해 내린 값이고, 이건 내리지 않는다 —
## 탭을 옮길 때마다 여기서 다시 계산하고, 저장도 이 값만 한다(11/5 스팀 피드백 1).
var _want_diff: int = 1
var _karma_box: HBoxContainer   # 11/7 업보 단계 조절(저승길을 깨면 보인다)
var _karma_val: Label
var _karma_lbl: Label           # 골드 줄 오른쪽 업보 요약


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	# ── 배경(그라데이션 + 먼지 + 비네트) — 메인 메뉴와 동일 톤 ──
	_root.add_child(UiKit.gradient_bg())
	_root.add_child(UiKit.motes(Vector2(640, 360), Vector2(720, 430)))
	_root.add_child(UiKit.vignette())

	# 좌상단 뒤로가기 — 전 메뉴 공통 위치/스타일 (S6 통일)
	var back := UiKit.back_button(_on_back)
	_back_btn = back

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 전체화면 컨테이너가 바깥 클릭을 삼키지 않게
	_root.add_child(center)
	_root.add_child(back)  # center '다음'에 추가 — 위에 그려져 클릭을 확실히 받음 (M39 버그: 순서 반대라 클릭 무반응)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)   # 16차: 영웅 세 줄 자리
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	v.add_child(UiKit.title_band("출격 준비", 38))
	# 11/7: 골드 줄 오른쪽에 업보 한 줄(단계 · 골드 · 마지막 제약). 새 줄을 만들면 영어 잠긴 영웅 상세 판이 화면 아래로 13 넘었다.
	var gold_row := HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_row.add_theme_constant_override("separation", 28)
	v.add_child(gold_row)
	_gold_lbl = Label.new()
	UiFont.apply(_gold_lbl, 18)
	_gold_lbl.add_theme_color_override("font_color", UiKit.ACCENT)
	_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_row.add_child(_gold_lbl)
	_karma_lbl = Label.new()
	UiFont.apply(_karma_lbl, 16)
	_karma_lbl.add_theme_color_override("font_color", Color("d9a6ff"))
	_karma_lbl.visible = false
	gold_row.add_child(_karma_lbl)

	# ── 모드/스테이지 (S1): 무한 모드 or 스테이지 1~5 (이전 스테이지·이전 티어 클리어로 개방) ──
	var mode_row := HBoxContainer.new()
	mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_row.add_theme_constant_override("separation", 8)
	v.add_child(mode_row)
	_mode_row = mode_row
	_mode_pad = Control.new()
	_mode_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode_row.add_child(_mode_pad)
	var mode_names: Array = ["무한"]   # 16차: 「∞」 글꼴 기호 뺌
	for si in G.STAGE_NAMES.size():
		mode_names.append("%d %s" % [si + 1, I18n.t(String(G.STAGE_NAMES[si]))])
	for i in mode_names.size():
		var mb := _mini_button(String(mode_names[i]), Vector2(118, 40))
		UiFont.apply(mb, 15)
		var midx: int = i - 1  # -1=무한, 0~5=스테이지
		mb.pressed.connect(func() -> void: _set_mode(midx))
		mode_row.add_child(mb)
		_mode_btns.append(mb)

	# 난이도 (티어) — 스테이지 모드에선 이전 티어 클리어로 개방
	var diff_row := HBoxContainer.new()
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_row.add_theme_constant_override("separation", 8)
	v.add_child(diff_row)
	for i in G.DIFF_NAMES.size():
		var b := _mini_button(I18n.t(String(G.DIFF_NAMES[i])), Vector2(120, 40))
		var idx: int = i
		b.pressed.connect(func() -> void: _set_diff(idx))
		diff_row.add_child(b)
		_diff_btns.append(b)
	# 11/7 업보 단계 — 저승길(스테이지 6)을 한 번 깨면 난이도 줄 오른쪽에 나온다. 마우스를 올리면 걸린 제약 전부.
	_karma_box = HBoxContainer.new()
	_karma_box.add_theme_constant_override("separation", 4)
	diff_row.add_child(_karma_box)
	var kpad := Control.new()
	kpad.custom_minimum_size = Vector2(14, 0)
	_karma_box.add_child(kpad)
	var kl := Label.new()
	kl.text = I18n.t("업보")
	UiFont.apply(kl, 18)
	kl.add_theme_color_override("font_color", UiParts.BRASS_HI)
	_karma_box.add_child(kl)
	var kminus := _mini_button("-", Vector2(40, 40))
	kminus.pressed.connect(func() -> void: _set_karma(G.karma - 1))
	_karma_box.add_child(kminus)
	_karma_val = Label.new()
	UiFont.apply(_karma_val, 20)
	_karma_val.custom_minimum_size = Vector2(30, 0)
	_karma_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_karma_box.add_child(_karma_val)
	var kplus := _mini_button("+", Vector2(40, 40))
	kplus.pressed.connect(func() -> void: _set_karma(G.karma + 1))
	_karma_box.add_child(kplus)
	# 선택한 난이도 설명 (설정 화면과 동일 문구 — G.DIFF_DESC 공용) + 스테이지 보상/기록
	_diff_desc_lbl = Label.new()
	UiFont.apply(_diff_desc_lbl, 14)
	_diff_desc_lbl.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_diff_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_diff_desc_lbl)
	_update_diff_visual()

	# ── 13차 4절: 영웅 격자 + 고른 영웅 상세 ──
	# ★ 예전엔 영웅 카드 14장을 가로로 끌어야 다 보였고, 카드 안 설명이 폭을 넘어 세 줄로 접혔다.
	#   「▲ 780 G」가 등급 올리기인지 안 읽혔고, 아래 상세는 숫자 다섯 줄이었다(에셋 담당 검토).
	#   이제 끌기 없는 격자(7 × 2) · 고른 영웅만 오른쪽에 큰 그림 · 고유 능력 한 줄 · 시작 능력치 아이콘 줄 ·
	#   「★ 등급 올리기」와 「출격」 버튼(Vampire Survivors · HoloCure 영웅 고르기처럼).
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 14)
	main.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(main)
	var gpanel := UiKit.make_panel()
	gpanel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main.add_child(gpanel)
	_row = GridContainer.new()
	(_row as GridContainer).columns = 7
	_row.add_theme_constant_override("h_separation", 6)
	_row.add_theme_constant_override("v_separation", 6)
	gpanel.add_child(_row)

	var panel := UiKit.make_panel(UiKit.CYAN)
	panel.custom_minimum_size = Vector2(DETAIL_W, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main.add_child(panel)
	var dv := VBoxContainer.new()
	# 10/13 QA B13: 폰(UI 「크게」) 영어에서 능력 설명이 네 줄인 영웅(총잡이 · 깃소금 · 새디 · 갈덴)은 상세 판이 화면 아래로
	#   15~17px 밀렸다(--herofit). 폰에선 줄 사이를 좁힌다(판 안 5줄 × 4px + 이름 칸 2줄 × 4px).
	dv.add_theme_constant_override("separation", 4 if G.mobile else 8)
	panel.add_child(dv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	dv.add_child(top)
	_detail_port = CenterContainer.new()
	_detail_port.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_port.custom_minimum_size = Vector2(132, 132)
	top.add_child(_detail_port)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2 if G.mobile else 6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	_detail_name = Label.new()
	UiFont.apply(_detail_name, 24)
	_detail_name.add_theme_color_override("font_color", UiKit.CYAN)
	tv.add_child(_detail_name)
	_detail_rank = Label.new()
	UiFont.apply(_detail_rank, 20)
	_detail_rank.add_theme_color_override("font_color", UiKit.ACCENT)
	tv.add_child(_detail_rank)
	var ab := HBoxContainer.new()
	ab.add_theme_constant_override("separation", 6)
	tv.add_child(ab)
	_detail_icon = IconBadge.new().setup("regen", 26.0)
	ab.add_child(_detail_icon)
	_detail_abil = Label.new()
	UiFont.apply(_detail_abil, 16)
	_detail_abil.add_theme_color_override("font_color", UiKit.TEXT)
	_detail_abil.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_abil.custom_minimum_size = Vector2(ABIL_W, 0)
	_detail_abil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ab.add_child(_detail_abil)
	_detail_stats = HBoxContainer.new()
	_detail_stats.add_theme_constant_override("separation", 10)
	dv.add_child(_detail_stats)
	_detail_lbl = Label.new()
	UiFont.apply(_detail_lbl, 16)
	_detail_lbl.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_lbl.custom_minimum_size = Vector2(LBL_W, 0)
	_detail_lbl.size_flags_horizontal = Control.SIZE_FILL
	dv.add_child(_detail_lbl)
	_skin_row = HBoxContainer.new()
	_skin_row.add_theme_constant_override("separation", 8)
	_skin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_child(_skin_row)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 10)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_child(brow)
	_up_btn = UiKit.button("등급 올리기", func() -> void: _on_up_pressed())
	_up_btn.custom_minimum_size = Vector2(250, 56)
	brow.add_child(_up_btn)
	_go_btn = UiKit.button("출격", func() -> void: _on_go_pressed(), true)
	_go_btn.custom_minimum_size = Vector2(150, 56)
	brow.add_child(_go_btn)
	# 18차: 폰(UI 「크게」)에선 아래 안내 줄이 화면 아래로 9px 넘었다. 11/7: PC 1280×720 에서도 상세 판이 고정 폭으로
	#   꺾이며 16px 넘었다(--uifit) — 줄을 없애고 출격 단추에 마우스를 올리면 나오는 설명으로 옮겼다.
	_go_btn.tooltip_text = I18n.t("영웅을 누르면 상세 · 출격 버튼 또는 같은 영웅을 한 번 더 누르면 출격")

	_build_cards()


## 난이도 등 작은 테마 버튼 (다크+골드 톤)
func _mini_button(text: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	UiFont.apply(b, 17)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.125, 0.12, 0.16)
	n.set_corner_radius_all(9)
	n.set_border_width_all(2)
	n.border_color = Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.45)
	n.set_content_margin_all(8)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = Color(0.17, 0.15, 0.21)
	h.border_color = UiKit.ACCENT
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_color_override("font_color", UiKit.TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	return b


func _build_cards() -> void:
	for c in _row.get_children():
		c.queue_free()
	_card_btns.clear()
	for def: Dictionary in Characters.defs():
		_row.add_child(_make_card(def))
	_gold_lbl.text = I18n.t("보유 골드:  %d G") % G.total_gold
	if _detail_name != null:
		var keep: Dictionary = _def_by_id(_selected_id)
		_show_detail(keep if not keep.is_empty() else Characters.defs()[0])
	_apply_card_selection()


func _make_card(def: Dictionary) -> Button:
	var col: Color = def["color"]
	var id: String = String(def["id"])
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 134)   # 16차: 영웅 20 = 7 × 3 줄이 한 화면에 들게(152 → 134)
	btn.clip_contents = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.PANEL_FILL
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.35)
	sb.set_content_margin_all(4)
	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = Color(col.r * 0.18 + UiKit.PANEL_FILL.r, col.g * 0.18 + UiKit.PANEL_FILL.g, col.b * 0.18 + UiKit.PANEL_FILL.b, 0.97)
	hover.border_color = UiKit.ACCENT
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	UiParts.style_cell(btn, false)   # 14차: 부품 칸(파인 바닥) — 위 단색은 부품이 없을 때만
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 11/5: 글자를 9호(20)로 키우니 칸 맨 아래에 붙은 이름이 칸 테두리에 잘렸다 — 테두리 안쪽으로 띄운다
	vb.offset_top = 4.0
	vb.offset_bottom = -7.0
	vb.alignment = BoxContainer.ALIGNMENT_END
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)
	var unlocked: bool = G.char_unlocked(id)
	var pc := CenterContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var port := _portrait(def, 80.0)
	if not unlocked:
		port.modulate = Color(0.22, 0.22, 0.28)
		# 15차 6절 4: 실루엣에 올리면 해금 조건 한 줄(한지 툴팁). 폰은 누르면 상세 판에 같은 줄이 나온다.
		btn.tooltip_text = I18n.t(String((def.get("unlock", {}) as Dictionary).get("cond", "")))
		if G.is_demo() and not G.DEMO_HEROES.has(id):   # 19차 4-2: 체험판에서는 조건을 채워도 안 열린다
			btn.tooltip_text = I18n.t("정식판에서 만날 수 있어요")
	pc.add_child(port)
	vb.add_child(pc)
	var name_lbl := Label.new()
	name_lbl.text = I18n.t(String(SHORT.get(id, def["name"])))   # 14차: 격자에는 짧은 이름(마루 · 갈덴)
	UiFont.apply(name_lbl, 16)
	name_lbl.add_theme_color_override("font_color", col.lightened(0.28) if unlocked else Color(0.55, 0.55, 0.6))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.max_lines_visible = 2
	name_lbl.custom_minimum_size = Vector2(86, 0)
	vb.add_child(name_lbl)
	# 16차 U5: 「★3」 · 「잠김」 글자 → 별 · 자물쇠 12px + 숫자
	var rank_row := HBoxContainer.new()
	rank_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_row.add_theme_constant_override("separation", 3)
	rank_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rank_row.add_child(UiParts.icon("star_full" if unlocked else "lock", 12))
	var rank_lbl := Label.new()
	rank_lbl.text = str(G.char_rank(id)) if unlocked else I18n.t("잠김")
	UiFont.apply(rank_lbl, 16)
	rank_lbl.add_theme_color_override("font_color", UiKit.ACCENT if unlocked else UiKit.TEXT_DIM)
	rank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rank_row.add_child(rank_lbl)
	# 10/13 QA B2: 별 · 자물쇠 줄이 칸(134) 아래로 잘렸다(폰 6px · PC 2~4px, --herofit). 초상은 도트 정수배라 못 줄인다 —
	#   칸 오른쪽 위 모서리 배지로 옮긴다. 잠긴 영웅은 자물쇠만(어두운 실루엣 · 상세 판이 해금 조건을 말한다).
	if not unlocked:
		rank_lbl.visible = false
	var badge := PanelContainer.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.05, 0.03, 0.05, 0.78)
	bsb.set_corner_radius_all(3)
	bsb.content_margin_left = 4.0
	bsb.content_margin_right = 4.0
	bsb.content_margin_top = 0.0
	bsb.content_margin_bottom = 0.0
	badge.add_theme_stylebox_override("panel", bsb)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(rank_row)
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.offset_left = 0.0
	badge.offset_right = -4.0
	badge.offset_top = 4.0
	btn.add_child(badge)
	# ★ 모바일에서 목록 위에서 손가락을 끌다 떼면 그 영웅으로 판이 바로 시작됐다(실플레이 리포트). 끌면 취소되는 탭.
	# 13차: PC 도 같은 규칙 — 처음 누르면 상세, 고른 영웅을 한 번 더 누르면 출격(올려만 둬서는 안 바뀐다)
	UiKit.tap_only(btn, func() -> void: _tap(def))
	_card_btns[id] = btn
	return btn


## 격자 칸 짧은 이름 — 상세 판에는 원래 이름 그대로(14차 2절 12)
const SHORT: Dictionary = {"tank": "마루", "knight": "새디", "pyro": "베른", "mudang": "갈덴"}


## 다음 별 — 바뀌는 능력치만 아이콘 + 「▲」 한 줄(14차: 숫자 열두 개 대신)
func _next_star_row(def: Dictionary, rank: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var a: Dictionary = Characters.start_stats(def, rank)
	var b: Dictionary = Characters.start_stats(def, rank + 1)
	var hd := Label.new()
	hd.text = I18n.t("다음 별")
	UiFont.apply(hd, 20)
	hd.add_theme_color_override("font_color", UiParts.BRASS_HI)
	row.add_child(hd)
	row.add_child(UiParts.icon("star_full", 12))
	var hn := Label.new()
	hn.text = str(rank + 1)
	UiFont.apply(hn, 20)
	hn.add_theme_color_override("font_color", UiParts.BRASS_HI)
	row.add_child(hn)
	for st in [["dmg", "dmg"], ["hp", "hp"], ["spd", "speed"], ["armor", "armor"]]:
		if absf(float(b[st[0]]) - float(a[st[0]])) < 0.001:
			continue
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(_stat_icon(String(st[1])))
		var up := Label.new()
		up.text = "+"   # 16차: 「▲」 글꼴 기호 대신
		UiFont.apply(up, 20)
		up.add_theme_color_override("font_color", Color("9dff6b"))
		cell.add_child(up)
		row.add_child(cell)
	return row


## 능력치 줄 아이콘 — 16차 U6 12px(공격력 · 체력 · 이동 · 방어). 그림이 없으면 예전 배지.
const _U6: Dictionary = {"dmg": "attack", "hp": "hp", "speed": "move", "armor": "defense"}

func _stat_icon(id: String) -> Control:
	var u6: String = String(_U6.get(id, ""))
	if u6 != "" and UiParts.icon_tex(u6, 12) != null:
		var tr: TextureRect = UiParts.icon(u6, 12)
		tr.custom_minimum_size = Vector2(26, 26)
		return tr
	return IconBadge.new().setup(id, 26.0)


## 칸 폭을 넘는 이름은 마지막 띄어쓰기에서 줄을 바꾼다. ★ 자동 줄바꿈은 한글을 글자 사이에서도 끊어
##   「열두 마디 베 / 른」이 됐다.
func _wrap_name(t: String, w: float) -> String:
	var f: Font = UiFont.font_for(16)
	if f == null or f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, UiFont.px(16)).x <= w:
		return t
	var i: int = t.rfind(" ")
	return t if i < 0 else t.substr(0, i) + "
" + t.substr(i + 1)


func _portrait(def: Dictionary, sz: float) -> Control:
	var cf: String = CharForge.hero_id(String(def["id"]))
	if cf != "":
		return CharForge.figure(cf, "anchor", CharForge.scale_for(sz))
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(sz, sz)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cv := CreatureVisual.new()
	cv.body_color = def["color"]
	cv.radius = sz * 0.40
	cv.sides = 18
	cv.eye_scale = 1.15
	cv.feature = String(FEATURES.get(String(def["id"]), ""))
	var sp: String = String(def.get("sprite", ""))
	cv.sprite_path = sp  # 실제 스프라이트(없으면 도형)
	cv.sprite_hframes = Enemy._strip_frames(sp)  # 걷기 스트립이면 첫 프레임만 보이게 순환
	cv.always_animate = true  # UI 좌표라 카메라와의 '월드 거리'가 멀다 — 거리 컬링 대상이 아니다
	cv.position = Vector2(sz * 0.5, sz * 0.5)
	cv.build()
	holder.add_child(cv)
	return holder


func _rank_up(id: String) -> void:
	if G.char_rank_up(id):
		G.sfx("levelup", 1.1)
		_build_cards()
		for def: Dictionary in Characters.defs():
			if String(def["id"]) == id:
				_show_detail(def)
				break


## 골드로 캐릭터 즉시 해금 (S1)
func _buy_char(id: String) -> void:
	if G.try_buy_char(id):
		G.meta["ucn_" + id] = 1  # 이미 직접 해금 — 별도 알림 생략
		G.save_game()
		G.sfx("levelup", 1.25)
		_build_cards()


func _show_detail(def: Dictionary) -> void:
	var id: String = String(def["id"])
	_selected_id = id
	_apply_card_selection()
	var rank: int = G.char_rank(id)
	var unlocked: bool = G.char_unlocked(id)
	if _detail_port != null:
		for ch in _detail_port.get_children():
			ch.queue_free()
		var cf: String = CharForge.hero_id(id)
		var big: Control = CharForge.figure(cf, "anchor", 3) if cf != "" else _portrait(def, 120.0)
		if not unlocked:
			big.modulate = Color(0.22, 0.22, 0.28)
		_detail_port.add_child(big)
	_detail_name.text = I18n.t(String(def["name"]))
	_detail_rank.text = (I18n.t("등급 %d / %d") % [rank, G.CHAR_RANK_MAX]) if unlocked else I18n.t("잠김")
	_detail_icon.setup(String(def.get("icon", "regen")), 26.0)
	var abil: String = I18n.t(String(def["abil"]))
	if bool(def.get("special", false)):
		abil = I18n.t("특수 영웅 · ") + abil
	UiKit.set_wrapped(_detail_abil, abil, 16, false, ABIL_W)   # 11/5: 낱말 단위 · 고른 줄바꿈(엔진 자동 줄바꿈은 한글 낱말을 끊는다)
	# 시작 능력치 — 아이콘 + 숫자 한 줄(상점 강화 포함)
	for c in _detail_stats.get_children():
		c.queue_free()
	var now: Dictionary = Characters.start_stats(def, rank)
	for st in [["dmg", "%.1f" % float(now["dmg"])], ["hp", "%d" % int(now["hp"])], ["speed", "%d" % int(now["spd"])], ["armor", "%.1f" % float(now["armor"])]]:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		cell.add_child(_stat_icon(String(st[0])))
		var vl := Label.new()
		vl.text = String(st[1])
		UiFont.apply(vl, 20)
		vl.add_theme_color_override("font_color", UiKit.TEXT)
		cell.add_child(vl)
		_detail_stats.add_child(cell)
	var lines: Array = []
	if not unlocked:
		var u: Dictionary = def.get("unlock", {})
		if G.is_demo() and not G.DEMO_HEROES.has(id):
			lines.append(I18n.t("정식판에서 만날 수 있어요"))
		else:
			lines.append(I18n.t("해금 조건: %s  (또는 %d G로 바로 해금)") % [I18n.t(String(u.get("cond", "?"))), int(u.get("gold", 0))])
	if unlocked and G.karma_best(id) > 0:
		lines.append(I18n.t("업보 최고 %d단계") % G.karma_best(id))   # 11/7
	var m: Dictionary = def.get("mods", {})
	var parts: Array = []
	if m.has("damage_mult"):
		parts.append(I18n.t("공격력 x%.2f") % float(m["damage_mult"]))
	if m.has("fire_mult"):
		parts.append(I18n.t("공속 x%.2f(간격)") % float(m["fire_mult"]))
	if m.has("speed_mult"):
		parts.append(I18n.t("이속 x%.2f") % float(m["speed_mult"]))
	if m.has("bspeed_mult"):
		parts.append(I18n.t("탄속 x%.2f") % float(m["bspeed_mult"]))
	if m.has("hp_add"):
		parts.append(I18n.t("체력 %+d") % int(m["hp_add"]))
	if m.has("armor_add"):
		parts.append(I18n.t("방어 %+d") % int(m["armor_add"]))
	if m.has("magnet_add"):
		parts.append(I18n.t("자석 %+d") % int(m["magnet_add"]))
	if m.has("luck_add"):
		parts.append(I18n.t("행운 %+d%%") % int(round(float(m["luck_add"]) * 100.0)))
	if m.has("crit_add"):
		parts.append(I18n.t("치명 %+d%%") % int(round(float(m["crit_add"]) * 100.0)))
	if m.has("pierce_add"):
		parts.append(I18n.t("관통 %+d") % int(m["pierce_add"]))
	if m.has("proj_add"):
		parts.append(I18n.t("탄환 %+d") % int(m["proj_add"]))
	if m.has("xp_mult"):
		parts.append(I18n.t("경험치 x%.2f") % float(m["xp_mult"]))
	if not parts.is_empty():
		lines.append(I18n.t("기본치: ") + "  ·  ".join(parts))
	if _star_row != null:
		_star_row.queue_free()
		_star_row = null
	if unlocked and rank < G.CHAR_RANK_MAX:
		_star_row = _next_star_row(def, rank)
		_detail_lbl.get_parent().add_child(_star_row)
		_detail_lbl.get_parent().move_child(_star_row, _detail_lbl.get_index())
		# ★ 14차: 「몹 체력도 ×1.015 같이 오른다 → 순이득 ×1.008」은 개발자 계산이었다(에셋 담당) — 뺐다
	UiKit.set_wrapped(_detail_lbl, "\n".join(lines), 16, true, LBL_W)   # 「기본치: A · B」 줄이 「· B」 로 꺾이지 않게 항목 사이에서
	_build_skin_row(id, unlocked)
	# 버튼 — 해금이면 「★ 등급 올리기 N G」, 잠김이면 「즉시 해금 N G」. 출격은 해금일 때만
	if unlocked:
		if rank >= G.CHAR_RANK_MAX:
			_up_btn.text = I18n.t("등급 최대")
			_up_btn.disabled = true
		else:
			var cost: int = G.char_rank_cost(id)
			_up_btn.text = I18n.t("등급 올리기  %s G") % G.gold_str(cost)
			_up_btn.disabled = G.total_gold < cost
	else:
		var ucost: int = int((def.get("unlock", {}) as Dictionary).get("gold", 0))
		_up_btn.text = I18n.t("즉시 해금 %s G") % G.gold_str(ucost)
		_up_btn.disabled = G.total_gold < ucost
		if G.is_demo() and not G.DEMO_HEROES.has(id):
			_up_btn.text = I18n.t("정식판 영웅")
			_up_btn.disabled = true
	_go_btn.disabled = not unlocked
	_up_btn.icon = UiParts.icon_tex("star_full" if unlocked else "lock", 16)   # 16차 U5: 「★」 글자 자리
	_fit_up_btn()


## 「등급 올리기 / 즉시 해금 N G」 단추가 상세 판 폭을 넘지 않게 글자를 줄인다.
## ★ 11/7 --herofit: 영어 「Unlock now」 줄이 단추를 넓혀 잠긴 영웅에서 판이 화면 밖으로 20~40 밀렸다.
func _fit_up_btn() -> void:
	var room: float = LBL_W - _go_btn.custom_minimum_size.x - 10.0 - 60.0   # 출격 단추 · 사이 10 · 단추 안 여백과 아이콘
	var s: int = 24
	while s > 16 and UiFont.font_for(s).get_string_size(_up_btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiFont.px(s)).x > room:
		s -= 1
	UiFont.apply(_up_btn, s)


## 차림 고르기 — 그 영웅의 차림 그림이 있을 때만 줄이 생긴다. 잠긴 차림은 눌리지 않고 조건을 툴팁으로.
func _build_skin_row(id: String, hero_open: bool) -> void:
	if _skin_row == null:
		return
	for c in _skin_row.get_children():
		c.queue_free()
	if not CharForge.has_skin(id, "jeoseung"):
		_skin_row.visible = false
		return
	_skin_row.visible = true
	var hd := Label.new()
	hd.text = I18n.t("차림")
	UiFont.apply(hd, 20)
	hd.add_theme_color_override("font_color", UiParts.BRASS_HI)
	_skin_row.add_child(hd)
	var cur: String = G.hero_skin(id)
	for sk: String in ["", "jeoseung"]:
		var nm: String = I18n.t("기본") if sk == "" else I18n.t("저승길")
		var b := UiKit.button(nm, func() -> void:
			G.set_hero_skin(id, sk)
			G.sfx("pickup", 1.2)
			_build_cards())
		b.custom_minimum_size = Vector2(120, 44)
		UiFont.apply(b, 20)
		var open: bool = hero_open and G.skin_unlocked(sk)
		b.disabled = not open or sk == cur
		if not G.skin_unlocked(sk):
			b.tooltip_text = I18n.t("스테이지 6(저승길) 클리어로 열림")
		_skin_row.add_child(b)


func _on_up_pressed() -> void:
	if _selected_id == "":
		return
	if G.char_unlocked(_selected_id):
		_rank_up(_selected_id)
	else:
		_buy_char(_selected_id)
		_show_detail(_def_by_id(_selected_id))


func _on_go_pressed() -> void:
	var d: Dictionary = _def_by_id(_selected_id)
	if not d.is_empty() and G.char_unlocked(_selected_id):
		_commit_and_go(d)


## 격자 칸 탭 — 처음은 상세, 이미 고른 영웅이면 출격. (_pick 은 바로 출격 — 검사 하니스가 부른다)
func _tap(def: Dictionary) -> void:
	if _selected_id != String(def["id"]) or not G.char_unlocked(String(def["id"])):
		_show_detail(def)
		return
	_commit_and_go(def)


## 선택된 카드에 골드 보더 강조
func _apply_card_selection() -> void:
	for id: String in _card_btns.keys():
		var btn: Button = _card_btns[id]
		if not is_instance_valid(btn):
			continue
		if UiParts.style_cell(btn, id == _selected_id):
			continue
		var sb: StyleBoxFlat = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb == null:
			continue
		sb.set_border_width_all(3 if id == _selected_id else 2)
		sb.border_color = UiKit.ACCENT if id == _selected_id else Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.35)


func _def_by_id(id: String) -> Dictionary:
	for def: Dictionary in Characters.defs():
		if String(def["id"]) == id:
			return def
	return {}


func open() -> void:
	_root.visible = true
	UiKit.focus_first(_root)   # 패드로 메뉴를 넘길 시작점
	get_tree().paused = true
	_sel_mode = G.stage_sel if G.run_mode == "stage" else -1  # 현재 설정을 로컬로 복사 (감사 C5)
	_want_diff = clampi(G.diff_pref, 0, G.DIFF_MAX)
	_sel_diff = _want_diff
	# 10/13 QA: run_mode 는 저장하지 않아 켤 때마다 「무한」 탭으로 열렸다 — 처음 하는 사람은 30분짜리 무한 판으로 시작했다
	#   (대기 화면 문구는 「스테이지를 정복하고, 무한 모드에서 30분을 버텨라」). 이번 실행에서 아직 출격 전이면
	#   스테이지 탭, 지금 난이도에서 열린 가장 높은 스테이지로 연다. 한 번 고르면 그 실행 동안은 고른 대로.
	if not G.mode_chosen and _sel_mode < 0:
		_sel_mode = 0
		for i in G.STAGE_NAMES.size():
			if G.stage_unlocked(i, _sel_diff):
				_sel_mode = i
	# QA 10/13: 설정의 기본 난이도로 잠긴 단계가 들어올 수 있다 — 스테이지 단추와 같이 깰 수 있는 단계로 내린다
	while _sel_diff > 0 and not _diff_open(_sel_diff):   # 11/7: 무한 지옥 잠금도 같이
		_sel_diff -= 1
	_build_cards()
	_update_diff_visual()
	# 13차: 메인 메뉴 「출격」이 바로 여기로 온다 — 지난 판 영웅을 골라 둔 채로 연다
	var last: Dictionary = _def_by_id(G.last_char_id)
	if not last.is_empty() and G.char_unlocked(String(last["id"])):
		_show_detail(last)
	_clear_back_overlap()


## 10/13 QA B13: 탭 줄(무한 · 스테이지 1~6)은 가운데 정렬이라 영어처럼 길어지면 왼쪽 끝이 좌상단 「뒤로」 단추 밑으로
## 들어가 「Endless」 앞 글자가 가려졌고(19.5:9 폰), 16:9 폰 영어에서는 줄이 화면보다 넓었다(1286 > 1280, 「6 Underworld Road」 잘림).
## 연 뒤에 잰다. 겹치는 만큼 줄 맨 앞을 벌려도(가운데 정렬이라 두 배) 화면에 들어가면 그렇게 하고,
## 안 들어가면 스테이지 탭을 번호 + 별 · 자물쇠만 남긴다(고른 스테이지 이름은 바로 아래 설명 줄에 나온다).
func _clear_back_overlap() -> void:
	if _mode_pad == null or _back_btn == null or _mode_btns.is_empty() or _mode_row == null:
		return
	_mode_pad.custom_minimum_size.x = 0.0
	if _mode_compact:
		_mode_compact = false
		_update_diff_visual()
	await get_tree().process_frame
	await get_tree().process_frame
	var avail: float = _root.size.x
	var lim: float = _back_btn.get_global_rect().end.x + 8.0
	var row_w: float = _mode_row.get_combined_minimum_size().x
	var first: Control = _mode_btns[0] as Control
	var below: bool = first.get_global_rect().position.y >= _back_btn.get_global_rect().end.y
	var over: float = 0.0 if below else lim - (avail - row_w) * 0.5
	if row_w + 2.0 * maxf(over, 0.0) > avail - 8.0:
		_mode_compact = true
		_update_diff_visual()
		await get_tree().process_frame
		await get_tree().process_frame
		row_w = _mode_row.get_combined_minimum_size().x
		over = 0.0 if below else lim - (avail - row_w) * 0.5
	if over > 0.0:
		_mode_pad.custom_minimum_size.x = minf(over * 2.0, maxf(0.0, avail - 8.0 - row_w))


func is_open() -> bool:
	return _root != null and _root.visible


func _unhandled_input(event: InputEvent) -> void:  # ESC로 닫기 (S5)
	if is_open() and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):   # 16차: 패드 B 도 뒤로
		_on_back()
		get_viewport().set_input_as_handled()


## 뒤로가기 — 선택 없이 메인 메뉴로 (버튼 + 모바일 하드웨어 back 공용)
func _on_back() -> void:
	_root.visible = false
	closed.emit()


## 모드 선택: -1 무한 / 0~4 스테이지. 잠긴 스테이지는 무시. (로컬 선택만 — G 커밋은 _pick에서)
func _set_mode(m: int) -> void:
	if m >= 0:
		if not G.stage_unlocked(m, 0):  # 쉬움조차 잠김 = 이전 스테이지 미클리어
			G.sfx("hurt", 1.4, -10.0)
			return
		_sel_mode = m
		# 고른 난이도가 이 스테이지에서 잠겨 있으면 플레이 가능한 최고 티어로 내린다(이 판에만 — 고른 값은 그대로)
		_sel_diff = _want_diff
		while _sel_diff > 0 and not G.stage_unlocked(m, _sel_diff):
			_sel_diff -= 1
	else:
		_sel_mode = -1
		_sel_diff = _want_diff   # 무한 모드는 지옥만 잠금이 있다 — 스테이지 탭에서 내려갔던 걸 되돌린다
		while _sel_diff > 0 and not _diff_open(_sel_diff):
			_sel_diff -= 1
	_update_diff_visual()


## 이 모드 · 난이도가 열렸는가 — 스테이지는 앞 난이도 클리어, 무한 지옥은 어느 스테이지든 매우어려움 클리어.
func _diff_open(i: int) -> bool:
	if _sel_mode >= 0:
		return G.stage_unlocked(_sel_mode, i)
	return i < G.DIFF_MAX or G.hell_unlocked_any()


func _set_karma(k: int) -> void:
	G.karma = clampi(k, 0, G.KARMA_MAX)
	G.save_game()
	G.sfx("pickup", 1.0 + 0.04 * float(G.karma), -8.0)
	_update_diff_visual()


func _set_diff(i: int) -> void:
	if not _diff_open(i):
		G.sfx("hurt", 1.4, -10.0)  # 이전 티어 미클리어 → 잠김
		return
	if i != _sel_diff:   # 잠겨서 내려간 칸을 다시 누른 건 고른 게 아니다
		_want_diff = i
	_sel_diff = i
	_update_diff_visual()


func _update_diff_visual() -> void:
	var stage_mode: bool = _sel_mode >= 0
	# 모드 버튼: 선택 강조 + 잠금/클리어 상태 표기
	for i in _mode_btns.size():
		var mb: Button = _mode_btns[i]
		var midx: int = i - 1
		var selected: bool = (midx < 0 and not stage_mode) or (stage_mode and midx == _sel_mode)
		UiKit.tab(mb, selected)
		if midx < 0:
			# 11/14 무한 별: 스테이지 칸처럼 — 한 난이도라도 완주했으면 빈 별, 다섯 다 완주했으면 찬 별
			var eclr: int = 0
			for d in G.DIFF_MAX + 1:
				if G.endless_cleared(d):
					eclr += 1
			var eic: String = "" if eclr == 0 else ("star_empty" if eclr < G.DIFF_MAX + 1 else "star_full")
			mb.icon = UiParts.icon_tex(eic, 16) if eic != "" else null
			mb.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if midx >= 0:
			var open: bool = G.stage_unlocked(midx, 0)
			# 16차 U5: 「· 잠김」 · 「☆」 · 「★」 글자 → 자물쇠 · 빈 별(일부 클리어) · 찬 별(난이도 넷 다) 16px
			var ic: String = ""
			if not open:
				ic = "lock"
			else:
				var clears: int = 0
				for d in G.DIFF_MAX + 1:   # 11/7: 지옥까지 다섯 칸을 다 깨야 찬 별
					if G.stage_cleared(midx, d):
						clears += 1
				if clears > 0:
					ic = "star_empty" if clears < G.DIFF_MAX + 1 else "star_full"
			mb.text = ("%d" % (midx + 1)) if _mode_compact else "%d %s" % [midx + 1, I18n.t(String(G.STAGE_NAMES[midx]))]
			mb.icon = UiParts.icon_tex(ic, 16) if ic != "" else null
			mb.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			mb.disabled = not open
			if G.is_demo() and midx > 0:   # 19차 4-2: 체험판은 첫 스테이지만
				mb.tooltip_text = I18n.t("정식판에서 열려요")
	# 난이도 버튼: 스테이지 모드에선 이전 티어 클리어로 개방
	for i in _diff_btns.size():
		var b: Button = _diff_btns[i]
		var locked: bool = not _diff_open(i)
		b.disabled = locked
		b.text = I18n.t(String(G.DIFF_NAMES[i]))
		var clr: bool = G.stage_cleared(_sel_mode, i) if stage_mode else G.endless_cleared(i)   # 11/14: 무한도 완주한 난이도에 별
		var dic: String = "lock" if locked else ("star_full" if clr else "")
		b.icon = UiParts.icon_tex(dic, 16) if dic != "" else null
		b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		UiKit.choice(b, i == _sel_diff)
	if _diff_desc_lbl != null:
		var di: int = clampi(_sel_diff, 0, G.DIFF_MAX)
		var txt: String = I18n.t(String(G.DIFF_DESC[di]))
		if stage_mode:
			var gm: float = (1.0 + G.STAGE_GOLD_STEP * float(_sel_mode)) * [0.7, 1.0, 1.7, 2.6, 3.6][di]
			# [감사 C29] 이미 깬 조합엔 '첫 클리어 +NG' 거짓 약속 대신 클리어 표시
			var fc_txt: String = (I18n.t("클리어함 · 재도전") if G.stage_cleared(_sel_mode, di) else I18n.t("첫 클리어 +%dG") % G.first_clear_gold(_sel_mode, di))
			txt = I18n.t("STAGE %d %s · 8분 뒤 보스 처치 시 클리어 · 골드 ×%.1f · %s\n%s") % [
				_sel_mode + 1, I18n.t(String(G.STAGE_NAMES[_sel_mode])), gm, fc_txt, txt]
			# 11/5: 고른 난이도가 이 스테이지에서 아직 잠겨 내려갔으면 왜 다른 칸이 골라져 있는지 한 줄로
			if _sel_diff < _want_diff:
				txt = I18n.t("%s 난이도는 이 스테이지의 앞 난이도를 깨면 열려요") % I18n.t(String(G.DIFF_NAMES[_want_diff])) + "\n" + txt
		else:
			txt = _endless_line(di) + "\n" + txt
		# 11/7 업보: 한 줄만 더한다(단계 · 골드 · 마지막으로 더해진 제약). 전부는 업보 칸에 마우스를 올리면.
		var kon: bool = G.karma_unlocked()
		if _karma_box != null:
			_karma_box.visible = kon
			_karma_val.text = str(G.karma)
			var tip: PackedStringArray = [I18n.t("업보 %d단계 · 골드 +%d%%") % [G.karma, 12 * G.karma]]
			for si in G.karma:
				tip.append("%d. %s" % [si + 1, I18n.t(String(G.KARMA_STEPS[si]))])
			if G.karma < G.KARMA_MAX:
				tip.append(I18n.t("다음은 %s") % I18n.t(String(G.KARMA_STEPS[G.karma])))
			_karma_box.tooltip_text = "\n".join(tip)
		if _karma_lbl != null:
			_karma_lbl.visible = kon and G.karma > 0
			if _karma_lbl.visible:
				var kline: String = I18n.t("업보 %d단계 · 골드 +%d%% · %s") % [G.karma, 12 * G.karma, I18n.t(String(G.KARMA_STEPS[G.karma - 1]))]
				if G.karma > 1:
					kline += I18n.t(" 외 %d개") % (G.karma - 1)
				_karma_lbl.text = kline
		_diff_desc_lbl.text = txt
		_diff_desc_lbl.add_theme_color_override("font_color", DIFF_COLORS[di].lightened(0.2))


## 11/14 무한 기록 한 줄 — 스테이지 줄(「STAGE 1 … · 첫 클리어 +NG」)과 같은 자리 · 같은 길이로.
##   완주했으면 별 · 최종 보스 최단 · 무한 별 합, 아직이면 첫 완주 골드 · 가장 오래 버틴 시간.
##   ★ 이 줄은 자동 줄바꿈이 없어 길면 화면이 옆으로 늘어난다(11/7 영웅 화면 가로 넘침) — 항목을 넷 넘게 붙이지 말 것.
func _endless_line(d: int) -> String:
	var parts: PackedStringArray = []
	if G.endless_cleared(d):
		parts.append(I18n.t("무한 완주함"))
		parts.append(I18n.t("별 %d/3") % G.endless_stars(d))
		var bt: float = G.endless_best_boss(d)
		if bt > 0.0:
			parts.append(I18n.t("최종 보스 %02d:%02d") % [int(bt) / 60, int(bt) % 60])
	else:
		parts.append(I18n.t("무한 모드 · 30분 최종 보스까지 생존"))
		var fg: int = G.endless_first_gold(d)
		if fg > 0:
			parts.append(I18n.t("첫 완주 +%sG") % G.gold_str(fg))
		var bs: int = G.endless_best_time(d)
		if bs > 0:
			parts.append(I18n.t("최고 %02d:%02d") % [bs / 60, bs % 60])
	parts.append(I18n.t("무한 별 %d/%d") % [G.endless_star_total(), G.ENDLESS_STAR_MAX])
	return " · ".join(parts)


func _pick(def: Dictionary) -> void:
	if not G.char_unlocked(String(def["id"])):  # 잠금 캐릭터는 선택 불가 — 상세만 표시
		G.sfx("hurt", 1.4, -10.0)
		_show_detail(def)
		return
	_commit_and_go(def)


func _commit_and_go(def: Dictionary) -> void:
	# [감사 C5] 출격 시점에만 모드/스테이지/난이도를 G로 커밋
	if _sel_mode >= 0:
		G.run_mode = "stage"
		G.stage_sel = _sel_mode
	else:
		G.run_mode = "endless"
	G.mode_chosen = true
	G.difficulty = _sel_diff      # 이 판의 난이도
	G.diff_pref = _want_diff      # 저장하는 건 고른 값 — 잠겨서 내려간 값으로 설정을 덮지 않는다
	G.save_game()
	get_tree().paused = false
	_root.visible = false
	picked.emit(def)
