extends Node
## 전역 게임 상태 + 저즙(juice) 헬퍼 + 런타임 인풋맵 셋업.
## 자동로드 이름 = G

signal enemy_died(pos: Vector2)
signal xp_changed
signal leveled_up
signal player_hp_changed
signal player_died
signal revive_offered                        # 죽었지만 광고 부활 기회가 남음 (main 이 패널을 띄운다)
signal chest_collected
signal boss_chest_collected  # 보스 드랍 상자 — 무작위 강화 1~5개 (M37)
signal codex_unlocked(key: String)          # 도감 신규 해금(토스트용)
signal achievement_unlocked(ach: Dictionary)  # 도전과제 달성(토스트용)
signal combo_changed                        # 킬 콤보 갱신/리셋 (HUD용, S1)
signal ui_scale_changed                     # 인터페이스 크기 설정 변경 (HUD 재스케일)

var time_alive: float = 0.0
var kills: int = 0
var level: int = 1
var wave: int = 1
var xp: int = 0
var xp_to_next: int = 5
var player: Node2D = null
var camera: Node2D = null
var running: bool = false

## 광고 부활 — 판당 1회. reset_run() 에서 0 으로 돌아간다.
const REVIVE_MAX: int = 1
var revive_used: int = 0

## 광고 없이 그냥 부활시켜 주는 빌드인가 — 스팀/데스크톱.
##
## ★ "광고 로드 실패" 로 판단하면 안 된다. 모바일에서 비행기모드를 켜도 똑같이
##   광고가 없는 상태가 되므로, 그걸 기준으로 삼으면 광고를 끄는 것이 곧
##   공짜 부활이 된다. 플랫폼(빌드)으로 갈라야 한다.
##
## 스팀 빌드에는 광고 SDK가 아예 안 들어간다. 그대로 두면 스팀 이용자는
## 부활이라는 기능 자체가 없는 게임을 하게 된다 — 돈 주고 산 쪽이 더 불리해진다.
func free_revive() -> bool:
	return is_desktop()


## PC 빌드인가(윈도우·스팀). 터치 여부가 아니라 '빌드'를 묻는 것이다 —
## G.mobile 은 터치 감지라 터치 되는 노트북에서도 참이 되므로 여기 쓰면 안 된다.
func is_desktop() -> bool:
	return not OS.has_feature("mobile")


## 지금 죽은 플레이어에게 부활 기회를 줄 수 있는가.
## 모바일은 광고가 실제로 손에 들려 있을 때만, 데스크톱은 판당 1회 무료.
func revive_available() -> bool:
	if revive_used >= REVIVE_MAX:
		return false
	return free_revive() or Ads.available()

# 기기별 성능 상한 (main이 부팅 시 detect_mobile로 세팅) + 프레임당 임팩트 이펙트 예산
var mobile: bool = false     # 모바일/터치 기기 여부(성능 분기)
var num_block_y: float = 0.0  # 14차: 이 화면 y 위로는 피해 숫자를 안 띄운다(HUD 위 띠 · 보스 막대). main_game 이 매 프레임 정한다
var _bullet_cap: int = 200   # 동시 탄환 상한(데스크톱). 모바일은 하향
var _fx_frame: int = -1
var _fx_count: int = 0
const FX_BUDGET: int = 14    # 물리프레임당 임팩트 이펙트(스파크/링/아크/섬광) 최대 스폰 수
## 17-1: 무기 몸통 그림(채찍 · 사신의 낫 휘두르기, 번개 사슬 줄기)은 임팩트 예산과 따로 센다.
## ★ 같은 예산을 나눠 쓰니 몹이 많을 때 처치 파편 · 피격 불꽃이 먼저 다 써 버려서
##   「사신의 낫이 몹 많을 땐 아예 안 보이고 숫자만 뜬다」가 됐다(사용자 10/11). 무기는 공격 그 자체라 빠지면 안 된다.
var _wfx_frame: int = -1
var _wfx_count: int = 0
const WFX_BUDGET: int = 10

# 무기 DPS 측정용 데미지 프로브 (--weapondps 하니스 전용)
var probe_on: bool = false
var dmg_probe: float = 0.0
# 피해 출처별 집계 (밸런스 디버그 — boomcheck 등에서 사용)
var tally_on: bool = false
var dmg_tally: Dictionary = {}


## 13차 결과 화면 — 이번 판 무기별 피해(출처 id → 합). take_damage(…, src) 와 지속 · 반응 피해가 쌓는다.
## tally(검사용 분류)와 달리 늘 켜져 있다. 출처 id 는 카드 id(wp_ · wpn_ · evo_ · b_) 또는 dot_burn · dot_poison · react · dash · thorns …
var run_dmg: Dictionary = {}

func log_dmg(src: String, amt: float) -> void:
	if amt <= 0.0:
		return
	var k: String = src if src != "" else "etc"
	run_dmg[k] = float(run_dmg.get(k, 0.0)) + amt


func tally(src: String, amt: float) -> void:
	if tally_on:
		dmg_tally[src] = float(dmg_tally.get(src, 0.0)) + amt


# 원소 반응 전역 예산 — 반응 발동은 초당 상수 회로 제한 (M39).
# 반응 빈도가 '적 수 × 명중 커버리지'에 비례해 군중전에서 총피해의 70%까지 폭증하던 것 차단.
var _react_window: int = -1
var _react_count: int = 0
const REACT_PER_SEC: int = 4


## 달빛 사제의 회복 — **판 전체** 예산. 초당 이 횟수까지만 회복이 일어난다.
## ★ 2026-09-06 지적: "치유 몹이 조금만 쌓여도 그냥 씹사기". 대상별 쿨만으로는 안 잡혔다 —
##   사제가 늘면 같은 몸을 두 번 살리는 게 아니라 **덮는 범위**가 넓어져 총 회복량이
##   사제 수에 비례했다(실측 4마리 = 3.33배). 원소 반응이 같은 문제로 이미 예산제를 쓰고
##   있으니 같은 방식으로 묶는다. 사제를 여럿 두는 의미는 이제 '넓게·끈질기게'지 '더 많이'가 아니다.
var _heal_window: int = -1
var _heal_count: int = 0
const HEAL_PER_SEC: int = 5


func heal_budget() -> bool:
	var w: int = int(time_alive)
	if w != _heal_window:
		_heal_window = w
		_heal_count = 0
	if _heal_count >= HEAL_PER_SEC:
		return false
	_heal_count += 1
	return true


func react_budget() -> bool:
	var w: int = int(time_alive)
	if w != _react_window:
		_react_window = w
		_react_count = 0
	if _react_count >= REACT_PER_SEC:
		return false
	_react_count += 1
	return true

# 골드 / 메타(영구 업글) — user:// 세이브 지속
var run_gold: int = 0
var _gm_window: int = -1  # 분당 골드 예산: 현재 분 인덱스
var _gm_earned: int = 0   # 이번 분에 받은 골드
var total_gold: int = 0
var meta: Dictionary = {}
# 도감/도전과제 — user:// 세이브 지속
var codex: Dictionary = {}         # 해금한 도감 key -> true
var achievements: Dictionary = {}  # 달성한 도전과제 id -> true
var stats: Dictionary = {}         # 누적 통계 (도전과제 판정용)

# 메뉴 흐름: 씬 리로드로 새 런 시작할 때 넘겨줄 캐릭터 (autoload라 리로드에도 유지)
var pending_char: Dictionary = {}
var master_volume: float = 0.85  # 0~1 (설정에서 조절)
var aim_mode: int = 0  # 0 자동조준 / 1 수동조준(마우스 방향)
## 13차 6절 7 — 접근성 켜고 끄기(설정 · 화면): 피해 숫자 · 화면 흔들림 · 번쩍임 줄이기
var show_dmgnum: bool = true
var shake_on: bool = true
var flash_low: bool = false
## 19차 3절 1: 「피해 숫자 — 전부 / 큰 것만 / 끄기」(0 · 1 · 2). show_dmgnum 은 2 가 아니면 켬(예전 검사 하니스가 그대로 쓴다).
var dmgnum_mode: int = 0
## 19차 3절 1: 「내 효과 흐리게」 — 영웅 둘레에서 내 무기 이펙트를 반투명으로(후반에 영웅이 이펙트에 묻혔다). 기본 켬.
var fx_dim_on: bool = true
## 화면 전체 번쩍임의 세기 배수 — 번쩍임 줄이기를 켜면 1/4 로
func flash_mult() -> float:
	return 0.25 if flash_low else 1.0
var auto_card: int = 0  # 만렙(풀 소진) 후 레벨업 카드: 0 직접선택 / 1 회복 / 2 골드 / 3 랜덤 (M37)
# ── 가독성 설정 (S1): -1 = 자동(모바일이면 확대) ──
var ui_scale_idx: int = -1   # 인터페이스 크기 0 보통 / 1 크게 / 2 아주 크게
var cam_zoom_idx: int = -1   # 화면(캐릭터) 확대 0 보통 / 1 크게 / 2 아주 크게
# ── 모드/스테이지 (S1): endless(무한) / stage(스테이지 클리어제) ──
var run_mode: String = "endless"
var mode_chosen: bool = false     # 이번 실행에서 출격 준비로 모드를 한 번 골랐는가(저장 안 함) — 처음엔 스테이지 탭으로 연다
var stage_sel: int = 0            # 스테이지 모드에서 고른 스테이지(0~5, 5 = 저승길)
var stage_prog: Dictionary = {}   # "c_<stage>_<diff>" -> true (클리어 기록, 저장 지속)
var endless_prog: Dictionary = {}   # 11/14 무한 기록 · 무한 별 (난이도별) — 아래 「무한 기록」 절
# ── 킬 콤보 (S1): 짧은 간격 연속 처치 → 카운터/사운드 상승 ──
var combo: int = 0
var combo_t: float = 0.0
var combo_best: int = 0
const COMBO_WINDOW: float = 1.9
var _pickup_streak: int = 0       # 줍기 연타 피치 상승용
var _pickup_last_ms: int = 0

var _hitstop_count: int = 0

var _sfx: Dictionary = {}
var _sfx_players: Array = []
var _sfx_idx: int = 0


## ── 19차 4-2 체험판 ──
## 스팀 체험판 빌드(내보내기 기능 태그 "demo")에서만 켜진다. 개발 PC 에서 볼 때는 실행 인자 --trial.
##   첫 스테이지 · 영웅 둘(울레아 · 타르한) · 무한 모드는 15분에서 끝(체험판 끝 창 + 찜하기).
##   세이브는 앱 이름을 「IMYEON Demo」로 바꿔 다른 폴더에 둔다 — 체험판 세이브는 본편으로 넘어가지 않는다(지시서).
const DEMO_HEROES: Array = ["base", "berserker"]
const DEMO_ENDLESS_END: float = 900.0
const STORE_URL: String = "https://store.steampowered.com/app/5428620/"


static func is_demo() -> bool:
	return OS.has_feature("demo") or "--trial" in OS.get_cmdline_user_args()


# ──────────────────── 11/7 튕김 기록 ────────────────────
## 스팀 플레이 보고: 「무한 모드 도중 강제 종료」. 봇 판(헤드리스 10판 · 화면 그리기 센 빌드 30분)으로는 판 도중 튕김이
## 안 났다. 플레이어 PC 에서 다시 나면 짚을 수 있게, 판 도중 상태를 10초마다 적고 정상 종료를 표시한다.
## 다음에 켰을 때 정상 종료 표시가 없으면 그 상태와 직전 로그 끝부분을 user://crash_reports/ 에 남긴다.
const GAME_VERSION: String = "1.5.0"
const SESSION_PATH: String = "user://session.cfg"
var crash_reports_new: int = 0   # 이번에 켜면서 새로 남긴 튕김 기록 수


func _session_begin() -> void:
	var old := ConfigFile.new()
	if old.load(SESSION_PATH) == OK and not bool(old.get_value("s", "clean", true)):
		_write_crash_report(old)
	var cfg := ConfigFile.new()
	cfg.set_value("s", "clean", false)
	cfg.set_value("s", "start", Time.get_datetime_string_from_system())
	cfg.set_value("s", "version", GAME_VERSION)
	cfg.save(SESSION_PATH)


## 판 도중 상태 한 묶음(main_game 이 10초마다). 튕기면 이게 마지막 기록이다.
func session_mark(info: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SESSION_PATH)
	cfg.set_value("s", "clean", false)
	cfg.set_value("s", "at", Time.get_datetime_string_from_system())
	for k: String in info:
		cfg.set_value("run", k, info[k])
	cfg.save(SESSION_PATH)


func session_end() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SESSION_PATH)
	cfg.set_value("s", "clean", true)
	cfg.save(SESSION_PATH)


func _write_crash_report(old: ConfigFile) -> void:
	DirAccess.make_dir_recursive_absolute("user://crash_reports")
	var lines: PackedStringArray = ["IMYEON : Yokai Survivor 튕김 기록", "버전 %s · 켠 시각 %s · 마지막 기록 %s" % [
		String(old.get_value("s", "version", "?")), String(old.get_value("s", "start", "?")), String(old.get_value("s", "at", "?"))], ""]
	if old.has_section("run"):
		for k: String in old.get_section_keys("run"):
			lines.append("%s = %s" % [k, str(old.get_value("run", k))])
	# 직전 실행의 엔진 로그 — 켤 때 godot.log 가 godot<시각>.log 로 밀려난다. 가장 최근 것의 끝부분.
	var newest: String = ""
	var d := DirAccess.open("user://logs")
	if d != null:
		for f: String in d.get_files():
			if f.begins_with("godot2") and f.ends_with(".log") and f > newest:
				newest = f
	if newest != "":
		var lf := FileAccess.open("user://logs/" + newest, FileAccess.READ)
		if lf != null:
			var all: PackedStringArray = lf.get_as_text().split("\n")
			lines.append("")
			lines.append("── %s 끝 120줄 ──" % newest)
			lines.append_array(all.slice(maxi(0, all.size() - 120)))
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	var out := FileAccess.open("user://crash_reports/crash_%s.txt" % stamp, FileAccess.WRITE)
	if out != null:
		out.store_string("\n".join(lines))
		crash_reports_new += 1
		print("[CRASH] 지난 실행이 정상 종료되지 않았다 — user://crash_reports/crash_%s.txt" % stamp)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		session_end()


func _ready() -> void:
	if is_demo():
		# user:// 는 부를 때마다 앱 이름에서 경로를 만든다 — 세이브를 처음 읽기 전에 바꾸고 폴더를 만들어 둔다
		ProjectSettings.set_setting("application/config/name", "IMYEON Demo")
		DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_title("IMYEON : Yokai Survivor Demo")
	_session_begin()   # 11/7 튕김 기록(체험판은 바뀐 폴더에)
	_setup_input()
	_load_sfx()
	_load_save()
	apply_lang()
	apply_cf()
	# 창 크기 · 자리 지켜보기(11/5) — 판이 멈춘 동안(설정 화면)에도 돌아야 한다
	_display_timer = Timer.new()
	_display_timer.wait_time = 0.5
	_display_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_display_timer.timeout.connect(_watch_display)
	add_child(_display_timer)
	_display_timer.start()
	get_tree().root.size_changed.connect(_on_root_resized)
	ui_scale_changed.connect(_on_root_resized)
	_on_root_resized.call_deferred()


## 프로젝트 이름을 "Survivor Roguelike" → "IMYEON : Yokai Survivor" 로 바꾸면
## user:// 가 가리키는 폴더 자체가 바뀐다. 그냥 두면 이미 윈도우로 받아서 하던
## 사람의 골드·별·도감이 통째로 사라진 것처럼 보인다(파일은 옛 폴더에 남아 있다).
##
## 새 폴더에 세이브가 없을 때만 옛 폴더를 한 번 들여다보고 옮겨 온다.
## 이미 새 세이브가 있으면 손대지 않는다 — 덮어쓰면 그게 더 큰 사고다.
const _OLD_USER_DIRS: Array = ["Survivor Roguelike"]


func _migrate_old_userdir() -> void:
	if FileAccess.file_exists("user://save.cfg") or is_demo():   # 체험판은 옛 세이브를 끌어오지 않는다
		return
	var parent: String = OS.get_user_data_dir().get_base_dir()
	for old_name: String in _OLD_USER_DIRS:
		var src: String = parent.path_join(old_name).path_join("save.cfg")
		if not FileAccess.file_exists(src):
			continue
		var f := FileAccess.open(src, FileAccess.READ)
		if f == null:
			continue
		var body: PackedByteArray = f.get_buffer(f.get_length())
		f.close()
		var dst := FileAccess.open("user://save.cfg", FileAccess.WRITE)
		if dst == null:
			return
		dst.store_buffer(body)
		dst.close()
		print("[SAVE] 옛 폴더에서 세이브를 옮겼다: %s" % old_name)
		return


## ── 저장 파일 지키기(16차 4-6) ──
## ★ 예전엔 save.cfg 하나를 그 자리에 덮어썼고, 읽다가 실패하면 조용히 새 판으로 시작했다. 그러면 다음 저장이
##   깨진 파일을 덮어써서 골드 · 해금 · 별이 통째로 사라진다(쓰는 도중 꺼지거나 디스크가 꽉 찬 경우).
##   이제: 새 내용은 .tmp 에 다 쓴 뒤 → 지금 파일을 .bak 으로 → .tmp 를 save.cfg 로 바꿔 단다.
##   맨 끝 줄 "_end" 가 없으면 반쯤 쓴 파일로 보고, 읽기에 실패하면 .bak 으로 돌아간다.
##   둘 다 못 읽으면 깨진 파일을 save.broken.cfg 로 비켜 두고(덮어쓰지 않는다) 새로 시작한다.
const SAVE_PATH: String = "user://save.cfg"
const SAVE_BAK: String = "user://save.bak.cfg"
const SAVE_TMP: String = "user://save.tmp.cfg"
var save_src: String = ""   # 마지막으로 읽은 곳(검사 · 로그용): "main" · "bak" · "new" · "broken"


func _read_save(path: String) -> ConfigFile:
	if not FileAccess.file_exists(path):
		return null
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return null
	if not cfg.has_section_key("data", "_end") and cfg.has_section_key("data", "_ver"):
		return null   # 끝 표시를 쓰는 형식인데 끝 줄이 없다 = 반쯤 쓴 파일
	if not cfg.has_section("data"):
		return null
	return cfg


## 도전과제 목표치. need 가 음수면 '도감을 전부 모아라' — 콘텐츠를 늘려도 따라 오른다(판정 · 도감 화면 공용, QA 10/13).
func ach_need(a: Dictionary) -> int:
	var need: int = int(a["need"])
	if need == -1:
		need = Codex.MONSTERS.size()
	elif need == -2:
		need = Codex.MAPS.size()
	elif need == -3:
		need = _yokai_total()
	return need


