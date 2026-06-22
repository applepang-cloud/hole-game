import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/material.dart';

/// web/index.html 의 브리지 함수 (three.js 게임 오버레이 제어)
@JS('holeShowGame')
external void _holeShowGame(JSString mode);
@JS('holeHideGame')
external void _holeHideGame();
@JS('holeRestart')
external void _holeRestart(JSString mode);
@JS('holeInput')
external void _holeInput(double x, double y);
@JS('holeToggle')
external void _holeToggle(JSString what);
@JS('holePause')
external void _holePause();
@JS('holeResume')
external void _holeResume();
@JS('holeMenuMusic')
external void _holeMenuMusic(JSBoolean on);
@JS('holeGetCleared')
external JSString _holeGetCleared();
@JS('holeSetCleared')
external void _holeSetCleared(JSString s);

void main() => runApp(const HoleApp());

/// 게임 모드 정의 — 모드 선택/엔드카드 텍스트를 Flutter가 소유한다.
class GameMode {
  final String id, emoji, title, desc;
  final Color accent;
  const GameMode(this.id, this.emoji, this.title, this.desc, this.accent);
}

const kMaps = <GameMode>[
  GameMode('map1', '🛏️', '맵 1 · 내 방', '개미·쥐·고양이를 굴려 납작! 창밖엔 누가…', Color(0xFF7BBF3A)),
  GameMode('map2', '🌳', '맵 2 · 우리 마당', '정원·집·자동차, 구멍에서 유령이…', Color(0xFF3A8F50)),
  GameMode('map3', '🛒', '맵 3 · 대형 마트', '좀비가 구멍에서! 구멍을 메워 막아라', Color(0xFF2A5A9C)),
  GameMode('map4', '🏫', '맵 4 · 학교', '교실·사물함, 도깨비·해골이 구멍에서', Color(0xFF5AA86A)),
  GameMode('map5', '🏙️', '맵 5 · 도시 거리', '빌딩·버스·시민, 구멍서 도깨비·유령', Color(0xFF6B7280)),
  GameMode('map6', '⚰️', '맵 6 · 저승 공동묘지', '묘비·도깨비불, 해골·유령·저승사자', Color(0xFF7A4FB0)),
];
const kEventModes = <GameMode>[
  GameMode('snow', '⛄', '눈사람 만들기', '눈덩이를 굴려 키워 눈사람 완성!', Color(0xFF4FB0E0)),
  GameMode('dung', '🪲', '쇠똥구리 · 마을', '버섯·풀·꽃 마을의 소똥을 굴려 산까지 뭉개라!', Color(0xFF6B4A2A)),
  GameMode('dungcity', '🌆', '쇠똥구리 · 도시', '소똥 덩어리를 굴려 도시를 통째로 뭉개라!', Color(0xFF8A6238)),
  GameMode('roll', '🟢', '공 굴리기', '끈끈한 공에 물건을 붙여 키운다', Color(0xFF7BBF3A)),
  GameMode('hole', '⚫', '구멍 빨아들이기', '구멍으로 물건을 쏙쏙 삼킨다', Color(0xFF3A3550)),
];

GameMode _modeById(String id) => [...kMaps, ...kEventModes]
    .firstWhere((m) => m.id == id, orElse: () => kMaps.first);

/// 스토리 컷씬 대사 한 줄 (left=화면 왼쪽 NPC / 오른쪽=주인공 퇴마사)
/// img = assets/portraits/<img>.png 파일 키 (캐릭터 초상)
class StoryLine {
  final bool left;
  final String img, name, text;
  const StoryLine(this.left, this.img, this.name, this.text);
}

class MapStory {
  final List<StoryLine> intro, outro;
  const MapStory(this.intro, this.outro);
}

