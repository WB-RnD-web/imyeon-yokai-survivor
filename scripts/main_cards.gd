extends Node2D
## 카드 계층 — 무엇을 고를 수 있고, 그게 화면에 어떻게 적히는가.
##
## 카드 목록 · 등급 추첨 가중치 · 슬롯 분류와 상한 · 융합 레시피 · 이번 판 장부,
## 그리고 **모든 실수치 표기**가 여기 한 곳에 있다.
##
## ★ 2026-09-06: 표기가 여기저기 흩어져 있던 것이 화근이었다. 카드 제목만 고치고
##   나머지 세 경로(_base_pool 의 n · _CARD_SPEC · _stat_total · G.w_next_label)를
##   놓쳐서, 카드에는 실수치가 뜨는데 ESC 빌드 패널에는 "+26%" 가 그대로 남았다.
##   표기를 만드는 함수는 앞으로 전부 이 파일 안에만 둔다 — 밖에서 새 수식을 쓰면
##   화면과 실제가 또 갈린다.
##
## 이 층은 아레나도 웨이브도 모른다. 파생 클래스(MainGame)가 이걸 쓴다.
class_name MainCards


## ★ 유물 상한(C+안). 6/6 은 사실상 '거의 다 가져간다'라 선택이 없었고, 그래서 한 축으로 모이지
##   않아 융합도 안 떴다. 4/4 로 조이고, 아래 _populate_cards 의 '보유 유물 보장 1장'이 수렴을 만든다.
##   스탯 카드는 상한에 넣지 않는다 — 넣으면 후반에 고를 게 없어져 레벨업이 벌칙이 된다.
## 한 런에서 완성할 수 있는 융합 수. 2였을 때 도전과제 '삼중 융합'(한 판 3종)이 영구 달성 불가였다.
## ★ 더 이상 상한으로 쓰지 않는다(2026-09-07). 융합 결과가 무기 칸을 차지하도록 바뀌면서
## 융합 횟수는 WEAPON_SLOTS 가 자연히 막는다. 값은 도감·통계 표기용으로만 남겨 둔다.
const MAX_FUSIONS: int = 3


const WEAPON_SLOTS: int = 4   # 뱀서식 무기 슬롯 상한 (가득 차면 새 무기 X, 기존 강화만)


## ★ 2026-09-06 재편: 분류가 무기/탄막/융합 셋이었는데 "탄막"을 상수는 PASSIVE 라 부르고
##   화면은 "탄막"이라 불러서 이미 어긋나 있었다. 게다가 판을 뒤집는 전설·신화는 어느 분류에도
##   없어서 ESC 에 칸이 안 잡혔다. 이제 넷이다 — 무기 / 탄막 / 패시브 / 융합.
##     탄막  b_*        명중 시 발동하는 부여 효과
##     패시브 l_* m_*   상시로 판을 바꾸는 전설·신화 (얻을 수 있는 최대치가 정확히 4다:
##                      전설 3종 + 신화 1장(MYTHIC_PER_RUN) — 그래서 n/4 가 거짓이 아니다)
##   스탯 강화(공격력·치명타…)는 일부러 칸 밖에 둔다. 상한에 넣으면 후반에 고를 게 없어져
##   레벨업이 벌칙이 된다 — 스탯이 전체 픽의 3분의 2다.
const BULLET_SLOTS: int = 4
const PASSIVE_SLOTS: int = 4


# 모든 카드를 다 모으면(풀 소진) 나오는 대체 카드 2종 — 회복과 골드를 분리(따로 선택)
const HEAL_CARD: Dictionary = {"id": "heal_card", "n": "휴식 (회복)", "d": "체력 30% 회복", "max": 0}


const GOLD_CARD: Dictionary = {"id": "gold_card", "n": "노다지 (골드)", "d": "골드를 즉시 획득", "max": 0}


# 진화(융합) = '특정 조합' 재료를 모으면 카드 등장.
# ★ 예전엔 12종 중 10종이 숨겨져 있었다(revealed:false). 몬테카를로로 재보니 '아무거나 고르는'
#   플레이에서 30분 런 융합 도달률이 0.1% 인데, 조합 하나를 정조준하면 94% 다 — 즉 진짜 장벽은
#   요구 레벨이 아니라 '뭘 노려야 하는지 모른다'였다. 그래서 전부 공개로 돌린다.
# M37 개편:
#  - 융합 시 재료가 '소멸'하고(슬롯 1칸 해방) 이를 커버하는 초월 강화판이 재부여됨
#  - 조합: 무기+속성 / 무기+무기 / 속성+속성 모두 존재
#  - revealed=true인 레시피만 도감에 처음부터 공개, 나머지는 직접 완성해야 도감 등록
const EVOLUTIONS: Array = [
	{"id": "evo_inferno", "n": "지옥불", "d": "불길이 훨씬 넓게 타올라 닿는 것을 태운다", "req": ["wpn_fire", "b_fire"], "revealed": true},
	{"id": "evo_blizzard", "n": "절대영도", "d": "빙결 파동이 겹겹이 깔려 얼려 세운다", "req": ["wpn_ice", "b_ice"], "revealed": true},
	{"id": "evo_plague", "n": "역병", "d": "독이 계속 번져 지나간 자리가 썩는다", "req": ["wpn_poison", "b_poison"], "revealed": true},
	{"id": "evo_railcannon", "n": "레일건", "d": "포탄이 긴 창이 되어 줄지어 꿰뚫는다", "req": ["wp_heavy", "b_big"], "revealed": true},  # S5: 무기+탄막 조합으로 재편
	{"id": "evo_tempest", "n": "폭풍군주", "d": "번개가 더 멀리·많이 옮겨 붙는다", "req": ["wpn_chain", "b_shock"], "revealed": true},
	{"id": "evo_legion", "n": "군단", "d": "소환수가 정령의 얼음탄을 쏘고 더 멀리까지 나간다", "req": ["wpn_summon", "summon_ice"], "revealed": true},
	{"id": "evo_reaper", "n": "사신의 낫", "d": "휘두르는 반경이 커지고 약한 것은 즉사", "req": ["wpn_whip", "b_exec"], "revealed": true},
	{"id": "evo_nova", "n": "초신성", "d": "레이저가 여러 갈래로 늘어 사방을 지진다", "req": ["wpn_beam", "b_fire"], "revealed": true},
	{"id": "evo_deadeye", "n": "필중의 눈", "d": "모든 탄이 흰 침이 되어 급소에 꽂힌다", "req": ["wp_rapid", "crit"], "revealed": true},
	# ── 이면 융합 3종 ──
	{"id": "evo_ninetail", "n": "구미호의 꼬리", "d": "부챗살이 아홉 갈래로 퍼지며 번개가 옮는다", "req": ["wp_fan", "b_chain"], "revealed": true},
	{"id": "evo_ledger", "n": "명부", "d": "화살이 줄지어 꿰뚫고 적힌 것은 끝난다", "req": ["wp_bow", "b_exec"], "revealed": true},
	{"id": "evo_orb", "n": "여의주", "d": "금빛 궤적으로 베고 벤 만큼 회복한다", "req": ["wp_jakdu", "b_vamp"], "revealed": true},
]


var _last_char: Dictionary = {}


var _upgrade_counts: Dictionary = {}


var _evolved: Dictionary = {}


var _consumed: Dictionary = {}  # 융합 재료로 소멸한 카드 id → 카드 풀에서 영구 제외(이번 런)


func _is_weapon_id(id: String) -> bool:
	return id.begins_with("wp_") or id.begins_with("wpn_") or id == "summon_ice"


## 탄막 부여 — 명중 시 발동
func _is_bullet_id(id: String) -> bool:
	return id.begins_with("b_")


## 상시 패시브 — 전설·신화
func _is_passive_id(id: String) -> bool:
	return id.begins_with("l_") or id.begins_with("m_")


## 그 분류로 몇 칸을 썼는가. cat: "무기" · "탄막" · "패시브"
## ★ 예전엔 bool 하나(want_weapon)라 두 분류밖에 표현 못 했다. 넷이 된 지금 그대로 두면
##   호출하는 쪽마다 자기 규칙을 다시 쓰게 되고, 그러면 또 갈린다.
## ★ 무기 칸은 장부가 아니라 **지금 실제로 들고 있는 무기**로 센다(2026-09-07).
##   예전엔 장부만 봐서, 융합하면 재료 2칸이 비고 결과 무기는 **어느 칸으로도 안 세어졌다** —
##   융합 결과가 공짜로 얹히는 셈이라 '융합 n/3' 이라는 별도 상한이 필요했다.
##   이제 결과 무기가 자기 분류(무기) 칸을 그대로 차지하므로, 융합 횟수는 무기 칸이 알아서
##   제한한다. 별도 융합 칸을 없앤 근거가 이것이다.
##   탄막·패시브는 노드가 아니라 플레이어 스탯이라 장부가 유일한 근거다 — 그대로 둔다.
func _owned_slot_count(cat: String) -> int:
	var n: int = 0
	if cat == "무기":
		var seen_w: Dictionary = {}
		for cid: String in _held_weapon_cards():
			if cid == "wp_balanced" or seen_w.has(cid):
				continue      # 시작 소총은 '내가 고른 무기'가 아니다
			seen_w[cid] = true
			n += 1
		return n
	for k in _upgrade_counts.keys():
		if int(_upgrade_counts[k]) <= 0:
			continue
		var id: String = String(k)
		# ★ 시작 소총은 칸을 안 먹는다. 모두에게 그냥 쥐어주는 것이라 '내가 고른 무기'가 아닌데,
		#   런 시작에 장부(_upgrade_counts)에 1 이 박히는 바람에 모든 영웅이 1/4 로 시작했다.
		#   융합 재료도 안 되고 초월 대상도 아닌 무기가 칸 하나를 잡고 있던 셈이다(2026-09-05 지적).
		#   장부에는 그대로 두므로 카드 별 표시·초월 +3·만렙 판정은 예전 그대로다.
		if id == "wp_balanced":
			continue
		match cat:
			"무기":
				if _is_weapon_id(id):
					n += 1
			"탄막":
				if _is_bullet_id(id):
					n += 1
			"패시브":
				if _is_passive_id(id):
					n += 1
	return n


