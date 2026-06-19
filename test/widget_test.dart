// hole_game 는 웹 전용 셸(dart:js_interop) + three.js iframe 구조라
// 실제 동작 검증은 build/web 브라우저 프리뷰로 수행한다.
// 여기서는 VM 에서 안전하게 도는 가벼운 새너티 테스트만 둔다.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity', () {
    expect(2 + 2, 4);
  });
}
