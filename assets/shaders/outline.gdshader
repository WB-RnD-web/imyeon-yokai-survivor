shader_type canvas_item;

// 픽셀 스프라이트 테두리. 알파가 빈 자리에서 이웃 여덟 방향을 훑어
// 하나라도 그림이 있으면 어두운 색을 찍는다 — 실루엣을 따라가는 1~2px 윤곽선.
//
// ★ 가로 스트립(hframes>1) 주의: Sprite2D 는 UV 를 텍스처 전체 기준으로 준다.
//   그냥 이웃을 훑으면 프레임 경계에서 옆 칸 그림을 끌어와 유령 테두리가 생긴다.
//   UV.x 로 지금 몇 번째 칸인지 되짚어 그 칸 안으로만 훑는다.
//
// ★ TEXTURE 를 함수 인자로 넘기면 안 된다(shader_compiler 가 custom_samplers 에서 걸린다).
//   샘플링은 전부 fragment 안에 펼쳐 둔다.
//
// ★★ canvas_item 셰이더에서 **COLOR 는 들어올 때 이미 `텍스처 × modulate` 다.**
//    이걸 '모듈레이트만'으로 착각해서 두 가지를 동시에 틀렸다(2026-09-15):
//      1) 투명한 자리에서 COLOR.a 가 0 이라, 테두리 알파에 그걸 곱하면 **항상 0** 이었다.
//         → 테두리가 한 번도 그려진 적이 없다. 계산은 맞았는데(이웃 알파 판정 OK) 안 보였다.
//      2) 불투명한 자리에서 `col * COLOR` 는 텍스처를 **두 번** 곱한다. 스프라이트가
//         제 색보다 어두워지고, lift 로 끌어올린 만큼 도로 눌렸다.
//    그래서 modulate 를 **vertex 단계에서 따로 받아** varying 으로 넘긴다.
//    (vertex 의 COLOR 는 텍스처가 안 곱해진 순수 modulate 다. MODULATE 내장은 이 버전에 없다.)
uniform vec4 line_color : source_color = vec4(0.03, 0.02, 0.05, 1.0);
uniform float line_px : hint_range(0.0, 8.0) = 1.0;  // 텍셀 단위 두께
uniform int hframes = 1;
uniform bool diagonal = true;  // 대각선까지 = 계단이 덜 보인다. 절전에서는 끈다(샘플 9→5).

// 안쪽 테두리(림라이트). 어두운 바깥선만으로는 **유닛 안쪽**이 배경과 같은 색인 문제가
// 그대로 남는다 — 갈색 몹 + 갈색 도서관 바닥은 ΔE 3~9 로 사실상 같은 색이다(contrast_qa.py).
// 실루엣 가장자리 한 겹을 제 색에서 밝은 쪽으로 밀면 '밝은테-어두운테' 두 겹이 되어,
// 배경이 밝든 어둡든 유닛 색이 무엇이든 경계에 반드시 대비 단차가 생긴다.
uniform float rim_lift : hint_range(0.0, 1.0) = 0.5;   // 제 색 → 흰색 쪽으로 미는 정도
uniform float rim_mix : hint_range(0.0, 1.0) = 0.85;   // 가장자리 픽셀에 얼마나 적용할지

// 어두운 스프라이트 끌어올리기(감마). 1.0 이면 손대지 않는다.
// 값은 CreatureVisual._lift_gamma 가 스프라이트 평균 밝기에서 구해 넣는다 —
// 몹 58종의 평균이 10~200 으로 20배 벌어져 있어서, 어두운 쪽은 어떤 바닥에서도 안 보였다.
// 곱하기가 아니라 감마라 0 과 1 은 그대로고 중간만 밀린다(하이라이트가 안 날아간다).
uniform float lift : hint_range(0.3, 1.0) = 1.0;

