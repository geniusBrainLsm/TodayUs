
import '../config/api_endpoints.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'user_profile_store.dart';

class StoreRobot {
  final int id;
  final String code;
  final String name;
  final String? tagline;
  final String? description;
  final int priceOil;
  final String? imageUrl;
  final String? splashImageUrl;
  final String? beforeDiaryImageUrl;
  final String? afterDiaryImageUrl;
  final String? themeColorHex;
  final String? previewMessage;
  final String? chatGuidance;
  final String? commentGuidance;
  final int? chatMaxTokens;
  final int? commentMaxTokens;
  final double? chatTemperature;
  final double? commentTemperature;
  final bool owned;
  final bool active;

  const StoreRobot({
    required this.id,
    required this.code,
    required this.name,
    required this.priceOil,
    this.tagline,
    this.description,
    this.imageUrl,
    this.splashImageUrl,
    this.beforeDiaryImageUrl,
    this.afterDiaryImageUrl,
    this.themeColorHex,
    this.previewMessage,
    this.chatGuidance,
    this.commentGuidance,
    this.chatMaxTokens,
    this.commentMaxTokens,
    this.chatTemperature,
    this.commentTemperature,
    required this.owned,
    required this.active,
  });

  factory StoreRobot.fromJson(Map<String, dynamic> json) {
    return StoreRobot(
      id: (json['id'] as num).toInt(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tagline: json['tagline']?.toString(),
      description: json['description']?.toString(),
      priceOil: (json['priceOil'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      splashImageUrl: json['splashImageUrl']?.toString(),
      beforeDiaryImageUrl: json['beforeDiaryImageUrl']?.toString(),
      afterDiaryImageUrl: json['afterDiaryImageUrl']?.toString(),
      themeColorHex: json['themeColorHex']?.toString(),
      previewMessage: json['previewMessage']?.toString(),
      chatGuidance: json['chatUserGuidance']?.toString(),
      commentGuidance: json['commentUserGuidance']?.toString(),
      chatMaxTokens: (json['chatMaxTokens'] as num?)?.toInt(),
      commentMaxTokens: (json['commentMaxTokens'] as num?)?.toInt(),
      chatTemperature: (json['chatTemperature'] as num?)?.toDouble(),
      commentTemperature: (json['commentTemperature'] as num?)?.toDouble(),
      owned: json['owned'] == true,
      active: json['active'] == true,
    );
  }
}

class StoreOverview {
  final int oilBalance;
  final List<StoreRobot> robots;

  const StoreOverview({required this.oilBalance, required this.robots});

  factory StoreOverview.fromJson(Map<String, dynamic> json) {
    final robots = (json['robots'] as List?)
            ?.map((item) => StoreRobot.fromJson(item as Map<String, dynamic>))
            .toList() ??
        <StoreRobot>[];
    return StoreOverview(
      oilBalance: (json['oilBalance'] as num?)?.toInt() ?? 0,
      robots: robots,
    );
  }
}

class StoreService {
  static Future<StoreOverview> fetchOverview() async {
    final response = await ApiService.get(ApiEndpoints.storeOverview);
    _ensureSuccess(response);
    final data = ApiService.parseResponse(response) ?? {};
    final overview = StoreOverview.fromJson(data);
    await _syncProfile(overview);
    return overview;
  }

  static Future<StoreOverview> purchaseRobot(int robotId) async {
    final response = await ApiService.post(
      ApiEndpoints.storePurchase(robotId),
      const {},
    );
    _ensureSuccess(response);
    final data = ApiService.parseResponse(response) ?? {};
    final overview = StoreOverview.fromJson(data);
    await _syncProfile(overview);
    return overview;
  }

  static Future<StoreOverview> activateRobot(int robotId) async {
    final response = await ApiService.post(
      ApiEndpoints.storeActivate(robotId),
      const {},
    );
    _ensureSuccess(response);
    final data = ApiService.parseResponse(response) ?? {};
    final overview = StoreOverview.fromJson(data);
    await _syncProfile(overview);
    return overview;
  }

  static void _ensureSuccess(http.Response response) {
    if (!ApiService.isSuccessful(response.statusCode)) {
      ApiService.handleErrorResponse(response);
    }
  }

  static Future<void> _syncProfile(StoreOverview overview) async {
    await UserProfileStore.saveOilBalance(overview.oilBalance);
    final activeRobot = overview.robots.firstWhere(
      (robot) => robot.active,
      orElse: () => overview.robots.isNotEmpty
          ? overview.robots.first
          : const StoreRobot(
              id: -1,
              code: '',
              name: '',
              priceOil: 0,
              owned: false,
              active: false,
            ),
    );
    if (activeRobot.id != -1) {
      await UserProfileStore.saveActiveRobotSummary(
        name: activeRobot.name,
        imageUrl: activeRobot.imageUrl,
        splashUrl: activeRobot.splashImageUrl,
        beforeDiaryImageUrl: activeRobot.beforeDiaryImageUrl,
        afterDiaryImageUrl: activeRobot.afterDiaryImageUrl,
        themeColorHex: activeRobot.themeColorHex,
        previewMessage: activeRobot.previewMessage,
      );
    }
  }
}

