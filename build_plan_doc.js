const path = require("path");
const fs = require("fs");
const GROOT = "C:/Users/song/AppData/Roaming/npm/node_modules";
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, LevelFormat, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageOrientation, ExternalHyperlink,
} = require(path.join(GROOT, "docx"));

const FONT = "Malgun Gothic";
const INK = "2B2335", ORANGE = "E8552D", PURPLE = "7A4FB0", GREEN = "4A8F3A", BLUE = "2A5A9C";
const HEADFILL = "F4C430", ROWALT = "FFF7E6", FLOWFILL = "EEF4FF", DONEFILL = "E4F3E0";

const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const CM = { top: 60, bottom: 60, left: 110, right: 110 };

function run(text, o = {}) { return new TextRun({ text, font: FONT, ...o }); }
function P(text, o = {}) { return new Paragraph({ children: [run(text, o.run || {})], ...(o.p || {}) }); }
function H(text, level) { return new Paragraph({ heading: level, children: [run(text, { bold: true })] }); }
function runs(arr) { return new Paragraph({ children: arr }); }
function bullet(content, lvl) {
  return new Paragraph({ numbering: { reference: "b", level: lvl || 0 },
    children: Array.isArray(content) ? content : [run(content)] });
}
// 플로우차트 한 줄(화살표 흐름) — 음영 박스 단락
function flow(text, indent) {
  return new Paragraph({
    shading: { fill: FLOWFILL, type: ShadingType.CLEAR },
    spacing: { before: 20, after: 20 }, indent: { left: (indent || 0) * 280 },
    children: [run(text, { size: 19 })],
  });
}
function cell(content, opt = {}) {
  const paras = (Array.isArray(content) ? content : [content]).map(c =>
    typeof c === "string" ? P(c, { run: { size: 18, ...(opt.run || {}) } }) : c);
  return new TableCell({ borders, margins: CM, verticalAlign: VerticalAlign.CENTER,
    width: { size: opt.w, type: WidthType.DXA },
    shading: opt.fill ? { fill: opt.fill, type: ShadingType.CLEAR } : undefined,
    children: paras });
}
function headRow(labels, widths) {
  return new TableRow({ tableHeader: true, children: labels.map((l, i) =>
    cell(P(l, { run: { bold: true, size: 18, color: INK } }), { w: widths[i], fill: HEADFILL })) });
}
function simpleTable(headers, rows, widths) {
  const r = [headRow(headers, widths)];
  rows.forEach((row, i) => r.push(new TableRow({ children: row.map((v, c) =>
    cell(P(String(v), { run: { size: 18, bold: c === 0 } }), { w: widths[c], fill: i % 2 ? ROWALT : undefined })) })));
  return new Table({ width: { size: widths.reduce((a, b) => a + b, 0), type: WidthType.DXA }, columnWidths: widths, rows: r });
}

const children = [];
const CW = 9360; // portrait content width

/* 표지 */
children.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 240, after: 60 },
  children: [run("굴려라! — 데굴데굴 별왕자", { bold: true, size: 46, color: ORANGE })] }));
children.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 },
  children: [run("게임 개발 계획서 (기획서)", { bold: true, size: 30, color: INK })] }));
children.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 30 },
  children: [run("캐주얼 3D 홀(Hole) 게임 · 광고 중심 + 인앱결제 보조 · 레벨 1,000개(1차 출시 600)", { size: 19, color: "555555" })] }));
children.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 220 },
  children: [run("문서 버전 v0.3 · 2026-06-19 · 기준 빌드 katamari-v7.html · 퍼블리싱 계약 진행 중", { size: 17, color: "888888" })] }));

