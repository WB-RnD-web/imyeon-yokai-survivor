class_name Player
extends CharacterBody2D
## 이동(즉각+가감속) · 대시(잔상/무적) · 자동 조준 발사 · 피격 손맛.

const SPEED: float = 330.0
const ACCEL: float = 3000.0
const FRICTION: float = 2600.0
const DASH_SPEED: float = 980.0
const DASH_TIME: float = 0.16
const DASH_CD: float = 10.0  # 기본 10초 (대시쿨 강화로 최대 3초까지)
const DASH_CD_MIN: float = 3.0
const RADIUS: float = 15.0
## 일반 소스(카드 · 장신구 · 도박 · 영웅 카드 · 영구강화) 치명타 상한. 100% 는 융합(필중의 눈) · 시그니처 전유물(M37).
const CRIT_CAP: float = 0.70
## 카드 · 도박으로 줄일 수 있는 발사 간격 배수 바닥.
const RATE_FLOOR: float = 0.25
## 대시 쿨 카드로 줄일 수 있는 배수 바닥.
const DASH_CD_MULT_FLOOR: float = 0.35

const MAX_HP: float = 100.0
const FIRE_RATE: float = 0.26
const BULLET_DMG: float = 14.0
const BULLET_SPEED: float = 720.0
const TARGET_RANGE: float = 400.0
## 무당(갈덴)의 원혼 — 처치할 때마다 SPIRIT_DUR 이 새로 채워지고, 붙어 있는 동안 공격력에
## SPIRIT_MULT 가 곱해진다. 배수와 지속시간이 코드·영웅설명·일시정지 화면 세 곳에 흩어져
## 있으면 반드시 갈라진다(2026-09-06: 화면 어디에도 이 숫자가 없어서 "20 이 23 이 됐다,
## 버그냐"가 나왔다). 그래서 여기 한 줄만 두고 나머지는 전부 이걸 읽는다.
const SPIRIT_MULT: float = 1.18
const SPIRIT_DUR: float = 4.0
## 같은 이유로 나머지 '피해를 바꾸는 능력'의 크기도 여기 모은다. --abilcheck 가
## 화면 설명에 이 숫자가 실제로 실렸는지 매번 확인한다.
const RAGE_MULT: float = 1.5          # 광폭: 체력 40% 아래
const DASH_STRIKE_MULT: float = 2.2   # 돌격기사: 들이받기 한 방
const SHADOW_CRIT: float = 0.5        # 그림자: 대시 후 치명타 확률 가산
const SHADOW_DUR: float = 2.0         # 대시가 끝난 뒤 남는 시간

# 업그레이드로 변하는 런타임 스탯 (const는 기본값)
## 무기 아키타입 — 다중 장착. 전역 스탯(damage/rate_mult/proj_bonus/pierce/bullet_speed)이 모든 무기에 적용.
const WEAPON_DEFS: Dictionary = {
	"balanced": {"key": "balanced", "name": "밸런스 소총", "type": "ranged", "cd": 0.28, "dmg": 1.0, "proj": 1, "spread": 9.0, "pierce": 0, "bspeed": 1.0, "big": 0, "range": 405.0, "col": Color("fff0b0")},
	"heavy": {"key": "heavy", "name": "대구경 캐논", "type": "ranged", "cd": 0.95, "dmg": 3.6, "proj": 1, "spread": 0.0, "pierce": 2, "bspeed": 0.85, "big": 2, "range": 525.0, "col": Color("ff9f43")},
	"rapid": {"key": "rapid", "name": "속사 기관총", "type": "ranged", "cd": 0.10, "dmg": 0.50, "proj": 1, "spread": 13.0, "pierce": 0, "bspeed": 1.25, "big": 0, "range": 350.0, "col": Color("ffe23f")},
	"mid": {"key": "mid", "name": "중거리 산탄", "type": "ranged", "cd": 0.50, "dmg": 0.88, "proj": 4, "spread": 34.0, "pierce": 0, "bspeed": 0.9, "big": 0, "range": 270.0, "col": Color("ff7a3c")},
	"melee": {"key": "melee", "name": "대검 근접", "type": "melee", "cd": 0.5, "dmg": 2.95, "proj": 1, "spread": 0.0, "pierce": 0, "bspeed": 1.0, "big": 0, "range": 90.0, "arc": 135.0, "col": Color("e8e8ff")},
	# ── 이면(裏面) 무기 4종 — 전부 기존 발사/휘두르기 경로를 그대로 탄다 ──
	"bow": {"key": "bow", "name": "각궁", "type": "ranged", "cd": 0.72, "dmg": 2.4, "proj": 1, "spread": 2.0, "pierce": 3, "bspeed": 1.45, "big": 0, "range": 640.0, "col": Color("f0c33c")},
	"fan": {"key": "fan", "name": "태극 부채", "type": "ranged", "cd": 0.62, "dmg": 0.62, "proj": 6, "spread": 52.0, "pierce": 1, "bspeed": 0.8, "big": 1, "range": 240.0, "col": Color("2e86ab")},
	"sinkal": {"key": "sinkal", "name": "신칼", "type": "ranged", "cd": 0.16, "dmg": 0.55, "proj": 2, "spread": 7.0, "pierce": 0, "bspeed": 1.35, "big": 0, "range": 300.0, "col": Color("f2efe6")},
	"jakdu": {"key": "jakdu", "name": "작두", "type": "melee", "cd": 0.82, "dmg": 4.2, "proj": 1, "spread": 0.0, "pierce": 0, "bspeed": 1.0, "big": 0, "range": 118.0, "arc": 190.0, "col": Color("c1272d")},
}

var max_hp: float = MAX_HP
var move_speed: float = SPEED

# ★ 전역 공격력이 폭주하던 구조를 여기서 끊는다.
#   예전엔 카드가 전부 damage 에 곱해졌다 — 커먼 '공격력 +13%' 9장, 무기 카드 +5% 24장,
#   탄막 +4% 15장, 고유 +7% 6장… 전부 곱연산이라 한 판 끝에 ×650 이 됐다(실측).
#   같은 기간 몹 체력은 ×42 밖에 안 오르니 게임이 3분이면 끝난다.
#   지금은 '자잘한 카드는 합연산(card_add), 전설·신화·융합·시그니처만 곱연산(card_mult)'이다.
#   같은 카드 수로 ×650 → ×60 수준. 상위 등급 한 장의 무게는 오히려 커진다.
var base_damage: float = BULLET_DMG  # 판 시작 확정치 (기본 × 메타 × 장신구 × 캐릭터/등급)
var card_add: float = 0.0            # 카드 합연산 누적
var card_mult: float = 1.0           # 곱연산 — 전설/신화/융합/시그니처 전용
var damage: float:
	get:
		return base_damage * (1.0 + card_add) * card_mult
	set(v):
		base_damage = v  # 판 시작 계산부(reset/meta/장신구/캐릭터)가 그대로 쓰던 대입 경로
var rate_mult: float = 1.0  # 연사 배수(낮을수록 빠름) — 모든 무기 쿨에 곱
var bullet_speed: float = BULLET_SPEED
var proj_bonus: int = 0  # 멀티샷 추가 탄환(원거리 무기마다)
var pierce: int = 0
var weapons_primary: Array = []  # [{id, t, level}] 다중 장착
## 손에 드는 그림의 기준 — **가장 최근에 얻은 주무기**. 규칙은 이 한 줄이 전부다.
## 예전엔 레벨이 제일 높은 것을 골랐는데, 시작 무기가 balanced(소총) 이라 소총 카드를
## 한 장만 먹어도 Lv2 가 되어 그 뒤로 뭘 들어도 손에는 계속 총이 있었다(2026-09-04 지적).
## 발사는 그대로 전부 나간다 — 몇 정을 들고 있는지는 발밑 시길 룬이 알린다.
## 측정 하니스 전용 — 켜면 시작 소총을 자동 복원하지 않는다.
var no_default_weapon: bool = false
## 초월(m_transcend)을 먹은 뒤 **새로 드는** 무기가 몇 단계 위에서 시작하는가.
## 예전엔 초월이 그 시점 보유분만 올려서, 그 뒤에 든 무기는 혼자 3단계 뒤처졌다.
var transcend_bonus: int = 0
var _last_primary: String = ""

## 깃소금(fourcards)의 도박 결과. 10레벨마다 굴려서 전역 스탯을 흔드는데,
## 어디에도 기록이 안 남아 **뭐가 얼마나 변했는지 아무도 몰랐다**(2026-09-05 지적).
## 알림 배너도 레벨업 모달이 화면을 멈춰 세우는 바람에 투명한 채로 얼어 있었다.
var gamble_rolls: int = 0        # 몇 번 굴렸나
var gamble_add: float = 0.0      # 도박이 더한 전역 공격력(합연산분)
var gamble_proj: int = 0         # 도박이 더한 탄환 수
var gamble_crit: float = 0.0     # 도박이 더한 치명타 확률
var gamble_rate: float = 1.0     # 도박이 곱한 공격주기(작을수록 빠름)
var gamble_last: String = ""     # 마지막 결과 문구
var gamble_log: Array = []       # 굴린 순서대로 결과 문구 (최근 것이 뒤)
## 융합으로 초월한 무기 — 아키타입키/특수무기id → 융합 id.
## ★ 융합은 지금까지 "레벨 11 + 속성 6" 이라는 숫자로만 존재했다. 화면에서는 달라진 게
##   하나도 없어서 "융합으로 레일건을 먹었는데 뭘 쏘는지도 모르겠다"가 나왔다(실플레이 리포트).
##   여기에 표식을 남겨 두면 탄환·근접 궤적·발밑 시길이 전부 '초월한 무기'로 보이게 바뀐다.
var fused_marks: Dictionary = {}
var crit_chance: float = 0.0
const CRIT_MULT_BASE: float = 1.70  # 기본 배율 상향 — 치명타 계열 커먼이 다른 커먼에 비해 너무 약했다
var crit_mult: float = CRIT_MULT_BASE
var regen: float = 0.0
var armor: float = 0.0
var magnet_bonus: float = 0.0
var luck: float = 0.0
var xp_mult: float = 1.0
var ability: String = ""
var four_cards: bool = false
var weapons: Dictionary = {}  # 특수무기 id -> 노드
# 탄막 부여 효과 레벨 (명중 시 발동)
var b_ice: int = 0
var b_fire: int = 0
var b_poison: int = 0
var b_shock: int = 0
var b_big: int = 0
var b_bounce: int = 0
var b_chain: int = 0  # 연쇄: 명중 시 주변 적에게 번개 전이
var b_homing: int = 0  # 유도: 탄이 가까운 적을 향해 휘어짐
var b_exec: int = 0   # 처형: 체력 낮은 잔몹 즉살 (enemy.take_damage에서 판정)
var b_vamp: int = 0   # 흡혈: 명중 시 체력 회복(쿨 게이트)
var b_bloom: int = 0  # 폭발 개화: 적 사망 시 광역 폭발 (enemy._die에서 판정)
var _vamp_cd: float = 0.0
var thorns: float = 0.0  # 피격 시 주변 반사 데미지
var dash_cd_mult: float = 1.0  # 대시 쿨다운 배수(낮을수록 빠름)
var last_stand: bool = false  # 불사(신화 카드 등): 죽을 위기에 순간 무적(쿨 60s)
var echo_chance: float = 0.0  # 메아리(전설): 발사가 확률로 2연발
var enemy_slow: float = 0.0   # 시간 왜곡(전설): 모든 적 이동속도 감소 비율
var special_mult: float = 1.0 # 특수무기 위력 배수 (화염술사 등)
var _ls_cd: float = 0.0
var _shadow_t: float = 0.0    # 그림자 도적: 대시 후 치명타 부스트 잔여시간
var _spirit_t: float = 0.0    # 무당: 처치 직후 원혼이 붙어 있는 시간
var _bead_cd: float = 0.0     # 승려: 염주가 다시 채워지기까지
var _dance_t: float = 0.0     # 화랑: 연속 이동 시간 (검무)
var dance_max: float = 6.0    # 검무 상한 시간 (고유 카드가 늘린다)
var dance_rate: float = 0.075 # 검무 초당 상승률
var bead_cd_max: float = 6.0  # 염주 재충전 시간 (고유 카드가 줄인다)
var _dodge_cd: float = 0.0    # 은장도: 다시 채워지기까지
var _dash_hit: Array = []     # 돌격기사: 이번 대시에서 이미 들이받은 적

