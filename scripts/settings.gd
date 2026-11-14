class_name SettingsMenu
extends CanvasLayer
## 설정: 기본 난이도 + 마스터 음량. 변경 즉시 user://save.cfg 저장.

signal closed

const DIFF_COLORS: Array = [Color("62d162"), Color("54c6ff"), Color("ff9f43"), Color("ff5a5a"), Color("b44dff")]
# 난이도 설명은 캐릭터 선택 화면과 공용 — G.DIFF_DESC (game.gd)

var _root: Control
var _diff_btns: Array = []
var _diff_desc_lbl: Label
var _aim_btns: Array = []
var _auto_btns: Array = []
var _uis_btns: Array = []   # 인터페이스 크기 (S1)
var _zoom_btns: Array = []  # 화면 확대 (S1)
var _perf_btns: Array = []  # 그래픽 성능(프레임 상한 · 이펙트 밀도)
var _stick_btns: Array = []  # 가상 조이스틱 응답 (터치 기기에서만 노출)
var _stickfix_btns: Array = []  # 조이스틱 자리 (고정 / 따라옴)
var _lang_btns: Array = []      # 언어 (자동 / 한국어 / English)
var _cf_btns: Array = []        # 캐릭터 그림 (기존 / 새 에셋) — 시범 비교용
var _win_btns: Array = []    # 창 / 전체화면 (PC 에서만 노출)
var _winsize_btns: Array = []   # 창 크기 (11/5)
var _res_lbl: Label             # 지금 해상도 한 줄


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 24
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	# ── 배경(그라데이션 + 먼지 + 비네트) ──
	_root.add_child(UiKit.gradient_bg())
	_root.add_child(UiKit.motes(Vector2(640, 360), Vector2(720, 430)))
	_root.add_child(UiKit.vignette())

	# 옵션이 많아져 세로로 길어짐 → 스크롤로 감싸 화면 밖 잘림 방지 (M35 일시정지와 동일 패턴)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true   # 16차 4-5: 패드로 아래 칸에 포커스가 가면 화면도 따라 내려간다
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	scroll.add_child(UiKit.TouchScroll.new(scroll))  # 모바일 드래그 스크롤 (S2)
	var outer := MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_top", 16)
	outer.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(outer)

	# ── 중앙 테마 패널 (컨트롤이 검은 배경에 뜨지 않도록) ──
	var panel := UiKit.make_panel()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	v.add_child(UiKit.title_band("설정", 46))
	# ── 13차 4절: 탭(일반 · 화면 · 소리 · 조작). 예전엔 항목이 한 장에 길게 이어졌다(에셋 담당 검토) ──
	var pv: VBoxContainer = v
	var trow := HBoxContainer.new()
	trow.alignment = BoxContainer.ALIGNMENT_CENTER
	trow.add_theme_constant_override("separation", 8)
	pv.add_child(trow)
	for ti in TAB_NAMES.size():
		var tix: int = ti
		var tb := UiKit.button(String(TAB_NAMES[ti]), func() -> void: _set_tab(tix), false, UiKit.ACCENT)
		tb.custom_minimum_size = Vector2(150, 46)
		trow.add_child(tb)
		_tab_btns.append(tb)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 14)
		pv.add_child(box)
		_tab_boxes.append(box)
	v = _tab_boxes[0]

	# ── 언어 ──
	# 버튼 글자는 그 언어로 쓴 이름 그대로 둔다. 영어로 켜 놓고 돌아올 길을 찾는 사람은
	# "Korean" 이 아니라 "한국어" 를 찾는다(반대도 마찬가지).
	v.add_child(UiKit.header("언어", UiKit.ACCENT, 22))
	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.add_theme_constant_override("separation", 10)
	v.add_child(lang_row)
	var lang_names: Array = ["자동", "한국어", "English"]
	for i in lang_names.size():
		var lidx: int = i - 1          # -1 자동(기기 언어) · 0 한국어 · 1 English
		var lb := UiKit.button(String(lang_names[i]), func() -> void: _set_lang(lidx), false, UiKit.CYAN)
		if i > 0:
			lb.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			lb.set_meta("i18n_keep", true)
		lb.custom_minimum_size = Vector2(150, 46)
		UiFont.apply(lb, 17)
		lang_row.add_child(lb)
		_lang_btns.append(lb)

	# ── 캐릭터 그림 (시범) ──
	# 새 캐릭터 에셋을 몇 자리에만 붙여 본 시범판이다. 같은 기기에서 예전 그림과 바로 견주게 둔다.
	# ★ 14차: 「캐릭터 그림 (시범) 기존 그림 / 새 에셋」은 개발용 스위치다 — --dev 로 켰을 때만 보인다
	var dev_ui: bool = "--dev" in OS.get_cmdline_user_args()
	var cf_head := UiKit.header("캐릭터 그림 (시범)", UiKit.ACCENT, 22)
	cf_head.visible = dev_ui
	v.add_child(cf_head)
	var cf_row := HBoxContainer.new()
	cf_row.visible = dev_ui
	cf_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cf_row.add_theme_constant_override("separation", 10)
	v.add_child(cf_row)
	var cf_names: Array = ["기존 그림", "새 에셋"]
	for i in cf_names.size():
		var on: bool = i == 1
		var cb := UiKit.button(String(cf_names[i]), func() -> void: _set_cf(on), false, UiKit.CYAN)
		cb.custom_minimum_size = Vector2(150, 46)
		UiFont.apply(cb, 17)
		cf_row.add_child(cb)
		_cf_btns.append(cb)

	# 난이도
	v.add_child(UiKit.header("기본 난이도", UiKit.ACCENT, 22))
	var diff_row := HBoxContainer.new()
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_row.add_theme_constant_override("separation", 10)
	v.add_child(diff_row)
	for i in G.DIFF_NAMES.size():
		var idx: int = i
		var b := UiKit.button(I18n.t(String(G.DIFF_NAMES[i])), func() -> void: _set_diff(idx), false, DIFF_COLORS[i])
		b.custom_minimum_size = Vector2(150, 46)
		UiFont.apply(b, 19)
		diff_row.add_child(b)
		_diff_btns.append(b)
	_diff_desc_lbl = Label.new()
	UiFont.apply(_diff_desc_lbl, 16)
	_diff_desc_lbl.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_diff_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_diff_desc_lbl)

	v.add_child(_divider())

	# 음량
	v = _tab_boxes[2]
	v.add_child(UiKit.header("마스터 음량", UiKit.ACCENT, 22))
	var vol_row := HBoxContainer.new()
	vol_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vol_row.add_theme_constant_override("separation", 14)
	v.add_child(vol_row)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = G.master_volume
	slider.custom_minimum_size = Vector2(320, 30)
	_style_slider(slider)
	var vol_val := Label.new()
	UiFont.apply(vol_val, 20)
	vol_val.add_theme_color_override("font_color", UiKit.ACCENT)
	vol_val.custom_minimum_size = Vector2(64, 0)
	vol_val.text = "%d%%" % int(round(G.master_volume * 100.0))
	slider.value_changed.connect(func(x: float) -> void:
		G.master_volume = x
		G.apply_volume()
		vol_val.text = "%d%%" % int(round(x * 100.0))
		G.save_game())
	vol_row.add_child(slider)
	vol_row.add_child(vol_val)

	v.add_child(_divider())

	# 조준 방식
	v = _tab_boxes[3]
	v.add_child(UiKit.header("조준 방식", UiKit.ACCENT, 22))
	var aim_row := HBoxContainer.new()
	aim_row.alignment = BoxContainer.ALIGNMENT_CENTER
	aim_row.add_theme_constant_override("separation", 10)
	v.add_child(aim_row)
	var aim_names: Array = ["자동 조준", "수동 조준 (마우스)"]
	for i in 2:
		var aidx: int = i
		var ab := UiKit.button(String(aim_names[i]), func() -> void: _set_aim(aidx), false, UiKit.CYAN)
		ab.custom_minimum_size = Vector2(200, 46)
		UiFont.apply(ab, 18)
		aim_row.add_child(ab)
		_aim_btns.append(ab)

	v.add_child(_divider())

	# ── 가독성 (S1): 인터페이스 크기 + 화면(캐릭터) 확대 — 모바일은 기본 '크게' ──
	v = _tab_boxes[1]
	v.add_child(UiKit.header("인터페이스 크기 (글자·게이지·카드)", UiKit.ACCENT, 22))
	var uis_row := HBoxContainer.new()
	uis_row.alignment = BoxContainer.ALIGNMENT_CENTER
	uis_row.add_theme_constant_override("separation", 10)
	v.add_child(uis_row)
	var uis_names: Array = ["보통", "크게", "아주 크게"]
	# 11/5: 인터페이스 크기는 한 칸씩 내려 「작게 · 보통 · 크게」(기본이 가운데) — game.gd ui_scale_default
	var ui_names: Array = ["작게", "보통", "크게"]
	for i in ui_names.size():
		var uidx: int = i
		var ub := UiKit.button(String(ui_names[i]), func() -> void: _set_uis(uidx), false, UiKit.CYAN)
		ub.custom_minimum_size = Vector2(150, 46)
		UiFont.apply(ub, 17)
		uis_row.add_child(ub)
		_uis_btns.append(ub)

	v.add_child(UiKit.header("화면 확대 (캐릭터·몬스터 크기)", UiKit.ACCENT, 22))
	var zoom_row := HBoxContainer.new()
	zoom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	zoom_row.add_theme_constant_override("separation", 10)
	v.add_child(zoom_row)
	for i in uis_names.size():
		var zidx: int = i
		var zb := UiKit.button(String(uis_names[i]), func() -> void: _set_zoom(zidx), false, UiKit.CYAN)
		zb.custom_minimum_size = Vector2(150, 46)
		UiFont.apply(zb, 17)
		zoom_row.add_child(zb)
		_zoom_btns.append(zb)
	var zoom_hint := Label.new()
	zoom_hint.text = "확대할수록 크게 보이는 대신 시야가 좁아집니다 · 모바일 기본값: 크게"
	UiFont.apply(zoom_hint, 13)
	zoom_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	zoom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(zoom_hint)

	# ── 가상 조이스틱 응답 (터치 기기에서만) ──
	# 예전엔 반경 165px·곡선 1.45 고정이라 "끝까지 땡겨야 속도가 난다"가 맞는 동작이었다.
	# 탄막 회피물에서는 이동속도가 곧 방어라, 기본을 '표준'으로 낮추고 옛 감각은 '정밀'로 남겼다.
	if G.mobile:
		# ── 조이스틱 자리 ──
		# 예전엔 따라오는 방식뿐이었다. 엄지를 아무 데나 올려도 되는 대신 화면에 기준점이 없어서
		# 방향을 감으로 잡아야 한다 — 탄막을 보면서 엄지를 볼 수는 없다.
		v = _tab_boxes[3]
		v.add_child(UiKit.header("조이스틱 자리", UiKit.ACCENT, 22))
		var fix_row := HBoxContainer.new()
		fix_row.alignment = BoxContainer.ALIGNMENT_CENTER
		fix_row.add_theme_constant_override("separation", 10)
		v.add_child(fix_row)
		for i in 2:
			var fidx: int = i
			var fnm: String = "고정" if i == 0 else "따라옴"
			var fb := UiKit.button(fnm, func() -> void: _set_stickfix(fidx), false, UiKit.CYAN)
			fb.custom_minimum_size = Vector2(150, 46)
			UiFont.apply(fb, 17)
			fix_row.add_child(fb)
			_stickfix_btns.append(fb)
		var fix_hint := Label.new()
		fix_hint.text = "고정은 왼쪽 아래 한 자리 · 따라옴은 처음 누른 자리가 가운데"
		UiFont.apply(fix_hint, 13)
		fix_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		fix_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(fix_hint)

		v.add_child(UiKit.header("조이스틱 반응", UiKit.ACCENT, 22))
		var stick_row := HBoxContainer.new()
		stick_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stick_row.add_theme_constant_override("separation", 10)
		v.add_child(stick_row)
		for i in TouchControls.STICK_PRESETS.size():
			var sidx: int = i
			var nm: String = String((TouchControls.STICK_PRESETS[i] as Dictionary)["name"])
			var sb := UiKit.button(nm, func() -> void: _set_stick(sidx), false, UiKit.CYAN)
			sb.custom_minimum_size = Vector2(150, 46)
			UiFont.apply(sb, 17)
			stick_row.add_child(sb)
			_stick_btns.append(sb)
		var stick_hint := Label.new()
		stick_hint.text = "정밀은 끝까지 밀어야 최고 속도 · 즉각은 살짝만 밀어도 최고 속도"
		UiFont.apply(stick_hint, 13)
		stick_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		stick_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(stick_hint)
		v.add_child(_divider())

	# ── 창 모드 (PC 전용) ──
	# 모바일에서 옮겨온 게임이라 이 항목이 아예 없었다. 스팀은 Alt+Tab·다중 모니터가
	# 기본이라 창으로 못 내리는 게임은 그것만으로 불만이 된다.
	if G.is_desktop():
		v = _tab_boxes[1]
		v.add_child(UiKit.header("창 모드", UiKit.ACCENT, 22))
		var win_row := HBoxContainer.new()
		win_row.alignment = BoxContainer.ALIGNMENT_CENTER
		win_row.add_theme_constant_override("separation", 10)
		v.add_child(win_row)
		var win_names: Array = ["창", "전체화면"]
		for i in win_names.size():
			var widx: int = i
			var wb := UiKit.button(String(win_names[i]), func() -> void: _set_win(widx), false, UiKit.CYAN)
			wb.custom_minimum_size = Vector2(150, 46)
			UiFont.apply(wb, 17)
			win_row.add_child(wb)
			_win_btns.append(wb)
		var win_hint := Label.new()
		win_hint.text = "F11 또는 Alt+Enter 로도 바꿀 수 있습니다"
		UiFont.apply(win_hint, 13)
		win_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		win_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(win_hint)
		# ── 11/5 스팀 피드백 5: 창 크기(해상도). 자동은 모니터에 맞춘 16:9, 나머지는 이 모니터에 들어가는 것만 ──
		v.add_child(UiKit.header("창 크기", UiKit.ACCENT, 22))
		var ws_row := HFlowContainer.new()
		ws_row.alignment = FlowContainer.ALIGNMENT_CENTER
		ws_row.add_theme_constant_override("h_separation", 10)
		ws_row.add_theme_constant_override("v_separation", 10)
		v.add_child(ws_row)
		var ws_list: Array = [Vector2i.ZERO] + G.win_size_choices()
		for sz: Vector2i in ws_list:
			var wsz: Vector2i = sz
			var nm: String = I18n.t("자동 맞춤") if sz == Vector2i.ZERO else "%d×%d" % [sz.x, sz.y]
			var sb := UiKit.button(nm, func() -> void: _set_winsize(wsz), false, UiKit.CYAN)
			sb.custom_minimum_size = Vector2(150, 46)
			UiFont.apply(sb, 17)
			sb.set_meta("win_size", sz)
			if sz != Vector2i.ZERO:
				sb.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
				sb.set_meta("i18n_keep", true)
			ws_row.add_child(sb)
			_winsize_btns.append(sb)
		_res_lbl = Label.new()
		UiFont.apply(_res_lbl, 16)
		_res_lbl.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		_res_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(_res_lbl)
		get_viewport().size_changed.connect(_update_win_visual)

	v.add_child(_divider())

	# ── 그래픽 성능 / 발열 ──
	# 프레임 상한이 없으면 120·144Hz 화면에서 두 배로 그린다. 물리는 60Hz 고정이라
	# 반응성 이득은 없고 배터리와 열만 늘어난다.
	v = _tab_boxes[1]
	v.add_child(UiKit.header("그래픽 성능", UiKit.ACCENT, 22))
	var perf_row := HBoxContainer.new()
	perf_row.alignment = BoxContainer.ALIGNMENT_CENTER
	perf_row.add_theme_constant_override("separation", 10)
	v.add_child(perf_row)
	var perf_names: Array = ["절전 30", "표준 60", "최대"]
	for i in perf_names.size():
		var pidx: int = i
		var pb := UiKit.button(String(perf_names[i]), func() -> void: _set_perf(pidx), false, UiKit.CYAN)
		pb.custom_minimum_size = Vector2(150, 46)
		UiFont.apply(pb, 17)
		perf_row.add_child(pb)
		_perf_btns.append(pb)
	var perf_hint := Label.new()
	perf_hint.text = "기기가 뜨거워지면 절전으로 · 절전은 탄환 잔상과 파티클도 함께 줄입니다"
	UiFont.apply(perf_hint, 13)
	perf_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	perf_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(perf_hint)

	v.add_child(_divider())

	# 13차 6절 7 — 접근성: 피해 숫자 · 화면 흔들림 · 번쩍임 줄이기
	v.add_child(UiKit.header("접근성", UiKit.ACCENT, 22))
	# 19차 3절 1: 「피해 숫자 — 전부 / 큰 것만 / 끄기」(큰 것 = 치명타 · 원소반응). 잘 팔린 서바이버들처럼 후반 화면을 덜 덮게.
	var drow := HBoxContainer.new()
	drow.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_theme_constant_override("separation", 10)
	v.add_child(drow)
	var dl := Label.new()
	dl.text = "피해 숫자"
	dl.custom_minimum_size = Vector2(190, 0)
	UiFont.apply(dl, 17)
	drow.add_child(dl)
	_dmgnum_btns.clear()
	for mi in 3:
		var want_m: int = mi
		var db := UiKit.button(["전부", "큰 것만", "끄기"][mi], func() -> void: _set_dmgnum(want_m), false, UiKit.CYAN)
		db.custom_minimum_size = Vector2(110, 46)
		UiFont.apply(db, 17)
		drow.add_child(db)
		_dmgnum_btns.append(db)
	# 19차 3절 1: 「내 효과 흐리게」 — 영웅 둘레에서 내 무기 이펙트를 반투명으로(기본 켬)
	for acc in [["내 효과 흐리게", "fx_dim_on", false], ["화면 흔들림", "shake_on", false], ["번쩍임 줄이기", "flash_low", true]]:
		var arow := HBoxContainer.new()
		arow.alignment = BoxContainer.ALIGNMENT_CENTER
		arow.add_theme_constant_override("separation", 10)
		v.add_child(arow)
		var al := Label.new()
		al.text = String(acc[0])
		al.custom_minimum_size = Vector2(190, 0)
		UiFont.apply(al, 17)
		arow.add_child(al)
		var key: String = String(acc[1])
		var pair: Array = []
		for on in [true, false]:
			var want: bool = on
			var ab := UiKit.button("켬" if on else "끔", func() -> void: _set_acc(key, want), false, UiKit.CYAN)
			ab.custom_minimum_size = Vector2(110, 46)
			UiFont.apply(ab, 17)
			arow.add_child(ab)
			pair.append(ab)
		# 위 「피해 숫자」 줄은 단추가 셋이라 가운데 정렬이면 이름 칸이 어긋난다 — 단추 한 칸만큼 빈칸
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(110, 0)
		arow.add_child(pad)
		_acc_btns[key] = pair
	_update_acc_visual()

	v.add_child(_divider())

	# 만렙(풀 소진) 후 레벨업 카드 — 자동선택으로 클릭 귀찮음 제거 (M37)
	v = _tab_boxes[0]
	v.add_child(UiKit.header("만렙 후 레벨업 카드", UiKit.ACCENT, 22))
	var auto_row := HBoxContainer.new()
	auto_row.alignment = BoxContainer.ALIGNMENT_CENTER
	auto_row.add_theme_constant_override("separation", 10)
	v.add_child(auto_row)
	var auto_names: Array = ["직접 선택", "자동: 회복", "자동: 골드", "자동: 랜덤"]
	for i in auto_names.size():
		var cidx: int = i
		var cb := UiKit.button(String(auto_names[i]), func() -> void: _set_auto(cidx), false, UiKit.CYAN)
		cb.custom_minimum_size = Vector2(150, 46)
		UiFont.apply(cb, 17)
		auto_row.add_child(cb)
		_auto_btns.append(cb)

	# ★ 2026-09-15: '융합 레시피 전체 공개' 버튼을 여기서 뺐다(출시 정리).
	#   코드 주석에도 "(개발/치트)"라고 적혀 있던 운영자 기능이다. 만들지도 않은 융합의
	#   도감 상세를 열어 주므로, 도감을 채우는 재미를 통째로 건너뛰게 한다.
	#   게다가 융합 12종은 이미 전부 open=true 라 '재료 공개'라는 원래 목적도 남아 있지 않았다.

	_build_info(_tab_boxes[4])

	_root.add_child(UiKit.back_button(_on_back))  # 좌상단 고정 — 전 메뉴 공통 (S6 통일)

	_set_tab(0)
	_update_diff_visual()
	_update_aim_visual()
	_update_auto_visual()
	_update_scale_visual()
	_update_perf_visual()
	_update_stick_visual()
	_update_stickfix_visual()
	_update_win_visual()


