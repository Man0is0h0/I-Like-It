import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Collects device and app info for debugging purposes.
/// Only captures non-PII data — no IMEI, no IP, no location.
class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> collect() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    // Screen info via Flutter's platform dispatcher
    final view = PlatformDispatcher.instance.views.first;
    final physicalSize = view.physicalSize;
    final pixelRatio = view.devicePixelRatio;
    final screenWidth = physicalSize.width.toInt();
    final screenHeight = physicalSize.height.toInt();
    final screenDensity = double.parse(pixelRatio.toStringAsFixed(2));

    // Determine locale & timezone
    final locale = PlatformDispatcher.instance.locale.toString(); // e.g. "en_IN"
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes = (offset.inMinutes.remainder(60)).abs().toString().padLeft(2, '0');
    final offsetSign = offset.isNegative ? '-' : '+';
    final timezoneStr = '${now.timeZoneName} (UTC$offsetSign$offsetHours:$offsetMinutes)';

    String deviceBrand = 'unknown';
    String deviceModel = 'unknown';
    String osVersion = 'unknown';
    int androidSdk = 0;
    bool isTablet = false;

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        deviceBrand = info.brand;
        deviceModel = info.model;
        osVersion = info.version.release;
        androidSdk = info.version.sdkInt;
        // Tablet heuristic: smallest side > 600dp
        final smallestSideDp = (physicalSize.shortestSide / pixelRatio);
        isTablet = smallestSideDp >= 600;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        deviceBrand = 'Apple';
        deviceModel = info.model;
        osVersion = info.systemVersion;
        androidSdk = 0;
        final smallestSideDp = (physicalSize.shortestSide / pixelRatio);
        isTablet = smallestSideDp >= 600;
      }
    } catch (e) {
      print('[DeviceInfoService] Error collecting device info: $e');
    }

    final yyyy = now.year.toString();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final istTimeString = '$yyyy-$mm-$dd $hh:$min:$ss IST';

    return {
      'device_brand': deviceBrand,
      'device_model': deviceModel,
      'android_version': osVersion,
      'android_sdk': androidSdk,
      'app_version': appVersion,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'screen_density': screenDensity,
      'is_tablet': isTablet,
      'locale': locale,
      'timezone': timezoneStr,
      'last_seen_at': istTimeString,
    };
  }
}