// 팔레트 바꾸기(캐릭터 에셋 인덱스 PNG). 켜면 텍스처는 '번호 그림'이다 — R 채널 = 팔레트 번호.
// 번호로 pal_tex 의 그 칸 색을 읽는다(0번 투명, i 번째 칸 = 번호 i). 테두리·림라이트는 알파만 보므로 그대로 돈다.
uniform bool use_pal = false;
uniform sampler2D pal_tex : filter_nearest, repeat_disable;
uniform float pal_w = 16.0;   // pal_tex 가로 칸 수

varying vec4 v_mod;   // 순수 modulate (피격 플래시·중독 물들임 등)

void vertex() {
	v_mod = COLOR;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (use_pal && col.a > 0.5) {
		float idx = floor(col.r * 255.0 + 0.5);
		col.rgb = texture(pal_tex, vec2((idx + 0.5) / pal_w, 0.5)).rgb;
	}
	if (lift < 0.999) {
		col.rgb = pow(col.rgb, vec3(lift));
	}
	if (col.a > 0.5) {
		// 안쪽 한 겹만 밝힌다. 이웃 넷 중 하나라도 비어 있으면 가장자리다.
		// (바깥선과 달리 한 텍셀만 본다 — 두꺼우면 도트가 뭉개진다.)
		float n = float(max(hframes, 1));
		float fi = floor(clamp(UV.x, 0.0, 0.999999) * n);
		vec2 t = TEXTURE_PIXEL_SIZE;
		vec2 lo = vec2(fi / n + t.x * 0.5, 0.0);
		vec2 hi = vec2((fi + 1.0) / n - t.x * 0.5, 1.0);
		float e = 1.0;
		e = min(e, texture(TEXTURE, clamp(UV + vec2(t.x, 0.0), lo, hi)).a);
		e = min(e, texture(TEXTURE, clamp(UV - vec2(t.x, 0.0), lo, hi)).a);
		e = min(e, texture(TEXTURE, clamp(UV + vec2(0.0, t.y), lo, hi)).a);
		e = min(e, texture(TEXTURE, clamp(UV - vec2(0.0, t.y), lo, hi)).a);
		float edge = (1.0 - smoothstep(0.35, 0.65, e)) * rim_mix;
		vec3 lit = mix(col.rgb, vec3(1.0), rim_lift);
		col.rgb = mix(col.rgb, lit, edge);
		COLOR = col * v_mod;
	} else {
		float n = float(max(hframes, 1));
		float fi = floor(clamp(UV.x, 0.0, 0.999999) * n);
		vec2 px = TEXTURE_PIXEL_SIZE * line_px;
		float u0 = fi / n + TEXTURE_PIXEL_SIZE.x * 0.5;
		float u1 = (fi + 1.0) / n - TEXTURE_PIXEL_SIZE.x * 0.5;
		vec2 lo = vec2(u0, 0.0);
		vec2 hi = vec2(u1, 1.0);
		float a = 0.0;
		a = max(a, texture(TEXTURE, clamp(UV + vec2(px.x, 0.0), lo, hi)).a);
		a = max(a, texture(TEXTURE, clamp(UV - vec2(px.x, 0.0), lo, hi)).a);
		a = max(a, texture(TEXTURE, clamp(UV + vec2(0.0, px.y), lo, hi)).a);
		a = max(a, texture(TEXTURE, clamp(UV - vec2(0.0, px.y), lo, hi)).a);
		if (diagonal) {
			a = max(a, texture(TEXTURE, clamp(UV + px, lo, hi)).a);
			a = max(a, texture(TEXTURE, clamp(UV - px, lo, hi)).a);
			a = max(a, texture(TEXTURE, clamp(UV + vec2(px.x, -px.y), lo, hi)).a);
			a = max(a, texture(TEXTURE, clamp(UV + vec2(-px.x, px.y), lo, hi)).a);
		}
		// 피격 플래시(modulate)가 테두리까지 하얗게 만들면 실루엣이 사라진다.
		// 테두리는 알파만 COLOR 를 따르고 색은 고정한다.
		COLOR = vec4(line_color.rgb, line_color.a * smoothstep(0.35, 0.65, a) * v_mod.a);
	}
}
