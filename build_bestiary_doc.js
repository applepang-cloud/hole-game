const path = require("path");
const fs = require("fs");
const GROOT = "C:/Users/song/AppData/Roaming/npm/node_modules";
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, LevelFormat, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageOrientation, ExternalHyperlink,
} = require(path.join(GROOT, "docx"));

const FONT = "Malgun Gothic";          // 한글 지원 (Windows 기본)
const INK = "2B2335", ORANGE = "E8552D", PURPLE = "7A4FB0", BLACK = "111111";
const HEADFILL = "F4C430", ROWALT = "FFF7E6", PURPLEFILL = "EBE3F6", BLACKFILL = "DDDADE";

const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const CM = { top: 60, bottom: 60, left: 110, right: 110 };

function run(text, o = {}) { return new TextRun({ text, font: FONT, ...o }); }
function P(text, o = {}) { return new Paragraph({ children: [run(text, o.run || {})], ...o.p }); }
function H(text, level) { return new Paragraph({ heading: level, children: [run(text, { bold: true })] }); }
function bullet(text, bold) {
  return new Paragraph({ numbering: { reference: "b", level: 0 },
    children: Array.isArray(text) ? text : [run(text, { bold: !!bold })] });
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

/* ============ 테마별 몬스터 진행표 데이터 (20블록 × 50레벨 = 1000) ============ */
const THEMES = [
  ["1","1–50","작은 방","먼지·잡귀","먼지뭉치, 머리카락 요괴, 작은 도깨비불","침대 밑 그림자(블랙)"],
  ["2","51–100","집 안","집귀신·살림 요괴","부엌칼귀, 시계 도깨비, 거울 귀신","거대 장롱귀(블랙)"],
  ["3","101–150","골목·계단","그림자·길귀","그슨대(소), 골목 그림자, 들개 악령","그슨대(거대·올려볼수록 커짐)"],
  ["4","151–200","마을 어귀","도깨비","도깨비, 도깨비불, 장승 도깨비","도깨비 대장(블랙)"],
  ["5","201–250","시장·장터","잡귀 떼·초기 좀비","시장 좀비, 떠돌이 악령, 굶주린 혼령","굶주린 무리(스웜 블랙)"],
  ["6","251–300","학교·폐교","학교괴담 악령","처녀귀신, 화장실 귀신, 계단 귀신","빨간마스크(블랙)"],
  ["7","301–350","공동묘지","언데드","스켈레톤, 좀비, 구울","강시(점프 추격·블랙)"],
  ["8","351–400","사당·신당","원귀·저주","몽달귀신, 원귀, 저주 인형","저주받은 신상(블랙)"],
  ["9","401–450","숲","숲 정령·요수","나무 정령, 늑대 요괴, 버섯 괴물","거대 멧돼지신(블랙)"],
  ["10","451–500","산·계곡","산신·요호","구미호, 산도깨비, 까마귀 떼","호랑이 산신(거대 블랙)"],
  ["11","501–550","강·호수","물귀신","물귀신, 이무기(새끼), 가재 요괴","이무기(거대·블랙)"],
  ["12","551–600","바다·해변","해괴·심해","인어 요괴, 문어 괴물, 조개 악령","크라켄(블랙)"],
  ["13","601–650","사막·유적","모래·고대","모래 악령, 미라, 풍뎅이 괴물","거대 모래벌레(블랙)"],
  ["14","651–700","설원·빙하","빙결 요괴","얼음 정령, 눈 괴물, 서리 늑대","서리 거인(블랙)"],
  ["15","701–750","화산·용암","불 정령·마수","화염 정령, 용암 골렘, 불도마뱀","화산 드래곤(블랙)"],
  ["16","751–800","폐허·공장","기계·오염 괴물","고철 좀비, 오염 슬라임, 드론 악귀","거대 폐기물 골렘(블랙)"],
  ["17","801–850","지하·동굴 심부","심층 언데드","레이스, 본 드래곤, 그림자 마수","리치(블랙)"],
  ["18","851–900","하늘·구름성","천공 요괴","뇌조(번개새), 구름 정령, 깃털 마수","천둥 거신(블랙)"],
  ["19","901–950","저승·명계","명계 사자","저승사자, 명부 귀졸, 망령 무리","명왕(보스 블랙)"],
  ["20","951–1000","우주·심연","이계 이형","별 먹는 벌레, 공허 촉수, 운석 골렘","공허신(최종 블랙홀)"],
];

/* ============ 카테고리별 베스티어리 ============ */
// [이름, 외형(로우폴리), 행동/역할, 등장 테마, 색]
const CATS = [
  ["A. 잡귀 · 먼지류 (튜토리얼~초반)", [
    ["먼지뭉치", "회색 솜털 구체 + 작은 눈", "느리게 떠다님, 가장 약한 흡수 대상", "방·집", "보라"],
    ["머리카락 요괴", "검은 실타래 + 외눈", "꿈틀대며 도망, 잡으면 콤보 적립", "방·골목", "보라"],
    ["작은 도깨비불", "파란/주황 불꽃 점", "지그재그 부유, 빛 점멸", "방·마을", "보라"],
    ["침대 밑 그림자", "넓적한 검은 형체", "처음 만나는 '나보다 큰' 위험 홀", "방", "블랙"],
  ]],
  ["B. 한국 전통 요괴 · 악령", [
    ["도깨비", "뿔 하나, 방망이, 통통한 체형", "껑충 뛰며 접근, 중간 흡수 대상", "마을", "보라"],
    ["그슨대", "올려다볼수록 커지는 검은 우장 형체", "쳐다보면 성장 → 시선 피해야 함(기믹)", "골목", "보라→블랙"],
    ["처녀귀신", "긴 머리·소복, 가려진 얼굴", "머리카락으로 옭아 속도 저하", "학교·폐교", "보라"],
    ["몽달귀신", "총각 원귀, 창백한 청년", "원한으로 광역 저주(시간 감소)", "사당", "보라"],
    ["구미호", "아홉 꼬리 여우, 우아함", "빠르게 회피, 잡으면 큰 콤보", "산", "보라"],
    ["이무기", "용이 못 된 거대 물뱀", "강·호수의 보스급 위험 홀", "강·바다", "블랙"],
    ["강시", "관복·부적, 뻣뻣하게 점프", "통통 튀며 추격하는 위험 홀", "공동묘지", "블랙"],
    ["저승사자", "검은 갓·도포, 명부", "명계 정예, 광역 끌어당김", "저승", "블랙"],
  ]],
  ["C. 언데드 · 좀비 (티어 진행)", [
    ["스켈레톤", "흰 뼈, 덜그럭", "기본 언데드, 무리로 등장", "묘지·동굴", "보라"],
    ["좀비", "썩은 살, 느린 걸음", "느리지만 수가 많음", "시장·묘지·폐허", "보라"],
    ["구울", "굶주린 식시귀, 날카로운 손톱", "빠른 돌진, 중간 위협", "묘지", "보라"],
    ["레이스", "반투명 망령, 검은 로브", "벽 통과·점멸 이동", "동굴 심부", "보라"],
    ["리치", "왕관 쓴 해골 마법사", "언데드 군주(보스), 소환", "동굴 심부", "블랙"],
  ]],
  ["D. 자연 정령 · 원소 괴수", [
    ["나무/숲 정령", "이끼 덮인 통나무 골렘", "느리고 단단, 큰 흡수 대상", "숲", "보라"],
    ["얼음 정령", "각진 빙정 결정체", "미끄러짐 유발 장판", "설원", "보라"],
    ["화염 정령 / 용암 골렘", "이글거리는 마그마 덩어리", "접촉 시 가열(위험)", "화산", "보라→블랙"],
    ["모래벌레", "거대한 마디 벌레", "땅속 잠복 후 솟구침(위험)", "사막", "블랙"],
    ["서리 거인 / 화산 드래곤", "테마 보스 거수", "맵을 압박하는 거대 블랙홀", "설원·화산", "블랙"],
  ]],
  ["E. 우주 · 이계 이형 (최종 테마)", [
    ["별 먹는 벌레", "발광 마디 + 다수 눈", "별빛을 흡수하며 증식", "우주", "보라"],
    ["공허 촉수", "검보라색 점멸 촉수", "화면 밖에서 휘둘러 옴", "심연", "보라→블랙"],
    ["운석 골렘", "암석+크리스탈 거구", "낙하 충격파", "우주", "보라"],
    ["공허신", "차원을 삼키는 최종 보스", "게임의 마지막 블랙홀", "심연", "블랙"],
  ]],
];

const TIERS = [
  ["언데드 라인", "스켈레톤 → 좀비 → 구울 → 레이스 → 리치(군주)"],
  ["한국 요괴 라인", "잡귀 → 도깨비 → 처녀/몽달귀신 → 구미호 → 이무기/저승사자"],
  ["원소 라인", "작은 정령 → 정령 → 원소 골렘 → 테마 거수(보스)"],
  ["콤보 변신 볼", "기본 볼 → (콤보 발동) 불꽃 볼 → 전기 볼 → 화려한 별빛 볼 → (종료) 원복"],
];

const SOURCES = [
  ["한국의 전통 요괴 — 나무위키", "https://namu.wiki/w/한국의 전통 요괴"],
  ["그슨대 — 나무위키", "https://namu.wiki/w/그슨대"],
  ["저승사자 — 나무위키", "https://namu.wiki/w/저승사자"],
  ["구미호 — 나무위키", "https://namu.wiki/w/구미호"],
  ["Hole.io — Wikipedia", "https://en.wikipedia.org/wiki/Hole.io"],
  ["Hole.io All Modes Guide — WriterParty", "https://writerparty.com/party/hole-io-all-modes-guide-how-to-win-in-classic-battle-and-solo-modes/"],
  ["Undead types/tiers — EN World", "https://www.enworld.org/threads/undead-family-trees.183392/"],
];

/* ===================== 문서 조립 ===================== */
const children = [];

// 표지
children.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 200, after: 60 },
  children: [run("굴려라! — 데굴데굴 별왕자", { bold: true, size: 44, color: ORANGE })] }));
