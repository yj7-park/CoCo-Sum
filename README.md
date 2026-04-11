<div align="center">

<img src="assets/icons/app_icon.png" width="120" alt="코코숨 아이콘">

# 코코숨 (CoCo-Sum)

**우리 아가 맑은 숨결 지킴이** 🌤️

아이들과 함께 즐기는 미세먼지 확인 앱  
코코의 표정 하나로 오늘 나가도 되는지 바로 알 수 있어요.

[![Web Deploy](https://github.com/yj7-park/CoCo-Sum/actions/workflows/deploy-web.yml/badge.svg)](https://github.com/yj7-park/CoCo-Sum/actions/workflows/deploy-web.yml)
[![Android Build](https://github.com/yj7-park/CoCo-Sum/actions/workflows/release-android.yml/badge.svg)](https://github.com/yj7-park/CoCo-Sum/actions/workflows/release-android.yml)
[![Release](https://img.shields.io/github/v/release/yj7-park/CoCo-Sum)](https://github.com/yj7-park/CoCo-Sum/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.32-blue?logo=flutter)](https://flutter.dev)

[🌐 웹 앱 바로가기](https://yj7-park.github.io/CoCo-Sum/) · [📱 APK 다운로드](https://github.com/yj7-park/CoCo-Sum/releases/latest)

</div>

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 코코 마스코트 | 공기질에 따라 표정이 바뀌는 구름 캐릭터 (둥실 애니메이션 + 눈 깜빡임) |
| GPS 최근접 측정소 | 위도/경도 기반 하버사인 공식으로 가장 가까운 측정소 데이터 자동 선택 |
| 행동 지침 배너 | "마음껏 뛰어놀아요!" / "마스크 꼭 써요!" 등 아이 눈높이 안내 |
| PM2.5 / PM10 | 초미세먼지·미세먼지 수치 + 등급 표시 |
| 공기질 4단계 | 좋음(파랑) → 보통(연두) → 나쁨(주황) → 매우나쁨(보라) 배경 변환 |

### 공기질 등급 & 코코 표정

| 등급 | PM2.5 (μg/m³) | 코코 | 행동 지침 |
|------|:---:|:---:|---|
| 좋음 | 0 ~ 15 | 😄 활짝 웃음 + 분홍볼 | 마음껏 뛰어놀아요! |
| 보통 | 16 ~ 35 | 🙂 잔잔한 미소 | 나가도 괜찮아요 |
| 나쁨 | 36 ~ 75 | 😷 마스크 착용 | 마스크 꼭 써요! |
| 매우나쁨 | 76+ | 😰 걱정 표정 | 오늘은 집에 있어요 |

---

## 스크린샷

> 스크린샷은 준비 중입니다.
> 웹 버전에서 직접 확인하세요 → https://yj7-park.github.io/CoCo-Sum/

---

## 설치

### 웹
브라우저에서 바로 사용: **https://yj7-park.github.io/CoCo-Sum/**

### Android APK

1. [최신 릴리즈](https://github.com/yj7-park/CoCo-Sum/releases/latest)에서 기기에 맞는 APK 다운로드

   | 파일 | 대상 기기 |
   |------|---------|
   | `cocosum-arm64.apk` | 2018년 이후 대부분의 안드로이드 폰 |
   | `cocosum-armv7.apk` | 구형 안드로이드 폰 |
   | `cocosum-x86_64.apk` | 에뮬레이터 |

2. **설정 → 보안 → 알 수 없는 앱 설치** 허용
3. APK 파일 실행 후 설치

---

## 개발 환경 설정

### 요구사항

- Flutter 3.32+
- Dart 3.8+
- Android Studio / VS Code

### 시작하기

```bash
git clone https://github.com/yj7-park/CoCo-Sum.git
cd CoCo-Sum
flutter pub get
flutter run
```

### 공식 에어코리아 API 키 연동 (선택)

현재는 에어코리아 웹사이트 크롤링으로 동작하며, API 키가 없어도 실행됩니다.  
더 안정적인 데이터를 위해 공식 API 키를 연동할 수 있어요.

1. [공공데이터포털](https://www.data.go.kr) 가입
2. `한국환경공단_에어코리아_대기오염정보` 오픈API 활용 신청
3. 발급받은 키로 `airkorea_api_datasource.dart` 구현 (아래 참고)

```dart
// lib/data/datasources/airkorea_api_datasource.dart 새 파일 생성
class AirKoreaApiDataSource implements AirQualityDataSource {
  static const _apiKey = 'YOUR_API_KEY_HERE';
  // airkorea_web_datasource.dart의 주석 참고
}

// lib/presentation/providers/providers.dart 한 줄 교체
final dataSourceProvider = Provider<AirQualityDataSource>((ref) {
  return AirKoreaApiDataSource(ref.watch(dioProvider));  // ← 여기만 변경
});
```

---

## 프로젝트 구조

```
lib/
├── domain/                     # 비즈니스 로직 (외부 의존성 없음)
│   ├── entities/
│   │   └── air_quality.dart    # AirQuality 엔티티, AirQualityGrade enum
│   ├── repositories/
│   │   └── air_quality_repository.dart  # 추상 인터페이스
│   └── usecases/
│       └── get_current_air_quality.dart
│
├── data/                       # 데이터 계층
│   ├── datasources/
│   │   ├── air_quality_datasource.dart      # DataSource 추상 인터페이스
│   │   └── airkorea_web_datasource.dart     # 웹 크롤링 구현체
│   ├── models/
│   │   └── air_quality_model.dart           # JSON ↔ Entity 변환
│   └── repositories/
│       └── air_quality_repository_impl.dart
│
└── presentation/               # UI 계층
    ├── pages/
    │   └── home_page.dart      # 메인 화면
    ├── providers/
    │   └── providers.dart      # Riverpod DI + 상태 관리
    ├── theme/
    │   └── app_theme.dart      # 색상, 테마
    └── widgets/
        ├── coco_character.dart  # 코코 마스코트 (CustomPainter + 애니메이션)
        ├── action_banner.dart   # 행동 지침 배너
        └── pollutant_card.dart  # PM2.5 / PM10 카드
```

### 최근접 측정소 선택 알고리즘

```
GPS 좌표 (lat, lon)
    │
    ├─ geocoding.placemarkFromCoordinates()
    │      └─ administrativeArea: "경기도" → "경기"
    │         subAdministrativeArea: "수원시 팔달구"
    │
    └─ AirKorea AJAX (시도 내 전체 측정소 조회, numOfRows=100)
           │
           ├─ [dmX, dmY 있음] 하버사인 공식 → 최단거리 측정소
           ├─ [좌표 없음]     구/군명 문자열 매칭 → stationName
           └─ [매칭 실패]     첫 번째 측정소 (fallback)
```

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.32 (iOS / Android / Web) |
| 상태 관리 | flutter_riverpod |
| 데이터 소스 | 에어코리아 웹 크롤링 (dio + html) |
| 위치 | geolocator + geocoding |
| UI | CustomPainter, AnimationController, google_fonts (Noto Sans KR) |
| 차트 | fl_chart (Phase 2) |
| 알림 | flutter_local_notifications (Phase 2) |

---

## 로드맵

- [x] Phase 1 — MVP
  - [x] GPS 기반 최근접 측정소 자동 선택
  - [x] 코코 마스코트 (공기질별 표정 + 둥실 애니메이션)
  - [x] PM2.5 / PM10 표시, 등급별 배경 변환
  - [x] GitHub Pages 웹 배포
  - [x] Android APK GitHub Release

- [ ] Phase 2 — 완성도 향상
  - [ ] 6대 오염물질 상세 화면 (O₃, NO₂, CO, SO₂)
  - [ ] 오늘 / 내일 예보
  - [ ] 시간대별 추이 차트 (fl_chart)
  - [ ] 아침 등원 전 푸시 알림

- [ ] Phase 3 — 차별화
  - [ ] 홈 화면 위젯
  - [ ] 즐겨찾기 (집, 어린이집, 친정)
  - [ ] 공기질 SNS 공유
  - [ ] 온보딩 화면
  - [ ] 공식 에어코리아 API 연동

---

## 기여

이슈와 PR을 환영합니다.  
코코 캐릭터 디자인 개선, 에러 수정, 새 기능 제안 모두 좋아요!

---

<div align="center">
  <sub>Made with 💙 for all the little ones and their parents</sub>
</div>