var hp: float = MAX_HP
var aim: Vector2 = Vector2.RIGHT
var _dash_t: float = 0.0
var _dash_cd: float = 0.0
var _iframe: float = 0.0
var _stun: float = 0.0
var _cv: CreatureVisual
var _barrel: Polygon2D
var _held: Sprite2D          # 실제 무기 그림 (없는 무기는 _barrel 폴리곤으로 폴백)
var _barrel_id: String = ""  # 현재 든 무기가 반영 중인 아키타입 (변할 때만 리빌드)


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 8  # 지형 장애물(레이어 4)에 막힘
	# ★ 영웅을 적 위에 그린다. 예전엔 전부 z_index 0 이라 **형제 순서**가 그리기 순서였고,
	#   플레이어가 Main 의 이른 자식이라 나중에 스폰된 모든 적이 영웅을 덮었다.
	#   수백 마리가 같은 자리로 몰리면 영웅이 그 밑에 완전히 묻힌다(2026-09-04 지적).
	#   적의 경고 링(z=40)·라벨(z=60)은 여전히 위라 가려지지 않는다.
	z_index = 6
	_make_foot_ring()
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = RADIUS
	col.shape = cs
	add_child(col)
	# 무기 프롭 (몸 뒤 = 들고 있는 느낌). 대표 주무기 아키타입에 맞춰 모양·색이 변신
	_barrel = Polygon2D.new()
	add_child(_barrel)
	_refresh_barrel()  # 기본(balanced) 실루엣 세팅
	_cv = CreatureVisual.new()
	_cv.body_color = Color("52e0cf")
	_cv.radius = RADIUS
	_cv.sides = 20
	_cv.always_animate = true  # 플레이어는 항상 화면 안 — 거리 컬링 제외
	_cv.build()
	add_child(_cv)
	_foot_bar = _FootBar.new()
	_foot_bar.position = Vector2(0.0, RADIUS * 0.86 + 5.0)
	_foot_bar.z_index = 1
	add_child(_foot_bar)


## 13차 4절: 주인공 발밑 체력 막대. ★ 눈은 주인공에 있는데 체력은 화면 구석에 있었다(에셋 담당 검토 ·
##   Vampire Survivors 처럼). 숫자는 HUD 왼쪽 위에 작게 남는다.
var _foot_bar: _FootBar

## 17-1: 「영웅 체력이 얼마나 깎였는지 잘 안 보인다」(사용자 10/11). 14차부터 왼쪽 위 숫자를 숨기고 이 막대만 남겼는데
##   ×1 이라 채움이 18×2 px 였다. ×2 로 키우고(격자 그대로), 방금 깎인 몫은 밝은 색으로 0.4초 남겼다가 줄어들게 하고,
##   맞는 순간 막대가 번쩍, 30% 아래에선 깜빡인다.
class _FootBar extends Node2D:
	const K: int = 2
	const LAG_HOLD: float = 0.4     # 깎인 몫을 이만큼 그대로 보여 준 뒤
	const LAG_SPEED: float = 0.9    # 초당 이 비율로 따라 내려간다
	var ratio: float = 1.0
	var lag: float = 1.0
	var _hold: float = 0.0
	var _blink: float = 0.0
	func set_ratio(r: float) -> void:
		if absf(r - ratio) < 0.004:
			return
		if r < ratio:
			_hold = LAG_HOLD
			_blink = 0.16
			lag = maxf(lag, ratio)
		else:
			lag = maxf(lag, r)   # 회복(재생은 매 프레임)은 채움이 밝은 몫 안으로 자라 들어간다 — 밝은 몫을 지우지 않는다
		ratio = r
		queue_redraw()
	func _process(delta: float) -> void:
		var busy: bool = _blink > 0.0 or lag > ratio or ratio < 0.3
		if not busy:
			return
		_blink = maxf(0.0, _blink - delta)
		if _hold > 0.0:
			_hold -= delta
		elif lag > ratio:
			lag = maxf(ratio, lag - LAG_SPEED * delta)
		if ratio < 0.3 and ratio > 0.0:
			modulate.a = 0.55 + 0.45 * absf(sin(float(Time.get_ticks_msec()) * 0.009))
		else:
			modulate.a = 1.0
		queue_redraw()
	func _draw() -> void:
		# 14차 U4: foot_hp(20×4) + 안쪽 1px 에 fill_hp 반복 — 17-1 부터 ×2(40×8, 채움 36×4)
		var fr: Texture2D = UiParts.tex("foot_hp", 0, K)
		var fl: Texture2D = UiParts.tex("fill_hp", 0, K)
		var inner_w: float = 18.0 * K
		var x0: float = -9.0 * K
		var r: float = clampf(ratio, 0.0, 1.0)
		var fw: float = floorf(inner_w * r / K) * K
		var lw: float = floorf(inner_w * clampf(lag, 0.0, 1.0) / K) * K
		if fr != null and fl != null:
			draw_texture(fr, Vector2(-10.0 * K, 0.0))
			if lw > fw:
				draw_rect(Rect2(x0 + fw, 1.0 * K, lw - fw, 2.0 * K), Color("fff2c4"))
			if fw >= 1.0:
				draw_texture_rect(fl, Rect2(x0, 1.0 * K, fw, 2.0 * K), true)
		else:
			draw_rect(Rect2(-10.0 * K, 0.0, 20.0 * K, 4.0 * K), Color(0.05, 0.04, 0.07, 0.9))
			if lw > fw:
				draw_rect(Rect2(x0 + fw, 1.0 * K, lw - fw, 2.0 * K), Color("fff2c4"))
			draw_rect(Rect2(x0, 1.0 * K, fw, 2.0 * K), Color("ff5c6a"))
		if _blink > 0.0:
			draw_rect(Rect2(-10.0 * K, 0.0, 20.0 * K, 4.0 * K), Color(1, 1, 1, 0.55 * _blink / 0.16))


func _physics_process(delta: float) -> void:
	if _foot_bar != null:
		_foot_bar.set_ratio(hp / maxf(1.0, max_hp))
		# 11/5 스팀 피드백 2: 창 모드에서 발밑 체력이 너무 작았다 — 세상이 작게 그려지는 만큼 키운다(G.world_ui_scale)
		_foot_bar.scale = Vector2.ONE * G._world_ui
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_iframe = maxf(0.0, _iframe - delta)
	_stun = maxf(0.0, _stun - delta)
	_ls_cd = maxf(0.0, _ls_cd - delta)
	_vamp_cd = maxf(0.0, _vamp_cd - delta)
	_shadow_t = maxf(0.0, _shadow_t - delta)
	_spirit_t = maxf(0.0, _spirit_t - delta)
	_bead_cd = maxf(0.0, _bead_cd - delta)
	_update_buff_ring()
	if _dodge_cd > 0.0:
		_dodge_cd = maxf(0.0, _dodge_cd - delta)
		if _dodge_cd <= 0.0 and G.acc_has("acc_eunjangdo"):
			acc_dodge_ready = true  # 은장도가 다시 채워졌다
	_heal_block = maxf(0.0, _heal_block - delta)
	var hcap: float = G.heal_cap_frac()
	if hcap > 0.0:
		_heal_bucket = maxf(0.0, _heal_bucket - max_hp * hcap * delta)   # 새는 양동이 — 1초치만큼 담긴다
	if regen > 0.0 and hp > 0.0 and hp < max_hp:
		hp = minf(max_hp, hp + _heal_scaled(regen * delta))
		G.player_hp_changed.emit()

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _stun > 0.0:
		input = Vector2.ZERO  # 기절: 이동/대시 불가 (사격은 유지)
	# 화랑의 검무 — 발이 멈추지 않는 한 칼끝이 계속 빨라진다. 멈추면 곧장 식는다.
	if ability == "sworddance":
		if input != Vector2.ZERO:
			_dance_t = minf(dance_max, _dance_t + delta)
		else:
			_dance_t = maxf(0.0, _dance_t - delta * 2.5)
	if _dash_t > 0.0:
		_dash_t -= delta  # 대시 중엔 관성 유지
		if ability == "dashstrike":
			_dash_strike()  # 돌격기사: 대시 경로의 적을 들이받음
	else:
		var target := input * move_speed
		if input != Vector2.ZERO:
			velocity = velocity.move_toward(target, ACCEL * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if _stun <= 0.0 and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
			_start_dash(input)
	move_and_slide()

	# 조준 (자동=최근접 / 수동=마우스 방향)
	var e := _nearest_enemy()
	aim = _compute_aim(e)
	_barrel.rotation = aim.angle()
	if _held != null and _held.visible:
		# 왼쪽을 겨누면 무기가 180도 돌아 위아래가 뒤집힌다 — 칼날이 아래로 가고 총이 거꾸로 잡힌다.
		# 세로로 한 번 더 뒤집어 주면 어느 방향을 봐도 똑바로 든 것으로 보인다.
		_held.flip_v = absf(aim.angle()) > PI * 0.5
	if _held_evo != null and _held_evo.visible:
		# 융합 아이콘은 총열과 같이 돌면 거꾸로 선다 — 세계 기준으로 늘 똑바로 세운다.
		_held_evo.rotation = -_barrel.rotation
	_refresh_barrel()  # 대표 주무기 바뀌면 총열/칼날 실루엣 갱신(안 바뀌면 즉시 리턴)
	# 장착 무기별 독립 발사
	_tick_weapons(delta, e)

	# 눈동자는 조준 방향을 봄, 몸은 세운 채 속도만큼 살짝 스쿼시 (이동감 저즙)
	_cv.look_dir = aim
	_cv.walk_speed = velocity.length()
	if _cv.is_cf():
		return    # 시트에는 걷기 동작이 있다 — 소수 배율 스쿼시는 도트를 끓게 한다
	var sp: float = clampf(velocity.length() / DASH_SPEED, 0.0, 1.0)
	var target := Vector2(1.0 + sp * 0.16, 1.0 - sp * 0.12) if velocity.length() > 8.0 else Vector2.ONE
	_cv.scale = _cv.scale.lerp(target, 0.25)


func _start_dash(dir: Vector2) -> void:
	var d := dir
	if d == Vector2.ZERO:
		d = aim
	_dash_t = DASH_TIME
	_dash_cd = maxf(DASH_CD_MIN, DASH_CD * dash_cd_mult)
	_iframe = maxf(_iframe, DASH_TIME + 0.04 + acc_dash_iframe)  # 죽부인이 이 창을 넓힌다
	_dash_hit = []
	if ability == "shadow":  # 그림자 도적: 대시 후 잠깐 치명타 급상승 (S2: 1.5→2.0초)
		_shadow_t = DASH_TIME + SHADOW_DUR
		_flash(Color("b06bff"))
	velocity = d.normalized() * DASH_SPEED
	G.add_shake(0.07)
	G.sfx("dash", randf_range(0.9, 1.1), -3.0)
	if _cv.play_once("skill"):
		_spawn_cf_vfx()
	_spawn_ghost()
	# 대시 잔상 몇 개 더
	for i in 3:
		get_tree().create_timer(0.03 * float(i + 1)).timeout.connect(_spawn_ghost)


func _spawn_ghost() -> void:
	if not is_inside_tree():
		return
	# 시트 모드 — 지금 칸을 그대로 떠서 잔상으로(원 대신 실루엣이 남는다)
	var snap: Sprite2D = _cv.snapshot()
	if snap != null:
		snap.modulate = Color(1, 1, 1, 0.45)
		snap.position += global_position
		get_parent().add_child(snap)
		G.mine(snap)   # 19차: 영웅 둘레에서 흐리게
		var stw := snap.create_tween()
		stw.tween_property(snap, "modulate:a", 0.0, 0.22)
		stw.tween_callback(snap.queue_free)
		return
	var g := Polygon2D.new()
	g.polygon = G.regular_polygon(20, RADIUS)
	g.color = Color(_cv.body_color.r, _cv.body_color.g, _cv.body_color.b, 0.4)
	g.global_position = global_position
	get_parent().add_child(g)
	G.mine(g)   # 19차: 영웅 둘레에서 흐리게
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)


## 돌격기사: 대시 중 겹친 적에게 강타 + 넉백 (적당 1회)
func _dash_strike() -> void:
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Enemy
		if e == null or not is_instance_valid(e) or _dash_hit.has(e):
			continue
		if global_position.distance_to(e.global_position) > RADIUS + e.rad + 8.0:
			continue
		_dash_hit.append(e)
		var dir: Vector2 = velocity.normalized() if velocity.length() > 1.0 else aim
		e.take_damage(damage * DASH_STRIKE_MULT, dir, false, "dash")  # S2: 특수 영웅 체급 상향 (1.7→2.2)
		e._knock += dir * 300.0
		G.add_shake(0.12)
		G.sfx_throttled("hit", 0.75, -4.0, 0.06)
		if G.fx_budget():  # 충돌 지점 은빛 충격 링
			var ring := Polygon2D.new()
			ring.polygon = G.regular_polygon(16, 12.0)
			ring.color = Color(0.85, 0.92, 1.0, 0.8)
			ring.global_position = e.global_position
			get_parent().add_child(ring)
			G.mine(ring)   # 19차: 영웅 둘레에서 흐리게
			var rtw := ring.create_tween()
			rtw.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.16)
			rtw.parallel().tween_property(ring, "modulate:a", 0.0, 0.16)
			rtw.tween_callback(ring.queue_free)


## 실효 치명타 확률 (그림자 도적 대시 부스트 반영)
func eff_crit() -> float:
	var c: float = crit_chance
	if _shadow_t > 0.0:
		c += SHADOW_CRIT
	return minf(1.0, c)


func _nearest_enemy() -> Node2D:
	# 보스는 거리를 0.55배로 쳐서 우선 조준 — 잡몹에 화력이 새서 보스가 안 죽는 것 방지 (S1)
	# [감사 C21] 탐지 반경을 장착 무기 최대 사거리에 맞춤 — 캐논(525)의 아웃레인지 개성이 실동작하게
	var best: Node2D = null
	var best_d: float = TARGET_RANGE
	for w in weapons_primary:
		var wd: Dictionary = WEAPON_DEFS.get(String(w["id"]), {})
		best_d = maxf(best_d, float(wd.get("range", 0.0)))
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Node2D
		if e == null or not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		# 실거리가 사거리 안일 때만 우대 — 밖의 보스를 조준해 사격이 잠기는 것 방지
		if d <= TARGET_RANGE and e is Enemy and (e as Enemy)._is_boss:
			d *= 0.55
		if d < best_d:
			best_d = d
			best = e
	return best