## 일시정지 빌드 패널용: 소유한 무기/탄막(패시브) 요약 {id, name, desc, level, max, kind}
## 그 무기가 **실제로** 몇 레벨인가. 카드 장부(_upgrade_counts)가 아니다.
## ★ 게임에는 무기 레벨이 두 벌 있다 — 실제 레벨(상한 없음)과 카드 장부(상한 6).
##   톨크의 벼림은 실제 레벨만 올리고 장부는 안 올려서 둘이 벌어진다. 그래서 ESC 왼쪽은
##   Lv11 인데 오른쪽 빌드 패널은 Lv6 MAX 라고 적히는 일이 생겼다(2026-09-05 지적).
##   화면에는 전부 실제 레벨을 쓴다 — 플레이어가 겪는 것이 그쪽이다.
func _real_weapon_level(id: String) -> int:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return 0
	if _WP_KEY.has(id):
		var arch: String = String(_WP_KEY[id])
		for w in p.weapons_primary:
			if String(w["id"]) == arch:
				return int(w["level"])
		return 0
	var nd: Node = p.weapons.get(id, null)
	if nd != null and is_instance_valid(nd):
		return int(nd.get("level"))
	return 0


## 융합 id → EVOLUTIONS 정의 (없으면 빈 사전).
func _evo_def(eid: String) -> Dictionary:
	for ev: Dictionary in EVOLUTIONS:
		if String(ev["id"]) == eid:
			return ev
	return {}


## 지금 **실제로 들고 있는** 무기들의 카드 id. 장부가 아니라 플레이어 노드가 기준이다 —
## 융합으로 장부에서 지워진 무기도 여기엔 남는다.
func _held_weapon_cards() -> Array:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return []
	var out: Array = []
	var rev: Dictionary = {}
	for c in _WP_KEY.keys():
		rev[String(_WP_KEY[c])] = String(c)   # 아키타입 → 카드 id
	for w in p.weapons_primary:
		var arch: String = String((w as Dictionary)["id"])
		if arch == "balanced":
			continue                          # 시작 소총은 '내가 고른 무기'가 아니다
		out.append(String(rev.get(arch, arch)))
	for k in p.weapons.keys():
		if is_instance_valid(p.weapons[k]):
			out.append(String(k))             # 특수무기는 카드 id 가 곧 무기 id
	return out


## 카드 풀에서 그 카드의 원본 정의를 꺼낸다 (없으면 빈 사전).
func _card_def(id: String) -> Dictionary:
	for u: Dictionary in _upgrade_pool():
		if String(u["id"]) == id:
			return u
	return {}


## 화면에 적을 레벨. 무기는 **무기가 실제로 쓰는 값**, 나머지는 고른 횟수.
## ★ 특수무기는 첫 픽에서 Lv2 로 시작한다(main_game.gd 의 "즉시 체감" 보정). 그런데 카드는
##   고른 횟수만 세고 있어서 무기가 늘 한 칸 앞서 있었다 — 10종 전부. 그래서 "만렙 Lv6" 이라
##   적어 놓은 특성이 화면 Lv5 에서 터졌다(2026-09-06 신고, --lvlcheck 가 전수로 확인).
##   ESC 빌드 패널과 성장 예고는 이미 실제 레벨을 쓰고 있었다 — 카드만 혼자 장부를 봤다.
func _shown_level(id: String) -> int:
	if _is_weapon_id(id):
		var real: int = _real_weapon_level(id)
		if real > 0:
			return real
	return int(_upgrade_counts.get(id, 0))


## 치명타 카드가 상한(70%) 뒤에도 쓸모 있는지 — 필중의 눈(속사 기관총 + 치명타 만렙) 재료로.
## 속사 기관총을 들고 있고 아직 그 융합을 안 했을 때만이다(11/7, MainGame._stat_card_capped).
func _crit_still_material() -> bool:
	return _shown_level("wp_rapid") > 0 and not _evolved.has("evo_deadeye")


## 카드 발치에 적을 레벨 예고 한 줄.
## ★ 처음엔 "Lv3 → Lv5 (+2단계)" 라고 적었는데 여전히 헷갈린다는 지적을 받았다(2026-09-07).
##   화살표와 괄호가 섞이면 어느 쪽이 지금이고 어느 쪽이 결과인지 눈이 한 번 더 판단해야 한다.
##   말로 못 박는다 — "지금 Lv3, 고르면 Lv5". 읽는 순서가 곧 시간 순서라 되물을 게 없다.
func _level_promise(cur: int, nxt: int) -> String:
	# ★ 처음엔 "지금 Lv1 · 고르면 Lv3 (2단계 한꺼번에)" 라고 적었다가 카드 폭(224px)을 넘어
	#   글자가 잘렸다 — 그림으로 찍어 보고 알았다(--cardshot, 2026-09-07).
	#   카드에는 이미 "Lv1 · 피해 21 · 초당 3.6발" 줄이 있어 '지금'은 거기서 읽힌다.
	#   여기서는 **고르면 어떻게 되는지**만 짧게 못 박는다.
	if cur <= 0:
		return I18n.t("고르면  Lv%d 로 시작") % nxt
	if nxt - cur >= 2:
		return I18n.t("고르면  Lv%d   (%d단계)") % [nxt, nxt - cur]
	return I18n.t("고르면  Lv%d") % nxt


## 이 무기가 특수무기(노드로 도는 것)인가. 아키타입 주무기는 wp_ 로 시작한다.
func _is_special_weapon(id: String) -> bool:
	return id.begins_with("wpn_") or id == "summon_ice"


## 이 카드를 **지금 고르면** 레벨이 몇이 되는가.
## ★ 카드가 현재 레벨만 적으면, 톨크(벼림)나 초월처럼 한 번에 여러 단계가 오르는 경우
##   무엇을 고르는지 알 수 없다 — "Lv1 아이템을 골랐는데 바로 Lv3 이 되더라. 카드가
##   현재 레벨인지 다음 레벨인지 애매하다"(2026-09-07 지적).
##   한계를 미는 경로가 셋이고 서로 더해진다: 특수무기 Lv2 시작 · 초월 +3 · 벼림 +1.
##   실제 적용부(_apply_upgrade)와 규칙이 갈리면 화면이 거짓말한다 — --maxcheck 가 매번 대조한다.
func _next_level_of(id: String) -> int:
	var cur: int = _shown_level(id)
	if not _is_weapon_id(id):
		return cur + 1
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return cur + 1
	var step: int = 1
	if cur <= 0:
		# 처음 드는 무기 — 특수무기는 Lv2 로 시작하고, 초월을 먹었으면 그 위에서 시작한다
		step = (2 if _is_special_weapon(id) else 1) + p.transcend_bonus
	if p.ability == "forge":
		step += 1        # 벼림: 무기 카드 한 장에 한 단계 더
		return mini(cur + step, maxi(cur + 1, _weapon_cap(id)))   # 상한(11)에 닿으면 덤은 안 붙는다
	return cur + step


## 무기 카드가 풀에서 빠지는 레벨(화면 Lv 기준). 카드 상한 6 + 초월 +3 + 톨크 벼림 +5.
## ★ 10/13 QA B5: 톨크 설명은 「무기 카드 한 장에 두 단계 (만렙 6 → 11)」인데, 9/15 초월 고침 때 상한을
##   실제 레벨로 자르게 바꾸면서 톨크도 6 에서 잘렸다(3장 만에 Lv7 에서 끝). 설명대로 11 까지 열어 둔다.
func _weapon_cap(id: String) -> int:
	var cap: int = _ability_max(id)
	var p := G.player as Player
	if p != null and is_instance_valid(p):
		cap += p.transcend_bonus
		if p.ability == "forge":
			cap += 5
	return cap


## 그 카드의 별 칸 수. 무기는 실제 레벨이 카드 상한을 넘을 수 있어(2레벨 시작·초월·벼림)
## 별을 잘라 삼키지 않게 같이 늘린다.
func _shown_max(id: String, base_max: int) -> int:
	return maxi(base_max, _shown_level(id))


