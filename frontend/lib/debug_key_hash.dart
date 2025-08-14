import 'dart:io';
import 'package:flutter/services.dart';

class DebugKeyHash {
  static Future<String?> getKeyHash() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.todayus.todayus_frontend/key_hash');
        final String keyHash = await platform.invokeMethod('getKeyHash');
        print('=== ACTUAL KEY HASH FROM APP ===');
        print('Key Hash: $keyHash');
        print('Copy this to Kakao Developers Console');
        print('================================');
        return keyHash;
      } catch (e) {
        print('Failed to get key hash from native: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> printKeyHash() async {
    await getKeyHash();
  }
}