func _compute_aim(e: Node2D) -> Vector2:
	if G.aim_mode == 1:  # 수동: 마우스 방향
		var m: Vector2 = get_global_mouse_position() - global_position
		return m.normalized() if m.length() > 1.0 else aim
	# 자동: 최근접 적 → 없으면 진행 방향 유지
	if e != null:
		return (e.global_position - global_position).normalized()
	if velocity.length() > 12.0:
		return velocity.normalized()
	return aim


func _ensure_default_weapon() -> void:
	# ★ --weapondps 측정 중에는 되살리지 않는다. 하니스가 주무기를 비워도 이 줄이 매 프레임
	#   소총을 다시 넣어서, 잰 값이 "특수무기"가 아니라 "특수무기 + 소총"이었다.
	#   그 표로 무기 순위를 매기고 있었으니 순위 자체가 틀렸다(2026-09-05 검증에서 발견).
	if no_default_weapon:
		return
	if weapons_primary.is_empty():
		weapons_primary.append({"id": "balanced", "t": 0.0, "level": 1})


## 장착 무기 각각 독립 쿨다운으로 발사
func _tick_weapons(delta: float, e: Node2D) -> void:
	if not G.running:
		return  # 런 종료 후(승리 패널 등) 사격 정지 (S4)
	_ensure_default_weapon()
	var manual: bool = G.aim_mode == 1
	for w in weapons_primary:
		w["t"] = maxf(0.0, float(w["t"]) - delta)
		if w["t"] > 0.0:
			continue
		var def: Dictionary = WEAPON_DEFS[String(w["id"])]
		# 자동 조준일 땐 사거리 내 적 있을 때만, 수동일 땐 항상 발사
		var lvl: int = int(w["level"])
		var reach: float = float(def["range"]) * G.w_area_mult(String(w["id"]), lvl)
		if not manual:
			if e == null or global_position.distance_to((e as Node2D).global_position) > reach:
				continue
		if String(def["type"]) == "melee":
			_melee_swing(def, lvl, String(w["id"]))
		else:
			_fire_ranged(def, lvl, String(w["id"]))
		w["t"] = float(def["cd"]) * rate_mult * G.w_rate_mult(String(w["id"]), lvl)


## 무기 레벨 성장.
## ★ 예전엔 (1 + 0.18×(Lv-1)) 합연산이라 레벨이 오를수록 한 장의 가치가 계속 떨어졌다.
##   Lv5→6 이 그 무기 +10.5%, 무기 3정이면 총 +4.4% — 커먼 '공격력 +16%'(전역 곱연산)에
##   구조적으로 못 이긴다. 이게 "영웅 무기 카드를 안 고르고 싶다"의 근본 원인이었다.
##   레벨당 +22% 곱연산으로 바꾸면 몇 장을 찍든 한 장의 가치가 일정하다.
const LVL_GROWTH: float = 1.22  # (호환 상수 — 실제 성장은 G.GROWTH_TRACKS 가 정한다)

## ★ 예전엔 레벨업이 곧 '그 무기 공격력 +22%' 하나였다. 강해지긴 하는데 무엇이 강해지는지
##   화면에 남는 게 없었다(카드 설명도 늘 같았다). 이제 무기마다 성장 순서가 있고
##   레벨업 카드가 다음에 오를 항목을 미리 알려 준다 — G.w_next_label 참고.
func _weapon_dmg(def: Dictionary, lvl: int) -> float:
	var key: String = String(def.get("key", ""))
	var dmg: float = damage * float(def["dmg"]) * G.w_dmg_mult(key, lvl) * (1.0 - G.run_penalty)
	dmg *= _hero_dmg_mult()
	return dmg


## 한 발 피해를 **영웅 몫 + 무기 몫** 두 항으로. 화면이 적는 그 두 숫자다.
##   영웅 몫 = 내 공격력이 이 무기에 실리는 값 (무기마다 배분이 다르다 — 캐논은 한 발에 몰고
##             기관총은 잘게 나눈다. 그래서 초당 화력은 비슷하고 손맛만 다르다)
##   무기 몫 = 그 무기 레벨이 벌어온 값. 무기 카드로만 자란다. Lv1 이면 0.
## 합은 _weapon_dmg 와 같다 — 곱을 쪼갠 것일 뿐이라 밸런스가 안 변한다. --sumcheck 가 잰다.
##
## ★ Vector2 로 안 돌린다. Godot 의 Vector2 성분은 32비트라 두 값이 잘리고, 화면의
##   int(round()) 경계에서 숫자가 1씩 튄다. Array 로 float64 를 그대로 넘긴다.
func weapon_dmg_parts(def: Dictionary, lvl: int) -> Array:
	var key: String = String(def.get("key", ""))
	var hero: float = damage * float(def["dmg"]) * (1.0 - G.run_penalty)
	hero *= _hero_dmg_mult()
	return [hero, hero * (G.w_dmg_mult(key, lvl) - 1.0)]


## 캐릭터 고유 능력에서 오는 공격력 배수 — 검무 · 원혼 · 광폭.
## ★ 광폭(rage)만 예전엔 여기 밖에 있었다. _weapon_dmg · weapon_dmg_parts · special_power
##   세 곳에서 따로 곱하고 있어서, 발밑 배수 링이 광폭을 아예 못 봤다(--uptimecheck 가 잡았다).
##   곱하는 순서가 달라질 뿐 곱 자체는 같으므로 밸런스는 그대로다 — --sumcheck 가 확인한다.
##   ability 는 영웅당 하나라 세 갈래는 서로 배타적이다.
func _hero_dmg_mult() -> float:
	var m: float = 1.0
	match ability:
		"sworddance":
			m *= 1.0 + dance_rate * _dance_t  # 기본 6초 연속 이동 = ×1.45
		"spirits":
			if _spirit_t > 0.0:
				m *= SPIRIT_MULT              # 처치 직후 원혼이 붙어 있는 동안
		"rage":
			if hp < max_hp * 0.4:
				m *= RAGE_MULT                # 체력 40% 아래
	return m


## 특수무기(속성/오라/소환) 데미지 배수 — 전역 데미지 스탯에 (감쇠하여) 연동.
## 기본 damage=14 → 1.0, 데미지 카드/메타/캐릭으로 커질수록 특수무기도 함께 강해짐(절반 비율).
func special_power() -> float:
	# ★ 예전엔 (0.5 + 0.5×비율) 이라 전역 데미지를 4배로 키워도 특수무기는 2.7배까지만 따라왔다.
	#   게다가 특수무기는 연사·멀티샷·관통·치명타를 아예 못 받아서, 빌드를 키울수록 지분이
	#   자동으로 줄었다 — 영웅 등급인데 커먼보다 못한 이유의 절반이 여기였다.
	#   지금은 데미지를 0.9제곱으로 받고 연사 스탯도 일부 반영한다. 기본값(14, 1.0)에서는 1.0 그대로다.
	var ratio: float = damage / BULLET_DMG
	# 연사 항은 1.8 에서 자른다 — rate_mult 하한(0.2~0.25)에서 2.35배가 되어 다른 배수와 전부 곱해지면
	# 특수무기만 혼자 튄다. 하한도 rate_mult 실제 하한(0.2)과 맞췄다.
	var p: float = pow(maxf(0.01, ratio), 0.9) * minf(1.8, 0.55 + 0.45 / maxf(0.2, rate_mult))
	# ★ 특수무기는 치명타 판정 자체가 없어서, 치명 확률·배율 카드를 아무리 쌓아도 오라·소환수는
	#   그대로였다. 그래서 critdmg 커먼의 픽당 가치가 실측 0.99(무효)였다.
	#   개별 무기마다 크리 판정을 넣으면 연출이 산만해지므로, 기댓값으로 한 번에 반영한다.
	p *= 1.0 + eff_crit() * (crit_mult - 1.0)
	p *= special_mult * _hero_dmg_mult() * (1.0 - G.run_penalty)  # [감사 C22] 융합 도주 페널티 전 경로 일관 적용
	return p


# 아키타입별 발사 개성 (S4: "무기들이 합쳐져 보인다" — 총구 위치/발사음/반동을 무기마다 분리)
const _ARCH_MUZZLE: Dictionary = {"balanced": 0.0, "heavy": 10.0, "rapid": -10.0, "mid": 5.0}   # 총구 수직 오프셋
const _ARCH_PITCH: Dictionary = {"balanced": 1.0, "heavy": 0.55, "rapid": 1.4, "mid": 0.78}     # 발사음 피치
const _ARCH_KICK: Dictionary = {"balanced": 26.0, "heavy": 90.0, "rapid": 10.0, "mid": 48.0}    # 반동


func _fire_ranged(def: Dictionary, lvl: int, arch: String = "balanced") -> void:
	if get_tree().get_node_count_in_group("bullet") > G.bullet_cap():
		return  # 탄막 과다 → 이번 발사 스킵(기기별 상한, 성능 보호)
	var volleys: int = 2 if (echo_chance > 0.0 and randf() < echo_chance) else 1  # 메아리(전설): 2연발
	var n: int = int(def["proj"]) + proj_bonus + G.w_grade(arch, lvl, "proj")
	var maxed: bool = G.w_maxed(arch, lvl)
	# ── 융합이 **탄 자체를 바꾸는** 자리. 2026-09-06 까지 융합은 레벨과 탄막 수치만 올렸고
	#    무기가 하는 짓은 융합 전과 똑같았다. 이름이 약속한 것을 여기서 실제로 만든다. ──
	var fuse: String = String(fused_marks.get(arch, ""))
	if fuse == "evo_ninetail":
		n = maxi(n, 9)          # 구미호의 꼬리 — 부챗살이 아홉 갈래로 퍼진다
	# 만렙 '집탄'(속사 기관총) — 흩어지던 13° 가 3.3° 로 모인다. 물줄기가 탄띠가 된다.
	var spread: float = float(def["spread"]) * (0.25 if (maxed and arch == "rapid") else 1.0)
	var step: float = deg_to_rad(spread)
	var start: float = -step * float(n - 1) * 0.5
	# 만렙 '평행 전개'(태극 부채) — 부챗살이 벌어지지 않고 나란히 나간다. 삼각형이 벽이 된다.
	var parallel: bool = maxed and arch == "fan"
	if parallel:
		step = 0.0
		start = 0.0
	var mz: float = float(_ARCH_MUZZLE.get(arch, 0.0))
	for v in volleys:
		for i in n:
			var a: Vector2 = aim.rotated(start + step * float(i) + float(v) * 0.06)
			var dmg: float = _weapon_dmg(def, lvl)
			var crit: bool = randf() < eff_crit()
			if crit:
				dmg *= crit_mult
			var b := Bullet.new()
			b.setup(a * (bullet_speed * float(def["bspeed"])), dmg, int(def["pierce"]) + pierce + G.w_grade(arch, lvl, "pierce"), crit)
			b.max_dist = float(def["range"]) * G.w_area_mult(arch, lvl)  # 무기마다 사거리가 다르다 (S6)
			b.apply_from(self)
			# ★ apply_from 은 **대입**이라 반드시 그 뒤에 얹어야 한다(앞에 두면 지워진다).
			#   유도는 이제 무기 성장 트랙 항목이다 — 신칼처럼 유도 칸을 가진 무기만 휘어진다.
			b._fx_homing += G.w_grade(arch, lvl, "homing")
			b._fx_big += int(def["big"])
			# ── 만렙 특성 부여 (G.MAX_TRAIT). apply_from 이 대입이라 반드시 그 **뒤**다 ──
			if maxed:
				match arch:
					"bow":
						b.pierce_decay = 0.82   # 꿰뚫어도 무뎌지지 않는다
					"sinkal":
						b.relaunch = 1          # 사거리가 다하면 한 번 되돌아온다
					"heavy":
						b.burst_on_stop = 0.35  # 멈추는 자리에서 터진다
			# ── 융합 특성. 만렙 특성 위에 얹는다(둘 다 가질 수 있다) ──
			match fuse:
				"evo_railcannon":
					# 레일건 — "포탄이 긴 창이 되어 줄지어 꿰뚫는다". 관통해도 위력이 안 준다.
					b.pierce_decay = 1.0
					b._fx_big += 2
					b.burst_on_stop = maxf(b.burst_on_stop, 0.5)
				"evo_deadeye":
					# 필중의 눈 — "모든 탄이 흰 침이 되어 급소에 꽂힌다". 급소는 뚫고 지나간다.
					# ★ 처음엔 감쇠까지 없앴는데 초당 10발짜리 속사에 곱해져 ×17.5 로 튀었다
					#   (--fusepower 실측, 2위의 두 배). 이 융합의 핵심은 치명타 100% 지
					#   무한 관통이 아니다 — 관통은 얕게 주고 감쇠는 남긴다.
					b._pierce += 1
					b.pierce_decay = 0.85
				"evo_ledger":
					# 명부 — "화살이 줄지어 꿰뚫고 적힌 것은 끝난다". 한 줄을 통째로 꿴다.
					b._pierce += 4
					b.pierce_decay = 1.0
				"evo_ninetail":
					# 구미호의 꼬리 — 아홉 갈래마다 번개가 옮는다.
					b._fx_chain = maxi(b._fx_chain, 2)
			b._elem_tint = def["col"]
			b._arch = arch  # 무기별 탄환 실루엣 (캐논=포탄, 속사=트레이서, 산탄=펠릿)
			b.fusion_id = String(fused_marks.get(arch, ""))  # 융합 무기는 탄환부터 다르게 보인다
			# 만렙 '평행 전개'는 각도가 아니라 **출발 위치**를 벌린다 — 그래서 나란히 난다.
			# global_position 은 여기서 대입되므로 오프셋도 반드시 이 줄에서 얹어야 한다.
			var side: float = ((float(i) - float(n - 1) * 0.5) * 26.0) if parallel else 0.0
			b.global_position = global_position + a * (RADIUS + 10.0) + a.orthogonal() * (mz + side)
			get_parent().add_child(b)
	# 만렙 '총구 폭풍'(중거리 산탄) — 펠릿이 갈라지기 전의 한 덩어리가 코앞을 그대로 때린다.
	# 산탄은 붙으면 셀수록 강한 무기라, 그 '붙었을 때'를 확실히 보상한다.
	if maxed and arch == "mid":
		var blast: float = _weapon_dmg(def, lvl) * 1.2
		for nd in G.enemies_cached():
			if not is_instance_valid(nd):
				continue
			var e := nd as Enemy
			if e == null or not is_instance_valid(e):
				continue
			var to: Vector2 = e.global_position - global_position
			if to.length() > 70.0 + e.rad or absf(to.angle_to(aim)) > 0.9:
				continue
			G.tally("총구폭풍", blast)
			e.take_damage(blast, to.normalized(), false, "blast")
	velocity -= aim * float(_ARCH_KICK.get(arch, 26.0))  # 무기별 반동 (캐논=묵직, 속사=경쾌)
	var pb: float = float(_ARCH_PITCH.get(arch, 1.0))
	G.sfx_throttled("shoot", pb * randf_range(0.95, 1.05), -8.0 if arch != "heavy" else -4.0, 0.05)
	_muzzle_flash(arch)