func _load_save(path: String = SAVE_PATH) -> void:
	if path == SAVE_PATH:
		_migrate_old_userdir()
	var cfg: ConfigFile = _read_save(path)
	save_src = "main"
	if cfg == null and FileAccess.file_exists(path):
		var bak: String = SAVE_BAK if path == SAVE_PATH else path.get_basename() + ".bak.cfg"
		cfg = _read_save(bak)
		save_src = "bak" if cfg != null else "broken"
		# 못 읽은 파일은 지우지도 덮어쓰지도 않고 옆으로 비켜 둔다 — 사람이 꺼내 볼 수 있게
		var broken: String = path.get_basename() + ".broken.cfg"
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(broken))
		push_warning("[SAVE] %s 를 못 읽었다 → %s · 원본은 %s" % [path, "백업으로" if cfg != null else "새로 시작", broken])
	elif cfg == null:
		# QA 10/13: 바꿔 다는 사이(.bak 으로 옮긴 뒤 · .tmp 를 제자리에 놓기 전)에 꺼지면 save.cfg 가 없다.
		#   그대로 새로 시작하면 저장 두 번 만에 .bak 까지 빈 세이브로 덮인다 — .bak 다음 .tmp 를 본다.
		var bak2: String = SAVE_BAK if path == SAVE_PATH else path.get_basename() + ".bak.cfg"
		var tmp2: String = SAVE_TMP if path == SAVE_PATH else path.get_basename() + ".tmp.cfg"
		cfg = _read_save(bak2)
		save_src = "bak"
		if cfg == null:
			cfg = _read_save(tmp2)
			save_src = "tmp"
		if cfg == null:
			save_src = "new"
	if cfg != null:
		total_gold = int(cfg.get_value("data", "gold", 0))
		meta = cfg.get_value("data", "meta", {})
		diff_pref = clampi(int(cfg.get_value("data", "difficulty", 1)), 0, DIFF_MAX)
		karma = clampi(int(cfg.get_value("data", "karma", 0)), 0, KARMA_MAX)
		difficulty = diff_pref
		master_volume = float(cfg.get_value("data", "volume", 0.85))
		aim_mode = int(cfg.get_value("data", "aim_mode", 0))
		auto_card = int(cfg.get_value("data", "auto_card", 0))
		codex = cfg.get_value("data", "codex", {})
		achievements = cfg.get_value("data", "achievements", {})
		stats = cfg.get_value("data", "stats", {})
		ui_scale_idx = int(cfg.get_value("data", "ui_scale", -1))
		cam_zoom_idx = int(cfg.get_value("data", "cam_zoom", -1))
		stage_prog = cfg.get_value("data", "stage_prog", {})
		endless_prog = cfg.get_value("data", "endless_prog", {})
		quests = cfg.get_value("data", "quests", {})
		perf_idx = int(cfg.get_value("data", "perf", -1))
		stick_idx = int(cfg.get_value("data", "stick", -1))
		stick_fix_idx = int(cfg.get_value("data", "stickfix", -1))
		lang_idx = int(cfg.get_value("data", "lang", -1))
		cf_on = bool(cfg.get_value("data", "cf_on", true))
		fullscreen = bool(cfg.get_value("data", "fullscreen", false))
		show_dmgnum = bool(cfg.get_value("data", "dmgnum_on", true))
		dmgnum_mode = int(cfg.get_value("data", "dmgnum_mode", 0 if show_dmgnum else 2))
		show_dmgnum = dmgnum_mode != 2
		fx_dim_on = bool(cfg.get_value("data", "fx_dim_on", true))
		shake_on = bool(cfg.get_value("data", "shake_on", true))
		flash_low = bool(cfg.get_value("data", "flash_low", false))
		# QA C6: 수집 통계는 새 도감 항목이 생길 때만 다시 셌다 — 옛 세이브는 다음 사건까지 틀린 값이었다. 불러올 때도 센다
		stats["mon_seen"] = _codex_count("mon_")
		stats["map_seen"] = _codex_count("map_")
		stats["fus_seen"] = _codex_count("fus_")
		stats["yokai_seen"] = _yokai_seen()
		# B12: 지난번에 내려놓은 채 꺼진 판의 골드를 돌려준다(한 번만 — 바로 0 으로 저장)
		var pg: int = int(cfg.get_value("data", "pend_gold", 0))
		if pg > 0:
			total_gold += pg
			pend_gold = 0
			print("[SAVE] 내려놓은 채 꺼진 판 골드 %d 를 돌려줬다" % pg)
			save_game(path)
	_migrate_unlocks()
	apply_volume()
	apply_perf()
	if path == SAVE_PATH:
		_load_display(save_src == "new")
	apply_window()


## ★ 해금 조건에 난이도(diff)를 새로 넣으면서, 예전 규칙(난이도 무관 클리어)으로 이미 열려 있던
##   캐릭터·무기가 다시 잠기는 소급 문제가 생겼다. 한 번만 훑어 예전 규칙을 만족하면 영구 해금으로
##   굳혀 둔다 — 유저가 이미 가지고 있던 것을 회수하지 않는다.
func _migrate_unlocks() -> void:
	if int(meta.get("mig_diff_unlock", 0)) > 0:
		return
	meta["mig_diff_unlock"] = 1
	for d: Dictionary in Characters.defs():
		var u: Dictionary = d.get("unlock", {})
		if not u.has("stage") or int(u.get("diff", 0)) <= 0:
			continue
		for dd in 4:  # 예전 규칙: 난이도 아무거나 클리어했으면 열려 있었다
			if stage_cleared(int(u["stage"]), dd):
				meta["uc_" + String(d["id"])] = 1
				break


var no_save: bool = false  # [감사 C16] 하니스 실행 중 실유저 세이브 오염 방지 (main이 인자 감지 시 설정)


func save_game(path: String = SAVE_PATH) -> void:
	if no_save and path == SAVE_PATH:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("data", "_ver", 16)   # 맨 앞 — 형식 표시. 이게 있는데 끝 줄(_end)이 없으면 반쯤 쓴 파일
	cfg.set_value("data", "gold", total_gold)
	cfg.set_value("data", "meta", meta)
	cfg.set_value("data", "difficulty", diff_pref)
	cfg.set_value("data", "karma", karma)
	cfg.set_value("data", "volume", master_volume)
	cfg.set_value("data", "aim_mode", aim_mode)
	cfg.set_value("data", "auto_card", auto_card)
	cfg.set_value("data", "codex", codex)
	cfg.set_value("data", "achievements", achievements)
	cfg.set_value("data", "stats", stats)
	cfg.set_value("data", "ui_scale", ui_scale_idx)
	cfg.set_value("data", "cam_zoom", cam_zoom_idx)
	cfg.set_value("data", "stage_prog", stage_prog)
	cfg.set_value("data", "endless_prog", endless_prog)
	cfg.set_value("data", "quests", quests)
	cfg.set_value("data", "perf", perf_idx)
	cfg.set_value("data", "stick", stick_idx)
	cfg.set_value("data", "stickfix", stick_fix_idx)
	cfg.set_value("data", "lang", lang_idx)
	cfg.set_value("data", "cf_on", cf_on)
	cfg.set_value("data", "dmgnum_on", show_dmgnum)
	cfg.set_value("data", "dmgnum_mode", dmgnum_mode)
	cfg.set_value("data", "fx_dim_on", fx_dim_on)
	cfg.set_value("data", "shake_on", shake_on)
	cfg.set_value("data", "flash_low", flash_low)
	cfg.set_value("data", "fullscreen", fullscreen)
	cfg.set_value("data", "pend_gold", pend_gold)   # 내려놓은 채 꺼진 판의 골드(B12) — 보통 0
	cfg.set_value("data", "_end", 1)   # 맨 끝 — 이 줄이 없으면 반쯤 쓴 파일(_read_save)
	_write_save(cfg, path)


## .tmp 에 끝까지 쓴 뒤 지금 파일을 .bak 으로 돌리고 .tmp 를 제자리에. 쓰는 도중 꺼져도 save.cfg 는 온전하다.
func _write_save(cfg: ConfigFile, path: String) -> void:
	var tmp: String = SAVE_TMP if path == SAVE_PATH else path.get_basename() + ".tmp.cfg"
	var bak: String = SAVE_BAK if path == SAVE_PATH else path.get_basename() + ".bak.cfg"
	if cfg.save(tmp) != OK:
		push_warning("[SAVE] 임시 파일을 못 썼다 — 이번 저장은 건너뛴다(기존 파일은 그대로)")
		return
	var g_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) and _read_save(path) != null:
		var g_bak: String = ProjectSettings.globalize_path(bak)
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(g_bak)
		DirAccess.rename_absolute(g_path, g_bak)
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(g_path)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), g_path)


# ──────────────────────── 창 모드 (PC 전용) ────────────────────────
## 모바일에서 옮겨온 게임이라 창/전체화면 전환이 아예 없었다. PC에서는 없으면
## 이상하고, 스팀은 Alt+Tab·다중 모니터가 기본이라 반드시 있어야 한다.
##
## ★ 전체화면은 EXCLUSIVE 가 아니라 FULLSCREEN(= 테두리 없는 전체화면)을 쓴다.
##   EXCLUSIVE 는 Alt+Tab 때 화면이 껌뻑이고 오버레이(스팀 Shift+Tab)가 깨진다.
var fullscreen: bool = false

## ── 11/5 스팀 피드백 4 · 5 · 7: 창 크기 · 해상도 ──
## ★ 예전엔 창이 늘 프로젝트 기본 1280×720 으로 떴다. 4K 모니터에선 화면의 1/9 짜리 창이 「HD 로 나온다」로 읽혔고,
##   전체 화면으로 켰다가 창으로 돌아와도 다시 1280×720 이었다. 창 크기 · 자리 · 최대화는 저장도 안 했다.
##   이제: 처음엔 모니터에 맞춘 16:9 크기로 가운데에 띄우고, 사용자가 바꾼 크기 · 자리 · 최대화는 기억한다.
##   전체 화면은 테두리 없는 전체 화면이라 언제나 모니터 원래 해상도로 그린다(canvas_items 늘이기).
## ★ 창 설정은 PC 마다 다르다 — 클라우드로 오가는 save.cfg 가 아니라 이 PC 의 display.cfg 에 둔다
##   (4K 데스크톱의 창 크기가 스팀덱으로 넘어가면 안 된다). display.cfg 는 스팀 오토 클라우드 목록에 없다.
const DISPLAY_PATH: String = "user://display.cfg"
## 창 크기 고르기(설정 화면). 모니터에 들어가는 것만 보여 준다.
const WIN_SIZES: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3200, 1800), Vector2i(3840, 2160)]
const WIN_MIN: Vector2i = Vector2i(960, 540)
var win_size: Vector2i = Vector2i.ZERO         # 0 = 자동(모니터에 맞춤)
var win_pos: Vector2i = Vector2i(-1, -1)        # 저장된 창 자리(없으면 가운데)
var win_screen: int = -1
var win_max: bool = false
var _display_seen: Vector4i = Vector4i.ZERO     # 지켜보던 창 크기 · 자리(바뀌면 잠시 뒤 저장)
var _display_dirty_t: float = 0.0
var _display_timer: Timer
var _last_screen: int = -1


## 검사 하니스(--resolution 이나 하니스 인자)로 띄운 창은 건드리지도 저장하지도 않는다 — 사진 크기가 바뀐다.
func _win_managed() -> bool:
	if not is_desktop() or DisplayServer.get_name() == "headless":
		return false
	if "--resolution" in OS.get_cmdline_args() or "--position" in OS.get_cmdline_args():
		return false
	for a: String in OS.get_cmdline_user_args():
		if not (a.begins_with("--lang=") or a == "--trial"):
			return false
	return true


func _load_display(first_install: bool) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(DISPLAY_PATH) == OK:
		fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
		win_size = cfg.get_value("display", "size", Vector2i.ZERO)
		win_pos = cfg.get_value("display", "pos", Vector2i(-1, -1))
		win_screen = int(cfg.get_value("display", "screen", -1))
		win_max = bool(cfg.get_value("display", "maximized", false))
	elif first_install and _win_managed():
		# 처음 받은 사람은 전체 화면(모니터 해상도 그대로)으로 연다. 이미 하던 사람은 고른 창 모드를 지킨다.
		# ★ 하니스(빈 APPDATA + --resolution)까지 전체 화면이 되면 개발 PC 모니터 비율(21:9)로 재게 된다(11/7 --herofit).
		fullscreen = true


func save_display() -> void:
	if not _win_managed():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "size", win_size)
	cfg.set_value("display", "pos", win_pos)
	cfg.set_value("display", "screen", win_screen)
	cfg.set_value("display", "maximized", win_max)
	cfg.save(DISPLAY_PATH)


## 창이 놓일 모니터. 저장한 모니터가 지금 없으면(모니터를 뺐다) 창이 지금 있는 모니터.
func _win_screen_now() -> int:
	if win_screen >= 0 and win_screen < DisplayServer.get_screen_count():
		return win_screen
	return DisplayServer.window_get_current_screen()


## 자동 창 크기 — 작업 표시줄 · 제목 줄을 빼고 남은 높이의 92% 안에 드는 가장 큰 16:9 표준 크기.
## 1080 모니터 1600×900 · 1440 모니터 1920×1080 · 4K 모니터 3200×1800.
func win_auto_size(scr: int = -1) -> Vector2i:
	if scr < 0:
		scr = _win_screen_now()
	var ur: Rect2i = DisplayServer.screen_get_usable_rect(scr)
	var lim := Vector2(float(ur.size.x) * 0.94, (float(ur.size.y) - 40.0) * 0.92)
	var best: Vector2i = WIN_MIN
	for sz: Vector2i in WIN_SIZES:
		if float(sz.x) <= lim.x and float(sz.y) <= lim.y:
			best = sz
	return best


## 설정 화면에 보여 줄 창 크기 칸 — 이 모니터에 들어가는 것만.
func win_size_choices() -> Array:
	var ur: Rect2i = DisplayServer.screen_get_usable_rect(_win_screen_now()) if DisplayServer.get_name() != "headless" else Rect2i(0, 0, 1920, 1040)
	var out: Array = []
	for sz: Vector2i in WIN_SIZES:
		if sz.x <= ur.size.x and sz.y + 30 <= ur.size.y:
			out.append(sz)
	return out


func _apply_window_rect() -> void:
	if not _win_managed() or fullscreen:
		return
	var scr: int = _win_screen_now()
	var ur: Rect2i = DisplayServer.screen_get_usable_rect(scr)
	var want: Vector2i = win_size if win_size.x >= WIN_MIN.x and win_size.y >= WIN_MIN.y else win_auto_size(scr)
	want = Vector2i(mini(want.x, ur.size.x), mini(want.y, maxi(WIN_MIN.y, ur.size.y - 30)))
	var pos: Vector2i = win_pos
	# 저장한 자리에서 창 제목 줄이 어느 모니터 안에도 없으면(모니터 배치가 바뀜) 가운데로
	var ok: bool = false
	if pos.x > -10000:
		for i in DisplayServer.get_screen_count():
			var r: Rect2i = DisplayServer.screen_get_usable_rect(i)
			if r.has_point(pos + Vector2i(mini(120, want.x / 2), 10)):
				ok = true
				break
	if not ok or pos == Vector2i(-1, -1):
		pos = ur.position + (ur.size - want) / 2
		pos.y = maxi(ur.position.y + 30, pos.y)   # 제목 줄이 화면 위로 나가지 않게
	DisplayServer.window_set_size(want)
	DisplayServer.window_set_position(pos)
	if win_max:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func apply_window() -> void:
	if not is_desktop():
		return
	# 16차 4-5: 창을 마구 줄이면 판 · 버튼이 서로 겹쳤다 — 960×540(설계 720 의 3/4) 아래로는 안 줄어든다
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_min_size(WIN_MIN)
	var cur: int = DisplayServer.window_get_mode()
	if fullscreen:
		if cur != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if cur == DisplayServer.WINDOW_MODE_FULLSCREEN or cur == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# ★ 전체 화면에서 창으로 오면 엔진은 「전체 화면 전에 쓰던 크기」로 돌아간다 — 전체 화면으로 켠 판이면 1280×720.
		#   모드가 바뀐 다음 프레임에 크기 · 자리를 다시 놓는다.
		_apply_window_rect.call_deferred()
		if cur == DisplayServer.WINDOW_MODE_FULLSCREEN and is_inside_tree():
			get_tree().create_timer(0.2, true, false, true).timeout.connect(_apply_window_rect)   # 창 관리자가 늦게 옛 크기로 돌려놓는 경우
	_display_seen = Vector4i.ZERO


## 창 크기를 고른다(설정). Vector2i.ZERO = 자동(모니터에 맞춤). 전체 화면이면 창으로 바꾸지 않고 다음에 창으로 갈 때 쓴다.
func set_win_size(sz: Vector2i) -> void:
	win_size = sz
	win_max = false
	win_pos = Vector2i(-1, -1)   # 크기를 고르면 가운데로 다시 놓는다
	if not fullscreen:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_window_rect.call_deferred()
	save_display()


## 사용자가 창을 끌어 바꾼 크기 · 자리 · 최대화를 기억한다. 0.5초마다 보고, 멈춘 지 0.6초 뒤에 한 번 쓴다(끄는 동안 디스크를 두드리지 않게).
func _watch_display() -> void:
	if DisplayServer.get_name() == "headless" or not is_desktop():
		return
	# 창을 다른 모니터로 옮기면(크기는 그대로) 모니터 배수가 바뀐다 — HUD 를 다시 맞춘다
	var scr_now: int = DisplayServer.window_get_current_screen()
	if scr_now != _last_screen:
		var first: bool = _last_screen < 0
		_last_screen = scr_now
		if not first:
			ui_scale_changed.emit()
	if not _win_managed() or fullscreen:
		return
	var mode: int = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_MINIMIZED or mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	var sz: Vector2i = DisplayServer.window_get_size()
	var ps: Vector2i = DisplayServer.window_get_position()
	var now := Vector4i(sz.x, sz.y, ps.x, ps.y)
	var maxed: bool = mode == DisplayServer.WINDOW_MODE_MAXIMIZED
	if _display_seen == Vector4i.ZERO:
		_display_seen = now
		return
	if now != _display_seen or maxed != win_max:
		_display_seen = now
		_display_dirty_t = 0.6
		win_max = maxed
		if not maxed:
			win_screen = DisplayServer.window_get_current_screen()
			win_pos = ps
			if sz != win_auto_size() or win_size != Vector2i.ZERO:
				win_size = sz
		return
	if _display_dirty_t > 0.0:
		_display_dirty_t -= 0.5
		if _display_dirty_t <= 0.0:
			save_display()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_window()
	save_game()
	save_display()


## Alt+Enter / F11 — 어느 PC 게임에서나 되는 것이라 설정 화면을 안 거쳐도 먹혀야 한다.
func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen)


## ★ 오토로드는 트리 맨 위라 _unhandled_input 을 '가장 마지막에' 받는다.
##   즉 게임/메뉴가 먼저 쓰고 남긴 것만 여기로 온다 — 단축키를 가로채지 않는다.
func _unhandled_input(event: InputEvent) -> void:
	if not is_desktop():
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_F11 or (k.keycode == KEY_ENTER and k.alt_pressed):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


# ──────────────────────── 그래픽 성능 / 발열 ────────────────────────
## 유저 보고: 탄막·몬스터가 많아지면 최신 기종에서도 렉과 발열이 심해진다.
## 원인 중 가장 큰 몫이 '프레임 상한이 없어 120/144Hz 화면에서 두 배로 그리던 것'이었다.
## 물리는 60Hz 고정이라 120fps 로 그려도 반응성 이득이 없고 열만 난다.
## 0 절전(30) / 1 표준(60) / 2 최대(무제한). -1 은 자동 — 모바일은 표준, PC 는 최대.
const PERF_FPS: Array = [30, 60, 0]
var perf_idx: int = -1

func perf_level() -> int:
	if perf_idx >= 0:
		return clampi(perf_idx, 0, 2)
	return 1 if (mobile or weak_gpu()) else 2


## 16차 4-3: 저사양 그래픽(GT 710 으로 잰 값 — 1920×1080 가장 무거운 순간 평균 29 FPS)은 자동값을 「표준」으로.
##   「표준」은 60 FPS 상한 + 바닥 큰 얼룩을 안 그려서 같은 장면이 평균 36 이 됐다. 설정에서 바꾸면 그 값을 따른다.
static var _weak_gpu: int = -1

func weak_gpu() -> bool:
	if _weak_gpu < 0:
		var n: String = RenderingServer.get_video_adapter_name().to_lower() if DisplayServer.get_name() != "headless" else ""
		_weak_gpu = 1 if (n.contains("gt 7") or n.contains("gt 6") or n.contains("gt 1030") or n.contains("intel(r) hd")
			or n.contains("intel(r) uhd") or n.contains("hd graphics") or n.contains("uhd graphics")) else 0
	return _weak_gpu == 1


## 이펙트 밀도 배수 — 절전에서는 파티클/데미지 숫자/트레일을 함께 줄인다.
func fx_scale() -> float:
	match perf_level():
		0:
			return 0.45
		1:
			return 0.75 if mobile else 1.0
		_:
			return 1.0


func apply_perf() -> void:
	Engine.max_fps = int(PERF_FPS[perf_level()])


## 가상 조이스틱 응답 프리셋 — 0 정밀 / 1 표준 / 2 즉각. -1 은 자동(= 표준).
var stick_idx: int = -1

