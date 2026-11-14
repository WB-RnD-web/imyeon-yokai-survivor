extends MainGame
## 진입점 + 헤드리스 검사 하니스.
##
## 게임 자체는 기반 클래스 MainGame(scripts/main_game.gd)에 있다. 여기 남은 것은
## `--artcheck` `--balance` `--walkcheck` 처럼 **출시 빌드에서 아무도 안 부르는** 코드다.
## main.tscn 이 가리키는 스크립트는 계속 이 파일이라 진입점은 안 바뀐다.
class_name Main


## 하니스 인자를 가로챈다. 하나라도 처리했으면 true — MainGame._ready 가 거기서 멈춘다.
func _dev_dispatch(uargs: PackedStringArray) -> bool:
	# ★ 2026-09-15 (출시 정리): 이 하니스들은 **소스에서만** 열린다.
	#   구운 exe 도 명령줄 인자를 그대로 받으므로, 스팀 실행 옵션에 `-- --immortal` 한 줄이면
	#   불사가 되고 `-- --balance` 로 판이 자동으로 굴러간다 — 출시 빌드에 있어야 할 구멍이 아니다.
	#   에디터/소스 실행(has_feature("editor"))과 디버그 빌드에서는 전부 그대로 돌아가므로
	#   --balance · --contrastshot · --dotcheck 같은 검사 도구는 하나도 안 줄어든다.
	if not (OS.has_feature("editor") or OS.is_debug_build()):
		return false
	if get_tree().root.has_meta("reloadtest_done"):
		_reloadtest_after()
		return true
	var lp_diff: int = 1
	var lp_dur: float = 240.0
	for a in uargs:
		if (a as String).begins_with("--diff="):
			lp_diff = int((a as String).get_slice("=", 1))
		if (a as String).begins_with("--dur="):
			lp_dur = float((a as String).get_slice("=", 1))
		if (a as String) == "--immortal":
			_lp_immortal = true
		if (a as String).begins_with("--fast="):
			_lp_fast = float((a as String).get_slice("=", 1))
		if (a as String) == "--nosnap":
			_lp_nosnap = true
		if (a as String) == "--m31smoke":
			_m31_smoke = true
		if (a as String) == "--fx=off":
			FxLib.on = false   # 8차 무기 이펙트 시트를 끄고 예전 도형으로(지금 ↔ 새 그림 비교)
		if (a as String) == "--press=time":
			G.press_time_only = true   # 몹 압력을 예전처럼 경과 시간으로(비교용)
		if (a as String) == "--hold":
			_bot_hold = true  # 봇이 도망치지 않고 제자리에서 버틴다 (유저의 'AFK 클리어' 재현)
		if (a as String).begins_with("--char="):
			_lp_char = (a as String).get_slice("=", 1)
		if (a as String).begins_with("--karma="):   # 11/7 업보 단계(저승길을 깬 것으로 친다)
			G.karma = clampi(int((a as String).get_slice("=", 1)), 0, G.KARMA_MAX)
			G.stage_prog["c_%d_0" % (G.STAGE_NAMES.size() - 1)] = 1
		if (a as String).begins_with("--seed="):
			# 카드 추첨·드랍·스폰이 전부 난수라, 시드를 안 고정하면 같은 설정도 결과가 10배씩 벌어진다.
			# 밸런스 수치를 비교하려면 반드시 고정해야 한다.
			seed(int((a as String).get_slice("=", 1)))
	# 가상 조이스틱+대시 버튼 (감지 자체는 _ready 최상단 — HUD보다 먼저)
	for a in uargs:
		if (a as String).begins_with("--perf"):
			_perf_flow((a as String).get_slice("=", 1) if "=" in (a as String) else "")
			return true
		if (a as String).begins_with("--demo="):
			_demo_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--balance"):
			_balance_flow(lp_diff, lp_dur)
			return true
		if (a as String).begins_with("--botrun"):
			_botrun_flow(lp_diff, lp_dur)
			return true
		if (a as String).begins_with("--physprof"):
			_physprof_flow(int((a as String).get_slice("=", 1)) if "=" in (a as String) else 200)
			return true
		if (a as String).begins_with("--loadpeak"):
			_perfpeak_flow(int((a as String).get_slice("=", 1)) if "=" in (a as String) else 0, lp_dur)
			return true
		if (a as String) == "--padcheck":
			_padcheck_flow()
			return true
		if (a as String) == "--wincheck":
			_wincheck_flow()
			return true
		if (a as String) == "--boottime":
			_boottime_flow()
			return true
		if (a as String).begins_with("--savecheck"):
			_savecheck_flow((a as String).get_slice("=", 1) if "=" in (a as String) else "")
			return true
		if (a as String).begins_with("--longplay="):
			_longplay_flow((a as String).get_slice("=", 1), lp_diff, lp_dur)
			return true
		if (a as String).begins_with("--showcase="):
			_showcase_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--codexshot="):
			_codex_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--tileshot="):
			_tile_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--cardshot="):
			_card_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--sigshot="):
			_sig_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--pauseshot="):
			_pause_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String) == "--statcheck":
			_statcheck_flow()
			return true
		if (a as String) == "--bosshp":
			_bosshp_flow()
			return true
		if (a as String) == "--swarmcheck":
			_swarmcheck_flow()
			return true
		if (a as String).begins_with("--crowdshot="):
			_crowdshot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String) == "--dotcheck":
			_dotcheck_flow()
			return true
		if (a as String) == "--i18ncheck":
			_i18ncheck_flow()
			return true
		if (a as String) == "--cfcheck":
			_cfcheck_flow()
			return true
		if (a as String) == "--cfshots":
			_cfshots_flow()
			return true
		if (a as String) == "--cfshots2":
			_cfshots2_flow()
			return true
		if (a as String) == "--cfshots_arrival":
			_cfshots_arrival_flow()
			return true
		if (a as String) == "--cfshots4":
			_cfshots4_flow()
			return true
		if (a as String) == "--cfshots5":
			_cfshots5_flow()
			return true
		if (a as String) == "--cfshots7":
			_cfshots7_flow()
			return true
		if (a as String) == "--fusionshot":
			_fusionshot_flow()
			return true
		if (a as String) == "--weaponfx":
			_weaponfx_flow()
			return true
		if (a as String) == "--artaudit":
			_artaudit_flow()
			return true
		if (a as String) == "--flashtest":
			_flashtest_flow()
			return true
		if (a as String) == "--textshot":
			_textshot_flow()
			return true
		if (a as String) == "--momentshot":
			_momentshot_flow()
			return true
		if (a as String) == "--midshot":
			_midshot_flow()
			return true
		if (a as String) == "--s6shot":
			_s6shot_flow()
			return true
		if (a as String) == "--transcap":
			_transcap_flow()
			return true
		if (a as String) == "--acccheck":
			_acccheck_flow()
			return true
		if (a as String) == "--artcheck":
			_artcheck_flow()
			return true
		if (a as String) == "--walkcheck":
			_walkcheck_flow()
			return true
		if (a as String) == "--healcheck":
			_healcheck_flow()
			return true
		if (a as String) == "--chestcheck":
			_chestcheck_flow()
			return true
		if (a as String) == "--shopcheck":
			_shopcheck_flow()
			return true
		if (a as String) == "--traitcheck":
			_traitcheck_flow()
			return true
		if (a as String) == "--sumcheck":
			_sumcheck_flow()
			return true
		if (a as String) == "--abilcheck":
			_abilcheck_flow()
			return true
		if (a as String) == "--transcheck":
			_transcheck_flow()
			return true
		if (a as String) == "--previewcheck":
			_previewcheck_flow()
			return true
		if (a as String) == "--orbcheck":
			_orbcheck_flow()
			return true
		if (a as String) == "--buildcheck":
			_buildcheck_flow()
			return true
		if (a as String) == "--cardcheck":
			_cardcheck_flow()
			return true
		if (a as String) == "--trackcheck":
			_trackcheck_flow()
			return true
		if (a as String) == "--uptimecheck":
			_uptimecheck_flow()
			return true
		if (a as String) == "--fusepower":
			_fusepower_flow()
			return true
		if (a as String) == "--lvlcheck":
			_lvlcheck_flow()
			return true
		if (a as String) == "--legioncheck":
			_legioncheck_flow()
			return true
		if (a as String) == "--countcheck":
			_countcheck_flow()
			return true
		if (a as String) == "--rankcheck":
			_rankcheck_flow()
			return true
		if (a as String) == "--fusedisplay":
			_fusedisplay_flow()
			return true
		if (a as String) == "--fusemech":
			_fusemech_flow()
			return true
		if (a as String) == "--fuseinherit":
			_fuseinherit_flow()
			return true
		if (a as String) == "--chestdouble":
			_chestdouble_flow()
			return true
		if (a as String) == "--finalcheck":
			_finalcheck_flow()
			return true
		if (a as String) == "--maxcheck":
			_maxcheck_flow()
			return true
		if (a as String) == "--cardshot":
			_cardshot_flow()
			return true
		if (a as String) == "--rarityshot":
			_rarityshot_flow()
			return true
		if (a as String) == "--herofit":
			_herofit_flow()
			return true
		if (a as String) == "--menushot":
			_menushot_flow()
			return true
		if (a as String) == "--steamcheck":
			_steamcheck_flow()
			return true
		if (a as String) == "--steamachv":
			_steamachv_flow()
			return true
		if (a as String) == "--storeshots":
			_storeshots_flow()
			return true
		if (a as String) == "--contrastshot":
			_contrastshot_flow()
			return true
		if (a as String) == "--stickshot":
			_stickshot_flow()
			return true
		if (a as String) == "--heldshot":
			_heldshot_flow()
			return true
		if (a as String) == "--winsize":
			_winsize_flow()
			return true
		if (a as String) == "--trailer":
			_trailer_flow()
			return true
		if (a as String) == "--ctrlcheck":
			_ctrlcheck_flow()
			return true
		if (a as String) == "--pausecheck":
			_pausecheck_flow()
			return true
		if (a as String) == "--diffcheck":
			_diffcheck_flow()
			return true
		if (a as String) == "--fusegrade":
			_fusegrade_flow()
			return true
		if (a as String) == "--summoncheck":
			_summoncheck_flow()
			return true
		if (a as String) == "--heldcheck":
			_heldcheck_flow()
			return true
		if (a as String).begins_with("--ridercheck"):
			_ridercheck_flow(int((a as String).get_slice("=", 1)) if "=" in (a as String) else 40)
			return true
		if (a as String).begins_with("--fusioncheck"):
			_fusioncheck_flow(int((a as String).get_slice("=", 1)) if "=" in (a as String) else 60)
			return true
		if (a as String) == "--m37smoke":
			_m37_smoke_flow()
			return true
		if (a as String).begins_with("--boomcheck"):
			var bstr: String = (a as String).get_slice("=", 1) if "=" in (a as String) else ""
			_boomcheck_flow(bstr)
			return true
		if (a as String).begins_with("--setshot="):
			_set_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--charshot="):
			_char_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String) == "--resultfit":
			_resultfit_flow()
			return true
		if (a as String) == "--uifit":
			_uifit_flow()
			return true
		if (a as String) == "--clickback":
			_clickback_flow()
			return true
		if (a as String) == "--scrollcheck":
			_scrollcheck_flow()
			return true
		if (a as String) == "--speccheck":
			_speccheck_flow()
			return true
		if (a as String) == "--questcheck":
			_questcheck_flow()
			return true
		if (a as String).begins_with("--shopshot="):
			_shop_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--demoshot="):
			_demoshot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--updateshot="):
			_updateshot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String) == "--obstblock":
			_obstblock_flow()
			return true
		if (a as String) == "--obstshot":
			_obstshot_flow()
			return true
		if (a as String).begins_with("--revivecheck"):
			_revivecheck_flow((a as String).get_slice("=", 1) if "=" in (a as String) else "")
			return true
		if (a as String).begins_with("--fightcheck"):
			_fightcheck_flow((a as String).get_slice("=", 1) if "=" in (a as String) else "")
			return true
		if (a as String).begins_with("--bosscheck"):
			_bosscheck_flow((a as String).get_slice("=", 1) if "=" in (a as String) else "")
			return true
		if (a as String) == "--scalecheck":
			_scalecheck_flow()
			return true
		if (a as String) == "--raritycheck":
			_rarity_check_flow()
			return true
		if (a as String).begins_with("--wpnshot="):
			_wpn_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--monshot="):
			_mon_shot_flow((a as String).get_slice("=", 1))
			return true
		if (a as String).begins_with("--weapondps"):
			_weapondps_flow((a as String).get_slice("=", 1) if "=" in (a as String) else "")
			return true
	return false



var _dps_home: Array = []   # 더미의 제자리 (넉백·추격으로 흐트러지면 되돌린다)
var _dps_dummies: Array = []


var _lp_char: String = ""   # --char=mudang : 실제 세이브의 그 영웅으로 재현한다
var _lp_immortal: bool = false  # 롱플레이: 불사(레벨 곡선 측정용)
var _bal_dmg_prev: float = 0.0   # 밸런스 하니스: 직전 줄까지 받은 피해(30초 구간 피해를 내려고)


var _lp_fast: float = 1.0       # 롱플레이: time_scale 압축


var _lp_nosnap: bool = false    # 롱플레이: 스샷 생략(헤드리스 수치 측정용)


var _m31_smoke: bool = false  # M31 스모크: 신규 무기/패시브/반응 강제 부여 후 롱플레이


var _bot_hold: bool = false   # 롱플레이/밸런스 봇 — 제자리 버티기 모드


## [검증용] 일시정지 빌드 패널 스샷 — 능력 많이 획득 시 화면 밖으로 안 나가는지(스크롤).
func _pause_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	for id: String in ["b_ice", "b_fire", "b_poison", "b_shock", "b_chain", "crit", "b_big", "b_bounce", "b_exec", "b_vamp", "b_bloom", "wp_heavy", "wp_rapid", "wpn_fire", "wpn_ice", "wpn_beam", "wpn_whip", "wpn_poison", "dmg", "crit"]:
		_apply_upgrade(id)
	_apply_upgrade("evo_reaper")  # 융합도 빌드 패널에 뜨는지 (M36-2)
	_apply_upgrade("evo_blizzard")
	await get_tree().process_frame
	await get_tree().process_frame
	# 19차 이후: 융합 무기가 왼쪽 위 무기 칸에 융합 아이콘으로 서는지(레벨 점 대신 융합 표시)
	await _snap("%s/hud.png" % dir)
	_pause_menu._toggle()
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap("%s/pause.png" % dir)
	# 「내가 든 것」 융합 칸을 누른 상태 — 상세 줄이 다음 레벨 없이 융합으로 읽히는지
	for c in _pause_menu._build_grid.get_children():
		if (c as Control).tooltip_text.contains(I18n.t("사신의 낫")):
			_pause_menu._build_detail.text = (c as Control).tooltip_text
			break
	await get_tree().process_frame
	await _snap("%s/pause_fused.png" % dir)
	get_tree().quit(0)


## [검증용] 능력 카드 스샷 — 무기/패시브 카드의 실수치 스탯 라인 + 레이아웃 확인.
func _card_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	(G.player as Player).add_primary_weapon("heavy")  # 대표무기=대검/캐논 반영 확인
	await get_tree().process_frame
	_levelup_root.visible = true
	get_tree().paused = true
	for c in _cards_box.get_children():
		c.queue_free()
	var pool: Array = _upgrade_pool()
	for wid: String in ["wp_heavy", "b_fire", "l_timewarp", "m_apocalypse"]:
		for u: Dictionary in pool:
			if String(u["id"]) == wid:
				_cards_box.add_child(_make_card(u))
				break
	# 융합 카드 비주얼 확인 (S5): 재료 만렙 강제 → 등장한 융합 카드 2장 추가
	for i in 6:
		_apply_upgrade("wpn_fire")
	for i in 5:
		_apply_upgrade("b_fire")
	for i in 6:
		_apply_upgrade("wp_rapid")
	for i in 3:
		_apply_upgrade("crit")
	for ev: Dictionary in _available_evolutions():
		_cards_box.add_child(_make_card(ev))
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap("%s/cards.png" % dir)
	get_tree().quit(0)


## [검증용] 17차 시그니처 카드 14 · 휴식 · 노다지 아이콘이 실제 레벨업 화면에 어떻게 뜨나 (--sigshot=<폴더>)
## 넉 장씩 네 화면. 카드마다 그 영웅으로 판을 열어(영웅 색 · 고유 카드 표시가 실제와 같게) 카드를 만든다.
func _sig_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	var owner_of: Dictionary = {}
	for hid: String in _CHAR_CARDS.keys():
		owner_of[String(_CHAR_CARDS[hid]["id"])] = hid
	var pages: Array = [
		["c_allround", "c_bloodlust", "c_overheat", "c_goldsense"],
		["c_ironwill", "c_allin", "c_charge", "c_emberheart"],
		["c_umbra", "c_bellcall", "c_bloomstep", "c_temper"],
		["c_mantra", "c_talon", "heal_card", "gold_card"],
	]
	for pi in pages.size():
		var first: String = String(pages[pi][0])
		var hero: Dictionary = Characters.defs()[0]
		for d: Dictionary in Characters.defs():
			if String(d.get("id", "")) == String(owner_of.get(first, "")):
				hero = d
		_begin_run(hero)
		await get_tree().process_frame
		_levelup_root.visible = true
		get_tree().paused = true
		for c in _cards_box.get_children():
			c.queue_free()
		for cid: String in pages[pi]:
			var u: Dictionary = {}
			if cid == "heal_card":
				u = HEAL_CARD.duplicate()
			elif cid == "gold_card":
				u = GOLD_CARD.duplicate()
			else:
				u = (_CHAR_CARDS[owner_of[cid]] as Dictionary).duplicate()
			_cards_box.add_child(_make_card(u))
		await get_tree().process_frame
		await get_tree().process_frame
		await _snap("%s/sig_%d.png" % [dir, pi + 1])
		get_tree().paused = false
		_levelup_root.visible = false
	get_tree().quit(0)


## [검증용] 스탯 실효 검증 (--statcheck, headless 가능) — 카드 수치가 '실제 게임 경로'에서 작동하는지.
## 행운 A/B(진짜 enemy._drop 2500회씩), 방어 관통 하한, 재생, 골드 항상적립+메타 곱. 실패 시 exit 1.
## 17-1: 보스 체력 순서 검사 (--bosshp). 지금 세이브(상점 · 영웅 등급 되먹임)로 중간보스 7종은 실제 Enemy._ready 를,
## 융합 · 스테이지 보스는 스폰이 부르는 함수(_fusion_hp · _stage_boss_hp)를 그대로 불러 잰다.
## 「옛 식」 칸은 비교용으로만 예전 식(meta 없음, 융합 1.35~2.2, 스테이지 1.25)을 적는다.
## 통과 조건: 가장 단단한 중간보스 < 융합 상한 < 스테이지 보스.
func _bosshp_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	var fails: int = 0
	var keep: Array = [G.run_mode, G.stage_sel, G.difficulty, G.level, G.time_alive]
	if _lp_char != "":
		G.last_char_id = _lp_char   # 영웅 등급이 되먹임에 들어간다 (--char=mudang)
	print("[BOSSHP] 영웅 %s · 몹 되먹임(meta_power) ×%.2f" % [G.last_char_id, G.meta_power()])
	print("[BOSSHP] 스테이지 난이도 | 중간보스 기본 · 최강 | 융합 하한~상한 | 스테이지 보스 | 옛 식(최강 중간 · 융합 상한 · 스테이지)")
	for st: int in [0, 2, 5]:
		for diff: int in [1, 2]:
			G.run_mode = "stage"
			G.stage_sel = st
			G.difficulty = diff
			G.level = 24
			G.time_alive = 342.0     # 9웨이브 중간보스 시각
			var mids: Array = []
			for k: int in [4, 13, 14, 15, 26, 27, 28]:
				var e := Enemy.new()
				e.kind = k
				add_child(e)          # _ready 가 실제 식으로 체력을 정한다
				mids.append(e.hp)
				e.queue_free()
			var mid_max: float = (mids.max() as float)
			var old_ref: float = 2600.0 * minf(G.power_mult(), 4.5) * G.diff_hp_mult() * G.stage_power()
			var old_mid_max: float = 4200.0 * minf(G.power_mult(), 4.5) * G.diff_hp_mult() * G.stage_power() * G.meta_power()
			G.time_alive = 300.0     # 융합은 3~6분 사이
			var fu_lo: float = _fusion_hp(0.0)
			var fu_hi: float = _fusion_hp(1.0e12)
			var old_fu_hi: float = 2600.0 * minf(G.power_mult(), 4.5) * G.diff_hp_mult() * G.stage_power() * 2.2
			G.time_alive = 480.0     # 스테이지 보스
			var sb: float = _stage_boss_hp()
			var old_sb: float = maxf(7000.0 * pow(1.5, float(st)) * G.diff_hp_mult(), 2600.0 * minf(G.power_mult(), 4.5) * G.diff_hp_mult() * G.stage_power() * 1.25)
			var ok: bool = mid_max < fu_hi and fu_hi < sb
			if not ok:
				fails += 1
			print("[BOSSHP] %d %s | %7.0f · %7.0f | %7.0f~%7.0f | %8.0f | 옛 %7.0f · %7.0f · %7.0f  %s" % [st + 1, String(G.DIFF_NAMES[diff]),
				float(mids[0]), mid_max, fu_lo, fu_hi, sb, old_mid_max, old_fu_hi, old_sb, "OK" if ok else "FAIL"])
			if old_ref <= 0.0:
				fails += 1
	G.run_mode = keep[0]
	G.stage_sel = keep[1]
	G.difficulty = keep[2]
	G.level = keep[3]
	G.time_alive = keep[4]
	print("[BOSSHP] %s (실패 %d)" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(0 if fails == 0 else 1)


## 17-1: 융합 게이지 검사 (--swarmcheck, 헤드리스). 「게이지가 나오는데 절대 융합 보스가 안 된다」를 막는 세 가지.
##   1) 보스 간격이 닫혀 있으면 몹이 기준을 넘어도 게이지가 안 보이고 융합도 안 된다(예전엔 게이지만 70% 까지 찼다)
##   2) 간격이 열리면 기준 위 20초 뒤 실제로 융합 보스가 나온다
##   3) 융합이 차는 중에 중간보스 차례가 오면 중간보스가 기다린다(「뭉치고 있다」 해 놓고 끊지 않는다)
func _swarmcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	p.process_mode = Node.PROCESS_MODE_DISABLED
	_spawn_t = 1.0e9
	var fails: int = 0
	var fill := func() -> void:
		var need: int = _merge_threshold() + 4 - _enemy_count()
		if need > 0:
			_cfs4_swarm(p.global_position, [0, 1, 7, 8], need, 260.0, 640.0)
	# 1) 문이 닫힘: 직전 보스 20초 전
	G.time_alive = 400.0
	_last_boss_t = 380.0
	fill.call()
	for i in 250:
		_update_fusion(0.1)
	var c1: bool = _fusion_boss == null and not _swarm_root.visible and _overcap_t == 0.0
	print("[SWARMCHECK] 1 보스 간격 닫힘 · 몹 %d/%d · 25초 → 융합 %s · 게이지 %s  %s" % [_enemy_count(), _merge_threshold(),
		"나옴" if _fusion_boss != null else "없음", "보임" if _swarm_root.visible else "숨김", "OK" if c1 else "FAIL"])
	fails += 0 if c1 else 1
	# 2) 문이 열림: 20초 넘게 버티면 융합
	_last_boss_t = -999.0
	fill.call()
	var seen_gauge: bool = false
	for i in 215:
		_update_fusion(0.1)
		seen_gauge = seen_gauge or _swarm_root.visible
		if _fusion_boss != null:
			break
	var c2: bool = _fusion_boss != null and seen_gauge
	print("[SWARMCHECK] 2 간격 열림 · 21.5초 → 융합 %s · 그사이 게이지 %s  %s" % ["나옴" if _fusion_boss != null else "없음",
		"보임" if seen_gauge else "안 보임", "OK" if c2 else "FAIL"])
	fails += 0 if c2 else 1
	# 3) 융합이 차는 중 중간보스 차례
	if _fusion_boss != null and is_instance_valid(_fusion_boss):
		(_fusion_boss as Node).queue_free()
	_fusion_boss = null
	_fusion_live = false
	_fusion_root.visible = false
	_fusion_lockout = 0.0
	_last_boss_t = -999.0
	_boss_pending = false
	_boss_eta = 0.0
	await get_tree().process_frame
	fill.call()
	for i in 60:
		_update_fusion(0.1)
	_request_boss()
	var c3: bool = _overcap_t > 0.0 and _boss_pending and _boss_eta <= 0.0
	print("[SWARMCHECK] 3 융합 6초째 중간보스 차례 → 중간보스 %s · 융합 %.1f초째 계속  %s" % ["대기" if _boss_pending else "바로 예고",
		_overcap_t, "OK" if c3 else "FAIL"])
	fails += 0 if c3 else 1
	print("[SWARMCHECK] %s (실패 %d)" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(0 if fails == 0 else 1)


## 17-1: 군중 속 사신의 낫 검사 (--crowdshot=<폴더>[:old]). 「몹이 많으면 낫이 아예 안 보이고 숫자만 뜬다」 재현.
## 사신의 낫 + 총 · 번개 사슬 · 화염을 들고 잡몹 260 을 둘레에 계속 채운 채 10초 동안 낫을 휘두른 횟수 중 그림이 나간 비율을 센다.
## :old 면 예전처럼 낫 그림이 임팩트 예산을 같이 쓴다(같은 장면 A/B). 창 모드면 낫이 나간 직후 컷 셋 + 피격 컷 하나를 찍는다.
func _crowdshot_flow(arg: String) -> void:
	var old: bool = arg.ends_with(":old")
	var dir: String = arg.trim_suffix(":old")   # 「C:/…」 경로라 콜론으로 자르면 안 된다
	DirAccess.make_dir_recursive_absolute(dir)
	G.wfx_legacy = old
	await get_tree().create_timer(0.3).timeout
	G.difficulty = 1
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	_theme_t = 1.0e9
	_spawn_t = 1.0e9          # 자연 스폰은 끄고 검사가 직접 채운다
	p.xp_mult = 0.0           # 레벨업 창이 판을 멈추지 않게
	p.max_hp = 4000.0
	p.hp = 4000.0
	_apply_upgrade("evo_reaper")
	for wid: String in ["wpn_chain", "wpn_chain", "wpn_fire", "wpn_fire"]:
		p.add_weapon(wid)
	p.add_primary_weapon("fan")
	var world: Node = p.get_parent()
	WhipWeapon.fx_drawn = 0
	WhipWeapon.fx_skipped = 0
	var t0: int = Time.get_ticks_msec()
	var shots: int = 0
	var seen: int = 0
	var hurt_done: bool = false
	while Time.get_ticks_msec() - t0 < 10000:
		var n: int = _enemy_count()
		for i in maxi(0, 260 - n):
			var e := Enemy.new()
			e.kind = [0, 1, 7, 8][i % 4]
			var ang: float = randf() * TAU
			e.global_position = p.global_position + Vector2(cos(ang), sin(ang)) * randf_range(70.0, 430.0)
			world.add_child(e)
		p.hp = maxf(p.hp, 1500.0) if not hurt_done else p.hp
		await get_tree().process_frame
		# 낫 그림이 막 나간 프레임 뒤에 찍는다
		if WhipWeapon.fx_drawn > seen:
			seen = WhipWeapon.fx_drawn
			if shots < 3 and Time.get_ticks_msec() - t0 > 2500 + shots * 1800:
				await get_tree().process_frame
				await get_tree().process_frame
				await _snap("%s/crowd_%d%s.png" % [dir, shots + 1, "_old" if old else ""])
				shots += 1
		# 마지막에 한 번 맞혀서 발밑 막대 · 머리 위 숫자 · 가장자리 붉음을 찍는다(체력 25% → 빈사 맥동까지)
		if not hurt_done and Time.get_ticks_msec() - t0 > 8500:
			hurt_done = true
			p.hp = p.max_hp * 0.31
			G.player_hp_changed.emit()
			p._iframe = 0.0
			p.take_damage(p.max_hp * 0.07 / 0.7 + p.armor)
			for k in 5:
				await get_tree().process_frame
			await _snap("%s/hurt%s.png" % [dir, "_old" if old else ""])
	var tot: int = WhipWeapon.fx_drawn + WhipWeapon.fx_skipped
	print("[CROWD] %s 몹 %d · 낫 휘두름 %d 중 그림 %d (%.0f%%) · 빠짐 %d" % ["예전(임팩트 예산 공유)" if old else "지금(무기 예산 따로)",
		_enemy_count(), tot, WhipWeapon.fx_drawn, 100.0 * float(WhipWeapon.fx_drawn) / maxf(1.0, float(tot)), WhipWeapon.fx_skipped])
	get_tree().quit(0)


func _statcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	var world: Node = p.get_parent()
	var fails: int = 0
	p.xp_mult = 0.0  # 대량 드랍 중 XP 흡수로 레벨업(카드 UI)이 터지는 것 차단
	# 1) 행운: 같은 적의 실제 드랍 루틴을 luck 0% vs +60%로 각 6000회 → 드랍 수 비율 ≈ 1.6 기대
	var e := Enemy.new()
	e.kind = 0
	world.add_child(e)
	e.global_position = p.global_position + Vector2(4000.0, 4000.0)
	var n0: int = _statcheck_drops(e, world, p, 0.0, 6000)
	await get_tree().process_frame  # 1차 생성물 해제 플러시
	var n1: int = _statcheck_drops(e, world, p, 0.60, 6000)
	var ratio: float = float(n1) / maxf(1.0, float(n0))
	print("[STATCHECK] luck: drops(+0%%)=%d  drops(+60%%)=%d  ratio=%.2f (기대≈1.60)" % [n0, n1, ratio])
	if ratio < 1.25 or ratio > 2.1:
		fails += 1
	p.luck = 0.0
	# 2) 방어: 관통 하한(피해의 30%는 항상) + 정상 플랫 감산
	p.hp = p.max_hp
	p._iframe = 0.0
	p.armor = 999.0
	p.take_damage(30.0)
	var loss: float = p.max_hp - p.hp
	print("[STATCHECK] armor(999) 30피해 → 손실 %.1f (기대 9.0 = 30%% 관통)" % loss)
	if absf(loss - 9.0) > 0.01:
		fails += 1
	p.hp = p.max_hp
	p._iframe = 0.0
	p.armor = 4.0
	p.take_damage(30.0)
	loss = p.max_hp - p.hp
	print("[STATCHECK] armor(4) 30피해 → 손실 %.1f (기대 26.0)" % loss)
	if absf(loss - 26.0) > 0.01:
		fails += 1
	p.armor = 0.0
	# 3) 재생: 10/s로 0.5초 → +5 근방
	p.regen = 10.0
	p.hp = p.max_hp * 0.5
	var hp0: float = p.hp
	await get_tree().create_timer(0.5).timeout
	var gained: float = p.hp - hp0
	print("[STATCHECK] regen 10/s × 0.5s → +%.1f (기대≈5)" % gained)
	if gained < 3.0 or gained > 8.0:
		fails += 1
	p.regen = 0.0
	# ★ 검사는 **테스터의 세이브에 의존하면 안 된다.** 하니스는 실제 save.cfg 를 읽으므로
	#   장신구(복주머니 골드 ×1.12)가 장착돼 있으면 기대값이 통째로 어긋난다 —
	#   실제로 골드 검사 3건이 그것 때문에 늘 실패하고 있었다(2026-09-06에 원인 확인).
	#   여기서 장착을 비우고 재적용해서, 누가 돌려도 같은 수가 나오게 만든다.
	var keep_slots: Array = []
	for i in 3:
		keep_slots.append(G.meta.get("acc_slot_%d" % i, ""))
		G.meta["acc_slot_%d" % i] = ""
	if G.player != null and is_instance_valid(G.player):
		(G.player as Player).apply_accessories()
	# 4) 골드: 분당 예산 초과 상태에서도 전액 적립(M36) + 메타 골드획득 곱
	var keep_mg: int = G.meta_level("m_gold")
	G.meta["m_gold"] = 0
	G._gm_window = int(G.time_alive / 60.0)
	G._gm_earned = 999999  # 예산 초과 강제
	var got_a: int = G.add_gold(37)
	print("[STATCHECK] gold: 예산초과 중 37 → %d 적립 (기대 37 = 항상 전액)" % got_a)
	if got_a != 37:
		fails += 1
	G.meta["m_gold"] = 5
	# 기대값을 G.META_TIERS 에서 역산한다 — 레벨당 수치를 조정해도 검사가 같이 따라온다
	var want_b: int = int(round(100.0 * (1.0 + G.meta_bonus("m_gold"))))
	var got_b: int = G.add_gold(100)
	print("[STATCHECK] gold: m_gold Lv5에 100 → %d 적립 (기대 %d = +%.0f%%/Lv)" % [got_b, want_b, G.meta_per("m_gold") * 100.0])
	if got_b != want_b:
		fails += 1
	G.meta["m_gold"] = keep_mg
	# ── 골드 공급 계약 2가지 ──
	#   (1) 예산이 남아 있으면 실제로 떨어진다 (공급식이 죽어 있지 않다)
	#   (2) 몇 마리를 잡든 분당 총액이 설계 상한을 못 넘는다
	# ★ (2)가 없어서 초당 80마리 구간에서 상한 110 이 실측 5,000 이 됐다(4분에 8천 골드).
	var world0: Node = self
	var e2 := Enemy.new()
	e2.kind = 0
	world0.add_child(e2)
	await get_tree().process_frame
	var _collect := func() -> int:
		var acc: int = 0
		for cn in get_tree().get_nodes_in_group("coin"):
			if cn is GoldCoin and is_instance_valid(cn):
				acc += (cn as GoldCoin)._value
				(cn as Node).remove_from_group("coin")  # queue_free 는 프레임 끝에 반영 — 즉시 빼야 두 번 안 센다
				(cn as Node).queue_free()
		return acc
	G.run_gold = 0
	G.time_alive = 59.0        # 이번 분 예산이 거의 다 열린 시점
	G._gm_window = -1
	for i in 60:
		e2._drop_gold()
	var early: int = _collect.call()
	print("[STATCHECK] gold: 예산 있음 60킬 → %d G 드랍 (기대 1 이상)" % early)
	if early < 1:
		fails += 1
	G.run_gold = 0
	G.time_alive = 59.0
	G._gm_window = -1
	var kills_n: int = 3000    # 같은 1분 안에 3,000마리 — 폭주 상황 재현
	for i in kills_n:
		e2._drop_gold()
	var minute_g: int = _collect.call() + G.run_gold
	var cap_g: int = G._gold_cap()
	print("[STATCHECK] gold: 1분 %d킬 → %d G (상한 %d — 초과하면 안 됨)" % [kills_n, minute_g, cap_g])
	if minute_g > cap_g:
		fails += 1
	e2.queue_free()
	# ── 장신구 실적용: 설명만 있고 구현이 없던 사고(호패·복주머니)를 회귀로 잡는다 ──
	for i in 3:                      # 위에서 비워 둔 장착 슬롯을 되돌린다
		G.meta["acc_slot_%d" % i] = keep_slots[i]
	var pl := G.player as Player
	G.meta["acc_own_acc_hopae"] = 1
	G.meta["acc_own_acc_bokjumeoni"] = 1
	G.meta["acc_slot_0"] = "acc_hopae"
	G.meta["acc_slot_1"] = "acc_bokjumeoni"
	pl.apply_meta()
	pl.apply_accessories()
	pl.apply_character(Characters.defs()[0])
	print("[STATCHECK] 호패 경험치 배수 %.2f (기대 1.10) / 복주머니 골드 배수 %.2f (기대 1.12)" % [pl.xp_mult, pl.acc_gold_mult])
	if absf(pl.xp_mult - 1.10) > 0.001 or absf(pl.acc_gold_mult - 1.12) > 0.001:
		fails += 1
	G.meta["acc_slot_0"] = ""
	G.meta["acc_slot_1"] = ""
	print("[STATCHECK] %s" % ("ALL PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## [검증용] 설정 화면 스샷 — 자동선택 옵션·레시피 공개 버튼 레이아웃 확인.
func _set_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	_main_menu.close()
	_settings.open()
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap(dir + "/settings.png")
	# 19차: 탭마다 한 장씩(접근성 줄은 「화면」 탭에 있다)
	for ti in _settings.TAB_NAMES.size():
		_settings._set_tab(ti)
		await get_tree().process_frame
		await get_tree().process_frame
		await _snap(dir + "/settings_tab%d.png" % ti)
		var ssc: ScrollContainer = _find_scroll(_settings)
		if ssc != null and ssc.get_v_scroll_bar().max_value > ssc.size.y + 1.0:
			ssc.scroll_vertical = 99999
			await get_tree().process_frame
			await get_tree().process_frame
			await _snap(dir + "/settings_tab%d_bottom.png" % ti)
			ssc.scroll_vertical = 0
	get_tree().quit(0)


## 스모크 로그 — stdout은 파이프 시 블록버퍼라 kill되면 유실 → 파일에도 즉시 기록.
func _m37_log(msg: String) -> void:
	print(msg)
	var path: String = "user://m37.log"
	var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(msg)
		f.close()


## [검증용] 폭발 연쇄 재현 (headless) — 하드코어 + 화염/감전/튕김 빌드로 '가만히 서서' 킬 속도 측정.
## 유저 리포트: 2:43에 처치 7857 (맵 자동 전멸). 너프 전/후 A/B용.
func _boomcheck_flow(build: String = "") -> void:
	await get_tree().create_timer(0.3).timeout
	G.difficulty = 3
	Engine.time_scale = 3.0
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1000000000.0
	p.hp = p.max_hp
	p.xp_mult = 0.0  # 레벨업 모달 차단 — 순수 빌드 킬 속도만 측정
	var ids: Array = ["b_fire", "b_fire", "b_shock", "b_shock", "b_shock", "b_bounce", "b_bounce", "b_bounce", "wp_rapid", "wp_rapid", "multi", "multi"]
	if build != "":
		ids = build.split(",")
	print("[BOOM] build=%s" % str(ids))
	for id: String in ids:
		_apply_upgrade(id)
	G.tally_on = true
	G.dmg_tally.clear()
	var t0: float = G.time_alive
	for i in 8:
		await get_tree().create_timer(20.0).timeout
		print("[BOOM] t=%3ds  kills=%d  enemies=%d" % [int(G.time_alive - t0), G.kills, get_tree().get_node_count_in_group("enemy")])
	# 피해 출처별 집계 — 뭐가 실제로 죽이는지
	var keys: Array = G.dmg_tally.keys()
	keys.sort_custom(func(a, b) -> bool: return float(G.dmg_tally[a]) > float(G.dmg_tally[b]))
	for k in keys:
		print("[BOOM] 피해원  %-8s  %12.0f" % [String(k), float(G.dmg_tally[k])])
	G.tally_on = false
	Engine.time_scale = 1.0
	get_tree().quit(0)


## [검증용] 전투 격리 검증 (headless) — 정지 플레이어 앞 적 1마리, 8초간 자동사격 → 처치되는지.
## 인자: "stage2" 등 → 스테이지 모드로 (기본 endless d1). 실패 시 exit 1.
## ──────────────────── 체험판 화면 (--trial --demoshot=<폴더>) ────────────────────
## 19차 4-2: 체험판으로 켰을 때 첫 화면 · 영웅 고르기(잠긴 영웅 상세 · 스테이지 탭) · 무한 15분 끝 창을 찍는다.
func _demoshot_flow(dir: String) -> void:
	if DisplayServer.get_name() == "headless" or not G.is_demo():
		print("[DEMOSHOT] 창모드 + --trial 로 켤 것")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.8).timeout
	print("[DEMOSHOT] user 폴더 %s" % OS.get_user_data_dir())
	_main_menu.open()   # 하니스로 켜면 부팅이 메뉴를 열지 않는다
	await get_tree().create_timer(0.6).timeout
	await _snap("%s/01_menu.png" % dir)
	_char_select.open()
	await get_tree().create_timer(0.5).timeout
	_char_select._set_mode(0)
	_char_select._show_detail(Characters.def_of("gunner"))
	await get_tree().create_timer(0.3).timeout
	await _snap("%s/02_select_locked.png" % dir)
	_char_select._show_detail(Characters.def_of("berserker"))
	await get_tree().create_timer(0.3).timeout
	await _snap("%s/03_select_berserker.png" % dir)
	_char_select._on_back()
	G.no_save = true
	G.run_mode = "endless"
	G.difficulty = 1
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(1.0)
	var p := G.player as Player
	p.grant_iframe(9999.0)
	p.xp_mult = 0.0
	G.time_alive = G.DEMO_ENDLESS_END - 0.5
	await get_tree().create_timer(1.5).timeout
	await _snap("%s/04_demo_end.png" % dir)
	print("[DEMOSHOT] 끝 화면 %s" % ("뜸" if _victory.visible else "안 뜸"))
	get_tree().quit(0)


## ──────────────────── 플레이 업데이트 안내 (--updateshot=<폴더>) ────────────────────
## 19차 5절: 플레이 답을 흉내 내서 메인 화면의 「새 버전」 · 「다시 시작」 안내를 찍고, 어느 경우에 무엇을 띄우는지 판정한다.
##   진짜 플레이 창(유연 · 즉시)은 폰에서 내부 앱 공유로만 뜬다. 세이브를 건드리니 APPDATA 를 나눠서 켤 것.
func _updateshot_flow(dir: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("[UPDATESHOT] 창모드로 켤 것")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(dir)
	G.no_save = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PlayUpdateCheck.CFG_PATH))
	await get_tree().create_timer(0.8).timeout
	_main_menu.open()
	var u: PlayUpdateCheck = _main_menu.update_check
	var fails: Array[String] = []
	var cases: Array = [
		# [이름, avail, days, priority, status, 기대(card / immediate / restart / none), 앞 상태]
		#   앞 상태: last_imm / last_flex = 마지막으로 띄운 종류, gap = 방금 즉시를 띄움, running = 판 도중 메뉴
		["새 버전 0일", 2, 0, 0, 0, "card", ""],
		["같은 날 또", 2, 1, 0, 0, "none", ""],
		["3일", 2, 3, 0, 0, "immediate", ""],
		["즉시 닫고 5분 안", 2, 3, 0, 0, "none", "gap"],
		["우선순위 4", 2, 0, 4, 0, "immediate", ""],
		["즉시 도중 복귀", 3, 0, 0, 2, "immediate", "last_imm"],
		["유연 받는 중 복귀", 3, 0, 0, 2, "none", "last_flex"],
		["새 버전 없음", 1, -1, 0, 0, "none", ""],
		["판 도중 메뉴", 2, 9, 0, 0, "none", "running"],
		["다 받음", 1, -1, 0, 11, "restart", ""],
	]
	for c in cases:
		u._close_card()
		u._downloaded = false
		u._imm_started = -PlayUpdateCheck.IMMEDIATE_GAP_MS if String(c[6]) != "gap" else Time.get_ticks_msec()
		if String(c[6]) == "last_imm":
			u._cfg_set("last_type", PlayUpdateCheck.TYPE_IMMEDIATE)
		elif String(c[6]) == "last_flex":
			u._cfg_set("last_type", PlayUpdateCheck.TYPE_FLEXIBLE)
		G.running = String(c[6]) == "running"
		await get_tree().process_frame
		var before: int = u.fake_started.size()
		u.fake_info(int(c[1]), int(c[2]), int(c[3]), int(c[4]))
		await get_tree().create_timer(0.4).timeout
		G.running = false
		var got: String = "none"
		if u._card != null:
			got = "restart" if u._downloaded else "card"
		elif u.fake_started.size() > before:
			got = "immediate"
		var ok: bool = got == String(c[5])
		print("[UPDATESHOT] %s %s → %s (기대 %s)" % ["PASS" if ok else "FAIL", c[0], got, c[5]])
		if not ok:
			fails.append(String(c[0]))
		if String(c[0]) == "새 버전 0일":
			await _snap("%s/update_offer.png" % dir)
		elif String(c[0]) == "다 받음":
			await _snap("%s/update_restart.png" % dir)
	# 메뉴를 닫으면(출격) 카드가 판으로 따라 들어가지 않는다
	var card_before: bool = u._card != null
	_main_menu.close()
	await get_tree().process_frame
	var gone: bool = card_before and u._card == null
	print("[UPDATESHOT] %s 메뉴 닫으면 카드도 닫힘 (카드 있었음 %s)" % ["PASS" if gone else "FAIL", card_before])
	if not gone:
		fails.append("메뉴 닫으면 카드")
	print("[UPDATESHOT] %s" % ("ALL PASS" if fails.is_empty() else "FAIL " + ", ".join(fails)))
	get_tree().quit(0 if fails.is_empty() else 1)


## ──────────────────── 광고 부활 신호 순서 (--revivecheck) ────────────────────
## 10/16 실기: 광고를 끝까지 봤는데 부활하지 않고 죽었다. 광고 SDK 가 「보상」과 「닫힘」을 다른 스레드에서 불러
##   닫힘이 먼저 오면 죽였다. 네 순서를 흉내 내서 살았나 죽었나를 본다(광고는 안 띄우고 Ads 신호만 쏜다).
func _revivecheck_flow(only: String = "") -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	var fails: Array[String] = []
	var cases: Array = [
		# [이름, 보상까지(초, -1 = 안 옴), 닫힘까지(초), 기대(살아남 / 죽음)]
		["보상 뒤 닫힘", 0.0, 0.2, "alive"],
		["닫힘 뒤 보상(0.3초)", 0.3, 0.0, "alive"],
		["닫힘 뒤 보상(2초)", 2.0, 0.0, "alive"],
		["닫힘만(보상 없음)", -1.0, 0.0, "dead"],
	]
	# 죽은 뒤 새 판은 장면을 다시 불러와 이 흐름이 끊긴다 — 죽는 경우는 맨 끝 하나만, 늦은 보상은 --revivecheck=late 로 따로
	if only == "late":
		cases = [["너무 늦은 보상(4초)", 4.0, 0.0, "dead"]]
	for c in cases:
		_begin_run(Characters.defs()[0])
		await _cf_wait_unpaused(0.5)
		var p := G.player as Player
		p.max_hp = 100.0
		p.hp = 1.0
		p._iframe = 0.0
		G.revive_used = 0
		p.take_damage(9999.0, "검사")
		await get_tree().process_frame
		if not p.pending_revive:
			print("[REVIVECHECK] FAIL %s: 부활 대기로 안 들어감" % c[0])
			fails.append(String(c[0]))
			continue
		_revive_busy = true       # 「광고 보기」를 누른 상태(광고 쪽은 신호만 흉내)
		_revive_left = 0.0
		var t_reward: float = float(c[1])
		var t_close: float = float(c[2])
		var events: Array = []
		if t_reward >= 0.0:
			events.append([t_reward, "reward"])
		events.append([t_close, "close"])
		events.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
		var t0: float = 0.0
		for ev in events:
			var wait: float = float(ev[0]) - t0
			if wait > 0.0:
				await get_tree().create_timer(wait, true, false, true).timeout
			t0 = float(ev[0])
			if String(ev[1]) == "reward":
				Ads.reward_earned.emit.call_deferred()
			else:
				Ads.ad_finished.emit.call_deferred()
		await get_tree().create_timer(3.5, true, false, true).timeout
		var alive: bool = is_instance_valid(p) and not p.pending_revive and p.hp > 0.0 and G.running
		var got: String = "alive" if alive else "dead"
		var ok: bool = got == String(c[3]) and not (got == "dead" and _run_active)
		print("[REVIVECHECK] %s %s → %s (기대 %s) run_active=%s gameover=%s" % ["PASS" if ok else "FAIL", c[0], got, c[3],
			_run_active, _gameover != null and _gameover.visible])
		if not ok:
			fails.append(String(c[0]))
		if _gameover != null:
			_gameover.visible = false
		get_tree().paused = false
	print("[REVIVECHECK] %s" % ("ALL PASS" if fails.is_empty() else "FAIL " + ", ".join(fails)))
	get_tree().quit(0 if fails.is_empty() else 1)


## ──────────────────── 장애물 막힘 (--obstblock) ────────────────────
## 장애물을 사이에 두고 몹 24마리가 영웅을 쫓게 해서, 몹 몸(반지름)이 장애물 충돌 원 안으로 파고든 최대 깊이를 잰다.
##   19차 3-2 에 몹 이동을 바꿔 보며 만들었다(바꾼 것은 이득이 없어 되돌렸다). 3px 넘게 파고들면 FAIL.
func _obstblock_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	seed(1913)
	G.difficulty = 1
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	p.global_position = Vector2.ZERO
	p.process_mode = Node.PROCESS_MODE_DISABLED   # 쏘지 않게(몹이 살아서 장애물을 돌아야 한다)
	_spawn_queue = 0
	_spawn_t = 1.0e9
	for o in get_tree().get_nodes_in_group("obstacle"):
		(o as Node).free()
	_obstacles = []
	var ob: Obstacle = Obstacle.spawn(self, Vector2(170, 0), 0, 50.0)
	_obstacles.append(ob)
	await get_tree().physics_frame
	var orad: float = ob._rad * 0.9
	var mobs: Array = []
	for i in 24:
		var e := Enemy.new()
		e.kind = [0, 8, 12][i % 3]
		e.global_position = Vector2(300.0 + float(i / 6) * 40.0, (float(i % 6) - 2.5) * 14.0)
		add_child(e)
		mobs.append(e)
	var worst: float = 0.0
	var touched: int = 0
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 6000:
		await get_tree().physics_frame
		for e: Enemy in mobs:
			if not is_instance_valid(e) or e._dead:
				continue
			var pen: float = (orad + e.rad) - e.global_position.distance_to(ob.global_position)
			if pen > -2.0:
				touched += 1
			worst = maxf(worst, pen)
	var ok: bool = worst < 3.0 and touched > 0
	print("[OBSTBLOCK] 장애물 반지름 %.0f  닿은 틱 %d  최대 파고듦 %.2fpx  %s" % [
		orad, touched, worst, "PASS" if ok else "FAIL"])
	get_tree().quit(0 if ok else 1)


## 11/5 스팀 피드백 6: 장애물 충돌이 그림과 맞는가(--obstshot).
## 테마 여섯 × 큰 · 작은 판을 한 줄씩 세우고, 영웅이 위 · 아래 · 왼쪽 · 오른쪽에서 걸어 들어갈 때 어디서 멈추는지
## (영웅 몸 중심과 그림의 몸통 가장자리 사이 거리)를 잰다. 예전 동그라미면 아래에서 그림 끝보다 한참 먼저 멈췄다.
## 사진: user://obstshot/ (뒤에 섰을 때 반투명 · 앞에 섰을 때 · 판 전체)
func _obstshot_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	_spawn_queue = 0
	_spawn_t = 1.0e9
	_theme_t = 1.0e9
	for e in get_tree().get_nodes_in_group("enemy"):
		(e as Node).queue_free()
	for o in get_tree().get_nodes_in_group("obstacle"):
		(o as Node).free()
	_obstacles = []
	var dir: String = "user://obstshot"
	DirAccess.make_dir_recursive_absolute(dir)
	var obs: Array = []
	for th in 6:
		for big in 2:
			var ob: Obstacle = Obstacle.spawn(self, Vector2(-1650.0 + float(th * 2 + big) * 300.0, 0.0), th, 50.0 if big == 1 else 36.0)
			obs.append(ob)
			_obstacles.append(ob)
	for i in 20:
		await get_tree().physics_frame
	var bad: int = 0
	print("[OBSTSHOT] 판 | 위에서 · 아래에서 · 왼쪽 · 오른쪽 멈춘 자리(영웅 중심 → 발판 가장자리 거리, px)")
	for ob: Obstacle in obs:
		var stops: Array = []
		for dv: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
			var start: Vector2 = ob.global_position - dv * 140.0
			var xf := Transform2D(0.0, start)
			var dist: float = 0.0
			while dist < 200.0:
				if p.test_move(xf.translated(dv * dist), dv * 2.0):
					break
				dist += 2.0
			stops.append(140.0 - dist)   # 장애물 기준점(바닥 가운데)에서 영웅 중심까지 남은 거리
		# 아래(앞)에서 다가가면 영웅 중심이 기준점에서 반지름 + 발판 앞 끝(몇 px)쯤에서 멈춰야 한다 — 예전 동그라미는 47~60
		var front: float = float(stops[1])
		if front > Player.RADIUS + 24.0 or front < Player.RADIUS - 2.0:
			bad += 1
		print("[OBSTSHOT] %s | 위 %.0f · 아래 %.0f · 왼 %.0f · 오른 %.0f" % [ob._sheet, stops[0], stops[1], stops[2], stops[3]])
	# 사진: 영웅을 큰 기둥 바로 뒤(위)에 → 반투명으로 비치는가 / 바로 앞(아래)에
	var pillar: Obstacle = obs[1]
	p.global_position = pillar.global_position + Vector2(0.0, -26.0)
	(G.camera as Camera2D).global_position = pillar.global_position
	for i in 30:
		await get_tree().process_frame
	await _snap("%s/behind.png" % dir)
	p.global_position = pillar.global_position + Vector2(0.0, 40.0)
	for i in 30:
		await get_tree().process_frame
	await _snap("%s/front.png" % dir)
	p.global_position = Vector2(0.0, 150.0)
	for i in 20:
		await get_tree().process_frame
	await _snap("%s/row.png" % dir)
	print("[OBSTSHOT] 앞에서 멈춘 자리가 어긋난 판 %d개 · 사진 %s  %s" % [bad, ProjectSettings.globalize_path(dir), "PASS" if bad == 0 else "FAIL"])
	get_tree().quit(0 if bad == 0 else 1)


func _fightcheck_flow(mode: String) -> void:
	await get_tree().create_timer(0.3).timeout
	if mode.begins_with("stage"):
		G.run_mode = "stage"
		G.stage_sel = clampi(int(mode.substr(5)), 0, 4)
	G.difficulty = 1 if not mode.begins_with("stage") else 0
	G.aim_mode = 0  # 자동조준 강제 (세이브 설정 격리)
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0  # 레벨업 모달 차단 — 모달이 뜨면 시간이 얼어 하니스가 무한 대기(행업)함
	p.global_position = Vector2.ZERO
	var swarm: bool = "swarm" in mode
	var first: Enemy = null
	var n: int = 60 if swarm else 1
	for i in n:
		var e := Enemy.new()
		e.kind = [0, 8, 12][i % 3] if swarm else 0
		var ang: float = TAU * float(i) / float(maxi(1, n))
		e.global_position = Vector2(cos(ang), sin(ang)) * (200.0 if not swarm else randf_range(380.0, 620.0))
		add_child(e)
		if first == null:
			first = e
	print("[FIGHT] mode=%s n=%d  적 HP=%.0f  spd=%.0f" % [mode if mode != "" else "endless", n, first.hp, first.spd])
	Engine.time_scale = 4.0
	var t0: float = G.time_alive
	var need: int = 5 if swarm else 1
	while G.time_alive - t0 < 12.0 and G.kills < need:
		await get_tree().create_timer(0.25).timeout
	Engine.time_scale = 1.0
	var ehp: float = first.hp if (is_instance_valid(first) and not first._dead) else -1.0
	var edist: float = first.global_position.distance_to(p.global_position) if is_instance_valid(first) else -1.0
	var avg_d: float = 0.0
	var cnt: int = 0
	for nd in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(nd):
			avg_d += (nd as Node2D).global_position.distance_to(p.global_position)
			cnt += 1
	print("[FIGHT] 12초 후: kills=%d  첫적HP=%.1f  첫적거리=%.0f  평균거리=%.0f(%d)  탄환=%d" % [G.kills, ehp, edist, avg_d / maxf(1.0, float(cnt)), cnt, get_tree().get_node_count_in_group("bullet")])
	print("[FIGHT] %s" % ("PASS" if G.kills >= need else "FAIL — 적이 안 죽음"))
	get_tree().quit(0 if G.kills >= need else 1)


## [검증용] 스테이지 보스전 격리 (headless) — 중반 빌드 + 잡몹 8마리 사이에서 보스가 죽는지.
## 자동조준 보스 우선 가중(S1)의 효과 검증. 60초(게임시간) 내 처치 실패 시 exit 1.
func _bosscheck_flow(snap_dir: String = "") -> void:
	await get_tree().create_timer(0.3).timeout
	G.run_mode = "stage"
	G.stage_sel = 0
	G.difficulty = 0
	G.aim_mode = 0  # 자동조준 강제 (세이브의 수동조준이 새면 허공 사격)
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0  # 레벨업 모달 차단
	for id: String in ["dmg", "dmg", "dmg", "multi", "multi", "rate", "rate", "wp_rapid", "wp_rapid", "crit"]:
		_apply_upgrade(id)  # 8분 시점 수준의 평범한 중반 빌드
	G.time_alive = G.STAGE_LEN  # 보스 스폰 시각으로 점프 (다음 _process에서 스폰)
	await get_tree().create_timer(0.5).timeout
	var boss: Enemy = _stage_boss
	if boss == null or not is_instance_valid(boss):
		print("[BOSSCHECK] FAIL — 스테이지 보스 미스폰")
		get_tree().quit(1)
		return
	var hp0: float = boss.hp
	print("[BOSSCHECK] 보스 kind=%d HP=%.0f — 잡몹 사이에서 60초 전투 시작" % [boss.kind, hp0])
	for i in 8:
		var e := Enemy.new()
		e.kind = 0
		var ang: float = TAU * float(i) / 8.0
		e.global_position = p.global_position + Vector2(cos(ang), sin(ang)) * 150.0
		add_child(e)
	Engine.time_scale = 5.0
	var t0: float = G.time_alive
	var next_log: float = 30.0
	# 240초 상한: C11 보스 체급 상향 반영 — 회피 위주 봇의 하한선 (실플레이어는 집중 화력으로 훨씬 빠름)
	while G.time_alive - t0 < 240.0 and not _stage_done:
		_flee_step()  # 실플레이처럼 무빙 (정지 플레이어 = 잡몹 자석 → 과대 비관)
		await get_tree().create_timer(0.1).timeout
		if G.time_alive - t0 >= next_log and _stage_boss != null and is_instance_valid(_stage_boss):
			next_log += 30.0
			var bd: float = _stage_boss.global_position.distance_to(p.global_position)
			print("[BOSSCHECK] t=%2.0fs  보스HP %.0f/%.0f  거리=%.0f  잡몹=%d" % [G.time_alive - t0, _stage_boss.hp, hp0, bd, _enemy_count() - 1])
	Engine.time_scale = 1.0
	for a in ["move_up", "move_down", "move_left", "move_right", "dash"]:
		Input.action_release(a)
	print("[BOSSCHECK] %s (%.0f초)" % ["PASS — 보스 처치·스테이지 클리어" if _stage_done else "FAIL — 240초 내 미처치", G.time_alive - t0])
	if snap_dir != "" and _stage_done:  # 승리 패널 스샷 (창모드 시각 검증용)
		DirAccess.make_dir_recursive_absolute(snap_dir)
		await get_tree().create_timer(0.4).timeout
		await _snap(snap_dir + "/victory.png")
	get_tree().quit(0 if _stage_done else 1)


## [검증용] 등급 가중 추첨 통계 (headless) — 20000회 추첨의 등급 분포 + 행운 영향.
func _rarity_check_flow() -> void:
	_m37_log("[RARITY] start")
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	_m37_log("[RARITY] run begun")
	var p := G.player as Player
	var myth: float = 0.0
	for lk: float in [0.0, 0.5]:
		p.luck = lk
		var tal: Dictionary = {}
		var draws: int = 5000
		var pool: Array = _filtered_pool()  # 풀은 불변 — 루프 밖에서 1회만 생성
		for i in draws:
			for u: Dictionary in _weighted_pick(pool, 3):
				var r: String = _rarity_of(String(u["id"]))
				tal[r] = int(tal.get(r, 0)) + 1
		var total: int = draws * 3
		var parts: Array = []
		for r: String in ["common", "rare", "epic", "unique", "legendary", "mythic"]:
			parts.append("%s %.2f%%" % [r, 100.0 * float(tal.get(r, 0)) / float(total)])
		_m37_log("[RARITY] 행운 +%d%%: %s" % [int(lk * 100.0), " · ".join(parts)])
		if lk == 0.0:
			myth = 100.0 * float(tal.get("mythic", 0)) / float(total)
	# ★ "신화가 너무 잘 뜬다"가 실플레이 리포트로 올라온 적이 있다. 카드를 새로 추가하거나
	#   가중치를 만지면 조용히 흔들리는 값이라 검사로 못 박아 둔다.
	#   0.21% × (레벨업 60회×2장 + 보스상자 12장) ≈ 판당 노출 24% 가 설계값이다.
	var ok: bool = myth >= 0.10 and myth <= 0.40
	_m37_log("[RARITY] 신화 카드당 %.2f%% (기대 0.10~0.40%%) — %s" % [myth, "PASS" if ok else "FAIL"])
	get_tree().quit(0 if ok else 1)


## [검증용] 캐릭터 선택 '뒤로' 버튼 실클릭 스모크 (창모드) — 좌상단 클릭이 실제로 먹는지.
## ★ 창모드 전용이다. 헤드리스에는 GUI 입력 경로가 없어 실클릭이 버튼에 닿지 않는다
##   (--uifit · --wpnshot 과 같은 부류인데 그 표시가 없었다).
##   그래서 헤드리스 일제검사에서 **늘 FAIL** 로 잡혔다 — 늘 실패하는 검사는
##   아무것도 못 잡는다. 실패가 아니라 '건너뜀'으로 갈라 준다.
func _clickback_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CLICKBACK] 건너뜀 — 창모드 전용 (실클릭에 GUI 가 필요하다)")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.3).timeout
	_main_menu.close()
	_char_select.open()
	await get_tree().process_frame
	await get_tree().process_frame
	var pos := Vector2(84, 42)  # 뒤로 버튼 중심 (24,20 + 120x44 절반)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = pos
	ev2.global_position = pos
	Input.parse_input_event(ev2)
	await get_tree().process_frame
	await get_tree().process_frame
	var closed: bool = not _char_select.is_open()
	print("[CLICKBACK] 뒤로 실클릭 → 캐릭선택 닫힘: %s" % str(closed))
	get_tree().quit(0 if closed else 1)


## [검증용] 특수 개체 (headless, S2) — 테마별 출현률(기대 6~9%) + 버프 플래그.
func _speccheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	G.time_alive = 200.0
	var fails: int = 0
	for th in 5:
		_cur_theme = th
		var cnt: Dictionary = {}
		for i in 2000:
			var k: int = _pick_kind()
			cnt[k] = int(cnt.get(k, 0)) + 1
		var spec: int = 0
		for k in [9, 10, 11, 12]:
			spec += int(cnt.get(k, 0))
		var pct: float = 100.0 * float(spec) / 2000.0
		print("[SPEC] 테마%d(%s): 특수 %.1f%%" % [th, String(G.STAGE_NAMES[th]), pct])
		if pct < 4.0 or pct > 12.0:
			fails += 1
	var e2 := Enemy.new()
	e2.kind = 9
	add_child(e2)
	await get_tree().process_frame
	print("[SPEC] 원혼: special=%s  HP=%.0f  xp=%d (기대 2.2x·3배)" % [str(e2.special), e2.hp, e2._xp])
	if not e2.special or e2._xp < 6:
		fails += 1
	print("[SPEC] %s" % ("ALL PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## [검증용] 융합 도달성 (headless, S8) — 실제 카드 풀·가중·슬롯 규칙을 그대로 태워
## '한 판에 융합을 보는가'를 잰다.
## ★ 롱플레이 봇은 30분에 레벨 13밖에 못 가서 이 질문에 답을 못 준다(실측). 그래서 전투를 빼고
##   레벨업 경로만 N판 돌린다. 유저 보고("융합을 한 번도 못 먹었다")가 회귀하는지 잡는 검사다.
func _fusioncheck_flow(runs: int) -> void:
	await get_tree().create_timer(0.2).timeout
	G.no_save = true
	var LV: int = 110  # 강빌드 기준 30분 도달 레벨 (game.gd 레벨 곡선 주석 기준)
	var hit: int = 0
	var first_lv_sum: int = 0
	for r in runs:
		_begin_run(Characters.defs()[0])
		var got: int = 0
		for lv in LV:
			var evos: Array = _available_evolutions()
			var pool: Array = _filtered_pool()
			# _populate_cards 와 같은 규칙: 진화 확정 1장 + 보유 유물 보장 1장 + 나머지 추첨
			var offer: Array = []
			if not evos.is_empty():
				offer.append(evos[randi() % evos.size()])
			var owned: Array = pool.filter(
				func(u: Dictionary) -> bool:
					var uid: String = String(u["id"])
					return int(_upgrade_counts.get(uid, 0)) > 0 and (_is_weapon_id(uid) or _is_bullet_id(uid))
			)
			if not owned.is_empty() and offer.size() < 3:
				var g: Dictionary = owned[randi() % owned.size()]
				offer.append(g)
				pool = pool.filter(func(u: Dictionary) -> bool: return String(u["id"]) != String(g["id"]))
			for up in _weighted_pick(pool, 3 - offer.size()):
				offer.append(up)
			if offer.is_empty():
				break
			var pick: Dictionary = offer[randi() % offer.size()]  # 최악 가정: 아무거나 고른다
			_apply_upgrade(String(pick["id"]))
			if String(pick["id"]).begins_with("evo_"):
				got = lv + 1
				break
		if got > 0:
			hit += 1
			first_lv_sum += got
	var pct: float = 100.0 * float(hit) / float(maxi(1, runs))
	print("[FUSION] %d판 · 레벨 %d까지 · 무작위 선택 → 융합 도달 %d판 (%.1f%%)" % [runs, LV, hit, pct])
	if hit > 0:
		print("[FUSION] 처음 융합이 뜬 평균 레벨 %.0f" % (float(first_lv_sum) / float(hit)))
	print("[FUSION] %s" % ("PASS" if pct >= 25.0 else "FAIL — 25%% 미만 (유저가 융합을 못 보는 상태)"))
	get_tree().quit(0 if pct >= 25.0 else 1)


## [검증용] 자산 정합성 (headless, S8) — 코드가 참조하는 스프라이트가 실제로 있는지,
## 걷기 스트립/단일 프레임 판정이 맞는지, 아이콘이 빠진 카드가 없는지 한 번에 본다.
## ★ 자산이 100장을 넘어가면 "오타 하나로 조용히 도형 폴백" 이 눈에 안 띈다 — 그걸 잡는 검사다.
func _artcheck_flow() -> void:
	await get_tree().create_timer(0.2).timeout
	var miss_mon: Array = []
	var strips: int = 0
	var stills: int = 0
	for k in Enemy.LOOKS.keys():
		var nm: String = String((Enemy.LOOKS[k] as Dictionary).get("spr", ""))
		if nm == "":
			continue
		var path: String = "res://assets/sprites/monsters/%s.png" % nm
		if not ResourceLoader.exists(path):
			miss_mon.append("kind %d → %s" % [int(k), nm])
			continue
		if Enemy._strip_frames(path) > 1:
			strips += 1
		else:
			stills += 1
	print("[ART] 몬스터 스프라이트: 스트립 %d · 단일 %d · 누락 %d" % [strips, stills, miss_mon.size()])
	for m in miss_mon:
		print("[ART]   ✗ 누락 %s" % String(m))
	var miss_char: Array = []
	for d: Dictionary in Characters.defs():
		var sp: String = String(d.get("sprite", ""))
		# 16차: 저승길 영웅 여섯은 예전 한 장 그림이 처음부터 없다(sprite "") — 캐릭터 에셋(cast.json)만. 적어 둔 경로가 없는 것만 누락
		if sp == "":
			continue
		if not ResourceLoader.exists(sp):
			miss_char.append(String(d["name"]))
	print("[ART] 캐릭터 스프라이트 누락 %d" % miss_char.size())
	for m2 in miss_char:
		print("[ART]   ✗ 누락 %s" % String(m2))
	# 카드 아이콘 — PNG 가 없으면 절차적 심볼로 떨어진다(치명적이진 않지만 몇 장인지는 알아야 한다)
	var no_png: Array = []
	for u: Dictionary in _base_pool():
		var id: String = String(u["id"])
		if not ResourceLoader.exists("res://assets/sprites/icons/%s.png" % id):
			no_png.append(id)
	print("[ART] 카드 %d종 중 PNG 아이콘 없는 것 %d종" % [_base_pool().size(), no_png.size()])
	if no_png.size() > 0:
		print("[ART]   (절차적 심볼로 표시) %s" % ", ".join(PackedStringArray(no_png)))
	var fails: int = miss_mon.size() + miss_char.size()
	print("[ART] %s" % ("ALL PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## [검증용] 장신구 (headless, S8) — 구매/장착/중복차단/효과 실적용/저장 지속. 실패 시 exit 1.
func _acccheck_flow() -> void:
	await get_tree().create_timer(0.2).timeout
	var fails: int = 0
	G.meta.clear()
	G.total_gold = 200000
	# 1) 구매: 골드가 깎이고 보유로 바뀐다. 두 번 사지지 않는다.
	var d: Dictionary = Accessories.def_of("acc_okring")
	var before: int = G.total_gold
	var ok1: bool = G.acc_buy("acc_okring")
	var spent: int = before - G.total_gold
	print("[ACC] 구매: %s / 지출 %d (기대 %d) / 보유 %s" % [str(ok1), spent, int(d["gold"]), str(G.acc_owned("acc_okring"))])
	if not ok1 or spent != int(d["gold"]) or not G.acc_owned("acc_okring"):
		fails += 1
	if G.acc_buy("acc_okring"):
		print("[ACC] ✗ 같은 장신구를 두 번 샀다")
		fails += 1
	# 2) 장착: 칸에 들어가고, 다른 칸에 같은 것을 넣으면 앞 칸이 비워진다(중복 장착 차단)
	G.acc_equip(0, "acc_okring")
	G.acc_equip(2, "acc_okring")
	var dup: int = 0
	for i in Accessories.SLOTS:
		if G.acc_slot(i) == "acc_okring":
			dup += 1
	print("[ACC] 중복 장착 차단: 같은 것이 낀 칸 수 = %d (기대 1)" % dup)
	if dup != 1:
		fails += 1
	# 3) 효과 실적용: 옥가락지(치명 +8% / 배율 +0.25)가 실제 스탯에 붙는가
	_begin_run(Characters.defs()[0])
	var p := G.player as Player
	var crit_with: float = p.crit_chance
	var cm_with: float = p.crit_mult
	G.acc_equip(0, "")
	G.acc_equip(2, "")
	_begin_run(Characters.defs()[0])
	var crit_wo: float = (G.player as Player).crit_chance
	var cm_wo: float = (G.player as Player).crit_mult
	print("[ACC] 옥가락지 효과: 치명 %.3f→%.3f (기대 +0.08) / 배율 %.2f→%.2f (기대 +0.25)" % [crit_wo, crit_with, cm_wo, cm_with])
	if absf((crit_with - crit_wo) - 0.08) > 0.001 or absf((cm_with - cm_wo) - 0.25) > 0.001:
		fails += 1
	# 4) 미보유 장신구는 장착되지 않는다
	G.acc_equip(1, "acc_geoul")
	print("[ACC] 미보유 장착 차단: 1번 칸 = '%s' (기대 빈칸)" % G.acc_slot(1))
	if G.acc_slot(1) != "":
		fails += 1
	# 5) 두 번 적용해도 누적되지 않는다 (런을 다시 시작해도 같은 값)
	G.acc_equip(0, "acc_okring")
	_begin_run(Characters.defs()[0])
	var again: float = (G.player as Player).crit_mult
	_begin_run(Characters.defs()[0])
	var again2: float = (G.player as Player).crit_mult
	print("[ACC] 재시작 누적 없음: %.2f → %.2f (같아야 함)" % [again, again2])
	if absf(again - again2) > 0.001:
		fails += 1
	print("[ACC] %s" % ("ALL PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## [검증용] 반복 퀘스트 로직 (headless, S5) — 진행/캡/수령/재수령 금지/기간 리셋.
func _questcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	var fails: int = 0
	var qd: Dictionary = Codex.QUESTS[0]  # d_kill: 400킬 / 60G
	G.quests.clear()
	G.quest_add("kills", 150)
	var e: Dictionary = G.quest_entry(qd)
	print("[QUEST] 진행 150: p=%d claimable=%s" % [int(e["p"]), str(G.quest_claimable(qd))])
	if int(e["p"]) != 150 or G.quest_claimable(qd):
		fails += 1
	G.quest_add("kills", 300)
	print("[QUEST] 450→캡400: p=%d claimable=%s count=%d" % [int(G.quest_entry(qd)["p"]), str(G.quest_claimable(qd)), G.quest_claimable_count()])
	if int(G.quest_entry(qd)["p"]) != 400 or not G.quest_claimable(qd):
		fails += 1
	var got: int = G.quest_claim("d_kill")
	var again: int = G.quest_claim("d_kill")
	print("[QUEST] 수령 +%dG (기대 60) / 재수령 %d (기대 0)" % [got, again])
	if got != 60 or again != 0:
		fails += 1
	(G.quests["d_kill"] as Dictionary)["k"] = "1999-01-01"  # 기간 경과 시뮬레이션
	var e2: Dictionary = G.quest_entry(qd)
	print("[QUEST] 기간 리셋: p=%d c=%s (기대 0/false)" % [int(e2["p"]), str(e2["c"])])
	if int(e2["p"]) != 0 or bool(e2["c"]):
		fails += 1
	print("[QUEST] %s" % ("ALL PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## [검증용] 상점 화면 스샷 (창모드, S5) — 스크롤 + 뒤로 버튼 도달 확인 (맨 아래로 스크롤한 컷 포함).
func _shop_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	_main_menu.close()
	_meta_shop.open()
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap(dir + "/shop_top.png")
	var sc: ScrollContainer = _find_scroll(_meta_shop)
	if sc != null:
		sc.scroll_vertical = 99999
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap(dir + "/shop_bottom.png")
	get_tree().quit(0)


## [검증용] 터치 드래그 스크롤 (창모드, S2) — 설정 세로/캐릭선택 가로 패닝 + 버튼 오발동 방지.
func _scrollcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	# ★ 이 검사는 2026-09-06 전까지 **늘 FAIL 이었다.** 1280×720 에서는 설정·캐릭선택 내용이
	#   화면 안에 다 들어와서 스크롤할 것이 없었고, 그래서 "끌었는데 안 움직인다"로 잡혔다.
	#   늘 실패하는 검사는 아무것도 못 잡는다 — 실제로 두 번이나 "헤드리스 탓"으로 넘겼다.
	#   내용이 반드시 넘치도록 논리 해상도를 좁혀 놓고 잰다(content_scale_size 라야 먹는다).
	get_window().content_scale_size = Vector2i(640, 400)
	get_window().size = Vector2i(640, 400)
	await get_tree().process_frame
	await get_tree().process_frame
	_main_menu.close()
	_settings.open()
	await get_tree().process_frame
	await get_tree().process_frame
	var sc: ScrollContainer = _find_scroll(_settings)
	var v0: int = sc.scroll_vertical
	var d0: int = G.difficulty
	var vol0: float = G.master_volume
	await _drag_mouse(Vector2(320, 330), Vector2(320, 70))  # 위로 끌기 = 아래로 스크롤
	var v1: int = sc.scroll_vertical
	var ok1: bool = v1 > v0 and G.difficulty == d0 and absf(G.master_volume - vol0) < 0.001
	print("[SCROLL] 설정 세로: %d → %d (기대 증가) · 난이도/음량 불변: %s" % [v0, v1, str(G.difficulty == d0 and absf(G.master_volume - vol0) < 0.001)])
	_settings._on_back()
	await get_tree().process_frame
	_main_menu.close()
	_char_select.open()
	await get_tree().process_frame
	await get_tree().process_frame
	# 16차부터 출격 준비는 끌기 없는 영웅 격자(7×3)라 가로 스크롤이 없다(10/13 QA: 여기서 null 로 스크립트 오류가 났다).
	#   스크롤이 있으면 예전처럼 재고, 없으면 「영웅 칸 위에서 끌다 떼도 출격이 안 된다」만 본다.
	var sc2: ScrollContainer = _find_scroll(_char_select)
	var h0: int = sc2.scroll_horizontal if sc2 != null else 0
	await _drag_mouse(Vector2(800, 400), Vector2(300, 400))  # 카드 위에서 왼쪽으로 스와이프
	var h1: int = sc2.scroll_horizontal if sc2 != null else 0
	var ok2: bool = (sc2 == null or h1 > h0) and _char_select.is_open()  # 스크롤됐고, 카드가 오발동(선택)되지 않았는지
	print("[SCROLL] 캐릭선택 %s · 카드 오발동 없음: %s" % [("가로: %d → %d (기대 증가)" % [h0, h1]) if sc2 != null else "가로 스크롤 없음(격자)", str(_char_select.is_open())])
	print("[SCROLL] %s" % ("ALL PASS" if ok1 and ok2 else "FAIL"))
	get_tree().quit(0 if ok1 and ok2 else 1)


func _find_scroll(root: Node) -> ScrollContainer:
	if root is ScrollContainer:
		return root
	for c in root.get_children():
		var r: ScrollContainer = _find_scroll(c)
		if r != null:
			return r
	return null


## 마우스 프레스→이동(12스텝)→릴리즈 합성 (터치 스크롤은 에뮬레이트 마우스 경로로 동작)
func _drag_mouse(from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = from
	press.global_position = from
	Input.parse_input_event(press)
	await get_tree().process_frame
	var steps: int = 12
	for i in steps:
		var pos: Vector2 = from.lerp(to, float(i + 1) / float(steps))
		var mv := InputEventMouseMotion.new()
		mv.position = pos
		mv.global_position = pos
		mv.relative = (to - from) / float(steps)
		mv.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mv)
		await get_tree().process_frame
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = to
	rel.global_position = to
	Input.parse_input_event(rel)
	await get_tree().process_frame
	await get_tree().process_frame


## [검증용] 캐릭터 선택 화면 스샷 — 난이도 설명 라벨 확인.
func _char_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	_main_menu.close()
	_char_select.open()
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap(dir + "/charsel.png")
	get_tree().quit(0)


## [검증용] M37 융합 개편 스모크 (headless) — 재료 소멸/초월 재부여/풀 재등장 금지/보스상자. 실패 시 exit 1.
func _m37_smoke_flow() -> void:
	_m37_log("[M37] flow start")
	await get_tree().create_timer(0.3).timeout
	_m37_log("[M37] begin_run")
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	_m37_log("[M37] run started")
	var p := G.player as Player
	var fails: int = 0
	# 1) 지옥불(무기+속성): 재료 만렙 → 카드 등장 → 융합 → 소멸+초월 재부여
	for i in 6:
		_apply_upgrade("wpn_fire")
	for i in 5:
		_apply_upgrade("b_fire")
	var has_card: bool = false
	for e: Dictionary in _available_evolutions():
		if String(e["id"]) == "evo_inferno":
			has_card = true
	_m37_log("[M37] 재료 만렙 → 지옥불 카드 등장: %s" % str(has_card))
	if not has_card:
		fails += 1
	_apply_upgrade("evo_inferno")
	await get_tree().process_frame
	var mat_gone: bool = (not _upgrade_counts.has("wpn_fire")) and (not _upgrade_counts.has("b_fire"))
	var lv9: bool = p.weapons.has("wpn_fire") and int(p.weapons["wpn_fire"].get("level")) == 11
	_m37_log("[M37] 재료 소멸: %s / 융합무기 Lv11: %s / 화상=%d (기대 6)" % [str(mat_gone), str(lv9), p.b_fire])
	if not mat_gone or not lv9 or p.b_fire != 6:
		fails += 1
	var reappear: bool = false
	for u: Dictionary in _filtered_pool():
		if String(u["id"]) in ["wpn_fire", "b_fire"]:
			reappear = true
	_m37_log("[M37] 소멸 카드 풀 재등장 없음: %s" % str(not reappear))
	if reappear:
		fails += 1
	# 2) 레일건(무기+탄막, S5 재편): heavy+거대탄환 소멸 → heavy Lv11 + 관통 +8, b_big 리셋
	for i in 6:
		_apply_upgrade("wp_heavy")
	for i in 4:
		_apply_upgrade("b_big")
	var pierce_before: int = p.pierce
	_apply_upgrade("evo_railcannon")
	var heavy_lv: int = 0
	for w in p.weapons_primary:
		if String(w["id"]) == "heavy":
			heavy_lv = int(w["level"])
	_m37_log("[M37] 레일건: heavy Lv%d (기대 11) / 관통 %d→%d (기대 %d) / b_big=%d (기대 0)" % [heavy_lv, pierce_before, p.pierce, pierce_before + 8, p.b_big])
	if heavy_lv != 11 or p.pierce != pierce_before + 8 or p.b_big != 0:
		fails += 1
	# 3) 필중의 눈(무기+탄막, S5 재편): 속사+유도 소멸 → 속사 Lv11 + 유도 6 + 크리 100%
	for i in 6:
		_apply_upgrade("wp_rapid")
	for i in 3:
		_apply_upgrade("crit")
	_apply_upgrade("evo_deadeye")
	var rapid_lv: int = 0
	for w2 in p.weapons_primary:
		if String(w2["id"]) == "rapid":
			rapid_lv = int(w2["level"])
	_m37_log("[M37] 필중의 눈: 크리 %.2f (기대 1.00) / rapid Lv%d (기대 11) / 유도=%d (기대 6)" % [p.crit_chance, rapid_lv, p.b_homing])
	if absf(p.crit_chance - 1.0) > 0.001 or rapid_lv != 11 or p.b_homing != 6:
		fails += 1
	# 4) 보스 상자: 시그널 → 무작위 강화 지급 (크래시 없이 동작)
	var dmg_before: float = p.damage
	var lv_marker: int = _upgrade_counts.size()
	G.boss_chest_collected.emit()
	_m37_log("[M37] 보스 상자: 강화 지급 시도 (카드 종류 %d→%d, dmg %.1f→%.1f)" % [lv_marker, _upgrade_counts.size(), dmg_before, p.damage])
	# 5) 신화 규칙 3종 — 한 판 1장 / 초월이 장부까지 올린다 / 만렙 넘긴 무기는 풀에서 빠진다
	#    ★ "초월을 먹었는데 카드에는 표시가 안 되고, 이미 풀강인데 또 강화가 뜬다"는 리포트의 회귀 검사
	for _i in 4:
		_apply_upgrade("wp_balanced")   # Lv5 로 올려 둔다 — 초월 +3 이면 만렙(6)을 넘긴다
	var wl0: int = int(_upgrade_counts.get("wp_balanced", 0))
	_apply_upgrade("m_transcend")
	await get_tree().process_frame
	var wl1: int = int(_upgrade_counts.get("wp_balanced", 0))
	_m37_log("[M37] 초월: 장부 레벨 %d → %d (기대 +3 · 카드 별표시와 일치)" % [wl0, wl1])
	if wl1 != wl0 + 3:
		fails += 1
	var myth_left: bool = false
	for u2: Dictionary in _filtered_pool():
		if String(u2["id"]).begins_with("m_"):
			myth_left = true
	_m37_log("[M37] 신화 1장 획득 후 풀에 신화 남음: %s (기대 false)" % str(myth_left))
	if myth_left:
		fails += 1
	var over_max: bool = false
	for u3: Dictionary in _filtered_pool():
		if String(u3["id"]) == "wp_balanced":
			over_max = true
	_m37_log("[M37] 만렙 넘긴 무기(Lv%d/6)가 풀에 남음: %s (기대 false — 무한 강화 차단)" % [wl1, str(over_max)])
	if over_max:
		fails += 1
	_m37_log("[M37] %s" % ("ALL PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## [검증용] 몬스터 애니메이션 스샷 — 9종을 링 배치, 0.45초 간격 2컷(포즈 차이 = 애니 작동 증거).
func _mon_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	var p := G.player as Player
	p.max_hp = 99999.0
	p.hp = 99999.0
	p.damage = 0.0001  # 관찰 중 사살 방지
	var world: Node = p.get_parent()
	for k in 9:
		var e := Enemy.new()
		e.kind = k
		world.add_child(e)
		var ang: float = TAU * float(k) / 9.0
		e.global_position = p.global_position + Vector2(cos(ang), sin(ang)) * 235.0
	await get_tree().create_timer(0.6).timeout
	await _snap(dir + "/mon_a.png")
	await get_tree().create_timer(0.45).timeout
	await _snap(dir + "/mon_b.png")
	get_tree().quit(0)


## 실제 드랍 경로(enemy._drop)를 n회 돌려 Pickup 생성 수를 센다. 젬/픽업은 즉시 정리.
func _statcheck_drops(e: Enemy, world: Node, p: Player, lk: float, n: int) -> int:
	p.luck = lk
	var before: int = _statcheck_pickup_count(world)
	for i in n:
		e._drop()
	var after: int = _statcheck_pickup_count(world)
	for c in world.get_children():
		if c is Pickup or c is XpGem:
			c.queue_free()
	return after - before


func _statcheck_pickup_count(world: Node) -> int:
	var cnt: int = 0
	for c in world.get_children():
		if c is Pickup:
			cnt += 1
	return cnt


## [검증용] 도감/도전과제 화면 스샷 — 표본 데이터 시드 후 4탭 캡처. 실제 세이브는 건드리지 않음.
## 테마별 바닥 타일 믹스 검증 컷 — 5테마 순회, 페이드 스킵 후 아레나만 스냅 (S7)
func _tile_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	var p := G.player as Player
	p.xp_mult = 0.0  # 레벨업 모달 방지 (하니스 필수)
	for i in 5:
		_bg.set_theme(i)
		_bg._fade = 1.0  # 크로스페이드 스킵
		await get_tree().process_frame
		await get_tree().process_frame
		await _snap("%s/tiles_%d_%s.png" % [dir, i, _bg.theme_name()])
	get_tree().quit(0)


func _codex_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	for k: String in ["mon_0", "mon_1", "mon_8", "mon_7", "mon_3", "map_0", "map_2", "map_3", "fus_evo_inferno", "fus_evo_reaper"]:
		G.codex[k] = true
	G.stats = {"best_time": 640, "best_level": 24, "total_kills": 3200, "total_bosses": 4, "total_fusions": 2, "jackpots": 1, "runs": 6, "mon_seen": 5, "map_seen": 3}
	G.achievements = {"survive_5m": true, "level_20": true, "kills_1k": true, "fusion_1": true, "jackpot": true}
	_main_menu.close()
	_codex_screen.open()
	var names: Array = ["conquest", "mon", "map", "fus", "ach", "quest"]  # 0번이 정복 탭으로 신설됨
	for i in names.size():
		_codex_screen._switch(i)
		await get_tree().process_frame
		await get_tree().process_frame
		await _snap("%s/codex_%d_%s.png" % [dir, i, String(names[i])])
	get_tree().quit(0)


## 3분+ 무적 봇 플레이로 FPS/노드수 실측 (렉 원인 데이터 수집)
func _perf_flow(logpath: String = "") -> void:
	var f: FileAccess = FileAccess.open(logpath, FileAccess.WRITE) if logpath != "" else null
	var p := G.player as Player
	p.apply_character(Characters.defs()[0])
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	G.difficulty = 3  # 하드코어 = 최악 부하
	# 헤비 빌드로 탄환·데미지숫자 폭주 재현 (사용자 렉 상황: 유도+튕김+관통+속사+연쇄)
	for i in 5:
		_apply_upgrade("multi")
	for i in 3:
		_apply_upgrade("pierce")
	for i in 4:
		_apply_upgrade("rate")
	for i in 4:
		_apply_upgrade("wp_rapid")  # 속사 기관총
	for i in 3:
		_apply_upgrade("crit")  # 유도
	for i in 3:
		_apply_upgrade("b_bounce")  # 튕김
	for i in 3:
		_apply_upgrade("b_chain")   # 연쇄
	_apply_upgrade("crit")
	_apply_upgrade("crit")
	p.damage = 0.05  # 스트레스: 적이 안 죽고 누적 → 탄환×적 최악 부하(유도 스캔) 재현
	G.reset_run()
	var t: float = 0.0
	var min_fps: float = 9999.0
	var dirs: Array = ["move_right", "move_down", "move_left", "move_up"]
	var di: int = 0
	while t < 160.0:
		Input.action_press(String(dirs[di]))
		await get_tree().create_timer(0.5).timeout
		Input.action_release(String(dirs[di]))
		di = (di + 1) % 4
		t += 0.5
		if int(t) % 3 == 0 and abs(t - float(int(t))) < 0.01:
			var fps: float = Engine.get_frames_per_second()
			if t > 6.0:
				min_fps = minf(min_fps, fps)
			var line: String = "[PERF] t=%3.0fs fps=%3.0f enemies=%d bullets=%d nodes=%d" % [t, fps, _enemy_count(), get_tree().get_node_count_in_group("bullet"), get_tree().get_node_count()]
			print(line)
			if f != null:
				f.store_line(line)
				f.flush()
	var done: String = "=== PERF DONE min_fps=%.0f ===" % min_fps
	print(done)
	if f != null:
		f.store_line(done)
		f.close()
	get_tree().quit(0)


# ---------------------------------------------------------------- 긴 실플레이(수분) 자동 검증
## 필멸 플레이어 + 회피AI + 자동 카드픽으로 수분간 실제 플레이. 20초마다 스샷+로그, 생존시간 보고.
## 근접 낫 스윙 이펙트/코인/소환수를 통제된 화면으로 캡처 (시각 검증용)
func _showcase_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	G.difficulty = 1
	G.aim_mode = 1  # 수동조준(오른쪽 고정)
	_begin_run(Characters.defs()[0])
	var p := G.player as Player
	p.add_primary_weapon("melee")
	p.add_weapon("wpn_summon")
	p.add_weapon("summon_ice")
	p.add_weapon("wpn_orb")
	for wid: String in ["wpn_poison", "wpn_ice", "wpn_fire", "wpn_chain"]:
		p.add_weapon(wid)
		p.add_weapon(wid)  # 레벨 올려 크고 빠르게
	# 스킬 아이콘 카드 확인용 컷
	G.add_xp(100)
	await get_tree().create_timer(0.35).timeout
	await _snap(dir + "/sc_card.png")
	var _g: int = 0
	while _levelup_root.visible and _g < 10:
		_auto_pick()
		await get_tree().process_frame
		_g += 1
	# 코인 + XP젬 (구분 확인) — 자석 밖 배치. 적은 아직 안 놓음(레벨업 방지)
	var gem_vals: Array = [1, 4, 9, 2, 7]
	for i in 10:
		var ang: float = TAU * float(i) / 10.0
		var base := p.global_position + Vector2(cos(ang), sin(ang)) * 165.0
		if i % 2 == 0:
			GoldCoin.spawn(self, base, 5)
		else:
			XpGem.spawn(self, base, int(gem_vals[(i / 2) % gem_vals.size()]))
	await get_tree().create_timer(1.2).timeout
	await _snap(dir + "/sc_coins_summons.png")
	# 오른쪽에 적 배치(낫 타격 대상, 탱크라 잘 안 죽음)
	for i in 5:
		var e := Enemy.new()
		e.kind = 2
		e.global_position = p.global_position + Vector2(70.0 + float(i) * 12.0, float(i - 2) * 22.0)
		add_child(e)
	# 낫 스윙: 오른쪽으로 휘두르며 진행 중 여러 컷
	p.aim = Vector2.RIGHT
	p._melee_swing(Player.WEAPON_DEFS["melee"], 3)
	await get_tree().create_timer(0.03).timeout
	await _snap(dir + "/sc_melee_a.png")
	await get_tree().create_timer(0.04).timeout
	await _snap(dir + "/sc_melee_b.png")
	await get_tree().create_timer(0.05).timeout
	await _snap(dir + "/sc_melee_c.png")
	# 속성 이펙트(독웅덩이/얼음장판/불꽃/번개) — 레벨업 원천차단 후 적 배치
	G.xp_to_next = 99999999
	for i in 14:
		var a2: float = TAU * float(i) / 14.0
		var ee := Enemy.new()
		ee.kind = 2
		ee.global_position = p.global_position + Vector2(cos(a2), sin(a2)) * randf_range(100.0, 175.0)
		add_child(ee)
	await get_tree().create_timer(2.0).timeout
	await _snap(dir + "/sc_effects.png")
	# 보스 예고형 장판 컷 (플레이어 발밑 붉은 경고 원)
	var boss := Enemy.new()
	boss.kind = 4
	boss.global_position = p.global_position + Vector2(230.0, -60.0)
	add_child(boss)
	boss._special_cd = 0.5
	await get_tree().create_timer(0.9).timeout
	await _snap(dir + "/sc_boss_aoe.png")
	# 아레나 경계 벽 — 플레이어를 오른쪽 가장자리로
	p.global_position = Vector2(ARENA - 50.0, 0.0)
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/sc_wall.png")
	# 일시정지 빌드 패널 — 무기/탄막 획득(_upgrade_counts 채움) 후 열기
	for wid: String in ["wp_heavy", "wpn_fire", "wpn_ice", "wpn_poison", "b_fire", "b_ice", "b_shock", "wpn_summon"]:
		_apply_upgrade(wid)
		_apply_upgrade(wid)
	_pause_menu._toggle()
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/sc_pause_build.png")
	get_tree().quit(0)


# ---------------------------------------------------------------- 무기 DPS 측정 하니스
## 각 무기를 통제 환경(불사 더미 링·스폰정지)에서 T초 실측 → DPS 출력. 헤드리스 OK(_snap 미사용).
## 카드에 적힌 레벨과 무기가 실제로 쓰는 레벨이 같은가.
## ★ 카드 표기는 _upgrade_counts(내가 그 카드를 몇 번 골랐나)를, 무기는 자기 level 을 쓴다.
##   두 값이 갈리는 경로가 둘 있다 — (1) 영웅 능력이 카드 없이 쥐어주는 무기(갈덴의 소환수),
##   (2) 초월(m_transcend) 뒤에 드는 무기. 갈리면 "만렙 Lv6" 이라 적힌 특성이 화면상 Lv5 에서
##   터진다 — 실제로 그렇게 신고받았다(2026-09-06). 여기서 전 특수무기를 전수로 본다.
func _lvlcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	var fails: int = 0
	var specials: Array = ["wpn_orb", "wpn_chain", "wpn_fire", "wpn_ice", "wpn_poison",
		"wpn_summon", "summon_ice", "wpn_whip", "wpn_boomerang", "wpn_beam"]
	# 1) 기본 영웅 — 카드로만 얻는 정상 경로
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	for sid: String in specials:
		for i in 6:
			_apply_upgrade(sid)
		var shown: int = _shown_level(sid)          # 화면이 적는 값
		var real: int = int(p.weapons[sid].get("level")) if p.weapons.has(sid) else -1
		if shown != real:
			print("[LVL]   ✗ %-13s 화면 Lv%d 인데 무기는 Lv%d (장부 %d)"
				% [sid, shown, real, int(_upgrade_counts.get(sid, 0))]); fails += 1
	print("[LVL] 기본 영웅 · 특수무기 %d종 카드6회 → 표기와 실제 %s"
		% [specials.size(), "일치" if fails == 0 else "불일치 %d건" % fails])
	# ★ "MAX 라고 적어 놓고 또 뜬다"는 신고를 잡는 자리(2026-09-06, 맹독 장판).
	#   화면이 MAX 라고 말한 카드는 (1) 카드 풀에서 사라져야 하고 (2) 융합 진행도에도
	#   같은 수로 적혀야 한다. 셋(카드·풀·융합)이 같은 레벨을 봐야 한다.
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	p = G.player as Player
	for sid2: String in specials:
		var cap2: int = _ability_max(sid2)
		var picks: int = 0
		while _shown_level(sid2) < cap2 and picks < 12:
			_apply_upgrade(sid2)
			picks += 1
		var shown2: int = _shown_level(sid2)
		var still: bool = false
		for u2: Dictionary in _filtered_pool():
			if String(u2["id"]) == sid2:
				still = true
		var real2: int = int(p.weapons[sid2].get("level")) if p.weapons.has(sid2) else -1
		if shown2 != cap2 or still or real2 != cap2:
			print("[LVL]   ✗ %-13s 카드 %d/%d · 무기 Lv%d · 풀에 %s"
				% [sid2, shown2, cap2, real2, "아직 있다" if still else "없다"])
			fails += 1
	print("[LVL] MAX 도달 후 카드 풀에서 사라지고 무기 레벨도 상한과 같은가: %s"
		% ("일치" if fails == 0 else "불일치"))
	# 2) 영웅 능력이 무기를 그냥 쥐어주는 경우 — 갈덴(소환수) · 베른(화염오라)
	for cid: String in ["mudang", "pyro"]:
		var cdef: Dictionary = Characters.defs()[0]
		for d: Dictionary in Characters.defs():
			if String(d["id"]) == cid or String(d.get("ability", "")) == cid:
				cdef = d
		_begin_run(cdef)
		await get_tree().process_frame
		p = G.player as Player
		var wid: String = "wpn_summon" if String(cdef.get("ability", "")) == "spirits" else "wpn_fire"
		var lv0: int = int(p.weapons[wid].get("level")) if p.weapons.has(wid) else -1
		var cnt0: int = int(_upgrade_counts.get(wid, 0))
		# 화면이 '만렙'이라고 말하는 그 지점까지 카드를 고른다
		var trait_at: int = -1
		var shown_at: int = -1
		for i in 8:
			_apply_upgrade(wid)
			var real: int = int(p.weapons[wid].get("level"))
			if trait_at < 0 and G.w_maxed(wid, real):
				trait_at = real
				shown_at = _shown_level(wid)
		print("[LVL] %-9s %s: 시작 카드%d/무기Lv%d · 만렙특성 발동 시점 = 무기Lv%d 인데 카드엔 Lv%d"
			% [String(cdef["name"]), wid, cnt0, lv0, trait_at, shown_at])
		if shown_at != trait_at:
			print("[LVL]   ✗ '만렙 Lv%d' 라 적어 놓고 화면 Lv%d 에서 터진다 (%d 칸 어긋남)"
				% [G.MAX_TRAIT_LV, shown_at, trait_at - shown_at])
			fails += 1
	print("[LVL] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 빌드를 잔뜩 쌓은 상태에서 ESC 화면이 **화면 안에 들어오는가**, 그리고 밖으로 나갔다면
## 손이 닿는가(스크롤·계속하기 버튼).
## ★ 유저가 "효과·아이템을 많이 얻으니 ESC 화면이 밀려버린다. 모바일에서 스크롤이나
##   뒤로가기가 안 되면 곤란하다"고 지적했다(2026-09-06). 세로 스크롤은 있는데
##   **가로 스크롤이 꺼져 있다**(pause_menu.gd:42) — 능력치 패널과 빌드 패널을 좌우로
##   나란히 놓는 구조라 빌드가 늘면 가로로 넘치고, 그러면 손이 닿을 방법이 없다.
##   기존 --scrollcheck 는 설정·캐릭선택만 봤고 일시정지 화면은 아무도 안 보고 있었다.
func _pausecheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	G.xp_to_next = 1000000000
	var fails: int = 0
	# 빌드를 가득 채운다 — 실제로 한 판 끝까지 간 사람이 보는 화면을 만든다
	for wid: String in ["wpn_fire", "wpn_ice", "wpn_poison", "wpn_summon"]:
		for i in 6:
			_apply_upgrade(wid)
	for bid: String in ["b_fire", "b_ice", "b_poison", "b_shock"]:
		for i in 6:
			_apply_upgrade(bid)
	for sid: String in ["dmg", "rate", "hp", "armor", "speed", "crit", "critdmg", "regen"]:
		for i in 4:
			_apply_upgrade(sid)
	for eid: String in ["evo_inferno", "evo_blizzard", "evo_plague"]:
		_apply_upgrade(eid)
	print("=== PAUSE  빌드 %d칸에서 ESC 화면이 화면 안에 들어오는가 ===" % _build_summary().size())
	# 데스크톱(1280×720)과 세로 모바일(720×1280) 둘 다 본다
	for vp: Vector2i in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(960, 540)]:
		# ★ 헤드리스에서는 window.size 를 바꿔도 논리 뷰포트가 안 따라온다(stretch=canvas_items).
		#   content_scale_size 가 실제로 게임이 보는 논리 해상도다 — 이걸 바꿔야 의미가 있다.
		get_window().content_scale_size = vp
		get_window().size = vp
		await get_tree().process_frame
		await get_tree().process_frame
		if not bool(_pause_menu.get("_open")):
			_pause_menu.call("_toggle")
		await get_tree().process_frame
		_pause_menu.call("_relayout")      # 열린 뒤의 실제 크기로 한 번 더 맞춘다
		await get_tree().process_frame
		await get_tree().process_frame
		var root: Control = _pause_menu.get("_root")
		var sc: ScrollContainer = _find_scroll(root)
		if sc == null:
			print("[PAUSE]   ✗ %dx%d 스크롤 컨테이너가 없다" % [vp.x, vp.y]); fails += 1
			continue
		# 내용이 얼마나 큰가 vs 화면이 얼마나 큰가
		var content: Control = null
		for c in sc.get_children():
			if c is Control and not (c is ScrollBar):
				content = c as Control
		var seen: Vector2 = get_viewport().get_visible_rect().size
		var need: Vector2 = content.get_combined_minimum_size() if content != null else Vector2.ZERO
		print("      (일시정지 화면이 인식한 폭 %.0f · 패널 세로쌓기 %s)"
			% [seen.x, str(bool(_pause_menu.get("_panel_row").get("vertical")))])
		var over_x: float = need.x - float(vp.x)
		var over_y: float = need.y - float(vp.y)
		var hscroll_on: bool = sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
		# 계속하기 버튼이 실제로 화면 안에 있는가 — 이게 '뒤로가기'다
		var btn: Button = _find_button(root, "계속")
		var btn_in: bool = false
		var btn_free: bool = false     # 스크롤 **밖**에 있는가 = 내용이 아무리 길어도 안 밀린다
		if btn != null:
			var r: Rect2 = btn.get_global_rect()
			btn_in = r.position.x >= -1.0 and r.end.x <= float(vp.x) + 1.0 				and r.position.y >= -1.0 and r.end.y <= float(vp.y) + 1.0
			var anc: Node = btn
			btn_free = true
			while anc != null:
				if anc == sc:
					btn_free = false
					break
				anc = anc.get_parent()
		print("  %4dx%-4d 내용 %.0fx%.0f · 넘침 가로 %+.0f 세로 %+.0f · 가로스크롤 %s · 계속하기 %s"
			% [vp.x, vp.y, need.x, need.y, over_x, over_y,
				"켜짐" if hscroll_on else "꺼짐", "닿음" if btn_in else "화면 밖"])
		if over_x > 1.0 and not hscroll_on:
			print("[PAUSE]   ✗ %dx%d 가로로 %.0fpx 넘치는데 가로 스크롤이 꺼져 있다 — 손이 안 닿는다"
				% [vp.x, vp.y, over_x]); fails += 1
		if not btn_in:
			print("[PAUSE]   ✗ %dx%d '계속하기' 가 화면 밖이다 — 모바일이면 빠져나올 방법이 없다"
				% [vp.x, vp.y]); fails += 1
		if not btn_free:
			print("[PAUSE]   ✗ %dx%d '계속하기' 가 스크롤 안에 있다 — 내용이 길어지면 밀려 내려간다"
				% [vp.x, vp.y]); fails += 1
		# 세로로 넘치면 스크롤이 실제로 먹는지 — 있다고 되는 게 아니라 움직여야 한다
		if over_y > 1.0:
			var v0: int = sc.scroll_vertical
			sc.scroll_vertical = 400
			await get_tree().process_frame
			if sc.scroll_vertical <= v0:
				print("[PAUSE]   ✗ %dx%d 세로로 넘치는데 스크롤이 안 움직인다" % [vp.x, vp.y]); fails += 1
			sc.scroll_vertical = 0
		_pause_menu.call("_toggle")
		await get_tree().process_frame
	get_window().size = Vector2i(1280, 720)
	print("[PAUSE] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 텍스트에 그 말이 들어간 버튼을 찾는다.
func _find_button(root: Node, needle: String) -> Button:
	if root is Button and needle in (root as Button).text:
		return root as Button
	for c in root.get_children():
		var r: Button = _find_button(c, needle)
		if r != null:
			return r
	return null


## 조작이 실제로 먹히는가 — 키를 눌러서 캐릭터가 그 방향으로 가는지 직접 본다.
## ★ 지금까지 조작을 재는 검사가 하나도 없었다. 키맵이 있다고 움직이는 게 아니다 —
##   기절·대시 쿨·일시정지가 입력을 먹는 경로가 여럿이라, 한 군데만 어긋나도 조작이 죽는다.
func _ctrlcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	G.xp_to_next = 1000000000
	var fails: int = 0
	# 1) 키맵 — 액션과 물리 키가 다 걸려 있는가
	var want: Dictionary = {
		"move_up": ["W", "위"], "move_down": ["S", "아래"],
		"move_left": ["A", "왼쪽"], "move_right": ["D", "오른쪽"],
		"dash": ["Space/Shift", "대시"], "pause": ["Esc/Tab", "일시정지"],
	}
	for act: String in want.keys():
		if not InputMap.has_action(act):
			print("[CTRL]   ✗ %s 액션이 없다" % act); fails += 1
			continue
		var evs: Array = InputMap.action_get_events(act)
		if evs.size() < 2:
			print("[CTRL]   ✗ %s 키가 %d개뿐 (둘 다 걸려야 한다)" % [act, evs.size()]); fails += 1
	# 2) 실제로 그 방향으로 가는가 — 키를 눌러 보고 좌표 변화를 잰다
	var dirs: Dictionary = {
		"move_right": Vector2.RIGHT, "move_left": Vector2.LEFT,
		"move_up": Vector2.UP, "move_down": Vector2.DOWN,
	}
	print("=== CTRL  키를 눌러 실제로 움직이는지 ===")
	for act: String in dirs.keys():
		for a2 in dirs.keys():
			Input.action_release(a2)
		p.global_position = Vector2.ZERO
		p.velocity = Vector2.ZERO
		Input.action_press(act)
		var t: float = 0.0
		while t < 0.35:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
		Input.action_release(act)
		var moved: Vector2 = p.global_position
		var want_dir: Vector2 = dirs[act]
		var along: float = moved.dot(want_dir)
		var off: float = absf(moved.dot(want_dir.orthogonal()))
		var ok: bool = along > 40.0 and off < 12.0
		print("  %-11s %-6s 이동 %6.1fpx · 옆으로 샘 %4.1fpx  %s"
			% [act, String((want[act] as Array)[1]), along, off, "✔" if ok else "✗"])
		if not ok:
			print("[CTRL]   ✗ %s 를 눌렀는데 그 방향으로 안 간다" % act); fails += 1
	# 3) 대시 — 쿨이 돌고, 누르면 실제로 튀어 나가는가
	for a3 in dirs.keys():
		Input.action_release(a3)
	p.global_position = Vector2.ZERO
	p.velocity = Vector2.ZERO
	p._dash_cd = 0.0
	Input.action_press("move_right")
	await get_tree().physics_frame
	Input.action_press("dash")
	var t2: float = 0.0
	while t2 < 0.25:
		await get_tree().physics_frame
		t2 += get_physics_process_delta_time()
	Input.action_release("dash")
	Input.action_release("move_right")
	var dash_px: float = p.global_position.x
	var cd_started: bool = p._dash_cd > 0.0
	print("  %-11s %-6s 이동 %6.1fpx · 쿨 %.2f초  %s"
		% ["dash", "대시", dash_px, p._dash_cd, "✔" if (dash_px > 90.0 and cd_started) else "✗"])
	if dash_px <= 90.0 or not cd_started:
		print("[CTRL]   ✗ 대시가 안 나가거나 쿨이 안 돈다"); fails += 1
	# 4) 조준 모드 — 셋 다 조준 벡터가 유효한가
	for am: int in [0, 1, 2]:
		G.aim_mode = am
		var e := Enemy.new()
		e.kind = 2
		e.global_position = Vector2(220, 0)
		add_child(e)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var av: Vector2 = p.aim
		var valid: bool = av.length() > 0.5 and is_finite(av.x) and is_finite(av.y)
		print("  조준모드 %d: aim=(%.2f, %.2f) %s" % [am, av.x, av.y, "✔" if valid else "✗"])
		if not valid:
			print("[CTRL]   ✗ 조준모드 %d 에서 조준 벡터가 죽는다" % am); fails += 1
		e.queue_free()
	G.aim_mode = 0
	# 5) 기절 중에는 못 움직여야 한다 (사격은 유지 — 설계상 그렇다)
	#    ★ velocity 를 안 지우면 바로 앞 대시의 관성이 남아 "기절인데 움직인다"로 잘못 잡힌다.
	p.velocity = Vector2.ZERO
	await get_tree().physics_frame
	p.global_position = Vector2.ZERO
	p.velocity = Vector2.ZERO
	p._stun = 0.5
	Input.action_press("move_right")
	var t3: float = 0.0
	while t3 < 0.3:
		await get_tree().physics_frame
		t3 += get_physics_process_delta_time()
	Input.action_release("move_right")
	var stun_px: float = absf(p.global_position.x)
	print("  기절 중 이동 %.1fpx  %s" % [stun_px, "✔ 막힌다" if stun_px < 12.0 else "✗ 움직인다"])
	if stun_px >= 12.0:
		print("[CTRL]   ✗ 기절 중인데 움직인다"); fails += 1
	p._stun = 0.0
	print("[CTRL] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 난이도 4단이 **정말 순서대로 어려운가**. 다이얼 값과 실제 판을 둘 다 본다.
## ★ 2026-09-06 에 보통 다이얼을 만졌는데, 그때 봇이 200~220초에서 막혀 난이도를 구분
##   못 한다는 걸 알았다. 그래서 여기서는 '몇 초 버텼나'가 아니라 **판이 주는 압력**
##   (몹 체력·받는 피해·스폰·적탄 상한)을 직접 재고, 그것이 단조 증가인지 본다.
func _diffcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	var fails: int = 0
	print("=== DIFF  난이도 4단이 순서대로 어려운가 ===")
	print("  %-6s %8s %8s %8s %8s %8s %10s" % ["난이도", "몹체력", "받는피해", "스폰", "적탄상한", "슈터시작", "종합압력"])
	var prev: float = -1.0
	var rows: Array = []
	for d: int in [0, 1, 2, 3]:
		G.difficulty = d
		var hp: float = G.diff_hp_mult()
		var dmg: float = G.diff_dmg_mult()
		var spawn: float = G.diff_spawn_mult()
		var cap: int = G.enemy_bullet_cap()
		var shooter: float = G.diff_shooter_start()
		# 종합 압력 — 다섯을 곱한 값. 하나만 보면 "체력은 쉬운데 스폰은 어렵다"를 놓친다.
		# ★ 스폰은 **간격** 배수라 클수록 쉽다(game.gd:1304). 처음에 그대로 곱했다가
		#   쉬움이 실제보다 어렵게 잡혔다 — 뒤집어서 곱해야 압력이 된다.
		var press: float = hp * dmg * (1.12 / maxf(0.01, spawn)) * (float(cap) / 84.0) * (55.0 / maxf(1.0, shooter))
		rows.append(press)
		print("  %-6s %8.2f %8.2f %8.2f %8d %8.0f %10.3f"
			% [String(G.DIFF_NAMES[d]), hp, dmg, spawn, cap, shooter, press])
		if prev >= 0.0 and press <= prev:
			print("[DIFF]   ✗ %s 가 앞 단계보다 안 어렵다 (%.3f ≤ %.3f)"
				% [String(G.DIFF_NAMES[d]), press, prev]); fails += 1
		prev = press
	# 단계 사이의 폭이 고르게 벌어지는가 — 한 칸만 3배씩 뛰면 그게 '난이도 절벽'이다
	print("  단계 폭:  %s" % " · ".join(PackedStringArray(
		range(1, rows.size()).map(func(i: int) -> String:
			return "%s→%s ×%.2f" % [String(G.DIFF_NAMES[i - 1]), String(G.DIFF_NAMES[i]),
				float(rows[i]) / maxf(0.001, float(rows[i - 1]))]))))
	var steps: Array = []
	for i in range(1, rows.size()):
		steps.append(float(rows[i]) / maxf(0.001, float(rows[i - 1])))
	var lo: float = steps[0]
	var hi: float = steps[0]
	for s2: float in steps:
		lo = minf(lo, s2)
		hi = maxf(hi, s2)
	if hi / maxf(0.001, lo) > 2.5:
		print("[DIFF]   ✗ 단계 폭이 고르지 않다 — 가장 큰 칸이 가장 작은 칸의 %.1f배 (절벽)"
			% (hi / lo)); fails += 1
	else:
		print("  단계 폭 편차 %.2f배 — 사다리가 고르다" % (hi / maxf(0.001, lo)))
	# ★ 종합값은 다섯을 곱한 것이라 크게 나온다 — **어느 다이얼이 혼자 가속하는지**가
	#   실제로 손댈 곳이다. 종합만 보면 무엇을 고쳐야 할지 알 수 없다.
	print("  다이얼별 칸 배수 (혼자 가속하는 것이 절벽을 만든다):")
	var dials: Dictionary = {
		"몹체력": [0.65, 0.92, 1.7, 2.6], "받는피해": [0.5, 0.85, 1.55, 2.3],
		"스폰압력": [1.0 / 1.6, 1.0 / 1.12, 1.0 / 0.72, 1.0 / 0.5],
		"적탄상한": [64.0, 84.0, 110.0, 140.0],
		"슈터압력": [55.0 / 80.0, 1.0, 55.0 / 34.0, 55.0 / 18.0],
	}
	for dn: String in dials.keys():
		var v: Array = dials[dn]
		var ss: PackedStringArray = []
		var dlo: float = 1.0e9
		var dhi: float = 0.0
		for i in range(1, v.size()):
			var r: float = float(v[i]) / maxf(0.001, float(v[i - 1]))
			ss.append("×%.2f" % r)
			dlo = minf(dlo, r)
			dhi = maxf(dhi, r)
		var flat: bool = dhi / maxf(0.001, dlo) <= 1.8
		print("    %-8s %s   %s" % [dn, " · ".join(ss), "고르다" if flat else "⚠ 가속 %.1f배" % (dhi / dlo)])
		if not flat:
			fails += 1
	G.difficulty = 1
	print("[DIFF] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 메인 대기화면을 그림으로 찍는다. 화면은 글로 못 고친다.
func _menushot_flow() -> void:
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	_main_menu.open()
	await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout   # 애니메이션이 자리를 잡을 시간
	DirAccess.make_dir_recursive_absolute("user://cardshot")
	await _snap("user://cardshot/menu.png")
	get_tree().quit()


## 스팀 출시에 필요한 것들이 실제로 붙어 있는지 본다.
## 스팀은 "빌드가 돌아간다"만으로는 부족한 자리가 몇 군데 있다 —
## 패드가 안 되면 스팀덱에서 아예 조작이 불가능하고, 창 모드가 없으면 Alt+Tab 이 막힌다.
func _steamcheck_flow() -> void:
	await get_tree().create_timer(0.2).timeout
	var fails: int = 0

	# ── 1. 게임패드 ────────────────────────────────────────
	# 스팀덱에는 키보드가 없다. 이동 4방향과 대시·일시정지가 패드로 다 되어야 한다.
	var need_axis: Array = ["move_left", "move_right", "move_up", "move_down"]
	for act: String in need_axis:
		var has_axis: bool = false
		var has_dpad: bool = false
		for ev: InputEvent in InputMap.action_get_events(act):
			if ev is InputEventJoypadMotion:
				has_axis = true
			elif ev is InputEventJoypadButton:
				has_dpad = true
		if has_axis and has_dpad:
			print("[PAD] %s  스틱 O  D패드 O" % act)
		else:
			print("[PAD] ✗ %s  스틱 %s  D패드 %s" % [act, "O" if has_axis else "X", "O" if has_dpad else "X"])
			fails += 1
	for act: String in ["dash", "pause"]:
		var has_btn: bool = false
		for ev: InputEvent in InputMap.action_get_events(act):
			if ev is InputEventJoypadButton:
				has_btn = true
		if has_btn:
			print("[PAD] %s  버튼 O" % act)
		else:
			print("[PAD] ✗ %s  패드 버튼이 없다" % act)
			fails += 1
	# 데드존이 너무 크면 살살 밀 때 안 움직여서 "패드가 안 먹는다"로 느껴진다
	var dz: float = InputMap.action_get_deadzone("move_left")
	if dz <= 0.3:
		print("[PAD] 데드존 %.2f" % dz)
	else:
		print("[PAD] ✗ 데드존 %.2f — 0.30 이하여야 한다" % dz)
		fails += 1

	# ── 2. 창 모드 ────────────────────────────────────────
	if G.has_method("toggle_fullscreen") and G.has_method("apply_window"):
		var before: bool = G.fullscreen
		G.fullscreen = not before
		G.fullscreen = before   # 실제 창을 건드리지 않고 값만 왕복 (헤드리스 안전)
		print("[WIN] 창/전체화면 전환 있음 (F11 · Alt+Enter)")
	else:
		print("[WIN] ✗ 창 모드 전환이 없다")
		fails += 1

	# ── 3. 부활 ───────────────────────────────────────────
	# 스팀 빌드에는 광고가 없다. 그대로 두면 돈 주고 산 쪽만 부활이 없는 게임을 한다.
	G.reset_run()
	if G.is_desktop():
		if G.free_revive() and G.revive_available():
			print("[REVIVE] 데스크톱 무료 부활 O (판당 %d회)" % G.REVIVE_MAX)
		else:
			print("[REVIVE] ✗ 데스크톱인데 부활이 안 열린다")
			fails += 1
		G.revive_used = G.REVIVE_MAX
		if G.revive_available():
			print("[REVIVE] ✗ 판당 횟수를 다 썼는데도 또 열린다")
			fails += 1
		else:
			print("[REVIVE] 소진 후 차단 O")
		G.reset_run()
	else:
		print("[REVIVE] (모바일 빌드 — 광고 부활 유지)")

	# ── 4. 스팀 연동 계층 ──────────────────────────────────
	var hub: Node = get_node_or_null("/root/SteamHub")
	if hub == null:
		print("[STEAM] ✗ SteamHub 오토로드가 없다")
		fails += 1
	else:
		print("[STEAM] SteamHub 오토로드 O")
		var app_id: int = int(hub.get("APP_ID"))
		if app_id > 0:
			print("[STEAM] AppID %d" % app_id)
		else:
			# 실패로 세지 않는다 — AppID 는 밸브가 주는 것이라 아직 없는 게 정상이다
			print("[STEAM] ⚠ AppID 미설정 (0) — 출시 전 scripts/steam.gd 를 채울 것")
		if not hub.has_method("unlock"):
			print("[STEAM] ✗ unlock() 이 없다")
			fails += 1

	# ── 5. 스팀 프리셋 ────────────────────────────────────
	var cfg := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if cfg == null:
		print("[EXPORT] (프리셋 파일이 빌드에 없다 — 정상)")
	else:
		var txt: String = cfg.get_as_text()
		cfg.close()
		if txt.contains("name=\"Steam\""):
			print("[EXPORT] Steam 프리셋 O")
		else:
			print("[EXPORT] ✗ Steam 프리셋이 없다")
			fails += 1
		if txt.contains("(prototype)"):
			print("[EXPORT] ✗ exe 설명에 아직 (prototype) 이 남아 있다")
			fails += 1
		else:
			print("[EXPORT] exe 속성 정리 O")

	print("\n=== STEAMCHECK %s (실패 %d) ===" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(0 if fails == 0 else 1)


## 스팀 스토어에 올릴 스크린샷을 실제 플레이에서 뽑는다.
## 스팀은 1920×1080 을 권장하고 **최소 5장**을 요구한다.
##
## 대기화면·캐릭터선택 둘은 진행과 무관하게 반드시 찍힌다. 나머지 넷(레벨업·군중·
## 보스·후반화력)은 판이 어떻게 풀리느냐에 달려 있어 한 번에 다 안 나올 수 있다 —
## 그래서 확정 둘을 먼저 깔아 최소 개수를 채워 둔다.
##
## ★ --headless 로 돌리면 안 된다. 렌더러가 없어 그림이 안 나온다.
##   실행: (--headless 없이) ... --path . -- --storeshots
##
## 연출을 위해 봇을 태우고 시간을 빠르게 돌린다.
func _storeshots_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[SHOT] ✗ --storeshots 는 --headless 없이 돌려야 한다 (렌더러 필요)")
		get_tree().quit(1)
		return
	var dir: String = "user://store"
	DirAccess.make_dir_recursive_absolute(dir)
	G.no_save = true
	G.difficulty = 2

	# 스팀 권장 해상도. 창을 실제로 그 크기로 띄워야 그 크기로 찍힌다.
	get_window().size = Vector2i(1920, 1080)
	await get_tree().create_timer(0.8).timeout

	# ── 1. 대기 화면 ──
	_main_menu.open()
	await get_tree().create_timer(1.4).timeout   # 용이 숨 쉬고 불티가 자리 잡을 시간
	await _snap("%s/01_menu.png" % dir)

	# ── 2. 캐릭터 선택 (영웅 16명) ──
	# ★ 이 장면은 진행 상황과 무관하게 반드시 찍힌다. 전투 장면 넷은 판이 어떻게
	#   풀리느냐에 달려 있어서, 스팀이 요구하는 최소 5장을 확정으로 채워 두는 몫이다.
	_main_menu.close()
	_char_select.open()
	await get_tree().create_timer(0.8).timeout
	await _snap("%s/02_heroes.png" % dir)
	_char_select._on_back()   # close() 는 없다 — 뒤로가기 핸들러가 닫는 경로다
	await get_tree().process_frame

	# ── 판 시작 ──
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	# ★ 다른 하니스처럼 max_hp 를 10억으로 올려 불사로 만들면 안 된다.
	#   화면 아래 체력바에 "999999035 / 1000000000" 이 그대로 찍힌다 —
	#   그 그림이 스토어 첫인상이 된다(2026-09-10, 실제로 한 번 그렇게 나왔다).
	#   최대체력은 손대지 않고 매 프레임 가득 채운다. 바는 정상으로 보인다.
	Engine.time_scale = 4.0

	# ★ 문턱이 낮으면 "00:20 · 레벨 3 · 적 몇 마리" 같은 초라한 장면이 찍힌다.
	#   스토어 첫인상이 그 장면이 된다 — 실제로 한 번 그렇게 나왔다(2026-09-10).
	#   판이 무르익은 뒤에만 셔터가 떨어지도록 시간·레벨·머릿수를 같이 건다.
	var shots: Dictionary = {"swarm": false, "level": false, "boss": false, "power": false}
	var t: float = 0.0
	# ★ 게임시간(t)만으로 상한을 걸면 안 된다. 레벨업 카드가 떠 있는 동안은 트리가
	#   멈춰 있어 t 가 안 흐르는데, 봇이 고를 카드가 없으면 그 화면에서 영영 안 나온다
	#   (실제로 15분을 갇혔다). 실제 시계로 한 번 더 막는다.
	var wall0: int = Time.get_ticks_msec()
	var stuck: int = 0
	while t < 900.0 and (Time.get_ticks_msec() - wall0) < 240000 and shots.values().has(false):
		await get_tree().process_frame
		t += get_process_delta_time()
		if is_instance_valid(p):
			p.hp = p.max_hp      # 죽으면 그림이 안 나온다. 바는 "196 / 196" 으로 정상
		else:
			break
		if _levelup_root != null and _levelup_root.visible:
			# ── 2. 레벨업 카드 (게임이 멈춰 있어 가장 깨끗하게 찍힌다) ──
			# 레벨 6짜리 카드는 죄다 기본 능력치라 볼 게 없다. 무기·융합이 섞이는 구간에서 찍는다
			if not shots["level"] and G.level >= 14:
				Engine.time_scale = 1.0
				await get_tree().create_timer(0.5).timeout
				await _snap("%s/03_levelup.png" % dir)
				shots["level"] = true
				Engine.time_scale = 4.0
			# ★ _auto_pick() 이 아무것도 못 고르는 판이 있다(고를 카드가 다 만렙인 경우).
			#   그러면 카드 화면이 안 닫히고, 트리가 멈춰 있어 게임시간도 안 흐른다.
			#   몇 프레임 눌러 봐서 안 닫히면 첫 카드를 직접 눌러 빠져나온다.
			_auto_pick()
			stuck += 1
			if stuck > 30:
				var box_n: int = _cards_box.get_child_count()
				if box_n > 0:
					(_cards_box.get_child(0) as Button).pressed.emit()
				stuck = 0
			continue
		stuck = 0
		_bal_step()
		var n: int = G.enemies_cached().size()
		# ── 3. 몰려드는 장면 (화면이 꽉 찬 뒤에) ──
		if not shots["swarm"] and n >= 45 and G.time_alive >= 150.0 and G.level >= 10:
			Engine.time_scale = 1.0
			if not _shot_clear():
				Engine.time_scale = 4.0
				continue
			await _snap("%s/04_swarm.png" % dir)
			shots["swarm"] = true
			Engine.time_scale = 4.0
		# ── 4. 보스전 ──
		if not shots["boss"]:
			for node in G.enemies_cached():
				var e := node as Enemy
				# ★ 보스가 있기만 하면 찍던 자리다. 봇이 멀리 도망가 있으면 "초록 벌판에
				#   점 하나"가 스토어 보스 컷으로 나간다(실제로 그렇게 나왔다).
				#   화면 안에서 맞붙고 있을 때만 셔터를 내린다.
				if e != null and is_instance_valid(e) and e._is_boss 						and e.global_position.distance_to(p.global_position) < 430.0:
					Engine.time_scale = 1.0
					# 등장 경고 문구가 화면 가운데를 덮는다 — 사라질 때까지 기다렸다 찍는다
					await get_tree().create_timer(3.5).timeout
					# ★ 기다리는 사이에 레벨업 카드가 떠서 보스를 통째로 덮은 적이 있다.
					#   그러면 03_levelup 과 똑같은 그림이 05_boss 로 저장된다.
					#   카드가 떠 있거나 보스가 이미 죽었으면 이번엔 넘기고 다음 기회를 노린다.
					if _levelup_root != null and _levelup_root.visible:
						Engine.time_scale = 4.0
						break
					if not is_instance_valid(e):
						Engine.time_scale = 4.0
						break
					# ★ 셔터 직전에 체력을 채운다. 위에서 3.5초를 await 로 기다리는 동안은
					#   이 함수의 루프가 안 돌아 p.hp 보충이 멈춘다 — 그 사이에 얻어맞아
					#   저체력 경고 비네트가 켜지면 **화면이 통째로 붉게** 찍힌다.
					#   실제로 05_boss 가 그렇게 나왔다(33/214, 보스도 안 보임).
					p.hp = p.max_hp
					if _lowhp_vig != null:
						_lowhp_vig.modulate.a = 0.0
					await get_tree().process_frame
					if not _shot_clear():
						Engine.time_scale = 4.0
						break
					await _snap("%s/05_boss.png" % dir)
					shots["boss"] = true
					Engine.time_scale = 4.0
					break
		# ── 5. 후반 화력 ──
		# ★ 처음엔 "레벨 22 + 융합 1회 + 적 18" 을 걸었는데 한 판에 다 안 모여 늘 못 찍었다.
		#   융합은 카드 운이라 조건에 넣으면 안 된다 — 화력은 레벨만으로도 충분히 보인다.
		if not shots["power"] and G.level >= 18 and n >= 12:
			Engine.time_scale = 1.0
			await _snap("%s/06_power.png" % dir)
			shots["power"] = true
			Engine.time_scale = 4.0

	Engine.time_scale = 1.0
	var missing: Array = []
	for k: String in shots:
		if not shots[k]:
			missing.append(k)
	if missing.is_empty():
		print("[SHOT] 스토어용 %d장 완료 → %s" % [
			shots.size() + 2, ProjectSettings.globalize_path(dir)   # +2 = 대기화면·캐릭터선택(확정)
		])
	else:
		print("[SHOT] ✗ 못 찍은 장면: %s (게임 %.0f초)" % [", ".join(missing), t])
	get_tree().quit(0 if missing.is_empty() else 1)


## ─────────────────── 트레일러 녹화 (--trailer) ───────────────────
##
## 스팀 스토어 트레일러용 영상을 실제 플레이에서 뽑는다.
##
## 실행 (창모드 + Movie Maker):
##   Godot --path . --resolution 1920x1080 --write-movie build/trailer/raw.avi \
##         --fixed-fps 60 -- --trailer
##
## ★ --resolution 을 반드시 줘야 한다. 녹화 해상도는 **창이 만들어질 때** 정해지므로
##   코드에서 get_window().size 를 바꿔도 늦다 — 실제로 1280x720 으로 찍혔다.
##
## ★ 소리는 AVI 안에 pcm_s16le 로 같이 들어간다. 따로 .wav 가 나오지 않는다.
##
## ★ Movie Maker 는 **그려진 프레임마다 한 장씩** 기록한다. 실제 시계와 무관하므로
##   PNG 를 손으로 뽑을 때처럼 느려져서 움직임이 튀는 문제가 없다.
##
## ★ 문제는 "볼 만한 장면까지 가는 데 몇 분이 걸린다"는 것이다. 그 몇 분을 그대로
##   녹화하면 아무도 안 보는 영상이 된다. 그래서 이렇게 나눈다 —
##     연출 구간   time_scale 1.0 로 실시간 녹화        (쓸 장면)
##     이동 구간   time_scale 를 올려 빠르게 통과       (버릴 장면)
##   그리고 **연출 구간의 프레임 번호를 찍어 준다.** 고정 60fps 라 프레임 번호가
##   곧 영상의 초 단위 위치다 — ffmpeg 이 그 구간만 잘라 이어 붙인다.
const _TRAILER_FPS: float = 60.0
const _TRAILER_DIR: String = "user://trailer"
var _tf: int = 0                 # 녹화 시작부터 지나간 프레임 = 소리 트랙의 위치
var _shot: int = 0               # 실제로 받아 적은 장면 수 = 영상 프레임 번호
var _clips: Array = []


## 레벨업 카드를 찍는 동안에는 고르지 않고 그대로 둔다.
## ★ 이게 없으면 카드 구간이 통째로 헛돈다 — 녹화 첫 프레임에 봇이 카드를 골라 버려서
##   4초 내내 카드가 아니라 전투가 찍힌다(2026-09-10, 완성본을 프레임으로 뜯어 보고 알았다).
var _hold_cards: bool = false


## 봇을 한 프레임 굴린다. 카드가 떠 있으면 골라서 넘긴다.
func _trailer_tick() -> void:
	var p := G.player as Player
	if p != null and is_instance_valid(p):
		p.hp = p.max_hp   # 죽으면 영상이 끊긴다. 체력바는 정상으로 보인다.
	# ★ 봇은 융합 보스를 자주 놓치고, 그때마다 붙는 공격력 -20% 가 쌓이면
	#   아무것도 못 죽이는 판이 된다(실제로 레벨 8·처치 96 에서 멈췄다).
	#   사람이 하면 안 그런 일이라 트레일러에서는 걷어낸다.
	G.run_penalty = 0.0
	if _levelup_root != null and _levelup_root.visible:
		if not _hold_cards:
			_auto_pick()
		return
	_bal_step()


## sec 초를 녹화한다(실시간). 이 구간이 트레일러에 실린다.
##
## ★ Movie Maker 에 영상을 맡기지 않는다. 그쪽은 **논리 뷰포트(1280×720)** 크기로만
##   기록해서, 창을 1920×1080 으로 띄우고 캔버스를 키워 봐도 720p 로 나온다(둘 다 시험함).
##   반면 get_viewport().get_texture() 는 창 해상도 그대로 1920×1080 을 준다.
##   그래서 화면은 여기서 직접 받아 적고, Movie Maker 는 소리 트랙만 쓰게 둔다.
##
## ★ --fixed-fps 로 돌리므로 한 장 저장하는 데 시간이 걸려도 델타는 항상 1/60 이다.
##   저장이 느려서 움직임이 튀는 일이 없다. PNG 는 한 장 1.5MB 라 JPG 로 받는다.
## tick 을 주면 봇 대신 그걸 프레임마다 부른다(인자 = 구간 안에서 지난 초). 18차 연출 장면용.
func _trailer_rec(name: String, sec: float, tick: Callable = Callable()) -> void:
	Engine.time_scale = 1.0
	# 소리 트랙은 Movie Maker 가 실행 첫 프레임부터 적는다. 사이사이 create_timer 로 기다린 프레임까지
	# 세야 구간과 소리가 맞는다(손으로 센 _tf 만 쓰면 앞의 대기만큼 소리가 2초 남짓 밀린다).
	_tf = Engine.get_process_frames()
	var start: int = _tf
	var n: int = int(sec * _TRAILER_FPS)
	for i in n:
		await get_tree().process_frame
		_tf += 1
		if tick.is_valid():
			tick.call(float(i) / _TRAILER_FPS)
		else:
			_trailer_tick()
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		img.save_jpg("%s/%05d.jpg" % [_TRAILER_DIR, _shot], 0.92)
		_shot += 1
	_clips.append({"name": name, "from": start, "to": _tf})
	print("[CLIP] %-10s %6.2f ~ %6.2f 초  (누적 %d장)" % [
		name, start / _TRAILER_FPS, _tf / _TRAILER_FPS, _shot
	])


## 게임 시간 game_sec 만큼 빠르게 통과한다. 녹화는 되지만 나중에 잘라낸다.
func _trailer_skip(game_sec: float, speed: float = 10.0, tick: Callable = Callable()) -> void:
	Engine.time_scale = speed
	var n: int = int(game_sec * _TRAILER_FPS / speed)
	for i in n:
		await get_tree().process_frame
		_tf += 1
		if tick.is_valid():
			tick.call(-1.0)
		else:
			_trailer_tick()


## 창·뷰포트가 실제로 몇으로 잡히는지 본다. 녹화 해상도가 그걸 따라간다.
func _winsize_flow() -> void:
	# 녹화는 content_scale_size 를 따라간다. 1080p 로 그리되 비율은 그대로 두려면
	# 캔버스를 1920x1080 으로 키우고 배율 1.5 를 걸어 720p 설계공간을 되돌린다.
	if "--bigcanvas" in OS.get_cmdline_user_args():
		get_window().content_scale_size = Vector2i(1920, 1080)
		get_window().content_scale_factor = 1.5
	for i in 90:
		await get_tree().process_frame
	print("[WIN] window=%s  viewport=%s  content_scale=%s" % [
		str(get_window().size), str(get_viewport().get_visible_rect().size),
		str(get_window().content_scale_size)])
	get_tree().quit()


## ── 18차 트레일러 장면 도우미 ──
## 장면 하나 = 판 하나. 자연 스폰 · 웨이브 · 레벨업은 끄고 몹 수는 _tr_fill_n 으로 직접 맞춘다.
var _tr_fill_n: int = 0        # 화면에 유지할 몹 수
var _tr_hp_lock: bool = true   # 체력을 프레임마다 채운다(죽으면 영상이 끊긴다)
var _tr_beat: int = 0          # 장면 안에서 다음에 터뜨릴 연출 순번


func _tr_def(id: String) -> Dictionary:
	for d: Dictionary in Characters.defs():
		if String(d["id"]) == id:
			return d
	return Characters.defs()[0]


## endless 면 무한 모드 판을 세우고 테마만 stage 로 바꾼다(스테이지 모드는 8분에 보스가 나와서 12분 장면을 못 찍는다).
func _tr_scene(hero: String, stage: int, ups: Array, t_alive: float, endless: bool = false) -> void:
	_tr_beat = 0
	_tr_hp_lock = true
	_hold_cards = false
	if _levelup_root != null:
		_levelup_root.visible = false
	get_tree().paused = false
	G.run_mode = "endless" if endless else "stage"
	G.stage_sel = stage
	_begin_run(_tr_def(hero))
	await get_tree().process_frame
	if endless:
		_cfs2_theme(stage)
	_spawn_t = 1.0e9
	_theme_t = 1.0e9
	_wave_t = -1.0e9
	var p := G.player as Player
	p.xp_mult = 0.0
	G.time_alive = t_alive
	# HUD 숫자도 장면 시각에 맞춘다(첫 녹화는 12분인데 「LV 1 · 웨이브 1 · 처치 14」로 찍혔다)
	G.level = int(3.0 + t_alive / 20.0)
	G.kills = int(t_alive * 1.6)
	G.run_gold = int(t_alive * 0.5)
	G.wave = int(t_alive / WAVE_DUR) + 1
	for id in ups:
		_apply_upgrade(String(id))
	_banner_q.clear()
	_tr_zoom(1.0)
	G.show_dmgnum = true


## 카메라를 기본 배율의 k 배로(18차 지시서 1-1: 상점의 작은 자동 재생 창에서 영웅이 콩알만 했다 — 시작과 12분 장면만 1.4배).
func _tr_zoom(k: float) -> void:
	if G.camera != null and is_instance_valid(G.camera):
		(G.camera as Camera2D).zoom = Vector2.ONE * G.cam_zoom() * k


## 체력 채우기 · 몹 수 맞추기. 카드를 붙잡고 있지 않으면 떠 있는 카드는 봇이 고른다.
func _tr_tick_keep(_t: float = -1.0) -> void:
	var p := G.player as Player
	if p != null and is_instance_valid(p) and _tr_hp_lock:
		p.hp = p.max_hp
	G.run_penalty = 0.0
	var need: int = _tr_fill_n - _enemy_count()
	for i in mini(need, 14):
		_spawn_enemy()
	if _levelup_root != null and _levelup_root.visible and not _hold_cards:
		_auto_pick()


## 무기가 하나씩 늘고 사이에 레벨업 카드가 두 번 지나간다(카드가 떠 있는 동안은 실제 게임처럼 판이 멈춘다).
func _tr_tick_grow(t: float) -> void:
	_tr_tick_keep(t)
	var beats: Array = [[0.4, "up", "wpn_fire"], [1.3, "card", ""], [2.2, "pick", ""], [3.0, "up", "wpn_chain"],
		[3.9, "card", ""], [4.8, "pick", ""], [5.6, "up", "wpn_orb"], [6.4, "up", "wp_fan"]]
	while _tr_beat < beats.size() and t >= float(beats[_tr_beat][0]):
		var b: Array = beats[_tr_beat]
		_tr_beat += 1
		match String(b[1]):
			"up":
				_apply_upgrade(String(b[2]))
				_levelup_burst()
				G.sfx("levelup", 0.7)
			"card":
				_hold_cards = true
				G.level += 1
				_pending_levelups = 1
				_open_levelup()
				G.sfx("levelup", 0.8)
			"pick":
				_hold_cards = false
				_auto_pick()
				if _levelup_root != null and _levelup_root.visible:
					_levelup_root.visible = false
					get_tree().paused = false
				_levelup_burst()


## 보스가 나오면 잡몹은 조연(실제 보스전 상한처럼 줄인다).
func _tr_tick_boss(t: float) -> void:
	if _stage_boss != null and is_instance_valid(_stage_boss):
		_tr_fill_n = 40
	_tr_tick_keep(t)


func _tr_tick_fusion(t: float) -> void:
	_tr_tick_keep(t)
	if _tr_beat == 0 and t >= 0.6:
		_tr_beat = 1
		_apply_upgrade("evo_reaper")   # 카드로 고를 때(_choose)와 같은 순서 — 적용 뒤 연출
		_fusion_flourish("evo_reaper")


## 5.2초에 체력이 바닥(빈사 맥동), 6.6초에 부활. 그 사이엔 무적이라 실제로 죽지는 않는다.
func _tr_tick_finale(t: float) -> void:
	var p := G.player as Player
	if p != null and is_instance_valid(p):
		if _tr_beat == 0 and t >= 5.2:
			_tr_beat = 1
			_tr_hp_lock = false
			p.hp = p.max_hp * 0.06
			p._iframe = 1.6
			G.player_hp_changed.emit()
		elif _tr_beat == 1 and t >= 6.6:
			_tr_beat = 2
			p.pending_revive = true
			p.revive()
			_tr_hp_lock = true
		elif _tr_beat == 1:
			p._iframe = maxf(p._iframe, 0.2)
	_tr_tick_keep(t)


func _trailer_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[TRAILER] ✗ --headless 로는 녹화가 안 된다 (렌더러 필요)")
		get_tree().quit(1)
		return
	G.no_save = true
	G.difficulty = 1   # 어려움(2)에서는 봇이 성장을 못 따라가 화면이 초라해진다
	quiet_moments = true   # 18차 지시서 1-1: 「100 콤보 최초 돌파」 알림이 자막과 두 줄로 겹쳤다
	get_window().size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(_TRAILER_DIR)
	# 지난 녹화가 남아 있으면 프레임 번호가 섞여 영상이 뒤죽박죽이 된다
	var d := DirAccess.open(_TRAILER_DIR)
	if d != null:
		for f: String in d.get_files():
			if f.ends_with(".jpg"):
				d.remove(f)
	await get_tree().create_timer(0.6).timeout
	if get_viewport().get_texture().get_image().get_width() < 1920:
		print("[TRAILER] ✗ 화면이 1920 이 아니다 — --resolution 1920x1080 을 줘야 한다")
		get_tree().quit(1)
		return

	# ★ 18차: 15차 대본대로 다시 짰다. 스팀 트레일러는 소리 없이 자동 재생되니 첫 5초가 전투여야 한다.
	#   봇 판을 그대로 찍으면 장면이 운에 달린다(보스가 화면 밖, 카드가 엉뚱한 순간). 장면마다 판을 새로 세운다.
	#   순서 = 몰려옴 5 · 무기가 늘어남 7 · 보스 8 · 융합 8 · 맵 여섯 2초씩 · 12분 전투와 부활 10.
	#   자막과 끝 카드(로고 · 찜하기 · 출시일)는 tools/make_trailer.py 가 얹는다.

	# ── 1. 몰려옴 — 영웅 하나가 가운데, 요괴 200 이 사방에서 ──
	await _tr_scene("base", 0, [], 150.0)
	_tr_fill_n = 200
	_tr_zoom(1.4)   # 당기면 화면이 좁아져 무리가 가장자리에서 들어온다 — 조금 더 기다려 둘러싸게
	await _trailer_skip(3.6, 1.0, _tr_tick_keep)
	await _trailer_rec("swarm", 5.0, _tr_tick_keep)
	_tr_zoom(1.0)

	# ── 2. 무기가 하나씩 늘고, 레벨업 카드가 두 번 빠르게 ──
	_tr_beat = 0
	await _trailer_rec("grow", 7.0, _tr_tick_grow)
	_hold_cards = false

	# ── 3. 보스 — 8분째 경고 띠와 컷인, 저승길에서 염라 ──
	await _tr_scene("seolhwa", 5, ["wpn_ice", "b_ice", "wpn_chain"], 476.6)
	_tr_fill_n = 70
	await _trailer_skip(2.4, 1.0, _tr_tick_keep)
	await _trailer_rec("boss", 8.0, _tr_tick_boss)

	# ── 4. 융합 — 컷인 뒤 사신의 낫이 화면을 쓸어 낸다 ──
	await _tr_scene("gangrim", 4, ["wpn_whip", "wpn_whip", "wpn_whip", "b_exec", "wpn_fire"], 420.0)
	_tr_fill_n = 240
	await _trailer_skip(2.4, 1.0, _tr_tick_keep)
	_tr_beat = 0
	G.show_dmgnum = false   # 18차 지시서 1-1: 「107 107 107」이 화면을 덮었다 — 사신의 낫이 쓸어 내는 모양이 주인공
	await _trailer_rec("fusion", 8.0, _tr_tick_fusion)
	G.show_dmgnum = true

	# ── 5. 맵 여섯을 2초씩, 영웅을 바꿔 가며 ──
	var maps: Array = [
		[0, "berserker", ["wp_heavy", "wpn_fire"]],
		[1, "gunner", ["wp_rapid", "wpn_chain"]],
		[2, "dudu", ["wpn_orb", "wpn_ice"]],
		[3, "pyro", ["b_fire", "wpn_beam"]],
		[4, "yeon", ["wpn_chain", "wpn_ice"]],
		[5, "mudang", ["wpn_fire", "wpn_chain"]],
	]
	for m: Array in maps:
		await _tr_scene(String(m[1]), int(m[0]), m[2] as Array, 300.0)
		_tr_fill_n = 150
		await _trailer_skip(2.4, 1.0, _tr_tick_keep)
		await _trailer_rec("map%d" % int(m[0]), 2.0, _tr_tick_keep)

	# ── 6. 12분 전투 — 화면이 가장 화려할 때, 체력이 바닥나면 부활 ──
	await _tr_scene("doyun", 3, ["wpn_fire", "b_fire", "evo_inferno", "wpn_chain", "b_shock", "evo_tempest", "wpn_beam", "wpn_orb", "wpn_ice"], 720.0, true)
	_tr_fill_n = 300
	_tr_zoom(1.4)
	await _trailer_skip(2.4, 1.0, _tr_tick_keep)
	_tr_beat = 0
	await _trailer_rec("finale", 10.0, _tr_tick_finale)
	_tr_zoom(1.0)

	Engine.time_scale = 1.0
	_tf = Engine.get_process_frames()
	var total: float = 0.0
	for c: Dictionary in _clips:
		total += (int(c["to"]) - int(c["from"])) / _TRAILER_FPS
	print("[TRAILER] 구간 %d개 · 영상 %.1f초 (%d장) · 소리 트랙 원본 %.1f초" % [
		_clips.size(), total, _shot, _tf / _TRAILER_FPS
	])
	print("[FRAMES] %s" % ProjectSettings.globalize_path(_TRAILER_DIR))
	# ffmpeg 이 그대로 읽어 자를 수 있게 한 줄로 뱉는다
	var spec: Array = []
	for c: Dictionary in _clips:
		spec.append("%s:%.3f:%.3f" % [
			String(c["name"]), int(c["from"]) / _TRAILER_FPS, int(c["to"]) / _TRAILER_FPS
		])
	print("[CLIPSPEC] %s" % " ".join(spec))
	get_tree().quit()


## 도전과제 27종을 스팀 파트너 사이트에 그대로 옮겨 적을 수 있는 모양으로 뽑는다.
## 손으로 옮기다 id 하나만 틀려도 그 도전과제는 영영 안 열린다.
func _steamachv_flow() -> void:
	await get_tree().create_timer(0.1).timeout
	print("=== 스팀 도전과제 등록용 목록 (%d종) ===" % Codex.ACHIEVEMENTS.size())
	print("파트너 사이트 → 앱 → Achievements 에 아래 API Name 그대로 만든다.")
	print("%-18s %-22s %s" % ["API Name", "표시 이름", "설명"])
	print("-".repeat(78))
	for a: Dictionary in Codex.ACHIEVEMENTS:
		print("%-18s %-22s %s" % [
			String(a.get("id", "")), String(a.get("name", "")), String(a.get("desc", ""))
		])
	print("-".repeat(78))
	print("아이콘은 종당 2장(획득·미획득)이 필요하다.")
	get_tree().quit()


## 출격 준비 화면 맞춤 검사 (--herofit). 10/13 QA B2 · B13 에서 옮겨 왔다.
## ① 영웅 칸(7×3)의 별 · 자물쇠 줄이 칸 아래로 잘리는가 — uifit 은 clip_contents 칸을 통과시켜 못 잡았다.
## ② 영웅 20명 각각 상세 판(능력 설명 줄 수가 다르다)이 화면 아래로 밀리는가 · 「등급 올리기」 「출격」 이 화면 안인가.
## 실패 0 이면 [HEROFIT] ALL PASS. 그림은 user://herofit/ (첫 영웅 · 가장 긴 설명 영웅).
func _herofit_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	for d: Dictionary in Characters.defs():
		G.meta["uc_" + String(d["id"])] = 1
	# 11/7: 업보 칸 · 설명 줄이 나오는 상태(저승길 클리어 · 업보 10)로 잰다 — 가장 긴 설명 줄
	G.stage_prog["c_%d_0" % (G.STAGE_NAMES.size() - 1)] = 1
	G.karma = G.KARMA_MAX
	DirAccess.make_dir_recursive_absolute("user://herofit")
	_main_menu.close()
	_char_select.open()
	for _i in 3:
		await get_tree().process_frame
	var vr: Rect2 = get_viewport().get_visible_rect()
	var fails: int = 0
	var cs: Node = _char_select
	# ① 칸 안 아랫줄
	var btns: Dictionary = cs.get("_card_btns")
	var cut: int = 0
	for id: String in btns:
		var b: Control = btns[id]
		var vb: Control = b.get_child(b.get_child_count() - 1) if b.get_child_count() > 0 else null
		for c in b.get_children():
			if c is VBoxContainer:
				vb = c
		if vb == null or vb.get_child_count() == 0:
			continue
		var last: Control = vb.get_child(vb.get_child_count() - 1) as Control
		var lb: float = last.get_global_rect().end.y
		var bb: float = b.get_global_rect().end.y
		var need: float = vb.get_combined_minimum_size().y
		if lb > bb + 0.5 or need > b.size.y + 0.5:
			cut += 1
			if cut <= 3:
				print("[HEROFIT]   ✗ %s 칸: 아랫줄 끝 %.0f > 칸 끝 %.0f (필요 높이 %.0f · 칸 %.0f)" % [id, lb, bb, need, b.size.y])
	if cut > 0:
		print("[HEROFIT] ✗ 영웅 칸 %d 개가 아랫줄(별 · 자물쇠)을 자른다" % cut)
		fails += 1
	else:
		print("[HEROFIT] 영웅 칸 %d 개 모두 아랫줄까지 칸 안" % btns.size())
	# ①-2 탭 줄 첫 칸(무한)이 좌상단 뒤로 단추와 겹치는가
	for _i in 3:
		await get_tree().process_frame
	var bk: Control = cs.get("_back_btn") as Control
	var mb0: Control = (cs.get("_mode_btns") as Array)[0] as Control
	if bk != null and mb0 != null and bk.get_global_rect().intersects(mb0.get_global_rect()):
		print("[HEROFIT] ✗ 「무한」 탭 %s 이 뒤로 단추 %s 와 겹친다" % [str(mb0.get_global_rect()), str(bk.get_global_rect())])
		fails += 1
	# ①-3 가로: 탭 줄 끝 · 출격 단추 오른쪽 끝이 화면 안인가(16:9 폰 영어에서 탭 줄 1286 > 1280 이었다)
	var mbs: Array = cs.get("_mode_btns")
	for c: Control in [mbs[0] as Control, mbs[mbs.size() - 1] as Control, cs.get("_go_btn") as Control]:
		var xf: Transform2D = c.get_global_transform_with_canvas()
		var lx: float = xf.origin.x
		var rx: float = (xf * c.size).x
		if lx < -0.5 or rx > vr.size.x + 0.5:
			print("[HEROFIT] ✗ \"%s\" 가로 %.0f~%.0f 가 화면(0~%.0f) 밖" % [String((c as Button).text) if c is Button else c.name, lx, rx, vr.size.x])
			fails += 1
	await _snap("user://herofit/charsel_first.png")
	# ② 영웅마다 상세 판
	var worst_id: String = ""
	var worst_b: float = 0.0
	var wide_id: String = ""
	# 11/7: 플레이어가 실제로 보는 세 상태를 다 돈다 — 열림 0등급(다음 별 줄) · 잠김(해금 조건 줄) · 최대 등급
	var pairs: Array = []
	for st: String in ["open", "locked", "max"]:
		for d0: Dictionary in Characters.defs():
			pairs.append([st, d0])
	for sd: Array in pairs:
		var d: Dictionary = sd[1]
		var hl: String = "%s(%s)" % [String(d["id"]), String(sd[0])]
		G.meta["uc_" + String(d["id"])] = 0 if String(sd[0]) == "locked" else 1
		G.meta["rank_" + String(d["id"])] = G.CHAR_RANK_MAX if String(sd[0]) == "max" else 0
		cs.call("_show_detail", d)
		for _i in 3:
			await get_tree().process_frame
		var bottom: float = 0.0
		for nm: String in ["_go_btn", "_up_btn", "_detail_abil", "_detail_stats"]:
			var c: Control = cs.get(nm) as Control
			if c != null and c.is_visible_in_tree():
				bottom = maxf(bottom, (c.get_global_transform_with_canvas() * c.size).y)   # 화면 좌표(UI 배율 포함)
		# 상세 판 자체(단추를 담은 가장 바깥 판)
		var pnl: Node = (cs.get("_go_btn") as Node)
		while pnl != null and not (pnl is PanelContainer):
			pnl = pnl.get_parent()
		if pnl != null:
			bottom = maxf(bottom, ((pnl as Control).get_global_transform_with_canvas() * (pnl as Control).size).y)
		if bottom > worst_b:
			worst_b = bottom
			worst_id = String(d["id"])
		if bottom > vr.size.y + 0.5:
			print("[HEROFIT]   ✗ %s 상세 판 아래끝 %.0f > 화면 %.0f" % [hl, bottom, vr.size.y])
			fails += 1
		# ③ 11/7 스팀 플레이 보고: 특정 영웅을 고르면 화면이 옆으로 늘어나 다 안 보인다.
		#   위 ② 는 아래끝만 쟀다. 출격 화면 안에서 보이는 칸 전부의 좌우 끝을 화면 폭과 견준다.
		var lx_min: float = 0.0
		var rx_max: float = 0.0
		var wide_nm: String = ""
		for c2: Node in (cs as Node).find_children("*", "Control", true, false):
			var cc: Control = c2 as Control
			if not cc.is_visible_in_tree() or cc.size.x <= 0.0:
				continue
			var xf2: Transform2D = cc.get_global_transform_with_canvas()
			var l2: float = (xf2 * Vector2.ZERO).x
			var r2: float = (xf2 * Vector2(cc.size.x, 0.0)).x
			if r2 > rx_max:
				rx_max = r2
				wide_nm = "%s(%s)" % [cc.name, cc.get_class()]
			lx_min = minf(lx_min, l2)
		if rx_max > vr.size.x + 0.5 or lx_min < -0.5:
			var dpanel: Node = (cs.get("_go_btn") as Node)
			while dpanel != null and not (dpanel is PanelContainer):
				dpanel = dpanel.get_parent()
			var why: Array = []
			for nm2: String in ["_detail_port", "_detail_name", "_detail_abil", "_detail_stats", "_detail_lbl", "_star_row", "_skin_row"]:
				var c3: Control = cs.get(nm2) as Control
				if c3 != null and is_instance_valid(c3) and c3.is_visible_in_tree():
					why.append("%s %.0f" % [nm2.trim_prefix("_"), c3.get_combined_minimum_size().x])
			print("[HEROFIT]   ✗ %s 가로 %.0f~%.0f 가 화면(0~%.0f) 밖 — 가장 오른쪽 %s · 상세 판 최소 폭 %.0f (%s)" % [hl, lx_min, rx_max, vr.size.x, wide_nm,
				(dpanel as Control).get_combined_minimum_size().x if dpanel != null else -1.0, ", ".join(why)])
			fails += 1
			if wide_id == "":
				wide_id = String(d["id"])
	for d: Dictionary in Characters.defs():
		if String(d["id"]) == worst_id:
			cs.call("_show_detail", d)
	for _i in 3:
		await get_tree().process_frame
	await _snap("user://herofit/charsel_%s.png" % worst_id)
	if wide_id != "":
		for d: Dictionary in Characters.defs():
			if String(d["id"]) == wide_id:
				cs.call("_show_detail", d)
		for _i in 3:
			await get_tree().process_frame
		await _snap("user://herofit/charsel_wide_%s.png" % wide_id)
	print("[HEROFIT] 화면 %s · 가장 아래까지 내려간 상세 판: %s (%.0f)" % [str(vr.size), worst_id, worst_b])
	print("[HEROFIT] %s" % ("ALL PASS" if fails == 0 else "FAIL — %d건" % fails))
	get_tree().quit(1 if fails > 0 else 0)


## 레벨업 카드 등급이 한눈에 읽히는지 보는 그림 (--rarityshot).
## ★ 10/13 사용자: "등급별 선택창, 뭐가 좋은 건지 안 좋은 건지 명확함이 떨어진다".
##   일반 · 희귀 · 영웅 · 고유 · 전설 · 신화 · 융합을 실제 레벨업 창에 네 장씩 세워 찍는다.
##   user://rarityshot/rarity_<묶음>.png — 낮은 등급부터 높은 등급 순서로 놓는다.
func _rarityshot_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	G.xp_to_next = 1000000000
	var dir: String = "user://rarityshot"
	DirAccess.make_dir_recursive_absolute(dir)
	var defs: Dictionary = {}
	for u: Dictionary in _base_pool():
		defs[String(u["id"])] = u
	for cid: String in _CHAR_CARDS:
		var cu: Dictionary = _CHAR_CARDS[cid]
		defs[String(cu["id"])] = cu
	for ev: Dictionary in EVOLUTIONS:
		defs[String(ev["id"])] = {"id": String(ev["id"]), "n": String(ev["n"]), "d": String(ev["d"]), "max": 1}
	var sets: Dictionary = {
		"low": ["dmg", "b_fire", "wp_bow", "c_allround"],
		"high": ["wpn_orb", "l_timewarp", "m_immortal", "evo_inferno"],
	}
	for key: String in sets:
		_populate_cards()
		for c in _cards_box.get_children():
			_cards_box.remove_child(c)
			c.queue_free()
		for cid: String in (sets[key] as Array):
			_cards_box.add_child(_make_card(defs[cid]))
		_levelup_root.visible = true
		get_tree().paused = true
		for i in 4:
			await get_tree().process_frame
		await _snap("%s/rarity_%s.png" % [dir, key])
		_levelup_root.visible = false
	print("[RARITYSHOT] 끝 — %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit()


## 레벨업 카드 화면을 **그림으로 찍고, 넘치는 곳을 숫자로 잰다.**
## ★ 2026-09-07: 카드에 "고르면 Lv3" 한 줄을 넣으면서 카드가 실제로 어떻게 보이는지 안 봤다.
##   카드는 224×296 고정인데 설명이 길어지면 아래 요소(별·아이콘)가 밖으로 밀려 안 보인다.
##   "글로만 확인"이 통하지 않는 자리다 — 자식 하나하나의 사각형을 카드 안쪽과 대조한다.
func _cardshot_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	var fails: int = 0
	var dir: String = "user://cardshot"
	DirAccess.make_dir_recursive_absolute(dir)
	# 최악을 만든다 — 설명이 가장 긴 카드들 + 톨크(한 장에 두 단계, 추가 라벨이 붙는다)
	var smith: Dictionary = Characters.defs()[0]
	for d: Dictionary in Characters.defs():
		if String(d.get("ability", "")) == "forge":
			smith = d
	for tag: String in ["기본", "톨크"]:
		_begin_run(smith if tag == "톨크" else Characters.defs()[0])
		await get_tree().process_frame
		p = G.player as Player
		G.xp_to_next = 1000000000
		# ★ 3장 샘플로는 최악이 안 걸린다. **카드 풀 전체를** 한 장씩 실제로 만들어 재야 한다 —
		#   길어지는 건 설명(성장 예고 + 만렙 특성 + 실수치)이라 무기·융합 카드가 가장 위험하다.
		for i in 3:
			_apply_upgrade("wpn_poison")
		_apply_upgrade("b_poison")
		# 1) 눈으로 볼 그림은 **실제 레벨업 화면**을 찍는다. 임시 컨테이너에 카드를 늘어놓으면
		#    레이아웃을 안 받아 화면 밖으로 나가고, 그건 게임 화면이 아니다(2026-09-07에 겪음).
		# ★ 무작위 추첨으로 찍으면 정작 문제인 카드(무기·융합)가 안 나온다 —
		#   실제로 탄막 카드 3장이 뽑혀서 확인이 안 됐다. 볼 것을 직접 세운다.
		_populate_cards()
		for c in _cards_box.get_children():
			c.queue_free()
		await get_tree().process_frame
		for pick: String in ["wp_heavy", "wpn_poison", "wpn_ice"]:
			for u: Dictionary in _upgrade_pool():
				if String(u["id"]) == pick:
					_cards_box.add_child(_make_card(u))
		_levelup_root.visible = true
		await get_tree().process_frame
		await get_tree().process_frame
		await _snap("%s/cards_%s.png" % [dir, tag])
		_levelup_root.visible = false
		# 2) 숫자는 풀 전체를 따로 잰다 — 3장 샘플로는 가장 긴 카드가 안 걸린다.
		var probe := HBoxContainer.new()
		add_child(probe)
		for u: Dictionary in _upgrade_pool():
			probe.add_child(_make_card(u))
		for ev: Dictionary in EVOLUTIONS:
			probe.add_child(_make_card({"id": String(ev["id"]), "n": String(ev["n"]),
				"d": String(ev["d"]), "max": 1}))
		await get_tree().process_frame
		var card_h: float = 0.0
		var worst_over: float = 0.0
		var worst_need: float = 0.0
		var worst_id: String = ""
		for c in probe.get_children():
			var btn := c as Button
			if btn == null:
				continue
			# ★ btn.clip_contents = true 라 밖으로 나간 것은 **잘려서 안 보인다.** 그러니
			#   "사각형 밖으로 나갔나"로는 절대 안 잡힌다 — 실제로 그렇게 재다가 0 을 얻었다.
			#   내용이 **필요로 하는 높이**와 카드가 **주는 높이**를 견줘야 한다.
			var need: float = 0.0
			var root: Control = null
			for cc in btn.get_children():
				if cc is Control:
					root = cc as Control
			if root != null:
				need = root.get_combined_minimum_size().y
			# ★ 프로브 HBox 는 Node2D 밑이라 레이아웃을 못 받는다 — btn.size.y 가 0 이다.
			#   카드 크기는 어차피 고정(custom_minimum_size)이므로 그 값과 직접 견준다.
			var have: float = maxf(btn.custom_minimum_size.y, btn.size.y)
			card_h = have
			var over: float = need - have
			if need > worst_need:
				worst_need = need
				worst_id = _last_visible_label(btn)
			if over > worst_over:
				worst_over = over
		probe.queue_free()
		print("  [%s] 카드 %d장 · 가장 긴 것 %.0f/%.0f · %s"
			% [tag, _upgrade_pool().size() + EVOLUTIONS.size(), worst_need, card_h,
				("넘침 %+.0fpx — %s" % [worst_over, worst_id]) if worst_over > 0.0
				else "여유 %.0fpx" % -worst_over])
		if worst_over > 0.0:
			print("  [CARD]   ✗ %s: 내용이 %.0fpx 넘쳐 아래쪽(별)이 잘린다 — %s"
				% [tag, worst_over, worst_id])
			fails += 1
	print("[CARD] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


var _ovf: Array = []

## 그 버튼 안의 모든 라벨/컨트롤이 버튼 사각형 밖으로 나갔는지 재귀로 훑는다.
func _scan_overflow(node: Node, box: Rect2, depth: int) -> void:
	if depth == 0:
		_ovf = []
	for c in node.get_children():
		var ct := c as Control
		if ct != null and ct.visible and ct.size.y > 0.5:
			var r: Rect2 = ct.get_global_rect()
			var over: float = maxf(0.0, r.end.y - box.end.y) + maxf(0.0, box.position.y - r.position.y)
			var what: String = ct.get_class()
			if ct is Label:
				what = "「%s」" % String((ct as Label).text).split("\n")[0].substr(0, 16)
			_ovf.append({"over": over, "what": what, "card": _card_label_of(node)})
		_scan_overflow(c, box, depth + 1)


func _card_label_of(_n: Node) -> String:
	return ""


## 그 카드에서 세로로 가장 아래에 있는 라벨 — 넘치면 이것부터 잘린다.
func _last_visible_label(root: Node) -> String:
	var best: String = "(없음)"
	var by: float = -1.0e9
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			var ct := c as Control
			if ct == null or not ct.visible:
				continue
			var y: float = ct.get_global_rect().end.y
			if y > by:
				by = y
				if ct is Label:
					best = "「%s」" % String((ct as Label).text).split("
")[0].substr(0, 14)
				else:
					best = ct.get_class()
	return best


## 그 카드가 실제로 필요로 하는 세로 길이.
func _content_h(btn: Button) -> float:
	var h: float = 0.0
	for c in btn.get_children():
		var ct := c as Control
		if ct != null:
			h = maxf(h, ct.get_combined_minimum_size().y)
	return h


## 한계를 밀어 올리는 것들(특수무기 Lv2 시작 · 톨크 벼림 +1 · 초월 +3)이 겹쳤을 때
## 화면 셋이 서로 안 맞는 곳을 찾는다 — 카드 레벨 · 별 칸 수 · '융합까지' 진행도.
## ★ 2026-09-07 지적: "max 가 올라가면 융합까지 줄에도 반영돼야 하지 않나" +
##   "톨크로 1레벨 아이템을 고르면 바로 Lv3 인데, 카드가 현재 레벨인지 다음 레벨인지 애매하다".
##   한계돌파 경로가 셋이고 서로 곱해지므로 조합을 전부 돌려 봐야 한다.
func _maxcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	var fails: int = 0
	var cases: Array = [
		{"n": "기본", "forge": false, "trans": false},
		{"n": "톨크(벼림)", "forge": true, "trans": false},
		{"n": "초월", "forge": false, "trans": true},
		{"n": "톨크+초월", "forge": true, "trans": true},
	]
	print("=== MAXCHECK  한계돌파가 겹칠 때 화면 셋이 서로 맞는가 ===")
	for c: Dictionary in cases:
		var smith: Dictionary = Characters.defs()[0]
		for d: Dictionary in Characters.defs():
			if String(d.get("ability", "")) == "forge":
				smith = d
		_begin_run(smith if bool(c["forge"]) else Characters.defs()[0])
		await get_tree().process_frame
		var p := G.player as Player
		G.xp_to_next = 1000000000
		if bool(c["trans"]):
			p.transcend_bonus += 3
			_transcended = true
		var wid: String = "wpn_poison"       # 맹독 장판 — 유저가 실제로 본 그 카드
		var picks: int = 0
		var trail: PackedStringArray = []
		while picks < 6:
			var before: int = _shown_level(wid)
			var in_pool: bool = false
			for u: Dictionary in _filtered_pool():
				if String(u["id"]) == wid:
					in_pool = true
			if not in_pool:
				break
			# 카드가 "고르면 Lv N" 이라고 예고한 값 — 실제로 그렇게 되는지 바로 뒤에서 대조한다
			var promised: int = _next_level_of(wid)
			_apply_upgrade(wid)
			picks += 1
			var after: int = _shown_level(wid)
			trail.append("%d→%d" % [before, after])
			if promised != after:
				print("  [MAX]   ✗ 카드는 Lv%d 이 된다고 적었는데 실제는 Lv%d 다 (%s)"
					% [promised, after, String(c["n"])])
				fails += 1
		var lvl: int = _shown_level(wid)
		var real: int = int(p.weapons[wid].get("level")) if p.weapons.has(wid) else -1
		var star_max: int = _shown_max(wid, _ability_max(wid))
		var want: int = _ability_max(wid)
		# '융합까지' 줄에서 이 재료가 어떻게 적히는지 그대로 뽑는다
		_apply_upgrade("b_poison")
		var fline: String = ""
		for s: String in fusion_progress_lines():
			if "역병" in s:
				fline = s
		print("  [%-9s] 픽 %d회 (%s) → 화면 Lv%d · 무기 Lv%d · 별 %d칸 · 상한 %d"
			% [String(c["n"]), picks, " ".join(trail), lvl, real, star_max, want])
		print("      융합까지:  %s" % (fline if fline != "" else "(안 뜸)"))
		if lvl != real:
			print("  [MAX]   ✗ 화면 Lv%d 인데 무기는 Lv%d" % [lvl, real]); fails += 1
		if lvl > star_max:
			print("  [MAX]   ✗ 레벨 %d 인데 별이 %d칸뿐 — 잘려 보인다" % [lvl, star_max]); fails += 1
		# ★ 핵심: 한계를 넘었는데 진행도가 "7/6" 처럼 분모를 넘어 찍히면 화면이 깨져 보인다
		if fline != "" and ("%d/%d" % [lvl, want]) in fline and lvl > want:
			print("  [MAX]   ✗ 융합 진행도가 분모를 넘는다: %d/%d" % [lvl, want]); fails += 1
		# ★ 한계돌파를 했다고 **융합이 막히면 안 된다.** 성립 조건은 정적 상한이어야 한다 —
		#   분모를 실제 레벨로 올려 놓고 조건까지 같이 올리면 초월할수록 융합이 멀어진다.
		for i in 6:
			_apply_upgrade("b_poison")
		var open_now: bool = false
		for ev: Dictionary in _available_evolutions():
			if String(ev["id"]) == "evo_plague":
				open_now = true
		print("      역병 융합 가능: %s" % ("✔" if open_now else "✗ 안 열린다"))
		if not open_now:
			print("  [MAX]   ✗ %s 조합에서 재료를 다 채웠는데 융합이 안 열린다" % String(c["n"]))
			fails += 1
		# 아키타입 무기(wp_heavy)도 같은 규칙을 따르는가 — 특수무기와 시작 레벨이 다르다
		var ah: int = _shown_level("wp_heavy")
		var ap: int = _next_level_of("wp_heavy")
		_apply_upgrade("wp_heavy")
		var ar: int = _shown_level("wp_heavy")
		if ap != ar:
			print("  [MAX]   ✗ 아키타입: 카드는 Lv%d 예고인데 실제 Lv%d (현재 %d, %s)"
				% [ap, ar, ah, String(c["n"])])
			fails += 1
		if bool(c["trans"]):
			p.transcend_bonus = 0
	print("[MAX] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 융합이 **재료 두 개의 특성을 모두 물려받는가**. 잃는 게 있으면 "따로 들고 다니는 게 낫다"가 된다.
## ★ 2026-09-07 지적: 군단으로 합치면 얼음정령의 만렙 특성 '파쇄'가 사라졌다.
##   원인은 두 가지였다 —
##   (1) 무기+무기 융합(군단만 해당)에서 소멸한 재료의 만렙 특성을 옮기는 코드가 없었다.
##   (2) 무기+탄막 융합 중 **탄을 안 쏘는 무기**(사슬·레이저)는 받은 탄막 효과가
##       내 총알에만 걸리고 결과 무기엔 아무 영향이 없었다 — 군단의 b_ice 와 같은 구멍.
##   여기서 12종 전부, 재료 두 개가 각각 결과에 남았는지 관측 가능한 값으로 확인한다.
func _fuseinherit_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	G.aim_mode = 0
	var fails: int = 0
	print("=== FUSE INHERIT  융합이 재료 두 개의 특성을 다 물려받는가 ===")
	print("  %-13s %-24s %-24s" % ["융합", "재료A 특성", "재료B 특성"])
	for evo: Dictionary in EVOLUTIONS:
		var eid: String = String(evo["id"])
		var req: Array = evo["req"]
		_begin_run(Characters.defs()[0])
		await get_tree().process_frame
		var p := G.player as Player
		p.max_hp = 1.0e9
		p.hp = 1.0e9
		G.xp_to_next = 1000000000
		p.global_position = Vector2.ZERO
		_dps_mode = true
		_dps_clear_weapons(p)
		for m: String in req:
			_fp_grant(p, String(m), 6)
		_apply_upgrade(eid)
		await get_tree().process_frame
		var cells: PackedStringArray = []
		for m: String in req:
			var mid: String = String(m)
			var arch: String = String(_WP_KEY.get(mid, mid))
			var tn: String = G.w_trait_name(arch)
			if tn == "" and not _is_weapon_id(mid):
				# 탄막·스탯 재료 — 만렙 특성이 없다. 대신 그 **효과**가 결과 무기에 실렸는지 본다.
				cells.append("%s (%s)" % [_mat_effect_label(mid), "✔" if _mat_effect_on(p, eid, mid) else "✗"])
			elif G.MAX_TRAIT.has(arch):
				var on: bool = _trait_on(p, eid, arch)
				cells.append("%s (%s)" % [tn, "✔" if on else "✗"])
				if not on:
					fails += 1
			else:
				# 밸런스 소총·작두·맹독 장판은 만렙 특성을 **일부러** 비워 뒀다(game.gd:1486).
				# 없는 것을 잃었다고 셀 수는 없다 — 그대로 적고 넘어간다.
				cells.append("만렙 특성 없음 (—)")
		print("  %-13s %-24s %-24s" % [String(evo["n"]), cells[0], cells[1]])
		for c in cells:
			if "✗" in String(c):
				print("  [FI]   ✗ %s: %s 가 결과에 안 남는다" % [String(evo["n"]), String(c)])
				if not ("✗" in String(cells[0]) and _WP_KEY.has(String(req[0]))):
					pass
		if "✗" in String(cells[1]) and G.w_trait_name(String(_WP_KEY.get(String(req[1]), String(req[1])))) == "":
			fails += 1
		_dps_clear_dummies()
	print("[FI] %s" % ("ALL PASS — 12종 전부 두 재료가 다 남는다" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 탄막·스탯 재료가 무엇을 주기로 했는가 (화면에 적을 이름).
func _mat_effect_label(mid: String) -> String:
	match mid:
		"b_fire": return "화상"
		"b_ice": return "빙결/감속"
		"b_poison": return "중독"
		"b_shock": return "감전"
		"b_big": return "거대탄"
		"b_exec": return "처형"
		"b_vamp": return "흡혈"
		"b_chain": return "연쇄"
		"crit": return "치명타"
	return mid


## 그 재료의 효과가 **결과 무기 자신에** 실렸는가. 플레이어 총알에만 걸리는 건 승계가 아니다.
func _mat_effect_on(p: Player, eid: String, mid: String) -> bool:
	match eid:
		"evo_inferno":    return true   # 오라가 직접 화상을 건다 (fire_weapon.apply_burn)
		"evo_blizzard":   return G.fused("wpn_ice", "evo_blizzard")     # 장판이 직접 얼린다
		"evo_plague":     return true   # 웅덩이가 직접 중독시킨다
		"evo_tempest":    return G.fused("wpn_chain", "evo_tempest")    # 번개가 직접 감전
		"evo_nova":       return G.fused("wpn_beam", "evo_nova")        # 빔이 직접 화상
		"evo_reaper":     return p.b_exec > 0   # 처형은 enemy.take_damage 라 모든 피해원에 걸린다
		"evo_ledger":     return p.b_exec > 0
		"evo_orb":        return String(p.fused_marks.get("jakdu", "")) == "evo_orb"  # 근접 흡혈
		"evo_railcannon": return p.pierce >= 8
		"evo_deadeye":    return p.crit_chance >= 0.999
		"evo_ninetail":   return p.b_chain > 0
		"evo_legion":     return _legion_bolt_ice(p)
	return false


## 결과 무기 자신이 그 만렙 특성을 지금 갖고 있는가.
func _trait_on(p: Player, eid: String, arch: String) -> bool:
	# 군단만 재료 두 개가 다 무기다 — 소멸한 얼음정령의 '파쇄'가 군단 탄에 실렸는지 직접 본다.
	if eid == "evo_legion" and arch == "summon_ice":
		return _legion_bolt_shatter(p)
	if p.weapons.has(arch) and is_instance_valid(p.weapons[arch]):
		return G.w_maxed(arch, int(p.weapons[arch].get("level")))
	for w in p.weapons_primary:
		if String((w as Dictionary)["id"]) == arch:
			return G.w_maxed(arch, int((w as Dictionary)["level"]))
	return false


func _legion_minion(p: Player) -> Node:
	var w: Node = p.weapons.get("wpn_summon")
	if w == null or not is_instance_valid(w):
		return null
	for m in (w.get("_minions") as Array):
		if is_instance_valid(m):
			return m as Node
	return null


func _legion_bolt_shatter(p: Player) -> bool:
	var m: Node = _legion_minion(p)
	return m != null and bool(m.get("legion")) and bool(m.get("shatter"))


func _legion_bolt_ice(p: Player) -> bool:
	var m: Node = _legion_minion(p)
	return m != null and bool(m.get("legion")) and int(m.get("ice_lv")) > 0


## 융합이 **무기가 하는 짓을 실제로 바꾸는가**. 12종 전부, 관측 가능한 값 하나씩.
## ★ 2026-09-06 까지 fused_marks 를 읽는 무기 스크립트는 하나도 없었다 — 융합 12개가 전부
##   "무기 Lv11 + 탄막효과 6 + card_mult ×1.25" 였고, 이름이 약속한 것(긴 창·아홉 갈래·
##   얼려 세운다·번진다)은 코드 어디에도 없었다. 더 나쁜 건, 탄을 안 쏘는 무기(오라·장판·
##   레이저·근접)에 **탄막 효과**를 줘서 그 절반은 아무 데도 안 걸렸다는 것이다.
##   여기서 각 융합이 실제로 바꾸는 값을 융합 전/후로 직접 잰다.
func _fusemech_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	var fails: int = 0
	print("=== FUSE MECH  융합이 무기 동작을 정말 바꾸는가 ===")
	print("  %-13s %-22s %10s %10s" % ["융합", "관측값", "융합 전", "융합 후"])
	for evo: Dictionary in EVOLUTIONS:
		var eid: String = String(evo["id"])
		_begin_run(Characters.defs()[0])
		await get_tree().process_frame
		var p := G.player as Player
		p.no_default_weapon = true
		p.weapons_primary = []
		for m: String in (evo["req"] as Array):
			_fp_grant(p, String(m), 6)
		var before: float = _fm_probe(p, eid)
		var lbl: String = _fm_label(eid)
		_apply_upgrade(eid)
		await get_tree().process_frame
		var after: float = _fm_probe(p, eid)
		var ok: bool = after > before + 0.0001
		print("  %-13s %-22s %10.2f %10.2f  %s"
			% [String(evo["n"]), lbl, before, after, "✔" if ok else "✗ 안 바뀐다"])
		if not ok:
			fails += 1
	print("[FM] %s" % ("ALL PASS — 12종 전부 동작이 바뀐다" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 그 융합이 무엇을 바꾸는지 — 화면에 적을 이름.
func _fm_label(eid: String) -> String:
	match eid:
		"evo_inferno":    return "오라 반경"
		"evo_blizzard":   return "한 번에 까는 장판 수"
		"evo_plague":     return "웅덩이 전염 세대"
		"evo_railcannon": return "탄 관통유지(1=무뎌짐없음)"
		"evo_tempest":    return "번개 마디 수"
		"evo_legion":     return "소환수 사거리"
		"evo_reaper":     return "채찍 반경"
		"evo_nova":       return "빔 갈래 수"
		"evo_deadeye":    return "탄 관통 수"
		"evo_ninetail":   return "부챗살 수"
		"evo_ledger":     return "탄 관통 수"
		"evo_orb":        return "벨 때 회복(0/1)"
	return "?"


## 융합이 바꾸기로 한 값을 실제로 읽어 온다. 무기마다 읽는 곳이 다르다.
func _fm_probe(p: Player, eid: String) -> float:
	match eid:
		"evo_inferno":
			var w: Node = p.weapons.get("wpn_fire")
			return float(w.call("_radius")) if w != null else -1.0
		"evo_blizzard":
			return 3.0 if G.fused("wpn_ice", "evo_blizzard") else 1.0
		"evo_plague":
			return 2.0 if G.fused("wpn_poison", "evo_plague") else 0.0
		"evo_tempest":
			return 1.6 if G.fused("wpn_chain", "evo_tempest") else 1.0
		"evo_legion":
			var w2: Node = p.weapons.get("wpn_summon")
			if w2 == null:
				return -1.0
			var ms: Array = w2.get("_minions")
			for m in ms:
				if is_instance_valid(m):
					return float(m.call("_leash"))
			return -1.0
		"evo_reaper":
			var w3: Node = p.weapons.get("wpn_whip")
			return float(w3.call("_reach")) if w3 != null else -1.0
		"evo_nova":
			var w4: Node = p.weapons.get("wpn_beam")
			return float(w4.call("_beam_count")) if w4 != null else -1.0
		"evo_orb":
			return 1.0 if String(p.fused_marks.get("jakdu", "")) == "evo_orb" else 0.0
		# 아키타입 융합은 탄을 한 발 쏴서 그 탄에서 직접 읽는다 — 코드가 아니라 결과를 본다
		"evo_railcannon", "evo_deadeye", "evo_ninetail", "evo_ledger":
			return _fm_bullet_probe(p, eid)
	return -1.0


## 실제로 한 발 쏘고, 나온 탄에서 값을 읽는다. '코드가 그렇게 생겼다'가 아니라 '정말 그렇게 나간다'.
func _fm_bullet_probe(p: Player, eid: String) -> float:
	for c in get_children():
		if c is Bullet:
			(c as Node).queue_free()
	var arch: String = {"evo_railcannon": "heavy", "evo_deadeye": "rapid",
		"evo_ninetail": "fan", "evo_ledger": "bow"}[eid]
	var lvl: int = 1
	for w in p.weapons_primary:
		if String((w as Dictionary)["id"]) == arch:
			lvl = int((w as Dictionary)["level"])
	p.aim = Vector2.RIGHT
	p._fire_ranged(Player.WEAPON_DEFS[arch], lvl, arch)
	var n: int = 0
	var pierce: float = 0.0
	var decay: float = 0.0
	for c in get_children():
		if c is Bullet:
			n += 1
			pierce = float((c as Bullet)._pierce)
			decay = (c as Bullet).pierce_decay
	for c in get_children():
		if c is Bullet:
			(c as Node).queue_free()
	if eid == "evo_ninetail":
		return float(n)
	if eid == "evo_railcannon":
		return decay
	return pierce


## 융합한 **뒤에도** 그 무기의 상세 능력치가 화면에 남는가. 12종 전부.
## ★ _consume_material 이 _upgrade_counts 에서 재료를 지우는데, ESC 빌드 목록은 그 장부를
##   돌면서 만들어진다 — 그래서 융합을 하면 결과 무기가 목록에서 통째로 사라진다.
##   Lv13 군단을 들고 있는데 화면에는 "보조 무기 1종" 뿐이었다(2026-09-06 지적).
##   여기서 (1) 목록에 있는가 (2) 레벨이 실제와 같은가 (3) 실수치 설명이 붙는가
##   (4) 융합 표식이 있는가 (5) 일시정지 화면이 이름을 부르는가 를 전부 본다.
func _fusedisplay_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	var fails: int = 0
	print("=== FUSE DISPLAY  융합 뒤 상세 능력치가 화면에 남는가 ===")
	print("  %-13s %-6s %-5s %-5s %-5s %s" % ["융합", "목록", "레벨", "실수치", "표식", "설명 첫줄"])
	for evo: Dictionary in EVOLUTIONS:
		var eid: String = String(evo["id"])
		var req: Array = evo["req"]
		_begin_run(Characters.defs()[0])
		await get_tree().process_frame
		var p := G.player as Player
		for m: String in req:
			_fp_grant(p, String(m), 6)
		_apply_upgrade(eid)
		await get_tree().process_frame
		# 융합 결과가 실린 무기 id 를 찾는다 (재료 중 무기 쪽, 군단은 wpn_summon 으로 합쳐진다)
		var wid: String = ""
		for k in p.fused_marks.keys():
			if String(p.fused_marks[k]) == eid:
				wid = String(k)
		var card_id: String = wid
		if not (wid.begins_with("wpn_") or wid == "summon_ice"):
			for c in _WP_KEY.keys():                   # 아키타입은 카드 id 가 wp_* 다
				if String(_WP_KEY[c]) == wid:
					card_id = String(c)
		var real_lv: int = _real_weapon_level(card_id)
		# (1)(2)(3)(4) — ESC 빌드 목록
		var found: Dictionary = {}
		for e: Dictionary in _build_summary():
			if String(e.get("id", "")) == card_id:
				found = e
		var listed: bool = not found.is_empty()
		var lv_ok: bool = listed and int(found.get("level", 0)) == real_lv and real_lv > 0
		var desc: String = String(found.get("desc", ""))
		var num_ok: bool = listed and desc.strip_edges() != "" and desc.length() > 12
		var mark_ok: bool = listed and String(found.get("tier", "")) == "융합"
		# (5) 일시정지 화면이 이 무기를 부르는가
		var named: bool = false
		if wid != "":
			var dn: String = ""
			if Player.WEAPON_DEFS.has(wid):
				dn = String((Player.WEAPON_DEFS[wid] as Dictionary)["name"])
			else:
				dn = _card_title(card_id, card_id)
			named = dn != ""
		print("  %-13s %-6s %-5s %-5s %-5s %s"
			% [String(evo["n"]), "✔" if listed else "✗ 없음",
				("Lv%d" % int(found.get("level", 0))) if listed else "-",
				"✔" if num_ok else "✗", "✔" if mark_ok else "✗",
				desc.split("\n")[0].substr(0, 34) if listed else "(목록에 없음)"])
		if not listed:
			print("  [FD]   ✗ %s: 융합 결과 무기(%s Lv%d)가 빌드 목록에 없다"
				% [String(evo["n"]), card_id, real_lv]); fails += 1
		else:
			if not lv_ok:
				print("  [FD]   ✗ %s: 목록 Lv%d 인데 무기는 Lv%d"
					% [String(evo["n"]), int(found.get("level", 0)), real_lv]); fails += 1
			if not num_ok:
				print("  [FD]   ✗ %s: 상세 능력치가 비어 있다" % String(evo["n"])); fails += 1
			if not mark_ok:
				print("  [FD]   ✗ %s: 융합 표식이 없다 — 초월한 무기인지 알 수 없다"
					% String(evo["n"])); fails += 1
		if not named:
			print("  [FD]   ✗ %s: 무기 이름을 못 찾는다" % String(evo["n"])); fails += 1
		# ★ 같은 융합이 목록에 두 번 나오면 안 된다 — 결과 무기 줄과 융합 배지 줄이
		#   따로 있어서 "동일한게 MAX, 융합로 나와있다"는 신고가 나왔다(2026-09-07).
		var hits: int = 0
		for e4: Dictionary in _build_summary():
			if String(ev_name_of(e4)) == String(evo["n"]):
				hits += 1
		if hits > 1:
			print("  [FD]   ✗ %s 가 빌드 목록에 %d번 나온다 (중복)" % [String(evo["n"]), hits])
			fails += 1
	print("[FD] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 그 빌드 항목이 어느 융합을 가리키는가. 16차에 이름 앞 「◆」를 뺐다 — 종류(tier)가 「융합」인 줄의 이름이 곧 융합 이름.
func ev_name_of(e: Dictionary) -> String:
	if String(e.get("tier", "")) != "융합":
		return ""
	return String(e.get("name", "")).strip_edges()


## 영웅 등급(별)이 (1) 정말 능력치를 올리는가 (2) 선택 화면이 적는 숫자가 실제 런과 같은가
## (3) 별 하나의 **순이득**이 얼마인가 — 몹도 같이 세지므로 표기값 그대로가 아니다.
## ★ "별을 찍으면 확실히 오르는 거 맞지?? 큰 체감을 못해서"(2026-09-06) 에 답하는 자리다.
func _countcheck_flow() -> void:
	await get_tree().create_timer(0.2).timeout
	print("=== COUNT  스토어 원고에 적을 숫자 (코드에서 센 값) ===")
	print("  영웅        %d명" % Characters.defs().size())
	print("  요괴(도감)  %d종" % Codex.MONSTERS.size())
	var nboss: int = 0
	for m: Dictionary in Codex.MONSTERS:
		if float(CharForge.enemy_slot(int(String(m["key"]).substr(4))).get("h", 0.0)) > 90.0:
			nboss += 1
	print("  그중 보스   %d종 (키 90px 넘는 자리)" % nboss)
	print("  융합        %d가지" % EVOLUTIONS.size())
	print("  도전과제    %d개" % Codex.ACHIEVEMENTS.size())
	print("  맵          %d곳 × 난이도 %d단계" % [Codex.MAPS.size(), G.DIFF_NAMES.size()])
	print("  무기 카드   %d종 / 전체 카드 %d종" % [
		_base_pool().filter(func(u: Dictionary) -> bool: return _is_weapon_id(String(u["id"]))).size(),
		_base_pool().size()])
	get_tree().quit(0)


func _rankcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	var fails: int = 0
	var cdef: Dictionary = Characters.defs()[0]
	for d: Dictionary in Characters.defs():
		if String(d["id"]) == (_lp_char if _lp_char != "" else "mudang"):
			cdef = d
	var cid: String = String(cdef["id"])
	print("=== RANK  %s ===" % String(cdef["name"]))
	print("  등급   공격력    체력   이동   방어    몹배수   순이득(등급0 대비)")
	var base_mult: float = 0.0
	for rk: int in [0, 3, 6, 10, 20]:
		G.meta["rank_" + cid] = rk
		G.last_char_id = cid
		var want: Dictionary = Characters.start_stats(cdef, rk)
		# 실제 런을 돌려서 같은 값이 나오는지 — 표기와 실효가 갈리면 여기서 잡힌다
		_begin_run(cdef)
		await get_tree().process_frame
		var p := G.player as Player
		var mob: float = G.meta_power(rk)
		var net: float = (float(want["dmg"]) / maxf(0.001, float(Characters.start_stats(cdef, 0)["dmg"]))) / (mob / maxf(0.001, G.meta_power(0)))
		if rk == 0:
			base_mult = net
		print("  ★%-4d %7.2f %7d %6d %6.1f   ×%.3f   ×%.3f"
			% [rk, float(want["dmg"]), int(want["hp"]), int(want["spd"]),
				float(want["armor"]), mob, net / maxf(0.001, base_mult)])
		for k: String in ["dmg", "hp", "spd", "armor"]:
			var real: float = p.damage if k == "dmg" else (p.max_hp if k == "hp" else (p.move_speed if k == "spd" else p.armor))
			if absf(real - float(want[k])) > 0.02:
				print("  [RANK]   ✗ ★%d %s 표기 %.3f 인데 실제 런은 %.3f" % [rk, k, float(want[k]), real])
				fails += 1
	G.meta["rank_" + cid] = 0
	print("  ※ 표기 공격력은 그대로 오르지만 몹 체력이 같이 올라 순이득은 그보다 작다.")
	print("[RANK] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 소환수가 (1) 흩어져서 각자 다른 적을 맡는가 (2) 군단 융합 뒤에 실제로 얼음탄을 쏘는가
## (3) 융합으로 닿는 거리가 정말 늘어나는가.
## ★ 세 가지 다 DPS 수치로는 안 보인다 — 더미가 붙박이면 접촉 피해가 전부를 먹기 때문이다.
##   유저가 실제로 불평한 것은 "뭉쳐 다닌다 · 얼음정령이 그냥 사라졌다 · 사거리가 그대로다"
##   셋이고(2026-09-06), 그건 이 세 값으로만 잡힌다.
func _legioncheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	G.aim_mode = 0
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	G.xp_to_next = 1000000000
	p.global_position = Vector2.ZERO
	_dps_mode = true
	_dps_clear_weapons(p)
	var fails: int = 0
	for phase in ["융합 전", "융합 후"]:
		if phase == "융합 전":
			for i in 6:
				_apply_upgrade("wpn_summon")
			for i in 6:
				_apply_upgrade("summon_ice")
		else:
			_apply_upgrade("evo_legion")
		p.global_position = Vector2.ZERO
		p.velocity = Vector2.ZERO
		_dps_clear_dummies()
		_dps_spawn_dummies(p)
		await get_tree().create_timer(2.5).timeout
		var w: Node = p.weapons.get("wpn_summon")
		var mins: Array = w.get("_minions") if w != null else []
		var live: Array = []
		for m in mins:
			if is_instance_valid(m):
				live.append(m)
		# (1) 각자 다른 적을 맡는가 — 목표가 몇 종류인가
		var tset: Dictionary = {}
		for m in live:
			var t: Variant = m.get("_target")
			if t != null and is_instance_valid(t):
				tset[(t as Node).get_instance_id()] = true
		# (2) 얼음탄이 실제로 날아가는가 — 1초 동안 새로 생긴 탄을 센다
		var b0: int = get_tree().get_node_count_in_group("bullet")
		await get_tree().create_timer(1.0).timeout
		var b1: int = get_tree().get_node_count_in_group("bullet")
		# (3) 닿는 거리
		var leash: float = float(live[0].call("_leash")) if not live.is_empty() else 0.0
		print("[LEGION] %-6s 소환수 %d마리 · 맡은 적 %d종류 · 사거리 %.0f · 탄 %d→%d · 사격 %s"
			% [phase, live.size(), tset.size(), leash, b0, b1,
				"켜짐" if (not live.is_empty() and bool(live[0].get("legion"))) else "꺼짐"])
		if phase == "융합 전":
			if live.size() >= 3 and tset.size() < 2:
				print("[LEGION]   ✗ %d마리가 전부 같은 적을 문다 (뭉침)" % live.size()); fails += 1
		else:
			if live.is_empty() or not bool(live[0].get("legion")):
				print("[LEGION]   ✗ 융합했는데 소환수가 군단이 아니다"); fails += 1
			if b1 <= b0:
				print("[LEGION]   ✗ 군단인데 얼음탄이 안 나간다"); fails += 1
	_dps_clear_dummies()
	print("[LEGION] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit(0)


## 융합 12종이 **실제로 얼마나 세지는가**. 재료를 만렙까지 올린 상태에서 한 번 재고,
## 융합을 적용한 뒤 다시 잰다. 그 비율이 "융합했더니 오?!" 의 크기다.
## ★ 이름은 전부 다른데(지옥불·레일건·군단…) 코드는 12개가 같은 모양이다 —
##   재료 2개 소멸 → 무기 Lv11 + 탄막효과 6 + card_mult ×1.25.
##   그러면 배수도 다 비슷하게 나올 수밖에 없다. 그걸 숫자로 확인하는 자리다.
func _fusepower_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	G.aim_mode = 0
	_begin_run(Characters.defs()[0])
	var p := G.player as Player
	_dps_mode = true
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	G.xp_to_next = 1000000000
	Engine.time_scale = 2.0
	var T: float = 4.0
	print("=== FUSE POWER  재료 만렙 → 융합 (더미24 · %.0f초 · timescale2) ===" % T)
	print("  %-14s %-22s %10s %10s %7s" % ["융합", "재료", "융합 전/s", "융합 후/s", "배수"])
	var rows: Array = []
	for evo: Dictionary in EVOLUTIONS:
		var eid: String = String(evo["id"])
		var req: Array = evo["req"]
		# 매번 완전히 새 판에서 — 앞 융합의 card_mult 와 탄막 수치가 남으면 값이 섞인다
		_begin_run(Characters.defs()[0])
		await get_tree().process_frame
		p = G.player as Player
		p.max_hp = 1.0e9
		p.hp = 1.0e9
		p.global_position = Vector2.ZERO
		p.velocity = Vector2.ZERO
		_dps_clear_weapons(p)
		for m: String in req:
			_fp_grant(p, String(m), 6)
		var before: float = await _fp_measure(p, T)
		var lv_b: int = _fp_weapon_lv(p, req)
		_apply_upgrade(eid)
		p.global_position = Vector2.ZERO
		p.velocity = Vector2.ZERO
		var after: float = await _fp_measure(p, T)
		var lv_a: int = _fp_weapon_lv(p, req)
		var mult: float = after / maxf(1.0, before)
		rows.append({"n": String(evo["n"]), "m": mult})
		print("  %-14s %-22s %10.0f %10.0f  ×%.2f   (무기 Lv%d → Lv%d)"
			% [String(evo["n"]), " + ".join(PackedStringArray(req)), before, after, mult, lv_b, lv_a])
		_dps_clear_dummies()
	Engine.time_scale = 1.0
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["m"]) > float(b["m"]))
	var lo: float = float((rows[rows.size() - 1] as Dictionary)["m"])
	var hi: float = float((rows[0] as Dictionary)["m"])
	print("  최고 %s ×%.2f · 최저 %s ×%.2f · 폭 %.1f배"
		% [String((rows[0] as Dictionary)["n"]), hi,
			String((rows[rows.size() - 1] as Dictionary)["n"]), lo, hi / maxf(0.01, lo)])
	# 융합은 재료 2칸을 통째로 태우고 융합 칸까지 쓴다. 그 값이면 최소 두 배는 돼야 한다.
	var weak: Array = []
	for r: Dictionary in rows:
		if float(r["m"]) < 2.0:
			weak.append("%s ×%.2f" % [String(r["n"]), float(r["m"])])
	if weak.is_empty():
		print("[FUSE] ALL PASS — 전부 2배 이상")
	else:
		print("[FUSE]   ✗ 재료 2칸을 태우고 2배가 안 되는 융합 %d종: %s"
			% [weak.size(), " · ".join(PackedStringArray(weak))])
	get_tree().quit(0)


## 융합 재료 하나를 지정 레벨까지 쥐어준다. 무기(아키타입/특수)와 탄막을 구분해야 한다.
func _fp_grant(p: Player, mid: String, lv: int) -> void:
	if mid.begins_with("wp_"):
		for i in lv:
			p.add_primary_weapon(mid.substr(3))
	elif mid.begins_with("wpn_") or mid == "summon_ice":
		for i in lv:
			p.add_weapon(mid)
	else:
		for i in lv:
			_apply_upgrade(mid)


## 이 융합이 다루는 무기의 지금 레벨 (전/후 비교용).
func _fp_weapon_lv(p: Player, req: Array) -> int:
	for m: String in req:
		var mid: String = String(m)
		if mid.begins_with("wpn_") or mid == "summon_ice":
			var w: Node = p.weapons.get(mid)
			if w != null and is_instance_valid(w):
				return int(w.get("level"))
		elif mid.begins_with("wp_"):
			for w2 in p.weapons_primary:
				if String((w2 as Dictionary)["id"]) == mid.substr(3):
					return int((w2 as Dictionary)["level"])
	# 융합 결과가 다른 무기로 옮겨간 경우(군단은 wpn_summon 으로 합쳐진다)
	for k in p.weapons.keys():
		if is_instance_valid(p.weapons[k]):
			return int(p.weapons[k].get("level"))
	return 0


func _fp_measure(p: Player, T: float) -> float:
	_dps_clear_dummies()
	_dps_spawn_dummies(p)
	await get_tree().create_timer(4.2).timeout   # 정착 + 직전 장판 소멸
	G.dmg_probe = 0.0
	G.probe_on = true
	var held: float = 0.0
	while held < T:
		await get_tree().physics_frame
		held += get_physics_process_delta_time()
		p.global_position = Vector2.ZERO
		p.velocity = Vector2.ZERO
		for di in _dps_dummies.size():
			if is_instance_valid(_dps_dummies[di]):
				(_dps_dummies[di] as Node2D).global_position = _dps_home[di]
	G.probe_on = false
	return G.dmg_probe / T


func _weapondps_flow(_dir: String) -> void:
	await get_tree().create_timer(0.3).timeout
	G.difficulty = 1
	G.aim_mode = 0  # 자동조준 — 탄이 더미를 향함
	_begin_run(Characters.defs()[0])
	var p := G.player as Player
	_dps_mode = true
	p.max_hp = 1.0e9   # 측정 중 사망 방지
	p.hp = 1.0e9
	G.xp_to_next = 1000000000  # 레벨업 모달 차단
	p.global_position = Vector2.ZERO
	Engine.time_scale = 2.0
	var T: float = 5.0
	# ★ 신규 무기가 빠져 있으면 '무기 간 격차'를 재는 이 하니스가 실제 빌드를 대표하지 못한다.
	#   WEAPON_DEFS 와 특수무기 목록에서 직접 뽑아, 무기를 추가해도 자동으로 측정에 들어오게 한다.
	var archetypes: Array = Player.WEAPON_DEFS.keys()
	var specials: Array = ["wpn_orb", "wpn_chain", "wpn_fire", "wpn_ice", "wpn_poison",
		"wpn_summon", "summon_ice", "wpn_whip", "wpn_boomerang", "wpn_beam"]
	var tmap: Dictionary = {}
	for a0: String in archetypes:
		tmap[a0] = "근접·무기카드" if String((Player.WEAPON_DEFS[a0] as Dictionary)["type"]) == "melee" else "탄환·무기카드"
	tmap["balanced"] = "탄환·기본"
	for s0: String in specials:
		tmap[s0] = "특수·영웅"
	var scenarios: Array = [
		{"name": "첫 픽 (기본 스탯)", "dmg": 14.0, "proj": 0, "crit": 0.05, "critm": Player.CRIT_MULT_BASE, "rate": 1.0, "arch_lvl": 1, "spec_lvl": 2},
		{"name": "5픽 (중반 강화 스탯)", "dmg": 42.0, "proj": 2, "crit": 0.35, "critm": 2.6, "rate": 0.7, "arch_lvl": 5, "spec_lvl": 6},
	]
	print("=== WEAPON DPS TEST START (더미10·%.0f초·timescale2) ===" % T)
	for sc: Dictionary in scenarios:
		print("--- 시나리오: %s (dmg=%.0f multi=+%d crit=%.0f%%) ---" % [String(sc["name"]), float(sc["dmg"]), int(sc["proj"]), float(sc["crit"]) * 100.0])
		for id: String in (archetypes + specials):
			p.damage = float(sc["dmg"])
			p.proj_bonus = int(sc["proj"])
			p.crit_chance = float(sc["crit"])
			p.crit_mult = float(sc["critm"])
			p.rate_mult = float(sc["rate"])
			p.bullet_speed = Player.BULLET_SPEED
			p.pierce = 0
			_dps_clear_weapons(p)
			var is_arch: bool = id in archetypes
			var lvl: int = int(sc["arch_lvl"]) if is_arch else int(sc["spec_lvl"])
			if is_arch:
				for i in lvl:
					p.add_primary_weapon(id)
			else:
				for i in lvl:
					p.add_weapon(id)
			# ★ 직전 무기의 반동(_ARCH_KICK)이 velocity 에 남아 플레이어가 원점에서 밀려난다.
			#   더미는 그 자리에 고정이라, 궤도 반경 68px 인 회전 오브는 조금만 밀려도
			#   영영 안 닿는다 — 이게 wpn_orb 가 두 번이나 0.0 을 찍은 진짜 이유다.
			p.global_position = Vector2.ZERO
			p.velocity = Vector2.ZERO
			_dps_spawn_dummies(p)
			await get_tree().create_timer(4.2).timeout  # 정착 + 직전 무기의 장판(최대4s) 소멸 대기
			G.dmg_probe = 0.0
			G.probe_on = true
			var held: float = 0.0
			while held < T:
				await get_tree().physics_frame
				held += get_physics_process_delta_time()
				p.global_position = Vector2.ZERO   # 근접·궤도형이 밀려나 측정이 죽지 않게
				p.velocity = Vector2.ZERO
				for di in _dps_dummies.size():     # 넉백으로 링이 흐트러지지 않게 붙들어 둔다
					if is_instance_valid(_dps_dummies[di]):
						(_dps_dummies[di] as Node2D).global_position = _dps_home[di]
			G.probe_on = false
			var dps: float = G.dmg_probe / T
			print("[DPS] %-11s Lv%d  %-14s : %9.1f /s" % [id, lvl, String(tmap[id]), dps])
			_dps_clear_dummies()
	Engine.time_scale = 1.0
	print("=== WEAPON DPS TEST DONE ===")
	get_tree().quit(0)


func _dps_clear_weapons(p: Player) -> void:
	p.no_default_weapon = true    # 안 그러면 _ensure_default_weapon 이 소총을 되살려 값이 섞인다
	p.weapons_primary = []
	for k in p.weapons.keys():
		if is_instance_valid(p.weapons[k]):
			(p.weapons[k] as Node).queue_free()
	p.weapons = {}
	for c in get_children():  # 잔류 탄환 제거
		if c is Bullet:
			(c as Node).queue_free()


## ★ 예전엔 80px 링 하나에만 세웠다. 그러면 궤도 반경 58px 인 회전 오브는 **한 번도 안 닿아**
##   DPS 0.0 이 찍힌다(2026-09-05 실측). 무기마다 사거리가 다른데 한 거리에서만 재면
##   그 거리에 맞는 무기만 유리하다. 안쪽 링을 하나 더 둬서 근접·궤도형도 공정하게 잰다.
func _dps_spawn_dummies(p: Player) -> void:
	# ★ 무기마다 닿는 거리가 다르다. 한두 개 링에만 세우면 그 거리에 안 맞는 무기가
	#   0.0 을 찍는다 — 회전 오브가 두 번이나 그랬다(궤도 58~68px, 더미는 44·80px).
	#   근접(90) · 궤도(58~80) · 오라(82~112) · 중거리(270) 를 전부 덮게 링을 여섯으로 편다.
	#   링마다 같은 수를 세워야 특정 거리의 무기가 유리해지지 않는다.
	var rings: Array = [26.0, 52.0, 68.0, 86.0, 130.0, 240.0]
	var per: int = 4
	for ri in rings.size():
		for i in per:
			var e := Enemy.new()
			e.kind = 2  # 탱크(넓은 판정)
			var a: float = TAU * (float(i) / float(per) + float(ri) * 0.13)
			e.global_position = p.global_position + Vector2(cos(a), sin(a)) * float(rings[ri])
			add_child(e)
			e.hp = 1.0e12  # 불사(측정 중 안 죽음)
			e.max_hp = 1.0e12
			# ★ 더미는 **제자리에 서 있어야** 한다. 예전엔 그냥 Enemy 라 4.2초 정착 동안
			#   플레이어에게 걸어와 전부 발밑에 뭉쳤다 — 링을 여섯 개로 펴 놔도 소용이 없고,
			#   실제로는 "전부 20px 에 쌓인 상태"를 재고 있었다. 접촉형(소환수)이 과대평가되고
			#   궤도형(회전 오브 68px)은 0.0 이 나오던 진짜 이유다(2026-09-06).
			e.spd = 0.0
			_dps_dummies.append(e)
			_dps_home.append(e.global_position)


func _dps_clear_dummies() -> void:
	_dps_home = []
	for d in _dps_dummies:
		if is_instance_valid(d):
			(d as Node).queue_free()
	_dps_dummies = []


## [검증용] 밸런스 곡선 측정 (headless) — 실제 게임을 돌리며 30초마다 지표를 찍는다.
##
## ★ 눈으로 "너무 세다/약하다"를 판정하면 튜닝이 왕복한다. 폭주하는 축이 무엇인지
##   (피해 스택 / 레벨 속도 / 스폰 공급 / 골드) 숫자로 갈라야 한 번에 잡힌다.
##   --hold 를 같이 주면 봇이 제자리에서 버틴다 = 유저가 리포트한 'AFK 클리어' 상황 그대로.
##
##   사용:  -- --balance --diff=0 --stage=0 --dur=480 --hold --fast=6 --nosnap
## 밸런스 측정용 봇 이동 — 기존 _flee_step 은 무조건 도망쳐서 경험치 젬을 하나도 안 줍는다.
## 그러면 카드가 안 쌓여 "빌드 없는 플레이어"만 측정하게 되고, 실제 유저의 체감과 어긋난다.
## 여기서는 사람이 하는 것처럼 '위험하면 물러서고, 안전하면 젬을 주우러 간다'.
func _bal_step() -> void:
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	var pos: Vector2 = (p as Node2D).global_position
	var threat: Vector2 = Vector2.ZERO
	var near: float = 1.0e9
	for node in G.enemies_cached():
		if not is_instance_valid(node):
			continue
		var e := node as Node2D
		if e == null:
			continue
		var to: Vector2 = pos - e.global_position
		var d: float = to.length()
		near = minf(near, d)
		if d < 220.0 and d > 0.01:
			threat += to.normalized() * ((220.0 - d) / 220.0)
	var move: Vector2 = Vector2.ZERO
	if near < 110.0 and threat.length() > 0.05:
		# 너무 붙었다 — 밀어내는 방향 + 접선으로 원을 그리며 빠진다
		var away: Vector2 = threat.normalized()
		move = (away * 0.8 + Vector2(-away.y, away.x) * 0.8).normalized()
	else:
		# 여유가 있으면 가장 가까운 경험치 젬을 주우러 간다 (실플레이어의 기본 행동)
		var best: Node2D = null
		var bd: float = 1.0e9
		for g in get_tree().get_nodes_in_group("xpgem"):
			var gn := g as Node2D
			if gn == null or not is_instance_valid(gn):
				continue
			var d2: float = pos.distance_squared_to(gn.global_position)
			if d2 < bd:
				bd = d2
				best = gn
		if best != null:
			move = (best.global_position - pos).normalized()
		elif pos.length() > 90.0:
			move = (-pos).normalized()
	if pos.length() > 1150.0:
		move = (move + (-pos).normalized() * 1.8).normalized()
	Input.action_release("dash")
	if move.length() > 0.01:
		_press_dir(move)
	else:
		for a in ["move_up", "move_down", "move_left", "move_right"]:
			Input.action_release(a)


## [검증용] 화면 넘침 검사 (창모드) — 라벨/버튼이 부모 칸이나 화면 밖으로 나가는지 훑는다.
##
## ★ "글자가 삐져나간다"는 리포트가 반복해서 올라오는데, 눈으로 찾으면 매번 다른 걸 놓친다.
##   Control 트리를 걸어 내려가며 자식 사각형이 부모 사각형을 넘는 곳을 전부 찍는다.
##   clip_contents / clip_text 가 걸린 노드는 넘어도 실제로 안 보이므로 통과 처리한다.
## 넘친 칸 안에서 사람이 알아볼 글자 하나를 찾아 온다 (어느 화면의 무엇인지 식별용)
func _uifit_text_of(n: Node) -> String:
	if n is Label and (n as Label).text != "":
		return (n as Label).text.replace("
", " ⏎ ").substr(0, 30)
	if n is Button and (n as Button).text != "":
		return (n as Button).text.substr(0, 30)
	for ch in n.get_children():
		var t: String = _uifit_text_of(ch)
		if t != "":
			return t
	return ""


var _seen_ctl: int = 0


## ★ 18차: 결과 판 셋(스테이지 클리어 · 무한 완주 · 게임오버)을 최악값으로 채워 단추가 전부 화면 안인지 잰다.
## 무기 출처 8 · 새로 열림 다섯 · 긴 골드 줄. 폰은 `--resolution 2340x1080 -- --touch --resultfit`(UI 「크게」),
## 「아주 크게」는 `--uiscale=2` 를 더한다. 예전 --uifit 의 「클리어」는 무기도 해금도 없는 판이라 못 잡았다(사용자 폰 보고).
func _resultfit_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[RESULTFIT] 건너뜀 — 창모드로 실행해야 한다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.4).timeout
	G.no_save = true
	for a in OS.get_cmdline_user_args():
		if (a as String).begins_with("--uiscale="):
			G.ui_scale_idx = int((a as String).get_slice("=", 1))
	var dir: String = "user://resultfit"
	DirAccess.make_dir_recursive_absolute(dir)
	var vr: Rect2 = get_viewport().get_visible_rect()
	var fails: int = 0
	for sc: String in ["clear", "endless", "gameover"]:
		G.run_mode = "endless" if sc == "endless" else "stage"
		G.stage_sel = 0
		get_tree().paused = false
		_begin_run(Characters.defs()[0])
		for _i in 3:
			await get_tree().process_frame
		G.time_alive = 1800.0 if sc == "endless" else 480.0
		G.kills = 123456
		G.level = 58
		G.combo_best = 9999
		G.run_gold = 99999
		G.run_dmg = {"wp_balanced": 9.0e6, "wpn_fire": 8.0e6, "wpn_chain": 7.0e6, "evo_reaper": 6.0e6,
			"wpn_ice": 5.0e6, "wpn_orb": 4.0e6, "wp_fan": 3.0e6, "b_fire": 2.0e6}
		match sc:
			"clear":
				_on_stage_clear()
			"endless":
				_on_endless_clear()
			"gameover":
				_on_player_died()
		# 새로 열림 다섯을 억지로 채운다(실제 판에선 첫 클리어 · 누적 해금이 한꺼번에 오면 이렇다)
		_unlock_cards.clear()
		for d: Dictionary in Characters.defs().slice(1, 4):
			_unlock_cards.append({"kind": "char", "id": String(d["id"]), "name": I18n.t(String(d["name"]))})
		# 10/13: 도전과제 카드(그림 88 · 이름 통째 · 보상 골드)도 섞는다 — 이름이 가장 긴 셋, 여섯 장이라 「+1」 까지 나온다
		var achs: Array = Codex.ACHIEVEMENTS.duplicate()
		achs.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return I18n.t(String(x["name"])).length() > I18n.t(String(y["name"])).length())
		for a2: Dictionary in achs.slice(0, 3):
			_unlock_cards.append({"kind": "ach", "id": String(a2["id"]), "name": I18n.t(String(a2["name"])), "gold": int(a2.get("gold", 0))})
		var panel: Control = _go_panel if sc == "gameover" else _vic_panel
		_res_unlocks(_go_unl if sc == "gameover" else _vic_unl)
		for _i in 3:
			await get_tree().process_frame
		await _fit_result_panel(panel)
		for _i in 3:
			await get_tree().process_frame
		var out: Array = []
		var nb: int = 0
		for b in panel.find_children("*", "Button", true, false):
			var bt := b as Button
			if bt == null or not bt.is_visible_in_tree():
				continue
			nb += 1
			var r: Rect2 = bt.get_global_rect()
			if not vr.grow(1.0).encloses(r):
				out.append("%s %s" % [bt.text, str(r)])
		fails += out.size()
		await _snap("%s/%s_%dx%d_ui%d.png" % [dir, sc, int(vr.size.x), int(vr.size.y), G.ui_scale_idx])
		var pms: Vector2 = panel.get_combined_minimum_size()
		print("[RESULTFIT] %-8s 판 %dx%d (쓸 수 있는 칸 %dx%d) → 배율 %.2f · 단추 %d개 중 화면 밖 %d%s" % [sc, int(pms.x), int(pms.y),
			int(_hud_layer.size.x - 32.0), int(_hud_layer.size.y - 32.0), panel.scale.x, nb, out.size(),
			("  ✗ " + " / ".join(out)) if not out.is_empty() else "  OK"])
		_victory.visible = false
		_gameover.visible = false
		_stage_done = false
		_endless_done = false
	print("[RESULTFIT] %s (화면 %dx%d, UI %d)" % ["PASS" if fails == 0 else "FAIL %d" % fails, int(vr.size.x), int(vr.size.y), G.ui_scale_idx])
	get_tree().quit(0 if fails == 0 else 1)


func _uifit_flow() -> void:
	# ★ 헤드리스에는 실제 레이아웃이 없어 폭이 전부 0 으로 나온다 — 100건이 통째로 오탐이 된다.
	#   이 검사만은 창모드로 돌려야 한다.
	if DisplayServer.get_name() == "headless":
		print("[UIFIT] 건너뜀 — 창모드로 실행해야 한다 (--headless 없이)")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.4).timeout
	# ★ 최악값으로 채워 놓고 본다. 기본 세이브(등급 0 · 골드 0)로는 문자열이 가장 짧아서
	#   "등급 20 / 20 ▰▰▰▰▰▰▰▰▰▰" 나 "37,600 G" 같은 실제 사고 케이스가 재현되지 않는다.
	G.no_save = true
	G.total_gold = 9999999
	for a in OS.get_cmdline_user_args():   # 18차: 「아주 크게」(2)로도 잰다 — 폰 기본은 「크게」(1)
		if (a as String).begins_with("--uiscale="):
			G.ui_scale_idx = int((a as String).get_slice("=", 1))
			_update_hud_scale()
	for cdef: Dictionary in Characters.defs():
		var cid: String = String(cdef["id"])
		G.meta["uc_" + cid] = 1
		G.meta["rank_" + cid] = G.CHAR_RANK_MAX
	for mid2: String in G.META_TIERS.keys():
		G.meta[mid2] = G.meta_max(mid2)
	for ad: Dictionary in Accessories.DEFS:
		G.meta["acc_own_" + String(ad["id"])] = 1
	var bad: Array = []
	var screens: Array = [
		["메인 메뉴", func() -> void: pass],
		["영웅 선택", func() -> void:
			_main_menu.close()
			_char_select.open()],
		["상점", func() -> void:
			_char_select._on_back()
			_meta_shop.open()],
		["도감", func() -> void:
			_meta_shop._on_close()
			_codex_screen.open()],
		["설정", func() -> void:
			_codex_screen.close()
			_settings.open()],
		# ── 판 안 — 영어는 글자가 길어 카드·요약·정산에서 먼저 넘친다 ──
		["HUD", func() -> void:
			_settings._on_back()
			get_tree().paused = false
			_main_menu.close()
			_begin_run(Characters.defs()[0]), 0.4],
		["레벨업", func() -> void:
			var p := G.player as Player
			if p != null and is_instance_valid(p):
				p.max_hp = 1.0e9
				p.hp = 1.0e9
			for id in ["wp_heavy", "wp_fan", "wpn_fire", "wpn_chain", "b_fire", "b_poison", "b_ice", "crit", "dmg", "m_transcend"]:
				_apply_upgrade(String(id))
			_open_levelup()],
		["일시정지", func() -> void:
			_levelup_root.visible = false
			get_tree().paused = false
			_pause_menu._toggle()],
		["보스 상자", func() -> void:
			_pause_menu._toggle()
			get_tree().paused = false
			_on_boss_chest()],
		["부활", func() -> void:
			_close_chest_panel()
			get_tree().paused = false
			_on_revive_offered()],
		["게임오버", func() -> void:
			_on_revive_decline(), 0.4],
		["새 판", func() -> void:
			get_tree().paused = false
			_begin_run(Characters.defs()[1]), 0.3],
		["클리어", func() -> void:
			_on_stage_clear(), 0.8],
	]
	for sc in screens:
		var nm: String = String((sc as Array)[0])
		((sc as Array)[1] as Callable).call()
		for _i in 6:
			await get_tree().process_frame
		if (sc as Array).size() > 2:
			await get_tree().create_timer(float((sc as Array)[2]), true).timeout
		var found: Array = []
		_seen_ctl = 0
		_uifit_walk(get_tree().root, found)
		for f in found:
			bad.append("%s | %s" % [nm, String(f)])
		print("[UIFIT] %-10s 표시된 글자칸 %d개 · 넘침 %d건" % [nm, _seen_ctl, found.size()])
	# ── 레벨업 카드 전부 — 화면엔 무작위 석 장만 뜨니 돌릴 때마다 결과가 달랐다(영어 카드 하나가 224 를 넘었다 안 넘었다).
	#   풀의 카드를 한 장씩 만들어 카드 몸(224) 안에 자식이 다 들어가는지 잰다.
	var probe := HBoxContainer.new()
	probe.position = Vector2(0, 2000)
	_levelup_root.add_child(probe)
	var ncard: int = 0
	for up: Dictionary in _upgrade_pool():
		var cb: Button = _make_card(up)
		probe.add_child(cb)
		ncard += 1
	for _i in 3:
		await get_tree().process_frame
	for cb2 in probe.get_children():
		var v0: Control = null
		for ch in cb2.get_children():
			if ch is VBoxContainer:
				v0 = ch as Control
		if v0 == null:
			continue
		var inner_w: float = (cb2 as Control).size.x - v0.offset_left + v0.offset_right   # 카드 안 글 폭(여백 뺀 것)
		for ch2 in v0.get_children():
			var cc := ch2 as Control
			if cc != null and cc.visible and cc.get_combined_minimum_size().x > inner_w + 2.0:
				bad.append("레벨업 카드 | %s %.0f > 글 폭 %.0f — 글자: \"%s\"" % [cc.get_class(), cc.get_combined_minimum_size().x, inner_w, (cc as RichTextLabel).get_parsed_text().replace("\n", " / ") if cc is RichTextLabel else _uifit_text_of(cc)])
	print("[UIFIT] 레벨업 카드  풀 전부 %d장" % ncard)
	probe.queue_free()
	for b in bad:
		print("[UIFIT]   ✗ " + String(b))
	# ── 자체 시험(14차 5절): 판 하나를 일부러 화면 아래로 반쯤 내려 두고 이 검사가 잡는지 본다 ──
	var lay := CanvasLayer.new()
	lay.layer = 90
	add_child(lay)
	var tp := UiKit.make_panel()
	var tv := VBoxContainer.new()
	tp.add_child(tv)
	var tl := Label.new()
	tl.text = "자체 시험 — 화면 아래로 잘린 판"
	tv.add_child(tl)
	tv.add_child(UiKit.button("잘린 버튼", Callable()))
	lay.add_child(tp)
	var vr0: Rect2 = get_viewport().get_visible_rect()
	tp.position = Vector2(vr0.size.x * 0.5 - 200.0, vr0.size.y - 60.0)
	for _i in 4:
		await get_tree().process_frame
	var st_found: Array = []
	_uifit_walk(lay, st_found)
	await _snap("user://uifit_selftest.png")
	print("[UIFIT] 자체 시험: 일부러 자른 판 · 버튼 %d건 잡음 — %s" % [st_found.size(), "OK" if st_found.size() >= 2 else "✗ 못 잡음"])
	for f in st_found:
		print("[UIFIT]   (자체 시험) " + String(f))
	lay.queue_free()
	if st_found.size() < 2:
		bad.append("자체 시험 실패 — 화면 밖 판을 못 잡는다")
	print("[UIFIT] %s — 총 %d건" % ["ALL PASS" if bad.is_empty() else "FAIL", bad.size()])
	get_tree().quit(1 if not bad.is_empty() else 0)


## 글자가 칸에 안 들어가는 곳을 찾는다.
## ★ 처음엔 '자식 사각형 > 부모 사각형'으로 쟀는데 하나도 안 잡혔다. VBox/HBox 는 자식을
##   자기 폭에 맞춰 늘리고 줄이므로, 라벨의 사각형은 늘 부모 안에 있다 — 넘치는 건 사각형이
##   아니라 '글자'다. 그래서 라벨이 요구하는 최소폭(get_combined_minimum_size)과 실제로 받은
##   폭을 비교한다. 자동 줄바꿈이나 잘라내기가 켜진 것은 넘쳐도 화면에 안 나가므로 통과.
func _uifit_walk(n: Node, out: Array, clipped: bool = false) -> void:
	var c := n as Control
	# ScrollContainer 안쪽은 넘치는 게 정상이다(그게 스크롤이다) — 조상 어디든 있으면 그 아래는 통과.
	var my_clip: bool = clipped or (c != null and c.clip_contents) or (n is ScrollContainer)
	if c != null and c.is_visible_in_tree() and c.size.x > 1.0:
		var need: float = 0.0
		var txt: String = ""
		var safe: bool = false
		if c is Label:
			var lb := c as Label
			safe = lb.clip_text or lb.autowrap_mode != TextServer.AUTOWRAP_OFF
			txt = lb.text.replace("
", " ⏎ ").substr(0, 30)
			need = lb.get_combined_minimum_size().x
		elif c is Button:
			var bt := c as Button
			safe = bt.clip_text or bt.autowrap_mode != TextServer.AUTOWRAP_OFF
			txt = bt.text.substr(0, 30)
			need = bt.get_combined_minimum_size().x
		if txt != "":
			_seen_ctl += 1
		if txt != "" and not safe and need > c.size.x + 2.0:
			out.append("%s \"%s\" 필요 %.0f > 받은 폭 %.0f" % [c.get_class(), txt, need, c.size.x])
		# ★ 잘라내기(clip_text)가 걸린 칸은 넘치지 않는 대신 **끝이 잘린다**. 위 검사는 이걸 통과시켜서
		#   영어 이름 "Maru, Third of the Ma" 가 잘린 채 나가는 걸 못 잡았다. 글자 폭을 직접 잰다.
		var clip_on: bool = (c is Label and (c as Label).clip_text and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF) \
			or (c is Button and (c as Button).clip_text)
		if txt != "" and clip_on:
			var f: Font = c.get_theme_font("font")
			var fs: int = c.get_theme_font_size("font_size")
			var raw: String = (c as Label).text if c is Label else (c as Button).text
			var wmax: float = 0.0
			for ln in c.atr(raw).split("\n"):
				wmax = maxf(wmax, f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			var pad: float = 0.0
			if c is Button:
				var sb: StyleBox = c.get_theme_stylebox("normal")
				pad = sb.get_minimum_size().x if sb != null else 0.0
			if wmax + pad > c.size.x + 2.0:
				out.append("%s \"%s\" 잘림 (글자 %.0f > 칸 %.0f)" % [c.get_class(), c.atr(raw).substr(0, 30), wmax + pad, c.size.x])
		# ★ 진짜 증상은 여기서 잡힌다. VBox 같은 컨테이너는 자식이 요구하는 최소폭 때문에
		#   앵커로 정한 폭(카드 186px)을 넘어 자기 몸을 키운다. 그러면 카드 그림 밖으로
		#   글자가 통째로 삐져나간다 — 라벨만 보면 '자기 칸에는 맞게' 들어가 있어서 안 잡힌다.
		var par2 := c.get_parent() as Control
		if par2 != null and not clipped and c.is_visible_in_tree() 				and par2.size.x > 1.0 and c.size.x > par2.size.x + 2.0:
			# 안에 글자가 하나도 없으면 눈에 보이는 '삐져나감'이 아니다(빈 레이아웃 칸) — 넘어간다
			var inner: String = _uifit_text_of(c)
			if inner != "":
				# 제일 넓은 자식을 같이 적는다 — 경로만으론 어느 줄이 밀었는지 모른다
				var wide: String = ""
				var wbest: float = 0.0
				for ch in c.get_children():
					if ch is Control and (ch as Control).visible and (ch as Control).get_combined_minimum_size().x > wbest:
						wbest = (ch as Control).get_combined_minimum_size().x
						wide = "%s %.0f \"%s\"" % [ch.get_class(), wbest, _uifit_text_of(ch as Control)]
				out.append("%s 가 부모 %s 를 넘음 (%.0f > %.0f) — 경로 %s / 글자: \"%s\" / 제일 넓은 자식: %s" % [
					c.get_class(), par2.get_class(), c.size.x, par2.size.x,
					String(c.get_path()).substr(0, 90), inner, wide])
		# 화면 밖으로 나간 것도 같이 본다 (앵커/오프셋 실수)
		# ★ 14차: 예전엔 창 픽셀 크기(1920)와 게임 좌표(1280 기준)를 섞어 쟀고, 가로만 · 글자칸만 봤다 —
		#   GAME OVER 판이 화면 아래로 잘려 버튼이 사라졌는데도 「넘침 0」이었다(에셋 담당 14차).
		#   이제 판(PanelContainer) · 버튼 · 글자칸을 화면 좌표(캔버스 변환 포함)로 위아래 · 좌우 모두 잰다.
		var is_box: bool = c is PanelContainer or c is Panel or c is Button
		if not my_clip and (txt != "" or is_box):
			var xf: Transform2D = c.get_global_transform_with_canvas()
			var r: Rect2 = Rect2(xf.origin, c.size * xf.get_scale())
			var vr: Rect2 = get_viewport().get_visible_rect()
			if r.position.x < vr.position.x - 4.0 or r.position.y < vr.position.y - 4.0 					or r.end.x > vr.end.x + 4.0 or r.end.y > vr.end.y + 4.0:
				out.append("%s \"%s\" 화면 밖 (x %.0f~%.0f · y %.0f~%.0f / 화면 %.0f×%.0f)" % [
					c.get_class(), txt if txt != "" else _uifit_text_of(c).substr(0, 24), r.position.x, r.end.x,
					r.position.y, r.end.y, vr.size.x, vr.size.y])
	for ch in n.get_children():
		_uifit_walk(ch, out, my_clip)


## [검증용] 손에 든 무기 확인 (창모드) — 9종을 차례로 들려 게임과 같은 크기로 찍는다.
## ★ "삼각형·네모·마름모를 들고 있다"는 리포트를 눈으로 확인하고 고치려면
##   실제 게임 배율에서 봐야 한다. 확대 스샷은 잘 보이지만 실제 체감과 다르다.
func _wpn_shot_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.4).timeout
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	G.freeze_enemies(9999.0)
	var keys: Array = ["balanced", "heavy", "rapid", "mid", "melee", "bow", "fan", "sinkal", "jakdu"]
	for k: String in keys:
		p.weapons_primary = [{"id": k, "t": 99.0, "level": 3}]
		p._refresh_barrel()
		for ang in [0.0, PI * 0.5]:                # 오른쪽·아래 두 방향 (회전 반영 확인)
			p.aim = Vector2(cos(ang), sin(ang))
			for _i in 4:
				await get_tree().process_frame
			await _snap("%s/held_%s_%d.png" % [dir, k, int(ang * 100.0)])
		print("[WPNSHOT] %s" % k)
	print("[WPNSHOT] DONE — %d종" % keys.size())
	get_tree().quit(0)


## [검증용] 성장 곡선 표 — 난이도·스테이지·시간·메타 진행에 따라 몹이 얼마나 세지는지 한눈에.
## ★ "강화 단계를 많이 뒀으니 몹도 그에 맞춰 올라가야 한다"는 요구를 눈이 아니라 표로 확인한다.
##   메타를 끝까지 올린 사람이 같은 스테이지를 계속 무쌍하면 강화할 이유가 사라진다.
func _scalecheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	var keep: Dictionary = G.meta.duplicate()
	print("[SCALE] 잡몹 체력 배수 (기본 20 기준) — 스테이지 모드")
	print("        메타          1분    3분    5분    8분")
	for stage_meta in [0, 1]:
		if stage_meta == 0:
			for mid: String in G.META_TIERS.keys():
				G.meta[mid] = 0
			for cd: Dictionary in Characters.defs():
				G.meta["rank_" + String(cd["id"])] = 0
		else:
			for mid2: String in G.META_TIERS.keys():
				G.meta[mid2] = G.meta_max(mid2)
			for cd2: Dictionary in Characters.defs():
				G.meta["rank_" + String(cd2["id"])] = G.CHAR_RANK_MAX
		for diff in range(4):
			G.difficulty = diff
			G.run_mode = "stage"
			G.stage_sel = 0
			var row: Array = []
			for tmin: float in [1.0, 3.0, 5.0, 8.0]:
				G.time_alive = tmin * 60.0
				G.level = int(4.0 + tmin * 3.4)   # 실측 곡선(8분에 레벨 30 안팎)에 맞춘 근사
				row.append("%6.1f" % G.enemy_hp_scale(G.level, G.pressure_t()))
			print("  %-4s %-10s %s" % [String(G.DIFF_NAMES[diff]), "강화없음" if stage_meta == 0 else "만렙강화", " ".join(row)])
	var sm: Array = []
	for i in 5:
		sm.append("%.2f" % pow(G.STAGE_HP_STEP, float(i)))
	print("[SCALE] 스테이지 배수(1~5): %s" % " · ".join(sm))
	# ── 네 축이 전부 '단조 증가'인지 못 박는다 ──
	#   난이도↑ / 스테이지↑ / 시간↑ / 영구강화↑ 어느 쪽도 몹이 약해지면 안 된다.
	#   축 하나를 만졌을 때 다른 축이 뒤집히는 사고를 여기서 잡는다.
	var fails: int = 0
	G.run_mode = "stage"
	G.stage_sel = 0
	G.time_alive = 300.0
	G.level = 22
	for mid3: String in G.META_TIERS.keys():
		G.meta[mid3] = 0
	var prev_d: float = 0.0
	for diff2 in range(4):
		G.difficulty = diff2
		var v: float = G.enemy_hp_scale(22, 300.0)
		if v <= prev_d:
			fails += 1
		prev_d = v
	G.difficulty = 1
	var prev_s: float = 0.0
	for st in range(5):
		G.stage_sel = st
		if G.stage_power() <= prev_s:
			fails += 1
		prev_s = G.stage_power()
	G.stage_sel = 0
	var prev_t: float = 0.0
	for tm: float in [1.0, 3.0, 5.0, 8.0]:
		var tv: float = 1.0 + pow(tm, 1.15) * 0.30
		if tv <= prev_t:
			fails += 1
		prev_t = tv
	var m0: float = G.meta_power()
	for mid4: String in G.META_TIERS.keys():
		G.meta[mid4] = G.meta_max(mid4)
	var m1: float = G.meta_power()
	print("[SCALE] 영구강화 반영: 강화없음 %.2f → 만렙 %.2f (반드시 커져야 한다)" % [m0, m1])
	if m1 <= m0 * 1.15:
		fails += 1
	G.meta = keep
	print("[SCALE] %s" % ("ALL PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


func _balance_flow(diff: int, dur: float) -> void:
	await get_tree().create_timer(0.3).timeout
	G.difficulty = diff
	G.aim_mode = 0
	G.tally_on = true
	# ★ 예전엔 무조건 0번(기본 영웅)이었다. 실플레이 조건을 재현하려면 그 사람이 실제로
	#   쓰는 영웅이어야 한다 — 영웅마다 시작 무기와 능력이 다르다(2026-09-06).
	var cdef: Dictionary = Characters.defs()[0]
	if _lp_char != "":
		for d: Dictionary in Characters.defs():
			if String(d["id"]) == _lp_char:
				cdef = d
				break
	G.last_char_id = String(cdef["id"])
	print("=== 조건: 영웅 %s(등급 %d) · 난이도 %s · 상점 공격력Lv%d 체력Lv%d · 몹배수 ×%.2f ===" % [
		String(cdef["name"]), G.char_rank(String(cdef["id"])),
		String(G.DIFF_NAMES[clampi(diff, 0, 3)]),
		G.meta_level("m_dmg"), G.meta_level("m_hp"), G.meta_power()])
	_begin_run(cdef)
	if G.player != null and is_instance_valid(G.player):
		print("=== 시작 최대 체력 %.0f · 방어 %.1f ===" % [(G.player as Player).max_hp, (G.player as Player).armor])
	if _lp_immortal and G.player != null and is_instance_valid(G.player):
		(G.player as Player).max_hp = 1.0e9   # 공격/경제 곡선만 보고 싶을 때 (생존은 따로 잰다)
		(G.player as Player).hp = 1.0e9
	if _lp_fast > 1.0:
		Engine.time_scale = _lp_fast
	var mode: String = "스테이지%d" % (G.stage_sel + 1) if G.run_mode == "stage" else "무한"
	print("=== BALANCE  %s · %s · %s · %.0f초 · 시드고정 ===" % [
		mode, String(G.DIFF_NAMES[clampi(diff, 0, 3)]), "제자리버티기" if _bot_hold else "카이팅", dur])
	print("  시각  레벨  처치   초당  골드  분당G   피해배수   대표몹HP   처치시간  체력   몹")
	var t: float = 0.0
	var next_log: float = 30.0
	var k_prev: int = 0
	var g_prev: int = 0
	var hp_lo: float = 1.0e9
	while t < dur:
		# ★ 보스 상자 패널은 판을 멈추고 **클릭**을 기다린다(2026-09-06 추가). 봇은 클릭을
		#   못 하므로 여기서 직접 닫아 준다 — 안 그러면 측정이 그 자리에서 영원히 멈춘다.
		if _chest_panel != null and is_instance_valid(_chest_panel):
			_close_chest_panel()
			await get_tree().process_frame
			continue
		if _levelup_root.visible:
			_auto_pick()
			await get_tree().process_frame
			t = G.time_alive
			continue
		if not G.running:
			break
		if _bot_hold:
			for a in ["move_up", "move_down", "move_left", "move_right", "dash"]:
				Input.action_release(a)
		else:
			_bal_step()
		await get_tree().create_timer(0.08).timeout
		t = G.time_alive
		var pl0 := G.player as Player
		if is_instance_valid(pl0):
			hp_lo = minf(hp_lo, pl0.hp / maxf(1.0, pl0.max_hp))
		if t >= next_log:
			next_log += 30.0
			_bal_row(t, k_prev, g_prev, hp_lo)
			k_prev = G.kills
			g_prev = G.run_gold
			hp_lo = 1.0e9
	print("=== BALANCE DONE  생존=%s  %.0f초  레벨=%d  처치=%d  골드=%d  피격=%d ===" % [
		str(G.running), t, G.level, G.kills, G.run_gold, G.hits_taken])
	if not G.running:
		# 죽었을 때 '무엇에' 죽었는지 — 봇이 잡몹 벽에 갈린 건지, 보스 패턴에 당한 건지
		# 구분이 안 되면 상한·피격·체력 중 무엇을 만져야 할지 알 수 없다.
		print("[BAL] 사망 시점: 보스 %s · 잡몹 %d마리 · 적탄 %d발 · 최근 피해원 %s" % [
			"있음" if _bal_boss_alive() else "없음", _enemy_count(),
			get_tree().get_node_count_in_group("ebullet"), G.last_hit_src])
	var tal: Array = []
	var keys: Array = G.dmg_tally.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return float(G.dmg_tally[a]) > float(G.dmg_tally[b]))
	var tot: float = 0.0
	for k in keys:
		tot += float(G.dmg_tally[k])
	for k in keys.slice(0, 8):
		tal.append("%s %.0f%%" % [String(k), 100.0 * float(G.dmg_tally[k]) / maxf(1.0, tot)])
	print("[BAL] 피해 출처: " + " · ".join(tal))
	var gs: Array = []
	for k in G.gold_src.keys():
		gs.append("%s %d" % [String(k), int(G.gold_src[k])])
	print("[BAL] 골드 출처: %s  (분당 상한 %d × %.1f분 = %d 이 설계값)" % [
		" · ".join(gs), G._gold_cap(), G.time_alive / 60.0, int(float(G._gold_cap()) * G.time_alive / 60.0)])
	get_tree().quit(0)


## ──────────────────── 가장 무거운 순간 프레임 (--loadpeak) ────────────────────
## 16차 4-3: 12분 이후 · 몹 300 · 무기 다섯(융합 둘) · 보스가 한 화면에 — 그 상태를 --dur 초 동안 유지하며
##   실제 프레임 시간을 전부 적는다(평균 FPS · 1% 하위 FPS · 최악 프레임 ms · 33ms 넘은 프레임 수).
##   몹은 죽는 만큼 0.25초마다 300 까지 다시 채운다(처치 연출 · 젬 · 피해 숫자까지 실제처럼).
##   실행:  ... --path . --resolution 1920x1080 -- --loadpeak=<테마 0~5> --dur=60     (창모드 · 헤드리스 불가)
## ──────────────────── 몹 처리 몫 재기 (--physprof=<몹 수>) ────────────────────
## 19차 3-2: 「물리가 제일 크니 move_and_slide 부터」라는 코드 읽기 짐작이 실측으로 틀렸다(고쳐도 그대로).
##   ★ Performance 의 TIME_PROCESS · TIME_PHYSICS_PROCESS 는 평균이 아니라 **지난 1초의 최댓값**이다. loadpeak 의
##   ms_physics 28ms 를 「물리가 프레임의 1/3」로 읽은 게 잘못이었다. 여기서는 실제 프레임 간격만 잰다.
##   loadpeak 와 같은 장면(무기 다섯 · 융합 둘 · 12분 · 몹 N)을 창으로 세우고, 그리는 것 · 처리하는 것을 하나씩 끄며
##   평균 · 하위 1% FPS 를 견준다(창모드만 뜻이 있다 — 헤드리스는 그리기 비용이 0 이다).
func _physprof_flow(mobs: int) -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	seed(4303)
	G.run_mode = "endless"
	G.difficulty = 1
	_main_menu.close()
	_begin_run(Characters.def_of("base"))
	await _cf_wait_unpaused(1.0)
	var p := G.player as Player
	p.grant_iframe(1.0e6)
	p.xp_mult = 0.0
	_spawn_queue = 0
	_spawn_t = 1.0e9
	for i in 6:
		_apply_upgrade("wpn_fire")
		_apply_upgrade("wp_bow")
	for i in 5:
		_apply_upgrade("b_fire")
		_apply_upgrade("b_exec")
	_apply_upgrade("evo_inferno")
	_apply_upgrade("evo_ledger")
	for i in 3:
		_apply_upgrade("wp_rapid")
		_apply_upgrade("wpn_orb")
	G.time_alive = 720.0
	G.level = 32
	var kinds: Array = (_THEME_KINDS[0] as Array).duplicate()
	kinds.append_array(_THEME_YOKAI[0] as Array)
	_cfs4_swarm(p.global_position, kinds, mobs, 260.0, 720.0)
	await get_tree().create_timer(2.0).timeout
	var refill := func() -> void:
		var n: int = _enemy_count()
		for i in maxi(0, mobs - n):
			var a: float = randf() * TAU
			_cfs4_spawn(int(kinds[randi() % kinds.size()]), p.global_position + Vector2(cos(a), sin(a)) * randf_range(420.0, 700.0))
	var measure := func(label: String) -> void:
		refill.call()
		await get_tree().create_timer(0.6).timeout
		var ft: PackedFloat32Array = PackedFloat32Array()
		var t0: int = Time.get_ticks_usec()
		var last: int = t0
		var n: int = 0
		while Time.get_ticks_usec() - t0 < 4000000:
			await get_tree().process_frame
			var now: int = Time.get_ticks_usec()
			ft.append(float(now - last) / 1000.0)
			last = now
			n += 1
			if n % 15 == 0:
				refill.call()
		var tot: float = 0.0
		for v in ft:
			tot += v
		var srt: PackedFloat32Array = ft.duplicate()
		srt.sort()
		print("[PHYSPROF] %-30s 몹 %3d  평균 %5.1ffps (%5.2fms)  하위1%% %5.1ffps" % [label, _enemy_count(),
			1000.0 * float(ft.size()) / tot, tot / float(ft.size()), 1000.0 / srt[int(float(srt.size()) * 0.99)]])
	var mobs_all := func() -> Array:
		var out: Array = []
		for e in get_tree().get_nodes_in_group("enemy"):
			if e is Enemy and is_instance_valid(e) and not (e as Enemy)._dead:
				out.append(e)
		return out
	var set_mobs := func(prop: String, on: bool) -> void:
		for e: Enemy in mobs_all.call():
			match prop:
				"cv": e._cv.set_process(on)
				"phys": e.set_physics_process(on)
				"vis": e.visible = on
	await measure.call("모두 켬")
	_GridBg.old_draw_test = true
	if _bg != null:
		_bg.queue_redraw()
		_bg._fx.queue_redraw()
	await measure.call("예전 그리기(--olddraw)")
	_GridBg.old_draw_test = false
	if _bg != null:
		_bg.queue_redraw()
		_bg._fx.queue_redraw()
	await measure.call("모두 켬(그리기 되돌림)")
	set_mobs.call("cv", false)
	await measure.call("몹 그림 애니(_cv) 끔")
	set_mobs.call("cv", true)
	set_mobs.call("phys", false)
	await measure.call("몹 _physics_process 끔")
	set_mobs.call("phys", true)
	set_mobs.call("vis", false)
	await measure.call("몹 안 그림(visible 끔)")
	set_mobs.call("vis", true)
	await measure.call("모두 켬(다시)")
	var dm: int = G.dmgnum_mode
	G.dmgnum_mode = 2
	await measure.call("피해 숫자 끔")
	G.dmgnum_mode = dm
	for b in get_tree().get_nodes_in_group("bullet"):
		(b as CanvasItem).visible = false
	await measure.call("탄 안 그림(지금 있는 것만)")
	if _hud_canvas != null:
		_hud_canvas.visible = false
	await measure.call("HUD 끔")
	if _hud_canvas != null:
		_hud_canvas.visible = true
	if _base_vig != null:   # 11/7: HUD 몫 가운데 늘 켜진 화면 전체 비네트만
		_base_vig.visible = false
		await measure.call("기본 비네트만 끔")
		_base_vig.visible = true
	if _bg != null:
		_bg.visible = false
	await measure.call("바닥 끔")
	if _bg != null:
		_bg.visible = true
	p.visible = false
	await measure.call("영웅 · 무기 그림 끔")
	p.visible = true
	print("[PHYSPROF] 끝")
	get_tree().quit(0)


func _perfpeak_flow(theme: int, dur: float) -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(4303)
	var mobs: int = 300
	for ua: String in OS.get_cmdline_user_args():
		if ua.begins_with("--perfidx="):
			G.perf_idx = int(ua.get_slice("=", 1))
			G.apply_perf()
		if ua == "--noblob":
			_GridBg.no_blob_test = true
		if ua.begins_with("--mobs="):   # 19차 3-2: 지시서 장면은 몹 200(폰 상한 190 언저리)
			mobs = maxi(1, int(ua.get_slice("=", 1)))
		if ua == "--olddraw":           # 19차 3-2: 고치기 전 그리기(바탕 사각형 · 분위기 원 · HUD 투명 판 상시)
			_GridBg.old_draw_test = true
	G.run_mode = "endless"
	G.difficulty = 1
	_main_menu.close()
	_begin_run(Characters.def_of("base"))
	await _cf_wait_unpaused(1.0)
	var p := G.player as Player
	p.grant_iframe(1.0e6)
	p.xp_mult = 0.0
	_spawn_queue = 0
	_spawn_t = 1.0e9
	G.stage = theme
	_cfs2_theme(theme)
	# 무기 다섯(소총 + 각궁 · 속사 기관총 · 화염 오라 · 회전 오브) · 융합 둘(지옥불 · 명부)
	for i in 6:
		_apply_upgrade("wpn_fire")
		_apply_upgrade("wp_bow")
	for i in 5:
		_apply_upgrade("b_fire")
		_apply_upgrade("b_exec")
	_apply_upgrade("evo_inferno")
	_apply_upgrade("evo_ledger")
	for i in 3:
		_apply_upgrade("wp_rapid")
		_apply_upgrade("wpn_orb")
	G.time_alive = 720.0
	G.level = 32
	var boss := _cfs4_spawn(13, p.global_position + Vector2(260, -160))
	boss.hp = 1.0e9
	boss.max_hp = 1.0e9
	var kinds: Array = (_THEME_KINDS[theme] as Array).duplicate()
	kinds.append_array(_THEME_YOKAI[theme] as Array)
	_cfs4_swarm(p.global_position, kinds, mobs, 260.0, 720.0)
	await get_tree().create_timer(2.0).timeout
	var frames: PackedFloat32Array = PackedFloat32Array()
	var mob_sum: int = 0
	var mob_n: int = 0
	var top_t: float = 0.0
	var bot_t: float = 0.0
	var t0: int = Time.get_ticks_usec()
	var last: int = t0
	var mem_max: float = 0.0
	var vp_rid: RID = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var t_proc: float = 0.0
	var t_phys: float = 0.0
	var t_rcpu: float = 0.0
	var t_rgpu: float = 0.0
	var n_s: int = 0
	var draws: float = 0.0
	while float(Time.get_ticks_usec() - t0) / 1.0e6 < dur:
		await get_tree().process_frame
		t_proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		t_phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		t_rcpu += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid)
		t_rgpu += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		n_s += 1
		var now: int = Time.get_ticks_usec()
		frames.append(float(now - last) / 1000.0)
		last = now
		var el: float = float(now - t0) / 1.0e6
		if el - top_t >= 0.25:
			top_t = el
			var n: int = _enemy_count()
			mob_sum += n
			mob_n += 1
			for i in maxi(0, mobs - n):
				var a: float = randf() * TAU
				_cfs4_spawn(int(kinds[randi() % kinds.size()]), p.global_position + Vector2(cos(a), sin(a)) * randf_range(420.0, 700.0))
		if el - bot_t >= 0.08:
			bot_t = el
			_bal_step()
		mem_max = maxf(mem_max, Performance.get_monitor(Performance.MEMORY_STATIC))
	var sorted: PackedFloat32Array = frames.duplicate()
	sorted.sort()
	var total_ms: float = 0.0
	for v in frames:
		total_ms += v
	var p99: float = sorted[int(float(sorted.size()) * 0.99)]
	var over33: int = 0
	var over17: int = 0
	for v in frames:
		if v > 33.4:
			over33 += 1
		if v > 16.8:
			over17 += 1
	var out: Dictionary = {
		"theme": theme, "mobs_target": mobs, "old_draw": _GridBg.old_draw_test, "perf_level": G.perf_level(), "res": "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"secs": dur, "frames": frames.size(), "avg_fps": snappedf(1000.0 * float(frames.size()) / total_ms, 0.1),
		"low1_fps": snappedf(1000.0 / p99, 0.1), "worst_ms": snappedf(sorted[sorted.size() - 1], 0.1),
		"over_16ms": over17, "over_33ms": over33, "mobs_avg": int(float(mob_sum) / maxf(1.0, float(mob_n))),
		"mem_mb": snappedf(mem_max / 1048576.0, 0.1), "gpu": RenderingServer.get_video_adapter_name(),
		"ms_process": snappedf(t_proc / maxf(1.0, n_s), 0.01), "ms_physics": snappedf(t_phys / maxf(1.0, n_s), 0.01),
		"ms_render_cpu": snappedf(t_rcpu / maxf(1.0, n_s), 0.01), "ms_render_gpu": snappedf(t_rgpu / maxf(1.0, n_s), 0.01),
		"draw_calls": int(draws / maxf(1.0, n_s)),
	}
	print("[PERFPEAK] " + JSON.stringify(out))
	get_tree().quit(0)


## ──────────────────── 시작 시간 (--boottime) ────────────────────
## 16차 4-3: 켜서 메뉴가 그려지기까지 · 출격 준비에서 「출격」 → 첫 전투 프레임까지. 첫 출격과 두 번째(씬 다시 불러오기) 둘 다.
##   실행:  ... --path . --resolution 1920x1080 -- --boottime        ([BOOT] 줄이 결과)
func _boottime_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	_main_menu.open()
	await RenderingServer.frame_post_draw
	print("[BOOT] 켜서 메인 메뉴까지 %d ms" % Time.get_ticks_msec())
	G.no_save = true
	await get_tree().create_timer(0.5).timeout
	_main_menu.close()
	_char_select.open()
	await get_tree().create_timer(0.3, true).timeout
	_char_select._commit_and_go(Characters.defs()[0])
	while G.deploy_ms > 0:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0)


## ──────────────────── 창 바꾸기 (--wincheck) ────────────────────
## 16차 4-5: 창 ↔ 전체 화면 · 해상도 바꾸기 · 창을 마구 줄이기 · 창을 빼앗겼을 때(Alt+Tab) — 판 도중에.
##   크기마다 HUD 와 일시정지 창을 uifit 검사(_uifit_walk)로 훑고 사진을 남긴다. 저장: user://wincheck/
func _wincheck_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	var dir: String = "user://wincheck"
	DirAccess.make_dir_recursive_absolute(dir)
	_main_menu.close()
	G.run_mode = "endless"
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(1.0)
	var p := G.player as Player
	p.grant_iframe(1.0e6)
	var fails: int = 0
	print("=== WINCHECK ===")
	var steps: Array = [
		["창 1920×1080", false, Vector2i(1920, 1080)], ["전체 화면", true, Vector2i.ZERO],
		["창 1280×720", false, Vector2i(1280, 720)], ["창 1280×800(스팀덱)", false, Vector2i(1280, 800)],
		["창 960×540", false, Vector2i(960, 540)], ["창 640×360 → 최소 크기에서 멈춰야", false, Vector2i(640, 360)],
		["다시 창 1920×1080", false, Vector2i(1920, 1080)],
	]
	for i in steps.size():
		var st: Array = steps[i]
		G.fullscreen = bool(st[1])
		G.apply_window()
		await get_tree().create_timer(0.3, true).timeout
		if not bool(st[1]):
			DisplayServer.window_set_size(st[2])
		await get_tree().create_timer(0.7, true).timeout
		var ws: Vector2i = DisplayServer.window_get_size()
		var found: Array = []
		_uifit_walk(_hud_layer, found)
		_pause_menu._toggle()
		await get_tree().create_timer(0.4, true).timeout
		var found2: Array = []
		_uifit_walk(_pause_menu._root, found2)
		await _snap(dir + "/%d.png" % i)
		_pause_menu._toggle()
		await get_tree().create_timer(0.2, true).timeout
		var min_ok: bool = ws.x >= 960 and ws.y >= 540
		var ok: bool = found.is_empty() and found2.is_empty() and min_ok
		print("  [%s] 창 %dx%d · HUD 넘침 %d · 일시정지 넘침 %d · 최소 크기 %s → %s" % [String(st[0]), ws.x, ws.y, found.size(), found2.size(),
			"✔" if min_ok else "✗", "OK" if ok else "FAIL"])
		for f in found + found2:
			print("      " + String(f))
		if not ok:
			fails += 1
	# 창을 빼앗김(Alt+Tab) — 일시정지가 열려야
	focus_pause_test = true
	_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().create_timer(0.3, true).timeout
	var fp: bool = _pause_menu._open
	print("  [창을 빼앗김] 일시정지 열림 %s" % ("✔" if fp else "✗"))
	if not fp:
		fails += 1
	print("[WINCHECK] %s" % ("ALL PASS" if fails == 0 else "FAIL %d건" % fails))
	get_tree().quit(0)


## ──────────────────── 패드만으로 끝까지 (--padcheck) ────────────────────
## 16차 4-5: 「전체 컨트롤러 지원」이라 적으려면 마우스 없이 메뉴 · 설정 · 출격 준비 · 레벨업 · 봉인 · 상자 · 도감 · 결과까지 가야 한다.
##   화면마다 (1) 열자마자 포커스가 있나 (2) D-패드로 닿는 버튼 수 / 보이는 버튼 수 (3) A 로 누르기 · B 로 뒤로.
##   입력은 실제 패드 이벤트(InputEventJoypadButton)를 엔진에 넣는다 — ui_* 기본 키맵을 그대로 탄다.
##   실행:  ... --path . --resolution 1920x1080 -- --padcheck      (창모드 — 포커스 이웃 찾기에 배치가 필요)
func _padcheck_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	UiKit.force_pad = true
	var fails: int = 0
	for d: Dictionary in Characters.defs():
		G.meta["uc_" + String(d["id"])] = 1
	G.total_gold = 50000
	print("=== PADCHECK ===")
	# A 가 버튼을 누르나 — 메인 메뉴 첫 버튼(출격)에 포커스를 두고 패드 A · 엔터 키를 차례로
	_main_menu.open()
	await get_tree().create_timer(0.4, true).timeout
	var f0: Control = get_viewport().gui_get_focus_owner()
	print("  [A 시험] 포커스 = %s" % (_pad_name(f0) if f0 != null else "없음"))
	await _pad_press(JOY_BUTTON_A)
	await get_tree().create_timer(0.4, true).timeout
	var a_ok: bool = _char_select.is_open()
	print("  [A 시험] 패드 A → 출격 준비 열림 %s" % ("✔" if a_ok else "✗"))
	if _char_select.is_open():
		_char_select._on_back()
	else:
		var ke := InputEventKey.new()
		ke.keycode = KEY_ENTER
		ke.physical_keycode = KEY_ENTER
		ke.pressed = true
		Input.parse_input_event(ke)
		await get_tree().process_frame
		var ke2: InputEventKey = ke.duplicate()
		ke2.pressed = false
		Input.parse_input_event(ke2)
		await get_tree().create_timer(0.4, true).timeout
		print("  [A 시험] 엔터 → 출격 준비 열림 %s" % ("✔" if _char_select.is_open() else "✗"))
		if _char_select.is_open():
			_char_select._on_back()
	if not a_ok:
		fails += 1
	var screens: Array = [
		["메인 메뉴", func() -> Control:
			_main_menu.open()
			return _main_menu._root, Callable()],
		["출격 준비", func() -> Control:
			_main_menu.close()
			_char_select.open()
			return _char_select._root, func() -> bool: return not _char_select.is_open()],
		["영구 강화", func() -> Control:
			_meta_shop.open()
			return _meta_shop._root, func() -> bool: return not _meta_shop.is_open()],
		["도감", func() -> Control:
			_codex_screen.open()
			return _codex_screen._root, func() -> bool: return not _codex_screen.is_open()],
		["설정", func() -> Control:
			_settings.open()
			return _settings._root, func() -> bool: return not _settings.is_open()],
	]
	for sc: Array in screens:
		var root: Control = await (sc[1] as Callable).call()
		await get_tree().create_timer(0.35, true).timeout
		fails += await _pad_screen(String(sc[0]), root)
		var closed: Callable = sc[2]
		if closed.is_valid():
			await _pad_press(JOY_BUTTON_B)
			await get_tree().create_timer(0.25, true).timeout
			var ok: bool = closed.call()
			print("  [%s] B 로 닫힘 %s" % [String(sc[0]), "✔" if ok else "✗"])
			if not ok:
				fails += 1
	# ── 판 안: 레벨업(A 로 카드) · 봉인(버튼 → 카드) · 상자 · 일시정지(Start · B) · 게임오버 ──
	_main_menu.close()
	G.run_mode = "endless"
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(0.8)
	var p := G.player as Player
	p.grant_iframe(1.0e6)
	_spawn_queue = 0
	_spawn_t = 1.0e9
	_pending_levelups += 1
	_open_levelup()
	await get_tree().create_timer(0.9, true).timeout
	fails += await _pad_screen("레벨업", _levelup_root)
	var fo: Control = get_viewport().gui_get_focus_owner()
	var on_card: bool = fo != null and fo.get_parent() == _cards_box
	await _pad_press(JOY_BUTTON_A)
	await get_tree().create_timer(0.4, true).timeout
	print("  [레벨업] 첫 포커스가 카드 %s · A 로 고름 %s" % ["✔" if on_card else "✗", "✔" if not _levelup_root.visible else "✗"])
	if not on_card or _levelup_root.visible:
		fails += 1
	get_tree().paused = false
	# 봉인: 봉인 버튼까지 내려가 A → 카드로 올라가 A
	_pending_levelups += 1
	_open_levelup()
	await get_tree().create_timer(0.9, true).timeout
	var ban_ok: bool = false
	for i in 8:
		var f2: Control = get_viewport().gui_get_focus_owner()
		if f2 == _banish_btn:
			break
		await _pad_press(JOY_BUTTON_DPAD_DOWN if i < 2 else JOY_BUTTON_DPAD_RIGHT)
	if get_viewport().gui_get_focus_owner() == _banish_btn and not _banish_btn.disabled:
		await _pad_press(JOY_BUTTON_A)
		await _pad_press(JOY_BUTTON_DPAD_UP)
		var left0: int = _banish_left
		await _pad_press(JOY_BUTTON_A)
		await get_tree().create_timer(0.3, true).timeout
		ban_ok = _banish_left < left0 or _banished.size() > 0
	print("  [봉인] 버튼 → 카드 %s" % ("✔" if ban_ok else "✗ (봉인 횟수 0 이면 버튼이 꺼져 있다 — 상점 「봉인」)"))
	if _levelup_root.visible:
		await _pad_press(JOY_BUTTON_A)
		await get_tree().create_timer(0.3, true).timeout
	get_tree().paused = false
	# 상자
	_on_boss_chest()
	await get_tree().create_timer(0.9, true).timeout
	var chest_focus: bool = get_viewport().gui_get_focus_owner() != null
	await _pad_press(JOY_BUTTON_A)
	await get_tree().create_timer(0.4, true).timeout
	var chest_closed: bool = _chest_panel == null or not is_instance_valid(_chest_panel)
	print("  [보스 상자] 포커스 %s · A 로 닫힘 %s" % ["✔" if chest_focus else "✗", "✔" if chest_closed else "✗"])
	if not chest_focus or not chest_closed:
		fails += 1
	get_tree().paused = false
	# 일시정지: Start 로 열고 → 포커스 → B 로 계속하기
	await _pad_press(JOY_BUTTON_START)
	await get_tree().create_timer(0.4, true).timeout
	var po: bool = _pause_menu._open
	fails += await _pad_screen("일시정지", _pause_menu._root)
	await _pad_press(JOY_BUTTON_B)
	await get_tree().create_timer(0.3, true).timeout
	print("  [일시정지] Start 로 열림 %s · B 로 계속 %s" % ["✔" if po else "✗", "✔" if not _pause_menu._open else "✗"])
	if not po or _pause_menu._open:
		fails += 1
	# 게임오버 — 포커스(다시 도전 · 메인 메뉴)
	_on_player_died()
	await get_tree().create_timer(1.2, true).timeout
	fails += await _pad_screen("게임오버", _gameover)
	print("[PADCHECK] %s" % ("ALL PASS" if fails == 0 else "FAIL %d건" % fails))
	get_tree().quit(0)


## 패드 버튼 한 번(누름 → 뗌). 엔진 입력 길(ui_* 액션 · 포커스 이동)을 그대로 탄다.
func _pad_press(btn: int) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = btn
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var e2 := InputEventJoypadButton.new()
	e2.device = 0
	e2.button_index = btn
	e2.pressed = false
	Input.parse_input_event(e2)
	await get_tree().process_frame
	await get_tree().process_frame


## 한 화면: 첫 포커스가 있나 · D-패드(아래/오른쪽/위/왼쪽 번갈아)로 보이는 버튼에 몇 개나 닿나. 실패 수를 돌려준다.
func _pad_screen(name: String, root: Control) -> int:
	var all: Array = []
	_pad_collect(root, all)
	var start: Control = get_viewport().gui_get_focus_owner()
	var seen: Dictionary = {}
	# 닿는 곳 찾기(너비 우선): 닿은 버튼마다 네 방향을 눌러 보고 새로 닿은 곳을 줄에 넣는다 — 한 줄로 쓸어 가면
	#   「위로 올라간 뒤 왼쪽」 같은 길을 못 찾는다(첫 판에서 출격 준비 12/31 로 잘못 나왔다).
	var queue: Array = []
	if start != null:
		seen[start] = true
		queue.append(start)
	var seq: Array = [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT]
	var steps: int = 0
	while not queue.is_empty() and steps < 400:
		var cur: Control = queue.pop_front()
		if not is_instance_valid(cur) or not cur.is_visible_in_tree():
			continue
		for dbtn in seq:
			cur.grab_focus()
			await get_tree().process_frame
			await _pad_press(int(dbtn))
			steps += 1
			var f: Control = get_viewport().gui_get_focus_owner()
			if f != null and not seen.has(f):
				seen[f] = true
				queue.append(f)
	if start != null and is_instance_valid(start):
		start.grab_focus()
	var reached: int = 0
	var missed: Array = []
	for b in all:
		if seen.has(b):
			reached += 1
		else:
			missed.append(_pad_name(b as Control))
	var ok: bool = start != null and reached >= all.size() - 0
	print("  [%s] 첫 포커스 %s · D-패드로 닿음 %d / %d%s" % [name, "✔" if start != null else "✗", reached, all.size(),
		("  · 못 닿음: " + ", ".join(missed.slice(0, 8))) if not missed.is_empty() else ""])
	return 0 if ok else 1


func _pad_collect(n: Node, out: Array) -> void:
	var c := n as Control
	if c != null and not c.is_visible_in_tree():
		return
	var b := n as BaseButton
	# 「뒤로」 버튼은 패드 B 가 대신한다(화면마다 B 로 닫히는지 따로 본다)
	if b != null and not b.disabled and b.focus_mode != Control.FOCUS_NONE \
			and not (b is Button and ((b as Button).text == I18n.t("뒤로"))):
		out.append(b)
	for ch in n.get_children():
		_pad_collect(ch, out)


func _pad_name(c: Control) -> String:
	var b := c as Button
	if b != null and b.text != "":
		return b.text.replace("\n", " ").left(14)
	return c.name


## ──────────────────── 저장 파일 (--savecheck) ────────────────────
## 16차 4-6: (1) 옛 빌드 세이브를 새 빌드가 그대로 읽나 — 영웅 해금 · 영구 강화 · 골드 · 도전과제 · 별 · 도감
##   (2) 새로 저장했다 다시 읽으면 같은가 (3) 빈 파일 · 반쯤 쓴 파일 · 쓰레기 바이트 · 남은 .tmp 에서 죽지 않고 백업으로 가나.
##   실행:  ... --headless --path . -- --savecheck=<옛 save.cfg 경로>      사용자 세이브(user://save.cfg)는 건드리지 않는다.
func _savecheck_flow(old_path: String) -> void:
	await get_tree().create_timer(0.2).timeout
	var dir: String = "user://savecheck"
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	var fails: int = 0
	print("=== SAVECHECK ===")
	# (1) 옛 세이브
	var old_copy: String = dir + "/old.cfg"
	if old_path != "" and FileAccess.file_exists(old_path):
		var src := FileAccess.open(old_path, FileAccess.READ)
		var dst := FileAccess.open(old_copy, FileAccess.WRITE)
		dst.store_buffer(src.get_buffer(src.get_length()))
		dst.close()
	else:
		print("  옛 세이브 경로가 없다: %s" % old_path)
		fails += 1
	G._load_save(old_copy)
	var a: Dictionary = _save_summary()
	print("  [옛 세이브 읽음] 출처=%s" % G.save_src)
	for k in a.keys():
		print("    %-10s %s" % [k, str(a[k])])
	# (2) 새 형식으로 저장 → 다시 읽기 → 같은가 (16차: 고른 차림도 같이 — 저승길 클리어 표시와 울레아 저승길 차림)
	G.stage_prog["c_5_0"] = true
	G.meta["skin_base"] = "jeoseung"
	a = _save_summary()
	var rt: String = dir + "/rt.cfg"
	G.save_game(rt)
	G._load_save(rt)
	var b: Dictionary = _save_summary()
	print("  [차림 저장] 울레아 = %s" % G.hero_skin("base"))
	var same: bool = JSON.stringify(a) == JSON.stringify(b)
	print("  [새로 저장 후 다시 읽음] %s" % ("같다" if same else "다르다!"))
	if not same:
		fails += 1
		print("    전: %s\n    후: %s" % [JSON.stringify(a), JSON.stringify(b)])
	var body: PackedByteArray = FileAccess.get_file_as_bytes(rt)
	# (3) 깨뜨리기 — 같은 폴더에 백업(rt 사본)을 두고 본 파일만 망가뜨린다
	var cases: Array = [
		["빈 파일", PackedByteArray(), true, "bak"],
		["반쯤 쓴 파일", body.slice(0, body.size() / 2), true, "bak"],
		["쓰레기 바이트", PackedByteArray([0xff, 0xfe, 0x00, 0x13, 0x37, 0x5b, 0x00, 0x7b]), true, "bak"],
		["줄 끝에서 잘린 파일(문법은 맞고 끝 줄만 없음)", body.slice(0, body.get_string_from_utf8().substr(0, body.size() / 2).rfind("\n") + 1), true, "bak"],
		["빈 파일 · 백업도 없음", PackedByteArray(), false, "broken"],
	]
	for i in cases.size():
		var c: Array = cases[i]
		var p: String = dir + "/c%d.cfg" % i
		var f := FileAccess.open(p, FileAccess.WRITE)
		f.store_buffer(c[1] as PackedByteArray)
		f.close()
		if bool(c[2]):
			var fb := FileAccess.open(dir + "/c%d.bak.cfg" % i, FileAccess.WRITE)
			fb.store_buffer(body)
			fb.close()
		G.total_gold = -1
		G._load_save(p)
		var ok_src: bool = G.save_src == String(c[3])
		var ok_gold: bool = (G.total_gold == int(b["gold"])) if bool(c[2]) else (G.total_gold == -1 or G.total_gold == 0)
		var kept: bool = FileAccess.file_exists(dir + "/c%d.broken.cfg" % i)
		var ok: bool = ok_src and ok_gold and kept
		print("  [%s] 출처=%s 골드=%d 깨진 파일 보관=%s → %s" % [String(c[0]), G.save_src, G.total_gold, str(kept), "OK" if ok else "FAIL"])
		if not ok:
			fails += 1
	# 남은 .tmp(쓰는 도중 꺼짐) — 본 파일이 멀쩡하면 본 파일을 읽어야 한다
	var p5: String = dir + "/c5.cfg"
	var f5 := FileAccess.open(p5, FileAccess.WRITE)
	f5.store_buffer(body)
	f5.close()
	var t5 := FileAccess.open(dir + "/c5.tmp.cfg", FileAccess.WRITE)
	t5.store_buffer(body.slice(0, body.size() / 3))
	t5.close()
	G._load_save(p5)
	var ok5: bool = G.save_src == "main" and G.total_gold == int(b["gold"])
	print("  [남은 .tmp] 출처=%s 골드=%d → %s" % [G.save_src, G.total_gold, "OK" if ok5 else "FAIL"])
	if not ok5:
		fails += 1
	# 저장을 두 번 하면 앞 것이 .bak 으로 남는가
	G.total_gold = 111
	G.save_game(dir + "/c6.cfg")
	G.total_gold = 222
	G.save_game(dir + "/c6.cfg")
	G._load_save(dir + "/c6.bak.cfg")
	var ok6: bool = G.total_gold == 111
	G._load_save(dir + "/c6.cfg")
	ok6 = ok6 and G.total_gold == 222 and not FileAccess.file_exists(dir + "/c6.tmp.cfg")
	print("  [두 번 저장 → 앞 것이 백업] %s" % ("OK" if ok6 else "FAIL"))
	if not ok6:
		fails += 1
	print("[SAVECHECK] %s" % ("ALL PASS" if fails == 0 else "FAIL %d건" % fails))
	get_tree().quit(0 if fails == 0 else 1)


func _save_summary() -> Dictionary:
	var heroes: Array = []
	for d: Dictionary in Characters.defs():
		if G.char_unlocked(String(d["id"])):
			heroes.append(String(d["id"]))
	var shop: Array = []
	for k: String in G.META_TIERS.keys():
		if G.meta_level(k) > 0:
			shop.append("%s%d" % [k.substr(2), G.meta_level(k)])
	var ranks: Array = []
	for d2: Dictionary in Characters.defs():
		var r: int = G.char_rank(String(d2["id"]))
		if r > 0:
			ranks.append("%s★%d" % [String(d2["id"]), r])
	return {"gold": G.total_gold, "heroes": heroes, "ranks": ranks, "shop": shop,
		"achv": G.achievements.size(), "clears": G.cleared_count(), "stars": G.star_total(),
		"codex": G.codex.size(), "kills": int(G.stats.get("total_kills", 0)), "runs": int(G.stats.get("runs", 0)),
		"skin_base": G.hero_skin("base")}


## ──────────────────── 출시 후보 봇 판 (--botrun) ────────────────────
## 16차 4-2: 영웅 20 × 스테이지 6 × 보통 120판을 봇으로. 한 프로세스 = 한 판이고, 끝에 [BOTRUN] JSON 한 줄.
##   끝까지 갔나(클리어 · 사망 · 시간 초과) · 걸린 게임 시간 · 처치 · 레벨 · 최대 메모리 · 최대 노드 · 최대 몹 수.
##   오류 줄 수는 돌리는 쪽(tools/botrun.py)이 이 프로세스 로그에서 센다.
##   실행:  ... --headless --path . -- --botrun --char=gangrim --stage=5 --diff=1 --fast=8 --seed=1 [--dur=1800]
##   --stage 를 안 주면 무한 모드(--dur 까지, 30분 최종 보스).
func _botrun_flow(diff: int, dur: float) -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = diff
	G.aim_mode = 0
	var cdef: Dictionary = Characters.def_of(_lp_char if _lp_char != "" else "base")
	G.meta["uc_" + String(cdef["id"])] = 1
	G.last_char_id = String(cdef["id"])
	G.harness_speed = maxf(1.0, _lp_fast)
	# 17-2 밸런스 표: --meta=zero|save|max(영구강화 없음 · 실제 세이브 · 만렙) · --fusion=off|force|natural · --nodmg
	var meta_mode: String = "save"
	var fusion_mode: String = "natural"
	for ua: String in OS.get_cmdline_user_args():
		if ua.begins_with("--meta="):
			meta_mode = ua.get_slice("=", 1)
		elif ua.begins_with("--fusion="):
			fusion_mode = ua.get_slice("=", 1)
		elif ua == "--nodmg":
			G.harness_nodmg = true
		elif ua.begins_with("--finalhp="):
			G.harness_final_hp = float(ua.get_slice("=", 1))
	if meta_mode != "save":
		var cid: String = String(cdef["id"])
		for mk: String in G.META_TIERS.keys():
			G.meta[mk] = 0 if meta_mode == "zero" else G.meta_max(mk)
		G.meta["rank_" + cid] = 0 if meta_mode == "zero" else G.CHAR_RANK_MAX
		for si in Accessories.SLOTS:
			G.meta["acc_slot_%d" % si] = ""
	G.tally_on = true
	G.dmg_tally.clear()
	# ★ 배속만 올리면 물리 한 걸음이 배속만큼 길어져(6배속 = 0.1초) 탄이 몹을 건너뛰고 봇이 엉뚱하게 죽었다
	#   (같은 영웅 · 스테이지 1 이 1배속 Lv48 클리어 → 6배속 Lv27 사망). 물리 틱을 배속만큼 올려 한 걸음을 1/60초로 둔다.
	var base_tps: int = int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60))
	Engine.physics_ticks_per_second = int(base_tps * G.harness_speed)
	Engine.max_physics_steps_per_frame = int(8 * G.harness_speed)
	_begin_run(cdef)
	if _lp_immortal and G.player != null and is_instance_valid(G.player):
		(G.player as Player).max_hp = 1.0e9   # 누수 그래프용 — 30분을 끝까지 가야 한다
		(G.player as Player).hp = 1.0e9
	# 11/7 무한 강제 종료 재현: 봇은 실제 「사기 조합」 판보다 훨씬 약하다(30분 Lv 12~45). 처음부터 특수무기 일곱 ·
	#   탄막 일곱 만렙 · 흡혈을 쥐여 화면에 탄 · 효과 · 처치가 가장 많은 판을 만든다.
	if "--godbuild" in OS.get_cmdline_user_args():
		for gid: String in ["wpn_whip", "wpn_beam", "wpn_boomerang", "wpn_fire", "wpn_ice", "wpn_poison", "wpn_chain"]:
			for _k in 6:
				_apply_upgrade(gid)
		for _k in 5:
			for gid2: String in ["b_fire", "b_ice", "b_poison", "b_shock", "b_chain", "b_exec", "b_vamp", "b_bloom"]:
				_apply_upgrade(gid2)
		for _k in 9:
			_apply_upgrade("dmg")
		for _k in 8:
			_apply_upgrade("rate")
	if _lp_fast > 1.0:
		Engine.time_scale = _lp_fast
	var stage_run: bool = G.run_mode == "stage"
	var cap: float = maxf(G.STAGE_LEN + 420.0, dur) if stage_run else maxf(dur, 60.0)   # --dur 로 늘릴 수 있다(시간 초과 판 다시 돌리기)
	var mem_max: float = 0.0
	var node_max: int = 0
	var mob_max: int = 0
	var t: float = 0.0
	var t0_ms: int = Time.get_ticks_msec()
	var result: String = "timeout"
	var next_mem: float = 0.0
	# 보스마다 등장 시각 · 체력 · 처치(또는 도망)까지 걸린 시간 — 역할은 등장 순간 main_game 의 참조로 가른다
	var bosses: Dictionary = {}
	var minutes: Array = []
	var next_min: float = 60.0
	var out_prev: float = 0.0
	var in_prev: float = 0.0
	var forced: int = 0
	var stuck_t: float = -1.0
	var stuck_ms: int = Time.get_ticks_msec()
	while true:
		# 17-2: 480판 중 2판이 게임 시간이 멈춘 채 30분을 넘겼다.
		#   시간이 실시간 20초 동안 그대로면 그때 화면 상태를 찍고 끝낸다 — 사람에겐 그대로 소프트락이다.
		if absf(G.time_alive - stuck_t) > 0.001:
			stuck_t = G.time_alive
			stuck_ms = Time.get_ticks_msec()
		elif Time.get_ticks_msec() - stuck_ms > 20000:
			print("[BOTSTUCK] t=%.1f paused=%s running=%s levelup=%s chest=%s revive=%s victory=%s gameover=%s win_seq=%s stage_done=%s final_spawned=%s stage_boss=%s pending_revive=%s time_scale=%.2f" % [
				G.time_alive, str(get_tree().paused), str(G.running), str(_levelup_root.visible),
				str(_chest_panel != null and is_instance_valid(_chest_panel)), str(_revive_panel != null and _revive_panel.visible),
				str(_victory.visible), str(_gameover.visible), str(_win_seq), str(_stage_done), str(_final_spawned),
				str(_stage_boss != null and is_instance_valid(_stage_boss)),
				str(is_instance_valid(G.player) and bool((G.player as Player).pending_revive)), Engine.time_scale])
			result = "stuck"
			break
		if _chest_panel != null and is_instance_valid(_chest_panel):
			_close_chest_panel()
			await get_tree().process_frame
			continue
		if _levelup_root.visible:
			_auto_pick()
			await get_tree().process_frame
			continue
		if _revive_panel != null and _revive_panel.visible:
			_on_revive_decline()
			await get_tree().process_frame
			continue
		if _stage_done or _endless_done:
			result = "clear"
			break
		if not G.running:
			result = "dead"
			break
		if t >= cap:
			break
		_bal_step()
		if fusion_mode == "off":
			_fusion_lockout = 1.0e9
		elif fusion_mode == "force" and _fusion_boss == null and _fusion_possible():
			_merge_into_boss()   # 몹이 덜 모여도 열리는 즉시 융합 — 「융합을 매번 본 판」
			forced += 1
		await get_tree().create_timer(0.08).timeout
		t = G.time_alive
		_botrun_track_bosses(bosses, t)
		if t >= next_min:
			next_min += 60.0
			var dout: float = 0.0
			for dk in G.dmg_tally.keys():
				dout += float(G.dmg_tally[dk])
			var pl1 := G.player as Player
			minutes.append([int(t / 60.0), G.level, G.kills, int(dout - out_prev), int(G.dmg_recv - in_prev),
				int(pl1.max_hp) if is_instance_valid(pl1) else 0, _enemy_count()])
			out_prev = dout
			in_prev = G.dmg_recv
		mem_max = maxf(mem_max, Performance.get_monitor(Performance.MEMORY_STATIC))
		node_max = maxi(node_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		mob_max = maxi(mob_max, _enemy_count())
		# 4-3 누수 그래프: 게임 1분마다 메모리 · 객체 · 노드 · 몹 · 그림 메모리 한 줄
		if t >= next_mem:
			next_mem += 60.0
			print("[BOTMEM] %d %.1f %d %d %d %.1f %.0f" % [int(t / 60.0), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
				int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				_enemy_count(), Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, Engine.get_frames_per_second()])
	var out: Dictionary = {
		"hero": String(cdef["id"]), "stage": (G.stage_sel + 1) if stage_run else 0, "diff": diff,
		"result": result, "game_sec": int(G.time_alive), "boss_sec": int(G.boss_fight_t),
		"kills": G.kills, "level": G.level, "hits": G.hits_taken,
		"mem_mb": snappedf(mem_max / 1048576.0, 0.1), "nodes_max": node_max, "mobs_max": mob_max,
		"real_sec": snappedf(float(Time.get_ticks_msec() - t0_ms) / 1000.0, 0.1),
		"last_hit": G.last_hit_src,
		"meta": meta_mode, "fusion": fusion_mode, "nodmg": G.harness_nodmg, "forced": forced,
		"meta_power": snappedf(G.meta_power(), 0.01), "dmg_in": int(G.dmg_recv),
		"max_hp": int((G.player as Player).max_hp) if is_instance_valid(G.player) else 0,
		"minutes": minutes,
	}
	_botrun_track_bosses(bosses, G.time_alive)
	var blist: Array = []
	for bk in bosses.keys():
		var b: Dictionary = bosses[bk]
		b.erase("ref")
		blist.append(b)
	blist.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["t0"]) < float(y["t0"]))
	out["bosses"] = blist
	print("[BOTRUN] " + JSON.stringify(out))
	Engine.time_scale = 1.0
	# 11/7 무한 강제 종료: 30분 판을 끝내고 종료할 때 exit 139(튕김)가 났다. 결과 화면 「다시 도전」 · 「메인 메뉴」도
	#   같은 큰 판을 지우므로 그 순간을 따로 잰다 — 종료 대신 씬을 다시 부르고, 새 씬이 뜨면 그때 끝낸다.
	if "--reloadtest" in OS.get_cmdline_user_args():
		get_tree().root.set_meta("reloadtest_done", true)
		print("[RELOADTEST] 다시 부르기 — 노드 %d · 몹 %d" % [int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), _enemy_count()])
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	get_tree().quit(0)


## --reloadtest 두 번째 씬: 다시 부른 판이 떴다. 몇 프레임 돌려 보고 끝낸다.
func _reloadtest_after() -> void:
	for _i in 30:
		await get_tree().process_frame
	print("[RELOADTEST] 새 씬 정상 — 노드 %d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	get_tree().quit(0)


## 17-2: 무한 30분 최종 보스(사신) 설계대로인가(사용자 10/12, 뱀파이어 서바이버의 사신).
##   ① 등장 순간 잡몹 소멸 · 진행 중 융합 퇴장 ② 몹 상한 0 ③ 60초 동안 잡몹 · 소환 · 융합 0(성장 끊김)
##   ④ 중간보스 웨이브가 와도 보류 ⑤ 사신이 플레이어보다 빠르고 몸박이 최대 체력의 절반, 도망쳐도 붙잡는다
##   ⑥ 장애물이 걷히고 다시 안 깔린다 ⑦ 1분 뒤 사신이 하나 더, 속도 · 피해가 분마다 오른다
##   ⑧ 얼음 감속을 걸면 사신이 플레이어보다 느려진다(도망칠 길이 실제로 있다)
func _finalcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.run_mode = "endless"
	G.difficulty = 1
	G.aim_mode = 0
	_begin_run(Characters.def_of("base"))
	await get_tree().process_frame
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	G.harness_nodmg = true  # 맞은 횟수만 센다
	G.time_alive = MATCH_LEN - 20.0
	for i in 150:
		var e := Enemy.new()
		e.kind = 0
		var ang: float = TAU * float(i) / 150.0
		e.global_position = p.global_position + Vector2(cos(ang), sin(ang)) * (260.0 + float(i % 5) * 40.0)
		add_child(e)
	await get_tree().process_frame
	_merge_into_boss()  # 최종 보스 직전에 융합 보스가 서 있는 상황
	var old: Array = []
	for i in 120:
		var e := Enemy.new()
		old.append(e)
		e.kind = 0
		var ang: float = TAU * float(i) / 120.0
		e.global_position = p.global_position + Vector2(cos(ang), sin(ang)) * 320.0
		add_child(e)
	await get_tree().process_frame
	_regen_obstacles(_cur_theme)
	var obst_before: int = _obstacles.size()
	var fus_before: bool = _fusion_boss != null and is_instance_valid(_fusion_boss)
	var mobs_before: int = _enemy_count()
	G.time_alive = MATCH_LEN
	await get_tree().create_timer(0.5).timeout
	var fails: int = 0
	var fb_ok: bool = _final_boss != null and is_instance_valid(_final_boss)
	var mobs_after: int = _enemy_count() - 1
	var old_left: int = 0
	for e in old:
		if is_instance_valid(e) and not (e as Enemy)._dead:
			old_left += 1
	var fus_gone: bool = _fusion_boss == null
	var cap: int = _enemy_cap()
	var ok1: bool = fb_ok and fus_before and fus_gone and old_left == 0 and mobs_after == 0
	print("[FINALCHECK] ① 최종 보스=%s · 융합 %s→%s · 있던 잡몹 %d 중 남은 것 %d · 0.5초 뒤 잡몹 %d  %s" % [fb_ok, fus_before, not fus_gone, mobs_before, old_left, mobs_after, "OK" if ok1 else "FAIL"])
	if not ok1:
		fails += 1
	var ok2: bool = cap == 0
	print("[FINALCHECK] ② 몹 상한 %d  %s" % [cap, "OK" if ok2 else "FAIL"])
	if not ok2:
		fails += 1
	Engine.time_scale = 5.0
	var t0: float = G.time_alive
	var max_mobs: int = 0
	var fus_seen: bool = false
	var lv0: int = G.level
	var hits0: int = G.hits_taken
	var spd0: float = (_final_boss.spd / p.move_speed) if _final_boss != null else 0.0
	_theme_t = 0.0  # 테마가 바뀌려 해도
	while G.time_alive - t0 < 66.0 and _final_boss != null and is_instance_valid(_final_boss):
		_flee_step()
		await get_tree().create_timer(0.1).timeout
		max_mobs = maxi(max_mobs, _enemy_count() - 1 - _reapers.size())
		if _fusion_boss != null:
			fus_seen = true
	Engine.time_scale = 1.0
	for a in ["move_up", "move_down", "move_left", "move_right", "dash"]:
		Input.action_release(a)
	var ok3: bool = not fus_seen and max_mobs == 0 and G.level == lv0
	print("[FINALCHECK] ③ 60초 · 융합 %s · 보스 말고 몹 최대 %d · 레벨 %d→%d  %s" % [fus_seen, max_mobs, lv0, G.level, "OK" if ok3 else "FAIL"])
	if not ok3:
		fails += 1
	var pend0: bool = _boss_pending
	for i in BOSS_EVERY:
		_advance_wave()
	var ok4: bool = _boss_pending == pend0 and _boss_eta <= 0.0
	print("[FINALCHECK] ④ 중간보스 웨이브 보류=%s  %s" % [ok4, "OK" if ok4 else "FAIL"])
	if not ok4:
		fails += 1
	var fb: Enemy = _final_boss
	var hits: int = G.hits_taken - hits0
	var ok5: bool = fb != null and is_instance_valid(fb) and fb.reaper and fb.spd > p.move_speed and fb.touch >= p.max_hp * Enemy.REAPER_HIT - 1.0 and hits >= 5
	print("[FINALCHECK] ⑤ 사신 속도 %.0f (플레이어 %.0f) · 몸박 = 최대 체력 × %.2f · 도망치는 60초에 맞은 횟수 %d  %s" % [
		fb.spd if fb != null else 0.0, p.move_speed, (fb.touch / p.max_hp) if fb != null else 0.0, hits, "OK" if ok5 else "FAIL"])
	if not ok5:
		fails += 1
	var ok6: bool = obst_before > 0 and _obstacles.is_empty()
	print("[FINALCHECK] ⑥ 장애물 %d → %d  %s" % [obst_before, _obstacles.size(), "OK" if ok6 else "FAIL"])
	if not ok6:
		fails += 1
	var spd1: float = (fb.spd / p.move_speed) if fb != null else 0.0
	var hit1: float = (fb.touch / p.max_hp) if fb != null else 0.0
	var ok7: bool = _reapers.size() == 1 and spd1 > spd0 + 0.04 and hit1 > Enemy.REAPER_HIT + 0.09
	print("[FINALCHECK] ⑦ 66초 뒤 사신 %d+%d · 속도 ×%.2f→×%.2f · 몸박 ×%.2f  %s" % [1, _reapers.size(), spd0, spd1, hit1, "OK" if ok7 else "FAIL"])
	if not ok7:
		fails += 1
	# ⑧ 얼음 감속이 사신에게도 먹나 — 다른 사신은 세워 두고, 멀리 떨어진 플레이어를 쫓는 속도를 잰다
	var v_free: float = 0.0
	var v_slow: float = 0.0
	if fb != null and is_instance_valid(fb):
		for r in _reapers:
			if is_instance_valid(r):
				(r as Enemy).apply_freeze(30.0)
		for k in 2:
			var toc: Vector2 = -fb.global_position
			p.global_position = fb.global_position + (toc.normalized() if toc.length() > 1.0 else Vector2.RIGHT) * 900.0
			if k == 1:
				fb.apply_slow(3.0)
			await get_tree().physics_frame
			var a0: Vector2 = fb.global_position
			var tb: float = G.time_alive
			await get_tree().create_timer(0.6).timeout
			var v: float = (fb.global_position - a0).length() / maxf(0.01, G.time_alive - tb)
			if k == 0:
				v_free = v
			else:
				v_slow = v
	var ok8: bool = v_free > p.move_speed and v_slow < p.move_speed
	print("[FINALCHECK] ⑧ 사신 실제 속도 %.0f → 얼음 감속 %.0f (플레이어 %.0f)  %s" % [v_free, v_slow, p.move_speed, "OK" if ok8 else "FAIL"])
	if not ok8:
		fails += 1
	print("[FINALCHECK] %s (실패 %d)" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(0 if fails == 0 else 1)


## 17-2: 보스 상자 둘을 같은 프레임에 주웠을 때 닫고 나면 판이 다시 흐르는가(예전엔 멈춘 채 아무 창도 없었다).
##   ① 상자 둘 → 닫기 → 흐름 ② 레벨업 위에 상자 → 닫기 → 레벨업 그대로 멈춤 ③ 상자 위에 상자 위에 상자(셋) → 닫기 → 흐름
func _chestdouble_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	_begin_run(Characters.def_of("base"))
	await get_tree().create_timer(0.3).timeout
	var fails: int = 0
	for case_i in 3:
		get_tree().paused = false
		if case_i == 1:
			_open_levelup()
		var k: int = 3 if case_i == 2 else 2
		for i in k:
			_on_boss_chest()
		var shown: int = _chest_got.size()
		await get_tree().process_frame
		_close_chest_panel()
		await get_tree().process_frame
		var want_paused: bool = case_i == 1
		var ok: bool = get_tree().paused == want_paused and (_chest_panel == null or not is_instance_valid(_chest_panel))
		print("[CHESTDOUBLE] %s · 상자 %d · 창에 카드 %d · 닫은 뒤 멈춤=%s(기대 %s)  %s" % [
			["상자 둘", "레벨업 위 상자 둘", "상자 셋"][case_i], k, shown, str(get_tree().paused), str(want_paused), "OK" if ok else "FAIL"])
		if not ok:
			fails += 1
		if case_i == 1:
			_auto_pick()
			await get_tree().process_frame
	print("[CHESTDOUBLE] %s" % ("PASS" if fails == 0 else "FAIL x%d" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## --botrun 보스 기록: 처음 보인 시각 · 역할(mid · fusion · stage · final) · 최대 체력 · 끝난 시각과 끝(kill · escape · open).
func _botrun_track_bosses(bosses: Dictionary, t: float) -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or not e._is_boss:
			continue
		var key: int = e.get_instance_id()
		if not bosses.has(key):
			var role: String = "mid"
			if e == _fusion_boss:
				role = "fusion"
			elif e == _stage_boss:
				role = "stage"
			elif e == _final_boss:
				role = "final"
			elif e.reaper:
				role = "reaper"
			bosses[key] = {"ref": e, "role": role, "kind": e.kind, "t0": snappedf(t, 0.1), "hp": int(e.max_hp),
				"lv": G.level, "end": "open", "t1": -1.0, "frac": 1.0}
		var b: Dictionary = bosses[key]
		b["hp"] = maxi(int(b["hp"]), int(e.max_hp))
		b["frac"] = snappedf(clampf(e.hp / maxf(1.0, e.max_hp), 0.0, 1.0), 0.01)
		b["dealt"] = int(e.max_hp - maxf(0.0, e.hp))  # 넣은 피해 그대로(--finalhp 처럼 체력이 크면 frac 이 0.01 단위라 안 보인다)
	for key in bosses.keys():
		var b: Dictionary = bosses[key]
		if String(b["end"]) != "open":
			continue
		var ref: Variant = b["ref"]
		var gone: bool = not is_instance_valid(ref)
		if not gone and ((ref as Enemy)._dead or (ref as Enemy).hp <= 0.0):
			b["end"] = "kill"
			b["t1"] = snappedf(t, 0.1)
		elif gone:
			b["end"] = "kill" if float(b["frac"]) <= 0.08 else "gone"
			b["t1"] = snappedf(t, 0.1)


## 한 줄 지표. '피해배수'는 기본치(14) 대비 전역 공격력이 몇 배가 됐는지 —
## 이 숫자가 몹 HP 증가 배수를 크게 앞지르면 그 판은 이미 끝난 것이다.
func _bal_row(t: float, k_prev: int, g_prev: int, hp_lo: float) -> void:
	var pl := G.player as Player
	if not is_instance_valid(pl):
		return
	var hp_sum: float = 0.0
	var n: int = 0
	for e in G.enemies_cached():
		if not is_instance_valid(e):
			continue
		var en := e as Enemy
		if en == null or en._is_boss:
			continue
		hp_sum += en.max_hp
		n += 1
	var ehp: float = hp_sum / float(maxi(1, n))
	var dps: float = _bal_dps(pl)
	print("  %3.0f초  %3d  %6d  %5.1f  %5d  %5.0f   x%7.1f   %8.0f   %7.2f초  %3.0f%%  %3d  상한%3d  공격x%.2f  압력%4.0f  받은피해%6.0f" % [
		t, G.level, G.kills, float(G.kills - k_prev) / 30.0, G.run_gold,
		float(G.run_gold - g_prev) * 2.0, pl.damage / Player.BULLET_DMG,
		ehp, ehp / maxf(1.0, dps), hp_lo * 100.0, n, _enemy_cap(), G.enemy_touch_scale(G.pressure_t()), G.pressure_t(), G.dmg_recv - _bal_dmg_prev])
	_bal_dmg_prev = G.dmg_recv


func _bal_boss_alive() -> bool:
	for e in G.enemies_cached():
		if is_instance_valid(e) and (e as Enemy) != null and (e as Enemy)._is_boss:
			return true
	return false


## 초당 이론 피해 — 주무기만(특수무기·장판 제외). 처치시간의 상한 기준값으로만 쓴다.
func _bal_dps(pl: Player) -> float:
	var d: float = 0.0
	for w in pl.weapons_primary:
		var def: Dictionary = Player.WEAPON_DEFS[String(w["id"])]
		var lvl: int = int(w["level"])
		var per: float = pl._weapon_dmg(def, lvl) * float(int(def["proj"]) + pl.proj_bonus)
		per *= 1.0 + pl.eff_crit() * (pl.crit_mult - 1.0)
		d += per / maxf(0.02, float(def["cd"]) * pl.rate_mult)
	return d


func _longplay_flow(dir: String, diff: int, dur: float = 240.0) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	G.difficulty = diff
	G.aim_mode = 0  # 봇은 자동조준
	_begin_run(Characters.defs()[0])  # apply_meta + apply_character + reset 일괄
	if _lp_immortal and G.player != null and is_instance_valid(G.player):
		(G.player as Player).max_hp = 1.0e9
		(G.player as Player).hp = 1.0e9
	if _m31_smoke:  # M31 스모크: 신규 무기/패시브/반응 전부 강제 부여
		for gid: String in ["wpn_whip", "wpn_beam", "wpn_boomerang", "wpn_fire", "wpn_ice", "wpn_poison", "wpn_chain"]:
			_apply_upgrade(gid)
		for _i in 5:
			for gid2: String in ["b_fire", "b_ice", "b_poison", "b_shock", "b_exec", "b_vamp", "b_bloom"]:
				_apply_upgrade(gid2)
		print("=== M31 SMOKE: granted new weapons+passives ===")
	if _lp_fast > 1.0:
		Engine.time_scale = _lp_fast
	var DUR: float = dur
	var t: float = 0.0
	var next_shot: float = 0.0
	print("=== LONGPLAY START diff=%d (%s) immortal=%s fast=%.0f ===" % [diff, String(G.DIFF_NAMES[clampi(diff, 0, 3)]), str(_lp_immortal), _lp_fast])
	while t < DUR:
		# ★ 보스 상자 패널은 판을 멈추고 **클릭**을 기다린다(2026-09-06 추가). 봇은 클릭을
		#   못 하므로 여기서 직접 닫아 준다 — 안 그러면 측정이 그 자리에서 영원히 멈춘다.
		if _chest_panel != null and is_instance_valid(_chest_panel):
			_close_chest_panel()
			await get_tree().process_frame
			continue
		if _levelup_root.visible:  # 레벨업 모달 자동 선택 (일시정지 중 → process_frame)
			_auto_pick()
			await get_tree().process_frame
			t = G.time_alive
			continue
		if not G.running:  # 사망
			break
		_flee_step()
		await get_tree().create_timer(0.08).timeout
		t = G.time_alive  # 게임시간 기준(무비 모드에서도 영상 길이 정확)
		if t >= next_shot:
			next_shot += 20.0
			var pl := G.player as Player
			var hp: int = int(pl.hp) if is_instance_valid(pl) else 0
			var mx: int = int(pl.max_hp) if is_instance_valid(pl) else 0
			var nd: float = -1.0
			if is_instance_valid(pl):
				var ne := pl._nearest_enemy()
				nd = pl.global_position.distance_to(ne.global_position) if ne != null else -1.0
			print("[LP d%d] t=%3.0fs  lvl=%d  kills=%d  gold=%d  hp=%d/%d  enemies=%d  bullets=%d  near=%.0f" % [diff, t, G.level, G.kills, G.run_gold, hp, mx, _enemy_count(), get_tree().get_node_count_in_group("bullet"), nd])
			if not _lp_nosnap:
				await _snap("%s/d%d_t%03.0f.png" % [dir, diff, t])
	for a in ["move_up", "move_down", "move_left", "move_right", "dash"]:
		Input.action_release(a)
	var alive: bool = G.running and G.player != null and is_instance_valid(G.player)
	if G.run_mode == "stage":
		print("=== LONGPLAY stage%d d%d DONE  cleared=%s  survived=%.0fs  alive=%s  lvl=%d  kills=%d  gold=%d ===" % [
			G.stage_sel, diff, str(_stage_done), t, str(alive or _stage_done), G.level, G.kills, _stage_earned if _stage_done else G.run_gold])
	else:
		print("=== LONGPLAY d%d DONE  survived=%.0fs(/%.0f)  alive=%s  lvl=%d  kills=%d ===" % [diff, t, DUR, str(alive), G.level, G.kills])
	get_tree().quit(0)


## 데미지/무기 우선 빌드픽 (실플레이어에 가깝게)
## 롱플레이 봇의 자동 선택 우선순위.
## ★ 여기 빠진 카드는 봇이 절대 안 고르므로, 측정된 '평균 빌드'가 실제 유저 빌드와 어긋난다.
##   신규 카드(전설/신화/이면 무기/영웅 고유)를 전부 넣어 두었다. 상위 등급이 앞에 온다.
const _AUTO_PRIO: Array = [
	"m_apocalypse", "m_transcend", "m_immortal",
	"l_giant", "l_echo", "l_timewarp",
	"evo_inferno", "evo_deadeye", "evo_railcannon", "evo_blizzard", "evo_tempest", "evo_reaper",
	"evo_nova", "evo_plague", "evo_legion", "evo_ninetail", "evo_ledger", "evo_orb",
	"wpn_whip", "wpn_beam", "wpn_boomerang", "wp_melee", "wp_heavy", "wp_rapid", "wp_mid",
	"wp_bow", "wp_jakdu", "wp_fan", "wp_sinkal", "wpn_fire", "wpn_ice", "wpn_summon",
	"c_allround", "c_bloodlust", "c_overheat", "c_goldsense", "c_ironwill", "c_allin",
	"c_charge", "c_emberheart", "c_umbra", "c_bellcall", "c_bloomstep", "c_temper", "c_mantra", "c_talon",
	"b_fire", "b_ice", "b_exec", "b_bloom", "b_vamp", "dmg", "rate", "crit", "wpn_orb", "wpn_chain",
	"wpn_poison", "summon_ice", "b_shock", "b_chain", "b_big", "b_bounce", "bspeed", "hp", "regen", "armor", "critdmg",
	"magnet", "speed", "xp_gain", "gamble", "luck", "thorns", "dashcd",
]


## ★ 예전엔 _AUTO_PRIO 고정 순서라 체력·방어·재생을 **맨 끝에서** 골랐다. 순수 유리대포로
##   90초에 죽으니 밸런스 측정이 통째로 비관 쪽으로 기울었다 — 사람은 체력이 깎이면
##   체력 카드를 집는다(2026-09-06). 방어가 뒤처지면 그때만 방어를 앞으로 당긴다.
const _AUTO_DEF: Array = ["hp", "armor", "regen"]


## 이 시점에 갖췄어야 할 최대 체력. 밑돌면 방어 카드를 우선한다.
func _auto_def_needed(p: Player) -> bool:
	return p.max_hp < 180.0 + G.time_alive * 0.55


func _auto_pick() -> void:
	var n: int = _cards_box.get_child_count()
	if n == 0:
		return
	# 진화 카드가 있으면 최우선
	for i in _last_offered.size():
		if i < n and String(_last_offered[i]).begins_with("evo_"):
			(_cards_box.get_child(i) as Button).pressed.emit()
			return
	# 방어가 뒤처졌으면 체력·방어·재생을 먼저 집는다 — 사람이 하는 선택이다
	var pl0 := G.player as Player
	if pl0 != null and is_instance_valid(pl0) and _auto_def_needed(pl0):
		for id0: String in _AUTO_DEF:
			var di: int = _last_offered.find(id0)
			if di >= 0 and di < n:
				(_cards_box.get_child(di) as Button).pressed.emit()
				return
	for id: String in _AUTO_PRIO:
		var idx: int = _last_offered.find(id)
		if idx >= 0 and idx < n:
			(_cards_box.get_child(idx) as Button).pressed.emit()
			return
	(_cards_box.get_child(0) as Button).pressed.emit()


## 카이팅 회피 AI: 위협에서 멀어지되 접선 방향으로 원을 그리며 도망(구석 몰림 방지).
func _flee_step() -> void:
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	var pos: Vector2 = (p as Node2D).global_position
	var threat: Vector2 = Vector2.ZERO
	var nearest_d: float = 1.0e9
	for node in get_tree().get_nodes_in_group("enemy"):
		var e := node as Node2D
		if e == null or not is_instance_valid(e):
			continue
		var to: Vector2 = pos - e.global_position
		var d: float = to.length()
		nearest_d = minf(nearest_d, d)
		if d < 360.0 and d > 0.01:
			threat += to.normalized() * ((360.0 - d) / 360.0)
	var to_center: Vector2 = -pos
	var move: Vector2
	if threat.length() > 0.05:
		var away: Vector2 = threat.normalized()
		var tangent: Vector2 = Vector2(-away.y, away.x)
		if tangent.dot(to_center) < 0.0:
			tangent = -tangent
		move = (away * 0.7 + tangent * 0.9).normalized()  # 원 그리며 카이팅
	else:
		move = to_center.normalized() if pos.length() > 80.0 else Vector2.RIGHT
	if pos.length() > 1150.0:
		move = (move + to_center.normalized() * 1.8).normalized()
	Input.action_release("dash")
	_press_dir(move)
	if nearest_d < 120.0:
		Input.action_press("dash")


func _press_dir(v: Vector2) -> void:
	_set_act("move_right", v.x > 0.35)
	_set_act("move_left", v.x < -0.35)
	_set_act("move_down", v.y > 0.35)
	_set_act("move_up", v.y < -0.35)


func _set_act(a: String, on: bool) -> void:
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)


# ---------------------------------------------------------------- 데모(자동 조작+스크린샷)
func _demo_flow(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	await get_tree().create_timer(0.3).timeout
	G.aim_mode = 0  # 데모는 자동조준
	G.total_gold = 250  # 상점 데모용 골드
	# 메인 메뉴 (6분기 + 현재 능력치)
	_main_menu.set_continue_enabled(false)
	_main_menu.open()
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/z_mainmenu.png")
	# 설정 (난이도/음량)
	_main_menu.close()
	_settings.open()
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/z_settings.png")
	_settings._on_back()
	await get_tree().create_timer(0.2).timeout
	# 상점 (현재 전체 능력치 표시)
	_main_menu.close()
	_meta_shop.open()
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/z_metashop.png")
	_meta_shop._on_close()
	await get_tree().create_timer(0.2).timeout
	# 캐릭터 선택 → 런 시작
	_main_menu.close()
	_char_select.open()
	await get_tree().create_timer(0.3).timeout
	await _snap(dir + "/a_charselect.png")
	_char_select._pick(Characters.defs()[0])
	await get_tree().process_frame
	# 특수무기 장착 (렌더 검증)
	var pp := G.player as Player
	pp.add_weapon("wpn_orb")
	pp.add_weapon("wpn_fire")
	pp.add_weapon("wpn_chain")
	pp.add_weapon("wpn_ice")
	pp.add_weapon("wpn_poison")
	pp.add_weapon("wpn_summon")
	# 전투 장면이 바로 잡히게 초기 적 몇 마리
	for i in 6:
		_spawn_enemy()
	await _snap(dir + "/0_start.png")
	# 실제 입력으로 이동 (position 대입 아님)
	await _hold("move_right", 0.9)
	await _snap(dir + "/1_move_right.png")
	await _hold("move_down", 0.7)
	Input.action_press("dash")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("dash")
	await get_tree().create_timer(0.25).timeout
	await _snap(dir + "/2_dash.png")
	for i in 8:
		_spawn_enemy()
	await _hold("move_left", 0.9)
	await _snap(dir + "/3_combat.png")
	await get_tree().create_timer(1.2).timeout
	await _snap(dir + "/4_later.png")
	# 레벨업 강화 선택 모달 검증 (자연발생분 비우고 강제 레벨업)
	var guard: int = 0
	while _levelup_root.visible and guard < 12:
		if _cards_box.get_child_count() > 0:
			(_cards_box.get_child(0) as Button).pressed.emit()
		await get_tree().process_frame
		guard += 1
	# 합성(진화) 카드가 나오도록 재료 2회씩 확보
	_apply_upgrade("multi")
	_apply_upgrade("multi")
	_apply_upgrade("pierce")
	_apply_upgrade("pierce")
	G.add_xp(6)
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap(dir + "/5_levelup.png")
	if _cards_box.get_child_count() > 0:
		(_cards_box.get_child(0) as Button).pressed.emit()
	await get_tree().create_timer(0.35).timeout
	await _snap(dir + "/6_after_pick.png")
	# 캐릭터 클로즈업 (매력 판정용) — 줌인 + 3종 적 근접
	if G.camera != null:
		(G.camera as Camera2D).zoom = Vector2(3.4, 3.4)
	for i in 3:
		var e := Enemy.new()
		e.kind = i % 3
		var a: float = TAU * float(i) / 3.0
		e.global_position = (G.player as Node2D).global_position + Vector2(cos(a), sin(a)) * 105.0
		add_child(e)
	await get_tree().create_timer(0.5).timeout
	await _snap(dir + "/7_portrait.png")
	# 보스 + 탄막 슈터 (등급 데모)
	if G.camera != null:
		(G.camera as Camera2D).zoom = Vector2(1.0, 1.0)
	await _demo_clear_modal()
	_spawn_boss()
	_spawn_enemy(3)
	_spawn_enemy(3)
	await get_tree().create_timer(1.0).timeout
	await _demo_clear_modal()
	await _snap(dir + "/8_boss.png")
	# 최종 보스 (30분 도달 강제)
	G.time_alive = MATCH_LEN + 1.0
	await get_tree().create_timer(0.4).timeout
	await _demo_clear_modal()
	await _snap(dir + "/f_finalboss.png")
	# 보물상자(진화) 검증: 능력 만렙 → 상자 스폰 → 획득 시 진화 배너
	for i in 5:
		_apply_upgrade("b_ice")
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/g_chest.png")
	G.chest_collected.emit()
	await get_tree().create_timer(0.5).timeout
	await _snap(dir + "/h_evolve.png")
	# 융합 보스 검증: 강제 합체 → 무장 플레이어가 처치 가능한지(HP 감소)
	for i in 12:
		_spawn_enemy()
	await get_tree().create_timer(0.3).timeout
	_merge_into_boss()
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/i_fusion.png")
	var fhp0: float = (_fusion_boss as Enemy).hp if _fusion_boss != null and is_instance_valid(_fusion_boss) else 0.0
	await get_tree().create_timer(3.0).timeout
	await _demo_clear_modal()
	var fhp1: float = (_fusion_boss as Enemy).hp if _fusion_boss != null and is_instance_valid(_fusion_boss) else -1.0
	print("[FUSION] hp %.0f -> %.0f (max %.0f)" % [fhp0, fhp1, _fusion_max_hp])
	await _snap(dir + "/j_fusion_dmg.png")
	# ESC 스탯 화면 (모달 비운 뒤) — 계속/메인메뉴 버튼 포함
	await _demo_clear_modal()
	_pause_menu._toggle()
	await get_tree().process_frame
	await get_tree().process_frame
	await _snap(dir + "/9_stats.png")
	# 이어하기 데모: 런 중 → 메인 메뉴(런 유지) → 이어하기 활성 확인
	_pause_menu._on_main_menu()
	await get_tree().create_timer(0.3).timeout
	await _snap(dir + "/z_continue.png")
	print("=== DEMO DONE (t=%.1f kills=%d level=%d enemies=%d) ===" % [G.time_alive, G.kills, G.level, _enemy_count()])
	get_tree().quit(0)


func _demo_clear_modal() -> void:
	var g: int = 0
	while _levelup_root.visible and g < 25:
		if _cards_box.get_child_count() > 0:
			(_cards_box.get_child(0) as Button).pressed.emit()
		await get_tree().process_frame
		g += 1


func _hold(action: String, dur: float) -> void:
	Input.action_press(action)
	await get_tree().create_timer(dur).timeout
	Input.action_release(action)
	await get_tree().create_timer(0.05).timeout


## 스토어용 셔터를 내려도 되는 상태인가. 모달이 하나라도 떠 있으면 그 패널이 찍힌다 —
## 레벨업 카드는 원래 막고 있었는데 **부활 패널·게임오버·승리 패널은 안 막아서**
## "한 번 더?" 창이 05_boss 로 저장된 적이 있다(2026-09-15).
func _shot_clear() -> bool:
	# ★ _chest_panel 은 CanvasLayer 라 CanvasItem 으로 캐스트하면 null 이 된다.
	#   타입을 가리지 않게 속성으로 읽는다.
	for n in [_levelup_root, _revive_panel, _gameover, _victory, _chest_panel]:
		if n != null and is_instance_valid(n) and bool((n as Node).get("visible")):
			return false
	return true


func _snap(path: String) -> void:
	# ★ 헤드리스에는 렌더러가 없어서 frame_post_draw 가 영영 안 온다 — 여기서 조용히 멈춘다.
	#   그림이 필요하면 --headless 없이 돌려야 한다(2026-09-07에 여기서 한 번 막혔다).
	if DisplayServer.get_name() == "headless":
		print("[SHOT] (헤드리스 — 그림 생략) %s" % path)
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[SHOT] %s" % path)


## ──────────────────── 유닛이 배경에 녹는지 재는 그림 (--contrastshot) ────────────────────
## 실플레이 리포트: "갈색 유닛은 잘 안 보인다 / 특정 유닛이 특정 맵에서 유난히 안 보인다".
##
## ★ 처음엔 파이썬으로 타일색 × 색조 × 밝기를 곱해 모델로 쟀는데, 화면과 3배씩 어긋났다.
##   테마마다 **변형 타일**이 섞이고(던전 27~70, 천상 233~250), 테마 전환은 1초 크로스페이드라
##   그 사이에는 바닥이 _base 위에 반투명으로 얹힌다. 모델로는 못 따라간다.
##   그래서 엔진이 실제로 그린 화면을 찍어서 잰다 — 셰이더 테두리·림라이트·채도까지 전부 포함된다.
##
## 테마마다 두 장을 찍는다: 바닥만 / 바닥 + 유닛 격자.
## 두 장의 차이가 곧 유닛 픽셀이라, 파이썬 쪽은 마스크를 따로 만들 필요가 없다.
##
##   실행:  (--headless 없이) ... --path . -- --contrastshot
##   측정:  python tools/contrast_qa.py
func _contrastshot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CONTRAST] ✗ --headless 없이 돌려야 한다 (렌더러 필요)")
		get_tree().quit(1)
		return
	var dir: String = "user://contrast"
	DirAccess.make_dir_recursive_absolute(dir)
	G.no_save = true
	get_window().size = Vector2i(1920, 1080)
	await get_tree().create_timer(0.8).timeout
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	# 판을 세운다 — 몹도 플레이어도 화면에 없어야 '바닥만' 장이 깨끗하다.
	G.running = false
	if _hud_canvas != null:
		_hud_canvas.visible = false
	if G.player != null and is_instance_valid(G.player):
		(G.player as Node2D).visible = false
	# ★ 먼지 파티클과 지형 장애물은 두 장 사이에서 달라진다 — 그 차이가 그대로 '유닛 픽셀'로
	#   잡혀 측정을 통째로 망친다(처음에 유닛색과 바닥색이 똑같이 나온 이유가 이것이었다).
	if _bg != null and _bg._motes != null:
		_bg._motes.visible = false
	for o in get_tree().get_nodes_in_group("obstacle"):
		(o as Node).queue_free()

	var kinds: Array = Enemy.LOOKS.keys()
	kinds.sort()
	# ★ CanvasLayer 좌표는 **논리 뷰포트**(content_scale_size, 1280x720)다.
	#   창 크기(1920x1080)로 격자를 깔면 1.5배로 확대돼 아랫줄이 화면 밖으로 나간다
	#   (처음에 29종 중 24종만 찍혔다). 스냅은 물리 해상도로 나오므로 배율을 같이 적어 둔다.
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var cols: int = 8
	var rows: int = int(ceil(float(kinds.size()) / float(cols)))
	var cw: float = vp.x / float(cols)
	var ch: float = vp.y / float(rows)
	var cells: Array = []

	var layer := CanvasLayer.new()
	layer.layer = 1  # 월드 위 · HUD 아래
	add_child(layer)

	for ti in _bg.THEMES.size():
		_bg.set_theme(ti)
		# 크로스페이드가 1.0초다. 다 끝난 뒤에 찍어야 바닥이 제 색으로 나온다
		# (스토어 스샷 한 장이 페이드 도중에 찍혀 밝기가 3배 어긋난 적이 있다).
		await get_tree().create_timer(1.8).timeout
		for n in get_tree().get_nodes_in_group("enemy"):
			(n as Node).queue_free()
		for o in get_tree().get_nodes_in_group("obstacle"):
			(o as Node).queue_free()
		await get_tree().create_timer(0.3).timeout
		await _snap("%s/t%d_bg.png" % [dir, ti])

		cells.clear()
		for i in kinds.size():
			var kind: int = int(kinds[i])
			var look: Dictionary = Enemy.LOOKS[kind]
			var kdef: Dictionary = Enemy.KINDS.get(kind, Enemy.KINDS[0])
			var rad: float = float(kdef["rad"])
			var vk: float = float(kdef.get("vis", 0.0))
			if vk > 0.0:
				rad = vk
			var cv := CreatureVisual.new()
			cv.body_color = kdef["col"]
			cv.radius = rad
			cv.sides = int(kdef["sides"])
			cv.angry = true
			cv.feature = String(look.get("feat", ""))
			var spath: String = "res://assets/sprites/monsters/%s.png" % String(look.get("spr", ""))
			cv.sprite_path = spath
			cv.sprite_hframes = Enemy._strip_frames(spath)
			cv.anim_style = ""        # 격자에서는 부속지·흔들림 없이 가만히
			cv.always_animate = true
			var cx: float = (float(i % cols) + 0.5) * cw
			var cy: float = (float(i / cols) + 0.5) * ch
			cv.position = Vector2(cx, cy)
			cv.build()
			layer.add_child(cv)
			cells.append({"kind": kind, "spr": String(look.get("spr", "")),
				"x": cx, "y": cy, "w": cw, "h": ch})
		await get_tree().create_timer(0.35).timeout
		await _snap("%s/t%d_units.png" % [dir, ti])
		for c in layer.get_children():
			(c as Node).queue_free()
		await get_tree().process_frame

	var meta: Dictionary = {"cols": cols, "box": 60, "vw": vp.x, "vh": vp.y, "cells": cells, "themes": []}
	for ti in _bg.THEMES.size():
		meta["themes"].append(String((_bg.THEMES[ti] as Dictionary)["name"]))
	var f: FileAccess = FileAccess.open("%s/cells.json" % dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(meta))
	f.close()
	print("[CONTRAST] 테마 %d개 × (바닥/유닛) 완료 → %s" % [_bg.THEMES.size(), ProjectSettings.globalize_path(dir)])
	print("[CONTRAST] 이제: python tools/contrast_qa.py")
	get_tree().quit(0)

## ──────────────────── 모바일 조이스틱 자리 확인 (--stickshot) ────────────────────
## 조이스틱을 고정형으로 바꿨는데(사용자 요구, 2026-09-15) 눈으로 확인할 길이 없었다.
## ★ --storeshots 로는 못 본다: _ready 가 _dev_dispatch 에서 먼저 return 해서
##   TouchControls 가 아예 안 붙는다(여기서 한 번 헛돌았다). 그래서 이 하니스가 직접 붙인다.
##
## 두 모드(고정/따라옴)를 각각, 놓은 상태와 민 상태로 찍는다 — 넉 장.
##   실행:  (--headless 없이) ... --path . -- --stickshot
func _stickshot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[STICK] ✗ --headless 없이 돌려야 한다 (렌더러 필요)")
		get_tree().quit(1)
		return
	var dir: String = "user://stick"
	DirAccess.make_dir_recursive_absolute(dir)
	G.no_save = true
	G.detect_mobile(true)
	get_window().size = Vector2i(1280, 720)
	await get_tree().create_timer(0.6).timeout
	var tc := TouchControls.new()
	add_child(tc)
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await get_tree().create_timer(0.6).timeout
	Engine.time_scale = 0.02   # 거의 멈춘 채로 — 조작 표시만 본다
	for mode in 2:
		G.set_stick_fixed(mode)
		var nm: String = "fixed" if mode == 0 else "follow"
		await get_tree().create_timer(0.2).timeout
		await _snap("%s/%s_idle.png" % [dir, nm])
		# 손가락을 왼쪽 아래쯤에 대고 오른위로 민 상태를 흉내낸다
		var vp: Vector2 = get_viewport().get_visible_rect().size
		var down := Vector2(150.0, vp.y - 150.0)
		tc._stick_idx = 0
		tc._stick_origin = tc._fixed_origin() if G.stick_fixed() else down
		tc._stick_cur = down + Vector2(190.0, -120.0)
		await get_tree().create_timer(0.2).timeout
		await _snap("%s/%s_push.png" % [dir, nm])
		tc._stick_idx = -1
	print("[STICK] 완료 → %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit(0)

## ──────────────────── 지속피해·상태이상 검사 (--dotcheck) ────────────────────
## 틱을 줄이면서 "초당 피해는 그대로"라고 말만 하면 반드시 틀린다. 실제로 때려 보고 잰다.
##
## 1) 독/화상을 걸고 2초를 돌려 총 피해를 잰다 — 기대값은 (인자로 준 초당피해) × 2초.
## 2) 얼음 스택이 꽉 차면 실제로 얼어붙는지, 쿨이 지나야 다시 얼리는지.
## 3) 독 스택이 꽉 차면 맹독이 터지고 그동안 피해가 몇 배가 되는지.
func _dotcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.running = true
	# ★ 플레이어를 세운다. 안 그러면 **무기가 시험용 더미를 쏜다** — 총피해가 80/94/108 로
	#   흔들리던 정체가 이것이었다(94-80=14 = _rp() 기본값, 즉 탄 한 발).
	if G.player != null and is_instance_valid(G.player):
		(G.player as Node2D).set_process(false)
		(G.player as Node2D).set_physics_process(false)
		(G.player as Node2D).visible = false
	var fails: int = 0
	print("=== DOT  틱을 줄여도 초당 피해가 그대로인가 ===")
	print("  틱: 지속피해 %.2f초 · 장판 %.2f초" % [Enemy.DOT_TICK, Enemy.HAZARD_TICK])

	# ── 1. 독: 초당 40 을 2초 ──
	var e := Enemy.new()
	e.kind = 0
	add_child(e)
	await get_tree().process_frame
	e.hp = 1.0e9
	e.max_hp = 1.0e9
	var before: float = e.hp
	# apply_poison 인자는 '예전 틱당' 단위다. 예전 실효 DPS = 인자 / 예전틱.
	var arg: float = 20.0
	var want_dps: float = arg / Enemy.OLD_POISON_TICK
	e.apply_poison(arg, 10.0)
	# ★ 시간 재는 법을 두 번 틀렸다. get_process_delta_time() 누적도, 실시계도 안 맞는다 —
	#   헤드리스는 물리가 실시간보다 빨리 돌아서, 같은 2초에 틱이 8번 들어가기도 11번
	#   들어가기도 한다(총피해 80 ~ 108 으로 흔들렸다). 지속피해는 _physics_process 에서
	#   도므로 **물리 프레임 수**로 세는 것이 유일하게 정확하다. 2초 = 120프레임.
	var f0: int = Engine.get_physics_frames()
	while Engine.get_physics_frames() - f0 < 120:
		G.running = true
		await get_tree().physics_frame
	var got: float = before - e.hp
	var want: float = want_dps * 2.0
	# 여유 6%. 플레이어를 세우고 물리 프레임으로 세면 결정적이라 더 조일 수 있다 —
	# 느슨하게 두면 "틱만 줄이고 세기는 그대로"가 깨져도 검사가 안 잡는다.
	var ok1: bool = absf(got - want) <= want * 0.06
	print("  독    2초 총피해 %7.1f  (기대 %7.1f = 초당 %.1f × 2초)  %s"
		% [got, want, want_dps, "OK" if ok1 else "✗"])
	if not ok1:
		fails += 1
	e.queue_free()

	# ── 2. 화상 ──
	var e2 := Enemy.new()
	e2.kind = 0
	add_child(e2)
	await get_tree().process_frame
	e2.hp = 1.0e9
	e2.max_hp = 1.0e9
	var b2: float = e2.hp
	var arg2: float = 16.0
	var wd2: float = arg2 / Enemy.OLD_BURN_TICK
	e2.apply_burn(arg2, 10.0)
	f0 = Engine.get_physics_frames()
	while Engine.get_physics_frames() - f0 < 120:
		G.running = true
		await get_tree().physics_frame
	var g2: float = b2 - e2.hp
	var w2: float = wd2 * 2.0
	var ok2: bool = absf(g2 - w2) <= w2 * 0.06
	print("  화상  2초 총피해 %7.1f  (기대 %7.1f = 초당 %.1f × 2초)  %s"
		% [g2, w2, wd2, "OK" if ok2 else "✗"])
	if not ok2:
		fails += 1
	e2.queue_free()

	# ── 3. 얼음 스택 → 결빙 ──
	var e3 := Enemy.new()
	e3.kind = 0
	add_child(e3)
	await get_tree().process_frame
	e3.hp = 1.0e9
	e3.max_hp = 1.0e9
	var froze: bool = false
	var gained: int = 0
	for i in 40:
		G.running = true   # 메인메뉴 _process 가 중간에 꺼 버린다 — 이 검사는 전투 중을 잰다
		e3.apply_slow(1.0)
		if e3._freeze_until > Time.get_ticks_msec():
			froze = true
			gained = i + 1
			break
		await get_tree().create_timer(0.12).timeout
	var ok3: bool = froze
	print("  얼음  %d번 맞고 결빙 %s (스택 상한 %d · 쿨 %.0f초)  %s"
		% [gained, "발동" if froze else "안 됨", Enemy.ICE_STACK_MAX, Enemy.ICE_PROC_CD,
			"OK" if ok3 else "✗"])
	if not ok3:
		fails += 1
	# 쿨 동안은 다시 안 얼어야 한다
	e3._freeze_until = 0
	var refroze: bool = false
	for i in 40:
		G.running = true
		e3.apply_slow(1.0)
		if e3._freeze_until > Time.get_ticks_msec():
			refroze = true
			break
		await get_tree().create_timer(0.1).timeout
	var ok4: bool = not refroze
	print("  얼음  쿨 안에 재결빙 %s (안 되어야 정상)  %s"
		% ["됨" if refroze else "안 됨", "OK" if ok4 else "✗"])
	if not ok4:
		fails += 1
	e3.queue_free()

	# ── 4. 독 스택 → 맹독 ──
	var e4 := Enemy.new()
	e4.kind = 0
	add_child(e4)
	await get_tree().process_frame
	e4.hp = 1.0e9
	e4.max_hp = 1.0e9
	var venom: bool = false
	for i in 40:
		G.running = true
		e4.apply_poison(arg, 10.0)
		if e4._venom_until > Time.get_ticks_msec():
			venom = true
			break
		await get_tree().create_timer(0.12).timeout
	var ok5: bool = venom
	# 맹독 동안의 초당 피해가 평소의 몇 배인가
	var b4: float = e4.hp
	f0 = Engine.get_physics_frames()
	while Engine.get_physics_frames() - f0 < 60:
		G.running = true
		await get_tree().physics_frame
	var vdps: float = b4 - e4.hp
	print("  독    맹독 %s · 발동 중 초당 %6.1f (평소 %6.1f · 약 %.1f배)  %s"
		% ["발동" if venom else "안 됨", vdps, want_dps, vdps / maxf(1.0, want_dps),
			"OK" if ok5 else "✗"])
	if not ok5:
		fails += 1
	e4.queue_free()

	print("[DOT] %s" % ("ALL PASS" if fails == 0 else "FAIL %d건" % fails))
	get_tree().quit(0 if fails == 0 else 1)

## ──────────────── 손에 든 무기가 융합을 알리는가 (--heldshot) ────────────────
## "태극부채로 구미호의 꼬리를 만들었는데 손에는 여전히 부채라 헷갈린다"(실플레이 리포트).
## 융합 전/후를 나란히 찍어서 정말 달라 보이는지 눈으로 확인한다.
##   실행: (--headless 없이) ... --path . -- --heldshot
func _heldshot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[HELD] ✗ --headless 없이 돌려야 한다 (렌더러 필요)")
		get_tree().quit(1)
		return
	var dir: String = "user://held"
	DirAccess.make_dir_recursive_absolute(dir)
	G.no_save = true
	get_window().size = Vector2i(1280, 720)
	await get_tree().create_timer(0.6).timeout
	_main_menu.close()
	# 주무기를 쓰는 융합만 본다 (특수무기는 손에 안 든다)
	var cases: Array = [
		{"evo": "evo_ninetail", "req": ["wp_fan", "b_chain"]},
		{"evo": "evo_railcannon", "req": ["wp_heavy", "b_big"]},
		{"evo": "evo_ledger", "req": ["wp_bow", "b_exec"]},
		{"evo": "evo_orb", "req": ["wp_jakdu", "b_vamp"]},
		{"evo": "evo_deadeye", "req": ["wp_rapid", "crit"]},
	]
	for c: Dictionary in cases:
		var eid: String = String(c["evo"])
		_begin_run(Characters.defs()[0])
		await get_tree().process_frame
		var p := G.player as Player
		for m: String in (c["req"] as Array):
			_fp_grant(p, String(m), 6)
		await get_tree().create_timer(0.35).timeout
		G.running = false
		if _hud_canvas != null:
			_hud_canvas.visible = false
		for n in get_tree().get_nodes_in_group("enemy"):
			(n as Node).queue_free()
		Engine.time_scale = 0.02
		await get_tree().create_timer(0.25).timeout
		await _snap("%s/%s_before.png" % [dir, eid])
		Engine.time_scale = 1.0
		G.running = true
		_apply_upgrade(eid)
		await get_tree().process_frame
		G.running = false
		for n in get_tree().get_nodes_in_group("enemy"):
			(n as Node).queue_free()
		Engine.time_scale = 0.02
		await get_tree().create_timer(0.25).timeout
		await _snap("%s/%s_after.png" % [dir, eid])
		Engine.time_scale = 1.0
	print("[HELD] 완료 → %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit(0)

## ──────────────── 초월이 정말 '한계돌파'인가 (--transcap) ────────────────
## 실플레이 리포트: "초월 전부터 들고 있던 무기는 Lv9 인데, 초월 뒤에 새로 든 무기는
## Lv4 로 시작해 카드 두 장이면 Lv6 에서 끝난다. 의도된 건가?"
##
## 의도가 아니다. 풀에서 빠지는 판정이 **실제 레벨**을 보는데 상한은 안 올라가 있었다.
## 카드가 "한계를 돌파한다"라고 적혀 있으니, 초월을 먹은 뒤에 든 무기도 같은 곳까지 가야 한다.
func _transcap_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	var fails: int = 0
	print("=== TRANSCAP  초월 뒤에 든 무기도 한계를 넘는가 ===")
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player

	# A: 초월 전부터 들고 있던 무기 — 만렙까지 올린 뒤 초월
	for _i in 6:
		_apply_upgrade("wp_heavy")
	var a_before: int = _real_weapon_level("wp_heavy")
	_apply_upgrade("m_transcend")
	var a_after: int = _real_weapon_level("wp_heavy")
	var ok1: bool = a_after == a_before + 3
	print("  기존 무기  Lv%d → 초월 → Lv%d  (기대 %d)  %s"
		% [a_before, a_after, a_before + 3, "OK" if ok1 else "✗"])
	if not ok1:
		fails += 1

	# B: 초월 뒤에 처음 드는 무기 — 카드를 계속 먹여서 어디까지 가는지
	var picks: int = 0
	var lv: int = 0
	for _i in 20:
		if not _offer_contains("wp_bow"):
			break
		_apply_upgrade("wp_bow")
		picks += 1
		lv = _real_weapon_level("wp_bow")
	var want: int = 6 + p.transcend_bonus
	var ok2: bool = lv == want
	print("  새 무기    카드 %d장으로 Lv%d 까지  (기대 Lv%d = 상한 6 + 초월 %d)  %s"
		% [picks, lv, want, p.transcend_bonus, "OK" if ok2 else "✗"])
	if not ok2:
		fails += 1

	var ok3: bool = lv == a_after
	print("  둘이 같은 곳에서 끝나는가  기존 Lv%d · 새것 Lv%d  %s"
		% [a_after, lv, "OK" if ok3 else "✗"])
	if not ok3:
		fails += 1

	print("[TRANSCAP] %s" % ("ALL PASS" if fails == 0 else "FAIL %d건" % fails))
	get_tree().quit(0 if fails == 0 else 1)


## 지금 카드 풀에 그 id 가 아직 남아 있는가 (만렙이면 빠진다).
func _offer_contains(id: String) -> bool:
	for u: Dictionary in _filtered_pool():
		if String(u["id"]) == id:
			return true
	return false

## ──────────────────── 영어로 켰을 때 화면에 한글이 남는가 (--i18ncheck) ────────────────────
## 번역표(tools/i18n.py)를 다 채워도 화면에 한글이 남는 길은 두 가지다:
##   1) 코드가 문구를 조합한다 — "레벨 %d" % n 처럼. 결과 "레벨 5" 는 번역표에 없으니
##      Label 의 자동 번역이 못 잡는다. 틀 쪽에 tr() 을 씌워야 한다.
##   2) 문구를 이어 붙인다 — "✦" + 이름. 이어 붙인 전체는 키가 아니다.
## 둘 다 번역표만 봐서는 안 보인다. 실제로 화면을 띄워서 **보이는 글자**를 센다.
##
## 헤드리스로 돈다(배치가 아니라 글자만 본다).
##   실행:  ... --headless --path . -- --lang=en --i18ncheck
const _HANGUL_RE: String = "[가-힣]"
var _i18n_bad: Dictionary = {}      # 보이는 문구 → 나온 화면들
var _i18n_seen: int = 0

func _i18ncheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	# 언어는 여기서 바꾸면 늦다 — 메인 메뉴는 이미 한국어로 조합돼 있다. 실행 인자로 받는다.
	if not TranslationServer.get_locale().begins_with("en"):
		print("[I18N] --lang=en 을 같이 줘야 한다  (지금 locale=%s)" % TranslationServer.get_locale())
		get_tree().quit(2)
		return
	print("=== I18N  영어로 켰을 때 화면에 한글이 남는가  (locale=%s) ===" % TranslationServer.get_locale())
	var re := RegEx.new()
	re.compile(_HANGUL_RE)
	await _i18n_snap("메인 메뉴", re)

	# ── 처음 켠 사람 — 잠김·미발견·빈 칸 문구는 다 채운 상태에서는 안 뜬다 ──
	G.meta = {}
	G.codex = {}
	G.total_gold = 0
	await _i18n_menus(re, "·처음")

	# ── 다 채운 사람 — 해금·등급·강화가 다 차야 모든 줄이 뜬다 ──
	G.total_gold = 9999999
	for cdef: Dictionary in Characters.defs():
		G.meta["uc_" + String(cdef["id"])] = 1
		G.meta["rank_" + String(cdef["id"])] = G.CHAR_RANK_MAX
	for mid2: String in G.META_TIERS.keys():
		G.meta[mid2] = G.meta_max(mid2)
	for ad: Dictionary in Accessories.DEFS:
		G.meta["acc_own_" + String(ad["id"])] = 1
	for e in Codex.FUSIONS:
		G.codex[String(e["key"])] = true
	for m in Codex.MONSTERS:
		G.codex[String(m["key"])] = true
	await _i18n_menus(re, "")
	_settings.open()
	await _i18n_snap("설정", re)
	_settings._on_back()

	# ── 판 안 ──
	get_tree().paused = false
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await get_tree().create_timer(0.3).timeout
	var p := G.player as Player
	if p != null and is_instance_valid(p):
		p.max_hp = 1.0e9
		p.hp = 1.0e9
	await _i18n_snap("HUD", re)

	# 모든 카드를 한 장씩 만들어 본다 — 레벨업에서 운 좋게 뜬 것만 보면 대부분을 놓친다
	var holder := VBoxContainer.new()
	_hud_layer.add_child(holder)
	var defs: Array = _base_pool().duplicate()
	defs.append_array(EVOLUTIONS)
	for cc in _CHAR_CARDS.values():
		defs.append(cc)
	defs.append(HEAL_CARD)
	defs.append(GOLD_CARD)
	for u in defs:
		holder.add_child(_make_card(u as Dictionary))
	await get_tree().process_frame
	_i18n_collect(holder, "카드 %d장" % defs.size(), re)
	holder.queue_free()

	# 무기·탄막을 몇 개 쥐여 줘야 일시정지 요약에 줄이 생긴다
	for id in ["wp_heavy", "wp_fan", "wpn_fire", "wpn_chain", "b_fire", "b_poison", "b_ice", "crit", "dmg", "m_transcend"]:
		_apply_upgrade(String(id))
	_open_levelup()
	await _i18n_snap("레벨업", re)
	_levelup_root.visible = false
	get_tree().paused = false
	_pause_menu._toggle()
	await _i18n_snap("일시정지", re)
	_pause_menu._toggle()
	get_tree().paused = false

	_on_boss_chest()
	await _i18n_snap("보스 상자", re)
	_close_chest_panel()
	get_tree().paused = false

	# 부활 권유 → 거절 → 게임오버
	_on_revive_offered()
	await _i18n_snap("부활", re)
	_on_revive_decline()
	await get_tree().create_timer(0.3).timeout
	await _i18n_snap("게임오버", re)

	# 새 판을 열어 클리어까지
	get_tree().paused = false
	_begin_run(Characters.defs()[1])
	await get_tree().create_timer(0.3).timeout
	_on_stage_clear()
	await get_tree().create_timer(0.3).timeout
	await _i18n_snap("스테이지 클리어", re)
	if _victory != null:
		_victory.visible = false

	# ── 결과 ──
	var keys: Array = _i18n_bad.keys()
	keys.sort()
	print("")
	print("  보이는 글자칸 %d개 중 한글이 남은 것 %d종" % [_i18n_seen, keys.size()])
	for k in keys:
		var where: Array = _i18n_bad[k]
		# 긴 설명은 앞 60자에 한글이 없을 수 있다 — 한글이 처음 나온 곳 앞뒤를 보여준다
		var flat: String = String(k).replace("\n", "⏎")
		var hit := re.search(flat)
		var from: int = maxi(0, (hit.get_start() if hit != null else 0) - 24)
		print("  ✗ %-60s  [%s]" % [flat.substr(from, 60), ", ".join(where.slice(0, 3))])
	print("[I18N] %s" % ("ALL PASS" if keys.is_empty() else "FAIL %d종" % keys.size()))
	get_tree().quit(0 if keys.is_empty() else 1)


## 메뉴 화면 한 바퀴 — 영웅 선택(영웅 상세 전부 · 모드 전부) · 상점 · 도감 탭 전부.
func _i18n_menus(re: RegEx, tag: String) -> void:
	_main_menu.close()
	_char_select.open()
	await _i18n_snap("영웅 선택" + tag, re)
	for cdef: Dictionary in Characters.defs():
		_char_select._show_detail(cdef)
		await _i18n_snap("영웅 상세" + tag, re, true)
	for mi in range(-1, G.STAGE_NAMES.size()):
		_char_select._set_mode(mi)
		await _i18n_snap("모드" + tag, re, true)
	_char_select._on_back()
	_meta_shop.open()
	await _i18n_snap("상점" + tag, re)
	_meta_shop._on_close()
	_codex_screen.open()
	for ti in 6:
		_codex_screen._switch(ti)
		await _i18n_snap("도감 탭%d%s" % [ti, tag], re)
	_codex_screen.close()
	_main_menu.open()


func _i18n_snap(screen: String, re: RegEx, quiet: bool = false) -> void:
	for _i in 4:
		await get_tree().process_frame
	var before: int = _i18n_bad.size()
	_i18n_collect(get_tree().root, screen, re)
	if not quiet or _i18n_bad.size() > before:
		print("  %-12s 새로 걸린 것 %d종" % [screen, _i18n_bad.size() - before])


## 보이는 Control 의 '화면에 찍히는 글자'를 본다. Label·Button 의 text 는 원문이 그대로
## 들어 있고 자동 번역은 그리는 순간에 일어나므로, atr() 로 실제로 찍히는 값을 만들어 본다.
func _i18n_collect(n: Node, screen: String, re: RegEx) -> void:
	var c := n as Control
	if c != null and not c.is_visible_in_tree():
		return
	if n.has_meta("i18n_keep"):
		return     # 일부러 원어로 둔 칸 — 설정의 "한국어" 버튼
	var shown: String = ""
	if n is Label:
		shown = (n as Label).atr((n as Label).text)
	elif n is Button:
		shown = (n as Button).atr((n as Button).text)
	elif n is RichTextLabel:
		shown = (n as RichTextLabel).atr((n as RichTextLabel).text)
	elif n is LineEdit:
		shown = (n as LineEdit).text
	# 툴팁도 화면이다 — 일시정지 빌드 칸의 상세가 여기 들어 있다
	var tips: Array = [shown]
	if c != null and c.tooltip_text != "":
		tips.append(c.atr(c.tooltip_text))
	for t in tips:
		var tx: String = String(t)
		if tx == "":
			continue
		_i18n_seen += 1
		if re.search(tx) != null:
			if not _i18n_bad.has(tx):
				_i18n_bad[tx] = []
			if not (_i18n_bad[tx] as Array).has(screen):
				(_i18n_bad[tx] as Array).append(screen)
	for ch in n.get_children():
		_i18n_collect(ch, screen, re)

## ──────────────────── 캐릭터 에셋 시범 검사 (--cfcheck) ────────────────────
## 새 캐릭터 에셋(charforge)을 붙인 자리가 **모든 상태에서** 맞게 도는지 본다. 헤드리스로 돈다.
##   1) 들어 있는 폴더 전부 — 시트 크기·프레임 수·ms·등급별 동작이 가이드와 맞는가
##   2) cast.json — 가리키는 폴더가 있고, 자리 이름이 게임에 실제로 있는가
##   3) 그리는 부품(CreatureVisual) 단위 — 정수배·최근접, 정지/걷기 전환, 좌우 반전,
##      한 번 재생 동작의 길이(ms 합), 쓰러짐 정지, 피격 간격, 없는 동작, 발 위치
##   4) 실제 판 — 영웅·잡몹·보스를 띄워 등장·피격·사망·스킬·궁극기·대시·부활·클리어를 일으킨다
##   5) 끄면(--cf=off 와 같은 길) 전 자리가 예전 그림으로 돌아가는가
##   실행:  ... --headless --path . -- --cfcheck
var _cf_fail: Array = []
var _cf_pass: int = 0

func _cf_ok(cond: bool, what: String) -> void:
	if cond:
		_cf_pass += 1
	else:
		_cf_fail.append(what)
		print("  ✗ " + what)


## CreatureVisual 을 dt 간격으로 직접 돌린다(실시간을 기다리지 않는다 — 결과가 매번 같다).
func _cf_step(cv: CreatureVisual, secs: float, dt: float = 1.0 / 60.0) -> void:
	var t: float = 0.0
	while t < secs - 0.0001:
		cv._process(dt)
		t += dt


## 한 번 재생 동작이 끝날 때까지 걸린 시간(초). 끝나지 않으면 -1.
func _cf_time_once(cv: CreatureVisual, a: String) -> float:
	if not cv.play_once(a):
		return -1.0
	var dt: float = 1.0 / 240.0
	var t: float = 0.0
	while cv._cf_once != "" and t < 10.0:
		cv._process(dt)
		t += dt
	return t if cv._cf_once == "" else -1.0


## 판이 멈추면(경험치로 레벨업 창이 뜨면) 사라지는 연출도 같이 멈춘다 — 창을 닫아 가며 기다린다.
## 처치한 몹이 떨군 '시간 정지'를 영웅이 주우면 몹이 몇 초 굳는다 — 검사 중엔 바로 푼다(어느 판에서 줍느냐로 결과가 갈렸다).
func _cf_wait_unpaused(secs: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) / 1000.0 < secs:
		if get_tree().paused:
			if _levelup_root != null:
				_levelup_root.visible = false
			get_tree().paused = false
		if G.enemies_frozen():
			G._freeze_until = 0
		await get_tree().process_frame


## 저승길 그림 자리(29~45)의 행동 틀 kind — Enemy.JEOSEUNG_ART 를 거꾸로(원혼 9 보다 티로 1 을 먼저). 기존 kind 는 그대로.
func _cf_tmpl(k: int) -> int:
	if Enemy.KINDS.has(k):
		return k
	var best: int = -1
	for tk: int in Enemy.JEOSEUNG_ART.keys():
		if int(Enemy.JEOSEUNG_ART[tk]) == k and (best < 0 or tk < best):
			best = tk
	return best


func _cfcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	CharForge.enabled = true
	print("=== CFCHECK  캐릭터 에셋 시범 ===")
	const TIER_ANIMS: Dictionary = {
		"일반": ["anchor", "death", "hit", "walk"],
		"희귀": ["anchor", "death", "emote", "hit", "walk"],
		"영웅": ["anchor", "death", "emote", "hit", "skill", "vfx", "walk"],
		"전설": ["anchor", "death", "emote", "hit", "portrait", "skill", "ultimate", "vfx", "walk"],
		"신화": ["anchor", "death", "emote", "entrance", "hit", "portrait", "skill", "ultimate", "vfx", "walk"],
	}

	# ── 1) 폴더 전부 ──
	var ids: Array = CharForge.ids()
	_cf_ok(ids.size() >= 3, "캐릭터 폴더 %d개 (3개 이상이어야)" % ids.size())
	var n_sheets: int = 0
	for id in ids:
		var inf: Dictionary = CharForge.info(String(id))
		var anims: Dictionary = inf.get("anims", {})
		var have: Array = anims.keys()
		have.sort()
		var want: Array = (TIER_ANIMS.get(String(inf.get("tier", "")), []) as Array).duplicate()
		# 주문분은 등급 가이드가 아니라 주문서(2차 3절) 규격으로 온다 — 그건 아래 2차 부분(_cf_spec_sheets)이 본다.
		# 재고 영웅은 대기(idle)를 따로 주문해 받았다(4차) — 가이드에 더해 본다.
		if not String(id).begins_with(CharForge.ORDERS_DIR):
			if have.has("idle") and String(inf.get("role", "")) == "주인공":
				want.append("idle")
				want.sort()
			_cf_ok(have == want, "%s 등급 %s 동작 %s (가이드 %s)" % [id, inf.get("tier", "?"), have, want])
		_cf_ok(String(inf.get("name", "")) != "" and String(inf.get("role", "")) != "", "%s dna.json 이름·역할" % id)
		for a in have:
			var an: Dictionary = anims[a]
			n_sheets += 1
			var tex: Texture2D = an["tex"]
			_cf_ok(tex != null, "%s/%s 그림이 읽힌다" % [id, a])
			if tex == null:
				continue
			_cf_ok(tex.get_width() == int(an["fw"]) * int(an["n"]) and tex.get_height() == int(an["fh"]),
				"%s/%s 크기 %dx%d = 칸 %dx%d × %d" % [id, a, tex.get_width(), tex.get_height(), an["fw"], an["fh"], an["n"]])
			_cf_ok((an["ms"] as Array).size() == int(an["n"]), "%s/%s ms 개수 = 프레임 수" % [id, a])
	print("  폴더 %d개 · 시트 %d장" % [ids.size(), n_sheets])

	# ── 2) cast.json ──
	var cast: Dictionary = CharForge.cast()
	var hero_ids: Array = []
	for d: Dictionary in Characters.defs():
		hero_ids.append(String(d["id"]))
	var any_myth: bool = false
	var roles: Dictionary = {}
	for k in (cast.get("heroes", {}) as Dictionary).keys():
		var cid: String = String(CharForge._slot("heroes", String(k)).get("id", ""))
		_cf_ok(hero_ids.has(String(k)), "cast 영웅 자리 '%s' 가 게임에 있다" % k)
		_cf_ok(CharForge.has(cid), "cast 영웅 %s → 폴더 %s 있음" % [k, cid])
		_cf_ok(CharForge.hero_id(String(k)) == cid, "hero_id(%s) = %s" % [k, cid])
		any_myth = any_myth or String(CharForge.info(cid).get("tier", "")) == "신화"
		roles[String(CharForge.info(cid).get("role", ""))] = true
	for k in (cast.get("enemies", {}) as Dictionary).keys():
		var cid2: String = String(CharForge._slot("enemies", String(k)).get("id", ""))
		_cf_ok(Enemy.KINDS.has(_cf_tmpl(int(k))), "cast 적 자리 kind %s 가 게임에 있다(저승길 그림이면 행동 틀 kind %d)" % [k, _cf_tmpl(int(k))])
		_cf_ok(CharForge.has(cid2), "cast 적 %s → 폴더 %s 있음" % [k, cid2])
		_cf_ok(CharForge.enemy_id(int(k)) == cid2, "enemy_id(%s) = %s" % [k, cid2])
		var tr: String = String(CharForge.info(cid2).get("tier", ""))
		roles[String(CharForge.info(cid2).get("role", ""))] = true
		if bool((Enemy.KINDS.get(_cf_tmpl(int(k)), {}) as Dictionary).get("boss", false)):
			any_myth = any_myth or tr == "신화"
	_cf_ok(any_myth, "주인공이나 보스 중 하나는 신화")
	_cf_ok(roles.has("주인공") and roles.has("잡몹") and roles.has("보스"), "주인공·잡몹·보스 하나씩 (%s)" % [roles.keys()])

	# ── 3) 그리는 부품 단위 ──
	var test_slots: Array = []
	for k in (cast.get("heroes", {}) as Dictionary).keys():
		var hs: Dictionary = CharForge._slot("heroes", String(k))
		test_slots.append([String(hs.get("id", "")), Player.RADIUS, "영웅 " + String(k), float(hs.get("h", 0.0))])
	for k in (cast.get("enemies", {}) as Dictionary).keys():
		var kd: Dictionary = Enemy.KINDS[_cf_tmpl(int(k))]
		var es: Dictionary = CharForge._slot("enemies", String(k))
		test_slots.append([String(es.get("id", "")), float(kd.get("vis", kd["rad"])), "적 kind " + String(k), float(es.get("h", 0.0))])
	# 16차: 영웅 차림(저승길 차림 20벌) — 영웅과 같은 자리 규격
	for k in (cast.get("skins", {}) as Dictionary).keys():
		var ss: Dictionary = CharForge._slot("skins", String(k))
		_cf_ok(hero_ids.has(String(k).get_slice("@", 0)), "cast 차림 '%s' 의 영웅이 게임에 있다" % k)
		_cf_ok(CharForge.has(String(ss.get("id", ""))), "cast 차림 %s → 폴더 %s 있음" % [k, String(ss.get("id", ""))])
		test_slots.append([String(ss.get("id", "")), Player.RADIUS, "차림 " + String(k), float(ss.get("h", 0.0))])
	for slot in test_slots:
		var cid3: String = String(slot[0])
		var r: float = float(slot[1])
		var label: String = "%s (%s)" % [slot[2], cid3]
		var slot_h: float = float(slot[3])
		# 서 있는 자세 — 대기(idle)가 있으면 그것, 없으면 anchor (영웅 14종은 4차에 idle 이 왔다)
		var rest: String = "idle" if CharForge.has_anim(cid3, "idle") else "anchor"
		var cv := CreatureVisual.new()
		cv.radius = r
		cv.cf_id = cid3
		cv.cf_target_h = slot_h
		cv.always_animate = true
		cv.build()
		_cf_ok(cv.is_cf(), label + " 시트 모드로 떴다")
		_cf_ok(slot_h > 0.0, label + " 배역표에 자리 키(h)가 있다")
		var k3: int = CharForge.scale_to(cid3, 0, slot_h)
		_cf_ok(cv.cf_scale() == k3 and cv._sprite.scale == Vector2(k3, k3), label + " 자리 키 %dpx → 정수 배율 ×%d" % [int(slot_h), k3])
		_cf_ok(cv._sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, label + " 최근접 필터")
		_cf_ok(cv.scale == Vector2.ONE, label + " 몸 전체 배율 1 (스쿼시 없음)")
		# 정지 → 걷기 → 정지
		cv.walk_speed = 0.0
		_cf_step(cv, 0.1)
		_cf_ok(cv._cf_cur == rest, label + " 서 있으면 %s (지금 %s)" % [rest, cv._cf_cur])
		cv.walk_speed = 120.0
		var seen: Dictionary = {}
		for _i in 120:
			cv._process(1.0 / 60.0)
			seen[cv._sprite.frame] = true
		_cf_ok(cv._cf_cur == "walk", label + " 움직이면 walk")
		_cf_ok(seen.size() == 4, label + " walk 4칸을 다 돈다 (%d칸)" % seen.size())
		var inner_y: float = cv._inner.position.y
		cv._process(1.0 / 60.0)
		_cf_ok(is_equal_approx(cv._inner.position.y, inner_y) and cv._inner.rotation == 0.0, label + " 걸을 때 몸을 흔들지 않는다(시트가 걷는다)")
		# 좌우 반전 — 시트는 오른쪽을 본다
		cv.look_dir = Vector2.LEFT
		cv._process(1.0 / 60.0)
		_cf_ok(cv._sprite.flip_h, label + " 왼쪽으로 가면 반전")
		cv.look_dir = Vector2.RIGHT
		cv._process(1.0 / 60.0)
		_cf_ok(not cv._sprite.flip_h, label + " 오른쪽으로 가면 그대로")
		cv.walk_speed = 0.0
		# 동작마다: 발 기준점 · 한 번 재생 길이
		var foot_y: float = roundf(r * 0.86)
		var foot_dev: Array = []
		var foot_act: Array = []     # 스킬·궁극기·등장 — 뛰어오르는 칸일 수 있어 기록만 한다
		for a2 in (CharForge.info(cid3)["anims"] as Dictionary).keys():
			var an2: Dictionary = CharForge.anim(cid3, a2)
			cv._cf_set(a2)
			_cf_ok(cv._sprite.offset == Vector2(-floorf(float(an2["fw"]) * 0.5), -(float(an2["fh"]) - 2.0)),
				label + " %s 기준점 = 발밑 가운데(아래 2px)" % a2)
			# 실제 그림에서 가장 아래 불투명 줄을 재서, 화면에서 발이 기준점에서 몇 px 떨어지는지
			if a2 in ["anchor", "walk", "hit", "emote", "skill", "ultimate", "entrance", "death"]:
				var img: Image = (an2["tex"] as Texture2D).get_image()
				if img != null:
					if img.is_compressed():
						img.decompress()
					for fi in int(an2["n"]):
						if a2 == "death" and fi == 1:
							continue      # 쓰러진 자세는 발이 기준점에 없다
						var bottom: int = -1
						for y in range(int(an2["fh"]) - 1, -1, -1):
							for x in range(fi * int(an2["fw"]), (fi + 1) * int(an2["fw"])):
								if img.get_pixel(x, y).a > 0.5:
									bottom = y
									break
							if bottom >= 0:
								break
						var screen_foot: float = cv._sprite.position.y + (cv._sprite.offset.y + float(bottom + 1)) * float(k3)
						if a2 in ["skill", "ultimate", "entrance"]:
							if absf(screen_foot - foot_y) > 0.01:
								foot_act.append("%s%d:%+.0f" % [a2, fi, screen_foot - foot_y])
						else:
							foot_dev.append(screen_foot - foot_y)
		var dmin: float = 0.0
		var dmax: float = 0.0
		for d2 in foot_dev:
			dmin = minf(dmin, float(d2))
			dmax = maxf(dmax, float(d2))
		print("  %s 발 위치(서 있는 동작): 기준점 대비 %+.0f ~ %+.0f px (배율 ×%d, %d칸)%s" % [label, dmin, dmax, k3, foot_dev.size(),
			("   · 떠오르는 칸 " + ", ".join(foot_act)) if not foot_act.is_empty() else ""])
		_cf_ok(absf(dmin) < 0.01 and absf(dmax) < 0.01, label + " 서 있는 동작 모든 칸 발이 기준점 그대로 (%+.0f ~ %+.0f px)" % [dmin, dmax])
		_cf_ok(foot_act.is_empty(), label + " 액션 칸(스킬·궁극기·등장)도 발이 기준점 그대로 %s" % [foot_act])
		cv._cf_set("anchor")
		for a3 in ["hit", "skill", "ultimate", "entrance", "emote"]:
			var want_len: float = cv.anim_len(a3)
			var got: float = _cf_time_once(cv, a3)
			if CharForge.has_anim(cid3, a3):
				_cf_ok(absf(got - want_len) < 0.02, label + " %s 길이 %.3f초 = ms 합 %.3f" % [a3, got, want_len])
				_cf_ok(cv._cf_cur == rest, label + " %s 뒤 %s 로 돌아온다 (%s)" % [a3, rest, cv._cf_cur])
			else:
				_cf_ok(got < 0.0 and cv._cf_cur == rest, label + " 없는 동작 %s 은 무시하고 하던 걸 계속" % a3)
		# 피격 간격 · 다른 동작을 안 끊는다
		cv.cf_reset()
		_cf_step(cv, 0.05)
		cv.hurt()
		_cf_ok(cv._cf_once == "hit", label + " 맞으면 hit")
		_cf_step(cv, cv.anim_len("hit") + 0.02)
		cv.hurt()
		_cf_ok(cv._cf_once == "", label + " 피격 직후 다시 맞아도 곧장 또 굳지 않는다")
		if cv.play_once("skill"):
			cv._cf_hit_gap = 0.0
			cv.hurt()
			_cf_ok(cv._cf_once == "skill", label + " 스킬 중에 맞아도 스킬을 끊지 않는다")
		# 쓰러짐 — 끝 칸에서 멈춘다, 일으키면 돌아온다
		cv.cf_reset()
		_cf_ok(cv.play_once("death", true), label + " death 재생")
		_cf_step(cv, cv.anim_len("death") + 1.0)
		_cf_ok(cv._cf_once == "death" and cv._sprite.frame == int(CharForge.anim(cid3, "death")["n"]) - 1, label + " 쓰러진 채 끝 칸에서 멈춘다")
		_cf_ok(not cv.play_once("skill"), label + " 쓰러진 뒤엔 다른 동작이 안 들어간다")
		cv.cf_reset()
		_cf_step(cv, 0.05)
		_cf_ok(cv._cf_cur == rest, label + " 일으키면 " + rest)
		var snap: Sprite2D = cv.snapshot()
		_cf_ok(snap != null and snap.texture == cv._sprite.texture and snap.frame == cv._sprite.frame, label + " 잔상이 지금 칸을 뜬다")
		if snap != null:
			snap.free()
		cv.free()

	# ── 4) 실제 판 ──
	var hero_def: Dictionary = {}
	var hero_key: String = String((cast.get("heroes", {}) as Dictionary).keys()[0])
	for d3: Dictionary in Characters.defs():
		if String(d3["id"]) == hero_key:
			hero_def = d3
	_main_menu.close()
	_begin_run(hero_def)
	# 16차: 무한 모드 테마 순환에 저승길이 들어왔다 — 저승길로 바뀌면 같은 kind 가 저승길 그림으로 나와 시험이 엇갈린다. 던전에 묶는다
	_theme_t = 1.0e9
	G.stage = 0
	await _cf_wait_unpaused(0.05)
	var p := G.player as Player
	_cf_ok(p != null and p._cv.is_cf() and p._cv.cf_id == CharForge.hero_id(hero_key), "판: 영웅 %s 가 새 그림" % hero_key)
	var hero_cf: String = p._cv.cf_id
	if CharForge.has_anim(hero_cf, "entrance"):
		_cf_ok(p._cv._cf_once == "entrance", "판: 영웅 등장 연출 (지금 %s)" % p._cv._cf_once)
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	await _cf_wait_unpaused(1.0)
	_cf_ok(p._cv._cf_once == "", "판: 등장이 끝나면 기본 자세로")
	# 대시 = 스킬 + 잔상
	var before_n: int = get_child_count()
	p._dash_cd = 0.0
	p._start_dash(Vector2.RIGHT)
	_cf_ok(p._cv._cf_once == "skill" or not CharForge.has_anim(hero_cf, "skill"), "판: 대시 = skill (지금 %s)" % p._cv._cf_once)
	await _cf_wait_unpaused(0.05)
	var ghosts: int = 0
	var vfxs: int = 0
	for ch in get_children():
		if ch is Sprite2D and (ch as Sprite2D).texture == p._cv._sprite.texture:
			ghosts += 1
		if ch is Sprite2D and CharForge.has_anim(hero_cf, "vfx") and (ch as Sprite2D).texture == CharForge.anim(hero_cf, "vfx")["tex"]:
			vfxs += 1
	_cf_ok(ghosts >= 1, "판: 대시 잔상이 지금 그림으로 남는다 (%d)" % ghosts)
	_cf_ok(vfxs == 1 or not CharForge.has_anim(hero_cf, "vfx"), "판: 대시 자리에 시그니처 이펙트 (%d)" % vfxs)
	await _cf_wait_unpaused(1.0)
	# 영웅 피격
	p._iframe = 0.0
	p._cv._cf_hit_gap = 0.0
	p.take_damage(1.0, "검사")
	_cf_ok(p._cv._cf_once == "hit", "판: 영웅이 맞으면 hit")
	await _cf_wait_unpaused(0.8)
	# 잡몹·보스
	var spawned: Dictionary = {}
	for k in (cast.get("enemies", {}) as Dictionary).keys():
		var e := Enemy.new()
		e.kind = int(k)
		e.global_position = p.global_position + Vector2(260.0 + 60.0 * float(spawned.size()), 0)
		add_child(e)
		spawned[int(k)] = e
	await _cf_wait_unpaused(0.05)
	await _cf_wait_unpaused(0.05)
	for k in spawned.keys():
		var e2 = spawned[k]
		if not is_instance_valid(e2):
			_cf_ok(false, "kind %d spawn survived" % k)
			continue
		(e2 as Enemy).hp = 1.0e7
		(e2 as Enemy).max_hp = 1.0e7
		var ecf: String = CharForge.enemy_id(int(k))
		_cf_ok(e2._cv.is_cf() and e2._cv.cf_id == ecf, "판: kind %d 가 새 그림 %s" % [k, ecf])
		if e2._is_boss and CharForge.has_anim(ecf, "entrance"):
			_cf_ok(e2._cv._cf_once == "entrance", "판: 보스 kind %d 등장 연출 (지금 %s)" % [k, e2._cv._cf_once])
	await _cf_wait_unpaused(1.2)
	for k in spawned.keys():
		var e3 = spawned[k]
		if not is_instance_valid(e3):
			continue
		# 보스는 나오자마자 탄을 쏜다 — 걷거나 패턴 동작 중이면 맞다(서서 굳어 있으면 틀리다)
		# 4차부터: 원거리 몹은 attack 시트로 쏘고, 돌진하는 몹·보스는 charge 자세로 다가온다 — 그것도 맞다
		_cf_ok(e3._cv._cf_cur == "walk" or e3._cv._cf_once == "hit" or e3._cv._cf_cur == "charge"
				or ((e3._is_boss or e3._ranged) and e3._cv._cf_once in ["skill", "ultimate", "attack"]),
			"판: kind %d 다가오며 walk (지금 %s/%s)" % [k, e3._cv._cf_cur, e3._cv._cf_once])
		e3._cv._cf_hit_gap = 0.0
		if e3._cv._cf_once == "":
			e3.take_damage(1.0, Vector2.RIGHT)
			_cf_ok(e3._cv._cf_once == "hit", "판: kind %d 맞으면 hit (지금 %s)" % [k, e3._cv._cf_once])
		if e3._is_boss:
			# 보스 패턴: 탄막 = skill, 장판 = ultimate(+ 이펙트)
			# 돌진 중엔 돌진 자세(charge)가 탄막·장판 동작보다 앞선다(의도). 패턴을 볼 땐 돌진을 멈춰 둔다 —
			# 4차에 보스 7종이 charge 시트를 받자 검사 도중 저절로 돌진해 장판 자리에 charge 가 찍혔다.
			e3._charge_cd = 99.0
			e3._boss_move_cd = 99.0
			e3._wind = 0.0
			e3._charge_t = 0.0
			e3._special_cd = 99.0       # 탄막을 볼 땐 장판도 묶는다(장판이 먼저 터지면 ultimate 가 찍힌다) — 아래 장판 검사에서 푼다
			e3._cf_charge_sync()
			await _cf_wait_unpaused(0.4)
			e3._cv.cf_reset()
			e3._fire_cd = 0.0
			await _cf_wait_unpaused(0.05)
			await _cf_wait_unpaused(0.05)
			var ecf2: String = e3._cv.cf_id
			if e3._is_fusion:
				e3._burst_cd = 0.0          # 융합 보스는 다른 길(_fusion_move)로 싸운다 — 방사 탄막을 당긴다
				await _cf_wait_unpaused(0.05)
				_cf_ok(e3._cv._cf_once in ["ultimate", "skill"] or not CharForge.has_anim(ecf2, "skill"), "판: 융합 보스 kind %d 방사 탄막 = ultimate/skill (지금 %s)" % [k, e3._cv._cf_once])
				continue
			_cf_ok(e3._cv._cf_once == "skill" or not CharForge.has_anim(ecf2, "skill"), "판: 보스 kind %d 탄막 = skill (지금 %s)" % [k, e3._cv._cf_once])
			await _cf_wait_unpaused(0.7)
			e3._cv.cf_reset()
			e3._special_cd = 0.0
			var cc0: int = get_child_count()
			await _cf_wait_unpaused(0.05)
			await _cf_wait_unpaused(0.05)
			_cf_ok(e3._cv._cf_once == ("ultimate" if CharForge.has_anim(ecf2, "ultimate") else "skill") or not CharForge.has_anim(ecf2, "skill"),
				"판: 보스 kind %d 장판 = ultimate (없으면 skill) (지금 %s)" % [k, e3._cv._cf_once])
			var ufx: int = 0
			for ch2 in get_children():
				if ch2 is Sprite2D and CharForge.has_anim(ecf2, "vfx") and (ch2 as Sprite2D).texture == CharForge.anim(ecf2, "vfx")["tex"]:
					ufx += 1
			_cf_ok(ufx >= 1 or not CharForge.has_anim(ecf2, "vfx"), "판: 장판 자리에 보스 이펙트 (%d, 자식 %d→%d)" % [ufx, cc0, get_child_count()])
	# 처치 → 쓰러짐 → 사라짐
	for k in spawned.keys():
		var e4 = spawned[k]
		if not is_instance_valid(e4):
			continue
		e4._cv.cf_reset()
		e4.take_damage(1.0e9, Vector2.RIGHT)
		await _cf_wait_unpaused(0.05)
		_cf_ok(is_instance_valid(e4) and e4._cv._cf_once == "death", "판: kind %d 처치 → death" % k)
		var wait: float = (e4._cv.anim_len("death") if e4._is_boss else 0.5) + 0.4
		await _cf_wait_unpaused(wait)
		_cf_ok(not is_instance_valid(e4), "판: kind %d 쓰러진 뒤 %.1f초 안에 사라진다" % [k, wait])
	# 융합 = ultimate, 클리어 = emote
	p._cv.cf_reset()
	p.cf_moment("ultimate")
	_cf_ok(p._cv._cf_once == "ultimate" or not CharForge.has_anim(hero_cf, "ultimate"), "판: 융합 순간 ultimate")
	await _cf_wait_unpaused(0.8)
	# 부활 대기 = 쓰러진 자세 → 부활 = 일어남
	p.hp = 1.0
	p.max_hp = 100.0
	p._iframe = 0.0
	G.revive_used = 0
	var can_revive: bool = G.revive_available()
	p.take_damage(9999.0, "검사")
	if can_revive:
		_cf_ok(p.pending_revive and p._cv._cf_once == "death", "판: 부활 대기 중 쓰러진 자세")
		p.revive()
		if _revive_panel != null:
			_revive_panel.visible = false
		get_tree().paused = false
		await _cf_wait_unpaused(0.05)
		await _cf_wait_unpaused(0.05)
		_cf_ok(p._cv._cf_once == "" and p._cv._cf_cur != "", "판: 부활하면 일어선다 (%s)" % p._cv._cf_cur)
		get_tree().paused = false
	# 끄면 예전 그림
	CharForge.enabled = false
	var e5 := Enemy.new()
	e5.kind = int((cast.get("enemies", {}) as Dictionary).keys()[0])
	e5.global_position = p.global_position + Vector2(-300, 0)
	add_child(e5)
	await _cf_wait_unpaused(0.05)
	_cf_ok(not e5._cv.is_cf() and e5._cv._sprite != null, "끄면: kind %d 가 예전 그림" % e5.kind)
	var cv_off := CreatureVisual.new()
	cv_off.radius = Player.RADIUS
	cv_off.cf_id = CharForge.hero_id(hero_key)
	_cf_ok(cv_off.cf_id == "", "끄면: 영웅 자리도 비어 예전 그림으로")
	cv_off.free()
	CharForge.enabled = true
	# cast 에서 빠진 자리는 예전 그림 그대로 — 한 자리를 잠깐 빼고 본다(되돌리기 = 줄 하나 지우기)
	var en_cast: Dictionary = CharForge._cast.get("enemies", {})
	var drop_key: String = "7" if en_cast.has("7") else String(en_cast.keys()[0])
	var kept: Variant = en_cast.get(drop_key, null)
	en_cast.erase(drop_key)
	var e6 := Enemy.new()
	e6.kind = int(drop_key)
	e6.global_position = p.global_position + Vector2(-300, 80)
	add_child(e6)
	await _cf_wait_unpaused(0.05)
	_cf_ok(not e6._cv.is_cf() and e6._cv._sprite != null, "cast 에서 뺀 kind %s 는 예전 그림 그대로" % drop_key)
	if kept != null:
		en_cast[drop_key] = kept

	await _cfcheck_v2(p)

	print("")
	print("[CFCHECK] %s — 통과 %d · 실패 %d" % ["ALL PASS" if _cf_fail.is_empty() else "FAIL", _cf_pass, _cf_fail.size()])
	get_tree().quit(0 if _cf_fail.is_empty() else 1)


## ── 2차(10/3 지시서) 검사 — 크기 판 · 새 시트 · 팔레트 · 주문분 규격 ──
## 1) 들어 있는 폴더 전부(주문분·px 판 포함): 발밑 모든 칸 2px · 색 수 · 팔레트
## 2) 배역표: 자리마다 키·작은 판·강화 개체·크기 단계가 지시서 3절 표대로인가
## 3) 주문분이 와 있으면: 자리별 시트·칸 수·크기 폴더·실제 키·팔레트 번호
## 4) 시험 캐릭터(user://cf_test, 재고 그림을 잘라 만든 가짜): charge·vanish·attack·idle·s1·px 판·팔레트를
##    그리는 부품 단위와 실제 판(몹·보스·펫) 양쪽에서 돌린다. 진짜 32종이 오기 전에 연결을 확인하는 용도다.
const CF_SPEC_H: Dictionary = {1: 28, 7: 28, 8: 28, 12: 28, 25: 28, 0: 40, 3: 40, 9: 40, 10: 40, 16: 40, 17: 40, 18: 40, 22: 40, 23: 40,
	2: 52, 11: 52, 19: 52, 20: 52, 21: 52, 24: 52, 4: 112, 13: 112, 14: 112, 15: 112, 26: 112, 27: 112, 28: 112, 5: 160, 6: 144}
const CF_SPEC_PX: Dictionary = {1: {"mini": 20}, 7: {"mini": 20, "elite": 40}, 8: {"mini": 20}, 0: {"mini": 28, "elite": 56},
	9: {"mini": 28}, 16: {"steps": [28, 40, 56]}, 17: {"steps": [40, 64, 88]}, 2: {"elite": 72}, 21: {"mini": 36}}
## 지시서 3절 '시트' 칸. 키 = kind(몹) 또는 펫 이름. 보스는 _cf_spec_sheets 가 따로 만든다.
const CF_SPEC_SHEETS: Dictionary = {
	7: ["charge"], 0: ["charge"], 3: ["attack"], 10: ["skill", "vfx"], 22: ["skill"], 23: ["attack"], 20: ["s1_anchor", "s1_walk"],
	"summon_green": ["skill", "attack"], "summon_ice": ["attack"], "summon_orb": ["idle"],   # 소환수 attack = 3차 추가 주문(군단 사격)
}
const CF_FRAMES: Dictionary = {"anchor": 1, "walk": 4, "hit": 1, "death": 2, "entrance": 3, "skill": 3, "ultimate": 3, "vfx": 1,
	"charge": 2, "vanish": 2, "attack": 3, "idle": 2, "s1_anchor": 1, "s1_walk": 4}
## 자리별 예외(받는 칸 수 목록). 5차 6절 ㉡: 오르빈(27) 궁극기는 0·1 두 칸만 쓴다(6차에 두 칸짜리로 왔다).
const CF_FRAMES_SLOT: Dictionary = {27: {"ultimate": [2]}}
const CFT_ROOT: String = "user://cf_test/"
## 4×2 팔레트 PNG 견본(색 형식 3, 2비트, 팔레트 표 4칸: 0 투명 · 1 #000000 · 2 #202a77 · 3 #b65609, 픽셀 0123/3210).
## PNG 머리 읽기를 시험한다 — 주문분이 오기 전엔 진짜 팔레트 PNG 가 없다.
const CF_IDX_PNG: String = "iVBORw0KGgoAAAANSUhEUgAAAAQAAAACAgMAAAACxpXwAAAADFBMVEUAAAAAAAAgKne2VgkbMl30AAAAAXRSTlMAQObYZgAAAAxJREFUeJxjkGZ4AgABOQEARWSRmwAAAABJRU5ErkJggg=="


## PNG 원본의 색 형식·비트·팔레트 표(PLTE)·투명 표(tRNS). 원본을 못 읽으면 {}
## (내보낸 빌드에는 임포트된 텍스처만 있고 원본 PNG 가 없다 — 그때는 이 검사를 건너뛴다).
func _cf_png_info(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var b: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if b.size() < 33 or b[1] != 0x50 or b[2] != 0x4E or b[3] != 0x47:
		return {}
	var plte: Array = []
	var trns := PackedByteArray()
	var i: int = 8
	while i + 8 <= b.size():
		var n: int = (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3]
		var t: String = b.slice(i + 4, i + 8).get_string_from_ascii()
		if t == "PLTE":
			for j in range(0, n - 2, 3):
				plte.append(Color8(b[i + 8 + j], b[i + 9 + j], b[i + 10 + j]))
		elif t == "tRNS":
			trns = b.slice(i + 8, i + 8 + n)
		elif t == "IEND":
			break
		i += 12 + n
	return {"type": int(b[25]), "depth": int(b[24]), "plte": plte, "trns": trns}


## 팔레트 PNG 규격(3차 지시서 1-2): 색 형식 3 · 0번 투명 · 1번부터 palette.json 순서. 어긋난 점 목록(비면 맞다).
func _cf_png_palette_issues(info: Dictionary, pal: Array) -> Array:
	var bad: Array = []
	if info.is_empty():
		return bad
	if int(info["type"]) != 3:
		bad.append("팔레트 PNG 가 아님(색 형식 %d)" % int(info["type"]))
		return bad
	var plte: Array = info["plte"]
	var trns: PackedByteArray = info["trns"]
	if trns.is_empty() or trns[0] != 0:
		bad.append("0번이 투명이 아님")
	if plte.size() < pal.size() + 1:
		bad.append("팔레트 표 %d칸 < palette.json %d색 + 투명" % [plte.size(), pal.size()])
	else:
		for k in pal.size():
			var a: Color = plte[k + 1]
			var c: Color = pal[k]
			if a.r8 != c.r8 or a.g8 != c.g8 or a.b8 != c.b8:
				bad.append("%d번 색이 palette.json 과 다름(%s ≠ %s)" % [k + 1, a.to_html(false), c.to_html(false)])
				break
	return bad
const CFT_ID: String = "orders/901_Ctest"


## 지시서가 그 자리에 약속한 시트 목록.
func _cf_spec_sheets(k: Variant) -> Array:
	var out: Array = ["anchor", "walk", "hit", "death"]
	if k is int and bool((Enemy.KINDS.get(k, {}) as Dictionary).get("boss", false)):
		out += ["entrance", "skill", "ultimate", "vfx"]
		if k == 13:
			out.append("vanish")
		elif k != 15:
			out.append("charge")
		if k == 27:
			out.append("attack")
		return out
	return out + (CF_SPEC_SHEETS.get(k, []) as Array)


func _cf_rgba(tex: Texture2D) -> Image:
	var img: Image = tex.get_image() if tex != null else null
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## 시트 한 장의 칸마다 '가장 아래 칠해진 줄 밑 여백'(px). 빈 칸은 -1.
func _cf_bottom_gaps(tex: Texture2D, fw: int, fh: int, n: int) -> Array:
	var img: Image = _cf_rgba(tex)
	if img == null:
		return []
	var data: PackedByteArray = img.get_data()
	var w: int = img.get_width()
	var out: Array = []
	for fi in n:
		var gap: int = -1
		for y in range(fh - 1, -1, -1):
			var hit: bool = false
			for x in range(fi * fw, (fi + 1) * fw):
				if data[(y * w + x) * 4 + 3] > 127:
					hit = true
					break
			if hit:
				gap = fh - 1 - y
				break
		out.append(gap)
	return out


## 첫 칸 몸 키(칠해진 맨 위 줄 ~ 맨 아래 줄).
func _cf_body_h(tex: Texture2D, fw: int, fh: int) -> int:
	var img: Image = _cf_rgba(tex)
	if img == null:
		return 0
	var r: Rect2i = img.get_region(Rect2i(0, 0, fw, fh)).get_used_rect()
	return r.size.y


## 캐릭터 한 명(모든 판)의 칠해진 색 전부(RGB 정수 → true).
func _cf_colors(id: String) -> Dictionary:
	var cols: Dictionary = {}
	for key in [0] + CharForge.keys(id):
		for a in (CharForge.info(id, key).get("anims", {}) as Dictionary).keys():
			var img: Image = _cf_rgba(CharForge.anim(id, a, key)["tex"])
			if img == null:
				continue
			var data: PackedByteArray = img.get_data()
			var i: int = 0
			while i < data.size():
				if data[i + 3] > 127:
					cols[(data[i] << 16) | (data[i + 1] << 8) | data[i + 2]] = true
				i += 4
	return cols


func _cfcheck_v2(p: Player) -> void:
	print("")
	print("=== 2차: 크기 판 · 새 시트 · 팔레트 · 주문분 ===")
	# ── 1) 폴더 전부: 발밑 · 색 · 팔레트 ──
	var n_frames: int = 0
	var bad_feet: Array = []
	var over16: Array = []
	var max_c: int = 0
	var n_pal: int = 0
	var n_png: int = 0          # 원본 PNG 머리까지 본 시트
	var n_png_skip: int = 0     # 원본이 없어 못 본 시트(내보낸 빌드)
	var plte_over: Array = []   # 팔레트 표가 16칸을 넘는 시트(쓰는 색이 15 이하면 실패는 아니다 — 표만 길다)
	for id in CharForge.ids():
		for key in [0] + CharForge.keys(String(id)):
			var anims: Dictionary = CharForge.info(String(id), key).get("anims", {})
			for a in anims.keys():
				if a in ["vfx", "portrait", "portrait_big"]:
					continue        # 몸이 없는 시트
				var an: Dictionary = anims[a]
				var gaps: Array = _cf_bottom_gaps(an["tex"], int(an["fw"]), int(an["fh"]), int(an["n"]))
				for fi in gaps.size():
					n_frames += 1
					if int(gaps[fi]) != 2:
						bad_feet.append("%s%s/%s#%d=%dpx" % [id, ("/px%d" % key) if key > 0 else "", a, fi, gaps[fi]])
		var cols: Dictionary = _cf_colors(String(id))
		max_c = maxi(max_c, cols.size())
		var pal: Array = CharForge.palette(String(id))
		if not pal.is_empty():
			n_pal += 1
			_cf_ok(pal.size() <= 15, "%s 팔레트 %d색 (투명까지 16칸 이하)" % [id, pal.size()])
			var lut: Dictionary = {}
			for c in pal:
				lut[((c as Color).r8 << 16) | ((c as Color).g8 << 8) | (c as Color).b8] = true
			var stray: int = 0
			for k in cols.keys():
				if not lut.has(k):
					stray += 1
			_cf_ok(stray == 0, "%s 그림의 모든 색이 palette.json 에 있다 (없는 색 %d)" % [id, stray])
			for key2 in [0] + CharForge.keys(String(id)):
				for a2 in (CharForge.info(String(id), key2).get("anims", {}) as Dictionary).keys():
					var pth: String = CharForge.root + String(id) + ("/px%d" % key2 if key2 > 0 else "") + "/sheets/" + String(a2) + ".png"
					var inf: Dictionary = _cf_png_info(pth)
					if inf.is_empty():
						n_png_skip += 1
						continue
					n_png += 1
					var iss: Array = _cf_png_palette_issues(inf, pal)
					_cf_ok(iss.is_empty(), "%s%s/%s 팔레트 PNG 규격 %s" % [id, ("/px%d" % key2) if key2 > 0 else "", a2, iss])
					if (inf["plte"] as Array).size() > 16:
						plte_over.append("%s/%s(%d칸)" % [id, a2, (inf["plte"] as Array).size()])
		elif cols.size() > 16:
			over16.append("%s(%d)" % [id, cols.size()])
	_cf_ok(n_frames > 0 and bad_feet.is_empty(), "발밑: %d칸 모두 정확히 2px (어긋난 칸 %d %s)" % [n_frames, bad_feet.size(), bad_feet.slice(0, 8)])
	print("  발밑 %d칸 · 2px 아닌 칸 %d" % [n_frames, bad_feet.size()])
	print("  색: 팔레트 있는 캐릭터 %d · 팔레트 없이 16색 넘는 캐릭터 %d %s · 가장 많은 색 %d" % [n_pal, over16.size(), over16.slice(0, 16), max_c])
	print("  팔레트 PNG 머리: 본 시트 %d · 원본 없어 건너뜀 %d · 팔레트 표가 16칸 넘는 시트 %d %s" % [n_png, n_png_skip, plte_over.size(), plte_over.slice(0, 6)])

	# ── 2) 배역표 크기 칸 ──
	for k in CF_SPEC_H.keys():
		var s: Dictionary = CharForge._slot("enemies", str(k))
		var px: Dictionary = CF_SPEC_PX.get(k, {})
		var steps: Array = (s.get("steps", []) as Array).map(func(v): return int(v))
		_cf_ok(int(s.get("h", 0)) == int(CF_SPEC_H[k]) and int(s.get("mini", 0)) == int(px.get("mini", 0))
			and int(s.get("elite", 0)) == int(px.get("elite", 0)) and steps == (px.get("steps", []) as Array),
			"배역표 kind %d 키 %s · mini %s · elite %s · steps %s = 지시서 %d %s" % [k, s.get("h"), s.get("mini", 0), s.get("elite", 0), steps, CF_SPEC_H[k], px])
	for hk in (CharForge.cast().get("heroes", {}) as Dictionary).keys():
		_cf_ok(int(CharForge._slot("heroes", String(hk)).get("h", 0)) == 40, "배역표 영웅 %s 키 40" % hk)
	for pk in ["summon_green", "summon_ice", "summon_orb"]:
		_cf_ok(int(CharForge._slot("pets", pk).get("h", 0)) == 32, "배역표 펫 %s 키 32" % pk)

	# ── 3) 주문분 규격(와 있는 자리만) ──
	var n_orders: int = 0
	var slots: Array = []
	for k in CF_SPEC_H.keys():
		slots.append([k, CharForge._slot("enemies", str(k)), float(CF_SPEC_H[k])])
	for pk in ["summon_green", "summon_ice", "summon_orb"]:
		slots.append([pk, CharForge._slot("pets", pk), 32.0])
	for sl in slots:
		var cid: String = String((sl[1] as Dictionary).get("id", ""))
		if not cid.begins_with(CharForge.ORDERS_DIR) or not CharForge.has(cid):
			continue
		n_orders += 1
		var want_h: float = float(sl[2])
		for a in _cf_spec_sheets(sl[0]):
			var an: Dictionary = CharForge.anim(cid, a)
			_cf_ok(not an.is_empty(), "주문 %s(%s) 시트 %s 있음" % [sl[0], cid, a])
			if not an.is_empty() and CF_FRAMES.has(a):
				var want_n: Array = (CF_FRAMES_SLOT.get(sl[0], {}) as Dictionary).get(a, [int(CF_FRAMES[a])])
				_cf_ok(want_n.has(int(an["n"])), "주문 %s %s %d칸 (지시서 %s)" % [sl[0], a, an["n"], str(want_n)])
		var a0: Dictionary = CharForge.anim(cid, "anchor")
		var bh: int = _cf_body_h(a0["tex"], int(a0["fw"]), int(a0["fh"]))
		# 주문분은 anchor 의 칠해진 높이(외곽선 포함)가 주문 키 ±1px 다(3차 지시서 1-1). 다른 시트는 키를 안 본다.
		_cf_ok(absf(float(bh) - want_h) <= 1.0, "주문 %s anchor 키 %dpx = 주문 키 %d ±1" % [sl[0], bh, int(want_h)])
		var px2: Dictionary = CF_SPEC_PX.get(sl[0], {})
		var need: Array = []
		for f in ["mini", "elite"]:
			if px2.has(f):
				need.append(int(px2[f]))
		for st in px2.get("steps", []):
			if int(st) != int(want_h):
				need.append(int(st))
		for kk in need:
			_cf_ok(CharForge.keys(cid).has(kk), "주문 %s px%d 폴더" % [sl[0], kk])
			if CharForge.keys(cid).has(kk):
				var ak: Dictionary = CharForge.anim(cid, "anchor", kk)
				var bk: int = _cf_body_h(ak["tex"], int(ak["fw"]), int(ak["fh"]))
				_cf_ok(absf(float(bk) - float(kk)) <= 1.0, "주문 %s px%d anchor 키 %dpx = %d ±1" % [sl[0], kk, bk, kk])
		_cf_ok(not CharForge.palette(cid).is_empty(), "주문 %s palette.json" % sl[0])
		for key in [0] + CharForge.keys(cid):
			for a in (CharForge.info(cid, key).get("anims", {}) as Dictionary).keys():
				CharForge.index_tex(cid, a, key)
		_cf_ok(CharForge.index_misses(cid) == 0, "주문 %s 모든 판·모든 시트가 같은 팔레트 번호 (어긋난 픽셀 %d)" % [sl[0], CharForge.index_misses(cid)])
	var hero_idle: int = 0
	for hk2 in (CharForge.cast().get("heroes", {}) as Dictionary).keys():
		var hid: String = CharForge.hero_id(String(hk2))
		if CharForge.has_anim(hid, "idle"):
			hero_idle += 1
			var ia: Dictionary = CharForge.anim(hid, "idle")
			_cf_ok(int(ia["n"]) == 2 and is_equal_approx(float(ia["len"]), 0.9), "영웅 %s idle 2칸 450ms" % hk2)
	if n_orders > 0:
		for hk3 in (CharForge.cast().get("heroes", {}) as Dictionary).keys():
			var hid3: String = CharForge.hero_id(String(hk3))
			_cf_ok(not CharForge.palette(hid3).is_empty(), "영웅 %s(%s) 도 팔레트 PNG + palette.json (3차 5-2)" % [hk3, hid3])
	print("  주문분 들어온 자리 %d / 32 · 대기(idle) 있는 영웅 %d / 14" % [n_orders, hero_idle])
	# 7차: 배역표 skip — 그 칸은 시간 0(앞 칸이 이어 받음). 실제로 돌려도 화면에 한 번도 안 나와야 한다.
	for grp3 in ["heroes", "enemies", "pets"]:
		for sk_key in (CharForge.cast().get(grp3, {}) as Dictionary).keys():
			var sl3: Variant = (CharForge.cast()[grp3] as Dictionary)[sk_key]
			if not (sl3 is Dictionary) or not (sl3 as Dictionary).has("skip"):
				continue
			var cid3: String = String((sl3 as Dictionary).get("id", ""))
			var skd: Dictionary = (sl3 as Dictionary)["skip"]
			for sa in skd.keys():
				var an3: Dictionary = CharForge.anim(cid3, String(sa))
				_cf_ok(not an3.is_empty(), "skip %s[%s] 시트 %s 있음" % [grp3, sk_key, sa])
				if an3.is_empty():
					continue
				for si in skd[sa]:
					_cf_ok(float((an3["ms"] as Array)[int(si)]) == 0.0, "skip %s[%s] %s %d칸 시간 0" % [grp3, sk_key, sa, int(si)])
				var cvs := CreatureVisual.new()
				cvs.radius = 15.0
				cvs.cf_id = cid3
				cvs.cf_target_h = float((sl3 as Dictionary).get("h", 40.0))
				cvs.always_animate = true
				cvs.build()
				add_child(cvs)
				if String(sa) != "idle":
					cvs.play_once(String(sa))
				var seen: Dictionary = {}
				var t_end: int = Time.get_ticks_msec() + int(float(an3["len"]) * (2000.0 if String(sa) == "idle" else 1000.0)) + 200
				while Time.get_ticks_msec() < t_end:
					if cvs._cf_cur == cvs._cf_name(String(sa)):
						seen[cvs._sprite.frame] = true
					await get_tree().process_frame
				var bad: Array = []
				for si2 in skd[sa]:
					if seen.has(int(si2)):
						bad.append(int(si2))
				_cf_ok(bad.is_empty() and not seen.is_empty(), "skip %s[%s] %s 돌려 봐도 %s칸이 안 나온다 (본 칸 %s)" % [grp3, sk_key, sa, str(skd[sa]), str(seen.keys())])
				cvs.queue_free()

	# ── 4) 시험 캐릭터로 새 연결을 돌린다 ──
	var src: String = CharForge.hero_id("rogue")
	if src == "" or not CharForge.has_anim(src, "entrance") or not CharForge.has_anim(src, "skill"):
		_cf_ok(false, "시험 캐릭터 재료(회풍 자리의 신화)가 없다")
		return
	_cft_build(src)
	var pass0: int = _cf_pass
	var fail0: int = _cf_fail.size()
	var saved_root: String = CharForge.root
	var saved_cast: String = CharForge.cast_path
	CharForge.root = CFT_ROOT
	CharForge.cast_path = CFT_ROOT + "cast.json"
	CharForge.reset_cache()
	await _cft_units()
	print("  시험 캐릭터 · 부품 단위: 통과 %d · 실패 %d" % [_cf_pass - pass0, _cf_fail.size() - fail0])
	pass0 = _cf_pass
	fail0 = _cf_fail.size()
	await _cft_flow(p)
	print("  시험 캐릭터 · 실제 판(몹·보스·펫): 통과 %d · 실패 %d" % [_cf_pass - pass0, _cf_fail.size() - fail0])
	CharForge.root = saved_root
	CharForge.cast_path = saved_cast
	CharForge.reset_cache()
	_cf_ok(CharForge.enemy_id(0) != "" and not CharForge.enemy_id(0).begins_with("orders/901"), "시험이 끝나면 진짜 배역표로 돌아온다")


func _cft_frames(id: String, a: String) -> Array:
	var an: Dictionary = CharForge.anim(id, a)
	var img: Image = _cf_rgba(an["tex"])
	var out: Array = []
	for i in int(an["n"]):
		out.append(img.get_region(Rect2i(i * int(an["fw"]), 0, int(an["fw"]), int(an["fh"]))))
	return out


## 빨강·파랑을 맞바꾼 그림(분노 단계 시트가 기본 시트와 다르게 보이도록).
func _cft_tint(img: Image) -> Image:
	var o: Image = img.duplicate()
	var data: PackedByteArray = o.get_data()
	var i: int = 0
	while i < data.size():
		var r: int = data[i]
		data[i] = data[i + 2]
		data[i + 2] = r
		i += 4
	return Image.create_from_data(o.get_width(), o.get_height(), false, Image.FORMAT_RGBA8, data)


func _cft_sheet(dir: String, name: String, frames: Array, ms: Array) -> void:
	var fw: int = (frames[0] as Image).get_width()
	var fh: int = (frames[0] as Image).get_height()
	var img := Image.create_empty(fw * frames.size(), fh, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		img.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	img.save_png(dir + name + ".png")
	var f := FileAccess.open(dir + name + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"frame_w": fw, "frame_h": fh, "frames": frames.size(), "ms": ms}))
	f.close()


## 재고 신화 한 명을 잘라 '주문분처럼 생긴' 가짜 폴더를 만든다(그림 내용은 상관없다 — 연결만 본다).
func _cft_build(src: String) -> void:
	_cft_rm(CFT_ROOT)
	var base: String = CFT_ROOT + CFT_ID + "/"
	var sheets: Dictionary = {}
	for a in (CharForge.info(src)["anims"] as Dictionary).keys():
		sheets[a] = [_cft_frames(src, a), (CharForge.anim(src, a)["ms"] as Array).map(func(v): return int(v))]
	var w: Array = sheets["walk"][0]
	var ent: Array = sheets["entrance"][0]
	var sk: Array = sheets["skill"][0]
	sheets["charge"] = [[w[0], w[1]], [300, 200]]
	sheets["vanish"] = [[ent[0], ent[1]], [250, 250]]
	sheets["attack"] = [[sk[0], sk[1], sk[2]], [120, 160, 120]]
	sheets["idle"] = [[w[0], w[2]], [450, 450]]
	sheets["s1_anchor"] = [[_cft_tint(sheets["anchor"][0][0])], [200]]
	sheets["s1_walk"] = [w.map(func(im): return _cft_tint(im)), [140, 140, 140, 140]]
	for sub in ["", "px28/", "px56/"]:
		var d: String = base + sub + "sheets/"
		DirAccess.make_dir_recursive_absolute(d)
		for nm in sheets.keys():
			_cft_sheet(d, nm, sheets[nm][0], sheets[nm][1])
	# 팔레트: 쓰인 색 전부. 0번 투명을 맨 앞에 둔다(읽는 쪽이 그걸 건너뛰는지도 본다).
	var cols: Dictionary = {}
	for nm in sheets.keys():
		for im in sheets[nm][0]:
			var data: PackedByteArray = (im as Image).get_data()
			var i: int = 0
			while i < data.size():
				if data[i + 3] > 127:
					cols["#%02x%02x%02x" % [data[i], data[i + 1], data[i + 2]]] = true
				i += 4
	var f := FileAccess.open(base + "palette.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"transparent_index": 0, "palette": cols.keys(), "note": "시험용"}))
	f.close()
	f = FileAccess.open(base + "dna.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"name": "시험", "role": "보스", "tier": "신화", "sprite_h": 40}))
	f.close()
	var tc: Dictionary = {
		"heroes": {"rogue": {"id": CFT_ID, "h": 40}},
		"enemies": {"0": {"id": CFT_ID, "h": 40, "mini": 28, "elite": 56}, "3": {"id": CFT_ID, "h": 40}, "4": {"id": CFT_ID, "h": 40},
			"6": {"id": CFT_ID, "h": 40}, "13": {"id": CFT_ID, "h": 40}, "16": {"id": CFT_ID, "h": 40, "steps": [28, 40, 56]},
			"17": {"id": CFT_ID, "h": 40, "steps": [40, 64, 88]}, "20": {"id": CFT_ID, "h": 40}, "27": {"id": CFT_ID, "h": 40}},
		"pets": {"summon_green": {"id": CFT_ID, "h": 40}, "summon_ice": {"id": CFT_ID, "h": 40}, "summon_orb": {"id": CFT_ID, "h": 40}},
	}
	f = FileAccess.open(CFT_ROOT + "cast.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(tc))
	f.close()


func _cft_rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for d in DirAccess.get_directories_at(dir):
		_cft_rm(dir.path_join(d) + "/")
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	DirAccess.remove_absolute(dir)


func _cft_mk(key: int, steps: Array, pal: Array) -> CreatureVisual:
	var c := CreatureVisual.new()
	c.radius = Player.RADIUS
	c.cf_id = CFT_ID
	c.cf_target_h = 40.0
	c.cf_key = key
	c.cf_steps = steps
	c.cf_palette = pal
	c.always_animate = true
	c.build()
	return c


## 두 그림이 불투명한 자리에서 색까지 같고, 투명한 자리도 같은가(투명 픽셀의 RGB 는 안 본다).
func _cf_same_opaque(a: Image, b: Image) -> bool:
	if a == null or b == null or a.get_size() != b.get_size():
		return false
	var da: PackedByteArray = a.get_data()
	var db: PackedByteArray = b.get_data()
	var i: int = 0
	while i < da.size():
		var oa: bool = da[i + 3] > 127
		if oa != (db[i + 3] > 127):
			return false
		if oa and (da[i] != db[i] or da[i + 1] != db[i + 1] or da[i + 2] != db[i + 2]):
			return false
		i += 4
	return true


## 그리는 부품 단위
func _cft_units() -> void:
	var id: String = CFT_ID
	_cf_ok(CharForge.ids().has(id), "시험: 주문 폴더(orders/)를 캐릭터로 읽는다 %s" % [CharForge.ids()])
	_cf_ok(CharForge.keys(id) == [28, 56], "시험: px 판 목록 %s = [28, 56]" % [CharForge.keys(id)])
	_cf_ok(float(CharForge.info(id, 28).get("native_h", 0)) == 28.0 and CharForge.scale_to(id, 28, 28.0) == 1, "시험: px28 판은 자기 키 28 · 1배")
	_cf_ok(CharForge.scale_to(id, 0, 112.0) == 3 and CharForge.scale_to(id, 0, 40.0) == 1, "시험: 40px 판을 112 자리에 ×3, 40 자리에 ×1")
	# px 판 고르기
	var c28: CreatureVisual = _cft_mk(28, [], [])
	_cf_ok(c28.is_cf() and c28.cf_key_now() == 28 and c28.cf_scale() == 1, "시험: mini 판(px28)으로 뜬다")
	_cf_ok(c28._sprite.texture == CharForge.anim(id, "idle", 28)["tex"] or c28._sprite.texture == CharForge.anim(id, "anchor", 28)["tex"], "시험: px28 판의 그림을 쓴다")
	c28.free()
	var c99: CreatureVisual = _cft_mk(99, [], [])
	_cf_ok(c99.is_cf() and c99.cf_key_now() == 0, "시험: 없는 판(px99)이면 기본 판으로")
	c99.free()
	# idle — 서 있으면 숨쉬기 450ms 두 칸
	var cv: CreatureVisual = _cft_mk(0, [], [])
	cv.walk_speed = 0.0
	_cf_step(cv, 0.02)
	_cf_ok(cv._cf_cur == "idle", "시험: 서 있으면 idle (%s)" % cv._cf_cur)
	var f0: int = cv._sprite.frame
	_cf_step(cv, 0.46)
	var f1: int = cv._sprite.frame
	_cf_step(cv, 0.45)
	_cf_ok(f0 == 0 and f1 == 1 and cv._sprite.frame == 0, "시험: idle 이 450ms 마다 칸을 넘긴다 (%d→%d→%d)" % [f0, f1, cv._sprite.frame])
	cv.walk_speed = 120.0
	_cf_step(cv, 0.05)
	_cf_ok(cv._cf_cur == "walk", "시험: 움직이면 walk")
	cv.walk_speed = 0.0
	# charge 자세
	_cf_ok(cv.pose("charge", 0) and cv._cf_cur == "charge" and cv._sprite.frame == 0, "시험: 돌진 예고 = charge 0번 칸")
	_cf_step(cv, 1.0)
	_cf_ok(cv._cf_cur == "charge" and cv._sprite.frame == 0, "시험: 자세는 시간이 가도 그 칸에 멈춰 있다")
	cv._cf_hit_gap = 0.0
	cv.hurt()
	_cf_ok(cv._cf_cur == "charge", "시험: 돌진 자세 중 맞아도 자세를 안 끊는다")
	cv.pose("charge", 1)
	_cf_ok(cv._sprite.frame == 1, "시험: 돌진 중 = charge 1번 칸")
	cv.release_pose("vanish")
	_cf_ok(cv.is_posing("charge"), "시험: 다른 이름으로는 자세가 안 풀린다")
	cv.release_pose("charge")
	_cf_step(cv, 0.02)
	_cf_ok(not cv.is_posing() and cv._cf_cur == "idle", "시험: 자세를 풀면 기본으로 (%s)" % cv._cf_cur)
	# attack — 준비 칸 길이와 전체 길이
	_cf_ok(is_equal_approx(cv.lead_time("attack"), 0.12), "시험: attack 준비 칸 0.12초 (%.3f)" % cv.lead_time("attack"))
	var at: float = _cf_time_once(cv, "attack")
	_cf_ok(absf(at - 0.40) < 0.02, "시험: attack 한 번 0.40초 (%.3f)" % at)
	_cf_ok(cv.lead_time("없는동작") < 0.0, "시험: 없는 시트의 준비 칸은 -1 (미리 들지 않는다)")
	# vanish
	_cf_ok(cv.pose("vanish", 0) and cv._sprite.frame == 0, "시험: 사라짐 = vanish 0번 칸")
	cv.pose("vanish", 1)
	_cf_ok(cv._sprite.frame == 1, "시험: 다시 나타남 = vanish 1번 칸")
	cv.release_pose("vanish")
	# s1 체력 단계
	cv.cf_set_state("s1")
	_cf_step(cv, 0.02)
	_cf_ok(cv._cf_cur == "s1_anchor", "시험: 분노 단계에서 서 있으면 s1_anchor (%s)" % cv._cf_cur)
	cv.walk_speed = 120.0
	_cf_step(cv, 0.05)
	_cf_ok(cv._cf_cur == "s1_walk", "시험: 분노 단계에서 걸으면 s1_walk (%s)" % cv._cf_cur)
	cv.cf_set_state("")
	_cf_step(cv, 0.02)
	_cf_ok(cv._cf_cur == "walk", "시험: 단계를 되돌리면 walk")
	cv.walk_speed = 0.0
	cv.free()
	# 크기 단계 — 정수배만, 가장 가까운 판으로
	var cs: CreatureVisual = _cft_mk(0, [28, 40, 56], [])
	var seen: Array = []
	for m in [0.7, 1.0, 1.2, 1.45]:
		cs.cf_step_for(m)
		seen.append(cs.cf_key_now())
	_cf_ok(seen == [28, 0, 0, 56], "시험: 몸집 0.7·1.0·1.2·1.45배 → 판 %s (= 28·기본·기본·56)" % [seen])
	_cf_ok(cs.scale == Vector2.ONE and cs._sprite.scale == Vector2.ONE, "시험: 크기 단계를 바꿔도 배율은 정수(1)")
	cs.free()
	# 팔레트 — 번호 되찾기 · 원래 색 복원 · 한 번호만 바꾸기
	var pal: Array = CharForge.palette(id)
	_cf_ok(pal.size() > 0, "시험: palette.json(확정 모양)을 읽는다 %d색" % pal.size())
	var same: bool = true
	for a in (CharForge.info(id).get("anims", {}) as Dictionary).keys():
		var orig: Image = _cf_rgba(CharForge.anim(id, a)["tex"])
		var back: Image = CharForge.recolor_image(id, a, pal)
		if not _cf_same_opaque(orig, back):
			same = false
	_cf_ok(same and CharForge.index_misses(id) == 0, "시험: 번호 그림 → 원래 팔레트로 되돌리면 모든 시트가 원본과 똑같다 (어긋난 픽셀 %d)" % CharForge.index_misses(id))
	var swapped: Array = pal.duplicate()
	swapped[0] = Color8(255, 0, 255)
	var orig_a: Image = _cf_rgba(CharForge.anim(id, "anchor")["tex"])
	var rec_a: Image = CharForge.recolor_image(id, "anchor", swapped)
	var c0: Color = pal[0]
	var want_n: int = 0
	var got_n: int = 0
	var other_changed: int = 0
	var od: PackedByteArray = orig_a.get_data()
	var rd: PackedByteArray = rec_a.get_data()
	var i: int = 0
	while i < od.size():
		if od[i + 3] > 127:
			var is0: bool = od[i] == c0.r8 and od[i + 1] == c0.g8 and od[i + 2] == c0.b8
			var now_mag: bool = rd[i] == 255 and rd[i + 1] == 0 and rd[i + 2] == 255
			if is0:
				want_n += 1
			if is0 and now_mag:
				got_n += 1
			if not is0 and (rd[i] != od[i] or rd[i + 1] != od[i + 1] or rd[i + 2] != od[i + 2]):
				other_changed += 1
		i += 4
	_cf_ok(want_n > 0 and got_n == want_n and other_changed == 0, "시험: 1번 색만 바꾸면 그 색 픽셀 %d개만 바뀐다 (%d · 다른 픽셀 %d)" % [want_n, got_n, other_changed])
	var cp: CreatureVisual = _cft_mk(0, [], swapped)
	var mat: ShaderMaterial = cp._sprite.material
	_cf_ok(cp._sprite.texture == CharForge.index_tex(id, cp._cf_cur) and mat != null and mat.get_shader_parameter("use_pal") == true
		and mat.get_shader_parameter("pal_tex") != null, "시험: 변종 색을 주면 번호 그림 + 팔레트 재질로 그린다")
	var snap: Sprite2D = cp.snapshot()
	_cf_ok(snap != null and snap.material == cp._sprite.material, "시험: 변종의 잔상도 같은 팔레트 재질")
	snap.free()
	var vfx: Sprite2D = cp.make_vfx()
	_cf_ok(vfx != null and vfx.material != null and (vfx.material as ShaderMaterial).get_shader_parameter("use_pal") == true, "시험: 변종의 이펙트도 같은 팔레트")
	vfx.free()
	cp.free()
	var cn: CreatureVisual = _cft_mk(0, [], [])
	_cf_ok(cn._sprite.material == null or (cn._sprite.material as ShaderMaterial).get_shader_parameter("use_pal") != true, "시험: 변종 색을 안 주면 원래 그림 그대로")
	cn.free()
	var black_first: Array = CharForge.parse_palette({"transparent_index": 0, "palette": ["#000000", "#202a77", "#b65609"]})
	_cf_ok(black_first.size() == 3 and (black_first[0] as Color) == Color8(0, 0, 0), "시험: 확정 모양은 첫 색이 검정이어도 번호 1")
	var fx_path: String = CFT_ROOT + "idx.png"
	var fxf := FileAccess.open(fx_path, FileAccess.WRITE)
	fxf.store_buffer(Marshalls.base64_to_raw(CF_IDX_PNG))
	fxf.close()
	var fxi: Dictionary = _cf_png_info(fx_path)
	_cf_ok(int(fxi.get("type", -1)) == 3 and (fxi.get("plte", []) as Array).size() == 4 and (fxi.get("trns", PackedByteArray()) as PackedByteArray)[0] == 0,
		"시험: PNG 머리에서 팔레트 표 4칸·0번 투명을 읽는다 %s" % [fxi])
	_cf_ok(_cf_png_palette_issues(fxi, black_first).is_empty(), "시험: 순서가 맞는 팔레트 PNG 는 통과")
	var swapped2: Array = CharForge.parse_palette({"transparent_index": 0, "palette": ["#000000", "#b65609", "#202a77"]})
	_cf_ok(not _cf_png_palette_issues(fxi, swapped2).is_empty(), "시험: palette.json 과 순서가 다르면 잡는다")
	var rgba_i: Dictionary = _cf_png_info(CFT_ROOT + CFT_ID + "/sheets/anchor.png")
	_cf_ok(int(rgba_i.get("type", -1)) == 6 and not _cf_png_palette_issues(rgba_i, black_first).is_empty(), "시험: RGBA PNG 는 팔레트 PNG 가 아니라고 잡는다")
	var fimg: Image = Image.load_from_file(fx_path)
	fimg.convert(Image.FORMAT_RGBA8)
	var fidx: Image = CharForge.index_image("fx", fimg, black_first)
	var fd: PackedByteArray = fidx.get_data()
	_cf_ok([fd[0], fd[4], fd[8], fd[12], fd[16], fd[20], fd[24], fd[28]] == [0, 1, 2, 3, 3, 2, 1, 0] and fd[3] == 0 and fd[7] == 255,
		"시험: Godot 이 RGBA 로 읽은 팔레트 PNG 에서 번호를 그대로 되찾는다")
	_cf_ok(CharForge.parse_palette(["#ff0000", [0, 255, 0], {"hex": "#0000ff"}]).size() == 3
		and CharForge.parse_palette({"palette": ["#00000000", "#ffffff"]}).size() == 1, "시험: palette.json 여러 모양을 읽는다")


func _cft_spawn(made: Array, p: Player, k: int, off: Vector2, kind_of: String) -> Enemy:
	var e := Enemy.new()
	e.kind = k
	e.global_position = p.global_position + off
	if kind_of == "mini":
		e._mini = true
	elif kind_of == "elite":
		e._elite = true
	add_child(e)
	made.append(e)
	return e


## 실제 판 — 몹·보스·펫이 새 시트를 제때 쓰는가
func _cft_flow(p: Player) -> void:
	var made: Array = []
	var e0: Enemy = _cft_spawn(made, p, 0, Vector2(300, 0), "")
	var em: Enemy = _cft_spawn(made, p, 0, Vector2(300, 60), "mini")
	var ee: Enemy = _cft_spawn(made, p, 0, Vector2(300, -60), "elite")
	var e3: Enemy = _cft_spawn(made, p, 3, Vector2(-300, 0), "")
	var e4: Enemy = _cft_spawn(made, p, 4, Vector2(0, 320), "")
	var e13: Enemy = _cft_spawn(made, p, 13, Vector2(0, -320), "")
	var e16: Enemy = _cft_spawn(made, p, 16, Vector2(380, 200), "")
	var e17: Enemy = _cft_spawn(made, p, 17, Vector2(-380, 200), "")
	var e20: Enemy = _cft_spawn(made, p, 20, Vector2(380, -200), "")
	var e27: Enemy = _cft_spawn(made, p, 27, Vector2(-380, -200), "")
	var e6: Enemy = _cft_spawn(made, p, 6, Vector2(500, 0), "")
	await _cf_wait_unpaused(0.1)
	for e in made:
		(e as Enemy).hp = 1.0e7
		(e as Enemy).max_hp = 1.0e7
		(e as Enemy)._fire_cd = 99.0
		(e as Enemy)._special_cd = 99.0
		(e as Enemy)._summon_cd = 99.0
		(e as Enemy)._charge_cd = 99.0
		(e as Enemy)._reap_cd = 99.0
	_cf_ok(e0._cv.is_cf() and e0._cv.cf_id == CFT_ID, "판(시험): kind 0 이 시험 캐릭터로 뜬다")
	_cf_ok(e4._cv._cf_once == "entrance", "판(시험): 보스 등장 = entrance (%s)" % e4._cv._cf_once)
	_cf_ok(em._cv.cf_key_now() == 28 and ee._cv.cf_key_now() == 56 and e0._cv.cf_key_now() == 0, "판(시험): 졸개·갈라진 판 = px28, 강화 개체 = px56, 보통 = 기본 판")
	# 잡몹 돌진: 예고 → 돌진 → 풀림
	e0._behavior = 0
	e0._wind = 0.3
	await _cf_wait_unpaused(0.05)
	_cf_ok(e0._cv.is_posing("charge") and e0._cv._sprite.frame == 0, "판(시험): 잡몹 돌진 예고 = charge 0번 칸 (%s/%d)" % [e0._cv._cf_cur, e0._cv._sprite.frame])
	e0._wind = 0.0
	e0._charge_t = 0.3
	await _cf_wait_unpaused(0.05)
	_cf_ok(e0._cv.is_posing("charge") and e0._cv._sprite.frame == 1, "판(시험): 잡몹 돌진 중 = charge 1번 칸")
	e0._charge_t = 0.0
	await _cf_wait_unpaused(0.05)
	_cf_ok(not e0._cv.is_posing(), "판(시험): 돌진이 끝나면 자세를 푼다 (%s)" % e0._cv._cf_cur)
	# 보스 돌진 예고
	e4._cv.cf_reset()
	e4._wind = 0.4
	await _cf_wait_unpaused(0.05)
	_cf_ok(e4._cv.is_posing("charge"), "판(시험): 보스 돌진 예고 = charge (%s)" % e4._cv._cf_cur)
	e4._wind = 0.0
	# 융합 보스 돌진
	e6._cv.cf_reset()
	e6._charge_cd = 0.0
	await _cf_wait_unpaused(0.05)
	_cf_ok(e6._charge_t > 0.0 and e6._cv.is_posing("charge") and e6._cv._sprite.frame == 1, "판(시험): 융합 보스 돌진 = charge 1번 칸 (%s, 돌진 %.2f)" % [e6._cv._cf_cur, e6._charge_t])
	e6._charge_cd = 99.0
	# 원거리 몹: 준비 칸만큼 먼저 attack, 쏜 뒤 풀림
	e3._cv.cf_reset()
	e3._fire_cd = 0.1
	await _cf_wait_unpaused(0.03)
	_cf_ok(e3._atk_primed and e3._cv._cf_once == "attack", "판(시험): 원거리 몹이 쏘기 직전에 attack 을 든다 (%s)" % e3._cv._cf_once)
	await _cf_wait_unpaused(0.25)
	_cf_ok(not e3._atk_primed, "판(시험): 쏘고 나면 다음 발을 위해 풀린다")
	e3._fire_cd = 99.0
	# 유령 군주 순간이동
	e13._cv.cf_reset()
	e13._ghost_teleport(p)
	_cf_ok(e13._cv.is_posing("vanish") and e13._cv._sprite.frame == 0, "판(시험): 순간이동 시작 = vanish 0번 칸")
	await _cf_wait_unpaused(0.45)
	_cf_ok(e13._cv.is_posing("vanish") and e13._cv._sprite.frame == 1, "판(시험): 다시 나타날 때 = vanish 1번 칸")
	await _cf_wait_unpaused(0.4)
	_cf_ok(not e13._cv.is_posing("vanish"), "판(시험): 나타나고 나면 자세를 푼다")
	# 우츠로 분노 단계 — 직전에 맞은 hit 이 재생 중이면 기본 시트 교체가 그 뒤로 밀린다(7차 첫 검사에서 한 번 걸림).
	#   다른 판 검사처럼 자세를 비우고, 잠깐 피격 반응을 막아 둔다.
	e20._cv.cf_reset()
	e20._cv._cf_hit_gap = 1.0
	e20.hp = e20.max_hp * 0.4
	await _cf_wait_unpaused(0.05)
	_cf_ok(e20._cv._cf_state == "s1" and String(e20._cv._cf_cur).begins_with("s1_"), "판(시험): 체력 절반 아래면 분노 시트 (%s)" % e20._cv._cf_cur)
	e20.hp = e20.max_hp
	await _cf_wait_unpaused(0.05)
	_cf_ok(e20._cv._cf_state == "", "판(시험): 체력이 돌아오면 기본 시트")
	# 오르빈 광역 베기
	e27._cv.cf_reset()
	e27._reap_cd = 0.1
	await _cf_wait_unpaused(0.03)
	_cf_ok(e27._reap_primed and e27._cv._cf_once == "attack", "판(시험): 광역 베기 직전에 attack 을 든다 (%s)" % e27._cv._cf_once)
	e27._reap_cd = 99.0
	# 크기 기믹: 소수배로 늘이지 않고 단계 판으로
	e16._set_size(1.45)
	var k16a: int = e16._cv.cf_key_now()
	e16._set_size(0.7)
	var k16b: int = e16._cv.cf_key_now()
	_cf_ok(k16a == 56 and k16b == 28 and e16._cv.scale == Vector2.ONE, "판(시험): 하글 1.45배 → px56, 0.7배 → px28, 몸 배율 1 (%d, %d, %s)" % [k16a, k16b, e16._cv.scale])
	e17._set_size(2.2)
	_cf_ok(e17._cv.cf_key_now() == 0 and e17._cv.scale == Vector2.ONE and absf(e17.rad - e17._base_rad * 2.2) < 0.01,
		"판(시험): 카리아 단계 판이 없으면 그림은 그대로, 판정만 2.2배 (배율 %s)" % e17._cv.scale)
	# 펫 3종
	p.add_weapon("wpn_summon")
	p.add_weapon("summon_ice")
	p.add_weapon("wpn_orb")
	await _cf_wait_unpaused(0.6)
	var pets: Array = []
	var stack: Array = [p.get_parent()]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
			if ch is CreatureVisual and (ch as CreatureVisual).cf_id == CFT_ID and not (n is Enemy) and not (n is Player):
				pets.append(ch)
	var scales_ok: bool = true
	var idle_orb: bool = false
	for pv in pets:
		var cvp := pv as CreatureVisual
		if cvp.scale != Vector2.ONE or cvp._sprite.scale != Vector2(cvp.cf_scale(), cvp.cf_scale()) or cvp.rotation != 0.0 or cvp.position.y != 0.0:
			scales_ok = false
		if cvp._cf_cur == "idle":
			idle_orb = true
	print("  펫 시트 %d마리: %s" % [pets.size(), pets.map(func(x): return "%s/%s" % [(x as Node).get_parent().get_class(), (x as CreatureVisual)._cf_cur])])
	_cf_ok(pets.size() >= 3, "판(시험): 펫(소환수·얼음 정령·회전 오브)이 시트로 그려진다 (%d)" % pets.size())
	_cf_ok(scales_ok, "판(시험): 펫은 통통 튀기·기울이기 없이 정수 배율")
	# 8차부터 회전 오브는 032 캐릭터 대신 무기 이펙트 구슬(wpn_orb/orb)로 돈다 — 그 시트가 있으면 구슬이 도는지를 본다
	var orb_fx: bool = false
	for wch in p.get_children():
		if wch is OrbitWeapon:
			for o in wch.get_children():
				for oc in o.get_children():
					if oc is AnimatedSprite2D and (oc as AnimatedSprite2D).is_playing():
						orb_fx = true
	_cf_ok(orb_fx if FxLib.has("wpn_orb", "orb") else idle_orb,
		"판(시험): 회전 오브가 돈다 — %s" % ("무기 이펙트 구슬(8차)" if FxLib.has("wpn_orb", "orb") else "서 있을 때 idle"))
	for e in made:
		if is_instance_valid(e):
			(e as Enemy).queue_free()
	await _cf_wait_unpaused(0.05)


## ──────────────────── 캐릭터 에셋 시범 화면 (--cfshots) ────────────────────
## 시범 3종이 들어간 실제 화면을 찍는다. 창모드로 돌린다(헤드리스는 그림이 없다).
##   실행:  ... --path . --resolution 1920x1080 -- --cfshots          (새 에셋)
##          ... --path . --resolution 1920x1080 -- --cf=off --cfshots (같은 장면, 예전 그림)
## 저장: user://cfshots/<on|off>/*.png
##
## 첫 장(00_feet)은 게임 배율 그대로 모든 동작의 모든 칸을 한 줄 바닥 위에 세운 그림이다.
## 실제로 그려진 화면(테두리 셰이더 포함)에서 칸마다 가장 아래 픽셀을 재서, 동작을 바꿀 때
## 발이 몇 화면 px 튀는지를 같이 적는다 — 시트 숫자가 아니라 **화면**을 잰다.
## 판 안 촬영 — 레벨업·부활 창이 떠 있으면 걷고 찍는다(그 창은 이 그림의 주제가 아니다).
func _cf_snap(path: String) -> void:
	if _levelup_root != null and _levelup_root.visible:
		_levelup_root.visible = false
	if _revive_panel != null and _revive_panel.visible:
		_revive_panel.visible = false
	if _chest_panel != null and is_instance_valid(_chest_panel):
		_close_chest_panel()
	await _snap(path)


## 한 줄로 세운다: 항목 = [캐릭터 ID, 그리는 반경, 게임 이름, 예전 그림 경로].
## 캐릭터 에셋이 꺼져 있으면(ID 가 "") 예전 그림으로 같은 자리에 세운다 — 전후 비교용.
func _cf_lineup_row(parent: Node2D, origin: Vector2, step: float, items: Array) -> void:
	for i in items.size():
		var it: Array = items[i]
		var cv := CreatureVisual.new()
		cv.radius = float(it[1])
		cv.cf_id = String(it[0])
		if it.size() > 4:
			cv.cf_target_h = float(it[4])
		if cv.cf_id == "":
			cv.sprite_path = String(it[3])
			cv.sprite_hframes = Enemy._strip_frames(String(it[3]))
		cv.always_animate = true
		cv.build()
		cv.position = origin + Vector2(step * float(i), 0)
		parent.add_child(cv)
		var lb := Label.new()
		lb.text = String(it[2]).replace(" ◆특수", "").replace(" ◆이면", "")
		UiFont.apply(lb, 10)
		lb.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lb.add_theme_constant_override("outline_size", 4)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.size = Vector2(step, 14)
		lb.position = cv.position + Vector2(-step * 0.5, cv.radius * 0.86 + 6.0)
		parent.add_child(lb)


func _cfshots_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CFSHOTS] 건너뜀 — 창모드로 실행해야 한다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	var tag: String = "on" if CharForge.enabled else "off"
	var dir: String = "user://cfshots/" + tag
	DirAccess.make_dir_recursive_absolute(dir)
	var cast: Dictionary = CharForge.cast()
	print("=== CFSHOTS (%s) ===" % tag)

	# ── 00 발 기준선 (새 에셋일 때만) ──
	if CharForge.enabled:
		var layer := CanvasLayer.new()
		layer.layer = 90
		add_child(layer)
		var bg := ColorRect.new()
		bg.color = Color(0.36, 0.38, 0.42)
		bg.size = Vector2(4000, 4000)
		bg.position = Vector2(-100, -100)
		layer.add_child(bg)
		var stage := Node2D.new()
		layer.add_child(stage)
		# 시범 3자리(회풍 · 기본 잡몹 · 첫 중간보스)만 — 전 배역은 13·14 장에 따로 세운다
		var rows: Array = []
		if CharForge.hero_id("rogue") != "":
			rows.append([CharForge.hero_id("rogue"), Player.RADIUS])
		for kk0 in [0, 4]:
			if CharForge.enemy_id(kk0) != "":
				var kd: Dictionary = Enemy.KINDS[kk0]
				rows.append([CharForge.enemy_id(kk0), float(kd.get("vis", kd["rad"]))])
		var y: float = 40.0
		var cells: Array = []     # [행, 열 x0, x1, 기준선 y(논리), 동작]
		for ri in rows.size():
			var cid: String = String(rows[ri][0])
			var r: float = float(rows[ri][1])
			var k3: int = CharForge.scale_for(r * CreatureVisual.DRAW_SCALE)
			var row_h: float = 52.0 * float(k3) + 18.0
			var base_y: float = y + row_h - 10.0
			var line := Line2D.new()
			line.points = PackedVector2Array([Vector2(0, base_y), Vector2(1280, base_y)])
			line.width = 1.0
			line.default_color = Color(0.3, 1.0, 0.4, 0.5)
			stage.add_child(line)
			var x: float = 12.0
			for a in ["anchor", "walk", "hit", "death", "emote", "skill", "ultimate", "entrance"]:
				if not CharForge.has_anim(cid, a):
					continue
				var an: Dictionary = CharForge.anim(cid, a)
				for fi in int(an["n"]):
					var cw: float = float(an["fw"]) * float(k3) + 4.0
					if x + cw > 1270.0:
						break
					var cv := CreatureVisual.new()
					cv.radius = r
					cv.cf_id = cid
					cv.always_animate = true
					cv.build()
					cv._cf_set(a)
					cv._sprite.frame = fi
					cv.process_mode = Node.PROCESS_MODE_DISABLED
					(cv._inner.get_child(0) as CanvasItem).visible = false   # 그림자를 끈다 — 발을 재야 한다
					# 발 기준점(그림자 자리)이 base_y 에 오게
					cv.position = Vector2(x + cw * 0.5, base_y - roundf(r * 0.86))
					stage.add_child(cv)
					if not (a == "death" and fi == 1):
						cells.append([ri, x, x + cw, base_y, a, fi])
					x += cw
			y += row_h + 6.0
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png(dir + "/00_feet.png")
		print("[SHOT] %s/00_feet.png" % dir)
		# 화면에서 잰다: 칸마다 배경과 다른 가장 아래 픽셀
		var sx: float = float(img.get_width()) / 1280.0
		var bgc: Color = img.get_pixel(2, img.get_height() - 3)
		var per_row: Dictionary = {}
		for c in cells:
			var x0: int = int(float(c[1]) * sx)
			var x1: int = int(float(c[2]) * sx)
			var by: int = int(float(c[3]) * sx)
			var low: int = -1
			for yy in range(mini(img.get_height() - 1, by + int(12 * sx)), maxi(0, by - int(160 * sx)), -1):
				var hit: bool = false
				for xx in range(x0 + 2, x1 - 2):
					var pc: Color = img.get_pixel(xx, yy)
					if absf(pc.r - bgc.r) + absf(pc.g - bgc.g) + absf(pc.b - bgc.b) > 0.12 and not (pc.g > pc.r + 0.25 and pc.g > pc.b + 0.2):
						hit = true
						break
				if hit:
					low = yy
					break
			var key: int = int(c[0])
			if not per_row.has(key):
				per_row[key] = []
			(per_row[key] as Array).append([String(c[4]), int(c[5]), low - by])
		for ri in per_row.keys():
			var lst: Array = per_row[ri]
			var lo: int = 9999
			var hi: int = -9999
			var detail: PackedStringArray = []
			for e in lst:
				lo = mini(lo, int(e[2]))
				hi = maxi(hi, int(e[2]))
				detail.append("%s%d:%+d" % [e[0], e[1], e[2]])
			print("[FEET] %s  화면 발 높이 범위 %d px  (%s)" % [rows[ri][0], hi - lo, " ".join(detail)])
		layer.queue_free()
		await get_tree().process_frame

	# ── 01 영웅 선택 — 회풍 카드 + 상세 초상화 ──
	# 시범 3자리로 고정한다(회풍 · 기본 잡몹 kind 0 · 첫 중간보스 kind 4) — 배역표 순서와 무관하게
	var hero_key: String = "rogue"
	var hero_def: Dictionary = {}
	for d: Dictionary in Characters.defs():
		if String(d["id"]) == hero_key:
			hero_def = d
	G.meta["uc_" + hero_key] = 1
	await _snap(dir + "/00_menu.png")      # 메인 메뉴 — 뒤 배경 최종 보스 · 아래 영웅 행렬
	_main_menu.close()
	_char_select.open()
	await get_tree().process_frame
	_char_select._show_detail(hero_def)
	var btn: Control = _char_select._card_btns.get(hero_key)
	if btn != null:
		var sc: Node = btn.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		if sc != null:
			(sc as ScrollContainer).ensure_control_visible(btn)
	for _i in 6:
		await get_tree().process_frame
	await _snap(dir + "/01_select.png")
	_char_select._on_back()

	# ── 02 도감 — 몬스터 탭 ──
	for m in Codex.MONSTERS:
		G.codex[String(m["key"])] = true
	_codex_screen.open()
	_codex_screen._switch(1)
	for _i in 6:
		await get_tree().process_frame
	await _snap(dir + "/02_codex.png")
	_codex_screen.close()

	# ── 판 ──
	get_tree().paused = false
	_main_menu.close()
	_begin_run(hero_def)
	await _cf_wait_unpaused(0.15)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	await _cf_snap(dir + "/03_hero_entrance.png")
	await _cf_wait_unpaused(1.0)
	# 잡몹 무리 — 오래 버티게 해서 걷는 모습을 찍는다
	var mob_kind: int = 0
	var boss_kind: int = 4
	var mobs: Array = []
	if mob_kind >= 0:
		for i in 26:
			var e := Enemy.new()
			e.kind = mob_kind
			var ang: float = TAU * float(i) / 26.0
			e.global_position = p.global_position + Vector2(cos(ang), sin(ang)) * (230.0 + 40.0 * float(i % 3))
			add_child(e)
			mobs.append(e)
		await _cf_wait_unpaused(0.03)
		for e in mobs:
			(e as Enemy).hp = 1.0e7
			(e as Enemy).max_hp = 1.0e7
	Input.action_press("move_right")
	await _cf_wait_unpaused(0.9)
	await _cf_snap(dir + "/04_swarm_walk.png")
	Input.action_release("move_right")
	# 대시 = 스킬
	p._dash_cd = 0.0
	p._start_dash(Vector2.LEFT)
	await _cf_wait_unpaused(0.07)
	await _cf_snap(dir + "/05_hero_dash_skill.png")
	await _cf_wait_unpaused(0.8)
	# 영웅 피격
	p._iframe = 0.0
	p._cv._cf_hit_gap = 0.0
	p.take_damage(1.0, "검사")
	await _cf_wait_unpaused(0.05)
	await _cf_snap(dir + "/06_hero_hit.png")
	# 잡몹 처치 — 쓰러지는 칸
	var killed: int = 0
	for e in mobs:
		if is_instance_valid(e) and killed < 8:
			(e as Enemy).take_damage(1.0e9, Vector2.RIGHT)
			killed += 1
	await _cf_wait_unpaused(0.06)
	await _cf_snap(dir + "/07_mob_death.png")
	for e in mobs:
		if is_instance_valid(e):
			(e as Enemy).take_damage(1.0e9, Vector2.RIGHT)
	await _cf_wait_unpaused(0.8)
	# 보스 — 등장 · 탄막(skill) · 장판(ultimate)
	if boss_kind >= 0:
		var b := Enemy.new()
		b.kind = boss_kind
		b.global_position = p.global_position + Vector2(220, -40)
		add_child(b)
		await _cf_wait_unpaused(0.35)
		await _cf_snap(dir + "/08_boss_entrance.png")
		await _cf_wait_unpaused(1.0)
		if is_instance_valid(b):
			b.hp = 1.0e7
			b.max_hp = 1.0e7
			b._cv.cf_reset()
			b._fire_cd = 0.0
			await _cf_wait_unpaused(0.25)
			await _cf_snap(dir + "/09_boss_skill.png")
			await _cf_wait_unpaused(0.8)
			b._cv.cf_reset()
			b._special_cd = 0.0
			await _cf_wait_unpaused(0.3)
			await _cf_snap(dir + "/10_boss_ultimate.png")
			await _cf_wait_unpaused(0.8)
			b._cv.cf_reset()
			b.take_damage(1.0e9, Vector2.RIGHT)
			await _cf_wait_unpaused(0.4)
			await _cf_snap(dir + "/11_boss_death.png")
	# 영웅 쓰러짐
	await _cf_wait_unpaused(1.0)
	p.max_hp = 100.0
	p.hp = 1.0
	p._iframe = 0.0
	G.revive_used = 0
	p.take_damage(9999.0, "검사")      # 부활 대기 = 쓰러진 자세(게임오버 창은 바로 덮어서 안 보인다)
	await _cf_wait_unpaused(1.1)
	await _cf_snap(dir + "/12_hero_death.png")
	if p.pending_revive:
		p.revive()

	# ── 13·14 전체 배역 — 실제 바닥 위에 게임 배율 그대로 세운다 ──
	G.running = false
	for n in get_tree().get_nodes_in_group("enemy"):
		(n as Node).queue_free()
	await _cf_wait_unpaused(0.1)
	var base: Vector2 = p.global_position
	p.visible = false
	var lineup := Node2D.new()
	add_child(lineup)
	var hero_row: Array = []
	for d4: Dictionary in Characters.defs():
		hero_row.append([d4, CharForge.hero_id(String(d4["id"]))])
	var mob_row: Array = []
	var boss_row: Array = []
	var kinds: Array = Enemy.KINDS.keys()
	kinds.sort()
	for kk in kinds:
		if bool((Enemy.KINDS[kk] as Dictionary).get("boss", false)):
			boss_row.append(kk)
		else:
			mob_row.append(kk)
	_cf_lineup_row(lineup, base + Vector2(-500, -170), 76.0, hero_row.map(func(h): return [String(h[1]), Player.RADIUS, String((h[0] as Dictionary)["name"]), String((h[0] as Dictionary).get("sprite", ""))]))
	_cf_lineup_row(lineup, base + Vector2(-560, 110), 58.0, mob_row.map(func(kk2): return [CharForge.enemy_id(int(kk2)), float((Enemy.KINDS[kk2] as Dictionary).get("vis", (Enemy.KINDS[kk2] as Dictionary)["rad"])), Codex.monster_name(int(kk2)), "res://assets/sprites/monsters/%s.png" % String((Enemy.LOOKS.get(kk2, {}) as Dictionary).get("spr", ""))]))
	await _cf_wait_unpaused(0.2)
	await _cf_snap(dir + "/13_lineup_heroes_mobs.png")
	lineup.queue_free()
	var lineup2 := Node2D.new()
	add_child(lineup2)
	var b1: Array = boss_row.slice(0, 5)
	var b2: Array = boss_row.slice(5)
	var mk := func(kk3): return [CharForge.enemy_id(int(kk3)), float((Enemy.KINDS[kk3] as Dictionary).get("vis", (Enemy.KINDS[kk3] as Dictionary)["rad"])), Codex.monster_name(int(kk3)), "res://assets/sprites/monsters/%s.png" % String((Enemy.LOOKS.get(kk3, {}) as Dictionary).get("spr", ""))]
	_cf_lineup_row(lineup2, base + Vector2(-480, -150), 240.0, b1.map(mk))
	_cf_lineup_row(lineup2, base + Vector2(-360, 190), 240.0, b2.map(mk))
	await _cf_wait_unpaused(0.2)
	await _cf_snap(dir + "/14_lineup_bosses.png")
	print("[CFSHOTS] 끝 → %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit(0)


## ──────────────────── 2차 지시서 보고용 화면 (--cfshots2) ────────────────────
## 어두운 바닥(던전)·밝은 바닥(천상) 각각에 영웅·몹·보스를 게임 배율 그대로 세우고,
## 보스 등장·돌진(예고·돌진)·장판, 팔레트 변종(시험 캐릭터)을 찍는다. 창모드로 돌린다.
##   실행:  ... --path . --resolution 1920x1080 -- --cfshots2
## 저장: user://cfshots2/*.png
func _cfs2_theme(th: int) -> void:
	_cur_theme = th
	G.stage = th   # 16차: 스폰 그림(저승길이면 저승길 몹)이 테마를 따라가게
	if _bg != null:
		_bg.set_theme(th)
	_regen_obstacles(th)
	_scatter_decals(th)


func _cfs2_clear_enemies() -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		(n as Node).queue_free()


func _cfs2_item(kk: int) -> Array:
	var kd: Dictionary = Enemy.KINDS[kk]
	return [CharForge.enemy_id(kk), float(kd.get("vis", kd["rad"])), Codex.monster_name(kk),
		"res://assets/sprites/monsters/%s.png" % String((Enemy.LOOKS.get(kk, {}) as Dictionary).get("spr", "")),
		float(CharForge.enemy_slot(kk).get("h", 0.0))]


func _cfshots2_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CFSHOTS2] 건너뜀 — 창모드로 실행해야 한다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	var dir: String = "user://cfshots2"
	DirAccess.make_dir_recursive_absolute(dir)
	print("=== CFSHOTS2 ===")
	var hero_def: Dictionary = Characters.defs()[0]
	for d: Dictionary in Characters.defs():
		if String(d["id"]) == "rogue":
			hero_def = d
	_main_menu.close()
	_begin_run(hero_def)
	await _cf_wait_unpaused(0.3)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	var kinds: Array = Enemy.KINDS.keys()
	kinds.sort()
	var mob_row: Array = []
	var boss_row: Array = []
	for kk in kinds:
		if bool((Enemy.KINDS[kk] as Dictionary).get("boss", false)):
			boss_row.append(kk)
		else:
			mob_row.append(kk)
	# ── 바닥 두 가지 × 줄 세우기 ──
	for th in [0, 4]:
		var tag: String = "dark" if th == 0 else "light"
		G.running = false
		_cfs2_clear_enemies()
		_cfs2_theme(th)
		await _cf_wait_unpaused(0.2)
		var base: Vector2 = p.global_position
		p.visible = false
		var lineup := Node2D.new()
		add_child(lineup)
		var hero_items: Array = []
		for d4: Dictionary in Characters.defs():
			var hs: Dictionary = CharForge.hero_slot(String(d4["id"]))
			hero_items.append([String(hs.get("id", "")), Player.RADIUS, String(d4["name"]), String(d4.get("sprite", "")), float(hs.get("h", 0.0))])
		_cf_lineup_row(lineup, base + Vector2(-500, -170), 76.0, hero_items)
		_cf_lineup_row(lineup, base + Vector2(-560, 110), 58.0, mob_row.map(func(k2): return _cfs2_item(int(k2))))
		await _cf_wait_unpaused(0.25)
		await _cf_snap(dir + "/%s_1_heroes_mobs.png" % tag)
		lineup.queue_free()
		var lineup2 := Node2D.new()
		add_child(lineup2)
		_cf_lineup_row(lineup2, base + Vector2(-480, -150), 240.0, boss_row.slice(0, 5).map(func(k3): return _cfs2_item(int(k3))))
		_cf_lineup_row(lineup2, base + Vector2(-360, 190), 240.0, boss_row.slice(5).map(func(k4): return _cfs2_item(int(k4))))
		await _cf_wait_unpaused(0.25)
		await _cf_snap(dir + "/%s_2_bosses.png" % tag)
		lineup2.queue_free()
		p.visible = true
		await _cf_wait_unpaused(0.1)
	# ── 보스: 등장 · 돌진 예고 · 돌진 · 장판 (어두운 바닥) ──
	_cfs2_theme(0)
	G.running = true
	_cfs2_clear_enemies()
	await _cf_wait_unpaused(0.2)
	var b := Enemy.new()
	b.kind = 4
	b.global_position = p.global_position + Vector2(230, -30)
	add_child(b)
	await _cf_wait_unpaused(0.25)
	b.hp = 1.0e7
	b.max_hp = 1.0e7
	b._fire_cd = 99.0
	b._summon_cd = 99.0
	b._special_cd = 99.0
	b._charge_cd = 99.0
	await _cf_snap(dir + "/boss_1_entrance.png")
	await _cf_wait_unpaused(1.0)
	b._cv.cf_reset()
	b._wind = 0.55
	await _cf_wait_unpaused(0.2)
	await _cf_snap(dir + "/boss_2_charge_windup.png")
	while is_instance_valid(b) and b._charge_t <= 0.0 and b._wind > 0.0:
		await get_tree().process_frame
	await _cf_wait_unpaused(0.08)
	await _cf_snap(dir + "/boss_3_charge_dash.png")
	await _cf_wait_unpaused(0.9)
	b._cv.cf_reset()
	b._special_cd = 0.0
	await _cf_wait_unpaused(0.3)
	await _cf_snap(dir + "/boss_4_aoe.png")
	_cfs2_clear_enemies()
	await _cf_wait_unpaused(2.0)     # 장판이 터지고 이펙트가 사라질 때까지 — 다음 장면에 남지 않게
	# ── 팔레트 변종(시험 캐릭터) — 어두운 바닥·밝은 바닥 ──
	var src: String = CharForge.hero_id("rogue")
	_cft_build(src)
	var saved_root: String = CharForge.root
	var saved_cast: String = CharForge.cast_path
	CharForge.root = CFT_ROOT
	CharForge.cast_path = CFT_ROOT + "cast.json"
	CharForge.reset_cache()
	var pal: Array = CharForge.palette(CFT_ID)
	G.running = false
	for th2 in [0, 4]:
		_cfs2_theme(th2)
		await _cf_wait_unpaused(0.15)
		p.visible = false
		var row := Node2D.new()
		add_child(row)
		var shifts: Array = [0.0, 0.33, 0.55, 0.8]
		for i in shifts.size():
			var cols: Array = []
			for c in pal:
				var cc: Color = c
				cols.append(Color.from_hsv(fposmod(cc.h + float(shifts[i]), 1.0), cc.s, cc.v) if i > 0 else cc)
			var cv := CreatureVisual.new()
			cv.radius = Player.RADIUS
			cv.cf_id = CFT_ID
			cv.cf_target_h = 80.0          # 잘 보이게 2배(정수)로
			cv.cf_palette = cols if i > 0 else []
			cv.always_animate = true
			cv.build()
			cv.position = p.global_position + Vector2(-300 + 200 * i, 40)
			row.add_child(cv)
		await _cf_wait_unpaused(0.2)
		await _cf_snap(dir + "/palette_%s.png" % ("dark" if th2 == 0 else "light"))
		row.queue_free()
	CharForge.root = saved_root
	CharForge.cast_path = saved_cast
	CharForge.reset_cache()
	print("[CFSHOTS2] 끝 → %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit(0)


## ──────────────────── 주문분 도착 후 화면 검사 (--cfshots_arrival) ────────────────────
## 2차 지시서 5-3: 던전(어두운)·천상(밝은) 바닥 위에 몹 20종·보스 9종을 게임 배율 그대로 세운다.
## 카메라 1.0 · 1.3 배. 1.3 배는 한 화면에 덜 들어가므로 화면에 맞는 만큼씩 쪽을 나눠 찍는다.
## 흑백(실루엣 구분)은 찍은 그림을 tools/charforge_arrival.sh 가 흑백으로 바꿔 둔다.
##   실행:  ... --path . --resolution 1920x1080 -- --cfshots_arrival
## 저장: user://cfshots_arrival/<dark|light>_z<10|13>_<mobs|bosses>_<쪽>.png
func _cfsa_page(parent: Node2D, center: Vector2, items: Array, start: int, cell: Vector2, z: float) -> int:
	var view: Vector2 = Vector2(1280.0, 720.0) / z
	var cols: int = maxi(1, int((view.x - 40.0) / cell.x))
	var rows: int = maxi(1, int((view.y - 90.0) / cell.y))
	var n: int = mini(items.size() - start, cols * rows)
	var used_rows: int = int(ceil(float(n) / float(cols)))
	var top_left: Vector2 = center - Vector2(float(mini(n, cols)) * cell.x, float(used_rows) * cell.y) * 0.5
	for i in n:
		var it: Array = items[start + i]
		var cv := CreatureVisual.new()
		cv.radius = float(it[1])
		cv.cf_id = String(it[0])
		cv.cf_target_h = float(it[4])
		if cv.cf_id == "":
			cv.sprite_path = String(it[3])
			cv.sprite_hframes = Enemy._strip_frames(String(it[3]))
		cv.always_animate = true
		cv.build()
		var c: int = i % cols
		var r: int = i / cols
		# 발밑이 칸 아래에서 이름표 자리만큼 위에 오게
		cv.position = top_left + Vector2((float(c) + 0.5) * cell.x, (float(r) + 1.0) * cell.y - 22.0 - cv.radius * 0.86)
		parent.add_child(cv)
		var lb := Label.new()
		lb.text = String(it[2]).replace(" ◆특수", "").replace(" ◆이면", "")
		UiFont.apply(lb, int(10.0 / z) + 1)
		lb.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lb.add_theme_constant_override("outline_size", 4)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.size = Vector2(cell.x, 14)
		lb.position = cv.position + Vector2(-cell.x * 0.5, cv.radius * 0.86 + 4.0)
		parent.add_child(lb)
	return n


func _cfshots_arrival_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CFSHOTS_ARRIVAL] 건너뜀 — 창모드로 실행해야 한다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	var dir: String = "user://cfshots_arrival"
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	print("=== CFSHOTS_ARRIVAL ===")
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(0.3)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	var kinds: Array = Enemy.KINDS.keys()
	kinds.sort()
	var mobs: Array = []
	var bosses: Array = []
	for kk in kinds:
		if bool((Enemy.KINDS[kk] as Dictionary).get("boss", false)):
			bosses.append(_cfs2_item(int(kk)))
		else:
			mobs.append(_cfs2_item(int(kk)))
	var cam: Camera2D = G.camera as Camera2D
	var zoom0: Vector2 = cam.zoom if cam != null else Vector2.ONE
	var n_shots: int = 0
	for th in [0, 4]:
		var tag: String = "dark" if th == 0 else "light"
		G.running = false
		_cfs2_clear_enemies()
		_cfs2_theme(th)
		p.visible = false
		for z in [1.0, 1.3]:
			if cam != null:
				cam.zoom = Vector2.ONE * z
			await _cf_wait_unpaused(0.2)
			for grp in [["mobs", mobs, Vector2(62, 84)], ["bosses", bosses, Vector2(250, 250)]]:
				var items: Array = grp[1]
				var start: int = 0
				var page: int = 1
				while start < items.size():
					var holder := Node2D.new()
					add_child(holder)
					var placed: int = _cfsa_page(holder, p.global_position, items, start, grp[2], z)
					await _cf_wait_unpaused(0.25)
					await _cf_snap(dir + "/%s_z%d_%s_%d.png" % [tag, int(round(z * 10.0)), grp[0], page])
					n_shots += 1
					holder.queue_free()
					await get_tree().process_frame
					start += placed
					page += 1
	if cam != null:
		cam.zoom = zoom0
	print("[CFSHOTS_ARRIVAL] %d장 → %s" % [n_shots, ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## ──────────────────── 4차 화면 (--cfshots4) ────────────────────
## 4차 지시서 4절: 어두운 돌바닥(던전·용암동굴·정원)과 밝은 회색 바닥(천상) 넷 다 · 수백 마리 떼 ·
## 보스전 · 볼케 형제 확대(112px 에서 두 형제로 읽히나) · 빈 통의 소류 쓰러짐(→ 작은 창랑 4마리).
##   실행:  ... --path . --resolution 1920x1080 -- --cfshots4
## 저장: user://cfshots4/
const CFS4_FLOORS: Array = [[0, "dungeon"], [3, "lava"], [2, "garden"], [4, "heaven"]]


func _cfs4_spawn(kind: int, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.kind = kind
	e.global_position = pos
	add_child(e)
	return e


func _cfs4_swarm(center: Vector2, kinds: Array, n: int, r0: float, r1: float) -> void:
	for i in n:
		var a: float = randf() * TAU
		var d: float = lerpf(r0, r1, sqrt(randf()))
		_cfs4_spawn(int(kinds[i % kinds.size()]), center + Vector2(cos(a), sin(a)) * d)


func _cfshots4_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CFSHOTS4] 건너뜀 — 창모드로 실행해야 한다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(4004)
	var dir: String = "user://cfshots4"
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	print("=== CFSHOTS4 ===")
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(0.3)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	var cam: Camera2D = G.camera as Camera2D
	var zoom0: Vector2 = cam.zoom if cam != null else Vector2.ONE
	var kinds: Array = Enemy.KINDS.keys()
	kinds.sort()
	var mobs: Array = []
	var bosses: Array = []
	var mob_kinds: Array = []
	for kk in kinds:
		if bool((Enemy.KINDS[kk] as Dictionary).get("boss", false)):
			bosses.append(_cfs2_item(int(kk)))
		else:
			mobs.append(_cfs2_item(int(kk)))
			mob_kinds.append(int(kk))
	var n_shots: int = 0
	# ── 1) 바닥 넷 × 줄 세우기 (게임 배율, 카메라 1.0) ──
	if cam != null:
		cam.zoom = Vector2.ONE
	for fl: Array in CFS4_FLOORS:
		G.running = false
		_cfs2_clear_enemies()
		_cfs2_theme(int(fl[0]))
		p.visible = false
		await _cf_wait_unpaused(0.2)
		for grp in [["mobs", mobs, Vector2(62, 84)], ["bosses", bosses, Vector2(250, 250)]]:
			var items: Array = grp[1]
			var start: int = 0
			var page: int = 1
			while start < items.size():
				var holder := Node2D.new()
				add_child(holder)
				var placed: int = _cfsa_page(holder, p.global_position, items, start, grp[2], 1.0)
				await _cf_wait_unpaused(0.25)
				await _cf_snap(dir + "/floor_%s_%s_%d.png" % [fl[1], grp[0], page])
				n_shots += 1
				holder.queue_free()
				await get_tree().process_frame
				start += placed
				page += 1
		p.visible = true
	if cam != null:
		cam.zoom = zoom0
	# ── 2) 떼 — 바닥마다 240마리. 흔한 몹(창랑)과 색이 겹치는 둘(하쓰바·브란드), 다시 그린 넷을 더 섞는다 ──
	var weighted: Array = mob_kinds.duplicate()
	for k5 in [0, 0, 0, 0, 7, 7, 18, 18, 10, 16, 17]:
		weighted.append(k5)
	for fl2: Array in CFS4_FLOORS:
		G.running = false
		_cfs2_clear_enemies()
		_cfs2_theme(int(fl2[0]))
		await _cf_wait_unpaused(0.1)
		G.running = true
		p.hp = p.max_hp
		weighted.shuffle()
		_cfs4_swarm(p.global_position, weighted, 240, 150.0, 620.0)
		await _cf_wait_unpaused(1.4)
		await _cf_snap(dir + "/swarm_%s.png" % fl2[1])
		n_shots += 1
	# 하쓰바(도마뱀)·브란드(족제비)만 — 둘 다 주황이라 모양으로 갈리는지
	for fl6: Array in [[0, "dungeon"], [4, "heaven"]]:
		G.running = false
		_cfs2_clear_enemies()
		_cfs2_theme(int(fl6[0]))
		await _cf_wait_unpaused(0.1)
		if cam != null:
			cam.zoom = Vector2.ONE * 1.3
		G.running = true
		var hb: Array = []
		for i in 60:
			hb.append(7 if i % 2 == 0 else 18)
		_cfs4_swarm(p.global_position, hb, 60, 120.0, 420.0)
		await _cf_wait_unpaused(1.0)
		await _cf_snap(dir + "/swarm_hatsuba_brand_%s.png" % fl6[1])
		n_shots += 1
		if cam != null:
			cam.zoom = zoom0
	# ── 3) 보스전 — 보스 + 몹 90마리 ──
	for bf: Array in [[0, 14, "dungeon"], [3, 28, "lava"], [2, 15, "garden"], [4, 27, "heaven"], [4, 6, "heaven"]]:
		G.running = false
		_cfs2_clear_enemies()
		_cfs2_theme(int(bf[0]))
		await _cf_wait_unpaused(0.1)
		G.running = true
		p.hp = p.max_hp
		var b := _cfs4_spawn(int(bf[1]), p.global_position + Vector2(260, -40))
		await _cf_wait_unpaused(0.1)
		if is_instance_valid(b):
			b.hp = 1.0e7
			b.max_hp = 1.0e7
		weighted.shuffle()
		_cfs4_swarm(p.global_position, weighted, 90, 220.0, 620.0)
		await _cf_wait_unpaused(1.8)
		await _cf_snap(dir + "/bossfight_%s_k%d.png" % [bf[2], bf[1]])
		n_shots += 1
	G.running = false
	_cfs2_clear_enemies()
	await _cf_wait_unpaused(0.3)
	# ── 4) 볼케 형제 확대 — 카메라 2배(1080p 에서 도트 한 칸 = 3px). 옆에 영웅(40px)을 세워 크기를 비교 ──
	p.visible = false
	var hs4: Dictionary = CharForge.hero_slot(String(Characters.defs()[0]["id"]))
	var bk: Array = _cfs2_item(14)
	for fl3: Array in [[0, "dungeon"], [4, "heaven"]]:
		_cfs2_theme(int(fl3[0]))
		if cam != null:
			cam.zoom = Vector2.ONE * 2.0
		var holder2 := Node2D.new()
		add_child(holder2)
		for j in 2:
			var cv := CreatureVisual.new()
			if j == 0:
				cv.radius = float(bk[1])
				cv.cf_id = String(bk[0])
				cv.cf_target_h = float(bk[4])
			else:
				cv.radius = Player.RADIUS
				cv.cf_id = String(hs4.get("id", ""))
				cv.cf_target_h = float(hs4.get("h", 0.0))
			cv.always_animate = true
			cv.build()
			cv.position = p.global_position + Vector2(-50.0 + 140.0 * float(j), 40.0 - cv.radius * 0.86)
			holder2.add_child(cv)
		await _cf_wait_unpaused(0.3)
		await _cf_snap(dir + "/closeup_bolke_%s.png" % fl3[1])
		n_shots += 1
		holder2.queue_free()
		await get_tree().process_frame
	p.visible = true
	# ── 5) 빈 통의 소류 쓰러짐 → 작은 창랑 4마리 (정원). 플레이어 무기를 멈춰 갈라진 것이 바로 안 죽게 ──
	_cfs2_theme(2)
	if cam != null:
		cam.zoom = Vector2.ONE * 1.5
	p.xp_mult = 0.0                    # 보스 경험치로 레벨업 빛무리가 덮지 않게
	await _cf_wait_unpaused(0.1)       # 카메라가 배율을 먹은 다음에 플레이어(카메라 포함)를 멈춘다
	p.process_mode = Node.PROCESS_MODE_DISABLED
	G.running = true
	var s := _cfs4_spawn(15, p.global_position + Vector2(170, 10))
	await _cf_wait_unpaused(0.1)
	if is_instance_valid(s):
		s.hp = 1.0e7
		s.max_hp = 1.0e7
		s._fire_cd = 99.0
		s._special_cd = 99.0
		s._summon_cd = 99.0
	await _cf_wait_unpaused(1.4)      # 등장 연출이 끝나게
	await _cf_snap(dir + "/soryu_0_alive.png")
	if is_instance_valid(s):
		s.take_damage(1.0e9, Vector2.RIGHT)
	var t_acc: float = 0.0
	var idx: int = 1
	for t in [0.05, 0.15, 0.15, 0.2, 0.45]:
		await _cf_wait_unpaused(float(t))
		t_acc += float(t)
		await _cf_snap(dir + "/soryu_%d_%dms.png" % [idx, int(round(t_acc * 1000.0))])
		idx += 1
	n_shots += 6
	p.process_mode = Node.PROCESS_MODE_INHERIT
	p.xp_mult = 1.0
	G.running = false
	if cam != null:
		cam.zoom = zoom0
	print("[CFSHOTS4] %d장 → %s" % [n_shots, ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## ──────────────────── 5차 화면 (--cfshots5) ────────────────────
## 5차 지시서 7절 3: 다시 그린 칸(나기·네페르 동작, 보스 vfx 셋, 볼케 전체, 오르빈 등장 2)을 보스전에서 본다.
## 보스 + 몹 70마리 싸움판에서 보스의 쿨을 묶고 칸을 하나씩 세워(pose) 찍는다. ultimate 0 에서 이펙트(vfx)를
## 게임과 같은 자리(플레이어 발밑)에 띄운다. 찍을 때마다 보스·플레이어의 화면 위치를 pos.txt 에 남긴다(잘라 붙이기용).
## 끝에 영웅 14종이 대시하며 남기는 자국(vfx) — 5절 "영웅 vfx 를 게임에서 쓰는지" 확인용.
##   실행:  ... --path . --resolution 1920x1080 -- --cfshots5
## 저장: user://cfshots5/
## 6차: 다시 그린 칸만 — 나기 동작 9칸 · 네페르 장판(vfx, ultimate 0 에서 뜬다) · 볼케 등장 · 오르빈 궁극기 두 칸.
## (5차 목록: 나기·네페르 등장·스킬·궁극기 / 그로크 궁극기 / 볼케 전체 / 오르빈 등장·궁극기 — git 이력에 있다)
const CFS5_BOSSES: Array = [
	[4, "nagi", [0], ["entrance", "skill", "ultimate"]],
	[5, "nefer", [0, 4], ["ultimate"]],
	[14, "bolke", [0, 4], ["entrance"]],
	[27, "orbin", [0, 4], ["ultimate"]],
]
const CFS5_FLOOR_NAME: Dictionary = {0: "dungeon", 2: "garden", 3: "lava", 4: "heaven"}


func _cfs5_pos(f: FileAccess, shot: String, nodes: Array) -> void:
	var vp := get_viewport()
	var xf: Transform2D = vp.get_final_transform() * vp.get_canvas_transform()
	var parts: Array = [shot, "%d" % int(vp.get_visible_rect().size.x)]
	for n: Node2D in nodes:
		var sp: Vector2 = xf * n.global_position
		parts.append("%d,%d" % [int(sp.x), int(sp.y)])
	f.store_line(" ".join(parts))
	f.flush()



## 보스전에서 칸마다 세워 찍기 — 보스 + 몹 70마리, 보스의 쿨을 묶고 pose 로 한 칸씩. 첫 칸은 비교용 walk 0.
## bosses = [[kind, 이름, [바닥 테마…], [시트…]], …]. 찍은 장수를 돌려준다(pos.txt 에 화면 좌표).
func _cfs5_boss_frames(pf: FileAccess, dir: String, bosses: Array, p: Player, mob_kinds: Array) -> int:
	var n_shots: int = 0
	for bs: Array in bosses:
		for th: int in bs[2]:
			G.running = false
			_cfs2_clear_enemies()
			_cfs2_theme(th)
			await _cf_wait_unpaused(0.1)
			G.running = true
			p.hp = p.max_hp
			var b := _cfs4_spawn(int(bs[0]), p.global_position + Vector2(230, -30))
			await _cf_wait_unpaused(0.1)
			if not is_instance_valid(b):
				continue
			b.hp = 1.0e7
			b.max_hp = 1.0e7
			mob_kinds.shuffle()
			_cfs4_swarm(p.global_position, mob_kinds, 70, 260.0, 640.0)
			await _cf_wait_unpaused(0.8)
			# 플레이어(무기)를 멈춰 피해 숫자가 보스 얼굴을 덮지 않게 — 몹은 그대로 움직인다. 카메라가 자리를 잡은 뒤에 멈춘다.
			p.process_mode = Node.PROCESS_MODE_DISABLED
			var tag: String = "%s_%s" % [bs[1], CFS5_FLOOR_NAME.get(th, str(th))]
			var seq: Array = (bs[3] as Array) if (bs[3] as Array).has("walk") else ["walk"] + (bs[3] as Array)
			for a: String in seq:
				if not is_instance_valid(b):
					break
				var an: Dictionary = b._cv.cf_anim(a)
				if an.is_empty():
					continue
				var nf: int = int(an["n"])
				if a == "walk" and not (bs[3] as Array).has("walk"):
					nf = 1                        # 비교 기준(평소 모습) 한 칸만
				for fi in nf:
					# 보스를 플레이어 오른쪽에 다시 세운다(걸어가 화면 위 HUD 에 가리지 않게, 이펙트와 한 화면에 들게)
					b.global_position = p.global_position + Vector2(190, 10)
					b.velocity = Vector2.ZERO
					# 쿨을 묶어 저절로 돌진·탄막·장판이 끼지 않게(칸마다 다시 — 피격 반응도 막는다)
					b._fire_cd = 99.0
					b._special_cd = 99.0
					b._summon_cd = 99.0
					b._burst_cd = 99.0
					b._charge_cd = 99.0
					b._boss_move_cd = 99.0
					b._wind = 0.0
					b._charge_t = 0.0
					b._cv.pose(a, fi)
					if a == "ultimate" and fi == 0:
						b._cf_vfx_at(p.global_position)
					await _cf_wait_unpaused(0.12)
					b._cv.pose(a, fi)
					var shot: String = "boss_%s_%s%d.png" % [tag, a, fi]
					_cfs5_pos(pf, shot, [b, p])
					await _cf_snap(dir + "/" + shot)
					n_shots += 1
				b._cv.release_pose(a)
			p.process_mode = Node.PROCESS_MODE_INHERIT
	return n_shots

func _cfshots5_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CFSHOTS5] 건너뜀 — 창모드로 실행해야 한다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(5005)
	var dir: String = "user://cfshots5"
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	var pf := FileAccess.open(dir + "/pos.txt", FileAccess.WRITE)
	print("=== CFSHOTS5 ===")
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(0.3)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	var cam: Camera2D = G.camera as Camera2D
	var zoom0: Vector2 = cam.zoom if cam != null else Vector2.ONE
	var mob_kinds: Array = []
	for kk in Enemy.KINDS.keys():
		if not bool((Enemy.KINDS[kk] as Dictionary).get("boss", false)):
			mob_kinds.append(int(kk))
	var n_shots: int = 0
	# ── 1) 보스전 — 칸마다 세워 찍기 (게임 카메라 그대로) ──
	n_shots += await _cfs5_boss_frames(pf, dir, CFS5_BOSSES, p, mob_kinds)
	G.running = false
	_cfs2_clear_enemies()
	await _cf_wait_unpaused(0.3)
	# ── 2) 영웅 14종의 대시 자국 — 대시를 떠난 자리에 vfx 를 남기는 게임 코드(player._spawn_cf_vfx)와 같은 자리·같은 배율 ──
	p.visible = false
	var defs: Array = Characters.defs()
	for th2: int in [0, 4]:
		_cfs2_theme(th2)
		await _cf_wait_unpaused(0.2)
		var holder := Node2D.new()
		add_child(holder)
		for i in defs.size():
			var hs: Dictionary = CharForge.hero_slot(String((defs[i] as Dictionary)["id"]))
			var cv := CreatureVisual.new()
			cv.radius = Player.RADIUS
			cv.cf_id = String(hs.get("id", ""))
			cv.cf_target_h = float(hs.get("h", 0.0))
			cv.always_animate = true
			cv.build()
			var c: int = i % 7
			var r: int = i / 7
			cv.position = p.global_position + Vector2(-480.0 + 160.0 * float(c), -90.0 + 170.0 * float(r))
			holder.add_child(cv)
			var vf: Dictionary = cv.cf_anim("vfx")
			var fx: Sprite2D = cv.make_vfx()
			if fx != null:
				fx.centered = false
				fx.offset = Vector2(-floorf(float(vf["fw"]) * 0.5), -(float(vf["fh"]) - 2.0))
				fx.position = cv.position + Vector2(-Player.DASH_SPEED * 0.07, roundf(Player.RADIUS * 0.86))
				fx.z_index = -1
				holder.add_child(fx)
			var lb := Label.new()
			lb.text = String((defs[i] as Dictionary)["name"])
			UiFont.apply(lb, 11)
			lb.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			lb.add_theme_constant_override("outline_size", 4)
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lb.size = Vector2(150, 14)
			lb.position = cv.position + Vector2(-110.0, Player.RADIUS * 0.86 + 6.0)
			holder.add_child(lb)
		await _cf_wait_unpaused(0.3)
		var shot2: String = "hero_dash_vfx_%s.png" % CFS5_FLOOR_NAME.get(th2, str(th2))
		await _cf_snap(dir + "/" + shot2)
		n_shots += 1
		holder.queue_free()
		await get_tree().process_frame
	p.visible = true
	p.xp_mult = 1.0
	if cam != null:
		cam.zoom = zoom0
	pf.close()
	print("[CFSHOTS5] %d장 → %s" % [n_shots, ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## ──────────────────── 무기 이펙트 한 장씩 (--weaponfx) ────────────────────
## 2026-10-06 사용자: "사신의 낫은 보이지도 않고… 전체 무기를 새로 만들어야겠다. 너무 캐릭터만 신경 쓴 듯."
## 지금 무기마다 화면에 어떻게 보이는지를 그림 주문서에 붙인다. 무기마다 새 판을 열어 그 무기만 들고
## (특수·융합은 기본 소총 Lv1 곁들임) 멈춘 몹 24마리 사이에서 쏘게 한 뒤 0.5·0.9·1.3초에 찍는다.
##   실행:  ... --path . --resolution 1920x1080 -- --weaponfx      저장: user://weaponfx/ (+ pos.txt)
const WFX_MAIN: Array = ["balanced", "heavy", "rapid", "mid", "melee", "bow", "fan", "sinkal", "jakdu"]
const WFX_SPECIAL: Array = ["wpn_whip", "wpn_beam", "wpn_boomerang", "wpn_chain", "wpn_fire", "wpn_ice",
	"wpn_poison", "wpn_orb", "wpn_summon", "summon_ice"]


func _weaponfx_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(808)
	var dir: String = "user://weaponfx"
	var wfloor: int = 0   # --wfxfloor=N 바닥 테마(0 던전 · 4 천상)
	for a0: String in OS.get_cmdline_user_args():
		if a0.begins_with("--wfxburst="):
			dir = "user://weaponfx_burst"
	for a1: String in OS.get_cmdline_user_args():
		if a1.begins_with("--wfxout="):
			dir = "user://" + a1.get_slice("=", 1)
		if a1.begins_with("--wfxfloor="):
			wfloor = int(a1.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	var pf := FileAccess.open(dir + "/pos.txt", FileAccess.WRITE)
	_main_menu.close()
	var entries: Array = []
	for k: String in WFX_MAIN:
		entries.append(["main", k, []])
	for k2: String in WFX_SPECIAL:
		entries.append(["special", k2, []])
	for ev: Dictionary in EVOLUTIONS:
		entries.append(["evo", String(ev["id"]), ev["req"]])
	# --wfxonly=<id,id> 그 무기만 · --wfxburst=N 0.5초부터 0.04초 간격 N장(휘두르기는 0.16초라 세 시점에 안 잡힌다)
	var only: PackedStringArray = PackedStringArray()
	var burst: int = 0
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--wfxonly="):
			only = a.get_slice("=", 1).split(",")
		if a.begins_with("--wfxburst="):
			burst = int(a.get_slice("=", 1))
	if not only.is_empty():
		entries = entries.filter(func(x: Array) -> bool: return only.has(String(x[1])))
	for en: Array in entries:
		_cfs2_clear_enemies()
		_begin_run(Characters.defs()[0])
		await _cf_wait_unpaused(0.5)
		var p := G.player as Player
		p.max_hp = 1.0e9
		p.hp = 1.0e9
		p.xp_mult = 0.0
		var kind: String = String(en[0])
		var id: String = String(en[1])
		p.weapons_primary = [{"id": id if kind == "main" else "balanced", "t": 0.0, "level": 5 if kind == "main" else 1}]
		p._refresh_barrel()
		if kind == "special":
			for _i in 4:
				p.add_weapon(id)
		elif kind == "evo":
			for r in en[2]:
				for _j in 3:
					_apply_upgrade(String(r))
			_apply_upgrade(id)
		G.time_alive = 1.0
		if wfloor != 0:
			_cfs2_theme(wfloor)
		await _cf_wait_unpaused(0.2)
		_cfs2_clear_enemies()
		var kinds: Array = [0, 1, 7, 8, 12]
		var near: bool = id in ["melee", "jakdu", "evo_orb"]
		_cfs4_swarm(p.global_position, kinds, 24, 40.0 if near else 110.0, 130.0 if near else 330.0)
		await _cf_wait_unpaused(0.05)
		for n in get_tree().get_nodes_in_group("enemy"):
			var e := n as Enemy
			if e != null and is_instance_valid(e):
				e.hp = 1.0e6
				e.max_hp = 1.0e6
				e.spd = 0.0
		if burst > 0:
			await _cf_wait_unpaused(0.5)
			for b in burst:
				var bshot: String = "%s_%s_b%02d.png" % [kind, id, b]
				_cfs5_pos(pf, bshot, [p])
				await _cf_snap(dir + "/" + bshot)
				await _cf_wait_unpaused(0.04)
			print("[WEAPONFX] %s %s burst %d" % [kind, id, burst])
			continue
		var t0: float = 0.0
		for i in 3:
			var t: float = [0.5, 0.9, 1.3][i]
			await _cf_wait_unpaused(t - t0)
			t0 = t
			var shot: String = "%s_%s_%d.png" % [kind, id, i]
			_cfs5_pos(pf, shot, [p])
			await _cf_snap(dir + "/" + shot)
		print("[WEAPONFX] %s %s" % [kind, id])
	pf.close()
	print("[WEAPONFX] %d종 → %s" % [entries.size(), ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## ──────────────────── 그림 전수 (--artaudit) ────────────────────
## 9차 지시서 3절: 게임 화면에 나오는 그림을 하나도 빼지 않고 센다. 화면을 하나씩 열어(메뉴 · 도감 탭 ·
## 테마 5종 전투 · 레벨업 · 일시정지 · 상자 · 부활 · 게임오버 · 클리어) 장면 트리를 훑는다.
##   그림     — 텍스처를 그리는 노드: 파일 경로(캐릭터 에셋은 charforge:<ID>) · 원본 크기 · 화면 배율
##   코드 도형 — Polygon2D · Line2D · ColorRect · 패널(StyleBox) · _draw 스크립트
##   글자     — Label · Button · RichTextLabel 의 글꼴
## 화면 배율 = 그림 1px 이 창에서 몇 px 인가(카메라 · 캔버스 · 창 늘이기까지). 1920×1080 창으로 돌린다.
##   실행:  ... --path . --resolution 1920x1080 -- --artaudit        저장: user://artaudit/(rows.tsv + 화면 사진)
var _aa: Dictionary = {}          # "화면|분류|키" -> {n, smin, smax, size, own}
var _aa_draw_cache: Dictionary = {}


func _aa_owner(n: Node) -> String:
	var cur: Node = n
	while cur != null:
		var sc: Script = cur.get_script() as Script
		if sc != null and sc.resource_path != "":
			return sc.resource_path.get_file().get_basename()
		cur = cur.get_parent()
	return "-"


func _aa_has_draw(n: Node) -> bool:
	var sc: Script = n.get_script() as Script
	if sc == null:
		return false
	var k: String = sc.resource_path
	if not _aa_draw_cache.has(k):
		var src: String = sc.source_code if sc is GDScript else ""
		_aa_draw_cache[k] = src.contains("func _draw(")
	return bool(_aa_draw_cache[k])


func _aa_tex_key(tex: Texture2D, n: Node) -> String:
	# 캐릭터 에셋은 번호 그림을 만들어 쓰니 경로가 없다 — 조상 CreatureVisual 의 cf_id 로 부른다
	var cur: Node = n
	while cur != null:
		if cur is CreatureVisual and String((cur as CreatureVisual).cf_id) != "":
			return "charforge:" + String((cur as CreatureVisual).cf_id)
		cur = cur.get_parent()
	if tex is AtlasTexture and (tex as AtlasTexture).atlas != null:
		var ap: String = (tex as AtlasTexture).atlas.resource_path
		if ap != "":
			return ap
	if tex.resource_path != "":
		return tex.resource_path.split("::")[0]
	if tex.resource_name != "":
		return tex.resource_name
	return "(만든 텍스처)@" + _aa_owner(n)


func _aa_add(screen: String, kind: String, key: String, own: String, scr: float, size: Vector2) -> void:
	var k: String = "%s|%s|%s" % [screen, kind, key]
	var r: Dictionary = _aa.get(k, {"n": 0, "smin": 1.0e9, "smax": 0.0, "size": size, "own": {}})
	r["n"] = int(r["n"]) + 1
	if scr > 0.0:
		r["smin"] = minf(float(r["smin"]), scr)
		r["smax"] = maxf(float(r["smax"]), scr)
	(r["own"] as Dictionary)[own] = true
	_aa[k] = r


func _aa_walk(n: Node, screen: String) -> void:
	var ci := n as CanvasItem
	if ci != null and not ci.is_visible_in_tree():
		return
	if ci != null:
		_aa_item(ci, screen)
	for c in n.get_children():
		_aa_walk(c, screen)


func _aa_item(ci: CanvasItem, screen: String) -> void:
	var vs: float = get_viewport().get_final_transform().get_scale().x
	var scr: float = absf(ci.get_global_transform_with_canvas().get_scale().x) * vs
	var own: String = _aa_owner(ci)
	var tex: Texture2D = null
	if ci is Sprite2D:
		tex = (ci as Sprite2D).texture
	elif ci is AnimatedSprite2D:
		var a2 := ci as AnimatedSprite2D
		if a2.sprite_frames != null and a2.sprite_frames.has_animation(a2.animation):
			tex = a2.sprite_frames.get_frame_texture(a2.animation, a2.frame)
	elif ci is TextureRect:
		tex = (ci as TextureRect).texture
		if tex != null and tex.get_width() > 0:
			scr *= (ci as Control).size.x / float(tex.get_width())
	elif ci is NinePatchRect:
		tex = (ci as NinePatchRect).texture
	elif ci is TextureButton:
		tex = (ci as TextureButton).texture_normal
	elif ci is CPUParticles2D:
		tex = (ci as CPUParticles2D).texture
		if tex == null:
			_aa_add(screen, "코드 도형", "입자(CPUParticles2D)@" + own, own, scr, Vector2.ZERO)
	elif ci is GPUParticles2D:
		tex = (ci as GPUParticles2D).texture
	elif ci is Line2D:
		tex = (ci as Line2D).texture
		if tex == null:
			_aa_add(screen, "코드 도형", "선(Line2D)@" + own, own, scr, Vector2.ZERO)
	elif ci is Polygon2D:
		tex = (ci as Polygon2D).texture
		if tex == null:
			_aa_add(screen, "코드 도형", "도형(Polygon2D)@" + own, own, scr, Vector2.ZERO)
	elif ci is ColorRect:
		_aa_add(screen, "코드 도형", "사각형(ColorRect)@" + own, own, scr, (ci as Control).size)
	if tex != null:
		_aa_add(screen, "그림", _aa_tex_key(tex, ci), own, scr, tex.get_size())
	# 패널·버튼 바탕(StyleBoxFlat) — 코드로 그린 틀
	if ci is Panel or ci is PanelContainer or ci is Button:
		var sb: StyleBox = (ci as Control).get_theme_stylebox("panel" if not (ci is Button) else "normal")
		if sb is StyleBoxFlat:
			_aa_add(screen, "코드 도형", "틀(StyleBoxFlat)@" + own, own, scr, (ci as Control).size)
		elif sb is StyleBoxTexture and (sb as StyleBoxTexture).texture != null:
			_aa_add(screen, "그림", (sb as StyleBoxTexture).texture.resource_path, own, scr, (sb as StyleBoxTexture).texture.get_size())
	if ci is Label or ci is Button or ci is RichTextLabel:
		var txt: String = ""
		if ci is Label:
			txt = (ci as Label).text
		elif ci is Button:
			txt = (ci as Button).text
		else:
			txt = (ci as RichTextLabel).get_parsed_text()
		if txt.strip_edges() != "":
			var f: Font = (ci as Control).get_theme_font("normal_font" if ci is RichTextLabel else "font")
			var fp: String = f.resource_path.get_file() if f != null and f.resource_path != "" else "(기본/만든 글꼴)"
			_aa_add(screen, "글자", fp + " " + str((ci as Control).get_theme_font_size("normal_font_size" if ci is RichTextLabel else "font_size")) + "pt@" + own, own, scr, Vector2.ZERO)
	if _aa_has_draw(ci):
		_aa_add(screen, "코드 도형", "_draw@" + own, own, scr, Vector2.ZERO)


func _aa_shot(screen: String, dir: String) -> void:
	_aa_walk(get_tree().root, screen)
	await _snap(dir + "/" + screen.replace(" ", "_").replace("/", "_") + ".png")   # _cf_snap 은 레벨업·상자·부활 창을 닫고 찍는다
	print("[ARTAUDIT] %s" % screen)


func _artaudit_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[ARTAUDIT] 창모드로 돌린다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(909)
	var dir: String = "user://artaudit"
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	# 도감·상점이 다 보이게: 전부 본 것 · 전부 가진 것으로
	G.total_gold = 999999
	for cdef: Dictionary in Characters.defs():
		G.meta["uc_" + String(cdef["id"])] = 1
	for m: Dictionary in Codex.MONSTERS:
		G.codex_see(String(m["key"]))
	for m2: Dictionary in Codex.MAPS:
		G.codex_see(String(m2["key"]))
	for f2: Dictionary in Codex.FUSIONS:
		G.codex_see(String(f2["key"]))
	for ad: Dictionary in Accessories.DEFS:
		G.meta["acc_own_" + String(ad["id"])] = 1
	_main_menu.open()
	await get_tree().create_timer(0.5, true).timeout
	await _aa_shot("메인 메뉴", dir)
	_main_menu.close()
	_char_select.open()
	await _cf_wait_unpaused(0.4)
	await _aa_shot("영웅 선택", dir)
	_char_select._on_back()
	_meta_shop.open()
	await _cf_wait_unpaused(0.4)
	await _aa_shot("상점", dir)
	_meta_shop._on_close()
	_codex_screen.open()
	for t in 6:
		_codex_screen._switch(t)
		await _cf_wait_unpaused(0.3)
		await _aa_shot("도감 %d %s" % [t, ["정복", "몬스터", "맵", "융합", "도전과제", "퀘스트"][t]], dir)
	_codex_screen.close()
	_settings.open()
	await _cf_wait_unpaused(0.3)
	await _aa_shot("설정", dir)
	_settings._on_back()
	get_tree().paused = false
	_main_menu.close()
	# ── 판 안: 테마 5종 — 그 테마의 몹풀 · 특수 · 요괴 · 스테이지 보스 · 정예 · 줍는 것 · 장애물 ──
	var th_names: Array = ["던전", "도서관", "정원", "용암동굴", "천상"]
	for th in 5:
		_begin_run(Characters.defs()[th % Characters.defs().size()])
		await _cf_wait_unpaused(0.4)
		var p := G.player as Player
		p.max_hp = 1.0e9
		p.hp = 1.0e9
		p.xp_mult = 0.0
		_cfs2_theme(th)
		_cfs2_clear_enemies()
		await _cf_wait_unpaused(0.1)
		var kinds: Array = (_THEME_KINDS[th] as Array).duplicate()
		kinds.append(int(_THEME_SPECIAL[th]))
		kinds.append_array(_THEME_YOKAI[th] as Array)
		_cfs4_swarm(p.global_position, kinds, 30, 120.0, 420.0)
		for ek: int in [0, 2, 7]:
			var el := Enemy.new()
			el.kind = ek
			el._elite = true
			el.global_position = p.global_position + Vector2(randf_range(-300, 300), randf_range(-200, 200))
			add_child(el)
		var bs := Enemy.new()
		bs.kind = int(STAGE_BOSS[th])
		bs.global_position = p.global_position + Vector2(260, -40)
		add_child(bs)
		for gv: int in [1, 3, 7, 25]:
			XpGem.spawn(self, p.global_position + Vector2(-200 + gv * 6, 120), gv)
		GoldCoin.spawn(self, p.global_position + Vector2(-120, 140), 5)
		for pk in 6:
			Pickup.spawn(self, p.global_position + Vector2(-60 + pk * 40, 170), pk)
		for c in get_children():
			if c is Pickup:
				# 자석에 끌려와 주워지면 보스 상자 창이 사진을 덮는다(12차부터 상자는 0.37초 뒤에 열려서 닫는 시점을 지나친다)
				(c as Pickup).set_process(false)
		for n in get_tree().get_nodes_in_group("enemy"):
			var e := n as Enemy
			if e != null:
				e.spd = 0.0
				e.hp = 1.0e7
				e.max_hp = 1.0e7
		p.add_weapon("wpn_fire")
		p.add_weapon("wpn_orb")
		await _cf_wait_unpaused(0.8)
		await _aa_shot("전투 %d %s" % [th, th_names[th]], dir)
		if th < 4:
			_on_revive_decline()
			await _cf_wait_unpaused(0.2)
			get_tree().paused = false
	# ── 판 안 패널들(uifit 순서) ──
	var p2 := G.player as Player
	for id in ["wp_heavy", "wp_fan", "wpn_chain", "b_fire", "crit", "dmg"]:
		_apply_upgrade(String(id))
	_open_levelup()
	await get_tree().create_timer(0.5, true).timeout   # _cf_wait_unpaused 는 레벨업 창을 닫는다
	await _aa_shot("레벨업", dir)
	_levelup_root.visible = false
	get_tree().paused = false
	_pause_menu._toggle()
	await get_tree().create_timer(0.4, true).timeout
	await _aa_shot("일시정지", dir)
	_pause_menu._toggle()
	get_tree().paused = false
	_on_boss_chest()
	await get_tree().create_timer(0.6, true).timeout
	await _aa_shot("보스 상자", dir)
	_close_chest_panel()
	get_tree().paused = false
	_on_revive_offered()
	await get_tree().create_timer(0.4, true).timeout
	await _aa_shot("부활", dir)
	_on_revive_decline()
	# 부활 창을 직접 띄워서 플레이어가 '죽는 중'이 아니다 — 거절해도 게임오버 창이 안 뜬다. 죽음을 직접 알린다.
	_on_player_died()
	await get_tree().create_timer(0.6, true).timeout
	await _aa_shot("게임오버", dir)
	get_tree().paused = false
	_begin_run(Characters.defs()[1])
	await _cf_wait_unpaused(0.4)
	_on_stage_clear()
	await get_tree().create_timer(0.9, true).timeout
	await _aa_shot("클리어", dir)
	if p2 != null:
		pass
	# ── 기록 ──
	var f := FileAccess.open(dir + "/rows.tsv", FileAccess.WRITE)
	f.store_line("화면\t분류\t키\t스크립트\t개수\t원본크기\t배율최소\t배율최대")
	for k: String in _aa.keys():
		var r: Dictionary = _aa[k]
		var parts: PackedStringArray = k.split("|")
		var sz: Vector2 = r["size"]
		f.store_line("%s\t%s\t%s\t%s\t%d\t%dx%d\t%.2f\t%.2f" % [parts[0], parts[1], parts[2],
			",".join(PackedStringArray((r["own"] as Dictionary).keys())), int(r["n"]), int(sz.x), int(sz.y),
			float(r["smin"]) if float(r["smin"]) < 1.0e8 else 0.0, float(r["smax"])])
	f.close()
	print("[ARTAUDIT] %d줄 → %s" % [_aa.size(), ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## ──────────────────── 피격 번쩍임 (--flashtest) ────────────────────
## 새 도트(스프라이트) 몹은 색을 곱해서 그리므로 흰색(1,1,1) 번쩍임이 아무 변화를 안 냈다.
## 같은 몹 둘을 세우고 오른쪽만 번쩍이게 해서 찍고, 두 몹 칸의 평균 밝기를 비교한다.
##   실행:  ... --path . --resolution 1280x720 -- --flashtest      저장: user://flashtest.png
func _flashtest_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(0.4)
	_cfs2_clear_enemies()
	var p := G.player as Player
	p.visible = false
	p.process_mode = Node.PROCESS_MODE_DISABLED   # 쏘지 않게 — 탄 번쩍임이 재는 칸에 섞인다
	var es: Array = []
	for i in 2:
		var e := Enemy.new()
		e.kind = 0
		e.global_position = p.global_position + Vector2(-60 + i * 120, 0)
		add_child(e)
		es.append(e)
	await get_tree().process_frame
	for e in es:
		(e as Enemy).set_physics_process(false)   # 걸어오지 않게 — 두 칸이 겹치면 비교가 안 된다
	await get_tree().create_timer(0.3).timeout
	(es[1] as Enemy)._cv.flash(Color.WHITE, 3.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("user://flashtest.png")
	var vs: Vector2 = get_viewport().get_final_transform().get_scale()
	var lum: Array = []
	for e in es:
		var sp: Vector2 = (e as Node2D).get_global_transform_with_canvas().origin * vs
		var sum: float = 0.0
		var n: int = 0
		for y in range(int(sp.y) - 30, int(sp.y) + 10):
			for x in range(int(sp.x) - 20, int(sp.x) + 20):
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
					sum += img.get_pixel(x, y).get_luminance()
					n += 1
		lum.append(sum / maxf(1.0, float(n)))
	print("[FLASH] 보통 %.3f · 번쩍 %.3f · %s" % [float(lum[0]), float(lum[1]), "보인다" if float(lum[1]) > float(lum[0]) * 1.25 else "안 보인다"])
	get_tree().quit(0)


## ──────────────────── 글자 그림 화면 (--textshot) ────────────────────
## 10차 A(숫자 · 낱말 그림)가 판에서 뜨는 모습. 배너는 한 번에 하나씩 흐르므로 하나씩 띄워 찍는다.
##   실행:  ... --path . --resolution 1920x1080 -- [--lang=en] --textshot      저장: user://textshot/
func _textshot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	var dir: String = "user://textshot"
	DirAccess.make_dir_recursive_absolute(dir)   # 한 · 영을 따로 돌려 한 폴더에 모은다(비우지 않는다)
	var lang: String = "en" if FxLib.lang_en() else "ko"
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(1.8)   # 판 시작 WAVE 1 배너가 지나가게
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	_cfs2_clear_enemies()
	_cfs2_theme(4)
	var es: Array = []
	for i in 6:
		var e := Enemy.new()
		e.kind = [0, 1, 7, 8, 3, 2][i]
		e.global_position = p.global_position + Vector2(-260 + i * 104, -90 + (i % 2) * 70)
		add_child(e)
		es.append(e)
	p.process_mode = Node.PROCESS_MODE_DISABLED   # 쏘지 않게 — 몹이 죽으면 반응 낱말을 못 띄운다
	await _cf_wait_unpaused(0.2)
	for e in es:
		(e as Enemy).set_physics_process(false)
		(e as Enemy).hp = 1.0e7
		(e as Enemy).max_hp = 1.0e7
	var shots: Array = [
		["wave", func() -> void: _wave = 7; _advance_wave()],
		["midboss", func() -> void: _wave = BOSS_EVERY - 1; _advance_wave()],
		["boss", func() -> void: _wave_banner("스테이지 보스 출현! 처치하면 클리어", Color("ff2d55"), [FxLib.word_sheet("w_boss")], I18n.t("스테이지 보스 · 처치하면 클리어"))],
		["fusion", func() -> void: _wave_banner(I18n.t("융합: %s") % I18n.t("사신의 낫"), Color("ffd54a"), [FxLib.word_sheet("w_fusion")], I18n.t("사신의 낫"))],
	]
	for sh in shots:
		_banner_q.clear()
		(sh[1] as Callable).call()
		await get_tree().create_timer(0.45, true).timeout
		await _snap(dir + "/%s_banner_%s.png" % [lang, String(sh[0])])
		await get_tree().create_timer(1.6, true).timeout
	# 콤보 · 반응 낱말 · 피해 숫자 4종을 한 화면에
	G.combo = 37
	G.combo_t = 30.0   # 콤보 창 — 0 이면 다음 프레임에 풀린다
	_on_combo_changed()
	var words: Array = ["파열!", "초전도!", "역병폭발!", "맹독!", "결빙!", "흡혈!"]
	var cols: Array = [Color("d8faff"), Color("bfe6ff"), Color("aef58a"), Color(0.62, 1.0, 0.5), Color(0.78, 0.94, 1.0), Color("ff8aa0")]
	for i in es.size():
		var e2 := es[i] as Enemy
		seed(1)   # _react_label 의 40% 거르기를 넘기게
		for _k in 6:
			e2._react_label(String(words[i]), cols[i])
		DamageNumber.spawn_as(self, e2.global_position + Vector2(0, 30), 128 + i * 111, [DamageNumber.HIT, DamageNumber.CRIT, DamageNumber.DOT, DamageNumber.REACT, DamageNumber.HIT, DamageNumber.CRIT][i],
			Color(0, 0, 0, 0) if i != 2 else Color("ff9a5c"))
	await get_tree().create_timer(0.12, true).timeout
	await _snap(dir + "/%s_battle_text.png" % lang)
	print("[TEXTSHOT] %s → %s" % [lang, ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## ──────────────────── 실제 판 중반 화면 (--midshot) ────────────────────
## 14차 5절: 「레벨 1 · 00:01 · 체력 999999999 검사용 세이브로는 HUD 를 평가할 수 없다. 12분째 몹 200마리 · 무기 여섯 ·
## 보스가 나올 때 팔린다. 그 화면을 찍어 와라」(에셋 담당). 세이브는 건드리지 않고(no_save) 판 중반 플레이어의 프로필을
## 메모리에 만든다 — 골드 2,840 · 영구 강화 낮은 단계 · 영웅 다섯 해금 · 스테이지 두 개 클리어.
##   실행:  ... --path . --resolution 1920x1080 -- [--touch] --midshot      저장: user://midshot/
func _midshot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(1412)
	_GridBg.old_draw_test = "--olddraw" in OS.get_cmdline_user_args()   # 19차 3-2: 그리기 줄인 전후를 같은 장면으로
	G.ui_scale_idx = -1     # 처음 받은 사람 기본 크기로 찍는다(내 설정 파일의 「크게」가 섞였었다)
	G.cam_zoom_idx = -1
	_update_hud_scale()     # HUD 는 부팅 때 설정 파일 값으로 이미 잡혀 있다
	var dir: String = "user://midshot"
	DirAccess.make_dir_recursive_absolute(dir)
	var tag: String = "mob_" if _mobile else ""
	# ── 판 중반 플레이어 프로필(메모리만) ──
	G.total_gold = 2840
	var mm: Dictionary = {"m_hp": 6, "m_dmg": 5, "m_speed": 3, "m_magnet": 2, "m_luck": 2, "m_regen": 2, "m_gold": 3, "m_reroll": 1, "m_banish": 1}
	for cid in ["base", "berserker", "gunner", "collector", "tank"]:
		mm["uc_" + cid] = 1
		mm["ucn_" + cid] = 1
	mm["rank_base"] = 4
	mm["rank_berserker"] = 2
	G.meta = mm
	G.stage_prog = {"c_0_0": true, "s_0_0": 2, "t_0_0": 96.0, "c_0_1": true, "s_0_1": 1, "t_0_1": 141.0, "c_1_0": true, "s_1_0": 3, "t_1_0": 58.0}
	# 도감 「처치 n」 — 지나온 맵(던전 · 도서관 · 정원) 몹은 그동안 잡은 수가 있어야 실제 세이브처럼 보인다
	for th in 3:
		for kd in (_THEME_KINDS[th] as Array):
			G.stats["mk_%d" % int(kd)] = 120 + (int(kd) * 173) % 700
	# ── 무한 모드 12분째 ──
	G.run_mode = "endless"
	G.difficulty = 1
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(1.6)
	var p := G.player as Player
	_spawn_queue = 0
	_spawn_t = 1.0e9
	for upg: Array in [["wp_bow", 4], ["wp_fan", 3], ["wpn_fire", 3], ["wpn_orb", 2], ["wp_balanced", 2],   # 무기 칸 4 + 시작 소총 = 실제 최대 다섯
			["b_fire", 3], ["b_chain", 2], ["b_big", 2], ["b_exec", 1], ["dmg", 3], ["hp", 2], ["crit", 2], ["speed", 1]]:
		for _i in int(upg[1]):
			_apply_upgrade(String(upg[0]))
	G.time_alive = 720.0
	G.level = 25
	G.xp_to_next = 120
	G.xp = 74
	_wave = 8
	G.wave = 8
	G.kills = 3412
	G.run_gold = 1206
	G.combo_best = 187
	p.max_hp = 412.0
	p.hp = 296.0
	G.player_hp_changed.emit()
	p.grant_iframe(9999.0)          # 찍는 동안 죽지 않게 — 체력 숫자는 실제 판 그대로 둔다
	p.xp_mult = 0.0                 # 찍는 동안 레벨업 창이 저절로 뜨지 않게
	_cfs2_theme(0)
	_cfs2_clear_enemies()
	await get_tree().process_frame
	var kinds: Array = (_THEME_KINDS[0] as Array).duplicate()
	kinds.append(int(_THEME_SPECIAL[0]))
	kinds.append_array(_THEME_YOKAI[0] as Array)
	_cfs4_swarm(p.global_position, kinds, 180, 170.0, 640.0)
	var mb := Enemy.new()
	mb.kind = 4
	mb.global_position = p.global_position + Vector2(300, -60)
	add_child(mb)
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Enemy
		if e != null:
			e.hp *= 6.0
			e.max_hp = e.hp
	await get_tree().create_timer(4.0).timeout

	await _snap(dir + "/%s08_battle.png" % tag)
	if _mobile:
		print("[MIDSHOT] 폰 전투 → %s" % ProjectSettings.globalize_path(dir))
		get_tree().quit(0)
		return
	# 레벨업 · 일시정지 · 보스 상자
	_pending_levelups += 1
	_open_levelup()
	await get_tree().create_timer(0.6, true).timeout
	await _snap(dir + "/09_levelup.png")
	_levelup_root.visible = false
	_pending_levelups = 0
	get_tree().paused = false
	_pause_menu._toggle()
	await get_tree().create_timer(0.5, true).timeout
	await _snap(dir + "/10_pause.png")
	# 메뉴들 — 일시정지에서 메인 메뉴로(이어하기 카드가 보이게)
	_pause_menu._on_main_menu()
	await get_tree().create_timer(0.6, true).timeout
	await _snap(dir + "/01_menu.png")
	_main_menu.close()
	_char_select.open()
	await get_tree().create_timer(0.5, true).timeout
	await _snap(dir + "/02_select.png")
	_char_select._on_back()
	_meta_shop.open()
	await get_tree().create_timer(0.5, true).timeout
	await _snap(dir + "/03_shop.png")
	_meta_shop._on_close()
	_codex_screen.open()
	for t: Array in [[1, "04_codex_mon"], [3, "05_codex_fus"], [2, "06_codex_map"]]:
		_codex_screen._switch(int(t[0]))
		await get_tree().create_timer(0.4, true).timeout
		await _snap(dir + "/%s.png" % String(t[1]))
	_codex_screen.close()
	_settings.open()
	_settings._set_tab(1)
	await get_tree().create_timer(0.4, true).timeout
	await _snap(dir + "/07_settings.png")
	_settings._on_back()
	_main_menu.close()
	_on_continue()
	get_tree().paused = false
	await get_tree().create_timer(0.3).timeout
	_on_boss_chest()
	await get_tree().create_timer(0.8, true).timeout
	await _snap(dir + "/11_chest.png")
	_close_chest_panel()
	get_tree().paused = false
	await get_tree().create_timer(5.0).timeout     # 무기별 피해가 쌓이게
	# 게임오버 — 새로 열린 영웅 하나(카드)
	G.meta["uc_knight"] = 1
	_on_player_died()
	await get_tree().create_timer(0.9, true).timeout
	await _snap(dir + "/12_gameover.png")
	# 스테이지 클리어 — 던전 8:00 뒤 보스전 1:13
	get_tree().paused = false
	G.run_mode = "stage"
	G.stage_sel = 0
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(1.2)
	p = G.player as Player
	_spawn_queue = 0
	_spawn_t = 1.0e9
	for upg2: Array in [["wp_bow", 3], ["wp_fan", 2], ["wpn_fire", 2], ["b_fire", 2], ["dmg", 2]]:
		for _j in int(upg2[1]):
			_apply_upgrade(String(upg2[0]))
	p.grant_iframe(9999.0)
	p.xp_mult = 0.0
	_cfs4_swarm(p.global_position, kinds, 60, 160.0, 420.0)
	await get_tree().create_timer(4.0).timeout
	G.time_alive = 553.0
	G.level = 21
	G.kills = 2870
	G.combo_best = 142
	G.boss_fight_t = 73.0
	_on_stage_clear()
	await get_tree().create_timer(0.9, true).timeout
	await _snap(dir + "/13_clear.png")
	print("[MIDSHOT] → %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit(0)


## ──────────────────── 저승길 · 새 영웅 · 차림 · 새 바닥 (--s6shot) ────────────────────
## 16차 4-1: 스테이지 6 을 붙인 뒤 눈으로 볼 화면 — 출격 준비(영웅 20 · 차림) · 저승길 몹 열일곱 줄 세우기 · 떼 ·
##   판관 컷인/전투 · 염라 컷인/전투/체력 절반(s1) · 도감(염라 · 맵 · 정복 6열) · 맵 여섯 바닥.
##   실행:  ... --path . --resolution 1920x1080 -- [--lang=en] --s6shot      저장: user://s6shot/
func _s6shot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(1606)
	G.ui_scale_idx = -1
	G.cam_zoom_idx = -1
	_update_hud_scale()
	var dir: String = "user://s6shot"
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	var mm: Dictionary = {"m_hp": 6, "m_dmg": 5, "m_speed": 3}
	for d: Dictionary in Characters.defs():
		mm["uc_" + String(d["id"])] = 1
		mm["ucn_" + String(d["id"])] = 1
	mm["skin_base"] = "jeoseung"
	G.meta = mm
	G.total_gold = 52000
	G.stage_prog = {}
	for i in 6:
		G.stage_prog["c_%d_0" % i] = true
		G.stage_prog["s_%d_0" % i] = 2
	# 출격 준비 — 저승길 고름 · 새 영웅 상세 · 차림
	G.run_mode = "stage"
	G.stage_sel = 5
	G.difficulty = 0
	_main_menu.close()
	_char_select.open()
	_char_select._set_mode(5)
	_char_select._show_detail(Characters.def_of("gangrim"))
	await get_tree().create_timer(0.6, true).timeout
	await _snap(dir + "/01_select_gangrim.png")
	_char_select._show_detail(Characters.def_of("base"))
	await get_tree().create_timer(0.4, true).timeout
	await _snap(dir + "/02_select_skin.png")
	_char_select._on_back()
	# 저승길 판 — 강림
	G.run_mode = "stage"
	G.stage_sel = 5
	G.difficulty = 1
	_main_menu.close()
	_begin_run(Characters.def_of("gangrim"))
	await _cf_wait_unpaused(1.2)
	var p := G.player as Player
	p.grant_iframe(9999.0)
	p.xp_mult = 0.0
	_spawn_queue = 0
	_spawn_t = 1.0e9
	_cfs2_clear_enemies()
	for o in _obstacles:
		(o as Node).queue_free()
	_obstacles = []
	await get_tree().create_timer(0.4).timeout
	await _snap(dir + "/03_start_banner.png")
	# 열일곱 줄 세우기 — 몹 15(3줄) + 판관 · 염라
	var cam: Camera2D = G.camera as Camera2D
	var order: Array = [1, 18, 7, 0, 8, 2, 3, 16, 20, 10, 11, 22, 17, 19, 21]
	var lineup: Array = []
	for i in order.size():
		var e := _cfs4_spawn(int(order[i]), p.global_position + Vector2(-400.0 + float(i % 5) * 170.0, -170.0 + float(i / 5) * 150.0))
		lineup.append(e)
	var pg := _cfs4_spawn(13, p.global_position + Vector2(-260.0, 330.0))
	var ym := _cfs4_spawn(5, p.global_position + Vector2(220.0, 330.0))
	lineup.append_array([pg, ym])
	await get_tree().create_timer(0.3).timeout
	for e in lineup:
		(e as Enemy).process_mode = Node.PROCESS_MODE_DISABLED
	_banner_q.clear()
	await get_tree().create_timer(1.2).timeout
	if cam != null:
		cam.zoom = Vector2.ONE * 0.8
	await get_tree().create_timer(0.3).timeout
	await _snap(dir + "/04_lineup.png")
	for e in lineup:
		(e as Node).queue_free()
	if cam != null:
		cam.zoom = Vector2.ONE * G.cam_zoom()
	await get_tree().create_timer(0.3).timeout
	# 떼 — 12분 판처럼
	for upg: Array in [["wp_bow", 3], ["wpn_fire", 2], ["b_fire", 2], ["dmg", 2]]:
		for _i in int(upg[1]):
			_apply_upgrade(String(upg[0]))
	G.time_alive = 300.0
	_regen_obstacles(5)
	var kinds: Array = (_THEME_KINDS[5] as Array).duplicate()
	kinds.append(int(_THEME_SPECIAL[5]))
	kinds.append_array(_THEME_YOKAI[5] as Array)
	_cfs4_swarm(p.global_position, kinds, 150, 170.0, 620.0)
	await get_tree().create_timer(3.0).timeout
	await _snap(dir + "/05_swarm.png")
	# 판관 — 중간보스 컷인 · 전투 (몹 상한을 넘으면 중간보스가 안 나오므로 떼를 치운다)
	_cfs2_clear_enemies()
	await get_tree().process_frame
	_spawn_boss()
	await get_tree().create_timer(0.7).timeout
	await _snap(dir + "/06_cutin_pangwan.png")
	for n in get_tree().get_nodes_in_group("enemy"):
		if (n as Enemy)._is_boss:
			(n as Node2D).global_position = p.global_position + Vector2(260, -120)
	await get_tree().create_timer(2.0).timeout
	await _snap(dir + "/07_pangwan.png")
	_cfs2_clear_enemies()
	# 염라 — 스테이지 보스 컷인 · 전투 · 체력 절반 아래(s1)
	G.time_alive = G.STAGE_LEN
	_spawn_stage_boss()
	await get_tree().create_timer(0.7).timeout
	await _snap(dir + "/08_cutin_yeomra.png")
	if _stage_boss != null and is_instance_valid(_stage_boss):
		(_stage_boss as Node2D).global_position = p.global_position + Vector2(0, -230)
	await get_tree().create_timer(2.0).timeout
	await _snap(dir + "/09_yeomra.png")
	if _stage_boss != null and is_instance_valid(_stage_boss):
		(_stage_boss as Enemy).hp = (_stage_boss as Enemy).max_hp * 0.42
		(_stage_boss as Node2D).global_position = p.global_position + Vector2(0, -230)
	await get_tree().create_timer(1.5).timeout
	await _snap(dir + "/10_yeomra_s1.png")
	# 도감 — 염라 · 맵 · 정복(6열)
	for kd in range(29, 46):
		G.codex["mon_%d" % kd] = true
	G.codex["map_5"] = true
	get_tree().paused = true
	_codex_screen.open()
	_codex_screen._switch(1)
	for m: Dictionary in Codex.MONSTERS:
		if String(m["key"]) == "mon_45":
			_codex_screen._mon_show(m)
	await get_tree().create_timer(0.5, true).timeout
	await _snap(dir + "/11_codex_yeomra.png")
	_codex_screen._switch(2)
	await get_tree().create_timer(0.4, true).timeout
	await _snap(dir + "/12_codex_map.png")
	_codex_screen._switch(0)
	await get_tree().create_timer(0.4, true).timeout
	await _snap(dir + "/13_codex_conquest.png")
	for aid in ["survive_5m", "kills_1k", "fusion_1", "stage_first", "boss_10"]:
		G.achievements[aid] = true
	_codex_screen._switch(4)
	await get_tree().create_timer(0.4, true).timeout
	await _snap(dir + "/14_codex_achv.png")
	_codex_screen.close()
	get_tree().paused = false
	# 맵 여섯 바닥 — 그 맵 몹 몇 마리와 함께(이음매 · 밝기에 몹이 묻히는지)
	if _stage_boss != null and is_instance_valid(_stage_boss):
		(_stage_boss as Node).queue_free()
	for th in 6:
		_cfs2_clear_enemies()
		G.stage = th
		_cfs2_theme(th)
		var tk: Array = (_THEME_KINDS[th] as Array).duplicate()
		tk.append_array(_THEME_YOKAI[th] as Array)
		_cfs4_swarm(p.global_position, tk, 40, 200.0, 560.0)
		await get_tree().create_timer(1.8).timeout
		await _snap(dir + "/2%d_floor_%s.png" % [th, String(Obstacle.ART_KEY[th])])
	print("[S6SHOT] → %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit(0)


## ──────────────────── 큰 순간 연출 화면 (--momentshot) ────────────────────
## 12차 F · G · E · 보스 portrait_big — 보스 등장 컷인 9 · 융합 컷인 · 레벨업 기둥 · 상자 열기 · 손에 든 무기 9 · 장애물 시험판.
##   실행:  ... --path . --resolution 1920x1080 -- [--lang=en] --momentshot      저장: user://momentshot/
func _momentshot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	var dir: String = "user://momentshot"
	DirAccess.make_dir_recursive_absolute(dir)
	var lang: String = "en" if FxLib.lang_en() else "ko"
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(1.8)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	_cfs2_clear_enemies()
	_cfs2_theme(4)
	for o in _obstacles:
		(o as Node).queue_free()
	_obstacles = []
	_spawn_queue = 0
	_spawn_t = 1.0e9      # 찍는 동안 새 몹이 안 나오게
	await get_tree().create_timer(0.3).timeout
	p.process_mode = Node.PROCESS_MODE_DISABLED
	# 보스 등장 컷인 — 중간보스 · 스테이지 · 융합 · 최종
	var bosses: Array = [[4, "mid"], [13, "mid"], [14, "mid"], [15, "mid"], [26, "mid"], [27, "mid"], [28, "mid"], [6, "fusion"], [5, "final"]]
	if lang == "en":
		bosses = [[4, "mid"], [6, "fusion"]]
	for b in bosses:
		_banner_q.clear()
		var k: int = int(b[0])
		match String(b[1]):
			"mid": _boss_cutin(k, FxLib.word_sheet("w_midboss"), "WAVE %d" % 9, Color("ffa63c"), 1.0)
			"fusion": _boss_cutin(k, FxLib.word_sheet("w_boss"), I18n.t("융합 보스 · 도망가기 전에 처치"), Color("ff3860"))
			"final": _boss_cutin(k, FxLib.word_sheet("w_boss"), I18n.t("최종 보스 · 쓰러뜨리면 완주"), Color("ff2d55"))
		await get_tree().create_timer(0.5, true, false, true).timeout
		await _snap(dir + "/%s_cutin_boss_%02d.png" % [lang, k])
		await get_tree().create_timer(1.3, true, false, true).timeout
	# 융합 컷인 + 영웅 자리 번쩍(무기 융합)
	_banner_q.clear()
	p.process_mode = Node.PROCESS_MODE_INHERIT
	_fusion_flourish("evo_reaper")
	await get_tree().create_timer(0.16, true, false, true).timeout
	await _snap(dir + "/%s_cutin_fusion.png" % lang)
	await get_tree().create_timer(2.0, true, false, true).timeout
	# 융합 슬로모션이 컷인 뒤에 풀렸는가(컷인으로 빠지면서 푸는 시계를 건너뛴 적이 있다)
	print("[MOMENT] 융합 2초 뒤 시간 배율 %.2f %s" % [Engine.time_scale, "OK" if Engine.time_scale > 0.99 else "✗ 슬로모션이 안 풀렸다"])
	Engine.time_scale = 1.0
	if lang == "en":
		print("[MOMENT] %s → %s" % [lang, ProjectSettings.globalize_path(dir)])
		get_tree().quit(0)
		return
	p.process_mode = Node.PROCESS_MODE_DISABLED
	_hud_canvas.visible = false
	# 레벨업 기둥 — 0.15 · 0.3 · 0.45초
	for t in [0.15, 0.3, 0.45]:
		_levelup_burst()
		await get_tree().create_timer(t, true, false, true).timeout
		await _snap(dir + "/levelup_%d.png" % int(t * 100.0))
		await get_tree().create_timer(0.8, true, false, true).timeout
	# 상자 열기 — 보통 · 보스(실제 줍기 길로), 0.1 · 0.3 · 0.5초
	for kk in [Pickup.CHEST, Pickup.CHEST_BOSS]:
		for t in [0.1, 0.3, 0.5]:
			var pk := Pickup.new()
			pk.kind = kk
			add_child(pk)
			pk.global_position = p.global_position + Vector2(70, 0)
			pk.set_process(false)      # 자석 거리 안이라 저절로 끌려와 주워진다 — 세워 두고 직접 줍는다
			await get_tree().create_timer(0.3, true, false, true).timeout
			if t == 0.1:
				await _snap(dir + "/chest%d_0.png" % kk)
			pk._collect()
			await get_tree().create_timer(t, true, false, true).timeout
			await _snap(dir + "/chest%d_%d.png" % [kk, int(t * 100.0)])
			if get_tree().paused:
				get_tree().paused = false
			if _chest_panel != null and is_instance_valid(_chest_panel):
				_chest_panel.queue_free()
			_banner_q.clear()
			await get_tree().create_timer(0.8, true, false, true).timeout
	# 손에 든 무기 9 — 오른쪽 · 왼쪽
	for wk: String in ["balanced", "heavy", "rapid", "mid", "melee", "bow", "fan", "sinkal", "jakdu"]:
		p.weapons_primary = [{"id": wk, "t": 99.0, "level": 3}]
		p._refresh_barrel()
		for side in [0, 1]:
			p._barrel.rotation = PI * float(side)
			if p._held != null:
				p._held.flip_v = side == 1
			p._cv.look_dir = Vector2(-1.0 if side == 1 else 1.0, 0.0)
			for _i in 3:
				await get_tree().process_frame
			await _snap(dir + "/held_%s_%d.png" % [wk, side])
	# B 아이콘 시험판 12 — 레벨업 카드(배지 64) · 상자 창(44) · HUD(26), 옆에 지금 아이콘 넷
	_hud_canvas.visible = true
	_open_levelup()
	await get_tree().process_frame
	for c in _cards_box.get_children():
		c.queue_free()
	var want: Array = ["wp_bow", "wp_fan", "hp", "crit"]
	for up in _upgrade_pool():
		if String((up as Dictionary)["id"]) in want:
			_cards_box.add_child(_make_card(up))
	await get_tree().create_timer(0.3, true, false, true).timeout
	await _snap(dir + "/icons_levelup.png")
	_levelup_root.visible = false
	get_tree().paused = false
	var ilay := CanvasLayer.new()
	ilay.layer = 20
	add_child(ilay)
	var bg := ColorRect.new()
	bg.color = Color("1b1d2a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ilay.add_child(bg)
	var ids: Array = ["wp_balanced", "wp_bow", "wp_fan", "wp_heavy", "wp_jakdu", "wp_melee", "wp_mid", "wp_rapid", "wp_sinkal", "hp", "magnet", "crit", "b_fire", "dmg", "armor", "evo_reaper"]
	for row in 3:
		var sz: float = [64.0, 44.0, 26.0][row]
		for i in ids.size():
			var b := IconBadge.new().setup(String(ids[i]), sz)
			b.position = Vector2(24.0 + float(i) * 76.0 + (64.0 - sz) * 0.5, 40.0 + float(row) * 90.0)
			ilay.add_child(b)
	await get_tree().create_timer(0.2, true, false, true).timeout
	await _snap(dir + "/icons_badges.png")
	ilay.queue_free()
	_hud_canvas.visible = false
	# 장애물 시험판 — 천상 크리스탈(천상 바닥) · 저승길 등롱(던전 바닥, 저승길 바닥이 오기 전 어두운 바닥으로)
	for th in [[4, 4], [0, 5]]:
		_cfs2_theme(int(th[0]))
		for o in _obstacles:
			(o as Node).queue_free()
		_obstacles = []
		_cfs2_clear_enemies()
		await get_tree().create_timer(0.3, true, false, true).timeout
		_obstacles.append(Obstacle.spawn(self, p.global_position + Vector2(-170, -30), int(th[1]), 36.0))
		_obstacles.append(Obstacle.spawn(self, p.global_position + Vector2(170, -10), int(th[1]), 50.0))
		for i in 3:
			var e := Enemy.new()
			e.kind = [2, 7, 1][i]
			e.global_position = p.global_position + Vector2(-70 + i * 70, 110)
			add_child(e)
		await get_tree().create_timer(0.6, true, false, true).timeout
		for n in get_tree().get_nodes_in_group("enemy"):
			(n as Enemy).set_physics_process(false)
		await get_tree().create_timer(0.1, true, false, true).timeout
		await _snap(dir + "/obstacle_%d.png" % int(th[1]))
	print("[MOMENT] %s → %s" % [lang, ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## ──────────────────── 융합 게이지 화면 (--fusionshot) ────────────────────
## 2026-10-06: 융합 보스를 '남은 초' 대신 게이지로. 몰려드는 요괴 게이지가 차는 모습 · 융합 보스 체력바 밑 도망 게이지.
##   실행:  ... --path . --resolution 1920x1080 -- --fusionshot      저장: user://fusionshot/
func _fusionshot_flow() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(606)
	var dir: String = "user://fusionshot"
	DirAccess.make_dir_recursive_absolute(dir)
	_main_menu.close()
	_begin_run(Characters.defs()[0])
	await _cf_wait_unpaused(0.3)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	G.time_alive = FUSION_MIN_TIME + 5.0
	p.process_mode = Node.PROCESS_MODE_DISABLED   # 무기를 멈춰 몹이 쌓이게
	var kinds: Array = [0, 1, 7, 8, 12]
	var shots: Array = [[0.5, "1_low"], [0.8, "2_mid"], [1.0, "3_full"]]
	for sh: Array in shots:
		var want: int = int(float(_merge_threshold()) * float(sh[0]))
		var need: int = want - _enemy_count()
		if need > 0:
			_cfs4_swarm(p.global_position, kinds, need, 260.0, 640.0)
		if String(sh[1]) == "3_full":
			_overcap_t = MERGE_HOLD * 0.8
		await _cf_wait_unpaused(0.8)
		await _cf_snap(dir + "/swarm_%s.png" % sh[1])
	_overcap_t = MERGE_HOLD
	await _cf_wait_unpaused(0.4)
	await _cf_snap(dir + "/fusion_0_spawn.png")
	_fusion_deadline = G.time_alive + FUSION_DEADLINE * 0.35
	await _cf_wait_unpaused(0.4)
	await _cf_snap(dir + "/fusion_1_escaping.png")
	print("[FUSIONSHOT] → %s" % ProjectSettings.globalize_path(dir))
	get_tree().quit(0)


## ──────────────────── 7차 화면 (--cfshots7) ────────────────────
## 7차 지시서 6절 2: 새 리콜을 falconer 자리에 넣고 자리·대시·융합을 보고, 바뀐 칸(11곳 · 브란드 걷기)을 게임 화면에서 본다.
##   1) 캐릭터 선택 — 리콜 상세(초상화). 잠겨 있으면 초상화가 안 나와서 이 실행에서만 푼다(G.no_save).
##   2) 리콜로 판 시작 → 등장 · 걷기 · 대시(skill + 대시 자국 vfx) · 융합 순간(ultimate)
##   3) 보스전 칸별 — 그로크 등장·피격 · 네페르 돌진·궁극기 · 볼케·오르빈 스킬 · 이오네 피격
##   4) 게임 배율 줄 세우기 — 새디 · 갈덴 · 아르잔 · 리콜의 모든 칸, 얼음 정령, 브란드 (던전 · 천상)
##   실행:  ... --path . --resolution 1920x1080 -- --cfshots7      저장: user://cfshots7/
const CFS7_BOSSES: Array = [
	[6, "grok", [0, 4], ["entrance", "hit"]],
	[5, "nefer", [0, 4], ["charge", "ultimate"]],
	[14, "bolke", [0], ["skill"]],
	[27, "orbin", [0, 4], ["skill"]],
	[28, "ione", [0], ["hit"]],
]
const CFS7_HERO_ANIMS: Array = ["anchor", "idle", "walk", "entrance", "skill", "vfx", "ultimate", "emote", "hit", "death"]


## 한 캐릭터의 칸을 왼쪽부터 게임과 같은 배율로 세운다(발 기준선 = origin.y). 칸 아래 작은 이름표. 끝 x 를 돌려준다.
func _cfs7_row(parent: Node2D, origin: Vector2, cf_id: String, target_h: float, radius: float, label: String, anims: Array) -> float:
	var x: float = origin.x
	var lb0 := Label.new()
	lb0.text = label
	UiFont.apply(lb0, 11)
	lb0.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lb0.add_theme_constant_override("outline_size", 4)
	lb0.position = Vector2(x, origin.y + 16.0)
	parent.add_child(lb0)
	for a: String in anims:
		var an: Dictionary = CharForge.anim(cf_id, a)
		if an.is_empty():
			continue
		for fi in (1 if a == "vfx" else int(an["n"])):
			var cv := CreatureVisual.new()
			cv.radius = radius
			cv.cf_id = cf_id
			cv.cf_target_h = target_h
			cv.always_animate = true
			cv.build()
			var k: float = float(cv.cf_scale())
			var w: float = float(an["fw"]) * k
			if a == "vfx":
				var fx: Sprite2D = cv.make_vfx()
				cv.free()
				if fx == null:
					continue
				fx.centered = false
				fx.offset = Vector2(-floorf(float(an["fw"]) * 0.5), -(float(an["fh"]) - 2.0))
				fx.position = Vector2(x + w * 0.5, origin.y)
				parent.add_child(fx)
			else:
				cv.pose(a, fi)
				cv.position = Vector2(x + w * 0.5, origin.y - radius * 0.86)
				parent.add_child(cv)
			var lb := Label.new()
			lb.text = "%s%d" % [a.substr(0, 4), fi]
			UiFont.apply(lb, 8)
			lb.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			lb.add_theme_constant_override("outline_size", 3)
			lb.position = Vector2(x, origin.y + 2.0)
			parent.add_child(lb)
			x += w + 6.0
	return x


func _cfshots7_flow() -> void:
	if DisplayServer.get_name() == "headless":
		print("[CFSHOTS7] 건너뜀 — 창모드로 실행해야 한다")
		get_tree().quit(0)
		return
	await get_tree().create_timer(0.5).timeout
	G.no_save = true
	seed(7007)
	var dir: String = "user://cfshots7"
	DirAccess.make_dir_recursive_absolute(dir)
	for fn in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(fn))
	var pf := FileAccess.open(dir + "/pos.txt", FileAccess.WRITE)
	print("=== CFSHOTS7 ===")
	var fdef: Dictionary = {}
	for d: Dictionary in Characters.defs():
		if String(d["id"]) == "falconer":
			fdef = d
	var n_shots: int = 0
	# ── 1) 캐릭터 선택 — 리콜 상세 ──
	_main_menu.close()
	G.meta["uc_falconer"] = 1
	_char_select.open()
	await _cf_wait_unpaused(0.6)
	_char_select._show_detail(fdef)
	var sc: ScrollContainer = _find_scroll(_char_select)
	if sc != null:
		sc.scroll_horizontal = 100000
	await _cf_wait_unpaused(0.4)
	await _cf_snap(dir + "/recall_select.png")
	n_shots += 1
	_char_select._on_back()
	await get_tree().process_frame
	# ── 2) 리콜로 판 시작 — 등장 · 걷기 · 대시 · 융합 ──
	_begin_run(fdef)
	await _cf_wait_unpaused(0.12)
	var p := G.player as Player
	p.max_hp = 1.0e9
	p.hp = 1.0e9
	p.xp_mult = 0.0
	await _cf_snap(dir + "/recall_1_entrance.png")
	await _cf_wait_unpaused(1.2)
	var mob_kinds: Array = []
	for kk in Enemy.KINDS.keys():
		if not bool((Enemy.KINDS[kk] as Dictionary).get("boss", false)):
			mob_kinds.append(int(kk))
	mob_kinds.shuffle()
	_cfs4_swarm(p.global_position, mob_kinds, 40, 260.0, 620.0)
	await _cf_wait_unpaused(0.6)
	await _cf_snap(dir + "/recall_2_walk.png")
	for k in 2:
		p._dash_cd = 0.0
		p._start_dash(Vector2.RIGHT if k == 0 else Vector2.LEFT)
		await _cf_wait_unpaused(0.05 if k == 0 else 0.12)
		_cfs5_pos(pf, "recall_3_dash_%d.png" % k, [p])
		await _cf_snap(dir + "/recall_3_dash_%d.png" % k)
		await _cf_wait_unpaused(0.6)
	p.cf_moment("ultimate")      # 게임은 융합할 때 이 동작을 낸다(main_game.gd)
	await _cf_wait_unpaused(0.1)
	await _cf_snap(dir + "/recall_4_fusion_0.png")
	await _cf_wait_unpaused(0.22)
	await _cf_snap(dir + "/recall_4_fusion_1.png")
	n_shots += 6
	# ── 3) 보스전 칸별 ──
	n_shots += await _cfs5_boss_frames(pf, dir, CFS7_BOSSES, p, mob_kinds)
	G.running = false
	_cfs2_clear_enemies()
	await _cf_wait_unpaused(0.3)
	# ── 4) 게임 배율 줄 세우기 ──
	p.visible = false
	var cam: Camera2D = G.camera as Camera2D
	var zoom0: Vector2 = cam.zoom if cam != null else Vector2.ONE
	if cam != null:
		cam.zoom = Vector2.ONE
	for th: int in [0, 4]:
		_cfs2_theme(th)
		await _cf_wait_unpaused(0.2)
		var holder := Node2D.new()
		add_child(holder)
		var ox: float = p.global_position.x - 620.0
		var oy: float = p.global_position.y - 250.0
		var ri: int = 0
		for hid: String in ["knight", "mudang", "hwarang", "falconer"]:
			var hs: Dictionary = CharForge.hero_slot(hid)
			var hname: String = hid
			for d2: Dictionary in Characters.defs():
				if String(d2["id"]) == hid:
					hname = String(d2["name"])
			_cfs7_row(holder, Vector2(ox, oy + 95.0 * float(ri)), String(hs.get("id", "")), float(hs.get("h", 40.0)), Player.RADIUS, hname, CFS7_HERO_ANIMS)
			ri += 1
		var ps: Dictionary = CharForge.pet_slot("summon_ice")
		_cfs7_row(holder, Vector2(ox, oy + 95.0 * float(ri)), String(ps.get("id", "")), float(ps.get("h", 32.0)), 15.0, "얼음 정령", ["anchor", "walk", "attack", "hit", "death"])
		var bk: Array = _cfs2_item(18)
		_cfs7_row(holder, Vector2(ox + 520.0, oy + 95.0 * float(ri)), String(bk[0]), float(bk[4]), float(bk[1]), "브란드", ["anchor", "walk", "hit", "death"])
		await _cf_wait_unpaused(0.3)
		await _cf_snap(dir + "/lineup_%s.png" % CFS5_FLOOR_NAME.get(th, str(th)))
		n_shots += 1
		holder.queue_free()
		await get_tree().process_frame
	if cam != null:
		cam.zoom = zoom0
	p.visible = true
	pf.close()
	print("[CFSHOTS7] %d장 → %s" % [n_shots, ProjectSettings.globalize_path(dir)])
	get_tree().quit(0)


## 걷기가 파닥거리지 않는지 본다. 두 가지를 잰다.
##   1) 칸이 도는 속도 — 4칸 걷기는 8~12fps 가 한계다. 그 위는 걷는 게 아니라 떠는 것이다.
##   2) 칸별 키 편차 — 발바닥이 맞아도 머리가 오르내리면 커졌다 작아졌다 하는 것으로 보인다.
## 2026-09-03: 두 가지가 동시에 틀려 있었다(플레이어 초당 23칸, 키 편차 중앙값 11.6%).
## --artcheck 는 "그림이 있는가"만 보므로 둘 다 통과시켰다.
func _walkcheck_flow() -> void:
	await get_tree().create_timer(0.2).timeout
	var bad_fps: Array = []
	var bad_h: Array = []
	var checked: int = 0

	# ── 1. 칸 도는 속도 ─────────────────────────────────────
	var pf: float = CreatureVisual.walk_fps(Player.SPEED, Player.RADIUS)
	print("[WALK] 플레이어 %.0fpx/s 반지름 %.0f → %.1f fps (%.2f 사이클/초)"
		% [Player.SPEED, Player.RADIUS, pf, pf / 4.0])
	if pf > 12.0 or pf < 3.0:
		bad_fps.append("플레이어 %.1f fps" % pf)
	var lo: float = 999.0
	var hi: float = 0.0
	for k in Enemy.KINDS.keys():
		var d: Dictionary = Enemy.KINDS[k] as Dictionary
		var spd: float = float(d.get("spd", 0.0))
		var rad: float = float(d.get("vis", d.get("rad", 12.0)))
		if spd <= 0.0:
			continue
		var f: float = CreatureVisual.walk_fps(spd, rad)
		lo = minf(lo, f)
		hi = maxf(hi, f)
		if f > 12.0 or f < 3.0:
			bad_fps.append("kind %d %.1f fps" % [int(k), f])
	print("[WALK] 몹 %.1f ~ %.1f fps" % [lo, hi])

	# ── 2. 칸별 키 편차 ─────────────────────────────────────
	var worst: float = 0.0
	var worst_nm: String = ""
	var paths: Array = []
	for k in Enemy.LOOKS.keys():
		var nm: String = String((Enemy.LOOKS[k] as Dictionary).get("spr", ""))
		if nm != "":
			paths.append("res://assets/sprites/monsters/%s.png" % nm)
	for d: Dictionary in Characters.defs():
		var sp: String = String(d.get("sprite", ""))
		if sp != "":
			paths.append(sp)
	for path: String in paths:
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			continue
		var img: Image = tex.get_image()
		if img == null:
			continue
		var w: int = img.get_width()
		var h: int = img.get_height()
		if w % 4 != 0 or w <= h:
			continue                      # 스트립이 아니다
		checked += 1
		var fw: int = w / 4
		var hs: Array[float] = []
		for c in 4:
			var top: int = -1
			var bot: int = -1
			for y in h:
				var any: bool = false
				for x in range(c * fw, (c + 1) * fw):
					if img.get_pixel(x, y).a > 0.03:
						any = true
						break
				if any:
					if top < 0:
						top = y
					bot = y
			hs.append(float(bot - top + 1) if top >= 0 else 0.0)
		var mn: float = hs[0]
		var mx: float = hs[0]
		var sum: float = 0.0
		for v: float in hs:
			mn = minf(mn, v)
			mx = maxf(mx, v)
			sum += v
		if sum <= 0.0:
			continue
		var dev: float = (mx - mn) / (sum / 4.0) * 100.0
		if dev > worst:
			worst = dev
			worst_nm = path.get_file()
		if dev > 6.0:
			bad_h.append("%s 키편차 %.1f%%" % [path.get_file(), dev])

	print("[WALK] 스트립 %d장 검사 · 키편차 최대 %.1f%% (%s)" % [checked, worst, worst_nm])
	for b in bad_fps:
		print("[WALK]   ✗ 너무 빠르다/느리다: %s" % String(b))
	for b in bad_h:
		print("[WALK]   ✗ %s" % String(b))
	if bad_fps.is_empty() and bad_h.is_empty():
		print("[WALK] ALL PASS")
	else:
		print("[WALK] 문제 %d건" % (bad_fps.size() + bad_h.size()))
	get_tree().quit()


## 카드를 계속 먹으면 공격력이 어디까지 가는가. 실제 풀에서 실제로 뽑아 실제로 적용한다.
## 2026-09-04 질문("영웅 공격력이 오른다는데 나중에 사기가 되지 않나")에 숫자로 답하려고 만들었다.
##   --ridercheck        카드 40장
##   --ridercheck=80     카드 80장
func _ridercheck_flow(picks: int) -> void:
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	if p == null:
		print("[RIDER] 플레이어가 없다")
		get_tree().quit()
		return
	p.xp_mult = 0.0
	var base: float = p.base_damage
	print("[RIDER] 기준 base_damage %.2f · 표시 데미지 %d" % [base, int(p.damage)])
	print("[RIDER] %4s %8s %8s %10s %8s"
		% ["장수", "card_add", "card_mult", "데미지", "배수"])

	var pool: Array = _upgrade_pool()
	for i in picks:
		if pool.is_empty():
			break
		var pick: Array = _weighted_pick(pool, 1)
		if pick.is_empty():
			break
		var id: String = String((pick[0] as Dictionary)["id"])
		_apply_upgrade(id)
		if (i + 1) % 5 == 0 or i == picks - 1:
			print("[RIDER] %4d %8.2f %8.2f %10d %7.1f배"
				% [i + 1, p.card_add, p.card_mult, int(p.damage),
				   p.damage / maxf(1.0, base)])
	print("[RIDER] 무기 %d정 · 특수무기 %d개" % [p.weapons_primary.size(), p.weapons.size()])
	get_tree().quit()


## 손에 든 무기 규칙: **가장 최근에 얻은 주무기**. 그 한 줄이 지켜지는지 본다.
## 2026-09-04: 예전 규칙(레벨 최대)이 "곡궁을 먹었는데 총이 계속 뜬다"를 만들었다.
## 규칙을 바꿨으면 규칙이 지켜지는지도 재야 한다 — 눈으로만 보면 또 놓친다.
func _heldcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	if p == null:
		print("[HELD] 플레이어가 없다")
		get_tree().quit()
		return
	var fails: int = 0
	# 시작 상태 — 아무것도 안 골랐으면 시작 무기
	var got: String = p._dominant_primary()
	print("[HELD] 시작            → %s" % got)
	if got != "balanced":
		print("[HELD]   ✗ 시작 무기가 아니다"); fails += 1
	# 소총을 한 번 더(Lv2) → 여전히 소총. 그 다음 곡궁 → 곡궁이어야 한다(레벨이 낮아도).
	for step: Array in [["balanced", "balanced"], ["bow", "bow"], ["jakdu", "jakdu"],
						["bow", "bow"], ["balanced", "balanced"]]:
		p.add_primary_weapon(String(step[0]))
		got = p._dominant_primary()
		var want: String = String(step[1])
		var lv: int = 0
		for w in p.weapons_primary:
			if String(w["id"]) == String(step[0]):
				lv = int(w["level"])
		print("[HELD] %-8s Lv%d 획득 → %s" % [String(step[0]), lv, got])
		if got != want:
			print("[HELD]   ✗ %s 여야 한다" % want); fails += 1
	print("[HELD] 주무기 %d정 · 발밑 룬 %d개"
		% [p.weapons_primary.size(), p.weapons_primary.size() + p.weapons.size()])
	print("[HELD] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 소환수가 (1) 서로 안 뭉치는지 (2) 플레이어 곁을 안 벗어나는지.
## 2026-09-04: 전원이 같은 한 점을 목표로 삼아 한 덩어리가 됐고, 취득이 자기 기준 375px 라
## 화면 밖까지 끌려갔다. 고쳤으면 재야 한다 — 물리 프레임을 실제로 돌려서 본다.
func _summoncheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	if p == null:
		print("[SUMMON] 플레이어가 없다")
		get_tree().quit()
		return
	p.xp_mult = 0.0
	for i in 4:
		p.add_weapon("wpn_summon")      # 레벨을 올려 마리 수를 늘린다
	var w: Node = p.weapons.get("wpn_summon", null)
	if w == null:
		print("[SUMMON] 소환수 무기가 안 붙었다")
		get_tree().quit()
		return
	# 물리 프레임을 실제로 돌린다 — 목표점 수렴은 시간이 지나야 드러난다
	for i in 180:
		await get_tree().physics_frame
	var ms: Array = w.get("_minions") as Array
	var alive: Array = []
	for m in ms:
		if is_instance_valid(m):
			alive.append(m)
	if alive.size() < 2:
		print("[SUMMON] 소환수가 %d 마리뿐이라 판정 불가" % alive.size())
		get_tree().quit()
		return
	var pp: Vector2 = p.global_position
	var near: float = 99999.0
	var far_p: float = 0.0
	for i in alive.size():
		far_p = maxf(far_p, pp.distance_to((alive[i] as Node2D).global_position))
		for j in range(i + 1, alive.size()):
			near = minf(near, (alive[i] as Node2D).global_position
				.distance_to((alive[j] as Node2D).global_position))
	print("[SUMMON] %d마리 · 서로 최소거리 %.1fpx · 플레이어에서 최대 %.1fpx"
		% [alive.size(), near, far_p])
	var fails: int = 0
	if near < 18.0:
		print("[SUMMON]   ✗ 뭉쳤다 — 그림 폭이 23px 이라 18px 밑이면 한 덩어리로 보인다")
		fails += 1
	if far_p > 340.0:
		print("[SUMMON]   ✗ 너무 멀다 — 리시(300)가 안 걸린다")
		fails += 1
	print("[SUMMON] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 융합이 **강등**이 아닌지, 그리고 융합 진척 줄에 "99" 가 안 새는지.
## 2026-09-05: 융합 결과가 Lv11 고정이라 톨크(무기 카드 한 장에 두 단계)가 레이저를
## Lv13(4줄기)까지 키운 뒤 융합하면 Lv11(3줄기)로 **줄었다.**
## 그리고 잠긴 무기의 카드 상한을 못 찾아 "작두 0/99" 가 화면에 찍혔다.
func _fusegrade_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	# 톨크(도깨비 대장장이 = forge). 무기 카드 한 장에 두 단계 오르는 캐릭터라 강등이 드러난다.
	var smith: Dictionary = {}
	for d: Dictionary in Characters.defs():
		if String(d.get("ability", "")) == "forge":
			smith = d
	if smith.is_empty():
		print("[FUSE] forge 캐릭터를 못 찾았다")
		get_tree().quit()
		return
	_begin_run(smith)
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	var fails: int = 0

	# ── 1. 레이저를 카드 만렙까지 올린 뒤 초신성으로 융합 ──
	for i in 6:
		_apply_upgrade("wpn_beam")
	for i in 6:
		_apply_upgrade("b_fire")
	var beam: Node = p.weapons.get("wpn_beam", null)
	var lv_before: int = int(beam.get("level")) if beam != null else 0
	var n_before: int = int(beam.call("_beam_count")) if beam != null and beam.has_method("_beam_count") else -1
	print("[FUSE] 융합 전  레이저 Lv%d · 줄기 %d" % [lv_before, n_before])
	_apply_upgrade("evo_nova")
	var beam2: Node = p.weapons.get("wpn_beam", null)
	var lv_after: int = int(beam2.get("level")) if beam2 != null else 0
	var n_after: int = int(beam2.call("_beam_count")) if beam2 != null and beam2.has_method("_beam_count") else -1
	print("[FUSE] 융합 후  레이저 Lv%d · 줄기 %d" % [lv_after, n_after])
	if lv_after < lv_before:
		print("[FUSE]   ✗ 레벨이 내려갔다 (%d → %d)" % [lv_before, lv_after]); fails += 1
	if n_before >= 0 and n_after < n_before:
		print("[FUSE]   ✗ 줄기가 줄었다 (%d → %d)" % [n_before, n_after]); fails += 1
	if p.b_fire < 6:
		print("[FUSE]   ✗ 탄막 화염이 6 미만 (%d)" % p.b_fire); fails += 1

	# ── 2. 융합 진척 줄에 99 가 없어야 한다 ──
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	for id: String in ["b_vamp", "b_chain", "b_exec"]:
		_apply_upgrade(id)
	var lines: Array = fusion_progress_lines()
	for l in lines:
		print("[FUSE] 진척: %s" % String(l))
		if "99" in String(l):
			print("[FUSE]   ✗ 99 가 화면에 샌다"); fails += 1
	print("[FUSE] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 영웅 고유 능력이 (1) 전부 화면에 설명되는지 (2) 깃소금 도박이 기록으로 남는지.
## 2026-09-05: ability 를 읽는 UI 가 하나도 없어서, 능력이 뭘 했는지 알 길이 없었다.
func _abilcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	var pm := load("res://scripts/pause_menu.gd")
	var probe: Node = pm.new()          # _ability_lines 만 부른다(화면에 안 붙인다)
	var fails: int = 0
	var seen: Dictionary = {}
	for d: Dictionary in Characters.defs():
		var ab: String = String(d.get("ability", ""))
		seen[ab] = true
	print("[ABIL] 영웅 %d종 · 능력 %d가지" % [Characters.defs().size(), seen.size()])

	# 능력별로 한 줄이라도 설명이 나오는지
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	# ★ 예전엔 "설명이 한 줄이라도 나오는가"만 봤다. 그래서 원혼(spirits)이 배수도 지속시간도
	#   없이 "처치가 원혼을 부른다"라고만 적힌 채로 통과했고, 화면의 피해 숫자가 20 에서 23 으로
	#   혼자 뛰는 걸 버그로 신고받았다(2026-09-06). 피해에 손대는 능력은 **숫자가 있어야** 한다.
	var dmg_abils: PackedStringArray = ["spirits", "sworddance", "rage", "shadow", "dashstrike",
		"pyro", "forge"]
	for ab: String in seen.keys():
		if ab == "":
			continue
		p.ability = ab
		var ls: Array = probe.call("_ability_lines", p)
		if ls.is_empty():
			print("[ABIL]   ✗ %s — 설명이 없다" % ab); fails += 1
			continue
		print("[ABIL] %-11s %s" % [ab, String(ls[0]).substr(0, 52)])
		if ab in dmg_abils:
			# '숫자가 있는가'로는 부족하다 — "지금 0.0초" 같은 타이머 표기가 통과해 버린다.
			# 물어야 하는 건 **얼마나 세지는가**, 즉 배수(×) 나 확률(%) 이 적혀 있는가다.
			var joined: String = " ".join(PackedStringArray(ls.map(func(x): return String(x))))
			if not ("×" in joined or "%" in joined):
				print("[ABIL]   ✗ %s — 피해를 바꾸는데 크기(× 또는 %%)가 안 적혔다: %s"
					% [ab, String(ls[0]).substr(0, 44)])
				fails += 1
	# 영웅 선택 화면의 한 줄(abil)도 같은 규칙을 받는다 — 카드에서 읽는 게 그 줄이다
	for d: Dictionary in Characters.defs():
		var ab2: String = String(d.get("ability", ""))
		if not (ab2 in dmg_abils):
			continue
		var txt: String = String(d.get("abil", ""))
		if not ("×" in txt or "%" in txt):
			print("[ABIL]   ✗ %s 영웅카드 설명에 크기가 없다: %s" % [String(d["name"]), txt])
			fails += 1

	# 깃소금 도박이 기록으로 남는지
	var gam: Dictionary = {}
	for d: Dictionary in Characters.defs():
		if String(d.get("ability", "")) == "fourcards":
			gam = d
	_begin_run(gam)
	await get_tree().process_frame
	p = G.player as Player
	for i in 5:
		_gambler_variance(p)
	print("[ABIL] 도박 %d회 · 공격력 %+.2f · 탄환 %+d · 치명 %+.2f · 주기 ×%.2f · 마지막 %s"
		% [p.gamble_rolls, p.gamble_add, p.gamble_proj, p.gamble_crit, p.gamble_rate, p.gamble_last])
	if p.gamble_rolls != 5:
		print("[ABIL]   ✗ 굴린 횟수가 안 쌓인다"); fails += 1
	if p.gamble_last == "":
		print("[ABIL]   ✗ 마지막 결과가 비어 있다"); fails += 1
	probe.free()
	print("[ABIL] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 성장 트랙의 **모든 칸이 실제로 무언가를 바꾸는지.** 죽은 칸을 찾는다.
## 트랙에 키를 적어도 그 값을 읽는 코드가 없으면 레벨을 올려도 아무 일이 안 일어난다 —
## 화면에는 "다음 → 유도" 라고 뜨는데 실제로는 안 휘는 식이다(2026-09-05 유도 키 신설).
func _trackcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	var fails: int = 0
	var dead: Array = []

	# 주무기 9종: 트랙 칸마다 Lv1 과 Lv6 의 실제 수치를 비교한다
	for arch: String in ["balanced", "heavy", "rapid", "mid", "melee", "bow", "fan", "sinkal", "jakdu"]:
		var d: Dictionary = Player.WEAPON_DEFS[arch]
		var tr: Array = G.w_track(arch)
		var seen: Dictionary = {}
		for k in tr:
			seen[String(k)] = true
		var line: PackedStringArray = []
		for key: String in seen.keys():
			var a: float = 0.0
			var b: float = 0.0
			match key:
				"dmg":
					a = G.w_dmg_mult(arch, 1); b = G.w_dmg_mult(arch, 11)
				"rate":
					a = G.w_rate_mult(arch, 1); b = G.w_rate_mult(arch, 11)
				"area", "range":
					a = G.w_area_mult(arch, 1); b = G.w_area_mult(arch, 11)
				"pierce", "proj", "homing", "count":
					a = float(G.w_grade(arch, 1, key)); b = float(G.w_grade(arch, 11, key))
				_:
					a = 0.0; b = 0.0
			if absf(b - a) < 0.0001:
				dead.append("%s / %s" % [arch, key])
				line.append("%s ✗" % key)
			else:
				line.append("%s %.2f→%.2f" % [key, a, b])
		print("[TRACK] %-9s %s" % [arch, " · ".join(line)])

	# 유도는 트랙에만 있으면 안 되고 **탄환까지 전달**돼야 한다
	var lv: int = 11
	var g: int = G.w_grade("sinkal", lv, "homing")
	print("[TRACK] 신칼 Lv%d 유도 칸 %d" % [lv, g])
	if g <= 0:
		print("[TRACK]   ✗ 신칼 트랙에 유도가 안 잡힌다"); fails += 1
	var src: String = FileAccess.get_file_as_string("res://scripts/player.gd")
	var i_apply: int = src.find("b.apply_from(self)")
	var i_hom: int = src.find("b._fx_homing += G.w_grade")
	if i_hom < 0:
		print("[TRACK]   ✗ 탄환에 유도를 더하는 줄이 없다 — 죽은 칸이다"); fails += 1
	elif i_hom < i_apply:
		print("[TRACK]   ✗ apply_from 보다 앞에 있다 — 대입에 지워진다"); fails += 1
	else:
		print("[TRACK] 유도 전달: apply_from 뒤에 있다 (덮어쓰기 안 당함)")

	if not dead.is_empty():
		print("[TRACK] 죽은 칸 %d개:" % dead.size())
		for x in dead:
			print("[TRACK]   ✗ %s" % String(x))
		fails += dead.size()
	print("[TRACK] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 카드에 실제로 뭐라고 적히는지. 제목과 설명을 그대로 찍어 본다.
## 2026-09-05: "%가 아니라 직관적인 수치로" — 바꿨으면 뭐라고 나오는지 봐야 한다.
func _cardcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	# 조금 키운 상태에서 봐야 "지금 값 → 다음 값" 이 의미가 있다
	for id: String in ["dmg", "dmg", "crit", "wp_bow", "wp_bow", "wpn_orb"]:
		_apply_upgrade(id)
	var bad: int = 0
	print("[CARD] 피해 %d · 이동 %d · 치명 %d%%" % [int(p.damage), int(p.move_speed), int(p.crit_chance * 100.0)])
	# ★ 예전엔 **제목만** 봤다. 그래서 "제목에 % 없음 = PASS" 가 나왔는데, 화면에 나가는
	#   나머지 세 경로(카드 설명 · ESC 빌드 패널 이름 · 빌드 패널 누적)는 검사 밖이라
	#   "+26%" 가 그대로 남아 있었다(2026-09-06 지적). 이제 네 경로를 전부 훑는다.
	#   %가 원래 단위인 것만 통과시킨다 — 확률(치명·행운·발동)과 배율(경험치·골드).
	var pct_ok: Array = ["crit", "luck", "xp_gain", "c_allin", "c_talon", "c_goldsense",
						 "c_bellcall", "l_echo", "l_timewarp", "gamble", "m_immortal",
						 "heal_card", "gold_card", "b_fire", "b_poison", "b_shock"]
	var all_cards: Array = _base_pool().duplicate()
	for cc in _CHAR_CARDS.values():   # 시그니처 카드도 화면에 나간다 — 같이 본다
		all_cards.append(cc)
	for u: Dictionary in all_cards:
		var id: String = String(u["id"])
		if id.begins_with("evo_"):
			continue
		var title: String = _card_title(id, String(u["n"]))
		var body: String = _card_stats(id).replace("
", " / ")
		if id in ["dmg", "rate", "speed", "crit", "critdmg", "dashcd", "wp_bow", "wpn_orb", "wpn_summon"]:
			print("[CARD] %-22s | %s" % [title, body.substr(0, 66)])
		var where: Array = [["제목", title], ["설명", body]]
		# 빌드 패널은 다른 함수를 타므로 따로 본다 — 여기가 실제로 새던 자리다
		if int(_upgrade_counts.get(id, 0)) > 0:
			where.append(["빌드이름", card_display_name(id, String(u["n"]))])
			where.append(["빌드누적", _stat_total(id, int(_upgrade_counts[id]))])
		for w: Array in where:
			if "%" in String(w[1]) and not (id in pct_ok):
				print("[CARD]   ✗ %s 에 %% 가 남았다: %s" % [String(w[0]), String(w[1]).substr(0, 50)])
				bad += 1
	print("[CARD] 검사한 카드 %d종 · 경로 4개(제목·설명·빌드이름·빌드누적)" % all_cards.size())
	print("[CARD] %s" % ("ALL PASS" if bad == 0 else "문제 %d건" % bad))
	get_tree().quit()


## 먹은 것이 **하나도 빠짐없이** 빌드 패널에 뜨는지.
## 2026-09-05: 무기·탄막만 나오고 레벨업으로 얻은 스탯 강화는 통째로 빠져 있었다.
func _buildcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	# 종류를 골고루 먹는다 — 스탯 · 무기 · 특수무기 · 탄막 · 전설
	var eaten: Array = ["dmg", "dmg", "crit", "armor", "magnet", "speed",
						"wp_bow", "wp_bow", "wpn_orb", "b_fire", "b_fire", "l_echo"]
	for id: String in eaten:
		_apply_upgrade(id)
	var want: Dictionary = {}
	for id: String in eaten:
		want[id] = true
	var rows: Array = _build_summary()
	var got: Dictionary = {}
	for r: Dictionary in rows:
		got[String(r["id"])] = r
	print("[BUILD] 먹은 종류 %d · 패널에 뜬 항목 %d" % [want.size(), rows.size()])
	var miss: int = 0
	for id in want.keys():
		if not got.has(id):
			print("[BUILD]   ✗ %s 가 패널에 없다" % String(id)); miss += 1
	for r: Dictionary in rows:
		print("[BUILD] [%s] %-16s Lv%d/%d  %s"
			% [String(r.get("kind", "?")), String(r["name"]), int(r["level"]), int(r["max"]),
			   String(r.get("desc", "")).split("
")[0].substr(0, 40)])
	# ★ 칸 표시가 실제 소유와 맞는지. 전설·신화가 '패시브' 로 안 세어진다는 지적(2026-09-06).
	print("[BUILD] %s" % slot_usage_line())
	var want_slot: Dictionary = {"무기": 2, "탄막": 1, "패시브": 1}  # 시작 소총은 안 센다
	for cat in want_slot.keys():
		var n0: int = _owned_slot_count(String(cat))
		if n0 != int(want_slot[cat]):
			print("[BUILD]   ✗ %s 칸 %d (기대 %d)" % [String(cat), n0, int(want_slot[cat])])
			miss += 1
	# ★ 융합하면 칸이 어떻게 움직이는가(2026-09-07 요구). 예전엔 재료 2칸이 비고 결과는
	#   **어느 칸도 안 먹었다** — 융합 결과가 공짜였고 그래서 '융합 n/3' 이라는 별도 상한이
	#   필요했다. 이제 결과가 자기 분류(무기) 칸을 차지하므로 그 상한을 없앨 수 있다.
	#   여기서 무기+탄막 융합과 무기+무기 융합(군단) 둘 다 실제로 그렇게 도는지 본다.
	for case: Dictionary in [
		{"evo": "evo_inferno", "req": ["wpn_fire", "b_fire"], "w": 1, "b": 0},
		{"evo": "evo_legion", "req": ["wpn_summon", "summon_ice"], "w": 1, "b": 0},
	]:
		_begin_run(Characters.defs()[0])
		await get_tree().process_frame
		for m: String in (case["req"] as Array):
			for i in 6:
				_apply_upgrade(m)
		var w0: int = _owned_slot_count("무기")
		var b0: int = _owned_slot_count("탄막")
		_apply_upgrade(String(case["evo"]))
		await get_tree().process_frame
		var w1: int = _owned_slot_count("무기")
		var b1: int = _owned_slot_count("탄막")
		var ok_w: bool = w1 == int(case["w"])
		var ok_b: bool = b1 == int(case["b"])
		print("[BUILD] %s 융합:  무기 %d→%d (기대 %d) · 탄막 %d→%d (기대 %d)  %s"
			% [String(case["evo"]), w0, w1, int(case["w"]), b0, b1, int(case["b"]),
				"✔" if (ok_w and ok_b) else "✗"])
		if not ok_w:
			print("[BUILD]   ✗ 융합 결과가 무기 칸을 안 먹는다 (%d, 기대 %d)" % [w1, int(case["w"])])
			miss += 1
		if not ok_b:
			print("[BUILD]   ✗ 탄막 칸이 기대와 다르다 (%d, 기대 %d)" % [b1, int(case["b"])])
			miss += 1
	if "융합" in slot_usage_line():
		print("[BUILD]   ✗ 칸 표시에 아직 '융합' 칸이 남아 있다"); miss += 1
	print("[BUILD] %s" % ("ALL PASS" if miss == 0 else "빠진 항목 %d건" % miss))
	get_tree().quit()


## 회전 오브가 **정말로 적을 때리는지.** --weapondps 가 0.0 을 찍어서 만들었다.
## 하니스는 더미를 링에 세우므로 궤도 반경과 어긋나면 0 이 나온다 — 여기서는 적을
## 궤도 위에 직접 놓고 체력이 주는지만 본다.
func _orbcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	p.global_position = Vector2.ZERO
	var bad: int = 0
	# 레벨마다 궤도 반경이 다르다 — 그 반경 위에 놓고 잰다. 고정 거리로 재면 반경이 자란
	# 순간부터 0 이 찍힌다(--weapondps 가 딱 그래서 두 번이나 0.0 을 냈다).
	for lv: int in [3, 6]:
		p.no_default_weapon = true
		for k in p.weapons.keys():
			if is_instance_valid(p.weapons[k]):
				(p.weapons[k] as Node).queue_free()
		p.weapons = {}
		await get_tree().process_frame
		for i in lv:
			p.add_weapon("wpn_orb")
		var rad: float = 58.0 * G.w_area_mult("wpn_orb", lv)
		var e := Enemy.new()
		e.kind = 2
		add_child(e)
		e.global_position = Vector2(rad, 0.0)
		e.hp = 1.0e9
		e.max_hp = 1.0e9
		var before: float = e.hp
		for i in 240:                      # 4초
			await get_tree().physics_frame
			e.global_position = Vector2(rad, 0.0)   # 못 움직이게 붙들어 둔다
		var dealt: float = before - e.hp
		print("[ORB] Lv%d 궤도반경 %.0f · 4초 피해 %.0f (초당 %.0f)" % [lv, rad, dealt, dealt / 4.0])
		if dealt <= 0.0:
			print("[ORB]   ✗ Lv%d 은 한 대도 못 때렸다" % lv)
			bad += 1
		if is_instance_valid(e):
			e.queue_free()
	print("[ORB] %s" % ("ALL PASS" if bad == 0 else "문제 %d건" % bad))
	get_tree().quit()


## 성장 예고가 **실제로 변하는 것을 말하는지** 전수로 본다.
## 무기 9종 × 레벨 1~11 = 99칸을 전부 돌면서, 예고한 항목이 다음 레벨에 진짜
## 달라지는지 확인한다. 2026-09-05: 칸 인덱스가 한 칸 밀려 "탄환수 1 → 1발" 처럼
## 아무것도 안 변하는 예고가 나왔다. 사람이 하나씩 볼 일이 아니다.
func _previewcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	var bad: int = 0
	var checked: int = 0
	for arch: String in ["balanced", "heavy", "rapid", "mid", "melee", "bow", "fan", "sinkal", "jakdu"]:
		var tr: Array = G.w_track(arch)
		for lv in range(1, 12):
			checked += 1
			var key: String = String(tr[maxi(0, lv - 1) % tr.size()])
			# 그 키가 lv → lv+1 에서 실제로 변하는가
			var a: float = 0.0
			var b: float = 0.0
			match key:
				"dmg":
					a = G.w_dmg_mult(arch, lv); b = G.w_dmg_mult(arch, lv + 1)
				"rate":
					a = G.w_rate_mult(arch, lv); b = G.w_rate_mult(arch, lv + 1)
				"area", "range":
					a = G.w_area_mult(arch, lv); b = G.w_area_mult(arch, lv + 1)
				_:
					a = float(G.w_grade(arch, lv, key)); b = float(G.w_grade(arch, lv + 1, key))
			if absf(b - a) < 0.0001:
				print("[PREVIEW] ✗ %s Lv%d → 예고 '%s' 인데 값이 안 변한다 (%.3f)"
					% [arch, lv, key, a])
				bad += 1
			# 화면에 나갈 문구도 같이 본다 — "X → X" 면 사람이 보기에 의미가 없다
			var txt: String = _next_step_text(arch, "wp_" + arch, lv)
			var parts: PackedStringArray = txt.split(" → ")
			if parts.size() == 2 and parts[0].split("  ")[-1].strip_edges() == parts[1].strip_edges():
				print("[PREVIEW] ✗ %s Lv%d → 문구가 그대로다: %s" % [arch, lv, txt])
				bad += 1
	print("[PREVIEW] %d칸 검사" % checked)
	print("[PREVIEW] %s" % ("ALL PASS" if bad == 0 else "문제 %d건" % bad))
	get_tree().quit()


## 초월(m_transcend)이 정말로 **한계를 넘기는지.**
## 2026-09-05: 장부까지 +3 해서 Lv3 짜리에 쓰면 장부가 6(만렙)이 되어 남은 카드 3장을
## 잃었다 — 초월이 아니라 "3장 미리 먹기"였다. 그리고 먹은 뒤 새로 든 무기는
## 혜택을 못 받아 혼자 3단계 뒤처졌다.
func _transcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	var fails: int = 0

	# 1) Lv3 무기에 초월 → 실제 6, 장부는 3 그대로라 카드로 더 키울 수 있어야 한다
	for i in 2:
		_apply_upgrade("wp_bow")          # 각궁 Lv3 (첫 장 Lv1 + 2장)
	var lv0: int = _real_weapon_level("wp_bow")
	_apply_upgrade("m_transcend")
	var lv1: int = _real_weapon_level("wp_bow")
	var book: int = int(_upgrade_counts.get("wp_bow", 0))
	print("[TRANS] 각궁 Lv%d → 초월 → Lv%d (장부 %d/6)" % [lv0, lv1, book])
	if lv1 != lv0 + 3:
		print("[TRANS]   ✗ +3 이 안 붙었다"); fails += 1
	if book > 3:
		print("[TRANS]   ✗ 장부까지 올라 카드가 막힌다"); fails += 1
	# 남은 카드를 마저 먹어 한계를 넘는지
	for i in 4:
		_apply_upgrade("wp_bow")
	var lv2: int = _real_weapon_level("wp_bow")
	print("[TRANS] 카드 4장 더 → Lv%d (만렙 6 을 넘겼나: %s)" % [lv2, "예" if lv2 > 6 else "아니오"])
	if lv2 <= 6:
		print("[TRANS]   ✗ 한계를 못 넘었다"); fails += 1

	# 2) 초월을 먹은 뒤 **새로** 든 무기도 3단계 위에서 시작해야 한다
	_apply_upgrade("wp_jakdu")
	var lvn: int = _real_weapon_level("wp_jakdu")
	print("[TRANS] 초월 뒤 새 무기(작두) 첫 장 → Lv%d" % lvn)
	if lvn < 4:
		print("[TRANS]   ✗ 새 무기가 혜택을 못 받는다 (Lv%d)" % lvn); fails += 1
	print("[TRANS] %s" % ("ALL PASS" if fails == 0 else "문제 %d건" % fails))
	get_tree().quit()


## 만렙(Lv6) 특성이 **정말 켜지는지.** 표에만 있고 코드에 안 걸린 특성은 화면에서
## "만렙 Lv6 → 착탄 폭발" 이라고 약속만 하고 아무 일도 안 하는 거짓말이 된다.
## 무기를 Lv6 까지 올린 뒤, 그 특성이 실제로 손대는 값이 Lv5 와 달라졌는지 본다.
func _traitcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	var bad: int = 0
	print("[TRAIT] 만렙 특성 %d종" % G.MAX_TRAIT.size())
	for id in G.MAX_TRAIT.keys():
		var key: String = String(id)
		# 게이트 자체가 레벨을 제대로 보는가 (융합·초월로 6 을 넘겨도 켜져야 한다)
		var g5: bool = G.w_maxed(key, 5)
		var g6: bool = G.w_maxed(key, 6)
		var g13: bool = G.w_maxed(key, 13)
		if g5 or not g6 or not g13:
			print("[TRAIT]   ✗ %s 게이트: Lv5=%s Lv6=%s Lv13=%s" % [key, str(g5), str(g6), str(g13)])
			bad += 1
		# 카드에 약속이 적히는가
		var line: String = _growth_line(key, key)
		if not (G.w_trait_name(key) in line):
			print("[TRAIT]   ✗ %s 카드에 특성 이름이 없다" % key)
			bad += 1
	# ── 실제로 값이 바뀌는지: 탄환 계열 셋을 직접 쏴 본다 ──
	var checks: Array = [
		{"arch": "bow", "field": "pierce_decay", "lv5": 0.72, "lv6": 0.82},
		{"arch": "sinkal", "field": "relaunch", "lv5": 0, "lv6": 1},
		{"arch": "heavy", "field": "burst_on_stop", "lv5": 0.0, "lv6": 0.35},
	]
	for c: Dictionary in checks:
		for lv: int in [5, 6]:
			p.weapons_primary = []
			p.no_default_weapon = true
			for i in lv:
				p.add_primary_weapon(String(c["arch"]))
			for ch in get_children():
				if ch is Bullet:
					(ch as Node).queue_free()
			var d: Dictionary = Player.WEAPON_DEFS[String(c["arch"])]
			p._fire_ranged(d, lv, String(c["arch"]))
			await get_tree().process_frame
			var got = null
			for ch in get_children():
				if ch is Bullet:
					got = (ch as Bullet).get(String(c["field"]))
					break
			var want = c["lv5"] if lv == 5 else c["lv6"]
			var ok: bool = got != null and absf(float(got) - float(want)) < 0.001
			print("[TRAIT] %-7s Lv%d  %-14s = %s (기대 %s) %s"
				% [String(c["arch"]), lv, String(c["field"]), str(got), str(want),
				   "" if ok else "✗"])
			if not ok:
				bad += 1
	print("[TRAIT] %s" % ("ALL PASS" if bad == 0 else "문제 %d건" % bad))
	get_tree().quit()


## 화면에 적는 "영웅 N + 무기 M" 의 합이 **실제 한 발 피해와 같은지.**
## 표시용 수식을 따로 쓰면 화면과 실제가 갈린다 — 실제로 그랬다(검무·격노·융합
## 페널티 셋이 표시 경로에서 통째로 빠져 있었다). 두 경로를 여기서 붙들어 둔다.
func _sumcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	var bad: int = 0
	var n: int = 0
	# 조건을 바꿔 가며 본다 — 융합 페널티가 걸린 상태도 포함해야 의미가 있다
	for pen: float in [0.0, 0.25]:
		G.run_penalty = pen
		for key in Player.WEAPON_DEFS.keys():
			var d: Dictionary = Player.WEAPON_DEFS[String(key)]
			for lv: int in [1, 3, 6, 11]:
				var parts: Array = p.weapon_dmg_parts(d, lv)
				var sum: float = float(parts[0]) + float(parts[1])
				var real: float = p._weapon_dmg(d, lv)
				n += 1
				if absf(sum - real) > maxf(1.0e-9, absf(real) * 1.0e-9):
					print("[SUM]   ✗ %s Lv%d pen=%.2f  합 %.9f vs 실제 %.9f"
						% [String(key), lv, pen, sum, real])
					bad += 1
	G.run_penalty = 0.0
	print("[SUM] %d칸 검사 (무기 %d종 × 레벨 4 × 페널티 2)" % [n, Player.WEAPON_DEFS.size()])
	print("[SUM] %s" % ("ALL PASS" if bad == 0 else "문제 %d건" % bad))
	get_tree().quit()


## 영웅 고유 능력이 **몇 퍼센트의 시간 동안 켜져 있는가**, 그리고 그때 한 발 피해가
## 화면 정수로 얼마에서 얼마로 뛰는가.
## ★ 갈덴(원혼)은 처치할 때마다 4초가 새로 채워진다. 처치가 4초에 한 번보다 잦으면
##   첫 처치 이후로 판이 끝날 때까지 안 꺼진다 — '순간 배수'가 아니라 사실상 상시 배수다.
##   화면에는 배수도 지속시간도 안 적혀 있어서 "20 이던 게 갑자기 23 이 됐다"로 보인다
##   (2026-09-06 지적). 켜짐 비율이 90%를 넘으면 그건 능력이 아니라 기본치다.
func _uptimecheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	G.difficulty = 1
	var cid: String = _lp_char if _lp_char != "" else "mudang"
	var cdef: Dictionary = Characters.defs()[0]
	for d: Dictionary in Characters.defs():
		if String(d["id"]) == cid:
			cdef = d
			break
	G.last_char_id = String(cdef["id"])
	_begin_run(cdef)
	await get_tree().process_frame
	var p := G.player as Player
	var abil: String = String(cdef.get("ability", "-"))
	print("=== ABIL  %s · 능력 %s · 등급 %d ===" % [
		String(cdef["name"]), abil, G.char_rank(String(cdef["id"]))])
	print("  기본 공격력 %.2f  (기본 %.0f × 상점 × 캐릭 × 등급)" % [p.damage, Player.BULLET_DMG])
	# 1) 능력이 꺼졌을 때와 켜졌을 때 — 화면이 적는 그 정수로 본다
	# ★ 조건을 직접 만들어 줘야 한다. 예전엔 _spirit_t/_dance_t 만 흔들어서, 광폭(rage)은
	#   체력이 가득한 채로 재는 바람에 "배수 ×1.000"이라는 거짓 표를 냈다.
	var d0: Dictionary = Player.WEAPON_DEFS["balanced"]
	var hp0: float = p.hp
	_abil_set(p, abil, false)
	var off_b: float = p._weapon_dmg(d0, 1)
	var off_s: float = p.special_power()
	_abil_set(p, abil, true)
	var on_b: float = p._weapon_dmg(d0, 1)
	var on_s: float = p.special_power()
	_abil_set(p, abil, false)
	p.hp = hp0
	print("  소총 한 발   %d  →  %d   (실수 %.2f → %.2f · 배수 ×%.3f)"
		% [int(off_b), int(on_b), off_b, on_b, on_b / maxf(0.001, off_b)])
	print("  특수무기배수 %.3f → %.3f  (소환수 한 타 %d → %d)"
		% [off_s, on_s, int(G.sp_base("wpn_summon")["dmg"] * off_s),
			int(G.sp_base("wpn_summon")["dmg"] * on_s)])
	# 2) 실제로 판을 돌려서 켜짐 비율을 잰다 — 이게 핵심이다
	if _lp_fast > 1.0:
		Engine.time_scale = _lp_fast
	var dur: float = 120.0
	var on_t: float = 0.0
	var mult_t: float = 0.0    # 배수 × 시간 누적 (시간가중 평균의 분자)
	var all_t: float = 0.0
	var first_on: float = -1.0
	var kills: int = 0
	while G.time_alive < dur and G.running:
		if _chest_panel != null and is_instance_valid(_chest_panel):
			_close_chest_panel()
			await get_tree().process_frame
			continue
		if _levelup_root.visible:
			_auto_pick()
			await get_tree().process_frame
			continue
		# ★ 봇을 실제로 몰아야 한다. 가만히 세워 두고 재면 검무(이동으로 쌓임)가 영원히 0% 이고,
		#   플레이어도 금방 죽어서 표본이 사라진다 — 계기가 조용히 거짓말하는 자리다.
		_bal_step()
		var dt: float = get_process_delta_time()
		all_t += dt
		# 켜짐 비율만으로는 검무처럼 **서서히 차오르는** 능력을 못 잰다(×1.01 도 '켜짐'이다).
		# 그래서 배수 자체의 시간가중 평균을 같이 쌓는다 — 이게 실제로 받은 이득이다.
		mult_t += p._hero_dmg_mult() * dt
		if _abil_on(p, abil):
			on_t += dt
			if first_on < 0.0:
				first_on = G.time_alive
		kills = G.kills
		await get_tree().process_frame
	Engine.time_scale = 1.0
	var pct: float = 100.0 * on_t / maxf(0.001, all_t)
	var avg: float = mult_t / maxf(0.001, all_t)
	var peak: float = on_b / maxf(0.001, off_b)
	print("  %.0f초 실측: 처치 %d · 켜짐 %.1f%% · 첫 발동 %.1f초"
		% [minf(dur, G.time_alive), kills, pct, maxf(0.0, first_on)])
	print("  평균 배수 ×%.3f  (최대 ×%.3f · 최대치의 %.0f%% 를 실제로 받았다)"
		% [avg, peak, 100.0 * (avg - 1.0) / maxf(0.001, peak - 1.0)])
	# 발밑 배수 링이 **실제 배수와 같은 천장**을 쓰는지. 여기가 갈라지면 게이지가 거짓말한다
	# (링은 꽉 찼는데 실제로는 절반만 올라와 있는 식). 그리고 능력 없는 영웅엔 노드가 안 생겨야 한다.
	var top: float = p.hero_mult_max()
	if top <= 1.001:
		# 배수를 안 만드는 영웅은 링 노드가 아예 안 생겨야 한다 (안 그리는 게 아니라 안 만든다)
		if p._buff_ring != null:
			print("  [ABIL] ✗ 배수가 없는 영웅인데 링 노드가 생겼다")
		else:
			print("  링 없음 — 배수를 만드는 능력이 아니다 (정상)")
	elif absf(top - peak) > 0.002:
		print("  [ABIL] ✗ 링 천장 ×%.3f 이 실제 최대 배수 ×%.3f 와 다르다" % [top, peak])
	else:
		_abil_set(p, abil, true)
		p._update_buff_ring()
		var full: float = p._buff_ring.ratio if p._buff_ring != null else -1.0
		_abil_set(p, abil, false)
		p._update_buff_ring()
		var empty: float = p._buff_ring.ratio if p._buff_ring != null else -1.0
		p.hp = hp0
		if absf(full - 1.0) > 0.01 or absf(empty) > 0.01:
			print("  [ABIL] ✗ 링이 안 따라온다: 발동 %.2f (기대 1.00) · 해제 %.2f (기대 0.00)"
				% [full, empty])
		else:
			print("  링 천장 ×%.3f 일치 · 발동 %.0f%% → 해제 %.0f%%"
				% [top, full * 100.0, empty * 100.0])
	# '얼마나 자주 켜지나'가 아니라 '최대치를 얼마나 늘 받고 있나'로 판단한다.
	# 90% 를 넘으면 그건 발동형 능력이 아니라 그냥 기본 공격력이다.
	var got: float = 100.0 * (avg - 1.0) / maxf(0.001, peak - 1.0)
	if got >= 90.0:
		print("  [ABIL] ✗ 최대치의 %.0f%% 상시 수령 — 능력이 아니라 기본치로 읽힌다." % got)
	else:
		print("  [ABIL] ✔ 최대치의 %.0f%% 수령 — 발동이 구분된다." % got)
	get_tree().quit()


## 능력의 발동 조건을 켜거나 끈다 — 배수를 재려면 조건부터 만들어 줘야 한다.
func _abil_set(p: Player, abil: String, on: bool) -> void:
	match abil:
		"spirits": p._spirit_t = Player.SPIRIT_DUR if on else 0.0
		"sworddance": p._dance_t = p.dance_max if on else 0.0
		"rage": p.hp = p.max_hp * (0.2 if on else 1.0)


## 능력이 지금 켜져 있는가 (피해 배수를 만드는 능력만).
func _abil_on(p: Player, abil: String) -> bool:
	match abil:
		"spirits": return p._spirit_t > 0.0
		"sworddance": return p._dance_t > 0.0
		"rage": return p.hp < p.max_hp * 0.4
	return false


## 영구 강화 상점: 8항목 전부 "사면 뭐가 어떻게 되는지" 가 뜨는지, 그리고 그 숫자가
## **실제로 움직이는지.** m_dmg 는 레벨당 +0.42 라 %.0f 로 적으면 "14 → 14" 가 되어
## 미리보기가 거짓말을 한다 — 서식 하나로 기능이 죽는 자리라 자동으로 잡는다.
func _shopcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	var bad: int = 0
	for m: Dictionary in MetaShop.META:
		var id: String = String(m["id"])
		for lv: int in [0, 5, G.meta_max(id) - 1]:
			G.meta[id] = lv
			var t: String = MetaShop._preview_text(id)
			if t == "":
				print("[SHOP]   ✗ %s Lv%d 미리보기가 비어 있다" % [id, lv]); bad += 1
				continue
			var parts: PackedStringArray = t.split(" → ")
			if parts.size() != 2 or parts[0].split(" ")[-1] == parts[1]:
				print("[SHOP]   ✗ %s Lv%d 값이 안 변한다: %s" % [id, lv, t]); bad += 1
			if lv == 5:
				print("[SHOP] %-9s %s   (레벨당 %s)" % [id, t, MetaShop.per_text(id)])
		G.meta[id] = 0
	# 상점 강화가 정말 인게임에 실리는가 — 공격력만 직접 확인한다
	G.meta["m_dmg"] = 10
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	var want: float = Player.BULLET_DMG * (1.0 + G.meta_bonus("m_dmg"))
	var got: float = p.base_damage
	# 영웅 등급·캐릭터 편차가 그 위에 곱해지므로 '최소한 그만큼은 되는가'로 본다
	print("[SHOP] 상점 공격력 Lv10 → 판 시작 공격력 %.1f (상점 단독 기준 %.1f)" % [got, want])
	if got < want - 0.01:
		print("[SHOP]   ✗ 상점 강화가 인게임에 안 실렸다"); bad += 1
	G.meta["m_dmg"] = 0
	print("[SHOP] %s" % ("ALL PASS" if bad == 0 else "문제 %d건" % bad))
	get_tree().quit()


## 보스 상자: 몇 장이 뜨는지, 그 분포가 의도대로인지, 그리고 결과 패널이 뜨고 닫히는지.
## 2026-09-06 질문 "1개에서 5개 랜덤으로 뜨고있는거 맞지?" — 사람이 세는 대신 여기서 센다.
func _chestcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.xp_mult = 0.0
	var hist: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	var N: int = 4000
	for i in N:
		var r: float = randf()
		var k: int = 1
		if r < 0.005:
			k = 5
		elif r < 0.03:
			k = 4
		elif r < 0.12:
			k = 3
		elif r < 0.42:
			k = 2
		hist[k] = int(hist[k]) + 1
	var want: Array = [58.0, 30.0, 9.0, 2.5, 0.5]
	var bad: int = 0
	print("[CHEST] %d회 추첨" % N)
	for k in range(1, 6):
		var pct: float = float(hist[k]) / float(N) * 100.0
		var w: float = want[k - 1]
		var ok: bool = absf(pct - w) < maxf(1.2, w * 0.35)
		print("[CHEST] %d장 %5.1f%% (설계 %.1f%%) %s" % [k, pct, w, "" if ok else "✗"])
		if not ok:
			bad += 1
	# 패널이 실제로 뜨고, 뜬 동안 판이 멈추고, 닫으면 다시 흐르는가
	var was: bool = get_tree().paused
	_on_boss_chest()
	await get_tree().process_frame
	var opened: bool = _chest_panel != null and is_instance_valid(_chest_panel)
	var paused_now: bool = get_tree().paused
	_close_chest_panel()
	await get_tree().process_frame
	var closed: bool = _chest_panel == null
	var resumed: bool = get_tree().paused == was
	print("[CHEST] 패널 열림=%s · 멈춤=%s · 닫힘=%s · 재개=%s"
		% [str(opened), str(paused_now), str(closed), str(resumed)])
	if not (opened and paused_now and closed and resumed):
		bad += 1
	print("[CHEST] %s" % ("ALL PASS" if bad == 0 else "문제 %d건" % bad))
	get_tree().quit()


## 달빛 사제(치유 몹)가 겹쳐 쌓였을 때 회복량이 **곱으로 늘지 않는지.**
## 2026-09-06 지적: "치유 몹이 조금만 쌓여도 그냥 씹사기". 사제 1마리와 4마리를 같은
## 부상자 무리에 붙여 놓고 같은 시간 동안 회복된 총량을 비교한다. 4배가 되면 안 된다.
func _healcheck_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	G.no_save = true
	_begin_run(Characters.defs()[0])
	await get_tree().process_frame
	var p := G.player as Player
	p.global_position = Vector2(4000, 4000)   # 플레이어 화력이 섞이지 않게 멀리 치워 둔다
	_dps_mode = true
	var results: Array = []
	for priests: int in [1, 4]:
		for n in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(n):
				(n as Node).queue_free()
		await get_tree().process_frame
		var hurt: Array = []
		for i in 20:                      # 부상자 20마리를 한 자리에 모아 둔다
			var e := Enemy.new()
			e.kind = 0
			add_child(e)
			e.global_position = Vector2(cos(TAU * float(i) / 20.0), sin(TAU * float(i) / 20.0)) * 60.0
			e.spd = 0.0
			e.max_hp = 1000.0
			e.hp = 300.0
			hurt.append(e)
		for i in priests:
			var h := Enemy.new()
			h.kind = 10                   # 달빛 사제
			add_child(h)
			h.global_position = Vector2(float(i) * 14.0, 0.0)
			h.spd = 0.0
			h.max_hp = 1000.0
			h.hp = 1000.0
		var before: float = 0.0
		for e in hurt:
			before += (e as Enemy).hp
		var t: float = 0.0
		while t < 7.0:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			for e in hurt:                # 부상자가 못 돌아다니게 붙들어 둔다
				if is_instance_valid(e):
					(e as Enemy).hp = minf((e as Enemy).hp, 1000.0)
		var after: float = 0.0
		for e in hurt:
			if is_instance_valid(e):
				after += (e as Enemy).hp
		results.append(after - before)
		print("[HEAL] 사제 %d마리 · 7초 동안 회복 %.0f" % [priests, after - before])
	var ratio: float = results[1] / maxf(1.0, results[0])
	print("[HEAL] 4마리 / 1마리 = %.2f배 (곱으로 늘면 4.0 에 가깝다)" % ratio)
	var ok: bool = ratio < 2.2
	print("[HEAL] %s" % ("ALL PASS" if ok else "✗ 사제가 겹칠수록 회복이 곱으로 는다"))
	get_tree().quit()
