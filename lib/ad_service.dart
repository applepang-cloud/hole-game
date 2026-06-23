import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 구글 AdMob 인터스티셜 광고 서비스.
/// 웹에서는 모든 메서드가 no-op.
/// 실제 출시 시 [_kInterstitialId]를 진짜 광고 단위 ID로 교체.
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();

  // Google 제공 테스트 광고 단위 ID (실제 출시 시 교체 필수)
  // App ID는 AndroidManifest.xml의 com.google.android.gms.ads.APPLICATION_ID에 설정
  static const String _kInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  InterstitialAd? _ad;
  bool _loading = false;

  /// 앱 시작 시 1회 호출. 웹이면 스킵.
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    instance.load();
  }

  /// 인터스티셜 사전 로드.
  void load() {
    if (kIsWeb || _loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: _kInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              load(); // 다음 광고 미리 로드
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _ad = null;
              load();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _loading = false;
        },
      ),
    );
  }

  /// 게임 종료(클리어/실패) 시 호출. 광고가 준비됐으면 표시, 아니면 [onClosed] 즉시 실행.
  void showInterstitial({required VoidCallback onClosed}) {
    if (kIsWeb || _ad == null) {
      onClosed();
      return;
    }
    final ad = _ad!;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        load();
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        load();
        onClosed();
      },
    );
    ad.show();
  }
}
