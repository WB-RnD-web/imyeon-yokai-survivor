class_name Enemy
extends CharacterBody2D
## kind: 0 일반 / 1 빠른스웜 / 2 탱크 / 3 탄막슈터 / 4 보스. 체력은 시간경과 배수 적용.

# ★ "vis" — **그리는 반경**. 없으면 rad 를 쓴다.
#   rad 는 충돌 판정이라 밸런스가 걸려 있어서 못 건드리는데, 그리는 배율은 rad 에서 나온다
#   (creature_visual.gd:135  sc = radius*2.15/프레임세로). 그 값이 1/n 에 안 맞으면 LINEAR 로
#   줄여 팔다리가 지워진다(같은 파일 141행 주석의 그 사고다). 그림용 반경만 따로 줘서
#   배율을 1/2·1/3·1/4 에 앉힌다. 체급이 15% 넘게 달라지는 건 그대로 뒀다 — 픽셀보다 체급이 크다.
const KINDS: Dictionary = {
	0: {"spd": 118.0, "rad": 14.0, "vis": 14.88, "hp": 44.0, "dmg": 8.0, "col": Color("e86a5c"), "sides": 3, "xp": 1, "ranged": false, "boss": false},
	1: {"spd": 212.0, "rad": 10.0, "vis": 11.16, "hp": 20.0, "dmg": 6.0, "col": Color("f2c14e"), "sides": 4, "xp": 1, "ranged": false, "boss": false},
	2: {"spd": 64.0, "rad": 23.0, "hp": 155.0, "dmg": 16.0, "col": Color("a56cf0"), "sides": 6, "xp": 4, "ranged": false, "boss": false},
	3: {"spd": 92.0, "rad": 15.0, "hp": 60.0, "dmg": 8.0, "col": Color("2fe6d0"), "sides": 5, "xp": 2, "ranged": true, "boss": false},
	4: {"spd": 50.0, "rad": 46.0, "hp": 2600.0, "dmg": 26.0, "col": Color("ff5c8a"), "sides": 8, "xp": 45, "ranged": false, "boss": true},  # M37: 1600→2600 (녹임 방지)
	5: {"spd": 44.0, "rad": 70.0, "hp": 80000.0, "dmg": 60.0, "col": Color("ff2d55"), "sides": 10, "xp": 500, "ranged": false, "boss": true},
	6: {"spd": 120.0, "rad": 60.0, "hp": 5000.0, "dmg": 42.0, "col": Color("ff3860"), "sides": 12, "xp": 300, "ranged": false, "boss": true},  # 융합 보스(hp는 합산으로 덮어씀)
	7: {"spd": 152.0, "rad": 13.0, "vis": 11.16, "hp": 54.0, "dmg": 9.0, "col": Color("9be86a"), "sides": 4, "xp": 2, "ranged": false, "boss": false},  # 고블린(민첩 돌진)
	8: {"spd": 104.0, "rad": 12.0, "vis": 11.16, "hp": 48.0, "dmg": 11.0, "col": Color("c7f24e"), "sides": 3, "xp": 2, "ranged": false, "boss": false},  # 뱀(위빙)
	# ── S1 신규 (운빨디펜스 이식) ──
	9: {"spd": 92.0, "rad": 13.0, "vis": 13.53, "hp": 42.0, "dmg": 10.0, "col": Color("dfe8f2"), "sides": 12, "xp": 2, "ranged": false, "boss": false},   # 원혼(지형 관통·반투명)
	10: {"spd": 76.0, "rad": 14.0, "hp": 72.0, "dmg": 6.0, "col": Color("c9a8ff"), "sides": 10, "xp": 4, "ranged": false, "boss": false},   # 달빛 사제(주변 치유)
	11: {"spd": 46.0, "rad": 21.0, "hp": 250.0, "dmg": 20.0, "col": Color("b58aff"), "sides": 8, "xp": 6, "ranged": false, "boss": false},  # 마그마 골렘(사망 시 탄 방출)
	12: {"spd": 195.0, "rad": 11.0, "vis": 10.15, "hp": 26.0, "dmg": 7.0, "col": Color("ff9a4a"), "sides": 6, "xp": 1, "ranged": false, "boss": false},   # 사냥 게(고속 위빙)
	13: {"spd": 55.0, "rad": 44.0, "hp": 3000.0, "dmg": 24.0, "col": Color("eaf4ef"), "sides": 12, "xp": 50, "ranged": false, "boss": true},  # 유령 군주(순간이동+유도탄)
	14: {"spd": 70.0, "rad": 42.0, "hp": 2400.0, "dmg": 22.0, "col": Color("6aa8ff"), "sides": 10, "xp": 50, "ranged": false, "boss": true},  # 흡혈박쥐 여왕(급습+흡혈+소환)
	15: {"spd": 40.0, "rad": 48.0, "hp": 3200.0, "dmg": 26.0, "col": Color("8fe36b"), "sides": 12, "xp": 50, "ranged": false, "boss": true},  # 맹독 슬라임 킹(독탄막+분열)
	# ── 이면(裏面) 요괴 10종 — 기존 판타지 위에 얹는 층 ──
	16: {"spd": 88.0, "rad": 15.0, "vis": 13.53, "hp": 58.0, "dmg": 11.0, "col": Color("241f2b"), "sides": 9, "xp": 3, "ranged": false, "boss": false},   # 어둑시니(멀수록 커진다)
	17: {"spd": 70.0, "rad": 17.0, "hp": 96.0, "dmg": 13.0, "col": Color("352e3d"), "sides": 7, "xp": 4, "ranged": false, "boss": false},   # 그슨대(볼수록 커진다)
	18: {"spd": 168.0, "rad": 16.0, "hp": 70.0, "dmg": 12.0, "col": Color("d9d3c4"), "sides": 6, "xp": 3, "ranged": false, "boss": false},  # 장산범(빠른 급습)
	19: {"spd": 58.0, "rad": 20.0, "hp": 210.0, "dmg": 15.0, "col": Color("74849c"), "sides": 8, "xp": 5, "ranged": false, "boss": false},  # 불가사리(쇠를 먹는다)
	20: {"spd": 116.0, "rad": 18.0, "vis": 20.3, "hp": 130.0, "dmg": 17.0, "col": Color("c1272d"), "sides": 5, "xp": 4, "ranged": false, "boss": false}, # 야차(분노)
	21: {"spd": 62.0, "rad": 21.0, "hp": 175.0, "dmg": 16.0, "col": Color("9c9482"), "sides": 7, "xp": 5, "ranged": false, "boss": false},  # 두억시니(분열)
	22: {"spd": 84.0, "rad": 15.0, "vis": 13.53, "hp": 78.0, "dmg": 10.0, "col": Color("16607a"), "sides": 10, "xp": 3, "ranged": false, "boss": false},  # 물귀신(끌어당김)
	23: {"spd": 132.0, "rad": 14.0, "hp": 66.0, "dmg": 9.0, "col": Color("f2efe6"), "sides": 8, "xp": 3, "ranged": true, "boss": false},    # 백여우(홀림 탄)
	24: {"spd": 74.0, "rad": 19.0, "vis": 20.3, "hp": 190.0, "dmg": 18.0, "col": Color("46536b"), "sides": 6, "xp": 5, "ranged": false, "boss": false},  # 강철 도깨비(단단함)
	25: {"spd": 205.0, "rad": 10.0, "vis": 11.16, "hp": 30.0, "dmg": 8.0, "col": Color("17151c"), "sides": 4, "xp": 2, "ranged": false, "boss": false},   # 그림자 무리(떼)
	# ── 이면 보스 3종 ──
	26: {"spd": 62.0, "rad": 44.0, "hp": 3400.0, "dmg": 25.0, "col": Color("f28fc0"), "sides": 12, "xp": 55, "ranged": false, "boss": true},  # 구미호(분신)
	27: {"spd": 52.0, "rad": 46.0, "hp": 3800.0, "dmg": 30.0, "col": Color("4a4152"), "sides": 10, "xp": 60, "ranged": true, "boss": true},   # 저승사자(명부)
	28: {"spd": 46.0, "rad": 52.0, "hp": 4200.0, "dmg": 28.0, "col": Color("f0c33c"), "sides": 12, "xp": 60, "ranged": false, "boss": true},  # 이무기(여의주)
}

## kind 별 겉모습 — 스프라이트 파일명 / 프로시저럴 애니 / 도형 폴백 장식 / 특수개체 여부.
## ★ 예전엔 이 정보가 _ready 안의 병렬 배열 4개(feats/sprites/hframes/anims)로 흩어져 있었고,
##   그중 hframes 만 경계 가드가 없어 kind 를 늘리면 그 자리에서 인덱스 에러가 났다.
##   한 표로 합쳐서 '몹 한 종 추가 = 여기 한 줄'이 되게 했다.
const LOOKS: Dictionary = {
	0: {"spr": "changrang", "anim": "hop", "feat": ""},
	1: {"spr": "tiro", "anim": "flap", "feat": ""},
	2: {"spr": "niobe", "anim": "march", "feat": "horns"},
	3: {"spr": "dorvan", "anim": "march", "feat": "spikes"},
	4: {"spr": "nagi_onestroke", "anim": "march", "feat": "crown"},
	5: {"spr": "nefer", "anim": "float", "feat": "crown"},
	6: {"spr": "nineplank_grok", "anim": "float", "feat": "crown"},
	7: {"spr": "hatsuba", "anim": "scurry", "feat": ""},
	8: {"spr": "neoul", "anim": "sway", "feat": ""},
	9: {"spr": "sinawi_twin", "anim": "float", "feat": "", "special": true},
	10: {"spr": "hald", "anim": "march", "feat": "", "special": true},
	11: {"spr": "halden", "anim": "march", "feat": "horns", "special": true},
	12: {"spr": "deonggi", "anim": "scurry", "feat": "spikes", "special": true},
	13: {"spr": "siul_blankface", "anim": "float", "feat": "crown"},
	14: {"spr": "bolke_brothers", "anim": "flap", "feat": "crown"},
	15: {"spr": "soryu", "anim": "hop", "feat": "crown"},
	16: {"spr": "hagl", "anim": "float", "feat": "", "special": true},
	17: {"spr": "karia", "anim": "float", "feat": "spikes", "special": true},
	18: {"spr": "brandr", "anim": "scurry", "feat": "", "special": true},
	19: {"spr": "kern", "anim": "march", "feat": "spikes", "special": true},
	20: {"spr": "utsuro", "anim": "march", "feat": "horns", "special": true},
	21: {"spr": "vallum", "anim": "march", "feat": "horns", "special": true},
	22: {"spr": "seket_scalepan", "anim": "float", "feat": "", "special": true},
	23: {"spr": "samhwan", "anim": "scurry", "feat": "", "special": true},
	24: {"spr": "deben_weigh", "anim": "march", "feat": "horns", "special": true},
	25: {"spr": "skarvi", "anim": "scurry", "feat": "", "special": false},
	26: {"spr": "valer", "anim": "scurry", "feat": "crown"},
	27: {"spr": "orvin_seal", "anim": "float", "feat": "crown"},
	28: {"spr": "ione_kilnshell", "anim": "sway", "feat": "crown"},
}

## 걷기 스트립(가로 4프레임)으로 구운 스프라이트는 여기에 등록된다.
## 러너(tools/pixel_gen.py)가 만드는 산출물이 전부 4프레임이라 파일이 있으면 4로 읽는다.
const STRIP_FRAMES: int = 4

## 스프라이트가 걷기 스트립인지(가로가 세로의 정수배) 판정해 프레임 수를 돌려준다.
## ★ 예전엔 종류마다 프레임 수를 손으로 적은 배열이 있었고, 값이 틀리면 몸이 반으로 잘렸다
##   (cyclop.png 를 2프레임으로 취급했던 사고). 이제 그림에서 직접 읽는다.
static var _frames_cache: Dictionary = {}

static func _strip_frames(path: String) -> int:
	if _frames_cache.has(path):
		return _frames_cache[path]
	var n: int = 1
	var tex: Texture2D = CreatureVisual._tex_for(path)
	if tex != null:
		var w: int = tex.get_width()
		var h: int = tex.get_height()
		# 걷기 스트립은 프레임 4장을 가로로 붙인 것이고, 프레임은 정사각이 아니다(64x96).
		# 그래서 '가로가 세로의 정수배'로는 못 잡는다 — 실제 산출물이 256x96 이라 w/h = 2.67 이다.
		# 판별: 가로가 더 길고, 4로 나뉘고, 한 프레임이 세로보다 넓지 않으면 스트립.
		if h > 0 and w > h and w % STRIP_FRAMES == 0 and int(w / STRIP_FRAMES) <= h:
			n = STRIP_FRAMES
	_frames_cache[path] = n
	return n
const BOUND: float = 1520.0  # 아레나 밖 이탈 방지 (넉백으로 맵 밖 나가던 버그)

## 저승길(스테이지 6, G.stage == 5): 몹마다 행동은 기존 틀(kind) 그대로 두고 그림 · 이름 · 도감만 저승길 몹으로 바꾼다.
## 11차 주문 때 저승길 열다섯 · 판관 · 염라를 처음부터 「○○ 틀」로 설계했다(망혼 = 티로 틀 …).
## 판관(시울 틀)이 부르는 원혼(9)도 망혼으로 나온다.
const JEOSEUNG_ART: Dictionary = {1: 29, 9: 29, 18: 30, 7: 31, 0: 32, 8: 33, 2: 34, 3: 35, 16: 36, 20: 37,
	10: 38, 11: 39, 22: 40, 17: 41, 19: 42, 21: 43, 13: 44, 5: 45}

## 그 자리에서 지금 스폰되면 어떤 그림 · 이름(도감 키)으로 나오나.
static func art_for(k: int) -> int:
	return int(JEOSEUNG_ART.get(k, k)) if G.stage == 5 else k