func _build_summary() -> Array:
	var defs: Dictionary = {}
	for u: Dictionary in _upgrade_pool():
		defs[String(u["id"])] = u
	var weapons: Array = []
	var passives: Array = []
	var stats: Array = []
	for k in _upgrade_counts.keys():
		var id: String = String(k)
		var lvl: int = int(_upgrade_counts[k])
		if lvl <= 0:
			continue
		# ★ 풀 소진 대체 카드는 장부에 쌓이지만 빌드가 아니다. 안 걸러서 ESC 에
		#   `[강화] heal_card Lv7/6` 같은 줄이 떴다(자동선택을 켜면 확실히 재현).
		if id == "heal_card" or id == "gold_card":
			continue
		var d: Dictionary = defs.get(id, {})
		# 탭 상세에 실수치 스탯 라인 병기 (M38: "상세가 안 적혀있다" 피드백)
		var full_desc: String = I18n.t(String(d.get("d", "")))
		var stat_line: String = _card_stats(id)
		if stat_line != "" and stat_line != full_desc:
			full_desc += "\n" + stat_line
		# ★ 여기가 "%가 아직 보인다"의 진원지였다(2026-09-06 지적). 카드 화면은 _card_title 을
		#   거쳐 실수치가 되는데 이 목록만 풀의 원문 이름(`"공격력 +26%"`)을 그대로 썼다.
		#   같은 이름은 반드시 같은 함수에서 나와야 한다.
		var e: Dictionary = {
			"id": id, "name": _card_title(id, String(d.get("n", id))), "desc": full_desc,
			"level": lvl, "max": int(d.get("max", 6)),
		}
		if _is_weapon_id(id):
			e["kind"] = "무기"
			var real: int = _real_weapon_level(id)
			if real > 0:
				e["level"] = real
				e["max"] = maxi(int(e["max"]), real)   # 한계돌파를 MAX 로 잘라 삼키지 않는다
			weapons.append(e)
		elif _is_bullet_id(id):
			e["kind"] = "탄막"
			passives.append(e)
		elif not (id.begins_with("m_") or id.begins_with("l_") or id.begins_with("evo_")):
			# ★ 레벨업으로 먹은 **스탯 강화**가 지금까지 이 목록에 아예 없었다.
			#   무기·탄막만 보여주고 공격력·치명타·방어 같은 것은 어디에도 안 남아서
			#   "내가 뭘 먹었더라" 를 확인할 방법이 없었다(2026-09-05 지적).
			#   전설·신화(m_/l_)는 아래 crowns 에서 따로 맨 앞에 세운다.
			e["kind"] = "강화"
			e["desc"] = _stat_total(id, int(e["level"]))
			stats.append(e)
	# ★ 융합하면 재료가 장부(_upgrade_counts)에서 지워진다(_consume_material). 그런데 위 반복은
	#   그 장부만 돌기 때문에 **융합 결과 무기가 목록에서 통째로 사라졌다** — Lv13 군단을 들고
	#   있는데 화면엔 아무것도 없었다. 12종 전부 그랬다(2026-09-06 지적, --fusedisplay 로 확인).
	#   장부가 아니라 **지금 실제로 들고 있는 무기**를 기준으로 빠진 것을 채운다.
	var seen: Dictionary = {}
	for e0 in weapons:
		seen[String((e0 as Dictionary)["id"])] = true
	for cid0: String in _held_weapon_cards():
		if seen.has(cid0):
			continue
		var lv0: int = _real_weapon_level(cid0)
		if lv0 <= 0:
			continue
		var d0: Dictionary = defs.get(cid0, {})
		var desc0: String = I18n.t(String(d0.get("d", "")))
		var sl0: String = _card_stats(cid0)
		if sl0 != "" and sl0 != desc0:
			desc0 += "\n" + sl0
		var e1: Dictionary = {
			"id": cid0, "name": _card_title(cid0, String(d0.get("n", cid0))),
			"desc": desc0, "level": lv0, "max": maxi(int(d0.get("max", 6)), lv0),
			"kind": "무기",
		}
		weapons.append(e1)
	# ★ 융합한 무기는 **융합의 이름과 설명**을 달아야 한다. 예전엔 목록에 나와도
	#   "군단 Lv13 · 적을 쫓아 접촉 타격하는 아군" — 융합 전 설명 그대로였다.
	#   무엇으로 변했는지 화면 어디에도 없으면 "융합했는데 뭐가 달라진 거지"가 된다.
	var pl := G.player as Player
	if pl != null and is_instance_valid(pl):
		for e2 in weapons:
			var ed: Dictionary = e2 as Dictionary
			var arch2: String = String(_WP_KEY.get(String(ed["id"]), String(ed["id"])))
			if not pl.fused_marks.has(arch2):
				continue
			ed["tier"] = "융합"
			var evo_id: String = String(pl.fused_marks[arch2])
			var ev2: Dictionary = _evo_def(evo_id)
			# 10/13 사용자: 융합하면 「내가 든 것」 · 왼쪽 위 무기 칸이 융합 아이콘이어야 한다(예전엔 재료 무기 그림 + MAX).
			#   다음 레벨이 없으니 레벨 점 · 「이번 레벨 → 다음」 미리보기도 뺀다(fused 를 보고 칸이 레벨 대신 「융합」을 단다).
			ed["icon"] = evo_id
			ed["fused"] = true
			if not ev2.is_empty():
				ed["name"] = I18n.t(String(ev2["n"]))   # 16차: 「◆」 글꼴 기호 뺌(종류 칸이 「융합」)
				# 융합 설명 + 무엇과 무엇을 녹였는지 + 지금 실수치(레벨 미리보기 없이)
				var body: String = I18n.t(String(ev2["d"]))
				var mats: Array = []
				for mid in ev2.get("req", []):
					mats.append(_mat_name(String(mid)))
				if not mats.is_empty():
					body += "\n" + I18n.t("%s 융합") % " + ".join(mats)
				var stat2: String = _fused_stat_line(String(ed["id"]))
				if stat2 != "":
					body += "\n" + stat2
				ed["desc"] = body

	# ★ 예전엔 융합을 **별도 배지 한 줄로 또** 넣었다. 그래서 한 번 융합하면 목록에
	#   같은 것이 두 번 나왔다 — 결과 무기 한 줄(MAX)과 융합 배지 한 줄(융합).
	#   "동일한게 MAX, 융합로 나와있더라. 헷갈릴듯"(2026-09-07 지적).
	#   지금은 결과 무기 줄이 이미 '✦ 융합명' 이름과 tier="융합" 배지를 달고 있으므로
	#   그 한 줄이면 충분하다. 재료가 사라져 무기가 안 남는 융합이 생기면 그때 되살릴 것.
	var fusions: Array = []
	for ev: Dictionary in EVOLUTIONS:
		if not _evolved.has(String(ev["id"])):
			continue
		var shown_already: bool = false
		for e3 in weapons:
			if String((e3 as Dictionary).get("tier", "")) == "융합" 					and I18n.t(String(ev["n"])) in String((e3 as Dictionary)["name"]):
				shown_already = true
		if shown_already:
			continue
		fusions.append({
			"id": String(ev["id"]), "name": I18n.t(String(ev["n"])), "desc": I18n.t(String(ev["d"])),
			"level": 1, "max": 1, "kind": "융합", "tier": "융합",
		})
	# ★ 신화·전설 카드는 지금까지 빌드 화면에 아예 안 나왔다. 판을 뒤집는 한 장인데
	#   먹고 나면 어디에도 안 남아서 "먹은 게 맞나?" 가 됐다(실플레이 리포트). 맨 앞에 세운다.
	var crowns: Array = []
	for k2 in _upgrade_counts.keys():
		var cid: String = String(k2)
		if not (cid.begins_with("m_") or cid.begins_with("l_")):
			continue
		if int(_upgrade_counts[k2]) <= 0:
			continue
		var cd: Dictionary = defs.get(cid, {})
		var cdesc: String = I18n.t(String(cd.get("d", "")))
		var cstat: String = _card_stats(cid)
		if cstat != "":
			cdesc += "
" + cstat
		# ★ kind 는 **칸 분류**다(무기/탄막/패시브/융합). 등급(신화·전설)은 따로 tier 로 넘긴다.
		#   예전엔 kind 에 등급을 넣어서, 칸은 "패시브 1/4" 라고 세는데 항목은 "[신화]" 라고
		#   찍혀 같은 것을 두 이름으로 부르고 있었다 — 안 세어지는 것처럼 보였다(2026-09-06 지적).
		crowns.append({
			"id": cid, "name": I18n.t(String(cd.get("n", cid))), "desc": cdesc,
			"level": int(_upgrade_counts[k2]), "max": int(cd.get("max", 1)),
			"kind": "패시브", "tier": "신화" if cid.begins_with("m_") else "전설",
		})
	return crowns + fusions + weapons + passives + stats


## 카드 이름 옆에 붙일 실수치가 있으면 그것으로, 없으면 원문 그대로.
## _build_summary · 레벨업 카드 · 하니스가 **전부 이 하나**를 부른다.
func card_display_name(id: String, fallback: String) -> String:
	return _card_title(id, fallback)


## 융합 재료 소멸 — 카드 기여분을 플레이어에게서 걷어내고 풀에서 제외 (M37).
## 무기는 노드/장착 제거, 패시브(b_*)는 0 리셋, 스탯 카드는 기여분 역적용.
## 초월(m_transcend)을 이미 먹었는가. 먹은 **뒤에** 얻는 무기도 같은 혜택을 받아야 한다 —
## 예전엔 그 시점 보유분에만 +3 이 붙어서, 초월 후 새 무기를 들면 혼자 3단계 뒤처졌다
## (2026-09-05 지적). 지금은 새로 장착할 때 여기서 보고 맞춰 준다.
var _transcended: bool = false


## 융합에 녹인 재료 무기가 **몇 레벨이었는지**. 융합 결과 레벨을 정하는 데 쓴다.
## ★ 예전엔 결과가 무조건 Lv11 고정이라, 재료가 그보다 높으면 융합이 곧 **강등**이었다.
##   톨크(무기 카드 한 장에 두 단계)가 레이저를 만렙까지 올리면 Lv13 = 레이저 4줄기인데,
##   융합하면 Lv11 = 3줄기로 줄었다(2026-09-05 실플레이 지적).
var _fused_from_lv: int = 0


func _consume_material(id: String) -> void:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return
	var cnt: int = int(_upgrade_counts.get(id, 0))
	_upgrade_counts.erase(id)
	_consumed[id] = true
	if _WP_KEY.has(id):  # 주무기 아키타입 — weapons_primary에서 제거 (노드 없음)
		var arch: String = String(_WP_KEY[id])
		for i in range(p.weapons_primary.size() - 1, -1, -1):
			if String(p.weapons_primary[i]["id"]) == arch:
				_fused_from_lv = maxi(_fused_from_lv, int(p.weapons_primary[i]["level"]))
				p.weapons_primary.remove_at(i)
	elif p.weapons.has(id):  # 특수무기 — erase 먼저(같은 프레임 재장착 안전), 노드 free
		var nd: Node = p.weapons[id]
		if is_instance_valid(nd):
			_fused_from_lv = maxi(_fused_from_lv, int(nd.get("level")))
		p.weapons.erase(id)
		if is_instance_valid(nd):
			nd.queue_free()
	elif id.begins_with("b_"):  # 탄막 패시브 — 단순 0 리셋 (인플라이트 탄환만 잔향, 무해)
		p.set(id, 0)
	else:  # 스탯 카드 — 카드 기여분만 역적용
		match id:
			"pierce":
				p.pierce = maxi(0, p.pierce - cnt)
			"crit":
				p.crit_chance = maxf(0.0, p.crit_chance - 0.09 * float(cnt))
			"critdmg":
				p.crit_mult = maxf(Player.CRIT_MULT_BASE, p.crit_mult - 0.30 * float(cnt))


## 융합 재료 이름 — 수치 꼬리를 뗀다. 카드 제목은 "치명타 +9%" 인데 융합 줄에서는
## 그 +9% 가 군더더기다(필중의 눈이 "속사 기관총 · 치명타 +9%" 로 나왔다, 2026-09-05).
func _mat_name(id: String) -> String:
	var n: String = _card_name(id)
	for sep: String in [" +", " -", " ×"]:
		var i: int = n.find(sep)
		if i > 0:
			n = n.substr(0, i)
	return n.strip_edges()


## 융합 결과 레벨. 재료가 이미 그 이상 커 있었으면 **그 위로** 올린다 — 융합이 강등이 되면 안 된다.
## +4 는 "융합했으니 확실히 세졌다"가 보이는 최소폭이다(레이저 기준 Lv13 → 17, 줄기 4 유지).
func _fuse_lv(base_lv: int) -> int:
	return maxi(base_lv, _fused_from_lv + 4)


## 남은 칸 — 일시정지 화면에 한 줄로. 상한을 도입한 이상 "왜 새 무기가 안 뜨나"에 답이 있어야 한다.
func slot_usage_line() -> String:
	# ★ '융합 n/3' 칸을 없앴다(2026-09-07). 융합 결과 무기가 이제 무기 칸을 그대로 차지하므로
	#   융합 횟수는 무기 칸이 알아서 막는다 — 상한을 두 군데서 세면 규칙만 늘고 뜻은 안 는다.
	# 14차: 괄호 속 설명은 기획 문서 말이었다(「플레이어가 읽는 글은 기획 문서가 아니다」, 에셋 담당) — 뺐다
	return I18n.t("칸:  무기 %d/%d · 탄막 %d/%d · 패시브 %d/%d") % [
		_owned_slot_count("무기"), WEAPON_SLOTS,
		_owned_slot_count("탄막"), BULLET_SLOTS,
		_owned_slot_count("패시브"), PASSIVE_SLOTS]


