extends MainCards
## 아레나 · 웨이브 스폰 · 보스 · HUD · 런 수명 · 승패.
## 카드/표기/슬롯/융합은 기반 클래스 MainCards(scripts/main_cards.gd)에 있고,
## 헤드리스 검사 하니스는 파생 클래스 Main(scripts/main.gd)에 있다.
class_name MainGame


const ARENA: float = 1500.0
const MAX_ENEMIES: int = 130  # 성능: 활성 몬스터 상한 (초과분은 등급/보스로 대체)
const BOSS_MIN_GAP: float = 90.0     # 종류 불문 보스 사이 최소 실시간 간격(초) — 하한
const BOSS_GAP_PER_MIN: float = 6.0  # 1분 경과마다 최소 간격 +6초 (후반일수록 보스=이벤트)
const BOSS_GAP_MAX: float = 150.0    # 최소 간격 상한(초)
const WAVE_DUR: float = 38.0  # 웨이브 길이
const BOSS_EVERY: int = 9  # 보스 웨이브 주기 (총 ~5마리)
const MATCH_LEN: float = 1800.0  # 30분 → 최종 무적 보스
const MERGE_THRESHOLD: int = 116  # 이 수 이상 몬스터가
const MERGE_HOLD: float = 20.0    # 이만큼 지속되면 융합 보스로 (너무 잦지 않게)
const SWARM_W: float = 420.0      # 몰려드는 요괴 게이지 폭
const FUSION_WARN_EARLY: float = 4.0   # 이만큼 몰려 있으면 "몰려든다" — 아직 줄일 수 있다
const FUSION_WARN_LEAD: float = 6.0    # 남은 시간이 이 밑이면 "뭉치고 있다" — 이제 온다
const FUSION_DEADLINE: float = 65.0  # 융합 보스 처치 제한시간(초과 시 도주+패널티) — M38: HP 상향분 완충 55→65
const FUSION_MIN_TIME: float = 180.0  # 첫 융합 보스 ~3분 이후
const FUSION_LOCKOUT: float = 150.0   # 융합 종료 후 재발동까지 최소 2.5분 (1분 주기 방지)
const FUSION_FIGHT_MIN: float = 40.0  # 스테이지 판: 융합 보스와 싸울 시간이 이만큼은 남아야 융합이 찬다

var _spawn_t: float = 0.0
var _mythic_taken: int = 0        # 이번 판에 고른 신화 수 (MYTHIC_PER_RUN 상한)
var _mythic_ids: Array = []       # 이번 판에 고른 신화 id — HUD/일시정지 표시용
var _last_boss_t: float = -999.0  # 마지막 보스 스폰 시각(웨이브/융합/최종 공통) — 전역 간격 게이트
var _boss_pending: bool = false
var _overcap_warned: bool = false  # "몰려든다"를 띄운 판인가 — "흩어졌다"를 한 번만 내기 위한 표식
## 보스가 나오기까지 남은 시간. 0 보다 크면 좌상단에 빨간 글자로 초를 센다.
## ★ 예전엔 보스가 예고 없이 튀어나왔다 — 웨이브 9가 되는 순간 그 자리에서 스폰했다.
##   화면 밖(머리 위 480px)에서 시작하니 "갑자기 떴다"로만 보인다(2026-09-07 지적).
##   나오기 전에 초를 세어 주면 도망칠 자리를 잡을 수 있다.
const BOSS_LEAD: float = 10.0
var _boss_eta: float = 0.0
var _boss_eta_kind: String = ""
var _lbl_bosseta: Label
var _spawn_queue: int = 0         # 웨이브 스폰 예약분 — 프레임당 조금씩 소화(스파이크 방지)
var _wave: int = 1
var _wave_t: float = 0.0
var _final_spawned: bool = false
var _dps_mode: bool = false  # --weapondps: 스폰/테마/융합 정지(통제된 측정)
var _mobile: bool = false  # 모바일/터치: 성능 위해 적 상한 하향
var _hud_canvas: CanvasLayer   # HUD 캔버스 레이어
var _hud_layer: Control        # HUD 스케일러(모든 HUD 요소의 부모) — 인터페이스 크기 설정으로 확대
var _lbl_wave: Label
var _pause_menu: PauseMenu
var _char_select: CharacterSelect
var _meta_shop: MetaShop
var _main_menu: MainMenu
var _settings: SettingsMenu
var _codex_screen: CodexScreen
var _run_active: bool = false  # 살아있는 런이 존재(이어하기 가능)
var _lbl_gold: Label
var _lbl_time: Label
var _lbl_kills: Label
var _lbl_level: Label
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _hp_lbl: Label
var _dash_badge: Control
var _dash_bg: ColorRect
var _dash_fill: ColorRect
var _dash_lbl: Label
var _xp_bg: ColorRect
var _xp_fill: ColorRect
var _levelup_flash: ColorRect
var _hurt_vig: TextureRect          # 17-1 피격 · 빈사 가장자리 붉은 비네트
var _hurt_hp_prev: float = -1.0
var _hurt_a: float = 0.0
var _gameover: Control
var _revive_panel: Control     # 광고 부활 제안 (판당 1회)
var _revive_left: float = 0.0  # 자동 포기까지 남은 초
var _app_away: bool = false     # 창 · 앱을 떠나 있음(Alt+Tab · 홈 버튼) — 부활 카운트다운을 멈춘다(QA C8)
var _revive_busy: bool = false # 광고 재생 중 — 중복 클릭 차단
var _victory: Control          # 스테이지 클리어 패널 (S1)
var _victory_lbl: Label
var _vic_stars: HBoxContainer   # 16차 U5: 결과 별 ★☆ 글자 대신 별 그림
var _victory_next: Button
var _victory_title: Label   # 스테이지 클리어 / 무한 완주에 따라 문구가 바뀐다
var _vic_w_clear: Control    # 낱말 그림 「STAGE CLEAR」
var _vic_w_result: Control   # 16차 U7 「결과」 · 「RESULT」 — 무한 완주 창 머리
var _combo_lbl: Label          # 킬 콤보 카운터 (S1)
var _combo_px: HBoxContainer = null   # 10차 A: [숫자][콤보!] 그림 줄 — 있으면 라벨 대신
var _combo_num: PixelText = null
var _lbl_crown: Label          # 신화 · 융합 상시 배지 (뭘 먹었는지 화면에 남긴다)
var _lowhp_vig: TextureRect    # 저체력 경고 비네트 (S1)
var _base_vig: Control         # 늘 켜진 화면 가장자리 비네트(11/7 --physprof 가 따로 끈다)
var _fusion_bg: ColorRect
# 스테이지 보스 상단 체력바 (S4: 중간보스와 구분되는 전용 연출)
var _sboss_root: Control
var _sboss_lbl: Label
var _sboss_bg: ColorRect
var _sboss_fill: ColorRect
## 웨이브 중간보스 바 (사용자 요구, 2026-09-15). 머리 위 바만 있어서 융합·스테이지 보스와
## 표시가 달라 보였다. 상단에도 주되, **폭을 좁게** 잡아 급이 다르다는 건 남긴다.
var _wboss_root: Control
var _wboss_lbl: Label
var _wboss_bg: ColorRect
var _wboss_fill: ColorRect
# ── 스테이지 모드 상태 (S1) ──
var _stage_mode: bool = false
var _stage_boss: Enemy = null
## QA 10/13: 보스를 냈고 아직 처리 안 했다(스테이지 · 무한 최종 · 융합). Godot 4 는 지워진 노드를 null 과 같다고 봐서
##   `_stage_boss != null` 로 먼저 거르면 _dead 를 들키기 전에 지워진 보스를 영영 놓친다(봇 8배속 약 5%).
var _stage_boss_down: bool = false
var _final_boss_down: bool = false
var _final_boss: Enemy = null   # 무한 모드 최종 보스 — 처치하면 '완주'로 끝난다
var _reapers: Array = []        # 최종 보스 뒤로 1분마다 하나씩 더 오는 사신들(완주 판정은 첫 사신 _final_boss 만)
var _reaper_next: float = INF
var _endless_done: bool = false
var _win_seq: bool = false      # 승리 연출 진행 중 (패널은 연출이 끝난 뒤)
var _stage_done: bool = false
var _stage_earned: int = 0
var _run_stage_l: int = 0   # 런 시작 시 래치된 스테이지/난이도 — 클리어 기록은 이 값만 사용 (위조 방지)
var _run_diff_l: int = 1
var _go_ms: int = 0         # 게임오버 표시 시각 — 짧은 입력 유예 (연타로 결과 화면 놓침 방지)
const STAGE_BOSS: Array = [4, 13, 15, 14, 5, 5]  # 던전=나기 / 도서관=시울 / 정원=소류 / 용암=볼케 / 천상=네페르 / 저승길=염라(네페르 틀)
var _levelup_root: Control
var _cards_box: HBoxContainer
var _pending_levelups: int = 0
var _reroll_btn: Button
var _reroll_left: int = 0
var _last_offered: Array = []  # 롱플레이 자동픽용: 마지막 제시된 카드 id들
# 융합 보스
var _overcap_t: float = 0.0
var _fusion_boss: Node = null
var _fusion_live: bool = false   # QA 10/13: 융합 보스가 떠 있다(지워진 노드는 null 과 같아서 따로 든다)
var _fusion_deadline: float = 0.0
var _fusion_max_hp: float = 1.0
var _fusion_lockout: float = 0.0
var _fusion_root: Control
var _fusion_fill: ColorRect
var _fusion_lbl: Label
var _fusion_tbg: ColorRect      # 융합 보스 도망 게이지(남은 시간, 숫자 없이)
var _fusion_tfill: ColorRect
var _swarm_root: Control        # 몰려드는 요괴 게이지 — 몹이 쌓일수록 차고, 가득 차면 융합 보스
var _swarm_lbl: Label
var _swarm_bg: ColorRect
var _swarm_fill: ColorRect
var _swarm_g: float = 0.0
# 보물상자(진화)
var _chest_panel: CanvasLayer = null   # 보스 상자 결과 패널 (열려 있으면 판이 멈춰 있다)
var _chest_was_paused: bool = false
var _chest_got: Array = []            # 지금 열린 상자 창이 보여 주는 카드(같은 프레임에 둘째 상자가 오면 합친다)
var _chest_pending: bool = false
var _sig_chest_done: bool = false  # 캐릭터 시그니처 보물상자 1회 지급 여부
var _chest_used: bool = false


func _ready() -> void:
	randomize()
	# 모바일/터치 감지는 HUD 빌드보다 '먼저' — 안 그러면 모바일 일시정지 버튼이 안 생김 (S1 수정)
	var mob0: bool = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or ("--touch" in OS.get_cmdline_user_args())
	G.detect_mobile(mob0)
	_mobile = mob0
	UiParts.skin_scrollbars()
	_build_background()
	var cam := GameCamera.new()
	add_child(cam)
	G.camera = cam
	var p := Player.new()
	add_child(p)
	G.player = p
	cam.global_position = Vector2.ZERO
	_build_hud()
	_build_levelup_ui()
	_pause_menu = PauseMenu.new()
	_pause_menu.build_provider = _build_summary
	_pause_menu.to_main_menu.connect(_on_pause_to_menu)
	add_child(_pause_menu)
	get_tree().quit_on_go_back = false  # 안드로이드 뒤로가기로 앱 종료 방지 → _notification에서 처리
	_char_select = CharacterSelect.new()
	_char_select.picked.connect(_on_char_picked)
	_char_select.closed.connect(_on_char_select_closed)
	add_child(_char_select)
	_meta_shop = MetaShop.new()
	_meta_shop.closed.connect(_on_shop_closed)
	add_child(_meta_shop)
	_settings = SettingsMenu.new()
	_settings.closed.connect(_on_settings_closed)
	add_child(_settings)
	_codex_screen = CodexScreen.new()
	_codex_screen.closed.connect(_on_codex_closed)
	add_child(_codex_screen)
	_main_menu = MainMenu.new()
	_main_menu.new_game.connect(_on_new_game)
	_main_menu.new_char.connect(_on_new_char)
	_main_menu.continue_game.connect(_on_continue)
	_main_menu.open_shop.connect(_on_open_shop)
	_main_menu.open_settings.connect(_on_open_settings)
	_main_menu.open_codex.connect(_on_open_codex)
	_main_menu.quit_game.connect(func() -> void:
		if G.running:   # QA 10/13: quit() 는 닫기 요청을 안 거쳐서 판 골드가 사라졌다
			G.bank_run_gold()
		get_tree().quit())
	add_child(_main_menu)
	G.leveled_up.connect(_on_level_up)
	G.player_hp_changed.connect(_update_hp)
	G.player_died.connect(_on_player_died)
	G.revive_offered.connect(_on_revive_offered)
	Ads.reward_earned.connect(_on_revive_reward)
	Ads.ad_finished.connect(_on_revive_ad_finished)
	G.achievement_unlocked.connect(_on_achievement)
	G.chest_collected.connect(_grant_signature)
	G.boss_chest_collected.connect(_on_boss_chest)
	_update_hp()

	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	G.no_save = uargs.size() > 0  # [감사 C16] 하니스/테스트 실행은 실유저 세이브를 절대 안 건드림
	for a in uargs:
		if (a as String).begins_with("--stage="):  # 스테이지 모드 시뮬 (S1)
			G.run_mode = "stage"
			G.stage_sel = clampi(int((a as String).get_slice("=", 1)), 0, G.STAGE_NAMES.size() - 1)
	if _dev_dispatch(uargs):
		return
	if _mobile:
		add_child(TouchControls.new())
	# 부팅: 씬 리로드로 넘어온 새 런이면 바로 시작, 아니면 메인 메뉴
	if not G.pending_char.is_empty():
		var d: Dictionary = G.pending_char
		G.pending_char = {}
		_begin_run(d)
	else:
		_main_menu.open()
		_boot_log.call_deferred()


## 16차 4-3: 켜서 메뉴가 그려지기까지 · 출격에서 첫 전투 프레임까지(ms) — 플레이어 로그(user://logs)에도 남는다.
func _boot_log() -> void:
	# 판 끝나고 메인 메뉴로 돌아올 때(씬 다시 불러오기)도 여기를 지난다 — 처음 켤 때 한 번만 적는다(10/13 QA C2)
	if G.boot_menu_ms > 0:
		return
	await RenderingServer.frame_post_draw
	print("[BOOT] 켜서 메인 메뉴까지 %d ms" % Time.get_ticks_msec())
	G.boot_menu_ms = Time.get_ticks_msec()


# ---------------------------------------------------------------- 메뉴 흐름
func _on_new_game() -> void:
	_start_or_reload(_last_char if not _last_char.is_empty() else Characters.defs()[0])


func _on_new_char() -> void:
	_main_menu.close()
	_char_select.open()


func _on_continue() -> void:
	if not _run_active:
		return
	_main_menu.close()
	get_tree().paused = false


func _on_open_shop() -> void:
	_main_menu.close()
	_meta_shop.open()


func _on_shop_closed() -> void:
	_main_menu.open()


## 도전과제 달성 알림.
## ★ 예전엔 G.running 일 때만 배너를 띄웠는데, 클리어로 달성되는 과제는 정산 직전에
##   running 이 false 로 꺼진 뒤에 판정돼서 배너가 구조적으로 절대 안 떴다.
##   지금은 게임 중이면 배너, 정산 중이면 결과 패널에 줄로 실린다.
var _pending_ach: Array = []
var _pending_ach_defs: Array = []   # QA 10/13: 정산 중 딴 도전과제 정의 — 결과 화면 「새로 열림」 카드로 싣는다
var _forge_extra: bool = false  # 도깨비 대장장이: 이번 무기 카드에 한 단계 더 붙일지
var _drain_acc: float = 0.0     # 스폰 소화량 누적(초당 환산 — 프레임레이트 독립)
var _shadow_pack: int = 0       # 그림자 무리는 떼로 온다 — 다음 스폰 몇 마리를 같은 종으로 낼지

func _on_achievement(a: Dictionary) -> void:
	if G.running:
		_wave_banner(I18n.t("도전과제 달성: %s  (+%dG)") % [I18n.t(String(a["name"])), int(a.get("gold", 0))], Color("ffd54a"))
	else:
		_pending_ach.append(I18n.t("도전과제: %s  (+%dG)") % [I18n.t(String(a["name"])), int(a.get("gold", 0))])
		_pending_ach_defs.append(a)


func _on_open_codex() -> void:
	_main_menu.close()
	_codex_screen.open()


func _on_codex_closed() -> void:
	_codex_screen.close()
	_main_menu.open()






















































func _on_open_settings() -> void:
	_main_menu.close()
	_settings.open()


func _on_settings_closed() -> void:
	_main_menu.open()


func _on_pause_to_menu() -> void:
	# 런 유지 + 일시정지 상태 그대로 → 이어하기 가능
	_main_menu.set_continue_enabled(true)
	_main_menu.open()


## 새 캐릭터/새 게임 시작. 이미 진행 중인 런(강화 누적)이면 깨끗한 씬으로 리로드.
func _start_or_reload(def: Dictionary) -> void:
	_last_char = def
	G.deploy_ms = Time.get_ticks_msec()   # 16차 4-3: 출격 → 첫 전투 프레임
	if _run_active:
		if G.running:
			G.bank_run_gold()  # [감사 C17] 런 포기 시 이번 런 골드 몰수되던 것 — 은행에 적립 후 리로드
		G.pending_char = def
		get_tree().paused = false
		get_tree().reload_current_scene()
	else:
		_begin_run(def)


## 플레이어가 실제로 들고 있는 무기를 카드 진척(_upgrade_counts)에 맞춘다.
## 캐릭터 고유 능력이나 장신구로 받은 무기도 '이미 1장 찍은 것'으로 세어야 융합 재료가 된다.
func _sync_owned_weapons() -> void:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return
	for w in p.weapons_primary:
		var wid: String = "wp_" + String(w["id"])
		_upgrade_counts[wid] = maxi(int(_upgrade_counts.get(wid, 0)), int(w["level"]))
	for k in p.weapons.keys():
		var node: Node = p.weapons[k]
		if not is_instance_valid(node):
			continue
		var lv: int = int(node.get("level")) if node.get("level") != null else 1
		_upgrade_counts[String(k)] = maxi(int(_upgrade_counts.get(String(k), 0)), lv)


## 이전 런의 잔존물(적·적탄·내탄·젬·금화·픽업·장판)을 실제로 해제한다.
## ★ 예전엔 스칼라 변수만 되돌리고 노드는 하나도 안 치웠다. 씬 리로드를 타지 않는 재시작
##   경로(승리 패널 → 새 게임 등)에서 적 383마리와 적탄 12발이 그대로 wave 1 로 넘어왔고,
##   G.reset_run() 이 freeze 를 풀어버려 승리 화면에서 얼려둔 잔당까지 되살아났다.
##   노드를 실제로 지우면 각자의 _exit_tree 가 정적 카운터(EnemyBullet.live / XpGem._live /
##   DamageNumber._active)까지 전부 0 으로 되돌려 준다 — 카운터를 손으로 밀 필요가 없다.
func _clear_run_entities() -> void:
	_close_chest_panel()   # 상자 패널이 열린 채 런이 끝나면 화면이 멈춘 채로 남는다
	# ★ "hazard" 를 안 지우면 **이전 런의 얼음 장판·독 웅덩이가 다음 런까지 살아서 계속
	#   피해를 준다.** 그룹이 없어 이 목록에서 빠져 있었다 — 측정에서는 앞 융합의 독이
	#   다음 융합 측정에 새는 것으로 드러났다(2026-09-06, --fusepower 의 레일건 값이 2.7배 튐).
	for g: String in ["enemy", "ebullet", "bullet", "xpgem", "coin", "hazard"]:
		for n in get_tree().get_nodes_in_group(g):
			if is_instance_valid(n):
				(n as Node).queue_free()
	# 픽업·장판은 그룹이 없어 자식에서 형으로 골라낸다
	for c in get_children():
		if c is Pickup or c is TelegraphAoE:
			(c as Node).queue_free()


## 현재 플레이어에 캐릭터/메타 적용 후 런 시작 (리로드 없이).
func _begin_run(def: Dictionary) -> void:
	_last_char = def
	_main_menu.close()
	if G.player != null and is_instance_valid(G.player):
		var pl := G.player as Player
		pl.apply_meta()
		pl.apply_accessories()  # 장착한 장신구 — 메타 다음, 캐릭터 편차 앞
		pl.apply_character(def)
	_wave = 1
	_wave_t = 0.0
	_final_spawned = false
	_stage_boss_down = false
	_final_boss_down = false
	_reapers.clear()
	_reaper_next = INF
	_spawn_queue = 0
	_clear_run_entities()
	# 승리 연출 상태도 전부 되돌린다 — 안 그러면 다음 런이 슬로모션으로 시작하거나
	# 클리어 판정이 이미 끝난 것으로 남는다 (리로드 없이 다시 시작하는 경로가 있다)
	_win_seq = false
	_win_at_ms = 0
	_win_paused = false
	_fusion_end_ms = 0
	_win_cb = Callable()
	_endless_done = false
	_stage_done = false
	_final_boss = null
	_pending_ach.clear()
	_pending_ach_defs.clear()
	_banner_q.clear()
	_banner_busy = false
	_forge_extra = false
	_shadow_pack = 0
	G.set_slowmo(1.0)
	if _sboss_root != null:
		_sboss_root.visible = false
	if _wboss_root != null:
		_wboss_root.visible = false
	_upgrade_counts.clear()
	_transcended = false
	_upgrade_counts["wp_balanced"] = 1  # 시작 무기(밸런스 소총 Lv1)를 카드 별표시와 일치시킴 (M38)
	# ★ 캐릭터·장신구가 '들고 시작하는' 무기(화염술사의 화염 오라, 무당·무당방울의 소환수)는
	#   지금까지 _upgrade_counts 에 안 잡혔다. 그래서 화염 오라를 들고 시작해도 융합 재료로는
	#   0장 취급이라 wpn_fire 를 처음부터 다시 6번 찍어야 했다 — 캐릭터 개성이 융합에서 죽어 있었다.
	#   apply_* 가 끝난 뒤 실제 보유 무기를 진척에 반영한다.
	_sync_owned_weapons()
	_evolved.clear()
	_consumed.clear()
	_chest_pending = false
	_sig_chest_done = false
	_reroll_left = 2 + G.meta_level("m_reroll") + (1 if G.acc_has("acc_norigae") else 0)  # 노리개: 리롤 +1
	_banish_left = 1 + G.meta_level("m_banish")   # 14차: 봉인 — 판 시작 1 + 영구 강화
	_banish_mode = false
	_banished.clear()
	_overcap_t = 0.0
	_fusion_boss = null
	_fusion_live = false
	_fusion_lockout = 0.0
	_last_boss_t = -999.0
	_hurt_hp_prev = -1.0
	_hurt_a = 0.0
	_mythic_taken = 0
	_mythic_ids = []
	_combo_paid = {}
	_boss_pending = false
	_chest_pending = false
	_chest_used = false
	if _fusion_root != null:
		_fusion_root.visible = false
	if _wboss_root != null:
		_wboss_root.visible = false
	G.reset_run()
	G.lock_run_meta_power()   # 영웅 능력치를 판 시작 때 고정하니 몹 되먹임도 같이 고정(QA C4)
	# 11/7 업보: 이번 판 단계를 출격 때 잡는다. 저승길을 아직 안 깼으면 0(설정에 남은 값이 새지 않게).
	G.run_karma = G.karma if G.karma_unlocked() else 0
	_events_reset()
	G.wave = 1
	# ── 모드별 시작 테마 (S1): 스테이지 모드 = 고른 스테이지 고정 / 무한 = 순환 ──
	_stage_mode = G.run_mode == "stage"
	_stage_boss = null
	_stage_done = false
	_run_stage_l = G.stage_sel  # [감사 C5/C6] 클리어 기록용 래치 — 런 도중 메뉴에서 바꿔도 위조 불가
	_run_diff_l = G.difficulty
	if _victory != null:
		_victory.visible = false
	if _gameover != null:
		_gameover.visible = false  # [감사 C4] 리로드 없는 재시작 시 게임오버 문구 박제 방지
	if _revive_panel != null:
		_revive_panel.visible = false  # 같은 이유 — 부활 패널이 다음 판에 박제되면 안 된다
	_revive_busy = false
	_revive_left = 0.0
	Ads.preload_ad()  # 첫 로드가 실패했을 수 있다 — 판 시작마다 다시 받아 본다 (이미 있으면 no-op)
	if _stage_mode:
		_cur_theme = clampi(G.stage_sel, 0, G.STAGE_NAMES.size() - 1)
		_theme_t = 1.0e9  # 테마 고정 (순환 없음)
		_apply_stage_rule(_cur_theme)
	else:
		_cur_theme = 0
		_theme_t = randf_range(22.0, 34.0)
		# QA C6: 무한 첫 테마(던전)만 맵 규칙(체력 ×1.18 · 경험치 ×1.15 · 배너 · 도감 map_0)을 안 걸었다 — 다음 테마부터 걸렸다
		_apply_stage_rule(_cur_theme)
	if _bg != null:
		_bg.set_theme(_cur_theme)
	_regen_obstacles(_cur_theme)
	get_tree().paused = false
	_run_active = true
	_main_menu.set_continue_enabled(true)
	if _stage_mode:
		_wave_banner("STAGE %d · %s (%s)" % [G.stage_sel + 1, I18n.t(String(G.STAGE_NAMES[G.stage_sel])), G.diff_label()], Color("ffd54a"))
	else:
		_wave_banner("WAVE 1", Color("ffd54a"), ["w_wave", "#1"])




func _on_char_picked(def: Dictionary) -> void:
	_start_or_reload(def)


## 캐릭터 선택에서 뒤로 → 메인 메뉴 (선택 없이)
func _on_char_select_closed() -> void:
	_main_menu.open()


func _process(delta: float) -> void:
	if G.deploy_ms > 0 and G.running:
		print("[BOOT] 출격에서 첫 전투 프레임까지 %d ms" % (Time.get_ticks_msec() - G.deploy_ms))
		G.deploy_ms = 0
	_update_boss_arrows()
	# 19차 3절 1: 내 이펙트 흐림 재질에 영웅 자리(몸 가운데)를 넣는다
	if G.player != null and is_instance_valid(G.player):
		G.set_fx_near((G.player as Node2D).global_position)
	# 부활 제안 카운트다운 — G.running 이 false 라 게임 로직은 멈춰 있지만 이건 돌아야 한다.
	if _revive_panel != null and _revive_panel.visible and not _revive_busy and _revive_left > 0.0 and not _app_away:
		_revive_left -= delta
		if _revive_left <= 0.0:
			_finish_death()   # 시간 초과 → 자동 포기
		else:
			_update_revive_label()
	# 승리 연출: 실시간 타이머라 일시정지·씬 전환과 무관하게 반드시 끝난다.
	# ★ 슬로모션이 걸린 채로 일시정지하면 메뉴 전체가 32% 속도로 돌아간다 — 트리가 멈춘 동안엔
	#   시간 배율을 원래대로 돌려 두고, 연출이 남아 있으면 재개할 때 다시 건다.
	if _fusion_end_ms > 0 and Time.get_ticks_msec() >= _fusion_end_ms:
		_fusion_end_ms = 0
		if _win_at_ms <= 0:  # 승리 연출이 겹쳐 있으면 그쪽이 시간 배율을 소유한다
			G.set_slowmo(1.0)
	if _win_at_ms > 0:
		var paused: bool = get_tree().paused
		if paused and not _win_paused:
			_win_paused = true
			G.set_slowmo(1.0)
		elif not paused and _win_paused:
			_win_paused = false
			G.set_slowmo(0.32)
		if Time.get_ticks_msec() >= _win_at_ms:
			_win_at_ms = 0
			_win_paused = false
			G.set_slowmo(1.0)
			if _win_cb.is_valid():
				_win_cb.call()
	if G.running and not _dps_mode:
		_wave_t += delta
		if _wave_t >= WAVE_DUR:
			_wave_t = 0.0
			_advance_wave()
		# 종국: 스테이지 모드 = 8분 스테이지 보스 / 무한 = 30분 최종 보스
		if G.boss_fight_t > 0.0 and not _win_seq:
			G.boss_fight_t += delta  # 보스전 경과 — 별 등급 판정에 쓰인다
		if _stage_mode:
			if not _final_spawned and G.time_alive >= G.STAGE_LEN:
				_final_spawned = true
				_spawn_stage_boss()
			if _final_spawned and not _stage_boss_down and (not is_instance_valid(_stage_boss) or _stage_boss._dead):
				_stage_boss_down = true
				_stage_boss = null
				_begin_win_sequence(_on_stage_clear)
		else:
			if G.is_demo() and not _endless_done and G.time_alive >= G.DEMO_ENDLESS_END:
				_on_demo_end()   # 19차 4-2: 체험판 무한은 15분에서 끝
			if not _final_spawned and G.time_alive >= MATCH_LEN:
				_final_spawned = true
				_spawn_final_boss()
			if _final_boss != null and is_instance_valid(_final_boss) and not _final_boss._dead and not _win_seq and G.time_alive >= _reaper_next:
				_reaper_next += REAPER_ADD_SEC
				if _reapers.size() < REAPER_MAX:
					_spawn_reaper_extra()
			if _final_spawned and not _final_boss_down and (not is_instance_valid(_final_boss) or _final_boss._dead):
				_final_boss_down = true
				_final_boss = null
				_begin_win_sequence(_on_endless_clear)
		_spawn_t -= delta
		# 스폰 압력: 무한은 30분 설계 그대로, 스테이지는 8분 완결이라 완만하게(t×0.6 환산).
		var t_eff: float = G.pressure_t(G.PRESS_FLOOR_COUNT, INF) * (0.6 if _stage_mode else 1.0)
		var interval: float = maxf(0.16, 1.1 - t_eff * 0.018) * G.diff_spawn_mult()
		if _boss_fight_on():
			interval *= 4.0  # 스테이지 보스전: 잡몹 유입 대폭 감소 — 잡몹 벽이 탄환을 다 흡수하는 것 방지
		if _spawn_t <= 0.0:
			_spawn_t = interval
			if _enemy_count() < _enemy_cap():
				_spawn_wave()  # 융합 보스가 나와도 일반 몹은 계속
		_drain_spawn_queue(delta)
		G.enemy_soft_cap = _enemy_cap()  # [감사 C13] 소환/분열도 참조하는 몹 상한 공유
		# [감사 C10] 스테이지 보스전 · 무한 최종 보스전엔 융합/웨이브 보스 난입 금지 — 최종 결전은 1:1
		var sboss_phase: bool = _final_spawned
		if not sboss_phase and not _stage_mode:
			_update_events(delta)   # 11/7 무한 패턴 이벤트
		_sess_t += delta
		if _sess_t >= 10.0:   # 11/7 튕김 기록: 판 도중 상태(튕기면 이게 마지막 기록)
			_sess_t = 0.0
			_session_mark()
		if not sboss_phase:
			_update_fusion(delta)
		elif _swarm_root.visible:
			_swarm_root.visible = false   # 최종 결전엔 융합이 없다
		if _boss_pending and _boss_gate_open() and not sboss_phase and _overcap_t <= 0.0:  # 게이트로 미뤄둔 웨이브 보스 방출(융합이 차는 중이면 대기)
			_boss_pending = false
			_arm_boss_eta("중간보스")
		# 보스 예고 카운트다운 — 0 이 되는 순간 실제로 나온다
		if _boss_eta > 0.0:
			_boss_eta = maxf(0.0, _boss_eta - delta)
			if _boss_eta <= 0.0:
				var k: String = _boss_eta_kind
				_boss_eta_kind = ""
				if k == "중간보스":
					_spawn_boss()
		_update_boss_eta_label()
		# 랜덤 테마 전환 (배경 + 지형 장애물)
		_theme_t -= delta
		if _theme_t <= 0.0:
			_theme_t = randf_range(25.0, 42.0)
			_cycle_theme()
		_stage_hazards(delta)
		# 아레나 밖으로 못 나가게 소프트 클램프
		if G.player != null and is_instance_valid(G.player):
			var pp := (G.player as Node2D).global_position
			(G.player as Node2D).global_position = pp.clamp(Vector2(-ARENA, -ARENA), Vector2(ARENA, ARENA))
	_update_hud()


## 게임오버 화면에서 대시키 / 화면 탭 / 클릭 → 다시(씬 리로드). 모바일도 탭으로 복귀 가능.
## [감사 C27] 사망 직전 연타 입력이 결과 화면을 즉시 닫아버리던 것 — 0.9초 입력 유예.
func _input(event: InputEvent) -> void:
	_levelup_keys(event)
	if not G.running and _gameover != null and _gameover.visible:
		if Time.get_ticks_msec() - _go_ms < 900:
			return
		# 14차: 게임오버 판에 버튼(다시 도전 · 메인 메뉴)이 생겼다 — 화면 아무 곳 탭으로 메뉴로 가면 버튼을 못 누른다. 대시 키만 남긴다.
		# QA 10/13: 패드 A 도 대시라 포커스된 「다시 도전」 대신 메인 메뉴로 갔다 — 패드는 단추 포커스로만
		if event.is_action_pressed("dash") and not (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton):
			get_tree().reload_current_scene()


## 13차: 레벨업 카드 숫자키 1 · 2 · 3 · 4.
## QA 10/13: 레벨업 창은 트리를 멈추는데 Main 은 멈춤을 따라가서 _input 이 안 불렸다 — 늘 도는 레벨업 층(_lv_keys)이 이걸 부른다.
func _levelup_keys(event: InputEvent) -> void:
	if _levelup_root != null and _levelup_root.visible and event is InputEventKey and (event as InputEventKey).pressed \
			and not (event as InputEventKey).echo:
		var kc: int = (event as InputEventKey).keycode
		if kc >= KEY_1 and kc <= KEY_4:
			var ci: int = kc - KEY_1
			if ci < _last_offered.size() and _cards_tap_ready():
				get_viewport().set_input_as_handled()
				_card_pressed(String(_last_offered[ci]))
			return


var focus_pause_test: bool = false   # --wincheck 가 창을 빼앗았을 때 일시정지가 열리는지 볼 때만


## 스팀 오버레이(Shift+Tab) — steam.gd 가 부른다. 열리면 창을 떠난 것과 같게: 판이 돌면 일시정지, 부활 카운트다운 멈춤.
func steam_overlay(active: bool) -> void:
	_app_away = active
	if active and G.running and not get_tree().paused and _pause_menu != null and not _pause_menu._open:
		_pause_menu._toggle()


## 안드로이드 뒤로가기(WM_GO_BACK_REQUEST) — 앱 종료 대신 일시정지 토글. (quit_on_go_back=false 필요)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:  # [감사 C17] 앱 강제 종료 시에도 이번 런 골드 보존
		# QA C8: 무료 부활 창이 떠 있을 때는 G.running 이 false 라 적립을 건너뛰었다. 적립 전 골드가 남아 있으면 적립한다
		#   (결과 화면까지 간 판은 이미 적립해서 run_gold 가 0 이다)
		if G.running or G.run_gold > 0:
			G.bank_run_gold()
		return
	# B12: 폰에서 내려놓을 때 판 골드를 따로 적어 두고, 돌아오면 지운다(그사이 꺼지면 다음에 켤 때 더해 준다)
	if what == NOTIFICATION_APPLICATION_PAUSED:
		G.park_run_gold()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		G.unpark_run_gold()
	# QA C8: 창을 떠나 있는 동안 부활 제안 10초가 흘러 놓쳤다 — 떠나 있는 동안은 멈춘다
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_app_away = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_app_away = false
	# 16차 4-5: Alt+Tab · 다른 창 · 폰 홈 버튼 — 판이 도는 중이면 일시정지를 연다(그사이 맞아 죽던 것).
	#   레벨업 · 상자 · 이미 열린 일시정지처럼 판이 멈춰 있으면 그대로 둔다. 검사 하니스(인자 있음)에서는 안 한다.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if G.running and not get_tree().paused and _pause_menu != null and not _pause_menu._open \
				and (OS.get_cmdline_user_args().is_empty() or focus_pause_test):
			_pause_menu._toggle()
		return
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	# 레벨업 강제 선택 중이면 무시
	if _levelup_root != null and _levelup_root.visible:
		return
	# 열린 서브 화면부터 닫기 (모바일 하드웨어 back = 각 화면 '뒤로'와 동일)
	if _char_select != null and _char_select.is_open():
		_char_select._on_back()
		return
	if _codex_screen != null and _codex_screen.is_open():
		_codex_screen._on_close()
		return
	if _settings != null and _settings.is_open():
		_settings._on_back()
		return
	if _meta_shop != null and _meta_shop.is_open():
		_meta_shop._on_close()
		return
	if _pause_menu == null:
		return
	if _pause_menu._open:
		_pause_menu._toggle()  # 이미 일시정지 → 재개
	elif G.running:
		_pause_menu._toggle()  # 게임 중 → 일시정지(빌드 확인 가능)
	# 그 외(메인 메뉴)에서는 무시 → 실수 종료 방지


## ★ 공유 캐시는 물리프레임 단위라 렌더프레임에서 읽으면 방금 낸 몹이 안 보인다 —
##   상한 판정에 쓰면 한 프레임에 상한을 넘겨 스폰한다. 이 함수는 초당 몇 번만 불리므로 실수로 센다.
func _enemy_count() -> int:
	return get_tree().get_node_count_in_group("enemy")   # 19차 3-2 ②: 세기만 하면 되는데 배열(몹 300칸)을 매번 새로 만들었다


## 스테이지 보스전이 진행 중인가 — 잡몹 유입 ×1/4 · 상한 60(잡몹은 조연).
## 무한 모드 30분 뒤는 여기가 아니라 _enemy_cap() 첫 줄(상한 0, 잡몹 없음)이 맡는다.
func _boss_fight_on() -> bool:
	return _stage_mode and _stage_boss != null and is_instance_valid(_stage_boss)


