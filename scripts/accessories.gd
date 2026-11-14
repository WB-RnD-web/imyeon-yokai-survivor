class_name Accessories
extends Object
## 액세서리(장신구) — 런 밖에서 사는 영구 장비. 상점에서 골드로 사고, 4칸에 끼워 나간다.
##
## ★ 왜 새로 만드나
##   기존 영구 성장축은 '스탯 8종 숫자 올리기' 하나뿐이었다. 숫자는 늘어나도 빌드가 바뀌지
##   않아서, 상점에 다시 들어갈 이유가 골드 소진 말고는 없었다. 액세서리는 '무엇을 끼느냐'로
##   같은 캐릭터의 플레이가 달라지는 축이다 — 칸이 4개뿐이라 고르는 순간 포기하는 것이 생긴다.
##
## ★ 레벨업 카드(탄막 부여)와 다른 점
##   카드는 런 안에서만 살고 무작위로 뽑힌다. 액세서리는 저장되고 내가 골라 낀다.
##   그래서 효과는 '판을 여는 조건'(시작 무기·시작 자원·규칙 변경) 위주로 두고,
##   단순 수치 증가는 등급이 오를수록 붙는 부가 효과로만 준다.

const SLOTS: int = 4

## 등급 — 값이 클수록 비싸고 세다. 상점 정렬·테두리 색에 쓴다.
const TIERS: Dictionary = {
	0: {"name": "평범", "col": Color("9c9482")},
	1: {"name": "귀함", "col": Color("2e86ab")},
	2: {"name": "진귀", "col": Color("7b3fb0")},
	3: {"name": "전설", "col": Color("f0c33c")},
}

## id / 이름 / 등급 / 가격 / 한 줄 설명 / 효과 키
## 효과는 player.apply_accessories() 가 읽는다. 새로 하나 추가하면 그 함수에도 한 줄이 는다.
const DEFS: Array = [
	# ── 평범 (초반에 살 수 있는 값) ──
	{"id": "acc_jipsin", "name": "짚신", "tier": 0, "gold": 900,
		"desc": "발이 가벼워진다. 이동 속도 +6%."},
	{"id": "acc_hopae", "name": "호패", "tier": 0, "gold": 1100,
		"desc": "이름값을 한다. 경험치 획득 +10%."},
	{"id": "acc_bokjumeoni", "name": "복주머니", "tier": 0, "gold": 1400,
		"desc": "주머니가 알아서 찬다. 골드 획득 +12% · 자석 +40."},
	{"id": "acc_yeomju", "name": "염주", "tier": 0, "gold": 1600,
		"desc": "한 알씩 굴린다. 매초 체력 +0.5 · 방어 +1."},
	# ── 귀함 ──
	{"id": "acc_okring", "name": "옥가락지", "tier": 1, "gold": 3600,
		"desc": "손끝이 날카로워진다. 치명타 확률 +8% · 치명타 배율 +0.25."},
	{"id": "acc_binyeo", "name": "비녀", "tier": 1, "gold": 4200,
		"desc": "찌르면 뚫린다. 관통 +1 · 탄속 +12%."},
	{"id": "acc_norigae", "name": "노리개", "tier": 1, "gold": 4800,
		"desc": "복이 따라붙는다. 행운 +10% · 레벨업 리롤 +1."},
	{"id": "acc_durumagi", "name": "두루마기", "tier": 1, "gold": 5200,
		"desc": "품이 넉넉하다. 최대 체력 +40 · 방어 +2."},
	# ── 진귀 ──
	{"id": "acc_eunjangdo", "name": "은장도", "tier": 2, "gold": 11000,
		"desc": "품고 다니는 한 수. 첫 피격을 흘려보내고, 이후 60초마다 다시 채워진다."},
	{"id": "acc_gat", "name": "갓", "tier": 2, "gold": 13000,
		"desc": "격이 다르다. 영웅 이상 카드가 뜰 확률 크게 상승 (행운 +25% 상당)."},
	{"id": "acc_jukbuin", "name": "죽부인", "tier": 2, "gold": 15000,
		"desc": "붙어 있으면 시원하다. 대시 쿨 -25% · 대시 중 무적 시간 연장."},
	# ── 전설 ──
	{"id": "acc_geoul", "name": "청동거울", "tier": 3, "gold": 34000,
		"desc": "맞은 것을 되비춘다. 가시 반사 +25 · 받는 피해 -8%."},
	{"id": "acc_bell", "name": "무당 방울", "tier": 3, "gold": 42000,
		"desc": "소리가 무기를 부른다. 특수무기 위력 ×1.20 · 소환수를 하나 데리고 시작."},
]


static func def_of(id: String) -> Dictionary:
	for d: Dictionary in DEFS:
		if String(d["id"]) == id:
			return d
	return {}


static func tier_color(t: int) -> Color:
	return (TIERS.get(clampi(t, 0, 3), TIERS[0]) as Dictionary)["col"]


static func tier_name(t: int) -> String:
	return I18n.t(String((TIERS.get(clampi(t, 0, 3), TIERS[0]) as Dictionary)["name"]))
