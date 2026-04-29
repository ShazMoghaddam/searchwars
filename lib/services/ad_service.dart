/// AdMob placeholder — disabled until you set up an AdMob account.
/// 
/// TO ENABLE:
/// 1. Add `google_mobile_ads: ^5.1.0` back to pubspec.yaml
/// 2. Add your AdMob App ID to AndroidManifest.xml
/// 3. Set kAdsEnabled = true below
/// 4. Replace the test IDs with your real IDs

const bool kAdsEnabled = false;

class AdService {
  static Future<void> init() async {}
  static Future<bool> showRewardedAd() async => false;
  static bool get isAdReady => false;
}