## 근접: 조준 방향 부채꼴 안의 적을 타격 + 휘두르는 낫 이펙트
func _melee_swing(def: Dictionary, lvl: int, arch: String = "melee") -> void:
	var rng: float = float(def["range"]) * G.w_area_mult(arch, lvl)
	var half: float = deg_to_rad(float(def["arc"])) * 0.5
	var dmg0: float = _weapon_dmg(def, lvl)
	var col: Color = def["col"]
	var fuse_melee: String = String(fused_marks.get(arch, ""))
	if fuse_melee != "":
		col = col.lerp(Color(1.0, 0.84, 0.29), 0.55)  # 융합 근접무기는 금빛 궤적으로 벤다
	var hits: int = 0
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var en := n as Enemy
		if en == null or not is_instance_valid(en):
			continue
		var to: Vector2 = en.global_position - global_position
		if to.length() > rng + en.rad:
			continue
		if absf(to.angle_to(aim)) > half:
			continue
		var dmg: float = dmg0
		var crit: bool = randf() < eff_crit()
		if crit:
			dmg *= crit_mult
		en.take_damage(dmg, to.normalized(), crit, "wp_" + arch)
		_apply_melee_fx(en)
		_melee_spark(en.global_position, col, crit)
		# ★ 여의주(작두+흡혈) — "벤 만큼 회복한다"고 적어 놓고 실제로는 아무 일도 안 일어났다.
		#   흡혈(hit_lifesteal)은 bullet.gd 에서만 불리는데 작두는 **탄을 안 쏘는 근접**이다.
		#   군단의 b_ice 와 같은 종류의 구멍이다(2026-09-06). 벤 자리에서 직접 회복시킨다.
		if fuse_melee == "evo_orb":
			hit_lifesteal()
		hits += 1
	_slash_effect(rng, half, col, arch)
	if fuse_melee == "evo_orb" and hits > 0 and G.fx_budget():
		var hl := FxLib.burst(self, global_position + Vector2(randf_range(-10.0, 10.0), -26.0), "evo_orb", "heal", 0.0, 1.5, -1.0, 7)
		if hl != null:
			hl.create_tween().tween_property(hl, "position:y", hl.position.y - 14.0, 0.36)
	# 만렙 '검압 잔류'(대검) — 벤 부채꼴이 0.5초 남아 걸어 들어오는 것을 30% 위력으로 벤다.
	# 한 번의 큰 호가 정체성이니, 그 호가 잠시 남는 것이 자연스러운 연장이다.
	if G.w_maxed(arch, lvl) and arch == "melee":
		_lingering_arc(rng, half, dmg0 * 0.30, col)
	if hits > 0:  # 연결감: 화면 흔들림 + 짧은 히트스톱
		G.add_shake(0.12)
		G.hitstop(0.03)
	G.sfx_throttled("hit", randf_range(0.8, 0.95), -6.0, 0.05)


## 만렙 '검압 잔류' — 벤 자리에 반투명 호를 0.5초 남기고, 그 안에 들어온 적을 두 번 벤다.
## 조준 방향은 벨 때로 고정된다(따라 돌면 그냥 상시 공격이 된다).
func _lingering_arc(rng: float, half: float, dmg: float, col: Color) -> void:
	var arc := _LingerArc.new()
	arc.rng = rng
	arc.half = half
	arc.dmg = dmg
	arc.dir = aim
	arc.global_position = global_position
	arc.col = col
	get_parent().add_child(arc)
	G.mine(arc)   # 19차: 영웅 둘레에서 흐리게


class _LingerArc:
	extends Node2D
	var rng: float = 90.0
	var half: float = 1.2
	var dmg: float = 5.0
	var dir: Vector2 = Vector2.RIGHT
	var col: Color = Color.WHITE
	var _t: float = 0.5
	var _tick: float = 0.0
	var _hit: Dictionary = {}

	func _ready() -> void:
		add_to_group("hazard")   # 런이 끝나면 같이 치운다 (_clear_run_entities)
		z_index = -2
		var pts := PackedVector2Array([Vector2.ZERO])
		var a0: float = dir.angle() - half
		for i in 13:
			pts.append(Vector2(cos(a0 + half * 2.0 * float(i) / 12.0),
				sin(a0 + half * 2.0 * float(i) / 12.0)) * rng)
		var poly := Polygon2D.new()
		poly.polygon = pts
		poly.color = Color(col.r, col.g, col.b, 0.16)
		add_child(poly)
		var tw := create_tween()
		tw.tween_property(poly, "modulate:a", 0.0, 0.5)

	func _process(delta: float) -> void:
		if not G.running:
			queue_free()
			return
		_t -= delta
		if _t <= 0.0:
			queue_free()
			return
		_tick -= delta
		if _tick > 0.0:
			return
		_tick = 0.16
		for n in G.enemies_cached():
			if not is_instance_valid(n):
				continue
			var e := n as Enemy
			if e == null or not is_instance_valid(e):
				continue
			var to: Vector2 = e.global_position - global_position
			if to.length() > rng + e.rad or absf(to.angle_to(dir)) > half:
				continue
			var k: int = e.get_instance_id()
			if _hit.has(k):
				continue
			_hit[k] = true
			G.tally("검압", dmg)
			e.take_damage(dmg, to.normalized(), false, "wave")


func _apply_melee_fx(en: Enemy) -> void:
	if b_ice > 0:
		en.apply_slow(0.5 + 0.25 * float(b_ice))
	if b_fire > 0:
		en.apply_burn(maxf(2.0, damage * 0.12 * float(b_fire)), 2.2)
	if b_poison > 0:
		en.apply_poison(maxf(2.0, damage * 0.10 * float(b_poison)), 3.0)
	if b_shock > 0:
		en.take_damage(damage * 0.20 * float(b_shock), aim, false, "b_shock")  # [감사 C7] M39 너프(0.35→0.20)를 근접 경로에도 통일
		en.apply_shock(2.0)
	if b_vamp > 0:
		hit_lifesteal()


## 흡혈: 명중 시 소량 회복 (쿨 게이트로 멀티히트·연사 남용 방지)
func hit_lifesteal() -> void:
	if b_vamp <= 0 or _vamp_cd > 0.0 or hp <= 0.0 or hp >= max_hp:
		return
	_vamp_cd = 0.12
	heal(0.4 + 0.35 * float(b_vamp))


## 낫을 실제로 휘두르는 이펙트: 옅은 잔상 부채꼴 + 초승달 날이 한쪽 끝→반대 끝으로 스윕
## 근접 궤적 — 무기 성격대로 스윕의 모양과 속도를 나눈다.
##   대검(melee) : 넓고 느린 한 번의 큰 호 (묵직)
##   작두(jakdu) : 반원을 통째로 도는 회전 베기 + 잔상 두 겹
## ★ 예전엔 둘 다 같은 초승달을 같은 속도로 돌렸다. 부채꼴 각도만 달라서
##   "무기가 바뀐 게 안 보인다"가 됐다.
## 8차 휘두르기 시트: 그림 속 칼끝 반지름(px) · 보여 주는 시간(초). 주문 7차 회신 4절.
const SWING_R: Dictionary = {"melee": 100.0, "jakdu": 130.0, "evo_orb": 150.0}
const SWING_T: Dictionary = {"melee": 0.20, "jakdu": 0.24, "evo_orb": 0.26}


## 이 근접 무기가 쓸 휘두르기 시트(여의주로 융합했으면 여의주). 없으면 "".
func _swing_fx_key(arch: String) -> String:
	var fz: String = String(fused_marks.get(arch, ""))
	if fz != "" and FxLib.has(fz, "swing"):
		return fz
	return arch if FxLib.has(arch, "swing") else ""


func _slash_effect(rng: float, half: float, col: Color, arch: String = "melee") -> void:
	var sk: String = _swing_fx_key(arch)
	if sk != "":
		# 시트는 오른쪽을 가운데로 위 → 아래로 벤다. 왼쪽을 볼 땐 위아래를 뒤집어야 여전히 위에서 내려 벤다.
		var sw := FxLib.burst(get_parent(), global_position, sk, "swing", aim.angle(), rng / float(SWING_R.get(sk, 100.0)),
			float(SWING_T.get(sk, 0.2)), 30, aim.x < 0.0)
		if sw != null:
			sw.modulate.a = FxLib.SWING_ALPHA
		if arch == "jakdu":
			G.add_shake(0.10)
		return
	if arch == "jakdu":
		_slash_jakdu(rng, half, col)
		return
	_slash_generic(rng, half, col)


## 작두 — 몸을 돌려 반원을 베어낸다. 두꺼운 날 + 뒤따르는 잔상.
func _slash_jakdu(rng: float, half: float, col: Color) -> void:
	if not G.fx_weapon_budget():
		return
	for layer in 2:
		var blade := _make_crescent(rng * (1.0 - 0.12 * float(layer)), col)
		blade.modulate.a = 1.0 - 0.55 * float(layer)
		get_parent().add_child(blade)
		G.mine(blade)   # 19차: 영웅 둘레에서 흐리게
		blade.global_position = global_position
		var w: float = deg_to_rad(46.0)
		blade.rotation = aim.angle() - half + w * 0.5
		var tw := blade.create_tween()
		tw.tween_interval(0.035 * float(layer))          # 잔상은 살짝 늦게 따라온다
		tw.tween_property(blade, "rotation", aim.angle() + half - w * 0.5, 0.13) 			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(blade, "modulate:a", 0.0, 0.17)
		tw.tween_callback(blade.queue_free)
	G.add_shake(0.10)


func _slash_generic(rng: float, half: float, col: Color) -> void:
	# 잔상용 옅은 부채꼴 (스윕이 지나간 자리)
	var fpts := PackedVector2Array()
	fpts.append(Vector2.ZERO)
	var seg: int = 12
	for i in seg + 1:
		var a: float = aim.angle() - half + (2.0 * half) * float(i) / float(seg)
		fpts.append(Vector2(cos(a), sin(a)) * rng)
	var fan := Polygon2D.new()
	fan.polygon = fpts
	fan.color = Color(col.r, col.g, col.b, 0.12)
	get_parent().add_child(fan)
	G.mine(fan)   # 19차: 영웅 둘레에서 흐리게
	fan.global_position = global_position
	var twf := fan.create_tween()
	twf.tween_property(fan, "modulate:a", 0.0, 0.15)
	twf.tween_callback(fan.queue_free)
	# 휘두르는 초승달 날 (부채꼴 시작 끝 → 반대 끝으로 0.15s 스윕)
	var blade := _make_crescent(rng, col)
	get_parent().add_child(blade)
	G.mine(blade)   # 19차: 영웅 둘레에서 흐리게
	blade.global_position = global_position
	var wwidth: float = deg_to_rad(38.0)
	blade.rotation = aim.angle() - half + wwidth * 0.5
	var tw := blade.create_tween()
	tw.tween_property(blade, "rotation", aim.angle() + half - wwidth * 0.5, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(blade, "modulate:a", 0.0, 0.18)
	tw.tween_callback(blade.queue_free)


## 초승달 날 폴리곤 (바깥 밝은 날 + 안쪽 은은한 몸통)
func _make_crescent(rng: float, col: Color) -> Polygon2D:
	var ri: float = rng * 0.66
	var ro: float = rng * 1.02
	var w: float = deg_to_rad(38.0)
	var seg: int = 14
	var pts := PackedVector2Array()
	var vc := PackedColorArray()
	var edge := Color(1, 1, 1, 0.92)
	var body := Color(col.r, col.g, col.b, 0.42)
	for i in seg + 1:
		var a: float = -w * 0.5 + w * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * ro)
		vc.append(edge)
	for i in range(seg, -1, -1):
		var a2: float = -w * 0.5 + w * float(i) / float(seg)
		pts.append(Vector2(cos(a2), sin(a2)) * ri)
		vc.append(body)
	var p := Polygon2D.new()
	p.polygon = pts
	p.vertex_colors = vc
	return p