## 인터페이스 크기 (S1) — 즉시 반영 (HUD 스케일러가 신호 수신)
func _set_uis(i: int) -> void:
	G.set_ui_scale(i)
	_update_scale_visual()


## 화면 확대 (S1) — 카메라 줌 즉시 반영
func _set_zoom(i: int) -> void:
	G.set_cam_zoom(i)
	_update_scale_visual()


func _update_scale_visual() -> void:
	var ui_cur: int = G.ui_scale_idx if G.ui_scale_idx >= 0 else G.ui_scale_default()
	var zm_cur: int = G.cam_zoom_idx if G.cam_zoom_idx >= 0 else (1 if G.mobile else 0)
	for i in _uis_btns.size():
		var b: Button = _uis_btns[i]
		UiKit.choice(b, i == ui_cur)
	for i in _zoom_btns.size():
		var b2: Button = _zoom_btns[i]
		UiKit.choice(b2, i == zm_cur)


## 조이스틱 자리 — 즉시 반영 (다음 터치부터)
func _set_lang(i: int) -> void:
	if i == G.lang_idx:
		return
	G.set_lang(i)
	# 이미 그려진 화면 가운데 코드가 조합한 문구("레벨 %d" % n 같은 것)는 저절로 안 바뀐다.
	# 씬을 다시 불러 메인 메뉴부터 새 언어로 그린다.
	_end_paused_run()   # QA 10/13: 일시정지 → 메인 메뉴 → 설정이면 판이 살아 있다
	get_tree().paused = false
	get_tree().reload_current_scene()