/* 0. 한눈에 보기 */
children.push(H("0. 한눈에 보기 (Executive Summary)", HeadingLevel.HEADING_1));
children.push(simpleTable(["항목", "내용"], [
  ["핵심 루프", "구멍을 굴려 물건을 빨아들여 → 커지고 → 목표 크기/제한시간 달성 → 다음 레벨"],
  ["1차 모드", "구멍 빨아들이기(hole)를 메인 진행 모드로 정식화 (나머지 2모드는 보너스/이벤트)"],
  ["진행 구조", "20 월드 × 50 레벨 = 1,000 레벨, 월드별 테마·난이도 곡선"],
  ["출시 범위", "1차 출시 600레벨(12월드×50) → 이후 업데이트로 1,000 확장"],
  ["퍼블리싱", "퍼블리셔(배급사) 계약 진행 중 — 글로벌 출시·UA·정산 협의"],
  ["수익화", "보상형 광고(부활·보상2배·아이템) + 전면광고(레벨 사이) + IAP(광고제거·코인팩·스타터팩)"],
  ["아이템", "벤치마킹: 시간연장·자석·스피드부스트·가속로켓·점프·시작크기업·코인2배·부활"],
  ["신규 모드", "멀티플레이 경쟁(§7), 페인트 그림완성(§8), 이벤트 미니게임 눈사람·쇠똥구리(§9)"],
  ["우선순위", "①기본 게임 → ②레벨/진행저장 → ③메타(홈·상점·재화) → ④아이템 → ⑤수익화 → ⑥600레벨 출시"],
], [2100, 7260]));

/* 0.5 현재 구현 현황 */
children.push(H("현재 구현 현황 (빌드 v7)", HeadingLevel.HEADING_2));
children.push(bullet([run("테마 맵 6종: ", { bold: true }), run("내 방(개미·쥐·고양이·창밖 귀신) / 마당(마을사람·유령·호박) / 마트(좀비) / 학교(도깨비·해골) / 도시(시민, 십자도로·인도·횡단보도 바닥) / 저승(해골·유령·저승사자).")]));
children.push(bullet([run("구멍: ", { bold: true }), run("작은 건 굴러 덮어 메우고(보라=메울 수 있음), 큰 건 빠져서 실패(검정=위험) — 색은 내 크기에 따라 실시간 변화. 모든 구멍 제거 시 클리어.")]));
children.push(bullet([run("성장: ", { bold: true }), run("일반 물체 깔아뭉개기/흡수는 조금, 구멍 메우면 크게.")]));
children.push(bullet([run("위협/전투: ", { bold: true }), run("몬스터가 추격·공격(종류별 데미지), 공중 헬기가 30초마다 폭격(착탄 예고링). 체력(HP 300) 게이지, 0이면 게임오버. 몬스터 사망 시 ‘으악’ 효과음.")]));
children.push(bullet([run("조작/메타: ", { bold: true }), run("일시정지(계속·다시하기·홈), 6맵 + 이벤트 모드(공 굴리기·구멍 빨아들이기). 플레이 볼=파란 볼.")]));
children.push(bullet([run("기술/게시: ", { bold: true }), run("Flutter 셸 + three.js iframe(postMessage), GitHub Pages(https) 게시. 헤드리스 검증 훅 window.__HOLE.")]));

/* 1. 비전 & 벤치마킹 */
children.push(H("1. 게임 비전 & 벤치마킹", HeadingLevel.HEADING_1));
children.push(P("컨셉: 「굴려라 왕자님」/「괴혼(카타마리 다마시)」의 “굴려서 키운다” 손맛 + Hole.io류 모바일 캐주얼의 짧고 반복적인 레벨·광고 수익 구조. 한 판 30초~2분, “한 판만 더” 도파민.", { run: { size: 19 } }));
children.push(H("벤치마킹 대상", HeadingLevel.HEADING_2));
children.push(simpleTable(["게임", "배울 점", "적용 포인트"], [
  ["굴려라 왕자님 / 괴혼", "굴려서 키우는 손맛, 2인 대전(더 많이 차지)", "코어 손맛, 멀티 경쟁 모드(§7)"],
  ["Hole.io", "구멍 성장, 전면광고 빈도, 스킨 IAP", "핵심 흡수 손맛, 스킨 상점"],
  ["Going Balls", "레벨 진행 + 보상형 광고 코인·부활", "레벨 맵 진행, 부활 광고"],
  ["Hole and Fill 류", "시간연장·자석 등 소모성 부스트", "인게임 아이템"],
  ["Voodoo 공통", "클리어 후 보상 2배, 스타터팩", "보상 2배·스타터팩 IAP"],
], [2100, 4060, 3200]));
children.push(H("실패/종료 조건 (벤치마킹 확인됨)", HeadingLevel.HEADING_2));
children.push(bullet("Hole.io는 약 2분 타임어택이 기본 — Classic=점수 경쟁, Solo=제한시간 내 도시 전부 흡수, Battle=시간제한 없이 더 큰 홀에 먹히면 탈락(최후 1인)."));
children.push(bullet([run("우리 게임 결론: ", { bold: true }), run("시간제 + 목표 크기 미달 실패 기본 + 큰 블랙홀에 닿으면 즉시 실패", { bold: true }), run(". 부활(광고/보석)로 같은 자리 재개.")]));

