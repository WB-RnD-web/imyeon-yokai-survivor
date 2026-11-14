class_name MetaShop
extends CanvasLayer
## 상점: 모은 골드로 영구 업글(메타). 초반 저렴, 레벨↑마다 극악. user:// 저장.
## 상단에 현재 전체 능력치 표시. 닫으면 메인 메뉴로 복귀(closed).

signal closed

## 항목 정의는 이름/아이콘만 여기 있고, 상한·레벨당 수치·가격은 전부 G.META_TIERS 가 정한다.
## (예전엔 base/max/desc 가 여기 박혀 있어서 실제 효과와 표기가 따로 놀 수 있었다)
const META: Array = [
	{"id": "m_hp", "name": "최대 체력", "icon": "hp"},
	{"id": "m_dmg", "name": "공격력", "icon": "dmg"},
	{"id": "m_speed", "name": "이동속도", "icon": "speed"},
	{"id": "m_magnet", "name": "자석 범위", "icon": "item_magnet"},
	{"id": "m_luck", "name": "행운", "icon": "luck"},
	{"id": "m_regen", "name": "체력 재생", "icon": "regen"},
	{"id": "m_gold", "name": "골드 획득", "icon": "gamble"},
	{"id": "m_reroll", "name": "시작 리롤", "icon": "bigxp"},
	{"id": "m_banish", "name": "봉인", "icon": "b_exec"},   # 14차 3절 4 — 레벨업 카드를 이번 판에서 영원히 빼는 횟수
]


## "레벨당 +3%" 처럼 사람이 읽는 문구. 수치는 G.META_TIERS 에서만 온다.
static func per_text(id: String) -> String:
	var per: float = G.meta_per(id)
	match id:
		"m_hp":
			return "+%d / Lv" % int(round(per))
		"m_dmg":
			# ★ "+3% / Lv" 였다. 3%가 무엇에 붙는 3%인지 안 알려준다 — 기준 공격력 14 면 +0.4다.
			return "+%.1f / Lv" % (Player.BULLET_DMG * per)
		"m_gold":
			return "+%d%% / Lv" % int(round(per * 100.0))
		"m_speed":
			return "+%.0f / Lv" % (Player.SPEED * per)
		"m_luck":
			return "+%.1f%% / Lv" % (per * 100.0)
		"m_magnet":
			return "+%d / Lv" % int(round(per))
		"m_regen":
			return "+%.2f/s / Lv" % per
		"m_reroll":
			return I18n.t("리롤 +%d / Lv") % int(round(per))
		"m_banish":
			return I18n.t("봉인 +%d / Lv") % int(round(per))
	return ""

