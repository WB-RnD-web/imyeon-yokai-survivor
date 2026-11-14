extends Node
## 스팀 연동 — 도전과제(codex.gd ACHIEVEMENTS)를 스팀 계정에 올리고, 도전과제에 붙은 인벤토리 수집품을 받는다(11/14).
##
## ★ 이 파일의 제1원칙은 ads.gd 와 같다: 스팀이 없어도 게임은 멀쩡해야 한다.
##   GodotSteam 미설치(안드로이드·웹·헤드리스 하니스), 스팀 클라이언트 꺼짐,
##   비스팀 경로로 켠 exe — 어느 경우든 _ok 가 false 가 되고 전부 무시된다.
##   게임 로직은 이 파일의 성공 여부를 절대 묻지 않는다.
##
## ★ GodotSteam 클래스를 코드에 '직접' 쓰면 안 된다. GDScript 는 class_name 을
##   파싱 시점에 해석하므로, 확장이 없는 환경에서 Steam 을 그냥 쓰면 스크립트가
##   통째로 파싱 실패한다(= 게임이 안 켜진다). Engine.get_singleton 으로 런타임에 찾는다.
##
## 설치 방법(AppID 나온 뒤):
##   1. GodotSteam GDExtension 을 받아 addons/godotsteam/ 에 푼다
##   2. 아래 APP_ID 를 실제 AppID 로 바꾼다
##   3. 프로젝트 루트에 steam_appid.txt 를 만들고 그 숫자만 적는다 (에디터 실행용)

## 스팀에서 발급받는 AppID. 0 이면 연동을 시도하지 않는다.
## ★ 출시 전 반드시 실제 값으로 바꿔야 한다 — 0 인 채로 구우면 도전과제가 안 올라간다.
const APP_ID: int = 5428620   # 17차(10/11) 앱 생성 · IMYEON : Yokai Survivor
## 19차 4-2 체험판 앱(스팀웍스에서 본편에 딸린 Demo 로 만든다). 0 이면 체험판 빌드는 스팀에 안 붙는다(찜하기 단추는 웹으로 연다).
const DEMO_APP_ID: int = 5438980   # 19차(10/13) 체험판 앱 · 디포 5438981

var _steam: Object = null
var _ok: bool = false
var _pump: bool = false     # run_callbacks 를 직접 돌려야 하는 빌드인가
var _promo_due: int = 0     # 11/14 수집품: 이 시각(ms)이 지나면 grantPromoItems 를 한 번 부른다(0 = 예약 없음)


func _ready() -> void:
	# 헤드리스(CLI 하니스)에서는 스팀을 건드리지 않는다 — 검증이 스팀 클라이언트를 기다리면 안 된다
	if DisplayServer.get_name() == "headless":
		return
	# 검사 하니스(창을 띄우는 --cfcheck · --uifit 등)로 켰을 때도 붙지 않는다 — 시험 판이 개발자 스팀 계정에
	# 도전과제를 찍으면 안 된다. 스팀은 실행 인자 없이 게임을 켠다. 연동을 일부러 보려면 --steamlive.
	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	if not uargs.is_empty() and not uargs.has("--steamlive"):
		return
	var app_id: int = DEMO_APP_ID if G.is_demo() else APP_ID
	if app_id <= 0:
		return
	if not Engine.has_singleton("Steam"):
		if OS.is_debug_build():
			push_warning("[Steam] 비활성 — GodotSteam 확장 없음 (addons/godotsteam 확인)")
		return
	_steam = Engine.get_singleton("Steam")

	# ★ 초기화 함수 이름·인자가 GodotSteam 판마다 다르다.
	#   ★ isSteamRunning() 은 클라이언트만 떠 있으면 true 라 초기화가 실패해도(앱 소유 없음 등) true 다(17차에 밟음 —
	#   그 상태로 setAchievement 를 부르면 「User Stats class not found」). steamInitEx 의 status 를 먼저 본다.
	if _steam.has_method("steamInitEx"):
		# GodotSteam 4.x: steamInitEx(app_id, embed_callbacks) — AppID 를 넘기면 스팀 밖에서 켜도(개발 PC) 붙는다.
		# 콜백은 아래 _process 에서 직접 돌린다(embed=false). status 0 = k_ESteamAPIInitResult_OK.
		var r: Variant = _steam.call("steamInitEx", app_id, false)
		if OS.is_debug_build():
			print("[Steam] steamInitEx → %s" % str(r))
		if r is Dictionary and int((r as Dictionary).get("status", 1)) != 0:
			return
	elif _steam.has_method("steamInit"):
		_steam.call("steamInit")
	else:
		push_warning("[Steam] 초기화 함수를 못 찾음 — GodotSteam 판 확인")
		return

	if not _steam.has_method("isSteamRunning") or not bool(_steam.call("isSteamRunning")):
		if OS.is_debug_build():
			print("[Steam] 클라이언트가 안 떠 있음 — 도전과제 연동 없이 진행")
		return

	_ok = true
	_pump = _steam.has_method("run_callbacks")
	if OS.is_debug_build():
		print("[Steam] 연결됨 — AppID %d" % app_id)

	# QA C8: 스팀 오버레이(Shift+Tab)는 창 포커스를 안 뺏어서 자동 일시정지가 안 걸렸다(오버레이 보는 동안 맞았다)
	if _steam.has_signal("overlay_toggled"):
		_steam.connect("overlay_toggled", _on_overlay)
	if G.is_demo():
		return   # 체험판 앱에는 도전과제가 없다 — 본편에서 딴다
	G.achievement_unlocked.connect(_on_unlocked)
	# 11/14 수집품: 도전과제가 스팀 서버에 저장됐다는 신호가 오면 promo 아이템을 받으러 간다
	for sig: String in ["user_achievement_stored", "user_stats_stored"]:
		if _steam.has_signal(sig):
			_steam.connect(sig, _on_stored)
	# 이미 딴 것들을 밀어 올린다. 스팀 연동 전에 딴 도전과제, 또는 모바일에서
	# 옮겨온 세이브가 있으면 스팀 쪽만 비어 있게 되므로 시작할 때 한 번 맞춘다.
	_backfill()
	_promo_due = Time.get_ticks_msec() + 2000   # 시작할 때 한 번 — 업데이트 전에 딴 도전과제의 수집품도 여기서 받는다