/* 2. 핵심 게임플레이 */
children.push(H("2. 핵심 게임플레이 (기본 게임 — 최우선)", HeadingLevel.HEADING_1));
children.push(runs([run("코어 루프: ", { bold: true }), run("구멍 이동(드래그/방향키/자이로) → 자기보다 작은 물건/몬스터 흡수 → 면적 성장 → 더 큰 대상 흡수 → 목표 크기/제한시간 달성 → 성공/실패", { size: 19 })]));
children.push(H("홀 색 규칙 (즉시 인지)", HeadingLevel.HEADING_2));
children.push(bullet([run("보라색 홀 🟣 ", { bold: true, color: PURPLE }), run("= 나보다 작아 흡수 가능 (콤보·점수 적립)")]));
children.push(bullet([run("검은색 홀 ⚫ ", { bold: true }), run("= 나보다 큰 위험 홀/보스 (닿으면 빠져서 실패, 더 커진 뒤 덮어서 제거)")]));
children.push(H("콤보 시스템 (신규 기획)", HeadingLevel.HEADING_2));
children.push(bullet("발동: 20초 내 고득점 달성 또는 홀 N개 이상 제거 → 볼이 불꽃/전기/별빛 볼로 변신(연출 강화)."));
children.push(bullet("유지/끊김: 20초 경과 후 3초 안에 홀을 제거하면 콤보 유지, 못하면 끊김 → 볼 원복."));
children.push(H("기본 빌드에서 정식화할 것", HeadingLevel.HEADING_2));
[["레벨 파라미터화", "목표 크기·제한시간·맵 크기·물건/몬스터 구성·장애물을 레벨 데이터로 분리"],
 ["별 3개 채점", "시간/크기/흡수 개수 기준 1~3성"],
 ["장애물·위험", "너무 큰 대상, 움직이는 물건, 블랙홀/보스"],
 ["콤보/점수", "연속 흡수 시 코인 보너스"]].forEach(([a, b]) =>
  children.push(bullet([run(a + ": ", { bold: true }), run(b)])));

/* 3. 레벨 1000 */
children.push(new Paragraph({ pageBreakBefore: true, heading: HeadingLevel.HEADING_1, children: [run("3. 레벨 시스템 — 1,000 레벨", { bold: true })] }));
children.push(bullet([run("구조: ", { bold: true }), run("20 월드 × 50 레벨 = 1,000. 월드 = 테마 + 난이도 밴드.")]));
children.push(P("테마 확장: 작은 방 → 집 → 골목 → 마을 → 시장 → 학교 → 묘지 → 사당 → 숲 → 산 → 강 → 바다 → 사막 → 설원 → 화산 → 폐허 → 지하 → 하늘 → 저승 → 우주 (50레벨 단위 20블록, 테마마다 다른 몬스터 — 별도 베스티어리 문서).", { run: { size: 19 } }));
children.push(H("제작 전략 (현실적으로 1,000개)", HeadingLevel.HEADING_2));
children.push(bullet("절차 생성(seed) + 난이도 곡선식으로 ~950개 자동 생성 (난이도 = f(world, levelInWorld) → 목표크기·시간·밀도·hazard)."));
children.push(bullet("핵심 50개(월드 첫/끝, 10단위 마일스톤)는 수작업 튜닝(보스/특수 기믹)."));
children.push(bullet("levels.json로 콘텐츠/코드 분리. 헤드리스 시뮬로 클리어 가능성 자동 검증."));
children.push(bullet("진행 저장: localStorage — 최고 레벨, 별점, 코인/보석/아이템, 광고제거, 설정."));

