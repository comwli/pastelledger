# 인계 문서 — 다른 PC에서 이어서 하기

작성: 2026-11-06. 이 PC(Windows)의 Claude 대화 내용을 다른 PC에서 이어가기 위한 정리.
다른 PC의 Claude에게: **이 문서를 먼저 끝까지 읽고**, `handoff/claude-config/`의 규칙을 따른다.

## 0. 다른 PC 준비

### 0-1. 코드
```bash
git clone https://github.com/comwli/pastelledger.git PastelLedger
cd PastelLedger
git config user.email "comwli@hanmail.net"
```

### 0-2. GitHub에 없는 파일 (USB·개인 클라우드로 직접 옮김)
| 파일 | 내용 | 필요성 |
|---|---|---|
| `seed/ledger-seed.json` | 가계부 데이터 (개인정보, 올리지 말 것) | 웹 JS ↔ 앱 Dart 계산 대조 테스트에 필요 |
| `assets/original/` | 원본 이미지 약 45MB | 이미지 재가공 때만 |
| `assets/icon-1024_old.png` | 이전 크레용 아이콘 | 필요 없으면 생략 |

### 0-3. Claude 작업 규칙 설치
`handoff/claude-config/`는 이 PC의 `~/.claude/` 파일을 그대로 복사한 것(원본과 바이트 동일 확인).
Git Bash에서 저장소 폴더 기준:
```bash
mkdir -p ~/.claude/rules ~/.claude/hooks
cp handoff/claude-config/CLAUDE.md ~/.claude/CLAUDE.md
cp handoff/claude-config/rules/procedure-rules.md ~/.claude/rules/
cp handoff/claude-config/hooks/procedure-rules.sh ~/.claude/hooks/
```
- 아래는 이 PC `~/.claude/settings.json`의 `hooks` 부분(17~30줄) 그대로. 다른 PC의 `settings.json`에 **덮어쓰지 말고 `"hooks"` 항목만 합친다** (이미 `hooks`가 있으면 `UserPromptSubmit` 배열에 추가).
```json
"hooks": {
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "shell": "bash",
          "command": "bash \"$HOME/.claude/hooks/procedure-rules.sh\"",
          "timeout": 10
        }
      ]
    }
  ]
}
```
- 다른 PC에 이미 `~/.claude/CLAUDE.md`가 있으면 덮어쓰기 전에 내용 확인.
- 참고: 이 PC는 플러그인 `superpowers`, `code-review`, `code-simplifier`, `security-guidance`(claude-plugins-official)를 켜 두었음. 규칙과 별개라 복사 대상 아님.

## 1. 프로젝트 현재 상태

- 웹앱(PWA) 완성·배포: https://comwli.github.io/pastelledger/ (GitHub Pages, 저장소 **공개**)
- 마지막 배포 커밋: `c9e5e67` (앱 아이콘 교체, `sw.js` 캐시 `pl-v8`)
- 구조: `index.html`(앱 전체, 인라인 CSS/JS), `cloud.js`(Firebase 로그인·Firestore 동기화), `firebase-config.js`, `firestore.rules`, `manifest.webmanifest`, `sw.js`, `icons/`, `assets/`
- Firebase 프로젝트 `pasteledger`: 이메일/비밀번호 로그인, Firestore 문서 `users/{uid}/data/ledger`, 규칙은 본인만 읽기·쓰기
- 데이터 형태 `S = {v, income, items, groups, checks, budget, entries, accounts, saveLog}`
  - 읽기 정규화: `index.html` `merge()` 736~745줄 / 쓰기: `JSON.stringify(S)` 전체를 `setDoc`
- 실제 아이폰 설치·검증은 아직 안 함 (PC 브라우저에서만 검증)

## 2. 결정된 것 — 안드로이드 앱 (C안: Flutter 네이티브)

사용자 결정: **C안(Flutter로 새로 만들기), 안드로이드 버전만 먼저.** iOS는 나중.

### 검토 과정 요약 (공식 문서로 확인함)
- 앱 형태 3종: A 주소 띄우기(PWABuilder/TWA) / B 웹 파일 넣기(Capacitor) / C 네이티브 새로(Flutter 등)
- 빌드 장소(PC 명령줄·클라우드)와 앱 형태는 별개. 안드로이드는 Android Studio 없이 명령줄(`gradlew`, `flutter build apk`) 빌드 가능 — developer.android.com/build/building-cmdline
- iOS 빌드는 macOS 필요(Flutter 문서) → Mac 없으면 클라우드 Mac(Codemagic 등). 아이폰 실행은 서명 필요: 무료 계정은 Mac의 Xcode로만(7일 만료), 아니면 Apple 개발자 $99/년
- 이전 대화에서 Claude가 "iOS는 Mac 필수", "APK는 Android Studio 필요"처럼 확인 없이 단정했다가 틀려서 사용자에게 지적받음 → **확인 가능한 건 공식 문서로 확인 후 답할 것**

### 사용자 답이 아직 필요한 3가지 (작업 착수 전 확인)
1. 테스트할 안드로이드 폰이 있는가? (없으면 에뮬레이터 + 시스템 이미지 추가 다운로드, PC 가상화 필요)
2. 앱 ID: 추천 `com.comwli.pastelledger` (스토어 출시 후 변경 불가)
3. Firebase 콘솔에서 안드로이드 앱 등록 → `google-services.json` 받기 (사용자 로그인 필요, Claude가 대신 못 함)

## 3. 체크리스트 (승인 대기 중 — 이 PC에서 승인 전에 중단됨)

