class_name MainMenu
extends CanvasLayer
## 최상위 메인 메뉴 (UiKit 디자인 시스템 + 게임 톤 배경/영웅 퍼레이드).
## 각 버튼은 시그널만 방출하고 실제 처리는 main.gd가 한다.

signal new_game
signal new_char
signal continue_game
signal open_shop
signal open_settings
signal open_codex
signal quit_game

var _root: Control
var _stats_lbl: Label
var _gold_lbl: Label
var _continue_btn: Button
var _codex_btn: Button   # 퀘스트 보상 배지 표시용 (S5)
var _can_continue: bool = false
var update_check := PlayUpdateCheck.new()   # 19차 5절: 메인 화면을 열 때 플레이 새 버전 확인(안드로이드만)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 22
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	add_child(update_check)
	update_check.setup(_root)

	# ── 배경 ──
	# ★ 예전엔 그라데이션 + 먼지 + 발치의 작은 영웅들이 전부라 화면 가운데가 통째로 비어 있었다.
	#   대기화면이 게임의 첫인상인데 "무슨 게임인지"가 한 장면도 없었다(2026-09-07 지적).
	#   최종 보스(네페르의 용)를 뒤에 크게 세운다 — 아이콘과 같은 놈이라 첫 화면과
	#   런처 아이콘이 한 얼굴로 이어진다. 어둡게 깔아 글자를 안 잡아먹게 한다.
	_root.add_child(UiKit.gradient_bg())
	# ★ 15차 6절 1: 목업 menu.png 의 밤 마당(달 · 소나무 · 석등 · 돌 마당, survivor_ui/menu_bg). 스팀 헤더 캡슐과
	#   같은 그림이라 상점에서 본 그림이 첫 화면으로 이어진다. 그림 그대로 깐다(어둡게 누르기 · 불티 · 가장자리 그늘 없음 — 목업).
	var mb: Control = _menu_bg_backdrop()
	if mb != null:
		_root.add_child(mb)
	else:
		# ★ 2026-10-03: 뒤 배경을 대표 그림(사당 위의 용, tools/make_keyart.py)으로 바꿨다.
		#   예전 용(final_dragon.png)은 오려 낸 한 컷이라 몸이 조각나 있었고, 크게 키우니 깨진 그림으로
		#   보였다("용가리도 깨진 이미지 그대로"). 그림이 없으면 예전 배경으로 돌아간다.
		var ka: Control = _keyart_backdrop()
		_root.add_child(ka if ka != null else _boss_backdrop())
		_root.add_child(UiKit.motes(Vector2(640, 360), Vector2(720, 430)))
		_root.add_child(_embers())
		# 발치의 영웅 행렬은 대표 그림이 들어오면서 뺐다 — 옛 작은 그림이 사당 마당 위에서 잡음이 됐다.
		if ka == null:
			_root.add_child(_hero_parade())
		_root.add_child(UiKit.vignette())

	# ── 콘텐츠 ── 14차 2절 13: 목업 menu.png 배치
	# ★ 13차엔 가운데 정렬 기둥(로고 → 글 → 버튼 | 영웅)이라 영웅 셋이 바닥 없이 공중에 떠 있었다(에셋 담당).
	#   왼쪽: 로고 · 한 줄 · 버튼 기둥(나무 패) · 이어하기 카드 / 오른쪽 아래: 사당 마당 위 영웅 셋 + 발밑 그림자.
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.position = Vector2(64, 36)
	_root.add_child(col)
	# 스토어 캡슐·런처 아이콘과 같은 도트 로고(tools/make_brand.py) — 그림이 없으면 예전 글자로.
	col.add_child(_title_band(_title_logo()))
	var sub := Label.new()
	sub.text = "스테이지를 정복하고, 무한 모드에서 30분을 버텨라"
	if G.is_demo():   # 19차 4-2 체험판: 무엇이 들어 있는지 첫 화면에서
		sub.text = "체험판에서는 첫 스테이지와 영웅 둘, 무한 모드 15분까지"
	UiFont.apply(sub, 17)
	sub.add_theme_color_override("font_color", UiParts.PAPER)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title_band(sub))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	col.add_child(spacer)

	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	btns.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(btns)
	btns.add_child(UiParts.with_icon(UiKit.button("출격", func() -> void: new_char.emit(), true), "play"))
	if G.is_demo():   # 체험판의 목적은 찜하기다 — 출격 바로 밑
		btns.add_child(UiParts.with_icon(UiKit.button("정식판 찜하기", func() -> void: SteamHub.open_store_page(), true), "star_full"))
	btns.add_child(UiParts.with_icon(UiKit.button("영구 강화", func() -> void: open_shop.emit()), "shop"))
	_codex_btn = UiParts.with_icon(UiKit.button("도감", func() -> void: open_codex.emit()), "dex")
	btns.add_child(_codex_btn)
	btns.add_child(UiParts.with_icon(UiKit.button("설정", func() -> void: open_settings.emit()), "gear"))
	btns.add_child(UiParts.with_icon(UiKit.button("종료", func() -> void: quit_game.emit(), false, UiKit.DANGER), "exit"))
	# 이어하기 — 이어할 판이 있을 때만, 버튼 기둥 밑 카드(판 정보 한 줄 · 목업)
	_continue_btn = UiKit.button("이어하기", func() -> void: continue_game.emit())
	_continue_btn.custom_minimum_size = Vector2(330, 64)
	_continue_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiFont.apply(_continue_btn, 20)    # 목업: 버튼 글자보다 한 단 작은 두 줄
	var cbox: StyleBoxTexture = UiParts.box("panel_small", 2)
	if cbox != null:
		for st in ["normal", "pressed", "disabled"]:
			_continue_btn.add_theme_stylebox_override(st, cbox)
		var chov: StyleBoxTexture = cbox.duplicate()
		chov.modulate_color = Color(1.18, 1.18, 1.18)
		_continue_btn.add_theme_stylebox_override("hover", chov)
	# 10/13: 판 도중 메인 메뉴로 나오면 「이어하기」 가 맨 아래 「종료」(빨강) 밑에 있었고 금색 「출격」 이 더 눈에 띄었다 —
	#   판을 이어 가려던 사람이 새 판을 누르기 쉬웠다. 맨 위에 두고(패드 첫 포커스도 여기) 글자를 금빛으로.
	_continue_btn.add_theme_color_override("font_color", UiParts.BRASS_HI)
	btns.add_child(_continue_btn)
	btns.move_child(_continue_btn, 0)

	var trio: Control = _hero_trio()
	trio.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	trio.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	trio.grow_vertical = Control.GROW_DIRECTION_BEGIN
	trio.offset_right = -110.0
	# 돌 마당: 그림 아래에서 약 60 그림 px(README) = 화면 높이의 60/540 — 그림자 밑이 그 줄에 닿게
	trio.offset_bottom = -78.0
	_root.add_child(trio)