/* 4. 아이템 */
children.push(H("4. 인게임 아이템 (Hole 게임 벤치마킹)", HeadingLevel.HEADING_1));
children.push(H("소모성 (라운드 전 최대 2개 장착)", HeadingLevel.HEADING_2));
children.push(simpleTable(["아이템", "효과", "획득"], [
  ["⏱️ 시간 연장", "시작 시간 +15초", "코인/광고"],
  ["🧲 자석", "흡수 가능한 대상을 끌어당기는 반경 ↑ (10초)", "코인/광고"],
  ["⚡ 스피드 부스트", "이동속도 +30% (8초)", "코인"],
  ["🚀 가속 로켓", "폭발적 직진 돌진. 멀티에선 상대 진영 파고들어 빼앗기", "코인/광고"],
  ["🦘 점프", "짧게 점프 — 큰(검정) 구멍·위험·상대 방해 회피", "코인/광고"],
  ["🟢 시작 크기 업", "시작 반지름 +20%", "코인"],
  ["✨ 코인 2배", "이번 판 코인 획득 ×2", "광고/보석"],
], [2400, 4960, 2000]));
children.push(bullet([run("부활(Continue): ", { bold: true }), run("실패 시 같은 위치 +10초. 1회차 보상형 광고, 2회차+ 보석.")]));
children.push(bullet([run("영구 업그레이드: ", { bold: true }), run("시작 크기/자석 반경/성장률/시작 시간 Lv (코인, 상한으로 페이투윈 방지).")]));
children.push(bullet([run("스킨: ", { bold: true }), run("구멍 테두리/이펙트, 사운드 팩 (IAP 또는 코인).")]));

/* 5. 수익화 */
children.push(H("5. 수익화 (광고 중심 + IAP 보조)", HeadingLevel.HEADING_1));
children.push(H("광고 (메인)", HeadingLevel.HEADING_2));
children.push(simpleTable(["유형", "위치/트리거", "비고"], [
  ["보상형(Rewarded)", "부활 / 보상2배 / 아이템 무료 / 일일 코인 / 자석", "핵심 수익·유저 자발적"],
  ["전면(Interstitial)", "레벨 클리어·실패 후 N판마다(2~3판)", "빈도 캡, 첫 5레벨 노출X"],
  ["배너(Banner)", "홈/로비 하단 (인게임X)", "광고제거 IAP로 제거"],
], [2400, 4960, 2000]));
children.push(H("인앱결제 (보조)", HeadingLevel.HEADING_2));
children.push(simpleTable(["상품", "내용", "형태"], [
  ["🚫 광고 제거", "전면·배너 제거(보상형 유지)", "영구"],
  ["🪙 코인팩", "소·중·대", "소비성"],
  ["💎 보석팩", "부활·고급아이템용", "소비성"],
  ["🎁 스타터팩", "광고제거+코인+아이템(할인)", "1회 한정"],
  ["📅 시즌/배틀패스", "레벨 진행 보상 트랙", "기간제(후기)"],
], [2400, 4960, 2000]));
children.push(bullet([run("재화: ", { bold: true }), run("코인(soft, 클리어·광고) / 보석(hard, IAP·드물게 보상).")]));
children.push(bullet([run("웹 단계: ", { bold: true }), run("광고를 “더미 광고(5초 대기 모달)”로 먼저 구현 → 앱 래핑 시 AdMob 연동.")]));

/* 6. 화면 & 플로우 */
children.push(new Paragraph({ pageBreakBefore: true, heading: HeadingLevel.HEADING_1, children: [run("6. 화면 설계 & 플로우", { bold: true })] }));

children.push(H("6.1 마스터 플로우 (진입 → 홈 → 플레이 → 성공/실패)", HeadingLevel.HEADING_2));
[
  ["앱 실행 (Splash/로딩)", 0],
  ["└ 최초 실행? — 예 → 튜토리얼 레벨 1~3 / 아니오 → 홈", 1],
  ["홈 화면 / 로비", 0],
  ["└ 레벨 맵 · 상점 · 설정 · 일일 보상", 1],
  ["레벨 선택 → 라운드 준비(아이템 장착) → 플레이", 0],
  ["플레이 → [라운드 종료 판정]", 0],
  ["├ 목표 달성 → 성공 화면 → 별점·코인 지급", 1],
  ["│   └ 보상 2배 광고? 예 → ×2 지급 / 건너뛰기", 2],
  ["│       └ N판마다 전면광고 → 다음 레벨 → 플레이", 2],
  ["└ 시간초과/실패 → 실패 화면", 1],
  ["    └ 부활? 광고/보석 → 플레이 재개 / 포기", 2],
  ["        └ 재도전? 예 → 라운드 준비 / 아니오 → 홈", 2],
].forEach(([t, i]) => children.push(flow(t, i)));