// 주인공: 변신 전 학생(student) → 퇴마사 소년(exorcist). 엄마=teacher2(이미지 재사용).
/// 맵 번호별 시작/종료 대사 (퇴마사 소년 스토리)
const kStory = <int, MapStory>{
  // 맵1 내 방 — 어머니의 폭로 + 변신 (좀 능청스러운 사춘기 아들)
  1: MapStory([
    StoryLine(true, 'teacher2', '엄마', '도현아, 잠깐 앉아봐. 진지한 얘기야.'),
    StoryLine(false, 'student', '도현', '또 방 치우라는 거지? 이따 한다니까…'),
    StoryLine(true, 'teacher2', '엄마', '아니. 우리 집안은 대대로 악령을 쫓는 「퇴마사」 가문이란다.'),
    StoryLine(false, 'student', '도현', '…엄마 또 밤새 드라마 봤구나.'),
    StoryLine(true, 'teacher2', '엄마', '요즘 마을에 싱크홀 자꾸 생기지? 그 구멍마다 악령의 기운이 흘러나와.'),
    StoryLine(true, 'teacher2', '엄마', '이건 네 아버지가 쓰던 퇴마복이야. 이제 네 차례란다.'),
    StoryLine(false, 'student', '도현', '에이 설마… 어? 옷이 저절로 빛나는데?!'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '뭐야 이거… 힘이 솟잖아! …나 좀, 멋있는데?'),
  ], [
    StoryLine(false, 'exorcist', '퇴마사 도현', '방 안 싱크홀, 깔끔하게 봉인 완료!'),
    StoryLine(true, 'teacher2', '엄마', '역시 내 아들. 근데 책상 밑은 아직 안 치웠더라?'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '…엄마, 그건 악령이 아니라 그냥 내 양말이야.'),
    StoryLine(true, 'teacher2', '엄마', '암튼! 마당으로 번지고 있어. 어서 가자.'),
  ]),
  // 맵2 마당 — 엄마의 잔소리 + 자신감 붙는 도현
  2: MapStory([
    StoryLine(true, 'teacher2', '엄마', '잔디 사이로 구멍이 뽕뽕! 유령이 스멀스멀 올라와!'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '걱정 마. 한 판 굴렸더니 감 잡았어.'),
    StoryLine(true, 'teacher2', '엄마', '자만 말고! 옆집 화단은 밟지 마라, 또 변상해야 해.'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '엄마, 나 지금 세계를 구하는 중이라고…'),
  ], [
    StoryLine(false, 'exorcist', '퇴마사 도현', '마당 구멍 전부 봉인! 화단도 무사하고.'),
    StoryLine(true, 'teacher2', '엄마', '장하다 우리 아들. 마트 사장님이 도와달라고 난리야.'),
  ]),
  // 맵3 마트 — 능청 사장님
  3: MapStory([
    StoryLine(true, 'shop1', '마트 사장', '퇴마사님!! 좀비가 1+1 시식코너를 싹 다 먹어치웠어요!'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '구멍부터 막죠. 좀비는 공짜를 못 참거든요.'),
    StoryLine(true, 'shop2', '마트 사장', '냉동코너에서 자꾸 기어나와요, 빨리요 빨리!'),
  ], [
    StoryLine(false, 'exorcist', '퇴마사 도현', '좀비 구멍 봉인 끝. 시식은… 좀 늦었네요.'),
    StoryLine(true, 'shop2', '마트 사장', '그래도 살았어요! 학교 선생님이 SOS 보냈대요.'),
  ]),
  // 맵4 학교 — 선생님과 티키타카
  4: MapStory([
    StoryLine(true, 'teacher1', '선생님', '도현 학생! 마침 잘 왔어요. 도깨비가 칠판에 낙서를…'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '선생님, 저 이제 학생 아니고 퇴마사예요.'),
    StoryLine(true, 'teacher1', '선생님', '그럼 결석 처리할게요. …농담이에요, 부탁해요!'),
  ], [
    StoryLine(false, 'exorcist', '퇴마사 도현', '교실 구멍 정리 끝! 도깨비도 하교시켰습니다.'),
    StoryLine(true, 'teacher1', '선생님', '역시! 근데 도시가 난리래요. 조심해요.'),
  ]),
  // 맵5 도시 — 큰 위협의 전조 + 아버지 떡밥
  5: MapStory([
    StoryLine(true, 'citizen', '시민', '퇴마사님! 도시가 통째로 가라앉을 판이에요!'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '사람들 대피시키세요. 큰 놈이… 느껴진다.'),
    StoryLine(true, 'cityteacher2', '도시 선생님', '맞아요, 묘지 쪽 기운이 제일 사나워요.'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '역시 마지막은 거기군. 아버지가 마지막으로 향한 곳…'),
  ], [
    StoryLine(false, 'exorcist', '퇴마사 도현', '도시 봉인 완료. 이제 진짜 마지막이다.'),
    StoryLine(true, 'citizen', '시민', '꼭 살아 돌아오셔야 해요!'),
  ]),
  // 맵6 공동묘지 — 좀비 → 묘지기, 아버지의 진실
  6: MapStory([
    StoryLine(true, 'zombie1', '좀비', '크아아아—!'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '윽…! 여기, 악령의 기운이 가장 짙어…!'),
    StoryLine(true, 'keeper', '묘지기', '기다렸네, 젊은 퇴마사여. 자네… 그 사람의 아들이군.'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '…아버지를, 아세요?'),
    StoryLine(true, 'keeper', '묘지기', '이곳을 지키다 봉인 속으로 사라졌지. 이젠 자네 차례다.'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '알겠어요. 아버지가 못 끝낸 일, 제가 끝낼게요!'),
  ], [
    StoryLine(false, 'exorcist', '퇴마사 도현', '모든 싱크홀을 봉인했다! 악령은 물러갔어.'),
    StoryLine(true, 'keeper', '묘지기', '해냈군. 자네 아버지가 무척 자랑스러워할 게야.'),
    StoryLine(false, 'exorcist', '퇴마사 도현', '…고마워요. 이제 집에 가서, 양말부터 치워야겠어요.'),
    StoryLine(true, 'keeper', '묘지기', '허허, 진정한 퇴마사로군.'),
  ]),
};

