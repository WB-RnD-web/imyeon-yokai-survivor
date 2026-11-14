class_name Characters
extends Object
## 캐릭터 로스터. 기본=능력 없음/균형. 나머지=고유능력 1개 + 기본치 소폭 편차.
## S1: 해금 경제 — 기본 외 전원 잠금. unlock = 조건 자동해금({"stat","need","cond"} 또는
## {"stage","cond"}) + 골드 구매("gold"). 신규 3종(기사/화염술사/그림자 도적)은 운빨디펜스 이식.

## 이 영웅을 **이 등급으로** 골랐을 때 판이 시작되는 능력치.
## ★ 선택 화면이 "등급 보너스: 공격 +15%" 라고만 적고 있었다. 15가 무엇에 붙는 15인지
##   안 알려주니 별을 하나 더 찍어도 뭐가 달라지는지 알 수 없다(2026-09-06 지적).
##   실수치를 적으려면 실제 런과 **같은 식**이어야 하므로 여기 한 곳에만 둔다 —
##   player.gd 의 meta 적용부(1200~) + apply_character 의 mods/등급 적용부와 같은 순서다.
##   어긋나면 --rankcheck 가 실제 apply_character 결과와 대조해서 잡는다.
static func start_stats(def: Dictionary, rank: int) -> Dictionary:
	var m: Dictionary = def.get("mods", {})
	var dmg: float = Player.BULLET_DMG * (1.0 + G.meta_bonus("m_dmg")) * float(m.get("damage_mult", 1.0))
	var hp: float = Player.MAX_HP + G.meta_bonus("m_hp") + float(m.get("hp_add", 0.0))
	var spd: float = Player.SPEED * (1.0 + G.meta_bonus("m_speed")) * float(m.get("speed_mult", 1.0))
	var arm: float = float(m.get("armor_add", 0.0))
	# QA 10/13: 끼운 장신구도 판 시작 값에 들어간다 — player.apply_accessories 와 같은 값(체력 · 이동 · 방어에 닿는 셋만)
	for aid: String in G.acc_equipped():
		match aid:
			"acc_jipsin":
				spd *= 1.06
			"acc_yeomju":
				arm += 1.0
			"acc_durumagi":
				hp += 40.0
				arm += 2.0
	dmg *= 1.0 + G.RANK_DMG * float(rank)
	hp += G.RANK_HP * float(rank)
	spd *= 1.0 + G.RANK_SPD * float(rank)
	arm += G.RANK_ARMOR * float(rank)
	return {"dmg": dmg, "hp": hp, "spd": spd, "armor": arm}