## 근접 타격 스파크
func _melee_spark(pos: Vector2, col: Color, crit: bool) -> void:
	if not crit and not G.fx_budget():
		return  # 크리티컬은 항상, 그 외 스파크는 프레임 예산 내에서만
	if FxLib.burst(get_parent(), pos, "common", "crit" if crit else "hit", 0.0, 1.0, -1.0, 21, randf() < 0.5) != null:
		return
	var s := Polygon2D.new()
	s.polygon = G.regular_polygon(4, 7.0 if crit else 5.0)
	s.color = Color(1, 1, 1, 0.9) if crit else Color(col.r, col.g, col.b, 0.9)
	s.global_position = pos
	get_parent().add_child(s)
	G.mine(s)   # 19차: 영웅 둘레에서 흐리게
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(0.1, 0.1), 0.1)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.1)
	tw.tween_callback(s.queue_free)


## 무기 장착/레벨업 (다중 장착)
func add_primary_weapon(id: String) -> void:
	_last_primary = id
	for w in weapons_primary:
		if String(w["id"]) == id:
			w["level"] = int(w["level"]) + 1
			return
	weapons_primary.append({"id": id, "t": 0.0, "level": 1 + transcend_bonus})
	_rebuild_sigil()


## 융합 전용: 주무기를 지정 레벨(카드 상한 초월 가능)로 장착.
func add_primary_at_level(arch: String, lv: int) -> void:
	_last_primary = arch
	for w in weapons_primary:
		if String(w["id"]) == arch:
			w["level"] = maxi(int(w["level"]), lv)
			return
	weapons_primary.append({"id": arch, "t": 0.0, "level": lv})


## 융합 전용: 특수무기를 지정 레벨로 (재료 소멸 후 초월 재부여).
func add_weapon_at_level(id: String, lv: int) -> void:
	add_weapon(id)
	var w: Node = weapons.get(id)
	if w != null:
		for i in maxi(0, lv - 1):
			w.call("level_up")


## 장착한 주무기(다중) 중 "대표" 아키타입 — 최고 레벨, 동레벨이면 최근 장착 우선.
func _dominant_primary() -> String:
	if _last_primary != "":
		for w in weapons_primary:
			if String(w["id"]) == _last_primary:
				return _last_primary
		_last_primary = ""     # 융합으로 재료가 사라진 경우
	# 아직 아무것도 안 골랐으면 시작 무기
	if not weapons_primary.is_empty():
		return String((weapons_primary[0] as Dictionary)["id"])
	return "balanced"


## 대표 아키타입이 바뀔 때만 손에 든 무기를 갈아 끼운다 (특수무기는 각자 노드라 무시).
## ★ 예전엔 단색 Polygon2D 하나였다. 30px 로 그려지니 "삼각형·네모·마름모를 들고 있다"로
##   보인다(실플레이 리포트). 이제 무기마다 실제 픽셀 그림을 든다(assets/sprites/weapons).
##   그림이 없으면 예전 폴리곤으로 조용히 되돌아간다 — 자산이 빠져도 게임은 돈다.
## ★ 2026-09-15: 융합해도 손에 든 그림이 그대로였다. 태극부채 + 연쇄로 '구미호의 꼬리'를
##   만들어도 여전히 부채를 들고 있어서, 지금 뭘 들었는지 화면으로는 알 수 없었다
##   (실플레이 리포트). 융합 그림을 새로 그리는 대신 있는 것으로 못 박는다:
##     · 무기 몸체를 그 융합의 색으로 물들이고
##     · 금빛 테두리를 둘러 '초월한 무기'라고 표시하고 (탄환의 금빛 표식과 같은 언어)
##     · 손잡이 쪽에 그 융합의 아이콘을 작게 붙인다 — 어느 융합인지까지 읽힌다.
var _held_evo: Sprite2D           # 손잡이 옆 융합 아이콘
var _barrel_evo: String = ""      # 지금 반영돼 있는 융합 id (바뀔 때만 다시 만든다)

func _refresh_barrel() -> void:
	if _barrel == null:
		return
	var id: String = _dominant_primary()
	var evo: String = String(fused_marks.get(id, ""))
	if id == _barrel_id and evo == _barrel_evo:
		return
	_barrel_id = id
	_barrel_evo = evo
	var tex: Texture2D = _held_tex(id)
	if tex != null:
		_barrel.polygon = PackedVector2Array()   # 폴리곤 폴백은 끈다
		if _held == null:
			_held = Sprite2D.new()
			_held.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_barrel.add_child(_held)
		_held.texture = tex
		var want: float = RADIUS * 2.6
		var hj: Dictionary = FxLib.json_of("ui/held/" + id, "held")
		if not hj.is_empty():
			# 12차 G — 40×16 · 그림 1px = 게임 1px(영웅 키 40 과 같은 배율). 기준점(손잡이)을 손 자리에.
			var an: Array = hj.get("anchor", [12, 8])
			_held.centered = false
			_held.offset = -Vector2(float(an[0]), float(an[1]))
			_held.scale = Vector2.ONE
			_held.position = Vector2(HELD_HAND_X, 0.0)
		else:
			# 예전 96px 그림 — 무기 길이가 캐릭터(반지름 15)의 2.6배쯤 되도록 맞추고, 손잡이가 몸에 오게 민다
			var sc: float = want / maxf(1.0, float(maxi(tex.get_width(), tex.get_height())))
			_held.centered = true
			_held.offset = Vector2.ZERO
			_held.scale = Vector2(sc, sc)
			_held.position = Vector2(want * 0.42, 0.0)
		_held.visible = true
		_apply_evo_mark(evo, want)
		return
	if _held != null:
		_held.visible = false
	_apply_evo_mark(evo, RADIUS * 2.6)
	_barrel.polygon = _barrel_poly(id)
	var metal := Color("caa24a")  # 건메탈 골드 베이스
	var col: Color = WEAPON_DEFS[id]["col"] if WEAPON_DEFS.has(id) else Color("fff0b0")
	_barrel.color = metal.lerp(col, 0.9 if id == "melee" else 0.45)  # 근접=강철빛, 총기=골드+색조


## 융합 표시를 손에 든 무기에 입힌다. 융합이 아니면 전부 원래대로 되돌린다.
func _apply_evo_mark(evo: String, want: float) -> void:
	if evo == "":
		if _held != null:
			_held.modulate = Color.WHITE
			_held.material = null
		if _held_evo != null:
			_held_evo.visible = false
		return
	var col: Color = Icons.color_of(evo)
	if _held != null:
		# 원래 그림을 살리면서 융합 색을 얹는다 — 통째로 칠하면 무기 모양이 뭉개진다.
		_held.modulate = Color.WHITE.lerp(col, 0.55)
		_held.material = CreatureVisual.gold_outline_mat()
	# 손잡이 옆 작은 융합 아이콘
	var path: String = "res://assets/sprites/icons/%s.png" % evo
	if not ResourceLoader.exists(path):
		if _held_evo != null:
			_held_evo.visible = false
		return
	if _held_evo == null:
		_held_evo = Sprite2D.new()
		_held_evo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_held_evo.z_index = 2          # 무기 위
		_barrel.add_child(_held_evo)
	var t: Texture2D = load(path)
	_held_evo.texture = t
	var isz: float = RADIUS * 0.95
	_held_evo.scale = Vector2.ONE * (isz / maxf(1.0, float(maxi(t.get_width(), t.get_height()))))
	_held_evo.position = Vector2(want * 0.10, -RADIUS * 0.72)
	_held_evo.visible = true


## 손에 드는 무기 그림. 종류가 아홉 개뿐이라 경로별로 한 번만 찾아 캐시한다.
## 12차 G(survivor_ui/held) 그림이 있으면 그것, 없으면 예전 held_*.png.
static var _held_cache: Dictionary = {}
const HELD_HAND_X: float = 9.0   # 손잡이 자리 — 예전 그림이 몸 뒤에서 시작하던 곳(-3px)과 맞춘다

static func _held_tex(id: String) -> Texture2D:
	if _held_cache.has(id):
		return _held_cache[id]
	var t: Texture2D = FxLib.tile("ui/held/" + id, "held", 0)
	if t != null:
		_held_cache[id] = t
		return t
	var path: String = "res://assets/sprites/weapons/held_%s.png" % id
	t = load(path) if ResourceLoader.exists(path) else null
	_held_cache[id] = t
	return t


## 아키타입별 무기 실루엣 (로컬 +X = 조준 방향; 몸 뒤에 깔려 총구/칼끝만 삐져나옴).
func _barrel_poly(id: String) -> PackedVector2Array:
	var r: float = RADIUS
	match id:
		"heavy":  # 대구경 캐논 — 굵고 긴 포신
			return PackedVector2Array([Vector2(0, -6.5), Vector2(r + 6.0, -7.0), Vector2(r + 20.0, -5.0), Vector2(r + 20.0, 5.0), Vector2(r + 6.0, 7.0), Vector2(0, 6.5)])
		"rapid":  # 속사 기관총 — 가늘고 긴 총열
			return PackedVector2Array([Vector2(0, -2.2), Vector2(r + 20.0, -1.4), Vector2(r + 20.0, 1.4), Vector2(0, 2.2)])
		"mid":    # 중거리 산탄 — 총구가 나팔처럼 벌어진 산탄총
			return PackedVector2Array([Vector2(0, -4.0), Vector2(r + 6.0, -4.5), Vector2(r + 12.0, -8.5), Vector2(r + 12.0, 8.5), Vector2(r + 6.0, 4.5), Vector2(0, 4.0)])
		"melee":  # 대검 — 앞으로 겨눈 잎사귀형 칼날
			return PackedVector2Array([Vector2(0, -2.5), Vector2(r + 4.0, -6.0), Vector2(r + 30.0, 0), Vector2(r + 4.0, 6.0), Vector2(0, 2.5)])
		# ── 이면 무기 4종. 예전엔 이 넷이 전부 balanced 총열로 그려져 뭘 들었는지 안 보였다 ──
		"bow":    # 각궁 — 활대의 굽은 실루엣
			return PackedVector2Array([Vector2(0, -14.0), Vector2(r + 6.0, -9.0), Vector2(r + 9.0, 0), Vector2(r + 6.0, 9.0), Vector2(0, 14.0), Vector2(3.0, 0)])
		"fan":    # 태극 부채 — 펼친 부챗살
			return PackedVector2Array([Vector2(0, 0), Vector2(r + 16.0, -13.0), Vector2(r + 20.0, 0), Vector2(r + 16.0, 13.0)])
		"sinkal": # 신칼 — 짧은 쌍칼(위아래로 벌어진 두 날)
			return PackedVector2Array([Vector2(0, -5.0), Vector2(r + 14.0, -8.0), Vector2(r + 16.0, -2.0), Vector2(r + 16.0, 2.0), Vector2(r + 14.0, 8.0), Vector2(0, 5.0)])
		"jakdu":  # 작두 — 두껍고 무거운 직선 날
			return PackedVector2Array([Vector2(0, -3.0), Vector2(r + 2.0, -11.0), Vector2(r + 26.0, -8.0), Vector2(r + 26.0, 8.0), Vector2(r + 2.0, 11.0), Vector2(0, 3.0)])
		_:        # balanced — 단정한 소총 총열(뾰족한 총구)
			return PackedVector2Array([Vector2(0, -3.2), Vector2(r + 12.0, -2.6), Vector2(r + 16.0, 0), Vector2(r + 12.0, 2.6), Vector2(0, 3.2)])