## 도트 로고(가로형). 언어에 맞는 판을 고르고 **정수배(2배)** 로만 키운다 —
## 1280×720 기준 2배 = 1080p 에서 3배라 도트 한 칸이 화면 3px 로 고르게 선다.
## 그림이 없으면(지운 경우) 예전처럼 글자 제목.
const LOGO_K: int = 2

func _title_logo() -> Control:
	var path: String = "res://assets/brand/logo_row_%s.png" % ("en" if G.lang() == "en" else "ko")
	if not ResourceLoader.exists(path):
		return UiKit.title("이면 : 요괴 서바이버", 60)
	var tex: Texture2D = load(path)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(tex.get_width(), tex.get_height()) * float(LOGO_K)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## 제목 뒤에 깔리는 어두운 띠 — 가운데가 짙고 좌우로 사라진다. 글자만 또렷해지고
## 배경 용은 그대로 비친다. 그리고 아주 느리게 밝아졌다 어두워져서 화면이 죽어 보이지 않게 한다.
func _title_band(inner: Control) -> Control:
	var wrap := CenterContainer.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.0))
	g.add_point(0.5, Color(0.02, 0.01, 0.03, 0.72))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.0, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 1
	var band := TextureRect.new()
	band.texture = gt
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.custom_minimum_size = Vector2(maxf(330.0, inner.get_combined_minimum_size().x + 60.0), maxf(40.0, inner.get_combined_minimum_size().y + 16.0))
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(band)
	wrap.add_child(inner)
	var tw := inner.create_tween().set_loops()
	tw.tween_property(inner, "modulate", Color(1.14, 1.10, 1.0, 1.0), 2.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(inner, "modulate", Color(1, 1, 1, 1), 2.2).set_trans(Tween.TRANS_SINE)
	return wrap


## 메뉴 배경(15차) — 960×540(16:9) · 1170×540(폰 와이드). 화면 높이에 맞춰 덮는다: 1080 화면이면 그림 1px = 화면 2px(정수).
## 화면이 16:9 보다 넓으면 와이드 판을 쓴다. 그림이 없으면 null(예전 대표 그림으로).
const MENU_BG_DIR: String = "res://assets/ui/menu_bg/"

func _menu_bg_backdrop() -> Control:
	var vp: Vector2 = get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1280, 720)
	var wide: bool = vp.x / maxf(1.0, vp.y) > 1.9
	var path: String = MENU_BG_DIR + ("menu_bg_wide.png" if wide else "menu_bg_16x9.png")
	if not ResourceLoader.exists(path):
		path = MENU_BG_DIR + "menu_bg_16x9.png"
		if not ResourceLoader.exists(path):
			return null
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## 대표 그림 — 320×180 도트를 **정확히 4배**(1280×720)로 깐다. 화면이 더 넓으면 양옆은 밤색 바탕.
## 버튼·글자가 그림 위에 올라가므로 어둡게 누르고, 숨 쉬듯 아주 천천히 밝아졌다 어두워진다(크기는 안 바꾼다).
const KEYART_PATH: String = "res://assets/brand/keyart.png"
const KEYART_DIM: Color = Color(0.62, 0.58, 0.60, 1.0)
## 대표 그림 가장자리(밤하늘) 색. 화면이 그림보다 넓거나 그림을 내려 위가 비면 이 색으로 채운다 — 경계선이 안 보인다.
const KEYART_EDGE: Color = Color8(11, 10, 16)

