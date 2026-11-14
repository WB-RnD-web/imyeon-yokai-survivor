class_name FxLib
extends RefCounted
## 무기 이펙트 시트(에셋 담당 8차) — assets/fx/<무기>/sheets/<시트>.png + .json.
## 규격(7차 회신 3절): 그림 1px = 게임 1px · 오른쪽(→)을 보고 그림 · 기준점은 칸 가운데
## (총구 섬광만 칸 왼쪽 가운데) · body/bolt/trail 은 가로로 이어 붙이는 조각.
## 10차부터 UI 묶음도 같은 형식으로 읽는다 — 무기 이름 자리에 "ui/<묶음>"(assets/ui/<묶음>/sheets/...).
## 시트가 없거나 --fx=off 면 모든 함수가 null/false 를 돌려주고, 부르는 쪽은 예전 도형을 그린다.
## 그래서 한 장씩 빠져도 게임은 선다(회신 5절 "그 장만 지금 도형으로").

const ROOT: String = "res://assets/fx/"

## 휘두르기 시트는 몹 위에 0.2~0.3초 덮인다. 칼날·궤적이 불투명이라 그 사이 몹이 통째로 가려져서
## (8차 화면: 여의주·작두) 살짝 비치게 한다. 시트는 그대로, 게임이 입히는 값이다.
const SWING_ALPHA: float = 0.8

static var on: bool = true             # 하니스 --fx=off: 예전 도형(지금 ↔ 새 그림 비교 화면)
static var _sf: Dictionary = {}        # "무기/시트" -> SpriteFrames 또는 null(없음)
static var _meta: Dictionary = {}      # "무기/시트" -> {w, h, n, len(초), scale, tex}
static var _tiles: Dictionary = {}     # "무기/시트/칸" -> ImageTexture
static var _scaled: Dictionary = {}    # "무기/시트/칸/배" -> 정수배로 키운 ImageTexture(9조각용)


static func _k(wid: String, sheet: String) -> String:
	return wid + "/" + sheet


static func _load(wid: String, sheet: String) -> void:
	var k: String = _k(wid, sheet)
	if _sf.has(k):
		return
	_sf[k] = null
	var base: String = ("res://assets/" + wid if wid.begins_with("ui/") else ROOT + wid) + "/sheets/" + sheet
	if not ResourceLoader.exists(base + ".png") or not FileAccess.file_exists(base + ".json"):
		return
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	if not (j is Dictionary):
		return
	var tex := load(base + ".png") as Texture2D
	if tex == null:
		return
	var fw: int = int(j["frame_w"])
	var fh: int = int(j["frame_h"])
	var n: int = int(j["frames"])
	var ms: Array = j.get("ms", [])
	var sf := SpriteFrames.new()
	# 칸 시간 = ms. 초당 1000칸으로 두고 칸 길이를 ms 로 주면 그대로 ms 가 된다.
	for an: String in ["once", "loop"]:
		sf.add_animation(an)
		sf.set_animation_speed(an, 1000.0)
		sf.set_animation_loop(an, an == "loop")
	var total: float = 0.0
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		var d: float = maxf(1.0, float(ms[i]) if i < ms.size() else 80.0)
		total += d
		sf.add_frame("once", at, d)
		sf.add_frame("loop", at, d)
	_sf[k] = sf
	_meta[k] = {"w": fw, "h": fh, "n": n, "len": total / 1000.0, "scale": _scale_of(j.get("scale", 1.0)), "tex": tex, "json": j}


## 12차 F 부터 json scale 이 글("battle x2" · "UI x2")로 온다. 전투는 그 배수, UI 는 부르는 쪽이 정하니 1.
static func _scale_of(v: Variant) -> float:
	if v is String:
		var s: String = (v as String).strip_edges().to_lower()
		if s.begins_with("battle") and s.contains("x"):
			return maxf(1.0, s.get_slice("x", 1).to_float())
		return 1.0
	return float(v)


static func has(wid: String, sheet: String) -> bool:
	if not on or wid == "":
		return false
	_load(wid, sheet)
	return _sf[_k(wid, sheet)] != null


## {w, h, n, len, scale} — 없으면 빈 사전.
static func info(wid: String, sheet: String) -> Dictionary:
	return _meta.get(_k(wid, sheet), {}) if has(wid, sheet) else {}


## 시트 하나를 도는 스프라이트. loop=false 면 한 번 돌고 마지막 칸에서 멈춘다.
static func sprite(wid: String, sheet: String, loop: bool = true) -> AnimatedSprite2D:
	if not has(wid, sheet):
		return null
	var m: Dictionary = _meta[_k(wid, sheet)]
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _sf[_k(wid, sheet)]
	s.animation = "loop" if loop else "once"
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sc: float = float(m["scale"])
	s.scale = Vector2(sc, sc)
	var an: Variant = (m["json"] as Dictionary).get("anchor", null)
	if an is Array and (an as Array).size() == 2:
		# 기준점이 칸 가운데가 아닌 시트(12차 F 레벨업 기둥 = 발밑, 상자 = 바닥)
		s.centered = false
		s.offset = -Vector2(float(an[0]), float(an[1]))
	s.play()
	if loop and int(m["n"]) > 1:
		s.frame = randi() % int(m["n"])   # 같은 장판·탄이 한 박자로 깜빡이지 않게
	return s