func _set_cf(on: bool) -> void:
	if on == G.cf_on:
		return
	G.set_cf(on)
	# 이미 만든 영웅 카드·도감 그림은 저절로 안 바뀐다 — 언어처럼 씬을 다시 연다.
	_end_paused_run()
	get_tree().paused = false
	get_tree().reload_current_scene()


## 멈춰 둔 판이 있으면(일시정지 → 메인 메뉴 → 설정) 다시 불러오기 전에 그 판 골드를 적립하고 판을 끝낸다.
func _end_paused_run() -> void:
	if G.running:
		G.bank_run_gold()
		G.running = false


func _update_cf_visual() -> void:
	var cur: int = 1 if G.cf_on else 0
	for i in _cf_btns.size():
		var b: Button = _cf_btns[i]
		UiKit.choice(b, i == cur)


func _update_lang_visual() -> void:
	var cur: int = G.lang_idx + 1
	for i in _lang_btns.size():
		var b: Button = _lang_btns[i]
		UiKit.choice(b, i == cur)


func _set_stickfix(i: int) -> void:
	G.set_stick_fixed(i)
	_update_stickfix_visual()


func _update_stickfix_visual() -> void:
	var cur: int = 0 if G.stick_fixed() else 1
	for i in _stickfix_btns.size():
		var b: Button = _stickfix_btns[i]
		UiKit.choice(b, i == cur)


