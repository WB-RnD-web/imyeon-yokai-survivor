class_name UiFont
extends RefCounted
## 게임 글꼴 — 갈무리(Galmuri, Lee Minseo, SIL OFL 1.1 · assets/fonts/galmuri/OFL.txt) 한 집안으로 (13차 6절 1).
## ★ 예전엔 메뉴 · 창 · 버튼이 매끈한 나눔고딕이고 숫자 · 큰 낱말만 도트라 "한 화면에 두 세계"였다(에셋 담당 13차 검토).
##
## 도트 글꼴은 **설계 픽셀의 정수배**로 그려야 계단이 고르다. 갈무리는 호수마다 설계 크기가 다르다
## (7호 8px · 9호 10px · 11호 12px · 14호 15px). 화면 기준(720) 크기를 아래 일곱 칸으로만 쓰면
## 1080 화면(×1.5)에서 인터페이스 크기 셋(×1 · ×4/3 · ×5/3, game.gd HUD_SCALES) 모두 정수배가 된다 —
## 예) 11호 24 → 1080 에서 36 · 48 · 60 = 12 의 3 · 4 · 5 배. 720 · 1440 화면의 기본 크기에서도 정수배다.
## 글꼴 가져오기는 안티에일리어싱 · 힌팅 · 서브픽셀 모두 끔(.import).
##
## 쓰는 법: 예전 `x.add_theme_font_size_override("font_size", n)` 자리에 `UiFont.apply(x, n)`.
## n 은 예전 크기 그대로 두면 가장 가까운 칸으로 맞춘다(13 → 16 · 18 → 20 · 26 → 24 · 52 → 48 …).

const DIR: String = "res://assets/fonts/galmuri/"
## (화면 기준 크기, 글꼴) — 위 설명의 일곱 칸
const STEPS: Array = [
	[16, "Galmuri7"], [20, "Galmuri9"], [24, "Galmuri11"], [30, "Galmuri14"],
	[40, "Galmuri9"], [48, "Galmuri11"], [60, "Galmuri14"],
]
## 예전 크기 → 칸. 이 값 이하면 그 칸이다.
const _UPTO: Array = [17, 21, 26, 34, 43, 53]

static var _fonts: Dictionary = {}


static func font(name: String) -> Font:
	if not _fonts.has(name):
		var p: String = DIR + name + ".woff"
		_fonts[name] = load(p) if ResourceLoader.exists(p) else null
	return _fonts[name]


## 예전 크기 n 을 칸 [크기, 글꼴 이름] 으로.
static func step(n: int) -> Array:
	if n < 18:
		n = 18      # 13차 4절: 폰 글자는 약 11pt(33px) 아래로 — 7호 16(화면 24px) 대신 9호 20(30px)부터
		#   11/5 스팀 피드백 3(「전체적으로 글씨가 작다」): PC 도 같은 규칙. 가장 작은 7호(설계 8px)는 1080 화면에서
		#   글자 높이가 18px 남짓이라 설명 줄 · 단추 글자가 작았다. 폰에서 이미 검사한 9호부터로 맞춘다.
	for i in _UPTO.size():
		if n <= int(_UPTO[i]):
			return STEPS[i]
	return STEPS[STEPS.size() - 1]


## 칸에 맞춘 크기만(직접 draw_string 하는 곳).
static func px(n: int) -> int:
	return int(step(n)[0])


## 칸에 맞춘 글꼴만.
static func font_for(n: int) -> Font:
	return font(String(step(n)[1]))


## 글꼴 + 크기를 같이 건다. 글꼴 파일이 없으면 크기만(예전처럼).
static func apply(c: Control, n: int) -> void:
	if c == null:
		return
	var st: Array = step(n)
	var f: Font = font(String(st[1]))
	if c is RichTextLabel:
		if f != null:
			c.add_theme_font_override("normal_font", f)
			c.add_theme_font_override("bold_font", f)
		c.add_theme_font_size_override("normal_font_size", int(st[0]))
		c.add_theme_font_size_override("bold_font_size", int(st[0]))
		return
	if f != null:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", int(st[0]))
