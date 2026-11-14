class_name Icons
extends Object
## 특성/아이템 아이콘을 도형으로 절차 드로잉. 카테고리별 알록달록한 색.
## draw_symbol(canvas_item, id, center, radius, color) — 흰 심볼을 그린다.

const COLORS: Dictionary = {
	"dmg": Color("ff5a5a"),
	"rate": Color("ffd23f"),
	"speed": Color("42e2b8"),
	"multi": Color("ff9f43"),
	"pierce": Color("b06bff"),
	"hp": Color("62d162"),
	"bspeed": Color("54c6ff"),
	"crit": Color("ff7a3c"),
	"critdmg": Color("ff4d6d"),
	"regen": Color("4fd18a"),
	"armor": Color("8aa6dd"),
	"magnet": Color("5c8dff"),
	"luck": Color("5fd39a"),
	"gamble": Color("ff5ca8"),
	"heal": Color("62d162"),
	"heal_card": Color("62d162"),
	"gold_card": Color("ffd54a"),
	# 캐릭터 고유 카드 (M37) — 통일 틸 컬러
	"c_allround": Color("42e2b8"),
	"c_bloodlust": Color("ff6a7a"),
	"c_overheat": Color("ffd23f"),
	"c_goldsense": Color("5fd39a"),
	"c_ironwill": Color("8aa6dd"),
	"c_allin": Color("ff5ca8"),
	# 전설/신화 카드 (M40)
	"l_timewarp": Color("8fd0ff"),
	"l_giant": Color("ffb15c"),
	"l_echo": Color("ffd23f"),
	"m_apocalypse": Color("ff3df0"),
	"m_immortal": Color("ff6a7a"),
	"m_transcend": Color("ff3df0"),
	"item_magnet": Color("5c8dff"),
	"freeze": Color("7fe9ff"),
	"bigxp": Color("9dff6b"),
	"wpn_orb": Color("7dff9b"),
	"wpn_chain": Color("aee1ff"),
	"wpn_fire": Color("ff7a3c"),
	"wpn_ice": Color("7fd4ff"),
	"wpn_poison": Color("8fe36b"),
	"wpn_summon": Color("baff7d"),
	"summon_ice": Color("7fd4ff"),
	# 탄막 부여 (온히트)
	"b_ice": Color("7fd4ff"),
	"b_fire": Color("ff7a3c"),
	"b_poison": Color("8fe36b"),
	"b_shock": Color("ffe23f"),
	"b_big": Color("ffb15c"),
	"b_bounce": Color("9de0ff"),
	"b_chain": Color("aee1ff"),
	"b_homing": Color("c77dff"),
	"b_exec": Color("ff5566"),
	"b_vamp": Color("d6486b"),
	"b_bloom": Color("ff9a4a"),
	"wpn_whip": Color("d98cff"),
	"wpn_boomerang": Color("e8d24a"),
	"wpn_beam": Color("ff4fa0"),
	# 추가 기본/특수
	"xp_gain": Color("9dff6b"),
	"dashcd": Color("42e2b8"),
	"thorns": Color("ff8a5c"),
	"chest": Color("ffd54a"),
	# 무기 아키타입
	"wp_heavy": Color("ff9f43"),
	"wp_rapid": Color("ffe23f"),
	"wp_mid": Color("ff7a3c"),
	"wp_melee": Color("dfe4ff"),
	"wp_balanced": Color("fff0b0"),
	# 이면 무기
	"wp_bow": Color("f0c33c"),
	"wp_fan": Color("2e86ab"),
	"wp_sinkal": Color("f2efe6"),
	"wp_jakdu": Color("c1272d"),
	# 특수 영웅 · 이면 영웅 고유 카드
	"c_charge": Color("c8d6ea"),
	"c_emberheart": Color("ff8a3c"),
	"c_umbra": Color("b06bff"),
	"c_bellcall": Color("c1272d"),
	"c_bloomstep": Color("2e86ab"),
	"c_temper": Color("a8761f"),
	"c_mantra": Color("f0c33c"),
	"c_talon": Color("74849c"),
	# 장신구 (상점)
	"acc_jipsin": Color("9c9482"),
	"acc_hopae": Color("bfb7a4"),
	"acc_bokjumeoni": Color("e05545"),
	"acc_yeomju": Color("6b4a12"),
	"acc_okring": Color("6dc46b"),
	"acc_binyeo": Color("aab8cc"),
	"acc_norigae": Color("f28fc0"),
	"acc_durumagi": Color("2e86ab"),
	"acc_eunjangdo": Color("d9d3c4"),
	"acc_gat": Color("352e3d"),
	"acc_jukbuin": Color("b0e89a"),
	"acc_geoul": Color("f7dd7e"),
	"acc_bell": Color("f0c33c"),
	"acc_slot": Color("74849c"),
}


