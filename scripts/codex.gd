class_name Codex
extends Object
## 도감 + 도전과제 정적 데이터. 해금 여부는 G(codex/achievements/stats)에 저장.

## 몬스터 도감 — key는 처치 시 G.codex_see("mon_<kind>")로 해금.
const MONSTERS: Array = [
	{"key": "mon_0", "name": "창랑", "sprite": "res://assets/sprites/monsters/changrang.png", "desc": "낮게 웅크렸다가 한달음에 덮친다. 정원에서는 쓰러지며 둘로 갈라진다"},
	{"key": "mon_1", "name": "티로", "sprite": "res://assets/sprites/monsters/tiro.png", "desc": "혀를 빼물고 꼬리를 흔들며 떼로 몰려온다. 볼케 형제가 불러내는 졸개도 이놈들이다"},
	{"key": "mon_8", "name": "너울", "sprite": "res://assets/sprites/monsters/neoul.png", "desc": "출렁이는 물 덩어리. 좌우로 흔들리며 다가오고, 정원에서는 꼬리 끝부터 둘로 갈라진다"},
	{"key": "mon_7", "name": "하쓰바", "sprite": "res://assets/sprites/monsters/hatsuba.png", "desc": "꼬리에 불을 단 도마뱀. 웅크렸다가 튀어 나가고, 용암동굴에서는 쓰러질 때 터지는 놈이 섞여 있다"},
	{"key": "mon_3", "name": "부러진 맹세 도르반", "sprite": "res://assets/sprites/monsters/dorvan.png", "desc": "맹세가 부러진 날부터 활을 들었다. 거리를 두고 돌며 한 발, 부채꼴 세 발, 느린 유도 화살을 번갈아 쏜다"},
	{"key": "mon_2", "name": "니오베", "sprite": "res://assets/sprites/monsters/niobe.png", "desc": "바위 뿔과 육각 방패를 앞세우고 느릿느릿 밀고 온다. 웬만해선 쓰러지지 않는다"},
	{"key": "mon_9", "name": "시나위", "tag": "특수", "sprite": "res://assets/sprites/monsters/sinawi_twin.png", "desc": "징을 머리 위에 띄운 탈 쓴 원혼. 벽을 그대로 지나오고, 시울이 부르면 떼로 나타난다"},
	{"key": "mon_10", "name": "할드", "tag": "특수", "sprite": "res://assets/sprites/monsters/hald.png", "desc": "머리 위 구슬이 차오를 때마다 주변 요괴의 상처를 씻어 낸다. 늘 한발 물러서 있다"},
	{"key": "mon_11", "name": "할덴", "tag": "특수", "sprite": "res://assets/sprites/monsters/halden.png", "desc": "금빛 금이 간 바위 거구. 아주 느리지만 쓰러질 때 몸이 터져 여덟 방향으로 파편을 뿌린다"},
	{"key": "mon_12", "name": "덩기", "tag": "특수", "sprite": "res://assets/sprites/monsters/deonggi.png", "desc": "마디마다 다리가 돋은 지네. 지그재그로 꺾으며 내달린다. 좀처럼 보기 어렵다"},
	{"key": "mon_4", "name": "한 획의 나기", "sprite": "res://assets/sprites/monsters/nagi_onestroke.png", "desc": "커다란 붓을 든 흰 범. 붓끝으로 찍은 자리마다 붉은 불길이 솟아 터지고, 웅크렸다가 단숨에 들이친다"},
	{"key": "mon_13", "name": "빈 낯의 시울", "sprite": "res://assets/sprites/monsters/siul_blankface.png", "desc": "책장 날개를 단 얼굴 없는 사서. 사라졌다가 바로 곁에 나타나고, 따라오는 원혼탄 세 발을 쏘며 시나위를 불러낸다"},
	{"key": "mon_14", "name": "볼케 형제", "sprite": "res://assets/sprites/monsters/bolke_brothers.png", "desc": "형의 어깨에 동생이 올라타 있다. 둘이 한 몸으로 급습해 닿는 대로 기운을 빨아들이고, 티로 떼를 불러낸다"},
	{"key": "mon_15", "name": "빈 통의 소류", "sprite": "res://assets/sprites/monsters/soryu.png", "desc": "항아리처럼 부푼 배를 금사슬로 동여맸다. 느리게 밀고 오며 독을 두 겹으로 뿜고, 쓰러지면 배 속에서 작은 창랑 넷이 기어 나온다"},
	{"key": "mon_6", "name": "아홉널 그로크", "sprite": "res://assets/sprites/monsters/nineplank_grok.png", "desc": "화면에 몹이 넘치면 모두 뭉쳐 눈알 덩어리로 깨어난다. 밀리지 않고 돌진하며, 닿은 자는 잠시 굳는다"},
	{"key": "mon_5", "name": "네페르", "sprite": "res://assets/sprites/monsters/nefer.png", "desc": "해를 단 지팡이를 든 천상의 주인. 장판이 누구보다 넓고 졸개를 쉴 새 없이 부른다"},
	# ── 이면(裏面) 요괴 ──
	{"key": "mon_16", "name": "하글", "tag": "이면", "sprite": "res://assets/sprites/monsters/hagl.png", "desc": "에메랄드 결정이 박힌 돌덩이. 멀리서 달려올수록 크고 무겁게 부딪치고, 가까이 오면 줄어든다"},
	{"key": "mon_17", "name": "카리아", "tag": "이면", "sprite": "res://assets/sprites/monsters/karia.png", "desc": "덩굴을 인 보랏빛 열매. 살아 있는 동안 쉬지 않고 부푼다. 오래 둘수록 커진다"},
	{"key": "mon_18", "name": "브란드", "tag": "이면", "sprite": "res://assets/sprites/monsters/brandr.png", "desc": "길고 날랜 주황 족제비. 눈 깜짝할 새에 파고든다"},
	{"key": "mon_19", "name": "케른", "tag": "이면", "sprite": "res://assets/sprites/monsters/kern.png", "desc": "톱니 입으로 쇠를 먹는다. 탄에 맞으면 절반만 다치고 그만큼 도로 채운다"},
	{"key": "mon_20", "name": "우츠로", "tag": "이면", "sprite": "res://assets/sprites/monsters/utsuro.png", "desc": "끊어진 염주를 건 야차. 다칠수록 붉게 달아올라 빨라진다"},
	{"key": "mon_21", "name": "발룸", "tag": "이면", "sprite": "res://assets/sprites/monsters/vallum.png", "desc": "꼬리가 두 갈래로 갈라진 요괴. 쓰러지면 꼬리를 따라 늘 둘로 쪼개진다"},
	{"key": "mon_22", "name": "세케트", "tag": "이면", "sprite": "res://assets/sprites/monsters/seket_scalepan.png", "desc": "외눈의 물귀신. 가까이 오면 너를 제 쪽으로 끌어당긴다"},
	{"key": "mon_23", "name": "삼환", "tag": "이면", "sprite": "res://assets/sprites/monsters/samhwan.png", "desc": "등에 탄창을 진 작은 석궁수. 재빨리 자리를 옮기며 한 발, 부채꼴, 유도 화살을 쏜다"},
	{"key": "mon_24", "name": "데벤", "tag": "이면", "sprite": "res://assets/sprites/monsters/deben_weigh.png", "desc": "금빛 무늬 등껍질을 진 바위 거북. 어떤 큰 한 방도 등껍질이 크게 깎아 낸다"},
	{"key": "mon_25", "name": "스카르비", "tag": "이면", "sprite": "res://assets/sprites/monsters/skarvi.png", "desc": "머리 셋이 한 몸에 뭉쳐 있다. 늘 셋씩 몰려와 빠르게 파고든다"},
	{"key": "mon_26", "name": "열지기 발레르", "sprite": "res://assets/sprites/monsters/valer.png", "desc": "빛 고리를 등에 진 금빛 창잡이. 창끝으로 장판을 긋고, 웅크렸다가 들이친다"},
	{"key": "mon_27", "name": "봉인의 오르빈", "sprite": "res://assets/sprites/monsters/orvin_seal.png", "desc": "봉인석 여섯을 거느린 고대 신수. 잠깐씩 숨을 고른 뒤 큰 낫으로 주변을 한 바퀴 베어 낸다"},
	{"key": "mon_28", "name": "불씨 이오네", "sprite": "res://assets/sprites/monsters/ione_kilnshell.png", "desc": "해 왕관을 쓴 불의 정령. 손에 든 불덩이를 탄막으로 흩뿌린다"},
	# ── 저승길(스테이지 6) — 행동은 기존 몹의 틀 그대로, 그림 · 이름만 저승길(Enemy.JEOSEUNG_ART) ──
	{"key": "mon_29", "name": "망혼", "sprite": "", "desc": "흰 수의를 입은 작은 혼. 떼로 몰려오고, 판관이 부르면 벽을 그대로 지나 나타난다"},
	{"key": "mon_30", "name": "저승 까마귀", "sprite": "", "desc": "발이 셋 달린 저승 까마귀. 눈 깜짝할 새에 파고든다"},
	{"key": "mon_31", "name": "도깨비불", "sprite": "", "desc": "푸른 불덩이 요괴. 웅크렸다가 튀어 나간다. 염라가 부르는 졸개도 망혼과 이것들이다"},
	{"key": "mon_32", "name": "업덩이", "sprite": "", "desc": "죄업이 뭉친 보랏빛 덩어리에 손이 여럿 달렸다. 낮게 웅크렸다가 한달음에 덮친다"},
	{"key": "mon_33", "name": "삼도천 뱀장어", "sprite": "", "desc": "등지느러미에 연꽃 등불을 단 뱀장어. 좌우로 출렁이며 다가온다"},
	{"key": "mon_34", "name": "옥졸 창병", "sprite": "", "desc": "붉은 갑옷의 옥졸. 큰 방패를 앞세우고 느릿느릿 밀고 온다. 웬만해선 쓰러지지 않는다"},
	{"key": "mon_35", "name": "귀졸 궁수", "sprite": "", "desc": "해골 탈을 쓴 귀졸. 거리를 두고 돌며 한 발, 부채꼴 세 발, 느린 유도 화살을 번갈아 쏜다"},
	{"key": "mon_36", "name": "우두", "sprite": "", "desc": "쇠스랑을 든 소머리 옥졸. 멀리서 달려올수록 크고 무겁게 부딪치고, 가까이 오면 줄어든다"},
	{"key": "mon_37", "name": "마면", "sprite": "", "desc": "쇠사슬 철퇴를 든 말머리 옥졸. 다칠수록 붉게 달아올라 빨라진다"},
	{"key": "mon_38", "name": "곡비", "tag": "특수", "sprite": "", "desc": "흰 상복을 입고 소매로 얼굴을 가린 곡비. 울음이 차오를 때마다 주변 요괴의 상처를 씻어 낸다. 늘 한발 물러서 있다"},
	{"key": "mon_39", "name": "상여꾼", "tag": "특수", "sprite": "", "desc": "꽃상여를 멘 거구. 아주 느리지만 쓰러질 때 여덟 방향으로 파편을 뿌린다"},
	{"key": "mon_40", "name": "손각시", "sprite": "", "desc": "붉은 혼례복을 입은 처녀 귀신. 가까이 오면 너를 제 쪽으로 끌어당긴다"},
	{"key": "mon_41", "name": "아귀", "sprite": "", "desc": "배만 부푼 마른 아귀. 살아 있는 동안 쉬지 않고 부푼다. 오래 둘수록 커진다"},
	{"key": "mon_42", "name": "명부 두루마리", "sprite": "", "desc": "살아 움직이는 명부. 탄에 맞으면 절반만 다치고 그만큼 도로 채운다"},
	{"key": "mon_43", "name": "쌍둥이 차사", "sprite": "", "desc": "갓 쓴 쌍둥이 저승차사가 한 몸에 붙어 있다. 쓰러지면 늘 둘로 쪼개진다"},
	{"key": "mon_44", "name": "저승 판관", "sprite": "", "desc": "붉은 관복에 붓과 명부를 든 판관. 사라졌다가 바로 곁에 나타나고, 따라오는 탄 세 발을 쏘며 망혼을 불러낸다"},
	{"key": "mon_45", "name": "염라", "sprite": "", "desc": "면류관을 쓰고 홀을 든 저승의 왕. 장판이 누구보다 넓고 졸개를 쉴 새 없이 부른다. 체력이 절반 아래로 떨어지면 업경을 띄우고 붉게 달아오른다"},
]