func stick_preset() -> int:
	return clampi(stick_idx if stick_idx >= 0 else 1, 0, 2)


func set_stick(i: int) -> void:
	stick_idx = i
	save_game()


## 조이스틱 자리 — 0 고정 / 1 따라옴. 기본은 **고정**이다.
## ★ 예전엔 따라오는 방식만 있었다(처음 누른 자리가 원점이고, 반경을 벗어나면 원점까지
##   손가락을 따라 끌려왔다). 엄지를 아무 데나 올려도 된다는 장점이 있지만, 화면에
##   기준점이 없어서 "지금 어느 쪽으로 가고 있는지"를 눈이 아니라 감으로 잡아야 한다 —
##   탄막을 보면서 엄지를 볼 수는 없다. 고정형은 원점이 늘 같은 자리라 그 감이 몸에 남는다.
##   (사용자 요구, 2026-09-15: "고정형이 더 낫다는 의견이 많다".)
## ──────────────────── 언어 ────────────────────
## -1 자동(OS 가 한국어면 한국어, 아니면 영어) / 0 한국어 / 1 English.
## 번역 키는 코드에 박힌 한글 그대로다(tools/i18n.py). 그래서 한국어일 때는 번역이 아예 없어도 된다.
##
## ★ 영어 번역을 **항상** 등록해 두면 안 된다. Godot 의 기본 대체 언어가 영어라서,
##   한국어를 골라도 "ko 번역에 없음 → 대체 언어 en 에서 찾음" 으로 영어가 새어 나온다.
##   영어일 때만 등록하고, 한국어로 돌아가면 뺀다.
const LANGS: Array = ["ko", "en"]
var lang_idx: int = -1
static var _en_tr: Translation = null

func lang() -> String:
	# 실행 인자 --lang=en 이 설정보다 앞선다(세이브는 안 바꾼다). 검사와 영어 스토어 스크린샷용.
	# 메뉴가 _ready 에서 문구를 조합하므로 판이 뜬 뒤에 바꾸면 늦다 — 처음부터 정해져 있어야 한다.
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--lang="):
			var v: String = String(a).substr(7)
			if LANGS.has(v):
				return v
	if lang_idx >= 0:
		return String(LANGS[clampi(lang_idx, 0, LANGS.size() - 1)])
	return "ko" if OS.get_locale_language() == "ko" else "en"


func apply_lang() -> void:
	var want: String = lang()
	if want == "en":
		if _en_tr == null:
			_en_tr = Translation.new()
			_en_tr.locale = "en"
			for k in I18nEn.EN:
				_en_tr.add_message(StringName(k), StringName(I18nEn.EN[k]))
		if not TranslationServer.get_loaded_locales().has("en") or not _en_registered:
			TranslationServer.add_translation(_en_tr)
			_en_registered = true
	elif _en_registered and _en_tr != null:
		TranslationServer.remove_translation(_en_tr)
		_en_registered = false
	TranslationServer.set_locale(want)


var _en_registered: bool = false


## 설정에서 바꾼다. 이미 만들어진 화면의 조합 문구("레벨 %d" % n 처럼 코드가 만든 것)는
## 자동으로 안 바뀌므로, 씬을 다시 불러 메인 메뉴부터 새 언어로 그린다.
## ── 캐릭터 그림 (시범) ──
## 새 캐릭터 에셋(charforge)을 쓸지. 끄면 전 자리가 예전 그림 — 같은 기기에서 둘을 바로 견준다.
## 실행 인자 --cf=off / --cf=on 이 설정보다 앞선다(검사·비교 스크린샷용, 세이브는 안 바꾼다).
var cf_on: bool = true

func apply_cf() -> void:
	var on: bool = cf_on
	for a in OS.get_cmdline_user_args():
		if String(a) == "--cf=off":
			on = false
		elif String(a) == "--cf=on":
			on = true
	CharForge.enabled = on


func set_cf(on: bool) -> void:
	cf_on = on
	save_game()
	apply_cf()


func set_lang(i: int) -> void:
	lang_idx = i
	save_game()
	apply_lang()


var stick_fix_idx: int = -1

func stick_fixed() -> bool:
	return (stick_fix_idx if stick_fix_idx >= 0 else 0) == 0


func set_stick_fixed(i: int) -> void:
	stick_fix_idx = i
	save_game()


func set_perf(i: int) -> void:
	perf_idx = i
	apply_perf()
	save_game()


# ──────────────────────── 가독성: 인터페이스/화면 확대 (S1) ────────────────────────
## 13차: 1.22 · 1.42 → 4/3 · 5/3. 1080 화면(×1.5)에서 UI 도트(그림 1px = UI 2px)와 갈무리 글꼴이
## 3 · 4 · 5 배 정수로 찍힌다 — 소수 배율이면 도트 계단이 칸마다 달라진다(UiFont 설명).
const HUD_SCALES: Array = [1.0, 4.0 / 3.0, 5.0 / 3.0]
const CAM_ZOOMS: Array = [1.0, 1.15, 1.3]


## 인터페이스 크기 자동값. 11/5 부터 PC 도 가운데 칸(1)이다.
## ★ 16차 4-5: 스팀덱(1280×800)에서 「작게」면 HUD 글자가 10px 안팎이 된다(7인치 화면).
## ★ 11/5 스팀 피드백 2 · 3: PC 기본(목업 크기)은 1080 전체 화면에서도 HUD 글자가 12px 쯤이라 작다는 말이 나왔다.
##   칸 이름도 「작게 · 보통 · 크게」로 한 칸씩 내렸다 — 예전 「크게」를 고른 사람은 새 「보통」으로 크기가 같다.
func ui_scale_default() -> int:
	return 1


## ── 11/5 스팀 피드백 2 · 4 · 5: 인터페이스 배수를 창이 아니라 모니터에 맞춘다 ──
## ★ 예전 HUD 배수는 칸마다 고정(논리 좌표 ×2/3 · ×1 · ×4/3)이라 화면 위 크기가 창 크기를 그대로 따라갔다.
##   1280×720 창이면 1080 전체 화면의 2/3 — 체력 막대 · 글자가 콩알만 했다(4K 모니터 창이면 더).
##   이제 칸마다 「1080 모니터에서 목업 1px = 화면 몇 px」(UI_PHYS)을 정하고, 모니터가 크면 그만큼 키운 뒤
##   창의 늘이기 배수(k)로 나눠 HUD 배수를 낸다. 창이 작아도 글자 크기가 모니터 기준으로 남는다.
##   창이 너무 작아 판이 안 들어가는 것은 UI_S_MAX(예전 「아주 크게」, 폰에서 검사한 끝값)로 막는다.
## ★ 화면 배수는 0.5 단위로 맞춘다 — 갈무리 글꼴(설계 px ×2)과 부품(×2)이 화면에서 정수배로 찍힌다(UiFont 설명).
const UI_PHYS: Array = [1.0, 1.5, 2.0]
const UI_S_MIN: float = 2.0 / 3.0
const UI_S_MAX: float = 4.0 / 3.0


func ui_scale_level() -> int:
	return clampi(ui_scale_idx if ui_scale_idx >= 0 else ui_scale_default(), 0, 2)


## 창(논리 좌표 → 화면 px) 늘이기 배수. canvas_items + expand 라 가로세로가 같다.
func canvas_k(vp: Vector2) -> float:
	var win: Vector2i = get_tree().root.size
	if vp.x <= 0.0 or win.x <= 0:
		return 1.0
	return float(win.x) / vp.x


## 모니터 크기 배수(1080 = 1). 검사는 --monitor=WxH 로 다른 모니터를 흉내 낸다.
func monitor_k() -> float:
	if _mon_k > 0.0:
		return _mon_k
	var h: float = 1080.0
	var forced: bool = false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--monitor="):
			h = float(a.get_slice("=", 1).get_slice("x", 1))
			forced = true
	if not forced and DisplayServer.get_name() != "headless":
		h = float(DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()).y)
	_mon_k = clampf(h / 1080.0, 0.74, 2.5)
	return _mon_k


var _mon_k: float = -1.0   # 창 크기가 바뀌거나 다른 모니터로 옮기면 다시 잰다(_on_root_resized · _watch_display)
var _world_ui: float = 1.0


func _on_root_resized() -> void:
	_mon_k = -1.0
	_world_ui = world_ui_scale()


## 목표 화면 배수(목업 1px 이 화면 몇 px 인가) — 0.5 단위로 맞추기 전 값.
func ui_phys_target() -> float:
	return float(UI_PHYS[ui_scale_level()]) * monitor_k()


## HUD · 레벨업 · 상자 · 결과 창 배수(1920 좌표 → 논리 좌표). 판이 들어가는지는 부르는 쪽이 한 번 더 줄인다.
func hud_layer_scale(vp: Vector2) -> float:
	if DisplayServer.get_name() == "headless":
		return [2.0 / 3.0, 1.0, 4.0 / 3.0][ui_scale_level()]
	var e: float = maxf(0.5, roundf(ui_phys_target() * 2.0) / 2.0)
	return clampf(e / canvas_k(vp), UI_S_MIN, UI_S_MAX)


## 게임 세상 안에 그리는 글자 · 막대(영웅 발밑 체력 · 피해 숫자) 배수. 1080 전체 화면 · 「보통」 = 1(예전 모습).
## 창이 작아 세상이 작게 그려지면 그만큼 키운다 — 1 아래로는 줄이지 않고, 2배에서 멈춘다.
func world_ui_scale() -> float:
	if DisplayServer.get_name() == "headless":
		return 1.0
	var vp: Vector2 = get_tree().root.get_visible_rect().size
	var z: float = cam_zoom()
	var w: float = ui_phys_target() / maxf(0.01, canvas_k(vp) * z)   # 1080 전체 화면 · 보통: 1.5 / (1.5 × 1) = 1
	return clampf(roundf(w * 2.0) / 2.0, 1.0, 2.0)


## 인터페이스(HUD/카드) 확대 배수. 자동(-1)이면 모바일 · 작은 화면 = 크게.
func hud_scale() -> float:
	var i: int = ui_scale_idx
	if i < 0:
		i = ui_scale_default()
	return float(HUD_SCALES[clampi(i, 0, 2)])


## 게임 화면(카메라) 확대 배수 — 캐릭터/몬스터가 커 보임. 자동(-1)이면 모바일=크게.
func cam_zoom() -> float:
	var i: int = cam_zoom_idx
	if i < 0:
		i = 1 if mobile else 0
	return float(CAM_ZOOMS[clampi(i, 0, 2)])


func set_ui_scale(i: int) -> void:
	ui_scale_idx = i
	save_game()
	ui_scale_changed.emit()


func set_cam_zoom(i: int) -> void:
	cam_zoom_idx = i
	_world_ui = world_ui_scale()
	save_game()
	if camera != null and is_instance_valid(camera):
		(camera as Camera2D).zoom = Vector2.ONE * cam_zoom()


# ──────────────────────── 스테이지 진행/보상 (S1) ────────────────────────
const STAGE_NAMES: Array = ["던전", "도서관", "정원", "용암동굴", "천상계", "저승길"]
const STAGE_LEN: float = 480.0  # 스테이지 클리어제: 8분 뒤 스테이지 보스 → 처치 시 클리어
# 스테이지가 오를수록 적이 '확확' 강해지고 (티어 배수와 곱연산) 골드도 크게 오른다.
const STAGE_HP_STEP: float = 1.45    # 적 체력 ×1.45^스테이지
const STAGE_GOLD_STEP: float = 0.55  # 골드 +55%/스테이지


func stage_cleared(i: int, d: int) -> bool:
	return stage_prog.has("c_%d_%d" % [i, d])


## 스테이지 i를 난이도 d로 플레이 가능? — 이전 스테이지(같은 티어) + 같은 스테이지(이전 티어) 클리어 필요.
func stage_unlocked(i: int, d: int) -> bool:
	if i > 0 and is_demo():   # 체험판은 첫 스테이지만
		return false
	if i > 0 and not stage_cleared(i - 1, d):
		return false
	if d > 0 and not stage_cleared(i, d - 1):
		return false
	return true


# ──────────────────────── 클리어 기록 · 별 등급 ────────────────────────
## ★ 예전에는 클리어 여부가 불리언 하나뿐이라, 한 번 깬 조합을 다시 깰 이유가 없었다.
##   같은 판을 '더 잘' 깨는 축을 만들기 위해 기록을 남긴다:
##     c_i_d  클리어 여부 · t_i_d  최고(=최단) 보스전 시간 · s_i_d  최고 별 등급 · k_i_d  최다 처치
var boss_fight_t: float = 0.0   # 최종/스테이지 보스가 등장한 뒤 흐른 시간 (등급 판정용)
var hits_taken: int = 0
var dmg_recv: float = 0.0          # 이번 런에서 받은 피해 합(방어 뒤) — 밸런스 하니스가 30초마다 읽는다
var last_hit_src: String = "-"   # 플레이어가 마지막으로 맞은 원인 (밸런스 하니스 사망 분석용)         # 이번 런에서 맞은 횟수 (전체)
var boss_hits: int = 0          # 보스전에서만 맞은 횟수 — 결과 화면이 이 값을 쓴다
var no_hit_boss: bool = true    # 보스전 무피격 여부
var run_fusions: int = 0        # 이번 런에서 완성한 융합 수 (한 판 3종 도전과제)

## 최종 결전 시작 — 별 등급 판정에 쓰는 시계를 켠다.
## ★ 스폰 지점이 둘(스테이지 보스 · 무한 최종 보스)이라 한쪽만 빠지면 별이 전부 3개로 굳는다.
##   실제로 그렇게 새서, 시작 지점을 이 함수 하나로 모았다.
func begin_boss_fight() -> void:
	boss_fight_t = 0.001
	no_hit_boss = true
	boss_hits = 0  # ★ 예전엔 런 전체 피격수를 '보스전 피격'으로 찍어 「피격 68회 · 보스전 무피격」이 같이 나왔다


## 별 등급 0~3. 깨기만 해도 1개, 빠르게 2개, 빠르고 안 맞으면 3개.
func clear_stars(fight_sec: float, no_hit: bool) -> int:
	var st: int = 1
	if fight_sec <= 90.0:
		st += 1
	if fight_sec <= 60.0 and no_hit:
		st += 1
	return st


func stage_stars(i: int, d: int) -> int:
	return int(stage_prog.get("s_%d_%d" % [i, d], 0))


func stage_best_time(i: int, d: int) -> float:
	return float(stage_prog.get("t_%d_%d" % [i, d], 0.0))


func stage_best_kills(i: int, d: int) -> int:
	return int(stage_prog.get("k_%d_%d" % [i, d], 0))


## 클리어한 조합 수 (별이 몇 개든 1로 셈).
func cleared_count() -> int:
	var n: int = 0
	for i in STAGE_NAMES.size():
		for d in 4:
			if stage_cleared(i, d):
				n += 1
	return n


## 모은 별 총합 (스테이지 6 × 난이도 4 × 별 3 = 최대 72).
func star_total() -> int:
	var n: int = 0
	for i in STAGE_NAMES.size():
		for d in 4:
			n += stage_stars(i, d)
	return n


## 클리어 기록 + 첫 클리어 보너스 골드 반환(0이면 재클리어).
## 별/최단시간/최다처치는 갱신됐을 때만 덮어쓴다 — 못 한 판을 쳐도 기록이 깎이지 않는다.
func mark_stage_clear(i: int, d: int) -> int:
	var key: String = "c_%d_%d" % [i, d]
	var first: bool = not stage_prog.has(key)
	stage_prog[key] = true
	var st: int = clear_stars(boss_fight_t, no_hit_boss)
	if no_hit_boss:
		stat_add("nohit_clears", 1)
	if boss_fight_t > 0.0 and boss_fight_t <= 60.0:
		stat_add("swift_clears", 1)
	if st > stage_stars(i, d):
		stage_prog["s_%d_%d" % [i, d]] = st
	var bt: float = stage_best_time(i, d)
	if bt <= 0.0 or boss_fight_t < bt:
		stage_prog["t_%d_%d" % [i, d]] = boss_fight_t
	if kills > stage_best_kills(i, d):
		stage_prog["k_%d_%d" % [i, d]] = kills
	stats["stages_cleared"] = cleared_count()
	stat_max("best_stars", star_total())
	stat_max("best_combo", combo_best)
	quest_add("clear", 1)
	check_achievements()
	save_game()
	if first:
		return first_clear_gold(i, d)
	return 0


func first_clear_gold(i: int, d: int) -> int:
	return int(round(120.0 * float(i + 1) * [1.0, 1.6, 2.6, 4.2, 6.0][clampi(d, 0, DIFF_MAX)]))


## ── 11/14 무한 기록 · 무한 별 ──
## 이용자: 「무한 모드엔 왜 별 같은 게 안 뜨나 · 깨거나 보스를 잡아도 쌓이는 게 없다」.
##   스테이지 별(6 × 4 × 3 = 72)은 그대로 두고, 무한에는 난이도(쉬움~지옥)마다 별 0~3 을 따로 둔다.
##   매기는 법은 스테이지와 같다(clear_stars) — 완주 1 · 사신을 90초 안에 잡으면 2 · 60초 안에 안 맞고 잡으면 3.
##   그래서 무한 별은 난이도 다섯 × 3 = 15 개다.
##   endless_prog 키: "c_<d>" 완주 · "s_<d>" 별 · "t_<d>" 사신 최단(초) · "k_<d>" 완주 판 최다 처치 · "b_<d>" 가장 오래 버틴 초(못 깬 판 포함)
const ENDLESS_STAR_MAX: int = 15

func endless_cleared(d: int) -> bool:
	return endless_prog.has("c_%d" % d)


func endless_stars(d: int) -> int:
	return int(endless_prog.get("s_%d" % d, 0))


func endless_best_boss(d: int) -> float:
	return float(endless_prog.get("t_%d" % d, 0.0))


func endless_best_kills(d: int) -> int:
	return int(endless_prog.get("k_%d" % d, 0))


func endless_best_time(d: int) -> int:
	return int(endless_prog.get("b_%d" % d, 0))


func endless_star_total() -> int:
	var n: int = 0
	for d in DIFF_MAX + 1:
		n += endless_stars(d)
	return n


## 무한 판이 끝날 때(완주 · 사망 둘 다) 버틴 시간을 그 난이도 기록에 남긴다. 기록이 올랐으면 true.
func note_endless_time(d: int, sec: int) -> bool:
	if sec <= endless_best_time(d):
		return false
	endless_prog["b_%d" % d] = sec
	return true


## 무한 완주 기록 — 별 · 사신 최단 · 처치는 올랐을 때만 덮어쓴다(못 한 판이 기록을 깎지 않게).
## 결과 창이 배지를 고르도록 전과 후를 돌려준다. 도전과제 판정은 run_ended() 가 한다.
func mark_endless_clear(d: int) -> Dictionary:
	var first: bool = not endless_cleared(d)
	var prev_star: int = endless_stars(d)
	var prev_t: float = endless_best_boss(d)
	var star: int = clear_stars(boss_fight_t, no_hit_boss)
	endless_prog["c_%d" % d] = true
	if star > prev_star:
		endless_prog["s_%d" % d] = star
	var faster: bool = boss_fight_t > 0.0 and (prev_t <= 0.0 or boss_fight_t < prev_t)
	if faster:
		endless_prog["t_%d" % d] = boss_fight_t
	if kills > endless_best_kills(d):
		endless_prog["k_%d" % d] = kills
	stats["endless_d%d" % d] = 1
	stat_max("endless_stars", endless_star_total())
	return {"first": first, "star": star, "prev_star": prev_star, "faster": faster and prev_t > 0.0}


## 난이도마다 처음 완주하면 따는 도전과제(매우어려움은 예전부터 있던 endless_hard 가 맡는다).
const ENDLESS_CLEAR_ACH: Array = ["ENDLESS_CLEAR_EASY", "ENDLESS_CLEAR_NORMAL", "ENDLESS_CLEAR_HARD", "endless_hard", "ENDLESS_CLEAR_HELL"]