## 조이스틱 반응 — 즉시 반영 (다음 터치부터 새 반경/곡선)
func _set_stick(i: int) -> void:
	G.set_stick(i)
	_update_stick_visual()


func _update_stick_visual() -> void:
	var cur: int = G.stick_preset()
	for i in _stick_btns.size():
		var b: Button = _stick_btns[i]
		UiKit.choice(b, i == cur)


## 창 모드 — 즉시 반영 + 저장 (0 창 / 1 전체화면)
func _set_win(i: int) -> void:
	G.set_fullscreen(i == 1)
	_update_win_visual()


func _update_win_visual() -> void:
	var cur: int = 1 if G.fullscreen else 0
	for i in _win_btns.size():
		var b: Button = _win_btns[i]
		UiKit.choice(b, i == cur)
	# 창 크기: 전체 화면이면 고를 수 없다(늘 모니터 해상도). 창을 끌어 바꾼 크기면 어느 칸에도 불이 안 들어온다.
	for b2: Button in _winsize_btns:
		var sz: Vector2i = b2.get_meta("win_size", Vector2i.ZERO)
		b2.disabled = G.fullscreen
		UiKit.choice(b2, not G.fullscreen and sz == G.win_size)
	if _res_lbl != null and is_instance_valid(_res_lbl) and DisplayServer.get_name() != "headless":
		var ws: Vector2i = DisplayServer.window_get_size()
		_res_lbl.text = (I18n.t("지금 %d×%d 전체 화면 (모니터 해상도)") if G.fullscreen else I18n.t("지금 %d×%d 창")) % [ws.x, ws.y]