## 그 종류의 이름. 보스 머리 위 이름표가 이걸 읽는다 — 이름을 두 군데 적으면 반드시 갈린다.
static func monster_name(kind: int) -> String:
	var key: String = "mon_%d" % kind
	for m: Dictionary in MONSTERS:
		if String(m["key"]) == key:
			return I18n.t(String(m["name"]))
	return ""


## 맵 도감 — 방문 시 G.codex_see("map_<i>")로 해금.
const MAPS: Array = [
	{"key": "map_0", "name": "던전", "desc": "도르반 궁수와 니오베 방패병이 지키는 지하. 적 체력 ×1.18 · 경험치 ×1.15."},
	{"key": "map_1", "name": "도서관", "desc": "유령 사서의 서고. 적 이동 ×1.16 · 경험치 ×1.25."},
	{"key": "map_2", "name": "생명의 정원", "desc": "쓰러지면 둘로 갈라지는 창랑과 너울의 정원. 양쪽 모두 서서히 회복."},
	{"key": "map_3", "name": "용암동굴", "desc": "쓰러지며 터지는 하쓰바와 주기적인 용암 분출을 피하라."},
	{"key": "map_4", "name": "천상계", "desc": "빠른 무리가 몰려든다. 적 이동 ×1.12 · 경험치 ×1.3."},
	{"key": "map_5", "name": "저승길", "desc": "염라가 다스리는 길. 망혼 떼와 옥졸이 막아서고, 판관이 길목을 지킨다. 적 체력 ×1.12 · 이동 ×1.08 · 경험치 ×1.3."},
]