func _keyart_backdrop() -> Control:
	if not ResourceLoader.exists(KEYART_PATH):
		return null
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.modulate = KEYART_DIM          # 어둡게 누르기·숨쉬기는 바탕과 그림에 같이 건다
	var edge := ColorRect.new()
	edge.color = KEYART_EDGE
	edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(edge)
	var tex: Texture2D = load(KEYART_PATH)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var sz := Vector2(tex.get_width(), tex.get_height()) * 4.0
	tr.custom_minimum_size = sz
	tr.size = sz
	tr.set_anchors_preset(Control.PRESET_CENTER)
	# 40 내린다 — 용 얼굴이 제목 아래 안내 문구에 겹치지 않고 그 밑 복도에 보이게. 위로 생긴 틈은 원래 밤하늘이다.
	tr.position = -sz * 0.5 + Vector2(0, 40)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(tr)
	var tw := wrap.create_tween().set_loops()
	tw.tween_property(wrap, "modulate", KEYART_DIM.lightened(0.10), 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(wrap, "modulate", KEYART_DIM, 3.0).set_trans(Tween.TRANS_SINE)
	return wrap


## (예전 배경 — 대표 그림이 없을 때만) 뒤에 버티고 선 최종 보스.
## 밝기는 낮게 — 배경은 배경이어야 하고, 읽어야 하는 것은 버튼과 글자다.
func _boss_backdrop() -> Control:
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 캐릭터 에셋 자리면 최종 보스(kind 5)의 정지 자세를 정수배로 크게 깐다.
	var cf: String = CharForge.enemy_id(5)
	if cf != "":
		var an: Dictionary = CharForge.anim(cf, "anchor")
		var k: int = maxi(1, int(660.0 / float(maxi(int(an["fw"]), int(an["fh"])))))
		var fig: Control = CharForge.figure(cf, "anchor", k)
		fig.set_anchors_preset(Control.PRESET_CENTER)
		fig.position = Vector2(-fig.size.x * 0.5, -fig.size.y * 0.5 - 34.0)
		fig.modulate = Color(1.0, 0.74, 0.52, 0.34)
		# 숨쉬기 확대는 걸지 않는다 — 큰 도트를 소수배로 키우면 화면 전체가 끓는다
		wrap.add_child(fig)
		return wrap
	var path: String = "res://assets/sprites/monsters/final_dragon.png"
	if not ResourceLoader.exists(path):
		return wrap
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # 픽셀아트 — 부드럽게 늘리면 죽는다
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_CENTER)
	# ★ 처음엔 620px 로 화면 정중앙에 뒀는데 버튼과 능력치 패널이 그 자리를 정확히 덮어서
	#   기둥 사이 틈으로만 보였다 — 그림으로 찍어 보고 알았다(2026-09-07).
	#   UI 가 안 쓰는 자리는 **위쪽 제목 띠와 좌우 가장자리**다. 크게 키워 위로 올리면
	#   날개가 제목 뒤로 펼쳐지고 몸통만 버튼에 가린다 — 그게 오히려 깊이가 된다.
	#   900px 은 너무 컸다 — 날개 끝과 머리가 화면 밖으로 나가서 주황색 무늬로만 보였다.
	#   실루엣이 **통째로** 들어와야 용으로 읽힌다. 720 세로에 맞춰 660 으로 잡고
	#   살짝만 올린다(머리는 제목 뒤, 발은 버튼 아래).
	#   ★ 2026-10-03: 660 은 204px 그림의 3.24배라 칸마다 굵기가 달랐고, 숨쉬기를 크기로 해서
	#     도트가 계속 지글거렸다. 정수배 3배(612)로 고정하고 숨쉬기는 밝기로 한다.
	var W: float = float((tr.texture as Texture2D).get_width() * 3)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(W, W)
	tr.size = Vector2(W, W)
	tr.position = Vector2(-W * 0.5, -W * 0.5 - 30.0)
	tr.modulate = Color(1.0, 0.74, 0.52, 0.34)   # 어둡고 붉게 — 글자를 안 잡아먹는다
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(tr)
	# 숨 — 6초에 한 번 아주 살짝 밝아진다. 빠르면 배경이 아니라 방해물이 된다.
	var tw := tr.create_tween().set_loops()
	tw.tween_property(tr, "modulate", Color(1.0, 0.80, 0.58, 0.42), 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(tr, "modulate", Color(1.0, 0.74, 0.52, 0.34), 3.0).set_trans(Tween.TRANS_SINE)
	return wrap


## 위로 흐르는 불티. 용이 뒤에 있으니 공기도 그 온도여야 한다.
func _embers() -> Control:
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := CPUParticles2D.new()
	p.amount = 46
	p.lifetime = 5.5
	p.preprocess = 5.5            # 열자마자 이미 떠 있게 — 안 그러면 첫 5초가 텅 빈다
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(660, 12)
	p.position = Vector2(640, 740)
	p.direction = Vector2(0, -1)
	p.spread = 16.0
	p.gravity = Vector2(0, -26)
	p.initial_velocity_min = 22.0
	p.initial_velocity_max = 64.0
	p.scale_amount_min = 1.4
	p.scale_amount_max = 3.4
	p.color = Color(1.0, 0.62, 0.26, 0.55)
	wrap.add_child(p)
	return wrap


## 하단 영웅 6종 퍼레이드 (게임 아트 노출 → 폼 느낌 탈피)
func _hero_parade() -> Control:
	var parade := HBoxContainer.new()
	parade.add_theme_constant_override("separation", 22)
	parade.alignment = BoxContainer.ALIGNMENT_CENTER
	parade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	parade.offset_top = -132
	parade.offset_bottom = -14
	parade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 캐릭터 에셋 자리면 실제 영웅들의 정지 자세(×2)를 세운다 — 옛 영웅 그림은 지금 게임에 없는 얼굴들이다.
	var cast_heroes: Array = []
	for d: Dictionary in Characters.defs():
		var hcf: String = CharForge.hero_id(String(d["id"]))
		if hcf != "":
			cast_heroes.append(hcf)
	if not cast_heroes.is_empty():
		for hcf2 in cast_heroes.slice(0, 9):
			var fig := CharForge.figure(String(hcf2), "anchor", 2)
			fig.modulate = Color(1, 1, 1, 0.5)
			var box := CenterContainer.new()
			box.custom_minimum_size = Vector2(96, 108)
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(fig)
			parade.add_child(box)
		return parade
	var names: Array = ["1", "2", "3", "4", "5", "6", "knight", "wizard", "rogue"]
	for i in names.size():
		var p: String = "res://assets/sprites/chars/%s.png" % String(names[i])
		if not ResourceLoader.exists(p):
			continue
		var tr := TextureRect.new()
		tr.texture = load(p)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(96, 108)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.modulate = Color(1, 1, 1, 0.5)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parade.add_child(tr)
	return parade


## 가운데가 밝은 골드 구분선
func _gold_divider(w: float) -> Control:
	var g := Gradient.new()
	g.set_color(0, Color(UiKit.ACCENT.r, UiKit.ACCENT.g, UiKit.ACCENT.b, 0.0))
	g.set_color(1, Color(UiKit.ACCENT.r, UiKit.ACCENT.g, UiKit.ACCENT.b, 0.0))
	g.add_point(0.5, UiKit.ACCENT)
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
	return tr


func _build_stats_panel() -> Control:
	var panel := UiKit.make_panel()
	# 내용만큼만 높이를 쓴다. 예전엔 버튼 줄 높이에 맞춰 늘어나서 아래 절반이 빈 상자였다.
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	panel.add_child(v)
	v.add_child(UiKit.header("현재 능력치  (영구 강화 반영)", UiKit.CYAN, 20))
	_gold_lbl = Label.new()
	UiFont.apply(_gold_lbl, 18)
	_gold_lbl.add_theme_color_override("font_color", UiKit.ACCENT)
	v.add_child(_gold_lbl)
	var sep := HSeparator.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(UiKit.PANEL_BORDER.r, UiKit.PANEL_BORDER.g, UiKit.PANEL_BORDER.b, 0.35)
	ss.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", ss)
	v.add_child(sep)
	_stats_lbl = Label.new()
	UiFont.apply(_stats_lbl, 18)
	_stats_lbl.add_theme_color_override("font_color", UiKit.TEXT)
	v.add_child(_stats_lbl)
	return panel


func set_continue_enabled(v: bool) -> void:
	_can_continue = v
	if _continue_btn != null:
		_continue_btn.visible = v      # 13차: 없으면 꺼진 버튼으로 자리를 차지하지 않는다
		_continue_btn.disabled = not v
		if v:
			var t: int = int(G.time_alive)
			var where: String = I18n.t(String(G.STAGE_NAMES[clampi(G.stage_sel, 0, G.STAGE_NAMES.size() - 1)])) if G.run_mode == "stage" else I18n.t("무한")
			_continue_btn.text = I18n.t("이어하기") + "\n" + "%s · %02d:%02d · Lv %d" % [where, t / 60, t % 60, G.level]


## 오른쪽 빈자리의 대표 영웅 셋 — 스토어 헤더 캡슐과 같은 캐스트(가운데 울레아, 양옆 갈덴 · 리콜). 서 있는 그림 ×3(정수배).
func _hero_trio() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 48)
	for hid in ["mudang", "base", "falconer"]:
		var cf: String = String(CharForge.hero_slot(hid).get("id", ""))
		if cf == "" or not CharForge.has_anim(cf, "anchor"):
			continue
		var stand := VBoxContainer.new()
		stand.add_theme_constant_override("separation", -8)    # 그림 아래 빈 2px × 2 에 그림자 반을 더 겹쳐 발이 땅에 닿게
		stand.size_flags_vertical = Control.SIZE_SHRINK_END
		stand.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fig: Control = CharForge.figure(cf, "anchor", 2)   # 14차 2절 13: ×2(1920 화면 ×3, 정수)
		fig.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		stand.add_child(fig)
		var sh := _Shadow.new()
		sh.custom_minimum_size = Vector2(72, 12)
		sh.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stand.add_child(sh)
		row.add_child(stand)
	return row


