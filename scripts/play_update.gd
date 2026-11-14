class_name PlayUpdateCheck
extends Node
## 19차 5절: 메인 화면을 열 때 구글 플레이에 새 버전이 있나 묻는다(안드로이드 · 플레이에서 깐 앱만).
##   새 버전을 이 폰이 안 지 3일 미만 → 닫을 수 있는 안내(하루 한 번). 「받기」면 유연 업데이트(뒤에서 받고 다 받으면 「다시 시작」)
##   3일 이상이거나 업데이트 우선순위 4 이상 → 세이브하고 즉시 업데이트(전체 화면). 닫으면 다음에 메인 화면을 열 때 다시
##   플레이가 답하지 않음 · 플레이 밖에서 깐 앱 · 스팀 · PC → 아무것도 안 한다
## 플레이 쪽은 addons/play_update(AAR, 소스 plugins_src/play_update). 판 도중(메뉴로 잠깐 나온 때 포함)에는 묻지도 띄우지도 않는다.

const STALE_DAYS: int = 3          # 시험 빌드(내보내기 기능 update_test)에서만 0
const PRIORITY_NOW: int = 4        # Play Developer API 로 매긴 우선순위가 이 이상이면 날 수와 상관없이 즉시
const CFG_PATH: String = "user://play_update.cfg"
const BUSY_GIVEUP_MS: int = 20000  # 플레이가 이만큼 답이 없으면 다음 메인 화면에서 다시 묻는다
const IMMEDIATE_GAP_MS: int = 300000   # 즉시 업데이트를 닫은 뒤 5분 안(상점 · 도감에서 돌아올 때)은 다시 띄우지 않는다
# 플레이 상수(com.google.android.play.core.install.model)
const AVAIL_YES: int = 2           # UpdateAvailability.UPDATE_AVAILABLE
const AVAIL_RUNNING: int = 3       # DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS — 우리가 띄운 업데이트가 진행 중
const TYPE_FLEXIBLE: int = 0
const TYPE_IMMEDIATE: int = 1
const STATUS_DOWNLOADED: int = 11
const STATUS_FAILED: int = 5

var _plugin: Object
var _host: Control                 # 안내를 얹을 곳(메인 메뉴 화면)
var _card: Control
var _busy_since: int = -1          # 플레이 답을 기다리기 시작한 때(ms), -1 = 안 기다림
var _imm_started: int = -IMMEDIATE_GAP_MS   # 즉시 업데이트를 마지막으로 띄운 때(ms)
var _downloaded: bool = false      # 유연 업데이트를 다 받음 → 메인 화면에서 「다시 시작」
var fake: bool = false             # 하니스(--updateshot): 플러그인 없이 흉내
var fake_started: Array[int] = []  # 흉내로 띄운 업데이트 종류(하니스가 센다)


func setup(host: Control) -> void:
	_host = host
	if OS.get_name() == "Android" and Engine.has_singleton("PlayUpdate"):
		_plugin = Engine.get_singleton("PlayUpdate")
		_plugin.info_ready.connect(_on_info)
		_plugin.info_failed.connect(func(msg: String) -> void:
			_busy_since = -1
			print("[PlayUpdate] 확인 못 함: %s" % msg))
		_plugin.flow_result.connect(_on_flow_result)
		_plugin.install_state.connect(_on_install_state)


func stale_days() -> int:
	return 0 if OS.has_feature("update_test") else STALE_DAYS


## 메인 화면을 열 때 부른다. 즉시 업데이트 도중 홈으로 나갔다 오면(_notification) 한 번 더.
func check() -> void:
	if (_plugin == null and not fake) or not _may_show():
		_close_card()
		return
	if _downloaded:
		_show_restart()
		return
	if fake or (_busy_since >= 0 and Time.get_ticks_msec() - _busy_since < BUSY_GIVEUP_MS):
		return
	_busy_since = Time.get_ticks_msec()
	_plugin.check()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and _menu_up():
		check()


## 판이 없고(메뉴로 잠깐 나온 판도 아님) 체험판도 아닐 때만.
func _may_show() -> bool:
	return not G.running and not G.is_demo()


func _on_info(avail: int, days: int, priority: int, flex_ok: bool, imm_ok: bool, status: int) -> void:
	_busy_since = -1
	print("[PlayUpdate] avail=%d days=%d priority=%d flex=%s imm=%s status=%d" % [avail, days, priority, flex_ok, imm_ok, status])
	if not _menu_up() or not _may_show():   # 답이 늦게 와서 그사이 출격했으면 아무것도 안 띄운다
		return
	if status == STATUS_DOWNLOADED:
		_downloaded = true
		_show_restart()
		return
	if avail == AVAIL_RUNNING:
		# 플레이는 유연 업데이트를 받는 중에도 3을 준다 — 우리가 즉시로 띄운 것만 즉시로 이어 준다
		if imm_ok and _cfg_get("last_type", TYPE_FLEXIBLE) == TYPE_IMMEDIATE:
			_start(TYPE_IMMEDIATE)
		return
	if avail != AVAIL_YES:
		return
	if imm_ok and (priority >= PRIORITY_NOW or days >= stale_days()):
		if Time.get_ticks_msec() - _imm_started >= IMMEDIATE_GAP_MS:
			_start(TYPE_IMMEDIATE)
		return
	if flex_ok and String(_cfg_get("asked_day", "")) != _today():
		_cfg_set("asked_day", _today())
		_show_offer()


