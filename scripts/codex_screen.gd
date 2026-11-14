class_name CodexScreen
extends CanvasLayer
## 도감 + 도전과제 화면 (UiKit). 탭: 몬스터 / 맵 / 융합 / 도전과제.
## main.gd가 open()/close() 호출, closed 시그널로 메인 메뉴 복귀.

signal closed

var _root: Control
var _content: VBoxContainer
var _tab: int = 0
var _tabs_row: HBoxContainer
var _progress_lbl: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 24
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_root.add_child(UiKit.gradient_bg())
	_root.add_child(UiKit.motes(Vector2(640, 360), Vector2(720, 430)))
	_root.add_child(UiKit.vignette())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	_root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	# ── 헤더: (좌상단 공통 뒤로 버튼 자리 비움) 제목 + 진행도 ──
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	# 10/13 QA B13: 폰은 뒤로 단추가 누르는 칸 높이(76)로 커져서 아래 탭 줄 첫 칸(「정복」)을 덮었다 — 머리 줄을 그만큼 띄운다
	if G.mobile:
		head.custom_minimum_size = Vector2(0, 64)
	col.add_child(head)
	var back_gap := Control.new()  # 좌상단 고정 '뒤로' 버튼과 겹치지 않게 띄움
	back_gap.custom_minimum_size = Vector2(150, 0)
	head.add_child(back_gap)
	head.add_child(UiKit.title_band("도감", 34))
	_progress_lbl = Label.new()
	UiFont.apply(_progress_lbl, 16)
	_progress_lbl.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_progress_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_progress_lbl)

	# ── 탭 ──
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 8)
	col.add_child(_tabs_row)
	var names: Array = ["정복", "몬스터", "맵", "융합", "도전과제", "퀘스트"]
	for i in names.size():
		var idx: int = i
		var tb := UiKit.button(String(names[i]), func() -> void: _switch(idx))
		tb.custom_minimum_size = Vector2(0, 50)  # UiKit 기본 330폭 해제 → 탭 균등 분배
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# 10/13 QA B13: 영어 탭 이름(Achievements …)이 칸 최소 폭을 밀어 탭 줄이 1422px — 16:9 폰에서 「Quests」 가 화면 밖.
		#   글자 폭이 칸 폭을 정하지 않게 하고(칸은 균등), 넘치면 글자를 줄인다
		tb.clip_text = true
		tb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_tabs_row.add_child(tb)
		# 칸 폭은 글자 길이에 비례해 나눈다 — 「Achievements」 처럼 긴 탭이 넓게, 「Maps」 는 좁게. 한글은 거의 균등.
		var tf: Font = tb.get_theme_font("font")
		var tw_need: float = tf.get_string_size(I18n.t(String(names[i])), HORIZONTAL_ALIGNMENT_LEFT, -1, tb.get_theme_font_size("font_size")).x if tf != null else 100.0
		tb.size_flags_stretch_ratio = tw_need + 48.0

	# ── 스크롤 콘텐츠 ──
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true   # 16차 4-5: 패드로 아래 칸에 포커스가 가면 화면도 따라 내려간다
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	scroll.add_child(UiKit.TouchScroll.new(scroll))  # 모바일 드래그 스크롤 (S2)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

	_root.add_child(UiKit.back_button(_on_close))  # 좌상단 고정 — 전 메뉴 공통 (S6 통일)


func open() -> void:
	_root.visible = true
	UiKit.focus_first(_root)   # 패드로 메뉴를 넘길 시작점
	get_tree().paused = true
	_switch(_tab)


func close() -> void:
	_root.visible = false


func is_open() -> bool:
	return _root != null and _root.visible


func _unhandled_input(event: InputEvent) -> void:  # ESC로 닫기 (S5)
	if is_open() and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):   # 16차: 패드 B 도 뒤로
		_on_close()
		get_viewport().set_input_as_handled()


func _on_close() -> void:
	close()
	closed.emit()


func _switch(t: int) -> void:
	_tab = t
	for i in _tabs_row.get_child_count():  # 선택 탭 강조
		var b := _tabs_row.get_child(i) as Button
		if b != null:
			UiKit.tab(b, i == t)
	for c in _content.get_children():
		c.queue_free()
	match t:
		0: _build_conquest()
		1: _build_monsters()
		2: _build_grid(Codex.MAPS, false)
		3: _build_fusions()
		4: _build_achievements()
		5: _build_quests()
	_refresh_progress()
	_refresh_quest_badge()