## 그 난이도를 처음 완주하면 받는 골드(영웅 고르는 곳 「첫 완주 +NG」). 이미 딴 도전과제면 0.
func endless_first_gold(d: int) -> int:
	var id: String = String(ENDLESS_CLEAR_ACH[clampi(d, 0, DIFF_MAX)])
	if achievements.has(id):
		return 0
	for a: Dictionary in Codex.ACHIEVEMENTS:
		if String(a["id"]) == id:
			return int(a.get("gold", 0))
	return 0


## 스테이지 모드 적 체력/피해 추가 배수 (티어 배수와 곱연산).
## 시작 5분에 걸쳐 1.0 → 만배율로 램프 — 빌드 없는 초반 붕괴 방지, 후반 스테이지 격차 유지.
func stage_power() -> float:
	if run_mode != "stage":
		return 1.0
	var f: float = clampf(time_alive / 300.0, 0.0, 1.0)
	return lerpf(1.0, pow(STAGE_HP_STEP, float(stage_sel)), f)


## 모드/스테이지 골드 배수 — 높은 스테이지일수록 벌이가 크게 오름
func stage_gold_mult() -> float:
	if run_mode != "stage":
		return 1.0
	return 1.0 + STAGE_GOLD_STEP * float(stage_sel)


## 영구 강화가 쌓인 만큼 몬스터도 같이 강해지는 배수.
## ★ 영구 강화를 30단계, 영웅 등급을 20단계로 잘게 쪼개 놨는데 몹은 그걸 전혀 안 본다.
##   그러면 상점을 파고들수록 같은 스테이지가 계속 쉬워지기만 하고, 어느 시점부터는
##   난이도라는 게 사라진다 — 강화할 이유도 같이 사라진다.
##   여기서 '내가 얼마나 강해졌는지'를 몹 체력에 절반쯤 되돌려 준다(절반이라 성장은 체감된다).
##   공격력 메타·영웅 등급·장신구를 다 합친 실효 배수를 쓰므로 새 강화를 추가해도 자동 반영된다.
## rank_override 를 주면 그 등급으로 계산한다 — 선택 화면이 "별 하나 더 찍으면 몹은 얼마나
## 세지나"를 적으려면 필요하다. 수식을 화면 쪽에서 다시 쓰면 반드시 갈린다.
func meta_power(rank_override: int = -1) -> float:
	if rank_override < 0 and _run_meta_power > 0.0 and running:
		return _run_meta_power
	var p: float = 1.0 + meta_bonus("m_dmg")          # 상점 공격력 (최대 +90%)
	# ★ 17-2: 체력 강화(m_hp)는 뺐다. 넣으면 만렙 몹이 ×2.57 로 아래 주석의 한계(×2.10)를 넘었다 —
	#   봇 시험(10/12)에서 만렙 강화가 지금 세이브보다 덜 깼다(어려움 스테이지 1·3·6 클리어 8% 대 35%, 8분 레벨 22 대 26).
	#   체력을 사도 몹이 단단해지면 「강화할수록 어려워지는」 쪽으로 기운다. 공격 강화와 등급만 되먹인다.
	var rk: int = char_rank(last_char_id) if rank_override < 0 else rank_override
	p *= 1.0 + RANK_DMG * float(rk)                   # 영웅 등급 (최대 +50%)
	# 0.35 = 플레이어 성장의 3분의 1 강. 실측으로 0.55 는 과했다 —
	# 만렙 강화 기준 플레이어 ×2.85 인데 몹이 ×2.10 을 넘어서면 '강화할수록 어려워지는' 게임이 된다.
	# 이 값에서 플레이어가 1.35배쯤 앞선다: 강화는 체감되고, 난이도는 사라지지 않는다.
	# 2026-10-06: 0.35 → 0.5. 강화를 갖춘 플레이어 기준으로 난이도를 맞춘다(사용자 요구). 0.55 는 과했다는 기록이 있어 그 아래.
	return 1.0 + (p - 1.0) * 0.5


var last_char_id: String = "base"  # 이번 판에 고른 영웅 (몹 스케일이 등급을 참조한다)

## 판이 도는 동안의 meta_power — 10/13 QA C4.
## 판 도중 일시정지 → 메인 메뉴 → 영구 강화 · 등급 올리기 → 이어하기 를 하면 영웅 능력치는 판 시작 때
## 그대로인데 몹(meta_power)만 바로 세졌다. 판 시작 때 값을 잡아 두고 판이 끝나면 푼다.
var _run_meta_power: float = -1.0


func lock_run_meta_power() -> void:
	_run_meta_power = -1.0
	_run_meta_power = meta_power()


## 잡몹 체력 배수 — 기본 체력에 곱해지는 값 하나로 모은다.
## ★ 예전엔 이 식이 enemy.gd 안에만 있었고 검사 하니스가 같은 식을 복제해서 들고 있었다.
##   한쪽만 고치면 표가 조용히 거짓말을 한다(실제로 그랬다). 이제 양쪽이 이 함수를 부른다.
##   축은 넷: 시간 · 플레이어 레벨 · 난이도/스테이지 · 영구강화(meta_power).
func enemy_hp_scale(lvl: int, t_alive: float) -> float:
	var tmin: float = t_alive / 60.0
	# 시간항을 낮추고 레벨항을 키웠다 — 몹이 '시계'가 아니라 '내 성장'을 보고 따라오면
	# 한 번 밀렸을 때도 회복이 가능하다(예전엔 시간항이 압도해 그대로 스노볼 역전됐다).
	var tcurve: float = (1.0 + pow(tmin, 1.15) * 0.24) if run_mode == "stage" else (1.0 + pow(tmin, 1.3) * 0.46)
	# 라이더를 걷어내 플레이어 화력이 줄었으므로 레벨항도 같이 낮췄었다(0.085 → 0.065).
	# 2026-09-06: 만렙 특성 16종 + 오브 반경 성장 복구로 처치 속도가 실측 약 2배가 됐다.
	# 되돌리는 게 아니라 그 3분의 1만 되민다 — 특성이 체감되는 몫은 남겨 둔다.
	var lvl_f: float = 1.0 + float(maxi(0, lvl - 1)) * 0.071
	# ★ 2026-09-06: 시간항과 레벨항을 **그냥 곱하고** 있었다. 그런데 둘은 독립이 아니다 —
	#   시간이 흐르니까 레벨이 오른다. 같은 것을 두 번 세는 셈이라 사실상 제곱으로 자랐다.
	#   8분 시점 실측: 몹 체력 ×10.6 인데 플레이어 화력은 ×9 — 오래 버틸수록 뒤처진다.
	#   (game.gd 위쪽 meta_power 주석이 경고한 "강화할수록 어려워지는 게임"이 시간축에서
	#    그대로 벌어지고 있었다.)
	#   레벨항의 지수를 낮춰 겹침을 걷어낸다. 1분 시점은 -17%, 8분 시점은 -37% —
	#   초반은 거의 그대로고 긴 판일수록 숨통이 트인다. 스테이지(8분 완주)가 특히 그렇다.
	return tcurve * pow(lvl_f, 0.55) * diff_hp_mult() * stage_power() * meta_power() * overtime_hp_mult() * karma_hp_mult()


# ──────────────────── 몹 압력 시각 (2026-10-06) ────────────────────
## 몹 수(상한·간격·한 번에 나오는 양) · 몹 체력의 시간 곡선 · 몹 공격력이 '경과 시간' 대신 이 값을 본다.
## 사용자: "플레이어 레벨에 따라 몹 수·체력·공격력이 올라야지, 무작정 시간에 따라 바뀌면 안 된다.
##   무한정 세지면 안 되고 난이도별 최대치가 있어야 한다. 무한 모드는 레벨 따라 오르되 30분은 버텨야 한다."
## 값 = 지금 레벨이 '보통 판에서 몇 초쯤 나오는 레벨인가'(LEVEL_T_* 표, --balance 실측).
##   보통 속도로 크는 판은 예전(시간 기준)과 같고, 빨리 크면 몹도 빨리, 늦게 크면 늦게 따라온다.
## 바닥: 경과 시간 × PRESS_FLOOR — 레벨을 안 올려도(경험치를 피해도) 판이 멈추지 않게.
## 상한: 난이도별 PRESS_MAX_*(초) — 그 시각의 압력보다 더 세지지 않는다.
const PRESS_FLOOR: float = 0.6
## 몹 **수**의 바닥은 더 높다 — 수까지 레벨만 보면 레벨이 느린 판은 몹이 적게 나와 경험치가 끊기고,
## 그래서 레벨이 더 느려지는 악순환이 생긴다(매우어려움 실측: 30분 레벨 34, 처치 79초). 경험치 공급은 시간이 받친다.
const PRESS_FLOOR_COUNT: float = 0.85
## 체력·공격력의 바닥은 이 시각에서 멈춘다 — 그 위로는 **레벨이 올라야만** 난이도별 상한까지 오른다. 어려움·매우어려움은 레벨이
## 원래 느려서 바닥(시간 × 0.6)이 30분에 1080초까지 끌고 가 다시 시간 기준이 됐다(실측: 매우어려움 30초 피해 9,700).
const PRESS_FLOOR_MAX: float = 600.0
## [레벨, 보통 판에서 그 레벨이 되는 초] — 갈덴(등급 6)·실제 세이브·보통, 시드 평균. 표 끝 너머는 마지막 기울기로 잇는다.
## 무한 · --immortal · 시드 7/11 평균, 60초 간격으로 솎음 (2026-10-06)
const LEVEL_T_ENDLESS: Array = [[1, 0.0], [6, 30.0], [11.5, 60.0], [16, 90.0], [18.5, 120.0], [22.5, 180.0], [25.5, 240.0], [29, 300.0],
	[30.5, 360.0], [33, 420.0], [34.5, 480.0], [36, 540.0], [38.5, 600.0], [41.5, 660.0], [44.5, 720.0], [47.5, 780.0],
	[49.5, 840.0], [51.5, 900.0], [55, 960.0], [57, 1020.0], [58.5, 1080.0], [60.5, 1140.0], [62, 1200.0], [64, 1260.0],
	[65, 1320.0], [67, 1380.0], [68.5, 1440.0], [69.5, 1500.0], [71, 1560.0], [72, 1620.0], [73, 1680.0], [74.5, 1740.0],
	[75, 1800.0]]
## 스테이지 1 · --immortal · 시드 7/11/23 평균 (2026-10-06)
const LEVEL_T_STAGE: Array = [[1, 0.0], [5.0, 30.0], [10.3, 60.0], [15.3, 90.0], [18.7, 120.0], [21.7, 150.0],
	[24.3, 180.0], [26.0, 210.0], [28.7, 240.0], [31.0, 270.0], [32.7, 300.0], [34.7, 330.0], [36.3, 360.0],
	[37.7, 390.0], [39.7, 420.0], [41.0, 450.0], [42.7, 480.0]]
## 쉬움 · 보통 · 어려움 · 매우어려움
## 무한은 30분을 버틸 수 있게 이 시각의 압력에서 멈춘다(그 뒤엔 플레이어만 강해진다).
## 실측(옛 시간 기준, 갈덴·보통): 대표몹 처치시간 10분 6.6초 → 16분 10초 → 30분 25.8초 — 후반이 벽이었다.
const PRESS_MAX_ENDLESS: Array = [600.0, 840.0, 1080.0, 1320.0, 1500.0]
## 스테이지도 8분 수준에서 막지 않는다 — 레벨이 빠른(강화를 많이 한) 판은 그만큼 더 세진다(2026-10-06 사용자:
## "쉬움 3스테이지, 영웅 7단계·기본 스탯·유물 갖추고 2분 뒤 가만히 있어도 무적, 8분에 3만 마리").
const PRESS_MAX_STAGE: Array = [720.0, 840.0, 960.0, 1080.0, 1200.0]


var press_time_only: bool = false   # 하니스 --press=time: 예전(시간 기준)과 같은 코드로 나란히 비교


## floor_cap: 바닥이 멈추는 시각. 체력·공격력은 PRESS_FLOOR_MAX(레벨이 올라야 그 위로), 몹 수는 상한 없이(경험치 공급).
func pressure_t(floor_frac: float = PRESS_FLOOR, floor_cap: float = PRESS_FLOOR_MAX) -> float:
	if press_time_only:
		return time_alive
	var stage: bool = run_mode == "stage"
	var t_lvl: float = level_to_time(LEVEL_T_STAGE if stage else LEVEL_T_ENDLESS, level)
	var t: float = maxf(t_lvl, minf(time_alive * floor_frac, floor_cap))
	return minf(t, _dv(PRESS_MAX_STAGE if stage else PRESS_MAX_ENDLESS))


## 표에서 레벨 → 초(구간 직선). 표 끝 너머는 마지막 구간의 기울기로 늘린다(상한은 pressure_t 가 건다).
static func level_to_time(tab: Array, lvl: int) -> float:
	var x: float = float(lvl)
	if x <= float(tab[0][0]):
		return float(tab[0][1])
	for i in range(1, tab.size()):
		var a: Array = tab[i - 1]
		var b: Array = tab[i]
		if x <= float(b[0]) or i == tab.size() - 1:
			var u: float = (x - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0]))
			return float(a[1]) + (float(b[1]) - float(a[1])) * u
	return float(tab[tab.size() - 1][1])


## 잡몹 공격력(몸박·적탄) 배수 — enemy.gd 와 밸런스 하니스가 같이 부른다(한 곳에만 둔다).
func enemy_touch_scale(t_alive: float) -> float:
	return diff_dmg_mult() * (1.0 + t_alive / 60.0 * 0.30) * sqrt(stage_power() * meta_power()) * overtime_dmg_mult() * karma_dmg_mult()


## 총 골드 배수(난이도 × 스테이지) — 드랍 계산 공용
func run_gold_mult() -> float:
	return diff_gold_mult() * stage_gold_mult()


# ──────────────────────── 해금 경제 (S1): 캐릭터/특수무기 ────────────────────────
## meta["uc_<id>"]=1 캐릭터 해금 / meta["uw_<id>"]=1 무기 해금. 조건 충족 시 자동 해금.
func char_unlocked(id: String) -> bool:
	if id == "base":
		return true
	if is_demo() and not DEMO_HEROES.has(id):   # 체험판은 영웅 둘
		return false
	if int(meta.get("uc_" + id, 0)) > 0:
		return true
	return _cond_met(Characters.unlock_of(id))


func try_buy_char(id: String) -> bool:
	var u: Dictionary = Characters.unlock_of(id)
	var cost: int = int(u.get("gold", 0))
	if is_demo() and not DEMO_HEROES.has(id):
		return false
	if cost <= 0 or total_gold < cost or char_unlocked(id):
		return false
	total_gold -= cost
	meta["uc_" + id] = 1
	save_game()
	return true


## 해금 조건({"stat","need"} 또는 {"stage","tier"}) 충족 여부
func _cond_met(u: Dictionary) -> bool:
	if u.is_empty():
		return false
	if u.has("stat"):
		return int(stats.get(String(u["stat"]), 0)) >= int(u.get("need", 999999))
	if u.has("stage"):
		# ★ 예전엔 난이도를 아예 안 봤다 — '쉬움'으로 한 번 깨면 모든 해금이 열려서
		#   상위 난이도로 갈 이유가 사라졌다. diff 를 적으면 그 난이도 이상에서만 인정한다.
		var need_d: int = int(u.get("diff", 0))
		for d in range(need_d, 4):
			if stage_cleared(int(u["stage"]), d):
				return true
		return false
	return false


## 특수무기 해금 정의 — 조건 달성(자동) 또는 골드 구매(상점). 나머지 무기는 기본 제공.
const WPN_UNLOCKS: Dictionary = {
	"wpn_boomerang": {"name": "부메랑", "desc": "던져서 되돌아오는 관통 무기", "stat": "best_time", "need": 360, "cond": "한 판 6분 생존", "gold": 400},
	"summon_ice": {"name": "얼음 정령", "desc": "얼음탄을 쏘는 소환수", "stat": "total_bosses", "need": 3, "cond": "보스 누적 3 처치", "gold": 500},
	"wpn_beam": {"name": "회전 레이저", "desc": "회전하며 스치는 적을 지짐", "stat": "total_kills", "need": 3000, "cond": "누적 3,000 처치", "gold": 700},
	# 이면 무기 — 요괴를 만나기 시작해야 열린다
	"wp_bow": {"name": "각궁", "desc": "멀리·빠르게·꿰뚫는 화살", "stat": "yokai_seen", "need": 1, "cond": "이면 요괴 1종 도감", "gold": 2200},
	"wp_fan": {"name": "태극 부채", "desc": "앞을 넓게 덮는 부채꼴 6발", "stat": "yokai_seen", "need": 4, "cond": "이면 요괴 4종 도감", "gold": 3400},
	"wp_sinkal": {"name": "신칼", "desc": "손이 안 보이는 쌍칼 연격", "stat": "best_stars", "need": 6, "cond": "클리어 별 6개", "gold": 4600},
	"wp_jakdu": {"name": "작두", "desc": "몸을 돌려 반원을 베어낸다", "stat": "best_stars", "need": 15, "cond": "클리어 별 15개", "gold": 8000},
}


func wpn_unlocked(id: String) -> bool:
	if not WPN_UNLOCKS.has(id):
		return true
	if int(meta.get("uw_" + id, 0)) > 0:
		return true
	return _cond_met(WPN_UNLOCKS[id])


func try_buy_wpn(id: String) -> bool:
	var u: Dictionary = WPN_UNLOCKS.get(id, {})
	var cost: int = int(u.get("gold", 0))
	if cost <= 0 or total_gold < cost or wpn_unlocked(id):
		return false
	total_gold -= cost
	meta["uw_" + id] = 1
	save_game()
	return true


# ──────────────────────────── 도감 / 도전과제 ────────────────────────────

## 도감 항목 해금 (신규면 저장 + 토스트 시그널). 몹/맵/융합 카운트 통계도 갱신.
func codex_see(key: String) -> void:
	if codex.has(key):
		return
	codex[key] = true
	stats["mon_seen"] = _codex_count("mon_")
	stats["map_seen"] = _codex_count("map_")
	stats["fus_seen"] = _codex_count("fus_")
	stats["yokai_seen"] = _yokai_seen()
	codex_unlocked.emit(key)
	check_achievements()
	save_game()


func _codex_count(prefix: String) -> int:
	var n: int = 0
	for k in codex.keys():
		if String(k).begins_with(prefix):
			n += 1
	return n


## 도감에 등록된 이면 요괴 총수 (mon_16 이상).
func _yokai_total() -> int:
	var n: int = 0
	for e: Dictionary in Codex.MONSTERS:
		var k: String = String(e["key"])
		if k.begins_with("mon_") and _is_yokai(int(k.substr(4))):
			n += 1
	return n


## 이면 요괴(kind 16 이상) 도감 수집 수.
func _yokai_seen() -> int:
	var n: int = 0
	for k in codex.keys():
		var ks: String = String(k)
		if ks.begins_with("mon_") and _is_yokai(int(ks.substr(4))):
			n += 1
	return n


## 이면 요괴 = kind 16~28. 저승길 몹(29~)은 따로 센다 — 「이면을 보다」 · 영웅 해금 조건이 저승길을 요구하지 않게.
static func _is_yokai(k: int) -> bool:
	return k >= 16 and k <= 28


func stat_add(key: String, n: int) -> void:
	stats[key] = int(stats.get(key, 0)) + n


func stat_max(key: String, v: int) -> void:
	if v > int(stats.get(key, 0)):
		stats[key] = v


## 누적 통계 기준으로 미달성 도전과제를 판정 → 신규 달성 시 골드 보상 + 시그널.
func check_achievements() -> void:
	var changed: bool = false
	for a: Dictionary in Codex.ACHIEVEMENTS:
		var id: String = String(a["id"])
		if achievements.has(id):
			continue
		# need 가 음수면 '도감을 전부 모아라' — 콘텐츠를 늘려도 목표치가 따라 오른다.
		# (예전엔 16/5 가 상수로 박혀 있어 몹을 늘리면 미수집 상태로 먼저 달성됐다)
		var need: int = ach_need(a)
		if int(stats.get(String(a["stat"]), 0)) >= need:
			achievements[id] = true
			total_gold += int(a.get("gold", 0))
			achievement_unlocked.emit(a)
			changed = true
	if changed:
		save_game()