int? _mapNum(String? id) =>
    (id != null && id.startsWith('map')) ? int.tryParse(id.substring(3)) : null;

class HoleApp extends StatelessWidget {
  const HoleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '홀 인 더 다크 (Hole in the Dark)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Malgun Gothic',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8552D)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _mode; // 현재 진행 중인 모드
  bool _playing = false; // 인게임(HUD 오버레이) 여부
  Map<String, dynamic>? _result; // 엔드카드 데이터(null이면 미표시)
  Map<String, dynamic> _state = const {}; // 최신 인게임 HUD 상태
  Rect? _stage; // 게임 스테이지(레터박스) 사각형 — HUD 정렬용
  bool _music = true, _sound = true, _gyro = false; // 오디오/자이로 토글 상태
  bool _paused = false; // 일시정지 여부

  String _screen = 'home'; // 'home' | 'story' | 'event' (플레이/대사 아닐 때)
  bool _storyMode = false; // 현재 진행이 스토리인지
  Set<int> _cleared = {}; // 클리어한 맵 번호
  int? _fingerMap; // 스토리 리스트에서 손가락으로 가리킬 맵 번호
  List<StoryLine>? _dialogue; // 대사 컷씬(진행 중이면 non-null)
  VoidCallback? _dialogueDone; // 대사 끝난 뒤 콜백
  int? _dlgBg; // 대사 배경 맵 번호(bgN.jpg)
  int _dlgKey = 0; // 컷씬마다 새 상태 보장용

  @override
  void initState() {
    super.initState();
    // 게임(three.js) → Flutter 메시지 수신 등록
    globalContext['__holeOnGameMsg'] = ((JSString json) {
      _onGameMsg(json.toDart);
    }).toJS;
    // 스토리 진행도 로드
    try {
      final s = _holeGetCleared().toDart;
      _cleared = s.split(',').where((e) => e.isNotEmpty).map(int.parse).toSet();
    } catch (_) {}
  }

  void _saveCleared() {
    try {
      _holeSetCleared((_cleared.toList()..sort()).join(',').toJS);
    } catch (_) {}
  }

  void _onGameMsg(String json) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['type']) {
      case 'state': // 인게임 HUD 갱신(초당 1회 + 이벤트 시)
        _state = msg;
        if (_playing && mounted) setState(() {});
        break;
      case 'layout': // 스테이지 사각형 → HUD 정렬
        _stage = Rect.fromLTWH(
          (msg['x'] as num).toDouble(),
          (msg['y'] as num).toDouble(),
          (msg['w'] as num).toDouble(),
          (msg['h'] as num).toDouble(),
        );
        if (mounted) setState(() {});
        break;
      case 'controls': // 오디오/자이로 토글 상태 동기화
        _music = msg['music'] == true;
        _sound = msg['sound'] == true;
        _gyro = msg['gyro'] == true;
        if (mounted) setState(() {});
        break;
      case 'over': // 게임 오버
        _holeHideGame();
        final win = msg['win'] == true;
        final num = _mapNum(_mode);
        if (_storyMode && win && num != null) {
          // 스토리 클리어 → 진행도 저장 + 종료 대사 → 리스트(다음 맵 손가락)
          _cleared.add(num);
          _saveCleared();
          final next = num + 1;
          setState(() {
            _playing = false;
            _paused = false;
            _result = null;
          });
          _startDialogue(kStory[num]?.outro ?? const [], () {
            setState(() {
              _screen = 'story';
              _fingerMap = (next <= kMaps.length && !_cleared.contains(next)) ? next : null;
            });
          }, bg: num);
        } else {
          setState(() {
            _playing = false;
            _paused = false;
            _result = msg;
          });
        }
        break;
      case 'home': // 인게임 "← 홈" 버튼 → 홈/스토리 리스트 복귀
        setState(() {
          _playing = false;
          _paused = false;
          _result = null;
          _screen = _storyMode ? 'story' : 'home';
        });
        break;
    }
  }

  // 대사 컷씬 시작 (lines 비면 즉시 onDone)
  void _startDialogue(List<StoryLine> lines, VoidCallback onDone, {int? bg}) {
    if (lines.isEmpty) {
      onDone();
      return;
    }
    setState(() {
      _dialogue = lines;
      _dialogueDone = onDone;
      _dlgBg = bg;
      _dlgKey++;
    });
  }

  void _endDialogue() {
    final done = _dialogueDone;
    setState(() {
      _dialogue = null;
      _dialogueDone = null;
    });
    done?.call();
  }

  // 이벤트 모드 시작 (스토리 아님)
  void _play(String mode) {
    _storyMode = false;
    setState(() {
      _mode = mode;
      _result = null;
      _paused = false;
      _playing = true;
    });
    _holeShowGame(mode.toJS);
  }

  // 스토리 맵 시작 → 시작 대사 후 게임 시작
  void _playStory(int num) {
    _storyMode = true;
    _mode = 'map$num';
    _fingerMap = null;
    _startDialogue(kStory[num]?.intro ?? const [], () {
      setState(() {
        _result = null;
        _paused = false;
        _playing = true;
      });
      _holeShowGame('map$num'.toJS);
    }, bg: num);
  }

  // 다시 하기(같은 맵/모드)
  void _again() {
    final mode = _mode ?? 'roll';
    setState(() {
      _result = null;
      _paused = false;
      _playing = true;
    });
    _holeRestart(mode.toJS);
  }

  // 홈 복귀 — 스토리면 맵 리스트로, 아니면 홈으로
  void _toHome() {
    setState(() {
      _result = null;
      _paused = false;
      _playing = false;
      _screen = _storyMode ? 'story' : 'home';
    });
    _holeHideGame();
  }

  // 일시정지 / 재개
  void _pause() {
    _holePause();
    setState(() => _paused = true);
  }

  void _resume() {
    _holeResume();
    setState(() => _paused = false);
  }

  @override
  Widget build(BuildContext context) {
    // 홈 메뉴 + 스토리 대사 등 비게임 화면에선 main 음악, 실제 게임 중엔 정지
    final menuMusic = _dialogue != null || !_playing;
    _holeMenuMusic(menuMusic.toJS);
    final Widget content;
    if (_dialogue != null) {
      content = _DialogueOverlay(
        key: ValueKey('dlg$_dlgKey'),
        lines: _dialogue!,
        bg: _dlgBg,
        onDone: _endDialogue,
      );
    } else if (_result != null) {
      content = KeyedSubtree(
        key: const ValueKey('end'),
        child: _withBackdrop(_EndCard(
          result: _result!,
          onAgain: _again,
          onHome: _toHome,
        )),
      );
    } else if (_playing) {
      // 인게임: 배경 투명(뒤의 게임 iframe이 비침) + HUD 오버레이(입력·토글·일시정지)
      content = _HudOverlay(
        key: const ValueKey('hud'),
        state: _state,
        stage: _stage,
        music: _music,
        sound: _sound,
        gyro: _gyro,
        paused: _paused,
        onInput: (x, y) => _holeInput(x, y),
        onToggle: (what) => _holeToggle(what.toJS),
        onPause: _pause,
        onResume: _resume,
        onRestart: _again,
        onHome: _toHome,
      );
    } else if (_screen == 'story') {
      content = KeyedSubtree(
        key: const ValueKey('story'),
        child: _withBackdrop(_StoryList(
          cleared: _cleared,
          fingerMap: _fingerMap,
          onPlay: _playStory,
          onBack: () => setState(() {
            _screen = 'home';
            _fingerMap = null;
          }),
        )),
      );
    } else if (_screen == 'event') {
      content = KeyedSubtree(
        key: const ValueKey('event'),
        child: _withBackdrop(_EventSelect(
          onPlay: _play,
          onBack: () => setState(() => _screen = 'home'),
        )),
      );
    } else {
      content = KeyedSubtree(
        key: const ValueKey('home'),
        child: _withBackdrop(_HomeMenu(
          onStory: () => setState(() => _screen = 'story'),
          onEvent: () => setState(() => _screen = 'event'),
        )),
      );
    }
    // Scaffold 자체는 항상 투명 — 불투명 화면은 _withBackdrop이 직접 그라데이션을 깐다.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: content,
      ),
    );
  }

  // 홈/엔드카드용 불투명 배경(그라데이션) — 화면 전체 채움
  Widget _withBackdrop(Widget child) => Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBFEAFF), Color(0xFF8FD2F5), Color(0xFF6CC05E)],
          ),
        ),
        child: SafeArea(child: child),
      );
}