## 퀘스트 탭 버튼에 '받을 보상' 배지 — 어디서든 한눈에 (S5)
func _refresh_quest_badge() -> void:
	var qb := _tabs_row.get_child(5) as Button
	if qb == null:
		return
	var n: int = G.quest_claimable_count()
	qb.text = (I18n.t("퀘스트 (%d)") % n) if n > 0 else I18n.t("퀘스트")


## 반복 퀘스트 목록 (S5): 일일/주간/월간 섹션 + 진행바 + [받기] 버튼
func _build_quests() -> void:
	for period: String in ["daily", "weekly", "monthly"]:
		_content.add_child(UiKit.header(String(Codex.QUEST_PERIOD_NAMES[period]), UiKit.ACCENT, 20))
		for qd: Dictionary in Codex.QUESTS:
			if String(qd["period"]) != period:
				continue
			_content.add_child(_quest_row(qd))


func _quest_row(qd: Dictionary) -> Control:
	var e: Dictionary = G.quest_entry(qd)
	var p: int = int(e["p"])
	var need: int = int(qd["need"])
	var claimed: bool = bool(e["c"])
	var can: bool = not claimed and p >= need
	var panel := UiKit.make_panel(UiKit.ACCENT if can else (Color(0.35, 0.6, 0.35) if claimed else UiKit.PANEL_BORDER))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var nm := Label.new()
	nm.text = "%s:  %s" % [I18n.t(String(qd["name"])), I18n.t(String(qd["desc"]))]
	UiFont.apply(nm, 18)
	nm.add_theme_color_override("font_color", UiKit.TEXT if not claimed else UiKit.TEXT_DIM)
	info.add_child(nm)
	# 진행바
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.26, 0.24, 0.32, 1.0)   # 13차: 판과 같은 어두운 색이라 막대가 안 보였다
	bar_bg.custom_minimum_size = Vector2(0, 12)
	info.add_child(bar_bg)
	var fill := ColorRect.new()
	fill.color = Color("7dff9b") if p >= need else UiKit.CYAN
	fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fill.size_flags_horizontal = 0
	bar_bg.add_child(fill)
	fill.anchor_right = clampf(float(p) / float(need), 0.0, 1.0)
	fill.anchor_bottom = 1.0
	var prog := Label.new()
	prog.text = "%d / %d" % [p, need]
	UiFont.apply(prog, 13)
	prog.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	info.add_child(prog)
	# 보상/받기
	if claimed:
		var done := Label.new()
		done.text = "수령 완료"
		UiFont.apply(done, 16)
		done.add_theme_color_override("font_color", Color("9dff6b"))
		done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(done)
	else:
		var btn := UiKit.button(I18n.t("받기  +%dG") % int(qd["gold"]) if can else "+%dG" % int(qd["gold"]), func() -> void: _claim(String(qd["id"])), can, UiKit.ACCENT)
		btn.custom_minimum_size = Vector2(150, 48)
		UiFont.apply(btn, 17)
		btn.disabled = not can
		var bc := CenterContainer.new()
		bc.add_child(btn)
		row.add_child(bc)
	return panel


func _claim(id: String) -> void:
	var got: int = G.quest_claim(id)
	if got > 0:
		G.sfx("levelup", 1.25)
		_switch(5)  # 목록/배지 갱신


func _refresh_progress() -> void:
	match _tab:
		0: _progress_lbl.text = I18n.t("정복  %d / %d      별  %d / %d") % [G.cleared_count(), G.STAGE_NAMES.size() * 4, G.star_total(), G.STAGE_NAMES.size() * 12]
		1: _progress_lbl.text = I18n.t("수집  %d / %d") % [_seen(Codex.MONSTERS), Codex.MONSTERS.size()]
		2: _progress_lbl.text = I18n.t("방문  %d / %d") % [_seen(Codex.MAPS), Codex.MAPS.size()]
		3: _progress_lbl.text = I18n.t("융합  %d / %d") % [_seen(Codex.FUSIONS), Codex.FUSIONS.size()]
		4: _progress_lbl.text = I18n.t("달성  %d / %d") % [G.achievements.size(), Codex.ACHIEVEMENTS.size()]
		5:
			var n: int = G.quest_claimable_count()
			_progress_lbl.text = (I18n.t("받을 보상 %d개!") % n) if n > 0 else I18n.t("받을 보상 없음")


func _seen(list: Array) -> int:
	var n: int = 0
	for e: Dictionary in list:
		if G.codex.has(String(e["key"])):
			n += 1
	return n