var kind: int = 0
var art: int = -1   # 그림 · 이름 · 도감 키. 스폰할 때 한 번 정한다(무한 모드에서 테마가 바뀌어도 그대로).
var spd: float = 118.0
var rad: float = 14.0
var touch: float = 8.0
var hp: float = 34.0
var max_hp: float = 34.0
var _xp: int = 1
var _ranged: bool = false
var _is_boss: bool = false
var _touch_cd: float = 0.0
var _fire_cd: float = 1.0
var _knock: Vector2 = Vector2.ZERO
var _cv: CreatureVisual
var _base_color: Color = Color("e86a5c")
var _dead: bool = false
var _boss_fill: Polygon2D
var _is_fusion: bool = false
var _charge_cd: float = 2.5
var _charge_t: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO
var _behavior: int = 0  # 0 추격 / 1 위빙 / 2 돌진(예고 후 대시)
var _elite: bool = false
## 11/7 정예 특성 — 어려움부터 정예에 붙는다(개수 G.elite_affix_count). 스팀 플레이 보고 「너무 시시하다」에 사용자가 고른 것.
const AFFIXES: Array = ["shield", "split", "volley", "curse", "haste"]
const AFFIX_NAMES: Dictionary = {"shield": "보호막", "split": "분열", "volley": "사방탄", "curse": "저주", "haste": "질주"}
const AFFIX_COLORS: Dictionary = {"shield": Color("8fd0ff"), "split": Color("ffd54a"), "volley": Color("ff9f43"), "curse": Color("c78bff"), "haste": Color("9dff6b")}
var affixes: Array = []
var force_elite: bool = false  # 11/7 무한 패턴 「정예 무리」: 확률 없이 정예로(add_child 전에 켠다)
var rush_dir: Vector2 = Vector2.ZERO   # 11/7 무한 패턴 「요괴 행렬」: 이 방향으로 곧장 돌진(추격하지 않는다)
var _rush_t: float = 0.0
var _shield: float = 0.0       # 보호막: 체력보다 먼저 깎인다(최대 체력의 절반)
var _volley_cd: float = 0.0    # 탄막: 다음 8방향 발사까지
var _wind: float = 0.0  # 돌진 예고(웅크림) 타이머
var _age: float = 0.0
var _special_cd: float = 4.5  # 보스 예고형 장판 공격 쿨
var _reap_cd: float = 6.5     # 저승사자 전용 광역 낫질 쿨 (보스 공용 쿨과 분리)
var _reap_primed: bool = false   # 광역 베기 attack 을 미리 들었다(캐릭터 에셋)
var _atk_primed: bool = false    # 원거리 몹 attack 을 미리 들었다(캐릭터 에셋)
## 우츠로 분노 시트(s1_*)로 갈아 끼우는 체력 비율. 빨라지는 건 연속이라 그림은 한 번만 바꾼다.
const RAGE_STAGE: float = 0.5
var _base_spd: float = 0.0    # 스폰 직후 확정된 이동속도 (기믹이 이 값을 기준으로 곱한다)
var _base_touch: float = 0.0  # 스폰 직후 확정된 접촉 피해
var _base_rad: float = 0.0    # 스폰 직후 확정된 반경 (몸집이 변하는 요괴의 기준)
var _size_k: float = 1.0      # 현재 몸집 배수
var _dark_far: float = 0.0    # 어둑시니: 최근 최대 거리(접촉 순간엔 0에 가까워 그 값으론 판정할 수 없다)
var _shape: CircleShape2D     # 접촉 판정 도형 (몸집과 함께 커진다)
var _burst_cd: float = 3.5
var split_gen: int = 0        # 분열형(정원): 죽으면 2마리로 쪼개짐 (남은 세대)
var is_bomber: bool = false   # 자폭형(용암): 죽을 때 광역 폭발로 플레이어 타격
var _chain_bombed: bool = false  # 다른 폭탄병 폭발로 죽음 → 연쇄기폭 안 함 (맵 전체 도미노 방지, M39)
## ★ 폭발 개화(b_bloom)에는 연쇄 깊이 제한이 아예 없었다. 몹이 상한(190마리) 근처로 차 있으면
##   한 마리만 죽어도 도미노가 맵 전체를 쓸어 버린다 — 실측으로 이 카드 하나가 총피해의 86%였다.
##   레어 등급 한 장이 전설·신화보다 세다는 리포트의 실체가 이것이다.
##   이제 폭발로 죽은 개체는 자기 세대를 물려받고, BLOOM_MAX_DEPTH 를 넘으면 더 안 터진다.
var _bloom_depth: int = 0
const BLOOM_MAX_DEPTH: int = 2
var _regen_stage: bool = false  # 생명의 정원: 서서히 자가회복
var _mini: bool = false       # 분열로 태어난 약체 개체 (체력/보상/크기 축소)
var _has_spawn_pos: bool = false
var _spawn_pos: Vector2 = Vector2.ZERO
var is_stage_boss: bool = false  # 스테이지 최종 보스: 근접 압박형 AI (겉돌지 않고 파고듦)
var reaper: bool = false         # 무한 30분 최종 보스(사신): _reaper_sync 가 매 프레임 속도 · 피해를 플레이어에 묶는다
## 사신(사용자 설계 10/12, 뱀파이어 서바이버의 사신) — 도망쳐서는 못 떼고 몇 대면 죽는다.
## 이동 · 체력 빌드로 넘지 못하게 플레이어 수치에 묶는다. 넘는 길은 화력 조합과 대시 · 감속뿐.
## 분마다 세진다(뱀파이어 서바이버처럼). 5분이면 몸박 한 번에 쓰러지고 플레이어보다 1.4배 빠르다.
## 그래도 얼음 감속(×0.45)을 계속 걸면 플레이어보다 느리다 — 도망 수단을 갖춘 빌드만 버틴다.
const REAPER_SPD: float = 1.15        # 플레이어 지금 이동 속도의 배수(처음)
const REAPER_SPD_GROW: float = 0.05   # 1분마다 더해지는 배수
const REAPER_SPD_MAX: float = 1.6
const REAPER_HIT: float = 0.5         # 몸박 한 번 = 플레이어 최대 체력의 절반(방어 적용 전). 탄 · 장판은 이 값의 배수
const REAPER_HIT_GROW: float = 0.1    # 1분마다 더해지는 몫
const REAPER_HIT_MAX: float = 1.0
var special: bool = false        # 특수 개체(S2): 운빨디펜스 이식 몹 — 희귀 출현·강화·보상↑·보라 오라
var _tp_active: bool = false     # 유령 군주 순간이동 페이드 중 (알파 소유권 트윈에)
var _last_hit_ms: int = -100000  # 마지막 피격 시각 (정원 재생의 전투이탈 판정)
var _boss_move_cd: float = 0.0   # 보스 이동 모드 재선정 타이머
var _strafe_sign: float = 1.0    # 보스 선회 방향(+1/-1)
var _summon_cd: float = 10.0     # 보스 잔몹 소환 쿨
var _slow_until: int = 0
## 개체별 완전 정지. G.enemies_frozen() 은 **전역** 정지라 한 마리만 세울 수단이 없었다.
## 얼음 장판 만렙 '빙결' 이 쓴다 — 재사용 가능하게 여기 한 줄로 둔다.
var _freeze_until: int = 0
var _poison_dmg: float = 0.0
var _poison_until: int = 0
var _poison_tick: float = 0.0
## 중독 중첩 — 계속 맞고 있으면 점점 아프다. 2026-09-05 이전엔 독이 "밟으면 아픈 바닥"
## 그 이상이 아니었다(중첩도 둔화도 방깎도 없었고, 걸려 있다는 표시조차 없었다).
var _poison_stacks: int = 0
var _poison_stack_cd: float = 0.0
const POISON_STACK_MAX: int = 5
const POISON_STACK_GAIN_CD: float = 0.35   # 한 방에 만렙이 되지 않게
const POISON_VULN_PER_STACK: float = 0.04  # 스택마다 받는 피해 +4% (5스택 = +20%)

## ★ 2026-09-15: 지속피해 한 틱이 독 0.5초 · 화상 0.4초였다. 밟고 나서 반 박자 뒤에
##   숫자가 뜨니 "내가 지금 독을 밟고 있는지"가 손에 안 잡힌다(실플레이 리포트: "1틱이 너무 길다").
##   틱을 0.25초로 줄이되 **초당 피해는 그대로** 둔다 — 반응만 빨라지고 세기는 안 변한다.
##   그래서 _poison_dmg/_burn_dmg 를 '틱당'이 아니라 **초당**으로 바꿨다. 예전 호출부는
##   인자 이름이 dps 인데 실제로는 틱당이라 실효 DPS 가 인자의 2배(독)·2.5배(화상)였다 —
##   그 배수를 apply 쪽에 접어 넣어 지금 밸런스를 그대로 보존한다.
const DOT_TICK: float = 0.25
## 장판(독/얼음/화염 웅덩이)이 판 위의 적을 훑는 주기. 피해는 이 값을 곱해 주므로
## 줄여도 초당 피해는 안 변한다 — 반응만 빨라진다.
const HAZARD_TICK: float = 0.2
const OLD_POISON_TICK: float = 0.5   # 예전 틱 — 환산에만 쓴다
const OLD_BURN_TICK: float = 0.4

## 얼음 중첩 — 독처럼 쌓이고, 꽉 차면 얼어붙는다.
## 예전엔 얼음이 감속 하나뿐이라 "느려졌나?" 수준이었고 쌓아 올리는 맛이 없었다.
var _ice_stacks: int = 0
var _ice_stack_cd: float = 0.0
var _ice_proc_cd: float = 0.0
const ICE_STACK_MAX: int = 5
const ICE_STACK_GAIN_CD: float = 0.30
const ICE_FREEZE_SEC: float = 1.0      # 잡몹 결빙 시간
const ICE_FREEZE_BOSS: float = 0.35    # 보스는 짧게 — 패턴이 통째로 사라지면 보스전이 아니다
const ICE_PROC_CD: float = 5.0         # 결빙 재발동 쿨 (영구 정지 방지)

## 독 만렙 — 맹독. 터뜨리고 한동안 훨씬 아프다.
var _venom_until: int = 0
var _venom_cd: float = 0.0
const VENOM_SEC: float = 3.0
## ★ 2.5 로 뒀더니 실측 7.5배가 나왔다 — 5스택이면 이미 ×3(스택 램프)인데 그 위에 곱해진다.
##   2.0 으로 낮춰 약 6배. 5스택까지 1.75초 + 맹독 3초 + 쿨 6초를 평균 내면 기존 대비 ×1.25 쯤이다.
##   (숫자는 --dotcheck 가 매번 다시 찍어 준다.)
const VENOM_MULT: float = 2.0
const VENOM_BURST: float = 3.0         # 터질 때 초당피해의 몇 배를 즉발로
const VENOM_CD: float = 6.0
var _dot_tint: Color = Color(0, 0, 0, 0)  # 이번에 모인 지속피해의 색 (중독=초록 / 화상=주황)
var _burn_dmg: float = 0.0
var _burn_until: int = 0
var _burn_tick: float = 0.0
# ── 원소 반응(M31): 서로 다른 속성이 겹치면 반응 발동 ──
var _shock_until: int = 0   # 감전 잔류 상태(반응 재료)
var _vuln_until: int = 0    # 취약: 받는 피해 증가
var _vuln_mult: float = 1.0
var _react_cd: float = 0.0  # 반응 재발동 쿨(오라가 매틱 반응하는 것 방지)


func _has_ice() -> bool: return Time.get_ticks_msec() < _slow_until
## 8차 공통 상태 시트 — 걸린 원소 하나를 머리 위에(얼음 > 화상 > 중독 > 감전). 0.15초마다만 본다.
## 바뀔 때만 노드를 바꾼다. 절전 모드에선 안 띄운다(몹 수백 마리 × 노드).
var _st_fx: AnimatedSprite2D = null
var _st_cur: String = ""
var _st_check: float = 0.0


func _status_fx(delta: float) -> void:
	_st_check -= delta
	if _st_check > 0.0:
		return
	_st_check = 0.15
	var now: int = Time.get_ticks_msec()
	var want: String = ""
	if now < _freeze_until:
		want = "st_freeze"
	elif now < _burn_until:
		want = "st_burn"
	elif now < _poison_until:
		want = "st_poison"
	elif now < _shock_until:
		want = "st_shock"
	if want != "" and (G.perf_level() <= 0 or not FxLib.has("common", want)):
		want = ""
	if want == _st_cur:
		return
	_st_cur = want
	if _st_fx != null and is_instance_valid(_st_fx):
		_st_fx.queue_free()
	_st_fx = null
	if want == "":
		return
	_st_fx = FxLib.sprite("common", want, true)
	_st_fx.position = Vector2(0.0, -rad - 14.0)
	_st_fx.z_index = 8
	add_child(_st_fx)
	G.mine(_st_fx)   # 19차: 화상 · 빙결 표시는 내 무기가 만든 것 — 영웅 둘레에서는 흐리게(후반에 영웅을 덮던 주황 원뿔)


func _has_fire() -> bool: return Time.get_ticks_msec() < _burn_until
func _has_poison() -> bool: return Time.get_ticks_msec() < _poison_until
func _has_shock() -> bool: return Time.get_ticks_msec() < _shock_until


## 이 개체만 완전히 세운다 (얼음 조각상). 중첩이 아니라 더 늦은 쪽으로 갱신한다.
func apply_freeze(sec: float) -> void:
	if _dead:
		return
	_freeze_until = maxi(_freeze_until, Time.get_ticks_msec() + int(sec * 1000.0))


func apply_slow(sec: float) -> void:
	_try_react("ice")
	_slow_until = maxi(_slow_until, Time.get_ticks_msec() + int(sec * 1000.0))
	if _ice_stack_cd > 0.0:
		return
	_ice_stack_cd = ICE_STACK_GAIN_CD
	_ice_stacks = mini(ICE_STACK_MAX, _ice_stacks + 1)
	if _ice_stacks >= ICE_STACK_MAX and _ice_proc_cd <= 0.0:
		# 꽉 찼다 — 얼어붙는다. 스택은 비우고 쿨을 걸어 영구 정지를 막는다.
		_ice_stacks = 0
		_ice_proc_cd = ICE_PROC_CD
		apply_freeze(ICE_FREEZE_BOSS if _is_boss else ICE_FREEZE_SEC)
		_react_ring(Color(0.72, 0.92, 1.0, 0.95), rad + 26.0)
		_react_label("결빙!", Color(0.78, 0.94, 1.0))