func _process(_delta: float) -> void:
	if _ok and _pump:
		_steam.call("run_callbacks")
	if _promo_due > 0 and Time.get_ticks_msec() >= _promo_due:
		_promo_due = 0
		grant_promos()


## ── 11/14 스팀 인벤토리 수집품 ──
## 도전과제마다 수집품 하나가 스팀웍스 아이템 정의의 promo 규칙 「ach:<도전과제 API 이름>」 으로 붙는다.
##   게임은 「받을 자격이 있는 promo 아이템을 다 달라」(ISteamInventory::GrantPromoItems)를 부르기만 하고,
##   어느 업적에 무엇을 줄지 · 한 번만 줄지는 스팀이 정한다. 아이템 정의 · 그림은 스팀웍스에 올린다.
##   인벤토리 함수가 없는 GodotSteam 판이거나 스팀이 없거나 체험판이면 조용히 건너뛴다.
##   (돌려받는 결과 핸들은 쓰지 않는다 — 판마다 몇 번뿐이라 DestroyResult 를 안 불러도 남는 건 작다)
func grant_promos() -> void:
	if not _ok or G.is_demo() or not _steam.has_method("grantPromoItems"):
		return
	_steam.call("grantPromoItems")
	if OS.is_debug_build():
		print("[Steam] grantPromoItems")


## user_achievement_stored(5개 인자) · user_stats_stored(2개 인자) 둘 다 받는다. 업적이 여럿 한꺼번에 저장되면
##   신호도 여럿 오니, 마지막 신호 1.5초 뒤에 한 번만 부른다.
func _on_stored(_a: Variant = null, _b: Variant = null, _c: Variant = null, _d: Variant = null, _e: Variant = null) -> void:
	_promo_due = Time.get_ticks_msec() + 1500


## 오버레이가 열리면 판을 멈춘다 — GodotSteam 판마다 인자 수가 달라(active 하나 · 셋) 나머지는 기본값으로 받는다.
func _on_overlay(active: bool, _user: Variant = null, _app: Variant = null) -> void:
	var m: Node = get_tree().current_scene
	if m != null and m.has_method("steam_overlay"):
		m.call("steam_overlay", active)


## 도전과제 달성 — G.achievement_unlocked 시그널이 부른다.
func _on_unlocked(ach: Dictionary) -> void:
	unlock(String(ach.get("id", "")))


func unlock(id: String) -> void:
	if not _ok or id.is_empty():
		return
	_steam.call("setAchievement", id)
	_steam.call("storeStats")


## 세이브에 있는데 스팀에 없는 것을 채운다.
func _backfill() -> void:
	if not _ok:
		return
	var pushed: int = 0
	for a: Dictionary in Codex.ACHIEVEMENTS:
		var id: String = String(a.get("id", ""))
		if id.is_empty() or not G.achievements.has(id):
			continue
		_steam.call("setAchievement", id)
		pushed += 1
	if pushed > 0:
		_steam.call("storeStats")
		if OS.is_debug_build():
			print("[Steam] 기존 달성 %d건 올림" % pushed)


## 체험판 「찜하기」 — 본편 상점 페이지. 스팀에 붙어 있으면 오버레이로(창을 안 떠난다), 아니면 브라우저로.
func open_store_page() -> void:
	if _ok and _steam.has_method("activateGameOverlayToStore"):
		_steam.call("activateGameOverlayToStore", APP_ID, 0)
		return
	OS.shell_open(G.STORE_URL)


## 스팀에서 실제로 돌고 있는가 — 검사 하니스가 묻는다.
func available() -> bool:
	return _ok
