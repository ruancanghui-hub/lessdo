import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'mobile_ads_support.dart';

/// Loads and presents AdMob app open ads on cold and warm starts.
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  var _isShowingAd = false;
  var _isLoadingAd = false;
  DateTime? _loadedAt;
  var _loadAttempts = 0;

  static const _maxLoadAttempts = 3;
  static const _maxCacheAge = Duration(hours: 4);

  bool get isAdAvailable {
    final ad = _appOpenAd;
    final loadedAt = _loadedAt;
    if (ad == null || loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < _maxCacheAge;
  }

  Future<void> loadAd() async {
    if (!MobileAdsSupport.enabled || _isLoadingAd || isAdAvailable) return;
    if (_loadAttempts >= _maxLoadAttempts) return;

    _isLoadingAd = true;
    await AppOpenAd.load(
      adUnitId: AdMobConfig.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          _loadedAt = DateTime.now();
          _loadAttempts = 0;
          _isLoadingAd = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('App open ad failed to load: $error');
          _appOpenAd = null;
          _loadedAt = null;
          _loadAttempts += 1;
          _isLoadingAd = false;
          if (_loadAttempts < _maxLoadAttempts) {
            final delay = Duration(seconds: 2 * _loadAttempts);
            unawaited(Future<void>.delayed(delay, loadAd));
          }
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (!MobileAdsSupport.enabled || _isShowingAd) return;
    if (!isAdAvailable) {
      unawaited(loadAd());
      return;
    }

    final ad = _appOpenAd!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _isShowingAd = true,
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        debugPrint('App open ad failed to show: $error');
        _isShowingAd = false;
        failedAd.dispose();
        _appOpenAd = null;
        _loadedAt = null;
        unawaited(loadAd());
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        _isShowingAd = false;
        dismissedAd.dispose();
        _appOpenAd = null;
        _loadedAt = null;
        unawaited(loadAd());
      },
    );
    ad.show();
  }
}

final appOpenAdManager = AppOpenAdManager();