## 지금 진행 중인 융합 레시피의 진척 — 일시정지 화면에 뿌린다.
## ★ 이게 없어서 "융합이 있다는 건 아는데 뭘 얼마나 모아야 하는지 모르겠다"가 됐다.
##   가장 가까운 것부터 3개만 보여준다(전부 뿌리면 12줄이라 읽히지 않는다).
func fusion_progress_lines() -> Array:
	var rows: Array = []
	for e: Dictionary in EVOLUTIONS:
		if _evolved.has(e["id"]):
			continue
		var reqs: Array = e["req"] as Array
		var got: int = 0
		var need: int = 0
		var parts: PackedStringArray = []
		var any: bool = false
		for req: String in reqs:
			var have: int = _shown_level(req)   # 카드에 적힌 그 레벨과 같은 수여야 한다
			# ★ 분모도 한계돌파를 따라야 한다. 정적 상한(6)만 쓰면 톨크로 Lv7 을 찍은 순간
			#   "맹독 장판 7/6" 처럼 분자가 분모를 넘어 화면이 깨져 보인다(2026-09-07 지적).
			#   별 칸 수와 같은 규칙(_shown_max)을 써서 화면 셋이 한 수를 보게 한다.
			#   ※ 융합 **성립 조건**은 그대로 정적 상한이다 — 초월했다고 융합이 어려워지면 안 된다.
			var want: int = _shown_max(req, _ability_max(req))
			got += mini(have, want)
			need += want
			if have > 0:
				any = true
			if G.WPN_UNLOCKS.has(req) and not G.wpn_unlocked(req):
				# 아직 안 열린 무기다. 개수를 적으면 "더 먹으면 된다"로 읽히는데 실은 못 먹는다.
				parts.append("%s (잠김)" % _mat_name(req))
			else:
				parts.append("%s %d/%d" % [_mat_name(req), have, want])
		if not any:
			continue  # 재료를 한 장도 안 든 레시피는 안 보여준다(도감에서 보면 된다)
		rows.append({"p": float(got) / float(maxi(1, need)), "t": "%s:  %s" % [I18n.t(String(e["n"])), " · ".join(parts)]})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["p"]) > float(b["p"]))
	var out: Array = []
	for i in mini(3, rows.size()):
		out.append(String((rows[i] as Dictionary)["t"]))
	return out


## 13차: 같은 진척을 아이콘 식으로 그리게 구조로 — [{evo, name, p, reqs: [[id, 지금, 필요, 잠김]]}] 가까운 셋.
func fusion_progress_rows() -> Array:
	var rows: Array = []
	for e: Dictionary in EVOLUTIONS:
		if _evolved.has(e["id"]):
			continue
		var reqs: Array = []
		var got: int = 0
		var need: int = 0
		var any: bool = false
		for req: String in (e["req"] as Array):
			var have: int = _shown_level(req)
			var want: int = _shown_max(req, _ability_max(req))
			got += mini(have, want)
			need += want
			if have > 0:
				any = true
			reqs.append([req, have, want, G.WPN_UNLOCKS.has(req) and not G.wpn_unlocked(req)])
		if not any:
			continue
		rows.append({"evo": String(e["id"]), "name": I18n.t(String(e["n"])), "p": float(got) / float(maxi(1, need)), "reqs": reqs})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["p"]) > float(b["p"]))
	return rows.slice(0, 3)


## 카드 id → 사람이 읽는 이름 (융합 진척 표시용)
func _card_name(id: String) -> String:
	for u: Dictionary in _base_pool():
		if String(u["id"]) == id:
			return I18n.t(String(u["n"])).replace("무기: ", "").replace("탄막: ", "").replace("Weapon: ", "").replace("Rounds: ", "")
	return id


func _available_evolutions() -> Array:
	var out: Array = []
	# 융합 횟수 상한은 없앴다 — 결과 무기가 무기 칸을 먹으므로 칸이 곧 상한이다(2026-09-07).
	for e: Dictionary in EVOLUTIONS:
		if _evolved.has(e["id"]):
			continue
		var ok: bool = true
		for req: String in (e["req"] as Array):
			if _shown_level(req) < _ability_max(req):  # 양쪽 재료를 '만렙'까지 찍어야 진화
				ok = false
				break
		if ok:
			out.append(e)
	return out


## 능력 등급 (프레임 색 = 등급, 아이콘 색 = 속성)
const RARITY: Dictionary = {
	"common": {"frame": Color("8a93a6"), "glow": Color("8a93a6"), "label": "일반"},
	"rare": {"frame": Color("4aa3ff"), "glow": Color("4aa3ff"), "label": "희귀"},
	"epic": {"frame": Color("b06bff"), "glow": Color("b06bff"), "label": "영웅"},
	"legendary": {"frame": Color("ffd54a"), "glow": Color("ffb03a"), "label": "전설"},
	"unique": {"frame": Color("42e2b8"), "glow": Color("42e2b8"), "label": "고유"},
	"mythic": {"frame": Color("ff3df0"), "glow": Color("ff3df0"), "label": "신화"},
}


# 등급별 등장 가중치 — 카드 1장이 뽑힐 상대 확률. 희귀급 위쪽은 행운의 영향을 받음.
# ★ 예전 값은 전설 5 / 신화 0.9 라 30분 런에서 신화 기대 노출이 0.35회였다. 8판에 한 번
#   볼까 말까 한 카드가 커먼 한 장 값이면 "봤다"는 감흥이 남을 수가 없다. 상위 등급을
#   실제로 만나게 하되(신화 런당 1.5회) 그만큼 값도 확실히 올렸다(아래 l_/m_ 참조).
#   unique(캐릭터 고유)가 epic 보다 흔하던 역순도 바로잡았다.
#   ★ 실플레이 리포트: "신화가 너무 잘 뜬다". 카드 한 장 기준으로는 0.53% 였지만 그건
#   '풀이 가득한 초반' 값이다. 판이 길어지면 커먼이 줄줄이 만렙으로 빠져나가 신화 지분이
#   저절로 올라가고, 여기에 보스 상자(판당 최대 25픽)까지 얹혀서 판당 노출이 3회에 가까웠다.
#   가중치를 4.0 → 2.0 으로 낮추고 '한 판에 신화 1장' 규칙(MYTHIC_PER_RUN)을 함께 건다.
#   실측: 카드 한 장당 0.53% → 0.13%, 한 판(레벨업 60회 + 보스상자) 기준 노출 50% → 25%.
const RARITY_W: Dictionary = {
	"common": 100.0, "rare": 45.0, "epic": 26.0, "unique": 22.0,
	"legendary": 12.0, "mythic": 2.0,
}


## 한 판에 볼 수 있는 신화 카드 수. 신화는 '판을 갈아엎는 한 장'이라 여러 장이 겹치면
## 그 판의 나머지 선택이 전부 의미를 잃는다 — 한 장으로 못 박고 그만큼 값을 세게 준다.
const MYTHIC_PER_RUN: int = 1


func _rarity_of(id: String) -> String:
	if id.begins_with("evo_"):
		return "legendary"
	if id.begins_with("l_"):
		return "legendary"  # 전설 카드 (M40)
	if id.begins_with("m_"):
		return "mythic"  # 신화 카드 (M40)
	if id.begins_with("c_"):
		return "unique"  # 캐릭터 고유 카드 (M37)
	if id.begins_with("wp_") or id.begins_with("wpn_") or id.begins_with("summon_") or id == "gamble":
		return "epic"  # 도박은 실측 픽당 가치가 커먼의 1.9배였다 — 레어 자리가 아니다
	if id.begins_with("b_"):
		return "rare"
	return "common"


## 무기 아키타입 카드 id → WEAPON_DEFS 키
const _WP_KEY: Dictionary = {
	"wp_balanced": "balanced", "wp_heavy": "heavy", "wp_rapid": "rapid",
	"wp_mid": "mid", "wp_melee": "melee",
	"wp_bow": "bow", "wp_fan": "fan", "wp_sinkal": "sinkal", "wp_jakdu": "jakdu",
}


