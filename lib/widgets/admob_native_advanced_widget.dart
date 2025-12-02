

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobNativeAdvancedWidget extends StatefulWidget {
  final String adUnitId;

  const AdmobNativeAdvancedWidget({super.key, required this.adUnitId});

  @override
  State<AdmobNativeAdvancedWidget> createState() => _AdmobNativeAdvancedWidgetState();
}

class _AdmobNativeAdvancedWidgetState extends State<AdmobNativeAdvancedWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    developer.log('AdmobNativeAdvancedWidget: initState called for adUnitId: ${widget.adUnitId}', name: 'AdMob');
    _loadAd();
  }

  void _loadAd() {
    developer.log('AdmobNativeAdvancedWidget: Starting to load ad for adUnitId: ${widget.adUnitId}, retry count: $_retryCount', name: 'AdMob');

    try {
      _nativeAd = NativeAd(
        adUnitId: widget.adUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            developer.log('AdmobNativeAdvancedWidget: Ad loaded successfully for adUnitId: ${widget.adUnitId}', name: 'AdMob');
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            developer.log('AdmobNativeAdvancedWidget: Ad failed to load for adUnitId: ${widget.adUnitId}, error code: ${error.code}, message: ${error.message}', name: 'AdMob', error: error);
            ad.dispose();
            _nativeAd = null;
            setState(() {
              _isAdLoaded = false;
            });

            // Retry loading if under max retries
            if (_retryCount < _maxRetries) {
              _retryCount++;
              developer.log('AdmobNativeAdvancedWidget: Retrying ad load, attempt: $_retryCount', name: 'AdMob');
              Future.delayed(const Duration(seconds: 2), _loadAd);
            } else {
              developer.log('AdmobNativeAdvancedWidget: Max retries reached, giving up on ad load for adUnitId: ${widget.adUnitId}', name: 'AdMob');
            }
          },
          onAdOpened: (ad) {
            developer.log('AdmobNativeAdvancedWidget: Ad opened for adUnitId: ${widget.adUnitId}', name: 'AdMob');
          },
          onAdClosed: (ad) {
            developer.log('AdmobNativeAdvancedWidget: Ad closed for adUnitId: ${widget.adUnitId}', name: 'AdMob');
          },
          onAdClicked: (ad) {
            developer.log('AdmobNativeAdvancedWidget: Ad clicked for adUnitId: ${widget.adUnitId}', name: 'AdMob');
          },
          onAdImpression: (ad) {
            developer.log('AdmobNativeAdvancedWidget: Ad impression recorded for adUnitId: ${widget.adUnitId}', name: 'AdMob');
          },
          onAdWillDismissScreen: (ad) {
            developer.log('AdmobNativeAdvancedWidget: Ad will dismiss screen for adUnitId: ${widget.adUnitId}', name: 'AdMob');
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          mainBackgroundColor: const Color(0xFF0D1B2A),
          cornerRadius: 8.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.blue,
            style: NativeTemplateFontStyle.monospace,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.grey,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.italic,
            size: 14.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.grey,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 12.0,
          ),
        ),
      )..load();
    } catch (e, stackTrace) {
      developer.log('AdmobNativeAdvancedWidget: Exception during ad load for adUnitId: ${widget.adUnitId}', name: 'AdMob', error: e, stackTrace: stackTrace);
      _nativeAd = null;
      setState(() {
        _isAdLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    developer.log('AdmobNativeAdvancedWidget: dispose called for adUnitId: ${widget.adUnitId}', name: 'AdMob');
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('AdmobNativeAdvancedWidget: build called for adUnitId: ${widget.adUnitId}, isAdLoaded: $_isAdLoaded, nativeAd: ${_nativeAd != null}', name: 'AdMob');

    if (_isAdLoaded && _nativeAd != null) {
      try {
        return Container(
          padding: const EdgeInsets.all(8.0),
          height: 120.0, // Reduced height for small template
          child: AdWidget(ad: _nativeAd!),
        );
      } catch (e, stackTrace) {
        developer.log('AdmobNativeAdvancedWidget: Exception in AdWidget for adUnitId: ${widget.adUnitId}', name: 'AdMob', error: e, stackTrace: stackTrace);
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }
  }
}