## 융합 도감 — 융합 완성 시 G.codex_see("fus_<evo_id>")로 해금.
## M37: open=true 레시피만 처음부터 공개(재료 표기), 나머지는 직접 완성해야 상세가 등록됨.
## mats=조합 재료, desc=상세 효과(재료 소멸 → 초월 재부여 + 슬롯 1칸 해방).
const FUSIONS: Array = [
	{"key": "fus_evo_inferno", "name": "지옥불", "open": true, "mats": "화염 오라 + 탄막: 화염",
		"desc": "재료를 흡수해 화염 오라를 초월 강화(Lv11). 화상 부여 6단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 오라 반경이 눈에 띄게 넓어지고 발밑 룬이 금빛 6갈래로 바뀐다."},
	{"key": "fus_evo_blizzard", "name": "절대영도", "open": true, "mats": "빙결 파동 + 탄막: 얼음",
		"desc": "재료를 흡수해 빙결 파동을 초월 강화(Lv11). 얼음 부여 6단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 장판이 겹겹이 깔리고 발밑 룬이 금빛 6갈래로 바뀐다."},
	{"key": "fus_evo_plague", "name": "역병", "open": true, "mats": "맹독 장판 + 탄막: 맹독",
		"desc": "재료를 흡수해 맹독 장판을 초월 강화(Lv11). 맹독 부여 6단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 독 장판이 더 넓게 번지고 발밑 룬이 금빛 6갈래로 바뀐다."},
	{"key": "fus_evo_railcannon", "name": "레일건", "open": true, "mats": "대구경 캐논 + 거대 탄환",
		"desc": "두 재료를 만렙까지 강화하면 등장. 포탄이 길게 뻗는 창으로 바뀌어 줄지어 선 적을 통째로 꿰뚫는다(Lv11 · 관통 +8 · 공격력 ×1.25 · 칸 1개 해방)."},
	{"key": "fus_evo_tempest", "name": "폭풍군주", "open": true, "mats": "번개 사슬 + 탄막: 감전",
		"desc": "재료를 흡수해 번개 사슬을 초월 강화(Lv11). 감전 부여 6단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 번개 갈래가 늘고 발밑 룬이 금빛 6갈래로 바뀐다."},
	{"key": "fus_evo_legion", "name": "군단", "open": true, "mats": "소환수 + 얼음 정령",
		"desc": "두 소환 무기가 하나의 군단으로 합쳐진다(Lv13). 얼음 부여 4단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 소환수가 한 무리로 합쳐지고 발밑 룬이 금빛 6갈래로 바뀐다."},
	{"key": "fus_evo_reaper", "name": "사신의 낫", "open": true, "mats": "채찍 + 처형",
		"desc": "재료를 흡수해 채찍을 초월 강화(Lv11). 처형 6단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 휘두르는 반경이 눈에 띄게 커진다."},
	{"key": "fus_evo_nova", "name": "초신성", "open": true, "mats": "회전 레이저 + 탄막: 화염",
		"desc": "재료를 흡수해 회전 레이저를 초월 강화(Lv11). 화상 부여 6단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 레이저 갈래가 늘어난다."},
	{"key": "fus_evo_deadeye", "name": "필중의 눈", "open": true, "mats": "속사 기관총 + 치명타",
		"desc": "두 재료를 만렙까지 강화하면 등장. 모든 탄이 새하얀 침이 되어 적을 쫓고, 전부 급소에 꽂힌다(Lv11 · 유도 6 · 치명 100% · 공격력 ×1.25)."},
	{"key": "fus_evo_ninetail", "name": "구미호의 꼬리", "open": true, "mats": "태극 부채 + 탄막: 연쇄",
		"desc": "재료를 흡수해 부채를 초월 강화(Lv11). 연쇄 부여 6단계 · 공격력 ×1.25 · 슬롯 1칸 해방. 부챗살이 아홉 갈래로 퍼지고 탄에 금빛 테두리가 생긴다."},
	{"key": "fus_evo_ledger", "name": "명부", "open": true, "mats": "각궁 + 처형",
		"desc": "이름이 적히면 끝난다. 각궁 초월(Lv11) · 처형 6단계 · 관통 +5 · 공격력 ×1.25. 화살에 금빛 테두리가 생긴다."},
	{"key": "fus_evo_orb", "name": "여의주", "open": true, "mats": "작두 + 흡혈",
		"desc": "여의주를 문 채 벤다. 작두 초월(Lv11) · 흡혈 6단계 · 최대 체력 +60 · 공격력 ×1.25. 베는 궤적이 금빛으로 바뀐다."},
]