## 무기 외 카드 효과를 '평이한 말'로 (레벨업마다 강해짐). 없으면 스탯라인 생략.
const _CARD_SPEC: Dictionary = {
	"dmg": "기본 공격력의 26%를 더한다 (9장이면 +234%)", "rate": "공격 속도 +12% (더 빠르게)", "speed": "달리기 속도 +8%",
	"hp": "최대 체력 +18 (즉시 회복도)",
	"bspeed": "탄환이 +14% 빠르게 날아감", "crit": "치명타 확률 +9% (일반 상한 70%)", "critdmg": "치명타 배율 +0.30 (기본 1.70배)",
	"regen": "매초 체력 1.0 자동 회복", "armor": "받는 피해 2 감소 (피해의 30%는 항상 받음)", "magnet": "아이템 줍는 범위 +55",
	"luck": "행운 +6% (드랍 확률에 가산 반영)", "xp_gain": "경험치 획득 +12% (레벨이 빨리 오른다)", "dashcd": "대시 쿨타임 15% 단축",
	"thorns": "피격 시 주변에 반사 피해 +8",
	"b_ice": "맞은 적이 느려짐 (레벨이 오르면 더 오래)", "b_fire": "맞은 적이 1.4초간 불탄다 (틱당 탄환 피해의 3.5%×레벨)",
	"b_poison": "맞은 적이 3초간 중독된다 (틱당 탄환 피해의 3%×레벨)", "b_shock": "명중 즉시 탄환 피해의 9%×레벨 추가 · 감전 잔류",
	"b_chain": "번개가 주변 적으로 튐 (레벨이 오르면 더 많이)",
	"b_big": "탄환이 커져서 잘 맞음", "b_bounce": "탄환이 적을 맞고 다른 적으로 튕김 (튕길수록 피해 감소)",
	"b_exec": "체력 적은 잡몹 즉시 처치 (레벨이 오르면 기준도 오른다)", "b_vamp": "적을 맞히면 체력 회복 (레벨이 오르면 더 많이)",
	"b_bloom": "적이 죽을 때 폭발 (연쇄는 2단계까지, 갈수록 약해짐)",
	"wpn_whip": "앞을 넓게 후려치는 근접 (레벨이 오르면 빠르고 넓게)", "wpn_boomerang": "던지면 되돌아오며 관통 (레벨이 오르면 멀리 · 많이)",
	"wpn_beam": "빙글 도는 레이저로 스치는 적을 계속 지짐", "wpn_orb": "주위를 도는 구슬로 타격 (레벨이 오르면 수 · 위력 증가)",
	"wpn_chain": "가까운 적에 번개 연쇄 (레벨이 오르면 위력 증가)", "wpn_fire": "몸 주위 화염 오라로 지속 화상 (레벨이 오르면 넓고 세게)",
	"wpn_ice": "주위를 얼려 피해+둔화 (레벨이 오르면 넓게)", "wpn_poison": "발밑 독장판 (레벨이 오르면 넓고 세게)",
	"wpn_summon": "적을 쫓는 아군 소환 (레벨이 오르면 수 증가)", "summon_ice": "얼음탄을 쏘는 정령 소환",
	"wp_bow": "멀리·빠르게 꿰뚫는 화살",
	"wp_fan": "앞을 넓게 덮는 부채꼴 6발",
	"wp_sinkal": "손이 안 보이는 쌍칼 연격",
	"wp_jakdu": "몸을 돌려 반원을 베어낸다",
	"gamble": "무작위로 능력 하나 대폭 강화",
	"heal_card": "최대 체력의 30%를 즉시 회복", "gold_card": "골드 +18~40 (난이도 배수 적용)",
	"c_allround": "공격력 +10% · 이동 +3% · 체력 +8", "c_bloodlust": "공격력 +16% · 흡혈 +1",
	"c_overheat": "공격속도 +10% · 탄속 +8%", "c_goldsense": "행운 드랍 ×1.08 · 자석 +40",
	"c_ironwill": "방어 +3 · 가시 +6 · 체력 +12", "c_allin": "치명 확률 +5% · 배율 +0.2",
	"c_charge": "대시 쿨 -12% · 공격력 +11%", "c_emberheart": "특수무기 ×1.10 · 화상 부여 +1",
	"c_umbra": "치명 배율 +0.25 · 이동 +4%", "c_bellcall": "특수무기 ×1.08 · 행운 +5%",
	"c_bloomstep": "이동 +6% · 검무 지속 +1.5초 · 상승률 증가", "c_temper": "특수무기 위력 ×1.16",
	"c_mantra": "방어 +2 · 재생 +0.6/s · 염주 쿨 -1초", "c_talon": "유도 +1 · 치명 확률 +6%",
	"l_timewarp": "적 이동속도 -15% (영구·중첩) · 공격력 +32%", "l_giant": "탄환 크기 +2 · 관통 +2 · 공격력 +45%",
	"l_echo": "발사 시 35% 확률로 한 번 더 발사 · 공격력 +12%", "m_apocalypse": "공격력 +120% · 치명 배율 +0.5",
	"m_immortal": "치명상 시 생존(쿨 60초) · 체력 +80 · 방어 +5 · 공격력 +66%",
	"m_transcend": "보유한 모든 무기가 만렙을 3단계 넘어선다(한계돌파) · 공격력 +25%",
}


## 그 스탯 카드를 N장 먹어서 **총 얼마를 얻었는지**. 빌드 패널에 붙는다.
## 카드 한 장의 값이 아니라 누적을 보여줘야 "내가 지금 뭘 얼마나 쌓았나"가 읽힌다.
func _stat_total(id: String, n: int) -> String:
	if n <= 0:
		return ""
	# ★ 배수·%로 적던 넷을 실수치로 바꿨다(2026-09-06 지적). "×1.08" 은 몇이 몇으로 갔는지
	#   안 알려준다 — 이동속도가 330 이면 356 이다. 확률(치명·행운)과 배율(경험치)만 % 로 남긴다.
	var p := G.player as Player
	var live: bool = p != null and is_instance_valid(p)
	match id:
		"dmg":
			if not live:
				return I18n.t("%d장 · 공격력 강화") % n
			return I18n.t("%d장 · 공격력 +%d") % [n, int(round(p.base_damage * (n * 0.26) * p.card_mult))]
		"rate":
			if not live:
				return I18n.t("%d장 · 발사 간격 ×%.2f") % [n, pow(0.88, float(n))]
			return I18n.t("%d장 · 초당 %.1f발") % [n, _shots_per_sec(p)]
		"speed":
			if not live:
				return I18n.t("%d장 · 이동속도 ×%.2f") % [n, pow(1.08, float(n))]
			return I18n.t("%d장 · 이동속도 %d") % [n, int(round(p.move_speed))]
		"hp":
			return I18n.t("%d장 · 최대 체력 +%d") % [n, n * 18]
		"bspeed":
			if not live:
				return I18n.t("%d장 · 탄속 ×%.2f") % [n, pow(1.14, float(n))]
			return I18n.t("%d장 · 탄속 %d") % [n, int(round(p.bullet_speed))]
		"crit":
			return I18n.t("%d장 · 치명타 +%d%%") % [n, int(round(n * 9.0))]
		"critdmg":
			return I18n.t("%d장 · 치명타 배율 +%.2f") % [n, n * 0.30]
		"regen":
			return I18n.t("%d장 · 재생 +%.1f/s") % [n, n * 1.0]
		"armor":
			return I18n.t("%d장 · 방어 +%d") % [n, n * 2]
		"magnet":
			return I18n.t("%d장 · 자석 +%d") % [n, n * 55]
		"luck":
			return I18n.t("%d장 · 행운 +%d%%") % [n, int(round(n * 6.0))]
		"xp_gain":
			return I18n.t("%d장 · 경험치 +%d%%") % [n, int(round(n * 12.0))]
		"dashcd":
			if not live:
				return I18n.t("%d장 · 대시 쿨 ×%.2f") % [n, pow(0.85, float(n))]
			return I18n.t("%d장 · 대시 쿨 %.1f초") % [n,
				maxf(Player.DASH_CD_MIN, Player.DASH_CD * p.dash_cd_mult)]
		"thorns":
			return I18n.t("%d장 · 반사 +%d") % [n, n * 8]
		"gamble":
			return I18n.t("%d장 · 무작위 강화") % n
		_:
			return I18n.t("%d장") % n


## 지금 실제 연사 — 손에 든 무기(가장 최근에 얻은 주무기) 기준.
## 여러 군데가 같은 식을 다시 쓰던 것을 한 줄로 모은다.
func _shots_per_sec(p: Player) -> float:
	var arch: String = p._dominant_primary()
	var wd: Dictionary = Player.WEAPON_DEFS.get(arch, {})
	if wd.is_empty():
		return 0.0
	var lv: int = maxi(1, _real_weapon_level("wp_" + arch))
	return 1.0 / maxf(0.02, float(wd["cd"]) * p.rate_mult * G.w_rate_mult(arch, lv))


## 카드 제목. 배수로 적힌 것은 **이번 한 장이 실제로 더해 주는 양**으로 바꿔 쓴다.
## "공격력 +26%" 는 26 이 무엇에 붙는 26 인지 안 알려준다 — 지금 피해가 19 면 +5 다.
## 확률(치명타·행운)과 배수(경험치·대시 쿨)는 % 가 원래 단위라 그대로 둔다.
## 2026-09-05: "%가 아니라 직관적인 수치로" 요구.
## 카드 이름은 전부 여기서 나온다. 원문을 그대로 돌려주는 갈래가 많아서 끝에서 한 번 번역한다
## (이미 번역된 문구는 번역표에 없으니 그대로 지나간다).
func _card_title(id: String, fallback: String) -> String:
	return I18n.t(_card_title_ko(id, fallback))


func _card_title_ko(id: String, fallback: String) -> String:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return fallback
	match id:
		"dmg":
			var d: float = p.base_damage * 0.26 * p.card_mult
			return I18n.t("공격력 +%d") % maxi(1, int(round(d)))
		"rate":
			var now: float = _shots_per_sec(p)
			if now <= 0.0:
				return fallback
			return I18n.t("공격속도 +%.1f발/초") % (now / 0.88 - now)
		"speed":
			return I18n.t("이동속도 +%d") % int(round(p.move_speed * 0.08))
		"critdmg":
			return "치명타 배율 +0.30"
		"bspeed":
			return I18n.t("탄속 +%d") % int(round(p.bullet_speed * 0.14))
		# ── 아래 넷은 실수치가 이미 있는데 이름이 여전히 % 였다(2026-09-06) ──
		"hp":
			return "최대체력 +18"
		"regen":
			return "체력 재생 +1.0/s"
		"armor":
			return "방어 +2"
		"magnet":
			return "자석 +55"
		"thorns":
			return "가시 반사 +8"
		"dashcd":
			var d0: float = maxf(Player.DASH_CD_MIN, Player.DASH_CD * p.dash_cd_mult)
			return I18n.t("대시 쿨 -%.1f초") % maxf(0.1, d0 - maxf(Player.DASH_CD_MIN, d0 * 0.85))
		_:
			return fallback