/// 인게임 HUD를 Flutter로 그리는 투명 오버레이.
/// 게임이 보내준 stage 사각형(레터박스) 안에 게임 DOM HUD와 동일 좌표로 배치하고,
/// 이동 입력(조이스틱)과 오디오/자이로 토글까지 Flutter가 받아 게임 엔진으로 전달한다.
class _HudOverlay extends StatelessWidget {
  const _HudOverlay({
    super.key,
    required this.state,
    required this.stage,
    required this.music,
    required this.sound,
    required this.gyro,
    required this.paused,
    required this.onInput,
    required this.onToggle,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });
  final Map<String, dynamic> state;
  final Rect? stage;
  final bool music, sound, gyro, paused;
  final void Function(double x, double y) onInput;
  final void Function(String what) onToggle;
  final VoidCallback onPause, onResume, onRestart, onHome;

  static const _cream = Color(0xFFFFF7E6);
  static const _ink = Color(0xFF4A3B2A);
  static const _muted = Color(0xFF9B8A72);
  static const _org = Color(0xFFE8552D);
  static const _grn = Color(0xFF7BBF3A);
  static const _red = Color(0xFFEF5350);

  static const _panel = BoxDecoration(
    color: _cream,
    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3)),
    borderRadius: BorderRadius.all(Radius.circular(14)),
    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rect = stage ?? Rect.fromLTWH(0, 0, size.width, size.height);
    return Stack(
      children: [
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: _stageContent(rect.width),
        ),
      ],
    );
  }

  Widget _stageContent(double stageW) {
    return Stack(
      children: [
        // 이동 입력(조이스틱) — 맨 아래 레이어. 위의 버튼이 우선 히트테스트됨.
        if (!paused) Positioned.fill(child: _GameInputLayer(onInput: onInput)),
        // HUD 표시(크기/타이머/카운트/목표) — 입력을 막지 않도록 IgnorePointer
        IgnorePointer(child: _readout(stageW)),
        // 체력 게이지 (좌하단) + 피격 시 게이지 번쩍 + 아파하는 주인공 얼굴/윽!
        if (state['hasHp'] == true) Positioned(left: 10, bottom: 16, child: _hpBar()),
        if (state['hasHp'] == true && state['hurt'] == true)
          Positioned(left: 8, bottom: 38, child: IgnorePointer(child: _hurtFace())),
        // 오디오/자이로 토글 (우하단)
        Positioned(right: 10, bottom: 14, child: _audioBar()),
        // 일시정지 버튼 (상단 중앙)
        Positioned(top: 8, left: 0, right: 0, child: Center(child: _pauseBtn())),
        // 일시정지 메뉴
        if (paused) Positioned.fill(child: _pauseModal()),
      ],
    );
  }

  // 피격 시 게이지 옆에 뜨는 아파하는 주인공 얼굴 + 윽!
  Widget _hurtFace() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF3B3B), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x88FF2222), blurRadius: 10)],
          ),
          clipBehavior: Clip.antiAlias,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Color(0x55FF2222), BlendMode.srcATop),
            child: Image.asset('assets/portraits/exorcist.png', fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox()),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xEEFF3B3B), borderRadius: BorderRadius.circular(8)),
          child: const Text('윽!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _hpBar() {
    final p = ((state['hpPct'] as num?)?.toDouble() ?? 1).clamp(0.0, 1.0);
    final col = p < 0.3 ? const Color(0xFFFF3B3B) : p < 0.6 ? const Color(0xFFFFB13A) : const Color(0xFF4AD06A);
    final hp = (state['hp'] as num?)?.toInt() ?? 0;
    final hpMax = (state['hpMax'] as num?)?.toInt() ?? 0;
    final hurt = state['hurt'] == true;
    return SizedBox(
      width: 178,
      child: Row(
        children: [
          Text('❤️', style: TextStyle(fontSize: hurt ? 19 : 15)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0x55000000),
                border: Border.all(color: hurt ? const Color(0xFFFF3B3B) : Colors.white, width: hurt ? 3 : 2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: hurt ? const [BoxShadow(color: Color(0xAAFF2222), blurRadius: 10)] : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: p == 0 ? 0.001 : p,
                      child: DecoratedBox(decoration: BoxDecoration(color: col)),
                    ),
                  ),
                  Center(
                    child: Text('$hp / $hpMax',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [Shadow(color: Color(0xAA000000), blurRadius: 2)])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pauseBtn() {
    return Opacity(
      opacity: 0.92,
      child: Material(
        color: _cream,
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPause,
          child: const SizedBox(
            width: 40, height: 40,
            child: Center(child: Text('⏸', style: TextStyle(fontSize: 18))),
          ),
        ),
      ),
    );
  }

  Widget _pauseModal() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 뒤 입력 차단
      onTap: () {},
      child: Container(
        color: const Color(0xCC0A0D12),
        alignment: Alignment.center,
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏸ 일시정지',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
              const SizedBox(height: 18),
              _pauseAction('▶  계속하기', const Color(0xFF7BBF3A), onResume),
              const SizedBox(height: 10),
              _pauseAction('🔄  다시하기', const Color(0xFFEF5D1E), onRestart),
              const SizedBox(height: 10),
              _pauseAction('🏠  홈으로', const Color(0xFF3A3550), onHome),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseAction(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 3,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _readout(double stageW) {
    final sizeStr = (state['size'] ?? '') as String;
    final mmss = (state['mmss'] ?? '0:00') as String;
    final warn = state['warn'] == true;
    final count = (state['count'] as num?)?.toInt() ?? 0;
    final countLabel = (state['countLabel'] ?? '') as String;
    final double goalPct =
        ((state['goalPct'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0).toDouble();
    final goalText = (state['goalText'] ?? '') as String;
    final goalW = stageW * 0.74 > 300 ? 300.0 : stageW * 0.74;

    return Stack(
      children: [
        // 좌상단 크기 패널
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            constraints: const BoxConstraints(minWidth: 118),
            padding: const EdgeInsets.fromLTRB(13, 7, 13, 8),
            decoration: _panel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('크기',
                    style: TextStyle(fontSize: 10, color: _muted, letterSpacing: 1)),
                Text(sizeStr,
                    style: const TextStyle(
                        fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, color: _org)),
              ],
            ),
          ),
        ),
        // 우상단 타이머 + 카운트
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: _panel,
                child: Text(mmss,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: warn ? _red : _ink)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: _panel,
                child: Text('$countLabel $count',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: _grn)),
              ),
            ],
          ),
        ),
        // 상단 중앙 목표 게이지
        Positioned(
          top: 62,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: goalW,
              child: _goalBar(goalPct, goalText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _audioBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _audioBtn('↗', true, () => onToggle('tab')),
        const SizedBox(width: 7),
        _audioBtn('📱', gyro, () => onToggle('gyro')),
        const SizedBox(width: 7),
        _audioBtn('♪', music, () => onToggle('music')),
        const SizedBox(width: 7),
        _audioBtn(sound ? '🔊' : '🔇', sound, () => onToggle('sound')),
      ],
    );
  }

  Widget _audioBtn(String label, bool on, VoidCallback onTap) {
    return Opacity(
      opacity: on ? 1.0 : 0.45,
      child: Material(
        color: _cream,
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(child: Text(label, style: const TextStyle(fontSize: 17))),
          ),
        ),
      ),
    );
  }

  Widget _goalBar(double pct, String text) {
    return Container(
      height: 15,
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: pct,
            heightFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF9BE15D), Color(0xFF5FB524)]),
              ),
            ),
          ),
          Center(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF3C5A18))),
          ),
        ],
      ),
    );
  }
}

