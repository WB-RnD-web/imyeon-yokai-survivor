class_name DamageNumber
extends Node2D
## 데미지 숫자 팝업 — 위로 튀며 사라짐.

static var _active: int = 0
## 13차 4절: 같은 적 · 같은 종류 숫자가 0.2초 안에 또 나오면 새로 띄우지 않고 그 숫자에 더한다.
## ★ 예전엔 탄 여러 발이 한 프레임에 맞으면 같은 자리에 숫자가 겹쳐 「2̶0」「1̶8」처럼 읽혔다(에셋 담당 13차 검토, 사진 다섯 장 모두).
##   종류가 다른 숫자(직격 · 치명 · 지속 · 반응)가 같은 적에 동시에 뜨면 한 줄씩 위로 쌓는다.
const MERGE_MS: int = 200
const STACK_DY: float = 30.0      # 14차: 22 였다 — 치명 숫자(키 26)가 아래 숫자에 겹쳤다
const STACK_MS: int = 550         # 숫자가 떠 있는 동안(0.5초)은 같은 적의 새 숫자를 한 줄 위로
static var _live: Dictionary = {}     # "적 id:종류" -> DamageNumber (합치는 창 안)
static var _stack: Dictionary = {}    # 적 id -> [마지막 시각 ms, 쌓인 줄 수]
## 14차: 몹이 몰리면 서로 다른 적의 숫자가 한 덩어리로 겹쳤다(12분 · 몹 180 화면).
## ★ 처음엔 화면을 칸(28×22, 다음엔 72×30)으로 나눠 칸마다 하나만 띄웠는데, 칸 경계 양쪽에 붙은 두 숫자는
##   몇 px 떨어져 있어도 다른 칸이라 그대로 겹쳤다. 이제 떠 있는 숫자 자리를 직접 잰다.
##   숫자는 0.5초 동안 42px 떠오르므로, 새 숫자가 옛 숫자보다 위쪽 띠(64px) 안이면 언젠가 지나가며 겹친다 — 그 띠까지 막는다.
##   막히면 치명 · 반응만 한 줄 위를 한 번 더 보고, 나머지는 띄우지 않는다.
static var _recent: Array = []        # [월드 자리, 시각 ms]
const NUM_W: float = 62.0             # 세 자리 숫자 폭(팝 1.25배 · 좌우 흔들림 포함)
const NUM_H: float = 22.0
const RISE_BAND: float = 64.0
const LIVE_MS: int = 1000          # 0.5초 떠오른 뒤 0.22초 머물고 0.28초 사라진다 — 사라질 때까지 자리를 잡아 둔다


static func _hits(p: Vector2, now: int) -> bool:
	while not _recent.is_empty() and now - int(_recent[0][1]) > LIVE_MS:
		_recent.pop_front()
	for r in _recent:
		var d: Vector2 = p - (r[0] as Vector2)
		if absf(d.x) < NUM_W and d.y > -RISE_BAND and d.y < NUM_H:
			return true
	return false

var _key: String = ""
var _value: int = 0
var _style: int = 0
var _born: int = 0
var _vis: CanvasItem = null


## 숫자 종류 — 직격/치명/지속피해/원소반응을 눈으로 구분한다.
## ★ 예전엔 지속피해와 원소반응까지 crit=true 로 띄워서, 화염을 들면 화면이 온통
##   커다란 주황 "숫자!" 로 덮였다. 정작 직격 숫자가 그 밑에 묻혀서
##   "다른 데미지가 눌리는 느낌"이 된다(실플레이 리포트).
enum { HIT, CRIT, DOT, REACT }

static func spawn(parent: Node, pos: Vector2, value: int, crit: bool = false, key: int = 0) -> void:
	spawn_as(parent, pos, value, CRIT if crit else HIT, Color(0, 0, 0, 0), key)