var _root: Control
var _gold_lbl: Label
var _stats_lbl: Label
var _grid: GridContainer
var _detail: PanelContainer    # 13차: 고른 강화 하나의 설명 · 다음 효과 · 가격 · 사기
var _sel: String = "m_hp"
var _wpn_row: GridContainer  # 특수무기 해금 카드 격자 (S1, S8에서 7장으로 늘어 접음)
var _scroll: ScrollContainer  # 구매할 때마다 목록을 다시 그리므로 스크롤 위치를 기억해 둔다
var _slot_row: HBoxContainer  # 장착 칸 4개
var _acc_grid: GridContainer  # 장신구 목록
var _acc_pick: int = -1       # 지금 고르는 중인 칸 (-1이면 고르는 중 아님)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	# ── 배경(그라데이션 + 먼지 + 비네트) — 메인 메뉴와 동일한 게임 톤 ──
	_root.add_child(UiKit.gradient_bg())
	_root.add_child(UiKit.motes(Vector2(640, 360), Vector2(720, 430)))
	_root.add_child(UiKit.vignette())

	# [S5] 무기 해금 섹션 추가로 내용이 720px를 넘어 '뒤로' 버튼이 화면 밖으로 밀렸었음 → 스크롤 랩핑
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true   # 16차 4-5: 패드로 아래 칸에 포커스가 가면 화면도 따라 내려간다
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll = scroll
	_root.add_child(scroll)
	scroll.add_child(UiKit.TouchScroll.new(scroll))
	var outer := MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_top", 14)
	outer.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(outer)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(v)

	v.add_child(UiKit.title_band("영구 강화 상점", 48))

	_gold_lbl = Label.new()
	UiFont.apply(_gold_lbl, 22)
	_gold_lbl.add_theme_color_override("font_color", UiKit.ACCENT)
	_gold_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_gold_lbl.add_theme_constant_override("outline_size", 4)
	_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_gold_lbl)

	# 현재 전체 능력치 (영구 강화 반영)
	_stats_lbl = Label.new()
	UiFont.apply(_stats_lbl, 17)
	_stats_lbl.add_theme_color_override("font_color", UiKit.CYAN)
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_stats_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	v.add_child(spacer)

	# ★ 13차: 카드 8장 테가 모두 다른 색(무지개)이고 카드마다 작은 글 세 줄이었다(에셋 담당 검토).
	#   아이콘 격자 + 레벨 막대 · 하나 고르면 아래 판에 설명 · 다음 효과 · 가격 · 사기(Vampire Survivors 파워업처럼).
	_grid = GridContainer.new()
	_grid.columns = 9
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	var gc := CenterContainer.new()
	gc.add_child(_grid)
	v.add_child(gc)
	_detail = UiKit.make_panel()
	_detail.custom_minimum_size = Vector2(760, 0)
	_detail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_detail)

	# ── 특수무기 해금 (S1): 조건 달성 시 자동, 골드로 즉시 해금도 가능 ──
	v.add_child(UiKit.header("특수무기 해금", UiParts.BRASS_HI, 20))
	# ★ 이면 무기 4종이 추가되며 7장이 됐다. HBox 로 두면 238px × 7 = 1,666px 로 화면(1,280)을
	#   넘고 가로 스크롤은 꺼져 있어 뒤쪽이 잘린다. 격자로 접는다.
	_wpn_row = GridContainer.new()
	_wpn_row.columns = 4
	_wpn_row.add_theme_constant_override("h_separation", 12)
	_wpn_row.add_theme_constant_override("v_separation", 10)
	var wc := CenterContainer.new()
	wc.add_child(_wpn_row)
	v.add_child(wc)

	# ── 액세서리(장신구): 사면 영구 보유, 네 칸에 끼워서 나간다 ──
	v.add_child(UiKit.header(I18n.t("장신구  ·  칸 %d개") % Accessories.SLOTS, Color("f0c33c"), 20))
	_slot_row = HBoxContainer.new()
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slot_row.add_theme_constant_override("separation", 10)
	v.add_child(_slot_row)
	_acc_grid = GridContainer.new()
	_acc_grid.columns = 2
	_acc_grid.add_theme_constant_override("h_separation", 16)
	_acc_grid.add_theme_constant_override("v_separation", 12)
	v.add_child(_acc_grid)

	_root.add_child(UiKit.back_button(_on_close))  # 좌상단 고정 — 전 메뉴 공통 (S6 통일)


func open() -> void:
	_root.visible = true
	UiKit.focus_first(_root)   # 패드로 메뉴를 넘길 시작점
	get_tree().paused = true
	_refresh()


func cost(m: Dictionary, lvl: int) -> int:
	return G.meta_cost(String(m["id"]), lvl)