func _set_winsize(sz: Vector2i) -> void:
	if G.fullscreen:
		return
	G.set_win_size(sz)
	_update_win_visual.call_deferred()


## 탭
const TAB_NAMES: Array = ["일반", "화면", "소리", "조작", "정보"]   # 16차 4-8: 정보 = 만든 사람 · 글꼴 · 엔진 · 라이선스 전문


## 정보 탭 — 크레딧 · 쓴 글꼴과 엔진 · 소리 출처 · 라이선스 전문(갈무리 OFL · Godot MIT · 엔진 안의 제3자 구성 요소).
## 라이선스 전문은 영어 원문 그대로 둔다(번역하면 원문이 아니게 된다).
func _build_info(box: VBoxContainer) -> void:
	var ver: String = str(ProjectSettings.get_setting("application/config/version", ""))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.custom_minimum_size = Vector2(760, 0)
	rt.selection_enabled = false
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.apply(rt, 16)
	rt.add_theme_color_override("default_color", UiKit.TEXT)
	var h: String = "[color=#f0d488]%s[/color]\n"
	var t: String = ""
	t += h % I18n.t("이면 : 요괴 서바이버") + ("%s\n\n" % ver if ver != "" else "\n")
	t += h % I18n.t("만든 사람")
	t += I18n.t("개발 · 배급  AN TAEUK") + "\n\n"
	t += h % I18n.t("글꼴")
	t += I18n.t("갈무리(Galmuri) · Lee Minseo · SIL Open Font License 1.1 · 게임 안 모든 글자") + "\n"
	t += I18n.t("Black Han Sans · Zess Type · SIL Open Font License 1.1 · 로고 글자 모양") + "\n\n"
	t += h % I18n.t("엔진")
	t += "Godot Engine %s · MIT License\n\n" % Engine.get_version_info().get("string", "")
	t += h % I18n.t("소리")
	t += I18n.t("효과음은 게임 코드로 직접 만든 소리입니다. 음악은 쓰지 않았습니다.") + "\n\n"
	t += h % I18n.t("라이선스 전문")
	var ofl: String = FileAccess.get_file_as_string("res://assets/fonts/galmuri/OFL.txt")
	if ofl != "":
		t += "[color=#b49a64]Galmuri: SIL Open Font License 1.1[/color]\n" + _bb_safe(ofl) + "\n\n"
	t += "[color=#b49a64]Godot Engine[/color]\n" + _bb_safe(Engine.get_license_text()) + "\n\n"
	t += "[color=#b49a64]Godot Engine: third-party components[/color]\n"
	for comp: Dictionary in Engine.get_copyright_info():
		var parts: Array = []
		for pt: Dictionary in comp.get("parts", []):
			for c in pt.get("copyright", []):
				parts.append(String(c))
			parts.append("License: " + String(pt.get("license", "")))
		t += "%s: %s\n" % [String(comp.get("name", "")), _bb_safe("; ".join(parts))]
	var lic: Dictionary = Engine.get_license_info()
	for k in lic.keys():
		t += "\n[color=#b49a64]%s[/color]\n%s\n" % [String(k), _bb_safe(String(lic[k]))]
	rt.text = t
	box.add_child(rt)