## 반복 퀘스트 (S5) — 일일/주간/월간 리셋, 달성 후 '받기'로 골드 수령 (운빨디펜스 업적 스타일).
## stat: kills(처치) / spec(특수 개체) / boss(보스) / runs(판수) / clear(스테이지 클리어)
const QUESTS: Array = [
	{"id": "d_kill", "period": "daily", "name": "오늘의 사냥", "desc": "몬스터 400마리 처치", "stat": "kills", "need": 400, "gold": 60},
	{"id": "d_spec", "period": "daily", "name": "희귀 수집가", "desc": "특수 개체 3마리 처치", "stat": "spec", "need": 3, "gold": 50},
	{"id": "d_run", "period": "daily", "name": "오늘의 출격", "desc": "게임 1판 플레이", "stat": "runs", "need": 1, "gold": 40},
	{"id": "w_kill", "period": "weekly", "name": "주간 학살자", "desc": "몬스터 3,000마리 처치", "stat": "kills", "need": 3000, "gold": 220},
	{"id": "w_boss", "period": "weekly", "name": "주간 보스 헌터", "desc": "보스 10마리 처치", "stat": "boss", "need": 10, "gold": 180},
	{"id": "m_clear", "period": "monthly", "name": "이달의 정복자", "desc": "스테이지 8회 클리어", "stat": "clear", "need": 8, "gold": 500},
]
const QUEST_PERIOD_NAMES: Dictionary = {"daily": "일일 (매일 리셋)", "weekly": "주간 (매주 리셋)", "monthly": "월간 (매달 리셋)"}