/// 이동 입력 레이어 — 드래그를 게임 조이스틱과 동일하게 매핑해 onInput(x,y, -1..1)으로 전달.
/// 게임의 moveStick(max=46, deadzone>6)을 그대로 복제한다. 떠다니는 조이스틱도 직접 그린다.
class _GameInputLayer extends StatefulWidget {
  const _GameInputLayer({required this.onInput});
  final void Function(double x, double y) onInput;
  @override
  State<_GameInputLayer> createState() => _GameInputLayerState();
}

class _GameInputLayerState extends State<_GameInputLayer> {
  static const double _max = 46, _dead = 6;
  Offset? _origin;
  Offset _knob = Offset.zero;

  void _start(Offset p) {
    setState(() {
      _origin = p;
      _knob = Offset.zero;
    });
    widget.onInput(0, 0);
  }

  void _move(Offset p) {
    if (_origin == null) return;
    var d = p - _origin!;
    final mag = d.distance;
    if (mag > _max) d = d * (_max / mag);
    setState(() => _knob = d);
    widget.onInput(d.distance > _dead ? d.dx / _max : 0, d.distance > _dead ? d.dy / _max : 0);
  }

  void _end() {
    if (_origin == null) return;
    setState(() => _origin = null);
    widget.onInput(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _start(e.localPosition),
      onPointerMove: (e) => _move(e.localPosition),
      onPointerUp: (e) => _end(),
      onPointerCancel: (e) => _end(),
      child: origin == null
          ? const SizedBox.expand()
          : Stack(
              children: [
                Positioned(
                  left: origin.dx - 60,
                  top: origin.dy - 60,
                  width: 120,
                  height: 120,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x33FFFFFF),
                      border: Border.fromBorderSide(
                          BorderSide(color: Color(0x88FFFFFF), width: 3)),
                    ),
                  ),
                ),
                Positioned(
                  left: origin.dx - 27 + _knob.dx,
                  top: origin.dy - 27 + _knob.dy,
                  width: 54,
                  height: 54,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFFFE7BD)],
                      ),
                      border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 3)),
                      boxShadow: [
                        BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// 홈 메뉴 = 스토리 / 이벤트 두 버튼
class _HomeMenu extends StatelessWidget {
  const _HomeMenu({required this.onStory, required this.onEvent});
  final VoidCallback onStory, onEvent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/portraits/exorcist.png',
                width: 96, height: 96, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Text('🧑‍🚀', style: TextStyle(fontSize: 70))),
          ),
          const SizedBox(height: 6),
          const Text('홀 인 더 다크',
              style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: Color(0xFFE8552D), offset: Offset(0, 4), blurRadius: 0)])),
          const Text('Hole in the Dark · 퇴마사 소년',
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _bigMenu('📖', '스토리', '맵을 순서대로 모험', const Color(0xFFEF5D1E), onStory),
          const SizedBox(height: 16),
          _bigMenu('🎪', '이벤트', '다른 방식 게임 2종', const Color(0xFF3A3550), onEvent),
        ],
      ),
    );
  }

  Widget _bigMenu(String emoji, String title, String sub, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 280,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        elevation: 6,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ),
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 스토리 = 맵 번호별 리스트 (잠금/해금·클리어 표시·다음 맵 손가락 안내)
class _StoryList extends StatelessWidget {
  const _StoryList({required this.cleared, required this.fingerMap, required this.onPlay, required this.onBack});
  final Set<int> cleared;
  final int? fingerMap;
  final void Function(int num) onPlay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 8),
      Row(children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: Colors.white)),
        const Text('📖 스토리',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      ]),
      if (fingerMap != null)
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('👆 다음 맵을 골라봐!',
              style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
          itemCount: kMaps.length,
          itemBuilder: (ctx, i) {
            final num = i + 1;
            final unlocked = num == 1 || cleared.contains(num - 1);
            final done = cleared.contains(num);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _StoryCard(
                mode: kMaps[i],
                unlocked: unlocked,
                cleared: done,
                finger: fingerMap == num,
                onTap: unlocked ? () => onPlay(num) : null,
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.mode, required this.unlocked, required this.cleared, required this.finger, required this.onTap});
  final GameMode mode;
  final bool unlocked, cleared, finger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Opacity(
      opacity: unlocked ? 1 : 0.5,
      child: Material(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        elevation: finger ? 8 : 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: finger
                ? BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEF5D1E), width: 3))
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Container(
                width: 46, height: 46, alignment: Alignment.center,
                decoration: BoxDecoration(color: mode.accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                child: Text(mode.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mode.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF4A3B2A))),
                  const SizedBox(height: 2),
                  Text(mode.desc, style: const TextStyle(fontSize: 11, color: Color(0xFF9B8A72))),
                ]),
              ),
              if (cleared) const Text('⭐', style: TextStyle(fontSize: 22))
              else if (!unlocked) const Icon(Icons.lock, color: Color(0xFF9B8A72))
              else Icon(Icons.play_circle_fill, color: mode.accent, size: 30),
            ]),
          ),
        ),
      ),
    );
    if (!finger) return card;
    return Stack(clipBehavior: Clip.none, children: [
      card,
      const Positioned(right: -4, bottom: -12, child: _FingerHint()),
    ]);
  }
}