## BBCode 안에 원문을 그대로 넣으려면 여는 대괄호만 바꾼다.
static func _bb_safe(s: String) -> String:
	return s.replace("[", "[lb]")
var _tab_btns: Array = []
var _tab_boxes: Array = []

func _set_tab(i: int) -> void:
	for k in _tab_boxes.size():
		(_tab_boxes[k] as Control).visible = k == i
		var b: Button = _tab_btns[k]
		UiKit.tab(b, k == i)


## 접근성 켜고 끄기 — G 의 값 이름 그대로(fx_dim_on · shake_on · flash_low)
var _acc_btns: Dictionary = {}
var _dmgnum_btns: Array = []


## 피해 숫자 세 단계 — 0 전부 · 1 큰 것만 · 2 끄기. show_dmgnum 은 끄기가 아니면 켬.
func _set_dmgnum(m: int) -> void:
	G.dmgnum_mode = clampi(m, 0, 2)
	G.show_dmgnum = G.dmgnum_mode != 2
	G.save_game()
	_update_acc_visual()

func _set_acc(key: String, on: bool) -> void:
	G.set(key, on)
	G.save_game()
	_update_acc_visual()


func _update_acc_visual() -> void:
	for i in _dmgnum_btns.size():
		UiKit.choice(_dmgnum_btns[i] as Button, i == G.dmgnum_mode)
	for key: String in _acc_btns.keys():
		var cur: bool = bool(G.get(key))
		var pair: Array = _acc_btns[key]
		for i in pair.size():
			var b: Button = pair[i]
			var sel: bool = (i == 0) == cur
			UiKit.choice(b, sel)


