# IMYEON : Yokai Survivor

A pixel-art survivor roguelike set in a Korean yokai underworld. Pick a hero, survive waves of yokai, fuse weapons and beat the stage bosses, or keep going in Endless mode.

- Steam: https://store.steampowered.com/app/5428620/
- Free Windows build: see [Releases](https://github.com/WB-RnD-web/imyeon-yokai-survivor/releases)
- Engine: Godot 4.7.1 (GL Compatibility)
- Current version: 1.5.0

The Steam release and the builds on this page come from the same source. The Steam release additionally ships [GodotSteam](https://godotsteam.com/) and Valve's `steam_api64.dll` for achievements and cloud saves. Those two files are not part of this repository.

## Build it yourself

1. Install [Godot 4.7.1](https://godotengine.org/download/archive/4.7.1-stable/) and its export templates.
2. Open this folder in Godot, or export from the command line:

   ```
   godot --headless --path . --import
   godot --headless --path . --export-release "Windows" build/windows/IMYEON.exe
   ```

3. Keep `IMYEON.exe` and `IMYEON.pck` in the same folder and run the exe.

The GitHub Actions workflow in `.github/workflows/release.yml` does exactly this for every tag and attaches the result to a release.

## Code signing policy

Free code signing provided by [SignPath.io](https://about.signpath.io/), certificate by [SignPath Foundation](https://signpath.org/).

- Committers and reviewers: [WB-RnD-web](https://github.com/WB-RnD-web)
- Approvers: [WB-RnD-web](https://github.com/WB-RnD-web)

Only binaries built by the GitHub Actions workflow of this repository from the tagged source are submitted for signing. Every signing request is approved by hand.

## Privacy policy

This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it.

The Steam release talks to the Steam client for achievements and cloud saves. That data is handled under [Steam's privacy policy](https://store.steampowered.com/privacy_agreement/). Game privacy policy: https://sites.google.com/view/wangbyul-games-privacy

## License

- Code and game assets in this repository: [MIT License](LICENSE).
- Galmuri fonts in `assets/fonts/galmuri`: SIL Open Font License 1.1 (see `assets/fonts/galmuri/OFL.txt`).
- Godot Engine and its components inside the exported program: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

## 한국어

한국 요괴 저승을 배경으로 한 도트 서바이버 로그라이크예요. 영웅을 골라 몰려오는 요괴를 버티고, 무기를 융합해 스테이지 보스를 잡거나 무한 모드로 끝까지 버텨요.

- 스팀: https://store.steampowered.com/app/5428620/
- 무료 윈도우판: [Releases](https://github.com/WB-RnD-web/imyeon-yokai-survivor/releases)
- 스팀판은 여기 있는 코드 그대로에 업적과 클라우드 저장용 GodotSteam, Valve 의 `steam_api64.dll` 만 더한 거예요.

코드와 그림, 효과음은 MIT 라이선스로 공개해요. 갈무리 글꼴은 SIL OFL 1.1 을 따라요.

윈도우 실행 파일 서명은 SignPath Foundation 이 무료로 해 줘요. 서명은 이 저장소의 GitHub Actions 가 태그에서 빌드한 파일에만 받고, 요청마다 사람이 승인해요.
