class_name PauseMenu
extends CanvasLayer
## ESC(또는 Tab)로 일시정지 + 현재 능력치(정갈한 2열 그리드). 레벨업 모달이 이미 멈춘 상태면 무시.
## [계속하기]로 재개 / [메인 메뉴]로 나가면 런은 살아있고 이어하기로 재개 가능.

signal to_main_menu

var _open: bool = false
var _root: Control
var _header: Label
var _grid: GridContainer
var _extra: Label
var _build_grid: GridContainer
var _panel_row: BoxContainer    # 좁은 화면에서 좌우 → 위아래로 뒤집는다 (HBox 는 못 뒤집는다)
var _btn_bar: PanelContainer    # 스크롤 밖 고정 버튼 줄 — 늘 화면 아래에 있다
var _hint: Label
var _scroll: ScrollContainer
var _build_detail: Label
var build_provider: Callable  # main._build_summary — 소유 무기/탄막 목록 제공
var _fuse_head: Label
var _fuse_box: VBoxContainer
var _wdmg: Dictionary = {}    # 카드 id -> 「한 발 23 (영웅 23 + 무기 0)」 — 아이콘을 누르면 상세에 붙는다


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	# ── 배경: 게임 위에 겹치므로 반투명 딤 + 은은한 그라데이션 + 비네트 ──
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	var grad := UiKit.gradient_bg()
	grad.modulate = Color(1, 1, 1, 0.5)  # 반투명 → 게임이 비침
	_root.add_child(grad)
	var vg := UiKit.vignette()
	vg.modulate = Color(1, 1, 1, 0.85)
	_root.add_child(vg)

	# 능력·빌드가 많아지면 세로로 길어지므로 스크롤 컨테이너로 감싼다(화면 밖으로 안 나가게)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true   # 16차 4-5: 패드로 아래 칸에 포커스가 가면 화면도 따라 내려간다
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	scroll.add_child(UiKit.TouchScroll.new(scroll))  # 모바일 드래그 스크롤 (S2)
	var outer := MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(outer)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(v)

	v.add_child(UiKit.title_band("일시정지", 38))

	# ── 능력치·빌드 패널을 좌우로 나란히 (세로 스크롤 안 생기게, M39) ──
	# ★ 넓은 화면에서만 좌우다. 좁은 화면(세로 모바일)에서는 위아래로 쌓는다 —
	#   좌우로 두면 내용 폭이 1079px 이라 720 폭 화면에서 359px 가 밖으로 나가고,
	#   가로 스크롤은 꺼져 있어서 **오른쪽 빌드 패널에 손이 아예 안 닿았다**(2026-09-06 지적).
	#   가로 스크롤을 켜는 대신 쌓는 이유: 좌우로 밀어야 보이는 화면은 모바일에서 최악이고,
	#   세로 스크롤은 이미 있고 잘 돈다. --pausecheck 가 세 해상도에서 확인한다.
	# ★ HBoxContainer 가 아니라 **평범한 BoxContainer** 다. HBox/VBox 는 방향이 고정된
	#   하위 클래스라 vertical 을 대입해도 무시된다 — 처음에 HBox 로 두고 vertical=true 를
	#   넣었는데 아무 일도 안 일어났다(--pausecheck 가 '세로쌓기 false' 로 잡았다).
	var hb := BoxContainer.new()
	hb.vertical = false
	hb.add_theme_constant_override("separation", 16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	_panel_row = hb

	# ── 능력치 패널 (왼쪽) ──
	var panel := UiKit.make_panel()
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hb.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	panel.add_child(pv)

	_header = UiKit.header("", UiKit.ACCENT, 18)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(_header)

	var sep := HSeparator.new()
	pv.add_child(sep)

	# 2열(아이콘 · 이름 · 값 × 2) 표 — 13차: 값은 오른쪽 정렬, 칸 사이는 빈 칸 하나
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 8)
	pv.add_child(_grid)

	_extra = Label.new()
	UiFont.apply(_extra, 16)
	_extra.add_theme_color_override("font_color", UiKit.CYAN)
	_extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pv.add_child(_extra)

	# ── 내가 든 것 (오른쪽): 아이콘 + 레벨, 누르면 상세 ──
	# ★ "현재 빌드" 였다. 게임 용어라 무슨 칸인지 한 번 더 생각하게 만든다(2026-09-07 지적).
	#   화면 문구는 플레이어가 쓰는 말이어야 한다 — 괄호 안내문도 문장으로 폈다.
	var bpanel := UiKit.make_panel(UiKit.CYAN)
	bpanel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hb.add_child(bpanel)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 8)
	bpanel.add_child(bv)
	var bh := UiKit.header("내가 든 것", UiKit.CYAN, 16)
	bh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(bh)
	_build_grid = GridContainer.new()
	_build_grid.columns = 5
	_build_grid.add_theme_constant_override("h_separation", 12)
	_build_grid.add_theme_constant_override("v_separation", 6)
	var bg_center := CenterContainer.new()
	bg_center.add_child(_build_grid)
	bv.add_child(bg_center)
	_build_detail = Label.new()
	UiFont.apply(_build_detail, 14)
	_build_detail.add_theme_color_override("font_color", UiKit.TEXT)
	_build_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_detail.custom_minimum_size = Vector2(380, 76)
	_build_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bv.add_child(_build_detail)
	# 13차: 지금 가능한 융합 — 문장 대신 아이콘 + 아이콘 = 아이콘 (Vampire Survivors 진화표처럼)
	_fuse_head = UiKit.header("융합까지", UiKit.ACCENT, 16)
	_fuse_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(_fuse_head)
	_fuse_box = VBoxContainer.new()
	_fuse_box.add_theme_constant_override("separation", 6)
	bv.add_child(_fuse_box)

	# ── 버튼: **스크롤 밖**에 화면 아래 고정 ──
	# ★ 예전엔 이 줄이 스크롤 안에 있었다. 빌드가 쌓이면 내용이 화면보다 길어지는데,
	#   그러면 '계속하기'가 스크롤 아래로 밀려 내려간다. 키보드가 있으면 ESC 로 빠져나오지만
	#   **모바일엔 ESC 가 없다** — 스크롤을 못 찾으면 판에서 못 나온다(2026-09-06 지적).
	#   나가는 문은 내용 길이와 무관하게 늘 같은 자리에 있어야 한다.
	var bar := PanelContainer.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.05, 0.05, 0.09, 0.92)
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 10
	bsb.content_margin_left = 18
	bsb.content_margin_right = 18
	bar.add_theme_stylebox_override("panel", bsb)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_root.add_child(bar)
	_btn_bar = bar
	var bar_v := VBoxContainer.new()
	bar_v.add_theme_constant_override("separation", 4)
	bar.add_child(bar_v)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	bar_v.add_child(btn_row)
	btn_row.add_child(UiParts.with_icon(UiKit.button("계속하기", _on_resume, true), "play"))
	btn_row.add_child(UiParts.with_icon(UiKit.button("메인 메뉴", _on_main_menu, false, UiKit.DANGER), "menu"))

	_hint = Label.new()
	UiFont.apply(_hint, 13)
	_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_v.add_child(_hint)
	# 화면 크기가 바뀌면(창 조절·기기 회전) 즉시 다시 배치한다. 열려 있는 동안 바뀔 수도 있다.
	get_viewport().size_changed.connect(_relayout)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (_open and event.is_action_pressed("ui_cancel")):   # 16차: 열려 있으면 패드 B 로도 계속하기
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	if not _open and get_tree().paused:
		return  # 다른 UI(레벨업 등)가 이미 멈춤 중
	if not _open and not G.running:
		return  # [감사 C4] 게임오버/승리 화면 위에서 일시정지 열림 → 죽은 씬 '새 게임' 소프트락 차단
	_open = not _open
	_root.visible = _open
	get_tree().paused = _open
	if _open:
		_refresh()
		UiKit.focus_first(_root)   # 패드로 메뉴를 넘길 시작점