## 발밑 그림자 — 납작한 짙은 타원 한 줄(목업 「발밑 그림자 한 줄」)
class _Shadow extends Control:
	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var pts := PackedVector2Array()
		for i in 24:
			var a: float = TAU * float(i) / 24.0
			pts.append(c + Vector2(cos(a) * size.x * 0.5, sin(a) * size.y * 0.5))
		draw_colored_polygon(pts, Color(0.04, 0.02, 0.03, 0.6))


func open() -> void:
	_root.visible = true
	get_tree().paused = true
	_refresh()
	UiKit.focus_first(_root)   # 패드로 메뉴를 넘길 시작점
	update_check.check()


func close() -> void:
	_root.visible = false
	update_check._close_card()


func _refresh() -> void:
	if _gold_lbl != null:
		_gold_lbl.text = I18n.t("보유 골드   %d G") % G.total_gold
	if _stats_lbl != null:
		_stats_lbl.text = "\n".join(G.meta_stat_lines())
	# [S5] "너 받을 보상 있어!" 배지 — 수령 가능한 퀘스트 보상 수를 도감 버튼에 표시
	if _codex_btn != null:
		var n: int = G.quest_claimable_count()
		_codex_btn.text = (I18n.t("도감 (보상 %d)") % n) if n > 0 else I18n.t("도감")
	set_continue_enabled(_can_continue)
