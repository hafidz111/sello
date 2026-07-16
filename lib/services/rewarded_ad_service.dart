import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sello/core/constants/admob_config.dart';

enum RewardedAdLoadState {
  idle,
  loading,
  ready,
  showing,
  failed,
}

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _rewardedAd;
  RewardedAdLoadState _state = RewardedAdLoadState.idle;
  String? _lastError;
  bool _initialized = false;

  RewardedAdLoadState get state => _state;
  String? get lastError => _lastError;
  bool get isReady => _state == RewardedAdLoadState.ready && _rewardedAd != null;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  Future<bool> loadReportRewardedAd() async {
    await initialize();

    if (_state == RewardedAdLoadState.loading ||
        _state == RewardedAdLoadState.showing) {
      return isReady;
    }

    _disposeAd();
    _state = RewardedAdLoadState.loading;
    _lastError = null;

    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: AdMobConfig.rewardedReportUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded: ${AdMobConfig.rewardedReportUnitId}');
          _rewardedAd = ad;
          _state = RewardedAdLoadState.ready;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _lastError = error.message;
          _state = RewardedAdLoadState.failed;
          _rewardedAd = null;
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Tampilkan iklan. [onUserEarnedReward] dipanggil jika user menyelesaikan reward.
  Future<bool> showReportRewardedAd({
    required void Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
    VoidCallback? onFailedToShow,
  }) async {
    if (_rewardedAd == null || _state != RewardedAdLoadState.ready) {
      final loaded = await loadReportRewardedAd();
      if (!loaded || _rewardedAd == null) {
        onFailedToShow?.call();
        return false;
      }
    }

    final showing = _rewardedAd!;
    final completer = Completer<bool>();
    var earned = false;

    showing.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed full screen content.');
        _state = RewardedAdLoadState.showing;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        _lastError = error.message;
        _state = RewardedAdLoadState.failed;
        ad.dispose();
        if (identical(_rewardedAd, ad)) _rewardedAd = null;
        onFailedToShow?.call();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed.');
        ad.dispose();
        if (identical(_rewardedAd, ad)) _rewardedAd = null;
        _state = RewardedAdLoadState.idle;
        onDismissed?.call();
        if (!completer.isCompleted) completer.complete(earned);
        unawaited(loadReportRewardedAd());
      },
      onAdImpression: (ad) {
        debugPrint('Rewarded ad impression.');
      },
      onAdClicked: (ad) {
        debugPrint('Rewarded ad clicked.');
      },
    );

    await showing.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward(reward);
      },
    );

    return completer.future;
  }

  void _disposeAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  void dispose() {
    _disposeAd();
    _state = RewardedAdLoadState.idle;
  }
}