children.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 },
  children: [run("테마별 몬스터 기획 자료 · 베스티어리(Bestiary)", { bold: true, size: 28, color: INK })] }));
children.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 240 },
  children: [run("자료 조사 정리본 v0.1 · 2026-06-19 · 한국 요괴 + 글로벌 언데드/괴수 혼합", { size: 18, color: "777777" })] }));

// 1. 개요
children.push(H("1. 몬스터 설계 원칙", HeadingLevel.HEADING_1));
[
  ["홀에서 나오는 몬스터를 ", "테마별로 차등", " — 진행할수록 새 종족이 등장해 질림 방지."],
  ["세계 확장: ", "작은 방 → 집 → 마을 → 도시 → 자연 → 대륙 → 하늘 → 저승 → 우주", "로 스케일이 커진다."],
  ["정서: ", "한국 전통 요괴·악령", "(도깨비·처녀귀신·그슨대·구미호·이무기·강시·저승사자) + 글로벌 ", ],
].forEach(()=>{});
children.push(bullet([run("홀에서 나오는 몬스터를 ", {}), run("테마별로 차등", { bold: true }), run(" — 진행할수록 새 종족이 등장해 질림 방지.", {})]));
children.push(bullet([run("세계 확장: ", {}), run("작은 방 → 집 → 마을 → 자연 → 대륙 → 하늘 → 저승 → 우주", { bold: true }), run(" 순으로 스케일이 커진다.", {})]));
children.push(bullet([run("정서 혼합: ", {}), run("한국 전통 요괴·악령", { bold: true }), run(" + 글로벌 ", {}), run("언데드/좀비·원소 괴수·이계 이형", { bold: true }), run(". 초반은 친근한 잡귀, 후반은 거대 보스.", {})]));
children.push(bullet([run("비주얼: ", {}), run("로우폴리 + 플랫셰이딩", { bold: true }), run(" 통일. 과하지 않게, 색으로 위험도를 즉시 인지.", {})]));
children.push(bullet([run("밸런스: ", {}), run("몬스터(흡수 대상)는 아이템 없이도 처치 가능", { bold: true }), run(", 보스/블랙홀은 충분히 커진 뒤 도전.", {})]));