## 무기별 발사 연출.
## ★ 예전엔 아홉 무기가 전부 같은 삼각형 하나를 띄웠다. 총열 실루엣은 나눠 놨는데
##   쏘는 순간이 다 똑같으니 "무기가 섞여 보인다"가 남는다(실플레이 리포트).
##   무기 성격대로 형태·색·수명을 나눈다. 예산(fx_budget)은 그대로 지킨다.
func _muzzle_flash(arch: String = "") -> void:
	if not G.fx_budget():
		return  # 다중무기 고연사 시 머즐플래시 노드 폭주 방지
	var id: String = arch if arch != "" else _barrel_id
	var col: Color = WEAPON_DEFS[id]["col"] if WEAPON_DEFS.has(id) else Color("fff2c4")
	var muzzle: Vector2 = global_position + aim * (RADIUS + 16.0)
	# 8차 총구 시트 — 융합(레일건·구미호의 꼬리)이면 융합 시트. 칸 왼쪽 가운데가 총구다.
	var mk: String = String(fused_marks.get(id, ""))
	if not FxLib.has(mk, "muzzle"):
		mk = id if FxLib.has(id, "muzzle") else ""
	if mk != "":
		FxLib.left_anchor(FxLib.burst(get_parent(), muzzle, mk, "muzzle", aim.angle(), 1.0, -1.0, 25), mk, "muzzle")
		return
	var root := Node2D.new()
	root.rotation = aim.angle()
	root.z_index = 25
	get_parent().add_child(root)
	G.mine(root)   # 19차: 영웅 둘레에서 흐리게
	root.global_position = muzzle
	var life: float = 0.09
	match id:
		"heavy":  # 대구경 — 크고 둔중한 폭연 + 옆으로 뻗는 충격
			life = 0.16
			_flash_part(root, G.regular_polygon(7, 20.0), Color(1.0, 0.86, 0.55, 0.95), Vector2(4, 0))
			_flash_part(root, PackedVector2Array([Vector2(0, -13), Vector2(30, 0), Vector2(0, 13)]),
				Color(1.0, 0.62, 0.22, 0.75), Vector2.ZERO)
		"rapid":  # 속사 — 아주 짧고 날카로운 섬광 (초당 10발이라 작게)
			life = 0.05
			_flash_part(root, PackedVector2Array([Vector2(0, -4), Vector2(22, 0), Vector2(0, 4)]),
				Color(1.0, 0.95, 0.6, 0.9), Vector2.ZERO)
		"mid":  # 산탄 — 넓게 퍼지는 부채 화염
			life = 0.11
			_flash_part(root, PackedVector2Array([Vector2(0, -16), Vector2(26, -6), Vector2(26, 6), Vector2(0, 16)]),
				Color(1.0, 0.72, 0.35, 0.8), Vector2.ZERO)
		"bow":  # 각궁 — 화약이 아니라 시위가 튕기는 잔상 (세로 선)
			life = 0.10
			_flash_part(root, PackedVector2Array([Vector2(-2, -16), Vector2(2, -16), Vector2(2, 16), Vector2(-2, 16)]),
				Color(col.r, col.g, col.b, 0.85), Vector2(-6, 0))
		"fan":  # 부채 — 펼쳐지는 반달
			life = 0.13
			_flash_part(root, _arc_poly(26.0, 14.0, deg_to_rad(78.0), 10),
				Color(col.r, col.g, col.b, 0.7), Vector2.ZERO)
		"sinkal":  # 신칼 — 교차하는 두 가닥 (쌍칼 연격)
			life = 0.07
			for s: float in [-1.0, 1.0]:
				_flash_part(root, PackedVector2Array([Vector2(0, s * -2), Vector2(20, s * -9), Vector2(20, s * -5)]),
					Color(1, 1, 1, 0.85), Vector2.ZERO)
		_:  # balanced 및 나머지 — 단정한 삼각 섬광
			_flash_part(root, G.regular_polygon(3, 12.0), Color("fff2c4"), Vector2.ZERO)
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector2(0.15, 0.15), life)
	tw.parallel().tween_property(root, "modulate:a", 0.0, life)
	tw.tween_callback(root.queue_free)


func _flash_part(root: Node2D, poly: PackedVector2Array, col: Color, off: Vector2) -> void:
	var f := Polygon2D.new()
	f.polygon = poly
	f.color = col
	f.position = off
	root.add_child(f)


## 부채꼴 링 조각 (안쪽 반지름 ri ~ 바깥 ro, 각도 폭 w)
func _arc_poly(ro: float, ri: float, w: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg + 1:
		var a: float = -w * 0.5 + w * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * ro)
	for i in range(seg, -1, -1):
		var a2: float = -w * 0.5 + w * float(i) / float(seg)
		pts.append(Vector2(cos(a2), sin(a2)) * ri)
	return pts


## 물귀신 같은 '끌어당기는' 적이 부르는 견인. 여러 마리가 겹쳐도 이동속도의 절반을 못 넘게 묶는다
## (안 묶으면 세 마리만 붙어도 발이 아예 안 떨어져서 버그처럼 보인다).
var _pull_frame: int = -1
var _pull_used: float = 0.0

func apply_pull(dir: Vector2, amount: float) -> void:
	var f: int = Engine.get_physics_frames()
	if f != _pull_frame:
		_pull_frame = f
		_pull_used = 0.0
	var cap: float = move_speed * 0.5 * get_physics_process_delta_time()
	var use: float = minf(amount, maxf(0.0, cap - _pull_used))
	if use <= 0.0:
		return
	_pull_used += use
	global_position += dir * use


## 잠깐 무적 — 승리 연출처럼 "다 이겼는데 죽는" 상황을 막을 때 쓴다.
func grant_iframe(sec: float) -> void:
	_iframe = maxf(_iframe, sec)


## 죽었지만 아직 _die() 를 안 한 상태 — 부활 패널이 떠 있는 동안 true.
var pending_revive: bool = false


## 광고를 끝까지 봤다 → 되살린다. 100% HP · 3초 무적 · 주변 정리.
func revive() -> void:
	if not pending_revive:
		return
	pending_revive = false
	hp = max_hp
	_iframe = 3.0
	_cv.cf_reset()
	G.revive_used += 1
	G.running = true
	# 부활하자마자 다시 죽는 최악의 경험을 막는다 — 몰려 있던 것들을 걷어낸다.
	_clear_nearby_enemies(320.0)
	_flash(Color(1.0, 0.95, 0.55))
	G.add_shake(0.8)
	G.sfx("levelup", 0.8)
	G.player_hp_changed.emit()


## 부활 포기(또는 광고 실패) → 원래대로 죽는다.
func finish_death() -> void:
	if not pending_revive:
		return
	pending_revive = false
	_die()


## 부활 직후 안전 확보 — 반경 안의 잔몹과 날아오던 적탄을 걷어낸다.
##
## ★ 두 가지를 일부러 안 한다:
##   1. 처치 처리(_die) 를 안 부른다 — 골드·도전과제·콤보가 오르면 광고가 파밍 수단이 된다.
##   2. 보스는 안 지운다 — 지우면 광고 한 번으로 보스를 통째로 건너뛰게 된다.
func _clear_nearby_enemies(radius: float) -> void:
	var rad2: float = radius * radius
	for n: Node in get_tree().get_nodes_in_group("enemy"):
		var e := n as Node2D
		if e == null or not is_instance_valid(e):
			continue
		if bool(e.get("_is_boss")):
			continue  # 보스는 남긴다 (무적 3초 동안 벗어나야 한다)
		if e.global_position.distance_squared_to(global_position) <= rad2:
			e.queue_free()
	# 이미 날아오고 있던 탄은 무적 3초가 끝난 직후에 맞을 수 있다 — 전부 지운다.
	for n: Node in get_tree().get_nodes_in_group("ebullet"):
		if is_instance_valid(n):
			n.queue_free()


func take_damage(amount: float, src: String = "몸박") -> void:
	G.last_hit_src = src
	if _iframe > 0.0 or hp <= 0.0 or not G.running:
		return  # 종료 후(승리 화면) 잔탄 피격 무시 (S4)
	# 은장도 — 품고 다니는 한 수. 한 번은 통째로 흘려보내고 60초 뒤 다시 채워진다.
	if acc_dodge_ready:
		acc_dodge_ready = false
		_dodge_cd = 60.0
		_iframe = 0.6
		_flash(Color(0.85, 0.92, 1.0))
		G.sfx("pickup", 0.7)
		return
	amount *= acc_dmg_taken_mult
	# 승려의 염주 — 6초에 한 번, 들어온 피해를 통째로 흘려보낸다
	if ability == "beads" and _bead_cd <= 0.0:
		_bead_cd = bead_cd_max
		_iframe = 0.5
		_flash(Color(1.0, 0.86, 0.35))
		G.sfx("pickup", 0.6)
		return
	# 방어는 플랫 감산이되, 원피해의 30%는 항상 관통 — 방어+재생+흡혈 탱커가 후반에 무적이 되는 것 방지
	var dmg: float = maxf(1.0, maxf(amount * 0.30, amount - armor))
	if G.harness_nodmg:
		# 검사(--botrun --nodmg): 받은 피해는 세되 깎지 않는다 — 봇이 죽어 보스 측정이 끊기지 않게, 최대 체력은 진짜 값 그대로
		G.dmg_recv += dmg
		G.hits_taken += 1
		_iframe = 0.32
		return
	hp = maxf(0.0, hp - dmg)
	G.dmg_recv += dmg
	# 0.7 → 0.4 → 0.32. "피격 당하는것도 좀 하드하게"(실플레이 리포트) — 군집 한가운데
	# 서 있는 것이 실제로 위험해야 회피가 플레이의 일부가 된다.
	_iframe = 0.32
	G.hits_taken += 1
	if G.boss_fight_t > 0.0:
		G.boss_hits += 1
		G.no_hit_boss = false  # 보스전에서 한 대라도 맞으면 별 3개는 못 받는다
	G.player_hp_changed.emit()
	G.sfx("hurt", 1.0, -3.0)
	G.add_shake(0.22)
	_flash(Color(1, 0.3, 0.3))
	_cv.hurt()
	_hurt_number(dmg)
	if thorns > 0.0:
		_reflect_thorns()
	# 광전사의 피: 죽을 위기에 순간 무적 (쿨 60s)
	if hp <= 0.0 and last_stand and _ls_cd <= 0.0:
		hp = maxf(1.0, max_hp * 0.35)
		_iframe = 2.0
		_ls_cd = 60.0
		_flash(Color(1.0, 0.15, 0.15))
		G.add_shake(0.9)
		G.player_hp_changed.emit()
		return
	if hp <= 0.0:
		# 광고 부활 기회가 남아 있으면 아직 죽이지 않는다 — main 이 패널을 띄우고
		# revive() 또는 finish_death() 중 하나를 반드시 부른다.
		if G.revive_available():
			_cv.play_once("death", true)
			pending_revive = true
			G.running = false          # 시간 정지 (적/탄 모두 멈춤)
			G.revive_offered.emit()
			return
		_die()


## 캐릭터 전용 진화(보물상자). 표시용 이름 반환.
func apply_signature(char_id: String) -> String:
	match char_id:
		"berserker":
			last_stand = true
			card_mult *= 1.3
			G.player_hp_changed.emit()
			return "광전사의 피 (죽을 위기에 순간 무적)"
		"gunner":
			pierce += 3
			proj_bonus += 1
			rate_mult = maxf(0.2, rate_mult * 0.8)
			return "관통 폭풍 (관통·연사·멀티)"
		"collector":
			magnet_bonus += 260.0
			xp_mult += 0.5
			luck += 0.1
			return "황금 자석 (자석·경험치·행운)"
		"tank":
			thorns += 25.0
			armor += 6.0
			regen += 3.0
			max_hp += 40.0
			hp = max_hp
			G.player_hp_changed.emit()
			return "가시 요새 (반사·방어·재생)"
		"gambler":
			crit_chance = minf(1.0, crit_chance + 0.2)
			crit_mult += 1.0
			b_shock += 2
			return "잭팟 러시 (치명·감전)"
		_:
			card_mult *= 1.25
			rate_mult = maxf(0.2, rate_mult * 0.85)
			move_speed *= 1.12
			max_hp += 30.0
			hp = max_hp
			G.player_hp_changed.emit()
			return "오버드라이브 (전능력 상승)"


func apply_stun(sec: float) -> void:
	if _iframe > 0.0:
		return
	_stun = maxf(_stun, sec)
	_flash(Color(1.0, 0.95, 0.3))


func _reflect_thorns() -> void:
	for n in G.enemies_cached():
		if not is_instance_valid(n):
			continue  # 공유 캐시는 이번 프레임에 죽은 개체를 담을 수 있다 (캐스트 전에 걸러야 한다)
		var e := n as Enemy
		if e == null or not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) < 150.0:
			e.take_damage(thorns, e.global_position - global_position, false, "thorns")


## 메타(영구 업글) 적용 — 캐릭터 적용 전에 호출 (기본치에 얹음)
## 런타임 스탯을 공장 초기값으로 되돌린다.
## ★ apply_meta / apply_accessories / apply_character 는 전부 '더하기'라, 씬 리로드 없이
##   런을 다시 시작하면 값이 겹겹이 쌓인다. 지금까지는 _start_or_reload 가 항상 씬을 다시
##   불러 준 덕에 드러나지 않았을 뿐, 경로 하나만 바뀌면 조용히 터지는 구조였다.
##   (--acccheck 하니스가 실제로 이걸 잡았다: 치명 배율 2.20 → 2.45 로 누적)
func reset_stats() -> void:
	max_hp = MAX_HP
	move_speed = SPEED
	base_damage = BULLET_DMG
	card_add = 0.0
	card_mult = 1.0
	rate_mult = 1.0
	bullet_speed = BULLET_SPEED
	proj_bonus = 0
	pierce = 0
	crit_chance = 0.0
	crit_mult = CRIT_MULT_BASE
	regen = 0.0
	armor = 0.0
	magnet_bonus = 0.0
	luck = 0.0
	xp_mult = 1.0
	thorns = 0.0
	dash_cd_mult = 1.0
	last_stand = false
	echo_chance = 0.0
	enemy_slow = 0.0
	special_mult = 1.0
	ability = ""
	four_cards = false
	b_ice = 0
	b_fire = 0
	b_poison = 0
	b_shock = 0
	b_big = 0
	b_bounce = 0
	b_chain = 0
	b_homing = 0
	b_exec = 0
	b_vamp = 0
	b_bloom = 0
	acc_dodge_ready = false
	acc_dmg_taken_mult = 1.0
	acc_gold_mult = 1.0
	acc_dash_iframe = 0.0
	_dance_t = 0.0
	dance_max = 6.0
	dance_rate = 0.075
	bead_cd_max = 6.0
	_spirit_t = 0.0
	_bead_cd = 0.0
	_dodge_cd = 0.0
	_shadow_t = 0.0
	weapons_primary = [{"id": "balanced", "t": 0.0, "level": 1}]
	_last_primary = ""
	gamble_rolls = 0
	gamble_add = 0.0
	gamble_proj = 0
	gamble_crit = 0.0
	gamble_rate = 1.0
	gamble_last = ""
	gamble_log = []
	for k in weapons.keys():  # 특수무기 노드도 같이 정리 (안 하면 이전 런 무기가 계속 돈다)
		var n: Node = weapons[k]
		if is_instance_valid(n):
			n.queue_free()
	weapons.clear()
	if G.enemy_died.is_connected(_on_kill_lifesteal):
		G.enemy_died.disconnect(_on_kill_lifesteal)
	if G.enemy_died.is_connected(_on_kill_spirit):
		G.enemy_died.disconnect(_on_kill_spirit)
	_rebuild_sigil()
	hp = max_hp