## 정복 현황 — 스테이지 5 × 난이도 4 = 20칸을 한 화면에.
## ★ 예전엔 20조합의 진행을 한눈에 볼 곳이 없었다. 어디까지 깼는지, 어디에 별이 비었는지가
##   안 보이면 "다음에 뭘 하지"가 생기지 않는다. 이 표가 그 자리를 채운다.
func _build_conquest() -> void:
	var lead := Label.new()
	lead.text = "별은 클리어에 1개, 보스전 90초 이내에 1개, 60초 이내 + 보스전 무피격에 1개."
	UiFont.apply(lead, 14)
	lead.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(lead)

	for d in G.DIFF_MAX + 1:   # 11/7: 지옥 줄까지
		_content.add_child(UiKit.header(I18n.t(String(G.DIFF_NAMES[d])), _diff_color(d), 19))
		var row := GridContainer.new()
		row.columns = G.STAGE_NAMES.size()
		row.add_theme_constant_override("h_separation", 8)
		row.add_theme_constant_override("v_separation", 8)
		_content.add_child(row)
		for i in G.STAGE_NAMES.size():
			row.add_child(_conquest_cell(i, d))


const _DIFF_COLS: Array = ["62d162", "54c6ff", "ff9f43", "ff5a5a", "b44dff"]

func _diff_color(d: int) -> Color:
	return Color(String(_DIFF_COLS[clampi(d, 0, G.DIFF_MAX)]))


func _conquest_cell(i: int, d: int) -> Control:
	var cleared: bool = G.stage_cleared(i, d)
	var open: bool = G.stage_unlocked(i, d)
	var st: int = G.stage_stars(i, d)
	var col: Color = _diff_color(d) if cleared else (UiKit.PANEL_BORDER if open else Color(0.32, 0.32, 0.38))
	var panel := UiKit.make_panel(col)
	panel.custom_minimum_size = Vector2(196 if G.STAGE_NAMES.size() <= 5 else 164, 0)   # 16차: 스테이지 6 열
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # 10/13: 남는 폭을 칸이 나눠 갖는다(영어 이름이 「…」 로 잘리지 않게)
	# 16차: 큰 판 여백(모서리 장석 크기)이 칸마다 붙어 6열이 화면을 넘었다(영어 1316 > 1280) — 작은 판 · 여백 8
	var small: StyleBoxTexture = UiParts.box("panel_small", 2, 0, 8.0)
	if small != null:
		panel.add_theme_stylebox_override("panel", small)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)
	_cq_lbl(vb, I18n.t(String(G.STAGE_NAMES[i])), 17, col.lightened(0.2) if cleared else UiKit.TEXT_DIM)
	# 16차 U5: 「★☆」 글자 → 별 그림, 「잠김」 앞 자물쇠(13차 도감 · 정복 줄)
	if cleared:
		vb.add_child(UiParts.stars(st, 3, 12))
	elif not open:
		var lk := HBoxContainer.new()
		lk.alignment = BoxContainer.ALIGNMENT_CENTER
		lk.add_theme_constant_override("separation", 4)
		lk.add_child(UiParts.icon("lock", 12))
		_cq_lbl(lk, I18n.t("잠김"), 18, UiKit.TEXT_DIM)
		vb.add_child(lk)
	else:
		_cq_lbl(vb, I18n.t("미클리어"), 18, UiKit.TEXT_DIM)
	if cleared:
		var bt: float = G.stage_best_time(i, d)
		var kb: int = G.stage_best_kills(i, d)
		_cq_lbl(vb, I18n.t("최단 보스전 %02d:%02d") % [int(bt) / 60, int(bt) % 60], 12, UiKit.TEXT_DIM)
		_cq_lbl(vb, I18n.t("최다 처치 %s") % G.gold_str(kb), 12, UiKit.TEXT_DIM)
	return panel


func _cq_lbl(parent: Node, text: String, size: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	UiFont.apply(l, size)
	# 16차: 스테이지 6 열이라 칸이 좁아졌다(196 → 164) — 영어 「Fastest boss fight 00:00」 이 칸을 밀었다(uifit 1316 > 1280)
	UiKit.fit_font(l, 146.0, size)
	# 10/13 QA B13: 폰은 글자가 18 밑으로 안 줄어서(UiFont.step) fit_font 가 못 줄였다 — 16:9 폰 영어에서 첫 줄이 화면 밖.
	#   글자가 칸을 밀지 못하게: 칸 폭(164)이 기준이고 넘치는 글자는 「…」
	if parent is VBoxContainer:   # 자물쇠 줄(HBox) 안 글자는 그대로 — 거기서 최소 폭을 없애면 글자가 사라진다
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.custom_minimum_size = Vector2(1, 0)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)