func apply_poison(dps: float, sec: float) -> void:
	_try_react("poison")
	# 인자는 '틱당'으로 쓰이고 있었다(틱 0.5초 → 실효 DPS = 인자 × 2). 초당으로 환산해 둔다.
	_poison_dmg = maxf(_poison_dmg, dps / OLD_POISON_TICK)
	# ★ maxi 다. 예전엔 대입이라 짧은 재부여가 남은 시간을 **깎았다.**
	_poison_until = maxi(_poison_until, Time.get_ticks_msec() + int(sec * 1000.0))
	if _poison_stack_cd <= 0.0:
		_poison_stacks = mini(POISON_STACK_MAX, _poison_stacks + 1)
		_poison_stack_cd = POISON_STACK_GAIN_CD
		if _poison_stacks >= POISON_STACK_MAX and _venom_cd <= 0.0:
			# 꽉 찼다 — 맹독이 터진다. 즉발 한 방 + 한동안 지속피해가 훨씬 아프다.
			_venom_cd = VENOM_CD
			_venom_until = Time.get_ticks_msec() + int(VENOM_SEC * 1000.0)
			var burst: float = _poison_dmg * VENOM_BURST * (0.5 if _is_boss else 1.0)
			_react_ring(Color(0.55, 1.0, 0.42, 0.95), rad + 30.0)
			_react_label("맹독!", Color(0.62, 1.0, 0.5))
			_react_dmg(burst, Color("8dff6a"))


func apply_burn(dps: float, sec: float) -> void:
	_try_react("fire")
	_burn_dmg = maxf(_burn_dmg, dps / OLD_BURN_TICK)  # 초당으로 환산 (예전 틱 0.4초)
	_burn_until = Time.get_ticks_msec() + int(sec * 1000.0)


## 감전 상태 부여 (b_shock 명중 시 즉발 피해와 함께 잔류 상태도 남겨 반응 재료가 됨)
func apply_shock(sec: float) -> void:
	_try_react("shock")
	_shock_until = maxi(_shock_until, Time.get_ticks_msec() + int(sec * 1000.0))


## 반응 파워 = 플레이어 공격력 기준(빌드가 커질수록 반응도 강해짐)
func _rp() -> float:
	if G.player != null and is_instance_valid(G.player):
		return (G.player as Player).damage * (1.0 - G.run_penalty)  # [감사 C22] 도주 페널티 일관 적용
	return 14.0


## 새 속성 적용 시, 이미 걸린 '다른' 속성이 있으면 반응 발동
func _try_react(elem: String) -> void:
	if _dead or _react_cd > 0.0:
		return
	var other: String = ""
	if elem != "ice" and _has_ice(): other = "ice"
	elif elem != "fire" and _has_fire(): other = "fire"
	elif elem != "shock" and _has_shock(): other = "shock"
	elif elem != "poison" and _has_poison(): other = "poison"
	if other == "":
		return
	if not G.react_budget():  # 전역 초당 상한 — 불발 시 개별 쿨 안 씀(다음 기회에 발동 가능)
		return
	_react_cd = 1.4  # M39: 0.7→1.4 — 화염+감전 등 이중부여 빌드가 맵 전체를 자동 전멸시키던 폭주 억제
	var pair: Array = [elem, other]
	pair.sort()
	match pair[0] + "+" + pair[1]:
		"fire+ice": _react_shatter()
		"ice+shock": _react_superconduct()
		"fire+poison": _react_plague()
		"fire+shock": _react_overload()
		"poison+shock": _react_corrode()
		"ice+poison": _react_frostbite()


## 반응 피해(직접 hp 차감 + 숫자 + 사망 처리). 반응은 속성부여를 안 해 재귀 안 함.
func _react_dmg(dmg: float, col: Color) -> void:
	if _dead or not G.running:
		return  # [감사 C20] 종료 후 반응 피해 우회 차단
	_last_hit_ms = Time.get_ticks_msec()
	if Time.get_ticks_msec() < _vuln_until:
		dmg *= _vuln_mult
	if _poison_stacks > 0:
		# 중독이 쌓일수록 몸이 무너진다 — 5스택이면 받는 피해 +20%.
		dmg *= 1.0 + POISON_VULN_PER_STACK * float(_poison_stacks)
	G.tally("원소반응", dmg)
	G.log_dmg("react", minf(dmg, maxf(0.0, hp)))
	hp -= dmg
	if G.probe_on:
		G.dmg_probe += dmg
	DamageNumber.spawn_as(get_parent(), _num_pos(8.0), int(dmg), DamageNumber.REACT, col, get_instance_id())
	_cv.flash(col)
	if _is_boss and _boss_fill != null:
		_boss_fill.scale.x = clampf(hp / max_hp, 0.0, 1.0)
	if hp <= 0.0:
		_die()


## 개체 표식 — 발밑 얇은 링 + 그 위를 도는 룬 몇 개.
## 꽉 찬 원반과 달리 캐릭터를 안 가리고, 링이 납작해서 '바닥에 그려진 문양'으로 읽힌다.
## runes=0 이면 링만(자폭형처럼 급한 경고), pulse 는 한 번 뛰는 데 걸리는 초.
func _mark_ring(col: Color, runes: int, pulse: float) -> void:
	var mark := Node2D.new()
	mark.z_index = -1
	mark.scale = Vector2(1.0, 0.42)          # 납작하게 = 바닥에 누운 고리
	mark.position = Vector2(0, rad * 0.80)
	add_child(mark)
	# ★ 회전은 **눌리지 않은** 안쪽 노드에 건다. 눌림을 들고 있는 mark 를 직접 돌리면
	#   지역 변환이 R(θ)·S 로 조립되어 납작한 축이 θ 와 함께 돌아간다 — 90도 지점에서
	#   세로로 선 길쭉한 타원이 된다(1 : 0.42 라 2.4배라 눈에 확 띈다).
	#   자식으로 한 겹 넣으면 최종 변환이 S·R(θ) 가 되어, 원을 먼저 돌리고(여전히 원)
	#   그 다음 누르므로 고리는 바닥에 누운 채 고정되고 룬만 그 궤도를 돈다.
	var spin := Node2D.new()
	mark.add_child(spin)
	var ring := Line2D.new()
	ring.width = maxf(2.0, rad * 0.11)
	ring.default_color = Color(col.r, col.g, col.b, 0.75)
	var pts: PackedVector2Array = G.regular_polygon(20, rad * 1.05)
	for pt: Vector2 in pts:
		ring.add_point(pt)
	ring.add_point(pts[0])
	spin.add_child(ring)
	for i in runes:                           # 고리 위를 도는 작은 룬 — 등급이 한눈에 세어진다
		var a: float = TAU * float(i) / float(maxi(1, runes))
		var rn := Polygon2D.new()
		rn.polygon = G.regular_polygon(4, maxf(2.0, rad * 0.14))
		rn.color = Color(col.r, col.g, col.b, 0.95)
		rn.position = Vector2(cos(a), sin(a)) * rad * 1.05
		spin.add_child(rn)
	if G.mobile:
		return  # 무한 트윈은 개체 수명 내내 돈다 — 모바일에선 정지 표식으로 충분
	var tw := create_tween().set_loops()
	tw.tween_property(mark, "scale", Vector2(1.12, 0.47), pulse).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mark, "scale", Vector2(0.96, 0.40), pulse).set_trans(Tween.TRANS_SINE)
	if runes > 0:
		var rt := spin.create_tween().set_loops()
		rt.tween_property(spin, "rotation", TAU, pulse * 12.0).from(0.0)


func _react_ring(col: Color, r: float) -> void:
	if not G.fx_budget():
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = col
	var pts: PackedVector2Array = G.regular_polygon(20, r)
	for pt: Vector2 in pts:
		ring.add_point(pt)
	ring.add_point(pts[0])
	ring.global_position = global_position
	ring.z_index = 40
	get_parent().add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector2(1.8, 1.8), 0.25)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.25)
	tw.tween_callback(ring.queue_free)


## 원소반응 문구 → 10차 낱말 그림 이름(ui/text 의 r_<이름>_ko · _en).
const REACT_WORD: Dictionary = {"파열!": "rupture", "초전도!": "supercon", "역병폭발!": "plague", "맹독!": "venom",
	"결빙!": "frozen", "흡혈!": "drain", "치유!": "heal", "부식!": "corrode", "과부하!": "overload", "동상!": "frostbite"}


func _react_label(txt: String, col: Color) -> void:
	if randf() > 0.4:  # 고밀도 전투에서 텍스트 도배/노드 폭증 방지 — 일부만 표시
		return
	if not G.fx_budget():
		return
	# 10차 A: 원소반응 낱말 그림(흰 글자에 반응 색을 곱한다, 그림 1px = 게임 2px). 없는 낱말은 글꼴로.
	var rk: String = String(REACT_WORD.get(txt, ""))
	if rk != "" and FxLib.has("ui/text", "r_%s_ko" % rk):
		var wt: Texture2D = FxLib.scaled("ui/text", FxLib.word_sheet("r_" + rk), 0, 2)
		if wt != null:
			var ws := Sprite2D.new()
			ws.texture = wt
			ws.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ws.modulate = col
			ws.z_index = 60
			get_parent().add_child(ws)
			ws.global_position = (global_position + Vector2(0, -rad - 26.0)).round()
			var tw2 := ws.create_tween()
			tw2.tween_property(ws, "global_position:y", ws.global_position.y - 22.0, 0.5)
			tw2.parallel().tween_property(ws, "modulate:a", 0.0, 0.5).set_delay(0.2)
			tw2.tween_callback(ws.queue_free)
			return
	var l := Label.new()
	l.text = txt
	UiFont.apply(l, 15)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	l.global_position = global_position + Vector2(-24, -rad - 34.0)
	l.z_index = 60
	get_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y - 22.0, 0.5)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tw.tween_callback(l.queue_free)


func _react_neighbors(radius: float, cb: Callable) -> void:
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or e == self or e._dead:
			continue
		if global_position.distance_to(e.global_position) < radius:
			cb.call(e)


## 파열 (얼음+화염): 단일 강타, 두 상태 소멸
func _react_shatter() -> void:
	_slow_until = 0
	_burn_until = 0
	_react_ring(Color("bfefff"), rad + 22.0)
	_react_label("파열!", Color("d8faff"))
	G.sfx_throttled("hit", 1.25, -4.0, 0.05)
	_react_dmg(_rp() * 2.2, Color("d8faff"))  # M39: 3.0→2.2 (단일 대상이라 소폭만)


## 초전도 (얼음+감전): 방어 무시 강타 + 취약 부여
func _react_superconduct() -> void:
	_vuln_until = Time.get_ticks_msec() + 3000
	_vuln_mult = 1.35
	_react_ring(Color("9ad8ff"), rad + 18.0)
	_react_label("초전도!", Color("bfe6ff"))
	G.sfx_throttled("hit", 1.35, -5.0, 0.05)
	_react_dmg(_rp() * 1.7, Color("bfe6ff"))


## 역병폭발 (화염+독): 주변 광역. M39: 이웃 '독 감염' 제거 — 상태가 무리 전체로 전염돼 자가증식하던 폭주 차단
func _react_plague() -> void:
	if FxLib.burst(get_parent(), global_position, "evo_plague", "burst", 0.0, (rad + 40.0) / 26.0, -1.0, 22) == null:
		_react_ring(Color("8fe36b"), rad + 40.0)
	_react_label("역병폭발!", Color("aef58a"))
	G.sfx_throttled("hit", 0.85, -3.0, 0.05)
	var d: float = _rp() * 0.7
	_react_neighbors(80.0, func(e: Enemy) -> void:
		G.tally("원소반응", d)
		e.take_damage(d, (e.global_position - global_position).normalized(), false, "react"))
	_react_dmg(d, Color("aef58a"))


## 과부하 (화염+감전): 주변 광역 강타 + 넉백 + 화면흔들림
func _react_overload() -> void:
	_react_ring(Color("ffb14a"), rad + 46.0)
	_react_label("과부하!", Color("ffd07a"))
	G.add_shake(0.18)
	G.sfx_throttled("hit", 0.7, -2.0, 0.05)
	var d: float = _rp() * 0.9  # M39: 1.9→0.9 (탄이 화염+감전을 동시 부여해 상시 발동 — 광역 핵이었음)
	_react_neighbors(85.0, func(e: Enemy) -> void:
		G.tally("원소반응", d)
		e.take_damage(d, (e.global_position - global_position).normalized(), false, "react")
		e._knock += (e.global_position - global_position).normalized() * 40.0)  # 120→40: 화염오라·독장판 밖으로 밀어내 자기 딜을 깎던 것
	_react_dmg(d * 1.6, Color("ffd07a"))


## 부식 (독+감전): 가까운 적들에게 번개 아크 피해. M39: 이웃 '독 감염' 제거(자가증식 차단) + 반경 축소
func _react_corrode() -> void:
	_react_label("부식!", Color("c8ff8a"))
	G.sfx_throttled("hit", 1.0, -6.0, 0.05)
	var d: float = _rp() * 0.45
	_react_neighbors(110.0, func(e: Enemy) -> void:
		G.tally("원소반응", d)
		e.take_damage(d, (e.global_position - global_position).normalized(), false, "react")
		_chain_arc(global_position, e.global_position))


## 동상 (얼음+독): 강타 + 강한 감속 갱신
func _react_frostbite() -> void:
	_slow_until = maxi(_slow_until, Time.get_ticks_msec() + 2200)
	_react_ring(Color("8fd0ff"), rad + 16.0)
	_react_label("동상!", Color("bfe6ff"))
	G.sfx_throttled("hit", 1.1, -6.0, 0.05)
	_react_dmg(_rp() * 1.2, Color("bfe6ff"))


