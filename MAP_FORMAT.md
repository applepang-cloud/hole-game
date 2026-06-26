# hole-map JSON 포맷 스펙 (맵 에디터 ↔ 게임 계약)

맵 에디터(외부, 예: claude.ai 아티팩트)는 이 포맷으로 맵을 **export(JSON)** 하고,
게임은 `커스텀 맵 불러오기`로 이 JSON을 읽어 그대로 재구성·플레이합니다.

핵심 설계: **오브젝트를 "프리미티브 파츠 배열"로 표현**합니다. 그러면 에디터가 만든
어떤 모양(자유 입력·사람·건물·외부 변형 등)이든 게임이 충실히 재현하며, 게임이
에디터 내부 타입을 몰라도 됩니다. (= 최소 공통 분모 = 프리미티브 메시 묶음)

---

## 최상위 구조

```json
{
  "format": "hole-map",        // 필수. 정확히 이 문자열이어야 로드됨
  "version": 1,
  "name": "내가 만든 맵",        // 표시용(선택)
  "bound": 26,                  // 플레이 영역 반경(±). 10~60로 클램프. 기본 26
  "indoor": false,             // true=실내(바닥+벽4면), false=실외(하늘돔+원형 바닥)
  "theme": "yard",             // 조명/분위기 프리셋(아래 표). 기본 indoor?room:yard
  "ground": "#83cf4e",         // 실외 바닥색(선택)
  "sky": "#a9def7",            // 실외 하늘색(선택)
  "floor": "#cdb38a",          // 실내 바닥색(선택)
  "wall":  "#cfdbe6",          // 실내 벽색(선택)
  "music": "map2.mp3",         // BGM 파일명(선택). 내장: map1.mp3~map6.mp3
  "time": 180,                 // 제한시간(초, 선택)
  "goal": { "type": "size", "value": 1.8 },   // 목표(아래 참고)
  "objects": [ /* 오브젝트 배열 */ ]
}
```

### theme 값 (조명 프리셋)
`default` `yard`(마당) `room`(방) `mart`(마트) `school`(학교) `city`(도시)
`grave`(공동묘지) `snow`(눈) `haunted`(귀신) `cathedral`(성당) `dracula`(드라큘라성)

### goal (클리어 목표)
- 맵에 `role:"spawner"`(구멍)가 **하나라도 있으면** → 자동으로 **"모든 구멍 메우기"** 가 목표가 됩니다(goal 무시).
- 구멍이 **없으면** → **크기 목표**: 공을 굴려 `goal.value`(반지름, 단위 m) 이상으로 키우면 클리어. 기본 1.8.

---

## 오브젝트 (objects[] 항목)

```json
{
  "id": "obj_1",              // 선택(에디터 식별용)
  "name": "빨간 의자",          // 선택(설명/표시용)
  "role": "prop",             // prop(기본) | monster | spawner
  "x": 3, "z": 2,             // 바닥 위 위치(맵 중심 0,0 기준). y는 자동 접지
  "rotY": 0.5,                // Y축 회전(라디안). 기본 0
  "scale": 1,                 // 전체 배율(숫자). 기본 1
  "color": "#cc5533",         // 파츠에 color 없을 때 폴백(선택)
  "parts": [ /* 프리미티브 파츠 배열 (아래) */ ]
}
```

### role
| role | 동작 |
|------|------|
| `prop` (기본) | 바닥에 배치되는 물체/장식/건물. 공으로 굴려 흡수(성장)·깔아뭉갬. |
| `monster` | 배회 AI가 붙은 생명체. 공이 작으면 공격, 크면 깔아뭉갬. |
| `spawner` | 바닥 구멍. `r`(또는 scale)로 크기 지정. 공보다 작으면 메워 제거(성장), 크면 빠져서 위험. 구멍이 있으면 "모두 메우기"가 클리어 조건. |

`spawner`는 parts가 필요 없습니다: `{ "role":"spawner", "x":5, "z":-3, "r":0.9 }`

---

## parts[] — 프리미티브 파츠