### A. 설치 (다운로드는 승인 후, 크기는 2026-11-06 확인 값)
| 항목 | 출처 | 크기 |
|---|---|---|
| JDK 21 (Microsoft OpenJDK 21.0.13) | winget `Microsoft.OpenJDK.21` | 171MB |
| Flutter 3.47.9 stable | storage.googleapis.com/flutter_infra_release | 1,850MB (zip) |
| Android 명령줄 도구 `commandlinetools-win-16111833_latest.zip` | dl.google.com/android/repository | 148MB |
| platform-tools / platforms;android-36 / build-tools;36.1.0 | sdkmanager | 8 / 63 / 57MB |
| NDK (빌드가 요구할 때만) | sdkmanager | 약 694MB |
- 첫 빌드 때 Gradle·라이브러리 추가 다운로드(크기 미리 알 수 없음)
- 시스템 환경변수는 바꾸지 않고 빌드 때만 지정하는 방향으로 제안했음
- 참고 요구 버전: AGP 8.x는 JDK 17 이상(developer.android.com/build/jdks)

### B. 프로젝트
- 위치 `PastelLedger/app/` — **GitHub에 push 안 함**(공개 저장소)으로 제안했음. 다른 PC로 옮겨 다닐 거면 비공개 저장소 등 방법을 사용자와 다시 정할 것
- 앱 이름 PastelLedger, 아이콘은 `assets/icon-1024.png`로 안드로이드 적응형 아이콘, `assets/empty.png` 사용

### C. 데이터 호환 (가장 중요)
- 웹과 같은 Firestore 문서 `users/{uid}/data/ledger` 공유 → 웹·앱 같은 계정 동시 사용
- 읽기: 웹 `merge()` 규칙 1:1 이식 (필드 자르기 길이, 숫자 변환, 날짜 형식 검사, 옛 `group`→카테고리 변환 `normGroups`, `carry/carryFrom/carryBase`)
- 쓰기: 웹과 같은 필드 구성, 문서 전체 저장
- 동기화: 실시간 반영, 내 쓰기(`hasPendingWrites`)는 건너뜀
- 기기 저장: Firestore 오프라인(안드로이드 기본 켜짐 — Firebase 문서), 테마·마지막 탭만 기기 저장

### D. 화면·기능 (웹 1:1)
- 상단: 달 이동, 설정, 이번 달 남은 금액(음수 빨강, 수입 없으면 안내), 저장 상태
- 지출: 월 합계, 달력(금액 비례 진하기·만 단위·오늘 밑줄·선택), 기록 폼(예산들+예산 외, 금액 필수), 날짜별 목록·수정·삭제("한 번 더"), 빈 화면 그림, 날짜 없는 이전 기록(접기), 남은 예산(색 점·은행·남음/초과·막대·총/이월/사용)
- 고정: 합계 카드 / 고정지출 전체 체크(일부 상태)·n/m, 카테고리별 목록(체크 취소선, 결제일·은행·메모·→계좌), 카테고리 편집(이름·▲▼·항목 편집·항목 추가), 삭제 시 항목 기타로(항목 남은 기타는 삭제 불가), 카테고리 추가(중복 이름 차단) / 저축 전체 체크·편집(연결 계좌)·추가, 체크 순간 금액 `saveLog` 기록(`setCheck`)
- 예산: 수입, 요약 6줄, 생활비 예산 보기·편집(이월 켜면 이번 달부터, 끄면 이월 정보 삭제)·삭제·추가, 초과 개수, 은행별 보낼 돈(체크분 제외 남음, 고정/저축/예산 표시, 정렬, 설명 줄)
- 통계: 도넛(고정 포함/생활비만, 가운데 글자, 범례 %, 조각 탭 시 금액), 예산 대비 사용, 고정지출 카테고리별(금액순·%), 총 저축자산(바로 씀/묶임), 계좌 보기·편집(삭제 시 연결 해제), 계좌별 이번 달 입금, 연결 저축 자동 입금·미체크 안내
- 설정: 테마 6종, 계정·로그아웃(확인 → 미전송 최대 5초 대기 → 기기 사본 삭제), 백업 내보내기(공유 시트, 웹과 같은 JSON)·가져오기(형식 검사·덮어쓰기 확인·개수 안내), 이전 기록 삭제(달 선택·건수 안내·"한 번 더"·백업 완료 후에만)
- 로그인: 로그인·회원가입·비밀번호 재설정, 한국어 오류 문구 7종(웹 `AUTH_MSG`와 동일)

### E. 웹에만 있고 앱에서 빼는 것
- `sw.js` 오프라인 캐시, 로그인 없는 기기 저장 모드, "주인 없는 기기 사본 올릴까요?" 질문

### F. 안드로이드 추가 (승인 필요)
- 뒤로가기: 수정 중 → 수정 취소, 편집 중 → 편집 끝, 그 외 기본 동작
- 상태바 색을 테마에 맞춤

### G. 검증
- `seed/ledger-seed.json`을 웹 JS와 Dart로 각각 읽어 결과 대조 테스트: `merge` 결과, `totals`, `carryIn`, `accBal`, 이전 기록 삭제 후 상태, 쓰기→읽기 왕복
- APK 빌드(처음엔 디버그 키 서명 설치용, 출시용 서명은 나중에)
- 실기기/에뮬레이터: 로그인, 웹↔앱 동기화 양방향, 각 탭

## 4. 그 밖에 알려둘 것
- `manifest.webmanifest`의 `theme_color`가 아직 레몬색 `#FEF1A2` (발견만 하고 안 고침, 사용자에게 보고함)
- 사용자 작업 규칙 핵심: 한국어, 서브에이전트 금지, 착수 전 체크리스트 승인, 범위 밖 변경 금지, 추측 금지, 빌드·검증 여부 사실대로