## 감전 연쇄 아크(부식 반응용)
func _chain_arc(a: Vector2, b: Vector2) -> void:
	if not G.fx_budget():
		return
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color("c8ff9a")
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var perp: Vector2 = (b - a).orthogonal().normalized()
	for i in 6:
		var t: float = float(i) / 5.0
		var jit: float = 0.0 if (i == 0 or i == 5) else randf_range(-14.0, 14.0)
		line.add_point(a.lerp(b, t) + perp * jit)
	line.z_index = 45
	get_parent().add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.2)
	tw.tween_callback(line.queue_free)


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 2
	collision_mask = 8  # 지형 장애물(레이어 4)에 막혀 돌아감
	if art < 0:
		art = art_for(kind)
	var k: Dictionary = KINDS.get(kind, KINDS[0])
	spd = k["spd"]
	rad = k["rad"]
	touch = k["dmg"]
	_xp = k["xp"]
	_ranged = k["ranged"]
	_is_boss = k["boss"]
	_is_fusion = kind == 6
	_base_color = k["col"]
	# 잡몹은 시간이 갈수록 체력이 '확확' 오르는 가파른 곡선(스테이지 비례), 보스는 기존 튜닝 유지.
	# S1: 스테이지 모드는 stage_power(1.45^스테이지)가 추가로 곱해져 뒤로 갈수록 확 강해짐.
	if _is_boss:
		# [감사 C11] 성장 상한 4.5 — 후반 중간보스가 최종보스보다 단단해지는 역전 방지
		# 17-1: 종류별 체력 차(2400~4200)를 0.9~1.3 배로 눌러 둔다 — 이무기(4200)가 기준의 1.62 배라 스테이지 보스를 넘었다.
		#   융합(kind 6) · 스테이지/최종 보스는 add_child 뒤에 main_game 이 자기 식으로 덮어쓴다.
		hp = G.boss_ref_hp() * clampf(float(k["hp"]) / 2600.0 * G.BOSS_MID_SCALE, G.BOSS_MID_MULT.x, G.BOSS_MID_MULT.y)
	else:
		# ★ 예전엔 체력이 사실상 '시간'만 보고 올랐다(시간항 6.9배 vs 레벨항 1.7배).
		#   플레이어의 힘은 시간이 아니라 '처치→레벨'로 오르기 때문에, 한 번 밀리면
		#   몹은 계속 세지고 나는 그대로라 영영 못 따라잡는다 — 실측으로 같은 설정 같은 봇이
		#   레벨 37/처치 3,891 과 레벨 16/처치 625 로 갈렸다(운으로 판이 결정됨).
		#   시간항을 줄이고 레벨항을 키우면, 잘 크면 몹도 따라 세지고 못 크면 숨통이 트인다.
		var tmin: float = G.time_alive / 60.0
		# 식은 G.enemy_hp_scale 한 곳에만 있다 (검사 하니스와 어긋날 수 없게)
		hp = float(k["hp"]) * G.enemy_hp_scale(G.level, G.pressure_t()) * G.stage_enemy_hp
	max_hp = hp
	# 몸박 데미지도 시간이 갈수록 증가 (예전엔 난이도 배수만 → 후반에 무해했음)
	# 분당 +22% → +30%. 후반에도 몸박이 무해하면 '가만히 서서 클리어'가 성립한다.
	touch *= G.enemy_touch_scale(G.pressure_t())
	spd *= minf(1.5, 1.0 + float(maxi(0, G.level - 1)) * 0.02)  # 레벨 오를수록 조금 빨라짐
	if is_stage_boss:
		spd *= 2.0  # 스테이지 보스: 도망다니는 플레이어를 실제로 쫓아갈 수 있는 발
		rad *= 1.2  # 체급도 한눈에 — 웨이브 중간보스와 확실히 구분 (S4)
	if G.player != null and is_instance_valid(G.player):  # 시간 왜곡(전설 카드): 전역 감속
		spd *= maxf(0.5, 1.0 - (G.player as Player).enemy_slow)
	if not _is_boss:
		spd *= G.stage_enemy_spd  # 맵 특화 이동배수
	_regen_stage = G.stage == 2  # 생명의 정원: 자가회복
	if _mini:  # 분열 미니: 약체 + 보상 축소
		hp *= 0.4
		max_hp = hp
		_xp = maxi(1, int(_xp / 2))
	# 특수 개체(S2): 이식 몹 4종은 '희귀·강화 개체'로만 등장 — 스타일 이질감을 특별함으로.
	# 보스 소환수(_mini)로 나올 땐 일반 취급.
	if bool((LOOKS.get(kind, {}) as Dictionary).get("special", false)) and not _mini:
		special = true
		hp *= 2.2
		max_hp = hp
		touch *= 1.15
		_xp = int(_xp * 3)
	# 이동 패턴 배정 — 단조로운 직선추격 탈피
	if not _is_boss:
		if kind == 1 or kind == 8:  # 박쥐 스웜 / 뱀 = 지그재그 위빙
			_behavior = 1 if randf() < 0.62 else 0
		elif kind == 0 or kind == 7:  # 슬라임 / 고블린 = 일부 돌진형
			_behavior = 2 if randf() < 0.46 else 0
		elif kind == 12:  # 사냥 게 = 항상 고속 위빙
			_behavior = 1
	if kind == 9:  # 원혼: 지형 장애물을 그대로 통과 (벽 뒤에서 스며나옴)
		collision_mask = 0
	# 엘리트 변종: 시간이 갈수록 확률↑ (근접형 대상) — 크고 단단하고 돌진, 보상↑
	# 11/7: 매우어려움 · 지옥은 위빙 몹(박쥐 · 뱀 · 게)도 정예로 나온다.
	if force_elite or (not _is_boss and not _mini and (kind == 0 or kind == 2 or kind == 7 or (G.difficulty >= 3 and (kind == 1 or kind == 8 or kind == 12)))):
		# ★ 2026-09-15: 예전 식은 0초부터 2% 로 시작해 1분마다 +4.5%p 였다. 엘리트는 체력
		#   ×3.2 라, 60→150초 사이에 대표몹 체력이 ×2.5 로 뛴 것의 절반이 이 비율이었다
		#   (곡선 자체는 ×1.6 밖에 안 오른다 — 나머지는 '무엇이 나오느냐'가 바꾼 것).
		#   시작점을 45초 뒤로 민다. 상한(18%)과 후반 밀도는 그대로다.
		var et: float = maxf(0.0, G.time_alive - 45.0)
		var ep: float = minf(clampf(et / 60.0 * 0.045, 0.0, 0.18) * G.elite_rate_mult(), 0.32)   # 11/7 난이도 · 업보 배수
		if force_elite or randf() < ep:
			_elite = true
			_behavior = 2
			rad *= 1.4
			hp *= 3.2
			max_hp = hp
			touch *= 1.4
			spd *= 1.12
			_xp = int(_xp * 3)
			_base_color = _base_color.lightened(0.18)
			_roll_affixes()
	if not _is_boss:
		spd *= G.karma_spd_mult()   # 11/7 업보 5단계
	# ★ 기믹(어둑시니 거리 비례 · 야차 분노)이 매 프레임 스탯을 다시 쓰는데, 그때 KINDS 원값으로
	#   되돌리면 난이도·시간·스테이지 배수가 통째로 날아간다. 스폰 직후 값을 기준으로 잡아 둔다.
	_base_spd = spd
	_base_touch = touch
	_base_rad = rad
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = rad
	col.shape = cs
	_shape = cs
	add_child(col)
	_cv = CreatureVisual.new()
	_cv.body_color = _base_color
	# ★ 그리는 크기를 충돌 반경에서 뗀다.
	#   creature_visual.gd:135 가 sc = radius*2.15/프레임세로 로 배율을 잡고, 그게 1/n 에 안 맞으면
	#   LINEAR 로 줄여 팔다리가 지워진다. 그런데 예전엔 특수 개체 x1.10 을 **필터를 정한 뒤에**
	#   _cv.scale 로 곱했다 — 판정은 1/3 로 보고 실제로는 0.367 로 그려서, 스냅이 아무 소용이 없었다.
	#   배율을 전부 radius 에 접어 넣으면 배율이 하나뿐이라 판정과 실제가 같아진다.
	#   충돌 rad 는 위에서 이미 CollisionShape 에 들어갔으므로 밸런스는 안 움직인다.
	var vr: float = rad
	var vk: float = float((KINDS.get(kind, {}) as Dictionary).get("vis", 0.0))
	if vk > 0.0:
		vr = rad * (vk / float((KINDS[kind] as Dictionary)["rad"]))   # 엘리트·스테이지보스 배수를 보존
	if _mini:
		vr *= 0.66
	if special:
		vr *= 1.10
	_cv.radius = vr
	_cv.sides = int(k["sides"])
	_cv.angry = true
	var look: Dictionary = LOOKS.get(kind, {})
	_cv.feature = String(look.get("feat", ""))
	# 실제 픽셀 스프라이트 (없으면 도형 폴백). 스트립(가로 4프레임)이면 프레임 순환.
	var sname: String = String(look.get("spr", ""))
	if sname != "":
		var spath: String = "res://assets/sprites/monsters/%s.png" % sname
		if not ResourceLoader.exists(spath) and kind == 5:
			spath = "res://assets/sprites/monsters/dragon.png"  # 최종보스 전용 스프라이트 미존재 시 융합체와 공용(구판)
		_cv.sprite_path = spath
		_cv.sprite_hframes = _strip_frames(spath)
	# 종류별 프로시저럴 애니메이션: 슬라임=홉, 박쥐=날갯짓, 사이클롭스/해골=행진,
	# 드래곤(보스/융합)=부유+큰날개, 고블린=종종걸음, 뱀=슬리더
	_cv.anim_style = String(look.get("anim", ""))
	_cv.always_animate = _is_boss  # 보스는 항상 눈에 띄어야 하므로 컬링 제외
	# 캐릭터 에셋 자리: 키(h) · 졸개/갈라진 판(mini) · 강화 개체(elite) · 크기 단계(steps)
	var slot: Dictionary = CharForge.enemy_slot(art)
	_cv.cf_id = String(slot.get("id", ""))
	if _cv.cf_id != "":
		_cv.cf_target_h = float(slot.get("h", 0.0))
		_cv.cf_steps = slot.get("steps", [])
		if _mini:
			_cv.cf_key = int(slot.get("mini", 0))
		elif _elite:
			_cv.cf_key = int(slot.get("elite", 0))
	_cv.build()
	add_child(_cv)
	if _is_boss:
		_cv.play_once("entrance")   # 재고는 신화만 있다. 주문분은 보스 9종 모두 있다 — 빛에서 나타남 → 착지 → 포즈
	# ★ 예전 표식은 전부 '반지름 1.4~1.75 짜리 꽉 찬 원반'이었다. 캐릭터보다 훨씬 큰 색덩어리가
	#   뒤에 깔리니 배리어를 두른 것처럼 보이고, 무엇보다 조잡하다(실플레이 리포트).
	#   이제 얇은 링 + 발밑에 도는 룬으로 바꾼다 — 표식은 읽히되 캐릭터를 안 가린다.
	if _elite:
		_mark_ring(Color(1.0, 0.82, 0.28), 3, 0.55)
	if special:  # 특수 개체 — 처치 시 확정 금화 (크기는 위 vr 에서 이미 반영)
		_mark_ring(Color(0.80, 0.50, 1.0), 4, 0.60)
	if is_bomber:  # 자폭형: 죽으면 광역 폭발 — 붉게, 빠르게 뛰는 링
		_mark_ring(Color(1.0, 0.32, 0.18), 0, 0.34)
	if is_stage_boss:  # 스테이지 보스 전용: 금빛 룬 고리 (중간보스가 아님을 시각 언어로)
		_mark_ring(Color(1.0, 0.83, 0.30), 6, 0.75)
	if _is_boss and not _is_fusion:
		_build_boss_bar()
	if _is_boss:  # 보스 등장 연출: 흔들림 + 이중 충격파 + 짧은 정지
		G.add_shake(0.55)
		G.hitstop(0.09)
		call_deferred("_boss_entrance_fx")
	if _has_spawn_pos:  # 분열로 태어난 개체는 지정 위치로 (deferred add_child 후)
		global_position = _spawn_pos
	scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 11/7 정예 특성 고르기 — 난이도 · 업보가 정한 개수만큼 겹치지 않게. 머리 위에 이름을 작게 띄운다.
var _affix_lbl: Label = null


func _roll_affixes() -> void:
	var n: int = G.elite_affix_count()
	if n <= 0:
		return
	var pool: Array = AFFIXES.duplicate()
	pool.shuffle()
	affixes = pool.slice(0, mini(n, pool.size()))
	if affixes.has("shield"):
		_shield = max_hp * 0.5
	if affixes.has("haste"):
		spd *= 1.35
	if affixes.has("split") and split_gen <= 0:
		split_gen = 1   # 죽으면 둘로 갈라진다(정원 분열형과 같은 길)
	if affixes.has("volley"):
		_volley_cd = randf_range(1.2, 2.6)
	_affix_lbl = Label.new()
	UiFont.apply(_affix_lbl, 14)
	_affix_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_affix_lbl.add_theme_constant_override("outline_size", 4)
	_affix_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_affix_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_affix_lbl.size = Vector2(160.0, 18.0)
	_affix_lbl.position = Vector2(-80.0, -rad * 2.3 - 18.0)
	_affix_lbl.z_index = 46
	add_child(_affix_lbl)
	_affix_relabel()


func _affix_relabel() -> void:
	if _affix_lbl == null or not is_instance_valid(_affix_lbl):
		return
	if affixes.is_empty():
		_affix_lbl.queue_free()
		_affix_lbl = null
		return
	var names: PackedStringArray = []
	for a: String in affixes:
		names.append(I18n.t(String(AFFIX_NAMES[a])))
	_affix_lbl.text = "  ".join(names)
	_affix_lbl.add_theme_color_override("font_color", AFFIX_COLORS[affixes[0]])


func _shield_break() -> void:
	_react_ring(AFFIX_COLORS["shield"], rad + 16.0)
	G.sfx_throttled("hit", 1.7, -4.0, 0.05)
	affixes.erase("shield")
	_affix_relabel()


