import '../config/api_endpoints.dart';
import 'api_service.dart';

class AiChatResponse {
  final String reply;
  final List<AiChatDiaryReference> references;

  AiChatResponse({required this.reply, required this.references});

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final refs = (json['references'] as List?)
            ?.map((item) =>
                AiChatDiaryReference.fromJson(item as Map<String, dynamic>))
            .toList() ??
        <AiChatDiaryReference>[];
    return AiChatResponse(
      reply: json['reply']?.toString() ?? '답변을 생성하지 못했어요.',
      references: refs,
    );
  }
}

class AiChatDiaryReference {
  final int diaryId;
  final String diaryDate;
  final String title;
  final String? moodEmoji;
  final String summary;

  AiChatDiaryReference({
    required this.diaryId,
    required this.diaryDate,
    required this.title,
    this.moodEmoji,
    required this.summary,
  });

  factory AiChatDiaryReference.fromJson(Map<String, dynamic> json) {
    return AiChatDiaryReference(
      diaryId: (json['diaryId'] as num).toInt(),
      diaryDate: json['diaryDate']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      moodEmoji: json['moodEmoji']?.toString(),
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class AiChatService {
  static Future<AiChatResponse> sendMessage(String message) async {
    final response = await ApiService.post(
      ApiEndpoints.aiChat,
      {'message': message},
    );

    if (!ApiService.isSuccessful(response.statusCode)) {
      ApiService.handleErrorResponse(response);
    }

    final data = ApiService.parseResponse(response) ?? {};
    return AiChatResponse.fromJson(data);
  }
}