## key = 맞은 적(인스턴스 id). 0 이면 합치지 않는다.
static func spawn_as(parent: Node, pos: Vector2, value: int, style: int, tint: Color = Color(0, 0, 0, 0), key: int = 0) -> void:
	if not G.show_dmgnum or G.dmgnum_mode == 2:
		return    # 설정 · 화면 「피해 숫자」 끄기
	if G.dmgnum_mode == 1 and not (style == CRIT or style == REACT):
		return    # 19차 3절 1: 「큰 것만」 — 치명타와 원소반응만(직격 · 지속피해 숫자가 후반 화면을 덮었다)
	# ★ 예전엔 crit 이면 상한을 통째로 우회했는데, 화상 DoT·원소반응이 항상 crit=true 로 부르고
	#   치명타율도 후반엔 70~100% 라 사실상 상한이 없었다. 적 150마리가 화상이면 초당 375개의
	#   Label + 트윈이 생성됐다 — '몬스터가 많아질수록 점점 심해진다'의 직접 원인.
	#   지금은 크리티컬도 상한을 지키되, 상한의 1.4배까지만 우선권을 준다.
	if value <= 0:
		return  # ★ 0 은 띄우지 않는다. 지속피해 한 틱이 1 미만이면 int() 가 0 이 되어
		#          화면에 "0" 이 끝없이 뜨고, 진짜 피해가 그 사이에 묻힌다(유저 보고).
	# 14차 2절 8: 위 HUD 띠(경험치 · 칸 · 타이머 · 보스 막대 · 이름) 자리에는 띄우지 않는다. 숫자는 떠오르므로 30 여유.
	if G.num_block_y > 0.0 and parent is CanvasItem:
		var sp: Vector2 = (parent as CanvasItem).get_viewport().get_canvas_transform() * pos
		if sp.y < G.num_block_y + 30.0:
			return
	var cap: int = G.dmgnum_cap()
	# 지속피해는 상한을 더 빡빡하게 — 적 150마리가 화상이면 이것만으로 화면이 찬다
	var lim: int = cap
	if style == CRIT:
		lim = int(cap * 1.4)
	elif style == DOT:
		lim = int(cap * 0.7)
	var now: int = Time.get_ticks_msec()
	var k2: String = ""
	if key != 0:
		k2 = "%d:%d" % [key, style]
		var ex: Variant = _live.get(k2, null)
		if ex != null and is_instance_valid(ex) and now - (ex as DamageNumber)._born < MERGE_MS:
			(ex as DamageNumber)._add(value)
			return
	if _active > lim:
		return
	if key != 0:
		# 같은 적에 다른 종류 숫자가 막 떠 있으면 한 줄 위로
		var st: Array = _stack.get(key, [0, 0])
		var n: int = (int(st[1]) + 1) % 4 if now - int(st[0]) < STACK_MS else 0
		pos.y -= STACK_DY * float(n)
		if _hits(pos, now):
			if style != CRIT and style != REACT:
				return
			pos.y -= STACK_DY
			if _hits(pos, now):
				return
		_stack[key] = [now, n]
	elif _hits(pos, now):
		return
	_recent.append([pos, now])
	var dn := DamageNumber.new()
	dn.global_position = pos
	if key != 0:
		dn._key = k2
		_live[k2] = dn
		if _live.size() > 256:      # 사라진 적의 칸이 남지 않게 가끔 비운다
			_live.clear()
			_stack.clear()
			_live[k2] = dn
	dn._born = now
	parent.add_child(dn)
	dn._show(value, style, tint)


func _exit_tree() -> void:
	_active -= 1
	if _key != "" and _live.get(_key, null) == self:
		_live.erase(_key)


static func _txt(value: int, style: int) -> String:
	match style:
		CRIT:
			return "%d!" % value
		REACT:
			return "%d✦" % value
	return str(value)