## B 아이콘 id → U6 능력치 아이콘 이름
const U6: Dictionary = {
	"hp": "hp", "dmg": "attack", "rate": "firerate", "multi": "multishot", "bspeed": "projspeed", "speed": "move",
	"crit": "crit", "critdmg": "critdmg", "armor": "defense", "regen": "regen", "magnet": "magnet", "luck": "luck", "dashcd": "dashcd",
}


func _add_stat(sname: String, value: String, vcol: Color = Color("f0ecff"), icon: String = "") -> void:
	if _grid.columns == 7 and _grid.get_child_count() % 7 == 3:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(18, 0)
		_grid.add_child(gap)
	# 16차 U6: 능력치 줄은 12px 능력치 아이콘(에셋 담당 「12px 는 HUD · 능력치 줄 글자 옆」). 없는 것(가시 반사)만 예전 배지.
	var ic: Control
	var u6: String = String(U6.get(icon, ""))
	if u6 != "" and UiParts.icon_tex(u6, 12) != null:
		ic = UiParts.icon(u6, 12)
	else:
		ic = IconBadge.new().setup(icon, 26.0) if icon != "" else Control.new()
	ic.custom_minimum_size = Vector2(26, 26)
	_grid.add_child(ic)
	var n := Label.new()
	n.text = sname
	UiFont.apply(n, 17)
	n.add_theme_color_override("font_color", Color("9a96b0"))
	_grid.add_child(n)
	var val := Label.new()
	val.text = value
	UiFont.apply(val, 18)
	val.add_theme_color_override("font_color", vcol)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.custom_minimum_size = Vector2(96, 0)
	_grid.add_child(val)


