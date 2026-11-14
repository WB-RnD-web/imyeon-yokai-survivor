extends Node
## 보상형 전면 광고 — AdMob 광고 단위 "죽었을때 부활"
##
## poingstudios/godot-admob-plugin (Godot 4.2+) 위에서 돈다.
##
## ★ 이 파일의 제1원칙: 광고가 없어도 게임은 멀쩡해야 한다.
##   플러그인 미설치(데스크톱·웹·헤드리스 하니스), 초기화 실패, 네트워크 없음 —
##   어느 경우든 available() 이 false 가 되고 부활 제안 자체가 안 뜬다.
##
## ★ 플러그인 클래스 이름을 코드에 '직접' 쓰면 안 된다.
##   GDScript 는 class_name 을 파싱 시점에 해석하므로, 플러그인이 없는 환경에서
##   RewardedInterstitialAdLoader 를 그냥 쓰면 스크립트가 통째로 파싱 실패한다
##   (= 게임이 안 켜진다). 그래서 _find_class() 로 런타임에 찾아 쓴다.

signal reward_earned    ## 끝까지 봐서 보상 획득 — 부활시켜도 되는 유일한 신호
signal ad_finished      ## 성공/실패/닫힘 무관하게 광고 흐름 종료 (UI 잠금 해제용)

## AdMob 광고 단위 — 보상형 전면 광고 "죽었을때 부활"
const AD_UNIT_RELEASE := ""  # 공개판은 광고가 없다. 안드로이드 출시판에서만 실제 ID 를 넣는다
## 구글 공식 테스트 단위. ★ 개발 중엔 반드시 이걸 써야 한다.
## 자기 앱 광고를 직접 누르면 무효 트래픽으로 AdMob 계정이 정지된다.
const AD_UNIT_TEST := "ca-app-pub-3940256099942544/5354046379"

var _ad: Object = null          # 로드된 RewardedInterstitialAd
var _loading: bool = false
var _init_ok: bool = false
var _showing: bool = false
## ★ 멤버여야 한다. GDScript 람다는 바깥 지역변수를 '값으로' 캡처하므로,
##   지역 var earned 에 콜백이 true 를 써도 다른 콜백은 영원히 false 를 본다.
##   (보상을 받아도 부활이 안 되는 버그였다)
var _earned: bool = false

## 광고에 필요한 플러그인 클래스 전부. 하나라도 없으면 광고 없이 간다.
const NEEDED := [
	"MobileAds",
	"AdRequest",
	"RewardedInterstitialAdLoader",
	"RewardedInterstitialAdLoadCallback",
	"FullScreenContentCallback",
	"OnUserEarnedRewardListener",
	"OnInitializationCompleteListener",
]


func _ready() -> void:
	# 헤드리스(CLI 하니스)에서는 광고 자체를 건드리지 않는다 — 검증 스크립트가 광고를 기다리면 안 된다
	if DisplayServer.get_name() == "headless":
		return
	# ★ 플랫폼으로 막지 않는다. 플러그인은 에디터에서 Mock 광고를 띄워 주므로
	#   (MobileSingletonPlugin._get_plugin → OS.has_feature("editor") 면 mock 반환)
	#   데스크톱 F5 로도 부활 흐름을 그대로 테스트할 수 있다.
	var missing: Array[String] = []
	for cname: String in NEEDED:
		if _find_class(cname) == null:
			missing.append(cname)
	if not missing.is_empty():
		if OS.is_debug_build():
			push_warning("[Ads] 비활성 — 플러그인 클래스 없음: %s (AdMob 애드온 설치/활성 확인)" % ", ".join(missing))
		return
	# ★ MobileAds 는 오토로드가 아니라 static 함수만 있는 class_name 클래스다.
	#   get_node_or_null("/root/MobileAds") 로 찾으면 항상 null 이라 광고가 영영 안 떴다.
	var mobile_ads: Script = _find_class("MobileAds")

	# ★★ initialize() 는 비동기다. 바로 다음 줄에서 광고를 로드하면 네이티브가
	#     java.lang.IllegalStateException:
	#       "MobileAds.initialize must be called before using the Google Mobile Ads SDK"
	#     을 던지고 **앱이 통째로 죽는다**(실기기에서 직접 밟음. 에디터 Mock 은 즉시
	#     완료돼서 안 잡힌다 — 데스크톱에서 멀쩡하다고 안심하면 안 되는 부분).
	#     반드시 완료 콜백을 받은 뒤에 로드한다.
	var init_listener: Object = _make("OnInitializationCompleteListener")
	if init_listener == null:
		return
	init_listener.set("on_initialization_complete", func(_status: Variant) -> void:
		_init_ok = true
		if OS.is_debug_build():
			print("[Ads] SDK 초기화 완료 — 단위 %s" % unit_id())
		preload_ad())
	mobile_ads.call("initialize", init_listener)
	if OS.is_debug_build():
		print("[Ads] SDK 초기화 요청 — 완료 콜백 대기")


