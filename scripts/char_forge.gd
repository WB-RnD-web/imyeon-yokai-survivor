class_name CharForge
## 캐릭터 에셋(charforge 배포본) 읽기.
##
## 서버 `survivor/<ID>/` 폴더를 **통째로** `res://assets/charforge/<ID>/` 에 넣으면 끝이다.
## 주문해서 받은 것(서버 `orders/imyeon/survivor/<번호>_<ID>/`)은 `res://assets/charforge/orders/` 아래에 같은 모양으로 둔다.
## 코드에 캐릭터를 하나씩 적지 않는다 — 폴더를 훑어서 읽는다.
##   sheets/<동작>.png + <동작>.json 한 쌍 = 애니메이션 하나
##   {"frame_w":46,"frame_h":46,"frames":4,"ms":[140,140,140,140]}
##   기준점은 발밑 가운데, 아래에서 2px 위 (공통_README §3)
##   px<키>/sheets/ = 같은 캐릭터를 다른 키로 다시 뽑은 판(졸개용 작은 판·강화 개체·크기 단계)
##   palette.json  = 인덱스 PNG 의 색 순서. {"transparent_index": 0, "palette": ["#000000", ...]}
##                   palette[0] 이 번호 1이다(0번 투명은 목록에 없다, 최대 15색). 모든 동작·모든 크기가 같은 번호를 쓴다.
##
## 게임의 어느 자리에 어느 캐릭터를 세우는지는 **cast.json 한 곳**에서 정한다.
##   {"heroes": {"rogue": {"id": "111_Cb803abf1", "h": 40}},
##    "enemies": {"0": {"id": "093_C0f0f5b2e", "h": 40, "mini": 28, "elite": 56}},
##    "pets": {"summon_ice": {"id": "", "h": 32}}}
##   h = 그 자리의 키(px). mini/elite = 졸개·갈라진 판과 강화 개체가 쓸 px 폴더. steps = 크기 단계.
##   값이 문자열 하나면 {"id": 그 값} 으로 읽는다(예전 형식).
## 여기 없거나 id 가 빈 자리는 예전 그림을 그대로 쓴다(되돌리기 = 줄 하나 지우기).
##
## sprites/ · preview/ 는 확인용이라 .gdignore 로 임포트에서 뺀다(폴더는 통째로 둔다).

const ROOT_DEFAULT: String = "res://assets/charforge/"
const CAST_DEFAULT: String = "res://assets/charforge/cast.json"
const ORDERS_DIR: String = "orders/"
## 재고 에셋의 게임 안 키. 주문분은 자기 키(cast 의 h, px 폴더 이름)로 뽑혀 온다.
const BASE_H: float = 40.0

## 검사 도구가 user:// 시험 폴더로 바꿔 끼운다. 평소엔 건드리지 않는다.
static var root: String = ROOT_DEFAULT
static var cast_path: String = CAST_DEFAULT

## 설정의 '캐릭터 그림: 기존' 으로 끄면 전 자리가 예전 그림으로 돌아간다(시범 비교용).
static var enabled: bool = true

static var _info: Dictionary = {}       # "id|key" -> {name, role, tier, native_h, anims: {동작: {tex, fw, fh, n, ms, len}}}
static var _cast: Dictionary = {}
static var _cast_loaded: bool = false
static var _ids: Array = []
static var _ids_loaded: bool = false
static var _keys: Dictionary = {}       # id -> [px 키...]
static var _pal: Dictionary = {}        # id -> Array[Color] (번호 1부터)
static var _idx_tex: Dictionary = {}    # "id|key|동작" -> ImageTexture (R = 팔레트 번호)
static var _idx_miss: Dictionary = {}   # id -> 팔레트에 없는 색이었던 픽셀 수
static var _pal_tex: Dictionary = {}    # 색 목록 문자열 -> ImageTexture (번호 → 색 한 줄)


## 캐시를 비운다(검사 도구가 시험 폴더로 바꿔 끼울 때).
static func reset_cache() -> void:
	_info.clear()
	_cast = {}
	_cast_loaded = false
	_ids = []
	_ids_loaded = false
	_keys.clear()
	_pal.clear()
	_idx_tex.clear()
	_idx_miss.clear()
	_pal_tex.clear()


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func _is_res(p: String) -> bool:
	return p.begins_with("res://")