## 총구 섬광처럼 칸 왼쪽 가운데가 기준점인 시트.
static func left_anchor(s: AnimatedSprite2D, wid: String, sheet: String) -> void:
	if s == null:
		return
	var m: Dictionary = info(wid, sheet)
	s.centered = false
	s.offset = Vector2(0.0, -float(m.get("h", 0)) * 0.5)


## 한 번 돌고 스스로 사라지는 이펙트. dur > 0 이면 시트 전체를 그 시간에 맞춰 늘이고 줄인다.
static func burst(parent: Node, pos: Vector2, wid: String, sheet: String, rot: float = 0.0,
		scl: float = 1.0, dur: float = -1.0, z: int = 20, flip_v: bool = false) -> AnimatedSprite2D:
	if parent == null:
		return null
	var s := sprite(wid, sheet, false)
	if s == null:
		return null
	s.rotation = rot
	s.scale *= scl
	if flip_v:
		s.scale.y = -s.scale.y
	s.z_index = z
	if dur > 0.0:
		s.speed_scale = float(info(wid, sheet)["len"]) / dur
	s.animation_finished.connect(s.queue_free)
	parent.add_child(s)
	s.global_position = pos
	return s


## 칸 하나를 따로 뗀 텍스처 — Line2D 반복(AtlasTexture 는 반복이 안 된다)과 파티클에 쓴다.
static func tile(wid: String, sheet: String, i: int) -> Texture2D:
	if not has(wid, sheet):
		return null
	var key: String = "%s/%d" % [_k(wid, sheet), i]
	if _tiles.has(key):
		return _tiles[key]
	var m: Dictionary = _meta[_k(wid, sheet)]
	var img: Image = (m["tex"] as Texture2D).get_image()
	if img == null:
		return null
	var fw: int = int(m["w"])
	var t := ImageTexture.create_from_image(img.get_region(Rect2i(clampi(i, 0, int(m["n"]) - 1) * fw, 0, fw, int(m["h"]))))
	_tiles[key] = t
	return t


## 이어 붙이는 조각(번개·잔광)을 a→b 로 깔고 dur 동안 칸을 넘기다 사라진다. a·b 는 parent 기준 좌표.
static func tile_line(parent: Node, a: Vector2, b: Vector2, wid: String, sheet: String,
		width: float = -1.0, dur: float = 0.2, z: int = 20) -> Line2D:
	if parent == null or not has(wid, sheet):
		return null
	var m: Dictionary = _meta[_k(wid, sheet)]
	var n: int = int(m["n"])
	var ln := tiled_line(wid, sheet, width)
	ln.points = PackedVector2Array([a, b])
	ln.z_index = z
	parent.add_child(ln)
	var tw := ln.create_tween()
	tw.tween_method(func(t: float) -> void:
		if is_instance_valid(ln):
			ln.texture = tile(wid, sheet, mini(n - 1, int(t * float(n)))), 0.0, 0.999, dur)
	tw.tween_callback(ln.queue_free)
	return ln


## 반복 텍스처를 깐 빈 Line2D. 점은 부르는 쪽이 넣는다(레이저처럼 계속 남는 것).
static func tiled_line(wid: String, sheet: String, width: float = -1.0) -> Line2D:
	var m: Dictionary = _meta.get(_k(wid, sheet), {})
	var ln := Line2D.new()
	ln.texture_mode = Line2D.LINE_TEXTURE_TILE
	ln.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ln.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ln.width = width if width > 0.0 else float(m.get("h", 8))
	ln.default_color = Color.WHITE
	ln.texture = tile(wid, sheet, 0)
	return ln


## 반복 시트를 시간에 맞춰 넘길 때 지금 칸 번호.
static func frame_at(wid: String, sheet: String, t: float) -> int:
	var m: Dictionary = info(wid, sheet)
	if m.is_empty():
		return 0
	var n: int = int(m["n"])
	return int(fposmod(t, float(m["len"])) / float(m["len"]) * float(n)) % n



## 시트의 json 그대로(advance · slice · tint · order · text …). 없으면 빈 사전.
static func json_of(wid: String, sheet: String) -> Dictionary:
	var m: Dictionary = info(wid, sheet)
	return m.get("json", {}) if not m.is_empty() else {}


## 영어로 켰는가 — 낱말 그림(_ko / _en)을 고른다.
static func lang_en() -> bool:
	return TranslationServer.get_locale().begins_with("en")