## 탄막 특성: 8방향(지옥 12방향) 탄. 적 탄 상한 · 발사 예산은 다른 탄과 같이 지킨다.
func _affix_volley() -> void:
	var n: int = 12 if G.difficulty >= 4 else 8
	var a0: float = randf() * TAU
	for i in n:
		var a: float = a0 + TAU * float(i) / float(n)
		_spawn_ebullet(Vector2(cos(a), sin(a)) * 170.0, false)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_touch_cd = maxf(0.0, _touch_cd - delta)
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_react_cd = maxf(0.0, _react_cd - delta)
	_age += delta
	_status_fx(delta)
	var p := G.player
	if p == null or not is_instance_valid(p):
		return
	if G.enemies_frozen() or Time.get_ticks_msec() < _freeze_until:
		velocity = _knock
		_cv.modulate = Color(0.72, 0.86, 1.35)
		_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		global_position = global_position.clamp(Vector2(-BOUND, -BOUND), Vector2(BOUND, BOUND))
		return
	if not _tp_active:  # 순간이동 페이드 중엔 트윈이 알파를 소유
		# ★ 예전엔 매 물리프레임 무조건 흰색을 다시 찍었다. 값이 같아도 CanvasItem 갱신이
		#   걸리므로 적 수만큼 헛일이 났다. 반투명 개체만 갱신하고 나머지는 한 번만 맞춘다.
		if kind == 9 or kind == 13:  # 원혼/유령 군주: 스산하게 어른거리는 반투명
			_cv.modulate = Color(1, 1, 1, 0.62 + 0.28 * sin(_age * 2.6))
		elif Time.get_ticks_msec() < _freeze_until:
			_cv.modulate = Color(0.62, 0.86, 1.45)   # 얼어붙음 — 한눈에
		elif _poison_stacks > 0:
			# ★ 중독은 딜만 들어가고 **걸렸다는 표시가 없었다.** 그래서 "그냥 밟으면
			#   아픈 바닥"으로만 읽혔다. 스택이 쌓일수록 초록이 짙어지게 한다.
			#   맹독(만렙)에 걸린 동안은 더 짙게 — 지금 제일 아픈 놈이 눈에 띄어야 한다.
			var t: float = float(_poison_stacks) / float(POISON_STACK_MAX)
			if Time.get_ticks_msec() < _venom_until:
				t = 1.35
			_cv.modulate = Color(1.0 - 0.45 * t, 1.0, 1.0 - 0.35 * t)
		elif _ice_stacks > 0:
			# 얼음도 쌓이는 게 보여야 "곧 얼겠다"가 읽힌다.
			var it: float = float(_ice_stacks) / float(ICE_STACK_MAX)
			_cv.modulate = Color(1.0 - 0.30 * it, 1.0 - 0.10 * it, 1.0 + 0.30 * it)
		elif _cv.modulate != Color.WHITE:
			_cv.modulate = Color.WHITE
	var to: Vector2 = p.global_position - global_position
	var dist: float = to.length()
	var dir: Vector2 = to.normalized() if dist > 0.01 else Vector2.RIGHT
	_cv.look_dir = dir
	_cv.walk_speed = velocity.length()   # 걸음 위상을 이동 거리에 붙인다(발이 미끄러지지 않게)
	_gimmick(delta, dir, dist, p)
	if kind == 10:  # 달빛 사제: 거리 유지 + 주기적 광역 치유
		_healer_move(delta, dir, dist)
	elif _is_fusion:
		_fusion_move(delta, dir, dist)
	elif _is_boss:
		_boss_ai(delta, dir, dist, p)
	elif _ranged:
		if dist < 190.0:
			velocity = -dir * spd + _knock
		elif dist > 280.0:
			velocity = dir * spd * 0.85 + _knock
		else:
			velocity = dir.orthogonal() * spd * 0.6 + _knock
		if not _atk_primed and _fire_cd <= _cv.lead_time("attack"):
			_atk_primed = _cv.play_once("attack")   # 준비 칸 → 발사 칸에 맞춰 탄이 나간다
		if _fire_cd <= 0.0 and G.shot_budget():
			if not _atk_primed:
				_cv.play_once("skill")   # 공격 시트가 없는 재고 몹 — 영웅 등급만 스킬로 대신한다
			_atk_primed = false
			_shooter_attack(p)
			_fire_cd = randf_range(1.5, 2.1)
	else:
		_normal_move(delta, dir, dist)
	_cf_charge_sync()
	# 특성 이름은 영웅 가까이 온 정예만 — 멀리 몰린 무리의 글자가 서로 겹쳐 못 읽었다(11/7 지옥 사진)
	if _affix_lbl != null and (Engine.get_physics_frames() + get_instance_id()) % 8 == 0:
		_affix_lbl.visible = dist < 420.0
	if _volley_cd > 0.0:
		_volley_cd -= delta
		if _volley_cd <= 0.0:
			_volley_cd = randf_range(3.2, 4.2)
			if dist < 720.0 and G.shot_budget():
				_affix_volley()
	if dist < rad + Player.RADIUS and _touch_cd <= 0.0:
		if p.has_method("take_damage"):
			var hits0: int = G.hits_taken
			p.call("take_damage", touch, "보스 몸박" if _is_boss else "잡몹 몸박")
			_touch_cd = 0.55
			if not affixes.is_empty() and affixes.has("curse") and G.hits_taken > hits0 and p is Player:
				(p as Player).curse_heal(4.0)   # 저주 특성: 물린 뒤 4초 회복 40%
			# 흡혈박쥐 여왕: 실제로 문 만큼만 흡수. ★ 17-2: 예전엔 플레이어 무적 시간에도 0.55초마다 최대 체력의 5% 를
			#   채웠다 — 스테이지 4 보스로 붙어 다니면 분당 몇 통을 회복해서 봇 20판 중 1판만 잡았다(넣은 피해의 1~3% 만 남음).
			if kind == 14 and hp < max_hp and G.hits_taken > hits0:
				hp = minf(max_hp, hp + max_hp * (0.012 if is_stage_boss else 0.02))
				if _boss_fill != null:
					_boss_fill.scale.x = clampf(hp / max_hp, 0.0, 1.0)
				_react_label("흡혈!", Color("ff8aa0"))
			if _is_fusion:
				if p.has_method("apply_stun"):
					p.call("apply_stun", 0.7)  # 융합 보스 접촉 = 스턴
			else:
				_knock += -dir * 150.0
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
	if Time.get_ticks_msec() < _slow_until:
		velocity *= 0.45  # 빙결(얼음 무기) 감속
	velocity += _separation()
	move_and_slide()
	global_position = global_position.clamp(Vector2(-BOUND, -BOUND), Vector2(BOUND, BOUND))
	# 생명의 정원: 자가회복 — '전투 이탈' 시에만 (최근 3.5초 내 피격이면 정지).
	# 예전엔 상시 재생이라 군중전 분산 칩댐을 전부 상쇄 → 아무도 안 죽는 균형이 성립했음 (S1 수정)
	if _regen_stage and not _is_boss and hp < max_hp and Time.get_ticks_msec() - _last_hit_ms > 3500:
		hp = minf(max_hp, hp + max_hp * 0.02 * delta)
	var dot_res: float = 0.5 if _is_boss else 1.0  # 보스는 지속피해 절반 (DoT로 녹는 것 방지, M37)
	_poison_stack_cd = maxf(0.0, _poison_stack_cd - delta)
	_ice_stack_cd = maxf(0.0, _ice_stack_cd - delta)
	_ice_proc_cd = maxf(0.0, _ice_proc_cd - delta)
	_venom_cd = maxf(0.0, _venom_cd - delta)
	if G.running and Time.get_ticks_msec() < _poison_until:  # 중독 DoT ([감사 C20] 종료 후 정지)
		_poison_tick -= delta
		if _poison_tick <= 0.0:
			_poison_tick = DOT_TICK
			var venom: float = VENOM_MULT if Time.get_ticks_msec() < _venom_until else 1.0
			var pd: float = _poison_dmg * DOT_TICK * venom * (1.0 + 0.5 * float(maxi(0, _poison_stacks - 1))) * dot_res
			G.tally("중독도트", pd)
			G.log_dmg("dot_poison", minf(pd, maxf(0.0, hp)))
			hp -= pd
			_last_hit_ms = Time.get_ticks_msec()  # [감사 C24] DoT도 전투 중 판정 — 정원 재생과 병행 방지
			if G.probe_on:
				G.dmg_probe += pd
			_dot_show(pd, Color("8dff6a"))   # 중독 = 초록
			if hp <= 0.0:
				_die()
	elif _poison_stacks > 0:
		_poison_stacks = 0        # 풀렸으면 세기도 0 으로 (안 그러면 다음에 만렙부터 시작한다)
		_poison_dmg = 0.0
	if _ice_stacks > 0 and Time.get_ticks_msec() >= _slow_until:
		_ice_stacks = 0           # 감속이 풀렸으면 얼음 세기도 0
	if not _dead and G.running and Time.get_ticks_msec() < _burn_until:  # 화염 DoT
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = DOT_TICK
			var bd: float = _burn_dmg * DOT_TICK * dot_res
			G.tally("화상도트", bd)
			G.log_dmg("dot_burn", minf(bd, maxf(0.0, hp)))
			hp -= bd
			_last_hit_ms = Time.get_ticks_msec()
			if G.probe_on:
				G.dmg_probe += bd
			_dot_show(bd, Color("ff8a3c"))   # 화상 = 주황
			if hp <= 0.0:
				_die()


## 지속피해(화상·중독) 표시.
## ★ 예전엔 틱마다 숫자를 띄웠는데, 한 틱이 0.4~0.8 이라 int() 가 0 이 되어 "0" 이 끝없이 떴다.
##   진짜 피해 숫자가 그 사이에 묻혀서 "데미지가 눌린다"는 체감까지 만들었다(유저 보고).
##   이제 0.9초 동안 누적했다가 합계를 한 번만 띄운다 — 숫자도 읽히고 노드도 1/3 로 준다.
var _dot_acc: float = 0.0
var _dot_t: float = 0.0

func _dot_show(amount: float, tint: Color = Color(0, 0, 0, 0)) -> void:
	_dot_tint = tint if tint.a > 0.0 else _dot_tint
	_dot_acc += amount
	var now: float = float(Time.get_ticks_msec()) * 0.001
	if now - _dot_t < 0.9:
		return
	_dot_t = now
	var v: int = int(round(_dot_acc))
	_dot_acc = 0.0
	if v > 0:
		DamageNumber.spawn_as(get_parent(), _num_pos(6.0), v, DamageNumber.DOT, _dot_tint, get_instance_id())
		_dot_tint = Color(0, 0, 0, 0)


## 몸집을 바꾼다 — 그림뿐 아니라 접촉 판정(rad)과 물리 도형까지 같이 움직여야
## "분명 안 닿았는데 맞았다 / 분명 닿았는데 안 맞는다"가 안 생긴다.
func _set_size(k: float) -> void:
	if absf(k - _size_k) < 0.02:
		return  # 변화가 작으면 물리 도형을 건드리지 않는다(매 프레임 shape 갱신은 비싸다)
	_size_k = k
	if _cv.is_cf():
		_cv.cf_step_for(k)   # 정수배만 — 단계 그림(px 폴더)이 없으면 그림 크기는 그대로, 판정만 바뀐다
	else:
		_cv.scale = Vector2(k, k)
	rad = _base_rad * k
	if _shape != null:
		_shape.radius = rad


## 돌진 예고(웅크림) = charge 0번 칸, 돌진 중 = 1번 칸에 세운다. 끝나면 푼다.
## 잡몹(웅크렸다 돌진)·보스·융합 보스가 같은 두 변수(_wind · _charge_t)를 쓰므로 한 곳에서 맞춘다.
func _cf_charge_sync() -> void:
	if not _cv.is_cf():
		return
	if _charge_t > 0.0:
		_cv.pose("charge", 1)
	elif _wind > 0.0:
		_cv.pose("charge", 0)
	else:
		_cv.release_pose("charge")


## ── 이면 요괴 기믹 ──
## 종류마다 '한 줄로 설명되는 행동'을 하나씩 준다. 값 계산만 하는 싼 연산이라 수백 마리여도 부담이 없다.
func _gimmick(delta: float, dir: Vector2, dist: float, p: Node2D) -> void:
	match kind:
		16:  # 어둑시니 — 어둠 속에서 자란다. 멀리서 달려들수록 크고 무겁게 부딪친다.
			# ★ 접촉 판정은 반경 30px 안에서만 일어난다. 그 순간의 거리로 배수를 잡으면 far≈0 이라
			#   '멀수록 세진다'가 영원히 발동하지 않고 상시 -36% 너프만 남는다(실제로 그랬다).
			#   최근에 얼마나 멀리 있었는지를 기억해 두고 그 값으로 판정한다.
			_dark_far = maxf(clampf(dist / 900.0, 0.0, 1.0), _dark_far - delta * 0.22)
			_set_size(0.7 + 0.75 * _dark_far)
			touch = _base_touch * (0.6 + 1.1 * _dark_far)
		17:  # 그슨대 — 볼수록 커진다. 살아 있는 시간에 비례해 계속 부푼다.
			_set_size(1.0 + minf(_age * 0.055, 1.2))
		20:  # 야차 — 분노. 체력이 깎일수록 빨라진다.
			var rage: float = 1.0 + (1.0 - clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)) * 0.9
			spd = _base_spd * rage
			if _cv.is_cf():
				_cv.cf_set_state("s1" if hp <= max_hp * RAGE_STAGE else "")   # 붉게 달아오른 시트
		22:  # 물귀신 — 끌어당긴다. 가까이 있으면 플레이어를 자기 쪽으로 잡아끈다.
			if dist < 220.0 and p.has_method("apply_pull"):
				p.call("apply_pull", -dir, 58.0 * delta)
	# 저승사자(27): 명부에 이름이 적히면 주기적으로 광역 낫질을 한다
	if kind == 27:
		_reap_cd -= delta
		if not _reap_primed and _reap_cd <= _cv.lead_time("attack"):
			_reap_primed = _cv.play_once("attack")   # 광역 베기 — 가운데 칸에 판정이 오게 먼저 든다
		if _reap_cd <= 0.0:
			_reap_primed = false
			_reap_cd = 6.5
			_react_ring(Color("d3aef5"), rad + 190.0)
			_react_label("명부", Color("d3aef5"))
			if dist < rad + 200.0 and p.has_method("take_damage"):
				p.call("take_damage", touch * 1.2, "보스 돌진")


## 융합 보스: 돌진(charge) + 사이사이 방사 탄막. 넉백 무효.
func _fusion_move(delta: float, dir: Vector2, dist: float) -> void:
	_charge_cd = maxf(0.0, _charge_cd - delta)
	_burst_cd = maxf(0.0, _burst_cd - delta)
	if _charge_t > 0.0:
		_charge_t -= delta
		velocity = _charge_dir * 560.0  # 돌진
	elif _charge_cd <= 0.0 and dist < 720.0:
		_charge_dir = dir
		_charge_t = 0.5
		_charge_cd = 3.0
		G.add_shake(0.3)
		G.sfx("hurt", 0.55, -1.0)
		if not _cv.cf_has("charge"):
			_cv.play_once("skill")   # 돌진 시트가 없는 재고 — 스킬로 대신
		velocity = _charge_dir * 560.0
	else:
		velocity = dir * spd  # 평상시 느린 추격
	if _burst_cd <= 0.0:
		_burst_cd = 3.8
		if _cv.play_once("ultimate") or _cv.play_once("skill"):
			_cf_vfx_at(global_position)
		_boss_burst()