# 융합별 고유 스타일 (S5): 재료 무기 심볼 + 테마색 — 전부 똑같은 금별이던 것을 개별 정체성으로
const EVO_STYLE: Dictionary = {
	"evo_inferno": {"base": "wpn_fire", "col": Color("ff6a3c")},
	"evo_blizzard": {"base": "wpn_ice", "col": Color("7fd4ff")},
	"evo_plague": {"base": "wpn_poison", "col": Color("8fe36b")},
	"evo_railcannon": {"base": "pierce", "col": Color("ffb15c")},
	"evo_tempest": {"base": "wpn_chain", "col": Color("aee1ff")},
	"evo_legion": {"base": "wpn_summon", "col": Color("baff7d")},
	"evo_reaper": {"base": "wp_melee", "col": Color("d98cff")},
	"evo_nova": {"base": "wpn_beam", "col": Color("ff4fa0")},
	"evo_deadeye": {"base": "b_homing", "col": Color("ffe23f")},
	"evo_ninetail": {"base": "wp_fan", "col": Color("f28fc0")},
	"evo_ledger": {"base": "wp_bow", "col": Color("4a4152")},
	"evo_orb": {"base": "wp_jakdu", "col": Color("f0c33c")},
}


static func color_of(id: String) -> Color:
	if id.begins_with("evo_"):
		return (EVO_STYLE.get(id, {}) as Dictionary).get("col", Color("ffd54a"))
	return COLORS.get(id, Color("cccccc"))