// 2. 색·역할 규칙
children.push(H("2. 색 · 역할 규칙 (즉시 인지)", HeadingLevel.HEADING_1));
{
  const w = [3200, 6160];
  children.push(new Table({ width: { size: 9360, type: WidthType.DXA }, columnWidths: w, rows: [
    headRow(["구분", "의미 / 연출"], w),
    new TableRow({ children: [
      cell(P("보라색 홀 🟣", { run: { bold: true, size: 18, color: PURPLE } }), { w: w[0], fill: PURPLEFILL }),
      cell("나보다 작아 흡수 가능한 몬스터/물건. 가까이 가면 빨려 들어와 콤보·점수 적립.", { w: w[1] }) ] }),
    new TableRow({ children: [
      cell(P("검은색 홀 ⚫", { run: { bold: true, size: 18, color: BLACK } }), { w: w[0], fill: BLACKFILL }),
      cell("나보다 큰 위험 홀/보스. 닿으면 내가 빠져 실패. 더 커진 뒤에야 덮어서 제거 가능.", { w: w[1] }) ] }),
    new TableRow({ children: [
      cell(P("콤보 변신 볼 ✨", { run: { bold: true, size: 18, color: ORANGE } }), { w: w[0], fill: ROWALT }),
      cell("콤보 발동 시 불꽃/전기/별빛 볼로 변신(연출 강화), 콤보 종료 시 원복.", { w: w[1] }) ] }),
  ]}));
}