func _refresh() -> void:
	# ★ 30단계짜리 강화를 연속으로 지르는 화면이다. 카드를 다시 그릴 때마다 맨 위로 튀면
	#   같은 항목을 다시 찾아 내려가는 일이 반복된다 — 위치를 그대로 되돌려 준다.
	var keep: int = _scroll.scroll_vertical if _scroll != null else 0
	# QA 10/13: 다시 그리면 포커스가 있던 단추도 지워져 패드로는 더 못 누른다 — 단추 이름으로 기억했다가 되돌린다
	var fo: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var fkey: String = String(fo.name) if fo != null and is_ancestor_of(fo) and String(fo.name).begins_with("q_") else ""
	if _scroll != null:
		_scroll.set_deferred("scroll_vertical", keep)
	_gold_lbl.text = I18n.t("보유 골드:  %s G") % G.gold_str(G.total_gold)
	_stats_lbl.text = G.meta_stat_compact()
	for c in _grid.get_children():
		_grid.remove_child(c)   # QA 10/13: 새 칸이 같은 이름을 받게 바로 뺀다
		c.queue_free()
	for m: Dictionary in META:
		_grid.add_child(_cell(m))
	_fill_detail()
	for c in _wpn_row.get_children():
		_wpn_row.remove_child(c)   # QA 10/13: 새 칸이 같은 이름을 받게 바로 뺀다
		c.queue_free()
	for wid: String in G.WPN_UNLOCKS.keys():
		_wpn_row.add_child(_wpn_card(wid))
	_refresh_acc()
	if fkey != "":
		_refocus(fkey)


## QA 10/13: 지운 단추가 실제로 사라진 다음 프레임에 같은 이름의 새 단추로 포커스를 옮긴다(없으면 첫 단추).
func _refocus(key: String) -> void:
	await get_tree().process_frame
	var n: Node = find_child(key, true, false)
	if n is Control and (n as Control).is_visible_in_tree():
		(n as Control).grab_focus()
	else:
		UiKit.focus_first(_root)


