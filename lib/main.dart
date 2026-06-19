import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/material.dart';

/// web/index.html 의 브리지 함수 (three.js 게임 오버레이 제어)
@JS('holeShowGame')
external void _holeShowGame(JSString? mode);

void main() => runApp(const HoleApp());

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
  String _lastEvent = '';

  @override
  void initState() {
    super.initState();
    // 게임(three.js) → Flutter 메시지 수신 등록
    globalContext['__holeOnGameMsg'] = ((JSString json) {
      setState(() => _lastEvent = json.toDart);
    }).toJS;
  }

  void _play([String? mode]) => _holeShowGame(mode?.toJS);

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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text('🤴', style: TextStyle(fontSize: 64)),
                const Text('굴려라!',
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Color(0xFFE8552D), offset: Offset(0, 4), blurRadius: 0)])),
                const Text('데굴데굴 별왕자',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _bigButton('▶  게임 시작', () => _play()),
                const SizedBox(height: 14),
                _modeButton('🟢 공 굴리기', () => _play('roll')),
                _modeButton('⚫ 구멍 빨아들이기', () => _play('hole')),
                _modeButton('🔵 구멍 피하기', () => _play('room')),
                const SizedBox(height: 18),
                if (_lastEvent.isNotEmpty)
                  Text('마지막 이벤트: $_lastEvent',
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Flutter 셸 + three.js 인게임 (벤치마킹 슬라이스)',
                      style: TextStyle(fontSize: 10, color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigButton(String label, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF5D1E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
        ),
        child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      );

  Widget _modeButton(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: 240,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFFF7E6),
              foregroundColor: const Color(0xFF4A3B2A),
              side: const BorderSide(color: Colors.white, width: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      );
}