## 그래픽 성능 — 즉시 반영 (Engine.max_fps + 이펙트 밀도)
func _set_perf(i: int) -> void:
	G.set_perf(i)
	_update_perf_visual()


func _update_perf_visual() -> void:
	var cur: int = G.perf_level()
	for i in _perf_btns.size():
		var b: Button = _perf_btns[i]
		UiKit.choice(b, i == cur)


func _set_auto(i: int) -> void:
	G.auto_card = i
	G.save_game()
	_update_auto_visual()


func _update_auto_visual() -> void:
	for i in _auto_btns.size():
		var b: Button = _auto_btns[i]
		UiKit.choice(b, i == G.auto_card)


## 골드 반투명 구분선
func _divider() -> HSeparator:
	var sep := HSeparator.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.35)
	ss.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", ss)
	return sep


## 슬라이더 트랙/그래버 골드 테마
func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.09, 0.09, 0.12)
	track.set_corner_radius_all(5)
	track.set_border_width_all(1)
	track.border_color = Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.5)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(UiKit.ACCENT.r, UiKit.ACCENT.g, UiKit.ACCENT.b, 0.9)
	fill.set_corner_radius_all(5)
	fill.content_margin_top = 5
	fill.content_margin_bottom = 5
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var grab := _grabber_tex(UiKit.ACCENT)
	s.add_theme_icon_override("grabber", grab)
	s.add_theme_icon_override("grabber_highlight", _grabber_tex(Color.WHITE))