func _start(type: int) -> void:
	_close_card()
	G.save_game()   # 즉시 업데이트는 끝나면 게임을 다시 켠다
	_cfg_set("last_type", type)
	if type == TYPE_IMMEDIATE:
		_imm_started = Time.get_ticks_msec()
	if fake:
		fake_started.append(type)
		print("[PlayUpdate] (흉내) start %s" % ("즉시" if type == TYPE_IMMEDIATE else "유연"))
		return
	if not bool(_plugin.start(type)):
		print("[PlayUpdate] 업데이트 창을 못 띄움 type=%d" % type)


func _on_flow_result(code: int) -> void:
	print("[PlayUpdate] flow_result=%d" % code)   # -1 받기 · 0 닫음 · 1 실패 — 닫았으면 다음 메인 화면에서 다시 묻는다


func _on_install_state(status: int) -> void:
	if status == STATUS_FAILED:
		_cfg_set("asked_day", "")   # 받다가 실패 — 오늘 다시 권해도 된다
		return
	if status != STATUS_DOWNLOADED:
		return
	_downloaded = true
	if _menu_up() and _may_show():
		_show_restart()


func _menu_up() -> bool:
	return _host != null and _host.is_visible_in_tree()


# ── 안내 카드 ── 메뉴 오른쪽 위, 닫을 수 있다
func _show_offer() -> void:
	_show_card("새 버전이 나왔어요", "받는 동안에도 계속 플레이할 수 있어요.", "받기", func() -> void: _start(TYPE_FLEXIBLE))


func _show_restart() -> void:
	_show_card("새 버전을 다 받았어요", "다시 시작하면 새 버전으로 켜져요.", "다시 시작", func() -> void:
		_close_card()
		G.save_game()
		_downloaded = false
		if fake:
			print("[PlayUpdate] (흉내) complete")
		else:
			_plugin.complete())


func _show_card(title: String, body: String, ok_text: String, ok: Callable) -> void:
	_close_card()
	if _host == null:
		return
	var p: PanelContainer = UiKit.make_panel()
	p.anchor_left = 1.0
	p.anchor_right = 1.0
	p.offset_right = -24.0
	p.offset_top = 24.0
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.custom_minimum_size = Vector2(380, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t := Label.new()
	t.text = title
	UiFont.apply(t, 22)
	t.add_theme_color_override("font_color", UiParts.BRASS_HI)
	v.add_child(t)
	var b := Label.new()
	b.text = body
	UiFont.apply(b, 17)
	b.add_theme_color_override("font_color", UiParts.PAPER)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var yes: Button = UiKit.button(ok_text, ok, true)
	var no: Button = UiKit.button("나중에", _close_card)
	for btn in [yes, no]:
		btn.custom_minimum_size.x = 170.0
		row.add_child(btn)
	_host.add_child(p)
	_card = p
	# 답은 늦게 온다 — 패드로 메뉴를 고르던 중이면 포커스를 뺏지 않는다(연타로 「받기」가 눌리지 않게)
	if _host.get_viewport().gui_get_focus_owner() == null:
		UiKit.focus_first(p)


## 메뉴를 닫을 때(출격 · 상점 등)도 부른다 — 카드가 판 안으로 따라 들어가지 않게.
func _close_card() -> void:
	if _card != null and is_instance_valid(_card):
		var had_focus: bool = _card.get_viewport().gui_get_focus_owner() != null \
			and _card.is_ancestor_of(_card.get_viewport().gui_get_focus_owner())
		_card.queue_free()
		if had_focus and _menu_up():
			UiKit.focus_first(_host)   # 메뉴 버튼이 카드보다 먼저 붙어 있어 첫 버튼으로 간다
	_card = null


# ── 기억(하루 한 번 · 마지막으로 띄운 종류) ── 날짜는 이 폰의 현지 날짜
func _today() -> String:
	return Time.get_date_string_from_system()


func _cfg_get(key: String, def: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return def
	return cfg.get_value("update", key, def)


func _cfg_set(key: String, val: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	cfg.set_value("update", key, val)
	cfg.save(CFG_PATH)


## 하니스(--updateshot): 플레이 답을 흉내 내 안내를 띄운다.
func fake_info(avail: int, days: int, priority: int = 0, status: int = 0) -> void:
	fake = true
	_on_info(avail, days, priority, true, true, status)