/// 통통 튀는 손가락 안내
class _FingerHint extends StatefulWidget {
  const _FingerHint();
  @override
  State<_FingerHint> createState() => _FingerHintState();
}

class _FingerHintState extends State<_FingerHint> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) => Transform.translate(
        offset: Offset(-_c.value * 8, -_c.value * 4),
        child: const Text('👆', style: TextStyle(fontSize: 34)),
      ),
    );
  }
}

/// 이벤트 = 2개 게임 모드 선택
class _EventSelect extends StatelessWidget {
  const _EventSelect({required this.onPlay, required this.onBack});
  final void Function(String mode) onPlay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 8),
      Row(children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: Colors.white)),
        const Text('🎪 이벤트',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      ]),
      const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text('두 가지 방식 중 골라봐!', style: TextStyle(fontSize: 13, color: Colors.white70)),
      ),
      for (final m in kEventModes)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: _ModeCard(mode: m, onTap: () => onPlay(m.id)),
        ),
    ]);
  }
}

/// 스토리 컷씬 — 좌우 캐릭터 + 말풍선, 탭하여 진행
class _DialogueOverlay extends StatefulWidget {
  const _DialogueOverlay({super.key, required this.lines, required this.onDone, this.bg});
  final List<StoryLine> lines;
  final VoidCallback onDone;
  final int? bg; // 배경 맵 번호(bgN.jpg)
  @override
  State<_DialogueOverlay> createState() => _DialogueOverlayState();
}