## 도감 그리드 (몬스터=스프라이트 / 맵·융합=심볼 카드). 미해금은 실루엣+???.
func _build_grid(list: Array, is_monster: bool) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(grid)
	for e: Dictionary in list:
		grid.add_child(_entry_card(e, is_monster))


func _entry_card(e: Dictionary, is_monster: bool) -> Control:
	var unlocked: bool = G.codex.has(String(e["key"]))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 172)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.14, 0.96)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = UiKit.ACCENT if unlocked else Color(0.3, 0.3, 0.36, 1.0)
	sb.set_content_margin_all(10)
	var cb0: StyleBoxTexture = UiParts.cell_box(false, 10.0)
	panel.add_theme_stylebox_override("panel", cb0 if cb0 != null else sb)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	# 아이콘/스프라이트 (중앙)
	var iconholder := CenterContainer.new()
	iconholder.custom_minimum_size = Vector2(0, 76)
	v.add_child(iconholder)
	if is_monster and String(e.get("sprite", "")) != "" and ResourceLoader.exists(String(e["sprite"])):
		var tr := TextureRect.new()
		tr.texture = _mon_tex(e)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(72, 72)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.modulate = Color(1, 1, 1, 1) if unlocked else Color(0, 0, 0, 0.85)  # 미해금=검은 실루엣
		iconholder.add_child(tr)
	elif String(e["key"]).begins_with("map_"):
		# 14차 2절 14: 맵은 그 바닥 타일 썸네일(64)
		var mt: Control = _map_thumb(int(String(e["key"]).substr(4)), 64)
		if not unlocked:
			mt.modulate = Color(0.15, 0.15, 0.18)
		iconholder.add_child(mt)
	else:
		var badge := IconBadge.new()
		var bid: String = _symbol_id(e)
		badge.setup(bid if unlocked else "chest", 62.0, Color(0.4, 0.4, 0.46, 1.0) if not unlocked else Color(0, 0, 0, 0))
		iconholder.add_child(badge)

	# 융합 레시피 3단계 표기 (M37): 완성=상세+재료 / 공개 레시피=이름+재료만 / 숨김=???
	var is_fusion: bool = String(e["key"]).begins_with("fus_")
	var recipe_open: bool = bool(e.get("open", false))
	var name_txt: String = I18n.t(String(e["name"])) if (unlocked or (is_fusion and recipe_open)) else "???"
	var desc_txt: String = I18n.t("아직 발견하지 못했습니다.")
	if unlocked:
		desc_txt = I18n.t(String(e["desc"]))
		if is_fusion and String(e.get("mats", "")) != "":
			desc_txt = I18n.t("조합: %s\n%s") % [I18n.t(String(e["mats"])), desc_txt]
	elif is_fusion:
		if recipe_open:
			desc_txt = I18n.t("조합: %s\n(아직 완성하지 못했습니다)") % I18n.t(String(e["mats"]))
		else:
			desc_txt = "직접 조합해서 발견하세요."

	var name_lbl := Label.new()
	name_lbl.text = name_txt
	UiFont.apply(name_lbl, 16)
	name_lbl.add_theme_color_override("font_color", UiKit.TEXT if unlocked else UiKit.TEXT_DIM)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_lbl)

	if is_fusion:
		var lk: String = _fusion_locked(String(e["key"]))
		if lk != "":
			desc_txt += "
" + lk  # 왜 못 만드는지 — 예전엔 조합만 보이고 이유가 없었다
	var desc := Label.new()
	desc.text = UiKit.wrap_words(desc_txt, 12, 230.0)   # 14차: 낱말 단위로만 꺾는다(「XP 대 / 폭↑」)
	UiFont.apply(desc, 12)
	desc.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	return panel


## ── 13차 몬스터 탭: 정사각 칸 격자 + 고른 몹 상세 ──
## ★ 예전엔 카드가 크고 설명 두 줄이 작았고, 그림이 소수 배율(2.08 · 2.51 …)로 늘어 흐렸다(에셋 담당 검토 · 9차 전수).
##   칸은 그림을 정수배로만 — 몹은 서 있는 그림 ×1(키 28~52), 보스는 큰 얼굴(portrait_big)의 얼굴 칸 64×64.
const MON_CELL: float = 76.0
var _mon_detail: VBoxContainer