children.push(H("6.2 게임 진입 (Splash / 온보딩)", HeadingLevel.HEADING_2));
["로고 스플래시 → 에셋·레벨데이터 로드", "└ 저장데이터 없음 → 튜토리얼 / 있음 → 홈"].forEach((t, i) => children.push(flow(t, i ? 1 : 0)));

children.push(H("6.3 홈 화면 / 로비", HeadingLevel.HEADING_2));
children.push(bullet("상단: 코인🪙 · 보석💎 · 설정⚙️"));
children.push(bullet("중앙: ▶ PLAY(현재 레벨) 큰 버튼 + 레벨 맵 진입"));
children.push(bullet("하단 탭: 🗺️레벨맵 · 🛒상점 · 🎁일일보상 · 🏆랭킹(후기) · (광고제거 전)배너"));

children.push(H("6.4 플레이 (인게임 HUD)", HeadingLevel.HEADING_2));
children.push(bullet("HUD: 크기 · 제한시간(경고색) · 목표 진행바 · 흡수 개수 · 일시정지⏸ · 장착 아이템(1~2)"));
["라운드 시작·카운트다운 → 플레이 루프", "└ 물건/몬스터 흡수 → 성장 → HUD 갱신", "└ 목표 달성? 예 → 성공 / 시간 0? 예 → 실패 / 아니오 → 루프 지속"].forEach((t, i) => children.push(flow(t, i ? 1 : 0)));

children.push(H("6.5 성공 시 (Win)", HeadingLevel.HEADING_2));
["성공! → 별점 연출 1~3⭐ → 코인·진행도 저장", "└ 보상 2배 광고? 시청 → 코인×2 / 아니오 → 다음 레벨·홈 선택", "└ N판마다 전면광고"].forEach((t, i) => children.push(flow(t, i ? 1 : 0)));
children.push(P("요소: “목표 달성! 🎉”, 별 3개, 획득 코인, [보상 2배 ▶광고], [다음 레벨], [홈]", { run: { size: 18, italics: true, color: "666666" } }));

children.push(H("6.6 실패 시 (Lose)", HeadingLevel.HEADING_2));
["실패(시간초과/목표미달/블랙홀에 빠짐)", "└ 부활? ▶광고 또는 💎보석 → +10초 같은 자리 재개 / 아니오", "    └ 재도전 → 라운드 준비 / 홈으로"].forEach((t, i) => children.push(flow(t, i)));
children.push(P("요소: “아쉬워요!”, 현재 크기/목표 대비, [부활 ▶광고](1회 무료), [다시하기], [홈]", { run: { size: 18, italics: true, color: "666666" } }));

/* 7. 멀티플레이 경쟁 모드 (신규) */
children.push(new Paragraph({ pageBreakBefore: true, heading: HeadingLevel.HEADING_1, children: [run("7. 멀티플레이 경쟁 모드 (신규)", { bold: true })] }));
children.push(P("벤치마킹: 「굴려라 왕자님」/「괴혼(카타마리 다마시)」 — 둘이 굴려 더 많이 차지하는 대전 손맛.", { run: { size: 19 } }));
children.push(H("개요", HeadingLevel.HEADING_2));
children.push(bullet("같은 맵에서 제한 시간 내 실시간 경쟁(1:1 우선, 추후 N인)."));
children.push(bullet("각 플레이어는 자기 색의 서로 다른 구멍 세트를 배정(나=보라, 상대=주황). 같은 맵, 다른 목표."));
children.push(H("빼앗기(스틸) — 핵심 재미", HeadingLevel.HEADING_2));
children.push(bullet([run("상대 구멍을 메우면(=먹으면): ", { bold: true }), run("내 획득 카운트 +1, 상대 쪽에 구멍이 더 생성(페널티 스폰).")]));
children.push(bullet("내 구멍만 메우면 안전하지만, 상대 구멍을 빼앗으면 점수도 벌고 상대를 방해. 단 상대 구멍이 나보다 크면(검정) 빼앗다 빠질 위험."));
children.push(H("승패 & 랭킹", HeadingLevel.HEADING_2));
children.push(bullet("획득 카운트(내 구멍 + 빼앗은 상대 구멍)순 순위. 인게임 실시간 점수바 + 종료 후 랭킹 화면, 시즌 리더보드(후기)."));
children.push(H("경쟁 특화 아이템 / 구현 단계", HeadingLevel.HEADING_2));
children.push(bullet([run("🚀 가속 로켓: ", { bold: true }), run("상대 진영으로 돌진해 구멍 빼앗기. "), run("🦘 점프: ", { bold: true }), run("큰 구멍·상대 방해·위험 지대 건너뛰기.")]));
children.push(bullet("1차 봇(AI) 대전으로 메커니즘 구현(기존 구멍 색·메우기·빠짐 구조 재활용, 구멍에 owner 추가) → 2차 WebSocket 실시간 동기화(서버 권위적)."));