## 한 판 종료 시 호출 (main 게임오버/최종보스) — 기록 갱신 + 판정.
func run_ended() -> void:
	_run_meta_power = -1.0
	stat_add("runs", 1)
	stat_max("best_combo", combo_best)
	stat_max("best_run_fusions", run_fusions)
	quest_add("runs", 1)
	stat_max("best_time", int(time_alive))
	stat_max("best_level", level)
	check_achievements()
	save_game()


func apply_volume() -> void:
	master_volume = clampf(master_volume, 0.0, 1.0)
	var db: float = -60.0 if master_volume <= 0.001 else linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(0, db)


## 메타(영구 업글) 기반 현재 능력치 요약 — 메인 메뉴/상점에서 표시.
func meta_stat_lines() -> Array:
	var hp: float = Player.MAX_HP + meta_bonus("m_hp")
	var dmg: float = Player.BULLET_DMG * (1.0 + meta_bonus("m_dmg"))
	var spd: float = Player.SPEED * (1.0 + meta_bonus("m_speed"))
	var mag: float = meta_bonus("m_magnet")
	var lck: float = meta_bonus("m_luck")
	var rgn: float = meta_bonus("m_regen")
	var gld: float = meta_bonus("m_gold")
	return [
		I18n.t("최대 체력       %d") % int(hp),
		I18n.t("공격력          %.0f") % dmg,
		I18n.t("이동속도        %.0f") % spd,
		I18n.t("자석 범위       +%d") % int(mag),
		I18n.t("행운            +%d%%") % int(round(lck * 100.0)),
		I18n.t("체력 재생       +%.1f/s") % rgn,
		I18n.t("골드 획득       +%d%%") % int(round(gld * 100.0)),
	]


## 상점 상단 등에 쓰는 압축 2줄 능력치 문자열.
func meta_stat_compact() -> String:
	var hp: float = Player.MAX_HP + meta_bonus("m_hp")
	var dmg: float = Player.BULLET_DMG * (1.0 + meta_bonus("m_dmg"))
	var spd: float = Player.SPEED * (1.0 + meta_bonus("m_speed"))
	var mag: int = int(meta_bonus("m_magnet"))
	var lck: int = int(round(meta_bonus("m_luck") * 100.0))
	var rgn: float = meta_bonus("m_regen")
	var gld: int = int(round(meta_bonus("m_gold") * 100.0))
	return I18n.t("체력 %d   ·   공격력 %.0f   ·   이동속도 %.0f\n행운 +%d%%   ·   자석 +%d   ·   재생 +%.1f/s   ·   골드 +%d%%") % [int(hp), dmg, spd, lck, mag, rgn, gld]


## 저장된 레벨. 상한이 줄어드는 개편이 와도 옛 세이브가 상한을 넘지 않게 잘라 읽는다.
func meta_level(id: String) -> int:
	var v: int = int(meta.get(id, 0))
	if META_TIERS.has(id):
		return clampi(v, 0, meta_max(id))
	return maxi(0, v)


# ──────────────────────── 영구 강화 수치 (한 곳에서만 정의) ────────────────────────
## ★ 예전엔 레벨당 수치가 player.apply_meta · meta_stat_lines · meta_stat_compact 세 군데에
##   같은 숫자로 흩어져 있었다. 한 곳만 고치면 상점 표기와 실제 효과가 조용히 어긋난다.
##   이제 아래 표가 유일한 정의이고 나머지는 전부 meta_bonus() 를 부른다.
##
## ★ 티어를 크게 늘리고 레벨당 수치를 잘게 쪼갰다(예: 체력 +15×12 → +6×30).
##   총량은 비슷하거나 조금 늘었지만, 한 번 지르는 맛이 30번으로 나뉘고 후반 한 칸에
##   수만 골드가 들어간다. 초반 가격은 예전보다 오히려 싸다(아래 cost 곡선 참고).
const META_TIERS: Dictionary = {
	"m_hp": {"max": 30, "per": 6.0, "base": 30},        # 최대 체력 +6 / Lv  (총 +180)
	"m_dmg": {"max": 30, "per": 0.03, "base": 40},      # 공격력 +3% / Lv   (총 +90%)
	"m_speed": {"max": 25, "per": 0.014, "base": 35},   # 이동속도 +1.4% / Lv (총 +35%)
	"m_magnet": {"max": 25, "per": 10.0, "base": 25},   # 자석 +10 / Lv     (총 +250)
	"m_luck": {"max": 20, "per": 0.02, "base": 70},     # 행운 +2% / Lv     (총 +40%)
	"m_regen": {"max": 20, "per": 0.12, "base": 50},    # 재생 +0.12/s / Lv (총 +2.4/s)
	"m_gold": {"max": 25, "per": 0.03, "base": 45},     # 골드 획득 +3% / Lv (총 +75%)
	"m_reroll": {"max": 8, "per": 1.0, "base": 55},     # 시작 리롤 +1 / Lv — 정수라 잘게 못 쪼갠다
	"m_banish": {"max": 4, "per": 1.0, "base": 120},    # 14차: 봉인 +1 / Lv (판 시작 1 + 이것)
}


func meta_max(id: String) -> int:
	return int((META_TIERS.get(id, {}) as Dictionary).get("max", 0))


func meta_per(id: String) -> float:
	return float((META_TIERS.get(id, {}) as Dictionary).get("per", 0.0))


## 해당 영구 강화의 현재 누적 보너스 (레벨 × 레벨당 수치).
func meta_bonus(id: String) -> float:
	return float(meta_level(id)) * meta_per(id)


## 영구 강화 한 칸의 가격.
## ★ 요구: 초반은 지금처럼 싸게, 후반은 한 칸에 수만 골드.
##   순수 거듭제곱(예전 base×(Lv+1)^1.7)은 초반이 상대적으로 비싸고 후반이 충분히 안 올랐다.
##   다항×지수 혼합이라 Lv1~5 는 오히려 예전보다 싸고, 20레벨을 넘어가면 만 단위로 붙는다.
##   (m_dmg base=40 기준) 예전 40/130/259/422 → 지금 40/100/180/280 … Lv20 8,900 · Lv30 37,600
func meta_cost(id: String, lvl: int) -> int:
	var base: float = float((META_TIERS.get(id, {}) as Dictionary).get("base", 40))
	var raw: float = base * pow(float(lvl + 1), 1.20) * pow(1.10, float(lvl))
	if raw < 1000.0:
		return int(round(raw / 5.0) * 5.0)      # 세 자리까지는 5원 단위
	return int(round(raw / 50.0) * 50.0)        # 그 위는 50원 단위 (가격표가 읽히게)


## 천단위 구분 — 수만 골드가 오가면 자릿수를 눈으로 못 센다.
static func gold_str(v: int) -> String:
	var neg: bool = v < 0
	var s: String = str(absi(v))
	var out: String = ""
	var c: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if neg else "") + out


# ──────────────────────── 액세서리 (장신구) ────────────────────────
## meta["acc_own_<id>"]=1 보유 / meta["acc_slot_<n>"]="<id>" 장착.
## 칸이 4개뿐이라 '무엇을 빼고 무엇을 낄까'가 매번 선택이 된다.
func acc_owned(id: String) -> bool:
	return int(meta.get("acc_own_" + id, 0)) > 0


func acc_buy(id: String) -> bool:
	var d: Dictionary = Accessories.def_of(id)
	if d.is_empty() or acc_owned(id):
		return false
	var c: int = int(d.get("gold", 0))
	if total_gold < c:
		return false
	total_gold -= c
	meta["acc_own_" + id] = 1
	save_game()
	return true


func acc_slot(n: int) -> String:
	return String(meta.get("acc_slot_%d" % n, ""))


## 장착. 이미 다른 칸에 낀 것이면 그 칸을 비워 중복 장착을 막는다.
func acc_equip(n: int, id: String) -> void:
	if id != "" and not acc_owned(id):
		return
	for i in Accessories.SLOTS:
		if i != n and acc_slot(i) == id and id != "":
			meta["acc_slot_%d" % i] = ""
	meta["acc_slot_%d" % clampi(n, 0, Accessories.SLOTS - 1)] = id
	save_game()


## 지금 장착 중인 액세서리 id 목록 (빈 칸 제외).
func acc_equipped() -> Array:
	var out: Array = []
	for i in Accessories.SLOTS:
		var id: String = acc_slot(i)
		# 중복은 acc_equip 이 막지만, 그 규칙이 생기기 전 세이브가 있으면 효과가 두 배로 붙는다
		if id != "" and acc_owned(id) and not out.has(id):
			out.append(id)
	return out


func acc_has(id: String) -> bool:
	return acc_equipped().has(id)


func acc_owned_count() -> int:
	var n: int = 0
	for d: Dictionary in Accessories.DEFS:
		if acc_owned(String(d["id"])):
			n += 1
	return n


# ---- 캐릭터 등급(강화): 골드로 캐릭터별 기본치 강화, 저장 지속
## ★ 5등급 5,034 G 로 끝나던 것을 20등급으로 쪼갰다. 등급당 수치는 절반 이하로 낮추고
##   (공격 +6%/등급 → +2.5%/등급) 후반 한 등급에 수만 골드가 들어가게 곡선을 세웠다.
##   특수 영웅(보라 프레임)은 체급이 큰 만큼 강화비도 1.35배다 — 예전엔 기본 캐릭터와 같았다.
const CHAR_RANK_MAX: int = 20

func char_rank(id: String) -> int:
	return clampi(int(meta.get("rank_" + id, 0)), 0, CHAR_RANK_MAX)


## 특수 영웅 여부 (characters.gd 의 "special": true)
func char_is_special(id: String) -> bool:
	return bool(Characters.def_of(id).get("special", false))


## ---- 영웅 차림(16차): 저승길 차림 20벌 — cast.json "skins" 의 "<영웅 id>@jeoseung" ----
## 저승길(스테이지 6)을 한 번 클리어하면 모든 영웅의 저승길 차림이 열린다. 고른 차림은 저장된다(meta "skin_<id>").
const SKINS: Array = ["jeoseung"]

func skin_unlocked(skin: String) -> bool:
	if skin == "":
		return true
	if skin == "jeoseung":
		for d in 4:
			if stage_cleared(5, d):
				return true
	return false


## 지금 입을 차림("" = 기본). 열리지 않았거나 그 영웅 차림 그림이 없으면 기본.
func hero_skin(id: String) -> String:
	var s: String = String(meta.get("skin_" + id, ""))
	if s == "" or not skin_unlocked(s) or not CharForge.has_skin(id, s):
		return ""
	return s


func set_hero_skin(id: String, skin: String) -> void:
	if skin == "":
		meta.erase("skin_" + id)
	else:
		meta["skin_" + id] = skin
	save_game()


func char_rank_cost(id: String) -> int:
	var r: int = char_rank(id)
	var mult: float = 1.35 if char_is_special(id) else 1.0
	var raw: float = 110.0 * mult * pow(float(r + 1), 1.15) * pow(1.13, float(r))
	if raw < 1000.0:
		return int(round(raw / 5.0) * 5.0)
	return int(round(raw / 50.0) * 50.0)


## 등급 보너스 — 한 곳에서만 정의(캐릭터 선택 화면 표기와 실효가 어긋나지 않게).
const RANK_DMG: float = 0.025    # 공격력 +2.5% / 등급 (20등급 = +50%)
const RANK_HP: float = 4.0       # 최대 체력 +4 / 등급 (= +80)
const RANK_SPD: float = 0.008    # 이동속도 +0.8% / 등급 (= +16%)
const RANK_ARMOR: float = 0.2    # 방어 +0.2 / 등급 (= +4)


func char_rank_up(id: String) -> bool:
	var r: int = char_rank(id)
	if r >= CHAR_RANK_MAX:
		return false
	var c: int = char_rank_cost(id)
	if total_gold < c:
		return false
	total_gold -= c
	meta["rank_" + id] = r + 1
	save_game()
	return true


## 난이도별 분당 골드 상한 (몹 무한 = 돈복사 방지). 30분 총합 ≈ cap×30.
## ★ 영구 강화를 30단계로 쪼개고 후반 한 칸을 수만 골드로 올렸으니, 수입도 같이 올려야
##   '가격만 오른 게임'이 되지 않는다. 상한 자체는 유지되므로 돈복사는 여전히 막힌다.
##   여기에 스테이지 배수(최대 ×3.2)와 골드 획득 강화(최대 +75%)가 곱해져서,
##   상위 콘텐츠를 뚫은 유저의 파밍 속도가 초반의 열 배 가까이 된다 — 그게 뚫을 이유가 된다.
func gold_per_min_cap() -> int:
	# ★ 예전 값(110/160/270/420)은 '지켜지기만 했다면' 맞는 숫자였다. 실제로는 아래
	#   gold_drop_room 설명대로 상한이 전혀 안 걸려서 실측 분당 5,000 이 나왔다.
	#   이제 상한이 진짜로 걸리므로, 그만큼 상한 자체를 현실적인 선까지 올려 둔다.
	return int(_dv([150.0, 240.0, 420.0, 680.0]))  # 쉬움/보통/어려움/매우어려움


## 이번 분 실효 골드 상한 (난이도 cap × 스테이지 배수 × 메타 m_gold 보정).
func _gold_cap() -> int:
	return int(float(gold_per_min_cap()) * stage_gold_mult() * gold_mult())


## 이번 분 예산을 '시간 비례'로 방출 → 5초 만에 다 채우던 것 방지, 1분에 걸쳐 고르게.
## 반환값(드랍 여유분)이 0이면 아직 시간-예산을 앞선 상태 → 드랍 확률 극감(_drop_gold).
func gold_room() -> int:
	var cap: int = _gold_cap()
	if int(time_alive / 60.0) != _gm_window:
		return cap  # 분이 바뀌면 곧 리셋 → 만액
	var sec_in: float = time_alive - float(_gm_window) * 60.0
	var allowed: int = int(float(cap) * clampf(sec_in / 58.0, 0.12, 1.0))  # 58초에 걸쳐 방출(초반 12%)
	return maxi(0, allowed - _gm_earned)


var _gm_dropped: int = 0  # 이번 분에 '바닥에 낸' 금액 — 수거 여부와 무관하게 예산을 소모한다
var gold_src: Dictionary = {}  # 수입 출처별 누적 (밸런스 하니스가 읽는다 — 어디서 새는지 눈으로 못 찾는다)

## 이번 분에 더 떨어뜨려도 되는 금액.
## ★ 예전엔 '주운 금액'으로만 예산을 세고, 초과해도 드랍 확률을 0.15배로 줄이기만 했다.
##   초당 80마리가 죽는 구간에서는 0.15배도 분당 수천 골드다 — 상한 110 이 실측 5,000 이 됐고
##   4분 플레이에 8,000 골드가 나왔다(실플레이 리포트). 이제 '낸 금액'을 세고 예산이
##   없으면 아예 안 낸다. 몹을 몇 마리 잡든 분당 수입이 설계값을 못 넘는다.
func gold_drop_room() -> int:
	_gold_window_tick()
	var sec_in: float = time_alive - float(_gm_window) * 60.0
	var allowed: int = int(float(_gold_cap()) * clampf(sec_in / 58.0, 0.12, 1.0))
	return maxi(0, allowed - _gm_dropped)


## 드랍 예산에서 실제로 낼 금액을 받아 온다 (모자라면 남은 만큼만, 없으면 0).
## 분이 바뀌면 이번 분 카운터를 한꺼번에 리셋한다 (수입/드랍 어느 쪽에서 먼저 불려도 동일).
func _gold_window_tick() -> void:
	var w: int = int(time_alive / 60.0)
	if w != _gm_window:
		_gm_window = w
		_gm_earned = 0
		_gm_dropped = 0


func gold_take(n: int) -> int:
	var give: int = mini(maxi(0, n), gold_drop_room())
	_gm_dropped += give
	return give


## 보스·융합보스·특수 개체의 처치 보상 — '이벤트'라 예산이 말랐어도 최소한은 낸다.
## 대신 낸 만큼 예산에서 빼므로 뒤이은 잡몹 드랍이 그만큼 줄어든다(총량은 지켜진다).
func gold_event(n: int) -> int:
	var want: int = maxi(0, n)
	var got: int = gold_take(want)          # 예산에서 낼 수 있는 만큼 먼저
	var floor_g: int = int(float(want) * 0.34)
	if got < floor_g:                        # 모자라면 최소보장분까지 채우고, 그만큼 예산을 더 태운다
		_gm_dropped += floor_g - got
		got = floor_g
	return got


## [감사 C30] 보너스성 지급(콤보/노다지 카드 등) — 분당 드랍 예산(_gm_earned)을 잠식하지 않음.
## 예산은 '몹 드랍 공급' 조절용이므로, 보너스가 예산을 먹으면 잘 싸운 직후 드랍이 마르는 역보상이 생김.
func add_gold_bonus(n: int) -> int:
	var give: int = int(round(float(maxi(0, n)) * gold_mult()))
	run_gold += give
	gold_src["보너스(콤보/카드/클리어)"] = int(gold_src.get("보너스(콤보/카드/클리어)", 0)) + give
	return give


## 골드 획득 총배수 — 영구 강화(m_gold) × 장신구(복주머니).
## 한 곳에 모아 둬야 '설명에는 +12% 인데 어디서도 안 곱해지는' 사고가 안 난다.
func gold_mult() -> float:
	var m: float = 1.0 + meta_bonus("m_gold")
	if player != null and is_instance_valid(player):
		m *= float((player as Player).acc_gold_mult)
	return m


var enemy_soft_cap: int = 9999  # [감사 C13] 현재 몹 상한 (main이 매 틱 갱신) — 소환/분열도 이 캡을 지킴

## ★ 분열·소환은 물리 콜백에서 불리고 실제 투입은 call_deferred 라 프레임 끝으로 밀린다.
##   그래서 한 프레임에 슬라임 N마리가 동시에 죽으면 N개 호출이 전부 '같은 스냅샷'을 보고
##   각자 통과해 2N마리를 예약했다 — 프레임 키를 어떻게 바꿔도 안 잡히는 종류의 초과다.
##   예약분을 따로 세어 그 프레임 안에서 즉시 반영한다.
var _spawn_reserved: int = 0
var _reserve_frame: int = -1

func reserve_spawn(n: int) -> bool:
	var f: int = Engine.get_physics_frames()
	if f != _reserve_frame:
		_reserve_frame = f
		_spawn_reserved = 0
	if enemies_cached().size() + _spawn_reserved + n > enemy_soft_cap:
		return false
	_spawn_reserved += n
	return true


# ──────────────────── 반복 퀘스트 (S5): 일일/주간/월간 · 달성 후 '받기' 수령 ────────────────────
var quests: Dictionary = {}  # id -> {"p": 진행, "c": 수령됨, "k": 기간키} — 기간키가 바뀌면 자동 리셋


func _q_key(period: String) -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	match period:
		"weekly":
			# 10/13 QA C6: 예전엔 UTC 기준 주(목요일 0시 UTC = 한국 목요일 오전 9시)라 일간 · 월간(기기 날짜)과 따로 놀았다.
			#   기기 시간대로 월요일 0시에 바뀐다. 1970-01-01 은 목요일이라 +3 하면 월요일 시작.
			var bias_s: float = float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0
			var local_day: int = int(floor((Time.get_unix_time_from_system() + bias_s) / 86400.0))
			return "wk%d" % int(floor(float(local_day + 3) / 7.0))
		"monthly":
			return "%04d-%02d" % [int(d["year"]), int(d["month"])]
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


## 퀘스트 상태 조회 (기간 경과 시 자동 리셋)
func quest_entry(qd: Dictionary) -> Dictionary:
	var id: String = String(qd["id"])
	var key: String = _q_key(String(qd["period"]))
	var e: Dictionary = quests.get(id, {})
	# 옛 주간 키(「w」 + UTC 주 번호)가 지금 UTC 주와 같으면 이번 주 진행으로 이어 준다 — 바꾼 날 진행이 날아가지 않게
	var old_wk: String = "w%d" % int(Time.get_unix_time_from_system() / 604800.0)
	if String(qd["period"]) == "weekly" and String(e.get("k", "")) == old_wk:
		e["k"] = key
	if String(e.get("k", "")) != key:
		e = {"p": 0, "c": false, "k": key}
		quests[id] = e
	return e