func _build_monsters() -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	_content.add_child(hb)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	hb.add_child(grid)
	var dp := UiKit.make_panel(UiKit.CYAN)
	dp.custom_minimum_size = Vector2(340, 0)
	dp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # 11/5: 오른쪽에 남던 빈 폭까지 설명 판으로 쓴다(글자를 키운 만큼 줄이 덜 꺾인다)
	hb.add_child(dp)
	_mon_detail = VBoxContainer.new()
	_mon_detail.add_theme_constant_override("separation", 8)
	dp.add_child(_mon_detail)
	var first: Dictionary = {}
	for e: Dictionary in Codex.MONSTERS:
		grid.add_child(_mon_cell(e))
		if first.is_empty() and G.codex.has(String(e["key"])):
			first = e
	_mon_show(first if not first.is_empty() else (Codex.MONSTERS[0] as Dictionary))


## 칸 안 그림 — ★ 14차: 보스는 큰 얼굴을 잘라 칸을 꽉 채우고 잡몹은 손톱만 했다(한 격자에 규칙이 둘).
##   이제 칸마다 같은 규칙: 그림을 칸(64) 안에 들어가는 가장 큰 정수배로. 보스는 portrait(128×120)를 정확히 반으로.
##   big = 상세 판 — 잡몹 서 있는 그림 ×3, 보스 portrait ×1.
func _mon_icon(e: Dictionary, big: bool) -> Control:
	var key: String = String(e.get("key", ""))
	var cf: String = CharForge.enemy_id(int(key.substr(4))) if key.begins_with("mon_") else ""
	var tex: Texture2D = null
	var k: float = 1.0
	if cf != "":
		var nh: float = float(CharForge.info(cf).get("native_h", 40.0))
		if nh > 90.0 and CharForge.has_anim(cf, "portrait"):
			tex = CharForge.frame_tex(cf, "portrait")
			if not big and tex != null:
				var img: Image = tex.get_image()
				if img != null:
					img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_NEAREST)
					tex = ImageTexture.create_from_image(img)
		else:
			tex = CharForge.frame_tex(cf, "anchor")
			if tex != null:
				var lim: float = 140.0 if big else 64.0
				k = 3.0 if big else maxf(1.0, floorf(lim / float(maxi(tex.get_width(), tex.get_height()))))
				if big and float(maxi(tex.get_width(), tex.get_height())) * 3.0 > 168.0:
					k = 2.0
	if tex == null:
		tex = _mon_tex(e)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var sz: Vector2 = (tex.get_size() * k) if tex != null else Vector2(64, 64)
	# ★ 14차: 옛 그림(_mon_tex)이나 큰 잡몹은 ×1 이어도 칸(64)보다 커서 이웃 칸까지 덮었다 — 정수로 나눠 칸 안에
	var cap: float = 168.0 if big else 64.0
	if maxf(sz.x, sz.y) > cap:
		sz /= ceilf(maxf(sz.x, sz.y) / cap)
	tr.custom_minimum_size = sz.floor()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _mon_cell(e: Dictionary) -> Control:
	var unlocked: bool = G.codex.has(String(e["key"]))
	var b := Button.new()
	b.custom_minimum_size = Vector2(MON_CELL, MON_CELL)
	b.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.14, 0.96)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(2)
	sb.border_color = Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.5 if unlocked else 0.2)
	var sh: StyleBoxFlat = sb.duplicate()
	sh.border_color = UiKit.ACCENT
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	b.add_theme_stylebox_override("focus", sh)
	UiParts.style_cell(b, false)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cc)
	var ic: Control = _mon_icon(e, false)
	if not unlocked:
		ic.modulate = Color(0, 0, 0, 0.85)   # 미발견 = 검은 실루엣
	cc.add_child(ic)
	b.pressed.connect(func() -> void: _mon_show(e))
	return b