## 활성 몬스터 상한 — 시간이 갈수록 상승(후반=빽빽한 군집). PC 440 / 모바일 190.
## 스테이지 모드는 8분 완결이라 증가 속도 완만 (무한의 t×0.6 환산).
## 스테이지 보스전 중엔 상한 60 — 잡몹은 조연으로만 (스폰 배치가 40마리라 간격 완화만으론 벽이 됨).
## 무한 모드 30분 뒤(사신)는 상한 0 — 잡몹도 보스 소환도 없다. 성장을 끊고 그때까지 쌓은 빌드로만 붙는다(사용자 설계 10/12).
## ★ 예전엔 시작하자마자 상한이 130 이었다. 판 시작 60초면 화면이 이미 가득 차는데,
##   그 구간의 플레이어는 아직 카드가 없다. 예전엔 공격력이 폭주해서 그걸 뚫었지만
##   피해 스택을 정상화한 지금은 초반이 그대로 벽이 된다(실측: 쉬움에서 2분에 사망).
##   시작 상한을 낮추고 시간에 따라 더 가파르게 올린다 — 초반은 숨통, 후반은 예전보다 빽빽.
##   난이도가 '몹 수'로도 드러나게 배수를 건다(예전엔 스폰 간격에만 반영됐다).
func _enemy_cap() -> int:
	if _final_spawned and not _stage_mode:
		return 0
	if _boss_fight_on():
		return 45 if _mobile else 60
	var t_eff: float = G.pressure_t(G.PRESS_FLOOR_COUNT, INF) * (0.6 if _stage_mode else 1.0)
	# 시작 60 → 8분 140 (쉬움 기준). 예전은 시작부터 130 이라 빌드 없는 구간이 그대로 벽이었고,
	# 동시에 그 구간이 발열·프레임드랍이 제일 심한 구간이기도 했다(최초 리포트).
	# ★ 2026-09-06: 시작 85 는 **군중 처리 수단이 있던 시절**의 수다. 그때는 공통 카드에
	#   관통·튕기기·탄환수가 있어서 한 발이 여럿을 뚫었다. 그 셋을 무기 성장으로 옮긴 뒤
	#   (사용자 요구, 2026-09-05) 한 발이 한 놈만 때리는데 군중은 그대로였다.
	#   화력이 아니라 **처리량**이 모자란 상태다 — 실측에서 죽는 순간이 늘 "잡몹 90~120마리
	#   몸박"이었다. 시작을 낮추고 기울기를 완만하게 해서 초반 벽을 걷어낸다.
	#   후반 상한은 그대로 둔다 — 빌드가 갖춰진 뒤의 밀도는 이 게임의 재미다.
	# ★ 2026-09-15: 몹끼리 밀어내기(Enemy._separation)를 넣으면서 같은 머릿수가 더 아프다.
	#   예전엔 한 점에 포개져 있어서 무적시간 0.32초가 그 뭉치를 통째로 한 대로 처리했는데,
	#   이제 흩어져 있으니 차례로 닿는다 — 실제 접촉 횟수가 는다(실측: 사망 원인이
	#   적탄 → 잡몹 몸박으로 바뀜). 시작을 낮추고 기울기를 올려 **4분 지점은 그대로** 둔다.
	#   보이는 밀도는 오히려 늘어난다(흩어져서 화면을 더 넓게 덮으므로).
	var dm: float = G._dv([0.80, 0.95, 1.0, 1.12])  # 2026-10-06 쉬움·보통 몹 수 상향
	if _mobile:
		return int(min(44.0 + t_eff * 0.29, 190.0) * dm)
	return int(min(50.0 + t_eff * 0.50, 420.0) * dm)


## 융합 발동 임계 — 동적 상한의 92%(포화 근처에서만 융합, 군집을 늘 잡아먹지 않게).
func _merge_threshold() -> int:
	return int(float(_enemy_cap()) * 0.92)


## 어떤 보스든 마지막 보스로부터 이만큼(초)은 지나야 다음 보스 허용. 시간이 갈수록 넓어져 '이벤트'감 유지.
func _boss_min_gap() -> float:
	return clampf(BOSS_MIN_GAP + G.time_alive / 60.0 * BOSS_GAP_PER_MIN, BOSS_MIN_GAP, BOSS_GAP_MAX)


## 전역 보스 간격 게이트 — 웨이브/융합 모두 이 문을 통과해야 스폰(파일업 방지).
## 좌상단 보스 예고 줄. 융합 보스는 이미 자기 카운터(_overcap_t)가 있으므로 그걸 쓰고,
## 웨이브 중간보스는 _boss_eta 를 쓴다. 둘 다 없으면 줄 자체를 숨긴다.
func _update_boss_eta_label() -> void:
	if _lbl_bosseta == null or not is_instance_valid(_lbl_bosseta):
		return
	var left: float = -1.0
	var what: String = ""
	if _boss_eta > 0.0:
		left = _boss_eta
		what = _boss_eta_kind
	elif _overcap_t > 0.0 and _overcap_t < MERGE_HOLD:
		var rem: float = MERGE_HOLD - _overcap_t
		if rem <= BOSS_LEAD:
			left = rem
			what = "융합 보스"
	if left < 0.0:
		_lbl_bosseta.visible = false
		return
	_lbl_bosseta.visible = true
	_lbl_bosseta.text = I18n.t("%s  %d초") % [what, int(ceil(left))]
	# 마지막 3초는 깜빡여서 눈에 걸리게 한다
	_lbl_bosseta.modulate.a = 1.0 if left > 3.0 else (0.45 + 0.55 * absf(sin(G.time_alive * 9.0)))


func _boss_gate_open() -> bool:
	return G.time_alive - _last_boss_t >= _boss_min_gap()


## 웨이브 보스 요청 — 게이트가 열려 있으면 즉시, 아니면 열릴 때까지 예약(보스 유실 방지).
func _request_boss() -> void:
	if _boss_gate_open() and _overcap_t <= 0.0:   # 17-1: 융합이 차는 중이면 그게 먼저 — 「뭉치고 있다」 해 놓고 끊지 않게
		_arm_boss_eta("중간보스")     # 즉시 스폰이 아니라 10초 예고 뒤에 나온다
	else:
		_boss_pending = true


## 보스 예고 시작. 이미 세고 있으면 덮어쓰지 않는다(둘이 겹치면 짧은 쪽이 이긴다).
func _arm_boss_eta(kind: String) -> void:
	if _boss_eta > 0.0:
		return
	_boss_eta = BOSS_LEAD
	_boss_eta_kind = kind


func _spawn_wave() -> void:
	var remaining: int = _enemy_cap() - _enemy_count()
	if remaining <= 0:
		return
	# ★ 예전엔 한 틱에 최대 40마리를 그 자리에서 만들었다. 한 마리가 노드 10개 + 스프라이트 조회라
	#   대량 사망 직후엔 프레임이 눈에 띄게 튀었다. 이제는 예약만 하고 매 프레임 조금씩 낸다.
	# 한 번에 쏟는 양도 완만하게 (8초당 +1 → 12초당 +1). 상한과 함께 초반 벽을 낮춘다.
	_spawn_queue += mini(mini(1 + int(G.pressure_t(G.PRESS_FLOOR_COUNT, INF) / 12.0), 40), remaining)


## 예약된 스폰을 프레임당 조금씩 소화 — 스파이크를 여러 프레임에 펴서 체감 렉을 없앤다.
## 예약된 스폰을 조금씩 소화 — 스파이크를 여러 프레임에 펴서 체감 렉을 없앤다.
## ★ '프레임당 N마리'로 두면 30fps 절전에서 실제 스폰량이 절반이 된다(난이도가 설정에 따라 달라짐).
##   초당 마리수로 환산해 프레임레이트와 무관하게 같은 양이 나가게 한다.
func _drain_spawn_queue(delta: float) -> void:
	if _shadow_pack > 0:  # 그림자 무리 잔여분 — 상한과 무관하게 이번 프레임에 붙여 낸다
		_shadow_pack -= 1
		if _enemy_count() < _enemy_cap():
			_spawn_enemy(25)
	if _spawn_queue <= 0:
		_drain_acc = 0.0
		return
	var per_sec: float = 240.0 if _mobile else 420.0  # 초당 최대 소화량 (60fps 기준 4/7마리)
	_drain_acc += per_sec * delta
	var budget: int = int(_drain_acc)
	if budget <= 0:
		return
	_drain_acc -= float(budget)
	var room: int = _enemy_cap() - _enemy_count()
	var n: int = mini(mini(_spawn_queue, budget), maxi(0, room))
	_spawn_queue -= mini(_spawn_queue, budget)  # 자리가 없으면 예약도 같이 소멸(무한 적체 방지)
	for i in n:
		_spawn_enemy()


## 맵(테마)별 전용 몹풀 — kind: 0슬라임 1박쥐 2사이클롭스 3해골슈터 7고블린 8뱀
const _THEME_KINDS: Array = [
	[3, 3, 2, 1, 7, 0],  # 던전 — 언데드/해골 슈터 위주
	[1, 1, 3, 3, 7],     # 도서관 — 빠른 유령 무리 + 마법 슈터
	[8, 8, 0, 0, 1],     # 정원 — 뱀/슬라임(분열형)
	[7, 7, 2, 0, 8],     # 용암동굴 — 고블린(자폭형) + 사이클롭스
	[1, 1, 3, 8, 7],     # 천상 — 빠른 무리 + 슈터
	[1, 1, 18, 7, 0, 8, 3, 2],  # 저승길 — 망혼 · 까마귀 · 도깨비불 · 업덩이 · 뱀장어 · 귀졸 궁수 · 옥졸 창병 (Enemy.JEOSEUNG_ART)
]
## 특수 개체(S2) — 운빨디펜스 이식 몹은 몹풀에 안 섞고 '희귀 주입'으로만 등장.
## 테마별 대표 특수: 던전=원혼 / 도서관=원혼 / 정원=사냥게 / 용암=마그마골렘 / 천상=달빛사제
## 테마별 '이면 요괴' 주입 후보 — 기존 특수 몹과 함께 희귀하게만 튀어나온다.
## 몹풀에 섞지 않는 이유: 요괴는 화풍도 체급도 특별해야 만났을 때 사건이 된다.
const _THEME_SPECIAL: Array = [9, 9, 12, 11, 10, 11]   # 저승길 = 상여꾼(할덴 틀)
const _THEME_YOKAI: Array = [
	[16, 21, 25],   # 던전 — 어둑시니 · 두억시니 · 그림자 무리
	[17, 24, 25],   # 도서관 — 그슨대 · 강철 도깨비 · 그림자 무리
	[18, 22, 23],   # 정원 — 장산범 · 물귀신 · 백여우
	[19, 20, 24],   # 용암동굴 — 불가사리 · 야차 · 강철 도깨비
	[23, 22, 17],   # 천상계 — 백여우 · 물귀신 · 그슨대
	[16, 20, 22, 17, 19, 21],   # 저승길 — 우두 · 마면 · 손각시 · 아귀 · 명부 두루마리 · 쌍둥이 차사
]


func _pick_kind() -> int:
	var t: float = G.time_alive
	# 특수 개체 주입 (75초 이후, 스폰의 ~5→8%): 테마 특수 + 어디서나 낮은 확률 달빛 사제
	if t >= 75.0:
		var roll: float = randf()
		var sp: float = 0.05 + minf(0.03, t / 600.0 * 0.03)
		if roll < sp:
			return int(_THEME_SPECIAL[_cur_theme % _THEME_SPECIAL.size()])
		if roll < sp + 0.018:
			return 10  # 달빛 사제는 모든 테마에 아주 낮은 확률로 (지원형 특수)
		# 이면 요괴 — 3분 이후부터, 테마별 3종 중 하나. 판이 무르익을수록 자주 나온다.
		if t >= 180.0 and roll < sp + 0.018 + 0.028 + minf(0.03, (t - 180.0) / 900.0 * 0.03):
			var yk: Array = _THEME_YOKAI[_cur_theme % _THEME_YOKAI.size()]
			return int(yk[randi() % yk.size()])
	var pool: Array = _THEME_KINDS[_cur_theme % _THEME_KINDS.size()]
	var k: int = int(pool[randi() % pool.size()])
	# 초반엔 슈터(3)/탱크(2) 미출현 — 기본 근접으로 대체
	if k == 3 and t < G.diff_shooter_start():
		return 1
	if k == 2 and t < G.diff_shooter_start() + 20.0:
		return 0
	return k


func _spawn_enemy(kind: int = -1) -> void:
	var e := Enemy.new()
	e.kind = kind if kind >= 0 else _pick_kind()
	# 맵 특화 변종 (add_child 전에 설정 → _ready가 반영)
	if _cur_theme == 2 and (e.kind == 0 or e.kind == 8) and randf() < 0.5:
		e.split_gen = 1       # 정원: 분열형
	elif _cur_theme == 3 and e.kind == 7 and randf() < 0.5:
		e.is_bomber = true    # 용암: 자폭형
	if e.kind == 21:          # 두억시니: 머리가 여럿이라 죽으면 갈라진다
		e.split_gen = 1
	elif e.kind == 25 and kind < 0:  # 그림자 무리: 혼자 오는 법이 없다 — 같은 자리에 두 마리 더
		_shadow_pack = 2
	var base := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	# [감사 C26] 벽/모서리 클램프로 플레이어 몸 위에 스폰되던 것 — 최소거리 300 보장 (실패 시 중앙 방향)
	var pos: Vector2 = base
	for attempt in 5:
		var ang: float = randf() * TAU
		pos = (base + Vector2(cos(ang), sin(ang)) * 660.0).clamp(Vector2(-ARENA, -ARENA), Vector2(ARENA, ARENA))
		if pos.distance_to(base) >= 300.0:
			break
	if pos.distance_to(base) < 300.0:
		pos = (base + (Vector2.ZERO - base).normalized() * 660.0).clamp(Vector2(-ARENA, -ARENA), Vector2(ARENA, ARENA))
	e.global_position = pos
	add_child(e)


# ──────────────────── 11/7 무한 패턴 이벤트 ────────────────────
## 무한에서 정해진 간격마다 짜인 패턴이 온다 — 포위진(고리로 나타나 조여 옴) · 요괴 행렬(한 줄이 화면을 가로질러 돌진) ·
## 정예 무리. 난이도가 높을수록 자주 · 많이. 사용자 결정(11/7): 「몹의 패턴이나 강력함이 더 올라가야」.
## 몹 상한은 넘을 수 있다(이벤트 몫만큼) — 대신 한 번에 나오는 수를 난이도 표로 묶어 프레임을 지킨다.
const EVENT_GAP: Array = [240.0, 200.0, 170.0, 150.0, 120.0]   # 이벤트 사이 초(쉬움 · 보통 · 어려움 · 매우어려움 · 지옥)
const EVENT_FIRST: float = 180.0
const EVENT_KINDS: Array = ["ring", "march", "elites"]
var _event_next: float = INF
var _event_i: int = 0


func _events_reset() -> void:
	_event_next = EVENT_FIRST
	_event_i = randi() % EVENT_KINDS.size()
	_sess_t = 0.0


var _sess_t: float = 0.0


func _session_mark() -> void:
	var p := G.player as Player
	var wl: PackedStringArray = []
	for k: String in _upgrade_counts:
		wl.append("%s%d" % [k, int(_upgrade_counts[k])])
	G.session_mark({
		"mode": G.run_mode, "diff": G.difficulty, "karma": G.run_karma, "stage": G.stage_sel,
		"hero": String(_last_char.get("id", "")), "t": int(G.time_alive), "lv": G.level, "kills": G.kills,
		"mobs": _enemy_count(), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"mem_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"vram_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"fps": int(Engine.get_frames_per_second()), "ebullets": EnemyBullet.live,
		"final": _final_spawned, "fusion_live": _fusion_live,
		"hp": int(p.hp) if is_instance_valid(p) else -1, "cards": " ".join(wl),
	})


func _update_events(_delta: float) -> void:
	if G.time_alive < _event_next or _fusion_live or not is_instance_valid(G.player):
		return
	_event_next = G.time_alive + G._dv(EVENT_GAP)
	var kind: String = String(EVENT_KINDS[_event_i % EVENT_KINDS.size()])
	_event_i += 1
	var base: Vector2 = (G.player as Node2D).global_position
	var pool: Array = _THEME_KINDS[_cur_theme % _THEME_KINDS.size()]
	match kind:
		"ring":
			var n: int = int(G._dv([14, 18, 22, 26, 32]))
			_wave_banner(I18n.t("포위진"), Color("ff8a3c"))
			for i in n:
				var a: float = TAU * float(i) / float(n)
				_event_spawn(int(pool[randi() % pool.size()]), base + Vector2(cos(a), sin(a)) * 560.0, false, Vector2.ZERO)
		"march":
			var n2: int = int(G._dv([10, 14, 18, 22, 28]))
			var side: Vector2 = Vector2.from_angle(randf() * TAU)
			var across: Vector2 = side.orthogonal()
			_wave_banner(I18n.t("요괴 행렬"), Color("ffc14a"))
			for i in n2:
				var off: float = (float(i) - float(n2 - 1) * 0.5) * 46.0
				var k2: int = int(pool[randi() % pool.size()])
				if k2 == 3:
					k2 = 1   # 슈터는 줄을 못 지킨다 — 빠른 근접으로
				_event_spawn(k2, base + side * 760.0 + across * off, false, -side)
		"elites":
			var n3: int = int(G._dv([2, 3, 3, 4, 5]))
			_wave_banner(I18n.t("정예 무리"), Color("ffd54a"))
			for i in n3:
				var a3: float = randf() * TAU
				_event_spawn([0, 2, 7][randi() % 3], base + Vector2(cos(a3), sin(a3)) * 600.0, true, Vector2.ZERO)
	G.sfx("hurt", 0.55, -4.0)
	G.add_shake(0.2)


func _event_spawn(kind: int, pos: Vector2, elite: bool, rush: Vector2) -> void:
	var e := Enemy.new()
	e.kind = kind
	e.force_elite = elite
	e.rush_dir = rush
	e.global_position = pos.clamp(Vector2(-ARENA + 40.0, -ARENA + 40.0), Vector2(ARENA - 40.0, ARENA - 40.0))
	add_child(e)


func _spawn_boss() -> void:
	if _enemy_count() >= _enemy_cap() + 6:
		return
	var ang: float = randf() * TAU
	var base := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	var e := Enemy.new()
	# 웨이브 보스 로테이션 (S1): 5분 이후 해골왕/유령군주/박쥐여왕/슬라임킹 순환 — 매번 다른 패턴.
	# 스테이지 모드에선 그 스테이지의 '최종 보스'는 중간보스로 안 나옴 (클리어 판정 혼동 방지).
	var pool: Array = [4, 13, 14, 15]
	var jeoseung: bool = _cur_theme == 5   # 저승길 중간보스는 판관(시울 틀) 하나
	if jeoseung:
		pool = [13]
	# 이면 보스 3종은 판이 무르익은 뒤(9분+)부터 중간보스 풀에 합류한다 —
	# 요괴가 나오기 시작한 판에서만 만나야 '이면이 열렸다'는 순서가 읽힌다.
	# ★ 예전 기준(540초)은 스테이지 모드(480초 완결)를 넘어서 스테이지에서는 영원히 안 나왔다.
	#   도감·해금이 무한 모드 전용이 되므로 모드별로 갈라 잡는다.
	if G.time_alive >= (240.0 if _stage_mode else 540.0) and not jeoseung:
		pool.append_array([26, 27, 28])
	if _stage_mode:
		pool.erase(int(STAGE_BOSS[clampi(G.stage_sel, 0, STAGE_BOSS.size() - 1)]))
	e.kind = int(pool[randi() % pool.size()]) if (G.time_alive >= 300.0 or _stage_mode) else 4
	e.global_position = (base + Vector2(cos(ang), sin(ang)) * 560.0).clamp(Vector2(-ARENA + 80.0, -ARENA + 80.0), Vector2(ARENA - 80.0, ARENA - 80.0))
	_last_boss_t = G.time_alive  # 전역 간격 게이트 갱신(실제 스폰 시각)
	add_child(e)
	_boss_cutin(e.art, FxLib.word_sheet("w_midboss"), "WAVE %d" % _wave, Color("ffa63c"), 1.0)


func _advance_wave() -> void:
	_wave += 1
	G.wave = _wave
	if _wave % BOSS_EVERY == 0 and not _final_spawned:  # 최종 결전(스테이지 보스 · 무한 최종 보스) 중엔 중간보스 보류
		# ★ 스테이지 보스 경고와 색·기호가 같아서 "보스 스테이지인 줄 알았다"가 나왔다.
		#   중간보스는 주황 · '중간보스'라고 명시, 스테이지/최종 보스만 붉은 ⚠ 를 쓴다.
		_wave_banner(I18n.t("WAVE %d · 중간보스 출현") % _wave, Color("ffa63c"),
			["w_wave", "#%d" % _wave, FxLib.word_sheet("w_midboss")])
		_request_boss()
	else:
		_wave_banner("WAVE %d" % _wave, Color("ffd54a"), ["w_wave", "#%d" % _wave])


## 융합 보스: 몬스터가 상한 근처로 일정시간 유지되면 전부 합쳐 하나의 보스로.
func _update_fusion(delta: float) -> void:
	if _fusion_live:
		if not is_instance_valid(_fusion_boss) or (_fusion_boss as Enemy)._dead:
			_on_fusion_defeated()
		elif G.time_alive > _fusion_deadline:
			_on_fusion_timeout()
		else:
			_update_fusion_bar()
		return
	var possible: bool = _fusion_possible()
	if not possible:
		# 17-1: 보스 간격 · 중간보스 대기 · 스테이지 보스 임박으로 막혔으면 조용히 접는다(몹이 흩어진 게 아니니 「흩어졌다」도 안 띄운다)
		_overcap_t = 0.0
		_overcap_warned = false
	elif _enemy_count() >= _merge_threshold():
		var was: float = _overcap_t
		_overcap_t += delta
		# ★ 이 20초 카운터가 지금까지 **화면에 한 픽셀도 안 나왔다.** 몹이 쌓이면 보스가
		#   튀어나오는데 예고가 0초였고, 스폰 위치가 머리 위 480px 라 화면 밖에서 시작한다.
		#   플레이어는 뭐가 왜 왔는지 알 수 없었다(2026-09-05 지적).
		#   몰리는 중임을 먼저 알리고, 임박하면 한 번 더 못 박는다.
		if was < FUSION_WARN_EARLY and _overcap_t >= FUSION_WARN_EARLY:
			_wave_banner("몰려든다", Color("ffc14a"))
			_overcap_warned = true
			G.sfx("hurt", 0.5, -6.0)
		if was < MERGE_HOLD - FUSION_WARN_LEAD and _overcap_t >= MERGE_HOLD - FUSION_WARN_LEAD:
			_wave_banner("무언가 뭉치고 있다", Color("ff8a3c"))
			G.sfx("hurt", 0.42, -3.0)
			G.add_shake(0.25)      # 등장 때(1.0)와 확실히 차등을 둔다
		if _overcap_t >= MERGE_HOLD:
			_merge_into_boss()
			_update_swarm_gauge()
			return
	else:
		# ★ 예고해 놓고 안 나오면 늑대소년이 되니 풀렸다고 알리는 건 맞다. 그런데 이 줄이
		#   **매 프레임** 돌았다 — 몹이 줄어드는 20여 초 동안 초당 60번씩 배너가 쌓였다.
		#   "자꾸 흩어진다 문구가 계속 뜨면서 정신사납다"(2026-09-07 지적).
		#   경고를 실제로 띄웠던 판에서, 임계 아래로 **처음 내려오는 그 한 번만** 알린다.
		if _overcap_warned and _overcap_t < FUSION_WARN_EARLY:
			_wave_banner("흩어졌다", Color("9fe8ff"))
			_overcap_warned = false
		_overcap_t = maxf(0.0, _overcap_t - delta * 0.5)
	_update_swarm_gauge()


## 지금 몹이 충분히 몰리면 실제로 융합 보스가 나올 수 있는가 — 게이지 표시와 융합 판정이 같은 조건을 본다.
## ★ 17-1: 게이지는 몹 수만 보고 70% 까지 찼는데 융합은 「직전 보스 뒤 90~150초(_boss_gate_open)」도 요구했다.
##   스테이지 판에선 첫 융합 → 중간보스가 그 문을 다시 닫아서 두 번째 게이지는 8분 보스 전까지 절대 안 터졌다
##   (사용자 10/11 「융합 게이지가 또 나오는데 절대 융합 보스로 안 만들어진다」).
func _fusion_possible() -> bool:
	if _fusion_boss != null:
		return false
	if G.time_alive < FUSION_MIN_TIME or G.time_alive < _fusion_lockout:
		return false
	if not _boss_gate_open() or _boss_eta > 0.0:
		return false   # 중간보스 예고 중 — 그 사이엔 융합이 끝까지 못 찬다(이미 차기 시작한 융합은 중간보스가 기다린다, _request_boss)
	if _stage_mode and G.time_alive + MERGE_HOLD + FUSION_FIGHT_MIN >= G.STAGE_LEN:
		return false   # 융합체가 나와도 싸울 틈 없이 스테이지 보스가 지운다(17-2 봇: 8분 직전 융합이 그대로 사라짐)
	return true


## 몰려드는 요괴 게이지: 몹 수가 융합 기준에 가까워질수록 70% 까지, 기준 위에서 버틴 시간만큼 나머지 30% 가 찬다.
## 가득 차는 순간이 융합(_overcap_t >= MERGE_HOLD)이다. 숫자 없이 색과 맥동으로만 — 융합이 불가능한 동안(3분 전 · 재발동 대기 ·
## 보스 간격 · 중간보스 대기 · 스테이지 보스 임박 · 보스 중)엔 숨긴다.
func _update_swarm_gauge() -> void:
	var can: bool = _fusion_possible()
	var g: float = 0.0
	if can:
		g = 0.7 * clampf(float(_enemy_count()) / maxf(1.0, float(_merge_threshold())), 0.0, 1.0) \
			+ 0.3 * clampf(_overcap_t / MERGE_HOLD, 0.0, 1.0)
	_swarm_g = lerpf(_swarm_g, g, 0.15)   # 몹 수가 프레임마다 출렁여도 게이지는 부드럽게
	var show: bool = can and _swarm_g >= 0.35
	if _swarm_root.visible != show:
		_swarm_root.visible = show
	if not show:
		return
	_swarm_fill.size.x = ((_boss_bw - 12.0) if _parts_hud else (SWARM_W - 4.0)) * clampf(_swarm_g, 0.0, 1.0)
	var col: Color = Color("ffc14a") if _swarm_g < 0.7 else (Color("ff8a3c") if _swarm_g < 0.9 else Color("ff3860"))
	if _parts_hud:
		_swarm_fill.modulate = col       # 채움 그림(fill_xp)에 색을 곱한다 — 바탕 ColorRect 는 투명
	else:
		_swarm_fill.color = col
	_swarm_lbl.add_theme_color_override("font_color", col)
	_swarm_lbl.text = I18n.t("요괴가 뭉치고 있다") if _swarm_g >= 0.9 else I18n.t("몰려드는 요괴")
	# 거의 찼으면 맥동 — '곧 터진다'
	_swarm_root.modulate.a = (0.75 + 0.25 * sin(float(Time.get_ticks_msec()) * 0.012)) if _swarm_g >= 0.85 else 1.0


func _merge_into_boss() -> void:
	_overcap_t = 0.0
	_last_boss_t = G.time_alive  # 전역 간격 게이트 갱신(융합 보스 등장)
	var total: float = 0.0
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e == null or not is_instance_valid(e):
			continue
		if e._is_boss:
			continue  # 기존 보스는 흡수하지 않음
		total += maxf(0.0, e.hp)
		e.queue_free()
	var boss := Enemy.new()
	boss.kind = 6
	var base := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	boss.global_position = (base + Vector2(0, -480.0)).clamp(Vector2(-ARENA + 90.0, -ARENA + 90.0), Vector2(ARENA - 90.0, ARENA - 90.0))
	add_child(boss)
	# 흡수량 기반이되, '레이드 보스'답게 웨이브 중간보스보다 단단하게 (M38)
	# [감사 C12] stage_power 누락으로 상위 스테이지에서 융합이 물몸이던 것 보정 + 성장 상한 동일 적용
	# 17-1: 기준(G.boss_ref_hp, meta_power 포함)의 1.2~1.5 배 — 중간보스(≤1.3) 위, 스테이지 보스(2.0) 아래.
	#   예전 1.35~2.2(meta 없음)는 상한이 스테이지 보스 하한(1.25)보다 컸다.
	boss.hp = _fusion_hp(total)
	boss.max_hp = boss.hp
	_fusion_boss = boss
	_fusion_live = true
	_fusion_max_hp = boss.hp
	_fusion_deadline = G.time_alive + FUSION_DEADLINE
	_fusion_root.visible = true
	_update_fusion_bar()
	if not _boss_cutin(6, FxLib.word_sheet("w_boss"), I18n.t("융합 보스 · 도망가기 전에 처치"), Color("ff3860")):
		_wave_banner(I18n.t("융합 보스 출현! 도망가기 전에 처치"), Color("ff3860"),
			[FxLib.word_sheet("w_boss")], I18n.t("융합 보스 · 도망가기 전에 처치"))
	G.add_shake(1.0)
	G.sfx("levelup", 0.5)


## 17-1: 융합 · 스테이지 보스 체력 식 — 스폰과 --bosshp 검사가 같은 함수를 부른다(식을 복제하면 검사가 조용히 거짓말을 한다).
func _fusion_hp(total: float) -> float:
	var ref: float = G.boss_ref_hp()
	return clampf(total, ref * G.BOSS_FUSION_MULT.x, ref * G.BOSS_FUSION_MULT.y)


func _stage_boss_hp() -> float:
	# 17-2: 예전 하한 7000×1.5^스테이지 는 스테이지 6 에서 7.6 배라 보스만 계속 커졌다 — 기준 하나로.
	return G.boss_ref_hp() * G.BOSS_STAGE_MULT


func _update_fusion_bar() -> void:
	if _fusion_boss == null or not is_instance_valid(_fusion_boss):
		return
	var e := _fusion_boss as Enemy
	if e._dead or e.hp <= 0.0:  # 처치 즉시 바/타이머 숨김 (사망 연출 중 잔존 방지, M39)
		_on_fusion_defeated()
		return
	var ratio: float = clampf(e.hp / maxf(1.0, _fusion_max_hp), 0.0, 1.0)
	_fusion_fill.size.x = (_boss_bw - 20.0 if _parts_hud else 696.0) * ratio
	# 남은 시간은 숫자 대신 얇은 도망 게이지로(줄어들수록 붉게). 0 이 되면 도망간다.
	var left: float = clampf((_fusion_deadline - G.time_alive) / FUSION_DEADLINE, 0.0, 1.0)
	_fusion_tfill.size.x = (_boss_bw - 20.0 if _parts_hud else 696.0) * left
	_fusion_tfill.color = Color(1, 1, 1, 0.9).lerp(Color("ff3860"), 1.0 - left)
	_fusion_lbl.text = _boss_name(6) if _parts_hud else I18n.t("융합 보스   %d%%") % int(ratio * 100.0)


func _on_fusion_defeated() -> void:
	_fusion_boss = null
	_fusion_live = false
	_overcap_t = 0.0
	_fusion_lockout = G.time_alive + FUSION_LOCKOUT
	_fusion_root.visible = false
	G.add_xp(45)  # 흡수된 무리 몫 보상 → 성장 정체 방지 (골드는 금화 다발 드랍)
	G.add_shake(0.7)
	_wave_banner("융합 보스 처치! 금화 다발 + 경험치", Color("7dff9b"))


func _on_fusion_timeout() -> void:
	if is_instance_valid(_fusion_boss):
		(_fusion_boss as Node).queue_free()
	_fusion_boss = null
	_fusion_live = false
	_overcap_t = 0.0
	_fusion_lockout = G.time_alive + FUSION_LOCKOUT
	_fusion_root.visible = false
	# 17-2: -20%(최대 -50%) → -10%(최대 -30%). 봇 시험에서 「열릴 때마다 융합」 판이 천상계 클리어 55%(융합 없음 85%)였다 —
	#   놓칠 때마다 깎이는 공격력이 쌓여 판 전체가 무너졌다. 놓친 대가는 남기되 판을 망치지는 않게.
	G.run_penalty = minf(0.3, G.run_penalty + 0.1)
	_wave_banner(I18n.t("융합 보스가 도망쳤다… 공격력 -%d%% (이번 판)") % int(G.run_penalty * 100.0), Color("ff5a5a"))


## 무한 모드 30분 지점의 최종 보스 = 사신.
## ★ 설계(사용자 10/12): 뱀파이어 서바이버의 30분 사신처럼 사실상 못 잡는 보스다. 30분 뒤로는 잡몹이 안 나와
##   성장이 끊기고, 보스는 플레이어보다 빠르고 몇 대면 죽인다(Enemy.reaper). 정말 사기적인 조합이나 처음부터
##   쌓은 빌드여야 겨우 잡거나 버틴다. 잡으면 완주(도전과제 「무한의 끝」).
## ★ 체력은 레벨(=빌드 규모)에만 비례하고 난이도 배수는 안 건다. 높은 난이도는 30분까지 키운 조합이 이미 약해서
##   (봇 레벨당 화력 쉬움 > 보통 > 어려움 > 매우어려움) 배수까지 얹으면 매우어려움은 글자 그대로 불가능해진다.
## ★ 숫자(10/12, 봇 80판 --finalhp=1e12 로 사신 하나에 2분 쏜 화력): 난이도마다 가장 센 조합이 쉬지 않고 쏘기만 해도
##   쉬움 142초 · 보통 388초 · 어려움 204초 · 매우어려움 1,520초, 가운데 조합은 쉬움에서도 1시간이 넘는다.
##   그 사이 사신이 늘고 빨라지고 한 방이 되니, 딜로 찍는 길은 사실상 없고 피하는 실력과 조합 운이 같이 있어야 잡는다.
## ★ 17-2 셋째(73bbff86)에서 이 보스를 잡기 쉬운 무대로 바꿨던 것은 설계와 반대라 되돌렸다.
const FINAL_HP_PER_LV: float = 400000.0
const FINAL_HP_MIN: float = 12000000.0   # 레벨 30 몫
## 1분마다 사신이 하나 더 온다(뱀파이어 서바이버처럼). 완주는 첫 사신(체력 막대)을 쓰러뜨렸을 때.
const REAPER_ADD_SEC: float = 60.0
const REAPER_MAX: int = 8

func _spawn_final_boss() -> void:
	if not _boss_cutin(Enemy.art_for(5), FxLib.word_sheet("w_boss"), I18n.t("최종 보스 · 쓰러뜨리면 완주"), Color("ff2d55")):
		_wave_banner("최종 보스 출현! 쓰러뜨리면 완주", Color("ff2d55"),
			[FxLib.word_sheet("w_boss")], I18n.t("최종 보스 · 쓰러뜨리면 완주"))
	G.add_shake(1.0)
	_last_boss_t = G.time_alive  # 최종 보스도 게이트 갱신 → 직후 다른 보스 파일업 차단
	_clear_stage_for_final()
	_clear_obstacles()  # 사신 앞엔 숨을 곳이 없다 — 장애물로 막아 두고 쏘는 길을 없앤다(사용자 10/12)
	var base := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	var e := Enemy.new()
	e.kind = 5
	e.is_stage_boss = true  # 근접 압박형 AI + 전용 체급 연출
	e.reaper = true         # 사신: 플레이어보다 빠르고 몇 대면 죽인다
	e.global_position = (base + Vector2(0, -520.0)).clamp(Vector2(-ARENA + 90.0, -ARENA + 90.0), Vector2(ARENA - 90.0, ARENA - 90.0))
	add_child(e)
	e.hp = maxf(FINAL_HP_MIN, FINAL_HP_PER_LV * float(G.level)) * G.karma_boss_hp_mult()   # 11/7 업보 7단계
	if G.harness_final_hp > 0.0:
		e.hp = G.harness_final_hp  # 검사(--finalhp): 안 죽는 체력으로 10분 동안 넣는 화력을 잰다
	e.max_hp = e.hp
	_final_boss = e
	G.reaper_t0 = G.time_alive
	_reaper_next = G.time_alive + REAPER_ADD_SEC
	G.begin_boss_fight()
	_sboss_lbl.text = _boss_name(e.art)
	_sboss_root.visible = true


## 1분마다 오는 사신 하나 더 — 플레이어 둘레 아무 쪽에서. 체력은 첫 사신과 같다(잡아도 완주는 아니다).
func _spawn_reaper_extra() -> void:
	var base := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	var a: float = randf() * TAU
	var e := Enemy.new()
	e.kind = 5
	e.is_stage_boss = true
	e.reaper = true
	e.global_position = (base + Vector2(cos(a), sin(a)) * 560.0).clamp(Vector2(-ARENA + 90.0, -ARENA + 90.0), Vector2(ARENA - 90.0, ARENA - 90.0))
	add_child(e)
	e.hp = _final_boss.max_hp if _final_boss != null and is_instance_valid(_final_boss) else e.hp
	e.max_hp = e.hp
	_reapers.append(e)
	G.add_shake(0.6)
	_wave_banner(I18n.t("최종 보스가 하나 더 나타났다"), Color("ff2d55"))


## 상단 보스 바 배치. 살아 있는 것만 위에서부터 채운다 —
## 중간보스 혼자 나왔는데 셋째 줄에 뜨면 바가 화면 한복판까지 내려온다.
## 순서는 사건의 크기 순: 스테이지/최종 > 융합 > 중간.
const WBOSS_W: float = 470.0  # 중간보스 바 폭 — 넓은 바(704)와 한눈에 급이 갈리게

## 14차 2절 6: 너비 300 · 왼쪽 얼굴 칸 · 이름은 막대 밑 가운데 · % 없음(목업 hud.png). 타이머 · 웨이브 바로 밑부터.
## ★ 지시서의 300 · 28 은 그림 px 다. 처음엔 HUD 논리 좌표에 300 을 그대로 넣어 1920 화면에서 450 이 됐고,
##   HUD 를 목업 배수(×2)로 맞춘 뒤엔 300 이 되어 목업(600)의 반이었다. 그림 px × 2 로 둔다.
const BOSS_BAR_W: float = 600.0
const BOSS_FACE: int = 48            # 얼굴 그림(portrait_big 96 의 정확히 반) + 칸 테 = 56
var _boss_faces: Dictionary = {}     # root -> TextureRect(얼굴 칸)

func _boss_face_tex(kind: int) -> Texture2D:
	var cf: String = CharForge.enemy_id(kind)
	if cf == "" or not CharForge.has_anim(cf, "portrait_big"):
		return null
	var key: String = "face_%d" % kind
	if _boss_faces.has(key):
		return _boss_faces[key]
	var img: Image = (CharForge.frame_tex(cf, "portrait_big") as Texture2D).get_image()
	if img == null:
		return null
	# portrait_big(96) 은 얼굴 클로즈업 한 장이다 — 정확히 반(48)으로. ★ 가운데 48 칸만 잘랐더니 눈 하나와 두건만 남아
	#   누구인지 안 읽혔다. 반으로 줄이면 픽셀 넷이 하나가 될 뿐 격자는 그대로다.
	if img.get_width() == BOSS_FACE * 2 and img.get_height() == BOSS_FACE * 2:
		img.resize(BOSS_FACE, BOSS_FACE, Image.INTERPOLATE_NEAREST)
	else:
		var cx: int = img.get_width() / 2 - BOSS_FACE / 2
		img = img.get_region(Rect2i(clampi(cx, 0, maxi(0, img.get_width() - BOSS_FACE)), 0, BOSS_FACE, BOSS_FACE))
	var t := ImageTexture.create_from_image(img)
	_boss_faces[key] = t
	return t


func _boss_face(root: Control, kind: int, pos: Vector2) -> void:
	var holder: PanelContainer = root.get_node_or_null("Face") as PanelContainer
	if holder == null:
		holder = PanelContainer.new()
		holder.name = "Face"
		var cb: StyleBoxTexture = UiParts.cell_box(false, 2.0)
		if cb != null:
			holder.add_theme_stylebox_override("panel", cb)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := TextureRect.new()
		tr.name = "T"
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
		root.add_child(holder)
	(holder.get_node("T") as TextureRect).texture = _boss_face_tex(kind)
	holder.position = pos
	holder.visible = (holder.get_node("T") as TextureRect).texture != null