## 달빛 사제(kind 10): 플레이어와 거리를 두고 맴돌며 2.2초마다 주변 아군을 치유.
## 우선 처치 대상 — 방치하면 군집이 안 죽는다.
var _heal_cd: float = 2.2
## 이 개체가 마지막으로 치유**받은** 시각(ms). 사제가 몇이 겹쳐도 한 몸이 받는 회복은
## 이 쿨 하나로 묶인다.
## ★ 2026-09-06 지적: "치유 몹이 조금만 쌓여도 씹사기". 예전엔 사제마다 독립으로 치유해서
##   사제 N 마리 = 회복 N 배였다. 사제가 넷이면 2.2초마다 최대 체력의 24% 라, 잡몹 군집이
##   플레이어 DPS 를 그냥 앞질렀다. 사제를 여럿 두는 의미는 **넓게 덮는 것**이지
##   같은 몸을 겹쳐 회복하는 게 아니다.
var _healed_at: int = 0
const HEAL_GRACE_MS: int = 1900   # 한 몸이 이 시간 안에 두 번 회복되지 않는다
const HEAL_MAX_TARGETS: int = 6   # 한 번의 맥동이 살리는 최대 수


func _healer_move(delta: float, dir: Vector2, dist: float) -> void:
	if dist < 170.0:
		velocity = -dir * spd + _knock
	elif dist > 260.0:
		velocity = dir * spd * 0.9 + _knock
	else:
		velocity = dir.orthogonal() * spd * 0.7 + _knock
	_heal_cd -= delta
	if _heal_cd <= 0.0:
		_heal_cd = 2.2
		var healed: int = 0
		var now: int = Time.get_ticks_msec()
		# ★ 반경 안의 **전부**를 살렸다. 화면에 130마리가 있으면 130마리가 회복한다 —
		#   사제 한 마리가 군중 전체의 체력바가 되는 구조였다. 한 번에 여섯까지로 묶는다.
		#   "사제 하나가 여섯을 살린다"는 규칙이라 플레이어가 셈할 수 있다.
		for n in G.enemies_cached():
			if healed >= HEAL_MAX_TARGETS:
				break
			if not is_instance_valid(n):
				continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
			var e := n as Enemy
			if e == null or not is_instance_valid(e) or e == self or e._dead or e._is_boss:
				continue
			if now < e._healed_at + HEAL_GRACE_MS:
				continue          # 방금 다른 사제가 살렸다 — 겹쳐서 두 번 받지 않는다
			if global_position.distance_to(e.global_position) < 150.0 and e.hp < e.max_hp:
				if not G.heal_budget():
					break      # 판 전체 회복 예산 소진 — 사제가 몇이든 총량은 같다
				e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.06)
				e._healed_at = now
				_heal_beam(e.global_position)
				healed += 1
		if healed > 0:
			_react_ring(Color("9dff9b"), 150.0)
			_react_label("치유!", Color("beffb0"))


## 누구를 살리고 있는지 선으로 잇는다. 사제를 먼저 잡아야 한다는 걸 화면이 말해 줘야 한다 —
## 초록 고리만으로는 어느 사제가 누굴 살리는지 안 보였다.
func _heal_beam(to: Vector2) -> void:
	if not G.fx_budget():
		return
	var line := Line2D.new()
	line.width = 2.4
	line.default_color = Color(0.62, 1.0, 0.6, 0.55)
	line.points = PackedVector2Array([Vector2.ZERO, to - global_position])
	line.z_index = -1
	add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.45)
	tw.tween_callback(line.queue_free)


## 일반 몹 이동: 추격 / 지그재그 위빙 / 예고 후 돌진 (단조로움 해소)
func _normal_move(delta: float, dir: Vector2, dist: float) -> void:
	# 11/7 「요괴 행렬」: 정한 방향으로 곧장 달린다. 화면을 다 건너면(약 1500px · 6초) 평소 추격으로 돌아온다.
	if rush_dir != Vector2.ZERO:
		_rush_t += delta
		velocity = rush_dir * maxf(spd * 1.8, 260.0) + _knock
		if _rush_t >= 6.0:
			rush_dir = Vector2.ZERO
		return
	match _behavior:
		1:  # 위빙 — 접근하며 좌우로 흔들어 포위
			var perp: Vector2 = dir.orthogonal() * sin(_age * 7.0) * 0.7
			velocity = (dir + perp).normalized() * spd + _knock
		2:  # 돌진 — 쿨 차면 웅크림(예고) 후 대시
			_charge_cd = maxf(0.0, _charge_cd - delta)
			if _charge_t > 0.0:
				_charge_t -= delta
				velocity = _charge_dir * 520.0 + _knock
			elif _wind > 0.0:
				_wind -= delta
				velocity = -dir * 24.0 + _knock
				_cv.modulate = Color(1.5, 0.9, 0.9)  # 붉게 예고
				if _wind <= 0.0:
					_charge_dir = dir
					_charge_t = 0.32
					_charge_cd = randf_range(2.4, 3.4)
					G.sfx_throttled("hurt", 0.7, -7.0, 0.1)
			elif _charge_cd <= 0.0 and dist < 460.0 and dist > 80.0:
				_wind = 0.34
				velocity = dir * spd * 0.4 + _knock
			else:
				velocity = dir * spd * 0.92 + _knock
		_:  # 직선 추격
			velocity = dir * spd + _knock


## 탄막 3종: 조준 단발 / 랜덤 흩뿌리기 / 유도탄
## 이웃 몹에게서 밀려나는 힘. 겹친 만큼만 밀고, 닿지 않으면 0 이다.
##
## ★ 추격을 이기면 안 된다. 밀어내는 힘이 제 속도를 넘으면 플레이어에게 다가오지 못하고
##   서로 튕기기만 하는 '기름 위의 구슬'이 된다. 상한을 spd 의 절반으로 묶는다.
## ★ 보스는 밀리지 않는다 — 잡몹 스무 마리가 보스를 옆으로 치우면 보스전이 성립하지 않는다.
##   대신 잡몹은 보스에게서 밀려난다(격자에는 보스도 들어 있다).
## ★ 매 프레임 다시 재면 몹 400마리 × 이웃 20~30 = 초당 60만 회다(실측으로 판이 눈에 띄게
##   느려졌다). 몹은 프레임당 2px 남짓 움직이므로 3프레임 묵은 값이어도 차이가 없다.
##   개체마다 다른 프레임에 계산하게 흩어 둬서(instance_id % 3) 한 프레임에 몰리지도 않는다.
const SEP_STRENGTH: float = 3.2
const SEP_EVERY: int = 3
var _sep_cache: Vector2 = Vector2.ZERO
var _sep_next: int = -1

func _separation() -> Vector2:
	if _is_boss or _dead:
		return Vector2.ZERO
	var f: int = Engine.get_physics_frames()
	if _sep_next < 0:
		_sep_next = f + int(get_instance_id() % SEP_EVERY)
	if f < _sep_next:
		return _sep_cache
	_sep_next = f + SEP_EVERY
	_sep_cache = Vector2.ZERO
	var grid: Dictionary = G.sep_grid()
	if grid.is_empty():
		return Vector2.ZERO
	var pos: Vector2 = global_position
	var cx: int = int(floor(pos.x / G.SEP_CELL))
	var cy: int = int(floor(pos.y / G.SEP_CELL))
	var push := Vector2.ZERO
	for off: Vector2i in G.SEP_OFF:
		var cell: Variant = grid.get(G.sep_key(cx + off.x, cy + off.y))
		if cell == null:
			continue
		for o in (cell as Array):
			if o == self or not is_instance_valid(o):
				continue
			var e2 := o as Enemy
			if e2 == null or e2._dead:
				continue
			var d: Vector2 = pos - e2.global_position
			# 판정 반경(rad)이 아니라 **그려지는 크기**를 기준으로 떼어 놔야 눈에 안 겹친다.
			# 보이는 반경 = rad * CreatureVisual.DRAW_SCALE / 2.
			var want: float = (rad + e2.rad) * (CreatureVisual.DRAW_SCALE * 0.5) * 0.95
			var dist: float = d.length()
			if dist >= want:
				continue
			if dist < 0.5:
				# 완전히 같은 자리 — 방향이 없으니 개체마다 다른 쪽으로 흩어 준다.
				var a: float = float(get_instance_id() % 628) * 0.01
				push += Vector2(cos(a), sin(a)) * want
				continue
			push += d / dist * (want - dist)
	if push != Vector2.ZERO:
		_sep_cache = (push * SEP_STRENGTH).limit_length(spd * 0.5)
	return _sep_cache


func _shooter_attack(p: Node2D) -> void:
	var to_p: Vector2 = (p.global_position - global_position).normalized()
	match randi() % 3:
		0:
			_spawn_ebullet(to_p * 225.0, false)
		1:
			for i in 3:
				var a: float = to_p.angle() + randf_range(-0.55, 0.55)
				_spawn_ebullet(Vector2(cos(a), sin(a)) * 205.0, false)
		2:
			_spawn_ebullet(to_p * 155.0, true)


func _spawn_ebullet(vel: Vector2, homing: bool) -> void:
	if not EnemyBullet.can_spawn():  # 적 탄환 상한 — 넘치면 이번 발사는 없던 일로
		return
	var b := EnemyBullet.new()
	b.setup(vel, touch * 0.8, homing)
	b.global_position = global_position
	get_parent().add_child(b)


func _boss_burst() -> void:
	var n: int = 26 if rad > 60.0 else 16
	if G.mobile:
		n = int(n * 0.7)  # 모바일: 방사 탄막 밀도 완화 (패턴은 유지)
	# ★ 루프 안에서 상한에 걸려 break 하면 한쪽만 뚫린 부채꼴이 나온다(피할 방향이 편향됨).
	#   남은 여유를 먼저 보고 개수를 줄여, 성기더라도 사방이 고르게 나가게 한다.
	n = mini(n, maxi(4, G.enemy_bullet_cap() - EnemyBullet.live))
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var b := EnemyBullet.new()
		b.setup(Vector2(cos(a), sin(a)) * 175.0, touch * 0.7)
		b.global_position = global_position
		get_parent().add_child(b)


## 보스 AI: 사거리 유지 선회(circle strafe) ↔ 예고 후 돌진을 오가며, 탄막 3종·예고장판·잔몹소환을 섞음.
## 직선추격 하나뿐이던 걸 살아있게 — 넉백·기존 헬퍼(TelegraphAoE/EnemyBullet/_react_ring) 재사용. 융합(kind6)은 _fusion_move가 담당.
func _boss_ai(delta: float, dir: Vector2, dist: float, p: Node2D) -> void:
	if reaper:
		_reaper_sync(p)
	# 체력 절반 아래 모습(s1) — 보스 중엔 염라만 시트가 있다(업경 · 붉게). 시트가 없으면 기본 그대로.
	if _cv.is_cf():
		_cv.cf_set_state("s1" if hp <= max_hp * RAGE_STAGE else "")
	# ── 이동: 대시 / 돌진예고 / 평상시 선회 ──
	_charge_cd = maxf(0.0, _charge_cd - delta)
	if kind == 13:  # 유령 군주: 돌진 대신 순간이동 (예고 링 → 소멸 → 플레이어 옆 재출현)
		velocity = dir * spd * 0.8 + _knock
		if _charge_cd <= 0.0 and dist > 150.0:
			_charge_cd = randf_range(5.0, 7.0)
			_ghost_teleport(p)
	elif _charge_t > 0.0:  # 대시 중 — 빠르게 파고듦 (박쥐 여왕은 더 빠른 급습)
		_charge_t -= delta
		velocity = _charge_dir * (640.0 if kind == 14 else 520.0) + _knock
	elif _wind > 0.0:  # 돌진 예고(웅크림) — 붉게 번쩍, 곧 튄다
		_wind -= delta
		velocity = -dir * spd * 0.3 + _knock
		_cv.modulate = Color(1.6, 0.7, 0.7)
		if _wind <= 0.0:
			_charge_dir = dir
			_charge_t = 0.34 if kind != 14 else 0.42
			G.add_shake(0.3)
			G.sfx_throttled("hurt", 0.6, -3.0, 0.1)
	else:
		_boss_move_cd -= delta
		if _boss_move_cd <= 0.0:  # 이동 모드 재선정
			var charge_p: float = 0.5
			if kind == 14:
				charge_p = 0.72  # 박쥐 여왕: 급습 위주
			elif kind == 15:
				charge_p = 0.0   # 슬라임 킹: 돌진 없음(느린 압박 + 탄막)
			if is_stage_boss:
				charge_p = minf(0.85, charge_p + 0.25)  # 스테이지 보스: 돌진 잦음
			if _charge_cd <= 0.0 and dist > 120.0 and randf() < charge_p:
				_wind = 0.55  # 돌진 예고 시작
				_charge_cd = randf_range(2.6, 4.2) if (kind == 14 or is_stage_boss) else randf_range(4.0, 6.0)
				_boss_move_cd = 1.2
			else:
				_strafe_sign = 1.0 if randf() < 0.5 else -1.0
				_boss_move_cd = randf_range(1.6, 2.8)
		# 사거리 유지하며 선회 — 웨이브 보스 ~210px / 스테이지 보스는 근접(~110px)까지 파고듦
		# (겉돌면 플레이어에 붙은 잡몹이 보스행 탄환을 전부 흡수 → 보스전이 안 끝남)
		var far_r: float = 130.0 if is_stage_boss else 250.0
		var near_r: float = 85.0 if is_stage_boss else 170.0
		var radial: float = 1.0 if dist > far_r else (-1.0 if dist < near_r else 0.0)
		velocity = (dir * radial + dir.orthogonal() * _strafe_sign).normalized() * spd + _knock
		if reaper:
			velocity = dir * spd + _knock  # 사신은 선회하지 않고 곧장 쫓는다
	# ── 탄막 (종류별 패턴) ──
	if _fire_cd <= 0.0:
		_fire_cd = randf_range(1.8, 2.5) if kind == 15 else randf_range(2.2, 3.0)
		_cv.play_once("skill")
		_boss_fire(dir)
	# ── 예고형 장판 (슬라임 킹은 독 웅덩이를 더 자주·넓게) ──
	_special_cd -= delta
	if _special_cd <= 0.0:
		_special_cd = randf_range(4.0, 6.0) if kind == 15 else randf_range(5.5, 8.0)
		var r_aoe: float = 150.0 if (kind == 5 or kind == 15) else 120.0
		TelegraphAoE.spawn(get_parent(), p.global_position, r_aoe, 1.0, touch * 1.5)
		if _cv.play_once("ultimate") or _cv.play_once("skill"):
			_cf_vfx_at(p.global_position)
	# ── 잔몹 소환(최종보스·박쥐 여왕은 자주) ──
	_summon_cd -= delta
	if _summon_cd <= 0.0:
		_summon_cd = 14.0 if kind == 5 else (11.0 if kind == 14 else 22.0)
		_cv.play_once("ultimate")
		_boss_summon()