## 도전과제 — G.stats 누적치가 need 이상이면 해금(+골드 보상).
const ACHIEVEMENTS: Array = [
	{"id": "survive_5m", "name": "생존자", "desc": "한 판에서 5분 생존", "stat": "best_time", "need": 300, "gold": 40},
	{"id": "survive_15m", "name": "베테랑", "desc": "한 판에서 15분 생존", "stat": "best_time", "need": 900, "gold": 120},
	{"id": "survive_full", "name": "완주자", "desc": "30분 최종 보스까지 도달", "stat": "best_time", "need": 1800, "gold": 300},
	{"id": "level_20", "name": "성장", "desc": "레벨 20 도달", "stat": "best_level", "need": 20, "gold": 50},
	{"id": "level_50", "name": "초월", "desc": "레벨 50 도달", "stat": "best_level", "need": 50, "gold": 180},
	{"id": "kills_1k", "name": "학살자", "desc": "누적 1,000 처치", "stat": "total_kills", "need": 1000, "gold": 50},
	{"id": "kills_10k", "name": "군단 분쇄", "desc": "누적 10,000 처치", "stat": "total_kills", "need": 10000, "gold": 200},
	{"id": "boss_10", "name": "보스 사냥꾼", "desc": "누적 보스 10 처치", "stat": "total_bosses", "need": 10, "gold": 100},
	{"id": "fusion_1", "name": "연금술사", "desc": "융합 1회 완성", "stat": "total_fusions", "need": 1, "gold": 80},
	{"id": "fusion_5", "name": "융합 대가", "desc": "융합 누적 5회", "stat": "total_fusions", "need": 5, "gold": 200},
	{"id": "jackpot", "name": "잭팟!", "desc": "도박 초대박 발동", "stat": "jackpots", "need": 1, "gold": 150},
	{"id": "runs_10", "name": "불굴", "desc": "10판 플레이", "stat": "runs", "need": 10, "gold": 60},
	{"id": "codex_mon", "name": "몬스터 박사", "desc": "모든 몬스터 도감 수집", "stat": "mon_seen", "need": -1, "gold": 400},  # need -1 = MONSTERS.size() (몹을 늘려도 자동 반영)
	{"id": "codex_map", "name": "탐험가", "desc": "모든 맵 방문", "stat": "map_seen", "need": -2, "gold": 80},  # need -2 = MAPS.size()
	# ── S1 스테이지 도전과제 (stages_cleared = 스테이지×난이도 클리어 조합 수, 최대 24) ──
	{"id": "stage_first", "name": "첫 정복", "desc": "스테이지 첫 클리어", "stat": "stages_cleared", "need": 1, "gold": 60},
	{"id": "stage_5", "name": "정복자", "desc": "스테이지 클리어 5회 (난이도 조합)", "stat": "stages_cleared", "need": 5, "gold": 180},
	{"id": "stage_all", "name": "완전 정복", "desc": "모든 스테이지×난이도 클리어 (24)", "stat": "stages_cleared", "need": 24, "gold": 600},
	# ── 실력으로만 따는 것들 — 누적 카운터만 있던 목록의 반대편 ──
	{"id": "endless_clear", "name": "무한의 끝", "desc": "무한 모드 최종 보스 처치", "stat": "endless_clears", "need": 1, "gold": 500},
	{"id": "endless_hard", "name": "끝의 끝", "desc": "무한 모드를 '매우어려움'으로 완주", "stat": "endless_hard", "need": 1, "gold": 10000},  # 11/14: 900 → 난이도별 완주 사다리(1,500 · 3,000 · 6,000 · 10,000 · 20,000)에 맞춤
	{"id": "star_20", "name": "별을 모으다", "desc": "클리어 별 20개 획득", "stat": "best_stars", "need": 20, "gold": 250},
	{"id": "star_45", "name": "별하늘", "desc": "클리어 별 45개 획득", "stat": "best_stars", "need": 45, "gold": 700},
	{"id": "star_60", "name": "만천의 별", "desc": "모든 조합에서 별 3개 (72개)", "stat": "best_stars", "need": 72, "gold": 1500},  # id 는 스팀 도전과제 이름이라 그대로
	{"id": "nohit_boss", "name": "그림자도 못 밟는다", "desc": "보스전에서 한 대도 안 맞고 클리어", "stat": "nohit_clears", "need": 1, "gold": 300},
	{"id": "swift_boss", "name": "속전속결", "desc": "보스를 등장 60초 안에 처치", "stat": "swift_clears", "need": 1, "gold": 220},
	{"id": "combo_300", "name": "끊기지 않는다", "desc": "한 판에서 콤보 300 달성", "stat": "best_combo", "need": 300, "gold": 260},
	{"id": "fusion_3run", "name": "삼중 융합", "desc": "한 판에서 융합 3종 완성", "stat": "best_run_fusions", "need": 3, "gold": 400},
	{"id": "yokai_all", "name": "이면을 보다", "desc": "이면 요괴 도감 전부 수집", "stat": "yokai_seen", "need": -3, "gold": 450},  # need -3 = 이면 요괴 수 (몹을 늘려도 자동 반영)
	# ── 11/14 무한 진행 · 누적 보상 (이용자 「무한은 깨도 쌓이는 게 없다 · 보스를 잡아도 누적 보상이 없다」) ──
	# ★ id 는 스팀 도전과제 API 이름 그대로이고, 스팀 인벤토리 아이템이 「ach:<id>」 로 붙는다 — 바꾸지 말 것.
	#   매우어려움 완주는 예전 endless_hard 가 맡는다(같은 조건을 둘로 만들지 않는다).
	{"id": "ENDLESS_CLEAR_EASY", "name": "첫 새벽", "desc": "무한 모드를 쉬움으로 완주", "stat": "endless_d0", "need": 1, "gold": 1500},
	{"id": "ENDLESS_CLEAR_NORMAL", "name": "긴 밤을 건너다", "desc": "무한 모드를 보통으로 완주", "stat": "endless_d1", "need": 1, "gold": 3000},
	{"id": "ENDLESS_CLEAR_HARD", "name": "사신과 마주 서다", "desc": "무한 모드를 어려움으로 완주", "stat": "endless_d2", "need": 1, "gold": 6000},
	{"id": "ENDLESS_CLEAR_HELL", "name": "지옥 끝까지", "desc": "무한 모드를 지옥으로 완주", "stat": "endless_d4", "need": 1, "gold": 20000},
	{"id": "ENDLESS_STARS_5", "name": "무한의 별", "desc": "무한 별 5개 획득", "stat": "endless_stars", "need": 5, "gold": 3000},
	{"id": "ENDLESS_STARS_10", "name": "저승 별자리", "desc": "무한 별 10개 획득", "stat": "endless_stars", "need": 10, "gold": 8000},
	{"id": "ENDLESS_STARS_15", "name": "꺼지지 않는 별", "desc": "무한 별 15개 모두 획득", "stat": "endless_stars", "need": 15, "gold": 20000},
	{"id": "BOSS_50", "name": "퇴마의 길", "desc": "누적 보스 50 처치", "stat": "total_bosses", "need": 50, "gold": 2000},
	{"id": "BOSS_200", "name": "퇴마사", "desc": "누적 보스 200 처치", "stat": "total_bosses", "need": 200, "gold": 6000},
	{"id": "BOSS_500", "name": "백귀를 멈추다", "desc": "누적 보스 500 처치", "stat": "total_bosses", "need": 500, "gold": 15000},
	{"id": "ENDLESS_CLEARS_5", "name": "다섯 번의 새벽", "desc": "무한 모드 누적 5회 완주", "stat": "endless_clears", "need": 5, "gold": 5000},
	{"id": "ENDLESS_CLEARS_20", "name": "새벽을 세는 사람", "desc": "무한 모드 누적 20회 완주", "stat": "endless_clears", "need": 20, "gold": 15000},
]