var _boss_bw: float = BOSS_BAR_W   # 지금 보스 막대 폭(11/5 — HUD 폭에 맞춰 줄어든다)


## 11/5 스팀 피드백 2: 창이 작으면 HUD 배수가 커져(1280×720 창 = ×4/3) HUD 폭이 960 뿐이라, 600 막대 + 얼굴 칸이
##   왼쪽 위 무기 · 장신구 칸을 덮었다. 왼쪽 칸(약 340) · 얼굴(64) 과 오른쪽 처치판(약 240) 사이에 들어가게 한다.
##   가운데(타이머 밑)에 둘 수 있으면 가운데, 안 되면 그 사이 칸에 맞춘다. 돌려주는 값 = (막대 왼쪽 x, 폭).
func _boss_bar_fit(w: float) -> Vector2:
	var left: float = 340.0 + 64.0 + 12.0
	var right: float = w - 240.0 - 12.0
	var bw: float = minf(BOSS_BAR_W, minf(w - 2.0 * left, 2.0 * (right - w * 0.5)))
	if bw >= 360.0:
		return Vector2(w * 0.5 - bw * 0.5, bw)
	bw = clampf(right - left, 260.0, BOSS_BAR_W)
	return Vector2(clampf(w * 0.5 - bw * 0.5, left, maxf(left, right - bw)), bw)


func _layout_boss_bars(w: float) -> void:
	if _parts_hud:
		var y2: float = 116.0   # 타이머 · 웨이브 줄 밑(목업 118)
		var fit: Vector2 = _boss_bar_fit(w)   # 목업: 막대가 화면 가운데, 얼굴 칸은 그 왼쪽 밖에 걸친다
		var bx: float = fit.x
		_boss_bw = fit.y
		var first_lbl: Label = null
		for r: Array in [[_sboss_root, _sboss_lbl, _sboss_bg, _sboss_fill], [_fusion_root, _fusion_lbl, _fusion_bg, _fusion_fill],
				[_wboss_root, _wboss_lbl, _wboss_bg, _wboss_fill]]:
			var root: Control = r[0]
			if not root.visible:
				continue
			var lb: Label = r[1]
			var bg: ColorRect = r[2]
			var fl: ColorRect = r[3]
			bg.position = Vector2(bx, y2)
			bg.size = Vector2(_boss_bw, 20.0)
			fl.position = Vector2(bx + 10.0, y2 + 6.0)
			fl.size.y = 8.0
			lb.position = Vector2(bx, y2 + 20.0)
			lb.size = Vector2(_boss_bw, 20.0)
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if first_lbl == null:
				first_lbl = lb
			var kd: int = 6
			if root == _sboss_root:
				var fb2: Enemy = _stage_boss if _stage_mode else _final_boss
				kd = fb2.art if fb2 != null and is_instance_valid(fb2) else Enemy.art_for(5)
			elif root == _wboss_root:
				var wb2: Enemy = _wave_boss_target()
				kd = wb2.art if wb2 != null else 4
			_boss_face(root, kd, Vector2(bx - 64.0, y2 - 18.0))
			if root == _fusion_root:
				_fusion_tbg.position = Vector2(bx + 10.0, y2 + 42.0)
				_fusion_tbg.size = Vector2(_boss_bw - 20.0, 4.0)
				_fusion_tfill.position = Vector2(bx + 10.0, y2 + 42.0)
				y2 += 10.0
			y2 += 70.0          # 얼굴 칸(56) + 이름 줄이 다음 막대와 안 겹치게
		var any_boss: bool = y2 > 116.0
		# ★ 15차 6절 3: 시계 · 웨이브 · 보스 막대 · 이벤트 막대가 위 가운데에 몰려 몹을 가렸다.
		#   보스 막대가 있으면 이벤트 막대는 접고, 첫 보스 이름 줄 오른쪽 끝에 작은 글자로만 둔다.
		_swarm_bg.visible = not any_boss
		_swarm_fill.visible = not any_boss
		if _swarm_root.visible and any_boss:
			# 11/5: 막대가 좁아지면(작은 창) 가운데 정렬 보스 이름과 오른쪽 이벤트 글자가 겹쳤다 —
			#   이름은 왼쪽 · 이벤트는 오른쪽에 붙이고, 그래도 둘이 한 줄에 안 들어가면 이벤트 글자를 한 줄 내린다.
			var sy: float = 116.0 + 20.0
			if first_lbl != null:
				first_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				var f1: Font = first_lbl.get_theme_font("font")
				var f2: Font = _swarm_lbl.get_theme_font("font")
				var w1: float = f1.get_string_size(first_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, first_lbl.get_theme_font_size("font_size")).x if f1 != null else 0.0
				var w2: float = f2.get_string_size(_swarm_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _swarm_lbl.get_theme_font_size("font_size")).x if f2 != null else 0.0
				if w1 + w2 + 24.0 > _boss_bw:
					sy += 22.0
			_swarm_lbl.position = Vector2(bx, sy)
			_swarm_lbl.size = Vector2(_boss_bw, 20.0)
			_swarm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		elif _swarm_root.visible:
			# 14차: 몰려드는 요괴 게이지도 보스 막대와 같은 폭(300)·같은 틀 — 900 폭 옛 막대가 화면 가운데를 가렸다
			var sx: float = bx
			_swarm_bg.position = Vector2(sx, y2)
			_swarm_bg.size = Vector2(_boss_bw, 16.0)
			_swarm_fill.position = Vector2(sx + 6.0, y2 + 6.0)
			_swarm_fill.size.y = 4.0
			_swarm_lbl.position = Vector2(sx, y2 + 16.0)
			_swarm_lbl.size = Vector2(_boss_bw, 20.0)
			_swarm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			y2 += 40.0
		# 14차 2절 8: 「이름표 · 막대와 겹치는 자리에는 숫자를 띄우지 않는다」 — 위 띠(경험치 · 칸 · 타이머 · 보스 막대)
		#   아래 끝을 화면 좌표로 알려 준다. DamageNumber 가 이 위쪽에서는 숫자를 안 띄운다.
		G.num_block_y = _hud_layer.position.y + maxf(y2, 130.0) * _hud_layer.scale.y
		return
	var y: float = 104.0   # 13차: 맨 위는 경험치 막대 · 그 밑 가운데는 타이머 — 보스 막대는 그 아래부터
	if _sboss_root.visible:
		_place_boss_bar(_sboss_lbl, _sboss_bg, _sboss_fill, w, y, 704.0, 32.0)
		y += 66.0
	if _fusion_root.visible:
		_place_boss_bar(_fusion_lbl, _fusion_bg, _fusion_fill, w, y, 704.0, 32.0)
		_fusion_tbg.position = Vector2(w * 0.5 - 352.0, y + 32.0 + 28.0)
		_fusion_tfill.position = Vector2(w * 0.5 - 348.0, y + 32.0 + 30.0)
		y += 76.0
	if _wboss_root.visible:
		_place_boss_bar(_wboss_lbl, _wboss_bg, _wboss_fill, w, y, WBOSS_W, 27.0)
		y += 60.0
	if _swarm_root.visible:
		_place_boss_bar(_swarm_lbl, _swarm_bg, _swarm_fill, w, y, SWARM_W, 24.0)
		_swarm_lbl.position = Vector2(w * 0.5 - 350.0, y)


func _place_boss_bar(lbl: Label, bg: ColorRect, fill: ColorRect, w: float, y: float, bw: float, gap: float) -> void:
	var cx: float = w * 0.5
	lbl.position = Vector2(cx - bw * 0.5 + 2.0, y)
	bg.position = Vector2(cx - bw * 0.5, y + gap)
	fill.position = Vector2(cx - bw * 0.5 + 4.0, y + gap + 2.0)


## 지금 상단에 띄울 중간보스 하나. 보스 게이트가 시간 기준이라 앞의 놈이 살아 있는 채로
## 다음이 나올 수 있다 — 그럴 땐 **가장 가까운 놈**을 잡는다. 지금 싸우는 상대가 그놈이다.
## (스테이지 보스·최종 보스는 is_stage_boss 로, 융합 보스는 _is_fusion 으로 빠진다.)
func _wave_boss_target() -> Enemy:
	# ★ 캐스트가 검사보다 **먼저** 돌면 안 된다. 해제된 객체는 as 에서 그 자리에 터진다
	#   ("Trying to cast a freed object") — 게임오버로 플레이어가 사라진 프레임에 HUD 가
	#   아직 한 번 더 도는 경로에서 실제로 났다. 저장소의 다른 곳도 전부 이 순서다.
	if G.player == null or not is_instance_valid(G.player):
		return null
	var p := G.player as Node2D
	var best: Enemy = null
	var bd: float = 1.0e20
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue
		var e := n as Enemy
		if e == null or e._dead or not e._is_boss or e._is_fusion or e.is_stage_boss:
			continue
		var d: float = e.global_position.distance_squared_to(p.global_position)
		if d < bd:
			bd = d
			best = e
	return best


## 보스 체력바 이름 — 도감·머리 위 이름표와 같은 이름(Codex). 예전엔 여기만 옛 이름(해골 왕·드래곤…)이 남아 있었다.
func _boss_name(k: int) -> String:
	var n: String = Codex.monster_name(k)
	return n if n != "" else "보스"


## 최종 결전 무대 정리 — 스테이지 보스와 무한 최종 보스가 나올 때 같이 쓴다.
## 진행 중이던 융합 보스는 페널티 없이 퇴장, 등장 충격파로 잡몹 소멸(보상 없음). 중간보스는 남긴다.
## 무한 최종 보스(사신)는 이 정리 뒤로 잡몹이 다시 안 나온다(_enemy_cap 0).
func _clear_stage_for_final() -> void:
	# [감사 C10] 진행 중이던 융합 보스는 페널티 없이 퇴장 — 최종 결전 단독 무대
	if _fusion_boss != null and is_instance_valid(_fusion_boss):
		(_fusion_boss as Node).queue_free()
	_fusion_boss = null
	_fusion_live = false
	_fusion_root.visible = false
	_overcap_t = 0.0
	for n in get_tree().get_nodes_in_group("enemy"):  # 등장 충격파: 기존 잡몹 소멸 (보상 없음)
		var en := n as Enemy
		if en == null or not is_instance_valid(en) or en._is_boss:
			continue
		# [감사 C25] 소멸 연출 중 '유령 몹'이 접촉피해/보상 주던 것 — 즉시 완전 무력화
		en._dead = true
		en.set_deferred("collision_layer", 0)
		en.set_physics_process(false)
		en.remove_from_group("enemy")
		var dtw := en.create_tween()
		dtw.tween_property(en, "modulate:a", 0.0, 0.35)
		dtw.tween_callback(en.queue_free)


## 스테이지 보스 (S1): 스테이지 고유 보스 — 처치하면 클리어. HP는 종류 무관 통일 공식.
## 등장 충격파가 잡몹을 일소 — 연출 겸, 잡몹 벽이 보스행 탄환을 전부 흡수하는 문제 해결.
func _spawn_stage_boss() -> void:
	var bk: int = int(STAGE_BOSS[clampi(G.stage_sel, 0, STAGE_BOSS.size() - 1)])
	if not _boss_cutin(Enemy.art_for(bk), FxLib.word_sheet("w_boss"), I18n.t("스테이지 보스 · 처치하면 클리어"), Color("ff2d55")):
		_wave_banner("스테이지 보스 출현! 처치하면 클리어", Color("ff2d55"),
			[FxLib.word_sheet("w_boss")], I18n.t("스테이지 보스 · 처치하면 클리어"))
	G.add_shake(1.0)
	_last_boss_t = G.time_alive
	_clear_stage_for_final()
	var base := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	var e := Enemy.new()
	e.kind = bk
	e.is_stage_boss = true  # 근접 압박형 AI
	e.global_position = (base + Vector2(0, -520.0)).clamp(Vector2(-ARENA + 90.0, -ARENA + 90.0), Vector2(ARENA - 90.0, ARENA - 90.0))
	add_child(e)
	# 종류별 기본 HP 편차 제거 — 스테이지 보스는 '고정 체급' 공식.
	# [감사 C11] 하한 = 같은 시점 웨이브 중간보스(성장 상한 적용)의 배수 — 최종 보스가 중간보스보다 물몸인 역전 방지.
	# 17-1: 1.25 배(meta 없음) → 기준(meta 포함)의 2.0 배. 강화를 갖춘 판에선 중간보스(×1.43 meta)가 이 보스보다 단단했다.
	#   가장 단단한 중간보스(1.3) · 융합 상한(1.5)보다 확실히 위에 선다.
	e.hp = _stage_boss_hp()
	e.max_hp = e.hp
	_stage_boss = e
	G.begin_boss_fight()  # ★ 별 등급·최단기록·무피격 판정의 시계는 여기서 시작한다


# ──────────────────────────── 승리 연출 ────────────────────────────
## ★ 예전엔 보스가 죽은 그 프레임에 텍스트 패널이 그냥 켜졌다. 30분을 버틴 끝이 0프레임이면
##   "이겼다"는 감각이 남을 자리가 없다. 그리고 보스가 떨군 상자·회복·큰경험치가 통째로
##   증발했다(G.running=false 가 즉시 걸려 픽업이 멈춘다).
##   이제 결정타에서 잠깐 시간이 늘어지고, 그 사이 바닥의 보상이 전부 빨려온다.
var _win_cb: Callable = Callable()
var _win_at_ms: int = 0
var _win_paused: bool = false   # 연출 중 일시정지 여부 (슬로모션을 잠시 풀어 둔 상태)

func _begin_win_sequence(cb: Callable) -> void:
	if _win_seq:
		return
	_win_seq = true
	_win_cb = cb
	_win_at_ms = Time.get_ticks_msec() + 2300
	G.hitstop(0.30)
	G.add_shake(1.6)
	G.set_slowmo(0.32)
	G.magnet_all(3.5)          # 보스가 떨군 것들이 전부 끌려온다
	G.freeze_enemies(6.0)      # 연출 동안 잔당 정지 — 다 이기고 죽는 일 없게
	G.sfx("levelup", 0.72)
	if G.player != null and is_instance_valid(G.player):
		(G.player as Player).grant_iframe(6.0)
	_win_flash()
	_wave_banner("결정타", Color("ffd54a"))


## 화면 전체가 한 번 하얗게 물들었다 걷힌다.
func _win_flash() -> void:
	if _levelup_flash == null:
		return
	# ★ 2026-09-15: 최고 알파가 **0.85** 였다. 화면 전체를 크림색으로 덮는 값이라,
	#   그 1.2초 동안은 몹이든 탄이든 색이 통째로 날아간다. 레벨업이 몇 초에 한 번씩
	#   터지는 구간(레벨 10~20)에서는 사실상 상시 흰 막이 깔린 셈이었다 —
	#   "다른 색상도 특정 상황이 오면 안 보인다"의 그 '특정 상황'이 이것이다.
	#   레벨업은 카드 화면이 뜨는 것으로 이미 확실히 알려진다. 번쩍임은 거들기만 하면 된다.
	_levelup_flash.color = Color(1.0, 0.96, 0.82, 0.0)
	_levelup_flash.visible = true   # 평소엔 꺼 둔다(_update_hud) — 번쩍일 때만 켠다
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_levelup_flash, "color:a", 0.26 * G.flash_mult(), 0.08)
	tw.tween_property(_levelup_flash, "color:a", 0.0, 0.42)


## 무한 모드 완주 — 30분을 버티고 최종 보스까지 잡았을 때.
func _on_endless_clear() -> void:
	if _endless_done:
		return
	_endless_done = true
	for cn in get_tree().get_nodes_in_group("coin"):
		if cn is GoldCoin and is_instance_valid(cn):
			G.add_gold((cn as GoldCoin)._value)
			(cn as Node).queue_free()
	G.running = false
	G.freeze_enemies(3600.0)
	_halt_run_weapons()
	G.stat_add("endless_clears", 1)
	if G.difficulty >= 3:
		G.stat_add("endless_hard", 1)
	G.record_karma(String(_last_char.get("id", "")))   # 11/7 업보: 영웅마다 깬 가장 높은 단계
	if G.no_hit_boss:
		G.stat_add("nohit_clears", 1)
	if G.boss_fight_t > 0.0 and G.boss_fight_t <= 60.0:
		G.stat_add("swift_clears", 1)
	G.stat_max("best_time", int(G.time_alive))
	G.stat_max("best_combo", G.combo_best)
	var bonus: int = G.add_gold_bonus(800 * (G.difficulty + 1))
	var earned: int = G.run_gold
	G.bank_run_gold()
	G.run_ended()
	G.check_achievements()
	var unlocks: Array = _collect_new_unlocks()
	var lines: Array = [
		I18n.t("무한 완주  ·  %s") % G.diff_label(),
		I18n.t("%02d:%02d  ·  처치 %d  ·  레벨 %d  ·  최고 콤보 %d") % [
			int(G.time_alive) / 60, int(G.time_alive) % 60, G.kills, G.level, G.combo_best],
		I18n.t("최종 보스 격파 %02d:%02d  ·  보스전 피격 %d회 (런 전체 %d회)%s") % [
			int(G.boss_fight_t) / 60, int(G.boss_fight_t) % 60, G.boss_hits, G.hits_taken,
			I18n.t("   무피격 격파") if G.no_hit_boss else ""],
		I18n.t("획득 골드 %s G  (완주 보너스 +%s 포함)  ·  총 %s G") % [G.gold_str(earned), G.gold_str(bonus), G.gold_str(G.total_gold)],
	]
	UiKit.set_wrapped(_victory_lbl, String(lines[0]), 20, true)   # 11/5: 항목 사이에서만 · 고르게 꺾는다
	if _vic_stars != null:
		_vic_stars.visible = false
	_res_summary(_vic_sum)
	UiKit.set_wrapped(_vic_gold, _keep_items(String(lines[3])), 20, true)
	_res_unlocks(_vic_unl)
	_fill_dmg_table(_vic_table)
	_victory_next.disabled = true
	_victory_title.text = I18n.t("완  주")
	_vic_word(false)   # 무한 완주는 「STAGE CLEAR」 가 아니라 「결과」(16차 U7 — 예전엔 낱말 그림이 늘 STAGE CLEAR 였다)
	_update_hud_scale()
	_victory.visible = true
	_fit_result_panel(_vic_panel)
	_pad_focus.call_deferred(_victory)
	G.sfx("levelup", 1.3)
	G.add_shake(0.5)


## 19차 4-2 체험판: 무한 15분에서 끝 — 완주 창을 그대로 쓰되 완주 기록 · 보너스는 없고 정식판 안내 한 줄.
func _on_demo_end() -> void:
	if _endless_done:
		return
	_endless_done = true
	for cn in get_tree().get_nodes_in_group("coin"):
		if cn is GoldCoin and is_instance_valid(cn):
			G.add_gold((cn as GoldCoin)._value)
			(cn as Node).queue_free()
	G.running = false
	G.freeze_enemies(3600.0)
	_halt_run_weapons()
	G.stat_max("best_time", int(G.time_alive))
	G.stat_max("best_combo", G.combo_best)
	var earned: int = G.run_gold
	G.bank_run_gold()
	G.run_ended()
	G.check_achievements()
	UiKit.set_wrapped(_victory_lbl, I18n.t("체험판은 여기까지예요.\n정식판 무한 모드는 30분, 최종 보스까지 이어져요."), 20)
	if _vic_stars != null:
		_vic_stars.visible = false
	_res_summary(_vic_sum)
	UiKit.set_wrapped(_vic_gold, _keep_items(I18n.t("획득 골드 %s G  ·  총 %s G") % [G.gold_str(earned), G.gold_str(G.total_gold)]), 20, true)
	_res_unlocks(_vic_unl)
	_fill_dmg_table(_vic_table)
	_victory_next.disabled = true
	_victory_title.text = I18n.t("체험판 끝")
	_vic_word(false)
	_update_hud_scale()
	_victory.visible = true
	_fit_result_panel(_vic_panel)
	_pad_focus.call_deferred(_victory)
	G.sfx("levelup", 1.3)


## 런 종료 시 무기·소환수 정지 (승리 후에도 계속 지지던 것 차단)
func _halt_run_weapons() -> void:
	if G.player == null or not is_instance_valid(G.player):
		return
	var pw := G.player as Player
	pw.set_physics_process(false)
	for k in pw.weapons.keys():
		var wn: Node = pw.weapons[k]
		if is_instance_valid(wn):
			wn.propagate_call("set_process", [false])
			wn.propagate_call("set_physics_process", [false])


## 스테이지 클리어 (S1): 기록 저장 + 첫 클리어 보너스 + 승리 패널
func _on_stage_clear() -> void:
	if _stage_done:
		return
	_stage_done = true
	_stage_boss = null
	if G.player != null and is_instance_valid(G.player):
		(G.player as Player).cf_moment("emote")   # 승리 포즈(희귀 이상)
	# [감사 C9/C18/C19] 보스 드랍 금화가 정산 직후 증발하던 것 — 바닥 금화 전액 즉시 수거 후 정산
	for cn in get_tree().get_nodes_in_group("coin"):
		if cn is GoldCoin and is_instance_valid(cn):
			G.add_gold((cn as GoldCoin)._value)
			(cn as Node).queue_free()
	G.running = false
	# _run_active는 true 유지 — 다음 '새 게임'이 씬 리로드를 타게(정지된 플레이어/잔존 무기 재사용 방지).
	# 이어하기 버튼은 _on_victory_menu에서 비활성.
	G.freeze_enemies(3600.0)  # 승리 화면 동안 잔존 적 정지 (사후 피격 방지)
	# 특수무기(오라/소환수/레이저)도 전부 정지 — 승리 후에도 계속 지지던 것 차단 (S4)
	_halt_run_weapons()
	# 이전 기록을 먼저 읽어야 '갱신했는지'를 판정할 수 있다
	var prev_star: int = G.stage_stars(_run_stage_l, _run_diff_l)
	var prev_time: float = G.stage_best_time(_run_stage_l, _run_diff_l)
	var star: int = G.clear_stars(G.boss_fight_t, G.no_hit_boss)
	var first_bonus: int = G.mark_stage_clear(_run_stage_l, _run_diff_l)  # [감사 C5/C6] 래치값으로만 기록
	G.record_karma(String(_last_char.get("id", "")))   # 11/7 업보: 영웅마다 깬 가장 높은 단계
	if first_bonus > 0:
		first_bonus = G.add_gold_bonus(first_bonus)  # 골드 획득 강화·복주머니가 여기에도 붙는다
	# 별 보상 — 잘 깰수록 골드가 더 붙는다 (이미 깬 판을 다시 깰 이유)
	var star_bonus: int = G.add_gold_bonus(int(round(60.0 * float(star) * float(_run_stage_l + 1) * G.diff_gold_mult())))
	var earned: int = G.run_gold
	_stage_earned = earned
	G.bank_run_gold()
	G.run_ended()
	var unlocks: Array = _collect_new_unlocks()
	# ★ 14차 2절 5: 글이 한 줄에 몰렸고(「보스전 00:00 · 보스전 피격 0회 (런 전체 0회) 무피격 격파」) ⏱ 기호가 남아 있었다.
	#   별 · 스테이지 한 줄(기록은 배지) · 요약 한 줄(시간 · 처치 · 레벨 · 콤보) · 무기 표 · 엽전 한 줄 · 해금 카드.
	var badges: Array = []
	if star > prev_star:
		badges.append(I18n.t("최고 등급"))
	if prev_time > 0.0 and G.boss_fight_t < prev_time:
		badges.append(I18n.t("최단 기록"))
	if G.no_hit_boss:
		badges.append(I18n.t("무피격"))
	if _vic_stars != null:
		for c in _vic_stars.get_children():
			c.queue_free()
		_vic_stars.add_child(UiParts.stars(star, 3, 16))
		_vic_stars.visible = true
	UiKit.set_wrapped(_victory_lbl, "%s (%s)%s" % [
		I18n.t(String(G.STAGE_NAMES[_run_stage_l])), G.diff_label(_run_diff_l),
		("   · " + "  · ".join(badges)) if not badges.is_empty() else ""], 20, true)
	_res_summary(_vic_sum)
	# 10/13 QA: 첫 클리어 · 별 보너스는 이미 획득 골드(run_gold)에 들어 있다 — 예전 「획득 X · 첫 클리어 +Y · 별 +Z」는
	#   더해야 하는 것처럼 읽혔다. 「포함」으로 묶고, 항목 안 띄어쓰기는 줄바꿈 없는 공백(「Star / bonus」로 갈라지던 것).
	UiKit.set_wrapped(_vic_gold, _keep_items(I18n.t("획득 골드 %s  (%s별 보너스 +%s 포함)  ·  총 %s") % [G.gold_str(earned),
		(I18n.t("첫 클리어 +%s · ") % G.gold_str(first_bonus)) if first_bonus > 0 else "",
		G.gold_str(star_bonus), G.gold_str(G.total_gold)]), 20, true)
	_res_unlocks(_vic_unl)
	_fill_dmg_table(_vic_table)
	# 다음 스테이지 버튼: 마지막 스테이지거나 아직 잠김이면 비활성
	var nxt: int = _run_stage_l + 1
	_victory_title.text = "STAGE CLEAR"
	_vic_word(true)
	_victory_next.disabled = nxt > G.STAGE_NAMES.size() - 1 or not G.stage_unlocked(nxt, _run_diff_l)
	_update_hud_scale()  # 스테일 크기 방어 (S3)
	_victory.visible = true
	_fit_result_panel(_vic_panel)
	_pad_focus.call_deferred(_victory)
	G.sfx("levelup", 1.3)
	G.add_shake(0.5)


## 같은 스테이지·난이도를 그대로 다시. 별 등급/최단 기록 갱신용.
func _on_victory_retry() -> void:
	G.stage_sel = _run_stage_l
	G.difficulty = _run_diff_l
	G.pending_char = _last_char
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_victory_next() -> void:
	G.stage_sel = mini(G.STAGE_NAMES.size() - 1, _run_stage_l + 1)
	G.difficulty = _run_diff_l
	G.pending_char = _last_char
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_victory_menu() -> void:
	_victory.visible = false
	_main_menu.set_continue_enabled(false)  # 끝난 런은 이어하기 불가 (새 게임 = 리로드)
	_main_menu.open()


## 런 종료 후 새로 열린 캐릭터/무기 알림 수집 (조건 자동 해금, 1회만 알림)
## 14차 2절 4: 결과 화면 해금은 글 네 줄 대신 초상 카드 한 줄 — 여기에 같이 쌓는다
var _unlock_cards: Array = []

func _collect_new_unlocks() -> Array:
	var out: Array = []
	_unlock_cards.clear()
	# ★ 줄은 여기서 완성한다(도전과제는 🏆, 해금은 🔓). 소비하는 세 곳이 각자 자물쇠를 덧붙이던 탓에
	#   「🔓 🏆 첫 정복 (+60G)」처럼 아이콘이 두 개 찍혔다.
	for line in _pending_ach:  # 정산 중 달성된 도전과제 (배너가 안 뜨는 구간)
		out.append(String(line))
	_pending_ach.clear()
	for d: Dictionary in Characters.defs():
		var id: String = String(d["id"])
		if id == "base":
			continue
		if G.char_unlocked(id) and int(G.meta.get("ucn_" + id, 0)) == 0:
			G.meta["ucn_" + id] = 1
			out.append(I18n.t("새 캐릭터 해금: %s") % I18n.t(String(d["name"])))
			_unlock_cards.append({"kind": "char", "id": id, "name": I18n.t(String(d["name"]))})
	for wid: String in G.WPN_UNLOCKS.keys():
		if G.wpn_unlocked(wid) and int(G.meta.get("uwn_" + wid, 0)) == 0:
			G.meta["uwn_" + wid] = 1
			out.append(I18n.t("새 무기 해금: %s") % I18n.t(String(G.WPN_UNLOCKS[wid]["name"])))
			_unlock_cards.append({"kind": "wpn", "id": wid, "name": I18n.t(String(G.WPN_UNLOCKS[wid]["name"]))})
	# QA 10/13: 도전과제도 카드로(스팀 그림 그대로). 예전엔 줄만 만들고 결과 화면 셋 다 버렸다.
	for a2: Dictionary in _pending_ach_defs:
		_unlock_cards.append({"kind": "ach", "id": String(a2["id"]), "name": I18n.t(String(a2["name"])), "gold": int(a2.get("gold", 0))})
	_pending_ach_defs.clear()
	if not out.is_empty():
		G.save_game()
	return out


## 화면 상단 배너.
## ★ 예전엔 부를 때마다 같은 좌표(top 128)에 새 Label 을 얹었다. 스테이지 전환처럼 배너가
##   연달아 뜨는 순간(WAVE 표시 + 보스 출현 + 도전과제 달성)에 글자가 그대로 겹쳐 찍혔다.
##   그리고 폭 제한이 없어서 긴 문구는 화면 밖으로 삐져나갔다 — 둘 다 유저 보고.
##   이제 한 번에 하나만 띄우고, 밀린 것은 줄 세워 차례로 보여준다.
var _banner_q: Array = []
var _banner_busy: bool = false

## art: 10차 낱말 그림 줄("w_wave" · "#12" 숫자) — 있으면 그림 줄 + 그 아래 sub(짧은 글)로 띄운다.
## 그림이 하나라도 없으면 text 를 예전처럼 글꼴 한 줄로. 긴 문장 · 이름은 늘 글꼴이다.
func _wave_banner(text: String, col: Color, art: Array = [], sub_text: String = "") -> void:
	if _hud_layer == null:
		return
	if _banner_q.size() >= 4:
		_banner_q.pop_front()  # 폭주 시 오래된 것부터 버린다(최신 소식이 더 중요)
	_banner_q.append({"t": text, "c": col, "a": art, "s": sub_text})
	if not _banner_busy:
		_banner_next()


func _banner_next() -> void:
	if _banner_q.is_empty():
		_banner_busy = false
		return
	_banner_busy = true
	var e: Dictionary = _banner_q.pop_front()
	if e.has("cut"):
		_cutin_show(e["cut"])
		return
	var text: String = String(e["t"])
	var art: Array = e.get("a", [])
	var prow: HBoxContainer = FxLib.pixel_row(art, 2, Color("ffd54a"), 3, "num_big") if not art.is_empty() else null
	if prow != null:
		_banner_pixel(prow, String(e.get("s", "")), e["c"])
		return
	var l := Label.new()
	l.text = text
	# 긴 문구는 글자를 줄이고 줄바꿈까지 허용 — 화면 밖으로 나가지 않게
	var fs: int = 46
	if text.length() > 18:
		fs = 34
	if text.length() > 30:
		fs = 26
	UiFont.apply(l, fs)
	l.add_theme_color_override("font_color", e["c"])
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = 128.0
	l.offset_left = 40.0
	l.offset_right = -40.0
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(l)
	# ★ 배너는 **멈춘 화면 위에서도** 흘러야 한다. 깃소금의 도박은 레벨업 직전에 굴리는데,
	#   곧바로 카드 모달이 get_tree().paused 를 걸어 버려서 이 트윈이 얼어붙었다.
	#   그 결과 "🎰 초대박" 배너가 투명한 채로 멈춰 있다가 카드를 고른 뒤에야 잠깐 떴고,
	#   그때는 방금 고른 카드와 구분이 안 됐다(2026-09-05 지적).
	l.process_mode = Node.PROCESS_MODE_ALWAYS
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(l, "modulate:a", 1.0, 0.20)
	tw.tween_interval(0.95)
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.tween_callback(l.queue_free)
	tw.tween_callback(_banner_next)


## 낱말 그림 배너 — 그림 줄(그림 1px = UI 2px) 아래에 짧은 글 한 줄. 멈춘 화면 위에서도 흐른다(아래 트윈 설명 참고).
func _banner_pixel(prow: HBoxContainer, sub_text: String, col: Color) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	box.offset_top = 120.0
	box.offset_left = 40.0
	box.offset_right = -40.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(prow)
	if sub_text != "":
		var l := Label.new()
		l.text = sub_text
		UiFont.apply(l, 26)
		l.add_theme_color_override("font_color", col)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)
	_hud_layer.add_child(box)
	box.process_mode = Node.PROCESS_MODE_ALWAYS
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(box, "modulate:a", 1.0, 0.20)
	tw.tween_interval(0.95)
	tw.tween_property(box, "modulate:a", 0.0, 0.35)
	tw.tween_callback(box.queue_free)
	tw.tween_callback(_banner_next)


# ---------------------------------------------------------------- 12차 F 컷인 (보스 등장 · 융합)
## 화면 위쪽을 가로지르는 띠 한 줄: 경고 띠(boss_band, 보스만) + 컷인 띠(cutin_band) 위에 얼굴 · 낱말 · 이름.
## 영웅은 화면 가운데(720 기준 y 360, 머리 끝 약 320)에 있다 — 띠는 그 위(y 52~308)에만 걸친다.
## ★ HUD 배율(4/3 · 5/3)을 타면 띠가 영웅을 덮는다 — 그래서 HUD 밖 자기 층에 720 기준으로 그린다.
## 배너와 같은 줄에 서서 겹치지 않는다. 그림은 UI ×2(얼굴 portrait_big 96 → 192 = 띠 높이), 영웅 portrait 는 ×3.
## 멈춘 화면 · 융합 슬로모션 위에서도 제 속도로 흐른다.
const CUTIN_Y: float = 52.0
var _cutin_layer: CanvasLayer = null

## 보스 kind 의 얼굴로 컷인. 띠 그림이 없으면 false — 부르는 쪽이 예전 배너를 띄운다.
func _boss_cutin(kind: int, word: String, sub: String, col: Color, hold: float = 1.25) -> bool:
	var bid: String = CharForge.enemy_id(kind)
	var tex: Texture2D = CharForge.frame_tex(bid, "portrait_big") if bid != "" and CharForge.has_anim(bid, "portrait_big") else null
	return _cutin({"word": word, "name": _boss_name(kind), "sub": sub, "col": col, "tex": tex, "k": 2,
		"left": false, "warn": true, "hold": hold})


func _cutin(c: Dictionary) -> bool:
	if _hud_layer == null or not FxLib.has("ui/moment", "cutin_band"):
		return false
	if _banner_q.size() >= 4:
		_banner_q.pop_front()
	_banner_q.append({"cut": c})
	if not _banner_busy:
		_banner_next()
	return true


## 이어 붙이는 띠(4칸 흐름)를 UI ×2 로 가로 전체에. 칸은 json ms 대로 넘긴다.
func _moment_strip(sheet: String) -> TextureRect:
	var m: Dictionary = FxLib.info("ui/moment", sheet)
	if m.is_empty():
		return null
	var r := TextureRect.new()
	r.texture = FxLib.scaled("ui/moment", sheet, 0, 2)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n: int = int(m["n"])
	var tw := r.create_tween().set_loops()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_ignore_time_scale(true)
	for i in n:
		var nxt: int = (i + 1) % n
		tw.tween_interval(float(m["len"]) / float(n))
		tw.tween_callback(func() -> void: r.texture = FxLib.scaled("ui/moment", sheet, nxt, 2))
	return r


## 깜빡이는 ⚠(boss_mark 4칸) UI ×2.
func _moment_mark() -> TextureRect:
	var m: Dictionary = FxLib.info("ui/moment", "boss_mark")
	if m.is_empty():
		return null
	var r := TextureRect.new()
	r.texture = FxLib.scaled("ui/moment", "boss_mark", 0, 2)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size = r.texture.get_size()
	var n: int = int(m["n"])
	var tw := r.create_tween().set_loops()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_ignore_time_scale(true)
	for i in n:
		var nxt: int = (i + 1) % n
		tw.tween_interval(float(m["len"]) / float(n))
		tw.tween_callback(func() -> void: r.texture = FxLib.scaled("ui/moment", "boss_mark", nxt, 2))
	return r