/* 8. 페인트 모드 (신규) */
children.push(new Paragraph({ pageBreakBefore: true, heading: HeadingLevel.HEADING_1, children: [run("8. 페인트 모드 (신규)", { bold: true })] }));
children.push(P("컨셉: 굴리는 손맛 + 색칠놀이/잉크 점유(스플래툰류). 바닥 캔버스를 페인트 볼로 굴러 칠해 그림을 완성한다.", { run: { size: 19 } }));
children.push(H("개요 & 페인트", HeadingLevel.HEADING_2));
children.push(bullet("바닥이 캔버스(목표 그림 밑그림·영역별 지정색). 페인트 장착 → 볼이 지나간 자리에 색이 칠해짐(트레일)."));
children.push(bullet("제한시간 내 목표 그림 N%(예 90%) 이상 칠하면 클리어. 영역별 지정색 일치 시 정확도 보너스."));
children.push(bullet("페인트 잔량 게이지 소모 → 맵의 페인트 통(리필 지점)에서 보충·색 교체."));
children.push(H("물 괴물(방해) — 핵심 갈등", HeadingLevel.HEADING_2));
children.push(bullet("물 괴물(물풍선·해파리·물대포 등)이 칠한 자리를 씻어 지움(원상복구)."));
children.push(bullet("볼에 물을 끼얹어 일정시간 ‘젖음’ → 페인트 못 칠함(마르거나 페인트 통 거치면 회복). 젖은 구역엔 페인트가 안 묻음."));
children.push(bullet("대응: 물 괴물을 굴려 납작(squash) 시키거나 회피하고, 마르기 전 빠르게 칠한다."));
children.push(H("채점 / 아이템 / 구현", HeadingLevel.HEADING_2));
children.push(bullet("채점: 완성도(%) + 색 정확도 + 남은 시간 → 별 1~3개."));
children.push(bullet([run("아이템: ", { bold: true }), run("🎨 페인트 리필 · 🛡️ 방수 코팅(물 면역) · 🖌️ 큰 붓(트레일 폭↑).")]));
children.push(bullet("구현: 바닥 CanvasTexture에 볼 위치마다 스탬프 → 목표 마스크 대비 칠해진 픽셀 비율로 완성도. water 몬스터 종류 추가."));

/* 9. 이벤트 미니게임 2종 (신규) */
children.push(new Paragraph({ pageBreakBefore: true, heading: HeadingLevel.HEADING_1, children: [run("9. 이벤트 미니게임 (눈사람·쇠똥구리)", { bold: true })] }));
children.push(P("「괴혼」의 굴려서 키우는 손맛을 테마만 바꿔 재활용. 이벤트 모드에 카드로 추가.", { run: { size: 19 } }));
children.push(H("⛄ 눈사람 만들기", HeadingLevel.HEADING_2));
children.push(bullet("작은 눈덩이를 굴려 군데군데 쌓인 눈·눈더미와 작은 눈으로 된 몬스터/눈사람 인간을 흡수해 키운다."));
children.push(bullet("커질수록 더 큰 대상 흡수(눈송이→눈뭉치→눈몬스터→큰 눈더미). 다양한 크기의 눈 소스 배치."));
children.push(bullet([run("클리어(미션별 택1): ", { bold: true }), run("(A) 목표 크기의 눈덩이 1개 완성, 또는 (B) 눈덩이 2개(몸통+머리)로 눈사람 완성.")]));
children.push(bullet("연출: 눈 결정 디테일, 완성 시 눈·코(당근)·팔(나뭇가지)·모자. 움직이는 눈몬스터는 흡수/회피 대상."));
children.push(H("🪲 쇠똥구리 (똥 굴리기)", HeadingLevel.HEADING_2));
children.push(bullet("쇠똥구리(딱정벌레)가 되어 마을에 가득한 소똥을 굴려 하나의 큰 똥덩어리로 키운다."));
children.push(bullet([run("클리어: ", { bold: true }), run("흩어진 소똥(크기 다양)을 흡수해 목표 크기 똥덩어리 완성. (선택) 다른 쇠똥구리 경쟁·장애물 회피.")]));
children.push(bullet("연출: 공(똥덩어리) 뒤에서 뒷다리로 미는 쇠똥구리, 똥덩어리 질감."));
children.push(H("공통 구현", HeadingLevel.HEADING_2));
children.push(bullet("기존 굴리기(roll) 엔진 재활용(흡수=성장, size 태그). 눈사람=2볼 합체/목표크기 분기, 쇠똥구리=단일 목표크기. 이벤트 메뉴 카드 추가, 아이템 호환, 테마 비주얼만 교체."));