## 픽셀 글자 한 줄의 폭(그림 px). 글자는 칸 가운데에 있고 json 의 advance 가 칠한 폭이다 — 칠한 폭 + 1px 씩 붙인다.
static func text_width(wid: String, sheet: String, text: String) -> int:
	var j: Dictionary = json_of(wid, sheet)
	if j.is_empty():
		return 0
	var order: Array = j.get("order", [])
	var adv: Array = j.get("advance", [])
	var w: int = 0
	var n: int = 0
	for ch in text:
		var i: int = order.find(ch)
		if i < 0:
			w += 3   # 모르는 글자(공백 등)는 빈칸
		else:
			w += int(adv[i]) if i < adv.size() else int(j["frame_w"])
		n += 1
	return w + maxi(0, n - 1)


## ci 에 픽셀 글자를 그린다. pos = 왼쪽 위, px = 정수 배율. 색은 ci 의 modulate 로(흰 그림 · tint).
static func draw_text(ci: CanvasItem, pos: Vector2, text: String, wid: String, sheet: String, px: float) -> void:
	var m: Dictionary = info(wid, sheet)
	if m.is_empty():
		return
	var j: Dictionary = m["json"]
	var order: Array = j.get("order", [])
	var adv: Array = j.get("advance", [])
	var fw: int = int(m["w"])
	var fh: int = int(m["h"])
	var tex: Texture2D = m["tex"]
	var x: float = pos.x
	for ch in text:
		var i: int = order.find(ch)
		if i < 0:
			x += 4.0 * px
			continue
		var a: int = int(adv[i]) if i < adv.size() else fw
		var off: int = (fw - a) / 2
		ci.draw_texture_rect_region(tex, Rect2(x, pos.y, float(a) * px, float(fh) * px), Rect2(i * fw + off, 0, a, fh))
		x += float(a + 1) * px


## 1칸 시트(낱말 그림 · 틀)를 정수배로 키운 텍스처. NinePatchRect · StyleBoxTexture 는 텍스처 픽셀을 그대로
## 그리므로 미리 키워 넘긴다(nearest 로 늘려 도트가 고르다).
static func scaled(wid: String, sheet: String, i: int, px: int) -> Texture2D:
	var key: String = "%s/%d/%d" % [_k(wid, sheet), i, px]
	if _scaled.has(key):
		return _scaled[key]
	var t: Texture2D = tile(wid, sheet, i)
	if t == null:
		return null
	var img: Image = t.get_image()
	img.resize(img.get_width() * px, img.get_height() * px, Image.INTERPOLATE_NEAREST)
	var st := ImageTexture.create_from_image(img)
	_scaled[key] = st
	return st


## 낱말 그림 한 장을 UI 에 놓는 TextureRect(정수배). 없으면 null.
static func word_rect(sheet: String, px: int) -> TextureRect:
	var t: Texture2D = scaled("ui/text", sheet, 0, px)
	if t == null:
		return null
	var r := TextureRect.new()
	r.texture = t
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size = t.get_size()
	return r


## 한 · 영 낱말 시트 이름 — base_ko / base_en 이 있으면 언어에 맞춰, 없으면 base 그대로.
static func word_sheet(base: String) -> String:
	var s2: String = base + ("_en" if lang_en() else "_ko")
	return s2 if has("ui/text", s2) else base


## 낱말 그림 + 숫자를 한 줄로(배너 · 콤보). parts: "w_wave" 같은 시트 이름 또는 "#12" 같은 숫자.
## 숫자는 num 을 num_tint 로 칠한다. 하나라도 없으면 null — 부르는 쪽이 글꼴로 그린다.
## num_sheet: 숫자 시트. 배너는 낱말과 같은 높이 16 · 금빛 세 단인 num_big(색이 그려져 있어 칠하지 않는다, 11차),
## 콤보는 num(흰 그림 × num_tint). num_px > 0 이면 숫자만 그 배율 — num_big 이 없을 때 num 을 3배로 맞추던 길.
static func pixel_row(parts: Array, px: int, num_tint: Color, num_px: int = 0, num_sheet: String = "num") -> HBoxContainer:
	if num_sheet != "num" and not has("ui/text", num_sheet):
		num_sheet = "num"
	elif num_sheet != "num":
		num_px = 0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4 * px)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pt in parts:
		var p2: String = String(pt)
		if p2.begins_with("#"):
			if not has("ui/text", "num"):
				row.free()
				return null
			var pn := PixelText.new()
			pn.sheet = num_sheet
			pn.px = float(num_px if num_px > 0 else px)
			pn.text = p2.substr(1)
			if bool(json_of("ui/text", num_sheet).get("tint", true)):   # 흰 그림(num)만 칠한다 — num_big 은 금빛이 그려져 있다
				pn.modulate = num_tint
			pn.size_flags_vertical = Control.SIZE_SHRINK_END
			row.add_child(pn)
		else:
			var wr := word_rect(p2, px)
			if wr == null:
				row.free()
				return null
			wr.size_flags_vertical = Control.SIZE_SHRINK_END
			row.add_child(wr)
	return row