## 퀘스트 진행 훅 — 처치/보스/특수/판수/클리어 지점에서 호출
func quest_add(stat: String, n: int) -> void:
	for qd: Dictionary in Codex.QUESTS:
		if String(qd["stat"]) != stat:
			continue
		var e: Dictionary = quest_entry(qd)
		if not bool(e["c"]):
			e["p"] = mini(int(qd["need"]), int(e["p"]) + n)


func quest_claimable(qd: Dictionary) -> bool:
	var e: Dictionary = quest_entry(qd)
	return not bool(e["c"]) and int(e["p"]) >= int(qd["need"])


## 받을 수 있는 보상 수 — 메인 메뉴/탭 배지용
func quest_claimable_count() -> int:
	var n: int = 0
	for qd: Dictionary in Codex.QUESTS:
		if quest_claimable(qd):
			n += 1
	return n


## 보상 수령 → 골드 지급 (메뉴 맥락: total_gold 직행)
func quest_claim(id: String) -> int:
	for qd: Dictionary in Codex.QUESTS:
		if String(qd["id"]) != id:
			continue
		if not quest_claimable(qd):
			return 0
		var e: Dictionary = quest_entry(qd)
		e["c"] = true
		var gold: int = int(qd["gold"])
		total_gold += gold
		save_game()
		return gold
	return 0


## 주운 골드는 '항상' 전액 적립 — 상한은 공급(드랍 확률)에서만 조절(_drop_gold).
## _gm_earned는 예산 추적용으로만 누적(gold_room이 드랍 억제 판단에 사용).
func add_gold(n: int) -> int:
	_gold_window_tick()
	# 메타 '골드 획득'과 장신구(복주머니)는 적립액에 직접 곱적용 (예전엔 분당 예산 상한만 올려 체감 0이었음 — M36 감사)
	var give: int = int(round(float(maxi(0, n)) * gold_mult()))
	_gm_earned += give
	run_gold += give
	gold_src["금화 줍기"] = int(gold_src.get("금화 줍기", 0)) + give
	return give


## main이 부팅 시 호출 — 기기별 성능 상한 설정 (탄환 캡 하향).
func detect_mobile(m: bool) -> void:
	mobile = m
	_bullet_cap = 110 if m else 220  # 신칼/부채/메아리로 발사량이 급증 — 예전 상한이면 연사·멀티샷 카드 값이 0 이 된다
	apply_perf()  # mobile 이 정해진 뒤라야 자동(-1) 프레임 상한이 제대로 잡힌다


## 현재 동시 탄환 상한 — player._fire_ranged가 초과 시 이번 발사 스킵.
func bullet_cap() -> int:
	if perf_level() == 0:
		return int(float(_bullet_cap) * 0.7)
	return _bullet_cap


## 적 탄환 상한 — 예전엔 상한 자체가 없어 슈터가 많은 테마에서 수백 발이 상주했다.
## ★ 2026-09-06: 데스크톱 160 은 성능 상한으로 잡은 수인데, 실제로는 **난이도 상한**으로
##   작동하고 있었다. 1스테이지 보통 80초에 이미 127~159발이 떠 있다 — 즉 포화다.
##   피할 수 있는 탄막이어야 실력이 개입한다. 상한이 곧 벽이면 그건 난이도가 아니라 사고다.
##   난이도별로 나눈다: 쉬움 64 · 보통 84 · 어려움 110 · 매우어려움 140.
func enemy_bullet_cap() -> int:
	if mobile:
		return 48 if perf_level() == 0 else 72
	return int(_dv([64.0, 84.0, 110.0, 140.0]))


## 원거리 몹의 발사 — **판 전체** 예산. 초당 이 횟수까지만 발사가 일어난다.
## 사수 하나하나는 1.5~2.1초마다 쏘는데, 몹이 90마리면 그중 3분의 1이 사수라
## 초당 15발이 나간다. 개별 몹은 안 바뀌었는데 군중이 커지면서 탄막이 벽이 됐다.
## 회복(heal_budget)·원소반응(react_budget)이 쓰는 같은 방식으로 묶는다.
var _shot_window: int = -1
var _shot_count: int = 0


func shot_budget() -> bool:
	var w: int = int(time_alive)
	if w != _shot_window:
		_shot_window = w
		_shot_count = 0
	if float(_shot_count) >= _dv([4.0, 6.0, 9.0, 12.0]):
		return false
	_shot_count += 1
	return true


## 데미지 숫자 동시 표시 상한 (모바일·절전에서 하향).
## ──────────── 19차 3절 1: 영웅 둘레에서 내 무기 이펙트 흐리게 ────────────
## 후반(12분 · 몹 200)에 불꽃 오라 · 베기 · 탄이 영웅을 덮어서 「내가 어디 있나」가 안 보였다(19차 보고 7절).
## 내 이펙트(무기 · 탄 · 베기 · 폭발)에 재질 하나를 같이 씌우고, 영웅에서 FX_NEAR_R 안의 픽셀만 FX_NEAR_A 로 그린다.
## 적 탄 · 몹 · 피해 숫자는 건드리지 않는다. 영웅 위치는 main 이 프레임마다 넣는다(set_fx_near).
## 반경은 전투 그림 픽셀(영웅과 같은 ×1) 48 — 지시서 「48px」. 화면 1080 에서는 카메라 배율만큼 커진다.
const FX_NEAR_R: float = 48.0
const FX_NEAR_A: float = 0.6
var fx_near_mat: ShaderMaterial = null

const _FX_NEAR_SHADER: String = """
shader_type canvas_item;
uniform vec2 hero_world = vec2(0.0, 0.0);
uniform float radius_world = 48.0;
uniform float near_alpha = 0.6;
varying vec2 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	float d = distance(wpos, hero_world);
	float k = smoothstep(radius_world * 0.8, radius_world, d);
	COLOR.a *= mix(near_alpha, 1.0, k);
}
"""


func _fx_near_material() -> ShaderMaterial:
	if fx_near_mat == null:
		var sh := Shader.new()
		sh.code = _FX_NEAR_SHADER
		fx_near_mat = ShaderMaterial.new()
		fx_near_mat.shader = sh
		fx_near_mat.set_shader_parameter("radius_world", FX_NEAR_R)
		fx_near_mat.set_shader_parameter("near_alpha", FX_NEAR_A if fx_dim_on else 1.0)
	return fx_near_mat


## 내 이펙트라고 표시한다 — 그 노드와 지금 있는 자식들(재질이 없는 것만)에 흐림 재질. 나중에 붙는 바로 아래 자식도.
func mine(n: Node) -> void:
	if n == null or not is_instance_valid(n):
		return
	_apply_mine(n, _fx_near_material())
	if not n.child_entered_tree.is_connected(_on_mine_child):
		n.child_entered_tree.connect(_on_mine_child)


func _apply_mine(n: Node, m: ShaderMaterial) -> void:
	if n is CanvasItem and (n as CanvasItem).material == null:
		(n as CanvasItem).material = m
	for c in n.get_children():
		_apply_mine(c, m)


func _on_mine_child(c: Node) -> void:
	_apply_mine(c, _fx_near_material())


## main 이 프레임마다 — 영웅 몸 가운데(세계 좌표)와 켬/끔.
func set_fx_near(hero_world: Vector2) -> void:
	var m: ShaderMaterial = _fx_near_material()
	m.set_shader_parameter("hero_world", hero_world)
	m.set_shader_parameter("near_alpha", FX_NEAR_A if fx_dim_on else 1.0)


func dmgnum_cap() -> int:
	if mobile:
		return 22 if perf_level() == 0 else 34
	# ★ 2026-09-15: 55 → 34. 치명타는 상한의 1.4배까지 허용되므로 실제로는 최대 77개가
	#   동시에 떠 있었다. 후반 치명타율이 70~100% 라 사실상 화면이 숫자로 덮인다.
	return 26 if perf_level() == 0 else 34  # 데스크톱에서 절전을 골라도 줄어들게


## 물리프레임당 1회만 적 그룹을 조회해 공유 (탄환 수백 개가 각자 스캔+배열할당하던 것 제거).
## 반환 배열의 원소는 죽었을 수 있으니 사용처에서 is_instance_valid 확인 필수(기존 코드 이미 그러함).
var _enemy_cache: Array = []
var _enemy_cache_frame: int = -1
func enemies_cached() -> Array:
	var f: int = Engine.get_physics_frames()
	if f != _enemy_cache_frame:
		_enemy_cache_frame = f
		_enemy_cache = get_tree().get_nodes_in_group("enemy")
	return _enemy_cache


## ──────────────── 몹 분리용 공간 격자 ────────────────
## 몹은 서로 충돌하지 않는다(collision_mask=8, 지형만). 그래서 속도가 같은 개체들이
## 플레이어라는 한 점을 향하면 **완전히 포개져** 한 마리처럼 보인다(실플레이 리포트).
## 물리로 밀면 400마리 상호충돌이라 감당이 안 되고, 벽처럼 굳어 카이팅이 죽는다.
## 대신 이웃만 훑어 살짝 밀어내는 조향력을 준다 — 겹침만 풀리고 추격은 그대로다.
##
## 전수 비교는 400² = 16만 회라 못 쓴다. 격자에 한 번 담아 두고 제 칸 + 이웃 8칸만 본다
## (칸당 두세 마리라 개체당 20~30회). 격자는 물리프레임당 한 번만 짓는다.
const SEP_CELL: float = 46.0
const SEP_OFF: Array = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
var _sep_cells: Dictionary = {}
var _sep_frame: int = -1

static func sep_key(cx: int, cy: int) -> int:
	return (cx + 4096) * 8192 + (cy + 4096)


func sep_grid() -> Dictionary:
	var f: int = Engine.get_physics_frames()
	if f == _sep_frame:
		return _sep_cells
	_sep_frame = f
	_sep_cells = {}
	for e in enemies_cached():
		if not is_instance_valid(e):
			continue
		var n2 := e as Node2D
		if n2 == null:
			continue
		var p: Vector2 = n2.global_position
		var k: int = sep_key(int(floor(p.x / SEP_CELL)), int(floor(p.y / SEP_CELL)))
		if _sep_cells.has(k):
			(_sep_cells[k] as Array).append(e)
		else:
			_sep_cells[k] = [e]
	return _sep_cells


## 이번 물리프레임에 임팩트 이펙트를 하나 더 그려도 되는지. 초과 시 false(프레임 스파이크 방지).
## ★ 예산 14는 데스크톱 기준이었고 모바일 하향이 없었다 — FX 1개가 노드 2개 + 트윈 2개라
##   예산을 꽉 채우면 초당 1,680개가 생성/소멸한다. 기기·성능설정에 맞춰 줄인다.
func fx_budget() -> bool:
	var f: int = Engine.get_physics_frames()
	if f != _fx_frame:
		_fx_frame = f
		_fx_count = 0
	if _fx_count >= int(float(FX_BUDGET) * fx_scale()):
		return false
	_fx_count += 1
	return true


var wfx_legacy: bool = false   # 검사(--crowdshot=…:old) 전용: 예전처럼 임팩트 예산을 같이 쓴다

## 무기 몸통 그림 예산 — 임팩트 예산(fx_budget)과 별개. 절전에서도 반은 남긴다.
func fx_weapon_budget() -> bool:
	if wfx_legacy:
		return fx_budget()
	var f: int = Engine.get_physics_frames()
	if f != _wfx_frame:
		_wfx_frame = f
		_wfx_count = 0
	if _wfx_count >= maxi(5, int(float(WFX_BUDGET) * fx_scale())):
		return false
	_wfx_count += 1
	return true


func bank_run_gold() -> void:
	total_gold += run_gold
	run_gold = 0
	pend_gold = 0
	save_game()


## 10/13 QA B12: 폰에서 앱을 내려놓은 채(전화 · 광고 · 다른 앱) 시스템이 메모리 때문에 꺼 버리면
## 판 골드는 결과 화면에서만 적립돼서 통째로 사라졌다. 내려놓을 때 「아직 적립 안 한 판 골드」를
## 세이브에 따로 적어 두고, 돌아오면 지운다. 못 돌아오고 꺼졌으면 다음에 켤 때 더해 준다(_load_save).
var pend_gold: int = 0


func park_run_gold() -> void:
	if run_gold <= 0 or no_save:
		return
	pend_gold = run_gold
	save_game()


func unpark_run_gold() -> void:
	if pend_gold <= 0:
		return
	pend_gold = 0
	save_game()


func _load_sfx() -> void:
	for n: String in ["shoot", "hit", "kill", "pickup", "levelup", "hurt", "dash"]:
		var path: String = "res://assets/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			_sfx[n] = load(path)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)