## 부활 제안을 띄워도 되는가. 광고가 실제로 손에 들려 있을 때만 true.
func available() -> bool:
	return _init_ok and _ad != null and not _showing


func unit_id() -> String:
	return AD_UNIT_TEST if OS.is_debug_build() else AD_UNIT_RELEASE


## class_name 으로 등록된 GDScript 클래스를 런타임에 찾는다.
## 플러그인이 없으면 null — 파싱 에러가 아니라 그냥 '없음'이 된다.
func _find_class(cname: String) -> Script:
	for c: Dictionary in ProjectSettings.get_global_class_list():
		if String(c.get("class", "")) == cname:
			var s: Resource = load(String(c.get("path", "")))
			return s as Script
	return null


func _make(cname: String) -> Object:
	var s: Script = _find_class(cname)
	if s == null:
		return null
	return s.new()


## 다음 부활용 광고를 미리 받아 둔다. 판 시작·부활 소진 직후에 부른다.
func preload_ad() -> void:
	if not _init_ok or _loading or _ad != null:
		return
	var loader: Object = _make("RewardedInterstitialAdLoader")
	var req: Object = _make("AdRequest")
	var cb: Object = _make("RewardedInterstitialAdLoadCallback")
	if loader == null or req == null or cb == null:
		_init_ok = false  # 플러그인 API 가 예상과 다름 — 광고 없이 간다
		return
	cb.set("on_ad_loaded", func(ad: Object) -> void:
		_ad = ad
		_loading = false
		if OS.is_debug_build():
			print("[Ads] 부활 광고 준비됨"))
	cb.set("on_ad_failed_to_load", func(err: Variant) -> void:
		_ad = null
		_loading = false
		if OS.is_debug_build():
			push_warning("[Ads] 광고 로드 실패: %s" % str(err)))
	_loading = true
	loader.call("load", unit_id(), req, cb)


## 부활 광고를 띄운다. 끝까지 보면 reward_earned, 어떤 식으로든 끝나면 ad_finished.
func show_revive_ad() -> void:
	if not available():
		ad_finished.emit()
		return
	_showing = true
	_earned = false

	# 전체화면 콜백 — 닫힘/실패를 잡아 UI 잠금을 반드시 푼다
	var fs: Object = _make("FullScreenContentCallback")
	if fs != null:
		# 종료 콜백도 같은 이유로 지연 실행한다 (위 주석 참고)
		fs.set("on_ad_dismissed_full_screen_content", func() -> void:
			_finish.call_deferred())
		fs.set("on_ad_failed_to_show_full_screen_content", func(_e: Variant) -> void:
			_finish.call_deferred())
		_ad.set("full_screen_content_callback", fs)

	var listener: Object = _make("OnUserEarnedRewardListener")
	if listener != null:
		listener.set("on_user_earned_reward", func(_reward: Variant) -> void:
			_earned = true
			# ★★ 이 콜백은 안드로이드 UI/JNI 스레드에서 온다.
			#     플러그인이 보상·종료 콜백에는 CONNECT_DEFERRED 를 안 붙였다
			#     (로드 콜백에만 붙어 있다). 여기서 곧바로 게임 상태를 건드리면
			#     렌더 스레드가 프레임을 그리는 도중에 노드를 지우게 되어
			#     "FORTIFY: pthread_mutex_lock called on a destroyed mutex" 로
			#     네이티브 크래시가 난다. 실기기에서 직접 밟았다.
			#     반드시 call_deferred 로 Godot 메인 스레드에 넘길 것.
			reward_earned.emit.call_deferred())

	_ad.call("show", listener)

	# 콜백을 못 붙였으면(=API 불일치) 영원히 매달리지 않도록 안전망
	if fs == null:
		await get_tree().create_timer(1.5).timeout
		_finish()


func _finish() -> void:
	if not _showing:
		return
	_showing = false
	_earned = false
	_ad = null          # 보상형 광고는 1회용 — 반드시 버리고 다시 받는다
	ad_finished.emit()  # 보상 여부는 reward_earned 를 쐈는지로 이미 전달됐다
	preload_ad()        # 다음 판을 위해 미리 받아 둔다