// 3. 테마별 진행표
children.push(H("3. 테마별 몬스터 진행표 (20블록 × 50레벨 = 1,000)", HeadingLevel.HEADING_1));
{
  const w = [760, 1300, 1900, 2300, 3300, 3400]; // sum 12960 (landscape content)
  const rows = [ headRow(["블록", "레벨", "테마", "몬스터 패밀리", "대표 몬스터", "위험 요소(블랙홀)"], w) ];
  THEMES.forEach((t, i) => {
    const fill = i % 2 ? ROWALT : undefined;
    rows.push(new TableRow({ children: t.map((v, c) =>
      cell(P(v, { run: { size: 17, bold: c === 0 } }), { w: w[c], fill })) }));
  });
  children.push(new Table({ width: { size: 12960, type: WidthType.DXA }, columnWidths: w, rows }));
}

// 4. 카테고리별 베스티어리
children.push(new Paragraph({ pageBreakBefore: true, heading: HeadingLevel.HEADING_1,
  children: [run("4. 카테고리별 베스티어리 (상세)", { bold: true })] }));
CATS.forEach(([title, rowsData]) => {
  children.push(H(title, HeadingLevel.HEADING_2));
  const w = [2000, 3260, 4000, 1900, 1800]; // sum 12960
  const rows = [ headRow(["몬스터", "외형(로우폴리)", "행동 / 역할", "등장 테마", "홀 색"], w) ];
  rowsData.forEach((r, i) => {
    const fill = i % 2 ? ROWALT : undefined;
    const colorCell = r[4].includes("블랙") ? BLACKFILL : r[4].includes("보라") ? PURPLEFILL : fill;
    rows.push(new TableRow({ children: [
      cell(P(r[0], { run: { size: 17, bold: true } }), { w: w[0], fill }),
      cell(P(r[1], { run: { size: 17 } }), { w: w[1], fill }),
      cell(P(r[2], { run: { size: 17 } }), { w: w[2], fill }),
      cell(P(r[3], { run: { size: 17 } }), { w: w[3], fill }),
      cell(P(r[4], { run: { size: 17, bold: true } }), { w: w[4], fill: colorCell }),
    ] }));
  });
  children.push(new Table({ width: { size: 12960, type: WidthType.DXA }, columnWidths: w, rows }));
  children.push(P("", { run: { size: 8 } }));
});

// 5. 티어/진화 라인
children.push(H("5. 몬스터 티어 · 진화 라인 (참고)", HeadingLevel.HEADING_1));
{
  const w = [3000, 9960];
  const rows = [ headRow(["라인", "진행"], w) ];
  TIERS.forEach((t, i) => rows.push(new TableRow({ children: [
    cell(P(t[0], { run: { bold: true, size: 18 } }), { w: w[0], fill: i % 2 ? ROWALT : undefined }),
    cell(P(t[1], { run: { size: 18 } }), { w: w[1], fill: i % 2 ? ROWALT : undefined }),
  ] })));
  children.push(new Table({ width: { size: 12960, type: WidthType.DXA }, columnWidths: w, rows }));
}

// 6. 미정/검토
children.push(H("6. 미정 · 추가 검토 사항", HeadingLevel.HEADING_1));
children.push(bullet([run("주인공 정체(법사/신/퇴마사) ", { bold: true }), run("미정", { bold: true, color: ORANGE }), run(" — 확정 시 나래이션 톤·콤보 볼·보스 연출을 여기에 맞춰 보강.", {})]));
children.push(bullet("테마당 대표 몬스터 3종 + 보스 1종 기준 → 총 약 80종. 우선 초반 5테마(방~학교)부터 에셋화."));
children.push(bullet("그슨대 '쳐다보면 커진다' 같은 기믹형 몬스터는 후순위(코어 흡수 손맛 검증 후)."));

// 7. 출처
children.push(H("7. 자료 출처", HeadingLevel.HEADING_1));
SOURCES.forEach(([t, url]) => children.push(new Paragraph({ numbering: { reference: "b", level: 0 },
  children: [ new ExternalHyperlink({ children: [new TextRun({ text: t, style: "Hyperlink", font: FONT, size: 18 })], link: url }) ] })));

/* ===================== 빌드 ===================== */
const doc = new Document({
  styles: {
    default: { document: { run: { font: FONT, size: 20, color: INK } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 30, bold: true, font: FONT, color: ORANGE },
        paragraph: { spacing: { before: 260, after: 140 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: FONT, color: INK },
        paragraph: { spacing: { before: 180, after: 100 }, outlineLevel: 1 } },
    ],
  },
  numbering: { config: [
    { reference: "b", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•",
      alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 460, hanging: 260 } } } }] },
  ]},
  sections: [{
    properties: { page: {
      size: { width: 12240, height: 15840, orientation: PageOrientation.LANDSCAPE },
      margin: { top: 1080, right: 1440, bottom: 1080, left: 1440 },
    }},
    children,
  }],
});

Packer.toBuffer(doc).then(buf => {
  const out = path.join(__dirname, "몬스터_기획자료.docx");
  fs.writeFileSync(out, buf);
  console.log("WROTE", out, buf.length, "bytes");
});