class _DialogueOverlayState extends State<_DialogueOverlay> {
  int _i = 0;

  void _next() {
    if (_i < widget.lines.length - 1) {
      setState(() => _i++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.lines[_i];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _next,
      child: Container(
        constraints: const BoxConstraints.expand(),
        color: const Color(0xFF0A0D12),
        child: Stack(children: [
          // 맵별 배경 이미지 (bgN.jpg)
          if (widget.bg != null)
            Positioned.fill(
              child: Image.asset('assets/backgrounds/bg${widget.bg}.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, s) => const SizedBox.expand()),
            ),
          // 배경 위 어둡게(가독성) — 약한 스크림
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x22000000), Color(0x99000000)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
          child: Stack(children: [
            // 말풍선 — 말하는 캐릭터 이미지 위로(겹치지 않게)
            Positioned(
              left: 14, right: 14,
              bottom: 24 + 237 + 16,   // 캐릭터(이미지225+패딩12, bottom24) 위로 띄움
              child: Align(
                alignment: line.left ? Alignment.centerLeft : Alignment.centerRight,
                child: _bubble(line),
              ),
            ),
            // 좌우 캐릭터 (하단)
            Positioned(left: 14, bottom: 24, child: _char(line, true)),
            Positioned(right: 14, bottom: 24, child: _char(line, false)),
            const Positioned(
              bottom: 6, left: 0, right: 0,
              child: Center(child: Text('▶ 탭하여 계속', style: TextStyle(color: Colors.white70, fontSize: 13))),
            ),
            // 스킵 — 대사 건너뛰고 바로 시작
            Positioned(
              top: 8, right: 10,
              child: Material(
                color: const Color(0x66000000),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onDone,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text('건너뛰기 ▶▶',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ]),
        ),
        ]),
      ),
    );
  }

  // 왼쪽 슬롯=NPC, 오른쪽 슬롯=주인공. 말하는 캐릭터는 크게/선명, 상대는 작게/흐리게.
  Widget _char(StoryLine line, bool leftSlot) {
    // 이 슬롯의 최근(현재까지) 캐릭터 — 없으면 표시 안 함
    StoryLine? c;
    for (int k = _i; k >= 0; k--) {
      if (widget.lines[k].left == leftSlot) { c = widget.lines[k]; break; }
    }
    if (c == null) return const SizedBox(width: 1, height: 1);
    final speaking = line.left == leftSlot;
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: speaking ? 1.0 : 0.84,
      child: Opacity(
        opacity: speaking ? 1.0 : 0.55,
        // 캐릭터 뒤 검은 반투명 패널 — 배경 위에서 캐릭터가 또렷하게
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xAA000000),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, spreadRadius: 2)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/portraits/${c.img}.png',
                width: 198, height: 225, fit: BoxFit.cover,
                errorBuilder: (ctx, e, s) => const SizedBox(width: 198, height: 225)),
          ),
        ),
      ),
    );
  }

  Widget _bubble(StoryLine line) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: line.left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(line.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFE8552D))),
          const SizedBox(height: 5),
          Text(line.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF2B2335), height: 1.25)),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});
  final GameMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Material(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(mode.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mode.title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4A3B2A))),
                      const SizedBox(height: 2),
                      Text(mode.desc,
                          style: const TextStyle(
                              fontSize: 11.5, color: Color(0xFF9B8A72))),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill, color: mode.accent, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 게임 오버 → Flutter 엔드카드