## 폴더 안의 이름들. 하위 폴더는 끝에 "/" 를 붙인다.
## res:// 는 임포트 리맵을 아는 ResourceLoader 로(내보낸 빌드에서도 맞다), 시험 폴더(user://)는 DirAccess 로.
static func _list(dir: String) -> PackedStringArray:
	if _is_res(dir):
		return ResourceLoader.list_directory(dir)
	var out := PackedStringArray()
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for d in DirAccess.get_directories_at(dir):
		out.append(d + "/")
	for f in DirAccess.get_files_at(dir):
		out.append(f)
	return out


static func _has_png(p: String) -> bool:
	return ResourceLoader.exists(p) if _is_res(p) else FileAccess.file_exists(p)


static func _load_tex(p: String) -> Texture2D:
	if _is_res(p):
		return load(p) as Texture2D
	var img: Image = Image.load_from_file(p)
	return ImageTexture.create_from_image(img) if img != null else null


## 폴더에 들어 있는 캐릭터 ID 전부. sheets/anchor.json 이 있는 폴더만 캐릭터로 친다.
## 주문분은 "orders/<폴더>" 로 잡힌다.
static func ids() -> Array:
	if _ids_loaded:
		return _ids
	_ids_loaded = true
	_ids = []
	for base in ["", ORDERS_DIR]:
		for n in _list(root + base):
			if not n.ends_with("/"):
				continue
			var id: String = base + n.trim_suffix("/")
			if id + "/" == ORDERS_DIR:
				continue
			if FileAccess.file_exists(root + id + "/sheets/anchor.json"):
				_ids.append(id)
	_ids.sort()
	return _ids


static func has(id: String) -> bool:
	return id != "" and not info(id).is_empty()


## 그 캐릭터에 따로 뽑혀 온 크기(px<키>/ 폴더의 키) 목록.
static func keys(id: String) -> Array:
	if _keys.has(id):
		return _keys[id]
	var out: Array = []
	if id != "":
		for n in _list(root + id + "/"):
			if n.begins_with("px") and n.ends_with("/"):
				var k: String = n.trim_prefix("px").trim_suffix("/")
				if k.is_valid_int() and FileAccess.file_exists(root + id + "/" + n + "sheets/anchor.json"):
					out.append(int(k))
	out.sort()
	_keys[id] = out
	return out


static func _sheet_dir(id: String, key: int) -> String:
	return root + id + ("/px%d" % key if key > 0 else "") + "/sheets/"


## 캐릭터 한 명(그 키의 판)의 설계 메모와 시트 전부. 한 번 읽으면 캐시한다.
static func info(id: String, key: int = 0) -> Dictionary:
	if id == "":
		return {}
	var ck: String = "%s|%d" % [id, key]
	if _info.has(ck):
		return _info[ck]
	var out: Dictionary = {}
	var dir: String = _sheet_dir(id, key)
	if FileAccess.file_exists(dir + "anchor.json"):
		var dna: Variant = _read_json(root + id + "/dna.json")
		var d: Dictionary = dna if dna is Dictionary else {}
		out = {"id": id, "key": key, "name": String(d.get("name", id)), "role": String(d.get("role", "")),
			"tier": String(d.get("tier", "")), "anims": {}}
		for f in _list(dir):
			if not f.ends_with(".json"):
				continue
			var a: String = f.get_basename()
			var meta: Variant = _read_json(dir + f)
			var png: String = dir + a + ".png"
			if not (meta is Dictionary) or not _has_png(png):
				continue
			var m: Dictionary = meta
			var ms: Array = (m.get("ms", []) as Array).duplicate()
			_apply_skip(id, a, ms)
			var total: float = 0.0
			for v in ms:
				total += float(v) / 1000.0
			(out["anims"] as Dictionary)[a] = {
				"tex": _load_tex(png),
				"fw": int(m.get("frame_w", 0)), "fh": int(m.get("frame_h", 0)),
				"n": maxi(1, int(m.get("frames", 1))), "ms": ms, "len": total,
			}
		out["native_h"] = _native_h(id, key, d, out["anims"])
	_info[ck] = out
	return out


