# PastelLedger

아이폰용 가계부 웹앱. 지출 · 고정 · 예산 · 통계 4개 탭, 파스텔 테마 6종.
데이터는 Firebase(로그인 계정)에 저장되어 폰을 바꿔도·다른 기기에서도 그대로. `firebase-config.js`가 `null`이면 이 기기에만 저장.

## 폴더

| 경로 | 내용 | GitHub에 올림 |
| --- | --- | --- |
| `index.html` | 앱 전체 | O |
| `cloud.js`, `firebase-config.js` | 로그인·클라우드 동기화 / Firebase 설정값 | O (설정값은 공개돼도 됨) |
| `firestore.rules` | Firestore 보안 규칙 (콘솔에 붙여넣기용) | O |
| `manifest.webmanifest`, `sw.js` | 홈 화면 앱·오프라인 | O |
| `icons/` | 홈 화면 아이콘 180/192/512 | O |
| `assets/` | 원본 아이콘, 카테고리 아이콘 (`cat-*.png`) | O |
| `seed/ledger-seed.json` | 기존 가계부 데이터 (개인정보) | **X** (`.gitignore`) |
| `make-icons.ps1` | `assets/icon-1024.png` → `icons/` 생성 | O |

## 이미지 교체

- 원본은 `assets/original/`에 둠 (GitHub에 안 올림). 카테고리 아이콘은 `cat-<이름><1~6>.png`, 번호 = 테마 순서(레몬·핑크·라벤더·민트·스카이·피치)
1. 원본을 `assets/original/`에 넣고 실행: `powershell -ExecutionPolicy Bypass -File optimize-assets.ps1`
   → `assets/`에 아이콘 256px(가장자리 조각 제거), `empty.png` 800×600(회색 막 제거), `icon-1024.png` 생성
2. 홈 화면 아이콘: `powershell -ExecutionPolicy Bypass -File make-icons.ps1`
3. `sw.js`의 `CACHE` 값을 올림 (예: `pl-v3` → `pl-v4`) — 폰에 새 파일이 반영되도록

## GitHub Pages 배포

1. GitHub에서 새 저장소 생성 (예: `pastelledger`)
2. 이 폴더에서:
   ```
   git init
   git add .
   git commit -m "PastelLedger"
   git branch -M main
   git remote add origin https://github.com/<아이디>/pastelledger.git
   git push -u origin main
   ```
3. 저장소 Settings → Pages → Branch `main` / `(root)` → Save
4. 주소: `https://<아이디>.github.io/pastelledger/`

> 공개 저장소라 누구나 코드를 볼 수 있음. 가계부 데이터는 `seed/`에만 있고 올라가지 않음 — `git status`로 `seed/`가 빠졌는지 확인.

## Firebase 설정 (한 번만)

1. https://console.firebase.google.com → **프로젝트 추가** → 이름 `pastelledger` → Google 애널리틱스 **사용 안함** → 만들기
2. 왼쪽 메뉴 **보안 → Authentication** (못 찾으면 상단 '제품 검색') → 시작하기 → 로그인 방법 **이메일/비밀번호** → 사용 설정(위 스위치만) → 저장
3. Authentication → **설정 → 승인된 도메인** → 도메인 추가 → `<아이디>.github.io`
4. 왼쪽 **데이터베이스 및 스토리지 → Firestore** (못 찾으면 '제품 검색') → 데이터베이스 만들기 → 위치 `asia-northeast3 (서울)` → **프로덕션 모드** → 만들기
5. Firestore → **규칙** 탭 → 내용을 `firestore.rules` 파일 내용으로 바꾸고 → 게시
6. 프로젝트 개요 옆 ⚙︎ → **프로젝트 설정** → 내 앱 → 웹(`</>`) → 앱 닉네임 `pastelledger` (호스팅 체크 안 함) → 앱 등록
7. 나오는 `const firebaseConfig = { ... }` 의 `{ ... }` 부분을 `firebase-config.js`의 `null` 자리에 붙여넣기
8. `sw.js`의 `CACHE` 값을 올리고 GitHub에 다시 push

## 아이폰 설치

1. Safari로 위 주소 열기 → 공유 → **홈 화면에 추가**
2. 홈 화면 아이콘으로 열기 → **처음이에요 · 회원가입** (이메일·비밀번호)
3. `seed/ledger-seed.json`을 아이폰 '파일' 앱으로 옮기기 (AirDrop, iCloud Drive 등)
4. ⚙︎ 설정 → 백업 → **가져오기** → 그 파일 선택 → 클라우드에 올라감
5. 가져온 뒤엔 폰의 파일은 지워도 됨

폰을 바꾸면: 새 폰에서 1번 후 같은 이메일로 **로그인**만 하면 됨.

## 설정 메뉴

- **백업 내보내기**: 전체 데이터를 `pastelledger-backup-날짜.json`으로 저장 (아이폰은 공유 시트). 같은 파일을 **가져오기**로 복원.
- **이전 기록 삭제**: 고른 달 이전의 지출 기록·납부 체크 삭제. 예산 이월은 이월 시작 금액(`carryBase`)으로, 계좌 월별 입금은 기존 금액으로 합쳐서 남은 예산·잔액은 그대로. 삭제 직전 백업 파일을 자동으로 먼저 만듦 (백업 취소 시 삭제 안 함).
