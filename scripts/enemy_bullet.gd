class_name EnemyBullet
extends Area2D
## 적이 쏘는 탄막 — 플레이어에게 데미지.

const RADIUS: float = 6.0
const LIFETIME: float = 3.4
const MAX_DIST: float = 900.0  # 이 거리 이상 날아가면 소멸 — 화면 밖에서 떠도는 탄 제거

## ★ 동시 개수 상한. 예전엔 상한도 사거리 컬링도 없어서, 슈터가 많은 테마(던전/도서관)에서
##   수백 발이 상주하며 Area2D 브로드페이즈와 드로우를 함께 갉아먹었다.
static var live: int = 0

## 지금 한 발 더 쏴도 되는지. 넘치면 스폰 자체를 건너뛴다.
static func can_spawn() -> bool:
	return live < G.enemy_bullet_cap()

var _vel: Vector2 = Vector2.ZERO
var _dmg: float = 7.0
var _life: float = LIFETIME
var _homing: bool = false
var _home_time: float = 0.0
var _traveled: float = 0.0


func setup(vel: Vector2, dmg: float, homing: bool = false) -> void:
	_vel = vel
	_dmg = dmg
	_homing = homing
	if homing:
		_home_time = 2.0


func _exit_tree() -> void:
	live -= 1


func _ready() -> void:
	live += 1
	add_to_group("ebullet")  # 런 재시작 시 실제 개수를 다시 셀 수 있게
	collision_layer = 0
	collision_mask = 1 | 8  # 플레이어(1) + 지형 장애물(8) — 내 탄환처럼 적 탄환도 기물에 막힘 (S4 공정성)
	monitoring = true
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = RADIUS
	col.shape = cs
	add_child(col)
	# ★ 적탄은 죽는 이유 1순위인데(--balance 사망 로그) 가장 안 보이는 물건이었다.
	#   직선탄이 ff8a5c 주황인데 용암동굴 테마의 강조색이 ff5a3c 다 — 배경과 같은 색이다.
	#   테마가 무엇이든 읽히게 세 겹으로 짠다: 검은 테두리 → 색 몸통 → 흰 심지.
	#   층도 못박는다 (몹 0 < 내 탄 3 < 적 탄 5 < 영웅 6).
	z_index = 5
	var main_col: Color = Color("c77dff") if _homing else Color("ff5470")  # 유도탄=보라 / 직선=붉은 자홍
	var edge := Polygon2D.new()
	edge.polygon = G.regular_polygon(10, RADIUS + 2.2)
	edge.color = Color(0.03, 0.02, 0.05, 0.95)
	add_child(edge)
	var vis := Polygon2D.new()
	vis.polygon = G.regular_polygon(10, RADIUS)
	vis.color = main_col
	add_child(vis)
	var core := Polygon2D.new()
	core.polygon = G.regular_polygon(8, RADIUS * 0.42)
	core.color = Color(1, 1, 1, 0.92)
	add_child(core)
	var glow := Polygon2D.new()
	glow.polygon = G.regular_polygon(10, RADIUS + 5.0)
	glow.color = Color(main_col.r, main_col.g, main_col.b, 0.34)
	glow.z_index = -1
	add_child(glow)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if G.enemies_frozen():
		return
	if _homing and _home_time > 0.0 and G.player != null and is_instance_valid(G.player):
		_home_time -= delta
		var sp: float = _vel.length()
		var desired: Vector2 = ((G.player as Node2D).global_position - global_position).normalized() * sp
		_vel = _vel.lerp(desired, 2.2 * delta)
	var step: Vector2 = _vel * delta
	global_position += step
	_traveled += step.length()
	_life -= delta
	if _life <= 0.0 or _traveled > MAX_DIST:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Obstacle:  # 지형에 막혀 소멸 (플레이어와 동일 규칙)
		queue_free()
		return
	if body is Player:
		(body as Player).take_damage(_dmg, "적탄")
		queue_free()