## 특수무기 해금 카드 (S1): 해금됨=체크 / 잠김=조건 + 골드 버튼
func _wpn_card(wid: String) -> Control:
	var u: Dictionary = G.WPN_UNLOCKS[wid]
	var unlocked: bool = G.wpn_unlocked(wid)
	var panel := UiKit.make_panel(UiKit.CYAN if unlocked else UiKit.PANEL_BORDER)
	panel.custom_minimum_size = Vector2(238, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	var name_col: Color = UiKit.CYAN if unlocked else UiKit.TEXT
	if UiParts.on():
		name_col = UiParts.BRASS_HI if unlocked else UiParts.PAPER    # 14차: 청록 글자도 테 한 색 규칙에 맞춰 놋쇠로
	_add_lbl(vb, ("" if unlocked else I18n.t("잠김") + " · ") + I18n.t(String(u["name"])), 18, name_col)
	_add_lbl(vb, String(u["desc"]), 12, UiKit.TEXT_DIM, 218.0)
	if unlocked:
		# 14차 2절 11: 「해금됨」 한 낱말 + 체크(갈무리에 ✔ 가 없어 도트 체크를 그린다)
		var ok := HBoxContainer.new()
		ok.alignment = BoxContainer.ALIGNMENT_CENTER
		ok.add_theme_constant_override("separation", 6)
		ok.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ck: TextureRect = UiParts.check_icon(Color("9dff6b"))
		ck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ok.add_child(ck)
		_add_lbl(ok, I18n.t("해금됨"), 16, Color("9dff6b"))
		vb.add_child(ok)
	else:
		_add_lbl(vb, I18n.t("조건: ") + I18n.t(String(u["cond"])), 12, Color("ffca7a"), 218.0)
		var c: int = int(u["gold"])
		var buy := UiKit.button(I18n.t("%s G 해금") % G.gold_str(c), _buy_wpn.bind(wid), G.total_gold >= c, UiKit.ACCENT)
		buy.name = "q_wpn_" + wid
		buy.custom_minimum_size = Vector2(130, 42)
		UiFont.apply(buy, 16)
		buy.disabled = G.total_gold < c
		var bc := CenterContainer.new()
		bc.add_child(buy)
		vb.add_child(bc)
	return panel


func _buy_wpn(wid: String) -> void:
	if G.try_buy_wpn(wid):
		G.meta["uwn_" + wid] = 1  # 직접 해금 — 별도 알림 생략
		G.save_game()
		G.sfx("levelup", 1.2)
		_refresh()


# ──────────────────────────── 장신구 ────────────────────────────

func _refresh_acc() -> void:
	for c in _slot_row.get_children():
		_slot_row.remove_child(c)   # QA 10/13: 새 칸이 같은 이름을 받게 바로 뺀다
		c.queue_free()
	for i in Accessories.SLOTS:
		_slot_row.add_child(_slot_button(i))
	for c in _acc_grid.get_children():
		_acc_grid.remove_child(c)   # QA 10/13: 새 칸이 같은 이름을 받게 바로 뺀다
		c.queue_free()
	for d: Dictionary in Accessories.DEFS:
		_acc_grid.add_child(_acc_card(d))


## 장착 칸 하나. 누르면 '이 칸에 넣을 것 고르는 중'이 되고, 목록에서 하나를 누르면 끼워진다.
func _slot_button(i: int) -> Control:
	var id: String = G.acc_slot(i)
	var d: Dictionary = Accessories.def_of(id)
	var picking: bool = _acc_pick == i
	var col: Color = Accessories.tier_color(int(d.get("tier", 0))) if not d.is_empty() else UiKit.PANEL_BORDER
	if picking:
		col = Color("9dff6b")
	var txt: String = String(d.get("name", "빈 칸")) if not d.is_empty() else I18n.t("빈 칸")
	var b := UiKit.button(txt, _on_slot_pressed.bind(i), not d.is_empty(), col)
	b.name = "q_slot_%d" % i
	if picking:
		UiParts.button_icon(b, "check")   # 16차: 「◆」 글꼴 기호 대신
	b.custom_minimum_size = Vector2(168, 46)
	UiFont.apply(b, 16)
	return b


func _on_slot_pressed(i: int) -> void:
	if _acc_pick == i:
		G.acc_equip(i, "")   # 고르는 중에 같은 칸을 또 누르면 비운다
		_acc_pick = -1
	else:
		_acc_pick = i
	G.sfx("pickup", 1.0)
	_refresh()


func _acc_card(d: Dictionary) -> Control:
	var id: String = String(d["id"])
	var owned: bool = G.acc_owned(id)
	var equipped: bool = G.acc_has(id)
	var tier: int = int(d["tier"])
	var col: Color = Accessories.tier_color(tier)
	var cost: int = int(d["gold"])
	var can_buy: bool = (not owned) and G.total_gold >= cost
	var panel := UiKit.make_panel(col if (owned or can_buy) else UiKit.PANEL_BORDER)
	panel.custom_minimum_size = Vector2(424, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var bc := CenterContainer.new()
	bc.add_child(IconBadge.new().setup(id, 44.0))
	row.add_child(bc)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	# 13차: 이름 · 등급을 한 줄에 두면 갈무리 영문(글자가 넓다)에서 칸을 넘었다 — 두 줄로
	_add_lbl_left(info, I18n.t(String(d["name"])), 18, col.lightened(0.15))
	_add_lbl_left(info, Accessories.tier_name(tier), 16, col.darkened(0.1))
	var desc := Label.new()
	desc.text = String(d["desc"])
	UiFont.apply(desc, 12)
	desc.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(210, 0)
	info.add_child(desc)
	var btn_txt: String = ""
	var act: Callable = Callable()
	if not owned:
		btn_txt = "%s G" % G.gold_str(cost)
		act = _buy_acc.bind(id)
	elif equipped:
		btn_txt = "장착 중"
	elif _acc_pick >= 0:
		btn_txt = I18n.t("%d번 칸에") % (_acc_pick + 1)
		act = _equip_acc.bind(id)
	else:
		btn_txt = "보유"
	var buy := UiKit.button(btn_txt, act, can_buy or (_acc_pick >= 0 and owned and not equipped), col)
	buy.name = "q_acc_" + id
	buy.custom_minimum_size = Vector2(112, 46)
	UiFont.apply(buy, 16)
	buy.disabled = not (can_buy or (_acc_pick >= 0 and owned and not equipped))
	var vc := CenterContainer.new()
	vc.add_child(buy)
	row.add_child(vc)
	return panel


func _buy_acc(id: String) -> void:
	if G.acc_buy(id):
		G.sfx("levelup", 1.15)
		_refresh()


func _equip_acc(id: String) -> void:
	if _acc_pick < 0:
		return
	G.acc_equip(_acc_pick, id)
	_acc_pick = -1
	G.sfx("levelup", 1.25)
	_refresh()


## 격자 칸 — 아이콘 · 레벨 막대 · Lv. 테두리는 한 색, 고른 칸만 금빛.
func _cell(m: Dictionary) -> Control:
	var mid: String = String(m["id"])
	var lvl: int = G.meta_level(mid)
	var mx: int = G.meta_max(mid)
	var b := Button.new()
	b.name = "q_cell_" + mid
	b.custom_minimum_size = Vector2(92, 112)
	b.focus_mode = Control.FOCUS_ALL
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.PANEL_FILL
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(3 if mid == _sel else 2)
	sb.border_color = UiKit.ACCENT if mid == _sel else Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.35)
	var sh: StyleBoxFlat = sb.duplicate()
	sh.border_color = UiKit.ACCENT
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	b.add_theme_stylebox_override("focus", sh)
	UiParts.style_cell(b, mid == _sel)
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var ic := CenterContainer.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.add_child(IconBadge.new().setup(String(m["icon"]), 48.0))
	vb.add_child(ic)
	# 레벨 막대(20~30단계라 점 대신 막대)
	var bar := ColorRect.new()
	bar.color = Color(0.05, 0.04, 0.07, 0.9)
	bar.custom_minimum_size = Vector2(72, 8)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.color = UiKit.ACCENT if lvl >= mx else Color("9dff6b")
	fill.size = Vector2(72.0 * clampf(float(lvl) / float(maxi(1, mx)), 0.0, 1.0), 8)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(fill)
	vb.add_child(bar)
	_add_lbl(vb, "MAX" if lvl >= mx else "%d/%d" % [lvl, mx], 16, UiKit.ACCENT if lvl >= mx else UiKit.TEXT_DIM)
	b.pressed.connect(func() -> void:
		_sel = mid
		_refresh())
	return b


## 아래 판 — 고른 강화의 이름 · Lv · 레벨당 · 누적 · 사면 · 가격 · 사기
func _fill_detail() -> void:
	if _detail == null:
		return
	for c in _detail.get_children():
		_detail.remove_child(c)   # QA 10/13: 새 칸이 같은 이름을 받게 바로 뺀다
		c.queue_free()
	var m: Dictionary = META[0]
	for mm: Dictionary in META:
		if String(mm["id"]) == _sel:
			m = mm
	var mid: String = String(m["id"])
	var lvl: int = G.meta_level(mid)
	var mx: int = G.meta_max(mid)
	var maxed: bool = lvl >= mx
	var c: int = cost(m, lvl)
	var affordable: bool = (not maxed) and G.total_gold >= c
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_detail.add_child(row)
	var bc := CenterContainer.new()
	bc.add_child(IconBadge.new().setup(String(m["icon"]), 64.0))
	row.add_child(bc)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	_add_lbl_left(info, I18n.t(String(m["name"])), 24, UiKit.TEXT)
	_add_lbl_left(info, "Lv %d / %d  ·  %s" % [lvl, mx, per_text(mid)], 16, UiKit.TEXT_DIM)
	_add_lbl_left(info, I18n.t("누적  %s") % _total_text(mid), 16, UiKit.TEXT_DIM)
	if not maxed:
		_add_lbl_left(info, I18n.t("사면  %s") % _preview_text(mid), 20, Color("9dff6b"))
	var cost_txt: String = "MAX" if maxed else (I18n.t("사기  %s G") % G.gold_str(c))
	var buy := UiKit.button(cost_txt, _buy.bind(m), affordable)
	buy.name = "q_buy_" + String(m["id"])
	buy.custom_minimum_size = Vector2(200, 56)
	buy.disabled = maxed or (not affordable)
	var vc := CenterContainer.new()
	vc.add_child(buy)
	row.add_child(vc)


func _card(m: Dictionary) -> Control:
	var mid: String = String(m["id"])
	var lvl: int = G.meta_level(mid)
	var mx: int = G.meta_max(mid)
	var maxed: bool = lvl >= mx
	var c: int = cost(m, lvl)
	var affordable: bool = (not maxed) and G.total_gold >= c
	var col: Color = Icons.color_of(String(m["icon"]))

	# 부담 가능하면 아이콘 컬러로 보더가 살아나고, 아니면 차분한 톤
	var panel := UiKit.make_panel(col if affordable else UiKit.PANEL_BORDER)
	panel.custom_minimum_size = Vector2(424, 0)  # 글자가 잘리지 않게 (1280 폭에 2열이 그대로 들어간다)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var bc := CenterContainer.new()
	bc.add_child(IconBadge.new().setup(String(m["icon"]), 48.0))
	row.add_child(bc)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	_add_lbl_left(info, String(m["name"]), 19, col.lightened(0.15))
	_add_lbl_left(info, "Lv %d / %d  ·  %s" % [lvl, mx, per_text(mid)], 12, UiKit.TEXT_DIM)
	# 지금까지 쌓인 총량 — 30단계로 잘게 쪼개면 "내가 얼마나 올렸지"가 안 보인다
	_add_lbl_left(info, I18n.t("누적  %s") % _total_text(mid), 12, col.darkened(0.1))
	# ★ "사면 뭐가 어떻게 되는지" 를 사기 전에 보여 준다(2026-09-06 요구).
	#   여기 숫자는 **판 시작 시점** 기준이다 — 영웅 등급·장신구는 그 뒤에 또 곱해진다.
	if not maxed:
		_add_lbl_left(info, I18n.t("사면  %s") % _preview_text(mid), 13, UiKit.CYAN)

	# 구매 버튼 — 부담 가능하면 골드(primary), MAX/부족이면 비활성
	var cost_txt: String = "MAX" if maxed else ("%s G" % G.gold_str(c))
	var buy := UiKit.button(cost_txt, _buy.bind(m), affordable, col if affordable else UiKit.ACCENT)
	buy.custom_minimum_size = Vector2(120, 52)
	UiFont.apply(buy, 19)
	buy.disabled = maxed or (not affordable)
	var vc := CenterContainer.new()
	vc.add_child(buy)
	row.add_child(vc)

	return panel


func _add_lbl(parent: Node, text: String, size: int, col: Color, wrap_w: float = 0.0) -> void:
	var l := Label.new()
	l.text = text
	UiFont.apply(l, size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap_w > 0.0:
		l.text = UiKit.wrap_words(text, size, wrap_w)   # 14차: 낱말 단위로만 꺾는다
		l.custom_minimum_size = Vector2(wrap_w, 0)
	parent.add_child(l)


func _add_lbl_left(parent: Node, text: String, size: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	UiFont.apply(l, size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# 30단계로 쪼갠 뒤 "Lv 30 / 30 · 레벨당 +3%" 같은 줄이 길어져 칸을 밀어냈다.
	# clip_text 를 켜면 Label 의 최소폭이 0 이 되어 부모를 못 넓힌다(= 칸 밖으로 안 나간다).
	l.clip_text = true
	# 잘라내기만 하면 영어 이름 끝이 잘린다("Bronze Mirror  ·  Legend"). 칸 폭이 정해진 뒤에 글자를 줄여 맞춘다.
	l.resized.connect(func() -> void: UiKit.fit_font(l, l.size.x - 2.0, size, maxi(10, size - 6)))
	parent.add_child(l)


## 이 강화를 한 칸 올리면 능력치가 얼마에서 얼마가 되는가.
## meta_bonus 는 레벨에 완전히 선형(game.gd)이라 한 레벨분만 더하면 그게 Lv+1 값이다 —
## 새 수식을 만들면 META_TIERS 가 유일 정의라는 규칙이 깨진다.
static func _preview_text(id: String) -> String:
	var now: float = G.meta_bonus(id)
	var nxt: float = now + G.meta_per(id)
	match id:
		"m_hp":
			return I18n.t("체력 %d → %d") % [int(round(Player.MAX_HP + now)), int(round(Player.MAX_HP + nxt))]
		"m_dmg":
			# %.1f 필수 — 레벨당 +0.42 라 %.0f 로 적으면 "14 → 14" 라는 거짓말이 된다
			return I18n.t("공격력 %.1f → %.1f") % [Player.BULLET_DMG * (1.0 + now), Player.BULLET_DMG * (1.0 + nxt)]
		"m_speed":
			return I18n.t("이동속도 %d → %d") % [int(round(Player.SPEED * (1.0 + now))),
				int(round(Player.SPEED * (1.0 + nxt)))]
		"m_magnet":
			return I18n.t("자석 +%d → +%d") % [int(round(now)), int(round(nxt))]
		"m_luck":
			return I18n.t("행운 +%d%% → +%d%%") % [int(round(now * 100.0)), int(round(nxt * 100.0))]
		"m_regen":
			return I18n.t("재생 %.2f/s → %.2f/s") % [now, nxt]
		"m_gold":
			return I18n.t("골드 +%d%% → +%d%%") % [int(round(now * 100.0)), int(round(nxt * 100.0))]
		"m_reroll":
			var extra: int = 1 if G.acc_has("acc_norigae") else 0
			return I18n.t("시작 리롤 %d회 → %d회") % [2 + int(round(now)) + extra, 2 + int(round(nxt)) + extra]
		"m_banish":
			return I18n.t("봉인 %d회 → %d회") % [1 + int(round(now)), 1 + int(round(nxt))]
	return ""


## 현재까지 쌓인 총 보너스 문구.
static func _total_text(id: String) -> String:
	var b: float = G.meta_bonus(id)
	match id:
		"m_hp":
			return I18n.t("+%d 체력") % int(round(b))
		"m_dmg":
			return I18n.t("공격력 %.1f") % (Player.BULLET_DMG * (1.0 + b))
		"m_gold":
			return I18n.t("+%d%% 골드") % int(round(b * 100.0))
		"m_speed":
			return I18n.t("이동속도 %d") % int(round(Player.SPEED * (1.0 + b)))
		"m_luck":
			return I18n.t("+%.1f%% 행운") % (b * 100.0)
		"m_magnet":
			return I18n.t("+%d 자석") % int(round(b))
		"m_regen":
			return I18n.t("+%.2f/s 재생") % b
		"m_reroll":
			# 시작 리롤은 기본 2 + 강화 + 노리개 1 — 표기와 실제가 어긋나지 않게 전부 더해서 보여준다
			return I18n.t("시작 리롤 %d회") % (2 + int(round(b)) + (1 if G.acc_has("acc_norigae") else 0))
		"m_banish":
			return I18n.t("봉인 %d회") % (1 + int(round(b)))
	return ""


func _buy(m: Dictionary) -> void:
	var lvl: int = G.meta_level(String(m["id"]))
	if lvl >= G.meta_max(String(m["id"])):
		return
	var c: int = cost(m, lvl)
	if G.total_gold < c:
		return
	G.total_gold -= c
	G.meta[String(m["id"])] = lvl + 1
	G.save_game()
	G.sfx("pickup", 1.2)
	_refresh()


func is_open() -> bool:
	return _root != null and _root.visible


## ESC(pause 액션)로도 닫힘 — PC에서 나갈 방법이 없다는 피드백 (S5)
func _unhandled_input(event: InputEvent) -> void:
	if is_open() and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):   # 16차: 패드 B 도 뒤로
		_on_close()
		get_viewport().set_input_as_handled()


func _on_close() -> void:
	_root.visible = false
	closed.emit()