## 이 판이 몇 px 키로 뽑혔는가. 확대 배율은 자리 키 ÷ 이 값의 정수배로만 잡는다.
##   px<키>/ 폴더 → 그 키. 설계 메모에 키가 적혀 있으면 그 값.
##   주문분 → anchor 칸 높이 - 4 (위아래 여백 2px 씩). 주문분은 anchor 의 칠해진 높이가 주문 키 ±1px 이다(3차 지시서).
##   재고 → 이 장르의 키 40.
## 배역표 자리의 "skip": {"시트": [칸, …]} — 그 칸의 시간을 앞 칸(첫 칸이면 뒤 칸)에 넘기고 0 으로 만든다.
## 그림은 그대로 두고 화면에만 안 나오게 한다(7차: 고쳐 와도 남은 칸을 그 자리에서 정리할 때). 시간 0 인 칸은
## CreatureVisual 이 같은 프레임 안에서 넘긴다 — 한 번 재생(once)도, 대기(idle) 반복도.
static func _apply_skip(id: String, a: String, ms: Array) -> void:
	_load_cast()
	for grp in ["heroes", "enemies", "pets"]:
		for slot: Variant in (_cast.get(grp, {}) as Dictionary).values():
			if not (slot is Dictionary) or String((slot as Dictionary).get("id", "")) != id:
				continue
			var sk: Array = ((slot as Dictionary).get("skip", {}) as Dictionary).get(a, [])
			for v in sk:
				var i: int = int(v)
				if i < 0 or i >= ms.size() or ms.size() < 2:
					continue
				var to: int = i - 1 if i > 0 else i + 1
				ms[to] = float(ms[to]) + float(ms[i])
				ms[i] = 0


static func _native_h(id: String, key: int, dna: Dictionary, anims: Dictionary) -> float:
	if key > 0:
		return float(key)
	for f in ["sprite_h", "key", "height"]:
		if dna.has(f) and float(dna[f]) > 0.0:
			return float(dna[f])
	if id.begins_with(ORDERS_DIR) and anims.has("anchor"):
		return maxf(8.0, float((anims["anchor"] as Dictionary)["fh"]) - 4.0)
	return BASE_H


static func anim(id: String, a: String, key: int = 0) -> Dictionary:
	return (info(id, key).get("anims", {}) as Dictionary).get(a, {})


static func has_anim(id: String, a: String, key: int = 0) -> bool:
	return not anim(id, a, key).is_empty()


## 그 동작 한 칸을 잘라 준다(도감·선택 화면 같은 UI 용).
static func frame_tex(id: String, a: String, i: int = 0, key: int = 0) -> Texture2D:
	var an: Dictionary = anim(id, a, key)
	if an.is_empty():
		return null
	var at := AtlasTexture.new()
	at.atlas = an["tex"]
	var fi: int = clampi(i, 0, int(an["n"]) - 1)
	at.region = Rect2(fi * int(an["fw"]), 0, int(an["fw"]), int(an["fh"]))
	return at


## UI 용 그림 한 장 — 그 동작의 한 칸을 **정수배**로 키워 담은 칸.
## TextureRect 를 늘리는 대신 크기를 정확히 칸 × k 로 못박는다(소수 배율이면 도트가 뭉개진다).
static func figure(id: String, a: String, k: int, i: int = 0) -> Control:
	var tex: Texture2D = frame_tex(id, a, i)
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex == null:
		return tr
	var sz := Vector2(tex.get_width(), tex.get_height()) * float(maxi(1, k))
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = sz
	tr.size = sz
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


## 원하는 화면 키(target_h)에 가장 가까운 **정수 배율**(재고 키 40 기준, UI 용). 보간 확대는 하지 않는다.
static func scale_for(target_h: float) -> int:
	return maxi(1, roundi(target_h / BASE_H))


## 그 판을 자리 키(target_h)에 맞출 정수 배율. 판이 이미 그 키로 뽑혔으면 1.
## 작게는 못 줄인다(1 아래로 안 내려간다) — 작은 판이 필요하면 px 폴더로 받는다.
static func scale_to(id: String, key: int, target_h: float) -> int:
	var nh: float = float(info(id, key).get("native_h", BASE_H))
	return maxi(1, roundi(target_h / maxf(1.0, nh)))


static func _load_cast() -> void:
	if _cast_loaded:
		return
	_cast_loaded = true
	var c: Variant = _read_json(cast_path)
	_cast = c if c is Dictionary else {}


## 자리 한 줄을 {id, h, ...} 로 맞춰 준다(문자열 하나짜리 예전 형식도 받는다).
static func _slot(group: String, k: String) -> Dictionary:
	_load_cast()
	var v: Variant = (_cast.get(group, {}) as Dictionary).get(k, null)
	if v is String:
		return {"id": v}
	if v is Dictionary:
		return v
	return {}


## 그 자리에 쓸 캐릭터가 있으면 자리 정보, 없거나 꺼져 있으면 {}.
static func _live(group: String, k: String) -> Dictionary:
	if not enabled:
		return {}
	var s: Dictionary = _slot(group, k)
	return s if has(String(s.get("id", ""))) else {}


static func hero_slot(char_id: String) -> Dictionary:
	var sk: String = G.hero_skin(char_id)
	if sk != "":
		var s: Dictionary = _live("skins", char_id + "@" + sk)
		if not s.is_empty():
			return s
	return _live("heroes", char_id)