## 화면 폭에 맞춰 배치를 바꾼다. 좁으면 두 패널을 위아래로 쌓고 빌드 격자를 좁힌다.
## 가로로 넘치면 손이 닿을 방법이 없으므로(가로 스크롤 꺼짐) 여기가 유일한 방어선이다.
func _relayout() -> void:
	var vr: Vector2 = get_viewport().get_visible_rect().size
	if _panel_row != null and is_instance_valid(_panel_row):
		_panel_row.vertical = vr.x < 1120.0
		# 13차: 영어(갈무리 영문은 글자가 넓다)에선 두 판이 1280 을 넘었다 — 넘치면 위아래로
		if not _panel_row.vertical:
			_panel_row.vertical = false
			if _panel_row.get_combined_minimum_size().x > vr.x - 24.0:
				_panel_row.vertical = true
	if _grid != null and is_instance_valid(_grid):
		_grid.columns = 7 if vr.x >= 760.0 else 3   # 좁으면 능력치 표를 한 줄에 하나씩
	if _build_grid != null and is_instance_valid(_build_grid):
		_build_grid.columns = 5 if vr.x >= 1120.0 else (4 if vr.x >= 760.0 else 3)
	# 고정 버튼 줄이 내용의 마지막 줄을 가리지 않게, 스크롤 영역을 그만큼 위에서 끊는다
	if _scroll != null and is_instance_valid(_scroll) and _btn_bar != null and is_instance_valid(_btn_bar):
		_scroll.offset_bottom = -maxf(56.0, _btn_bar.size.y)
	# 내용이 화면보다 길면 **스크롤할 수 있다는 것**을 알려 준다. 안 적으면 아래가 있는 줄 모른다.
	if _hint != null and is_instance_valid(_hint) and _scroll != null:
		var over: bool = false
		for c in _scroll.get_children():
			if c is Control and not (c is ScrollBar):
				over = (c as Control).get_combined_minimum_size().y > _scroll.size.y
		# 16차 4-5: 패드가 꽂혀 있으면 키보드 안내(ESC)는 뺀다 — 패드는 B · START 로 닫힌다(버튼 그림 없이 엑스박스 · PS 둘 다 맞게)
		var pad: bool = not Input.get_connected_joypads().is_empty()
		_hint.text = I18n.t("위아래로 밀어 더 보기") if over else ("" if pad or G.mobile else I18n.t("ESC 로 닫기"))   # QA 10/13: 폰엔 ESC 가 없다