각 파츠는 하나의 메시입니다. 파츠들을 조합해 한 오브젝트의 모양을 만듭니다.
파츠의 `pos`/`rot`/`scale`은 **오브젝트 로컬 좌표**(오브젝트 원점 기준)입니다.
오브젝트 전체는 자동으로 바닥(y=0)에 접지되므로, 파츠 y는 0 이상으로 쌓아 올리면 됩니다.

```json
{
  "g": "box",                 // 도형: box | sphere | cylinder | cone | torus
  "size": [1, 0.6, 1],        // box 전용: [가로, 높이, 깊이]
  "r": 0.5,                   // sphere/cone/torus 반지름. cylinder는 [위, 아래, 높이] 배열 가능
  "h": 1,                     // cone/cylinder 높이(또는 r 배열로 대체)
  "tube": 0.12,               // torus 두께
  "pos": [0, 0.3, 0],         // 로컬 위치 [x,y,z]
  "rot": [0, 0, 0],           // 로컬 회전 [x,y,z] 라디안
  "scale": 1,                 // 파츠 배율(숫자 또는 [x,y,z])
  "color": "#cc5533",         // 색
  "shading": "smooth",        // smooth | flat (선택, 기본=게임 전역 설정)
  "gloss": 0.5                // 광택 0~1 (선택)
}
```

### 도형별 필드 요약
| g | 필요 필드 | 비고 |
|---|----------|------|
| `box` | `size:[w,h,d]` | 직육면체 |
| `sphere` | `r` | 구 |
| `cylinder` | `r:[top,bottom,height]` 또는 `r`+`h` | 원기둥/원뿔대 |
| `cone` | `r`, `h` | 원뿔 |
| `torus` | `r`, `tube` | 도넛(고리) |

---

## 예시 (실외 마당 맵)

```json
{
  "format": "hole-map",
  "name": "테스트 마당",
  "bound": 20, "indoor": false, "theme": "yard",
  "ground": "#8fcf5a", "sky": "#a9def7",
  "goal": { "type": "size", "value": 1.4 },
  "objects": [
    { "role": "prop", "x": 3, "z": 2, "rotY": 0.5,
      "parts": [
        { "g": "box",  "size": [1,0.6,1], "pos": [0,0.3,0], "color": "#cc5533" },
        { "g": "cone", "r": 0.7, "h": 0.8, "pos": [0,1.0,0], "color": "#aa3322" }
      ] },
    { "role": "prop", "x": -4, "z": 1, "scale": 1.2,
      "parts": [ { "g": "cylinder", "r": [0.3,0.3,1.4], "pos": [0,0.7,0], "color": "#dddddd" } ] },
    { "role": "monster", "x": 0, "z": 6,
      "parts": [
        { "g": "sphere", "r": 0.5, "pos": [0,0.5,0], "color": "#33aa66" },
        { "g": "sphere", "r": 0.12, "pos": [0.2,0.7,0.45], "color": "#ffffff" }
      ] },
    { "role": "spawner", "x": 5, "z": -3, "r": 0.9 }
  ]
}
```

---

## 게임에서 불러오는 법
- 게임 메뉴 → **🛠️ 커스텀 맵 불러오기** → JSON 파일 선택 또는 붙여넣기 → 불러와서 플레이.
- 또는 코드/부모창에서 `window.__holeLoadCustomMap(jsonStringOrObject)` 호출.
- 임베드(부모 iframe/WebView)에서는 `postMessage({holeCmd:'loadCustom', map: <json>})` 로 로드 가능.

## 제약 / 안내
- 모양은 **프리미티브 조합**으로만 재현됩니다(텍스처/외부 GLB 메시는 미지원 → 에디터에서 프리미티브로 근사해 export 권장).
- 색/크기/회전/위치/광택/셰이딩은 모두 반영됩니다.
- 알 수 없는 `g`(도형)는 box로 대체됩니다.
- `format`이 `"hole-map"`이 아니거나 `objects`가 배열이 아니면 로드가 거부되고 안내 메시지가 표시됩니다.