func apply_meta() -> void:
	reset_stats()  # 항상 깨끗한 기본치에서 시작한다
	# 레벨당 수치는 G.META_TIERS 한 곳에만 있다 — 상점 표기와 실효가 어긋날 수 없다
	max_hp += G.meta_bonus("m_hp")
	damage *= 1.0 + G.meta_bonus("m_dmg")
	move_speed *= 1.0 + G.meta_bonus("m_speed")
	magnet_bonus += G.meta_bonus("m_magnet")
	luck += G.meta_bonus("m_luck")
	regen += G.meta_bonus("m_regen")
	hp = max_hp


## 장착한 액세서리 반영 — apply_meta 와 apply_character 사이에서 부른다.
## 정의는 Accessories.DEFS 한 곳, 효과는 여기 한 곳. 새로 하나 만들면 두 곳만 손대면 된다.
var acc_dodge_ready: bool = false   # 은장도: 다음 피격 한 번을 흘려보낼 수 있는 상태
var acc_dmg_taken_mult: float = 1.0  # 청동거울: 받는 피해 배수
var acc_gold_mult: float = 1.0       # 복주머니: 골드 획득 배수 (G.add_gold 가 읽는다)
var acc_dash_iframe: float = 0.0     # 죽부인: 대시 중 무적 연장(초)

func apply_accessories() -> void:
	acc_dodge_ready = false
	acc_dmg_taken_mult = 1.0
	acc_gold_mult = 1.0
	acc_dash_iframe = 0.0
	for id: String in G.acc_equipped():
		match id:
			"acc_jipsin":
				move_speed *= 1.06
			"acc_hopae":
				xp_mult += 0.10
			"acc_bokjumeoni":
				magnet_bonus += 40.0
				acc_gold_mult *= 1.12
			"acc_yeomju":
				regen += 0.5
				armor += 1.0
			"acc_okring":
				add_crit(0.08)
				crit_mult += 0.25
			"acc_binyeo":
				pierce += 1
				bullet_speed *= 1.12
			"acc_norigae":
				luck += 0.10
			"acc_durumagi":
				max_hp += 40.0
				armor += 2.0
			"acc_eunjangdo":
				acc_dodge_ready = true
			"acc_gat":
				luck += 0.25
			"acc_jukbuin":
				dash_cd_mult *= 0.75
				acc_dash_iframe += 0.14
			"acc_geoul":
				thorns += 25.0
				acc_dmg_taken_mult *= 0.92
			"acc_bell":
				special_mult *= 1.20
				add_weapon("wpn_summon")
	hp = minf(max_hp, hp if hp > 0.0 else max_hp)
	G.player_hp_changed.emit()


## 선택한 캐릭터의 기본치 편차 + 고유능력 적용 (main이 _ready 이후 호출)
## 일반 소스의 치명타 더하기. CRIT_CAP 을 넘기지 않되, 융합 · 시그니처로 이미 그 위에 있으면 깎지 않는다.
## ★ 11/7: 예전엔 자리마다 minf(0.70, 지금 + x) 라서, 필중의 눈 100% 에서 장신구 · 도박 · 영웅 카드를 받으면 70% 로 내려앉았다.
func add_crit(amt: float) -> void:
	crit_chance = maxf(crit_chance, minf(CRIT_CAP, crit_chance + amt))


## 발사 간격 배수 줄이기(작을수록 빠름). 바닥 0.25 를 넘지 않되, 이미 그 아래면(영웅 기본 0.2 등) 되돌리지 않는다.
func cut_rate(mult: float) -> void:
	rate_mult = minf(rate_mult, maxf(RATE_FLOOR, rate_mult * mult))


func apply_character(def: Dictionary) -> void:
	weapons_primary = [{"id": "balanced", "t": 0.0, "level": 1}]
	_last_primary = ""  # 새 런 무기 초기화
	gamble_rolls = 0
	gamble_add = 0.0
	gamble_proj = 0
	gamble_crit = 0.0
	gamble_rate = 1.0
	gamble_last = ""
	gamble_log = []
	fused_marks = {}
	_heal_bucket = 0.0
	_heal_block = 0.0
	var m: Dictionary = def.get("mods", {})
	damage *= float(m.get("damage_mult", 1.0))
	rate_mult = maxf(0.2, rate_mult * float(m.get("fire_mult", 1.0)))
	move_speed *= float(m.get("speed_mult", 1.0))
	bullet_speed *= float(m.get("bspeed_mult", 1.0))
	max_hp += float(m.get("hp_add", 0.0))
	hp = max_hp
	armor += float(m.get("armor_add", 0.0))
	magnet_bonus += float(m.get("magnet_add", 0.0))
	luck += float(m.get("luck_add", 0.0))
	# ★ 카드·장신구는 minf(0.70, ...) 인데 여기만 상한이 없어, 카드로 70% 를 채운 도박사·도적·매잡이가
	#   그 위로 올라갔다. "100% 는 융합/시그니처 전유물"이라는 규칙이 여기서 새고 있었다.
	add_crit(float(m.get("crit_add", 0.0)))
	pierce += int(m.get("pierce_add", 0))
	proj_bonus += int(m.get("proj_add", 0))
	# ★ 여기만 대입이라 앞서 붙은 장신구(호패 +10%)가 매번 지워졌다. 기본값이 1.0 이라 곱해도 기존 동작은 동일.
	xp_mult *= float(m.get("xp_mult", 1.0))
	ability = String(def.get("ability", ""))
	four_cards = ability == "fourcards"
	# 캐릭터 등급(강화) 반영 — 등급당 기본치 상승 + 고유능력 강화
	# 등급당 수치는 G.RANK_* 한 곳에만 있다 (선택 화면 표기와 실효가 어긋나지 않게)
	G.last_char_id = String(def.get("id", "base"))  # 몹 스케일이 이 영웅의 등급을 본다
	var rank: int = G.char_rank(String(def.get("id", "")))
	if rank > 0:
		damage *= 1.0 + G.RANK_DMG * float(rank)
		max_hp += G.RANK_HP * float(rank)
		move_speed *= 1.0 + G.RANK_SPD * float(rank)
		armor += G.RANK_ARMOR * float(rank)
		hp = max_hp
	# 선택 캐릭터의 실제 스프라이트로 비주얼 교체 (없으면 도형 유지)
	var sp: String = String(def.get("sprite", ""))
	var cf_slot: Dictionary = CharForge.hero_slot(String(def.get("id", "")))
	var cf: String = String(cf_slot.get("id", ""))
	if _cv != null and cf != "":
		_cv.queue_free()
		_cv = CreatureVisual.new()
		_cv.radius = RADIUS
		_cv.cf_id = cf
		_cv.cf_target_h = float(cf_slot.get("h", 0.0))
		_cv.always_animate = true
		_cv.build()
		add_child(_cv)
		_place_hero_mark()
		# 신화는 등장 연출이 있다 — 판이 열릴 때 한 번
		_cv.play_once("entrance")
	elif _cv != null and sp != "" and ResourceLoader.exists(sp):
		_cv.queue_free()
		_cv = CreatureVisual.new()
		_cv.radius = RADIUS
		_cv.sprite_path = sp
		_cv.sprite_hframes = Enemy._strip_frames(sp)  # 걷기 스트립이면 프레임 순환 (그림에서 직접 판별)
		_cv.always_animate = true
		_cv.build()
		add_child(_cv)
	elif _cv != null:
		_cv.set_base_color(def.get("color", _cv.body_color))
	G.player_hp_changed.emit()
	if ability == "lifesteal" and not G.enemy_died.is_connected(_on_kill_lifesteal):
		G.enemy_died.connect(_on_kill_lifesteal)
	# ── S1 신규 캐릭터 고유 능력 ──
	if ability == "dashstrike":  # 돌격기사: 대시 쿨 -40% (돌진이 곧 무기)
		dash_cd_mult *= 0.6
	elif ability == "pyro":  # 화염술사: 화염 오라 소지 시작 + 특수무기 위력 +25% (S2 상향)
		special_mult *= 1.25
		add_weapon("wpn_fire")
	# ── 이면 영웅 고유 능력 ──
	elif ability == "spirits":  # 무당: 방울 — 소환수를 데리고 시작하고, 처치가 소환수를 키운다
		add_weapon("wpn_summon")
		if not G.enemy_died.is_connected(_on_kill_spirit):
			G.enemy_died.connect(_on_kill_spirit)
	elif ability == "forge":  # 도깨비 대장장이: 벼림 — 특수무기가 굵어진다
		special_mult *= 1.25   # 17-2: 1.40 → 1.25 — 봇 판 분당 화력이 다른 영웅 중앙값의 4.3 배
	elif ability == "beads":  # 승려: 염주 — 주기적으로 피해 한 번을 흘려보낸다
		_bead_cd = 0.0
	elif ability == "falcon":  # 매잡이: 매 — 모든 탄이 조금씩 휘어 적을 찾는다
		b_homing = maxi(b_homing, 1)
	# ── 저승길 영웅(16차): 시작 무기 — 주무기를 바꿔 들거나(start_primary) 특수무기 하나를 들고 시작(start) ──
	special_mult *= float(m.get("special_mult", 1.0))
	var sp0: String = String(def.get("start_primary", ""))
	if sp0 != "":
		weapons_primary = [{"id": sp0, "t": 0.0, "level": 1}]
		_last_primary = sp0
		_rebuild_sigil()
	var sw0: String = String(def.get("start", ""))
	if sw0 != "":
		add_weapon(sw0)


func _on_kill_lifesteal(_pos: Vector2) -> void:
	heal(1.5)


## 무당: 처치한 자리에서 원혼이 잠깐 남아 소환수의 힘이 된다.
## (실제 노드를 더 만들면 군중전에서 비싸므로, 소환수 위력 배수를 짧게 올리는 방식)
func _on_kill_spirit(_pos: Vector2) -> void:
	_spirit_t = SPIRIT_DUR


## 발밑 시길 링 — 지금 들고 있는 무기를 캐릭터만 봐도 알게 한다.
## ★ 브로타토는 무기 실물을 캐릭터에 붙여 이 문제를 푸는데, 6정을 붙이면 실루엣이 묻힌다(유저 판단).
##   목적("내가 뭘 들었나")만 떼어내 발밑에 무기 수만큼 룬을 돌린다. 노드는 무기 수 + 1개뿐이고
##   트윈을 안 써서 G.fx_budget() 을 전혀 안 먹는다.
var _sigil: Node2D

func _rebuild_sigil() -> void:
	if _sigil == null:
		_sigil = Node2D.new()
		_sigil.z_index = -2  # 캐릭터·그림자 아래
		add_child(_sigil)
	for c in _sigil.get_children():
		c.queue_free()
	var ids: Array = []
	for w in weapons_primary:
		ids.append(String(w["id"]))
	for k in weapons.keys():
		ids.append(String(k))
	if ids.size() <= 1:
		return  # 무기 1정이면 알려줄 것이 없다
	var n: int = ids.size()
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var wid: String = String(ids[i])
		var fused: bool = fused_marks.has(wid)
		var rune := Polygon2D.new()
		# 융합한 무기의 룬은 더 크고 여섯 갈래 — 발밑만 봐도 "몇 개를 초월했는지"가 읽힌다
		rune.polygon = G.regular_polygon(6, 5.2) if fused else G.regular_polygon(4, 3.4)
		rune.color = G.weapon_color(wid)
		rune.position = Vector2(cos(a), sin(a)) * (RADIUS + 9.0) + Vector2(0, RADIUS * 0.55)
		_sigil.add_child(rune)
		if fused:  # 금빛 후광 한 겹
			var halo := Polygon2D.new()
			halo.polygon = G.regular_polygon(10, 8.0)
			halo.color = Color(1.0, 0.84, 0.29, 0.34)
			halo.position = rune.position
			halo.z_index = -1
			_sigil.add_child(halo)