func _refresh() -> void:
	_relayout()
	_wdmg.clear()
	var p := G.player as Player
	for c in _grid.get_children():
		c.queue_free()
	if p == null or not is_instance_valid(p):
		_header.text = "(캐릭터 없음)"
		return
	_header.text = I18n.t("레벨 %d    ·    처치 %d    ·    생존 %02d:%02d    ·    골드 %d") % [
		G.level, G.kills, int(G.time_alive) / 60, int(G.time_alive) % 60, G.run_gold
	]
	# 10/13 QA C7: 예전엔 「연사(밸런스)  3.6 발/초」 — 시작 소총 기준이라 소총이 없는 영웅(두두 · 물결)에게도 떴고
	#   소총 레벨도 안 봤다. 모든 무기에 같이 붙는 공격 주기 배수로 적는다(1 보다 크면 빠르다).
	var atk_spd: float = 1.0 / maxf(0.03, p.rate_mult)
	var dash_full: float = maxf(Player.DASH_CD_MIN, Player.DASH_CD * p.dash_cd_mult)
	_add_stat("체력", "%d / %d" % [int(ceil(p.hp)), int(p.max_hp)], Color("ff8a95"), "hp")
	_add_stat("영웅 공격력", "%.0f" % p.damage, Color("ff8a6a"), "dmg")
	_add_stat("공격속도", "×%.2f" % atk_spd, Color("f0ecff"), "rate")
	_add_stat("멀티샷 / 관통", "+%d / %d" % [p.proj_bonus, p.pierce], Color("f0ecff"), "multi")
	_add_stat("탄속", "%.0f" % p.bullet_speed, Color("f0ecff"), "bspeed")
	_add_stat("이동속도", "%.0f" % p.move_speed, Color("f0ecff"), "speed")
	_add_stat("치명타", "%.0f%%" % (p.crit_chance * 100.0), Color("ffd23f"), "crit")
	_add_stat("치명 배율", "x%.1f" % p.crit_mult, Color("ffd23f"), "critdmg")
	_add_stat("방어", "%.0f" % p.armor, Color("8aa6dd"), "armor")
	_add_stat("체력 재생", "%.1f/s" % p.regen, Color("7dff9b"), "regen")
	_add_stat("자석 범위", "+%.0f" % p.magnet_bonus, Color("5c8dff"), "magnet")
	# 행운은 '실효'로 표기 — 아이템 드랍 확률에 ×(1+행운) 곱연산 (숫자만 +로 보이면 의심하니까)
	_add_stat("행운", I18n.t("드랍 ×%.2f") % (1.0 + p.luck), Color("5fd39a"), "luck")
	_add_stat("대시 쿨", I18n.t("%.1f초") % dash_full, Color("42e2b8"), "dashcd")
	if p.thorns > 0.0:
		_add_stat("가시 반사", "%.0f" % p.thorns, Color("ff8a5c"), "thorns")
	# 탄막 부여 / 무기 요약
	var fx: Array = []
	if p.b_ice > 0:
		fx.append(I18n.t("얼음%d") % p.b_ice)
	if p.b_fire > 0:
		fx.append(I18n.t("화염%d") % p.b_fire)
	if p.b_poison > 0:
		fx.append(I18n.t("맹독%d") % p.b_poison)
	if p.b_shock > 0:
		fx.append(I18n.t("감전%d") % p.b_shock)
	if p.b_big > 0:
		fx.append(I18n.t("거대%d") % p.b_big)
	if p.b_bounce > 0:
		fx.append(I18n.t("튕김%d") % p.b_bounce)
	# ★ 11개 중 6개만 찍고 있었다. 연쇄·처형·흡혈·개화·유도는 켜져 있어도 화면에 흔적이 없어서
	#   "먹은 게 맞나"를 확인할 방법이 없었다(2026-09-06 검증에서 발견).
	if p.b_chain > 0:
		fx.append(I18n.t("연쇄%d") % p.b_chain)
	if p.b_exec > 0:
		fx.append(I18n.t("처형%d") % p.b_exec)
	if p.b_vamp > 0:
		fx.append(I18n.t("흡혈%d") % p.b_vamp)
	if p.b_bloom > 0:
		fx.append(I18n.t("개화%d") % p.b_bloom)
	if p.b_homing > 0:
		fx.append(I18n.t("유도%d") % p.b_homing)
	var lines: Array = []
	# 장착 무기(아키타입) 목록 — 융합한 것은 ✦ 로 표시
	var wnames: Array = []
	for w in p.weapons_primary:
		var wid: String = String(w["id"])
		var def: Dictionary = Player.WEAPON_DEFS[wid]
		var mark: String = I18n.t("융합 ") if p.fused_marks.has(wid) else ""   # 16차: 「◆」 글꼴 기호 대신 낱말
		# 한 발 피해를 **영웅 몫 + 무기 몫**으로. 이 화면 위쪽의 "공격력"은 영웅 스탯 하나뿐이라,
		# 그게 무기를 통해 실제로 얼마가 되는지 볼 데가 없었다(2026-09-06 요구).
		var pr: Array = p.weapon_dmg_parts(def, int(w["level"]))
		var wtrait: String = ""
		if G.w_maxed(wid, int(w["level"])):
			wtrait = "  · %s" % G.w_trait_name(wid)
		var h0: int = int(round(float(pr[0])))
		var w0: int = int(round(float(pr[1])))
		wnames.append(I18n.t("%s%s Lv%d · 한 발 %d (영웅 %d + 무기 %d)%s")
			% [mark, I18n.t(String(def["name"])), int(w["level"]), h0 + w0, h0, w0, wtrait])
		_wdmg["wp_" + wid] = I18n.t("한 발 %d (영웅 %d + 무기 %d)") % [h0 + w0, h0, w0] + wtrait
	# ★ 13차: 무기 · 탄막 문장 20줄이 가운데 정렬로 쌓여 아래가 버튼에 가렸다(에셋 담당 검토).
	#   무기마다 한 발 피해는 오른쪽 아이콘을 누르면 상세에 나온다(_wdmg) · 탄막 부여는 아이콘 칸이 보여 준다.
	# ★ 예전엔 "보조 무기: 1종" 한 줄이었다. Lv13 군단을 들고 있어도 이름도 레벨도 위력도
	#   화면 어디에도 없었다 — 주무기는 무기마다 한 줄씩 적으면서 특수무기만 개수만 셌다
	#   (2026-09-06 지적). 같은 규칙으로 한 줄씩 적는다.
	if not p.weapons.is_empty():
		for k in p.weapons.keys():
			var nd: Node = p.weapons[k]
			if not is_instance_valid(nd):
				continue
			var sid: String = String(k)
			var slv: int = int(nd.get("level"))
			var sb: Dictionary = G.sp_base(sid)
			var per: String = I18n.t(String(sb.get("per", "타")))
			var hit: float = float(sb.get("dmg", 0.0)) * G.w_dmg_mult(sid, slv) * p.special_power()
			var smark: String = I18n.t("융합 ") if p.fused_marks.has(sid) else ""
			var strait: String = ""
			if G.w_maxed(sid, slv):
				strait = "  · %s" % G.w_trait_name(sid)
			_wdmg[sid] = I18n.t("한 %s %d") % [per, int(round(hit))] + strait
	# ── 영웅 고유 능력 ──
	# ★ 예전엔 ability 를 읽는 UI 가 **하나도 없었다.** 능력이 스탯에 녹아든 뒤에는
	#   그게 능력 덕인지 카드 덕인지 분간할 근거가 화면에 없었고, 깃소금의 도박은
	#   무엇이 얼마나 변했는지 아무도 몰랐다(2026-09-05 지적).
	var abil: Array = _ability_lines(p)
	if not abil.is_empty():
		lines.append("")
		lines.append(I18n.t("고유 능력"))
		for a in abil:
			lines.append("   " + String(a))

	# ★ 칸이 몇 개 남았는지 — 이걸 안 보여주면 "왜 새 무기가 안 뜨지?"가 된다.
	#   슬롯 상한(무기 4 / 탄막 4)을 도입한 뒤 반드시 필요한 줄이다.
	var main0 := get_tree().current_scene
	if main0 != null and main0.has_method("slot_usage_line"):
		lines.append(String(main0.call("slot_usage_line")))
	# 융합까지 얼마나 남았는지 — 이 화면이 유일하게 '목표'를 보여주는 자리다. 13차: 오른쪽에 아이콘 식으로
	_refresh_fusions()
	call_deferred("_relayout")   # 내용을 다 채운 폭으로 한 번 더(넘치면 위아래로)
	if G.run_penalty > 0.0:
		lines.append(I18n.t("융합 페널티: 공격력 -%d%%") % int(G.run_penalty * 100.0))
	_extra.text = "\n".join(lines) if not lines.is_empty() else ""

	# 빌드 아이콘 그리드 (무기/탄막 몇성 + 호버/탭 상세)
	if _build_grid != null:
		for c in _build_grid.get_children():
			c.queue_free()
		UiKit.set_wrapped(_build_detail, "아이콘을 누르면 자세히 나옵니다", 14)
		var summary: Array = []
		if build_provider.is_valid():
			summary = build_provider.call()
		if summary.is_empty():
			UiKit.set_wrapped(_build_detail, "아직 고른 것이 없습니다", 14)
		for e in summary:
			_build_grid.add_child(_build_item(e as Dictionary))


