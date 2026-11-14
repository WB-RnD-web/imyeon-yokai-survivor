shader_type canvas_item;

// 바닥 채도 낮추기.
//
// 도서관 바닥이 갈색(rgb 77,51,35)인데 갈색 몹이 넷이라 ΔE 3~10 — 사실상 같은 색이었다
// (tools/contrast_qa.py). 도서관 색조만 고치면 다음 맵에서 같은 일이 반복된다.
// 색은 배우가 갖고 무대는 무채색에 가깝게 — 그러면 어떤 유닛이 어느 맵에 서든 색이 갈린다.
//
// 밝기는 건드리지 않는다(GROUND_DIM 이 따로 한다). 여기서는 채도만 뺀다.
uniform float amount : hint_range(0.0, 1.0) = 0.45;

// 결 누르기. 채도를 빼도 **나뭇결·벽돌줄의 명암 대비**는 그대로라, 바닥이 여전히 시끄럽다
// (도서관 마루가 특히 그렇다 — 밝은 널과 어두운 널이 번갈아 있어서 그 줄무늬가 몹만큼 눈에 띈다).
// 각 픽셀을 그 테마 바닥의 평균색 쪽으로 당겨서 무늬의 진폭만 줄인다.
// 무늬는 남고(패턴은 보인다) 대비만 낮아진다.
uniform vec3 base_col = vec3(0.2);
uniform float flatten : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 m = COLOR;                       // 색조 × 칸별 밝기 (draw 쪽 모듈레이트)
	vec4 t = texture(TEXTURE, UV);
	vec3 c = t.rgb * m.rgb;
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 o = mix(c, vec3(l), amount);     // 채도 빼기
	// base_col 은 이 테마 바닥 타일의 **원본 평균색**이다. 같은 모듈레이트를 곱해 주면
	// 지금 픽셀과 같은 공간의 '평균 바닥'이 되고, 그쪽으로 당기면 무늬의 진폭만 준다.
	vec3 b = base_col * m.rgb;
	b = mix(b, vec3(dot(b, vec3(0.2126, 0.7152, 0.0722))), amount);
	COLOR = vec4(mix(o, b, flatten), t.a * m.a);
}