func _mon_show(e: Dictionary) -> void:
	if _mon_detail == null:
		return
	for c in _mon_detail.get_children():
		c.queue_free()
	var unlocked: bool = G.codex.has(String(e["key"]))
	var cc := CenterContainer.new()
	cc.custom_minimum_size = Vector2(0, 200)
	_mon_detail.add_child(cc)
	var ic: Control = _mon_icon(e, true)
	if not unlocked:
		ic.modulate = Color(0, 0, 0, 0.85)
	cc.add_child(ic)
	var nm := Label.new()
	nm.text = I18n.t(String(e["name"])) if unlocked else "???"
	UiFont.apply(nm, 24)
	nm.add_theme_color_override("font_color", UiKit.TEXT if unlocked else UiKit.TEXT_DIM)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mon_detail.add_child(nm)
	# 16차: 「◆특수」 · 「◆이면」을 이름에서 떼어 배지로(글꼴 기호 빼기)
	var tag: String = String(e.get("tag", ""))
	if unlocked and tag != "":
		var tb := CenterContainer.new()
		tb.add_child(UiParts.badge(I18n.t(tag), 16))
		_mon_detail.add_child(tb)
	# 14차: 처치 수 · 나오는 맵(맵 바닥 썸네일)
	if unlocked:
		var kc := Label.new()
		kc.text = I18n.t("처치 %s") % G.gold_str(int(G.stats.get("mk_" + String(e["key"]).substr(4), 0)))
		UiFont.apply(kc, 20)
		kc.add_theme_color_override("font_color", UiParts.BRASS_HI)
		kc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_mon_detail.add_child(kc)
		var maps := HBoxContainer.new()
		maps.alignment = BoxContainer.ALIGNMENT_CENTER
		maps.add_theme_constant_override("separation", 6)
		for mi in _mon_maps(int(String(e["key"]).substr(4))):
			maps.add_child(_map_thumb(mi, 32))
		_mon_detail.add_child(maps)
	var ds := Label.new()
	UiFont.apply(ds, 16)
	ds.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	ds.custom_minimum_size = Vector2(320, 0)
	ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mon_detail.add_child(ds)
	# 11/5: 엔진 자동 줄바꿈이 「갈라진 / 다」처럼 낱말 가운데를 끊었다 — 낱말 단위 · 고른 줄바꿈
	UiKit.set_wrapped(ds, String(e["desc"]) if unlocked else "아직 발견하지 못했습니다.", 16)


## 이 몹이 나오는 맵(테마 몹 풀 · 특수 · 요괴 · 스테이지 보스) — 메인의 표를 읽는다.
func _mon_maps(kind: int) -> Array:
	var main := get_tree().current_scene
	var out: Array = []
	if main == null:
		return out
	if kind >= 29:   # 16차: 저승길 몹 · 판관 · 염라는 저승길에만(행동 틀 kind 는 다른 맵 몹이라 표로는 못 찾는다)
		return [5]
	for th in 5:
		var hit: bool = false
		for nm in ["_THEME_KINDS", "_THEME_YOKAI"]:
			var arr: Variant = main.get(nm)
			if arr is Array and th < (arr as Array).size() and kind in ((arr as Array)[th] as Array):
				hit = true
		var sp: Variant = main.get("_THEME_SPECIAL")
		if sp is Array and th < (sp as Array).size() and int((sp as Array)[th]) == kind:
			hit = true
		var sb: Variant = main.get("STAGE_BOSS")
		if sb is Array and th < (sb as Array).size() and int((sb as Array)[th]) == kind:
			hit = true
		if hit:
			out.append(th)
	return out


## 맵 썸네일 — 그 맵 바닥 타일(이미 있는 그림)을 정수배로 잘라 칸에(14차 2절 14).
const _MAP_TILES: Array = ["dungeon", "library", "garden", "lava", "heaven", "jeoseung"]

func _map_thumb(th: int, sz: int) -> Control:
	var p: String = "res://assets/sprites/tiles/%s_ground.png" % String(_MAP_TILES[clampi(th, 0, _MAP_TILES.size() - 1)])
	var holder := PanelContainer.new()
	var cb: StyleBoxTexture = UiParts.cell_box(false, 2.0)
	if cb != null:
		holder.add_theme_stylebox_override("panel", cb)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(p):
		var at := AtlasTexture.new()
		at.atlas = load(p)
		at.region = Rect2(0, 0, sz, sz)
		var tr := TextureRect.new()
		tr.texture = at
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(sz, sz)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
	return holder


## ── 13차 융합 탭: 재료 아이콘 + 재료 아이콘 = 결과 아이콘 (Vampire Survivors 진화표처럼) ──
## 고른 줄의 설명은 아래 판에. 문장 네 줄 카드는 뺐다.
var _fus_detail: Label