## 원형 그래버 텍스처 생성
func _grabber_tex(col: Color) -> ImageTexture:
	var d := 18
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := d / 2.0
	for y in d:
		for x in d:
			var dist := Vector2(x - r + 0.5, y - r + 0.5).length()
			if dist <= r - 0.5:
				img.set_pixel(x, y, col)
			elif dist <= r:
				img.set_pixel(x, y, Color(col.r, col.g, col.b, 0.5))
	return ImageTexture.create_from_image(img)


func _lbl(parent: Node, text: String, size: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	UiFont.apply(l, size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)


func _set_diff(i: int) -> void:
	# [감사 C6] 진행 중인 판의 난이도(G.difficulty)는 바꾸지 않는다(클리어 기록 · 보상 위조 차단).
	#   11/5: 고른 난이도(diff_pref)는 판 중에도 바꿀 수 있고 다음 판부터 쓴다.
	G.diff_pref = i
	if not G.running:
		G.difficulty = i
	G.save_game()
	_update_diff_visual()
	_update_aim_visual()


func _set_aim(i: int) -> void:
	G.aim_mode = i
	G.save_game()
	_update_aim_visual()


func _update_aim_visual() -> void:
	for i in _aim_btns.size():
		var b: Button = _aim_btns[i]
		UiKit.choice(b, i == G.aim_mode)


func _update_diff_visual() -> void:
	for i in _diff_btns.size():
		var b: Button = _diff_btns[i]
		UiKit.choice(b, i == G.diff_pref)
	if _diff_desc_lbl != null:
		var dtxt: String = I18n.t(String(G.DIFF_DESC[clampi(G.diff_pref, 0, G.DIFF_MAX)]))
		if G.running and G.diff_pref != G.difficulty:
			dtxt += "\n" + I18n.t("지금 판은 %s 그대로, 다음 판부터 바뀌어요") % I18n.t(String(G.DIFF_NAMES[clampi(G.difficulty, 0, G.DIFF_MAX)]))
		_diff_desc_lbl.text = dtxt


func open() -> void:
	_root.visible = true
	get_tree().paused = true
	_update_diff_visual()
	_update_aim_visual()
	_update_auto_visual()
	_update_scale_visual()
	_update_perf_visual()
	_update_stick_visual()
	_update_stickfix_visual()
	_update_win_visual()
	_update_lang_visual()
	_update_cf_visual()
	UiKit.focus_first(_root)   # 패드로 메뉴를 넘길 시작점


func is_open() -> bool:
	return _root != null and _root.visible


func _unhandled_input(event: InputEvent) -> void:  # ESC로 닫기 (S5)
	if is_open() and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):   # 16차: 패드 B 도 뒤로
		_on_back()
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	_root.visible = false
	closed.emit()