func _cutin_show(c: Dictionary) -> void:
	var col: Color = c.get("col", Color("ffd54a"))
	var left: bool = bool(c.get("left", false))    # 얼굴 자리: 영웅 = 왼쪽(오른쪽을 본다) · 보스 = 오른쪽(왼쪽을 본다)
	if _cutin_layer == null:
		_cutin_layer = CanvasLayer.new()
		_cutin_layer.layer = 5                    # HUD(1) 위 · 레벨업(10) · 상자 창(12) 아래
		_cutin_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_cutin_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	_cutin_layer.add_child(root)
	var y: float = CUTIN_Y
	# 경고 띠 — 가운데 어두운 판에 ⚠ 낱말 ⚠
	if bool(c.get("warn", false)) and FxLib.has("ui/moment", "boss_band"):
		var wb: TextureRect = _moment_strip("boss_band")
		wb.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		wb.offset_top = y
		wb.offset_bottom = y + 64.0
		root.add_child(wb)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for part in ["mark", String(c.get("word", "")), "mark"]:
			var it: Control = _moment_mark() if part == "mark" else FxLib.word_rect(part, 2)
			if it != null:
				it.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				row.add_child(it)
		var plate := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("141a3a")
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		plate.add_theme_stylebox_override("panel", sb)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(row)
		var cc := CenterContainer.new()
		cc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		cc.offset_top = y + 8.0
		cc.offset_bottom = y + 56.0
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(plate)
		root.add_child(cc)
		y += 64.0
	# 컷인 띠
	var band: TextureRect = _moment_strip("cutin_band")
	band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	band.offset_top = y
	band.offset_bottom = y + 192.0
	band.pivot_offset = Vector2(0.0, 96.0)
	root.add_child(band)
	# 얼굴 — 띠 바닥에 맞춰 옆에서 미끄러져 들어온다
	var tex: Texture2D = c.get("tex", null)
	var face: TextureRect = null
	var fw: float = 0.0
	if tex != null:
		var k: float = float(c.get("k", 2))
		var fs: Vector2 = tex.get_size() * k
		fw = fs.x
		face = TextureRect.new()
		face.texture = tex
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_SCALE
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if left:
			face.anchor_left = 0.0
			face.anchor_right = 0.0
			face.offset_left = 96.0
		else:
			face.anchor_left = 1.0
			face.anchor_right = 1.0
			face.offset_left = -96.0 - fs.x
		face.offset_right = face.offset_left + fs.x
		face.offset_top = y + 192.0 - 2.0 - fs.y
		face.offset_bottom = y + 192.0 - 2.0
		root.add_child(face)
	# 낱말(보스는 위 경고 띠에 이미 있다) · 이름 · 한 줄
	var tx := VBoxContainer.new()
	tx.add_theme_constant_override("separation", 6)
	tx.alignment = BoxContainer.ALIGNMENT_CENTER
	tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not bool(c.get("warn", false)) and String(c.get("word", "")) != "":
		var wr: TextureRect = FxLib.word_rect(String(c["word"]), 3)
		if wr != null:
			wr.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if left else Control.SIZE_SHRINK_END
			tx.add_child(wr)
	for line in [[String(c.get("name", "")), 44, Color.WHITE], [String(c.get("sub", "")), 24, col]]:
		if String(line[0]) == "":
			continue
		var l := Label.new()
		l.text = String(line[0])
		UiFont.apply(l, int(line[1]))
		l.add_theme_color_override("font_color", line[2])
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("outline_size", 8)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tx.add_child(l)
	tx.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tx.offset_top = y + 16.0
	tx.offset_bottom = y + 176.0
	if left:
		tx.offset_left = 96.0 + fw + 32.0
		tx.offset_right = -48.0
	else:
		tx.offset_left = 48.0
		tx.offset_right = -96.0 - fw - 32.0
	root.add_child(tx)
	# 들어오고 · 머물고 · 빠진다
	root.modulate.a = 0.0
	band.scale = Vector2(1.0, 0.1)
	var slide: float = -320.0 if left else 320.0
	if face != null:
		face.offset_left += slide
		face.offset_right += slide
	var tw := create_tween()     # 배너와 같이 이 노드에 — 끝에 다음 배너를 부른다
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_ignore_time_scale(true)
	tw.tween_property(root, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(band, "scale:y", 1.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if face != null:
		tw.parallel().tween_property(face, "offset_left", face.offset_left - slide, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(face, "offset_right", face.offset_right - slide, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(float(c.get("hold", 1.25)))
	tw.tween_property(root, "modulate:a", 0.0, 0.25)
	tw.tween_callback(root.queue_free)
	tw.tween_callback(_banner_next)


# ---------------------------------------------------------------- 배경 (테마 순환) + 지형 장애물
var _bg = null
var _obstacles: Array = []
var _decals: Array = []
var _theme_t: float = 0.0
var _cur_theme: int = 0
var _lava_t: float = 0.0    # 용암동굴: 용암 분출 타이머
var _garden_t: float = 0.0  # 정원: 플레이어 재생 틱 타이머
## 테마별 흩뿌릴 장식 데칼(비충돌). 인덱스=테마. 천상은 데칼 없음.
const DECAL_TEX: Array = [
	"res://assets/sprites/tiles/dungeon_ground2.png",
	"res://assets/sprites/tiles/library_ground2.png",
	"res://assets/sprites/tiles/garden_ground2.png",
	"res://assets/sprites/tiles/lava_ground2.png",
	"",
	"res://assets/sprites/tiles/jeoseung_patch.png",
]

func _build_background() -> void:
	_bg = _GridBg.new()
	_bg.z_index = -100
	add_child(_bg)


## 플레이 중 랜덤하게 테마 전환 (배경색 + 지형 장애물 교체)
func _cycle_theme() -> void:
	if _bg == null:
		return
	if _final_spawned and not _stage_mode:
		return  # 사신 구간: 빈 들판 그대로(장애물을 다시 깔지 않는다)
	# 테마 수는 배경 정의(THEMES)가 정한다 — 리터럴 5 로 두면 테마를 늘려도 절대 안 나온다
	var n_themes: int = _GridBg.THEMES.size()
	var nxt: int = _cur_theme
	if n_themes <= 1:
		return
	while nxt == _cur_theme:
		nxt = randi() % n_themes
	_cur_theme = nxt
	_bg.set_theme(nxt)
	_regen_obstacles(nxt)
	_scatter_decals(nxt)
	_apply_stage_rule(nxt)


## 맵 특화 규칙 적용 (적 배수 세팅 + 규칙 배너). 던전/도서관/정원/용암동굴/천상.
func _apply_stage_rule(i: int) -> void:
	G.stage = i
	G.codex_see("map_%d" % i)  # 맵 도감 해금
	match i:
		0:  # 던전 — 언데드 소굴
			G.stage_enemy_hp = 1.18
			G.stage_enemy_spd = 1.0
			G.stage_xp_mult = 1.15
			_wave_banner("던전 · 적 체력 ×1.18 · 경험치 ×1.15", Color("ffb07a"))
		1:  # 도서관 — 유령 사서
			G.stage_enemy_hp = 1.0
			G.stage_enemy_spd = 1.16
			G.stage_xp_mult = 1.25
			_wave_banner("도서관 · 적 이동 ×1.16 · 경험치 ×1.25", Color("ffe0a0"))
		2:  # 정원 — 생명의 정원
			G.stage_enemy_hp = 1.0
			G.stage_enemy_spd = 1.0
			G.stage_xp_mult = 1.0
			_wave_banner("생명의 정원 · 양쪽 모두 재생", Color("bfffb0"))
		3:  # 용암동굴 — 불지옥
			G.stage_enemy_hp = 1.1
			G.stage_enemy_spd = 1.0
			G.stage_xp_mult = 1.1
			_wave_banner("용암동굴 · 터지는 하쓰바 · 용암 분출", Color("ff8a5a"))
		4:  # 천상 — 천상계
			G.stage_enemy_hp = 1.0
			G.stage_enemy_spd = 1.12
			G.stage_xp_mult = 1.3
			_wave_banner("천상계 · 적 이동 ×1.12 · 경험치 ×1.3", Color("cdb8ff"))
		5:  # 저승길 — 염라의 길
			G.stage_enemy_hp = 1.12
			G.stage_enemy_spd = 1.08
			G.stage_xp_mult = 1.3
			_wave_banner("저승길 · 적 체력 ×1.12 · 이동 ×1.08 · 경험치 ×1.3", Color("9ad8ff"))
		_:
			G.stage_enemy_hp = 1.0
			G.stage_enemy_spd = 1.0
			G.stage_xp_mult = 1.0


## 맵 특화 환경 효과 (정원=플레이어 재생 / 용암동굴=용암 분출)
func _stage_hazards(delta: float) -> void:
	if G.player == null or not is_instance_valid(G.player):
		return
	var p := G.player as Player
	if _cur_theme == 2:  # 생명의 정원: 플레이어도 서서히 재생
		_garden_t -= delta
		if _garden_t <= 0.0:
			_garden_t = 0.5
			if p.hp > 0.0 and p.hp < p.max_hp:
				p.heal(p.max_hp * 0.012)
	elif _cur_theme == 3:  # 용암동굴: 주기적 용암 분출(예고 후 폭발 → 비켜야 함)
		_lava_t -= delta
		if _lava_t <= 0.0:
			_lava_t = randf_range(2.2, 3.6)
			var off := Vector2(randf_range(-230.0, 230.0), randf_range(-230.0, 230.0))
			var pos: Vector2 = (p.global_position + off).clamp(Vector2(-ARENA + 40.0, -ARENA + 40.0), Vector2(ARENA - 40.0, ARENA - 40.0))
			TelegraphAoE.spawn(self, pos, 95.0, 0.9, 18.0 + G.time_alive * 0.25)


## 지형 장애물을 전부 걷는다(줄어들며 사라짐).
func _clear_obstacles() -> void:
	for o in _obstacles:
		if is_instance_valid(o):
			var ot := (o as Node2D).create_tween()
			ot.tween_property(o, "scale", Vector2(0.1, 0.1), 0.2)
			ot.tween_callback((o as Node).queue_free)
	_obstacles = []


## 현재 테마에 맞는 지형 장애물 배치 (이동을 막음)
func _regen_obstacles(theme_i: int) -> void:
	_clear_obstacles()
	var pcenter := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	var count: int = 7
	var tries: int = 0
	while _obstacles.size() < count and tries < 60:
		tries += 1
		var ang: float = randf() * TAU
		var d: float = randf_range(280.0, 1150.0)
		var pos: Vector2 = pcenter + Vector2(cos(ang), sin(ang)) * d
		pos = pos.clamp(Vector2(-ARENA + 120.0, -ARENA + 120.0), Vector2(ARENA - 120.0, ARENA - 120.0))
		var ok: bool = true
		for o in _obstacles:  # 서로 너무 붙지 않게
			if pos.distance_to((o as Node2D).global_position) < 220.0:
				ok = false
				break
		if not ok:
			continue
		var r: float = randf_range(34.0, 52.0)
		_obstacles.append(Obstacle.spawn(self, pos, theme_i, r))


## 테마별 장식 데칼 흩뿌리기 (비충돌 스프라이트 — 지형지물 느낌). 바닥 위·몹 아래.
func _scatter_decals(theme_i: int) -> void:
	for d in _decals:
		if is_instance_valid(d):
			(d as Node).queue_free()
	_decals = []
	var path: String = String(DECAL_TEX[theme_i % DECAL_TEX.size()])
	if path == "" or not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex == null:
		return
	var pcenter := (G.player as Node2D).global_position if G.player != null and is_instance_valid(G.player) else Vector2.ZERO
	for i in 8:
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.z_index = -50  # 바닥(-100) 위, 몹(0) 아래
		# 개체별 반전/회전/밝기로 복붙감 완화.
		# ★ 14차: 아무 각도(0~360°) · 소수 배율(1.3~2.6)이었다 — 도트를 90° 배수가 아닌 각도로 돌리거나 소수배로 늘리면
		#   픽셀 계단이 깨진다(「도트 게임에서 가장 먼저 티 나는 실수」, 에셋 담당). 90° 단위 · 좌우/위아래 뒤집기 · 정수배만.
		s.flip_h = randf() < 0.5
		s.flip_v = randf() < 0.5
		var ang: float = randf() * TAU
		var dist: float = randf_range(160.0, 1320.0)
		s.global_position = ((pcenter + Vector2(cos(ang), sin(ang)) * dist).clamp(Vector2(-ARENA, -ARENA), Vector2(ARENA, ARENA))).round()
		s.rotation = float(randi() % 4) * (PI * 0.5)
		var sc: float = 2.0 if randf() < 0.5 else 1.0
		s.scale = Vector2(sc, sc)
		var db: float = randf_range(0.6, 0.92)  # 개체별 밝기 차
		s.modulate = Color(db, db, db, 0.0)
		add_child(s)
		var pop := s.create_tween()  # 페이드 인
		pop.tween_property(s, "modulate:a", 0.7, 0.4)
		_decals.append(s)


class _GridBg extends Node2D:
	const ARENA: float = 1500.0
	const TILE: float = 64.0
	# ★ 2026-09-15: 0.86 → 0.70. 바닥이 '그림'이라(픽셀 타일 + 칸마다 밝기 변주 + 저주파 얼룩)
	#   그 위에 30px 짜리 몹과 5px 짜리 탄이 올라가면 서로 잡아먹는다.
	#   배경은 무대지 배우가 아니다 — 한 단 더 눌러서 뒤로 보낸다.
	#   (0.70 까지 내렸다가 0.78 로 되돌렸다. 대비를 실제로 죽이던 건 밝기가 아니라
	#    겹쳐 쌓이던 얼룩과 아레나 글로우였고, 그 둘을 고치니 0.70 은 던전에서 너무 어두웠다.
	#    던전 색조도 0.62 → 0.74 로 같이 올린다 — 원래도 제일 어두운 테마였다.)
	# ★ 16차: 바닥 타일 19 + 저승길 4 를 에셋 담당이 **화면에 보일 밝기 그대로** 다시 그렸다(던전 0.15 · 용암 0.09 · 천상 0.27 · 저승길 0.065).
	#   예전 타일(0.27~0.98)을 누르던 0.78 · 색조 · 결 누르기를 그대로 두면 새 타일은 판석이 안 보이는 검은 바닥이 된다(--s6shot 20~25).
	#   새 타일은 이미 눌러 그린 것이라 여기서는 더 누르지 않는다.
	const GROUND_DIM: float = 1.0
	static var no_blob_test: bool = false   # --loadpeak --noblob 측정용
	## 19차 3-2: 고치기 전 그리기(바탕 사각형 상시 · 분위기 원 둘 상시 · HUD 투명 판 상시)로 재는 A/B 용(--olddraw)
	static var old_draw_test: bool = false
	# ★ 밝기를 눌러도 **색이 같으면** 안 보인다. 도서관 갈색 바닥 위의 갈색 몹 넷이
	#   ΔE 3~10 이었다 — 어두운 테두리를 줘도 안쪽은 여전히 배경색이다.
	#   (python tools/contrast_qa.py 가 스프라이트 × 테마 145짝을 전부 잰다.)
	#   테마 하나만 고치면 다음 맵에서 같은 일이 난다. 바닥 전체의 채도를 뺀다 —
	#   색은 배우가 갖고 무대는 무채색 쪽으로.
	const GROUND_DESAT: float = 0.0    # 16차: 새 타일은 채도를 낮춰 그렸다
	# ★ 채도를 빼도 **나뭇결·벽돌줄의 명암 대비**는 그대로다. 도서관 마루가 특히 그런데,
	#   밝은 널과 어두운 널이 번갈아 있어서 그 줄무늬가 몹만큼 눈에 띈다.
	#   무늬를 그 테마 바닥의 평균색 쪽으로 당겨 진폭만 줄인다 — 패턴은 남고 시끄러움만 준다.
	const GROUND_FLATTEN: float = 0.0  # 16차: 새 타일은 결이 이미 잔잔하다
	## 테마: 바닥 타일 텍스처 + 색조 + 글로우/경계/모트 색. 웨이브마다 순환(크로스페이드).
	const THEMES: Array = [
		{"name": "던전", "ground": "res://assets/sprites/tiles/dungeon_ground.png", "vars": ["res://assets/sprites/tiles/dungeon_b.png", "res://assets/sprites/tiles/dungeon_c.png"], "tint": Color(1, 1, 1), "base": Color("1a181f"), "accent": Color("ff8a3c"), "border": Color("6a5a3a"), "mote": Color(1.0, 0.7, 0.4, 0.14)},
		{"name": "도서관", "ground": "res://assets/sprites/tiles/library_ground.png", "vars": ["res://assets/sprites/tiles/wood_b.png", "res://assets/sprites/tiles/wood_c.png"], "tint": Color(1, 1, 1), "base": Color("2a2418"), "accent": Color("ffcf7a"), "border": Color("7a5a2a"), "mote": Color(1.0, 0.85, 0.5, 0.16)},
		{"name": "정원", "ground": "res://assets/sprites/tiles/garden_ground.png", "vars": ["res://assets/sprites/tiles/garden_ground.png", "res://assets/sprites/tiles/garden_ground.png", "res://assets/sprites/tiles/garden_ground.png", "res://assets/sprites/tiles/grass_b.png", "res://assets/sprites/tiles/grass_c.png"], "tint": Color(1, 1, 1), "base": Color("1c2a1e"), "accent": Color("8ef0a0"), "border": Color("4a7a4a"), "mote": Color(0.7, 1.0, 0.72, 0.18)},  # 기본 중복=가중치 — 꽃밭 변형은 1/3만
		{"name": "용암동굴", "ground": "res://assets/sprites/tiles/lava_ground.png", "vars": ["res://assets/sprites/tiles/lava_b.png", "res://assets/sprites/tiles/lava_c.png"], "tint": Color(1, 1, 1), "base": Color("2a1618"), "accent": Color("ff5a3c"), "border": Color("7a3a2a"), "mote": Color(1.0, 0.5, 0.3, 0.18)},
		{"name": "천상", "ground": "res://assets/sprites/tiles/heaven_ground.png", "vars": ["res://assets/sprites/tiles/heaven_b.png", "res://assets/sprites/tiles/heaven_c.png"], "tint": Color(1, 1, 1), "base": Color("1a1a30"), "accent": Color("b58aff"), "border": Color("6a5aff"), "mote": Color(0.8, 0.85, 1.0, 0.2)},
		{"name": "저승길", "ground": "res://assets/sprites/tiles/jeoseung_ground.png", "vars": ["res://assets/sprites/tiles/jeoseung_ground.png", "res://assets/sprites/tiles/jeoseung_ground.png", "res://assets/sprites/tiles/jeoseung_b.png", "res://assets/sprites/tiles/jeoseung_c.png"], "tint": Color(1, 1, 1), "base": Color("12141c"), "accent": Color("7ad8ff"), "border": Color("3a4a6a"), "mote": Color(0.6, 0.85, 1.0, 0.18)},  # 본 3 : 변형 1 : 1 — 본 타일을 더 자주(에셋 담당 권장 6 : 2 에 가깝게)
	]
	var _t: float = 0.0
	var _base: Color = Color("23202a")
	var _accent: Color = Color("ff8a3c")
	var _border: Color = Color("6a5a3a")
	var _theme_i: int = 0
	var _ground: Texture2D = null
	var _grounds: Array = []  # 기본+변형 타일 풀 — 셀 해시로 섞어 반복감 제거 (S7)
	var _prev_ground: Texture2D = null
	var _tint: Color = Color(1, 1, 1)
	var _prev_tint: Color = Color(1, 1, 1)
	var _fade: float = 1.0
	var _motes: CPUParticles2D
	# ── 재드로우 억제 (성능) ──
	# 예전엔 _process 가 매 프레임 queue_redraw() 라 타일 240장 + 얼룩 60장을 초당 120번 다시 그렸다.
	# 배경은 카메라가 크게 움직이기 전엔 내용이 안 바뀌므로, 화면보다 넓게 한 번 그려두고
	# 그 여유분(PAD)을 벗어날 때만 다시 그린다. 실측 기준 재드로우가 초당 120회 → 1회 미만.
	var _drawn_at: Vector2 = Vector2(1.0e9, 1.0e9)
	var _drawn_pad: float = 0.0
	var _drawn_half: Vector2 = Vector2.ZERO  # 그릴 때의 가시영역 절반 — 줌이 바뀌면 다시 그려야 한다
	var _drawn_fade: float = -1.0           # 그릴 때의 크로스페이드 진행도
	var _fx: _ArenaFx

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 픽셀 타일 크리스프
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # draw_texture_rect tile=true 타일링
		# 채도 빼기는 이 노드가 그리는 것 전부(타일·얼룩)에 한 번에 걸린다.
		# 배경은 카메라가 크게 움직일 때만 다시 그리므로 셰이더 비용은 사실상 0이다.
		# 절전에서는 바닥 셰이더를 통째로 뺀다 — 화면 전체를 덮는 면적이라 약한 GPU 에서
		# 제일 먼저 체감되는 비용이다. 대비는 몹 쪽(테두리·림라이트·lift)이 이미 책임진다.
		if (GROUND_DESAT > 0.0 or GROUND_FLATTEN > 0.0) and G.perf_level() > 0 and ResourceLoader.exists("res://assets/shaders/ground_desat.gdshader"):
			var m := ShaderMaterial.new()
			m.shader = load("res://assets/shaders/ground_desat.gdshader")
			m.set_shader_parameter("amount", GROUND_DESAT)
			material = m
		_fx = _ArenaFx.new()  # 맥동하는 글로우/경계선만 따로 — 얘만 매 프레임 갱신
		_fx.z_index = 1
		add_child(_fx)
		var th: Dictionary = THEMES[0]
		_base = th["base"]
		_accent = th["accent"]
		_border = th["border"]
		_tint = th["tint"]
		_ground = _load_ground(String(th["ground"]))
		_grounds = _load_pool(th)
		_push_ground_mean()   # _grounds 가 채워진 뒤여야 한다 (평균을 거기서 낸다)
		_motes = CPUParticles2D.new()
		# 모트는 아레나 전체(1720²)에 뿌려도 화면에 보이는 건 일부뿐이었다 — 화면 크기에 맞춰 줄인다.
		_motes.amount = 34 if G.mobile else 70
		_motes.lifetime = 9.0
		_motes.preprocess = 9.0
		_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_motes.emission_rect_extents = Vector2(900.0, 620.0)
		_motes.direction = Vector2(0.2, -1.0)
		_motes.spread = 25.0
		_motes.gravity = Vector2.ZERO
		_motes.initial_velocity_min = 5.0
		_motes.initial_velocity_max = 22.0
		_motes.scale_amount_min = 1.2
		_motes.scale_amount_max = 3.4
		_motes.color = th["mote"]
		# ★ z_index 는 부모 기준 상대값이다. _GridBg 자체가 -100 인데 여기서 -1 을 주면 -101 이 되어
		#   바로 위에서 그리는 불투명 배경 사각형에 통째로 가려진다 — 지금까지 먼지는 한 번도
		#   화면에 나온 적이 없으면서 파티클 계산만 돌고 있었다. +1 이라야 배경 위·개체 아래다.
		_motes.z_index = 1
		add_child(_motes)

	func _load_ground(path: String) -> Texture2D:
		if ResourceLoader.exists(path):
			return load(path)
		return null

	## 기본+변형 타일을 존재하는 것만 모아 풀 구성 — 변형 없으면 기본 1장(기존과 동일).
	## ★ 각 타일의 90/180/270도 회전본을 여기서 미리 구워 둔다. 예전엔 셀마다
	##   draw_set_transform 으로 돌렸는데 그게 드로우 배칭을 끊는 주범이었다.
	##   회전본은 테마 전환 때 한 번만 만들어지고 캐시된다.
	static var _rot_cache: Dictionary = {}

	func _rotations(tex: Texture2D, path: String) -> Array:
		if _rot_cache.has(path):
			return _rot_cache[path]
		var out: Array = [tex]
		var img: Image = tex.get_image()
		# 정사각 · 비압축일 때만 회전본을 만든다 (VRAM 압축 텍스처는 rotate_90 이 안 먹는다)
		if img != null and img.get_width() == img.get_height():
			if img.is_compressed():
				if img.decompress() != OK:
					img = null
			if img != null:
				for k in 3:
					var r := Image.new()
					r.copy_from(img)
					for _q in (k + 1):
						r.rotate_90(CLOCKWISE)
					out.append(ImageTexture.create_from_image(r))
				# 좌우 반전본도 — 예전 draw_set_transform 방식이 주던 변주(회전4×반전2=8종)를 그대로 복원
				for k2 in 4:
					var fl := Image.new()
					fl.copy_from(img)
					for _q2 in k2:
						fl.rotate_90(CLOCKWISE)
					fl.flip_x()
					out.append(ImageTexture.create_from_image(fl))
		_rot_cache[path] = out
		return out

	func _load_pool(th: Dictionary) -> Array:
		var pool: Array = []
		var paths: Array = [String(th["ground"])]
		for vp in th.get("vars", []):
			paths.append(String(vp))
		for path: String in paths:
			var t: Texture2D = _load_ground(path)
			if t != null:
				pool.append_array(_rotations(t, path))
		return pool

	## 웨이브마다 테마 전환 (바닥 타일 크로스페이드 + 색 트윈)
	func set_theme(i: int) -> void:
		_theme_i = i % THEMES.size()
		var th: Dictionary = THEMES[_theme_i]
		if _motes != null:
			_motes.color = th["mote"]
		_prev_ground = _ground
		_prev_tint = _tint
		_ground = _load_ground(String(th["ground"]))
		_grounds = _load_pool(th)
		_tint = th["tint"]
		_push_ground_mean()
		_fade = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "_base", th["base"], 1.2)
		tw.tween_property(self, "_accent", th["accent"], 1.2)
		tw.tween_property(self, "_border", th["border"], 1.2)
		tw.tween_property(self, "_fade", 1.0, 1.0)

	## 바닥 타일 풀의 평균색. 결 누르기(flatten)가 이 색 쪽으로 당긴다.
	## 타일마다 한 번만 재고 캐시한다 — 테마 순환 때 다시 계산하지 않게.
	static var _mean_cache: Dictionary = {}

	func _ground_mean() -> Color:
		var acc := Color(0, 0, 0, 0)
		var n: int = 0
		for tx in _grounds:
			var t := tx as Texture2D
			if t == null:
				continue
			var key: String = t.resource_path
			var c: Color
			if key != "" and _mean_cache.has(key):
				c = _mean_cache[key]
			else:
				c = _tex_mean(t)
				if key != "":
					_mean_cache[key] = c
			acc += c
			n += 1
		if n == 0:
			return Color(0.2, 0.2, 0.2)
		return Color(acc.r / n, acc.g / n, acc.b / n)

	static func _tex_mean(t: Texture2D) -> Color:
		var img: Image = t.get_image()
		if img == null:
			return Color(0.2, 0.2, 0.2)
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var buf: PackedByteArray = img.get_data()
		var r: float = 0.0
		var g: float = 0.0
		var b: float = 0.0
		var n: int = 0
		var i: int = 0
		while i < buf.size():
			if buf[i + 3] >= 200:
				r += float(buf[i])
				g += float(buf[i + 1])
				b += float(buf[i + 2])
				n += 1
			i += 4
		if n == 0:
			return Color(0.2, 0.2, 0.2)
		return Color(r / float(n) / 255.0, g / float(n) / 255.0, b / float(n) / 255.0)

	func _push_ground_mean() -> void:
		var c: Color = _ground_mean()
		# 몹 테두리 색이 이 밝기를 보고 뒤집힌다 — 어두운 맵이면 밝은 테두리.
		# 화면에 실제로 나오는 밝기여야 하므로 색조·GROUND_DIM·칸밝기를 다 곱해서 넘긴다.
		var k: float = 0.91 * GROUND_DIM
		var lit := Color(c.r * _tint.r * k, c.g * _tint.g * k, c.b * _tint.b * k)
		CreatureVisual.set_world_luma(0.2126 * lit.r + 0.7152 * lit.g + 0.0722 * lit.b)
		var m := material as ShaderMaterial
		if m == null:
			return
		m.set_shader_parameter("base_col", Vector3(c.r, c.g, c.b))
		m.set_shader_parameter("flatten", GROUND_FLATTEN)

	func theme_name() -> String:
		return String(THEMES[_theme_i]["name"])

	## 카메라가 지금 보고 있는 월드 중심.
	func _cam_center() -> Vector2:
		var vp := get_viewport()
		return vp.get_canvas_transform().affine_inverse() * (vp.get_visible_rect().size * 0.5)

	func _process(delta: float) -> void:
		_t += delta
		var c: Vector2 = _cam_center()
		if _motes != null:
			_motes.position = c  # 모트가 카메라를 따라다닌다(좁은 방출 영역으로도 화면이 안 빈다)
		# 그려둔 여유분을 벗어났거나, 화면 크기·줌이 바뀌었거나, 테마 크로스페이드 중일 때만 다시 그린다.
		var vp := get_viewport()
		var inv := vp.get_canvas_transform().affine_inverse()
		var hh: Vector2 = ((inv * vp.get_visible_rect().size) - (inv * Vector2.ZERO)).abs() * 0.5
		# ★ _fade < 1.0 조건만 두면 페이드가 정확히 1.0 이 되는 프레임에 마지막 갱신을 못 해서
		#   바닥이 83% 상태로 굳었다가 나중에 툭 튄다. 마지막으로 그린 값과 달라졌으면 무조건 다시 그린다.
		if _fade != _drawn_fade or c.distance_to(_drawn_at) > _drawn_pad or hh.distance_to(_drawn_half) > 4.0:
			queue_redraw()

	## 결정론적 셀 해시 (좌표별 회전/반전/밝기 변주 → 반복 격자·환공포증 제거)
	func _cell_hash(x: int, y: int) -> int:
		var h: int = (x * 73856093) ^ (y * 19349663)
		h = (h ^ (h >> 13)) * 1274126177
		return absi(h)

	## 부드러운 대형 얼룩(동심원으로 그라데이션 흉내).
	## 겹 수가 곧 반투명 오버드로 배수라, 모바일에서는 2겹으로 줄인다(눈에 거의 안 띈다).
	## ★ 2026-09-15: 겹을 **같은 알파로** 쌓고 있었다. 가장자리를 부드럽게 하려고 원을 4장
	##   겹쳐 그리는 건데, 알파가 그대로면 가운데는 1-(1-a)⁴ ≈ 4a 가 된다. 얼룩 반경이
	##   190~400 이고 간격이 470 이라 이웃끼리도 겹쳐서, 밝은 얼룩 몇 개가 만나면
	##   화면 대부분에 뿌연 막이 깔린다 — 배경 대비를 통째로 죽이던 주범이다(스크린샷 확인).
	##   합쳐서 원래 의도한 알파가 되도록 겹 수로 나눠 준다.
	func _soft_blob(c: Vector2, r: float, col: Color) -> void:
		var layers: int = 2 if G.mobile else 4
		var step: float = 0.46 if G.mobile else 0.23
		var a: float = 1.0 - pow(1.0 - clampf(col.a, 0.0, 1.0), 1.0 / float(layers))
		var lc := Color(col.r, col.g, col.b, a)
		for k in layers:
			draw_circle(c, r * (1.0 - float(k) * step), lc)

	func _draw() -> void:
		# 19차 3-2: 바닥 그리기에서 화면 전체를 덮는 칠이 넷이었다(바탕 사각형 · 타일 · 분위기 원 둘). GT 710 1080p 에서
		#   바닥 하나가 프레임의 7.6ms 였다(--physprof). 아레나 안은 타일이 빈틈없이 덮으므로 바탕 사각형은
		#   타일이 비치는 테마 전환 때만 그린다. 아레나 밖은 아래 공허 사각형 넷이 덮는다.
		if _fade < 1.0 or _grounds.is_empty() or old_draw_test:
			draw_rect(Rect2(-3200, -3200, 6400, 6400), _base, true)
		var inv := get_viewport().get_canvas_transform().affine_inverse()
		var vp: Vector2 = get_viewport().get_visible_rect().size
		var w0: Vector2 = inv * Vector2.ZERO
		var w1: Vector2 = inv * vp
		# ★ 화면보다 한 뼘 넓게 그려 둔다 — 이 여유분 덕에 걸어다니는 동안 재드로우가 없다.
		var vhalf: Vector2 = (w1 - w0).abs() * 0.5
		_drawn_at = _cam_center()
		_drawn_half = vhalf
		_drawn_fade = _fade
		# 여유분 1.45배 중 0.40배까지만 움직이고 다시 그린다 — 한 프레임 지연을 감안한 안전 마진
		_drawn_pad = minf(vhalf.x, vhalf.y) * 0.40
		var pad: Vector2 = vhalf * 1.45
		w0 = _drawn_at - pad
		w1 = _drawn_at + pad
		# 가시영역을 아레나 안으로 클램프 — 밖은 바닥/얼룩 안 그림 → 어두운 공허
		var axmin: float = maxf(minf(w0.x, w1.x), -ARENA)
		var axmax: float = minf(maxf(w0.x, w1.x), ARENA)
		var aymin: float = maxf(minf(w0.y, w1.y), -ARENA)
		var aymax: float = minf(maxf(w0.y, w1.y), ARENA)
		var inside: bool = axmax > axmin and aymax > aymin
		# 타일 바닥 — 아레나 안 가시영역만. 셀별 변주는 유지하되 draw_set_transform 을 쓰지 않는다.
		# ★ 예전엔 셀마다 draw_set_transform 을 넣어 회전/반전을 줬는데, 이 명령이 캔버스 배칭을
		#   끊어서 같은 텍스처인데도 타일 수만큼 드로우 콜이 나갔다(가시영역 240칸 = 240콜).
		#   회전본을 로드 시점에 미리 구워두고(_grounds 가 이미 회전 변형을 포함) 텍스처별로 모아 그리면
		#   드로우 콜이 텍스처 종류 수(보통 8~20)로 떨어진다.
		if not _grounds.is_empty() and inside:
			var cx0: int = int(floor(axmin / TILE))
			var cx1: int = int(ceil(axmax / TILE))
			var cy0: int = int(floor(aymin / TILE))
			var cy1: int = int(ceil(aymax / TILE))
			var n: int = _grounds.size()
			var buckets: Array = []
			buckets.resize(n)
			for i in n:
				buckets[i] = []
			for cy in range(cy0, cy1):
				for cx in range(cx0, cx1):
					var hsh: int = _cell_hash(cx, cy)
					# 칸별 밝기 변주 폭도 0.34 → 0.18 로 줄인다. 반복 격자를 깨려고 넣은
					# 장치인데, 폭이 넓으니 밝은 칸이 몹만큼 눈에 띄어 시선을 뺏고 있었다.
					var b: float = (0.92 + float((hsh >> 3) & 31) / 31.0 * 0.08) * GROUND_DIM   # 16차: 변주 폭 0.18 → 0.08(새 타일은 변형 둘로 되풀이를 깬다)
					(buckets[(hsh >> 8) % n] as Array).append([
						Vector2(float(cx) * TILE, float(cy) * TILE),
						Color(_tint.r * b, _tint.g * b, _tint.b * b, _fade),
					])
			for i in n:
				var tex: Texture2D = _grounds[i]
				for cell: Array in (buckets[i] as Array):
					draw_texture_rect(tex, Rect2(cell[0], Vector2(TILE, TILE)), false, cell[1])
		# 대형 저주파 얼룩(밝고 어두운 패치)
		var MC := 470.0
		# 16차 4-3: 큰 얼룩은 반투명 원 네 겹이라 저사양 그래픽(GT 710)에서 프레임의 약 10% 를 먹었다 — 「최대」에서만 그린다.
		#   새 바닥 타일은 변형 둘을 섞어 되풀이가 덜 보여서 얼룩 없이도 단조롭지 않다.
		if inside and not no_blob_test and G.perf_level() >= 2:
			for by in range(int(floor(aymin / MC)), int(ceil(aymax / MC)) + 1):
				for bx in range(int(floor(axmin / MC)), int(ceil(axmax / MC)) + 1):
					var mh: int = _cell_hash(bx * 11 + 5, by * 17 + 9)
					var mp := Vector2((float(bx) + 0.5) * MC + float(mh % 300) - 150.0, (float(by) + 0.5) * MC + float((mh >> 9) % 300) - 150.0)
					var mr: float = 190.0 + float((mh >> 4) % 210)
					var ia: float = (0.03 + 0.035 * float((mh >> 18) % 100) / 100.0) * _fade
					var mcol := Color(0, 0, 0, ia) if (mh & 1) == 0 else Color(0.92, 0.86, 0.78, ia * 0.6)
					_soft_blob(mp, mr, mcol)
		# 아레나 밖을 공허로 덮기 (엣지 타일 넘침 가림)
		var VB := 3200.0
		draw_rect(Rect2(-VB, -VB, VB * 2.0, VB - ARENA), _base, true)
		draw_rect(Rect2(-VB, ARENA, VB * 2.0, VB - ARENA), _base, true)
		draw_rect(Rect2(-VB, -ARENA, VB - ARENA, ARENA * 2.0), _base, true)
		draw_rect(Rect2(ARENA, -ARENA, VB - ARENA, ARENA * 2.0), _base, true)
		# 중앙 글로우 · 경계 벽은 _ArenaFx 가 따로 그린다 (맥동 때문에 매 프레임 갱신이 필요해서,
		# 타일/얼룩과 같은 _draw 에 두면 배경 전체가 초당 60번 다시 그려진다)
		if _fx != null:
			_fx.tint(_accent, _border)


## 맥동하는 중앙 글로우 + 아레나 경계선만 담당. 드로우 명령 5개짜리라 매 프레임 갱신해도 싸다.
class _ArenaFx extends Node2D:
	const ARENA: float = 1500.0
	var _t: float = 0.0
	var _accent: Color = Color("ff8a3c")
	var _border: Color = Color("6a5a3a")

	func tint(a: Color, b: Color) -> void:
		_accent = a
		_border = b
		queue_redraw()

	var _acc: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		# 맥동 주기가 4~12초라 초당 12번만 갱신해도 눈으로 구분이 안 된다. 대면적 알파 채우기라
		# 매 프레임 다시 그리면 모바일 GPU 에서 가장 비싼 종류의 오버드로가 된다.
		_acc += delta
		if _acc >= 0.083:
			_acc = 0.0
			queue_redraw()

	func _draw() -> void:
		# ★ 2026-09-15: 이 두 원은 아레나 '분위기'용인데 반지름이 1425·750 이라 사실상
		#   **플레이 화면 전체**에 강조색 막을 씌운다. 겹치는 한가운데는 9~11% 였다.
		#   용암동굴 강조색이 ff5a3c(밝은 주황)라, 그 막이 그대로 배경 밝기가 되고
		#   그 위의 몹·탄환이 묻힌다. 분위기는 남기되 3분의 1로 줄인다.
		# 19차 3-2: 두 원은 화면 전체를 덮는 반투명 칠 두 겹이다(알파 1.4~2.6%). 「최대」에서만 — 큰 얼룩과 같은 규칙.
		if G.perf_level() >= 2 or _GridBg.old_draw_test:
			draw_circle(Vector2.ZERO, ARENA * 0.95, Color(_accent.r, _accent.g, _accent.b, 0.018 + 0.008 * sin(_t * 0.5)))
			draw_circle(Vector2.ZERO, ARENA * 0.5, Color(_accent.r, _accent.g, _accent.b, 0.014 + 0.008 * sin(_t * 0.5 + 1.0)))
		var arect := Rect2(-ARENA, -ARENA, ARENA * 2.0, ARENA * 2.0)
		var wp: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 1.6))
		draw_rect(arect, Color(_accent.r, _accent.g, _accent.b, 0.13 * wp), false, 26.0)  # 바깥 글로우
		draw_rect(arect, Color(_border.r, _border.g, _border.b, 0.98), false, 9.0)         # 메인 벽
		draw_rect(arect, Color(1, 1, 1, 0.5 * wp), false, 2.0)                             # 안쪽 밝은 라인


# ---------------------------------------------------------------- HUD
## HUD 스케일러: scale=s, size=화면/s — 인터페이스 크기(설정)만큼 전체 HUD가 커진다.
## 요소 위치는 앵커/매 프레임 갱신이라 어떤 화면비·배율에서도 안 잘림. (S1 가독성)
## ★ 18차: 결과 판(클리어 · 무한 완주 · 게임오버)이 화면보다 크면 통째로 줄인다. 단추 줄은 언제나 화면 안.
##   두 단으로 바꿔도 영어 · 「아주 크게」 · 해금 다섯 같은 겹침은 또 넘칠 수 있다 — 마지막 안전장치.
##   최소 크기는 한 프레임 뒤에야 맞는다(방금 채운 표 · 카드). --resultfit 이 최악값으로 잰다.
func _fit_result_panel(panel: Control) -> void:
	if panel == null or not is_instance_valid(panel) or _hud_layer == null:
		return
	panel.scale = Vector2.ONE
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var ms: Vector2 = panel.get_combined_minimum_size()
	var avail: Vector2 = _hud_layer.size - Vector2(32.0, 32.0)
	var k: float = minf(1.0, minf(avail.x / maxf(1.0, ms.x), avail.y / maxf(1.0, ms.y)))
	panel.pivot_offset = ms * 0.5
	panel.scale = Vector2(k, k)


func _update_hud_scale() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if _hud_layer != null:
		var s: float = G.hud_scale()
		# ★ 14차: 부품 HUD 는 목업(hud.png)이 1920 화면에 ×2 로 그렸다. 우리 논리 좌표(1280)에 부품 ×2 를 그대로 두면
		#   1920 에서 ×3 이 되어 시계 · 칸 · 처치판이 목업보다 1.5배 컸다. 보통 / 크게 / 아주 크게 = 화면 ×2 / ×3 / ×4.
		#   PC 기본은 보통(목업 크기), 폰 기본은 크게(손가락 거리에서 읽히게).
		if UiParts.on():
			s = G.hud_layer_scale(vp)   # 11/5: 모니터 기준(창이 작아도 글자 · 막대가 안 줄어든다) — game.gd 설명
		# 13차 4절: 폰은 안전 영역 안으로 — 가로 화면 양옆 카메라 구멍 · 둥근 모서리에 HUD 글자가 가렸다
		var ins: Vector4 = _safe_insets(vp)
		_hud_layer.scale = Vector2(s, s)
		_hud_layer.size = (vp - Vector2(ins.x + ins.z, ins.y + ins.w)) / s
		_hud_layer.position = Vector2(ins.x, ins.y)
	if _levelup_root != null:
		# 레벨업 카드는 과확대 시 4장이 안 들어감 → 폭 기준 자동 상한
		# 14차: 부품이 있으면 HUD 와 같은 배수(PC 보통 = 2/3 → 1920 좌표 = 목업 숫자) — _modal_scale
		var s2: float = _modal_scale()
		_levelup_root.scale = Vector2(s2, s2)
		_levelup_root.size = vp / s2
		_levelup_root.position = Vector2.ZERO
	if _victory != null and _victory.visible:
		_fit_result_panel(_vic_panel)
	if _gameover != null and _gameover.visible:
		_fit_result_panel(_go_panel)


## 안전 영역 여백(왼 · 위 · 오른 · 아래, 화면 기준 좌표). 폰만 — PC 창은 화면 전체가 아니라 계산이 맞지 않는다.
func _safe_insets(vp: Vector2) -> Vector4:
	if not (G.mobile and OS.has_feature("mobile")):
		return Vector4.ZERO
	var sa: Rect2i = DisplayServer.get_display_safe_area()
	var ss: Vector2i = DisplayServer.screen_get_size()
	var win: Vector2i = get_window().size
	if sa.size.x <= 0 or win.x <= 0:
		return Vector4.ZERO
	var k: float = vp.x / float(win.x)
	return Vector4(
		clampf(float(sa.position.x) * k, 0.0, 120.0), clampf(float(sa.position.y) * k, 0.0, 120.0),
		clampf(float(ss.x - sa.end.x) * k, 0.0, 120.0), clampf(float(ss.y - sa.end.y) * k, 0.0, 120.0))


## 가장자리 비네트 — 위 · 아래 · 왼 · 오른 띠 넷(가장자리 alpha → 안쪽 0). 모서리는 두 띠가 겹쳐 조금 더 어둡다(방사형과 비슷).
func _edge_vignette(alpha: float) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# [앵커 왼 · 위 · 오른 · 아래, 그러데이션 시작(진한 쪽) → 끝]
	for b: Array in [[0.0, 0.0, 1.0, 0.13, Vector2(0.5, 0.0), Vector2(0.5, 1.0)],
			[0.0, 0.87, 1.0, 1.0, Vector2(0.5, 1.0), Vector2(0.5, 0.0)],
			[0.0, 0.13, 0.09, 0.87, Vector2(0.0, 0.5), Vector2(1.0, 0.5)],
			[0.91, 0.13, 1.0, 0.87, Vector2(1.0, 0.5), Vector2(0.0, 0.5)]]:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, alpha))
		g.set_color(1, Color(0, 0, 0, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = b[4]
		gt.fill_to = b[5]
		gt.width = 64
		gt.height = 64
		var tr := TextureRect.new()
		tr.texture = gt
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.anchor_left = b[0]
		tr.anchor_top = b[1]
		tr.anchor_right = b[2]
		tr.anchor_bottom = b[3]
		root.add_child(tr)
	return root


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_canvas = layer
	_hud_layer = Control.new()
	_hud_layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hud_layer)
	get_viewport().size_changed.connect(_update_hud_scale)
	G.ui_scale_changed.connect(_update_hud_scale)

	# 모바일: 게임 중 일시정지 버튼 (우상단) — ESC 대체
	if _mobile:
		var pbtn := Button.new()
		pbtn.text = "II"
		UiFont.apply(pbtn, 26)
		pbtn.anchor_left = 1.0
		pbtn.anchor_right = 1.0
		pbtn.offset_left = -80.0
		pbtn.offset_top = 14.0
		pbtn.offset_right = -14.0
		pbtn.offset_bottom = 80.0
		pbtn.focus_mode = Control.FOCUS_NONE
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.1, 0.1, 0.14, 0.66)
		psb.set_corner_radius_all(12)
		psb.set_border_width_all(2)
		psb.border_color = UiKit.ACCENT
		pbtn.add_theme_stylebox_override("normal", psb)
		pbtn.add_theme_stylebox_override("hover", psb)
		pbtn.add_theme_stylebox_override("pressed", psb)
		pbtn.add_theme_color_override("font_color", UiKit.ACCENT)
		UiParts.style_button(pbtn, "normal")     # 14차: 다른 버튼과 같은 나무 패
		pbtn.pressed.connect(func() -> void:
			if _pause_menu != null:
				_pause_menu._toggle()
		)
		_hud_layer.add_child(pbtn)

	# 비네트 (가장자리 어둡게 — 화면 집중감)
	# ★ 11/7 프레임: 화면 전체 방사형 반투명 판 하나가 GT 710 · 1080p 에서 2.5ms 를 먹었다(--physprof 「기본 비네트만 끔」
	#   48 → 55fps). 가운데는 거의 투명한데도 화면 전체를 칠했다. 가장자리 네 띠로 바꿔 칠하는 면적을 절반쯤으로 줄인다.
	_base_vig = _edge_vignette(0.24)
	_hud_layer.add_child(_base_vig)

	# 저체력 경고 비네트 (체력 30% 미만 시 붉게 맥동 — 위기 가독성)
	var rg := Gradient.new()
	rg.set_color(0, Color(0.9, 0.05, 0.05, 0.0))
	rg.set_color(1, Color(0.9, 0.05, 0.05, 0.55))
	var rgt := GradientTexture2D.new()
	rgt.gradient = rg
	rgt.fill = GradientTexture2D.FILL_RADIAL
	rgt.fill_from = Vector2(0.5, 0.5)
	rgt.fill_to = Vector2(1.0, 0.5)
	rgt.width = 320
	rgt.height = 320
	_lowhp_vig = TextureRect.new()
	_lowhp_vig.texture = rgt
	_lowhp_vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lowhp_vig.stretch_mode = TextureRect.STRETCH_SCALE
	_lowhp_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lowhp_vig.modulate.a = 0.0
	_hud_layer.add_child(_lowhp_vig)

	_levelup_flash = ColorRect.new()
	_levelup_flash.color = Color(1, 1, 1, 0.0)
	_levelup_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_levelup_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_levelup_flash)
	# 17-1: 맞으면 화면 가장자리가 붉게 번쩍(깎인 양만큼), 30% 아래에선 은은하게 맥동 — 체력은 발밑 막대만 남아 있어 놓치기 쉬웠다
	_hurt_vig = UiKit.vignette()
	_hurt_vig.modulate = Color(1.0, 0.12, 0.10, 0.0)
	# 가운데 8할은 완전히 비우고 바깥 띠만 붉힌다 — 기본 비네트(가운데→끝 직선)를 그대로 쓰면 화면 전체가 붉게 덮였다(첫 시험 컷)
	var hg: Gradient = (_hurt_vig.texture as GradientTexture2D).gradient
	hg.set_color(0, Color(1, 1, 1, 0.0))
	hg.set_color(1, Color(1, 1, 1, 0.75))
	hg.add_point(0.80, Color(1, 1, 1, 0.0))
	_hud_layer.add_child(_hurt_vig)

	# ── 13차 4절: 전투 HUD 배치 (에셋 담당 검토 · Vampire Survivors · HoloCure 비교) ──
	# ★ 예전엔 위 왼쪽에 글자 다섯 줄(시간 · 웨이브 · 처치 · 레벨 · 골드)이 아이콘 없이 쌓였고, 경험치는 맨 위 8px 선,
	#   체력은 왼쪽 아래 구석, 지금 든 무기는 일시정지에서만 보였다.
	#   이제: 맨 위 화면 너비 경험치 막대 + 끝에 LV · 가운데 위 큰 타이머(밑에 웨이브 · 보스 예고) ·
	#   왼쪽 위 체력 · 대시 고리 · 무기 칸 · 패시브 칸 · 오른쪽 위 골드 · 처치 · 주인공 발밑 체력 막대(player.gd).
	var center := VBoxContainer.new()
	_hud_center = center
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	center.offset_left = -260.0
	center.offset_right = 260.0
	center.offset_top = 28.0
	center.add_theme_constant_override("separation", 0)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(center)
	# 19차 2절: 시계 · 웨이브 받침(hud_plate 9조각, UI ×2). 몹이 위쪽으로 몰리면 글자 뒤로 몹이 지나가 묻혔다.
	#   글자 둘레 그린 크기 4px(UI 8) 여유, 몹이 살짝 비치게 알파 0.85. 그림이 없으면 예전처럼 글자만.
	var tw_holder: Control = center
	var plate_sb: StyleBoxTexture = UiParts.box("hud_plate", 2, 0, 8.0)
	if plate_sb != null:
		var plate := PanelContainer.new()
		plate.name = "HudPlate"
		plate.add_theme_stylebox_override("panel", plate_sb)
		plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		plate.self_modulate = Color(1, 1, 1, 0.85)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(plate)
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", 0)
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(pv)
		tw_holder = pv
	_lbl_time = _mk_label(tw_holder, 40)
	_lbl_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if UiParts.on():
		_lbl_time.add_theme_color_override("font_color", UiParts.BRASS_HI)   # 목업: 놋쇠색 시계
		_lbl_time.add_theme_constant_override("outline_size", 2)
	_lbl_wave = _mk_label(tw_holder, 20 if UiParts.on() else 16)
	_lbl_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_wave.add_theme_color_override("font_color", Color("c9c2dc"))
	# ★ 보스 예고 — 빨간 글자. 배너는 한 번 지나가면 끝이라 "언제 오는지"를 못 준다.
	#   유저 요구: "보스 뜨기 10초 전에 빨간색 글자로 시간을 표현"(2026-09-07). 13차부터 타이머 밑.
	_lbl_bosseta = _mk_label(center, 20)
	_lbl_bosseta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_bosseta.add_theme_color_override("font_color", Color("ff2d55"))
	_lbl_bosseta.visible = false
	# 오른쪽 위: 골드 · 처치 (아이콘 + 숫자). 모바일은 일시정지 버튼 왼쪽으로
	# 14차: 목업처럼 작은 옻칠 판(panel_small) 안에 「처치 · 엽전」 — 이름 왼쪽 · 숫자 오른쪽
	var kpanel := PanelContainer.new()
	var ksb: StyleBoxTexture = UiParts.panel_box(true)
	if ksb != null:
		kpanel.add_theme_stylebox_override("panel", ksb)
	else:
		kpanel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	kpanel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	kpanel.offset_left = -232.0 - (80.0 if _mobile else 0.0)
	kpanel.offset_right = -12.0 - (80.0 if _mobile else 0.0)
	kpanel.offset_top = 26.0
	kpanel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	kpanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(kpanel)
	var right := GridContainer.new()
	right.columns = 2
	right.add_theme_constant_override("h_separation", 18)
	right.add_theme_constant_override("v_separation", 0)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kpanel.add_child(right)
	for which in ["kills", "gold"]:
		# 16차 U5: 「처치」 · 「골드」 글자 자리에 해골 · 엽전 12px(목업 hud.png 자리). 그림이 없으면 글자.
		var ic: TextureRect = UiParts.icon("skull" if which == "kills" else "coin", 12)
		if ic.texture != null:
			right.add_child(ic)
		else:
			var nm := _mk_label(right, 20)
			nm.text = I18n.t("처치") if which == "kills" else I18n.t("골드")
			nm.add_theme_color_override("font_color", UiParts.PAPER_D)
		var lb := _mk_label(right, 24)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lb.custom_minimum_size = Vector2(110, 0)
		lb.add_theme_color_override("font_color", UiParts.PAPER_HI)
		if which == "gold":
			_lbl_gold = lb
		else:
			_lbl_kills = lb
	# 왼쪽 위: 체력 막대(아래 _update_hud 에서 자리) 다음 줄부터 무기 칸 · 패시브 칸 · 신화/융합 이름
	var left := VBoxContainer.new()
	left.position = Vector2(12, 60 if not UiParts.on() else 30)
	left.add_theme_constant_override("separation", 4)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(left)
	_slots_w = HBoxContainer.new()
	_slots_w.add_theme_constant_override("separation", 4)
	_slots_w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_slots_w)
	_slots_p = HBoxContainer.new()
	_slots_p.add_theme_constant_override("separation", 4)
	_slots_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_slots_p)
	# ★ 신화/융합은 판을 뒤집는 한 장인데 먹고 나면 화면 어디에도 안 남았다 —
	#   "신화를 먹었는데 아무 표시가 없어서 더 혼란스럽다"(실플레이 리포트). 상시 한 줄로 박는다.
	_lbl_crown = _mk_label(left, 16)
	_lbl_crown.add_theme_color_override("font_color", Color("ff8df2"))
	_lbl_crown.visible = false
	# 경험치 막대 끝의 LV
	_lbl_level = _mk_label(_hud_layer, 20)
	_lbl_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_level.add_theme_color_override("font_color", Color("9dff6b"))
	if UiParts.on():
		UiFont.apply(_lbl_level, 24)       # 목업: 경험치 막대 끝 놋쇠 「LV 12」
		_lbl_level.add_theme_color_override("font_color", UiParts.BRASS_HI)

	# 킬 콤보 카운터 (우상단 — 연쇄 처치 시 팡팡 커짐)
	_combo_lbl = Label.new()
	UiFont.apply(_combo_lbl, 34)
	_combo_lbl.add_theme_color_override("font_color", Color("ffd54a"))
	_combo_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_combo_lbl.add_theme_constant_override("outline_size", 7)
	_combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_lbl.anchor_left = 1.0
	_combo_lbl.anchor_right = 1.0
	_combo_lbl.offset_left = -260.0
	_combo_lbl.offset_right = -16.0
	_combo_lbl.offset_top = 96.0 + 16.0
	_combo_lbl.pivot_offset = Vector2(230.0, 20.0)
	_combo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_lbl.visible = false
	_hud_layer.add_child(_combo_lbl)
	_combo_px = FxLib.pixel_row(["#0", FxLib.word_sheet("w_combo")], 2, Color("ffd54a"))
	if _combo_px != null:
		_combo_num = _combo_px.get_child(0) as PixelText
		_combo_px.alignment = BoxContainer.ALIGNMENT_END
		_combo_px.anchor_left = 1.0
		_combo_px.anchor_right = 1.0
		_combo_px.offset_left = -260.0
		_combo_px.offset_right = -16.0
		_combo_px.offset_top = 100.0 + 16.0
		_combo_px.pivot_offset = Vector2(230.0, 14.0)
		_combo_px.visible = false
		_hud_layer.add_child(_combo_px)
	G.combo_changed.connect(_on_combo_changed)

	# XP 바 — 맨 위 화면 너비(끝에 LV 자리를 남긴다), 높이 16(막대 그림 8 × 2). 폭은 _update_hud 에서 화면폭 추종
	_xp_bg = ColorRect.new()
	_xp_bg.color = Color(0, 0, 0, 0.45)
	_xp_bg.position = Vector2(XP_X, XP_Y)
	_xp_bg.size = Vector2(1180, XP_H)
	_hud_layer.add_child(_xp_bg)
	_xp_fill = ColorRect.new()
	_xp_fill.color = Color("7dff9b")
	_xp_fill.position = Vector2(XP_X, XP_Y)
	_xp_fill.size = Vector2(0, XP_H)
	_hud_layer.add_child(_xp_fill)

	# HP 바 — 왼쪽 위 작게(숫자만 읽는 곳). 눈이 가는 자리는 주인공 발밑 막대(player.gd)
	_hp_bg = ColorRect.new()
	_hp_bg.color = Color(0, 0, 0, 0.5)
	_hp_bg.size = Vector2(HP_W, 16)
	_hud_layer.add_child(_hp_bg)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color("ff5c6a")
	_hp_fill.size = Vector2(HP_W, 16)
	_hud_layer.add_child(_hp_fill)
	_hp_lbl = Label.new()
	UiFont.apply(_hp_lbl, 16)
	_hp_lbl.add_theme_color_override("font_color", Color.WHITE)
	_hp_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hp_lbl.add_theme_constant_override("outline_size", 4)
	_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_lbl.size = Vector2(HP_W, 16)
	_hud_layer.add_child(_hp_lbl)

	# 대시 — HP 바 오른쪽 원형 고리(차오르는 호). 예전 글자 막대 「대시 OK」는 숨긴다(13차 4절)
	_dash_badge = IconBadge.new().setup("dashcd", 26.0)
	_hud_layer.add_child(_dash_badge)
	_dash_ring = _HudRing.new()
	_dash_ring.size = Vector2(34, 34)
	_dash_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_dash_ring)
	# 14차 U4: 대시 8칸 고리 + 「대시」 글자(왼쪽 아래, 목업)
	_parts_hud = UiParts.on()
	_dash_px = HBoxContainer.new()
	_dash_px.add_theme_constant_override("separation", 8)
	_dash_px.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_px.visible = _parts_hud
	_hud_layer.add_child(_dash_px)
	_dash_tex = TextureRect.new()
	_dash_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dash_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_tex.texture = UiParts.tex("dash_ring", 7)
	_dash_px.add_child(_dash_tex)
	var dl := _mk_label(_dash_px, 20)
	dl.text = I18n.t("대시")
	dl.add_theme_color_override("font_color", UiParts.PAPER)
	dl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dash_bg = ColorRect.new()
	_dash_bg.color = Color(0, 0, 0, 0.5)
	_dash_bg.size = Vector2(120, 22)
	_hud_layer.add_child(_dash_bg)
	_dash_fill = ColorRect.new()
	_dash_fill.color = Color("5cc0ff")
	_dash_fill.size = Vector2(0, 22)
	_hud_layer.add_child(_dash_fill)
	_dash_lbl = Label.new()
	UiFont.apply(_dash_lbl, 13)
	_dash_lbl.add_theme_color_override("font_color", Color.WHITE)
	_dash_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_dash_lbl.add_theme_constant_override("outline_size", 4)
	_dash_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_lbl.size = Vector2(120, 20)
	_hud_layer.add_child(_dash_lbl)
	for n0: CanvasItem in [_dash_bg, _dash_fill, _dash_lbl]:
		n0.visible = false

	# 융합 보스 체력바 (화면 상단 중앙 — 중심은 _update_hud에서 화면폭 추종)
	_fusion_root = Control.new()
	_fusion_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fusion_root.visible = false
	_fusion_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_fusion_root)
	_fusion_lbl = Label.new()
	UiFont.apply(_fusion_lbl, 24)
	_fusion_lbl.add_theme_color_override("font_color", Color("ff6a80"))
	_fusion_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_fusion_lbl.add_theme_constant_override("outline_size", 5)
	_fusion_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fusion_lbl.position = Vector2(290, 28)
	_fusion_lbl.size = Vector2(700, 30)
	_fusion_root.add_child(_fusion_lbl)
	_fusion_bg = ColorRect.new()
	_fusion_bg.color = Color(0, 0, 0, 0.6)
	_fusion_bg.position = Vector2(288, 60)
	_fusion_bg.size = Vector2(704, 26)
	_fusion_root.add_child(_fusion_bg)
	_fusion_fill = ColorRect.new()
	_fusion_fill.color = Color("ff3860")
	_fusion_fill.position = Vector2(292, 62)
	_fusion_fill.size = Vector2(696, 22)
	_fusion_root.add_child(_fusion_fill)
	_fusion_tbg = ColorRect.new()
	_fusion_tbg.color = Color(0.30, 0.27, 0.36, 0.9)
	_fusion_tbg.size = Vector2(704, 8)
	_fusion_root.add_child(_fusion_tbg)
	_fusion_tfill = ColorRect.new()
	_fusion_tfill.color = Color(1, 1, 1, 0.9)
	_fusion_tfill.size = Vector2(696, 4)
	_fusion_root.add_child(_fusion_tfill)

	# 몰려드는 요괴 게이지 — 2026-10-06 사용자: 융합 보스는 초가 아니라 '너무 많이 쌓였다'는 느낌이 드는 게이지로.
	_swarm_root = Control.new()
	_swarm_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_swarm_root.visible = false
	_swarm_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_swarm_root)
	_swarm_lbl = Label.new()
	UiFont.apply(_swarm_lbl, 18)
	_swarm_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_swarm_lbl.add_theme_constant_override("outline_size", 5)
	_swarm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_swarm_lbl.size = Vector2(700, 24)
	_swarm_root.add_child(_swarm_lbl)
	_swarm_bg = ColorRect.new()
	_swarm_bg.color = Color(0.30, 0.27, 0.36, 0.9)   # 어두운 바닥에서도 게이지 전체 길이가 보이게
	_swarm_bg.size = Vector2(SWARM_W, 16)
	_swarm_root.add_child(_swarm_bg)
	_swarm_fill = ColorRect.new()
	_swarm_fill.size = Vector2(0, 12)
	_swarm_root.add_child(_swarm_fill)

	# 스테이지 보스 체력바 (상단 중앙, 금색 — 융합 바와 구분)
	_sboss_root = Control.new()
	_sboss_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sboss_root.visible = false
	_sboss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_sboss_root)
	_sboss_lbl = Label.new()
	UiFont.apply(_sboss_lbl, 24)
	_sboss_lbl.add_theme_color_override("font_color", Color("ffd54a"))
	_sboss_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0, 0.9))
	_sboss_lbl.add_theme_constant_override("outline_size", 5)
	_sboss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sboss_lbl.clip_text = true  # 700px 를 넘는 문구가 옆으로 삐져나가지 않게
	_sboss_lbl.position = Vector2(290, 94)  # 융합 바(y28~86)와 세로 분리 — 동시 표시 시 겹침 방지 (감사 C10)
	_sboss_lbl.size = Vector2(700, 30)
	_sboss_root.add_child(_sboss_lbl)
	_sboss_bg = ColorRect.new()
	_sboss_bg.color = Color(0, 0, 0, 0.6)
	_sboss_bg.position = Vector2(288, 126)
	_sboss_bg.size = Vector2(704, 26)
	_sboss_root.add_child(_sboss_bg)
	_sboss_fill = ColorRect.new()
	_sboss_fill.color = Color("ffb03a")
	_sboss_fill.position = Vector2(292, 128)
	_sboss_fill.size = Vector2(696, 22)
	_sboss_root.add_child(_sboss_fill)

	# 웨이브 중간보스 체력바 — 좁은 주황. 색은 등장 배너(ffa63c)와 같은 것으로 맞춘다.
	# ★ y 는 여기서 정하지 않는다. 세 바가 다 고정 줄이면 중간보스 혼자 나와도 셋째 줄에
	#   떠서 화면 한복판까지 내려온다. _layout_boss_bars 가 살아 있는 것만 위에서부터 채운다.
	_wboss_root = Control.new()
	_wboss_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wboss_root.visible = false
	_wboss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_wboss_root)
	_wboss_lbl = Label.new()
	UiFont.apply(_wboss_lbl, 19)
	_wboss_lbl.add_theme_color_override("font_color", Color("ffa63c"))
	_wboss_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0, 0.9))
	_wboss_lbl.add_theme_constant_override("outline_size", 5)
	_wboss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wboss_lbl.clip_text = true
	_wboss_lbl.size = Vector2(WBOSS_W - 4.0, 26)
	_wboss_root.add_child(_wboss_lbl)
	_wboss_bg = ColorRect.new()
	_wboss_bg.color = Color(0, 0, 0, 0.6)
	_wboss_bg.size = Vector2(WBOSS_W, 20)
	_wboss_root.add_child(_wboss_bg)
	_wboss_fill = ColorRect.new()
	_wboss_fill.color = Color("e8862a")
	_wboss_fill.size = Vector2(WBOSS_W - 8.0, 16)
	_wboss_root.add_child(_wboss_fill)

	# 게임오버 (UiKit 테마 패널)
	_gameover = Control.new()
	_gameover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gameover.visible = false
	_gameover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.offset_left = -600.0
	dim.offset_top = -600.0
	dim.offset_right = 600.0
	dim.offset_bottom = 600.0
	_gameover.add_child(dim)
	_gameover.add_child(UiKit.vignette())
	var goc := CenterContainer.new()
	goc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gameover.add_child(goc)
	var gpanel := UiKit.make_panel(UiKit.DANGER)
	gpanel.custom_minimum_size = Vector2(900, 0)
	goc.add_child(gpanel)
	_go_panel = gpanel
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 14)
	gv.alignment = BoxContainer.ALIGNMENT_CENTER
	gpanel.add_child(gv)
	var got := Label.new()
	got.text = "GAME OVER"
	UiFont.apply(got, 54)
	got.add_theme_color_override("font_color", UiKit.DANGER)
	got.add_theme_color_override("font_outline_color", Color(0.1, 0, 0, 0.9))
	got.add_theme_constant_override("outline_size", 8)
	got.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(got)
	# 16차 U7: 「게임 오버」 · 「GAME OVER」 낱말 그림(붉은색, 높이 16 × 4) — 있으면 글꼴 제목 대신
	var gow := FxLib.word_rect(FxLib.word_sheet("w_gameover"), 4)
	if gow != null:
		gow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		gv.add_child(gow)
		gv.move_child(gow, got.get_index())
		got.visible = false
	gv.add_child(UiKit.divider(360.0))
	var go_lbl := Label.new()
	go_lbl.name = "GOLabel"
	go_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFont.apply(go_lbl, 22)
	go_lbl.add_theme_color_override("font_color", UiKit.TEXT)
	gv.add_child(go_lbl)
	_go_table = VBoxContainer.new()
	_go_table.add_theme_constant_override("separation", 4)
	gv.add_child(_go_table)
	gv.move_child(_go_table, go_lbl.get_index())   # 요약 글 위 — 무기 표가 이 화면에서 가장 오래 기억된다
	# 14차: 요약 한 줄(시간 · 처치 · 레벨 · 콤보) · 해금 초상 카드 · 버튼 둘. 판은 화면 안(판 높이를 줄였다)
	_go_sum = HBoxContainer.new()
	gv.add_child(_go_sum)
	gv.move_child(_go_sum, _go_table.get_index())
	_go_unl = HBoxContainer.new()
	gv.add_child(_go_unl)
	var gbt := HBoxContainer.new()
	gbt.alignment = BoxContainer.ALIGNMENT_CENTER
	gbt.add_theme_constant_override("separation", 16)
	gv.add_child(gbt)
	for gb: Button in [UiParts.with_icon(UiKit.button("다시 도전", _on_victory_retry, true), "reroll"), UiParts.with_icon(UiKit.button("메인 메뉴", func() -> void: get_tree().reload_current_scene()), "menu")]:
		gb.custom_minimum_size.x = 220.0
		gbt.add_child(gb)
	gv.add_theme_constant_override("separation", 10)
	# ★ 14차: 실제 판(무기 여섯 · 해금 다섯)으로 채우니 한 줄 기둥이 화면 아래로 잘렸다 — 두 단으로.
	#   왼쪽 = 무기 표, 오른쪽 = 요약 · 엽전 · 새로 열림. 버튼은 판 아래.
	var gbody := HBoxContainer.new()
	gbody.add_theme_constant_override("separation", 28)
	gbody.alignment = BoxContainer.ALIGNMENT_CENTER
	gv.add_child(gbody)
	gv.move_child(gbody, _go_sum.get_index())
	_go_table.reparent(gbody)
	var gright := VBoxContainer.new()
	gright.add_theme_constant_override("separation", 12)
	gright.alignment = BoxContainer.ALIGNMENT_CENTER
	gbody.add_child(gright)
	for n3: Control in [_go_sum, go_lbl]:
		n3.reparent(gright)
	# 새로 열림은 초상 ×2(98) 카드라 오른쪽 단(약 400)에 다섯이 안 들어간다 — 두 단 밑에 판 너비로 한 줄
	gv.move_child(_go_unl, gbody.get_index() + 1)
	gv.move_child(gbt, gv.get_child_count() - 1)
	_hud_layer.add_child(_gameover)

	# ── 광고 부활 제안 패널 (판당 1회) ──
	_revive_panel = Control.new()
	_revive_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_revive_panel.visible = false
	var rdim := ColorRect.new()
	rdim.color = Color(0, 0, 0, 0.78)
	rdim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rdim.offset_left = -600.0
	rdim.offset_top = -600.0
	rdim.offset_right = 600.0
	rdim.offset_bottom = 600.0
	_revive_panel.add_child(rdim)
	_revive_panel.add_child(UiKit.vignette())
	var rc := CenterContainer.new()
	rc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_revive_panel.add_child(rc)
	var rpanel := UiKit.make_panel(UiKit.ACCENT)
	rc.add_child(rpanel)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 14)
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rpanel.add_child(rv)
	var rt := Label.new()
	rt.text = "한 번 더?"
	UiFont.apply(rt, 52)
	rt.add_theme_color_override("font_color", UiKit.ACCENT)
	rt.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0, 0.9))
	rt.add_theme_constant_override("outline_size", 8)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(rt)
	rv.add_child(UiKit.divider(360.0))
	var rl := Label.new()
	rl.name = "ReviveLabel"
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFont.apply(rl, 21)
	rl.add_theme_color_override("font_color", UiKit.TEXT)
	rv.add_child(rl)
	# 스팀·데스크톱은 광고가 없다 — 문구가 "광고 보고" 로 남으면 오지 않는 광고를 기다리게 된다
	var rbtn := UiKit.button(I18n.t("이어서 하기") if G.free_revive() else I18n.t("광고 보고 부활"), _on_revive_watch, true)
	rbtn.name = "ReviveWatch"
	rv.add_child(rbtn)
	var rgive := UiKit.button("포기하고 결과 보기", _on_revive_decline)
	rgive.name = "ReviveDecline"
	rv.add_child(rgive)
	_hud_layer.add_child(_revive_panel)

	# ── 스테이지 클리어 패널 (S1) ──
	_victory = Control.new()
	_victory.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory.visible = false
	var vdim := ColorRect.new()
	vdim.color = Color(0, 0, 0, 0.7)
	vdim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vdim.offset_left = -600.0
	vdim.offset_top = -600.0
	vdim.offset_right = 600.0
	vdim.offset_bottom = 600.0
	_victory.add_child(vdim)
	_victory.add_child(UiKit.vignette())
	var vc := CenterContainer.new()
	vc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory.add_child(vc)
	var vpanel := UiKit.make_panel(UiKit.ACCENT)
	vc.add_child(vpanel)
	_vic_panel = vpanel
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 14)
	vv.alignment = BoxContainer.ALIGNMENT_CENTER
	vpanel.add_child(vv)
	_victory_title = Label.new()
	var vt := _victory_title
	vt.text = "STAGE CLEAR"
	UiFont.apply(vt, 52)
	vt.add_theme_color_override("font_color", UiKit.ACCENT)
	vt.add_theme_color_override("font_outline_color", Color(0.15, 0.09, 0, 0.9))
	vt.add_theme_constant_override("outline_size", 8)
	vt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vv.add_child(vt)
	var clw := FxLib.word_rect("w_clear", 4)   # 10차 A — 글꼴 제목 대신 그림(예전 「★ STAGE CLEAR ★」 는 패널을 넘쳤다)
	if clw != null:
		clw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vv.add_child(clw)
		vv.move_child(clw, vt.get_index())
		vt.visible = false
		_vic_w_clear = clw
	var rsw := FxLib.word_rect(FxLib.word_sheet("w_result"), 4)
	if rsw != null:
		rsw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rsw.visible = false
		vv.add_child(rsw)
		vv.move_child(rsw, vt.get_index())
		_vic_w_result = rsw
	vv.add_child(UiKit.divider(360.0))
	_vic_sum = HBoxContainer.new()
	_victory_lbl = Label.new()
	_victory_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFont.apply(_victory_lbl, 20)
	_victory_lbl.add_theme_color_override("font_color", UiKit.TEXT)
	_victory_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_victory_lbl.custom_minimum_size = Vector2(760, 0)
	_victory_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vic_stars = HBoxContainer.new()
	_vic_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	_vic_stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vv.add_child(_vic_stars)
	vv.add_child(_victory_lbl)
	vv.add_child(_vic_sum)
	_vic_table = VBoxContainer.new()
	_vic_table.add_theme_constant_override("separation", 4)
	vv.add_child(_vic_table)
	_vic_gold = Label.new()
	UiFont.apply(_vic_gold, 20)
	_vic_gold.add_theme_color_override("font_color", UiParts.PAPER_D)
	_vic_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vv.add_child(_vic_gold)
	_vic_unl = HBoxContainer.new()
	vv.add_child(_vic_unl)
	vv.add_theme_constant_override("separation", 10)
	var vbtns := HBoxContainer.new()
	vbtns.alignment = BoxContainer.ALIGNMENT_CENTER
	vbtns.add_theme_constant_override("separation", 16)
	vv.add_child(vbtns)
	# 재도전 — 별 등급을 올리려면 같은 판을 다시 도는 게 정석이라 버튼이 한 칸 앞에 있어야 한다
	# (예전엔 메인 메뉴 → 캐릭터 선택 → 스테이지 선택을 매번 왕복해야 했다)
	# ★ 버튼 셋이 기본 폭 330 이라 판이 화면 폭(1062 > 1049)을 넘었다 — 9차부터 남아 있던 uifit 1건. 13차에 폭을 줄였다.
	for vb0: Button in [UiParts.with_icon(UiKit.button("다시 도전", _on_victory_retry), "reroll"), UiParts.with_icon(UiKit.button("다음 스테이지", _on_victory_next, true), "play"),
			UiParts.with_icon(UiKit.button("메인 메뉴", _on_victory_menu), "menu")]:
		vb0.custom_minimum_size.x = 250.0
		vbtns.add_child(vb0)
	_victory_next = vbtns.get_child(1) as Button
	if G.is_demo():   # 19차 4-2: 체험판은 다음 스테이지가 없다 — 그 자리에 찜하기
		_victory_next.visible = false
		var wish: Button = UiParts.with_icon(UiKit.button("정식판 찜하기", func() -> void: SteamHub.open_store_page(), true), "star_full")
		wish.custom_minimum_size.x = 250.0
		vbtns.add_child(wish)
		vbtns.move_child(wish, 1)
	# ★ 18차: 폰(UI 「크게」 = 논리 1280×720)에서 무기 표 6줄과 새로 열림 카드가 한 기둥에 쌓여 판이 화면보다 길어졌다.
	#   아래 단추 줄이 화면 밖으로 밀리고 스크롤도 없어 클리어 뒤 나갈 수가 없었다(사용자 폰 보고). 게임오버는 14차에
	#   같은 일로 두 단이 됐는데 클리어 판엔 안 했다. 같은 두 단으로: 왼쪽 무기 표, 오른쪽 별 · 스테이지 · 요약 · 골드,
	#   새로 열림은 그 밑 한 줄, 단추는 맨 아래. 그래도 크면 _fit_result_panel 이 통째로 줄인다.
	var vbody := HBoxContainer.new()
	vbody.add_theme_constant_override("separation", 28)
	vbody.alignment = BoxContainer.ALIGNMENT_CENTER
	vv.add_child(vbody)
	vv.move_child(vbody, _vic_stars.get_index())
	_vic_table.reparent(vbody)
	var vright := VBoxContainer.new()
	vright.add_theme_constant_override("separation", 12)
	vright.alignment = BoxContainer.ALIGNMENT_CENTER
	vbody.add_child(vright)
	for n4: Control in [_vic_stars, _victory_lbl, _vic_sum, _vic_gold]:
		n4.reparent(vright)
	_victory_lbl.custom_minimum_size = Vector2(440, 0)   # 한 기둥일 때의 760 이면 두 단이 화면을 넘는다
	_vic_gold.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vic_gold.custom_minimum_size = Vector2(440, 0)
	vv.move_child(_vic_unl, vbody.get_index() + 1)
	vv.move_child(vbtns, vv.get_child_count() - 1)
	_hud_layer.add_child(_victory)
	if _parts_hud:
		# 14차 2절 6 · 7: 경험치 = hud_xp_frame(가로 이어 붙임) + fill_xp, 보스 = hud_boss_frame + fill_boss
		_skin_part_bar(_xp_bg, _xp_fill, "hud_xp_frame", "fill_xp", true)
		for pb2: Array in [[_sboss_bg, _sboss_fill], [_wboss_bg, _wboss_fill], [_fusion_bg, _fusion_fill]]:
			_skin_part_bar(pb2[0] as ColorRect, pb2[1] as ColorRect, "hud_boss_frame", "fill_boss", false)
		for lb3: Label in [_sboss_lbl, _wboss_lbl, _fusion_lbl]:
			UiFont.apply(lb3, 20)
			lb3.add_theme_color_override("font_color", UiParts.PAPER_HI)
			lb3.clip_text = true
		_xp_spark = ColorRect.new()
		_xp_spark.color = UiParts.PAPER_HI
		_xp_spark.size = Vector2(2, 4)
		_xp_spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_layer.add_child(_xp_spark)
		_skin_part_bar(_swarm_bg, _swarm_fill, "hud_xp_frame", "fill_xp", true)
		UiFont.apply(_swarm_lbl, 16)
	else:
		for pair: Array in [[_xp_bg, _xp_fill], [_hp_bg, _hp_fill], [_dash_bg, _dash_fill], [_sboss_bg, _sboss_fill],
				[_wboss_bg, _wboss_fill], [_fusion_bg, _fusion_fill], [_swarm_bg, _swarm_fill]]:
			_skin_bar(pair[0] as ColorRect, pair[1] as ColorRect)

	_update_hud_scale()