## 합치기 — 숫자를 바꾸고 한 번 더 톡 튄다.
func _add(v: int) -> void:
	_value += v
	if _vis is PixelText:
		var pt := _vis as PixelText
		pt.text = _txt(_value, _style)
		pt.position = (-pt.size * 0.5).round()
	elif _vis is Label:
		(_vis as Label).text = _txt(_value, _style)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.18, 1.18), 0.05)
	tw.tween_property(self, "scale", Vector2.ONE, 0.07)


func _show(value: int, style: int, tint: Color = Color(0, 0, 0, 0)) -> void:
	_active += 1
	_value = value
	_style = style
	var crit: bool = style == CRIT
	var txt: String = str(value)
	var size: int = 22
	var col := Color("fff2a8")
	var pop: float = 1.25
	var rise: float = 42.0
	match style:
		CRIT:
			# ★ 2026-09-15: 34 × pop 1.55 = 화면에서 53px 다. 몹 스프라이트가 30px 인데
			#   숫자가 그 두 배로 뜬다 — 스크린샷에서 몹 무리가 통째로 숫자에 덮였다.
			#   치명타를 구분하는 몫은 색·기울기·테두리로도 충분하다.
			txt = "%d!" % value
			size = 27
			col = Color("ff6a2e")
			pop = 1.4
		DOT:  # 지속피해
			# ★ 2026-09-15: 15px · 알파 0.72 · 상한 0.45배였다. 직격 숫자를 안 가리려는
			#   의도였는데 그 결과가 "독 데미지가 얼마나 뜨는지 눈에 거의 안 보인다"였다
			#   (실플레이 리포트). 지속피해가 총피해의 20~30%를 차지하는 빌드에서
			#   그 몫이 화면에 아예 안 나오면 무기를 고를 근거가 사라진다.
			#   여전히 직격보다는 작게 두되, 읽히기는 해야 한다.
			size = 19
			col = tint if tint.a > 0.0 else Color("ff9a5c")
			col.a = 0.95
			pop = 1.08
			rise = 30.0
		REACT:  # 원소반응: 중간 크기 + 반응 색 + 별표 (치명타와 헷갈리지 않게)
			txt = "%d✦" % value
			size = 25
			col = tint if tint.a > 0.0 else Color("9fe8ff")
			pop = 1.3
	# 10차 A: 픽셀 숫자(num · num_crit). 흰 num 에 지금 색을 곱하고, 치명타는 색이 그려진 num_crit.
	# 그림 1px = 게임 2px(정수배). 시트가 없으면 아래 글꼴 라벨.
	if FxLib.has("ui/text", "num"):
		var pt := PixelText.new()
		pt.sheet = "num_crit" if crit and FxLib.has("ui/text", "num_crit") else "num"
		pt.px = 2.0
		pt.text = txt
		if pt.sheet == "num":
			pt.modulate = col
		pt.position = (-pt.size * 0.5).round()
		add_child(pt)
		_vis = pt
		_anim(pt, crit, style, pop, rise)
		return
	var lbl := Label.new()
	lbl.text = txt
	UiFont.apply(lbl, size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 6 if crit else (3 if style == DOT else 5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-24, -14)
	lbl.custom_minimum_size = Vector2(48, 0)
	add_child(lbl)
	_vis = lbl
	_anim(lbl, crit, style, pop, rise)


func _anim(lbl: CanvasItem, crit: bool, style: int, pop: float, rise: float) -> void:
	if crit and not (lbl is PixelText):  # 크리티컬: 살짝 기울어진 채 크게 팡 (도트는 돌리면 계단이 생겨 안 돌린다)
		rotation = randf_range(-0.12, 0.12)
	z_index = 70 if crit else (50 if style == REACT else 30)  # 직격/치명이 항상 위로
	var dx: float = randf_range(-14.0, 14.0)
	var tw := create_tween()
	tw.tween_property(self, "position", position + Vector2(dx, -rise), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2(pop, pop), 0.12)
	tw.chain().tween_property(self, "scale", Vector2.ONE, 0.1)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.28).set_delay(0.22)
	tw.tween_callback(queue_free)