## 빌드 항목 1칸: 아이콘 + 레벨, 커서/탭 시 하단에 상세 표시
func _build_item(e: Dictionary) -> Control:
	var lvl: int = int(e["level"])
	var mx: int = int(e["max"])
	var maxed: bool = mx > 0 and lvl >= mx
	# 대괄호는 **칸 분류**(무기/탄막/패시브/융합), 그 뒤는 등급(신화·전설). 둘은 다른 것이다.
	var tier0: String = String(e.get("tier", ""))
	var tier_txt: String = (" · " + I18n.t(tier0)) if (tier0 != "" and tier0 != String(e.get("kind", ""))) else ""
	var fused: bool = bool(e.get("fused", false))
	var detail: String = "[%s%s] %s   ·   Lv %d%s
%s" % [
		I18n.t(String(e.get("kind", ""))), tier_txt, String(e["name"]), lvl,
		(" (MAX)" if maxed else " / %d" % mx), String(e["desc"])
	]
	if fused:   # 융합 무기는 더 오르지 않는다 — 레벨 · MAX 대신 「융합」 한 낱말
		detail = "[%s] %s\n%s" % [I18n.t("융합"), String(e["name"]), String(e["desc"])]
	if _wdmg.has(String(e["id"])):
		detail += "\n" + String(_wdmg[String(e["id"])])
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 2)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.tooltip_text = detail
	cell.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed) or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed):
			UiKit.set_wrapped(_build_detail, detail, 14)
	)
	var badge := IconBadge.new()
	badge.setup(String(e.get("icon", e["id"])), 46.0)   # 융합 무기는 재료 무기가 아니라 융합 아이콘
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(badge)
	var ll := Label.new()
	# 신화/전설/융합은 레벨이 아니라 등급 이름을 찍는다 — 한 장짜리라 "Lv1"이 오히려 작아 보인다
	var kind: String = "융합" if fused else String(e.get("kind", ""))
	var crown: Dictionary = {
		"신화": Color("ff3df0"), "전설": Color("ffd54a"), "융합": Color("ffd54a"),
	}
	if crown.has(kind):
		ll.text = kind
		ll.add_theme_color_override("font_color", crown[kind])
	else:
		ll.text = "MAX" if maxed else "Lv%d" % lvl
		ll.add_theme_color_override("font_color", UiKit.ACCENT if maxed else UiKit.TEXT_DIM)
	UiFont.apply(ll, 14)
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ll.clip_text = true                       # 칸을 넘겨 옆 아이콘 위로 번지지 않게
	ll.custom_minimum_size = Vector2(54, 0)
	cell.add_child(ll)
	return cell