## 14차 U4 막대 — 바탕 ColorRect 위에 틀(9조각, 가로 이어 붙임이면 TILE), 채움 ColorRect 안에 채움 그림(가로 반복).
## 채움은 틀 안 3px(UI 6) — 자리는 _update_hud · _layout_boss_bars 가 정한다.
var _parts_hud: bool = false
var _dash_px: HBoxContainer
var _dash_tex: TextureRect
var _dash_frame: int = -1
var _xp_spark: ColorRect

func _skin_part_bar(bg: ColorRect, fill: ColorRect, frame_sheet: String, fill_sheet: String, tile: bool) -> void:
	if bg == null or fill == null:
		return
	var fr := NinePatchRect.new()
	fr.texture = UiParts.tex(frame_sheet)
	fr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sl: Array = FxLib.json_of(UiParts.W, frame_sheet).get("slice", [4, 4, 4, 4])
	fr.set_patch_margin(SIDE_LEFT, int(sl[0]) * 2)
	fr.set_patch_margin(SIDE_TOP, int(sl[1]) * 2)
	fr.set_patch_margin(SIDE_RIGHT, int(sl[2]) * 2)
	fr.set_patch_margin(SIDE_BOTTOM, int(sl[3]) * 2)
	if tile:
		fr.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(fr)
	bg.color = Color(0, 0, 0, 0)
	var ft := TextureRect.new()
	ft.texture = UiParts.tex(fill_sheet)
	ft.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ft.stretch_mode = TextureRect.STRETCH_TILE
	ft.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ft.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.add_child(ft)
	fill.color = Color(1, 1, 1, 0)