## 스탯 카드가 **지금 값을 얼마로 바꾸는지**. "+26%" 는 26이 뭐에 붙는 26인지 안 알려준다.
## 2026-09-05: "%가 아니라 직관적인 수치로" 라는 요구에 맞춰, 카드를 볼 때 현재값과
## 먹은 뒤 값을 나란히 보여준다. 카드 화면은 게임이 살아 있는 상태에서만 뜨므로
## p 의 현재값을 그 자리에서 읽을 수 있다.
func _stat_preview(id: String) -> String:
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return ""
	match id:
		"dmg":
			var now: float = p.damage
			var nxt: float = p.base_damage * (1.0 + p.card_add + 0.26) * p.card_mult
			return I18n.t("피해 %d → %d") % [int(now), int(nxt)]
		"rate":
			var arch: String = p._dominant_primary()
			var d: Dictionary = Player.WEAPON_DEFS.get(arch, {})
			if d.is_empty():
				return ""
			var lv: int = _real_weapon_level("wp_" + arch)
			var cd0: float = float(d["cd"]) * p.rate_mult * G.w_rate_mult(arch, maxi(1, lv))
			return I18n.t("초당 %.1f발 → %.1f발") % [1.0 / maxf(0.02, cd0), 1.0 / maxf(0.02, cd0 * 0.88)]
		"speed":
			return I18n.t("이동 %d → %d") % [int(p.move_speed), int(p.move_speed * 1.08)]
		"hp":
			return I18n.t("체력 %d → %d") % [int(p.max_hp), int(p.max_hp + 18.0)]
		"bspeed":
			return I18n.t("탄속 %d → %d") % [int(p.bullet_speed), int(p.bullet_speed * 1.14)]
		"crit":
			if p.crit_chance >= Player.CRIT_CAP - 0.001:
				return I18n.t("치명타 상한 %d%% (필중의 눈 재료)") % int(Player.CRIT_CAP * 100.0)
			return I18n.t("치명타 %d%% → %d%%") % [int(p.crit_chance * 100.0),
				int(maxf(p.crit_chance, minf(Player.CRIT_CAP, p.crit_chance + 0.09)) * 100.0)]
		"critdmg":
			return I18n.t("치명타 배율 ×%.2f → ×%.2f") % [p.crit_mult, p.crit_mult + 0.30]
		"regen":
			return I18n.t("재생 %.1f/s → %.1f/s") % [p.regen, p.regen + 1.0]
		"armor":
			return I18n.t("방어 %d → %d") % [int(p.armor), int(p.armor + 2.0)]
		"magnet":
			return I18n.t("자석 %d → %d") % [int(p.magnet_bonus), int(p.magnet_bonus + 55.0)]
		"luck":
			return I18n.t("행운 %d%% → %d%%") % [int(p.luck * 100.0), int((p.luck + 0.06) * 100.0)]
		"xp_gain":
			return I18n.t("경험치 ×%.2f → ×%.2f") % [p.xp_mult, p.xp_mult + 0.12]   # QA 10/13: xp_mult 는 1.0 에서 시작
		"dashcd":
			var d0: float = maxf(Player.DASH_CD_MIN, Player.DASH_CD * p.dash_cd_mult)
			var d1: float = maxf(Player.DASH_CD_MIN, Player.DASH_CD * maxf(0.35, p.dash_cd_mult * 0.85))
			return I18n.t("대시 쿨 %.1f초 → %.1f초") % [d0, d1]
		"thorns":
			return I18n.t("반사 %d → %d") % [int(p.thorns), int(p.thorns + 8.0)]
		_:
			return ""


## 카드에 붙일 실수치 요약. 무기 아키타입은 WEAPON_DEFS로 계산, 그 외는 _CARD_SPEC 표.
func _card_stats(id: String) -> String:
	if id.begins_with("evo_"):  # 융합 카드: 등장 조건과 대가를 명시 (S5 — "조건 없이 떴다" 오해 해소)
		return I18n.t("재료 2종 소멸 → 초월 무기 (칸 1개 해방)")
	if _WP_KEY.has(id):
		var wk: String = String(_WP_KEY[id])
		var rl: int = _real_weapon_level(id)
		var head: String = ("Lv%d · " % rl) if rl > 0 else ""
		return head + _weapon_stat_line(wk, rl) + _growth_line(wk, id)
	if _SPECIAL_TRACK.has(id):
		var sl: int = _real_weapon_level(id)
		var sh: String = ("Lv%d · " % sl) if sl > 0 else ""
		return sh + _sp_stat_line(id, sl) + _growth_line(id, id)
	var pv: String = _stat_preview(id)
	if pv != "":
		return pv          # 스탯 카드는 산문 대신 **지금 값 → 먹은 뒤 값**
	return _crown_spec(id)


## 융합한 무기의 지금 실수치 한 줄 — _card_stats 에서 「Lv · 」 머리와 다음 레벨 미리보기(_growth_line)를 뺀 것.
##   융합 무기는 더 오르지 않는다(카드 풀에서 빠짐). 「이번 레벨: 346 → 405 · 다음 →」 은 없는 단계를 약속했다.
func _fused_stat_line(id: String) -> String:
	if _WP_KEY.has(id):
		return _weapon_stat_line(String(_WP_KEY[id]), _real_weapon_level(id))
	if _SPECIAL_TRACK.has(id):
		return _sp_stat_line(id, _real_weapon_level(id))
	return ""


## 전설·신화·시그니처 카드 설명. 산문 안의 "공격력 +45%" 를 지금 값 기준 실수치로 바꾼다.
## ★ 표에는 %로 적혀 있다 — 그 표는 게임이 안 도는 화면(도감·메인메뉴)의 몫이다.
##   판이 돌고 있으면 내 공격력이 얼마나 오르는지 숫자로 보여 준다.
const _CROWN_DMG: Dictionary = {
	"c_allround": 0.10, "c_bloodlust": 0.16, "c_charge": 0.11,   # QA 10/13: 적용값(main_game.gd)에 맞춤 — 예전 표는 6 · 10 · 7
	"l_timewarp": 0.32, "l_giant": 0.45, "l_echo": 0.12,          # 시간 왜곡 ×1.32(예전 표 18)
	"m_apocalypse": 1.20, "m_immortal": 0.66, "m_transcend": 0.25,  # 불사의 심장 ×1.28 × 1.3 = ×1.66(예전 표 30)
}


## 이동속도 % 도 같이 실수치로. 값 하나짜리 표를 두 개 두는 것보다 낫다.
const _CROWN_SPD: Dictionary = {
	"c_allround": 0.03, "c_umbra": 0.04, "c_bloomstep": 0.06,
}


func _crown_spec(id: String) -> String:
	var txt: String = I18n.t(String(_CARD_SPEC.get(id, "")))
	var p := G.player as Player
	if p == null or not is_instance_valid(p):
		return txt
	if _CROWN_DMG.has(id):
		var add: int = maxi(1, int(round(p.base_damage * float(_CROWN_DMG[id]) * p.card_mult)))
		if not id.begins_with("c_"):   # QA 10/13: 곱연산 카드는 합연산 누적까지 곱해진 지금 공격력에 % 가 붙는다
			add = maxi(1, int(round(p.base_damage * (1.0 + p.card_add) * p.card_mult * float(_CROWN_DMG[id]))))
		txt = txt.replace(I18n.t("공격력 +%d%%") % int(round(float(_CROWN_DMG[id]) * 100.0)),
			I18n.t("공격력 +%d") % add)
	if _CROWN_SPD.has(id):
		var sp: int = maxi(1, int(round(p.move_speed * float(_CROWN_SPD[id]))))
		txt = txt.replace(I18n.t("이동 +%d%%") % int(round(float(_CROWN_SPD[id]) * 100.0)), I18n.t("이동 +%d") % sp)
	# 대시 쿨은 초로. 카드가 -12% 라고만 적으면 지금 쿨이 얼마인지 모른다.
	for pctv: int in [12]:
		var lbl: String = I18n.t("대시 쿨 -%d%%") % pctv
		if lbl in txt:
			var d0: float = maxf(Player.DASH_CD_MIN, Player.DASH_CD * p.dash_cd_mult)
			var d1: float = maxf(Player.DASH_CD_MIN, d0 * (1.0 - float(pctv) / 100.0))
			txt = txt.replace(lbl, I18n.t("대시 쿨 -%.1f초") % maxf(0.1, d0 - d1))
	if I18n.t("공격속도 +10%") in txt:   # 랑데 c_overheat
		var now: float = _shots_per_sec(p)
		txt = txt.replace(I18n.t("공격속도 +10%"), I18n.t("공격속도 +%.1f발/초") % maxf(0.1, now / 0.9 - now))
	if I18n.t("탄속 +8%") in txt:
		txt = txt.replace(I18n.t("탄속 +8%"), I18n.t("탄속 +%d") % int(round(p.bullet_speed * 0.08)))
	return txt


## 특수무기 한 줄 수치 — 주무기의 _weapon_stat_line 에 해당한다.
## ★ 지금까지 특수무기 카드에는 숫자가 **한 글자도** 없었다(산문만). 그래서 무기를 키워도
##   무엇이 얼마나 세졌는지 화면에 근거가 없었다(2026-09-06 지적).
func _sp_stat_line(id: String, lvl: int) -> String:
	var sb: Dictionary = G.SP_BASE.get(id, {})
	if sb.is_empty():
		return I18n.t(String(_CARD_SPEC.get(id, "")))
	var lv: int = maxi(1, lvl)
	var live: bool = lvl > 0
	var pw: float = G.sp_pow() if live else 1.0
	var hero: float = float(sb["dmg"]) * pw
	var total: float = hero * G.w_dmg_mult(id, lv)
	var parts: PackedStringArray = [I18n.t("피해 %d/%s") % [int(round(total)), I18n.t(String(sb["per"]))]]
	var c: float = float(sb["cd"])
	if c > 0.0:
		parts.append(I18n.t("주기 %.2f초") % maxf(float(sb["cd_min"]), c * G.w_rate_mult(id, lv)))
	parts.append(I18n.t("반경 %d") % int(float(sb["rad"]) * G.w_area_mult(id, lv)))
	var line: String = " · ".join(parts)
	# 영웅 몫 + 무기 몫 — 무기 레벨이 벌어온 값이 눈에 보여야 카드를 왜 먹는지가 읽힌다
	if live and total - hero >= 1.0:
		line += I18n.t("\n영웅 %d + 무기 %d") % [int(round(hero)), int(round(total - hero))]
	return line


## 특수무기 id 중 성장 트랙을 가진 것 (G.GROWTH_TRACKS 와 같은 키)
const _SPECIAL_TRACK: Dictionary = {
	"wpn_whip": 1, "wpn_boomerang": 1, "wpn_beam": 1, "wpn_orb": 1, "wpn_chain": 1,
	"wpn_fire": 1, "wpn_ice": 1, "wpn_poison": 1, "wpn_summon": 1, "summon_ice": 1,
}


