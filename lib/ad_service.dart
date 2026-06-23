// 광고 없는 오프라인 버전 — 모든 메서드 no-op
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();

  static Future<void> initialize() async {}
  void showInterstitial({required void Function() onClosed}) => onClosed();
}
