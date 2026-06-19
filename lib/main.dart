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

void main() => runApp(const HoleApp());

/// 게임 모드 정의 — 모드 선택/엔드카드 텍스트를 Flutter가 소유한다.
class GameMode {
  final String id, emoji, title, desc;
  final Color accent;
  const GameMode(this.id, this.emoji, this.title, this.desc, this.accent);
}

const kModes = <GameMode>[
  GameMode('roll', '🟢', '공 굴리기', '끈끈한 공에 물건을 붙여 키운다', Color(0xFF7BBF3A)),
  GameMode('hole', '⚫', '구멍 빨아들이기', '구멍으로 물건을 쏙쏙 삼킨다', Color(0xFF3A3550)),
  GameMode('room', '🔵', '구멍 피하기', '작은 구멍은 없애고 큰 구멍은 피한다', Color(0xFF2A5A9C)),
];

GameMode _modeById(String id) =>
    kModes.firstWhere((m) => m.id == id, orElse: () => kModes.first);

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
  Map<String, dynamic>? _result; // 엔드카드 데이터(null이면 미표시)

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
    final type = msg['type'];
    if (type == 'over') {
      // 게임 오버 → iframe 숨기고 Flutter 엔드카드 표시
      _holeHideGame();
      setState(() => _result = msg);
    } else if (type == 'home') {
      // 인게임 "← 홈" 버튼 → 홈 복귀
      setState(() => _result = null);
    }
  }

  // 모드 선택 → 게임 시작
  void _play(String mode) {
    setState(() {
      _mode = mode;
      _result = null;
    });
    _holeShowGame(mode.toJS);
  }

  // 엔드카드: 다시 하기(같은 모드)
  void _again() {
    final mode = _mode ?? 'roll';
    setState(() => _result = null);
    _holeRestart(mode.toJS);
  }

  // 엔드카드: 모드 선택(홈 복귀)
  void _toHome() {
    setState(() => _result = null);
    _holeHideGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBFEAFF), Color(0xFF8FD2F5), Color(0xFF6CC05E)],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _result == null
                ? _ModeSelect(key: const ValueKey('home'), onPlay: _play)
                : _EndCard(
                    key: const ValueKey('end'),
                    result: _result!,
                    onAgain: _again,
                    onHome: _toHome,
                  ),
          ),
        ),
      ),
    );
  }
}

/// 홈 = 모드 선택 화면
class _ModeSelect extends StatelessWidget {
  const _ModeSelect({super.key, required this.onPlay});
  final void Function(String mode) onPlay;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('🤴', style: TextStyle(fontSize: 64)),
          const Text('굴려라!',
              style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0xFFE8552D), offset: Offset(0, 4), blurRadius: 0)
                  ])),
          const Text('데굴데굴 별왕자',
              style: TextStyle(
                  fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 28),
          for (final m in kModes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _ModeCard(mode: m, onTap: () => onPlay(m.id)),
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('반다이남코 「괴혼」 오마주 · Flutter 셸 + three.js',
                style: TextStyle(fontSize: 10, color: Colors.white70)),
          ),
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
    super.key,
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