func _build_fusions() -> void:
	var main := get_tree().current_scene
	var evos: Array = main.get("EVOLUTIONS") if main != null and main.get("EVOLUTIONS") is Array else []
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	var gc := CenterContainer.new()
	gc.add_child(grid)
	_content.add_child(gc)
	_fus_detail = Label.new()
	UiFont.apply(_fus_detail, 16)
	_fus_detail.add_theme_color_override("font_color", UiKit.TEXT)
	_fus_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fus_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fus_detail.custom_minimum_size = Vector2(900, 72)
	_content.add_child(_fus_detail)
	for fe: Dictionary in Codex.FUSIONS:
		var eid: String = String(fe["key"]).trim_prefix("fus_")
		var reqs: Array = []
		for ev: Dictionary in evos:
			if String(ev["id"]) == eid:
				reqs = ev["req"] as Array
		grid.add_child(_fus_row(fe, eid, reqs))
	UiKit.set_wrapped(_fus_detail, "줄을 누르면 설명이 나옵니다", 16)


func _fus_row(fe: Dictionary, eid: String, reqs: Array) -> Control:
	var done: bool = G.codex.has(String(fe["key"]))
	var known: bool = done or bool(fe.get("open", false))
	var b := Button.new()
	b.custom_minimum_size = Vector2(440, 56)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.14, 0.96)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(2)
	sb.border_color = UiKit.ACCENT if done else Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.3)
	var sh: StyleBoxFlat = sb.duplicate()
	sh.border_color = UiKit.CYAN
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	b.add_theme_stylebox_override("focus", sh)
	UiParts.style_cell(b, done)
	var hb := HBoxContainer.new()
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10
	hb.add_theme_constant_override("separation", 6)
	hb.alignment = BoxContainer.ALIGNMENT_BEGIN
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(hb)
	for i in reqs.size():
		if i > 0:
			hb.add_child(_sym("+"))
		var rb := IconBadge.new().setup(String(reqs[i]) if known else "chest", 40.0)
		rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(rb)
	hb.add_child(_sym("="))
	var eb := IconBadge.new().setup(eid if known else "chest", 40.0)
	eb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not done:
		eb.modulate = Color(0.5, 0.5, 0.55)
	hb.add_child(eb)
	var nl := Label.new()
	nl.text = I18n.t(String(fe["name"])) if known else "???"
	UiFont.apply(nl, 20)
	nl.add_theme_color_override("font_color", Color("ffd54a") if done else UiKit.TEXT_DIM)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(nl)
	b.pressed.connect(func() -> void:
		var t: String = I18n.t(String(fe["desc"])) if done else (I18n.t("조합: %s\n(아직 완성하지 못했습니다)") % I18n.t(String(fe.get("mats", ""))) if known else I18n.t("직접 조합해서 발견하세요."))
		var lk: String = _fusion_locked(String(fe["key"]))
		UiKit.set_wrapped(_fus_detail, t + (("\n" + lk) if lk != "" else ""), 16))
	return b


func _sym(t: String) -> Label:
	var l := Label.new()
	l.text = t
	UiFont.apply(l, 24)
	l.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 융합/맵 카드 심볼 id (IconBadge용) — 융합은 evo_ 아이디로 금별.
## [감사 C28] 발견한 맵은 미발견 '상자'와 구분되는 테마 심볼 (석벽/지식/생명/불꽃/천상)
const _MAP_SYMBOLS: Dictionary = {
	"map_0": "armor", "map_1": "xp_gain", "map_2": "regen", "map_3": "wpn_fire", "map_4": "l_timewarp",
}
func _symbol_id(e: Dictionary) -> String:
	var key: String = String(e["key"])
	if key.begins_with("fus_"):
		return key.substr(4)  # "evo_..." → 금별
	if key.begins_with("map_"):
		return String(_MAP_SYMBOLS.get(key, "chest"))
	return "chest"


## 이 융합에 필요한 무기 중 아직 잠긴 것 — 도감에서 "왜 못 만드나"를 알려주기 위해.
func _fusion_locked(key: String) -> String:
	var eid: String = key.trim_prefix("fus_")
	var main := get_tree().current_scene
	if main == null or not (main.get("EVOLUTIONS") is Array):
		return ""
	for e: Dictionary in (main.get("EVOLUTIONS") as Array):
		if String(e["id"]) != eid:
			continue
		var need: PackedStringArray = []
		for r: String in (e["req"] as Array):
			if G.WPN_UNLOCKS.has(r) and not G.wpn_unlocked(r):
				need.append(I18n.t(String((G.WPN_UNLOCKS[r] as Dictionary)["name"])))
		if not need.is_empty():
			return I18n.t("%s 해금 필요") % ", ".join(need)
	return ""