## "이번에 무엇이 오르는가" 한 줄.
## ★ 예전엔 레벨업이 무기의 모든 수치를 동시에 올렸고 카드 설명도 매번 같았다.
##   플레이어 입장에서는 "그냥 세짐"이라 어떤 무기를 왜 키우는지가 안 읽혔다(실플레이 리포트).
##   지금은 무기마다 성장 순서가 정해져 있으니, 그 순서를 카드에 그대로 보여 준다.
## 다음 한 칸이 실제로 무엇을 바꾸는가. 무기가 손에 있으면 현재값과 나란히 적는다.
func _next_step_text(arch: String, card_id: String, lvl: int) -> String:
	var p := G.player as Player
	var d: Dictionary = Player.WEAPON_DEFS.get(arch, {})
	# ★ (lvl-1) 이다. w_grade 는 `for i in level-1: tr[i % size]` 로 세므로
	#   Lv N → N+1 에서 **새로 적용되는 칸**은 tr[(N-1) % size] 다.
	#   lvl 로 읽으면 한 칸 밀려서 엉뚱한 항목을 예고한다 — 그래서 "탄환수 1 → 1발"
	#   처럼 변화가 없는 줄이 나왔다(2026-09-05 지적).
	var tr0: Array = G.w_track(arch)
	var key: String = String(tr0[maxi(0, lvl - 1) % tr0.size()])
	var label: String = I18n.t(String(G.TRACK_LABEL.get(key, key)))
	# ★ 특수무기 10종은 WEAPON_DEFS 에 키가 없어서 여기서 통째로 아래 fallback 으로 떨어졌고,
	#   그래서 채찍·오브·소환수… 전부 "공격력 +44%" 라는 % 한 줄만 떴다(2026-09-06 지적).
	#   이제 G.SP_BASE 를 읽어 주무기와 같은 "지금 값 → 다음 값" 을 낸다.
	if d.is_empty() and G.SP_BASE.has(arch):
		return _sp_step_text(arch, key, label, maxi(1, lvl))
	if d.is_empty():
		return G.w_next_label(arch, maxi(1, lvl + 1))
	# ★ 아직 안 든 무기(lvl 0)도 여기로 온다. 예전엔 통째로 w_next_label 로 떨어져
	#   "공격력 +44%" 만 떴다 — 무기를 고르기 **전**이 정작 수치가 제일 필요한 순간이다.
	#   그때는 내 공격력 대신 기준값(14)으로 계산해 카탈로그 성능을 보여 준다.
	var live: bool = p != null and is_instance_valid(p) and lvl > 0
	var a: int = maxi(1, lvl)
	var b: int = a + 1
	match key:
		"dmg":
			var f: float = (p.damage if live else Player.BULLET_DMG) * float(d["dmg"])
			return "%s  %d → %d" % [label, int(f * G.w_dmg_mult(arch, a)), int(f * G.w_dmg_mult(arch, b))]
		"rate":
			var c0: float = float(d["cd"]) * (p.rate_mult if live else 1.0)
			return I18n.t("연사  초당 %.1f → %.1f발") % [
				1.0 / maxf(0.02, c0 * G.w_rate_mult(arch, a)),
				1.0 / maxf(0.02, c0 * G.w_rate_mult(arch, b))]
		"area", "range":
			var r: float = float(d["range"])
			return "%s  %d → %d" % [label, int(r * G.w_area_mult(arch, a)), int(r * G.w_area_mult(arch, b))]
		"pierce":
			var base_p: int = int(d["pierce"]) + (p.pierce if live else 0)
			return I18n.t("%s  %d → %d명") % [label, base_p + G.w_grade(arch, a, "pierce"),
				base_p + G.w_grade(arch, b, "pierce")]
		"proj":
			var base_j: int = int(d["proj"]) + (p.proj_bonus if live else 0)
			return I18n.t("%s  %d → %d발") % [label, base_j + G.w_grade(arch, a, "proj"),
				base_j + G.w_grade(arch, b, "proj")]
		"homing":
			return "%s  %d → %d" % [label, G.w_grade(arch, a, "homing"), G.w_grade(arch, b, "homing")]
		_:
			return G.w_next_label(arch, maxi(1, lvl + 1))


## 특수무기(오라·장판·소환·궤도) 한 칸이 실제로 바꾸는 값.
## 주무기와 달리 피해가 무기 스크립트 안에 있어서, G.SP_BASE 를 유일 조회처로 쓴다.
## 단위가 무기마다 다르다 — 장판·오라·레이저는 초당, 나머지는 한 타.
func _sp_step_text(id: String, key: String, label: String, lvl: int) -> String:
	var sb: Dictionary = G.SP_BASE[id]
	var pw: float = G.sp_pow()
	var a: int = lvl
	var b: int = lvl + 1
	match key:
		"dmg":
			var f: float = float(sb["dmg"]) * pw
			return "%s  %d → %d/%s" % [label, int(round(f * G.w_dmg_mult(id, a))),
				int(round(f * G.w_dmg_mult(id, b))), I18n.t(String(sb["per"]))]
		"rate":
			var c: float = float(sb["cd"])
			if c <= 0.0:   # 상시 판정(오라·장판) — 주기가 없다
				return I18n.t("%s  더 자주 판정") % label
			var lo: float = float(sb["cd_min"])
			return I18n.t("%s  %.2f초 → %.2f초") % [label,
				maxf(lo, c * G.w_rate_mult(id, a)), maxf(lo, c * G.w_rate_mult(id, b))]
		"area", "range":
			var r: float = float(sb["rad"])
			return "%s  %d → %d" % [label, int(r * G.w_area_mult(id, a)), int(r * G.w_area_mult(id, b))]
		"count":
			var n0: int = G.w_grade(id, a, "count")
			var n1: int = G.w_grade(id, b, "count")
			var base_n: int = 2 if (id == "wpn_orb" or id == "wpn_summon") else (3 if id == "wpn_chain" else 1)
			return "%s  %d → %d" % [label, base_n + n0, base_n + n1]
		_:
			return G.w_next_label(id, b)