## 10차 D: 코드 막대(바탕 · 채움 ColorRect)에 그림을 입힌다. 위치 · 폭 · 색을 바꾸는 코드는 그대로 둔다.
##   틀(bar_frame, 테 3px)  — 바탕의 자식으로 바깥 6 UI px(그림 3px × 2)에 둘러 씌운다. 가운데는 투명이라 바탕이 보인다.
##   채움(bar_fill, 흰 바탕 · 위 밝은 줄 · 아래 어두운 줄) — 채움의 자식으로 곱하기(MUL). 흰 곳은 채움 색 그대로, 줄만 명암.
func _skin_bar(bg: ColorRect, fill: ColorRect) -> void:
	if bg == null or fill == null or not FxLib.has("ui/frame", "bar_frame"):
		return
	var fr := NinePatchRect.new()
	fr.texture = FxLib.scaled("ui/frame", "bar_frame", 0, 2)
	fr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for sd in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		fr.set_patch_margin(sd, 8)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.set_anchors_preset(Control.PRESET_FULL_RECT)
	fr.offset_left = -6.0
	fr.offset_top = -6.0
	fr.offset_right = 6.0
	fr.offset_bottom = 6.0
	bg.add_child(fr)
	bg.color = Color(0.05, 0.04, 0.07, 0.85)   # 홈 바탕은 더 짙게 — 틀 안쪽 그늘과 이어지게
	if FxLib.has("ui/frame", "bar_fill"):
		var sh := NinePatchRect.new()
		sh.texture = FxLib.scaled("ui/frame", "bar_fill", 0, 2)
		sh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sh.set_patch_margin(SIDE_TOP, 2)
		sh.set_patch_margin(SIDE_BOTTOM, 2)
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var mm := CanvasItemMaterial.new()
		mm.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		sh.material = mm
		fill.add_child(sh)


## 전설 · 신화 · 융합 카드 테두리를 도는 반짝임(card_shine 4칸) — 틀 위에 겹쳐 그린다. 멈춘 화면(레벨업)에서도 돈다.
func _card_shine(btn: Control) -> void:
	var m: Dictionary = FxLib.info("ui/frame", "card_shine")
	var nine := NinePatchRect.new()
	nine.texture = FxLib.scaled("ui/frame", "card_shine", 0, 2)
	nine.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for sd in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		nine.set_patch_margin(sd, int((FxLib.json_of("ui/frame", "card_shine").get("slice", [16]) as Array)[0]) * 2)
	nine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nine.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.add_child(nine)
	var n: int = int(m.get("n", 4))
	var step: float = float(m.get("len", 0.36)) / float(maxi(1, n))
	var tw := nine.create_tween().set_loops()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for i in n:
		var ti: int = i
		tw.tween_callback(func() -> void: nine.texture = FxLib.scaled("ui/frame", "card_shine", ti, 2))
		tw.tween_interval(step)


## 13차 HUD 치수
const XP_X: float = 8.0
const XP_Y: float = 6.0
const XP_H: float = 16.0      # U4 경험치 막대 그림 높이 8 × 2
const HP_W: float = 200.0
const SLOT: float = 48.0      # 14차 목업: 무기 칸 48(칸 테 24 × 2)
const SLOT_P: float = 36.0    # 그 밖 칸 36
var _slots_w: HBoxContainer
var _hud_center: Control      # 타이머 · 웨이브 · 보스 예고 — 레벨업 · 상자 창이 뜨면 그 제목과 겹쳐서 숨긴다
var _slots_p: HBoxContainer
var _slots_sig: String = "-"
var _dash_ring: _HudRing
var _hud_has_icon_gold: bool = false
var _hud_has_icon_kills: bool = false


## 대시 고리 — 차오르는 호. 다 차면 초록, 차는 중엔 하늘(예전 막대 색 그대로). U4 「대시 원형 8칸」 그림이 오면 갈아 끼운다.
class _HudRing extends Control:
	var ratio: float = 1.0
	var full: bool = true
	func set_ratio(r: float, rd: bool) -> void:
		if absf(r - ratio) < 0.01 and rd == full:
			return
		ratio = r
		full = rd
		queue_redraw()
	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.5 - 2.0
		draw_arc(c, r, 0.0, TAU, 32, Color(0, 0, 0, 0.55), 4.0)
		if ratio > 0.001:
			draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * clampf(ratio, 0.0, 1.0), 32,
				Color("7dff9b") if full else Color("5cc0ff"), 4.0)


## 오른쪽 위 아이콘 — 골드는 C 엽전(줍는 것 그림 ×2), 처치는 U5 해골이 오기 전까지 없음(글자로).
func _hud_icon(which: String) -> Control:
	if which == "coin" and FxLib.has("ui/pickup", "coin"):
		var t: Texture2D = FxLib.scaled("ui/pickup", "coin", 0, 2)
		var r := TextureRect.new()
		r.texture = t
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.custom_minimum_size = t.get_size()
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_has_icon_gold = true
		return r
	return null


## 무기 칸 · 패시브 칸 — 들고 있는 것이 바뀔 때만 다시 짓는다(_build_summary 를 매 프레임 부르지 않게).
func _refresh_hud_slots() -> void:
	if _slots_w == null:
		return
	var sig: String = str(_upgrade_counts.hash()) + ":" + str(_evolved.size()) + ":" + str(_mythic_ids.size())
	if sig == _slots_sig:
		return
	_slots_sig = sig
	for box: HBoxContainer in [_slots_w, _slots_p]:
		for c in box.get_children():
			c.queue_free()
	var ws: Array = []
	var ps: Array = []
	for e: Dictionary in _build_summary():
		var kind: String = String(e.get("kind", ""))
		if kind == "강화":
			continue           # 능력치 강화는 일시정지 능력치 표에서 본다 — HUD 칸은 무기 · 탄막 · 전설 · 신화만
		if kind == "무기" or kind == "융합":
			ws.append(e)
		else:
			ps.append(e)
	# 14차 목업: 칸(cell) 안에 아이콘, 무기 칸 밑엔 레벨 점. 빈 칸도 보여 준다(무기 6 · 그 밖 4).
	var parts: bool = UiParts.on()
	# 목업(hud.png): 무기 칸 48 · 그 밖 칸 36(1920 화면 기준 · HUD 보통 배수에서 이 숫자 그대로)
	for row: Array in [[_slots_w, ws, 6, true, SLOT], [_slots_p, ps, 4, false, SLOT_P]]:
		var box2: HBoxContainer = row[0]
		var list: Array = row[1]
		var sz: float = float(row[4]) if parts else SLOT
		var n: int = maxi(int(row[2]) if parts else 0, mini(8, list.size()))
		for i in n:
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 2)
			col.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box2.add_child(col)
			var cell := PanelContainer.new()
			cell.custom_minimum_size = Vector2(sz, sz)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# 10/13 사용자: 융합한 무기는 융합 아이콘 · 금 테(cell_sel) · 레벨 점 대신 「융합」. 다음 레벨이 없다.
			var fused: bool = i < list.size() and bool((list[i] as Dictionary).get("fused", false))
			var cbx: StyleBoxTexture = UiParts.cell_box(fused, 2.0)
			cell.add_theme_stylebox_override("panel", cbx if cbx != null else StyleBoxEmpty.new())
			col.add_child(cell)
			if i >= list.size():
				continue
			var e: Dictionary = list[i]
			var b := IconBadge.new()
			b.bare = parts
			b.setup(String(e.get("icon", e["id"])), sz - 8.0 if parts else SLOT - 4.0)
			cell.add_child(b)
			var lvl: int = int(e.get("level", 1))
			var mx: int = int(e.get("max", 0))
			if fused and bool(row[3]):
				# 글자는 레벨 점보다 키가 커서 그대로 넣으면 융합하는 순간 아래 줄(패시브 칸)이 9px 내려앉았다.
				#   점 줄 높이(8)짜리 빈 칸에 얹고 넘치는 몇 px 은 줄 사이 틈에 그린다.
				var fh := Control.new()
				fh.custom_minimum_size = Vector2(sz, 8.0)
				fh.mouse_filter = Control.MOUSE_FILTER_IGNORE
				col.add_child(fh)
				var fl := Label.new()
				# 영어 「Fusion」 은 칸(48)보다 넓어 옆 칸 글자와 붙었다(「FusionFusion」) — 이 칸만 짧은 낱말
				fl.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
				fl.text = "Fused" if G.lang() == "en" else "융합"
				UiFont.apply(fl, 12)
				fl.add_theme_color_override("font_color", Color("ffd54a"))
				fl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
				fl.add_theme_constant_override("outline_size", 4)
				fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				fl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				fl.position = Vector2(-8.0, -5.0)
				fl.size = Vector2(sz + 16.0, 18.0)
				fh.add_child(fl)
			elif bool(row[3]) and parts and String(e.get("kind", "")) == "무기":
				var pr := HBoxContainer.new()
				pr.alignment = BoxContainer.ALIGNMENT_CENTER
				pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				# 찬 점(지금 레벨) + 빈 점(남은 레벨) — 목업처럼 끝이 어디인지 보이게. 8개까지.
				# 목업은 점 ×2(8px). 점 그림에 먹 테가 있어 붙여 놓아도 갈린다 — 여섯(만렙 6)까지 칸 폭 48 에 딱 든다.
				var tot: int = clampi(maxi(mx, lvl), 1, 8)
				var pk: int = 2 if tot <= 6 else 1
				pr.add_theme_constant_override("separation", 0 if pk == 2 else 2)
				for k in tot:
					var d := TextureRect.new()
					d.texture = UiParts.tex("pip_on" if k < lvl else "pip_off", 0, pk)
					d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					d.mouse_filter = Control.MOUSE_FILTER_IGNORE
					pr.add_child(d)
				col.add_child(pr)
			elif not parts and String(e.get("kind", "")) in ["무기", "탄막"]:
				var lv := Label.new()
				lv.text = "M" if (mx > 0 and lvl >= mx) else str(lvl)
				UiFont.apply(lv, 16)
				lv.position = Vector2(SLOT - 12.0, SLOT - 16.0)
				cell.add_child(lv)


func _mk_label(parent: Node, size: int) -> Label:
	var l := Label.new()
	UiFont.apply(l, size)
	l.add_theme_color_override("font_color", Color("f0ecff"))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 5)
	parent.add_child(l)
	return l


func _update_hud() -> void:
	_tick_hurt_vig()
	# 19차 3-2: 투명도 0 인 화면 전체 판도 켜져 있으면 매 프레임 화면 전체를 칠한다(레벨업 번쩍임 · 저체력 비네트).
	if _levelup_flash != null:
		_levelup_flash.visible = _levelup_flash.color.a > 0.004 or _GridBg.old_draw_test
	if _lowhp_vig != null:
		_lowhp_vig.visible = _lowhp_vig.modulate.a > 0.004 or _GridBg.old_draw_test
	var t: int = int(G.time_alive)
	_lbl_time.text = "%02d:%02d" % [t / 60, t % 60]
	if _stage_mode:
		var remain: int = maxi(0, int(G.STAGE_LEN) - t)
		if _stage_boss != null and is_instance_valid(_stage_boss):
			_lbl_wave.text = I18n.t("%s (%s) · 보스전!") % [I18n.t(String(G.STAGE_NAMES[G.stage_sel])), G.diff_label()]
		elif _final_spawned:
			_lbl_wave.text = "%s (%s)" % [I18n.t(String(G.STAGE_NAMES[G.stage_sel])), G.diff_label()]
		else:
			_lbl_wave.text = I18n.t("%s (%s) · 보스까지 %02d:%02d") % [I18n.t(String(G.STAGE_NAMES[G.stage_sel])), G.diff_label(), remain / 60, remain % 60]
	else:
		_lbl_wave.text = I18n.t("웨이브 %d") % G.wave
	_lbl_kills.text = G.gold_str(G.kills)
	_lbl_level.text = "LV %d" % G.level
	_lbl_gold.text = G.gold_str(G.run_gold)
	_refresh_crown_badge()
	_refresh_hud_slots()
	# 화면폭/높이 추종 배치 (스케일러 논리 크기 기준 — 어떤 배율에서도 안 잘림)
	var W: float = _hud_layer.size.x
	var H: float = _hud_layer.size.y
	var xw: float = W - XP_X * 2.0 - 84.0 - (80.0 if _mobile else 0.0)   # 폰은 오른쪽 위 일시정지 버튼 자리를 비운다
	_xp_bg.size.x = xw
	var xr: float = float(G.xp) / float(max(1, G.xp_to_next))
	_xp_fill.size = Vector2(xw * clampf(xr, 0.0, 1.0), XP_H)
	_lbl_level.position = Vector2(XP_X + xw + 4.0, XP_Y - 2.0)
	_lbl_level.size = Vector2(80.0, 24.0)
	_hp_bg.position = Vector2(12, 34)
	_hp_fill.position = Vector2(12, 34)
	_hp_lbl.position = Vector2(12, 34)
	_dash_badge.position = Vector2(12 + HP_W + 12.0, 29)
	_dash_ring.position = _dash_badge.position - Vector2(4, 4)
	if _parts_hud:
		# 14차 목업: 체력은 발밑 막대만, 대시는 왼쪽 아래 8칸 고리(dash_ring) + 「대시」
		for n2: CanvasItem in [_hp_bg, _hp_fill, _hp_lbl, _dash_badge, _dash_ring]:
			n2.visible = false
		_dash_px.position = Vector2(12, H - 48.0)
		_xp_fill.position = Vector2(XP_X + 6.0, XP_Y + 6.0)
		_xp_fill.size = Vector2((xw - 12.0) * clampf(xr, 0.0, 1.0), 4.0)
		_xp_spark.position = Vector2(XP_X + 6.0 + _xp_fill.size.x - 2.0, XP_Y + 6.0)
		_xp_spark.visible = _xp_fill.size.x > 2.0
		_xp_spark.modulate.a = 0.55 + 0.45 * absf(sin(float(Time.get_ticks_msec()) * 0.008))
	# 최종 결전 바: 스테이지 보스(스테이지 모드) 또는 최종 보스(무한 모드) 체력 추종
	var fb: Enemy = _stage_boss if _stage_mode else _final_boss
	var sb_on: bool = fb != null and is_instance_valid(fb) and not fb._dead
	if _sboss_root.visible != sb_on:
		_sboss_root.visible = sb_on
	if sb_on:
		var sratio: float = clampf(fb.hp / maxf(1.0, fb.max_hp), 0.0, 1.0)
		_sboss_fill.size.x = (_boss_bw - 20.0 if _parts_hud else 696.0) * sratio
		var tag: String = "STAGE BOSS" if _stage_mode else "FINAL BOSS"
		if _parts_hud:
			_sboss_lbl.text = _boss_name(fb.art)
		else:
			_sboss_lbl.text = "%s · %s   %d%%  ·  %02d:%02d" % [tag, _boss_name(fb.art), int(sratio * 100.0),
			int(G.boss_fight_t) / 60, int(G.boss_fight_t) % 60]
	# 웨이브 중간보스 바
	var wb: Enemy = _wave_boss_target()
	if _wboss_root.visible != (wb != null):
		_wboss_root.visible = wb != null
	if wb != null:
		var wratio: float = clampf(wb.hp / maxf(1.0, wb.max_hp), 0.0, 1.0)
		_wboss_fill.size.x = (_boss_bw - 20.0 if _parts_hud else WBOSS_W - 8.0) * wratio
		_wboss_lbl.text = _boss_name(wb.art) if _parts_hud else I18n.t("중간보스 · %s   %d%%") % [_boss_name(wb.art), int(wratio * 100.0)]
	_layout_boss_bars(W)
	# 13차: 가운데 위가 타이머 자리가 되면서 레벨업 · 보스 상자 창 제목 뒤로 비쳐 겹쳤다 — 창이 떠 있는 동안 숨긴다
	_hud_modal((_levelup_root != null and _levelup_root.visible) or (_chest_panel != null and is_instance_valid(_chest_panel)))
	# 저체력 경고 비네트 (30% 미만 → 붉게 맥동)
	if G.player != null and is_instance_valid(G.player) and G.running:
		var pl0 := G.player as Player
		var hr: float = pl0.hp / maxf(1.0, pl0.max_hp)
		if hr < 0.3:
			_lowhp_vig.modulate.a = 0.5 + 0.3 * sin(G.time_alive * 6.0)
		else:
			_lowhp_vig.modulate.a = maxf(0.0, _lowhp_vig.modulate.a - 0.06)
	else:
		_lowhp_vig.modulate.a = 0.0
	# 콤보 잔여시간 페이드
	if _combo_lbl.visible and G.combo > 0:
		_combo_lbl.modulate.a = clampf(G.combo_t / 0.6, 0.35, 1.0)
	# 대시 게이지
	if G.player != null and is_instance_valid(G.player):
		var pl := G.player as Player
		var dr: float = pl.dash_ratio()
		_dash_ring.set_ratio(dr, pl.dash_ready())
		if _parts_hud:
			var fi: int = 7 if pl.dash_ready() else clampi(int(dr * 8.0) - 1, 0, 6)   # 칸 k = k/8 찼음, 8번째 = 준비
			if fi != _dash_frame:
				_dash_frame = fi
				_dash_tex.texture = UiParts.tex("dash_ring", fi)
		_dash_fill.size.x = 120.0 * dr
		if pl.dash_ready():
			_dash_fill.color = Color("7dff9b")
			_dash_lbl.text = "대시 OK"
		else:
			_dash_fill.color = Color("5cc0ff")
			var full: float = maxf(Player.DASH_CD_MIN, Player.DASH_CD * pl.dash_cd_mult)
			_dash_lbl.text = I18n.t("%.1f초") % (full * (1.0 - dr))


## ── 14차 결과 화면 공용: 요약 한 줄 · 해금 초상 카드 ──
var _go_sum: HBoxContainer
var quiet_moments: bool = false   # 18차 트레일러: 콤보 최초 돌파 알림을 안 띄운다
var _go_panel: Control    # 18차: 화면보다 크면 줄이려고 잡아 둔다(_fit_result_panel)
var _vic_panel: Control
var _go_unl: HBoxContainer
var _vic_sum: HBoxContainer
var _vic_gold: Label
var _vic_unl: HBoxContainer

func _res_summary(box: HBoxContainer) -> void:
	if box == null:
		return
	for c in box.get_children():
		c.queue_free()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	var t: int = int(G.time_alive)
	for it in [["시간", "%02d:%02d" % [t / 60, t % 60]], ["처치", G.gold_str(G.kills)], ["레벨", str(G.level)], ["최고 콤보", G.gold_str(G.combo_best)]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		var a := Label.new()
		a.text = I18n.t(String(it[0]))
		UiFont.apply(a, 16)
		a.add_theme_color_override("font_color", UiParts.PAPER_D)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(a)
		var b := Label.new()
		b.text = String(it[1])
		UiFont.apply(b, 30)
		b.add_theme_color_override("font_color", UiParts.PAPER_HI)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(b)
		box.add_child(col)


func _res_unlocks(box: HBoxContainer) -> void:
	if box == null:
		return
	for c in box.get_children():
		c.queue_free()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	box.visible = not _unlock_cards.is_empty()
	if not box.visible:
		return
	var hd := Label.new()
	hd.text = I18n.t("새로 열림")
	UiFont.apply(hd, 16)
	hd.add_theme_color_override("font_color", UiParts.BRASS_HI)
	hd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(hd)
	for u: Dictionary in _unlock_cards.slice(0, 5):
		var card := PanelContainer.new()
		var cb: StyleBoxTexture = UiParts.cell_box(false, 4.0)
		if cb != null:
			card.add_theme_stylebox_override("panel", cb)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		card.add_child(v)
		var pic: Control = null
		if String(u["kind"]) == "ach":
			var ap: String = "res://assets/ui/achievements/%s.png" % String(u["id"])
			if ResourceLoader.exists(ap):
				var ach_pic := TextureRect.new()
				ach_pic.texture = load(ap)
				ach_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				ach_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				ach_pic.custom_minimum_size = Vector2(88, 88)
				pic = ach_pic
				# 10/13: 보상 골드를 그림 오른쪽 아래에 — 골드 합계가 왜 늘었는지 읽히게(칸 높이는 그대로)
				if int(u.get("gold", 0)) > 0:
					var gl := Label.new()
					gl.text = "+%sG" % G.gold_str(int(u["gold"]))
					UiFont.apply(gl, 16)
					gl.add_theme_color_override("font_color", UiParts.BRASS_HI)
					gl.add_theme_color_override("font_outline_color", UiParts.INK)
					gl.add_theme_constant_override("outline_size", 6)
					gl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
					gl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
					gl.grow_vertical = Control.GROW_DIRECTION_BEGIN
					gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					ach_pic.add_child(gl)
		elif String(u["kind"]) == "char":
			var cf: String = CharForge.hero_id(String(u["id"]))
			if cf != "" and CharForge.has_anim(cf, "portrait"):
				pic = CharForge.figure(cf, "portrait", 2)     # 지시서 2절 4: portrait ×2 + 이름
		if pic == null:
			pic = IconBadge.new().setup(String(u["id"]), 88.0)
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(pic)
		var nl := Label.new()
		# 한글 이름은 마지막 낱말이 이름(「열두 마디 베른」 → 베른). 영어는 앞이 이름이라(「Bern of Twelve Knots」 → Knots 가 됐다) 전체를 칸에 맞춘다
		nl.text = String(u["name"]) if FxLib.lang_en() or String(u["kind"]) == "ach" else String(u["name"]).split(" ")[-1]   # 도전과제 이름은 통째로(「첫 정복」 → 「정복」 이 됐다)
		UiFont.apply(nl, 20)
		UiKit.fit_font(nl, 150.0, 20, 12)
		nl.add_theme_color_override("font_color", UiParts.PAPER_HI)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nl)
		box.add_child(card)
	if _unlock_cards.size() > 5:   # QA 10/13: 다섯 칸을 넘으면 남은 수만(도감 · 도전과제 탭에 다 있다)
		var more := Label.new()
		more.text = "+%d" % (_unlock_cards.size() - 5)
		UiFont.apply(more, 20)
		more.add_theme_color_override("font_color", UiParts.BRASS_HI)
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(more)


## ── 13차 결과 화면: 무기별 피해 표 ──
## ★ 예전 결과 화면은 글 네 줄(생존 · 처치 · 레벨 · 골드)뿐이었다. 플레이어가 「다음 판엔 이 무기」를
##   정하는 화면이라 무기별 피해가 가장 오래 기억된다(에셋 담당 13차 · Vampire Survivors 결과 화면).
##   G.run_dmg(출처 id → 합)를 보여 준다. 융합한 무기는 융합 결과 이름으로 합친다. 가장 센 줄은 금빛.
var _go_table: VBoxContainer
var _vic_table: VBoxContainer
const _DMG_NAMES: Dictionary = {
	"dot_burn": "화상", "dot_poison": "중독", "react": "원소 반응", "dash": "대시 돌격",
	"thorns": "가시 반사", "blast": "총구 폭풍", "wave": "검압", "bomber": "자폭", "etc": "기타",
}
const _DMG_ICONS: Dictionary = {"dot_burn": "b_fire", "dot_poison": "b_poison", "dash": "dashcd", "thorns": "thorns"}


func _dmg_show_id(k: String) -> String:
	var p: Player = G.player as Player if G.player != null and is_instance_valid(G.player) else null
	if p == null:
		return k
	var base: String = k.substr(3) if k.begins_with("wp_") else k
	var evo: String = String(p.fused_marks.get(base, ""))
	return evo if evo != "" else k


func _dmg_name(k: String) -> String:
	if _DMG_NAMES.has(k):
		return I18n.t(String(_DMG_NAMES[k]))
	if k.begins_with("evo_"):
		var ed: Dictionary = _evo_def(k)
		return I18n.t(String(ed.get("n", k)))
	return _card_name(k)


static func _short_num(v: float) -> String:
	if v >= 1.0e6:
		return "%.1fM" % (v / 1.0e6)
	if v >= 1.0e4:
		return "%.1fK" % (v / 1.0e3)
	return str(int(round(v)))


func _fill_dmg_table(box: VBoxContainer) -> void:
	if box == null:
		return
	for c in box.get_children():
		c.queue_free()
	var merged: Dictionary = {}
	var total: float = 0.0
	for k in G.run_dmg.keys():
		var v: float = float(G.run_dmg[k])
		var sid: String = _dmg_show_id(String(k))
		merged[sid] = float(merged.get(sid, 0.0)) + v
		total += v
	box.visible = total > 0.0
	if total <= 0.0:
		return
	var keys: Array = merged.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return float(merged[a]) > float(merged[b]))
	var secs: float = maxf(1.0, G.time_alive)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	box.add_child(cc)
	for hd in ["", "무기", "피해", "비율", "초당"]:
		var h := Label.new()
		h.text = I18n.t(String(hd)) if String(hd) != "" else ""
		UiFont.apply(h, 16)
		h.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if hd in ["피해", "비율", "초당"] else HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(h)
	for i in mini(6, keys.size()):
		var k: String = String(keys[i])
		var v: float = float(merged[k])
		var col: Color = Color("ffd54a") if i == 0 else UiKit.TEXT
		var ic: String = String(_DMG_ICONS.get(k, k if (k.begins_with("wp") or k.begins_with("evo_") or k.begins_with("b_") or k == "summon_ice") else ""))
		var icn: Control = IconBadge.new().setup(ic, 26.0) if ic != "" else Control.new()
		icn.custom_minimum_size = Vector2(26, 26)
		grid.add_child(icn)
		for cell in [_dmg_name(k), _short_num(v), "%d%%" % int(round(v * 100.0 / total)), _short_num(v / secs)]:
			var l := Label.new()
			l.text = String(cell)
			UiFont.apply(l, 20)
			l.add_theme_color_override("font_color", col)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if grid.get_child_count() % 5 == 1 else HORIZONTAL_ALIGNMENT_RIGHT
			grid.add_child(l)


## 신화·융합 배지 — 이번 판에 얻은 '판을 뒤집는 것'만 이름으로 나열한다.
## 매 프레임 문자열을 다시 만들면 헛일이라, 개수가 바뀔 때만 다시 짓는다.
var _crown_sig: int = -1
func _refresh_crown_badge() -> void:
	if _lbl_crown == null:
		return
	var sig: int = _mythic_ids.size() * 100 + _evolved.size()
	if sig == _crown_sig:
		return
	_crown_sig = sig
	var parts: Array = []
	for mid: String in _mythic_ids:
		parts.append(_card_name(mid))
	for ev: Dictionary in EVOLUTIONS:
		if _evolved.has(String(ev["id"])):
			parts.append(I18n.t(String(ev["n"])))
	_lbl_crown.visible = not parts.is_empty()
	_lbl_crown.text = "  ·  ".join(parts)   # 16차: 「◆」 「◇」 글꼴 기호 뺌


## 콤보 갱신: 5 이상부터 표시, 커질수록 팡팡 튀고 마일스톤마다 배너+보너스 골드
## ★ 마일스톤 보상은 '한 판에 한 번'이다. 예전엔 콤보가 끊겼다 다시 오를 때마다 다시 줬는데,
##   콤보 유지 시간이 짧아서 실플레이 4분에 25/50/100 구간을 수십 번 넘나든다 —
##   분당 골드 상한을 우회하는 무한 지급 통로였다(실측: 4분에 8천 골드의 주범).
const COMBO_MILESTONES: Array = [25, 50, 100, 200, 400, 800, 1600]
var _combo_paid: Dictionary = {}
func _on_combo_changed() -> void:
	if _combo_lbl == null:
		return
	var c: int = G.combo
	if c < 5:
		_combo_lbl.visible = false
		if _combo_px != null:
			_combo_px.visible = false
		return
	var heat: float = clampf(float(c) / 150.0, 0.0, 1.0)
	if _combo_px != null:
		_combo_px.visible = true
		_combo_num.text = str(c)
		_combo_num.modulate = Color("ffd54a").lerp(Color("ff5c2e"), heat)
		_combo_px.scale = Vector2(1.3, 1.3)
		_combo_px.create_tween().tween_property(_combo_px, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_combo_lbl.visible = true
		_combo_lbl.text = I18n.t("%d 콤보!") % c
	if _combo_px == null:
		_combo_lbl.add_theme_color_override("font_color", Color("ffd54a").lerp(Color("ff5c2e"), heat))
		_combo_lbl.scale = Vector2(1.3, 1.3)
		var tw := _combo_lbl.create_tween()
		tw.tween_property(_combo_lbl, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if c in COMBO_MILESTONES and not _combo_paid.has(c):
		_combo_paid[c] = true  # 이번 판에서 이 구간은 지급 완료 — 콤보가 끊겨도 다시 안 준다
		# 실측: c/6 이면 한 판 보너스가 700G 로 드랍 예산(995G)의 70% 였다. 실력 보너스가
		# 본 수입에 맞먹으면 예산을 조인 의미가 없다. 최대 317G 로 낮춘다.
		var bonus: int = c / 10
		G.add_gold_bonus(bonus)  # [감사 C30] 드랍 예산 미잠식 — 보너스 직후 드랍이 마르지 않게
		if not quiet_moments:   # 18차: 트레일러 녹화 중엔 자막과 두 줄로 겹쳐 읽혀서 뺀다
			_wave_banner(I18n.t("%d 콤보 최초 돌파! +%dG") % [c, bonus], Color("ff9a3c"))
		G.add_shake(0.3)
		G.sfx("levelup", 1.2 + 0.1 * float(COMBO_MILESTONES.find(c)))


## 17-1 피격 비네트: 번쩍임은 0.35초쯤에 걷히고, 체력 30% 아래면 바닥에 약한 맥동을 깐다.
var _hurt_ms: int = 0

func _tick_hurt_vig() -> void:
	if _hurt_vig == null:
		return
	var now: int = Time.get_ticks_msec()
	var dt: float = clampf(float(now - _hurt_ms) / 1000.0, 0.0, 0.1) if _hurt_ms > 0 else 0.0
	_hurt_ms = now
	_hurt_a = maxf(0.0, _hurt_a - dt * 2.4)
	var low: float = 0.0
	if G.running and G.player != null and is_instance_valid(G.player):
		var pl := G.player as Player
		var r: float = pl.hp / maxf(1.0, pl.max_hp)
		if r < 0.3 and pl.hp > 0.0:
			low = (0.14 + 0.12 * absf(sin(float(now) * 0.006))) * G.flash_mult()
	var a: float = maxf(_hurt_a, low) if G.running else 0.0
	if absf(_hurt_vig.modulate.a - a) > 0.004:
		_hurt_vig.modulate.a = a
	_hurt_vig.visible = a > 0.004


func _update_hp() -> void:
	if G.player != null and is_instance_valid(G.player):
		var pl := G.player as Player
		var ratio: float = clampf(pl.hp / pl.max_hp, 0.0, 1.0)
		# 17-1: 깎였을 때만(재생 · 회복은 매 프레임 이리 온다) 깎인 비율만큼 가장자리를 붉힌다
		if _hurt_hp_prev >= 0.0 and pl.hp < _hurt_hp_prev - 0.01 and G.running:
			var frac: float = (_hurt_hp_prev - pl.hp) / maxf(1.0, pl.max_hp)
			_hurt_a = maxf(_hurt_a, clampf(0.30 + frac * 2.5, 0.30, 0.65) * G.flash_mult())
		_hurt_hp_prev = pl.hp
		_hp_fill.size = Vector2(HP_W * ratio, 16.0)
		if _hp_lbl != null:
			_hp_lbl.text = "%d / %d" % [int(ceil(pl.hp)), int(pl.max_hp)]


func _on_level_up() -> void:
	if not G.running:
		return  # 종료 후 레벨업 이벤트 무시 — 승리/게임오버 화면 위에 모달 안 뜸 (S4)
	_levelup_flash.color = Color(1, 1, 1, 0.35 * G.flash_mult())
	_levelup_flash.visible = true
	var tw := create_tween()
	tw.tween_property(_levelup_flash, "color:a", 0.0, 0.3)
	_levelup_burst()
	# (M39) 레벨15 시그니처 '진화' 상자 제거 — 진화(융합)는 오직 '만렙 재료 2개 조합'으로만.
	# 상자는 보스 드랍(무작위 강화)만 남김. apply_signature는 미사용 보존.
	# 도박꾼: 10레벨마다 1회만 도박 롤 (매 강화 X)
	if G.level % 10 == 0 and G.player != null and is_instance_valid(G.player) and (G.player as Player).ability == "fourcards":
		_gambler_variance(G.player as Player)
	_pending_levelups += 1
	# 만렙(풀 소진) 후 자동선택 옵션 (M37): 모달·일시정지 없이 즉시 적용 + 배너
	if G.auto_card > 0 and (_levelup_root == null or not _levelup_root.visible) and _pool_exhausted():
		while _pending_levelups > 0:
			_pending_levelups -= 1
			var aid: String = ""
			match G.auto_card:
				1: aid = "heal_card"
				2: aid = "gold_card"
				_: aid = "heal_card" if randi() % 2 == 0 else "gold_card"
			_apply_upgrade(aid)
			_wave_banner(I18n.t("자동 선택: ") + (I18n.t("휴식 (회복)") if aid == "heal_card" else I18n.t("노다지 (골드)")), Color("ffd54a"))
		return
	if _levelup_root != null and not _levelup_root.visible:
		_open_levelup()


## 레벨업 순간 플레이어 주변 금빛 폭발 (링 2겹 + 파티클) — 성장의 손맛
func _levelup_burst() -> void:
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	var pos: Vector2 = (p as Node2D).global_position
	# 12차 F levelup — 기준점 = 영웅 발밑(몸 가운데에서 반지름 × 0.86 아래, CreatureVisual 그림자 자리)
	var pillar: AnimatedSprite2D = FxLib.burst(self, pos + Vector2(0.0, Player.RADIUS * 0.86), "ui/moment", "levelup", 0.0, 1.0, -1.0, 50)
	if pillar != null:
		pillar.process_mode = Node.PROCESS_MODE_ALWAYS
	for ri in 2:
		var ring := Line2D.new()
		ring.width = 5.0 - float(ri) * 2.0
		ring.default_color = Color("ffd54a") if ri == 0 else Color(1, 1, 1, 0.7)
		var pts: PackedVector2Array = G.regular_polygon(24, 26.0 + float(ri) * 14.0)
		for pt: Vector2 in pts:
			ring.add_point(pt)
		ring.add_point(pts[0])
		ring.global_position = pos
		ring.z_index = 50
		add_child(ring)
		var rtw := ring.create_tween()
		rtw.tween_property(ring, "scale", Vector2(3.2 + float(ri), 3.2 + float(ri)), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		rtw.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
		rtw.tween_callback(ring.queue_free)
	var pt2 := CPUParticles2D.new()
	pt2.emitting = true
	pt2.one_shot = true
	pt2.explosiveness = 1.0
	pt2.amount = 16
	pt2.lifetime = 0.55
	pt2.spread = 180.0
	pt2.initial_velocity_min = 140.0
	pt2.initial_velocity_max = 340.0
	pt2.scale_amount_min = 2.0
	pt2.scale_amount_max = 4.0
	pt2.color = Color("ffe08a")
	pt2.global_position = pos
	add_child(pt2)
	get_tree().create_timer(0.8).timeout.connect(pt2.queue_free)


## 고를 수 있는 카드(진화 포함)가 하나도 안 남았는지 — 자동선택(M37)의 발동 조건.
func _pool_exhausted() -> bool:
	if not _available_evolutions().is_empty():
		return false
	return _filtered_pool().is_empty()


## 일반 상한에 이미 닿아 먹어도 오를 게 없는 능력 카드인지.
## ★ 11/7 스팀 플레이 보고: 치명타가 70% 인데 계속 나왔다. 카드는 고른 횟수(7)로만 빠졌는데
##   치명타는 영웅 기본 · 장신구 · 도박 · 영웅 카드로도 올라 횟수가 남은 채 상한에 닿는다.
##   치명타는 필중의 눈(속사 기관총 + 치명타 만렙) 재료라, 속사 기관총을 들고 아직 융합 전이면 남긴다.
func _stat_card_capped(uid: String) -> bool:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return false
	match uid:
		"crit":
			if p.crit_chance < Player.CRIT_CAP - 0.001:
				return false
			return not _crit_still_material()
		"rate":
			return p.rate_mult <= Player.RATE_FLOOR + 0.0001
		"dashcd":
			return p.dash_cd_mult <= Player.DASH_CD_MULT_FLOOR + 0.0001
	return false


## 현재 시점에 뽑힐 수 있는 카드 풀 (만렙/슬롯/소멸 필터) — 카드 모달·보스 상자 공용.
func _filtered_pool() -> Array:
	var wcount: int = _owned_slot_count("무기")
	var bcount: int = _owned_slot_count("탄막")
	var pcount: int = _owned_slot_count("패시브")
	return _upgrade_pool().filter(
		func(u: Dictionary) -> bool:
			var uid: String = String(u["id"])
			if _consumed.has(uid) or _banished.has(uid):
				return false
			# ★ 화면이 적는 레벨과 **같은 것**으로 잘라야 한다. 예전엔 여기만 장부(고른 횟수)를
			#   봐서, 특수무기(Lv2 시작)는 카드에 "Lv6 MAX" 가 뜬 뒤에도 한 번 더 나왔고
			#   그걸 먹으면 Lv7 이 됐다 — 맹독 장판으로 신고받은 그 증상이다(2026-09-06).
			# ★ 2026-09-15: 초월(m_transcend)을 먹으면 **한계 자체가 3 올라가야 한다.**
			#   예전엔 상한이 고정이라, 초월 전부터 들고 있던 무기는 Lv9 가 되는데
			#   초월 뒤에 새로 든 무기는 Lv4 에서 시작해 카드 2장이면 6 에 닿아 풀에서 빠졌다
			#   — 같은 판에서 어떤 무기는 9, 어떤 무기는 6 으로 끝났다(실플레이 리포트).
			#   카드 설명이 "한계를 돌파한다"인데 뒤에 든 무기만 한계가 그대로였던 것이다.
			var cap: int = _weapon_cap(uid) if _is_weapon_id(uid) else int(u.get("max", 99))
			if _shown_level(uid) >= cap:
				return false
			if _stat_card_capped(uid):
				return false
			if uid.begins_with("m_") and _mythic_taken >= MYTHIC_PER_RUN:
				return false  # 신화는 한 판에 한 장 (남은 선택이 의미를 유지하게)
			var owned: bool = int(_upgrade_counts.get(uid, 0)) > 0
			if _is_weapon_id(uid) and not owned and wcount >= WEAPON_SLOTS:
				return false
			if _is_bullet_id(uid) and not owned and bcount >= BULLET_SLOTS:
				return false
			if _is_passive_id(uid) and not owned and pcount >= PASSIVE_SLOTS:
				return false
			return true
	)


## 보스 상자 (M37): 무작위 강화 1~5개 즉시 지급. 5개는 극악(0.5%).
func _on_boss_chest() -> void:
	if not G.running:
		return  # [감사 C9] 승리 화면 위로 보스 상자 연출 겹치는 것 차단
	var got: Array = []
	# 상자 하나가 카드를 몇 장 주는가 — 1장이 기본이고 5장은 200판에 한 번꼴이다.
	var r: float = randf()
	var n: int = 1
	if r < 0.005:
		n = 5
	elif r < 0.03:
		n = 4
	elif r < 0.12:
		n = 3
	elif r < 0.42:
		n = 2
	for i in n:
		var pool: Array = _filtered_pool()
		if pool.is_empty():  # 더 줄 게 없으면 회복/골드로 대체
			var fb: String = "heal_card" if randi() % 2 == 0 else "gold_card"
			_apply_upgrade(fb)
			got.append({"id": fb, "n": I18n.t("휴식") if fb == "heal_card" else I18n.t("노다지")})
			continue
		var picked: Array = _weighted_pick(pool, 1)  # 보스 상자도 등급 가중 (신화는 여기서도 극악)
		var up: Dictionary = picked[0]
		_apply_upgrade(String(up["id"]))
		got.append({"id": String(up["id"]), "n": _card_title(String(up["id"]), String(up["n"]))})
	G.add_shake(0.5 + 0.1 * float(n))
	_show_chest_panel(got)


## 보스 상자로 **무엇을 받았는지** 멈춰 서서 보여 준다.
## ★ 예전엔 배너 한 줄로 흘려보냈다. 상자는 한 판에 몇 번 없는 사건인데, 카드 이름이
##   화면 위를 지나가 버려서 뭘 받았는지 알 수가 없었다(2026-09-06 지적).
##   레벨업 모달과 같은 규칙으로 판을 멈추고, 아무 곳이나 누르면 재개한다.
func _show_chest_panel(got: Array) -> void:
	_hud_modal(true)
	# ★ 17-2: 상자 둘을 같은 프레임에 주우면(보스 둘이 붙어 죽어 자석이 한꺼번에 당김) 둘째 창이 「열기 전부터 멈춰 있었다」고
	#   기억해서, 닫은 뒤에도 판이 멈춘 채 아무 창도 없었다(봇 480판 중 2판이 이렇게 섰다). 이미 열려 있으면 처음 기억을 지키고
	#   앞 상자 카드까지 한 창에 같이 보여 준다.
	var stacked: bool = _chest_panel != null and is_instance_valid(_chest_panel)
	if stacked:
		_chest_panel.queue_free()
		got = _chest_got + got
	_chest_got = got
	var layer := CanvasLayer.new()
	layer.layer = 12                                   # 레벨업 모달(10) 위
	layer.process_mode = Node.PROCESS_MODE_ALWAYS      # 멈춘 동안에도 입력을 받아야 한다
	add_child(layer)
	_chest_panel = layer
	_pad_focus.call_deferred(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.01, 0.66)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var n: int = got.size()
	if UiParts.on():
		# ★ 15차 6절 2: 레벨업은 부적 카드인데 상자만 글 목록 창이었다. 같은 카드를 나란히 — 레벨업과 같은 배수(1920 좌표).
		var s2: float = _modal_scale()
		var vp2: Vector2 = get_viewport().get_visible_rect().size
		root.set_anchors_preset(Control.PRESET_TOP_LEFT)    # 꽉 찬 앵커면 크기가 화면으로 되돌아가 배수 뒤 판이 2/3 만 덮는다
		root.position = Vector2.ZERO
		root.scale = Vector2(s2, s2)
		root.size = vp2 / s2
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 22)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(cv)
		var hb: Control = UiParts.title_band(I18n.t("보스 상자: 카드 %d장") % n, 30)
		hb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cv.add_child(hb)
		var crow := HBoxContainer.new()
		crow.alignment = BoxContainer.ALIGNMENT_CENTER
		crow.add_theme_constant_override("separation", 24)
		crow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(crow)
		for e2 in got:
			crow.add_child(_chest_card(e2 as Dictionary))
		var tip2 := Label.new()
		tip2.text = _chest_tip()
		UiFont.apply(tip2, 20)
		tip2.add_theme_color_override("font_color", UiParts.PAPER)
		tip2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(tip2)
		_chest_close_on_input(root, stacked)
		return
	var panel := UiKit.make_panel(Color("ffd54a"))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := UiKit.title(I18n.t("보스 상자: 카드 %d장") % n, 30)
	head.add_theme_color_override("font_color", Color("ffd54a") if n >= 3 else Color("ffe9a8"))
	v.add_child(head)
	for e in got:
		var d: Dictionary = e as Dictionary
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		v.add_child(row)
		var bc := CenterContainer.new()
		bc.add_child(IconBadge.new().setup(String(d["id"]), 44.0))
		row.add_child(bc)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var nm := Label.new()
		nm.text = String(d["n"])
		UiFont.apply(nm, 20)
		nm.add_theme_color_override("font_color", Color("f4efe2"))
		col.add_child(nm)
		var sub := Label.new()
		sub.text = _card_stats(String(d["id"])).split("
")[0]
		UiFont.apply(sub, 13)
		sub.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.custom_minimum_size = Vector2(360, 0)
		col.add_child(sub)
	var tip := Label.new()
	tip.text = _chest_tip()
	UiFont.apply(tip, 15)
	tip.add_theme_color_override("font_color", UiKit.CYAN)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tip)
	_chest_close_on_input(root, stacked)


## 아무 곳이나 누르면 닫는다 · 판을 멈춘다(상자 창 공용).
func _chest_close_on_input(root: Control, stacked: bool = false) -> void:
	# 11/5 스팀 피드백 8: 예전엔 「아무 키」였다 — 이동 키 · 대시를 누른 채면 열리자마자 닫혀 무엇을 받았는지 못 봤다.
	#   이제 클릭 · 터치 · 누르기(Enter · 패드 A) · 뒤로(Esc · 패드 B · START)만 닫는다. 이동 키는 아무 일도 안 한다.
	root.gui_input.connect(func(ev: InputEvent) -> void:
		if _chest_close_input(ev):
			root.accept_event()
			_close_chest_panel()
	)
	# 16차 4-5: 키 · 패드 입력은 포커스가 있는 곳으로만 온다 — 판 자체가 포커스를 받아야 패드로 닫힌다
	root.focus_mode = Control.FOCUS_ALL
	root.grab_focus.call_deferred()
	# ★ 레벨업 모달이 이미 떠 있으면 판은 이미 멈춰 있다. 그 상태를 기억했다가 그대로 돌려준다 —
	#   안 그러면 상자를 닫는 순간 레벨업 카드가 뜬 채로 게임이 다시 흐른다.
	if not stacked:
		_chest_was_paused = get_tree().paused
	get_tree().paused = true


## 상자 창을 닫는 입력인가 — 클릭 · 터치 · 누르기 · 뒤로만(이동 · 대시 키는 아니다). 반복 입력은 _LvKeys 가 이미 버린다.
func _chest_close_input(ev: InputEvent) -> bool:
	if ev.is_echo():
		return false
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if ev is InputEventScreenTouch:
		return (ev as InputEventScreenTouch).pressed
	if ev is InputEventKey or ev is InputEventJoypadButton:
		if ev.is_action_pressed("move_up") or ev.is_action_pressed("move_down") or ev.is_action_pressed("move_left") \
				or ev.is_action_pressed("move_right") or ev.is_action_pressed("dash"):
			if not (ev is InputEventJoypadButton and ev.is_action_pressed("ui_accept")):   # 패드 A 는 대시이자 누르기
				return false
		return ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause")
	return false


## 상자 창 아래 안내 — 기기에 맞는 닫는 법.
func _chest_tip() -> String:
	if G.mobile:
		return I18n.t("아무 곳이나 눌러 계속")
	if not Input.get_connected_joypads().is_empty():
		return I18n.t("A 버튼으로 계속")
	return I18n.t("클릭하거나 Enter 를 눌러 계속")


## 상자에서 받은 카드 한 장 — 레벨업 부적 카드와 같은 판 · 크기, 누를 것은 없다(이미 받았다).
func _chest_card(d: Dictionary) -> Control:
	var id: String = String(d["id"])
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tb: StyleBoxTexture = UiParts.talisman_box(_grade_key(id))
	if tb != null:
		card.add_theme_stylebox_override("panel", tb)
	# 등급 이름표 · 빛 테는 카드(PanelContainer) 밖 겉 칸에 — 판 안에 넣으면 컨테이너가 끌어다 눕힌다
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(CARD_W, CARD_H)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_grade_glow(holder, id)
	holder.add_child(card)
	_add_grade_tag(holder, id)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, 4)
	v.add_child(top)
	var chip := PanelContainer.new()
	var cb: StyleBoxTexture = UiParts.cell_box(false, 6.0)
	if cb != null:
		chip.add_theme_stylebox_override("panel", cb)
	chip.custom_minimum_size = Vector2(120, 120)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icc := CenterContainer.new()
	icc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ib := IconBadge.new()
	ib.bare = true
	icc.add_child(ib.setup(id, 64.0))
	chip.add_child(icc)
	v.add_child(chip)
	var tw: float = CARD_W - 2.0 * CARD_PAD
	var nm := Label.new()
	# 영어판은 이름이 번역된 뒤라 「Weapon: 」 「Rounds: 」 머리말도 지운다(레벨업 카드와 같게)
	nm.text = UiKit.wrap_words(I18n.t(String(d["n"])).replace("무기: ", "").replace("탄막: ", "").replace("Weapon: ", "").replace("Rounds: ", ""), 24, tw)
	UiFont.apply(nm, 24)
	nm.add_theme_color_override("font_color", UiParts.INK)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.max_lines_visible = 2
	v.add_child(nm)
	var lv: int = _shown_level(id)
	var bd: Control = UiParts.badge(I18n.t("새로!") if lv <= 1 else "Lv %d" % lv, 20)
	bd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(bd)
	var ef := Label.new()
	ef.text = _two_lines(_card_stats(id).split("\n")[0], 20, tw)
	UiFont.apply(ef, 20)
	ef.add_theme_color_override("font_color", UiParts.LAC)
	ef.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ef)
	return holder


