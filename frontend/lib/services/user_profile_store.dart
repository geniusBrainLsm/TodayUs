import 'package:shared_preferences/shared_preferences.dart';

class RobotAppearance {
  final String? name;
  final String? imageUrl;
  final String? splashImageUrl;
  final String? themeColorHex;
  final String? previewMessage;

  const RobotAppearance({
    this.name,
    this.imageUrl,
    this.splashImageUrl,
    this.themeColorHex,
    this.previewMessage,
  });
}

class UserProfileStore {
  static const _oilBalanceKey = 'user_oil_balance';
  static const _robotNameKey = 'user_robot_name';
  static const _robotImageUrlKey = 'user_robot_image_url';
  static const _robotSplashUrlKey = 'user_robot_splash_url';
  static const _robotThemeColorKey = 'user_robot_theme_color';
  static const _robotPreviewKey = 'user_robot_preview_message';
  static const _userRoleKey = 'user_role';

  static Future<void> saveUserSnapshot(Map<String, dynamic>? userJson) async {
    if (userJson == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_oilBalanceKey, (userJson['oilBalance'] as num?)?.toInt() ?? 0);
    await prefs.setString(_robotNameKey, userJson['activeRobotName']?.toString() ?? '');
    await prefs.setString(
        _robotImageUrlKey, userJson['activeRobotImageUrl']?.toString() ?? '');
    await prefs.setString(
        _robotSplashUrlKey, userJson['activeRobotSplashImageUrl']?.toString() ?? '');
    await prefs.setString(
        _robotThemeColorKey, userJson['activeRobotThemeColorHex']?.toString() ?? '');
    await prefs.setString(
        _robotPreviewKey, userJson['activeRobotPreviewMessage']?.toString() ?? '');
    await prefs.setString(_userRoleKey, userJson['role']?.toString() ?? 'USER');
  }

  static Future<void> saveOilBalance(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_oilBalanceKey, balance);
  }

  static Future<int> getOilBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_oilBalanceKey) ?? 0;
  }

  static Future<void> saveActiveRobotSummary({
    String? name,
    String? imageUrl,
    String? splashUrl,
    String? themeColorHex,
    String? previewMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_robotNameKey, name ?? '');
    await prefs.setString(_robotImageUrlKey, imageUrl ?? '');
    await prefs.setString(_robotSplashUrlKey, splashUrl ?? '');
    await prefs.setString(_robotThemeColorKey, themeColorHex ?? '');
    await prefs.setString(_robotPreviewKey, previewMessage ?? '');
  }

  static Future<RobotAppearance> loadActiveRobot() async {
    final prefs = await SharedPreferences.getInstance();
    return RobotAppearance(
      name: prefs.getString(_robotNameKey),
      imageUrl: prefs.getString(_robotImageUrlKey),
      splashImageUrl: prefs.getString(_robotSplashUrlKey),
      themeColorHex: prefs.getString(_robotThemeColorKey),
      previewMessage: prefs.getString(_robotPreviewKey),
    );
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }
}
