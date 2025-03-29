enum UserRole { host, participant }

class CallParticipant {
  final String id;
  final String callId;
  final String userId;
  final String userDisplayName;
  final UserRole userRole;
  final DateTime joinTime;
  final DateTime? leaveTime;
  final int? durationInSeconds;
  final DeviceInfo deviceInfo;
  final bool hasAudio;
  final bool wasRemoved;

  CallParticipant({
    required this.id,
    required this.callId,
    required this.userId,
    required this.userDisplayName,
    required this.userRole,
    required this.joinTime,
    this.leaveTime,
    this.durationInSeconds,
    required this.deviceInfo,
    this.hasAudio = true,
    this.wasRemoved = false,
  });

  bool get isActive => leaveTime == null;
  bool get isHost => userRole == UserRole.host;

  Duration? get duration =>
      durationInSeconds != null
          ? Duration(seconds: durationInSeconds!)
          : (leaveTime != null ? leaveTime!.difference(joinTime) : null);

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['id'],
      callId: json['callId'],
      userId: json['userId'],
      userDisplayName: json['userDisplayName'],
      userRole: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${json['userRole']}',
        orElse: () => UserRole.participant,
      ),
      joinTime: (json['joinTime'] as dynamic).toDate(),
      leaveTime:
          json['leaveTime'] != null
              ? (json['leaveTime'] as dynamic).toDate()
              : null,
      durationInSeconds: json['durationInSeconds'],
      deviceInfo: DeviceInfo.fromJson(json['deviceInfo']),
      hasAudio: json['hasAudio'] ?? true,
      wasRemoved: json['wasRemoved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callId': callId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userRole': userRole.toString().split('.').last,
      'joinTime': joinTime,
      'leaveTime': leaveTime,
      'durationInSeconds': durationInSeconds,
      'deviceInfo': deviceInfo.toJson(),
      'hasAudio': hasAudio,
      'wasRemoved': wasRemoved,
    };
  }

  CallParticipant copyWith({
    String? id,
    String? callId,
    String? userId,
    String? userDisplayName,
    UserRole? userRole,
    DateTime? joinTime,
    DateTime? leaveTime,
    int? durationInSeconds,
    DeviceInfo? deviceInfo,
    bool? hasAudio,
    bool? wasRemoved,
  }) {
    return CallParticipant(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userRole: userRole ?? this.userRole,
      joinTime: joinTime ?? this.joinTime,
      leaveTime: leaveTime ?? this.leaveTime,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      hasAudio: hasAudio ?? this.hasAudio,
      wasRemoved: wasRemoved ?? this.wasRemoved,
    );
  }
}

class DeviceInfo {
  final String platform;
  final String? browser;
  final String? deviceModel;
  final String? ipAddress;

  DeviceInfo({
    required this.platform,
    this.browser,
    this.deviceModel,
    this.ipAddress,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'] ?? 'unknown',
      browser: json['browser'],
      deviceModel: json['deviceModel'],
      ipAddress: json['ipAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'browser': browser,
      'deviceModel': deviceModel,
      'ipAddress': ipAddress,
    };
  }
}