## 지금 가능한 융합 — 재료 아이콘(지금/필요) + 재료 아이콘 = 결과 아이콘. 가까운 셋.
func _refresh_fusions() -> void:
	if _fuse_box == null:
		return
	for c in _fuse_box.get_children():
		c.queue_free()
	var main := get_tree().current_scene
	var rows: Array = main.call("fusion_progress_rows") if main != null and main.has_method("fusion_progress_rows") else []
	_fuse_head.visible = not rows.is_empty()
	for r: Dictionary in rows:
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 6)
		_fuse_box.add_child(hb)
		var first: bool = true
		for q: Array in (r["reqs"] as Array):
			if not first:
				hb.add_child(_fuse_sym("+"))
			first = false
			hb.add_child(IconBadge.new().setup(String(q[0]), 36.0))
			var ql := Label.new()
			ql.text = I18n.t("잠김") if bool(q[3]) else "%d/%d" % [int(q[1]), int(q[2])]
			UiFont.apply(ql, 16)
			ql.add_theme_color_override("font_color", UiKit.ACCENT if int(q[1]) >= int(q[2]) else UiKit.TEXT_DIM)
			hb.add_child(ql)
		hb.add_child(_fuse_sym("="))
		var eb := IconBadge.new().setup(String(r["evo"]), 36.0)
		eb.tooltip_text = String(r["name"])
		hb.add_child(eb)
		var nl := Label.new()
		nl.text = String(r["name"])
		UiFont.apply(nl, 16)
		nl.add_theme_color_override("font_color", Color("ffd54a"))
		hb.add_child(nl)