static func defs() -> Array:
	return [
		{
			"id": "base", "name": "울레아", "icon": "regen", "color": Color("52e0cf"),
			"abil": "고유 능력 없음 · 균형", "ability": "", "sprite": "res://assets/sprites/chars/ullea.png", "mods": {},
		},
		{
			"id": "berserker", "name": "타르한", "icon": "dmg", "color": Color("ff5a5a"),
			"abil": "체력 40% 이하일 때 공격력 x1.5", "ability": "rage", "sprite": "res://assets/sprites/chars/tarkhan.png",
			"mods": {"damage_mult": 1.25, "hp_add": -20.0, "speed_mult": 1.05},
			"unlock": {"stat": "total_kills", "need": 800, "cond": "누적 800 처치", "gold": 1800},
		},
		{
			"id": "gunner", "name": "랑데", "icon": "bspeed", "color": Color("54c6ff"),
			"abil": "기본 관통 +1 · 빠른 연사 · 낮은 공격력", "ability": "", "sprite": "res://assets/sprites/chars/rande.png",
			"mods": {"fire_mult": 0.82, "bspeed_mult": 1.2, "damage_mult": 0.9, "pierce_add": 1},
			"unlock": {"stat": "best_time", "need": 480, "cond": "한 판 8분 생존", "gold": 2600},
		},
		{
			"id": "collector", "name": "바스락", "icon": "item_magnet", "color": Color("5c8dff"),
			"abil": "경험치 획득 +30% · 넓은 자석", "ability": "", "sprite": "res://assets/sprites/chars/baseurak.png",
			"mods": {"magnet_add": 120.0, "luck_add": 0.03, "xp_mult": 1.3, "hp_add": -10.0},
			"unlock": {"stat": "runs", "need": 5, "cond": "5판 플레이", "gold": 2200},
		},
		{
			"id": "tank", "name": "갈기 셋째 마루", "icon": "armor", "color": Color("8aa6dd"),
			"abil": "처치 시 체력 소량 회복 · 튼튼하지만 느림", "ability": "lifesteal", "sprite": "res://assets/sprites/chars/maru.png",
			"mods": {"hp_add": 60.0, "armor_add": 4.0, "speed_mult": 0.9},
			"unlock": {"stat": "best_level", "need": 15, "cond": "레벨 15 도달", "gold": 3200},
		},
		{
			"id": "gambler", "name": "깃소금", "icon": "gamble", "color": Color("ff5ca8"),
			"abil": "레벨업 강화를 4개 중 선택 · 10레벨마다 도박 (대개 조금, 드물게 크게 오르거나 내린다)", "ability": "fourcards", "sprite": "res://assets/sprites/chars/gitsogeum.png",
			"mods": {"luck_add": 0.06, "crit_add": 0.08},
			"unlock": {"stat": "total_bosses", "need": 5, "cond": "보스 누적 5 처치", "gold": 4800},
		},
		# ── S1 신규 → S2: '특수 영웅' (운빨디펜스 콜라보 — 전용 보라 프레임·강화된 체급) ──
		{
			"id": "knight", "name": "뒷불 새디", "icon": "dashcd", "color": Color("c8d6ea"), "special": true,
			"abil": "대시가 적을 강타(공격력 220%) · 대시 쿨 -40%", "ability": "dashstrike", "sprite": "res://assets/sprites/chars/sadie_backfire.png",
			"mods": {"armor_add": 2.0, "hp_add": 20.0, "speed_mult": 0.97},
			"unlock": {"stage": 1, "diff": 1, "cond": "스테이지 2(도서관) 보통 이상 클리어", "gold": 9000},
		},
		{
			"id": "pyro", "name": "열두 마디 베른", "icon": "b_fire", "color": Color("ff8a3c"), "special": true,
			"abil": "화염 오라를 갖고 시작 · 특수무기 위력 ×1.25", "ability": "pyro", "sprite": "res://assets/sprites/chars/bern_pipe.png",
			"mods": {"damage_mult": 0.92, "hp_add": -10.0},
			"unlock": {"stat": "total_fusions", "need": 1, "cond": "융합 1회 완성", "gold": 13000},
		},
		{
			"id": "rogue", "name": "회풍", "icon": "crit", "color": Color("b06bff"), "special": true,
			"abil": "대시 후 2초간 치명타 +50%", "ability": "shadow", "sprite": "res://assets/sprites/chars/hoepung.png",
			"mods": {"crit_add": 0.10, "speed_mult": 1.12, "hp_add": -25.0},
			"unlock": {"stage": 2, "diff": 2, "cond": "스테이지 3(정원) 어려움 이상 클리어", "gold": 18000},
		},
		# ── 이면(裏面) 영웅 5종 — 요괴가 나오기 시작한 뒤 문이 열린다 ──
		{
			"id": "mudang", "name": "일곱 맹세의 갈덴", "icon": "wpn_summon", "color": Color("c1272d"), "special": true,
			"abil": I18n.t("소환수를 들고 시작 · 처치하면 %.0f초간 공격력 ×%.2f (처치마다 갱신)") % [
				Player.SPIRIT_DUR, Player.SPIRIT_MULT], "ability": "spirits",
			"sprite": "res://assets/sprites/chars/galden.png",
			"mods": {"damage_mult": 0.94, "luck_add": 0.05, "hp_add": -5.0},
			"unlock": {"stat": "yokai_seen", "need": 3, "cond": "이면 요괴 3종 도감 수집", "gold": 16000},
		},
		{
			"id": "hwarang", "name": "아르잔", "icon": "speed", "color": Color("2e86ab"), "special": true,
			"abil": "검무 · 움직이는 동안 공격력이 올라 최대 ×1.45", "ability": "sworddance",
			"sprite": "res://assets/sprites/chars/arjan_droop.png",
			"mods": {"speed_mult": 1.10, "damage_mult": 0.90, "crit_add": 0.05},
			"unlock": {"stat": "best_stars", "need": 12, "cond": "클리어 별 12개 수집", "gold": 20000},
		},
		{
			"id": "smith", "name": "톨크", "icon": "wp_heavy", "color": Color("a8761f"), "special": true,
			"abil": "무기 카드 한 장에 두 단계 (만렙 6 → 11) · 특수무기 위력 ×1.25", "ability": "forge",
			"sprite": "res://assets/sprites/chars/tolk.png",
			"mods": {"hp_add": 25.0, "speed_mult": 0.95, "damage_mult": 0.95},
			"unlock": {"stat": "total_fusions", "need": 5, "cond": "융합 누적 5회 완성", "gold": 26000},
		},
		{
			"id": "monk", "name": "비나리", "icon": "armor", "color": Color("f0c33c"), "special": true,
			"abil": "염주 · 6초마다 피해 한 번을 흘려보낸다", "ability": "beads",
			"sprite": "res://assets/sprites/chars/binari.png",
			"mods": {"hp_add": 35.0, "armor_add": 2.0, "damage_mult": 0.92, "speed_mult": 0.97},
			"unlock": {"stat": "nohit_clears", "need": 1, "cond": "보스전 무피격 클리어 1회", "gold": 30000},
		},
		{
			"id": "falconer", "name": "리콜", "icon": "b_homing", "color": Color("74849c"), "special": true,
			"abil": "매의 눈으로 노린다 · 탄이 적 쪽으로 살짝 휜다", "ability": "falcon",
			"sprite": "res://assets/sprites/chars/recall.png",
			"mods": {"bspeed_mult": 1.15, "crit_add": 0.06, "hp_add": -15.0},
			"unlock": {"stat": "endless_clears", "need": 1, "cond": "무한 모드 완주 1회", "gold": 36000},
		},
		# ── 저승길 영웅 6종(16차) — 새 능력 코드 없이 시작 무기(start · start_primary)와 기존 능력 · 수치로만 가른다 ──
		{
			"id": "gangrim", "name": "강림", "icon": "wpn_whip", "color": Color("d8d2c0"), "special": true,
			"abil": "채찍을 들고 시작 · 처치하면 체력을 조금 되찾는다", "ability": "lifesteal", "start": "wpn_whip",
			"sprite": "", "mods": {"damage_mult": 1.05, "hp_add": 15.0},
			"unlock": {"stage": 5, "diff": 0, "cond": "스테이지 6(저승길) 클리어", "gold": 40000},
		},
		{
			"id": "seolhwa", "name": "설화", "icon": "wpn_ice", "color": Color("bfe8ff"), "special": true,
			"abil": "빙결 파동을 들고 시작 · 특수무기 위력 ×1.15", "ability": "", "start": "wpn_ice",
			"sprite": "", "mods": {"speed_mult": 1.06, "hp_add": -10.0, "special_mult": 1.15},
			"unlock": {"stat": "total_kills", "need": 20000, "cond": "누적 20,000 처치", "gold": 22000},
		},
		{
			"id": "dudu", "name": "두두", "icon": "wp_melee", "color": Color("d0703a"), "special": true,
			"abil": "대검을 들고 시작 · 튼튼하지만 느리다", "ability": "", "start_primary": "melee",
			"sprite": "", "mods": {"hp_add": 40.0, "armor_add": 2.0, "speed_mult": 0.95},
			"unlock": {"stat": "best_level", "need": 40, "cond": "레벨 40 도달", "gold": 24000},
		},
		{
			"id": "yeon", "name": "연", "icon": "wpn_orb", "color": Color("ff8fb0"), "special": true,
			"abil": "회전 오브를 들고 시작 · 행운과 치명타가 조금 높다", "ability": "", "start": "wpn_orb",
			"sprite": "", "mods": {"luck_add": 0.05, "crit_add": 0.05, "hp_add": -10.0},
			"unlock": {"stat": "total_bosses", "need": 30, "cond": "보스 누적 30 처치", "gold": 26000},
		},
		{
			"id": "mulgyeol", "name": "물결", "icon": "wp_bow", "color": Color("3fb6c8"), "special": true,
			"abil": "각궁을 들고 시작 · 관통 +1", "ability": "", "start_primary": "bow",
			"sprite": "", "mods": {"pierce_add": 1, "bspeed_mult": 1.15, "damage_mult": 0.95},
			"unlock": {"stat": "best_time", "need": 1200, "cond": "한 판 20분 생존", "gold": 28000},
		},
		{
			"id": "doyun", "name": "도윤", "icon": "wpn_chain", "color": Color("9a8cff"), "special": true,
			"abil": "번개 사슬을 들고 시작 · 경험치 +10%", "ability": "", "start": "wpn_chain",
			"sprite": "", "mods": {"xp_mult": 1.1, "luck_add": 0.04, "hp_add": -10.0},
			"unlock": {"stat": "mon_seen", "need": 30, "cond": "몬스터 도감 30종", "gold": 32000},
		},
	]


static func unlock_of(id: String) -> Dictionary:
	for d: Dictionary in defs():
		if String(d["id"]) == id:
			return d.get("unlock", {})
	return {}


static func def_of(id: String) -> Dictionary:
	for d: Dictionary in defs():
		if String(d["id"]) == id:
			return d
	return defs()[0]
