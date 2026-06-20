import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/ads/admob_config.dart';
import 'package:lessdo/ads/mobile_ads_support.dart';

void main() {
  test('AdMob config uses publisher app and app open unit IDs', () {
    expect(
      AdMobConfig.applicationId,
      'ca-app-pub-1210970407399902~1651813383',
    );
    expect(
      AdMobConfig.appOpenAdUnitId,
      'ca-app-pub-1210970407399902/9742322322',
    );
  });

  test('mobile ads are disabled during flutter tests', () {
    expect(MobileAdsSupport.enabled, isFalse);
  });
}