static func draw_symbol(ci: CanvasItem, id: String, c: Vector2, r: float, col: Color = Color.WHITE) -> void:
	var lw: float = maxf(2.5, r * 0.20)
	if id.begins_with("evo_"):
		# 융합: 금빛 광선 8줄 + 이중 링 + 중앙에 '재료 무기' 심볼(테마색) — 한눈에 어떤 융합인지
		var st: Dictionary = EVO_STYLE.get(id, {})
		var gold := Color("ffd54a")
		for i in 8:
			var a: float = TAU * float(i) / 8.0 + PI / 8.0
			ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.72, c + Vector2(cos(a), sin(a)) * r * 1.02, gold, lw * 0.6)
		ci.draw_arc(c, r * 0.66, 0, TAU, 24, gold, lw * 0.55)
		ci.draw_arc(c, r * 0.58, 0, TAU, 24, Color(gold.r, gold.g, gold.b, 0.4), lw * 0.4)
		if st.is_empty():
			_draw_star(ci, c, r * 0.5, gold)
		else:
			draw_symbol(ci, String(st["base"]), c, r * 0.44, st["col"])
		return
	match id:
		"dmg", "wp_heavy", "wp_balanced", "m_apocalypse":  # 검
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.26, r * 0.3), c + Vector2(0, r * 0.55), c + Vector2(-r * 0.26, r * 0.3)]), col)
			ci.draw_line(c + Vector2(-r * 0.55, r * 0.3), c + Vector2(r * 0.55, r * 0.3), col, lw)
			ci.draw_line(c + Vector2(0, r * 0.55), c + Vector2(0, r), col, lw)
		"rate", "b_shock", "wp_rapid", "c_overheat":  # 번개
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.2, -r), c + Vector2(-r * 0.35, r * 0.1), c + Vector2(r * 0.1, r * 0.1), c + Vector2(-r * 0.25, r)]), col, lw)
		"wp_mid":  # 중거리 산탄 (부채꼴 점)
			for a2 in [-0.5, -0.17, 0.17, 0.5]:
				ci.draw_circle(c + Vector2(sin(a2), 0.4) * r * 0.7, r * 0.16, col)
		"wp_melee":  # 근접 슬래시
			ci.draw_arc(c, r * 0.85, deg_to_rad(-60), deg_to_rad(60), 16, col, lw)
			ci.draw_line(c + Vector2(-r * 0.5, r * 0.5), c + Vector2(r * 0.5, -r * 0.5), col, lw)
		"speed", "dashcd":  # 이중 갈매기 »
			for dx: float in [-r * 0.35, r * 0.15]:
				ci.draw_polyline(PackedVector2Array([c + Vector2(dx, -r * 0.55), c + Vector2(dx + r * 0.5, 0), c + Vector2(dx, r * 0.55)]), col, lw)
		"bspeed":  # 빠른 화살
			_arrow(ci, c + Vector2(-r * 0.7, 0), c + Vector2(r * 0.75, 0), col, lw)
			ci.draw_line(c + Vector2(-r, -r * 0.4), c + Vector2(-r * 0.5, -r * 0.4), col, lw * 0.7)
			ci.draw_line(c + Vector2(-r, r * 0.4), c + Vector2(-r * 0.5, r * 0.4), col, lw * 0.7)
		"pierce":  # 관통 화살 + 표적
			ci.draw_arc(c, r * 0.5, 0, TAU, 20, col, lw * 0.7)
			_arrow(ci, c + Vector2(-r, r), c + Vector2(r, -r), col, lw)
		"multi", "l_echo":  # 세 발
			for off: Vector2 in [Vector2(0, -r * 0.5), Vector2(-r * 0.45, r * 0.35), Vector2(r * 0.45, r * 0.35)]:
				ci.draw_circle(c + off, r * 0.26, col)
		"hp", "heal", "heal_card", "m_immortal":  # 플러스(십자)
			var t: float = r * 0.28
			ci.draw_rect(Rect2(c.x - t, c.y - r * 0.72, t * 2.0, r * 1.44), col)
			ci.draw_rect(Rect2(c.x - r * 0.72, c.y - t, r * 1.44, t * 2.0), col)
		"gold_card":  # 금화 (겹동전)
			ci.draw_circle(c + Vector2(-r * 0.22, r * 0.12), r * 0.55, col.darkened(0.25))
			ci.draw_circle(c + Vector2(r * 0.18, -r * 0.12), r * 0.62, col)
			ci.draw_arc(c + Vector2(r * 0.18, -r * 0.12), r * 0.36, 0, TAU, 18, Color(0.25, 0.18, 0.05, 0.9), lw * 0.6)
		"regen", "c_allround":  # 링 안의 플러스
			ci.draw_arc(c, r * 0.8, 0, TAU, 22, col, lw)
			ci.draw_line(c + Vector2(0, -r * 0.42), c + Vector2(0, r * 0.42), col, lw)
			ci.draw_line(c + Vector2(-r * 0.42, 0), c + Vector2(r * 0.42, 0), col, lw)
		"armor", "c_ironwill":  # 방패
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.5), c + Vector2(r * 0.55, r * 0.55), c + Vector2(0, r), c + Vector2(-r * 0.55, r * 0.55), c + Vector2(-r * 0.8, -r * 0.5)]), col)
		"crit", "critdmg", "m_transcend":  # 별폭발(*)
			for i in 8:
				var a: float = TAU * float(i) / 8.0
				ci.draw_line(c, c + Vector2(cos(a), sin(a)) * r, col, lw * 0.8)
			ci.draw_circle(c, r * 0.22, col)
			if id == "critdmg":
				ci.draw_arc(c, r * 0.62, 0, TAU, 20, col, lw * 0.6)
		"magnet", "item_magnet":  # U 자석
			ci.draw_arc(c + Vector2(0, -r * 0.15), r * 0.62, deg_to_rad(160), deg_to_rad(380), 24, col, lw)
			ci.draw_line(c + Vector2(-r * 0.58, -r * 0.15), c + Vector2(-r * 0.58, r * 0.7), col, lw)
			ci.draw_line(c + Vector2(r * 0.58, -r * 0.15), c + Vector2(r * 0.58, r * 0.7), col, lw)
			ci.draw_line(c + Vector2(-r * 0.58, r * 0.5), c + Vector2(-r * 0.58, r * 0.7), Color("ff5a5a"), lw)
			ci.draw_line(c + Vector2(r * 0.58, r * 0.5), c + Vector2(r * 0.58, r * 0.7), Color("ff5a5a"), lw)
		"luck", "c_goldsense":  # 네잎클로버
			for off: Vector2 in [Vector2(0, -r * 0.4), Vector2(0, r * 0.4), Vector2(-r * 0.4, 0), Vector2(r * 0.4, 0)]:
				ci.draw_circle(c + off, r * 0.34, col)
		"gamble", "c_allin":  # 주사위
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.7, -r * 0.7), c + Vector2(r * 0.7, -r * 0.7), c + Vector2(r * 0.7, r * 0.7), c + Vector2(-r * 0.7, r * 0.7)]), col)
			for off: Vector2 in [Vector2(-r * 0.35, -r * 0.35), Vector2(r * 0.35, -r * 0.35), Vector2(0, 0), Vector2(-r * 0.35, r * 0.35), Vector2(r * 0.35, r * 0.35)]:
				ci.draw_circle(c + off, r * 0.11, Color("2a1030"))
		"freeze", "b_ice", "l_timewarp":  # 눈송이
			for i in 3:
				var a: float = PI * float(i) / 3.0
				var d: Vector2 = Vector2(cos(a), sin(a)) * r
				ci.draw_line(c - d, c + d, col, lw * 0.8)
			for i in 6:
				var a2: float = TAU * float(i) / 6.0
				var tip: Vector2 = c + Vector2(cos(a2), sin(a2)) * r
				ci.draw_line(tip, tip - Vector2(cos(a2), sin(a2)) * r * 0.32 + Vector2(-sin(a2), cos(a2)) * r * 0.25, col, lw * 0.6)
		"bigxp", "xp_gain":  # 큰 보석
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.85, 0), c + Vector2(0, r), c + Vector2(-r * 0.85, 0)]), col)
			ci.draw_line(c + Vector2(0, -r), c + Vector2(0, r), Color(0, 0, 0, 0.3), lw * 0.6)
			ci.draw_line(c + Vector2(-r * 0.85, 0), c + Vector2(r * 0.85, 0), Color(0, 0, 0, 0.3), lw * 0.6)
		"wpn_orb":  # 궤도 오브
			ci.draw_arc(c, r * 0.72, 0, TAU, 22, col, lw * 0.7)
			ci.draw_circle(c + Vector2(r * 0.72, 0), r * 0.26, col)
		"wpn_chain":  # 번개 사슬
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.2, -r), c + Vector2(-r * 0.35, r * 0.1), c + Vector2(r * 0.1, r * 0.1), c + Vector2(-r * 0.25, r)]), col, lw)
		"wpn_fire", "b_fire":  # 화염
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.55, r * 0.1), c + Vector2(r * 0.32, r * 0.7), c + Vector2(0, r), c + Vector2(-r * 0.32, r * 0.7), c + Vector2(-r * 0.55, r * 0.1)]), col)
		"wpn_ice":  # 눈송이
			for i in 3:
				var a: float = PI * float(i) / 3.0
				var d: Vector2 = Vector2(cos(a), sin(a)) * r
				ci.draw_line(c - d, c + d, col, lw * 0.8)
		"wpn_poison", "b_poison":  # 독방울
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.6, r * 0.35), c + Vector2(0, r), c + Vector2(-r * 0.6, r * 0.35)]), col)
			ci.draw_circle(c + Vector2(0, r * 0.25), r * 0.18, Color(0, 0, 0, 0.35))
		"wpn_summon", "summon_ice":  # 소환수(눈 달린 원)
			ci.draw_circle(c, r * 0.72, col)
			ci.draw_circle(c + Vector2(-r * 0.28, -r * 0.08), r * 0.15, Color(0.1, 0.1, 0.15))
			ci.draw_circle(c + Vector2(r * 0.28, -r * 0.08), r * 0.15, Color(0.1, 0.1, 0.15))
		"b_big", "l_giant":  # 큰 탄환 (링 안 굵은 점)
			ci.draw_arc(c, r * 0.85, 0, TAU, 22, col, lw * 0.7)
			ci.draw_circle(c, r * 0.45, col)
		"b_bounce":  # 튕김 (지그재그 반사)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r, -r * 0.5), c + Vector2(-r * 0.2, r * 0.5), c + Vector2(r * 0.4, -r * 0.5), c + Vector2(r, r * 0.4)]), col, lw)
			ci.draw_circle(c + Vector2(r, r * 0.4), r * 0.16, col)
		"b_chain":  # 연쇄 (분기하는 번개)
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.15, -r), c + Vector2(-r * 0.3, -r * 0.1), c + Vector2(r * 0.1, 0)]), col, lw)
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.1, 0), c + Vector2(-r * 0.35, r), c]), col, lw)
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.1, 0), c + Vector2(r * 0.7, r * 0.7)]), col, lw)
			ci.draw_circle(c + Vector2(-r * 0.35, r), r * 0.14, col)
			ci.draw_circle(c + Vector2(r * 0.7, r * 0.7), r * 0.14, col)
		"b_homing":  # 유도 (표적을 향해 휘는 화살)
			ci.draw_arc(c + Vector2(r * 0.35, r * 0.15), r * 0.32, 0, TAU, 18, col, lw * 0.7)
			ci.draw_circle(c + Vector2(r * 0.35, r * 0.15), r * 0.12, col)
			ci.draw_arc(c, r * 0.85, deg_to_rad(150), deg_to_rad(20), 16, col, lw)
			_arrow(ci, c + Vector2(-r * 0.2, -r * 0.62), c + Vector2(r * 0.05, -r * 0.2), col, lw * 0.85)
		"thorns":  # 가시 반사 (별 가시)
			for i in 8:
				var ta: float = TAU * float(i) / 8.0
				ci.draw_line(c + Vector2(cos(ta), sin(ta)) * r * 0.35, c + Vector2(cos(ta), sin(ta)) * r, col, lw * 0.8)
		"b_exec":  # 처형 (해골 낫 대신 큰 X)
			ci.draw_line(c + Vector2(-r * 0.7, -r * 0.7), c + Vector2(r * 0.7, r * 0.7), col, lw * 1.3)
			ci.draw_line(c + Vector2(r * 0.7, -r * 0.7), c + Vector2(-r * 0.7, r * 0.7), col, lw * 1.3)
			ci.draw_circle(c, r * 0.18, col)
		"b_vamp", "c_bloodlust":  # 흡혈 (핏방울 + 송곳니)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.6, r * 0.35), c + Vector2(0, r), c + Vector2(-r * 0.6, r * 0.35)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.28, r * 0.1), c + Vector2(-r * 0.1, r * 0.1), c + Vector2(-r * 0.19, r * 0.5)]), Color(1, 1, 1, 0.9))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.28, r * 0.1), c + Vector2(r * 0.1, r * 0.1), c + Vector2(r * 0.19, r * 0.5)]), Color(1, 1, 1, 0.9))
		"b_bloom":  # 폭발 개화 (방사 삼각 스타버스트)
			for i in 8:
				var ba: float = TAU * float(i) / 8.0
				var d2: Vector2 = Vector2(cos(ba), sin(ba))
				var pp: Vector2 = d2.orthogonal()
				ci.draw_colored_polygon(PackedVector2Array([c + d2 * r, c + d2 * r * 0.4 + pp * r * 0.16, c + d2 * r * 0.4 - pp * r * 0.16]), col)
			ci.draw_circle(c, r * 0.24, col)
		"wpn_whip":  # 채찍 (S자 채찍)
			var wp := PackedVector2Array()
			for i in 13:
				var t: float = float(i) / 12.0
				wp.append(c + Vector2(-r + 2.0 * r * t, sin(t * PI * 1.6) * r * 0.55))
			ci.draw_polyline(wp, col, lw)
			ci.draw_circle(c + Vector2(-r, 0), r * 0.2, col)  # 손잡이
		"wpn_boomerang":  # 부메랑 (V자)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, r * 0.5), c + Vector2(0, -r * 0.6), c + Vector2(r * 0.7, r * 0.5)]), col, lw * 1.2)
		"wpn_beam":  # 회전 레이저 (대각 빔 + 광점)
			ci.draw_line(c + Vector2(-r * 0.85, r * 0.85), c + Vector2(r * 0.85, -r * 0.85), col, lw * 1.2)
			ci.draw_circle(c, r * 0.22, Color(1, 1, 1, 0.95))
			ci.draw_circle(c + Vector2(r * 0.55, -r * 0.55), r * 0.13, col)
		"chest":  # 보물상자
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.1), c + Vector2(r * 0.8, -r * 0.1), c + Vector2(r * 0.8, r * 0.7), c + Vector2(-r * 0.8, r * 0.7)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.85, -r * 0.55), c + Vector2(r * 0.85, -r * 0.55), c + Vector2(r * 0.8, -r * 0.1), c + Vector2(-r * 0.8, -r * 0.1)]), col.darkened(0.15))
			ci.draw_rect(Rect2(c.x - r * 0.14, c.y - r * 0.28, r * 0.28, r * 0.42), Color(0.3, 0.2, 0.0))
		# ── 이면 무기 ──
		"wp_bow":  # 각궁 (활대 + 시위 + 화살)
			var bow := PackedVector2Array()
			for i in 11:
				var t: float = float(i) / 10.0
				var a: float = lerpf(-1.15, 1.15, t)
				bow.append(c + Vector2(cos(a) * r * 0.8 - r * 0.15, sin(a) * r * 0.9))
			ci.draw_polyline(bow, col, lw)
			ci.draw_line(c + Vector2(bow[0].x - c.x, -r * 0.82), c + Vector2(bow[0].x - c.x, r * 0.82), col.lightened(0.3), lw * 0.6)
			ci.draw_line(c + Vector2(-r * 0.55, 0), c + Vector2(r * 0.85, 0), Color(1, 1, 1, 0.95), lw * 0.7)
		"wp_fan":  # 태극 부채 (부채살 5개 + 호)
			for i in 5:
				var fa: float = lerpf(-1.05, 1.05, float(i) / 4.0) - PI * 0.5
				ci.draw_line(c + Vector2(0, r * 0.75), c + Vector2(0, r * 0.75) + Vector2(cos(fa), sin(fa)) * r * 1.35, col, lw * 0.7)
			var arc := PackedVector2Array()
			for i in 9:
				var aa: float = lerpf(-1.05, 1.05, float(i) / 8.0) - PI * 0.5
				arc.append(c + Vector2(0, r * 0.75) + Vector2(cos(aa), sin(aa)) * r * 1.35)
			ci.draw_polyline(arc, col.lightened(0.25), lw * 0.8)
		"wp_sinkal":  # 신칼 (교차한 두 자루 + 종이 술)
			ci.draw_line(c + Vector2(-r * 0.8, r * 0.8), c + Vector2(r * 0.8, -r * 0.8), col, lw)
			ci.draw_line(c + Vector2(r * 0.8, r * 0.8), c + Vector2(-r * 0.8, -r * 0.8), col, lw)
			ci.draw_circle(c, r * 0.2, Color(1, 1, 1, 0.9))
		"wp_jakdu":  # 작두 (두꺼운 날 + 받침)
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.9, -r * 0.15), c + Vector2(r * 0.85, -r * 0.55),
				c + Vector2(r * 0.85, -r * 0.1), c + Vector2(-r * 0.9, r * 0.15)]), col)
			ci.draw_rect(Rect2(c.x - r * 0.7, c.y + r * 0.35, r * 1.4, r * 0.35), col.darkened(0.35))
		_:
			# 장신구는 아직 전용 PNG 가 없을 수 있다 — 등급이 읽히는 마름모 + 중앙 보석으로 대체.
			if id.begins_with("acc_"):
				ci.draw_colored_polygon(PackedVector2Array([
					c + Vector2(0, -r * 0.9), c + Vector2(r * 0.7, 0),
					c + Vector2(0, r * 0.9), c + Vector2(-r * 0.7, 0)]), col.darkened(0.15))
				ci.draw_circle(c, r * 0.26, Color(1, 1, 1, 0.9))
			else:
				ci.draw_circle(c, r * 0.5, col)


static func _draw_star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a: float = -PI * 0.5 + PI * float(i) / 5.0
		var rr: float = r if i % 2 == 0 else r * 0.44
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)


static func _arrow(ci: CanvasItem, from: Vector2, to: Vector2, col: Color, w: float) -> void:
	ci.draw_line(from, to, col, w)
	var d: Vector2 = (to - from).normalized()
	var n: Vector2 = Vector2(-d.y, d.x)
	var h: float = w * 2.6
	ci.draw_line(to, to - d * h + n * h, col, w)
	ci.draw_line(to, to - d * h - n * h, col, w)