func _growth_line(track_key: String, card_id: String) -> String:
	# ★ 장부가 아니라 **실제 무기 레벨**을 본다. 톨크처럼 카드 한 장에 두 단계 오르는
	#   경우 장부(최대 6)와 실제 레벨(상한 없음)이 벌어지고, 장부로 예고하면 엉뚱한 칸을 알려준다.
	var lvl: int = _real_weapon_level(card_id)
	if lvl <= 0:
		lvl = int(_upgrade_counts.get(card_id, 0))
	var tr: Array = G.w_track(track_key)
	# 이번 칸이 무엇을 얼마나 바꾸는지 — 배수가 아니라 **지금 값 → 다음 값**으로 적는다.
	var now_txt: String = I18n.t("이번 레벨: %s") % _next_step_text(track_key, card_id, lvl)
	var nxt: Array = []
	for i in range(lvl + 1, lvl + 3):  # 다음 두 칸까지 미리 보여 준다
		nxt.append(I18n.t(String(G.TRACK_LABEL.get(String(tr[(i - 1) % tr.size()]), "?"))))
	var out: String = I18n.t("
%s
다음 →  %s") % [now_txt, " · ".join(nxt)]
	# ★ 만렙 특성은 **Lv1 카드에서부터** 보여야 한다. 안 보이면 "이 무기를 끝까지 키운다"가
	#   선택이 되질 않는다 — 성장 트랙을 화면에 내놓은 것과 같은 이유다.
	var tn: String = G.w_trait_name(track_key)
	if tn != "":
		# ★ 무조건 "만렙" 이라 적던 자리다. 특수무기는 Lv2 로 시작해 카드 6장이면 Lv7 까지
		#   가므로 Lv6 은 만렙이 아니다 — 거기서 특성이 터지는데 카드엔 아직 칸이 남아 있다.
		#   상한과 같을 때만 '만렙'이라 부르고, 아니면 그냥 그 레벨을 적는다.
		var cap: int = _shown_max(card_id, int((_card_def(card_id)).get("max", 6)))
		var word: String = I18n.t("달성") if G.w_maxed(track_key, lvl) else (I18n.t("만렙") if cap <= G.MAX_TRAIT_LV else I18n.t("특성"))
		out += "\n%s Lv%d →  %s" % [word, G.MAX_TRAIT_LV, tn]
	return out


## WEAPON_DEFS 기반 스탯 (기본 damage=14 기준·전역강화 미반영 = 무기 고유 성능)
## 무기 한 줄 수치. lvl 을 주면 **그 레벨의 실수치**를, 0 이면 카탈로그 기본치를 낸다.
## 계산식은 player.gd 의 전투 경로(_weapon_dmg / _tick_weapons / _fire_ranged)와 같은 것을
## 쓴다 — 다른 식으로 다시 쓰면 화면과 실제가 갈린다.
func _weapon_stat_line(key: String, lvl: int = 0) -> String:
	var d: Dictionary = Player.WEAPON_DEFS.get(key, {})
	if d.is_empty():
		return ""
	var p := G.player as Player
	var live: bool = lvl > 0 and p != null and is_instance_valid(p)
	var parts: PackedStringArray = []

	# ★ 한 발 피해를 **영웅 몫 + 무기 몫**으로 쪼갠다(2026-09-06 요구).
	#   실전투와 같은 식이어야 하므로 Player.weapon_dmg_parts 를 그대로 쓴다 —
	#   여기서 수식을 다시 쓰면 검무·격노·융합 페널티가 빠져 화면과 실제가 갈린다.
	#   (그 결함이 실제로 있었다: 예전 이 줄은 셋을 통째로 빠뜨렸다.)
	var hero: float = 0.0
	var wpn: float = 0.0
	if live:
		var pr: Array = p.weapon_dmg_parts(d, lvl)
		hero = float(pr[0])
		wpn = float(pr[1])
	else:
		hero = Player.BULLET_DMG * float(d["dmg"])
	var dmg: float = hero + wpn
	var dtxt: String = I18n.t("피해 %d") % int(round(dmg))
	var proj: int = int(d["proj"]) + (p.proj_bonus if live else 0)
	if proj > 1:
		dtxt += "×%d" % proj
	parts.append(dtxt)

	var cd: float = float(d["cd"])
	if live:
		cd *= p.rate_mult * G.w_rate_mult(key, lvl)
	parts.append(I18n.t("초당 %.1f발") % (1.0 / maxf(0.02, cd)))

	if String(d["type"]) == "melee":
		parts.append(I18n.t("부채꼴 %d도") % int(d.get("arc", 0)))
	else:
		var pierce: int = int(d["pierce"]) + (p.pierce if live else 0) 			+ (G.w_grade(key, lvl, "pierce") if live else 0)
		if pierce > 0:
			parts.append(I18n.t("관통 %d명") % pierce)
	var rng: float = float(d["range"]) * (G.w_area_mult(key, lvl) if live else 1.0)
	parts.append(I18n.t("사거리 %d") % int(rng))
	var line: String = " · ".join(parts)
	# 둘째 줄로 내린다 — 첫 줄에 괄호로 끼우면 산탄의 "×4" 가 무엇에 걸리는지 안 읽힌다.
	# Lv1(무기 몫 0)이면 생략한다. "영웅 34 + 무기 0" 은 정보가 아니다.
	if wpn >= 1.0:
		line += I18n.t("\n영웅 %d + 무기 %d") % [int(round(hero)), int(round(wpn))]
	return line


# 캐릭터 고유 카드 (M37) — 해당 캐릭터로 플레이할 때만 풀에 등장. 슬롯 상한 비적용(c_ 접두사).
const _CHAR_CARDS: Dictionary = {
	"base": {"id": "c_allround", "n": "만능 훈련", "d": "공격력·이동·체력 소폭 동시 상승", "max": 4},
	"berserker": {"id": "c_bloodlust", "n": "피의 갈망", "d": "공격력 상승 + 명중 시 흡혈", "max": 3},
	"gunner": {"id": "c_overheat", "n": "과열 기관", "d": "연사·탄속 동시 상승", "max": 3},
	"collector": {"id": "c_goldsense", "n": "황금 감각", "d": "행운·자석 동시 상승", "max": 3},
	"tank": {"id": "c_ironwill", "n": "강철 의지", "d": "방어·가시·체력 동시 상승", "max": 3},
	"gambler": {"id": "c_allin", "n": "올인", "d": "치명타 확률·배율 동시 상승", "max": 3},
	# ── S2 특수 영웅 (예전엔 고유 카드가 없어 등급값을 못 했다) ──
	"knight": {"id": "c_charge", "n": "돌격 나팔", "d": "대시 쿨 감소 + 공격력 상승", "max": 3},
	"pyro": {"id": "c_emberheart", "n": "잉걸 심장", "d": "특수무기 위력 + 화상 부여 상승", "max": 3},
	"rogue": {"id": "c_umbra", "n": "그림자 걸음", "d": "치명 배율 + 이동속도 상승", "max": 3},
	# ── 이면 영웅 ──
	"mudang": {"id": "c_bellcall", "n": "방울 부름", "d": "소환수 위력 + 행운 상승", "max": 3},
	"hwarang": {"id": "c_bloomstep", "n": "꽃걸음", "d": "이동속도 + 검무 지속 상승", "max": 3},
	"smith": {"id": "c_temper", "n": "담금질", "d": "특수무기 위력 대폭 상승", "max": 3},
	"monk": {"id": "c_mantra", "n": "진언", "d": "방어·재생 + 염주 회복 가속", "max": 3},
	"falconer": {"id": "c_talon", "n": "매의 발톱", "d": "유도 + 치명타 확률 상승", "max": 3},
}


## 능력 카탈로그: 기본 강화 / 탄막 부여(온히트) / 오라 / 소환수 / 특수. 각 max=상한 레벨.
func _upgrade_pool() -> Array:
	# 잠긴 특수무기는 카드 풀에서 제외 (S1 해금 경제 — 조건 달성/상점 구매로 개방)
	var pool: Array = _base_pool().filter(func(u: Dictionary) -> bool: return G.wpn_unlocked(String(u["id"])))
	var cid: String = String(_last_char.get("id", ""))
	if _CHAR_CARDS.has(cid):  # 캐릭터 고유 카드는 그 캐릭터에게만
		pool.append(_CHAR_CARDS[cid])
	return pool


func _base_pool() -> Array:
	return [
		# ── 기본 강화 ──
		{"id": "dmg", "n": "공격력 강화", "d": "모든 무기에 실리는 영웅 공격력", "max": 9},
		{"id": "rate", "n": "공격속도 강화", "d": "발사 간격 감소", "max": 8},
		{"id": "speed", "n": "이동속도 강화", "d": "더 빠르게", "max": 6},
		# ★ 2026-09-05: '탄환 +1' · '관통 +1' · '유도' 세 장을 여기서 뺐다.
		#   전역 변수 하나를 올려 **들고 있는 모든 무기**를 같이 세게 만들던 카드다.
		#   이제 그 셋은 무기 성장 트랙(G.GROWTH_TRACKS)에만 있다 — 무기를 먹으면 그 무기만 큰다.
		#   변수 자체(p.proj_bonus / p.pierce / p.b_homing)는 남는다: 장신구·영웅 능력·
		#   도박·전설 카드가 여전히 쓴다.
		{"id": "hp", "n": "최대체력 +18", "d": "회복 포함", "max": 10},
		{"id": "bspeed", "n": "탄속 강화", "d": "탄환이 빠르게", "max": 6},
		{"id": "crit", "n": "치명타 +9%", "d": "치명타 확률 증가", "max": 7},
		{"id": "critdmg", "n": "치명타 배율 +0.30", "d": "치명타 한 방이 더 아프다", "max": 8},
		{"id": "regen", "n": "체력 재생 +1.0/s", "d": "초당 자동 회복", "max": 6},
		{"id": "armor", "n": "방어 +2", "d": "받는 피해 감소", "max": 6},
		{"id": "magnet", "n": "자석 +55", "d": "경험치 흡수 범위", "max": 6},
		{"id": "luck", "n": "행운 +6%", "d": "드랍 확률 (곱연산·희귀)", "max": 6},
		{"id": "xp_gain", "n": "경험치 획득 +12%", "d": "레벨업이 빨라짐", "max": 4},
		{"id": "dashcd", "n": "대시 쿨 단축", "d": "더 자주 대시", "max": 4},
		{"id": "thorns", "n": "가시 반사 +8", "d": "피격 시 주변에 반사 피해", "max": 5},
		# ── 탄막 부여 (명중 시 발동) ──
		{"id": "b_ice", "n": "탄막: 얼음", "d": "명중한 적을 감속", "max": 5},
		{"id": "b_fire", "n": "탄막: 화염", "d": "명중한 적을 화상(지속피해)", "max": 5},
		{"id": "b_poison", "n": "탄막: 맹독", "d": "명중한 적을 중독(지속피해)", "max": 5},
		{"id": "b_shock", "n": "탄막: 감전", "d": "명중 시 추가 번개 피해", "max": 5},
		{"id": "b_chain", "n": "탄막: 연쇄", "d": "명중 시 주변 적에게 번개 전이", "max": 5},
		{"id": "b_big", "n": "거대 탄환", "d": "탄환이 커져 판정 범위가 넓어진다", "max": 4},
		{"id": "b_bounce", "n": "튕기는 탄환", "d": "적을 맞고 다른 적에게 튕김", "max": 3},
		{"id": "b_exec", "n": "처형", "d": "체력 낮은 잔몹을 즉시 처형", "max": 5},
		{"id": "b_vamp", "n": "흡혈", "d": "명중 시 체력을 소량 회복", "max": 5},
		{"id": "b_bloom", "n": "폭발 개화", "d": "적 사망 시 광역 폭발(연쇄)", "max": 5},
		# ── 무기 아키타입 (다중 장착, 각자 독립 발사) ──
		{"id": "wp_heavy", "n": "무기: 대구경 캐논", "d": "강력·관통·느린 원거리", "max": 6},
		{"id": "wp_rapid", "n": "무기: 속사 기관총", "d": "약하지만 초고속 원거리", "max": 6},
		{"id": "wp_mid", "n": "무기: 중거리 산탄", "d": "근~중거리 4발 산탄", "max": 6},
		{"id": "wp_melee", "n": "무기: 대검(근접)", "d": "조준 방향 부채꼴 강타", "max": 6},
		{"id": "wp_balanced", "n": "무기: 밸런스 소총", "d": "표준 원거리(추가 장착)", "max": 6},
		# ── 이면 무기 (요괴 계열) ──
		{"id": "wp_bow", "n": "무기: 각궁", "d": "멀리·빠르게·꿰뚫는 화살", "max": 6},
		{"id": "wp_fan", "n": "무기: 태극 부채", "d": "앞을 넓게 덮는 부채꼴 6발", "max": 6},
		{"id": "wp_sinkal", "n": "무기: 신칼", "d": "손이 안 보이는 쌍칼 연격", "max": 6},
		{"id": "wp_jakdu", "n": "무기: 작두", "d": "몸을 돌려 반원을 베어낸다", "max": 6},
		# ── 근접/특수 무기 (비총기) ──
		{"id": "wpn_whip", "n": "채찍", "d": "넓은 부채꼴을 빠르게 후려침(근접)", "max": 6},
		{"id": "wpn_boomerang", "n": "부메랑", "d": "던져서 되돌아오는 관통 무기", "max": 6},
		{"id": "wpn_beam", "n": "회전 레이저", "d": "계속 회전하며 스치는 적을 지짐", "max": 6},
		# ── 주변 효과(오라) ──
		{"id": "wpn_orb", "n": "회전 오브", "d": "주위를 도는 오브가 적을 타격", "max": 6},
		{"id": "wpn_chain", "n": "번개 사슬", "d": "가까운 적들에게 연쇄 번개", "max": 6},
		{"id": "wpn_fire", "n": "화염 오라", "d": "주위 적을 지속 화상", "max": 6},
		{"id": "wpn_ice", "n": "빙결 파동", "d": "주위 적 데미지 + 감속", "max": 6},
		{"id": "wpn_poison", "n": "맹독 장판", "d": "가까운 적을 지속 중독", "max": 6},
		# ── 소환수 ──
		{"id": "wpn_summon", "n": "소환수", "d": "적을 쫓아 접촉 타격하는 아군", "max": 6},
		{"id": "summon_ice", "n": "얼음 정령", "d": "적에게 얼음탄을 쏘는 소환수", "max": 6},
		# ── 특수 ──
		{"id": "gamble", "n": "도박!", "d": "무작위 강력 강화", "max": 8},
		# ── 전설 (l_) — 극악 확률 등장 (M40) ──
		{"id": "l_timewarp", "n": "시간 왜곡", "d": "적이 느려지고 내 공격은 강해짐", "max": 2},
		{"id": "l_giant", "n": "거인의 탄환", "d": "탄환 거대화 · 관통 · 공격력 급증", "max": 1},
		{"id": "l_echo", "n": "메아리", "d": "발사가 한 번 더 울림", "max": 2},
		# ── 신화 (m_) — 그야말로 극악 (M40) ──
		{"id": "m_apocalypse", "n": "종말의 인장", "d": "공격력이 두 배를 넘어섬", "max": 1},
		{"id": "m_immortal", "n": "불사의 심장", "d": "죽음을 견디고 몸이 단단해짐", "max": 1},
		{"id": "m_transcend", "n": "초월", "d": "모든 무기가 만렙을 넘어선다 (한계돌파)", "max": 1},
	]


## 카드 상한 조회. ★ **원본 표**를 본다 — _upgrade_pool() 은 해금 필터를 거친 목록이라
## 아직 안 열린 무기가 이미 빠져 있고, 그러면 여기서 못 찾아 기본값 99 가 새어 나간다.
## 그 99 가 일시정지 화면에 "작두 0/99" 로 찍혀 "99개를 먹으라"로 읽혔다(2026-09-05).
## 게다가 99 는 진척률 분모를 부풀려 그 레시피 줄을 정렬 최하위로 밀어내기까지 했다.
func _ability_max(id: String) -> int:
	for u: Dictionary in _base_pool():
		if String(u["id"]) == id:
			return int(u.get("max", 99))
	return 99