class _EndCard extends StatelessWidget {
  const _EndCard({
    required this.result,
    required this.onAgain,
    required this.onHome,
  });
  final Map<String, dynamic> result;
  final VoidCallback onAgain, onHome;

  @override
  Widget build(BuildContext context) {
    final win = result['win'] == true;
    final modeId = (result['mode'] ?? 'roll') as String;
    final mode = _modeById(modeId);
    final isRoom = modeId == 'room';
    final isRoll = modeId == 'roll';
    final size = (result['size'] ?? '') as String;
    final count = (result['count'] as num?)?.toInt() ?? 0;
    final roomTotal = (result['roomTotal'] as num?)?.toInt() ?? 0;
    final reason = (result['reason'] ?? '') as String;

    final title = win
        ? (isRoom ? '클리어! 🎉' : '목표 달성! 🎉')
        : (reason.isNotEmpty ? reason : '시간 종료!');
    final countLine = isRoom
        ? '없앤 구멍 $count / $roomTotal'
        : '${isRoll ? '모은 물건 ' : '빨아들인 '}$count개';
    final msg = win
        ? (isRoom
            ? '방 안의 구멍을 모두 없앴다!'
            : (isRoll ? '멋진 별이 완성됐어요!' : '온 동네를 다 삼켰다!'))
        : '다음엔 더 크게!';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(win ? '🏆' : '⏰', style: const TextStyle(fontSize: 56)),
          Text(title,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0xFFE8552D), offset: Offset(0, 3), blurRadius: 0)
                  ])),
          const SizedBox(height: 18),
          Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                Text(size,
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: mode.accent)),
                const SizedBox(height: 6),
                Text(countLine,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A3B2A))),
                const SizedBox(height: 4),
                Text(msg,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF9B8A72))),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: onAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5D1E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 5,
              ),
              child: const Text('🔄  다시 하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 280,
            child: OutlinedButton(
              onPressed: onHome,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF7E6),
                foregroundColor: const Color(0xFF4A3B2A),
                side: const BorderSide(color: Colors.white, width: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('모드 선택',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