## 사신: 속도와 피해를 지금 플레이어 수치에 맞춘다(이동 속도 카드 · 최대 체력 카드로 벗어날 수 없게).
## 시간 왜곡(전설)의 적 감속은 그대로 먹는다 — 사기 조합의 한 축.
func _reaper_sync(p: Node2D) -> void:
	var pl := p as Player
	if pl == null:
		return
	var mins: float = maxf(0.0, G.time_alive - G.reaper_t0) / 60.0
	spd = pl.move_speed * minf(REAPER_SPD_MAX, REAPER_SPD + REAPER_SPD_GROW * mins) * maxf(0.5, 1.0 - pl.enemy_slow)
	touch = pl.max_hp * minf(REAPER_HIT_MAX, REAPER_HIT + REAPER_HIT_GROW * mins)
	_base_touch = touch


## 유령 군주: 예고 링 → 페이드아웃 → 플레이어 근처 재출현(도착 예고 포함)
func _ghost_teleport(p: Node2D) -> void:
	_react_ring(Color("d8faff"), rad + 26.0)
	G.sfx_throttled("hurt", 1.3, -6.0, 0.1)
	var dest: Vector2 = p.global_position + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * randf_range(150.0, 210.0)
	dest = dest.clamp(Vector2(-BOUND + 80.0, -BOUND + 80.0), Vector2(BOUND - 80.0, BOUND - 80.0))
	_tp_active = true
	_cv.pose("vanish", 0)   # 안개처럼 사라짐 (시트가 없으면 흐려지기만)
	var tw := create_tween()
	tw.tween_property(_cv, "modulate:a", 0.06, 0.35)
	tw.tween_callback(func() -> void:
		if _dead or not is_inside_tree():
			return
		global_position = dest
		_cv.pose("vanish", 1)   # 다시 나타남
		_react_ring(Color("d8faff"), rad + 30.0)
		G.add_shake(0.25))
	tw.tween_property(_cv, "modulate:a", 0.9, 0.25)
	tw.tween_callback(func() -> void:
		_tp_active = false
		_cv.release_pose("vanish"))


## 보스 탄막: 종류별 고유 패턴 + 공용 3종(방사링/나선/조준 부채꼴)
func _boss_fire(dir: Vector2) -> void:
	if kind == 13:  # 유령 군주: 유도 원혼탄 3발
		var base_a: float = dir.angle()
		for j in 3:
			var a: float = base_a + (float(j) - 1.0) * 0.5
			_spawn_ebullet(Vector2(cos(a), sin(a)) * 165.0, true)
		return
	if kind == 15:  # 슬라임 킹: 굵은 독 방사 (2겹 링)
		var n2: int = 12
		for i in n2:
			var a2: float = TAU * float(i) / float(n2) + _age * 0.7
			_spawn_ebullet(Vector2(cos(a2), sin(a2)) * 150.0, false)
			if randf() < 0.4:
				_spawn_ebullet(Vector2(cos(a2 + 0.13), sin(a2 + 0.13)) * 105.0, false)
		return
	match randi() % 3:
		0:  # 균등 방사 링 (기존 재사용)
			_boss_burst()
		1:  # 나선 — 나이(_age)에 따라 각도가 도는 방사
			var n: int = 14 if rad > 60.0 else 10
			var off: float = _age * 2.2
			for i in n:
				var a: float = TAU * float(i) / float(n) + off
				_spawn_ebullet(Vector2(cos(a), sin(a)) * 185.0, false)
		2:  # 조준 산탄 — 플레이어 방향 부채꼴 5발
			var base_a: float = dir.angle()
			for j in 5:
				var a2: float = base_a + (float(j) - 2.0) * 0.16
				_spawn_ebullet(Vector2(cos(a2), sin(a2)) * 235.0, false)


## 보스 소환: 약한 스웜(박쥐/고블린) 3마리를 주변에. _do_split처럼 deferred add_child로 안전하게.
func _boss_summon() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var cnt: int = 4 if kind == 14 else 3
	if not G.reserve_spawn(cnt):
		return  # [감사 C13] 소환도 몹 상한 준수 — 보스전 잡몹 벽 재발 방지
	G.sfx_throttled("hurt", 0.9, -6.0, 0.1)
	_react_ring(Color("ff9ad0"), rad + 30.0)  # 소환 파문
	for i in cnt:
		var m := Enemy.new()
		if kind == 14:
			m.kind = 1  # 박쥐 여왕은 박쥐 무리만
		elif kind == 13:
			m.kind = 9  # 유령 군주는 원혼
		else:
			m.kind = 1 if randf() < 0.5 else 7  # 박쥐/고블린
		m._mini = true
		m._has_spawn_pos = true
		var a: float = TAU * float(i) / float(cnt) + _age  # [감사 C33] 분모 3 하드코딩 → 4마리가 겹치던 것 수정
		m._spawn_pos = global_position + Vector2(cos(a), sin(a)) * (rad + 40.0)
		parent.call_deferred("add_child", m)


## 피해 숫자 자리. ★ 14차: 보스는 머리 위에 이름표 · 체력 막대가 있어 숫자가 그 위에 겹쳤다(「20」이 보스 이름 위) —
##   보스는 몸 가운데에서 띄운다(에셋 담당 「이름표 · 막대와 겹치는 자리에는 숫자를 띄우지 않는다」).
func _num_pos(dy: float) -> Vector2:
	if _is_boss:
		return global_position + Vector2(0, -rad * 0.15)
	return global_position + Vector2(0, -rad - dy)


func take_damage(amount: float, knock_dir: Vector2, crit: bool = false, src: String = "") -> void:
	if _dead or not G.running:
		return  # 종료 후 잔존 탄환/장판이 몹을 계속 잡는 것 차단 (S4)
	if Time.get_ticks_msec() < _vuln_until:  # 취약(초전도 반응): 받는 피해 증가
		amount *= _vuln_mult
	# ── 이면 요괴 기믹: 받는 피해 쪽 ──
	if kind == 19:  # 불가사리 — 쇠를 먹는다. 탄환 피해를 절반만 받고 그만큼 회복한다.
		var eaten: float = amount * 0.45
		amount -= eaten
		hp = minf(max_hp, hp + eaten * 0.35)
		if randf() < 0.12:
			_react_label("먹는다", Color("aab8cc"))
	elif kind == 24:  # 강철 도깨비 — 방망이만큼 두껍다. 한 방에 정해진 양을 깎아낸다.
		amount = maxf(amount * 0.35, amount - 14.0)
	if _shield > 0.0:   # 11/7 보호막 특성: 체력보다 먼저 깎인다
		var ab: float = minf(_shield, amount)
		_shield -= ab
		amount -= ab
		if _shield <= 0.0:
			_shield_break()
		if amount <= 0.0:
			_cv.flash(AFFIX_COLORS["shield"])
			return
	if G.probe_on:
		G.dmg_probe += amount
	_last_hit_ms = Time.get_ticks_msec()
	G.log_dmg(src, minf(amount, maxf(0.0, hp)))
	hp -= amount
	# 넉백 대폭↓ — 예전엔 밀어버려서 적이 다가오질 못함(너무 쉬움). 이제 살짝 밀림.
	# 넉백 = 탄환 위력 비례(속사 저위력탄 스팸이 무한히 밀어내던 것 방지) + 누적 상한 (M38)
	var kf: float = 0.0 if _is_fusion else (22.0 if _is_boss else 48.0 * clampf(amount / 14.0, 0.25, 1.25))
	_knock = (_knock + knock_dir.normalized() * kf).limit_length(240.0)
	DamageNumber.spawn(get_parent(), _num_pos(6.0), int(amount), crit, get_instance_id())
	_cv.flash(Color.WHITE)
	_cv.hurt()
	# 처형(b_exec): 체력 낮은 잡몹 즉살 (보스 제외, 직접타격에만)
	if not _is_boss and hp > 0.0 and G.player != null and is_instance_valid(G.player):
		var ex: int = (G.player as Player).b_exec
		if ex > 0 and hp <= max_hp * (0.05 + 0.035 * float(ex)):
			hp = 0.0
			_exec_fx()
	if _is_boss and _boss_fill != null:
		_boss_fill.scale.x = clampf(hp / max_hp, 0.0, 1.0)
	if hp <= 0.0:
		_die()


## 처형 이펙트: 붉은 X 슬래시
func _exec_fx() -> void:
	G.sfx_throttled("kill", 1.3, -3.0, 0.03)
	if not G.fx_budget():
		return  # X슬래시 비주얼만 게이트 (즉살 판정은 이미 끝남)
	var xk: Array = ["evo_reaper", "execute"] if G.fused("wpn_whip", "evo_reaper") else \
		(["evo_ledger", "mark"] if G.fused("bow", "evo_ledger") else [])
	if not xk.is_empty() and FxLib.burst(get_parent(), global_position, String(xk[0]), String(xk[1]),
			0.0, maxf(1.0, rad / 16.0), -1.0, 55) != null:
		return
	for s in [-1.0, 1.0]:
		var l := Line2D.new()
		l.width = 4.0
		l.default_color = Color("ff5566")
		l.add_point(Vector2(-rad, -rad * s))
		l.add_point(Vector2(rad, rad * s))
		l.global_position = global_position
		l.z_index = 55
		get_parent().add_child(l)
		var tw := l.create_tween()
		tw.tween_property(l, "scale", Vector2(1.6, 1.6), 0.18)
		tw.parallel().tween_property(l, "modulate:a", 0.0, 0.18)
		tw.tween_callback(l.queue_free)


func _die() -> void:
	_dead = true
	# 폭발 개화(b_bloom): 죽을 때 광역 폭발 (연쇄 가능). 잔몹만.
	if not _is_boss and G.player != null and is_instance_valid(G.player):
		var bl: int = (G.player as Player).b_bloom
		if bl > 0 and _bloom_depth < BLOOM_MAX_DEPTH:
			_bloom_explode(bl, _bloom_depth + 1)
	if is_bomber and not _chain_bombed:  # 자폭형: 죽을 때 광역 폭발 (다른 폭발로 죽으면 연쇄 X)
		_bomber_detonate()
	if split_gen > 0 and not _is_boss:  # 분열형: 2마리로 쪼개짐
		_do_split()
	if kind == 11:  # 마그마 골렘: 죽으면서 탄환 8방 방출 (마지막까지 위협적)
		_golem_nova()
	if kind == 15:  # 맹독 슬라임 킹: 죽으면 미니 슬라임 4마리로 갈라짐
		_king_split()
	G.add_kill(art)   # 도감 「처치 n」 — 저승길 몹은 저승길 칸에 센다
	G.codex_see("mon_%d" % art)  # 도감 해금 (저승길 몹은 저승길 칸)
	if special:
		G.quest_add("spec", 1)  # 퀘스트: 특수 개체 처치 (S5)
	if _is_boss:
		G.stat_add("total_bosses", 1)
		G.quest_add("boss", 1)
	_drop_gold()  # 골드는 카운터 증가가 아니라 금화 드랍 → 주워야 함
	G.enemy_died.emit(global_position)
	G.sfx("kill", G.kill_pitch())  # 콤보가 쌓일수록 높아지는 처치음 (연쇄 쾌감)
	if special:  # 특수 개체 처치: 맑은 차임 + 보라 확산 링 — "귀한 걸 잡았다"
		G.sfx("levelup", 1.55, -8.0)
		_react_ring(Color(0.8, 0.5, 1.0, 0.9), rad + 20.0)
	_drop()
	_burst()
	set_deferred("collision_layer", 0)
	remove_from_group("enemy")
	if _is_boss:
		G.add_shake(0.5)
		G.hitstop(0.1)
	if _cv.play_once("death", true):
		# 잡몹은 1초 가까이 누워 있으면 수백 마리가 바닥에 쌓인다 — 쓰러지는 칸만 보이고 빨리 걷는다.
		# 보스는 끝 칸(700ms)까지 다 보여 준다.
		var hold: float = _cv.anim_len("death") if _is_boss else minf(_cv.anim_len("death"), 0.5)
		var dtw := create_tween()
		dtw.tween_interval(hold)
		dtw.tween_property(_cv, "modulate:a", 0.0, 0.15)
		dtw.tween_callback(queue_free)
		return
	var tw := create_tween()
	tw.tween_property(_cv, "scale", Vector2(1.7, 1.7), 0.12)
	tw.parallel().tween_property(_cv, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)


func _drop() -> void:
	var xpv: int = maxi(1, int(round(float(_xp) * G.stage_xp_mult)))  # 맵 특화 XP 배수
	if _is_boss:
		Pickup.spawn(get_parent(), global_position + Vector2(-28, 0), Pickup.HEAL)
		Pickup.spawn(get_parent(), global_position + Vector2(28, 0), Pickup.MAGNET)
		Pickup.spawn(get_parent(), global_position + Vector2(0, 28), Pickup.BIGXP)
		Pickup.spawn(get_parent(), global_position + Vector2(0, -34), Pickup.CHEST_BOSS)  # 보스 상자: 강화 1~5개 (M37)
		XpGem.spawn(get_parent(), global_position, xpv)
		return
	XpGem.spawn(get_parent(), global_position, xpv)
	var lf: float = 1.0  # 행운 곱연산 (행운 없으면 극악 확률)
	if G.player != null and is_instance_valid(G.player):
		lf = 1.0 + (G.player as Player).luck
	# ★ 11/7 스팀 플레이 보고: 「자석이랑 멈추는 게 너무 잘 떠서 쉽다」. 처치 확률만 있어 후반(초당 수십 마리)엔
	#   몇 초마다 떨어졌다. 확률은 그대로 두고 같은 아이템이 다시 떨어지기까지 최소 간격(G.DROP_GAP)을 둔다.
	var roll: float = randf()
	if roll < 0.010 * lf:
		if G.drop_ready(Pickup.HEAL):
			Pickup.spawn(get_parent(), global_position, Pickup.HEAL)
	elif roll < 0.017 * lf:
		if G.drop_ready(Pickup.MAGNET):
			Pickup.spawn(get_parent(), global_position, Pickup.MAGNET)
	elif roll < 0.022 * lf:
		if G.drop_ready(Pickup.FREEZE):
			Pickup.spawn(get_parent(), global_position, Pickup.FREEZE)
	elif roll < 0.032 * lf:
		Pickup.spawn(get_parent(), global_position, Pickup.BIGXP)