## 그 영웅의 그 차림 그림이 배역표에 있고 실제로 받아 둔 폴더가 있는가.
static func has_skin(char_id: String, skin: String) -> bool:
	return not _live("skins", char_id + "@" + skin).is_empty()


static func enemy_slot(kind: int) -> Dictionary:
	return _live("enemies", str(kind))


static func pet_slot(name: String) -> Dictionary:
	return _live("pets", name)


## 영웅 자리(characters.gd 의 id) → 캐릭터 ID. 없거나 꺼져 있으면 "".
static func hero_id(char_id: String) -> String:
	return String(hero_slot(char_id).get("id", ""))


## 적 자리(Enemy.kind) → 캐릭터 ID. 없거나 꺼져 있으면 "".
static func enemy_id(kind: int) -> String:
	return String(enemy_slot(kind).get("id", ""))


## 펫 자리(summon_green / summon_ice / summon_orb) → 캐릭터 ID.
static func pet_id(name: String) -> String:
	return String(pet_slot(name).get("id", ""))


## cast.json 전체(검사용).
static func cast() -> Dictionary:
	_load_cast()
	return _cast


## 펫(소환수) 그림. 배역표에 캐릭터가 있으면 시트로 그리고, 없으면 예전 한 장 그림.
## 시트로 그릴 땐 통통 튀기·기울이기를 걸면 안 된다(배율이 소수가 된다) — 받는 쪽이 is_cf() 로 가른다.
static func pet_art(name: String, fallback_path: String, radius: float) -> Node2D:
	var s: Dictionary = pet_slot(name)
	if not s.is_empty():
		var cv := CreatureVisual.new()
		cv.cf_id = String(s["id"])
		cv.cf_target_h = float(s.get("h", 0.0))
		cv.radius = radius
		cv.always_animate = true
		cv.build()
		if cv.is_cf():
			return cv
		cv.free()
	return Cutie.sprite(fallback_path, radius)


## ── 팔레트(인덱스 PNG) ──
## 서버는 인덱스 PNG 로 주지만 Godot 은 RGBA 로 가져온다. 그래서 palette.json 의 색 목록으로
## 색 → 번호를 되찾아 '번호 그림'(R 채널 = 번호)을 만들어 두고, 셰이더가 번호로 새 색을 찾는다.
## 같은 캐릭터의 모든 동작·모든 크기가 같은 번호를 쓰므로 색 목록 하나만 바꾸면 변종이 된다.

## 색 목록(번호 1부터). 없으면 [].
static func palette(id: String) -> Array:
	if _pal.has(id):
		return _pal[id]
	var out: Array = parse_palette(_read_json(root + id + "/palette.json"))
	_pal[id] = out
	return out


## palette.json 을 읽는다. 담당이 정한 모양(3차 지시서):
##   {"transparent_index": 0, "palette": ["#000000", "#202a77", ...]}  — palette[0] = 번호 1, 0번 투명은 목록에 없다.
##   이 모양이면 첫 항목이 검정이어도 그대로 번호 1이다.
## 확정 전에 쓰던 모양도 계속 받는다: ["#rrggbb", ...] · {"colors": [...]} · 항목 "#rrggbb(aa)" · [r,g,b(,a)] · {"hex": ...}
##   그때는 첫 항목이 투명(알파 0 · null · "transparent")이면 그게 0번이고, 아니면 목록이 1번부터다.
static func parse_palette(v: Variant) -> Array:
	var arr: Array = []
	var explicit: bool = false     # transparent_index 가 있으면 목록에 투명이 없다고 믿는다
	if v is Array:
		arr = v
	elif v is Dictionary:
		explicit = (v as Dictionary).has("transparent_index")
		for f in ["palette", "colors", "index", "entries"]:
			if (v as Dictionary).get(f, null) is Array:
				arr = (v as Dictionary)[f]
				break
	var cols: Array = []
	for e in arr:
		cols.append(_to_color(e))
	if not explicit and not cols.is_empty() and (cols[0] == null or (cols[0] as Color).a < 0.01):
		cols.remove_at(0)
	var out: Array = []
	for c in cols:
		if c != null:
			out.append(c)
	return out