## 카드 효과 두 줄. 넘치면 끝의 괄호 설명(「(레벨이 오르면 …)」)부터 뺀다 — 예전엔 셋째 줄을 그냥 잘라
##   영어 카드가 「Lightning leaps to nearby enemies (more」 로 끝났다(16차 영어판 읽기). 그래도 넘치면 둘째 줄 끝을 「…」.
func _two_lines(text: String, size: int, w: float) -> String:
	var lines: PackedStringArray = UiKit.wrap_words(text, size, w).split("\n")
	if lines.size() <= 2:
		return "\n".join(lines)
	var tr: String = I18n.t(text).strip_edges()
	var cut: int = tr.rfind(" (")
	if tr.ends_with(")") and cut > 0:
		lines = UiKit.wrap_words(tr.substr(0, cut), size, w).split("\n")
		if lines.size() <= 2:
			return "\n".join(lines)
	return lines[0] + "\n" + lines[1].strip_edges() + "…"


## 승리 창 머리 낱말 그림 — 스테이지 클리어면 「STAGE CLEAR」, 무한 완주면 「결과」.
func _vic_word(clear: bool) -> void:
	if _vic_w_clear != null:
		_vic_w_clear.visible = clear
	if _vic_w_result != null:
		_vic_w_result.visible = not clear
	if _victory_title != null:
		_victory_title.visible = (_vic_w_clear == null) if clear else (_vic_w_result == null)


## 16차 4-5: 판 안 창(레벨업 · 상자 · 부활 · 결과)이 열리면 패드일 때 첫 버튼에 포커스 — 없으면 패드로는 아무것도 못 누른다.
## ★ 17-2: 인자를 Node 로 받으면 창이 같은 프레임에 닫혔을 때(봇 · 연타) 호출 자체가 「Cannot convert argument 1」 오류를 찍었다.
func _pad_focus(n: Variant) -> void:
	if is_instance_valid(n) and n is Node:
		UiKit.focus_first(n as Node)


## 레벨업 · 상자 창 배수 — 부품이 있으면 HUD 와 같은 표(1920 좌표), 카드 넷 · 높이가 들어가게만 줄인다.
func _modal_scale() -> float:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var s2: float = clampf(G.hud_scale(), 1.0, 1.25)
	s2 = maxf(1.0, minf(s2, vp.x / 990.0))
	if UiParts.on():
		s2 = G.hud_layer_scale(vp)
		s2 = minf(s2, minf(vp.x / 1300.0, vp.y / 700.0))
	return s2


func _close_chest_panel() -> void:
	if _chest_panel != null and is_instance_valid(_chest_panel):
		_chest_panel.queue_free()
	_chest_panel = null
	if not _chest_was_paused:
		get_tree().paused = false


# ---------------------------------------------------------------- 레벨업 강화 선택 (R3)
## QA 10/13: 레벨업 숫자키 받기 — 늘 도는 층 아래라 트리가 멈춰도 입력이 온다.
class _LvKeys extends Node:
	var host: Node = null
	## 11/5 스팀 피드백 8: 「보스 잡고 보너스 창이 떴을 때 움직이면 창이 사라진다」. 상자 창은 아무 키나 닫았는데,
	##   이동 키를 누른 채면 키 반복 입력(echo)이 바로 들어와 열리자마자 닫혔다. 레벨업 · 결과 창도 대시(Space · 패드 A)가
	##   「누르기」와 같은 키라 싸우다 누른 대시가 포커스된 카드 · 단추를 눌렀다.
	##   창(레벨업 · 상자 · 부활 · 결과)이 뜬 뒤 ARM_MS 동안의 키 · 패드 · 클릭, 반복 입력, 창이 뜰 때 이미 누르고 있던 키는 버린다.
	const ARM_MS: int = 450
	var _down: Dictionary = {}     # 지금 눌려 있는 키 · 패드 단추
	var _stale: Dictionary = {}    # 창이 뜰 때 이미 눌려 있던 것 — 뗄 때까지 무시
	var _was_open: bool = false
	var _arm_until: int = 0

	func _process(_d: float) -> void:
		var open: bool = host != null and bool(host.call("_modal_open"))
		if open and not _was_open:
			_arm_until = Time.get_ticks_msec() + ARM_MS
			_stale = _down.duplicate()
		_was_open = open

	static func _ev_key(event: InputEvent) -> String:
		if event is InputEventKey:
			var k := event as InputEventKey
			return "k%d" % (k.physical_keycode if k.physical_keycode != 0 else k.keycode)
		if event is InputEventJoypadButton:
			return "j%d" % (event as InputEventJoypadButton).button_index
		return ""

	func _blocked(event: InputEvent, key: String) -> bool:
		var now: int = Time.get_ticks_msec()
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			return event.is_pressed() and now < _arm_until
		if key == "":
			return false
		if event.is_echo():
			return true
		if _stale.has(key):
			if not event.is_pressed():
				_stale.erase(key)
			return true
		return event.is_pressed() and now < _arm_until

	func _input(event: InputEvent) -> void:
		var key: String = _ev_key(event)
		if key != "" and not event.is_echo():
			if event.is_pressed():
				_down[key] = true
			else:
				_down.erase(key)
		if host != null and bool(host.call("_modal_open")):
			if not _was_open:   # 이번 프레임에 막 떴다(_process 보다 입력이 먼저 왔다)
				_process(0.0)
			if _blocked(event, key):
				get_viewport().set_input_as_handled()
				return
		if host != null and get_tree().paused:
			host.call("_levelup_keys", event)
		# QA 10/13: 패드 버튼이 들어왔는데 포커스가 없으면 지금 맨 위 화면의 첫 단추로(켠 뒤 꽂은 패드 · 지워진 단추)
		if host != null and (event is InputEventJoypadButton) and event.is_pressed() \
				and get_viewport().gui_get_focus_owner() == null:
			host.call("_pad_refocus")


## 11/5: 판을 멈추고 고르게 하는 창이 떠 있는가(입력 유예 — _LvKeys).
func _modal_open() -> bool:
	return (_levelup_root != null and _levelup_root.visible) \
		or (_chest_panel != null and is_instance_valid(_chest_panel)) \
		or (_revive_panel != null and _revive_panel.visible) \
		or (_victory != null and _victory.visible) \
		or (_gameover != null and _gameover.visible)


## QA 10/13: 포커스가 없을 때 패드가 잡을 화면 — 맨 위부터(상자 · 레벨업 · 부활 · 결과 · 일시정지 · 메뉴들).
func _pad_refocus() -> void:
	var tops: Array = [_chest_panel, _levelup_root, _revive_panel, _victory, _gameover]
	for n2 in [_pause_menu, _char_select, _meta_shop, _settings, _codex_screen, _main_menu]:
		tops.append(n2.get("_root") if n2 != null else null)
	for t in tops:
		if t != null and is_instance_valid(t) and ((t is CanvasLayer and (t as CanvasLayer).visible) or (t is Control and (t as Control).is_visible_in_tree())):
			UiKit.focus_first(t as Node)
			return


func _build_levelup_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 동작
	add_child(layer)
	var lv_keys := _LvKeys.new()   # QA 10/13: 멈춘 동안에도 숫자키를 받아 Main 으로 넘긴다
	lv_keys.host = self
	layer.add_child(lv_keys)
	_levelup_root = Control.new()
	_levelup_root.set_anchors_preset(Control.PRESET_TOP_LEFT)  # 크기/배율은 _update_hud_scale이 관리
	_levelup_root.size = Vector2(1280, 720)
	_levelup_root.visible = false
	layer.add_child(_levelup_root)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.04, 0.07, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 오버사이즈: 스케일러 크기가 순간 스테일이어도 가장자리가 뚫려 보이지 않게 (S3)
	dim.offset_left = -600.0
	dim.offset_top = -600.0
	dim.offset_right = 600.0
	dim.offset_bottom = 600.0
	_levelup_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_levelup_root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	center.add_child(v)
	# 10차 A — 카드 위 큰 제목. 부품 판은 1920 좌표라 4배(목업 제목 폭 310)
	var lvw := FxLib.word_rect("w_levelup", 4 if UiParts.on() and not G.mobile else 3)
	if lvw != null:
		lvw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(lvw)
	# ★ 14차: 「강화를 선택하세요」는 필요 없는 말이었다(에셋 담당) — 그림 제목이 없을 때만 글자 제목
	if lvw == null:
		var title := Label.new()
		title.text = "LEVEL UP!"
		UiFont.apply(title, 48)
		title.add_theme_color_override("font_color", Color("ffe08a"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(title)
	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 24 if UiParts.on() else 18)
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_cards_box)
	# 14차 3절 4: 다시 뽑기 · 건너뛰기 · 봉인(나무 패 보통 · 보통 · 위험 — 목업 그대로)
	# ★ 리롤만으로는 빌드를 짤 수 없다 — 원하지 않는 것을 이번 판에서 영원히 빼는 「봉인」이 이 장르 전략의 절반이다.
	var kgap := Control.new()
	kgap.custom_minimum_size = Vector2(0, 26)      # 카드 밑 숫자키(1 2 3)가 버튼에 가리지 않게
	v.add_child(kgap)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 18)
	v.add_child(brow)
	_reroll_btn = UiParts.with_icon(UiKit.button("다시 뽑기", _on_reroll), "reroll")
	brow.add_child(_reroll_btn)
	_skip_btn = UiParts.with_icon(UiKit.button("건너뛰기", _on_skip), "skip")
	brow.add_child(_skip_btn)
	_banish_btn = UiParts.with_icon(UiKit.button("봉인", _on_banish_toggle, false, UiKit.DANGER), "seal")
	brow.add_child(_banish_btn)
	for bb: Button in [_reroll_btn, _skip_btn, _banish_btn]:
		bb.custom_minimum_size = Vector2(236.0, 48.0) if UiParts.on() else Vector2(240.0, bb.custom_minimum_size.y)


## 카드가 뜬 뒤 이만큼은 탭을 안 받는다. 레벨업은 예고 없이 터지므로,
## 마침 그 자리에 손가락이 있었다면 그건 '고른 것'이 아니다.
const CARDS_ARM_SEC: float = 0.25
var _cards_shown_ms: int = 0

func _cards_tap_ready() -> bool:
	return Time.get_ticks_msec() - _cards_shown_ms >= int(CARDS_ARM_SEC * 1000.0)


## 창이 판을 멈추면 _update_hud 가 안 돈다 — 여는 자리에서 직접 부른다. 닫히면 _update_hud 가 되돌린다.
func _hud_modal(on: bool) -> void:
	for n1: CanvasItem in [_hud_center, _sboss_root, _fusion_root, _wboss_root, _swarm_root]:
		if n1 != null:
			n1.modulate.a = 0.0 if on else 1.0


func _open_levelup() -> void:
	_hud_modal(true)
	_banish_mode = false
	_update_hud_scale()  # 스테일 뷰포트 크기 방어 — 모달이 화면 일부만 덮여 '짤려 보이는' 간헐 현상 (S3)
	_cards_shown_ms = Time.get_ticks_msec()
	_levelup_root.visible = true
	get_tree().paused = true
	_populate_cards()
	_pad_focus.call_deferred(_levelup_root)   # 16차 4-5: 패드만으로 카드를 고르게 — 첫 카드에 포커스












func _populate_cards() -> void:
	for c in _cards_box.get_children():
		_cards_box.remove_child(c)   # QA 10/13: 바로 빼야 아래 포커스가 지워질 옛 카드로 안 간다
		c.queue_free()
	var count: int = 3
	if G.player != null and is_instance_valid(G.player) and (G.player as Player).four_cards:
		count = 4
	var cards: Array = []
	var evos: Array = _available_evolutions()
	if not evos.is_empty():
		evos.shuffle()
		# ★ 2026-09-15: 예전엔 **무조건 한 장**이었다. 처형(b_exec)처럼 융합 둘에 걸친
		#   재료를 만렙까지 찍으면 사신의 낫과 명부가 동시에 열리는데, 그중 하나가
		#   매번 무작위로 뽑혀서 원하는 쪽이 안 나올 수 있었다 — 고를 수가 없었다
		#   (실플레이 질문: "처형이랑 엮이는 융합이 여러 개면 다 뜨는 거야?").
		#   융합은 빌드의 결론이다. 여러 개가 열렸으면 **그 자리에서 고를 수 있어야** 한다.
		#   일반 카드 자리는 최소 한 장 남긴다 — 융합만 뜨면 다른 성장이 멈춘다.
		var nevo: int = mini(evos.size(), maxi(1, count - 1))
		for i in nevo:
			cards.append(evos[i])
	# 만렙/소멸 제외 + 슬롯 게이트 → 등급 가중 추첨 (일반 흔함 ~ 신화 극악, M40)
	var pool: Array = _filtered_pool()
	# ★ 보유 유물 보장 1장 (C+안): 이미 든 무기/탄막 중 아직 만렙이 아닌 것을 한 장 확정으로 끼운다.
	#   상한만 조여서는 융합이 안 살아난다 — 매 레벨업에 '지금 키우는 것'이 한 장 보이면
	#   자연히 한 축으로 수렴하고, 그 수렴이 곧 융합 재료가 된다.
	#   추첨과 같은 pool 에서 뽑고 그 항목을 pool 에서 빼기 때문에 중복 카드가 나오지 않는다.
	var owned_pool: Array = pool.filter(
		func(u: Dictionary) -> bool:
			var uid: String = String(u["id"])
			return int(_upgrade_counts.get(uid, 0)) > 0 and (_is_weapon_id(uid) or _is_bullet_id(uid))
	)
	if not owned_pool.is_empty() and cards.size() < count:
		var pick: Dictionary = owned_pool[randi() % owned_pool.size()]
		cards.append(pick)
		pool = pool.filter(func(u: Dictionary) -> bool: return String(u["id"]) != String(pick["id"]))
	for up in _weighted_pick(pool, count - cards.size()):
		cards.append(up)
	cards.shuffle()  # 보장 카드가 늘 같은 자리에 오면 '고정 슬롯'처럼 읽힌다
	# 풀 소진(전부 만렙/슬롯참) → 남는 칸은 회복/골드 카드를 번갈아(따로 선택 가능하게)
	var filler: int = 0
	while cards.size() < count:
		cards.append(HEAL_CARD if filler % 2 == 0 else GOLD_CARD)
		filler += 1
	_last_offered = []
	for c in cards:
		_last_offered.append(String((c as Dictionary)["id"]))
		_cards_box.add_child(_make_card(c as Dictionary))
	_update_reroll_btn()
	# QA 10/13: 고른 카드(포커스)가 지워지면 패드로는 다음 카드를 못 고른다 — 새 카드에 포커스(창을 처음 열 때와 같게)
	_pad_focus.call_deferred(_levelup_root)


























## 등급 가중 무작위 추출 (중복 없음). 영웅/전설/신화 가중치는 행운에 비례해 상승.
func _weighted_pick(pool: Array, count: int) -> Array:
	var lk: float = 0.0
	if G.player != null and is_instance_valid(G.player):
		lk = (G.player as Player).luck
	var out: Array = []
	var work: Array = pool.duplicate()
	while out.size() < count and not work.is_empty():
		var total: float = 0.0
		var ws: Array = []
		for u: Dictionary in work:
			var r: String = _rarity_of(String(u["id"]))
			var w: float = float(RARITY_W.get(r, 10.0))
			if r != "common" and r != "rare":
				w *= 1.0 + lk  # 행운: 고급 카드 등장 확률 상승 (고유/영웅/전설/신화)
			ws.append(w)
			total += w
		var roll: float = randf() * total
		for i in work.size():
			roll -= float(ws[i])
			if roll <= 0.0:
				out.append(work[i])
				work.remove_at(i)
				break
	return out


## 14차 목업 levelup.png — 부적 카드 296×416(1920 화면 = 부품 판 좌표), 글 안쪽 여백 28
const CARD_W: float = 296.0
const CARD_H: float = 416.0
const CARD_PAD: float = 28.0

## 결과 화면 골드 줄 — 「  ·  」 로 나뉜 항목 안의 띄어쓰기를 줄바꿈 없는 공백으로. 줄은 항목 사이에서만 꺾인다.
## (10/13 QA C9: 영어 「Star / bonus」, 한글 「· 총 / 107,555」 처럼 낱말 중간에서 갈라졌다)
func _keep_items(s: String) -> String:
	var parts: PackedStringArray = s.split("  ·  ")
	for i in parts.size():
		parts[i] = parts[i].strip_edges().replace(" ", "\u00a0")
	return "  ·  ".join(parts)


## 카드 등급 이름표 · 빛 테 — 10/13 사용자 「등급별 선택창, 뭐가 좋은 건지 안 좋은 건지 명확함이 떨어진다」.
## ★ 예전 부적 카드는 등급 이름 없이 테두리 그림만 달랐는데, 일반이 진한 빨강 띠라 가장 세 보이고
##   전설 · 신화 · 융합은 띠가 종이 색이라 가장 약해 보였다(셋이 같은 그림이기도 했다).
##   이제 카드 위 가장자리에 「등급 ◆…」 이름표(◆ 개수가 곧 순서), 등급별 테두리(talisman_g_*),
##   전설 · 융합 · 신화는 카드 뒤 빛 테가 숨 쉬듯 깜빡인다.
const GRADE_TAG: Dictionary = {
	"common": ["일반", 1, Color("8a7f66")],
	"rare": ["희귀", 2, Color("3a5ca8")],
	"epic": ["영웅", 3, Color("8a4ab0")],
	"unique": ["고유", 3, Color("1e8468")],
	"legendary": ["전설", 4, Color("c48c1c")],
	"evo": ["융합", 4, Color("d0581a")],
	"mythic": ["신화", 5, Color("cc2050")],
}


func _grade_key(id: String) -> String:
	return "evo" if id.begins_with("evo_") else _rarity_of(id)


## 카드 위 가장자리에 반쯤 걸치는 이름표. parent(카드) 기준 위쪽 가운데.
func _add_grade_tag(parent: Control, id: String) -> void:
	var g: Array = GRADE_TAG.get(_grade_key(id), GRADE_TAG["common"])
	var sb := StyleBoxFlat.new()
	sb.bg_color = g[2]
	sb.set_border_width_all(2)
	sb.border_color = UiParts.INK
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 1.0
	sb.content_margin_bottom = 1.0
	var p := PanelContainer.new()
	p.name = "GradeTag"
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = "%s %s" % [I18n.t(String(g[0])), "◆".repeat(int(g[1]))]
	UiFont.apply(l, 24)
	l.add_theme_color_override("font_color", UiParts.PAPER_HI)
	l.add_theme_color_override("font_outline_color", UiParts.INK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.offset_top = -18.0
	parent.add_child(p)


## 전설 · 융합 · 신화만 카드 뒤 빛 테(깜빡임). 레벨업 창은 트리를 멈추니 트윈은 멈춤에서도 돈다.
func _add_grade_glow(parent: Control, id: String) -> void:
	var k: String = _grade_key(id)
	if not (k in ["legendary", "evo", "mythic"]):
		return
	var col: Color = (GRADE_TAG[k] as Array)[2]
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col, 0.0)
	sb.shadow_color = Color(col.lightened(0.2), 0.8)
	sb.shadow_size = 16
	var gp := Panel.new()
	gp.name = "GradeGlow"
	gp.add_theme_stylebox_override("panel", sb)
	gp.show_behind_parent = true
	gp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gp.offset_left = 6.0
	gp.offset_top = 6.0
	gp.offset_right = -6.0
	gp.offset_bottom = -6.0
	parent.add_child(gp)
	var per: float = 0.45 if k == "mythic" else 0.8
	var tw := gp.create_tween().set_loops()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(gp, "modulate:a", 0.3, per).set_trans(Tween.TRANS_SINE)
	tw.tween_property(gp, "modulate:a", 1.0, per).set_trans(Tween.TRANS_SINE)


func _make_card(up: Dictionary) -> Button:
	var id: String = String(up["id"])
	var rk: String = _rarity_of(id)
	var rar: Dictionary = RARITY[rk]
	var frame: Color = rar["frame"]
	var is_evo: bool = id.begins_with("evo_")
	# 카드가 적는 레벨은 장부가 아니라 **무기가 실제로 쓰는 값**이다 — _shown_level 주석 참고.
	var lvl: int = _shown_level(id)
	var mx: int = _shown_max(id, int(up.get("max", 0)))
	var paper: bool = UiParts.on()
	# 글자 색 — 부적(한지)이면 먹 · 주사, 예전 판이면 밝은 색
	var c_name: Color = UiParts.INK if paper else Color(0.97, 0.97, 1.0)
	var c_body: Color = UiParts.LAC if paper else Color("a8a2c2")

	var btn := Button.new()
	# 14차 2절 2 · U3: 부적 카드. 카드에는 아이콘 · 이름 · 배지 · 효과 두 줄 · 레벨 점만 — 숫자 덤프는 일시정지 상세로.
	var cw: float = CARD_W if paper else 224.0
	var ch: float = CARD_H if paper else 320.0
	btn.custom_minimum_size = Vector2(cw, ch)
	btn.pivot_offset = Vector2(cw, ch) * 0.5
	btn.focus_mode = Control.FOCUS_ALL
	_add_grade_glow(btn, id)
	var tb: StyleBoxTexture = UiParts.talisman_box("evo" if is_evo else rk)
	if tb != null:
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(st, tb)
		# 고른 테(talisman_sel 2칸 깜빡) — 카드보다 3px(UI 6) 크게, 올리거나 포커스일 때만
		var sel := NinePatchRect.new()
		sel.texture = UiParts.tex("talisman_sel", 0, 2)
		for sd in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			sel.set_patch_margin(sd, 12)
		sel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sel.offset_left = -6.0
		sel.offset_top = -6.0
		sel.offset_right = 6.0
		sel.offset_bottom = 6.0
		sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sel.visible = false
		btn.add_child(sel)
		var blink := sel.create_tween().set_loops()
		blink.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		blink.tween_interval(0.25)
		blink.tween_callback(func() -> void: sel.texture = UiParts.tex("talisman_sel", 1, 2))
		blink.tween_interval(0.25)
		blink.tween_callback(func() -> void: sel.texture = UiParts.tex("talisman_sel", 0, 2))
		btn.mouse_entered.connect(func() -> void: sel.visible = true)
		btn.mouse_exited.connect(func() -> void: sel.visible = btn.has_focus())
		btn.focus_entered.connect(func() -> void: sel.visible = true)
		btn.focus_exited.connect(func() -> void: sel.visible = false)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.10, 0.14, 0.98)
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(3)
		sb.border_color = frame
		for st in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(st, sb)
	btn.mouse_entered.connect(func() -> void: _card_scale(btn, 1.03))
	btn.mouse_exited.connect(func() -> void: _card_scale(btn, 1.0))
	_add_grade_tag(btn, id)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = CARD_PAD if paper else 18.0
	v.offset_right = -(CARD_PAD if paper else 18.0)
	v.offset_top = 32.0 if paper else 26.0
	v.offset_bottom = -30.0 if paper else -22.0
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", 10 if paper else 8)
	var tw: float = cw - 2.0 * (CARD_PAD if paper else 18.0)      # 글 폭(낱말 단위로 미리 꺾는 기준)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(v)

	# 아이콘 — 짙은 칸(cell) 안
	var chip := PanelContainer.new()
	var cb: StyleBoxTexture = UiParts.cell_box(false, 6.0)
	if cb != null:
		chip.add_theme_stylebox_override("panel", cb)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.custom_minimum_size = Vector2(120, 120) if paper else Vector2(84, 84)
	var icc := CenterContainer.new()
	icc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ib := IconBadge.new()
	ib.bare = paper          # 목업: 칸 안에 도트 그림만(원 바탕 없이) · ×3
	icc.add_child(ib.setup(id, 64.0))
	chip.add_child(icc)
	var chip_center := CenterContainer.new()
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_center.add_child(chip)
	v.add_child(chip_center)

	var name_lbl := Label.new()
	name_lbl.text = UiKit.wrap_words(_card_title(id, String(up["n"])).replace("무기: ", "").replace("탄막: ", "").replace("Weapon: ", "").replace("Rounds: ", ""), 24, tw)
	UiFont.apply(name_lbl, 24)
	name_lbl.add_theme_color_override("font_color", c_name)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.max_lines_visible = 2
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_lbl)

	# 배지 — 「새로!」 · 「Lv 3 → 4」 · 「융합」 · 「MAX」
	var nxt0: int = _next_level_of(id) if _is_weapon_id(id) else lvl + 1
	var badge_txt: String = ""
	if is_evo:
		badge_txt = I18n.t("새로!")   # 「융합」은 위 등급 이름표가 말한다
	elif mx > 0 and lvl >= mx:
		badge_txt = "MAX"
	elif lvl <= 0:
		badge_txt = I18n.t("새로!")
	else:
		badge_txt = "Lv %d → %d" % [lvl, mini(nxt0, maxi(mx, nxt0))]
	v.add_child(UiParts.badge(badge_txt, 20) if paper else _pill(badge_txt, Color("ffd54a")))

	# 효과 — 두 줄까지. 바뀌는 수치가 있으면 그 줄(바뀐 값만 주사색), 없으면 짧은 설명
	var change: String = _card_change_line(_card_stats(id))
	var eff := RichTextLabel.new()
	eff.bbcode_enabled = true
	eff.fit_content = true
	eff.scroll_active = false
	eff.autowrap_mode = TextServer.AUTOWRAP_OFF        # 낱말 단위로 미리 꺾는다(wrap_words) — 자동은 「즉 / 시」처럼 끊는다
	eff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.apply(eff, 20)
	eff.add_theme_color_override("default_color", c_body)
	var hot: String = (UiParts.CIN_D if paper else Color("9dff6b")).to_html(false)
	if change != "":
		eff.text = "[center]%s[/center]" % _bb_change(UiKit.wrap_words(change, 20, tw)).replace("#9dff6b", "#" + hot)
	else:
		eff.text = "[center]%s[/center]" % _two_lines(String(up["d"]).split("\n")[0], 20, tw).replace("[", "[lb]")
	v.add_child(eff)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)

	# 레벨 점 — 지금까지 찬 점 · 남은 점(부적 pip). 많으면(12칸 넘음) 숫자로
	if not is_evo and mx > 0:
		var tot: int = maxi(mx, nxt0)
		if paper and tot <= 12:
			v.add_child(UiParts.pips(lvl, tot))
		else:
			var dl := Label.new()
			dl.text = "Lv %d / %d" % [lvl, tot]
			UiFont.apply(dl, 16)
			dl.add_theme_color_override("font_color", c_body)
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(dl)

	# 숫자키 — 카드 밑(목업처럼). 폰은 없음 · 패드가 꽂혀 있으면 없음(16차 4-5: 패드는 A 로 고른다 — 키보드 숫자는 잡음)
	if not _mobile and Input.get_connected_joypads().is_empty():
		btn.clip_contents = false
		var key_lbl := Label.new()
		key_lbl.text = str(_last_offered.size())   # _populate_cards 가 이 카드 id 를 먼저 넣고 부른다
		UiFont.apply(key_lbl, 24)
		key_lbl.add_theme_color_override("font_color", UiParts.BRASS_HI)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		key_lbl.offset_top = 12.0
		key_lbl.offset_bottom = 40.0
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(key_lbl)

	# ★ pressed 는 놓는 순간 발동한다 — 손가락을 끌다 떼면 그 카드가 선택된다.
	#   끌면 취소되는 탭으로 바꾸고, 카드가 뜬 직후 짧게는 아예 안 받는다.
	UiKit.tap_only(btn, func() -> void: _card_pressed(id), _cards_tap_ready)
	return btn


## 카드 수치 글에서 「바뀌는 것」 한 줄. 무기는 「▲ 이번 레벨: …」 줄, 스탯 카드는 「지금 → 먹은 뒤」 첫 줄.
func _card_change_line(stat_all: String) -> String:
	var mark: String = I18n.t("이번 레벨: %s") % ""
	for ln: String in stat_all.split("\n"):
		if mark != "" and ln.begins_with(mark):
			return ln.substr(mark.length())
	var first: String = stat_all.split("\n")[0] if stat_all != "" else ""
	return first if first.contains("→") else ""


## 위 한 줄을 뺀 나머지 수치 줄.
func _card_stats_rest(stat_all: String, change: String) -> String:
	if change == "":
		return stat_all
	var out: PackedStringArray = []
	for ln: String in stat_all.split("\n"):
		if ln.ends_with(change):
			continue
		out.append(ln)
	return "\n".join(out)


## 「a → b」 의 b 만 초록. bbcode 대괄호는 풀어 둔다.
func _bb_change(t: String) -> String:
	var e: String = t.replace("[", "[lb]")
	var i: int = e.find("→")
	if i < 0:
		return e
	var rest: String = e.substr(i + 1)
	# 14차: wrap_words 가 화살표 뒤에서 줄을 꺾었으면 그 줄바꿈을 살린다(지우면 한 줄로 붙어 카드 밖으로 나갔다)
	var gap: String = "\n" if rest.lstrip(" ").begins_with("\n") else " "
	return e.substr(0, i + 1) + gap + "[color=#9dff6b]" + rest.strip_edges() + "[/color]"


## 등급 사다리 라이더는 2026-09-04 에 없앴다. 값은 b_ 0.07 · c_ 0.11 · wp_ 0.09 · wpn_ 0.08 이었고,
## _apply_upgrade 맨 앞에서 카드 id 접두사만 보고 card_add 에 얹었다. 되살릴 일이 있으면
## 그 자리(_apply_upgrade 첫머리)와 wp_/wpn_ 분기를 보면 된다 — 다만 같은 불만이 다시 나온다.


















func _card_scale(btn: Button, s: float) -> void:
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(s, s), 0.08)