## 짧은 효과음 재생 (풀 순환). 표시 전용 아님 — 실제 소리는 사용자가 들어야 판정 가능.
func sfx(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not _sfx.has(name) or _sfx_players.is_empty():
		return
	var p := _sfx_players[_sfx_idx] as AudioStreamPlayer
	_sfx_idx = (_sfx_idx + 1) % _sfx_players.size()
	p.stream = _sfx[name]
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


func _process(delta: float) -> void:
	if running:
		time_alive += delta
		if combo > 0:  # 콤보 창 경과 → 리셋
			combo_t -= delta
			if combo_t <= 0.0:
				combo = 0
				combo_changed.emit()


func _setup_input() -> void:
	var defs: Dictionary = {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"dash": [KEY_SPACE, KEY_SHIFT],
		"pause": [KEY_ESCAPE, KEY_TAB],
	}
	for action: String in defs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for kc: int in (defs[action] as Array):
			var ev := InputEventKey.new()
			ev.physical_keycode = kc
			InputMap.action_add_event(action, ev)
	# 11/5 스팀 피드백 8: 엔진 기본 「누르기(ui_accept)」에 Space 가 들어 있는데 Space 는 대시다 — 레벨업 카드가 뜬 직후
	#   싸우던 손으로 누른 대시가 포커스된 카드를 골랐다. 키보드 누르기는 Enter 만 남긴다(클릭 · 숫자 1~4 는 그대로).
	if InputMap.has_action("ui_accept"):
		for e: InputEvent in InputMap.action_get_events("ui_accept"):
			if e is InputEventKey and ((e as InputEventKey).keycode == KEY_SPACE or (e as InputEventKey).physical_keycode == KEY_SPACE):
				InputMap.action_erase_event("ui_accept", e)
	_setup_gamepad()


## 게임패드 — 스팀 출시 대응. 스팀 이용자 상당수가 패드를 쓰고,
## 스팀덱은 애초에 키보드가 없다(= 패드가 없으면 게임이 아예 조작 불가).
##
## ★ 왼쪽 스틱은 InputEventJoypadMotion 을 축의 '부호별로' 하나씩 걸어야 한다.
##   축 하나에 이벤트 하나만 걸면 한쪽 방향만 먹는다.
##   axis_value 는 방향(부호)만 의미가 있고 크기는 런타임 입력값이 채운다 —
##   Input.get_vector() 가 이걸 읽어서 아날로그 강도까지 그대로 살린다.
func _setup_gamepad() -> void:
	# 왼쪽 스틱 (아날로그 — 살살 밀면 살살 걷는다)
	var axes: Dictionary = {
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0],
		"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action: String in axes:
		var a: Array = axes[action]
		var ev := InputEventJoypadMotion.new()
		ev.axis = int(a[0])
		ev.axis_value = float(a[1])
		InputMap.action_add_event(action, ev)

	# 방향키(D-패드) — 스틱을 안 쓰는 사람도 있다
	var btns: Dictionary = {
		"move_left": [JOY_BUTTON_DPAD_LEFT],
		"move_right": [JOY_BUTTON_DPAD_RIGHT],
		"move_up": [JOY_BUTTON_DPAD_UP],
		"move_down": [JOY_BUTTON_DPAD_DOWN],
		# 대시는 A(아래 버튼)와 오른쪽 범퍼 둘 다 — 엄지를 스틱에서 떼기 싫은 사람용
		"dash": [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER],
		# 일시정지는 스타트. 스팀덱에서도 같은 자리다
		"pause": [JOY_BUTTON_START],
	}
	for action: String in btns:
		for bc: int in (btns[action] as Array):
			var ev := InputEventJoypadButton.new()
			ev.button_index = bc
			InputMap.action_add_event(action, ev)

	# 스틱 중립에서 손을 떼도 캐릭터가 흐르지 않게 — 기본 0.5 는 너무 둔하다
	for action: String in axes:
		InputMap.action_set_deadzone(action, 0.2)

	# ★ 16차 4-5: 엔진 기본 키맵은 ui_* 방향에만 패드가 걸려 있고 누르기 · 뒤로에는 없다 —
	#   D-패드로 버튼까지 가 놓고 A 를 눌러도 아무 일이 없었다(--padcheck 에서 엔터는 되고 A 는 안 됐다).
	#   A = 누르기(ui_accept) · B = 뒤로(ui_cancel). 스팀덱도 같은 자리다.
	for pair: Array in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var jev := InputEventJoypadButton.new()
		jev.button_index = int(pair[1])
		if not InputMap.action_has_event(String(pair[0]), jev):
			InputMap.action_add_event(String(pair[0]), jev)


## 융합 보스를 놓쳤을 때의 이번 런 한정 페널티 (플레이어 공격력 감소). 새 게임 시 0.
var run_penalty: float = 0.0

## 맵(스테이지) 특화 규칙 — _cycle_theme에서 설정, 적/드랍이 읽음.
var stage: int = 0                # 현재 테마 인덱스(0~5, 5 = 저승길)
var stage_enemy_hp: float = 1.0   # 맵별 적 체력 배수
var stage_enemy_spd: float = 1.0  # 맵별 적 이동 배수
var stage_xp_mult: float = 1.0    # 맵별 처치 XP 배수

func reset_run() -> void:
	_run_meta_power = -1.0
	run_dmg = {}
	revive_used = 0
	time_alive = 0.0
	kills = 0
	level = 1
	xp = 0
	xp_to_next = 5
	wave = 1
	run_gold = 0
	gold_src = {}
	_gm_window = -1
	_gm_earned = 0
	_gm_dropped = 0
	run_penalty = 0.0
	stage = 0
	stage_enemy_hp = 1.0
	stage_enemy_spd = 1.0
	stage_xp_mult = 1.0
	combo = 0
	combo_t = 0.0
	combo_best = 0
	boss_fight_t = 0.0
	hits_taken = 0
	dmg_recv = 0.0
	last_hit_src = "-"
	boss_hits = 0
	no_hit_boss = true
	run_fusions = 0
	# [감사 C1/C2] 승리 화면의 freeze_enemies(3600)가 다음 런까지 새던 게임파괴 버그 — 새 런마다 완전 해제
	_freeze_until = 0
	_magnet_until = 0
	_drop_next.clear()
	_slowmo_scale = 1.0
	Engine.time_scale = harness_speed
	running = true


func add_kill(kind: int = -1) -> void:
	if not running:
		return  # 종료 후 잔존 처치는 집계 안 함 (S4)
	kills += 1
	if kind >= 0:
		stat_add("mk_%d" % kind, 1)   # 14차: 도감 몬스터 상세의 「처치 수」
	stat_add("total_kills", 1)
	quest_add("kills", 1)
	# 킬 콤보: 짧은 간격 연속 처치 → 카운터 상승 (사운드 피치/HUD 팝은 사용처에서)
	combo += 1
	combo_t = COMBO_WINDOW
	if combo > combo_best:
		combo_best = combo
	combo_changed.emit()


## 콤보에 따라 킬 사운드 피치 상승 (중독적 연쇄감)
func kill_pitch() -> float:
	return randf_range(0.9, 1.05) + minf(0.5, float(combo) * 0.012)


## 줍기 연타 피치 상승 — 0.6초 안에 이어 주우면 점점 높은 소리 (진공 청소 쾌감)
func pickup_pitch() -> float:
	var now: int = Time.get_ticks_msec()
	if now - _pickup_last_ms > 600:
		_pickup_streak = 0
	_pickup_last_ms = now
	_pickup_streak += 1
	return minf(1.7, 0.95 + 0.045 * float(_pickup_streak))


func add_xp(n: int) -> void:
	if not running:
		return  # 런 종료 후(승리/사망) 잔존 처치로 레벨업 모달이 뜨는 것 차단 (S4)
	if player != null and is_instance_valid(player):
		var xm: Variant = player.get("xp_mult")
		if xm != null:
			n = int(ceil(float(n) * float(xm)))
	xp += n
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		# 2차 곡선 — 고레벨일수록 급격히 비싸짐(강빌드도 3분에 170렙 같은 폭주 차단).
		# 강빌드 기준 30분≈100~120렙 목표. 실플레이 '30분에 레벨 X' 받으면 계수(0.85) 미세조정.
		xp_to_next = 12 + int(level * level * 0.85)
		leveled_up.emit()
		sfx("levelup")
		hitstop(0.07)
		add_shake(0.45)
	xp_changed.emit()


## 히트스톱 — 실시간 타이머(ignore_time_scale)로 잠깐 얼렸다 복원. 중첩 안전.
## 연출용 지속 슬로모션. 히트스톱이 끝날 때 1.0 이 아니라 이 값으로 되돌아간다
## (승리 연출 중에 히트스톱이 겹치면 슬로모션이 통째로 풀리던 것 방지).
var _slowmo_scale: float = 1.0
## 검사 하니스(--botrun · --balance --fast)만 쓰는 배속. 게임에서는 늘 1.0 — 히트스톱 · 슬로모션이 끝날 때 이 배속으로 돌아간다
##   (예전엔 1.0 으로 돌아가서 첫 히트스톱 뒤로는 --fast 가 풀려 있었다: 496초 판이 508초 걸림).
var harness_speed: float = 1.0
var reaper_t0: float = 0.0   # 무한 최종 보스(사신)가 처음 나온 시각 — 사신들은 여기서부터 분마다 세진다(Enemy._reaper_sync)
var harness_final_hp: float = 0.0   # --botrun --finalhp=N: 무한 최종 보스 체력을 N 으로(안 죽게 두고 화력을 잰다)
var harness_nodmg: bool = false   # --botrun --nodmg: 받은 피해를 세기만 한다(player.take_damage)
var harness_oldchain: bool = false   # --dmgshare --oldchain: 11/14 고치기 전 연쇄 식(앞뒤 비교용)
var deploy_ms: int = 0      # 16차 4-3: 출격을 누른 시각(씬을 다시 불러도 남게 G 에)
var boot_menu_ms: int = 0

func set_slowmo(scale: float) -> void:
	_slowmo_scale = clampf(scale, 0.05, 1.0)
	if _hitstop_count <= 0:
		Engine.time_scale = _slowmo_scale * harness_speed


func hitstop(duration: float) -> void:
	_hitstop_count += 1
	Engine.time_scale = 0.04
	var t: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	await t.timeout
	_hitstop_count -= 1
	if _hitstop_count <= 0:
		_hitstop_count = 0
		Engine.time_scale = _slowmo_scale * harness_speed


func add_shake(amount: float) -> void:
	if not shake_on:
		return
	if camera != null and is_instance_valid(camera) and camera.has_method("add_trauma"):
		camera.call("add_trauma", amount)


# ---- 빙결 / 자석 / 난이도 (드랍·스케일용)
var _freeze_until: int = 0
var _magnet_until: int = 0
var _sfx_cd: Dictionary = {}

const DIFF_NAMES: Array = ["쉬움", "보통", "어려움", "매우어려움", "지옥"]
# 난이도 설명 — 설정/캐릭터 선택 공용 (M37+). S1: 티어 간 격차·보상 대폭 확대.
const DIFF_DESC: Array = [
	"적 약함 · 느린 스폰 · 탄막 늦게 · 골드 -30%",
	"표준 밸런스",
	"적 HP 1.7배 · 잦은 스폰 · 탄막 빠름 · 정예 특성 하나 · 회복 -15% · 골드 +70%",
	"HP 2.6배·공격 2.3배 · 24초부터 탄막 · 정예 특성 둘 · 회복 -30% · 골드 +160%",
	"HP 3.6배 · 공격 3배 · 정예 특성 둘에 더 자주 · 회복 -45% · 골드 +260%",
]
## 가장 높은 난이도 번호. 11/7 「지옥」(4)을 더했다 — 매우어려움으로 깬 스테이지부터 열린다(stage_unlocked 규칙 그대로).
const DIFF_MAX: int = 4
var difficulty: int = 1  # 0 쉬움 ~ 4 지옥 — 지금 판(또는 다음 판)에 쓰는 값
## 11/5 스팀 피드백 1: 설정에서 「매우어려움」으로 바꾸고 한 판 하고 나오면 「쉬움」이 돼 있었다.
##   출격 창이 처음엔 스테이지 탭으로 열리고, 그 스테이지에서 아직 안 열린 단계면 난이도를 내리는데,
##   그 내린 값을 출격할 때 그대로 저장해서 설정이 덮였다. 이제 저장하는 건 이 값(사용자가 고른 난이도)뿐이고,
##   잠겨서 내린 값은 그 판에만 쓴다.
var diff_pref: int = 1


## 짧은 시간 안에 같은 소리 폭주 방지 (히트음 스팸 차단)
func sfx_throttled(name: String, pitch: float = 1.0, vol_db: float = 0.0, gap: float = 0.045) -> void:
	var now: int = Time.get_ticks_msec()
	if now < int(_sfx_cd.get(name, 0)):
		return
	_sfx_cd[name] = now + int(gap * 1000.0)
	sfx(name, pitch, vol_db)


## 난이도별 값 표에서 지금 난이도 값. 표가 짧으면(지옥 칸이 없으면) 마지막 칸을 쓴다.
func _dv(arr: Array) -> float:
	return float(arr[clampi(difficulty, 0, arr.size() - 1)])


func diff_spawn_mult() -> float:
	# ★ 2026-09-06: 쉬움→보통 한 칸이 너무 크다. 체력 ×0.65→×1.0, 피해 ×0.5→×1.0,
	#   스폰 ×1.6→×1.0, 슈터 80초→45초 — 넷이 한꺼번에 뛰어서 실질 3배 가까이 된다.
	#   두 번째 칸이 "표준 밸런스"라고 적혀 있는데 표준이 아니었다. 보통만 가운데로 옮긴다.
	#   쉬움·어려움·매우어려움은 그대로 둬서 사다리 폭은 유지한다.
	return _dv([1.4, 1.05, 0.72, 0.5, 0.44])  # 스폰 간격 배수 (클수록 느림) — 2026-10-06 쉬움·보통 조금 빽빽하게


func diff_hp_mult() -> float:
	# ★ 처음엔 0.85 까지 내렸다가 0.92 로 되돌렸다. 봇이 난이도와 무관하게 200초대에서
	#   막혀(카이팅 한계) 그 위로는 측정이 난이도를 구분하지 못한다 — 계기 해상도를 넘는
	#   조정은 근거가 없다. 아래 넷(적탄 상한·발사 예산·군중 곡선·체력 곡선)이 구조적
	#   불공정을 이미 걷어냈으니, 난이도 다이얼은 절반만 움직인다.
	return _dv([0.8, 1.0, 1.7, 2.6, 3.6])  # 2026-10-06 쉬움·보통 상향(강화 갖춘 플레이어 기준)


func diff_dmg_mult() -> float:
	# 실측에서 죽는 이유가 늘 몸박·적탄이었다 — 몹 체력이 아니라 **받는 피해**가 벽이다.
	return _dv([0.65, 0.95, 1.55, 2.3, 3.0])  # 2026-10-06 쉬움·보통 상향


func diff_shooter_start() -> float:
	# ★ 80/55/25/8 이었다. 칸 사이 배수가 ×1.45 · ×2.20 · ×3.13 으로 **혼자 가속**하는
	#   유일한 다이얼이었다(--diffcheck). 슈터는 죽는 이유 1순위라 이 가속이 그대로
	#   난이도 절벽이 된다. 배수를 ×1.45 · ×1.62 · ×1.89 로 펴서 사다리를 고르게 만든다.
	#   쉬움·보통은 손대지 않는다 — 보통은 2026-09-06 에 이미 실측으로 맞춰 놨다.
	# ★ 2026-09-15: 보통 55 → 75. --balance 세 시드가 **전부 적탄에 죽었고**(126초 Lv16 /
	#   147초 Lv18 / 210초 Lv21) 죽은 자리가 레벨 15~20 구간에 그대로 몰렸다.
	#   55초면 레벨 9~10 이라 아직 무기가 한 정뿐인데 탄막이 시작된다 — 빌드가 서기 전에
	#   회피 난이도부터 올라간다. 슈터를 레벨 12~13 쯤으로 밀어 순서를 바로잡는다.
	#   어려움 둘도 같은 비율로 밀되 사다리 폭(×1.45·×1.62·×1.89)은 유지한다.
	#   쉬움도 같이 민다 — 80 으로 두면 보통(75)과 붙어 버려 칸 구분이 사라진다.
	return _dv([100.0, 75.0, 46.0, 24.0, 15.0])  # 탄막 슈터 등장 시작 시간


func diff_boss_first() -> float:
	return _dv([100.0, 65.0, 45.0, 28.0, 20.0])


## 난이도별 골드 배수 (어려울수록 훨씬 많이 번다 — S1: 1.4/1.8 → 1.7/2.6)
func diff_gold_mult() -> float:
	return _dv([0.7, 1.0, 1.7, 2.6, 3.6]) * karma_gold_mult()


# ──────────────────── 11/7 난이도 2차: 상한 뒤 강해짐 · 회복 견제 · 아이템 간격 · 정예 특성 ────────────────────
## 스팀 플레이 보고(11/7): 「사기 조합 · 사기 융합을 모으면 체력 관리나 흡혈만 잘 해도 너무 쉽다, 시시하다」,
##   「자석이랑 멈추는 게 너무 잘 떠서 쉽다」. 사용자 결정(11/7): 상한 뒤에도 계속 강해짐 · 정예 특성 · 회복 견제 ·
##   무한 패턴 이벤트 · 아이템 빈도 조정 · 새 난이도 「지옥」 · 업보 단계.

## 압력이 난이도 상한(PRESS_MAX_*)을 넘어선 초. 예전엔 상한에서 멈추고 「그 뒤엔 플레이어만 강해진다」였다.
## 레벨이 상한보다 빨리 크는 판(사기 조합)일수록 크고, 무한은 시간이 흐르는 만큼도 큰다.
func overtime_sec() -> float:
	if press_time_only:
		return 0.0
	var stage: bool = run_mode == "stage"
	var cap: float = _dv(PRESS_MAX_STAGE if stage else PRESS_MAX_ENDLESS)
	var over: float = maxf(0.0, level_to_time(LEVEL_T_STAGE if stage else LEVEL_T_ENDLESS, level) - cap)
	if not stage:
		over = maxf(over, time_alive - cap)
	return over


## 상한을 넘은 1분마다 몹 체력 · 공격력이 오르는 몫(쉬움 · 보통 · 어려움 · 매우어려움 · 지옥).
const OVER_HP_PER_MIN: Array = [0.04, 0.08, 0.12, 0.16, 0.24]
const OVER_DMG_PER_MIN: Array = [0.02, 0.05, 0.08, 0.11, 0.16]


func overtime_hp_mult() -> float:
	return 1.0 + overtime_sec() / 60.0 * _dv(OVER_HP_PER_MIN)


func overtime_dmg_mult() -> float:
	return 1.0 + overtime_sec() / 60.0 * _dv(OVER_DMG_PER_MIN)


## 회복 효율 — 흡혈 · 재생 · 처치 회복 · 회복 구슬 전부(Player.heal · 재생이 부른다). 카드로 바로 오르는 체력은 빼고.
func heal_eff() -> float:
	return _dv([1.0, 1.0, 0.85, 0.7, 0.55]) * karma_heal_mult()


## 초당 회복 상한(최대 체력 비율). 0 이면 없음. 처치 회복 · 흡혈만 쌓아 안 죽는 판을 막는다.
func heal_cap_frac() -> float:
	return _dv([0.0, 0.10, 0.07, 0.05, 0.035])


## 같은 아이템이 다시 떨어지기까지 최소 초(쉬움 · 보통 · 어려움 · 매우어려움 · 지옥). 키는 Pickup.HEAL · MAGNET · FREEZE.
## 예전엔 처치 한 마리마다 확률만 있어서 후반(초당 수십 마리)엔 자석 · 시간 멈춤이 몇 초마다 떨어졌다.
const DROP_GAP: Dictionary = {
	0: [12.0, 18.0, 24.0, 30.0, 40.0],     # 회복
	1: [40.0, 55.0, 70.0, 85.0, 110.0],    # 자석
	2: [45.0, 65.0, 85.0, 110.0, 140.0],   # 시간 멈춤
}
var _drop_next: Dictionary = {}


## 이 아이템을 지금 떨어뜨려도 되는가 — 되면 다음 간격을 잡는다.
func drop_ready(kind: int) -> bool:
	if not DROP_GAP.has(kind):
		return true
	if time_alive < float(_drop_next.get(kind, 0.0)):
		return false
	_drop_next[kind] = time_alive + _dv(DROP_GAP[kind]) * karma_drop_gap_mult()
	return true


## 시간 멈춤 아이템이 몹을 얼리는 초.
func freeze_pickup_sec() -> float:
	return _dv([2.6, 2.6, 2.2, 1.8, 1.4])


## 정예 몹 확률 배수와 정예 하나에 붙는 특성 수.
func elite_rate_mult() -> float:
	return _dv([0.8, 1.0, 1.25, 1.5, 1.9]) * karma_elite_mult()


func elite_affix_count() -> int:
	return int(_dv([0, 0, 1, 2, 2])) + karma_affix_bonus()


# ──────────────────── 11/7 업보 단계(스스로 거는 제약) ────────────────────
## 출격 전에 고르는 단계 0~10. 단계마다 아래 제약이 하나씩 더해지고(누적) 골드가 단계당 +12% 더 나온다.
## 영웅마다 깬 가장 높은 단계를 meta["karma_<영웅>"] 에 남긴다. 저승길(스테이지 6)을 한 번 깨면 열린다.
## 사용자 결정(11/7): 「하루 만에 다 깼다, 이게 끝이냐」에 답할 내용으로 지옥 난이도와 함께.
const KARMA_MAX: int = 10
const KARMA_STEPS: Array = [
	"몹 체력 +20%",
	"몹 공격력 +20%",
	"정예가 1.5배 자주 나온다",
	"회복 -25%",
	"몹 이동 속도 +10%",
	"자석 · 회복 · 시간 멈춤이 1.5배 드물게",
	"보스 체력 +40%",
	"정예 특성 하나 더",
	"몹 체력 +30% 더",
	"몹 공격력 +30% 더",
]
var karma: int = 0        # 고른 단계(설정 · 저장)
var run_karma: int = 0    # 이번 판 단계 — 출격 때 잡는다(판 도중 설정을 바꿔도 이번 판은 그대로)


## 무한 모드 「지옥」은 어느 스테이지든 매우어려움을 한 번 깨면 열린다(스테이지는 stage_unlocked 규칙).
func hell_unlocked_any() -> bool:
	for i in STAGE_NAMES.size():
		if stage_cleared(i, DIFF_MAX - 1):
			return true
	return false


func karma_unlocked() -> bool:
	for d in DIFF_MAX + 1:
		if stage_cleared(STAGE_NAMES.size() - 1, d):
			return true
	return false


func _karma_on(step: int) -> bool:
	return run_karma >= step


func karma_hp_mult() -> float:
	return (1.2 if _karma_on(1) else 1.0) * (1.3 if _karma_on(9) else 1.0)


func karma_dmg_mult() -> float:
	return (1.2 if _karma_on(2) else 1.0) * (1.3 if _karma_on(10) else 1.0)


func karma_elite_mult() -> float:
	return 1.5 if _karma_on(3) else 1.0


func karma_heal_mult() -> float:
	return 0.75 if _karma_on(4) else 1.0


func karma_spd_mult() -> float:
	return 1.1 if _karma_on(5) else 1.0


func karma_drop_gap_mult() -> float:
	return 1.5 if _karma_on(6) else 1.0


func karma_boss_hp_mult() -> float:
	return 1.4 if _karma_on(7) else 1.0


func karma_affix_bonus() -> int:
	return 1 if _karma_on(8) else 0


func karma_gold_mult() -> float:
	return 1.0 + 0.12 * float(run_karma)


## 보스 체력에 더 곱하는 몫 — 업보(보스 · 몹 체력)와 상한 뒤 강해짐의 제곱근(보스는 잡몹만큼 가파르면 판이 길어진다).
func boss_extra_hp_mult() -> float:
	return karma_boss_hp_mult() * karma_hp_mult() * sqrt(overtime_hp_mult())


## 판 위에 적는 난이도 이름 — 업보를 걸었으면 「지옥 · 업보 3」.
func diff_label(d: int = -1) -> String:
	var n: String = I18n.t(String(DIFF_NAMES[clampi(difficulty if d < 0 else d, 0, DIFF_MAX)]))
	return n if run_karma <= 0 else I18n.t("%s · 업보 %d") % [n, run_karma]


func karma_best(hero: String) -> int:
	return int(meta.get("karma_" + hero, 0))


## 깬 판의 업보 단계를 영웅 기록에 남긴다(스테이지 클리어 · 무한 완주). 기록이 올랐으면 true.
func record_karma(hero: String) -> bool:
	if run_karma <= 0 or hero == "" or run_karma <= karma_best(hero):
		return false
	meta["karma_" + hero] = run_karma
	return true


func freeze_enemies(sec: float) -> void:
	_freeze_until = Time.get_ticks_msec() + int(sec * 1000.0)


func enemies_frozen() -> bool:
	return Time.get_ticks_msec() < _freeze_until


func magnet_all(sec: float = 0.6) -> void:
	_magnet_until = Time.get_ticks_msec() + int(sec * 1000.0)


func magnet_active() -> bool:
	return Time.get_ticks_msec() < _magnet_until


## 시간 경과 난이도 배수 (적 체력 스케일) — 1분마다 +55%
func difficulty_mult() -> float:
	return 1.0 + time_alive / 60.0 * 0.55


## 종합 파워 배수: 시간 + 레벨. 레벨 오를수록 몬스터도 자연히 강해짐.
func power_mult() -> float:
	return (1.0 + time_alive / 60.0 * 0.4) * (1.0 + float(maxi(0, level - 1)) * 0.06)


## 17-1: 보스 체력의 기준 한 덩어리 = 같은 시점 기본 중간보스(kind 4, 2600). 중간보스 · 융합 보스 · 스테이지 보스가 이 값의 배수로 선다.
## ★ 예전엔 중간보스 식에만 meta_power(상점 · 영웅 등급 되먹임, 실제 세이브 ×1.43)가 있었고 융합 · 스테이지 보스 식엔 빠져 있었다.
##   게다가 융합 상한(×2.2)이 스테이지 보스 하한(×1.25)보다 커서, 강화를 갖춘 판에선 이무기 · 저승사자 중간보스 > 융합 > 스테이지 보스로
##   순서가 거꾸로였다(사용자 10/11 「중간보스나 융합보스가 마지막 보스보다 훨씬 강하다」).
##   이제 세 보스가 같은 기준을 쓰고 배수만 다르다.
## ★ 17-2(10/12 봇 480판): 17-1 의 0.9~1.3 · 1.2~1.5 · 2.0 은 전부 너무 단단했다. 봇이 보스에 넣는 피해는
##   전체 화력의 7~20% 뿐이라(보스 앞의 잡몹이 탄을 먼저 받는다) 보통 스테이지 1 보스가 178초, 중간보스가 274초,
##   융합 보스는 20판 중 15판이 도망쳤다. 스테이지 보스는 17-1 전 체급(사람이 깨던 값) 근처로, 중간 · 융합은 그 아래로.
##   중간보스 0.42~0.6 · 융합 0.6~0.8 · 스테이지 보스 1.0. 순서(중간 < 융합 < 스테이지)는 그대로다.
const BOSS_MID_MULT: Vector2 = Vector2(0.42, 0.6)
const BOSS_MID_SCALE: float = 0.46       # 종류별 기본 체력(k.hp / 2600) 에 곱한 뒤 위 범위로 자른다
const BOSS_FUSION_MULT: Vector2 = Vector2(0.6, 0.8)
const BOSS_STAGE_MULT: float = 1.0
## 보스는 스테이지 배율(1.45^스테이지)을 다 받지 않는다. 잡몹은 6.4 배(스테이지 6)까지 오르는데 플레이어 화력은
## 스테이지 1 의 1.5 배밖에 안 된다(봇 8분 화력 858 → 1,322). 다 받으면 스테이지 6 보스가 봇 기준 15분을 넘긴다.
const BOSS_STAGE_POW: float = 0.65

func boss_ref_hp() -> float:
	return 2600.0 * minf(power_mult(), 4.5) * diff_hp_mult() * pow(stage_power(), BOSS_STAGE_POW) * meta_power() * boss_extra_hp_mult()


## 무기 id → 대표 색. 주무기는 WEAPON_DEFS, 특수무기는 아이콘 색을 그대로 쓴다.
## ★ 무기 색이 지금까지 WEAPON_DEFS·icons.gd·각 무기 스크립트 세 군데에 흩어져 있었다.
##   여기로 조회를 모아 두면 HUD·발밑 시길·탄환이 같은 색을 쓰게 된다.
static func weapon_color(id: String) -> Color:
	if Player.WEAPON_DEFS.has(id):
		return (Player.WEAPON_DEFS[id] as Dictionary)["col"]
	return Icons.color_of(id)


# ──────────────────── 무기 성장 트랙 — 레벨 한 칸이 '한 가지'만 올린다 ────────────────────
## ★ 예전에는 레벨이 오르면 그 무기의 피해·주기·범위·개수가 한꺼번에 올랐다. 거기에
##   sp_lv(1.20^(Lv-1)) 곱연산까지 겹쳐서 특수무기 하나가 Lv1→6 에 DPS 9배가 됐다.
##   플레이어에게도 "레벨업하면 그냥 다 세짐"이라 무엇을 키우는지가 안 읽혔다.
##   이제 무기마다 성장 순서가 정해져 있고, 카드가 '다음에 뭐가 오르는지'를 미리 알려 준다.
##   6레벨을 넘어가면(융합 Lv11/13, 초월 +3) 트랙을 처음부터 다시 돈다.
const TRACK_LABEL: Dictionary = {
	"dmg": "공격력", "rate": "공격주기", "area": "범위", "count": "개수",
	"pierce": "관통", "proj": "탄환수", "range": "사거리", "homing": "유도",
}

## 한 칸이 올리는 폭 — 여기만 만지면 전 무기가 같이 움직인다.
## 2026-09-04: 등급 사다리 라이더(카드 종류와 무관하게 붙던 전역 +7~11%)를 걷어냈다.
## 그 몫을 **무기 자신의 성장**으로 옮긴다 — 무기 카드를 먹으면 그 무기가 확실히 세진다.
const STEP_DMG: float = 1.44    # 공격력 한 칸 (라이더 제거 보정: 1.34 → 1.44)
const STEP_RATE: float = 0.86   # 공격주기 한 칸 (작을수록 빠름)
const STEP_AREA: float = 1.17   # 사거리/반경 한 칸


const GROWTH_TRACKS: Dictionary = {
	# ── 주무기 아키타입 ──
	# ★ 2026-09-05: 관통·탄환수·유도를 **공통 카드에서 걷어내고 여기로 옮겼다.**
	#   예전엔 '관통 +1' 카드 한 장이 들고 있는 모든 무기의 관통을 올려서,
	#   무기를 하나 먹었는데 다른 무기까지 세지는 일이 생겼다. 이제 무기 카드는
	#   그 무기의 트랙만 한 칸 민다 — 무기마다 성장하는 방향이 다르다.
	#   ★ 칸을 6 으로 늘렸다. 5 칸에 탄환류를 끼우니 공격력 칸이 3 → 1~2 로 깎여
	#     무기가 통째로 약해졌다(2026-09-05 --trackcheck 로 발견: 신칼 dmg 2.07배 vs 캐논 8.92배).
	#     한 칸 늘려서 탄환류를 넣고도 공격력 비중을 예전대로 되돌린다.
	"balanced": ["dmg", "rate", "pierce", "dmg", "proj", "dmg"],    # 균형 — 뭐든 조금씩
	"heavy":    ["dmg", "pierce", "dmg", "area", "dmg", "rate"],    # 한 방 · 꿰뚫기
	"rapid":    ["rate", "dmg", "proj", "rate", "dmg", "rate"],     # 연사 · 다발
	"mid":      ["proj", "dmg", "rate", "proj", "dmg", "dmg"],      # 산탄 — 알이 늘어난다
	# ★ 대검과 작두가 **글자 하나까지 같은 트랙**이었다. 레벨을 올려도 둘이 같은 방향으로만
	#   자라서, 무기를 나눠 놓은 의미가 없었다(2026-09-06 설계 검토에서 발견).
	#   대검은 '더 자주 휘두르는 쪽', 작두는 '한 번을 크게 베는 쪽'으로 갈랐다.
	"melee":    ["dmg", "rate", "area", "dmg", "rate", "dmg"],      # 대검 — 빠르게 여러 번
	"bow":      ["pierce", "dmg", "range", "pierce", "dmg", "dmg"], # 각궁 — 멀리 · 꿰뚫기
	"fan":      ["proj", "dmg", "area", "proj", "rate", "dmg"],     # 부채 — 부채꼴이 두꺼워진다
	"sinkal":   ["rate", "homing", "dmg", "rate", "homing", "dmg"], # 신칼 — 던진 칼이 쫓아간다
	"jakdu":    ["dmg", "area", "dmg", "rate", "area", "dmg"],      # 작두 — 반원이 커진다
	# ── 특수무기 ──
	"wpn_whip":      ["area", "dmg", "rate", "dmg", "area"],
	"wpn_boomerang": ["dmg", "range", "count", "dmg", "rate"],
	"wpn_beam":      ["dmg", "count", "rate", "dmg", "area"],
	# ★ "area" 칸이 없어서 궤도 반경이 Lv1~Lv6 내내 58px 로 못 박혀 있었다. 몹이 몰려 있어도
	#   오브가 훑는 원이 안 자라니 레벨을 올려도 닿는 적 수가 그대로였다(--weapondps 가
	#   Lv2 도 Lv6 도 0.0 을 찍던 것의 절반은 이것이다). 소환수에서 고친 '죽은 칸'과 같은 문제.
	"wpn_orb":       ["count", "dmg", "area", "dmg", "count", "rate"],
	"wpn_chain":     ["count", "dmg", "rate", "dmg", "count"],
	"wpn_fire":      ["area", "dmg", "rate", "dmg", "area"],
	"wpn_ice":       ["dmg", "area", "rate", "area", "dmg"],
	"wpn_poison":    ["dmg", "area", "dmg", "rate", "area"],
	# ★ "rate" 칸은 죽은 칸이었다 — summon_weapon.gd 가 w_rate_mult 를 안 읽는다.
	#   레벨을 올려도 아무 일이 안 일어나는 칸이라 "area" 로 바꿨다(판정 반경이 자란다).
	"wpn_summon":    ["count", "dmg", "area", "dmg", "count"],
	"summon_ice":    ["dmg", "count", "rate", "dmg", "count"],
}


const _TRACK_FALLBACK: Array = ["dmg", "rate", "dmg", "area", "dmg"]


## 특수무기 기본 수치 — 카드에 **실수치**를 적기 위한 유일한 조회처.
## ★ 2026-09-06: 이 셋(피해·주기·반경)이 무기 스크립트 열 개에 흩어져 있어서 카드 표기가
##   값을 못 읽었다. 그래서 특수무기 카드는 성장 예고를 w_next_label 로 떨어뜨렸고,
##   화면에 "공격력 +44%" 라는 % 가 **10종 전부에** 떴다(사용자 지적의 직접 원인).
##   숫자를 여기서 고치면 무기 동작과 카드 표기가 같이 움직인다 — 한쪽만 바뀌지 않는다.
## per: "타" = 한 번 맞을 때 / "초" = 초당 누적 (장판·오라·레이저)
const SP_BASE: Dictionary = {
	"wpn_whip":      {"dmg": 13.0, "cd": 0.90, "cd_min": 0.42, "rad": 185.0, "per": "타"},
	"wpn_boomerang": {"dmg": 16.0, "cd": 2.10, "cd_min": 1.05, "rad": 280.0, "per": "타"},
	"wpn_beam":      {"dmg": 34.0, "cd": 0.00, "cd_min": 0.0, "rad": 260.0, "per": "초"},
	"wpn_orb":       {"dmg": 10.0, "cd": 0.38, "cd_min": 0.0, "rad": 58.0, "per": "타"},
	# 사슬은 반경 270 으로 가장 멀리 닿지만 마디가 5~7개로 잘려 군중전에서 광역기에 밀린다.
	# 기본치를 올려도 여전히 최하위라(측정 1278/s, 특수 중앙값 4400) 주기를 줄이는 쪽으로 갔다.
	# 17-2: 24 → 32. 만렙 더미 2,091/s 로 특수 중앙값(약 4,500)의 절반 아래였고, 사슬로 시작하는 도윤이 영웅 화력 0.56 배였다.
	"wpn_chain":     {"dmg": 32.0, "cd": 0.95, "cd_min": 0.35, "rad": 270.0, "per": "타"},
	"wpn_fire":      {"dmg": 12.0, "cd": 0.00, "cd_min": 0.0, "rad": 82.0, "per": "초"},
	"wpn_ice":       {"dmg": 8.0, "cd": 0.00, "cd_min": 0.0, "rad": 108.0, "per": "초"},  # 17-2: 5.5 → 8.0 (만렙 1,561/s 최하위 · 설화 0.49 배)
	"wpn_poison":    {"dmg": 4.0, "cd": 0.00, "cd_min": 0.0, "rad": 92.0, "per": "초"},
	"wpn_summon":    {"dmg": 5.5, "cd": 0.52, "cd_min": 0.0, "rad": 13.0, "per": "타"},  # 만렙 충격파와 맞바꾼 하향
	"summon_ice":    {"dmg": 13.0, "cd": 1.15, "cd_min": 0.5, "rad": 300.0, "per": "타"},
}


## 특수무기의 화면 이름. 카드 풀에만 있어서 일시정지 화면이 id 를 그대로 적을 뻔했다.
const SP_NAME: Dictionary = {
	"wpn_orb": "회전 오브", "wpn_chain": "번개 사슬", "wpn_fire": "화염 오라",
	"wpn_ice": "빙결 파동", "wpn_poison": "맹독 장판", "wpn_summon": "소환수",
	"summon_ice": "얼음 정령", "wpn_whip": "채찍", "wpn_boomerang": "부메랑",
	"wpn_beam": "회전 레이저",
}


static func sp_name(id: String) -> String:
	return I18n.t(String(SP_NAME.get(id, id)))


static func sp_base(id: String) -> Dictionary:
	return SP_BASE.get(id, {})




## 만렙(Lv6) 에 열리는 무기 고유 특성.
## ★ 2026-09-06 요구: "레벨이 오르면 무기 특성에 맞는 게 하나 생기면 좋겠다."
##   숫자를 더 올리는 게 아니라 **눈에 보이는 한 가지 변화**여야 한다 — 성장 트랙을
##   만든 이유와 같다. 그래서 특성은 전부 그 무기가 이미 하던 일의 연장이다.
##   비워 둔 셋(밸런스 소총 · 작두 · 맹독 장판)은 이유가 있다:
##     밸런스 소총 — 기준 무기가 한 정은 있어야 나머지 특성이 '특별'해진다
##     작두        — 이미 주무기 화력 1위. 여기 얹으면 격차만 벌어진다
##     맹독 장판   — "독이 번진다"는 융합(역병)의 설명 그 자체라 융합이 빈 껍데기가 된다
const MAX_TRAIT_LV: int = 6

const MAX_TRAIT: Dictionary = {
	"heavy":  {"n": "착탄 폭발", "d": "포탄이 멈추는 자리에서 터진다"},
	"rapid":  {"n": "집탄", "d": "흩어지던 탄이 한 줄기로 모인다"},
	"mid":    {"n": "총구 폭풍", "d": "갈라지기 전의 한 덩어리가 코앞을 때린다"},
	"melee":  {"n": "검압 잔류", "d": "벤 자리가 남아 걸어드는 것을 벤다"},
	"bow":    {"n": "무뎌지지 않는다", "d": "꿰뚫어도 화살이 힘을 잃지 않는다"},
	"fan":    {"n": "평행 전개", "d": "부챗살이 벌어지지 않고 나란히 나간다"},
	"sinkal": {"n": "회수", "d": "사거리가 다한 칼이 한 번 되돌아온다"},
	"wpn_whip":      {"n": "끌어당김", "d": "후려친 것이 밀려나지 않고 딸려온다"},
	"wpn_boomerang": {"n": "선회", "d": "반환점에서 한 바퀴 돌고 온다"},
	"wpn_beam":      {"n": "역회전", "d": "반대로 도는 빔이 한 줄 더 생긴다"},
	"wpn_orb":       {"n": "요격", "d": "오브가 적의 탄을 쳐낸다"},
	"wpn_chain":     {"n": "분기", "d": "번개가 갈라져 선이 아니라 나무가 된다"},
	"wpn_fire":      {"n": "전염", "d": "불타 죽은 것이 옆으로 불을 옮긴다"},
	"wpn_ice":       {"n": "빙결", "d": "오래 서 있던 것이 잠시 얼어붙는다"},
	"wpn_summon":    {"n": "충격파", "d": "때린 자리에 작은 파문이 인다"},
	"summon_ice":    {"n": "파쇄", "d": "멈춘 얼음탄이 파편으로 흩어진다"},
}


## 그 무기가 만렙 특성을 열었는가. 19곳이 같은 규칙을 읽게 여기 한 줄로 둔다.
## 융합(Lv11/13)·초월(+3)로 6을 넘긴 무기도 자동으로 포함된다.
static func w_maxed(id: String, level: int) -> bool:
	return level >= MAX_TRAIT_LV and MAX_TRAIT.has(id)


## 이 무기가 그 융합으로 초월했는가.
## ★ 무기 스크립트가 자기 동작을 바꾸는 **단 하나의 관문**이다. 2026-09-06 까지 융합은
##   "무기 Lv11 + 탄막효과 6 + card_mult ×1.25" 열두 개가 전부 같은 모양이었고, 무기 쪽에서
##   fused_marks 를 읽는 스크립트는 하나도 없었다 — 이름은 지옥불·레일건인데 하는 짓이
##   융합 전과 똑같았다("융합했는데 오?? 할 게 없다", 실플레이 리포트).
func fused(weapon_id: String, evo_id: String) -> bool:
	if player == null or not is_instance_valid(player) or not (player is Player):
		return false
	return String((player as Player).fused_marks.get(weapon_id, "")) == evo_id


static func w_trait_name(id: String) -> String:
	return I18n.t(String((MAX_TRAIT.get(id, {}) as Dictionary).get("n", "")))


static func w_track(id: String) -> Array:
	return GROWTH_TRACKS.get(id, _TRACK_FALLBACK)


## Lv1→level 사이에 stat 이 몇 번 올랐는지. Lv1 은 아직 한 번도 안 올랐다(0).
static func w_grade(id: String, level: int, stat: String) -> int:
	var tr: Array = w_track(id)
	var n: int = 0
	for i in maxi(0, level - 1):
		if String(tr[i % tr.size()]) == stat:
			n += 1
	return n




static func w_dmg_mult(id: String, level: int) -> float:
	return pow(STEP_DMG, float(w_grade(id, level, "dmg")))




static func w_rate_mult(id: String, level: int) -> float:
	return pow(STEP_RATE, float(w_grade(id, level, "rate")))




static func w_area_mult(id: String, level: int) -> float:
	return pow(STEP_AREA, float(w_grade(id, level, "area") + w_grade(id, level, "range")))


## 이번 레벨업으로 오른 항목 / 다음 레벨업에 오를 항목 (카드·빌드 화면 표시용)
static func w_next_stat(id: String, level: int) -> String:
	var tr: Array = w_track(id)
	return String(tr[maxi(0, level - 1) % tr.size()])




static func w_next_label(id: String, level: int) -> String:
	var st: String = w_next_stat(id, level)
	var amt: String = ""
	match st:
		"dmg":
			amt = "+%d%%" % int(round((STEP_DMG - 1.0) * 100.0))
		"rate":
			amt = "-%d%%" % int(round((1.0 - STEP_RATE) * 100.0))
		"area", "range":
			amt = "+%d%%" % int(round((STEP_AREA - 1.0) * 100.0))
		_:
			amt = "+1"
	return "%s %s" % [I18n.t(String(TRACK_LABEL.get(st, st))), amt]





## 특수무기 레벨 성장 배수 — 주무기와 같은 곱연산 규칙(레벨당 +20%).
## ★ 예전엔 무기마다 (6 + 4×Lv) 같은 선형이라 레벨이 오를수록 한 장의 가치가 계속 떨어졌다.
##   주무기만 pow(1.22, Lv-1) 곱연산으로 바꿔 놓으니 특수무기(영웅 등급)가 상대적으로 더 밀렸다.
##   여기서 같은 규칙을 주고, 각 무기의 선형 계수는 절반으로 낮춰 저레벨 체감을 유지한다.
## ★ 예전엔 레벨마다 무조건 1.20 배였다. 무기 스크립트의 선형 계수(base + k×Lv)와
##   곱해져 Lv1→6 에 6~9배가 나왔고, 거기에 범위·개수까지 같이 올라 실질 DPS 가 10배를 넘겼다.
##   이제 성장 트랙의 '공격력' 칸이 몇 번 나왔는지만 본다 — 6레벨이면 두세 칸이다.
func sp_lv(level: int) -> float:
	return 1.0  # (호환용) 실제 성장은 무기별 G.w_dmg_mult 가 담당한다


## 특수무기가 '탄환 +1'(proj_bonus)에서 받는 추가 개체 수 — 2장당 1개.
## 오브·소환수처럼 개수가 곧 위력인 무기가 멀티샷 카드를 전혀 못 받던 것을 잇는다.
func sp_units() -> int:
	if player != null and is_instance_valid(player):
		return int((player as Player).proj_bonus / 2)
	return 0


## 특수무기의 같은 적 재타격 쿨(ms) — 관통 카드가 이 간격을 줄인다(주무기의 관통에 대응).
func sp_hit_cd(base_ms: int, level: int) -> int:
	var p_pierce: int = 0
	if player != null and is_instance_valid(player):
		p_pierce = (player as Player).pierce
	return maxi(150, base_ms - level * 18 - p_pierce * 20)


## 특수무기 데미지 스케일(플레이어 전역 데미지 연동). 널 안전.
func sp_pow() -> float:
	if player != null and is_instance_valid(player):
		return player.special_power()
	return 1.0


## 원점 중심 정다각형 점 배열 (Polygon2D 비주얼용)
## ★ 초당 수백 개의 탄환·이펙트가 같은 (변 수, 반지름) 조합을 반복 요청한다.
##   삼각함수 + PackedVector2Array 할당이 그만큼 돌던 것을 캐시로 없앤다.
##   반환값을 호출부가 고쳐 쓰지 않으므로(전부 Polygon2D.polygon 대입) 공유해도 안전하다.
static var _poly_cache: Dictionary = {}

static func regular_polygon(sides: int, radius: float, rot: float = 0.0) -> PackedVector2Array:
	var key: String = "%d|%.2f|%.3f" % [sides, radius, rot]
	var hit: Variant = _poly_cache.get(key)
	if hit != null:
		return hit
	var pts := PackedVector2Array()
	for i in sides:
		var a: float = TAU * float(i) / float(sides) + rot
		pts.append(Vector2(cos(a), sin(a)) * radius)
	if _poly_cache.size() < 512:  # 무한 증식 방지 (조합은 실제로 수십 개뿐)
		_poly_cache[key] = pts
	return pts