static func _to_color(e: Variant) -> Variant:
	if e == null:
		return null
	if e is Dictionary:
		for f in ["hex", "color", "rgb", "rgba"]:
			if (e as Dictionary).has(f):
				return _to_color((e as Dictionary)[f])
		return null
	if e is String:
		var s: String = (e as String).strip_edges()
		if s == "" or s.to_lower() == "transparent":
			return Color(0, 0, 0, 0)
		return Color.html(s) if Color.html_is_valid(s) else null
	if e is Array and (e as Array).size() >= 3:
		var a: Array = e
		var al: float = float(a[3]) if a.size() >= 4 else 255.0
		return Color8(int(a[0]), int(a[1]), int(a[2]), int(al))
	return null


static func _rgb_key(r: int, g: int, b: int) -> int:
	return (r << 16) | (g << 8) | b


## 시트 한 장을 번호 그림으로 바꾼다. R = 팔레트 번호(1..n), A = 원래 알파(0 또는 255).
## 팔레트에 없는 색은 가장 가까운 번호로 넣고 개수를 센다(검사가 0 인지 본다).
static func index_image(id: String, src: Image, pal: Array) -> Image:
	var img: Image = src.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var lut: Dictionary = {}
	for i in pal.size():
		var c: Color = pal[i]
		lut[_rgb_key(c.r8, c.g8, c.b8)] = i + 1
	var buf: PackedByteArray = img.get_data()
	var miss: int = 0
	var i: int = 0
	while i < buf.size():
		if buf[i + 3] < 128:
			buf[i] = 0
			buf[i + 1] = 0
			buf[i + 2] = 0
			buf[i + 3] = 0
		else:
			var key: int = _rgb_key(buf[i], buf[i + 1], buf[i + 2])
			var n: int = int(lut.get(key, 0))
			if n == 0:
				miss += 1
				n = _nearest_index(buf[i], buf[i + 1], buf[i + 2], pal)
				lut[key] = n
			buf[i] = n
			buf[i + 1] = 0
			buf[i + 2] = 0
			buf[i + 3] = 255
		i += 4
	_idx_miss[id] = int(_idx_miss.get(id, 0)) + miss
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, buf)


static func _nearest_index(r: int, g: int, b: int, pal: Array) -> int:
	var best: int = 1
	var bd: int = 1 << 30
	for i in pal.size():
		var c: Color = pal[i]
		var d: int = absi(c.r8 - r) + absi(c.g8 - g) + absi(c.b8 - b)
		if d < bd:
			bd = d
			best = i + 1
	return best


## 그 동작의 번호 그림. 팔레트가 없으면 null.
static func index_tex(id: String, a: String, key: int = 0) -> Texture2D:
	var ck: String = "%s|%d|%s" % [id, key, a]
	if _idx_tex.has(ck):
		return _idx_tex[ck]
	var pal: Array = palette(id)
	var an: Dictionary = anim(id, a, key)
	if pal.is_empty() or an.is_empty() or an["tex"] == null:
		return null
	var src: Image = (an["tex"] as Texture2D).get_image()
	if src == null:
		return null
	var t := ImageTexture.create_from_image(index_image(id, src, pal))
	_idx_tex[ck] = t
	return t


## 번호 그림을 만드는 동안 팔레트에 없던 색 픽셀 수(검사용).
static func index_misses(id: String) -> int:
	return int(_idx_miss.get(id, 0))


## 번호 → 색 한 줄 텍스처. 0번은 투명, i 번째 칸 = 번호 i 의 색. 같은 목록이면 같은 텍스처를 돌려준다.
static func palette_texture(cols: Array) -> Texture2D:
	var parts: PackedStringArray = []
	for c in cols:
		parts.append((c as Color).to_html(false))
	var ck: String = ",".join(parts)
	if _pal_tex.has(ck):
		return _pal_tex[ck]
	var w: int = maxi(16, cols.size() + 1)
	var img := Image.create_empty(w, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in cols.size():
		img.set_pixel(i + 1, 0, cols[i])
	var t := ImageTexture.create_from_image(img)
	_pal_tex[ck] = t
	return t


## CPU 로 색을 바꾼 그림(검사·UI 미리보기용). 셰이더와 같은 규칙: 번호 i → new_cols[i-1].
static func recolor_image(id: String, a: String, new_cols: Array, key: int = 0) -> Image:
	var it: Texture2D = index_tex(id, a, key)
	if it == null:
		return null
	var img: Image = it.get_image()
	var buf: PackedByteArray = img.get_data()
	var i: int = 0
	while i < buf.size():
		if buf[i + 3] > 0:
			var n: int = buf[i]
			var c: Color = new_cols[n - 1] if n >= 1 and n <= new_cols.size() else Color.MAGENTA
			buf[i] = c.r8
			buf[i + 1] = c.g8
			buf[i + 2] = c.b8
		i += 4
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, buf)