func _pill(text: String, c: Color) -> Control:
	var p := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = c
	psb.set_corner_radius_all(8)
	psb.content_margin_left = 8
	psb.content_margin_right = 8
	psb.content_margin_top = 1
	psb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", psb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	UiFont.apply(l, 12)
	l.add_theme_color_override("font_color", Color("2a1e00"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## 카드 하단 별 진행바 (채움/빈 별, 상한>10이면 게이지 막대)
class _StarRow:
	extends Control
	var _lvl: int = 0
	var _mx: int = 0
	var _glow: Color = Color("ffd54a")
	var _bar: bool = false

	func setup(lvl: int, mx: int, glow: Color) -> _StarRow:
		_lvl = lvl
		_mx = mx
		_glow = glow
		_bar = mx > 10
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(90.0, 18.0) if _bar else Vector2(float(mx) * 17.0, 18.0)
		return self

	func _draw() -> void:
		if _bar:
			var w: float = size.x
			draw_rect(Rect2(0, 6, w, 6), Color(1, 1, 1, 0.14), true)
			draw_rect(Rect2(0, 6, w * clampf(float(_lvl) / float(_mx), 0.0, 1.0), 6), _glow, true)
			return
		var near_cap: bool = _lvl >= _mx - 1
		for i in _mx:
			var ctr := Vector2(8.5 + float(i) * 17.0, 9.0)
			if i < _lvl:
				_star(ctr, 7.0, _glow if near_cap else Color("ffd54a"), true)
			else:
				_star(ctr, 7.0, Color(1, 1, 1, 0.16), false)

	func _star(c: Vector2, r: float, col: Color, filled: bool) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var a: float = -PI * 0.5 + PI * float(i) / 5.0
			var rr: float = r if i % 2 == 0 else r * 0.44
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		if filled:
			draw_colored_polygon(pts, col)
		else:
			pts.append(pts[0])
			draw_polyline(pts, col, 1.4)


func _on_reroll() -> void:
	if _reroll_left <= 0:
		return
	_reroll_left -= 1
	G.sfx("pickup", 1.3)
	_populate_cards()


func _update_reroll_btn() -> void:
	if _reroll_btn == null:
		return
	_reroll_btn.text = I18n.t("다시 뽑기 %d") % _reroll_left
	_reroll_btn.disabled = _reroll_left <= 0
	if _banish_btn != null:
		_banish_btn.text = I18n.t("봉인할 카드 고르기") if _banish_mode else I18n.t("봉인 %d") % _banish_left
		_banish_btn.disabled = _banish_left <= 0 and not _banish_mode


## ── 14차 3절 4: 건너뛰기 · 봉인 ──
## 건너뛰기 = 이번 레벨업을 받지 않는다(횟수 제한 없음). 봉인 = 고른 카드를 이번 판 카드 풀에서 영원히 뺀다
## (판 시작 1 + 영구 강화 「봉인」 레벨). 봉인을 누르면 다음에 누른 카드가 봉인되고 카드가 다시 뽑힌다.
var _skip_btn: Button
var _banish_btn: Button
var _banish_mode: bool = false
var _banish_left: int = 0
var _banished: Dictionary = {}


func _on_skip() -> void:
	if not _cards_tap_ready():
		return
	_banish_mode = false
	_pending_levelups -= 1
	G.sfx("pickup", 0.8)
	if _pending_levelups > 0:
		_populate_cards()
	else:
		_levelup_root.visible = false
		get_tree().paused = false


func _on_banish_toggle() -> void:
	if _banish_left <= 0 and not _banish_mode:
		return
	_banish_mode = not _banish_mode
	_update_reroll_btn()
	for c in _cards_box.get_children():
		if c is Control:
			(c as Control).modulate = Color(1.0, 0.72, 0.68) if _banish_mode else Color.WHITE


## 카드를 누름 — 봉인 중이면 봉인, 아니면 고르기.
func _card_pressed(id: String) -> void:
	if _banish_mode:
		_banish_mode = false
		_banish_left -= 1
		_banished[id] = true
		G.sfx("hurt", 0.7, -4.0)
		_populate_cards()
		return
	_choose(id)


func _choose(id: String) -> void:
	_apply_upgrade(id)
	_pending_levelups -= 1
	if _pending_levelups > 0:
		_populate_cards()
	else:
		_levelup_root.visible = false
		get_tree().paused = false
	if id.begins_with("evo_"):
		_fusion_flourish(id)


## 융합 완성 연출.
## ★ 예전엔 융합 카드를 골라도 그냥 적용되고 끝이었다 — 재료 11장을 모은 보상이 다른 카드와
##   구분이 안 됐다. 화면이 한 번 멎고 빛나고, 무엇이 무엇으로 합쳐졌는지 이름으로 알려준다.
##   ★ 반드시 모달이 닫히고 일시정지가 풀린 뒤에 돌아야 한다 — paused 중엔 트윈이 안 움직인다.
func _fusion_flourish(id: String) -> void:
	var name: String = id
	var mats: PackedStringArray = []
	for e: Dictionary in EVOLUTIONS:
		if String(e["id"]) == id:
			name = String(e["n"])
			for r: String in (e["req"] as Array):
				mats.append(_card_name(r))
			break
	G.hitstop(0.16)
	G.add_shake(1.1)
	G.set_slowmo(0.45)
	G.magnet_all(1.6)   # 화면이 늘어진 동안 바닥 보상이 끌려온다
	G.sfx("levelup", 0.62)
	G.sfx_throttled("levelup", 1.35, -3.0, 0.0)
	_win_flash()
	if G.player != null and is_instance_valid(G.player):
		(G.player as Player).grant_iframe(1.4)  # 연출 중 사고사 방지
		var fl: AnimatedSprite2D = FxLib.burst(self, (G.player as Node2D).global_position, "ui/moment", "fusion_flash", 0.0, 1.0, -1.0, 50)
		if fl != null:
			fl.process_mode = Node.PROCESS_MODE_ALWAYS
	var mat_line: String = I18n.t("%s + %s 가 하나로") % [mats[0], mats[1]] if mats.size() >= 2 else ""
	var hid: String = String(CharForge.hero_slot(String(_last_char.get("id", ""))).get("id", ""))
	var htex: Texture2D = CharForge.frame_tex(hid, "portrait") if hid != "" and CharForge.has_anim(hid, "portrait") else null
	_fusion_end_ms = Time.get_ticks_msec() + 900   # ★ 슬로모션을 푸는 시계 — 컷인으로 빠지기 전에 걸어야 한다
	if _cutin({"word": FxLib.word_sheet("w_fusion"), "name": name, "sub": mat_line, "col": Color("ffd54a"),
			"tex": htex, "k": 3, "left": true, "hold": 1.2}):
		return
	_wave_banner(I18n.t("융합: %s") % name, Color("ffd54a"), [FxLib.word_sheet("w_fusion")], name)
	if mats.size() >= 2:
		_wave_banner(mat_line, Color("f7dd7e"))


var _fusion_end_ms: int = 0








func _apply_upgrade(id: String) -> void:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return
	if id.begins_with("evo_"):
		_fused_from_lv = 0     # 이번 융합에 녹일 재료 레벨을 새로 센다
		p.cf_moment("ultimate")   # 융합은 판에서 가장 큰 순간 — 궁극기 동작(전설 이상)

	# ── 등급 사다리 라이더는 걷어냈다 (2026-09-04) ──
	# 예전엔 여기서 카드 id 접두사만 보고 전역 공격력(card_add)을 얹었다
	#   b_ +7% · c_ +11% · wp_ +9% · wpn_ +8%
	# 픽당 전투력 서열을 세우려던 장치였지만, 플레이어 눈에는 "탄막 카드를 먹었는데
	# 왜 소총 데미지가 오르지" 로만 보였다. 실측 기여가 71~159% 라 사실상 성장의 절반이
	# 이 보이지 않는 줄에서 나오고 있었다.
	# ★ 원칙: 무기 카드는 그 무기만, 탄막 카드는 그 탄막만 바꾼다.
	#   등급 격차는 카드 자체 수치와 등장 가중치(RARITY_W)로 잡는다.
	# 도깨비 대장장이 — 무기를 벼린다. 무기 카드를 고르면 한 단계가 더 붙는다.
	if p.ability == "forge" and (id.begins_with("wp_") or id.begins_with("wpn_") or id.begins_with("summon_")):
		_forge_extra = true
	if not id.begins_with("evo_"):
		_upgrade_counts[id] = int(_upgrade_counts.get(id, 0)) + 1
		# (진화는 무기 만렙이 아니라 '특정 무기 조합'으로만 — _available_evolutions 참고)
	if id.begins_with("m_"):
		_mythic_taken += 1
		_mythic_ids.append(String(id))  # HUD 에 뭘 먹었는지 남긴다 (예전엔 아무 표시도 없었다)
	match id:
		"dmg":
			p.card_add += 0.26  # 합연산 기준 표기 (카드 텍스트 "+26%")
		"rate":
			p.cut_rate(0.88)
		"speed":
			p.move_speed *= 1.08
		"multi":
			p.proj_bonus += 1
		"pierce":
			p.pierce += 1
		"hp":
			p.max_hp += 18.0
			p.hp = minf(p.max_hp, p.hp + 18.0)
			G.player_hp_changed.emit()
		"bspeed":
			p.bullet_speed *= 1.14
		"crit":  # 일반 소스 상한 70% — 100%는 융합(필중의 눈)/시그니처 전유물 (M37)
			p.add_crit(0.09)
		"critdmg":
			p.crit_mult += 0.30
		"regen":
			p.regen += 1.0
		"armor":
			p.armor += 2.0
		"magnet":
			p.magnet_bonus += 55.0
		"luck":
			p.luck += 0.06  # 행운은 대폭 러프 (드랍은 lf=1+luck 곱연산, 기본 극악)
		"xp_gain":
			p.xp_mult += 0.12  # 카드 수를 늘리는 복리 카드라 커먼 안에서도 실질 최상위였다
		"dashcd":
			p.dash_cd_mult = maxf(Player.DASH_CD_MULT_FLOOR, p.dash_cd_mult * 0.85)
		"thorns":
			p.thorns += 8.0
		"b_ice":
			p.b_ice += 1
		"b_fire":
			p.b_fire += 1
		"b_poison":
			p.b_poison += 1
		"b_shock":
			p.b_shock += 1
		"b_chain":
			p.b_chain += 1
		"b_homing":
			p.b_homing += 1
		"b_big":
			p.b_big += 1
		"b_bounce":
			p.b_bounce += 1
		"b_exec":
			p.b_exec += 1
		"b_vamp":
			p.b_vamp += 1
		"b_bloom":
			p.b_bloom += 1
		# ── 무기 카드 (영웅) ──
		# ★ 무기 레벨만 올리면 슬롯이 찬 뒤엔 "그 무기 한 정만 +22%" 라 전역 곱연산인 커먼에
		#   계속 진다. 무기 카드마다 전역 공격력 라이더를 얹어 등급값을 맞춘다.
		"wp_heavy":
			p.add_primary_weapon("heavy")
		"wp_rapid":
			p.add_primary_weapon("rapid")
		"wp_mid":
			p.add_primary_weapon("mid")
		"wp_melee":
			p.add_primary_weapon("melee")
		"wp_balanced":
			p.add_primary_weapon("balanced")
		"wp_bow":
			p.add_primary_weapon("bow")
		"wp_fan":
			p.add_primary_weapon("fan")
		"wp_sinkal":
			p.add_primary_weapon("sinkal")
		"wp_jakdu":
			p.add_primary_weapon("jakdu")
		"wpn_orb", "wpn_chain", "wpn_fire", "wpn_ice", "wpn_poison", "wpn_summon", "summon_ice", "wpn_whip", "wpn_boomerang", "wpn_beam":
			var first: bool = not (p.weapons.has(id) and is_instance_valid(p.weapons[id]))
			p.add_weapon(id)
			if first:
				p.add_weapon(id)  # 영웅 등급 보정: 특수무기는 2레벨로 시작(즉시 체감)
			p.special_mult *= 1.04
		"gamble":
			match randi() % 4:
				0:
					p.card_add += 0.45
				1:
					p.proj_bonus += 2
				2:
					p.cut_rate(0.78)
				3:
					p.add_crit(0.18)  # 도박도 일반 상한
		# ── 융합 (M37): 재료 소멸(슬롯 해방) → 초월 강화판 재부여 ──
		# _fused_from_lv 는 _consume_material 이 채운다. 한 번의 융합마다 0 부터 세야 하므로
		# 여기서 리셋한다 — 안 하면 두 번째 융합이 첫 번째 재료 레벨을 물려받는다.
		"evo_inferno":  # 화염오라 + 탄막화염 소멸 → 오라 Lv11 + 화상 6
			_consume_material("wpn_fire")
			_consume_material("b_fire")
			p.add_weapon_at_level("wpn_fire", _fuse_lv(11))
			p.b_fire = maxi(p.b_fire, 6)
			p.card_mult *= 1.25
			p.fused_marks["wpn_fire"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_blizzard":  # 빙결파동 + 탄막얼음 소멸 → 파동 Lv11 + 얼음 6
			_consume_material("wpn_ice")
			_consume_material("b_ice")
			p.add_weapon_at_level("wpn_ice", _fuse_lv(11))
			p.b_ice = maxi(p.b_ice, 6)
			p.card_mult *= 1.25
			p.fused_marks["wpn_ice"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_plague":  # 맹독장판 + 탄막맹독 소멸 → 장판 Lv11 + 맹독 6
			_consume_material("wpn_poison")
			_consume_material("b_poison")
			p.add_weapon_at_level("wpn_poison", _fuse_lv(11))
			p.b_poison = maxi(p.b_poison, 6)
			p.card_mult *= 1.25  # 융합 공통 라이더 — 예전엔 이게 없어 같은 11픽 투자에 보상이 절반이었다
			p.fused_marks["wpn_poison"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_railcannon":  # 대구경캐논 + 거대탄환 소멸 → 캐논 Lv11 + 관통 8 (가늘고 긴 관통빔)
			_consume_material("wp_heavy")
			_consume_material("b_big")
			p.add_primary_at_level("heavy", _fuse_lv(11))
			p.pierce += 8
			p.card_mult *= 1.25
			p.fused_marks["heavy"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_tempest":  # 번개사슬 + 탄막감전 소멸 → 사슬 Lv11 + 감전 6
			_consume_material("wpn_chain")
			_consume_material("b_shock")
			p.add_weapon_at_level("wpn_chain", _fuse_lv(11))
			p.b_shock = maxi(p.b_shock, 6)
			p.card_mult *= 1.25
			p.fused_marks["wpn_chain"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_legion":  # 소환수 + 얼음정령 소멸(무기+무기) → 하나의 군단으로 합쳐진다
			# ★ 예전엔 둘 다 소멸시키고 둘 다 다시 줬다. 그래서 무기 칸이 하나도 안 비었고,
			#   "재료 2칸 → 결과 1칸"이라는 다른 융합의 규칙과 혼자 어긋났다.
			#   이제 소환수 한 정으로 합치고 얼음 정령의 힘은 그 안에 얹는다 — 칸이 정확히 1개 빈다.
			# ★ 예전엔 여기서 b_ice(탄막 빙결) 4 를 얹고 "얼음 정령의 빙결이 군단에 남는다"고 적었다.
			#   그런데 소환수는 **탄을 안 쏜다** — 접촉 타격뿐이라 그 빙결이 걸릴 자리가 없었다.
			#   그래서 융합 전후에 달라지는 게 레벨과 card_mult 뿐이었고, 화면에서는
			#   "얼음정령이 사라지고 초록 소환수만 늘었다"로만 보였다(2026-09-06 지적).
			#   이제 합쳐진 소환수가 정령의 얼음탄을 **직접 쏜다**(summon_weapon.gd 의 legion).
			#   b_ice 는 내 총알에도 그대로 남겨 둔다 — 그건 원래 값을 하고 있었다.
			_consume_material("wpn_summon")
			_consume_material("summon_ice")
			p.add_weapon_at_level("wpn_summon", _fuse_lv(13))  # 두 무기가 합쳐진 만큼 레벨을 더 준다
			p.b_ice = maxi(p.b_ice, 4)
			p.card_mult *= 1.25
			p.fused_marks["wpn_summon"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			# 표식이 붙은 뒤에 다시 세워야 소환수가 '군단'으로 다시 태어난다(사격·긴 사거리)
			if p.weapons.has("wpn_summon") and is_instance_valid(p.weapons["wpn_summon"]):
				p.weapons["wpn_summon"].call("_rebuild")
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_reaper":  # 채찍 + 처형 소멸 → 채찍 Lv11 + 처형 6
			_consume_material("wpn_whip")
			_consume_material("b_exec")
			p.add_weapon_at_level("wpn_whip", _fuse_lv(11))
			p.b_exec = maxi(p.b_exec, 6)
			p.card_mult *= 1.25
			p.fused_marks["wpn_whip"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_nova":  # 회전레이저 + 탄막화염 소멸 → 레이저 Lv11 + 화상 6
			_consume_material("wpn_beam")
			_consume_material("b_fire")
			p.add_weapon_at_level("wpn_beam", _fuse_lv(11))
			p.b_fire = maxi(p.b_fire, 6)
			p.card_mult *= 1.25
			p.fused_marks["wpn_beam"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_deadeye":  # 속사 + 치명타 소멸 → 속사 Lv11 + 유도 6 + 치명타 100% (모든 탄이 급소를 쫓는다)
			# ★ 레시피(req)는 ["wp_rapid","crit"] 인데 여기서 소멸시키던 건 b_homing 이었다.
			#   b_homing 은 공통 카드에서 뺀 뒤(2026-09-05) 아예 얻을 수 없는 id 라, 융합해도
			#   재료가 안 사라지고 치명타 카드는 풀에 그대로 남았다 — "칸 1개 해방" 문구와도
			#   어긋났다. ESC 는 req 를 읽어 "치명타 7/7" 이라 띄우는데 실제 소비는 딴 것이었다.
			_consume_material("wp_rapid")
			_consume_material("crit")
			p.add_primary_at_level("rapid", _fuse_lv(11))
			p.b_homing = maxi(p.b_homing, 6)
			p.crit_chance = 1.0
			p.crit_mult += 0.30  # 여기만 유독 튀어 다른 융합의 8배였다
			p.card_mult *= 1.25
			p.fused_marks["rapid"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_ninetail":  # 태극부채 + 연쇄 소멸 → 부채 Lv11 + 연쇄 6 (아홉 갈래로 퍼지는 부채)
			_consume_material("wp_fan")
			_consume_material("b_chain")
			p.add_primary_at_level("fan", _fuse_lv(11))
			p.b_chain = maxi(p.b_chain, 6)
			p.card_mult *= 1.25
			p.fused_marks["fan"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_ledger":  # 각궁 + 처형 소멸 → 각궁 Lv11 + 처형 6 + 관통 (이름이 적히면 끝난다)
			_consume_material("wp_bow")
			_consume_material("b_exec")
			p.add_primary_at_level("bow", _fuse_lv(11))
			p.b_exec = maxi(p.b_exec, 6)
			p.pierce += 5
			p.card_mult *= 1.25
			p.fused_marks["bow"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		"evo_orb":  # 작두 + 흡혈 소멸 → 작두 Lv11 + 흡혈 6 + 체력 (여의주를 문 채 벤다)
			_consume_material("wp_jakdu")
			_consume_material("b_vamp")
			p.add_primary_at_level("jakdu", _fuse_lv(11))
			p.b_vamp = maxi(p.b_vamp, 6)
			p.max_hp += 60.0
			p.hp = minf(p.max_hp, p.hp + 60.0)
			G.player_hp_changed.emit()
			p.card_mult *= 1.25
			p.fused_marks["jakdu"] = id  # 융합 표식 — 탄환/시길이 초월 무기로 보이게
			p._rebuild_sigil()  # 표식이 붙은 뒤라야 발밑 룬이 금빛 6갈래로 바뀐다
			_evolved[id] = true
		# ── 캐릭터 고유 카드 (M37) ──
		"c_allround":  # 기본: 만능 훈련
			p.card_add += 0.10
			p.move_speed *= 1.03
			p.max_hp += 8.0
			p.hp = minf(p.max_hp, p.hp + 8.0)
			G.player_hp_changed.emit()
		"c_bloodlust":  # 광전사: 피의 갈망
			p.card_add += 0.16
			p.b_vamp += 1
		"c_overheat":  # 사수: 과열 기관
			p.cut_rate(0.90)
			p.bullet_speed *= 1.08
		"c_goldsense":  # 수집가: 황금 감각
			p.luck += 0.08
			p.magnet_bonus += 40.0
		"c_ironwill":  # 수호자: 강철 의지
			p.armor += 3.0
			p.thorns += 6.0
			p.max_hp += 12.0
			p.hp = minf(p.max_hp, p.hp + 12.0)
			G.player_hp_changed.emit()
		"c_allin":  # 도박사: 올인
			p.add_crit(0.05)
			p.crit_mult += 0.2
		"c_charge":  # 돌격기사: 돌격 나팔
			p.dash_cd_mult = maxf(0.25, p.dash_cd_mult * 0.88)
			p.card_add += 0.11
		"c_emberheart":  # 화염술사: 잉걸 심장
			p.special_mult *= 1.10
			p.b_fire += 1
		"c_umbra":  # 그림자 도적: 그림자 걸음
			p.crit_mult += 0.25
			p.move_speed *= 1.04
		"c_bellcall":  # 무당: 방울 부름
			p.special_mult *= 1.08
			p.luck += 0.05
		"c_bloomstep":  # 화랑: 꽃걸음 — 검무가 더 오래·더 세게 오른다 (설명대로)
			p.move_speed *= 1.06
			p.dance_max += 1.5
			p.dance_rate += 0.012
		"c_temper":  # 도깨비 대장장이: 담금질
			p.special_mult *= 1.16
		"c_mantra":  # 승려: 진언 — 염주가 더 빨리 채워진다 (설명대로)
			p.armor += 2.0
			p.regen += 0.6
			p.bead_cd_max = maxf(2.5, p.bead_cd_max - 1.0)
		"c_talon":  # 매잡이: 매의 발톱
			p.b_homing += 1
			p.add_crit(0.06)
		# ── 전설/신화 카드 (M40) ──
		# ── 전설 (l_) ──
		# ★ 예전엔 전설 3종이 각각 전투력 0 / 커먼 이하 / 커먼 동급이었다. 20배 어렵게 만나서
		#   커먼 한 장 값이면 고를 이유가 없다. 전부 '전역 공격 라이더 + 고유 효과'로 다시 짰다.
		"l_timewarp":  # 시간 왜곡: 적이 느려지고, 느려진 적은 더 아프게 맞는다
			p.enemy_slow = minf(0.30, p.enemy_slow + 0.15)
			p.card_mult *= 1.32  # 실측 픽당 배수가 커먼 rate(×1.25)에 지고 있었다
			for n in get_tree().get_nodes_in_group("enemy"):
				var en := n as Enemy
				if en != null and is_instance_valid(en):
					en.spd *= 0.85
		"l_giant":  # 거인의 탄환: 커지고, 꿰뚫고, 세진다
			p.b_big += 2
			p.pierce += 2
			p.card_mult *= 1.45
		"l_echo":  # 메아리: 발사가 두 번 울린다
			p.echo_chance = minf(0.70, p.echo_chance + 0.35)
			p.card_mult *= 1.12
		# ── 신화 (m_) ──
		"m_apocalypse":  # 종말의 인장
			p.card_mult *= 2.2
			p.crit_mult += 0.5
		"m_immortal":  # 불사의 심장 — 생존 전용이라 전투력이 0이던 것을 보강
			p.last_stand = true
			p.card_mult *= 1.28  # 아래 1.3 과 합쳐 ×1.66 — 신화가 전설보다 낮던 역전 해소
			p.max_hp += 80.0
			p.hp = minf(p.max_hp, p.hp + 80.0)
			p.armor += 5.0
			p.card_mult *= 1.3
			G.player_hp_changed.emit()
		"m_transcend":  # 초월: 보유 무기를 한계 위로 밀어 올린다 (한계돌파)
			# ★ 예전엔 무기 노드의 레벨만 올리고 _upgrade_counts 는 그대로 뒀다. 그래서
			#   (a) 카드에는 여전히 예전 별 개수가 찍히고, (b) 만렙 판정이 옛 값을 보니까
			#   이미 한계를 넘긴 무기가 카드 풀에 계속 남아 또 강화됐다.
			#   이제 장부(_upgrade_counts)까지 같이 올린다 — 표시가 맞고, 만렙이면 풀에서 빠진다.
			#   '한계돌파'는 여기서 정확히 +3 만큼만 일어나고 그 뒤로는 더 안 늘어난다.
			for w in p.weapons_primary:
				w["level"] = int(w["level"]) + 3
			for k in p.weapons.keys():
				if is_instance_valid(p.weapons[k]):
					for _i in 3:
						(p.weapons[k] as Node).call("level_up")
			# ★ 장부(_upgrade_counts)는 **안 올린다.** 올리면 "3장 미리 먹은 것"이 되어
			#   초월이 아니게 된다. 실제 레벨만 밀어 올린다.
			#   ★ 풀에서 빠지는 판정은 장부가 아니라 _shown_level(=실제 레벨)이 한다.
			#   그래서 상한도 같이 올려 줘야 한다 — _upgrade_pool 필터의 transcend_bonus 참고.
			_transcended = true
			p.transcend_bonus += 3    # 이 판에서 앞으로 드는 무기도 3단계 위에서 시작
			p.card_mult *= 1.25
		"heal_card":  # 풀 소진 시 대체 카드 — 회복
			p.hp = minf(p.max_hp, p.hp + p.max_hp * 0.30)
			G.player_hp_changed.emit()
			G.sfx("levelup", 1.1)
		"gold_card":  # 풀 소진 시 대체 카드 — 골드 (보너스 경로: 드랍 예산 미잠식, 감사 C30)
			G.add_gold_bonus(int(round(randf_range(18.0, 40.0) * G.run_gold_mult())))
			G.sfx("pickup", 1.2)
	if _forge_extra:
		_forge_extra = false
		if _shown_level(id) >= _weapon_cap(id):
			pass   # 벼림 상한(11)에 닿았으면 덤 단계는 안 붙인다 — 카드 예고(_next_level_of)도 같은 값으로 자른다
		elif id.begins_with("wp_"):
			p.add_primary_weapon(String(_WP_KEY.get(id, "")))
		elif id.begins_with("wpn_") or id.begins_with("summon_"):
			p.add_weapon(id)
	if id.begins_with("evo_"):  # 융합 완성 → 도감 해금 + 통계
		G.codex_see("fus_" + id)
		G.stat_add("total_fusions", 1)
		G.run_fusions += 1
		G.stat_max("best_run_fusions", G.run_fusions)
		G.check_achievements()


## 도박꾼 도박 롤 — 10레벨마다 1회. 극단(초대박/폭망)은 각 1%, 기본은 소폭 ±(평균 약간 +).
func _gambler_variance(p: Player) -> void:
	var r: float = randf()
	p.gamble_rolls += 1
	if r < 0.01:  # 🎰 초대박 (1%)
		p.card_add += 1.0
		p.proj_bonus += 1
		p.add_crit(0.12)
		p.gamble_add += 1.0
		p.gamble_proj += 1
		p.gamble_crit += 0.12
		p.gamble_last = "초대박"
		p.gamble_log.append("초대박")
		G.add_shake(0.8)
		G.sfx("levelup", 1.4)
		G.stat_add("jackpots", 1)  # 도전과제: 잭팟
		G.check_achievements()
		_wave_banner("초대박!! 능력 폭증", Color("ffd54a"))
	elif r < 0.02:  # 💀 폭망 (1%)
		p.card_add = maxf(0.0, p.card_add - 0.45)
		p.proj_bonus = maxi(0, p.proj_bonus - 1)
		p.gamble_add -= 0.45
		p.gamble_proj -= 1
		p.gamble_last = "폭망"
		p.gamble_log.append("폭망")
		G.add_shake(0.4)
		G.sfx("hurt", 0.6)
		_wave_banner("폭망… 능력 대폭 하락", Color("ff5a5a"))
	elif randf() < 0.62:  # 소폭 상승 (평균 약간 +로 기울임)
		match randi() % 3:
			0:
				p.card_add += 0.10
				p.gamble_add += 0.10
			1:
				p.cut_rate(0.94)
				p.gamble_rate *= 0.94
			2:
				p.add_crit(0.04)
				p.gamble_crit += 0.04
		p.gamble_last = "소폭 상승"
		p.gamble_log.append("소폭 상승")
		_wave_banner("도박: 소폭 상승", Color("9fe8ff"))
	else:  # 소폭 하락
		if randi() % 2 == 0:
			p.card_add = maxf(0.0, p.card_add - 0.06)
			p.gamble_add -= 0.06
		else:
			p.rate_mult = minf(3.0, p.rate_mult * 1.06)
			p.gamble_rate *= 1.06
		p.gamble_last = "소폭 하락"
		p.gamble_log.append("소폭 하락")
		_wave_banner("도박: 소폭 하락", Color("c0b0d0"))




func _spawn_chest() -> void:
	_chest_pending = true
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	var pos: Vector2 = (p as Node2D).global_position + Vector2(randf_range(-70.0, 70.0), -90.0)
	Pickup.spawn(self, pos, Pickup.CHEST)
	_wave_banner("보물상자 출현! (능력 만렙)", Color("ffd54a"))
	G.sfx("levelup", 0.9)


## 보물상자 획득 → 캐릭터 전용 진화(최초) 또는 강화(이후)
func _grant_signature() -> void:
	_chest_pending = false
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return
	if not _chest_used:
		_chest_used = true
		var nm: String = p.apply_signature(String(_last_char.get("id", "base")))
		_wave_banner(I18n.t("진화: %s") % nm, Color("ffd54a"))
	else:
		p.card_add += 0.15
		p.max_hp += 25.0
		p.hp = p.max_hp
		G.player_hp_changed.emit()
		_wave_banner("보물: 능력치 강화", Color("ffd54a"))
	G.add_shake(0.6)
	G.sfx("levelup", 1.2)


## 죽었지만 광고 부활이 가능한 상태. 패널을 띄우고 유저 선택을 기다린다.
## 여기서 나가는 길은 딱 둘 — _do_revive() 또는 _finish_death(). 반드시 하나는 불린다.
func _on_revive_offered() -> void:
	if _stage_done or _endless_done:
		_finish_death()
		return  # 이미 클리어 정산이 끝난 판
	if _revive_panel == null or not G.revive_available():
		_finish_death()
		return
	_revive_busy = false
	_revive_left = 10.0
	_update_revive_label()
	_set_revive_buttons(true)
	_revive_panel.visible = true
	_pad_focus.call_deferred(_revive_panel)


func _update_revive_label() -> void:
	if _revive_panel == null:
		return
	var lbl := _revive_panel.find_child("ReviveLabel", true, false) as Label
	if lbl == null:
		return
	if _revive_busy:
		lbl.text = "광고를 불러오는 중…"
		return
	var how: String = (
		I18n.t("체력을 모두 채우고 이어서 합니다.")
		if G.free_revive()
		else I18n.t("광고를 끝까지 보면 체력을 모두 채우고 이어서 합니다.")
	)
	lbl.text = I18n.t("생존 %02d:%02d · 처치 %d · 레벨 %d\n%s\n(판당 1회)\n\n%d초 뒤 자동으로 포기합니다") % [
		int(G.time_alive) / 60, int(G.time_alive) % 60, G.kills, G.level, how, int(ceil(_revive_left))
	]


func _set_revive_buttons(on: bool) -> void:
	if _revive_panel == null:
		return
	for n: String in ["ReviveWatch", "ReviveDecline"]:
		var b := _revive_panel.find_child(n, true, false) as Button
		if b != null:
			b.disabled = not on


func _on_revive_watch() -> void:
	if _revive_busy:
		return
	# 스팀·데스크톱: 볼 광고가 없다. 곧장 되살린다.
	if G.free_revive():
		_revive_left = 0.0
		_set_revive_buttons(false)
		_do_revive()
		return
	_revive_busy = true
	_revive_left = 0.0        # 카운트다운 정지 — 광고 도중에 자동 포기되면 안 된다
	_set_revive_buttons(false)
	_update_revive_label()
	Ads.show_revive_ad()


func _on_revive_decline() -> void:
	if _revive_busy:
		return
	_finish_death()


## 광고를 끝까지 봤다 → 부활
func _on_revive_reward() -> void:
	_do_revive()


## 광고가 어떤 식으로든 끝났다. 보상을 못 받았으면(=아직 pending) 그대로 죽는다.
## ★ 10/16 실기: 광고를 끝까지 봤는데 부활하지 않고 죽었다. 광고 SDK 는 「보상」과 「닫힘」을 서로 다른
##   스레드에서 부를 수 있어서 닫힘이 먼저 도착하면 보상 없이 닫힌 것으로 보고 죽였다(보상은 그 뒤에 와서 버려짐).
##   닫힘이 먼저 오면 REVIVE_REWARD_GRACE 초 동안 늦게 오는 보상을 기다린 뒤에 판단한다.
const REVIVE_REWARD_GRACE: float = 2.5
var _revive_wait_id: int = 0


func _on_revive_ad_finished() -> void:
	if not _revive_busy:
		return
	var p: Player = G.player as Player if is_instance_valid(G.player) else null
	if p == null or not p.pending_revive:
		_revive_busy = false
		return
	_revive_wait_id += 1
	var my_id: int = _revive_wait_id
	await get_tree().create_timer(REVIVE_REWARD_GRACE, true, false, true).timeout
	if my_id != _revive_wait_id or not _revive_busy:
		return   # 그사이 보상이 와서 되살렸다
	_revive_busy = false
	if is_instance_valid(p) and p.pending_revive:
		_finish_death()   # 중도 이탈·로드 실패 — 보상 없음


func _do_revive() -> void:
	if not is_instance_valid(G.player):
		return   # 죽은 뒤 영웅이 이미 지워졌다
	var p := G.player as Player
	if p == null or not p.pending_revive:
		return   # 이미 죽음 처리가 끝난 뒤의 늦은 보상 — 판을 살아 있는 것으로 되돌리지 않는다
	_revive_busy = false
	_revive_wait_id += 1   # 기다리던 「보상 없이 닫힘」 판단을 취소
	if _revive_panel != null:
		_revive_panel.visible = false
	p.revive()
	_run_active = true


func _finish_death() -> void:
	_revive_busy = false
	_revive_left = 0.0
	if _revive_panel != null:
		_revive_panel.visible = false
	var p := G.player as Player
	if p != null and is_instance_valid(p) and p.pending_revive:
		p.finish_death()


func _on_player_died() -> void:
	if _stage_done or _endless_done:
		return  # 이미 클리어 정산이 끝난 판 — 사후 사망은 무시 (승리 화면이 게임오버로 덮이던 것)
	# 승리 연출이 예약돼 있었으면 취소한다. 안 그러면 죽은 뒤에 클리어 정산이 한 번 더 돈다.
	_win_at_ms = 0
	_win_seq = false
	_win_paused = false
	_fusion_end_ms = 0
	_win_cb = Callable()
	G.set_slowmo(1.0)
	_run_active = false
	_fusion_boss = null
	_fusion_live = false
	if _fusion_root != null:
		_fusion_root.visible = false
	if _wboss_root != null:
		_wboss_root.visible = false
	if _gameover == null:
		return
	if _stage_done:
		return  # 스테이지 클리어 패널이 이미 떠 있으면 게임오버 처리 안 함
	_update_hud_scale()  # 스테일 크기 방어 (S3)
	var earned: int = G.run_gold
	G.bank_run_gold()
	G.run_ended()  # 도전과제 기록 갱신(생존시간/레벨/판수) + 저장
	var unlock_txt: String = ""
	for u in _collect_new_unlocks():
		unlock_txt += "\n" + String(u)
	var lbl := _gameover.find_child("GOLabel", true, false) as Label  # 패널 안에 중첩됨 → 재귀 탐색
	if lbl == null:
		_gameover.visible = true
		return
	lbl.text = _keep_items(I18n.t("획득 골드 %s  ·  총 %s") % [G.gold_str(earned), G.gold_str(G.total_gold)])
	UiFont.apply(lbl, 20)
	lbl.add_theme_color_override("font_color", UiParts.PAPER_D)
	_res_summary(_go_sum)
	_res_unlocks(_go_unl)
	_fill_dmg_table(_go_table)
	_go_ms = Time.get_ticks_msec()
	_gameover.visible = true
	_fit_result_panel(_go_panel)
	_pad_focus.call_deferred(_gameover)







































































## 화면 밖 보스를 화면 가장자리 화살표로 가리킨다.
## 2026-09-05: 융합 보스는 플레이어 머리 위 480px 에 뜨는데 화면 반높이가 360px 라
## **100% 화면 밖에서 시작한다.** 등장 배너가 사라지면 뭐가 어디서 오는지 알 방법이 없었다.
var _boss_arrows: Array = []
var _arrow_root: Control


func _update_boss_arrows() -> void:
	if _hud_layer == null or not G.running:
		for a in _boss_arrows:
			if is_instance_valid(a):
				(a as CanvasItem).visible = false
		return
	if _arrow_root == null:
		_arrow_root = Control.new()
		_arrow_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_arrow_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_arrow_root.z_index = 40
		_hud_layer.add_child(_arrow_root)
	var p := G.player as Node2D
	if p == null or not is_instance_valid(p):
		return
	# 화면 밖 보스만 모은다
	var off: Array = []
	var vp: Vector2 = get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var half: Vector2 = vp * 0.5 / (cam.zoom if cam != null else Vector2.ONE)
	var center: Vector2 = cam.get_screen_center_position() if cam != null else p.global_position
	for n in G.enemies_cached():
		# ★ 공유 캐시는 이번 프레임에 죽은 개체를 담는다. 유효성을 **캐스트보다 먼저**
		#   봐야 한다 — 해제된 것에 `as` 를 걸면 그 줄에서 터진다(--orbcheck 에서 발견).
		if not is_instance_valid(n):
			continue
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or not e._is_boss:
			continue
		var d: Vector2 = e.global_position - center
		if absf(d.x) <= half.x - 40.0 and absf(d.y) <= half.y - 40.0:
			continue                      # 화면 안이면 굳이 안 가리킨다
		off.append(d)
	while _boss_arrows.size() < off.size():
		var tri := Polygon2D.new()
		tri.polygon = PackedVector2Array([Vector2(0, -15), Vector2(11, 9), Vector2(-11, 9)])
		tri.color = Color(1.0, 0.32, 0.28, 0.92)
		_arrow_root.add_child(tri)
		_boss_arrows.append(tri)
	for i in _boss_arrows.size():
		var tri2 := _boss_arrows[i] as Polygon2D
		if not is_instance_valid(tri2):
			continue
		if i >= off.size():
			tri2.visible = false
			continue
		var d2: Vector2 = off[i]
		# 화면 가장자리 안쪽에 붙인다 — 방향만 알면 되므로 사각형 경계로 투영한다
		var m: float = maxf(absf(d2.x) / maxf(1.0, vp.x * 0.5 - 34.0),
							absf(d2.y) / maxf(1.0, vp.y * 0.5 - 34.0))
		tri2.position = vp * 0.5 + d2 / maxf(0.001, m)
		tri2.rotation = d2.angle() + PI * 0.5
		tri2.visible = true








## 헤드리스 검사 하니스가 인자를 가로채는 구멍. 파생 클래스 Main 이 덮어쓴다.
## 게임 코드는 하니스를 몰라야 하므로 여기서는 아무 일도 안 한다.
func _dev_dispatch(_uargs: PackedStringArray) -> bool:
	return false