## 골드 금화 드랍 — 일반은 확률, 보스는 다발. 난이도·행운 반영.
## 분당 예산을 시간에 걸쳐 방출(G.gold_drop_room): 예산이 마르면 이번 분에는 더 안 낸다.
func _drop_gold() -> void:
	var dm: float = G.run_gold_mult()  # 난이도 × 스테이지 배수 (높이 갈수록 벌이 급증)
	var lf: float = 1.0
	if G.player != null and is_instance_valid(G.player):
		lf = 1.0 + (G.player as Player).luck * 0.5
	# ★ 모든 금화는 G.gold_take / G.gold_event 를 거친다. 예산이 마르면 '적게'가 아니라
	#   '아예 안 나온다' — 예전의 0.15배 트리클이 초당 80킬 구간에서 상한을 40배 넘겼다.
	# ★ 특수 개체는 전체 스폰의 8% 라 '희귀 이벤트'가 아니다. 여기에 예산 우회(gold_event)를
	#   주면 판당 수백 골드가 상한 밖으로 샌다(실측). 보스/융합보스만 우회를 쓴다.
	if special:  # 특수 개체(달빛 사제 포함): 처치 보상 — 금화 다발(단, 예산 안에서)
		if G.gold_drop_room() <= 0:
			return
		for i in 2:
			var sv: int = G.gold_take(maxi(2, int(round(randf_range(2.0, 5.0) * dm))))
			if sv <= 0:
				continue
			var so := Vector2(randf_range(-22.0, 22.0), randf_range(-22.0, 22.0))
			GoldCoin.spawn(get_parent(), global_position + so, sv)
		return
	# 목표: 보통 30분 완주 ≈ 분당 상한 × 30 (행운/메타/스테이지로 상향). 기본은 극악하게.
	if _is_fusion:
		for i in 5:
			var fv: int = G.gold_event(int(round(randf_range(6.0, 14.0) * dm)))
			if fv <= 0:
				continue
			var o := Vector2(randf_range(-44.0, 44.0), randf_range(-44.0, 44.0))
			GoldCoin.spawn(get_parent(), global_position + o, fv)
	elif _is_boss:
		for i in 2:
			var bv: int = G.gold_event(int(round(randf_range(5.0, 12.0) * dm)))
			if bv <= 0:
				continue
			var o2 := Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
			GoldCoin.spawn(get_parent(), global_position + o2, bv)
	else:
		if G.gold_drop_room() <= 0:
			return  # 이번 분 예산 소진 — 몇 마리를 더 잡든 이 분에는 더 안 나온다
		if randf() < 0.20 * lf:  # 금화 드랍 (경험치젬과 겹치지 않게 옆으로 오프셋)
			var gv: int = G.gold_take(maxi(1, int(round(randf_range(1.6, 4.2) * dm))))
			if gv <= 0:
				return
			var goff := Vector2(randf_range(20.0, 34.0) * (1.0 if randf() < 0.5 else -1.0), randf_range(-10.0, 10.0))
			GoldCoin.spawn(get_parent(), global_position + goff, gv)


## 보스 등장 이중 충격파 (add_child 완료 후 deferred 호출)
## 캐릭터 에셋의 시그니처 이펙트를 그 자리에 잠깐 띄운다(보스 궁극기가 떨어지는 자리).
func _cf_vfx_at(pos: Vector2) -> void:
	if not is_inside_tree():
		return
	var fx: Sprite2D = _cv.make_vfx()
	if fx == null:
		return
	fx.global_position = pos
	fx.modulate = Color(1, 1, 1, 0.9)
	get_parent().add_child(fx)
	var tw := fx.create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(fx, "modulate:a", 0.0, 0.4)
	tw.tween_callback(fx.queue_free)


func _boss_entrance_fx() -> void:
	if _dead or not is_inside_tree():
		return
	_react_ring(Color(_base_color.r, _base_color.g, _base_color.b, 0.95), rad + 30.0)
	_react_ring(Color(1, 1, 1, 0.7), rad + 60.0)


## 머리 위 체력바. 웨이브 중간보스(kind 4/13/14/15)와 스테이지 보스가 단다.
## ★ 융합 보스(kind 6)는 상단 전체바를 쓰므로 이 바가 없다. 그래서 "몰려든다" 로 나온 융합체와
##   "중간보스 출현" 으로 나온 놈이 **표시가 달라 보여** 버그로 신고받았다(2026-09-07).
##   실제로는 서로 다른 적이 맞는데 화면이 그걸 안 알려준 것이라, 바 위에 이름을 적는다.
##   이름은 도감(Codex.MONSTERS)에서 가져온다 — 이름표가 두 군데로 갈리면 반드시 어긋난다.
func _build_boss_bar() -> void:
	# 14차: 부품 HUD 는 위 가운데 보스 막대(얼굴 · 이름)가 있다 — 머리 위 이름표 · 분홍 막대까지 달면 같은 이름이
	#   화면에 두 번 뜬다(12분 화면). 목업 hud.png 도 보스 머리 위는 비어 있다.
	if UiParts.on():
		return
	var nm: String = Codex.monster_name(art)
	if nm != "":
		var lbl := Label.new()
		lbl.text = nm
		UiFont.apply(lbl, 13)
		lbl.add_theme_color_override("font_color", Color("ffd9e4"))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size = Vector2(rad * 4.0, 16.0)
		lbl.position = Vector2(-rad * 2.0, -rad - 38.0)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
	var w: float = rad * 2.4
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5, 7), Vector2(-w * 0.5, 7)])
	bg.color = Color(0, 0, 0, 0.6)
	bg.position = Vector2(0, -rad - 18.0)
	add_child(bg)
	_boss_fill = Polygon2D.new()
	_boss_fill.polygon = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 7), Vector2(0, 7)])
	_boss_fill.color = Color("ff5c8a")
	_boss_fill.position = Vector2(-w * 0.5, -rad - 18.0)
	add_child(_boss_fill)


func _burst() -> void:
	# ★ 킬마다 CPUParticles2D 노드 + SceneTreeTimer 를 새로 만든다. 초당 수십~수백 킬이 나는
	#   게임이라 예산을 안 걸면 이것만으로 노드 생성이 폭주한다. 보스는 항상 터뜨린다.
	if not _is_boss and not _elite and not G.fx_budget():
		return
	var pt := CPUParticles2D.new()
	pt.emitting = true
	pt.one_shot = true
	pt.explosiveness = 1.0
	pt.amount = 14 if _is_boss else (5 if G.mobile else 9)
	pt.lifetime = 0.5
	pt.speed_scale = 1.6
	pt.spread = 180.0
	pt.initial_velocity_min = 100.0
	pt.initial_velocity_max = 320.0 if _is_boss else 280.0
	pt.scale_amount_min = 2.0
	pt.scale_amount_max = 5.0 if _is_boss else 4.0
	# 걸린 원소 상태에 따라 파편 색 변화 (불타 죽으면 불꽃, 얼어 죽으면 얼음 조각…)
	var bc: Color = _base_color
	if _has_fire():
		bc = Color("ff8a3c")
	elif _has_ice():
		bc = Color("9fd8ff")
	elif _has_poison():
		bc = Color("8fe36b")
	elif _has_shock():
		bc = Color("ffe23f")
	pt.color = bc
	pt.global_position = global_position
	get_parent().add_child(pt)
	# 타이머 노드 하나를 더 만드는 대신 파티클 자신이 끝나면 사라지게 한다
	pt.finished.connect(pt.queue_free)
	# 큰 몹/엘리트/보스는 확산 링 추가 — "잡았다"는 확실한 한 방
	if (_elite or _is_boss or rad >= 20.0) and G.fx_budget():
		_react_ring(Color(bc.r, bc.g, bc.b, 0.9), rad + 14.0)


## 마그마 골렘: 사망 시 8방 탄환 (물리 콜백 중일 수 있어 deferred 스폰)
func _golem_nova() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for i in 8:
		var a: float = TAU * float(i) / 8.0 + _age
		if not EnemyBullet.can_spawn():
			break
		var b := EnemyBullet.new()
		b.setup(Vector2(cos(a), sin(a)) * 165.0, touch * 0.6)
		b.global_position = global_position
		parent.call_deferred("add_child", b)


## 맹독 슬라임 킹: 사망 시 미니 슬라임 4마리 (마지막 저항)
func _king_split() -> void:
	var parent := get_parent()
	if parent == null or not G.running:
		return  # [감사 C31] 스테이지 클리어(승리) 순간엔 분열 생략 — 승리 화면에 잡몹 솟아나는 것 방지
	if not G.reserve_spawn(4):
		return  # [감사 C13] 몹 상한 준수
	for i in 4:
		var m := Enemy.new()
		m.kind = 0
		m._mini = true
		m._has_spawn_pos = true
		var a: float = TAU * float(i) / 4.0 + _age
		m._spawn_pos = global_position + Vector2(cos(a), sin(a)) * (rad + 16.0)
		parent.call_deferred("add_child", m)


## 폭발 개화: 죽을 때 주변 잔몹에 광역 피해 (연쇄 사망 유도)
func _bloom_explode(lv: int, depth: int = 1) -> void:
	# 연쇄 한 단계마다 반경·피해가 확 줄어든다 — '터지는 맛'은 남기고 도미노만 끊는다
	# ★ 연쇄 깊이를 막은 뒤에도 총피해의 44% 였다. 이유는 '한 번에 여러 마리'다 —
	#   같은 피해라도 반경 안 15마리를 동시에 때리면 탄환 한 발의 15배가 된다.
	#   대상당 위력을 탄환 한 발보다 확실히 낮게 두고 반경도 줄인다(광역은 그 자체가 값이다).
	var fall: float = pow(0.55, float(depth - 1))
	var r: float = (48.0 + 5.0 * float(lv)) * fall
	var dmg: float = _rp() * (0.18 + 0.07 * float(lv)) * fall
	if G.fx_budget():  # 링 비주얼만 예산 게이트 (아래 광역 피해는 항상 적용)
		var ring := Line2D.new()
		ring.width = 5.0
		ring.default_color = Color("ff9a4a")
		var pts: PackedVector2Array = G.regular_polygon(18, r)
		for pt: Vector2 in pts:
			ring.add_point(pt)
		ring.add_point(pts[0])
		ring.global_position = global_position
		ring.z_index = 42
		get_parent().add_child(ring)
		var tw := ring.create_tween()
		tw.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.22)
		tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
		tw.tween_callback(ring.queue_free)
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or e == self or e._dead:
			continue
		if global_position.distance_to(e.global_position) < r:
			if e.is_bomber:  # 이 폭발로 죽으면 연쇄기폭 금지, 살아남으면 원복
				e._chain_bombed = true
			e._bloom_depth = depth  # 이 폭발로 죽으면 다음 개화는 한 세대 깊어진다
			G.tally("폭발개화", dmg)
			e.take_damage(dmg, (e.global_position - global_position).normalized(), false, "b_bloom")
			if is_instance_valid(e) and not e._dead:
				e._chain_bombed = false
				e._bloom_depth = 0  # 살아남았으면 원복 (나중에 총으로 죽을 땐 1세대로 터진다)


## 분열형: 같은 종류의 작은 개체 2마리로 쪼개짐 (남은 세대 -1).
## _die는 물리 충돌 콜백 중 호출될 수 있어 add_child를 deferred로 — 설정은 전부 플래그로 넘김.
func _do_split() -> void:
	var parent := get_parent()
	if parent == null or not G.running:
		return
	if not G.reserve_spawn(2):
		return  # [감사 C13] 분열도 몹 상한 준수
	for i in 2:
		var m := Enemy.new()
		m.kind = kind
		m.art = art   # 갈라진 몸은 부모와 같은 그림 (무한 모드에서 그새 테마가 바뀌어도)
		m.split_gen = split_gen - 1
		m._mini = true
		m._has_spawn_pos = true
		m._spawn_pos = global_position + Vector2(cos(TAU * float(i) / 2.0 + _age), sin(TAU * float(i) / 2.0 + _age)) * (rad + 10.0)
		parent.call_deferred("add_child", m)


## 자폭형: 죽을 때 광역 폭발 — 플레이어와 주변 적에게 피해
func _bomber_detonate() -> void:
	var r: float = 96.0
	G.add_shake(0.22)
	G.sfx_throttled("hurt", 0.6, -2.0, 0.05)
	var ring := Line2D.new()
	ring.width = 6.0
	ring.default_color = Color("ff5030")
	var pts: PackedVector2Array = G.regular_polygon(20, r)
	for pt: Vector2 in pts:
		ring.add_point(pt)
	ring.add_point(pts[0])
	ring.global_position = global_position
	ring.z_index = 44
	get_parent().add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector2(1.6, 1.6), 0.24)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.24)
	tw.tween_callback(ring.queue_free)
	var p := G.player
	if p != null and is_instance_valid(p) and p.global_position.distance_to(global_position) < r + Player.RADIUS:
		if p.has_method("take_damage"):
			p.call("take_damage", touch * 1.3, "자폭 폭발")
	for n in G.enemies_cached():  # 자기 편에게도 피해(연쇄)
		if not is_instance_valid(n):
			continue
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or e == self or e._dead:
			continue
		if global_position.distance_to(e.global_position) < r:
			G.tally("자폭폭발", touch * 1.5)
			e.take_damage(touch * 1.5, (e.global_position - global_position).normalized(), false, "bomber")