func _fuse_sym(t: String) -> Label:
	var l := Label.new()
	l.text = t
	UiFont.apply(l, 20)
	l.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	return l


func _on_resume() -> void:
	if _open:
		_toggle()


func _on_main_menu() -> void:
	# 런은 유지한 채 메뉴로. 일시정지 상태 그대로 넘김 → 이어하기로 재개.
	_open = false
	_root.visible = false
	to_main_menu.emit()


## 영웅 고유 능력이 **지금** 무엇을 하고 있는지. 켜졌다 꺼지는 것은 남은 시간까지 적는다.
func _ability_lines(p: Player) -> Array:
	var out: Array = []
	match p.ability:
		"fourcards":
			out.append(I18n.t("레벨업마다 카드 4장 중 선택"))
			out.append(I18n.t("10레벨마다 도박  (굴린 횟수 %d)") % p.gamble_rolls)
			if p.gamble_rolls > 0:
				var g: PackedStringArray = []
				if absf(p.gamble_add) > 0.001:
					g.append(I18n.t("공격력 %+d") % int(round(p.base_damage * p.gamble_add * p.card_mult)))
				if p.gamble_proj != 0:
					g.append(I18n.t("탄환 %+d") % p.gamble_proj)
				if absf(p.gamble_crit) > 0.001:
					g.append(I18n.t("치명타 %+.0f%%") % (p.gamble_crit * 100.0))
				if absf(p.gamble_rate - 1.0) > 0.001:
					g.append(I18n.t("공격주기 ×%.2f") % p.gamble_rate)
				out.append(I18n.t("   도박 누적:  ") + (", ".join(g) if g.size() > 0 else I18n.t("변화 없음")))
				# 굴린 순서를 그대로 — 뭐가 올랐고 뭐가 내렸는지 종합으로 보여야 한다
				if not p.gamble_log.is_empty():
					var hist: PackedStringArray = []
					for x in p.gamble_log:
						hist.append(I18n.t(String(x)))
					out.append(I18n.t("   굴린 순서:  ") + " → ".join(hist))
		"forge":
			out.append(I18n.t("무기 카드 한 장에 두 단계 (그래서 무기 Lv 가 6 을 넘는다)"))
			out.append(I18n.t("특수무기 위력 ×1.25"))
		"pyro":
			out.append(I18n.t("화염 오라를 들고 시작 · 특수무기 위력 ×1.25"))
		"dashstrike":
			out.append(I18n.t("대시 쿨 %.1f초 · 들이받으면 공격력 ×%.2f (한 방 %d)")
				% [maxf(Player.DASH_CD_MIN, Player.DASH_CD * p.dash_cd_mult),
					Player.DASH_STRIKE_MULT, int(p.damage * Player.DASH_STRIKE_MULT)])
		"falcon":
			out.append(I18n.t("모든 탄이 조금씩 휘어 적을 찾는다 (유도 1)"))
		"lifesteal":
			out.append(I18n.t("처치할 때마다 체력을 조금 되찾는다"))
		"rage":
			var on: bool = p.hp < p.max_hp * 0.4
			out.append(I18n.t("체력 %d 아래에서 공격력 ×%.2f  (%s)")
				% [int(p.max_hp * 0.4), Player.RAGE_MULT,
					I18n.t("발동 중") if on else I18n.t("대기 · 지금 %d") % int(p.hp)])   # 괄호 안 괄호 「(대기 (지금 205))」 를 피한다
		"sworddance":
			out.append(I18n.t("계속 움직이면 %.0f초에 걸쳐 공격력 ×1.00 → ×%.2f")
				% [p.dance_max, 1.0 + p.dance_rate * p.dance_max])
			out.append(I18n.t("   지금 ×%.2f  (%.1f초 쌓임)")
				% [1.0 + p.dance_rate * p._dance_t, p._dance_t])
		"shadow":
			out.append(I18n.t("대시 후 %.0f초간 치명타 확률 +%.0f%%  (%s)")
				% [Player.DASH_TIME + Player.SHADOW_DUR, Player.SHADOW_CRIT * 100.0,
					I18n.t("남은 %.1f초") % p._shadow_t if p._shadow_t > 0.0 else I18n.t("대기")])
		"spirits":
			out.append(I18n.t("소환수를 데리고 시작"))
			# 배수를 안 적으면 아래 무기 목록의 피해 숫자가 혼자 뛴다 — 그게 버그로 읽힌다
			# (2026-09-06 지적). 무기별 실수치는 무기 목록이 이미 적으므로 여기선 배수만 적는다.
			out.append(I18n.t("처치하면 %.0f초간 공격력 ×%.2f · 처치마다 다시 채워진다  (%s)")
				% [Player.SPIRIT_DUR, Player.SPIRIT_MULT,
					I18n.t("남은 %.1f초") % p._spirit_t if p._spirit_t > 0.0 else I18n.t("대기")])
		"beads":
			out.append(I18n.t("염주가 피해 한 번을 흘려보낸다  (%s)")
				% (I18n.t("준비됨") if p._bead_cd <= 0.0 else I18n.t("%.1f초 뒤 충전") % p._bead_cd))
		_:
			pass
	return out