## 걷기 스트립이면 첫 프레임만 잘라서 표시.
## ★ 프레임 수를 도감 항목에 손으로 적어 두면 자산을 다시 구울 때마다 어긋난다 —
##   Enemy 와 같은 판정(가로가 세로의 정확히 4배면 스트립)을 그대로 쓴다.
func _mon_tex(e: Dictionary) -> Texture2D:
	# 캐릭터 에셋 자리면 그 정지 자세 한 칸
	var key: String = String(e.get("key", ""))
	if key.begins_with("mon_"):
		var cf: String = CharForge.enemy_id(int(key.substr(4)))
		if cf != "":
			return CharForge.frame_tex(cf, "anchor")
	var path: String = String(e["sprite"])
	var tex: Texture2D = load(path)
	var hf: int = int(e.get("hframes", Enemy._strip_frames(path)))
	if hf > 1 and tex != null:
		var at := AtlasTexture.new()
		at.atlas = tex
		var fw: float = float(tex.get_width()) / float(hf)
		at.region = Rect2(0, 0, fw, tex.get_height())
		return at
	return tex


## 도전과제 목록 (달성/미달성 + 진행도 + 보상).
func _build_achievements() -> void:
	for a: Dictionary in Codex.ACHIEVEMENTS:
		var done: bool = G.achievements.has(String(a["id"]))
		var cur: int = int(G.stats.get(String(a["stat"]), 0))
		var need: int = G.ach_need(a)   # QA 10/13: -1 · -2 · -3 자리표가 그대로 찍혔다
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.11, 0.08, 0.96) if done else Color(0.10, 0.10, 0.13, 0.94)
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(2)
		sb.border_color = UiKit.ACCENT if done else Color(0.28, 0.28, 0.34, 1.0)
		sb.set_content_margin_all(12)
		row.add_theme_stylebox_override("panel", sb)
		# 16차: 도전과제 줄만 매끈한 단색 판(StyleBoxFlat)으로 남아 있었다(--artaudit) — 다른 칸과 같은 옻칠 작은 판
		var ps: StyleBoxTexture = UiParts.box("panel_small", 2, 0, 12.0)
		if ps != null:
			row.add_theme_stylebox_override("panel", ps)
			row.modulate = Color.WHITE if done else Color(0.78, 0.76, 0.80)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		row.add_child(h)
		# 16차: 「★」 「☆」 글자 대신 스팀 도전과제 그림(획득 · 미획득, 32 그림 ×2 = 64) — 스팀 화면과 같은 그림
		var ap: String = "res://assets/ui/achievements/%s%s.png" % [String(a["id"]), "" if done else "_locked"]
		if ResourceLoader.exists(ap):
			var art := TextureRect.new()
			art.texture = load(ap)
			art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			art.custom_minimum_size = Vector2(64, 64)
			art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(art)
		else:
			h.add_child(UiParts.icon("check" if done else "lock", 16))
		var txt := VBoxContainer.new()
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(txt)
		var nm := Label.new()
		nm.text = String(a["name"])
		UiFont.apply(nm, 19)
		nm.add_theme_color_override("font_color", UiKit.TEXT if done else Color(0.8, 0.8, 0.86))
		txt.add_child(nm)
		var ds := Label.new()
		var prog: String = "" if done else "   (%d / %d)" % [mini(cur, need), need]
		ds.text = I18n.t(String(a["desc"])) + prog
		UiFont.apply(ds, 14)
		ds.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		txt.add_child(ds)
		# 10/13: 딴 것과 못 딴 것이 그림 밝기로만 갈렸다 — 딴 줄은 오른쪽에 「✓ 달성」 을 붙인다
		if done:
			var dn := HBoxContainer.new()
			dn.add_theme_constant_override("separation", 4)
			dn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			dn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dn.add_child(UiParts.icon("check", 16))
			var dl := Label.new()
			dl.text = I18n.t("달성")
			UiFont.apply(dl, 18)
			dl.add_theme_color_override("font_color", Color("8ee07a"))
			dn.add_child(dl)
			h.add_child(dn)
		var reward := Label.new()
		reward.text = "+%d G" % int(a.get("gold", 0))
		UiFont.apply(reward, 18)
		reward.add_theme_color_override("font_color", UiKit.ACCENT if done else UiKit.TEXT_DIM)
		reward.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(reward)
		_content.add_child(row)
