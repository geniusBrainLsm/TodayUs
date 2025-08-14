// Models for couple connection functionality

/// Represents the current connection status of a couple
enum CoupleConnectionStatus {
  notConnected,
  pendingInvite,
  connected,
  connectionFailed,
}

/// Data structure for couple connection information
class CoupleConnection {
  final String? inviteCode;
  final String? partnerName;
  final String? partnerNickname;
  final CoupleConnectionStatus status;
  final DateTime? connectedAt;
  final DateTime? inviteCreatedAt;
  final DateTime? inviteExpiresAt;

  const CoupleConnection({
    this.inviteCode,
    this.partnerName,
    this.partnerNickname,
    required this.status,
    this.connectedAt,
    this.inviteCreatedAt,
    this.inviteExpiresAt,
  });

  /// Create a CoupleConnection with no connection
  factory CoupleConnection.notConnected() {
    return const CoupleConnection(
      status: CoupleConnectionStatus.notConnected,
    );
  }

  /// Create a CoupleConnection with pending invite
  factory CoupleConnection.withInvite(String inviteCode, DateTime expiresAt) {
    return CoupleConnection(
      inviteCode: inviteCode,
      status: CoupleConnectionStatus.pendingInvite,
      inviteCreatedAt: DateTime.now(),
      inviteExpiresAt: expiresAt,
    );
  }

  /// Create a CoupleConnection that is connected
  factory CoupleConnection.connected(String partnerName, String partnerNickname) {
    return CoupleConnection(
      partnerName: partnerName,
      partnerNickname: partnerNickname,
      status: CoupleConnectionStatus.connected,
      connectedAt: DateTime.now(),
    );
  }

  /// Check if the invite code has expired
  bool get isInviteExpired {
    if (inviteExpiresAt == null) return false;
    return DateTime.now().isAfter(inviteExpiresAt!);
  }

  /// Get remaining time for invite expiration
  Duration? get timeUntilExpiration {
    if (inviteExpiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(inviteExpiresAt!)) return null;
    return inviteExpiresAt!.difference(now);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'inviteCode': inviteCode,
      'partnerName': partnerName,
      'partnerNickname': partnerNickname,
      'status': status.index,
      'connectedAt': connectedAt?.toIso8601String(),
      'inviteCreatedAt': inviteCreatedAt?.toIso8601String(),
      'inviteExpiresAt': inviteExpiresAt?.toIso8601String(),
    };
  }

  /// Create from JSON stored data
  factory CoupleConnection.fromJson(Map<String, dynamic> json) {
    return CoupleConnection(
      inviteCode: json['inviteCode'],
      partnerName: json['partnerName'],
      partnerNickname: json['partnerNickname'],
      status: CoupleConnectionStatus.values[json['status'] ?? 0],
      connectedAt: json['connectedAt'] != null 
          ? DateTime.parse(json['connectedAt']) 
          : null,
      inviteCreatedAt: json['inviteCreatedAt'] != null 
          ? DateTime.parse(json['inviteCreatedAt']) 
          : null,
      inviteExpiresAt: json['inviteExpiresAt'] != null 
          ? DateTime.parse(json['inviteExpiresAt']) 
          : null,
    );
  }

  /// Create a copy with updated fields
  CoupleConnection copyWith({
    String? inviteCode,
    String? partnerName,
    String? partnerNickname,
    CoupleConnectionStatus? status,
    DateTime? connectedAt,
    DateTime? inviteCreatedAt,
    DateTime? inviteExpiresAt,
  }) {
    return CoupleConnection(
      inviteCode: inviteCode ?? this.inviteCode,
      partnerName: partnerName ?? this.partnerName,
      partnerNickname: partnerNickname ?? this.partnerNickname,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      inviteCreatedAt: inviteCreatedAt ?? this.inviteCreatedAt,
      inviteExpiresAt: inviteExpiresAt ?? this.inviteExpiresAt,
    );
  }
}

/// Data structure for invite code validation
class InviteCodeValidation {
  final bool isValid;
  final String? error;
  final String? partnerName;
  final String? partnerNickname;

  const InviteCodeValidation({
    required this.isValid,
    this.error,
    this.partnerName,
    this.partnerNickname,
  });

  factory InviteCodeValidation.valid(String partnerName, String partnerNickname) {
    return InviteCodeValidation(
      isValid: true,
      partnerName: partnerName,
      partnerNickname: partnerNickname,
    );
  }

  factory InviteCodeValidation.invalid(String error) {
    return InviteCodeValidation(
      isValid: false,
      error: error,
    );
  }
}