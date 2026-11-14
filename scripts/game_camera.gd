class_name GameCamera
extends Camera2D
## 플레이어 팔로우 + 트라우마 기반 스크린셰이크.

const MAX_OFFSET: Vector2 = Vector2(9, 9)  # 진동 대폭 축소 (사용자: 진동 과함)
const DECAY: float = 3.4
const FOLLOW: float = 0.001  # 작을수록 빠르게 따라붙음 (pow(FOLLOW, delta))

var trauma: float = 0.0
var _noise := FastNoiseLite.new()
var _t: float = 0.0


func _ready() -> void:
	make_current()
	_noise.frequency = 0.6
	_noise.seed = 12345
	zoom = Vector2.ONE * G.cam_zoom()  # 화면 확대 설정(S1) — 모바일 기본 확대로 캐릭터가 커 보임


func add_trauma(a: float) -> void:
	trauma = clampf(trauma + a, 0.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	if G.player != null and is_instance_valid(G.player):
		global_position = global_position.lerp((G.player as Node2D).global_position, 1.0 - pow(FOLLOW, delta))
	var s: float = trauma * trauma
	offset = Vector2(
		_noise.get_noise_2d(_t * 500.0, 0.0),
		_noise.get_noise_2d(0.0, _t * 500.0)
	) * MAX_OFFSET * s
	trauma = maxf(0.0, trauma - DECAY * delta)
