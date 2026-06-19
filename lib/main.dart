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
  GameMode('roll', '🟢', '공 굴리기', '끈끈한 공에 물건을 붙여 키운다', Color(0xFF7BBF3A)),
  GameMode('hole', '⚫', '구멍 빨아들이기', '구멍으로 물건을 쏙쏙 삼킨다', Color(0xFF3A3550)),
];

GameMode _modeById(String id) => [...kMaps, ...kEventModes]
    .firstWhere((m) => m.id == id, orElse: () => kMaps.first);

class HoleApp extends StatelessWidget {
  const HoleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '굴려라! — 데굴데굴 별왕자',
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

  @override
  void initState() {
    super.initState();
    // 게임(three.js) → Flutter 메시지 수신 등록
    globalContext['__holeOnGameMsg'] = ((JSString json) {
      _onGameMsg(json.toDart);
    }).toJS;
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
      case 'over': // 게임 오버 → iframe 숨기고 Flutter 엔드카드 표시
        _holeHideGame();
        setState(() {
          _playing = false;
          _paused = false;
          _result = msg;
        });
        break;
      case 'home': // 인게임 "← 홈" 버튼 → 홈 복귀
        setState(() {
          _playing = false;
          _paused = false;
          _result = null;
        });
        break;
    }
  }

  // 모드 선택 → 게임 시작
  void _play(String mode) {
    setState(() {
      _mode = mode;
      _result = null;
      _paused = false;
      _playing = true;
    });
    _holeShowGame(mode.toJS);
  }

  // 다시 하기(같은 모드) — 엔드카드 / 일시정지 공용
  void _again() {
    final mode = _mode ?? 'roll';
    setState(() {
      _result = null;
      _paused = false;
      _playing = true;
    });
    _holeRestart(mode.toJS);
  }

  // 홈 복귀 — 엔드카드 / 일시정지 공용
  void _toHome() {
    setState(() {
      _result = null;
      _paused = false;
      _playing = false;
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
    final Widget content;
    if (_result != null) {
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
    } else {
      content = KeyedSubtree(
        key: const ValueKey('home'),
        child: _withBackdrop(_ModeSelect(onPlay: _play)),
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

  // 홈/엔드카드용 불투명 배경(그라데이션)
  Widget _withBackdrop(Widget child) => Container(
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
        // 오디오/자이로 토글 (우하단)
        Positioned(right: 10, bottom: 14, child: _audioBar()),
        // 일시정지 버튼 (상단 중앙)
        Positioned(top: 8, left: 0, right: 0, child: Center(child: _pauseBtn())),
        // 일시정지 메뉴
        if (paused) Positioned.fill(child: _pauseModal()),
      ],
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

/// 홈 = 맵 선택 + 이벤트 모드
class _ModeSelect extends StatefulWidget {
  const _ModeSelect({required this.onPlay});
  final void Function(String mode) onPlay;
  @override
  State<_ModeSelect> createState() => _ModeSelectState();
}

class _ModeSelectState extends State<_ModeSelect> {
  bool _eventScreen = false; // 이벤트 모드 선택 화면 여부

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          const Text('🤴', style: TextStyle(fontSize: 56)),
          const Text('굴려라!',
              style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0xFFE8552D), offset: Offset(0, 4), blurRadius: 0)
                  ])),
          const Text('데굴데굴 별왕자',
              style: TextStyle(
                  fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          if (!_eventScreen) ..._mainMenu() else ..._eventMenu(),
          const SizedBox(height: 12),
          const Text('반다이남코 「괴혼」 오마주 · Flutter 셸 + three.js',
              style: TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // 메인: 맵 3개 + 이벤트 모드 진입 버튼
  List<Widget> _mainMenu() => [
        for (final m in kMaps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ModeCard(mode: m, onTap: () => widget.onPlay(m.id)),
          ),
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          child: Material(
            color: const Color(0xFF3A3550),
            borderRadius: BorderRadius.circular(16),
            elevation: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _eventScreen = true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text('🎪', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('이벤트 모드',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];

  // 이벤트 모드: 2개 게임 모드 중 하나 선택 + 뒤로
  List<Widget> _eventMenu() => [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text('🎪 이벤트 모드 · 게임 선택',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        for (final m in kEventModes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ModeCard(mode: m, onTap: () => widget.onPlay(m.id)),
          ),
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _eventScreen = false),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0x33FFFFFF),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('뒤로', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ];
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