## 능력 배수 링 — 능력으로 올라온 공격력이 지금 천장의 몇 퍼센트인지 발밑에 그린다.
## ★ 화면에 숫자만 혼자 뛰고(20 → 23) 이유가 어디에도 없으면 그건 버그로 읽힌다(2026-09-06 지적).
##   HUD 는 이미 좌상단 6줄 · 우상단 콤보 · 상단 XP 바로 차 있어서 한 칸도 안 쓴다.
##   눈이 이미 가 있는 캐릭터 발밑에, 기존 시길 링과 같은 자리·같은 비용(노드 1개, 트윈 없음)으로 붙인다.
##   능력이 배수를 안 만드는 영웅은 hero_mult_max()==1.0 이라 **노드 자체가 안 생긴다.**
##   색은 영웅색이 아니라 호박색 하나로 고정한다 — 색이 뜻하는 건 '누구냐'가 아니라
##   '공격력이 올라와 있다'여야 영웅을 바꿔도 같은 뜻으로 읽힌다.
const BUFF_COL: Color = Color("ffb648")

class _BuffRing extends Node2D:
	var ratio: float = 0.0
	func _draw() -> void:
		if ratio <= 0.004:
			return
		# 무기 시길 룬이 RADIUS+9 자리에서 반경 5.2 까지 뻗으므로 그 바깥으로 뺀다 —
		# 겹치면 두 표시가 서로를 지저분하게 만든다.
		var r: float = Player.RADIUS + 19.0
		# 바닥 홈 한 겹을 깔아야 '얼마나 찼는지'가 읽힌다 (빈 칸이 안 보이면 게이지가 아니다)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 30, Color(0, 0, 0, 0.22), 3.0, true)
		draw_arc(Vector2.ZERO, r, -PI * 0.5, -PI * 0.5 + TAU * ratio, 30,
			Color(Player.BUFF_COL.r, Player.BUFF_COL.g, Player.BUFF_COL.b, 0.34 + 0.5 * ratio),
			3.0, true)

var _buff_ring: _BuffRing
var _mult_prev: float = 1.0


## 이 영웅의 능력이 공격력에 올릴 수 있는 배수의 천장. 1.0 이면 그릴 게 없다.
## 배수 자체는 _hero_dmg_mult() 한 곳에서만 만들어지므로 여기가 그 짝이다.
func hero_mult_max() -> float:
	match ability:
		"spirits": return SPIRIT_MULT
		"sworddance": return 1.0 + dance_rate * dance_max
		"rage": return RAGE_MULT
	return 1.0


func _update_buff_ring() -> void:
	var top: float = hero_mult_max()
	if top <= 1.001:
		return
	var m: float = _hero_dmg_mult()
	if _buff_ring == null:
		_buff_ring = _BuffRing.new()
		_buff_ring.z_index = -2   # 캐릭터·그림자 아래 (시길 링과 같은 층)
		add_child(_buff_ring)
	var ratio: float = clampf((m - 1.0) / (top - 1.0), 0.0, 1.0)
	if absf(ratio - _buff_ring.ratio) > 0.004:
		_buff_ring.ratio = ratio
		_buff_ring.queue_redraw()
	# 기준선에서 막 올라온 **그 순간**에만 숫자를 한 번 띄운다. 매 프레임 띄우면 검무처럼
	# 계속 변하는 능력이 화면을 도배한다 — 알려줘야 하는 건 '왜 갑자기 바뀌었지?' 하나뿐이다.
	if m > 1.004 and _mult_prev <= 1.004:
		_buff_label(I18n.t("공격력 ×%.2f") % m)
	_mult_prev = m


## 17-1: 영웅이 맞은 양을 머리 위에 빨갛게. 몹 피해 숫자(DamageNumber)는 겹침 · 상한으로 걸러지는데
##   몹이 몰린 자리에선 영웅 숫자가 늘 걸러져서 안 나왔다. 무적시간(0.32초) 덕에 초당 셋을 넘지 않아 따로 띄운다.
func _hurt_number(dmg: float) -> void:
	if not G.show_dmgnum or G.dmgnum_mode == 2 or dmg < 0.5:
		return
	var l := Label.new()
	l.text = "-%d" % int(ceil(dmg))
	UiFont.apply(l, 24)
	l.add_theme_color_override("font_color", Color("ff4a52"))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.0, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(80.0, 26.0)
	l.global_position = (global_position + Vector2(-40.0 + randf_range(-8.0, 8.0), -RADIUS - 52.0)).round()
	l.z_index = 70
	get_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y - 26.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tw.tween_callback(l.queue_free)


func _buff_label(txt: String) -> void:
	if not G.fx_budget():
		return
	var l := Label.new()
	l.text = txt
	UiFont.apply(l, 16)
	l.add_theme_color_override("font_color", BUFF_COL)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	l.global_position = global_position + Vector2(-40, -RADIUS - 40.0)
	l.z_index = 60
	get_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y - 24.0, 0.7)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.35)
	tw.tween_callback(l.queue_free)


## 특수무기 장착/레벨업
func add_weapon(id: String) -> void:
	if weapons.has(id) and is_instance_valid(weapons[id]):
		weapons[id].call("level_up")
		return
	var w: Node2D = null
	match id:
		"wpn_orb":
			w = OrbitWeapon.new()
		"wpn_chain":
			w = ChainWeapon.new()
		"wpn_fire":
			w = FireWeapon.new()
		"wpn_ice":
			w = IceWeapon.new()
		"wpn_poison":
			w = PoisonWeapon.new()
		"wpn_summon":
			w = SummonWeapon.new()
		"summon_ice":
			w = IceSummon.new()
		"wpn_whip":
			w = WhipWeapon.new()
		"wpn_boomerang":
			w = BoomerangWeapon.new()
		"wpn_beam":
			w = BeamWeapon.new()
	if w != null:
		add_child(w)
		G.mine(w)   # 19차: 영웅 둘레에서 흐리게
		weapons[id] = w
		for _i in transcend_bonus:      # 초월을 먹은 뒤 든 무기도 같은 단계에서 시작한다
			w.call("level_up")
	_rebuild_sigil()


## 11/7 회복 견제 — 흡혈 · 재생 · 처치 회복 · 회복 구슬이 모두 여길 지난다(카드로 바로 오르는 체력은 빼고).
##   난이도 · 업보 효율(G.heal_eff), 초당 상한(최대 체력 × G.heal_cap_frac, 새는 양동이), 저주 정예에게 물린 뒤 40%.
##   스팀 플레이 보고 「흡혈만 잘 하면 너무 쉽다」 — 처치 회복 영웅은 초당 수십 마리를 잡으면 초당 수십을 채웠다.
var _heal_bucket: float = 0.0
var _heal_block: float = 0.0


func _heal_scaled(amount: float) -> float:
	var a: float = amount * G.heal_eff()
	if _heal_block > 0.0:
		a *= 0.4
	var hcap: float = G.heal_cap_frac()
	if hcap > 0.0:
		a = minf(a, maxf(0.0, max_hp * hcap - _heal_bucket))
		_heal_bucket += a
	return a


## 저주 정예에게 물렸다 — 그 동안 회복이 40% 로 준다. 보라색으로 한 번 번쩍.
func curse_heal(sec: float) -> void:
	if _heal_block <= 0.0:
		_flash(Color(0.78, 0.55, 1.0))
	_heal_block = maxf(_heal_block, sec)


func heal(amount: float) -> void:
	if hp <= 0.0:
		return
	amount = _heal_scaled(amount)
	if amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	G.player_hp_changed.emit()
	_flash(Color(0.5, 1.0, 0.6))


func _flash(c: Color) -> void:
	_cv.flash(c, 0.35)


func _die() -> void:
	G.running = false
	G.player_died.emit()
	if _cv.is_cf():
		# 쓰러진 채 입력을 받아 미끄러지면 안 된다 — 이동·사격을 끊고 동작만 끝까지 보여 준다.
		set_physics_process(false)
		_cv.play_once("death", true)
		# 게임오버 패널이 판을 멈춰도 쓰러지는 동작은 끝까지 돈다
		_cv.process_mode = Node.PROCESS_MODE_ALWAYS
		var dt := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		dt.tween_interval(_cv.anim_len("death") + 0.3)
		dt.tween_callback(queue_free)
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.01, 0.01), 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(queue_free)


## 캐릭터 에셋의 시그니처 이펙트(vfx) — 대시를 떠난 자리에 잠깐 남는다.
func _spawn_cf_vfx() -> void:
	var an: Dictionary = _cv.cf_anim("vfx")
	if an.is_empty() or not is_inside_tree():
		return
	var fx: Sprite2D = _cv.make_vfx()
	fx.centered = false
	fx.offset = Vector2(-floorf(float(an["fw"]) * 0.5), -(float(an["fh"]) - 2.0))
	fx.flip_h = velocity.x < 0.0
	fx.global_position = global_position + Vector2(0, roundf(RADIUS * 0.86))
	fx.z_index = -1
	get_parent().add_child(fx)
	G.mine(fx)   # 19차: 영웅 둘레에서 흐리게
	var tw := fx.create_tween()
	tw.tween_property(fx, "modulate:a", 0.0, 0.35)
	tw.tween_callback(fx.queue_free)


## 융합 · 클리어 같은 큰 순간의 동작(궁극기 · 감정 표현). 그 등급에 없으면 아무 일도 없다.
func cf_moment(a: String) -> void:
	if _cv != null and _cv.is_cf():
		_cv.play_once(a)


## HUD 대시 게이지용: 0(방금 씀)~1(준비완료)
func dash_ratio() -> float:
	var full: float = maxf(DASH_CD_MIN, DASH_CD * dash_cd_mult)
	return 1.0 - clampf(_dash_cd / maxf(0.01, full), 0.0, 1.0)


func dash_ready() -> bool:
	return _dash_cd <= 0.0


## 발밑 고리 — **이게 내 영웅이다** 를 한눈에.
## 2026-09-05: 43종을 새로 그리고 나니 영웅과 몹이 게임 크기(30px)에서 색까지 닮은 쌍이
## 생겼다(뒷불 새디 ↔ 니오베 8.9, 전체 중앙값 61). 그림을 다시 굽는 것보다 확실하다 —
## 어떤 조합이 나와도 고리가 있는 쪽이 나다.
## 19차 2절: 발밑 고리(hero_ring 56×24 · 6칸 120ms · 전투 ×1, anchor [28,12] = 발 기준점).
## ★ 후반(12분 · 몹 200)에 불꽃 오라 · 베기가 영웅을 덮어 「내가 어디 있나」가 안 보였다(19차 보고 7절).
##   내 이펙트보다 위(29), 피해 숫자(30 · 50 · 70)보다 아래에 그린다. 몸이 보이는 건 G.mine 흐림이 맡는다.
func _make_hero_ring() -> bool:
	var path: String = "res://assets/ui/parts/sheets/hero_ring.png"
	if not ResourceLoader.exists(path):
		return false
	var sp := Sprite2D.new()
	sp.name = "HeroRing"
	sp.texture = load(path)
	sp.hframes = 6
	sp.centered = false
	sp.offset = Vector2(-28.0, -12.0)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.position = Vector2(0.0, roundf(RADIUS * 0.72))
	sp.z_as_relative = false
	sp.z_index = 29
	add_child(sp)
	var tw := sp.create_tween().set_loops()
	tw.tween_interval(0.12)
	tw.tween_callback(func() -> void: sp.frame = (sp.frame + 1) % 6)
	# 19차 2절 hero_mark(선택): 머리 위 6px 에 아래로 향한 흰 화살촉. 몹 200 이 영웅 자리에 몰린 12분 장면에서
	#   고리만으로는 「어디 있나」가 모자라서 같이 단다. 머리 높이는 영웅 그림 키(_place_hero_mark)로 맞춘다.
	var mpath: String = "res://assets/ui/parts/sheets/hero_mark.png"
	if ResourceLoader.exists(mpath):
		var mk := Sprite2D.new()
		mk.name = "HeroMark"
		mk.texture = load(mpath)
		mk.hframes = 2
		mk.centered = false
		mk.offset = Vector2(-6.0, -10.0)
		mk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mk.z_as_relative = false
		mk.z_index = 29
		add_child(mk)
		_hero_mark = mk
		_place_hero_mark()
		var tw2 := mk.create_tween().set_loops()
		tw2.tween_interval(0.3)
		tw2.tween_callback(func() -> void: mk.frame = (mk.frame + 1) % 2)
	return true


var _hero_mark: Sprite2D = null

## 머리 위 6px — 발(RADIUS×0.72)에서 영웅 그림 키만큼 위. 키를 모르면 예전 짐작(반지름 × DRAW_SCALE).
func _place_hero_mark() -> void:
	if _hero_mark == null or not is_instance_valid(_hero_mark):
		return
	var h: float = RADIUS * CreatureVisual.DRAW_SCALE
	if _cv != null and is_instance_valid(_cv) and _cv.cf_target_h > 0.0:
		h = _cv.cf_target_h
	_hero_mark.position = Vector2(0.0, roundf(RADIUS * 0.72 - h - 6.0))


func _make_foot_ring() -> void:
	if _make_hero_ring():
		return   # 19차 고리가 예전 선 고리를 갈음한다
	var ring := Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(1.0, 0.95, 0.62, 0.55)
	var pts: PackedVector2Array = G.regular_polygon(18, RADIUS * 1.15)
	for pt: Vector2 in pts:
		ring.add_point(pt)
	ring.add_point(pts[0])
	var holder := Node2D.new()
	holder.scale = Vector2(1.0, 0.42)          # 바닥에 누운 원근 (몹 표식과 같은 눌림)
	holder.position = Vector2(0, RADIUS * 0.72)
	holder.z_index = -3                        # 영웅 그림 아래, 그림자보다도 아래
	holder.add_child(ring)
	add_child(holder)
