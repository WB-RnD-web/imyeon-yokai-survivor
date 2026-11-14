class_name I18n
## 화면 문구 번역 도우미.
##
## 번역 키는 코드에 박힌 한글 문구 그대로다(원본표 i18n/en.tsv · 굽는 도구 tools/i18n.py).
## Label·Button 에 문구를 **그대로** 넣으면 Godot 가 알아서 번역한다 — 여기를 안 거쳐도 된다.
## 여기를 거쳐야 하는 건 코드가 문구를 **조합**할 때다:
##
##     lbl.text = I18n.t("레벨 %d") % G.level       ← 틀을 먼저 번역하고 값을 끼운다
##     lbl.text = "✔ " + I18n.t(def["name"])        ← 이어 붙이는 조각마다
##
## "레벨 %d" % n 의 결과("레벨 5")는 번역표에 없으니 자동 번역이 못 잡는다.
##
## ★ tr() 을 안 쓰고 이걸 쓰는 이유: tr() 은 인스턴스 함수라 static 함수 안에서 못 부른다.
##   카드·영웅 정의처럼 static 으로 문구를 만드는 곳이 있어서 어디서든 되는 쪽으로 통일한다.


static func t(s: String) -> String:
	return String(TranslationServer.translate(s))