/* 10. 로드맵 */
children.push(new Paragraph({ pageBreakBefore: true, heading: HeadingLevel.HEADING_1, children: [run("10. 개발 로드맵 (기본 게임 우선)", { bold: true })] }));
children.push(simpleTable(["단계", "내용", "상태"], [
  ["Phase 0 — 기본 게임 정련", "3D 홀 흡수 코어, HUD, 자이로 수정, 웹 게시 / 홀 모드 정식화·별3개·콤보·코인", "일부 완료 ✅"],
  ["Phase 1 — 레벨 시스템", "레벨 데이터 모델·로더·난이도 곡선, 진행 저장, 레벨 맵 UI, 절차생성+검증", "예정"],
  ["Phase 2 — 메타", "홈/로비, 코인·보석 재화, 상점, 일일 보상, 설정", "예정"],
  ["Phase 3 — 아이템", "소모성 5종 + 부활 + 영구 업그레이드 + 스킨", "예정"],
  ["Phase 4 — 수익화", "보상형/전면/배너(웹 더미광고), IAP 자리, 빈도 정책", "예정"],
  ["Phase 5 — 콘텐츠", "1차 600레벨(12월드) 생성·밸런싱·폴리시 → 출시 (이후 1,000까지 시즌 업데이트)", "예정"],
  ["Phase 6 — 출시·퍼블리싱", "앱 래핑(Flutter/Capacitor)+AdMob/IAP 실연동, 스토어/QA, 퍼블리셔 계약·소프트론치→글로벌", "진행 중"],
], [2700, 5460, 1200]));

/* 11. 기술/리스크 */
children.push(H("11. 기술 메모 & 리스크", HeadingLevel.HEADING_1));
children.push(bullet("현재: 단일 HTML + Three.js(r128). 콘텐츠 확장 시 levels.json 외부화. 포팅 방향: Flutter 셸 + three.js iframe/postMessage."));
children.push(bullet("게시: GitHub Pages(https) — 모바일 자이로/센서는 https 필수."));
children.push(bullet("검증: 프리뷰 헤드리스 eval로 자동 스모크/밸런싱."));
children.push(simpleTable(["리스크", "대응"], [
  ["1,000레벨 단조로움", "월드 테마·기믹·보스, 절차생성+수작업 혼합"],
  ["페이투윈 불만", "아이템은 가속/구제, 기본은 무과금 클리어 가능"],
  ["웹 광고 SDK 제약", "더미광고로 플로우 선구현 → 앱 래핑 시 실연동"],
  ["성능(오브젝트 수)", "풀링, 거리 컬링, MAX 캡"],
], [3000, 6360]));

/* 빌드 */
const doc = new Document({
  styles: {
    default: { document: { run: { font: FONT, size: 20, color: INK } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 30, bold: true, font: FONT, color: ORANGE },
        paragraph: { spacing: { before: 280, after: 140 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 23, bold: true, font: FONT, color: BLUE },
        paragraph: { spacing: { before: 160, after: 90 }, outlineLevel: 1 } },
    ],
  },
  numbering: { config: [
    { reference: "b", levels: [
      { level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 460, hanging: 260 } } } },
      { level: 1, format: LevelFormat.BULLET, text: "◦", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 860, hanging: 260 } } } },
    ] },
  ]},
  sections: [{
    properties: { page: {
      size: { width: 12240, height: 15840 },
      margin: { top: 1080, right: 1440, bottom: 1080, left: 1440 },
    }},
    children,
  }],
});

Packer.toBuffer(doc).then(buf => {
  const out = path.join(__dirname, "hole_game_plan.docx");
  fs.writeFileSync(out, buf);
  console.log("WROTE", out, buf.length, "bytes");
});
